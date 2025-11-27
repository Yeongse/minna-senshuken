/// API例外の基底クラス
sealed class ApiException implements Exception {
  String get message;
  String? get code;
  int? get statusCode;

  @override
  String toString() => 'ApiException: $message (code: $code, status: $statusCode)';
}

/// クライアントエラー（4xx）
class ClientException extends ApiException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final int statusCode;
  final Map<String, List<String>>? details;

  ClientException({
    required this.message,
    this.code,
    required this.statusCode,
    this.details,
  });
}

/// 認証エラー（401）
class UnauthorizedException extends ApiException {
  @override
  final String message;
  @override
  final String? code;
  @override
  int get statusCode => 401;

  UnauthorizedException({
    this.message = '認証が必要です',
    this.code,
  });
}

/// 認可エラー（403）
class ForbiddenException extends ApiException {
  @override
  final String message;
  @override
  final String? code;
  @override
  int get statusCode => 403;

  ForbiddenException({
    this.message = 'アクセス権限がありません',
    this.code,
  });
}

/// リソース不在エラー（404）
class NotFoundException extends ApiException {
  @override
  final String message;
  @override
  final String? code;
  @override
  int get statusCode => 404;

  NotFoundException({
    this.message = 'リソースが見つかりません',
    this.code,
  });
}

/// 競合エラー（409）
class ConflictException extends ApiException {
  @override
  final String message;
  @override
  final String? code;
  @override
  int get statusCode => 409;

  ConflictException({
    required this.message,
    this.code,
  });
}

/// サーバーエラー（5xx）
class ServerException extends ApiException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final int statusCode;

  ServerException({
    this.message = 'サーバーエラーが発生しました',
    this.code,
    this.statusCode = 500,
  });
}

/// ネットワークエラー
class NetworkException extends ApiException {
  @override
  final String message;
  @override
  String? get code => 'NETWORK_ERROR';
  @override
  int? get statusCode => null;

  NetworkException({
    this.message = 'ネットワーク接続に失敗しました',
  });
}

/// タイムアウトエラー
class ApiTimeoutException extends ApiException {
  @override
  final String message;
  @override
  String? get code => 'TIMEOUT';
  @override
  int? get statusCode => null;

  ApiTimeoutException({
    this.message = 'リクエストがタイムアウトしました',
  });
}

/// バックエンドエラーコードからApiExceptionを生成するファクトリ
ApiException createApiExceptionFromErrorCode({
  required String? errorCode,
  required String message,
  required int statusCode,
  Map<String, List<String>>? details,
}) {
  switch (errorCode) {
    case 'UNAUTHORIZED':
    case 'INVALID_TOKEN':
    case 'TOKEN_EXPIRED':
      return UnauthorizedException(message: message, code: errorCode);
    case 'FORBIDDEN':
    case 'NOT_OWNER':
      return ForbiddenException(message: message, code: errorCode);
    case 'NOT_FOUND':
    case 'USER_NOT_FOUND':
    case 'CHAMPIONSHIP_NOT_FOUND':
    case 'ANSWER_NOT_FOUND':
      return NotFoundException(message: message, code: errorCode);
    case 'ALREADY_LIKED':
      return ConflictException(message: message, code: errorCode);
    case 'VALIDATION_ERROR':
    case 'INVALID_STATUS':
      return ClientException(
        message: message,
        code: errorCode,
        statusCode: statusCode,
        details: details,
      );
    case 'INTERNAL_ERROR':
      return ServerException(message: message, code: errorCode, statusCode: statusCode);
    default:
      if (statusCode >= 500) {
        return ServerException(message: message, code: errorCode, statusCode: statusCode);
      }
      return ClientException(
        message: message,
        code: errorCode,
        statusCode: statusCode,
        details: details,
      );
  }
}
