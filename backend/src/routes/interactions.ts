import { Hono } from 'hono';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';
import { Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { requireAuth, optionalAuth, type AuthUser } from '../middleware/auth';
import { ErrorCodes, NotFoundError, ConflictError, ValidationError } from '../lib/errors';
import { paginationSchema, createPaginatedResult, calculateSkip } from '../lib/pagination';

type Variables = { user: AuthUser | null };

const interactionsRoutes = new Hono<{ Variables: Variables }>();

// Validation schemas
const createCommentSchema = z.object({
  text: z.string().min(1).max(200),
});

// POST /answers/:id/like - Add like to answer
interactionsRoutes.post(
  '/answers/:id/like',
  requireAuth(),
  async (c) => {
    const { id: answerId } = c.req.param();
    const user = c.get('user')!;

    // Check if answer exists
    const answer = await prisma.answer.findUnique({
      where: { id: answerId },
    });

    if (!answer) {
      throw new NotFoundError('回答が見つかりません', ErrorCodes.ANSWER_NOT_FOUND);
    }

    try {
      // Create like and increment count in transaction
      const like = await prisma.like.create({
        data: {
          answerId,
          userId: user.id,
        },
      });

      // Increment like count
      await prisma.answer.update({
        where: { id: answerId },
        data: { likeCount: { increment: 1 } },
      });

      return c.json({
        id: like.id,
        answerId: like.answerId,
        userId: like.userId,
        createdAt: like.createdAt,
      }, 201);
    } catch (error) {
      // Handle unique constraint violation (already liked)
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictError('既にいいねしています', ErrorCodes.ALREADY_LIKED);
      }
      throw error;
    }
  }
);

// GET /answers/:id/comments - List comments
interactionsRoutes.get(
  '/answers/:id/comments',
  optionalAuth(),
  zValidator('query', paginationSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です');
    }
  }),
  async (c) => {
    const { id: answerId } = c.req.param();
    const params = c.req.valid('query');

    // Check if answer exists
    const answer = await prisma.answer.findUnique({
      where: { id: answerId },
    });

    if (!answer) {
      throw new NotFoundError('回答が見つかりません', ErrorCodes.ANSWER_NOT_FOUND);
    }

    const [comments, total] = await Promise.all([
      prisma.comment.findMany({
        where: { answerId },
        orderBy: { createdAt: 'asc' },
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
      prisma.comment.count({ where: { answerId } }),
    ]);

    const items = comments.map((c) => ({
      id: c.id,
      answerId: c.answerId,
      userId: c.userId,
      text: c.text,
      createdAt: c.createdAt,
      user: c.user,
    }));

    return c.json(createPaginatedResult(items, total, params));
  }
);

// POST /answers/:id/comments - Create comment
interactionsRoutes.post(
  '/answers/:id/comments',
  requireAuth(),
  zValidator('json', createCommentSchema, (result, c) => {
    if (!result.success) {
      throw new ValidationError('入力値が不正です', {
        ...Object.fromEntries(
          result.error.issues.map((issue) => [issue.path.join('.'), [issue.message]])
        ),
      });
    }
  }),
  async (c) => {
    const { id: answerId } = c.req.param();
    const user = c.get('user')!;
    const data = c.req.valid('json');

    // Check if answer exists
    const answer = await prisma.answer.findUnique({
      where: { id: answerId },
    });

    if (!answer) {
      throw new NotFoundError('回答が見つかりません', ErrorCodes.ANSWER_NOT_FOUND);
    }

    // Create comment
    const comment = await prisma.comment.create({
      data: {
        answerId,
        userId: user.id,
        text: data.text,
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

    // Increment comment count
    await prisma.answer.update({
      where: { id: answerId },
      data: { commentCount: { increment: 1 } },
    });

    return c.json({
      id: comment.id,
      answerId: comment.answerId,
      userId: comment.userId,
      text: comment.text,
      createdAt: comment.createdAt,
      user: comment.user,
    }, 201);
  }
);

export { interactionsRoutes };
