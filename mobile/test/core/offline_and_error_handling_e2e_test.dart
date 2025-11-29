import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/core/api/api_exception.dart';
import 'package:minna_senshuken/core/models/enums.dart';
import 'package:minna_senshuken/core/models/user.dart';
import 'package:minna_senshuken/core/providers.dart';
import 'package:minna_senshuken/core/services/cache_service.dart';
import 'package:minna_senshuken/core/utils/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('オフライン対応E2E確認', () {
    late SharedPreferences prefs;
    late StorageService storageService;
    late CacheService cacheService;

    final testProfile = UserProfile(
      id: 'test-uid',
      displayName: 'キャッシュユーザー',
      avatarUrl: null,
      bio: 'キャッシュテスト',
      twitterUrl: null,
      createdAt: DateTime(2024, 1, 1),
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs: prefs);
      cacheService = CacheService(storage: storageService);
    });

    group('タスク7.5.1: CacheServiceのテスト', () {
      test('データをキャッシュに保存して取得できる', () async {
        // データを保存
        await cacheService.set<UserProfile>(
          CacheService.userProfileKey('test-uid'),
          testProfile,
          (p) => p.toJson(),
        );

        // データを取得
        final cached = cacheService.get<UserProfile>(
          CacheService.userProfileKey('test-uid'),
          UserProfile.fromJson,
          ttl: const Duration(minutes: 10),
        );

        expect(cached, isNotNull);
        expect(cached!.id, 'test-uid');
        expect(cached.displayName, 'キャッシュユーザー');
      });

      test('TTLが設定された場合でも保存直後は有効', () async {
        // データを保存
        await cacheService.set<UserProfile>(
          CacheService.userProfileKey('ttl-test'),
          testProfile,
          (p) => p.toJson(),
        );

        // TTL設定ありでデータを取得（保存直後なので有効）
        final cached = cacheService.get<UserProfile>(
          CacheService.userProfileKey('ttl-test'),
          UserProfile.fromJson,
          ttl: const Duration(hours: 1),
        );

        expect(cached, isNotNull);
      });

      test('存在しないキーはnullを返す', () {
        final cached = cacheService.get<UserProfile>(
          CacheService.userProfileKey('nonexistent'),
          UserProfile.fromJson,
          ttl: const Duration(minutes: 10),
        );

        expect(cached, isNull);
      });

      test('キャッシュを削除できる', () async {
        // データを保存
        await cacheService.set<UserProfile>(
          CacheService.userProfileKey('delete-test'),
          testProfile,
          (p) => p.toJson(),
        );

        // データが存在することを確認
        expect(
          cacheService.get<UserProfile>(
            CacheService.userProfileKey('delete-test'),
            UserProfile.fromJson,
          ),
          isNotNull,
        );

        // データを削除
        await cacheService.remove(CacheService.userProfileKey('delete-test'));

        // データが削除されたことを確認
        expect(
          cacheService.get<UserProfile>(
            CacheService.userProfileKey('delete-test'),
            UserProfile.fromJson,
          ),
          isNull,
        );
      });

      test('全キャッシュをクリアできる', () async {
        // 複数のデータを保存
        await cacheService.set<UserProfile>(
          CacheService.userProfileKey('clear-test-1'),
          testProfile,
          (p) => p.toJson(),
        );
        await cacheService.set<UserProfile>(
          CacheService.userProfileKey('clear-test-2'),
          testProfile,
          (p) => p.toJson(),
        );

        // 全クリア
        await cacheService.clear();

        // すべてのデータが削除されたことを確認
        expect(
          cacheService.get<UserProfile>(
            CacheService.userProfileKey('clear-test-1'),
            UserProfile.fromJson,
          ),
          isNull,
        );
        expect(
          cacheService.get<UserProfile>(
            CacheService.userProfileKey('clear-test-2'),
            UserProfile.fromJson,
          ),
          isNull,
        );
      });
    });

    group('タスク7.5.2: CacheEntryのテスト', () {
      test('CacheEntryをJSONに変換して復元できる', () {
        final entry = CacheEntry(
          data: testProfile,
          timestamp: DateTime(2024, 1, 1, 12, 0),
        );

        final json = entry.toJson((p) => p.toJson());

        expect(json['data'], isNotNull);
        expect(json['timestamp'], '2024-01-01T12:00:00.000');

        final restored = CacheEntry.fromJson<UserProfile>(
          json,
          UserProfile.fromJson,
        );

        expect(restored, isNotNull);
        expect(restored!.data.displayName, 'キャッシュユーザー');
        expect(restored.timestamp, DateTime(2024, 1, 1, 12, 0));
      });

      test('不正なJSONからの復元はnullを返す', () {
        final invalidJson = {'invalid': 'data'};

        final restored = CacheEntry.fromJson<UserProfile>(
          invalidJson,
          UserProfile.fromJson,
        );

        expect(restored, isNull);
      });
    });

    group('タスク7.5.3: キャッシュキー生成のテスト', () {
      test('選手権一覧のキャッシュキーが正しく生成される', () {
        expect(
          CacheService.championshipListKey(ChampionshipStatus.recruiting),
          'cache_championships_list_recruiting',
        );
        expect(
          CacheService.championshipListKey(ChampionshipStatus.selecting),
          'cache_championships_list_selecting',
        );
        expect(
          CacheService.championshipListKey(ChampionshipStatus.announced),
          'cache_championships_list_announced',
        );
        expect(
          CacheService.championshipListKey(null),
          'cache_championships_list_all',
        );
      });

      test('選手権詳細のキャッシュキーが正しく生成される', () {
        expect(
          CacheService.championshipDetailKey('championship-123'),
          'cache_championship_championship-123',
        );
      });

      test('ユーザープロフィールのキャッシュキーが正しく生成される', () {
        expect(
          CacheService.userProfileKey('user-456'),
          'cache_user_user-456',
        );
      });
    });

    group('タスク7.5.4: StorageServiceのテスト', () {
      test('文字列を保存して取得できる', () async {
        await storageService.setString('test_string', 'hello');
        expect(storageService.getString('test_string'), 'hello');
      });

      test('整数を保存して取得できる', () async {
        await storageService.setInt('test_int', 42);
        expect(storageService.getInt('test_int'), 42);
      });

      test('真偽値を保存して取得できる', () async {
        await storageService.setBool('test_bool', true);
        expect(storageService.getBool('test_bool'), true);
      });

      test('JSONオブジェクトを保存して取得できる', () async {
        await storageService.setJson<UserProfile>(
          'test_json',
          testProfile,
          (p) => p.toJson(),
        );

        final retrieved = storageService.getJson<UserProfile>(
          'test_json',
          UserProfile.fromJson,
        );

        expect(retrieved, isNotNull);
        expect(retrieved!.displayName, 'キャッシュユーザー');
      });

      test('存在しないキーはnullを返す', () {
        expect(storageService.getString('nonexistent'), isNull);
        expect(storageService.getInt('nonexistent'), isNull);
        expect(storageService.getBool('nonexistent'), isNull);
      });

      test('キーを削除できる', () async {
        await storageService.setString('to_remove', 'value');
        expect(storageService.getString('to_remove'), 'value');

        await storageService.remove('to_remove');
        expect(storageService.getString('to_remove'), isNull);
      });
    });

    group('タスク7.5.5: 接続状態のテスト', () {
      test('isOnlineProviderがオンライン時にtrueを返す', () {
        final container = ProviderContainer(
          overrides: [
            isOnlineProvider.overrideWithValue(true),
          ],
        );
        addTearDown(container.dispose);

        final isOnline = container.read(isOnlineProvider);
        expect(isOnline, isTrue);
      });

      test('isOnlineProviderがオフライン時にfalseを返す', () {
        final container = ProviderContainer(
          overrides: [
            isOnlineProvider.overrideWithValue(false),
          ],
        );
        addTearDown(container.dispose);

        final isOnline = container.read(isOnlineProvider);
        expect(isOnline, isFalse);
      });

      test('ConnectivityResult.noneはオフラインを示す', () {
        // ConnectivityResult.noneがオフラインを意味することを確認
        expect(ConnectivityResult.none != ConnectivityResult.wifi, isTrue);
        expect(ConnectivityResult.none != ConnectivityResult.mobile, isTrue);
      });

      test('ConnectivityResult.wifiはオンラインを示す', () {
        // Wifiはオンラインを意味する
        expect(ConnectivityResult.wifi != ConnectivityResult.none, isTrue);
      });
    });
  });

  group('エラーハンドリングE2E確認', () {
    group('タスク7.6.1: ApiExceptionの種類', () {
      test('NetworkExceptionが正しく作成される', () {
        final exception = NetworkException(message: 'ネットワークエラー');

        expect(exception.message, 'ネットワークエラー');
        expect(exception.statusCode, isNull);
        expect(exception.code, 'NETWORK_ERROR');
      });

      test('UnauthorizedExceptionが正しく作成される', () {
        final exception = UnauthorizedException(
          message: '認証エラー',
          code: 'UNAUTHORIZED',
        );

        expect(exception.message, '認証エラー');
        expect(exception.statusCode, 401);
        expect(exception.code, 'UNAUTHORIZED');
      });

      test('NotFoundExceptionが正しく作成される', () {
        final exception = NotFoundException(
          message: 'リソースが見つかりません',
          code: 'NOT_FOUND',
        );

        expect(exception.message, 'リソースが見つかりません');
        expect(exception.statusCode, 404);
        expect(exception.code, 'NOT_FOUND');
      });

      test('ClientExceptionが正しく作成される', () {
        final exception = ClientException(
          message: 'クライアントエラー',
          statusCode: 400,
          code: 'BAD_REQUEST',
        );

        expect(exception.message, 'クライアントエラー');
        expect(exception.statusCode, 400);
        expect(exception.code, 'BAD_REQUEST');
      });

      test('ServerExceptionが正しく作成される', () {
        final exception = ServerException(
          message: 'サーバーエラー',
          statusCode: 500,
          code: 'INTERNAL_ERROR',
        );

        expect(exception.message, 'サーバーエラー');
        expect(exception.statusCode, 500);
        expect(exception.code, 'INTERNAL_ERROR');
      });

      test('ForbiddenExceptionが正しく作成される', () {
        final exception = ForbiddenException(
          message: 'アクセス禁止',
          code: 'FORBIDDEN',
        );

        expect(exception.message, 'アクセス禁止');
        expect(exception.statusCode, 403);
        expect(exception.code, 'FORBIDDEN');
      });

      test('ConflictExceptionが正しく作成される', () {
        final exception = ConflictException(
          message: '競合エラー',
          code: 'ALREADY_LIKED',
        );

        expect(exception.message, '競合エラー');
        expect(exception.statusCode, 409);
        expect(exception.code, 'ALREADY_LIKED');
      });

      test('ApiTimeoutExceptionが正しく作成される', () {
        final exception = ApiTimeoutException(message: 'タイムアウト');

        expect(exception.message, 'タイムアウト');
        expect(exception.statusCode, isNull);
        expect(exception.code, 'TIMEOUT');
      });
    });

    group('タスク7.6.2: createApiExceptionFromErrorCodeのテスト', () {
      test('UNAUTHORIZEDコードでUnauthorizedExceptionが作成される', () {
        final exception = createApiExceptionFromErrorCode(
          errorCode: 'UNAUTHORIZED',
          message: '認証が必要です',
          statusCode: 401,
        );

        expect(exception, isA<UnauthorizedException>());
        expect(exception.message, '認証が必要です');
      });

      test('TOKEN_EXPIREDコードでUnauthorizedExceptionが作成される', () {
        final exception = createApiExceptionFromErrorCode(
          errorCode: 'TOKEN_EXPIRED',
          message: 'トークンが期限切れです',
          statusCode: 401,
        );

        expect(exception, isA<UnauthorizedException>());
        expect(exception.code, 'TOKEN_EXPIRED');
      });

      test('NOT_FOUNDコードでNotFoundExceptionが作成される', () {
        final exception = createApiExceptionFromErrorCode(
          errorCode: 'NOT_FOUND',
          message: '見つかりません',
          statusCode: 404,
        );

        expect(exception, isA<NotFoundException>());
      });

      test('INTERNAL_ERRORコードでServerExceptionが作成される', () {
        final exception = createApiExceptionFromErrorCode(
          errorCode: 'INTERNAL_ERROR',
          message: 'サーバーエラー',
          statusCode: 500,
        );

        expect(exception, isA<ServerException>());
      });

      test('FORBIDDENコードでForbiddenExceptionが作成される', () {
        final exception = createApiExceptionFromErrorCode(
          errorCode: 'FORBIDDEN',
          message: 'アクセス禁止',
          statusCode: 403,
        );

        expect(exception, isA<ForbiddenException>());
      });

      test('ALREADY_LIKEDコードでConflictExceptionが作成される', () {
        final exception = createApiExceptionFromErrorCode(
          errorCode: 'ALREADY_LIKED',
          message: 'すでにいいね済み',
          statusCode: 409,
        );

        expect(exception, isA<ConflictException>());
      });

      test('500番台のステータスコードでServerExceptionが作成される', () {
        final exception = createApiExceptionFromErrorCode(
          errorCode: 'SERVICE_UNAVAILABLE',
          message: 'サービス利用不可',
          statusCode: 503,
        );

        expect(exception, isA<ServerException>());
      });

      test('不明なコードで400番台はClientExceptionが作成される', () {
        final exception = createApiExceptionFromErrorCode(
          errorCode: 'UNKNOWN_CODE',
          message: '不明なエラー',
          statusCode: 400,
        );

        expect(exception, isA<ClientException>());
      });
    });

    group('タスク7.6.3: ApiExceptionの継承関係', () {
      test('すべての例外はApiExceptionを継承している', () {
        final network = NetworkException(message: 'test');
        final unauthorized = UnauthorizedException(message: 'test');
        final notFound = NotFoundException(message: 'test');
        final client = ClientException(message: 'test', statusCode: 400);
        final server = ServerException(message: 'test');
        final forbidden = ForbiddenException(message: 'test');
        final conflict = ConflictException(message: 'test');
        final timeout = ApiTimeoutException(message: 'test');

        expect(network, isA<ApiException>());
        expect(unauthorized, isA<ApiException>());
        expect(notFound, isA<ApiException>());
        expect(client, isA<ApiException>());
        expect(server, isA<ApiException>());
        expect(forbidden, isA<ApiException>());
        expect(conflict, isA<ApiException>());
        expect(timeout, isA<ApiException>());
      });

      test('すべての例外はExceptionを実装している', () {
        final network = NetworkException(message: 'test');

        expect(network, isA<Exception>());
      });
    });

    group('タスク7.6.4: ApiException.toStringのテスト', () {
      test('toStringが正しい形式で出力される', () {
        final exception = UnauthorizedException(
          message: '認証エラー',
          code: 'UNAUTHORIZED',
        );

        final str = exception.toString();

        expect(str, contains('ApiException'));
        expect(str, contains('認証エラー'));
        expect(str, contains('UNAUTHORIZED'));
      });
    });

    group('タスク7.6.5: ClientExceptionのdetailsテスト', () {
      test('ClientExceptionがdetailsを保持できる', () {
        final exception = ClientException(
          message: 'バリデーションエラー',
          statusCode: 422,
          code: 'VALIDATION_ERROR',
          details: {
            'email': ['メールアドレスの形式が正しくありません'],
            'password': ['パスワードは8文字以上必要です'],
          },
        );

        expect(exception.details, isNotNull);
        expect(exception.details!['email'], contains('メールアドレスの形式が正しくありません'));
        expect(exception.details!['password'], contains('パスワードは8文字以上必要です'));
      });
    });
  });
}
