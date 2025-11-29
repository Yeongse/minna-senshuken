import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../models/answer.dart';
import '../models/championship.dart';
import '../models/user.dart';
import '../providers.dart';
import '../services/cache_service.dart';

/// プロフィールのキャッシュTTL
const _profileCacheTtl = Duration(minutes: 10);

/// プロフィールProvider（ログインユーザー自身のプロフィール）
final profileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return null;
  }

  final userApi = ref.watch(userApiProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);
  final userId = currentUser.uid;

  // オフライン時はキャッシュから取得
  if (!isOnline) {
    final cached = cacheService.get<UserProfile>(
      CacheService.userProfileKey(userId),
      UserProfile.fromJson,
      ttl: _profileCacheTtl,
    );
    if (cached != null) {
      return cached;
    }
  }

  // APIから取得
  final profile = await userApi.getUser(userId);

  // キャッシュに保存
  await cacheService.set<UserProfile>(
    CacheService.userProfileKey(userId),
    profile,
    (p) => p.toJson(),
  );

  return profile;
});

/// ユーザー詳細Provider（任意のユーザー）
final userDetailProvider =
    FutureProvider.autoDispose.family<UserProfile, String>((ref, userId) async {
  final userApi = ref.watch(userApiProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);

  // オフライン時はキャッシュから取得
  if (!isOnline) {
    final cached = cacheService.get<UserProfile>(
      CacheService.userProfileKey(userId),
      UserProfile.fromJson,
      ttl: _profileCacheTtl,
    );
    if (cached != null) {
      return cached;
    }
  }

  // APIから取得
  final profile = await userApi.getUser(userId);

  // キャッシュに保存
  await cacheService.set<UserProfile>(
    CacheService.userProfileKey(userId),
    profile,
    (p) => p.toJson(),
  );

  return profile;
});

/// ユーザーの主催選手権一覧Provider
final userChampionshipsProvider = FutureProvider.autoDispose
    .family<List<Championship>, String>((ref, userId) async {
  final userApi = ref.watch(userApiProvider);
  final response = await userApi.getUserChampionships(userId);
  return response.items;
});

/// ユーザーの回答一覧Provider
final userAnswersProvider =
    FutureProvider.autoDispose.family<List<Answer>, String>((ref, userId) async {
  final userApi = ref.watch(userApiProvider);
  final response = await userApi.getUserAnswers(userId);
  return response.items;
});

/// プロフィール編集の状態
class ProfileEditState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ProfileEditState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ProfileEditState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return ProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// プロフィール編集のNotifier
class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final Ref _ref;
  File? _avatarFile;

  ProfileEditNotifier(this._ref) : super(const ProfileEditState());

  File? get avatarFile => _avatarFile;

  void setAvatarFile(File? file) {
    _avatarFile = file;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// バリデーション
  String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return '表示名を入力してください';
    }
    if (value.length > 30) {
      return '表示名は30文字以内で入力してください';
    }
    return null;
  }

  String? validateBio(String? value) {
    if (value != null && value.length > 200) {
      return '自己紹介は200文字以内で入力してください';
    }
    return null;
  }

  /// プロフィールを更新
  Future<bool> updateProfile({
    required String displayName,
    String? bio,
    String? twitterUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final userApi = _ref.read(userApiProvider);
      final uploadService = _ref.read(uploadServiceProvider);

      String? avatarUrl;

      // アバター画像がある場合はアップロード
      if (_avatarFile != null) {
        avatarUrl = await uploadService.uploadImage(_avatarFile!);
      }

      // プロフィール更新
      await userApi.updateMyProfile(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        twitterUrl: twitterUrl,
      );

      // プロフィールProviderを無効化して再取得
      _ref.invalidate(profileProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
      _avatarFile = null;
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

/// プロフィール編集のProvider
final profileEditNotifierProvider =
    StateNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>(
        (ref) {
  return ProfileEditNotifier(ref);
});
