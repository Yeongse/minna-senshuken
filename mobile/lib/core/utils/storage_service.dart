import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// ローカルストレージサービスのインターフェース
abstract class StorageServiceInterface {
  /// 文字列を保存
  Future<void> setString(String key, String value);

  /// 文字列を取得
  String? getString(String key);

  /// 整数を保存
  Future<void> setInt(String key, int value);

  /// 整数を取得
  int? getInt(String key);

  /// 真偽値を保存
  Future<void> setBool(String key, bool value);

  /// 真偽値を取得
  bool? getBool(String key);

  /// JSONオブジェクトを保存
  Future<void> setJson<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  );

  /// JSONオブジェクトを取得
  T? getJson<T>(String key, T Function(Map<String, dynamic>) fromJson);

  /// キーを削除
  Future<void> remove(String key);

  /// 全データをクリア
  Future<void> clear();
}

/// SharedPreferencesのラッパーサービス
class StorageService implements StorageServiceInterface {
  final SharedPreferences _prefs;

  StorageService({required SharedPreferences prefs}) : _prefs = prefs;

  /// SharedPreferencesインスタンスを初期化して返す
  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs: prefs);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  @override
  Future<void> setJson<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final jsonString = jsonEncode(toJson(value));
    await _prefs.setString(key, jsonString);
  }

  @override
  T? getJson<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) {
      return null;
    }
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
