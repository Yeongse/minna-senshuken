import { describe, it, expect } from 'vitest';
import {
  AppError,
  ErrorCodes,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ValidationError,
  ConflictError,
  InternalError,
} from './errors';

describe('AppError', () => {
  it('should create error with code, message and status', () => {
    const error = new AppError(ErrorCodes.NOT_FOUND, 'Item not found', 404);
    expect(error.code).toBe(ErrorCodes.NOT_FOUND);
    expect(error.message).toBe('Item not found');
    expect(error.statusCode).toBe(404);
  });

  it('should convert to JSON with error structure', () => {
    const error = new AppError(ErrorCodes.VALIDATION_ERROR, 'Invalid input', 400, {
      title: ['タイトルは必須です'],
    });
    const json = error.toJSON();
    expect(json.error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(json.error.message).toBe('Invalid input');
    expect(json.error.details).toEqual({ title: ['タイトルは必須です'] });
  });
});

describe('UnauthorizedError', () => {
  it('should create 401 error', () => {
    const error = new UnauthorizedError();
    expect(error.statusCode).toBe(401);
    expect(error.code).toBe(ErrorCodes.UNAUTHORIZED);
  });

  it('should support custom message and code', () => {
    const error = new UnauthorizedError('トークンが無効です', ErrorCodes.INVALID_TOKEN);
    expect(error.message).toBe('トークンが無効です');
    expect(error.code).toBe(ErrorCodes.INVALID_TOKEN);
  });
});

describe('ForbiddenError', () => {
  it('should create 403 error', () => {
    const error = new ForbiddenError();
    expect(error.statusCode).toBe(403);
    expect(error.code).toBe(ErrorCodes.FORBIDDEN);
  });
});

describe('NotFoundError', () => {
  it('should create 404 error', () => {
    const error = new NotFoundError();
    expect(error.statusCode).toBe(404);
    expect(error.code).toBe(ErrorCodes.NOT_FOUND);
  });
});

describe('ValidationError', () => {
  it('should create 400 error with details', () => {
    const error = new ValidationError('入力エラー', {
      title: ['50文字以内で入力してください'],
      description: ['必須項目です'],
    });
    expect(error.statusCode).toBe(400);
    expect(error.code).toBe(ErrorCodes.VALIDATION_ERROR);
    expect(error.details).toEqual({
      title: ['50文字以内で入力してください'],
      description: ['必須項目です'],
    });
  });
});

describe('ConflictError', () => {
  it('should create 409 error', () => {
    const error = new ConflictError('既にいいね済みです');
    expect(error.statusCode).toBe(409);
    expect(error.code).toBe(ErrorCodes.ALREADY_LIKED);
  });
});

describe('InternalError', () => {
  it('should create 500 error', () => {
    const error = new InternalError();
    expect(error.statusCode).toBe(500);
    expect(error.code).toBe(ErrorCodes.INTERNAL_ERROR);
  });
});
