import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Hono } from 'hono';
import { championshipsRoutes } from './championships';
import { errorHandler } from '../middleware/error-handler';
import { ChampionshipStatus } from '@prisma/client';

// Mock prisma
vi.mock('../lib/prisma', () => ({
  prisma: {
    championship: {
      findUnique: vi.fn(),
      findMany: vi.fn(),
      count: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
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

describe('Championships Routes', () => {
  const mockUser = {
    id: 'user-123',
    firebaseUid: 'firebase-uid-123',
    displayName: 'Test User',
  };

  const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 1 week from now
  const pastDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // 1 week ago

  const mockChampionship = {
    id: 'champ-123',
    userId: 'user-123',
    title: 'Test Championship',
    description: 'Test Description',
    status: ChampionshipStatus.RECRUITING,
    startAt: new Date('2024-01-01'),
    endAt: futureDate,
    summaryComment: null,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
    user: {
      id: 'user-123',
      displayName: 'Test User',
      avatarUrl: null,
    },
    _count: {
      answers: 10,
    },
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('GET /championships', () => {
    it('should return championships list with pagination', async () => {
      vi.mocked(prisma.championship.findMany).mockResolvedValue([mockChampionship] as any);
      vi.mocked(prisma.championship.count).mockResolvedValue(1);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships?page=1&limit=20');
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.items).toHaveLength(1);
      expect(body.pagination.page).toBe(1);
      expect(body.pagination.total).toBe(1);
    });

    it('should filter championships by status', async () => {
      vi.mocked(prisma.championship.findMany).mockResolvedValue([]);
      vi.mocked(prisma.championship.count).mockResolvedValue(0);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      await app.request('/championships?status=recruiting');
      expect(prisma.championship.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            status: ChampionshipStatus.RECRUITING,
          }),
        })
      );
    });

    it('should sort championships by newest', async () => {
      vi.mocked(prisma.championship.findMany).mockResolvedValue([]);
      vi.mocked(prisma.championship.count).mockResolvedValue(0);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      await app.request('/championships?sort=newest');
      expect(prisma.championship.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          orderBy: { createdAt: 'desc' },
        })
      );
    });
  });

  describe('GET /championships/:id', () => {
    it('should return championship details', async () => {
      vi.mocked(prisma.championship.findUnique).mockResolvedValue({
        ...mockChampionship,
        answers: [],
      } as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships/champ-123');
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.id).toBe('champ-123');
      expect(body.title).toBe('Test Championship');
    });

    it('should return 404 when championship not found', async () => {
      vi.mocked(prisma.championship.findUnique).mockResolvedValue(null);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships/non-existent');
      expect(res.status).toBe(404);
      const body = await res.json();
      expect(body.error.code).toBe('CHAMPIONSHIP_NOT_FOUND');
    });

    it('should compute status as selecting when endAt has passed', async () => {
      vi.mocked(prisma.championship.findUnique).mockResolvedValue({
        ...mockChampionship,
        endAt: pastDate,
        answers: [],
      } as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships/champ-123');
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.status).toBe('selecting');
    });
  });

  describe('POST /championships', () => {
    it('should create a new championship', async () => {
      vi.mocked(prisma.championship.create).mockResolvedValue({
        ...mockChampionship,
        user: {
          id: 'user-123',
          displayName: 'Test User',
          avatarUrl: null,
        },
        _count: { answers: 0 },
        answers: [],
      } as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify(mockUser),
        },
        body: JSON.stringify({
          title: 'New Championship',
          description: 'New Description',
          durationDays: 7,
        }),
      });
      expect(res.status).toBe(201);
      expect(prisma.championship.create).toHaveBeenCalled();
    });

    it('should return 400 when title exceeds 50 characters', async () => {
      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify(mockUser),
        },
        body: JSON.stringify({
          title: 'a'.repeat(51),
          description: 'Description',
          durationDays: 7,
        }),
      });
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should return 400 when durationDays exceeds 14', async () => {
      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify(mockUser),
        },
        body: JSON.stringify({
          title: 'Title',
          description: 'Description',
          durationDays: 15,
        }),
      });
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('PUT /championships/:id/force-end', () => {
    it('should force end a championship', async () => {
      vi.mocked(prisma.championship.findUnique).mockResolvedValue(mockChampionship as any);
      vi.mocked(prisma.championship.update).mockResolvedValue({
        ...mockChampionship,
        status: ChampionshipStatus.SELECTING,
        endAt: new Date(),
      } as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships/champ-123/force-end', {
        method: 'PUT',
        headers: {
          'X-Mock-User': JSON.stringify(mockUser),
        },
      });
      expect(res.status).toBe(200);
      expect(prisma.championship.update).toHaveBeenCalledWith({
        where: { id: 'champ-123' },
        data: expect.objectContaining({
          status: ChampionshipStatus.SELECTING,
        }),
        include: expect.any(Object),
      });
    });

    it('should return 403 when user is not the owner', async () => {
      vi.mocked(prisma.championship.findUnique).mockResolvedValue(mockChampionship as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships/champ-123/force-end', {
        method: 'PUT',
        headers: {
          'X-Mock-User': JSON.stringify({ ...mockUser, id: 'other-user' }),
        },
      });
      expect(res.status).toBe(403);
      const body = await res.json();
      expect(body.error.code).toBe('NOT_OWNER');
    });

    it('should return 404 when championship not found', async () => {
      vi.mocked(prisma.championship.findUnique).mockResolvedValue(null);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships/non-existent/force-end', {
        method: 'PUT',
        headers: {
          'X-Mock-User': JSON.stringify(mockUser),
        },
      });
      expect(res.status).toBe(404);
      const body = await res.json();
      expect(body.error.code).toBe('CHAMPIONSHIP_NOT_FOUND');
    });
  });

  describe('PUT /championships/:id/publish-result', () => {
    it('should publish championship result', async () => {
      const selectingChampionship = {
        ...mockChampionship,
        status: ChampionshipStatus.SELECTING,
      };
      vi.mocked(prisma.championship.findUnique).mockResolvedValue(selectingChampionship as any);
      vi.mocked(prisma.championship.update).mockResolvedValue({
        ...selectingChampionship,
        status: ChampionshipStatus.ANNOUNCED,
        summaryComment: 'Great championship!',
      } as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships/champ-123/publish-result', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify(mockUser),
        },
        body: JSON.stringify({
          summaryComment: 'Great championship!',
        }),
      });
      expect(res.status).toBe(200);
      expect(prisma.championship.update).toHaveBeenCalledWith({
        where: { id: 'champ-123' },
        data: expect.objectContaining({
          status: ChampionshipStatus.ANNOUNCED,
          summaryComment: 'Great championship!',
        }),
        include: expect.any(Object),
      });
    });

    it('should return 400 when championship is not in selecting status', async () => {
      vi.mocked(prisma.championship.findUnique).mockResolvedValue(mockChampionship as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships/champ-123/publish-result', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify(mockUser),
        },
        body: JSON.stringify({}),
      });
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error.code).toBe('INVALID_STATUS');
    });

    it('should return 403 when user is not the owner', async () => {
      const selectingChampionship = {
        ...mockChampionship,
        status: ChampionshipStatus.SELECTING,
      };
      vi.mocked(prisma.championship.findUnique).mockResolvedValue(selectingChampionship as any);

      const app = new Hono();
      app.onError(errorHandler);
      app.route('/championships', championshipsRoutes);

      const res = await app.request('/championships/champ-123/publish-result', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Mock-User': JSON.stringify({ ...mockUser, id: 'other-user' }),
        },
        body: JSON.stringify({}),
      });
      expect(res.status).toBe(403);
      const body = await res.json();
      expect(body.error.code).toBe('NOT_OWNER');
    });
  });
});
