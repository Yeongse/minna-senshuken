import { Hono } from 'hono';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';
import { ChampionshipStatus } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { requireAuth, optionalAuth, type AuthUser } from '../middleware/auth';
import { ErrorCodes, NotFoundError, ForbiddenError, ValidationError, AppError } from '../lib/errors';
import { paginationSchema, createPaginatedResult, calculateSkip } from '../lib/pagination';
import { computeChampionshipStatus, isSelecting } from '../lib/championship-status';

type Variables = { user: AuthUser | null };

const championshipsRoutes = new Hono<{ Variables: Variables }>();

// Validation schemas
const listChampionshipsSchema = paginationSchema.extend({
  status: z.enum(['recruiting', 'selecting', 'announced']).optional(),
  sort: z.enum(['newest', 'popular']).default('newest'),
});

const createChampionshipSchema = z.object({
  title: z.string().min(1).max(50),
  description: z.string().min(1).max(500),
  durationDays: z.number().int().min(1).max(14),
});

const publishResultSchema = z.object({
  summaryComment: z.string().max(1000).optional(),
});

// Include configurations for queries
const championshipInclude = {
  user: {
    select: {
      id: true,
      displayName: true,
      avatarUrl: true,
    },
  },
  _count: {
    select: { answers: true },
  },
};

// Map frontend status to database status
function mapStatusToDbStatus(status: 'recruiting' | 'selecting' | 'announced'): ChampionshipStatus {
  const statusMap = {
    recruiting: ChampionshipStatus.RECRUITING,
    selecting: ChampionshipStatus.SELECTING,
    announced: ChampionshipStatus.ANNOUNCED,
  };
  return statusMap[status];
}

// Format championship response
function formatChampionship(c: any) {
  return {
    id: c.id,
    title: c.title,
    description: c.description,
    status: computeChampionshipStatus(c.status, c.endAt),
    startAt: c.startAt,
    endAt: c.endAt,
    summaryComment: c.summaryComment,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
    user: c.user,
    answerCount: c._count?.answers ?? 0,
    totalLikes: c.answers?.reduce((sum: number, a: any) => sum + a.likeCount, 0) ?? 0,
  };
}

// GET /championships - List championships
championshipsRoutes.get(
  '/',
  optionalAuth(),
  zValidator('query', listChampionshipsSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です');
    }
  }),
  async (c) => {
    const params = c.req.valid('query');

    const where: any = {};
    if (params.status) {
      where.status = mapStatusToDbStatus(params.status);
    }

    const orderBy = params.sort === 'popular'
      ? { answers: { _count: 'desc' as const } }
      : { createdAt: 'desc' as const };

    const [championships, total] = await Promise.all([
      prisma.championship.findMany({
        where,
        orderBy,
        skip: calculateSkip(params),
        take: params.limit,
        include: championshipInclude,
      }),
      prisma.championship.count({ where }),
    ]);

    const items = championships.map(formatChampionship);
    return c.json(createPaginatedResult(items, total, params));
  }
);

// GET /championships/:id - Get championship details
championshipsRoutes.get('/:id', optionalAuth(), async (c) => {
  const { id } = c.req.param();

  const championship = await prisma.championship.findUnique({
    where: { id },
    include: {
      ...championshipInclude,
      answers: {
        select: {
          likeCount: true,
        },
      },
    },
  });

  if (!championship) {
    throw new NotFoundError('選手権が見つかりません', ErrorCodes.CHAMPIONSHIP_NOT_FOUND);
  }

  return c.json(formatChampionship(championship));
});

// POST /championships - Create championship
championshipsRoutes.post(
  '/',
  requireAuth(),
  zValidator('json', createChampionshipSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です', {
        ...Object.fromEntries(
          result.error.issues.map((issue) => [issue.path.join('.'), [issue.message]])
        ),
      });
    }
  }),
  async (c) => {
    const user = c.get('user')!;
    const data = c.req.valid('json');

    const startAt = new Date();
    const endAt = new Date(startAt.getTime() + data.durationDays * 24 * 60 * 60 * 1000);

    const championship = await prisma.championship.create({
      data: {
        userId: user.id,
        title: data.title,
        description: data.description,
        startAt,
        endAt,
      },
      include: {
        ...championshipInclude,
        answers: {
          select: {
            likeCount: true,
          },
        },
      },
    });

    return c.json(formatChampionship(championship), 201);
  }
);

// PUT /championships/:id/force-end - Force end championship
championshipsRoutes.put('/:id/force-end', requireAuth(), async (c) => {
  const { id } = c.req.param();
  const user = c.get('user')!;

  const championship = await prisma.championship.findUnique({
    where: { id },
  });

  if (!championship) {
    throw new NotFoundError('選手権が見つかりません', ErrorCodes.CHAMPIONSHIP_NOT_FOUND);
  }

  if (championship.userId !== user.id) {
    throw new ForbiddenError('選手権の主催者のみが実行できます', ErrorCodes.NOT_OWNER);
  }

  const updated = await prisma.championship.update({
    where: { id },
    data: {
      status: ChampionshipStatus.SELECTING,
      endAt: new Date(),
    },
    include: {
      ...championshipInclude,
      answers: {
        select: {
          likeCount: true,
        },
      },
    },
  });

  return c.json(formatChampionship(updated));
});

// PUT /championships/:id/publish-result - Publish championship result
championshipsRoutes.put(
  '/:id/publish-result',
  requireAuth(),
  zValidator('json', publishResultSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です');
    }
  }),
  async (c) => {
    const { id } = c.req.param();
    const user = c.get('user')!;
    const data = c.req.valid('json');

    const championship = await prisma.championship.findUnique({
      where: { id },
    });

    if (!championship) {
      throw new NotFoundError('選手権が見つかりません', ErrorCodes.CHAMPIONSHIP_NOT_FOUND);
    }

    if (championship.userId !== user.id) {
      throw new ForbiddenError('選手権の主催者のみが実行できます', ErrorCodes.NOT_OWNER);
    }

    // Check if championship is in SELECTING status
    if (!isSelecting(championship.status, championship.endAt)) {
      throw new AppError(
        ErrorCodes.INVALID_STATUS,
        '選定中の選手権のみ結果発表できます',
        400
      );
    }

    const updated = await prisma.championship.update({
      where: { id },
      data: {
        status: ChampionshipStatus.ANNOUNCED,
        summaryComment: data.summaryComment,
      },
      include: {
        ...championshipInclude,
        answers: {
          select: {
            likeCount: true,
          },
        },
      },
    });

    return c.json(formatChampionship(updated));
  }
);

export { championshipsRoutes };
