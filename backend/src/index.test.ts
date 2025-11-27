import { describe, it, expect, vi, beforeEach } from 'vitest';
import { app } from './index';

// Mock all dependencies for integration tests
vi.mock('./lib/prisma', () => ({
  prisma: {
    championship: {
      findUnique: vi.fn(),
      findMany: vi.fn(),
      count: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    answer: {
      findUnique: vi.fn(),
      findMany: vi.fn(),
      count: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    user: {
      findUnique: vi.fn(),
      create: vi.fn(),
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

vi.mock('./lib/firebase', () => ({
  getAuth: vi.fn(() => ({
    verifyIdToken: vi.fn(),
  })),
  initializeFirebase: vi.fn(),
}));

vi.mock('./lib/storage', () => ({
  generateUploadUrl: vi.fn(),
}));

vi.mock('./config/env', () => ({
  env: {
    DATABASE_URL: 'test',
    FIREBASE_PROJECT_ID: 'test',
    GCS_BUCKET_NAME: 'test-bucket',
    PORT: '8080',
  },
  loadEnv: vi.fn(),
}));

beforeEach(() => {
  vi.clearAllMocks();
});

describe('Health check endpoint', () => {
  it('should return status ok', async () => {
    const res = await app.request('/health');
    expect(res.status).toBe(200);

    const json = await res.json();
    expect(json.status).toBe('ok');
    expect(json.timestamp).toBeDefined();
  });
});

describe('Root endpoint', () => {
  it('should return API message', async () => {
    const res = await app.request('/');
    expect(res.status).toBe(200);

    const json = await res.json();
    expect(json.message).toBe('みんなの選手権 API');
  });
});

describe('API Routes Integration', () => {
  describe('Championships Routes', () => {
    it('GET /championships should be accessible', async () => {
      const { prisma } = await import('./lib/prisma');
      vi.mocked(prisma.championship.findMany).mockResolvedValue([]);
      vi.mocked(prisma.championship.count).mockResolvedValue(0);

      const res = await app.request('/championships');
      expect(res.status).toBe(200);
      const json = await res.json();
      expect(json.items).toEqual([]);
      expect(json.pagination).toBeDefined();
    });
  });

  describe('Error Handling', () => {
    it('should return 404 for non-existent championship', async () => {
      const { prisma } = await import('./lib/prisma');
      vi.mocked(prisma.championship.findUnique).mockResolvedValue(null);

      const res = await app.request('/championships/non-existent');
      expect(res.status).toBe(404);
      const json = await res.json();
      expect(json.error.code).toBe('CHAMPIONSHIP_NOT_FOUND');
    });

    it('should return consistent error format', async () => {
      const { prisma } = await import('./lib/prisma');
      vi.mocked(prisma.championship.findUnique).mockResolvedValue(null);

      const res = await app.request('/championships/non-existent');
      const json = await res.json();

      expect(json.error).toBeDefined();
      expect(json.error.code).toBeDefined();
      expect(json.error.message).toBeDefined();
    });
  });
});
