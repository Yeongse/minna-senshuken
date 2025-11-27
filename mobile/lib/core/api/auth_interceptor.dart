import 'package:dio/dio.dart';

import '../auth/auth_service.dart';

/// リクエストにFirebase ID Tokenを自動付与するインターセプター
class AuthInterceptor extends Interceptor {
  final AuthServiceInterface _authService;

  AuthInterceptor({required AuthServiceInterface authService})
      : _authService = authService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 認証済みユーザーの場合のみトークンを付与
    if (_authService.isAuthenticated) {
      final token = await _authService.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
