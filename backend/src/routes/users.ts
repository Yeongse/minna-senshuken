import { Hono } from 'hono';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';
import { prisma } from '../lib/prisma';
import { requireAuth, type AuthUser } from '../middleware/auth';
import { ErrorCodes, NotFoundError, ValidationError } from '../lib/errors';
import { paginationSchema, createPaginatedResult, calculateSkip } from '../lib/pagination';
import { computeChampionshipStatus } from '../lib/championship-status';

type Variables = { user: AuthUser };

const usersRoutes = new Hono<{ Variables: Variables }>();

// Validation schemas
const updateProfileSchema = z.object({
  displayName: z.string().min(1).max(30).optional(),
  bio: z.string().max(200).optional(),
  avatarUrl: z.string().url().optional().nullable(),
  twitterUrl: z.string().url().optional().nullable(),
});

// GET /users/:id - Get user profile
usersRoutes.get('/:id', async (c) => {
  const { id } = c.req.param();

  const user = await prisma.user.findUnique({
    where: { id },
  });

  if (!user) {
    throw new NotFoundError('ユーザーが見つかりません', ErrorCodes.USER_NOT_FOUND);
  }

  return c.json({
    id: user.id,
    displayName: user.displayName,
    avatarUrl: user.avatarUrl,
    bio: user.bio,
    twitterUrl: user.twitterUrl,
    createdAt: user.createdAt,
  });
});

// PATCH /users/me - Update own profile
usersRoutes.patch(
  '/me',
  requireAuth(),
  zValidator('json', updateProfileSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です', {
        ...Object.fromEntries(
          result.error.issues.map((issue) => [issue.path.join('.'), [issue.message]])
        ),
      });
    }
  }),
  async (c) => {
    const user = c.get('user');
    const data = c.req.valid('json');

    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: {
        ...(data.displayName !== undefined && { displayName: data.displayName }),
        ...(data.bio !== undefined && { bio: data.bio }),
        ...(data.avatarUrl !== undefined && { avatarUrl: data.avatarUrl }),
        ...(data.twitterUrl !== undefined && { twitterUrl: data.twitterUrl }),
      },
    });

    return c.json({
      id: updatedUser.id,
      displayName: updatedUser.displayName,
      avatarUrl: updatedUser.avatarUrl,
      bio: updatedUser.bio,
      twitterUrl: updatedUser.twitterUrl,
      createdAt: updatedUser.createdAt,
      updatedAt: updatedUser.updatedAt,
    });
  }
);

// GET /users/:id/championships - Get user's championships
usersRoutes.get(
  '/:id/championships',
  zValidator('query', paginationSchema),
  async (c) => {
    const { id } = c.req.param();
    const params = c.req.valid('query');

    // Check if user exists
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundError('ユーザーが見つかりません', ErrorCodes.USER_NOT_FOUND);
    }

    const [championships, total] = await Promise.all([
      prisma.championship.findMany({
        where: { userId: id },
        orderBy: { createdAt: 'desc' },
        skip: calculateSkip(params),
        take: params.limit,
        include: {
          _count: {
            select: { answers: true },
          },
        },
      }),
      prisma.championship.count({ where: { userId: id } }),
    ]);

    const items = championships.map((c) => ({
      id: c.id,
      title: c.title,
      description: c.description,
      status: computeChampionshipStatus(c.status, c.endAt),
      startAt: c.startAt,
      endAt: c.endAt,
      answerCount: c._count.answers,
      createdAt: c.createdAt,
    }));

    return c.json(createPaginatedResult(items, total, params));
  }
);

// GET /users/:id/answers - Get user's answers
usersRoutes.get(
  '/:id/answers',
  zValidator('query', paginationSchema),
  async (c) => {
    const { id } = c.req.param();
    const params = c.req.valid('query');

    // Check if user exists
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundError('ユーザーが見つかりません', ErrorCodes.USER_NOT_FOUND);
    }

    const [answers, total] = await Promise.all([
      prisma.answer.findMany({
        where: { userId: id },
        orderBy: { createdAt: 'desc' },
        skip: calculateSkip(params),
        take: params.limit,
        include: {
          championship: {
            select: {
              id: true,
              title: true,
            },
          },
        },
      }),
      prisma.answer.count({ where: { userId: id } }),
    ]);

    const items = answers.map((a) => ({
      id: a.id,
      text: a.text,
      imageUrl: a.imageUrl,
      awardType: a.awardType,
      awardComment: a.awardComment,
      likeCount: a.likeCount,
      commentCount: a.commentCount,
      createdAt: a.createdAt,
      championship: a.championship,
    }));

    return c.json(createPaginatedResult(items, total, params));
  }
);

export { usersRoutes };
