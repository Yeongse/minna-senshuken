import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Hono } from 'hono';
import { requireAuth, optionalAuth, type AuthUser } from './auth';
import { errorHandler } from './error-handler';

// Mock firebase-admin
vi.mock('../lib/firebase', () => ({
  getAuth: vi.fn(),
}));

// Mock prisma
vi.mock('../lib/prisma', () => ({
  prisma: {
    user: {
      findUnique: vi.fn(),
      create: vi.fn(),
    },
  },
}));

import { getAuth } from '../lib/firebase';
import { prisma } from '../lib/prisma';

describe('Auth Middleware', () => {
  const mockVerifyIdToken = vi.fn();
  const mockUser = {
    id: 'user-123',
    firebaseUid: 'firebase-uid-123',
    displayName: 'Test User',
    avatarUrl: null,
    bio: null,
    twitterUrl: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(getAuth).mockReturnValue({
      verifyIdToken: mockVerifyIdToken,
    } as any);
  });

  describe('requireAuth', () => {
    it('should return 401 when Authorization header is missing', async () => {
      const app = new Hono();
      app.onError(errorHandler);
      app.use('*', requireAuth());
      app.get('/test', (c) => c.json({ ok: true }));

      const res = await app.request('/test');
      expect(res.status).toBe(401);
      const body = await res.json();
      expect(body.error.code).toBe('UNAUTHORIZED');
    });

    it('should return 401 when token format is invalid', async () => {
      const app = new Hono();
      app.onError(errorHandler);
      app.use('*', requireAuth());
      app.get('/test', (c) => c.json({ ok: true }));

      const res = await app.request('/test', {
        headers: { Authorization: 'InvalidFormat token123' },
      });
      expect(res.status).toBe(401);
      const body = await res.json();
      expect(body.error.code).toBe('UNAUTHORIZED');
    });

    it('should return 401 when token is invalid', async () => {
      mockVerifyIdToken.mockRejectedValue(new Error('Invalid token'));

      const app = new Hono();
      app.onError(errorHandler);
      app.use('*', requireAuth());
      app.get('/test', (c) => c.json({ ok: true }));

      const res = await app.request('/test', {
        headers: { Authorization: 'Bearer invalid-token' },
      });
      expect(res.status).toBe(401);
      const body = await res.json();
      expect(body.error.code).toBe('INVALID_TOKEN');
    });

    it('should return 401 when token is expired', async () => {
      const expiredError = new Error('Token expired');
      (expiredError as any).code = 'auth/id-token-expired';
      mockVerifyIdToken.mockRejectedValue(expiredError);

      const app = new Hono();
      app.onError(errorHandler);
      app.use('*', requireAuth());
      app.get('/test', (c) => c.json({ ok: true }));

      const res = await app.request('/test', {
        headers: { Authorization: 'Bearer expired-token' },
      });
      expect(res.status).toBe(401);
      const body = await res.json();
      expect(body.error.code).toBe('TOKEN_EXPIRED');
    });

    it('should set user in context when token is valid', async () => {
      mockVerifyIdToken.mockResolvedValue({ uid: 'firebase-uid-123' });
      vi.mocked(prisma.user.findUnique).mockResolvedValue(mockUser);

      let capturedUser: AuthUser | null = null;
      const app = new Hono<{ Variables: { user: AuthUser } }>();
      app.use('*', requireAuth());
      app.get('/test', (c) => {
        capturedUser = c.get('user');
        return c.json({ ok: true });
      });

      const res = await app.request('/test', {
        headers: { Authorization: 'Bearer valid-token' },
      });
      expect(res.status).toBe(200);
      expect(capturedUser).toEqual({
        id: 'user-123',
        firebaseUid: 'firebase-uid-123',
        displayName: 'Test User',
      });
    });

    it('should create user if not exists', async () => {
      mockVerifyIdToken.mockResolvedValue({
        uid: 'new-firebase-uid',
        name: 'New User',
      });
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.user.create).mockResolvedValue({
        ...mockUser,
        id: 'new-user-id',
        firebaseUid: 'new-firebase-uid',
        displayName: 'New User',
      });

      const app = new Hono<{ Variables: { user: AuthUser } }>();
      app.use('*', requireAuth());
      app.get('/test', (c) => c.json({ user: c.get('user') }));

      const res = await app.request('/test', {
        headers: { Authorization: 'Bearer valid-token' },
      });
      expect(res.status).toBe(200);
      expect(prisma.user.create).toHaveBeenCalledWith({
        data: {
          firebaseUid: 'new-firebase-uid',
          displayName: 'New User',
        },
      });
    });

    it('should use default display name if Firebase name is not provided', async () => {
      mockVerifyIdToken.mockResolvedValue({
        uid: 'new-firebase-uid',
      });
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.user.create).mockResolvedValue({
        ...mockUser,
        id: 'new-user-id',
        firebaseUid: 'new-firebase-uid',
        displayName: 'ユーザー',
      });

      const app = new Hono<{ Variables: { user: AuthUser } }>();
      app.use('*', requireAuth());
      app.get('/test', (c) => c.json({ user: c.get('user') }));

      const res = await app.request('/test', {
        headers: { Authorization: 'Bearer valid-token' },
      });
      expect(res.status).toBe(200);
      expect(prisma.user.create).toHaveBeenCalledWith({
        data: {
          firebaseUid: 'new-firebase-uid',
          displayName: 'ユーザー',
        },
      });
    });
  });

  describe('optionalAuth', () => {
    it('should allow request without Authorization header', async () => {
      let capturedUser: AuthUser | null = null;
      const app = new Hono<{ Variables: { user: AuthUser | null } }>();
      app.use('*', optionalAuth());
      app.get('/test', (c) => {
        capturedUser = c.get('user');
        return c.json({ ok: true });
      });

      const res = await app.request('/test');
      expect(res.status).toBe(200);
      expect(capturedUser).toBeNull();
    });

    it('should set user when valid token is provided', async () => {
      mockVerifyIdToken.mockResolvedValue({ uid: 'firebase-uid-123' });
      vi.mocked(prisma.user.findUnique).mockResolvedValue(mockUser);

      let capturedUser: AuthUser | null = null;
      const app = new Hono<{ Variables: { user: AuthUser | null } }>();
      app.use('*', optionalAuth());
      app.get('/test', (c) => {
        capturedUser = c.get('user');
        return c.json({ ok: true });
      });

      const res = await app.request('/test', {
        headers: { Authorization: 'Bearer valid-token' },
      });
      expect(res.status).toBe(200);
      expect(capturedUser).toEqual({
        id: 'user-123',
        firebaseUid: 'firebase-uid-123',
        displayName: 'Test User',
      });
    });

    it('should set user to null when token is invalid', async () => {
      mockVerifyIdToken.mockRejectedValue(new Error('Invalid token'));

      let capturedUser: AuthUser | null = null;
      const app = new Hono<{ Variables: { user: AuthUser | null } }>();
      app.use('*', optionalAuth());
      app.get('/test', (c) => {
        capturedUser = c.get('user');
        return c.json({ ok: true });
      });

      const res = await app.request('/test', {
        headers: { Authorization: 'Bearer invalid-token' },
      });
      expect(res.status).toBe(200);
      expect(capturedUser).toBeNull();
    });
  });
});
