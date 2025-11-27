import 'package:dio/dio.dart';

import '../auth/auth_service.dart';
import 'api_exception.dart';

/// HTTPエラーをApiExceptionに変換し、401時のリトライ処理を行うインターセプター
class ErrorInterceptor extends Interceptor {
  final AuthServiceInterface _authService;
  final Dio _dio;

  ErrorInterceptor({
    required AuthServiceInterface authService,
    required Dio dio,
  })  : _authService = authService,
        _dio = dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // タイムアウトエラー
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: ApiTimeoutException(),
          type: err.type,
        ),
      );
      return;
    }

    // ネットワークエラー
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown && err.response == null) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: NetworkException(),
          type: err.type,
        ),
      );
      return;
    }

    final response = err.response;
    if (response == null) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: NetworkException(),
          type: err.type,
        ),
      );
      return;
    }

    final statusCode = response.statusCode ?? 500;
    final responseData = response.data;

    // エラーレスポンスボディからメッセージとコードを抽出
    String message = 'エラーが発生しました';
    String? errorCode;
    Map<String, List<String>>? details;

    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ?? message;
      errorCode = responseData['code'] as String?;
      final rawDetails = responseData['details'];
      if (rawDetails is Map<String, dynamic>) {
        details = rawDetails.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>).cast<String>(),
          ),
        );
      }
    }

    // TOKEN_EXPIREDエラー時のリトライ処理
    if (statusCode == 401 && errorCode == 'TOKEN_EXPIRED') {
      try {
        // トークンを強制リフレッシュ
        final newToken = await _authService.getIdToken(forceRefresh: true);
        if (newToken != null) {
          // 新しいトークンでリクエストを再試行
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(options);
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        // リトライ失敗時はログアウト
        await _authService.signOut();
      }
    }

    // ApiExceptionを生成
    final apiException = createApiExceptionFromErrorCode(
      errorCode: errorCode,
      message: message,
      statusCode: statusCode,
      details: details,
    );

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: response,
        error: apiException,
        type: err.type,
      ),
    );
  }
}
