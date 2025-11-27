import type { MiddlewareHandler } from 'hono';
import { getAuth } from '../lib/firebase';
import { prisma } from '../lib/prisma';
import { ErrorCodes, UnauthorizedError } from '../lib/errors';

export interface AuthUser {
  id: string;
  firebaseUid: string;
  displayName: string;
}

/**
 * Extract Bearer token from Authorization header
 */
function extractToken(authHeader: string | undefined): string | null {
  if (!authHeader) return null;
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') return null;
  return parts[1] || null;
}

/**
 * Verify Firebase ID token and find or create user
 */
async function verifyAndGetUser(token: string): Promise<AuthUser> {
  const auth = getAuth();

  let decodedToken;
  try {
    decodedToken = await auth.verifyIdToken(token);
  } catch (error: any) {
    if (error.code === 'auth/id-token-expired') {
      throw new UnauthorizedError('トークンの有効期限が切れています', ErrorCodes.TOKEN_EXPIRED);
    }
    throw new UnauthorizedError('無効なトークンです', ErrorCodes.INVALID_TOKEN);
  }

  // Find or create user
  let user = await prisma.user.findUnique({
    where: { firebaseUid: decodedToken.uid },
  });

  if (!user) {
    user = await prisma.user.create({
      data: {
        firebaseUid: decodedToken.uid,
        displayName: decodedToken.name || 'ユーザー',
      },
    });
  }

  return {
    id: user.id,
    firebaseUid: user.firebaseUid,
    displayName: user.displayName,
  };
}

/**
 * Required authentication middleware
 * Returns 401 if no valid token is provided
 */
export function requireAuth(): MiddlewareHandler<{ Variables: { user: AuthUser } }> {
  return async (c, next) => {
    const authHeader = c.req.header('Authorization');
    const token = extractToken(authHeader);

    if (!token) {
      throw new UnauthorizedError('認証が必要です', ErrorCodes.UNAUTHORIZED);
    }

    const user = await verifyAndGetUser(token);
    c.set('user', user);
    await next();
  };
}

/**
 * Optional authentication middleware
 * Sets user to null if no token or invalid token
 */
export function optionalAuth(): MiddlewareHandler<{ Variables: { user: AuthUser | null } }> {
  return async (c, next) => {
    const authHeader = c.req.header('Authorization');
    const token = extractToken(authHeader);

    if (!token) {
      c.set('user', null);
      await next();
      return;
    }

    try {
      const user = await verifyAndGetUser(token);
      c.set('user', user);
    } catch {
      c.set('user', null);
    }

    await next();
  };
}
