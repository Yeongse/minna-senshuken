import { describe, it, expect } from 'vitest';
import { Hono } from 'hono';
import { z } from 'zod';
import { errorHandler } from './error-handler';
import {
  AppError,
  ErrorCodes,
  NotFoundError,
  ValidationError,
} from '../lib/errors';

function createTestApp() {
  const app = new Hono();
  app.onError(errorHandler);
  return app;
}

describe('errorHandler', () => {
  describe('AppError handling', () => {
    it('should return error response with correct status code', async () => {
      const app = createTestApp();
      app.get('/not-found', () => {
        throw new NotFoundError('選手権が見つかりません', ErrorCodes.CHAMPIONSHIP_NOT_FOUND);
      });

      const res = await app.request('/not-found');
      expect(res.status).toBe(404);

      const json = await res.json();
      expect(json.error.code).toBe(ErrorCodes.CHAMPIONSHIP_NOT_FOUND);
      expect(json.error.message).toBe('選手権が見つかりません');
    });

    it('should include details in response when provided', async () => {
      const app = createTestApp();
      app.get('/validation', () => {
        throw new ValidationError('入力エラー', {
          title: ['必須項目です'],
        });
      });

      const res = await app.request('/validation');
      expect(res.status).toBe(400);

      const json = await res.json();
      expect(json.error.details).toEqual({ title: ['必須項目です'] });
    });
  });

  describe('ZodError handling', () => {
    it('should convert ZodError to 400 response with details', async () => {
      const app = createTestApp();
      const schema = z.object({
        title: z.string().min(1, '必須項目です'),
        count: z.number().min(0, '0以上を入力してください'),
      });

      app.get('/zod-error', () => {
        schema.parse({ title: '', count: -1 });
      });

      const res = await app.request('/zod-error');
      expect(res.status).toBe(400);

      const json = await res.json();
      expect(json.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
      expect(json.error.message).toBe('入力値が不正です');
      expect(json.error.details.title).toContain('必須項目です');
      expect(json.error.details.count).toContain('0以上を入力してください');
    });
  });

  describe('Unknown error handling', () => {
    it('should return 500 for unknown errors', async () => {
      const app = createTestApp();
      app.get('/unknown', () => {
        throw new Error('Something went wrong');
      });

      const res = await app.request('/unknown');
      expect(res.status).toBe(500);

      const json = await res.json();
      expect(json.error.code).toBe(ErrorCodes.INTERNAL_ERROR);
      expect(json.error.message).toBe('サーバーエラーが発生しました');
    });
  });
});
