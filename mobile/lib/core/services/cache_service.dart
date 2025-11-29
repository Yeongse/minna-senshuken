import 'dart:convert';

import '../models/enums.dart';
import '../utils/storage_service.dart';

/// キャッシュエントリのラッパー（タイムスタンプ付き）
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry({required this.data, required this.timestamp});

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) dataToJson) {
    return {
      'data': dataToJson(data),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static CacheEntry<T>? fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) dataFromJson,
  ) {
    try {
      final data = dataFromJson(json['data'] as Map<String, dynamic>);
      final timestamp = DateTime.parse(json['timestamp'] as String);
      return CacheEntry(data: data, timestamp: timestamp);
    } catch (_) {
      return null;
    }
  }
}

/// キャッシュサービスのインターフェース
abstract class CacheServiceInterface {
  /// データを保存
  Future<void> set<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  );

  /// データを取得（TTL超過時はnull）
  T? get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? ttl,
  });

  /// キーを削除
  Future<void> remove(String key);

  /// 全キャッシュをクリア
  Future<void> clear();
}

/// オフラインキャッシング、TTL管理を行うサービス
class CacheService implements CacheServiceInterface {
  final StorageService _storage;

  CacheService({required StorageService storage}) : _storage = storage;

  /// 選手権一覧のキャッシュキー
  static String championshipListKey(ChampionshipStatus? status) =>
      'cache_championships_list_${status?.name ?? 'all'}';

  /// 選手権詳細のキャッシュキー
  static String championshipDetailKey(String id) => 'cache_championship_$id';

  /// ユーザープロフィールのキャッシュキー
  static String userProfileKey(String id) => 'cache_user_$id';

  @override
  Future<void> set<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final entry = CacheEntry(data: value, timestamp: DateTime.now());
    final jsonString = jsonEncode(entry.toJson(toJson));
    await _storage.setString(key, jsonString);
  }

  @override
  T? get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? ttl,
  }) {
    final jsonString = _storage.getString(key);
    if (jsonString == null) {
      return null;
    }

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final entry = CacheEntry.fromJson<T>(jsonMap, fromJson);

      if (entry == null) {
        return null;
      }

      // TTLチェック
      if (ttl != null) {
        final now = DateTime.now();
        final expiresAt = entry.timestamp.add(ttl);
        if (now.isAfter(expiresAt)) {
          return null;
        }
      }

      return entry.data;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    await _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    await _storage.clear();
  }
}
