import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../models/answer.dart';
import '../models/comment.dart';
import '../providers.dart';

/// 回答一覧を取得するProvider
final answerListProvider =
    FutureProvider.family<List<Answer>, String>((ref, championshipId) async {
  final answerApi = ref.watch(answerApiProvider);
  final response = await answerApi.getAnswers(championshipId);
  return response.items;
});

/// 回答詳細を取得するProvider
final answerDetailProvider =
    FutureProvider.family<Answer, ({String championshipId, String answerId})>(
  (ref, params) async {
    final answerApi = ref.watch(answerApiProvider);
    // APIには回答単体取得がないため、一覧から取得
    final response = await answerApi.getAnswers(params.championshipId);
    final answer = response.items.firstWhere(
      (a) => a.id == params.answerId,
      orElse: () => throw Exception('回答が見つかりません'),
    );
    return answer;
  },
);

/// コメント一覧を取得するProvider
final commentListProvider =
    FutureProvider.family<List<Comment>, String>((ref, answerId) async {
  final answerApi = ref.watch(answerApiProvider);
  final response = await answerApi.getComments(answerId);
  return response.items;
});

/// 回答作成の状態
class AnswerCreateState {
  final bool isLoading;
  final double? uploadProgress;
  final Answer? answer;
  final String? error;
  final Map<String, String> validationErrors;
  final File? selectedImage;

  const AnswerCreateState({
    this.isLoading = false,
    this.uploadProgress,
    this.answer,
    this.error,
    this.validationErrors = const {},
    this.selectedImage,
  });

  AnswerCreateState copyWith({
    bool? isLoading,
    double? uploadProgress,
    Answer? answer,
    String? error,
    Map<String, String>? validationErrors,
    File? selectedImage,
    bool clearUploadProgress = false,
    bool clearSelectedImage = false,
  }) {
    return AnswerCreateState(
      isLoading: isLoading ?? this.isLoading,
      uploadProgress: clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      answer: answer ?? this.answer,
      error: error,
      validationErrors: validationErrors ?? this.validationErrors,
      selectedImage: clearSelectedImage ? null : (selectedImage ?? this.selectedImage),
    );
  }
}

/// 回答作成のNotifier
class AnswerCreateNotifier extends StateNotifier<AnswerCreateState> {
  final Ref _ref;
  final String _championshipId;

  AnswerCreateNotifier(this._ref, this._championshipId)
      : super(const AnswerCreateState());

  /// 画像を設定
  void setImage(File? file) {
    state = state.copyWith(selectedImage: file, clearSelectedImage: file == null);
  }

  /// バリデーション
  Map<String, String> _validate({required String text}) {
    final errors = <String, String>{};

    if (text.isEmpty) {
      errors['text'] = '回答を入力してください';
    } else if (text.length > 300) {
      errors['text'] = '回答は300文字以内で入力してください';
    }

    return errors;
  }

  /// 回答を作成
  Future<bool> create({required String text}) async {
    // バリデーション
    final validationErrors = _validate(text: text);

    if (validationErrors.isNotEmpty) {
      state = state.copyWith(validationErrors: validationErrors);
      return false;
    }

    state = state.copyWith(isLoading: true, validationErrors: {});

    try {
      String? imageUrl;

      // 画像がある場合はアップロード
      if (state.selectedImage != null) {
        final uploadService = _ref.read(uploadServiceProvider);
        imageUrl = await uploadService.uploadImage(
          state.selectedImage!,
          onProgress: (progress) {
            state = state.copyWith(uploadProgress: progress);
          },
        );
      }

      final answerApi = _ref.read(answerApiProvider);
      final answer = await answerApi.createAnswer(
        _championshipId,
        text: text,
        imageUrl: imageUrl,
      );

      state = state.copyWith(
        isLoading: false,
        answer: answer,
        clearUploadProgress: true,
      );

      // 回答一覧を無効化
      _ref.invalidate(answerListProvider(_championshipId));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearUploadProgress: true,
      );
      return false;
    }
  }

  /// 状態をリセット
  void reset() {
    state = const AnswerCreateState();
  }
}

/// 回答作成のProviderファミリー
final answerCreateNotifierProvider = StateNotifierProvider.family<
    AnswerCreateNotifier, AnswerCreateState, String>(
  (ref, championshipId) => AnswerCreateNotifier(ref, championshipId),
);

/// 回答編集の状態
class AnswerEditState {
  final bool isLoading;
  final bool isInitialized;
  final double? uploadProgress;
  final Answer? originalAnswer;
  final Answer? updatedAnswer;
  final String? error;
  final Map<String, String> validationErrors;
  final File? selectedImage;
  final bool hasNewImage;

  const AnswerEditState({
    this.isLoading = false,
    this.isInitialized = false,
    this.uploadProgress,
    this.originalAnswer,
    this.updatedAnswer,
    this.error,
    this.validationErrors = const {},
    this.selectedImage,
    this.hasNewImage = false,
  });

  AnswerEditState copyWith({
    bool? isLoading,
    bool? isInitialized,
    double? uploadProgress,
    Answer? originalAnswer,
    Answer? updatedAnswer,
    String? error,
    Map<String, String>? validationErrors,
    File? selectedImage,
    bool? hasNewImage,
    bool clearUploadProgress = false,
  }) {
    return AnswerEditState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      uploadProgress: clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      originalAnswer: originalAnswer ?? this.originalAnswer,
      updatedAnswer: updatedAnswer ?? this.updatedAnswer,
      error: error,
      validationErrors: validationErrors ?? this.validationErrors,
      selectedImage: selectedImage ?? this.selectedImage,
      hasNewImage: hasNewImage ?? this.hasNewImage,
    );
  }
}

/// 回答編集のNotifier
class AnswerEditNotifier extends StateNotifier<AnswerEditState> {
  final Ref _ref;
  final String _championshipId;
  final String _answerId;

  AnswerEditNotifier(this._ref, this._championshipId, this._answerId)
      : super(const AnswerEditState());

  /// 初期化（回答データを取得）
  Future<bool> init() async {
    if (state.isInitialized) return true;

    state = state.copyWith(isLoading: true);

    try {
      final answerApi = _ref.read(answerApiProvider);
      final response = await answerApi.getAnswers(_championshipId);
      final answer = response.items.firstWhere(
        (a) => a.id == _answerId,
        orElse: () => throw Exception('回答が見つかりません'),
      );

      // 権限チェック
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null || answer.userId != currentUser.uid) {
        state = state.copyWith(
          isLoading: false,
          error: 'この回答を編集する権限がありません',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        originalAnswer: answer,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 画像を設定
  void setImage(File? file) {
    state = state.copyWith(selectedImage: file, hasNewImage: true);
  }

  /// バリデーション
  Map<String, String> _validate({required String text}) {
    final errors = <String, String>{};

    if (text.isEmpty) {
      errors['text'] = '回答を入力してください';
    } else if (text.length > 300) {
      errors['text'] = '回答は300文字以内で入力してください';
    }

    return errors;
  }

  /// 回答を更新
  Future<bool> update({required String text}) async {
    // バリデーション
    final validationErrors = _validate(text: text);

    if (validationErrors.isNotEmpty) {
      state = state.copyWith(validationErrors: validationErrors);
      return false;
    }

    state = state.copyWith(isLoading: true, validationErrors: {});

    try {
      String? imageUrl;

      // 新しい画像がある場合はアップロード
      if (state.hasNewImage && state.selectedImage != null) {
        final uploadService = _ref.read(uploadServiceProvider);
        imageUrl = await uploadService.uploadImage(
          state.selectedImage!,
          onProgress: (progress) {
            state = state.copyWith(uploadProgress: progress);
          },
        );
      } else if (!state.hasNewImage) {
        // 既存の画像URLを維持
        imageUrl = state.originalAnswer?.imageUrl;
      }

      final answerApi = _ref.read(answerApiProvider);
      final answer = await answerApi.updateAnswer(
        _answerId,
        text: text,
        imageUrl: imageUrl,
      );

      state = state.copyWith(
        isLoading: false,
        updatedAnswer: answer,
        clearUploadProgress: true,
      );

      // 回答一覧を無効化
      _ref.invalidate(answerListProvider(_championshipId));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearUploadProgress: true,
      );
      return false;
    }
  }

  /// 状態をリセット
  void reset() {
    state = const AnswerEditState();
  }
}

/// 回答編集のProviderファミリー
final answerEditNotifierProvider = StateNotifierProvider.family<
    AnswerEditNotifier,
    AnswerEditState,
    ({String championshipId, String answerId})>(
  (ref, params) => AnswerEditNotifier(ref, params.championshipId, params.answerId),
);

/// いいね状態
class LikeState {
  final bool isLoading;
  final bool isLiked;
  final int likeCount;
  final String? error;

  const LikeState({
    this.isLoading = false,
    this.isLiked = false,
    this.likeCount = 0,
    this.error,
  });

  LikeState copyWith({
    bool? isLoading,
    bool? isLiked,
    int? likeCount,
    String? error,
  }) {
    return LikeState(
      isLoading: isLoading ?? this.isLoading,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      error: error,
    );
  }
}

/// いいねNotifier
class LikeNotifier extends StateNotifier<LikeState> {
  final Ref _ref;
  final String _championshipId;
  final String _answerId;

  LikeNotifier(this._ref, this._championshipId, this._answerId)
      : super(const LikeState());

  /// 初期状態を設定
  void initialize({required int likeCount, required bool isLiked}) {
    state = LikeState(likeCount: likeCount, isLiked: isLiked);
  }

  /// いいねを追加
  Future<void> addLike() async {
    if (state.isLoading || state.isLiked) return;

    state = state.copyWith(isLoading: true);

    try {
      final answerApi = _ref.read(answerApiProvider);
      await answerApi.addLike(_answerId);

      state = state.copyWith(
        isLoading: false,
        isLiked: true,
        likeCount: state.likeCount + 1,
      );

      // 回答一覧を無効化
      _ref.invalidate(answerListProvider(_championshipId));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// いいねのProviderファミリー
final likeNotifierProvider = StateNotifierProvider.family<
    LikeNotifier,
    LikeState,
    ({String championshipId, String answerId})>(
  (ref, params) => LikeNotifier(ref, params.championshipId, params.answerId),
);

/// コメント投稿状態
class CommentCreateState {
  final bool isLoading;
  final Comment? comment;
  final String? error;
  final Map<String, String> validationErrors;

  const CommentCreateState({
    this.isLoading = false,
    this.comment,
    this.error,
    this.validationErrors = const {},
  });

  CommentCreateState copyWith({
    bool? isLoading,
    Comment? comment,
    String? error,
    Map<String, String>? validationErrors,
  }) {
    return CommentCreateState(
      isLoading: isLoading ?? this.isLoading,
      comment: comment ?? this.comment,
      error: error,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

/// コメント投稿Notifier
class CommentCreateNotifier extends StateNotifier<CommentCreateState> {
  final Ref _ref;
  final String _answerId;

  CommentCreateNotifier(this._ref, this._answerId)
      : super(const CommentCreateState());

  /// バリデーション
  Map<String, String> _validate({required String text}) {
    final errors = <String, String>{};

    if (text.isEmpty) {
      errors['text'] = 'コメントを入力してください';
    } else if (text.length > 200) {
      errors['text'] = 'コメントは200文字以内で入力してください';
    }

    return errors;
  }

  /// コメントを投稿
  Future<bool> create({required String text}) async {
    final validationErrors = _validate(text: text);

    if (validationErrors.isNotEmpty) {
      state = state.copyWith(validationErrors: validationErrors);
      return false;
    }

    state = state.copyWith(isLoading: true, validationErrors: {});

    try {
      final answerApi = _ref.read(answerApiProvider);
      final comment = await answerApi.createComment(_answerId, text: text);

      state = state.copyWith(
        isLoading: false,
        comment: comment,
      );

      // コメント一覧を無効化
      _ref.invalidate(commentListProvider(_answerId));

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
    state = const CommentCreateState();
  }
}

/// コメント投稿のProviderファミリー
final commentCreateNotifierProvider =
    StateNotifierProvider.family<CommentCreateNotifier, CommentCreateState, String>(
  (ref, answerId) => CommentCreateNotifier(ref, answerId),
);
