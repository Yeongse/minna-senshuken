import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Hono } from 'hono';
import { interactionsRoutes } from './interactions';
import { errorHandler } from '../middleware/error-handler';
import { Prisma } from '@prisma/client';

// Mock prisma
vi.mock('../lib/prisma', () => ({
  prisma: {
    answer: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    like: {
      create: vi.fn(),
    },
    comment: {
      findMany: vi.fn(),
      count: vi.fn(),
      create: vi.fn(),
    },
  },
}));

// Mock auth middleware
vi.mock('../middleware/auth', () => ({
  requireAuth: vi.fn(() => async (c: any, next: any) => {
    const mockUser = c.req.header('X-Mock-User');
    if (mockUser) {
      c.set('user', JSON.parse(mockUser));
    }
    await next();
  }),
  optionalAuth: vi.fn(() => async (c: any, next: any) => {
    const mockUser = c.req.header('X-Mock-User');
    if (mockUser) {
      c.set('user', JSON.parse(mockUser));
    } else {
      c.set('user', null);
    }
    await next();
  }),
}));

import { prisma } from '../lib/prisma';

describe('Interactions Routes', () => {
  const mockUser = {
    id: 'user-123',
    firebaseUid: 'firebase-uid-123',
    displayName: 'Test User',
  };

  const mockAnswer = {
    id: 'answer-123',
    championshipId: 'champ-123',
    userId: 'user-456',
    text: 'Test Answer',
    imageUrl: null,
    awardType: null,
    awardComment: null,
    likeCount: 5,
    commentCount: 3,
    createdAt: new Date('2024-01-02'),
    updatedAt: new Date('2024-01-02'),
  };

  const mockLike = {
    id: 'like-123',
    answerId: 'answer-123',
    userId: 'user-123',
    createdAt: new Date('2024-01-03'),
  };

  const mockComment = {
    id: 'comment-123',
    answerId: 'answer-123',
    userId: 'user-123',
    text: 'Great answer!',
    createdAt: new Date('2024-01-03'),
    user: {
      id: 'user-123',
      displayName: 'Test User',
      avatarUrl: null,
    },
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('POST /answers/:id/like', () => {
    it('should add a like to an answer', async () => {
      vi.mocked(prisma.answer.findUnique).mockResolvedValue(mockAnswer as any);
      vi.mocked(prisma.like.create).mockResolvedValue(mockLike as any);
      vi.mocked(prisma.answer.update).mockResolvedValue({
        ...mockAnswer,
        likeCount: 6,
      } as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/', interactionsRoutes);

      const res = await app.request('/answers/answer-123/like', {
        method: 'POST',
        headers: {
          'X-Mock-User': JSON.stringify(mockUser),
        },
      });
      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.id).toBe('like-123');
      expect(prisma.like.create).toHaveBeenCalled();
      expect(prisma.answer.update).toHaveBeenCalledWith({
        where: { id: 'answer-123' },
        data: { likeCount: { increment: 1 } },
      });
    });

    it('should return 404 when answer not found', async () => {
      vi.mocked(prisma.answer.findUnique).mockResolvedValue(null);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/', interactionsRoutes);

      const res = await app.request('/answers/non-existent/like', {
        method: 'POST',
        headers: {
          'X-Mock-User': JSON.stringify(mockUser),
        },
      });
      expect(res.status).toBe(404);
      const body = await res.json();
      expect(body.error.code).toBe('ANSWER_NOT_FOUND');
    });

    it('should return 409 when user already liked', async () => {
      vi.mocked(prisma.answer.findUnique).mockResolvedValue(mockAnswer as any);

      // Prisma unique constraint error
      const prismaError = new Prisma.PrismaClientKnownRequestError(
        'Unique constraint failed',
        { code: 'P2002', clientVersion: '5.22.0' }
      );
      vi.mocked(prisma.like.create).mockRejectedValue(prismaError);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/', interactionsRoutes);

      const res = await app.request('/answers/answer-123/like', {
        method: 'POST',
        headers: {
          'X-Mock-User': JSON.stringify(mockUser),
        },
      });
      expect(res.status).toBe(409);
      const body = await res.json();
      expect(body.error.code).toBe('ALREADY_LIKED');
    });
  });

  describe('GET /answers/:id/comments', () => {
    it('should return comments list with pagination', async () => {
      vi.mocked(prisma.answer.findUnique).mockResolvedValue(mockAnswer as any);
      vi.mocked(prisma.comment.findMany).mockResolvedValue([mockComment] as any);
      vi.mocked(prisma.comment.count).mockResolvedValue(1);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/', interactionsRoutes);

      const res = await app.request('/answers/answer-123/comments?page=1&limit=20');
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.items).toHaveLength(1);
      expect(body.items[0].id).toBe('comment-123');
      expect(body.items[0].text).toBe('Great answer!');
      expect(body.pagination.page).toBe(1);
      expect(body.pagination.total).toBe(1);
    });

    it('should sort comments by createdAt ascending (oldest first)', async () => {
      vi.mocked(prisma.answer.findUnique).mockResolvedValue(mockAnswer as any);
      vi.mocked(prisma.comment.findMany).mockResolvedValue([]);
      vi.mocked(prisma.comment.count).mockResolvedValue(0);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/', interactionsRoutes);

      await app.request('/answers/answer-123/comments');
      expect(prisma.comment.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          orderBy: { createdAt: 'asc' },
        })
      );
    });

    it('should return 404 when answer not found', async () => {
      vi.mocked(prisma.answer.findUnique).mockResolvedValue(null);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/', interactionsRoutes);

      const res = await app.request('/answers/non-existent/comments');
      expect(res.status).toBe(404);
      const body = await res.json();
      expect(body.error.code).toBe('ANSWER_NOT_FOUND');
    });
  });

  describe('POST /answers/:id/comments', () => {
    it('should create a new comment', async () => {
      vi.mocked(prisma.answer.findUnique).mockResolvedValue(mockAnswer as any);
      vi.mocked(prisma.comment.create).mockResolvedValue(mockComment as any);
      vi.mocked(prisma.answer.update).mockResolvedValue({
        ...mockAnswer,
        commentCount: 4,
      } as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/', interactionsRoutes);

      const res = await app.request('/answers/answer-123/comments', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify(mockUser),
        },
        body: JSON.stringify({
          text: 'Great answer!',
        }),
      });
      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.id).toBe('comment-123');
      expect(body.text).toBe('Great answer!');
      expect(prisma.comment.create).toHaveBeenCalled();
      expect(prisma.answer.update).toHaveBeenCalledWith({
        where: { id: 'answer-123' },
        data: { commentCount: { increment: 1 } },
      });
    });

    it('should return 400 when text exceeds 200 characters', async () => {
      vi.mocked(prisma.answer.findUnique).mockResolvedValue(mockAnswer as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/', interactionsRoutes);

      const res = await app.request('/answers/answer-123/comments', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify(mockUser),
        },
        body: JSON.stringify({
          text: 'a'.repeat(201),
        }),
      });
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should return 404 when answer not found', async () => {
      vi.mocked(prisma.answer.findUnique).mockResolvedValue(null);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/', interactionsRoutes);

      const res = await app.request('/answers/non-existent/comments', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify(mockUser),
        },
        body: JSON.stringify({
          text: 'Great answer!',
        }),
      });
      expect(res.status).toBe(404);
      const body = await res.json();
      expect(body.error.code).toBe('ANSWER_NOT_FOUND');
    });
  });
});
