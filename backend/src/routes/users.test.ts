import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Hono } from 'hono';
import { usersRoutes } from './users';
import { errorHandler } from '../middleware/error-handler';

// Mock prisma
vi.mock('../lib/prisma', () => ({
  prisma: {
    user: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    championship: {
      findMany: vi.fn(),
      count: vi.fn(),
    },
    answer: {
      findMany: vi.fn(),
      count: vi.fn(),
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
    c.set('user', null);
    await next();
  }),
}));

import { prisma } from '../lib/prisma';

describe('Users Routes', () => {
  const mockUser = {
    id: 'user-123',
    firebaseUid: 'firebase-uid-123',
    displayName: 'Test User',
    avatarUrl: 'https://example.com/avatar.png',
    bio: 'Test bio',
    twitterUrl: 'https://twitter.com/testuser',
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('GET /users/:id', () => {
    it('should return user profile', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(mockUser);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/users', usersRoutes);

      const res = await app.request('/users/user-123');
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.id).toBe('user-123');
      expect(body.displayName).toBe('Test User');
    });

    it('should return 404 when user not found', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/users', usersRoutes);

      const res = await app.request('/users/non-existent-user');
      expect(res.status).toBe(404);
      const body = await res.json();
      expect(body.error.code).toBe('USER_NOT_FOUND');
    });
  });

  describe('PATCH /users/me', () => {
    it('should update user profile', async () => {
      const updatedUser = {
        ...mockUser,
        displayName: 'Updated Name',
        bio: 'Updated bio',
      };
      vi.mocked(prisma.user.update).mockResolvedValue(updatedUser);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/users', usersRoutes);

      const res = await app.request('/users/me', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify({
            id: 'user-123',
            firebaseUid: 'firebase-uid-123',
            displayName: 'Test User',
          }),
        },
        body: JSON.stringify({
          displayName: 'Updated Name',
          bio: 'Updated bio',
        }),
      });
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.displayName).toBe('Updated Name');
      expect(body.bio).toBe('Updated bio');
    });

    it('should return 400 when displayName exceeds 30 characters', async () => {
      const app = new Hono();
      app.onError(errorHandler);
      app.route('/users', usersRoutes);

      const res = await app.request('/users/me', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify({
            id: 'user-123',
            firebaseUid: 'firebase-uid-123',
            displayName: 'Test User',
          }),
        },
        body: JSON.stringify({
          displayName: 'a'.repeat(31),
        }),
      });
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should return 400 when bio exceeds 200 characters', async () => {
      const app = new Hono();
      app.onError(errorHandler);
      app.route('/users', usersRoutes);

      const res = await app.request('/users/me', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify({
            id: 'user-123',
            firebaseUid: 'firebase-uid-123',
            displayName: 'Test User',
          }),
        },
        body: JSON.stringify({
          bio: 'a'.repeat(201),
        }),
      });
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('GET /users/:id/championships', () => {
    it('should return user championships with pagination', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(mockUser);
      vi.mocked(prisma.championship.findMany).mockResolvedValue([
        {
          id: 'champ-1',
          userId: 'user-123',
          title: 'Championship 1',
          description: 'Description 1',
          status: 'RECRUITING',
          startAt: new Date('2024-01-01'),
          endAt: new Date('2025-01-15'),
          summaryComment: null,
          createdAt: new Date('2024-01-01'),
          updatedAt: new Date('2024-01-01'),
          _count: { answers: 5 },
        },
      ] as any);
      vi.mocked(prisma.championship.count).mockResolvedValue(1);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/users', usersRoutes);

      const res = await app.request('/users/user-123/championships?page=1&limit=20');
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.items).toHaveLength(1);
      expect(body.pagination.page).toBe(1);
      expect(body.pagination.limit).toBe(20);
      expect(body.pagination.total).toBe(1);
    });

    it('should return 404 when user not found', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/users', usersRoutes);

      const res = await app.request('/users/non-existent-user/championships');
      expect(res.status).toBe(404);
      const body = await res.json();
      expect(body.error.code).toBe('USER_NOT_FOUND');
    });
  });

  describe('GET /users/:id/answers', () => {
    it('should return user answers with pagination', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(mockUser);
      vi.mocked(prisma.answer.findMany).mockResolvedValue([
        {
          id: 'answer-1',
          championshipId: 'champ-1',
          userId: 'user-123',
          text: 'Answer text',
          imageUrl: null,
          awardType: null,
          awardComment: null,
          likeCount: 5,
          commentCount: 2,
          createdAt: new Date('2024-01-01'),
          updatedAt: new Date('2024-01-01'),
          championship: {
            id: 'champ-1',
            title: 'Championship 1',
          },
        },
      ] as any);
      vi.mocked(prisma.answer.count).mockResolvedValue(1);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/users', usersRoutes);

      const res = await app.request('/users/user-123/answers?page=1&limit=20');
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.items).toHaveLength(1);
      expect(body.pagination.page).toBe(1);
    });

    it('should return 404 when user not found', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/users', usersRoutes);

      const res = await app.request('/users/non-existent-user/answers');
      expect(res.status).toBe(404);
      const body = await res.json();
      expect(body.error.code).toBe('USER_NOT_FOUND');
    });
  });
});
