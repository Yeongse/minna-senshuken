export const ErrorCodes = {
  // Authentication errors (401)
  UNAUTHORIZED: 'UNAUTHORIZED',
  INVALID_TOKEN: 'INVALID_TOKEN',
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',

  // Authorization errors (403)
  FORBIDDEN: 'FORBIDDEN',
  NOT_OWNER: 'NOT_OWNER',

  // Resource errors (404)
  NOT_FOUND: 'NOT_FOUND',
  USER_NOT_FOUND: 'USER_NOT_FOUND',
  CHAMPIONSHIP_NOT_FOUND: 'CHAMPIONSHIP_NOT_FOUND',
  ANSWER_NOT_FOUND: 'ANSWER_NOT_FOUND',

  // Validation errors (400)
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INVALID_STATUS: 'INVALID_STATUS',

  // Conflict errors (409)
  ALREADY_LIKED: 'ALREADY_LIKED',

  // Server errors (500)
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];

export interface ErrorResponseBody {
  error: {
    code: ErrorCode;
    message: string;
    details?: Record<string, string[]>;
  };
}

export class AppError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly statusCode: number,
    public readonly details?: Record<string, string[]>
  ) {
    super(message);
    this.name = 'AppError';
  }

  toJSON(): ErrorResponseBody {
    return {
      error: {
        code: this.code,
        message: this.message,
        ...(this.details && { details: this.details }),
      },
    };
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = '認証が必要です', code: ErrorCode = ErrorCodes.UNAUTHORIZED) {
    super(code, message, 401);
  }
}

export class ForbiddenError extends AppError {
  constructor(message = 'このリソースへのアクセス権限がありません', code: ErrorCode = ErrorCodes.FORBIDDEN) {
    super(code, message, 403);
  }
}

export class NotFoundError extends AppError {
  constructor(message = 'リソースが見つかりません', code: ErrorCode = ErrorCodes.NOT_FOUND) {
    super(code, message, 404);
  }
}

export class ValidationError extends AppError {
  constructor(message = '入力値が不正です', details?: Record<string, string[]>) {
    super(ErrorCodes.VALIDATION_ERROR, message, 400, details);
  }
}

export class ConflictError extends AppError {
  constructor(message: string, code: ErrorCode = ErrorCodes.ALREADY_LIKED) {
    super(code, message, 409);
  }
}

export class InternalError extends AppError {
  constructor(message = 'サーバーエラーが発生しました') {
    super(ErrorCodes.INTERNAL_ERROR, message, 500);
  }
}
