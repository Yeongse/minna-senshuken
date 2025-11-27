import { Context } from 'hono';
import { ZodError } from 'zod';
import { AppError, ErrorCodes, type ErrorResponseBody } from '../lib/errors';

export function errorHandler(err: Error, c: Context) {
  // Log error for debugging
  console.error('Error:', err);

  // Handle AppError
  if (err instanceof AppError) {
    return c.json(err.toJSON(), err.statusCode as 400 | 401 | 403 | 404 | 409 | 500);
  }

  // Handle Zod validation errors
  if (err instanceof ZodError) {
    const details: Record<string, string[]> = {};
    for (const issue of err.issues) {
      const path = issue.path.join('.');
      if (!details[path]) {
        details[path] = [];
      }
      details[path]!.push(issue.message);
    }

    const response: ErrorResponseBody = {
      error: {
        code: ErrorCodes.VALIDATION_ERROR,
        message: '入力値が不正です',
        details,
      },
    };

    return c.json(response, 400);
  }

  // Handle unknown errors
  const response: ErrorResponseBody = {
    error: {
      code: ErrorCodes.INTERNAL_ERROR,
      message: 'サーバーエラーが発生しました',
    },
  };

  return c.json(response, 500);
}
