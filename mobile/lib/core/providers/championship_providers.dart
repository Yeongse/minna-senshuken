import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/championship.dart';
import '../models/enums.dart';
import '../providers.dart';
import '../services/cache_service.dart';

/// 選手権一覧のTTL（5分）
const _championshipListTtl = Duration(minutes: 5);

/// 選手権詳細のTTL（10分）
const _championshipDetailTtl = Duration(minutes: 10);

/// 選手権一覧を取得するProvider
final championshipListProvider =
    FutureProvider.family<List<Championship>, ChampionshipStatus?>(
  (ref, status) async {
    final cacheService = ref.watch(cacheServiceProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final cacheKey = CacheService.championshipListKey(status);

    // オフライン時はキャッシュから取得
    if (!isOnline) {
      final cached = cacheService.get<List<dynamic>>(
        cacheKey,
        (json) => json['items'] as List<dynamic>,
        ttl: _championshipListTtl,
      );
      if (cached != null) {
        return cached
            .map((item) => Championship.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw Exception('オフラインでデータがありません');
    }

    // オンライン時はAPIから取得
    final championshipApi = ref.watch(championshipApiProvider);
    final response = await championshipApi.getChampionships(status: status);

    // キャッシュに保存
    await cacheService.set(
      cacheKey,
      {'items': response.items.map((c) => c.toJson()).toList()},
      (data) => data,
    );

    return response.items;
  },
);

/// 選手権詳細を取得するProvider
final championshipDetailProvider =
    FutureProvider.family<ChampionshipDetail, String>(
  (ref, id) async {
    final cacheService = ref.watch(cacheServiceProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final cacheKey = CacheService.championshipDetailKey(id);

    // オフライン時はキャッシュから取得
    if (!isOnline) {
      final cached = cacheService.get<Map<String, dynamic>>(
        cacheKey,
        (json) => json,
        ttl: _championshipDetailTtl,
      );
      if (cached != null) {
        return ChampionshipDetail.fromJson(cached);
      }
      throw Exception('オフラインでデータがありません');
    }

    // オンライン時はAPIから取得
    final championshipApi = ref.watch(championshipApiProvider);
    final championship = await championshipApi.getChampionship(id);

    // キャッシュに保存
    await cacheService.set(
      cacheKey,
      championship.toJson(),
      (data) => data,
    );

    return championship;
  },
);

/// 選手権作成の状態
class ChampionshipCreateState {
  final bool isLoading;
  final Championship? championship;
  final String? error;
  final Map<String, String> validationErrors;

  const ChampionshipCreateState({
    this.isLoading = false,
    this.championship,
    this.error,
    this.validationErrors = const {},
  });

  ChampionshipCreateState copyWith({
    bool? isLoading,
    Championship? championship,
    String? error,
    Map<String, String>? validationErrors,
  }) {
    return ChampionshipCreateState(
      isLoading: isLoading ?? this.isLoading,
      championship: championship ?? this.championship,
      error: error,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

/// 選手権作成のNotifier
class ChampionshipCreateNotifier extends StateNotifier<ChampionshipCreateState> {
  final Ref _ref;

  ChampionshipCreateNotifier(this._ref) : super(const ChampionshipCreateState());

  /// バリデーション
  Map<String, String> _validate({
    required String title,
    required String description,
    required int durationDays,
  }) {
    final errors = <String, String>{};

    if (title.isEmpty) {
      errors['title'] = 'タイトルを入力してください';
    } else if (title.length > 50) {
      errors['title'] = 'タイトルは50文字以内で入力してください';
    }

    if (description.isEmpty) {
      errors['description'] = '説明を入力してください';
    } else if (description.length > 500) {
      errors['description'] = '説明は500文字以内で入力してください';
    }

    if (durationDays < 1) {
      errors['durationDays'] = '期間は1日以上を指定してください';
    } else if (durationDays > 14) {
      errors['durationDays'] = '期間は14日以内で指定してください';
    }

    return errors;
  }

  /// 選手権を作成
  Future<bool> create({
    required String title,
    required String description,
    required int durationDays,
  }) async {
    // バリデーション
    final validationErrors = _validate(
      title: title,
      description: description,
      durationDays: durationDays,
    );

    if (validationErrors.isNotEmpty) {
      state = state.copyWith(validationErrors: validationErrors);
      return false;
    }

    state = state.copyWith(isLoading: true, validationErrors: {});

    try {
      final championshipApi = _ref.read(championshipApiProvider);
      final championship = await championshipApi.createChampionship(
        title: title,
        description: description,
        durationDays: durationDays,
      );

      state = state.copyWith(
        isLoading: false,
        championship: championship,
      );

      // 選手権一覧を無効化
      _ref.invalidate(championshipListProvider(null));
      _ref.invalidate(championshipListProvider(ChampionshipStatus.recruiting));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 状態をリセット
  void reset() {
    state = const ChampionshipCreateState();
  }
}

/// 選手権作成のProvider
final championshipCreateNotifierProvider =
    StateNotifierProvider<ChampionshipCreateNotifier, ChampionshipCreateState>(
  (ref) => ChampionshipCreateNotifier(ref),
);
