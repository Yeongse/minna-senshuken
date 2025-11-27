import { Hono } from 'hono';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';
import { AwardType } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { requireAuth, optionalAuth, type AuthUser } from '../middleware/auth';
import { ErrorCodes, NotFoundError, ForbiddenError, ValidationError, AppError } from '../lib/errors';
import { paginationSchema, createPaginatedResult, calculateSkip } from '../lib/pagination';
import { isRecruiting, isSelecting } from '../lib/championship-status';
import { generateUploadUrl } from '../lib/storage';
import { env } from '../config/env';

type Variables = { user: AuthUser | null };

const answersRoutes = new Hono<{ Variables: Variables }>();

// Validation schemas
const listAnswersSchema = paginationSchema.extend({
  sort: z.enum(['score', 'newest']).default('score'),
});

const createAnswerSchema = z.object({
  text: z.string().min(1).max(300),
  imageUrl: z.string().url().optional(),
});

const updateAnswerSchema = z.object({
  text: z.string().min(1).max(300).optional(),
  imageUrl: z.string().url().optional().nullable(),
});

const setAwardSchema = z.object({
  awardType: z.enum(['grand_prize', 'prize', 'special_prize']).nullable(),
  awardComment: z.string().max(300).optional(),
});

const uploadUrlSchema = z.object({
  contentType: z.string().refine(
    (val) => val.startsWith('image/'),
    { message: 'contentType must be an image type (image/*)' }
  ),
  fileName: z.string().min(1),
});

// Map frontend award type to database award type
function mapAwardType(awardType: string | null): AwardType | null {
  if (awardType === null) return null;
  const awardTypeMap: Record<string, AwardType> = {
    grand_prize: AwardType.GRAND_PRIZE,
    prize: AwardType.PRIZE,
    special_prize: AwardType.SPECIAL_PRIZE,
  };
  return awardTypeMap[awardType] ?? null;
}

// Map database award type to frontend format
function mapDbAwardType(awardType: AwardType | null): string | null {
  if (awardType === null) return null;
  const awardTypeMap: Record<AwardType, string> = {
    [AwardType.GRAND_PRIZE]: 'grand_prize',
    [AwardType.PRIZE]: 'prize',
    [AwardType.SPECIAL_PRIZE]: 'special_prize',
  };
  return awardTypeMap[awardType];
}

// Calculate answer score
function calculateScore(likeCount: number, commentCount: number): number {
  return likeCount + commentCount * 0.5;
}

// Format answer response
function formatAnswer(a: any) {
  return {
    id: a.id,
    championshipId: a.championshipId,
    userId: a.userId,
    text: a.text,
    imageUrl: a.imageUrl,
    awardType: mapDbAwardType(a.awardType),
    awardComment: a.awardComment,
    likeCount: a.likeCount,
    commentCount: a.commentCount,
    score: calculateScore(a.likeCount, a.commentCount),
    createdAt: a.createdAt,
    updatedAt: a.updatedAt,
    user: a.user,
  };
}

// Include configuration for answer queries
const answerInclude = {
  user: {
    select: {
      id: true,
      displayName: true,
      avatarUrl: true,
    },
  },
  championship: true,
};

// GET /championships/:id/answers - List answers
answersRoutes.get(
  '/championships/:id/answers',
  optionalAuth(),
  zValidator('query', listAnswersSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です');
    }
  }),
  async (c) => {
    const { id: championshipId } = c.req.param();
    const params = c.req.valid('query');

    // Check if championship exists
    const championship = await prisma.championship.findUnique({
      where: { id: championshipId },
    });

    if (!championship) {
      throw new NotFoundError('選手権が見つかりません', ErrorCodes.CHAMPIONSHIP_NOT_FOUND);
    }

    // For score sort, we need to fetch all and sort in application layer
    // since score is a computed field
    const orderBy = params.sort === 'newest'
      ? { createdAt: 'desc' as const }
      : [{ likeCount: 'desc' as const }, { commentCount: 'desc' as const }];

    const [answers, total] = await Promise.all([
      prisma.answer.findMany({
        where: { championshipId },
        orderBy,
        skip: calculateSkip(params),
        take: params.limit,
        include: {
          user: {
            select: {
              id: true,
              displayName: true,
              avatarUrl: true,
            },
          },
        },
      }),
      prisma.answer.count({ where: { championshipId } }),
    ]);

    let items = answers.map(formatAnswer);

    // If sorting by score, sort in application layer for accurate results
    if (params.sort === 'score') {
      items.sort((a, b) => b.score - a.score);
    }

    return c.json(createPaginatedResult(items, total, params));
  }
);

// POST /championships/:id/answers - Create answer
answersRoutes.post(
  '/championships/:id/answers',
  requireAuth(),
  zValidator('json', createAnswerSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です', {
        ...Object.fromEntries(
          result.error.issues.map((issue) => [issue.path.join('.'), [issue.message]])
        ),
      });
    }
  }),
  async (c) => {
    const { id: championshipId } = c.req.param();
    const user = c.get('user')!;
    const data = c.req.valid('json');

    // Check if championship exists and is recruiting
    const championship = await prisma.championship.findUnique({
      where: { id: championshipId },
    });

    if (!championship) {
      throw new NotFoundError('選手権が見つかりません', ErrorCodes.CHAMPIONSHIP_NOT_FOUND);
    }

    if (!isRecruiting(championship.status, championship.endAt)) {
      throw new AppError(
        ErrorCodes.INVALID_STATUS,
        '募集中の選手権のみ回答を投稿できます',
        400
      );
    }

    const answer = await prisma.answer.create({
      data: {
        championshipId,
        userId: user.id,
        text: data.text,
        imageUrl: data.imageUrl,
      },
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });

    return c.json(formatAnswer(answer), 201);
  }
);

// PUT /answers/:id - Update answer
answersRoutes.put(
  '/answers/:id',
  requireAuth(),
  zValidator('json', updateAnswerSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です', {
        ...Object.fromEntries(
          result.error.issues.map((issue) => [issue.path.join('.'), [issue.message]])
        ),
      });
    }
  }),
  async (c) => {
    const { id } = c.req.param();
    const user = c.get('user')!;
    const data = c.req.valid('json');

    // Get answer with championship info
    const answer = await prisma.answer.findUnique({
      where: { id },
      include: answerInclude,
    });

    if (!answer) {
      throw new NotFoundError('回答が見つかりません', ErrorCodes.ANSWER_NOT_FOUND);
    }

    // Check if user is the author
    if (answer.userId !== user.id) {
      throw new ForbiddenError('回答の投稿者のみが編集できます', ErrorCodes.NOT_OWNER);
    }

    // Check if championship is recruiting
    if (!isRecruiting(answer.championship.status, answer.championship.endAt)) {
      throw new AppError(
        ErrorCodes.INVALID_STATUS,
        '募集中の選手権の回答のみ編集できます',
        400
      );
    }

    const updated = await prisma.answer.update({
      where: { id },
      data: {
        ...(data.text !== undefined && { text: data.text }),
        ...(data.imageUrl !== undefined && { imageUrl: data.imageUrl }),
      },
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });

    return c.json(formatAnswer(updated));
  }
);

// PUT /answers/:id/award - Set award
answersRoutes.put(
  '/answers/:id/award',
  requireAuth(),
  zValidator('json', setAwardSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です', {
        ...Object.fromEntries(
          result.error.issues.map((issue) => [issue.path.join('.'), [issue.message]])
        ),
      });
    }
  }),
  async (c) => {
    const { id } = c.req.param();
    const user = c.get('user')!;
    const data = c.req.valid('json');

    // Get answer with championship info
    const answer = await prisma.answer.findUnique({
      where: { id },
      include: answerInclude,
    });

    if (!answer) {
      throw new NotFoundError('回答が見つかりません', ErrorCodes.ANSWER_NOT_FOUND);
    }

    // Check if user is the championship owner
    if (answer.championship.userId !== user.id) {
      throw new ForbiddenError('選手権の主催者のみが受賞を設定できます', ErrorCodes.NOT_OWNER);
    }

    // Check if championship is selecting
    if (!isSelecting(answer.championship.status, answer.championship.endAt)) {
      throw new AppError(
        ErrorCodes.INVALID_STATUS,
        '選定中の選手権のみ受賞を設定できます',
        400
      );
    }

    const updated = await prisma.answer.update({
      where: { id },
      data: {
        awardType: mapAwardType(data.awardType),
        awardComment: data.awardType ? data.awardComment : null,
      },
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });

    return c.json(formatAnswer(updated));
  }
);

// POST /answers/upload-url - Generate signed upload URL
answersRoutes.post(
  '/answers/upload-url',
  requireAuth(),
  zValidator('json', uploadUrlSchema, (result, c) => {
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

    const result = await generateUploadUrl(env.GCS_BUCKET_NAME, {
      fileName: data.fileName,
      contentType: data.contentType,
      userId: user.id,
    });

    return c.json(result);
  }
);

export { answersRoutes };
