import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/auth_interceptor.dart';
import 'api/error_interceptor.dart';
import 'auth/auth_provider.dart';
import 'services/answer_api.dart';
import 'services/championship_api.dart';
import 'services/upload_service.dart';
import 'services/user_api.dart';
import 'utils/storage_service.dart';

/// 環境設定
class AppConfig {
  final String apiBaseUrl;

  const AppConfig({required this.apiBaseUrl});
}

/// アプリ設定のProvider
final appConfigProvider = Provider<AppConfig>((ref) {
  // 環境変数またはビルド設定から取得
  // デフォルト値を設定（開発環境用）
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  return const AppConfig(apiBaseUrl: baseUrl);
});

/// SharedPreferencesのProvider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

/// StorageServiceのProvider
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs: prefs);
});

/// Dioインスタンス（内部使用）
final _dioProvider = Provider<Dio>((ref) {
  return Dio();
});

/// ApiClientのProvider
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final dio = ref.watch(_dioProvider);

  final authInterceptor = AuthInterceptor(authService: authService);
  final errorInterceptor = ErrorInterceptor(
    authService: authService,
    dio: dio,
  );

  return ApiClient(
    baseUrl: config.apiBaseUrl,
    dio: dio,
    interceptors: [authInterceptor, errorInterceptor],
  );
});

/// ChampionshipApiのProvider
final championshipApiProvider = Provider<ChampionshipApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChampionshipApi(apiClient: apiClient);
});

/// AnswerApiのProvider
final answerApiProvider = Provider<AnswerApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnswerApi(apiClient: apiClient);
});

/// UserApiのProvider
final userApiProvider = Provider<UserApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserApi(apiClient: apiClient);
});

/// UploadServiceのProvider
final uploadServiceProvider = Provider<UploadService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UploadService(apiClient: apiClient);
});
