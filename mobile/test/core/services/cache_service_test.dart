import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minna_senshuken/core/services/cache_service.dart';
import 'package:minna_senshuken/core/utils/storage_service.dart';

void main() {
  late CacheService cacheService;
  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs: prefs);
    cacheService = CacheService(storage: storageService);
  });

  group('CacheService', () {
    group('set and get', () {
      test('should store and retrieve a value successfully', () async {
        final testData = {'name': 'test', 'count': 42};

        await cacheService.set(
          'test_key',
          testData,
          (data) => data,
        );

        final result = cacheService.get<Map<String, dynamic>>(
          'test_key',
          (json) => json,
        );

        expect(result, isNotNull);
        expect(result!['name'], equals('test'));
        expect(result['count'], equals(42));
      });

      test('should return null for non-existent key', () {
        final result = cacheService.get<Map<String, dynamic>>(
          'non_existent_key',
          (json) => json,
        );

        expect(result, isNull);
      });

      test('should return null when TTL has expired', () async {
        final testData = {'name': 'test'};

        await cacheService.set(
          'test_key',
          testData,
          (data) => data,
        );

        // Wait for the data to expire (using short TTL)
        final result = cacheService.get<Map<String, dynamic>>(
          'test_key',
          (json) => json,
          ttl: const Duration(milliseconds: 1),
        );

        // Immediately after storing, TTL should not be expired yet
        // But with 1ms TTL, by the time we check it may have expired
        // So let's add a small delay
        await Future.delayed(const Duration(milliseconds: 10));

        final expiredResult = cacheService.get<Map<String, dynamic>>(
          'test_key',
          (json) => json,
          ttl: const Duration(milliseconds: 1),
        );

        expect(expiredResult, isNull);
      });

      test('should return value when TTL is valid', () async {
        final testData = {'name': 'test'};

        await cacheService.set(
          'test_key',
          testData,
          (data) => data,
        );

        final result = cacheService.get<Map<String, dynamic>>(
          'test_key',
          (json) => json,
          ttl: const Duration(hours: 1),
        );

        expect(result, isNotNull);
        expect(result!['name'], equals('test'));
      });
    });

    group('remove', () {
      test('should remove cached data', () async {
        final testData = {'name': 'test'};

        await cacheService.set(
          'test_key',
          testData,
          (data) => data,
        );

        await cacheService.remove('test_key');

        final result = cacheService.get<Map<String, dynamic>>(
          'test_key',
          (json) => json,
        );

        expect(result, isNull);
      });
    });

    group('clear', () {
      test('should clear all cached data', () async {
        await cacheService.set(
          'key1',
          {'name': 'test1'},
          (data) => data,
        );
        await cacheService.set(
          'key2',
          {'name': 'test2'},
          (data) => data,
        );

        await cacheService.clear();

        expect(cacheService.get<Map<String, dynamic>>('key1', (json) => json), isNull);
        expect(cacheService.get<Map<String, dynamic>>('key2', (json) => json), isNull);
      });
    });

    group('cache key generators', () {
      test('championshipListKey should generate correct key', () {
        expect(CacheService.championshipListKey(null), equals('cache_championships_list_all'));
        // Note: ChampionshipStatus enum needs to be imported for full test
      });

      test('championshipDetailKey should generate correct key', () {
        expect(CacheService.championshipDetailKey('123'), equals('cache_championship_123'));
      });

      test('userProfileKey should generate correct key', () {
        expect(CacheService.userProfileKey('user123'), equals('cache_user_user123'));
      });
    });
  });
}
