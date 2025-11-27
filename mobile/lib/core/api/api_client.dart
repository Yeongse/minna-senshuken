import 'package:dio/dio.dart';

/// ApiClientのインターフェース
abstract class ApiClientService {
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<void> delete(String path);
}

/// Dioベースの型安全なHTTPクライアント
class ApiClient implements ApiClientService {
  final Dio _dio;

  ApiClient({
    required String baseUrl,
    Dio? dio,
    List<Interceptor>? interceptors,
  }) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors);
    }
  }

  /// Dioインスタンスを取得（テスト用）
  Dio get dio => _dio;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return _parseResponse<T>(response, fromJson);
  }

  @override
  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _dio.post<dynamic>(
      path,
      data: data,
    );
    return _parseResponse<T>(response, fromJson);
  }

  @override
  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _dio.put<dynamic>(
      path,
      data: data,
    );
    return _parseResponse<T>(response, fromJson);
  }

  @override
  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _dio.patch<dynamic>(
      path,
      data: data,
    );
    return _parseResponse<T>(response, fromJson);
  }

  @override
  Future<void> delete(String path) async {
    await _dio.delete<dynamic>(path);
  }

  T _parseResponse<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final data = response.data;

    if (fromJson != null && data is Map<String, dynamic>) {
      return fromJson(data);
    }

    if (data is T) {
      return data;
    }

    throw FormatException(
      'Expected type $T but got ${data.runtimeType}',
    );
  }
}
