import '../api/api_client.dart';
import '../models/answer.dart';
import '../models/comment.dart';
import '../models/enums.dart';
import '../models/like.dart';
import '../models/pagination.dart';

/// 回答API
class AnswerApi {
  final ApiClient _apiClient;

  AnswerApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 回答一覧を取得
  Future<PaginatedResponse<Answer>> getAnswers(
    String championshipId, {
    int page = 1,
    int limit = 20,
    AnswerSort sort = AnswerSort.score,
  }) async {
    return _apiClient.get<PaginatedResponse<Answer>>(
      '/championships/$championshipId/answers',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort.toJson(),
      },
      fromJson: (json) => PaginatedResponse.fromJson(
        json,
        Answer.fromJson,
      ),
    );
  }

  /// 回答を投稿
  Future<Answer> createAnswer(
    String championshipId, {
    required String text,
    String? imageUrl,
  }) async {
    return _apiClient.post<Answer>(
      '/championships/$championshipId/answers',
      data: {
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
      fromJson: Answer.fromJson,
    );
  }

  /// 回答を編集
  Future<Answer> updateAnswer(
    String id, {
    String? text,
    String? imageUrl,
  }) async {
    return _apiClient.patch<Answer>(
      '/answers/$id',
      data: {
        if (text != null) 'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
      fromJson: Answer.fromJson,
    );
  }

  /// 受賞を設定
  Future<Answer> setAward(
    String id, {
    required AwardType? awardType,
    String? awardComment,
  }) async {
    return _apiClient.patch<Answer>(
      '/answers/$id/award',
      data: {
        'awardType': awardType?.toJson(),
        if (awardComment != null) 'awardComment': awardComment,
      },
      fromJson: Answer.fromJson,
    );
  }

  /// いいねを追加
  Future<Like> addLike(String answerId) async {
    return _apiClient.post<Like>(
      '/answers/$answerId/likes',
      fromJson: Like.fromJson,
    );
  }

  /// コメント一覧を取得
  Future<PaginatedResponse<Comment>> getComments(
    String answerId, {
    int page = 1,
    int limit = 20,
  }) async {
    return _apiClient.get<PaginatedResponse<Comment>>(
      '/answers/$answerId/comments',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      fromJson: (json) => PaginatedResponse.fromJson(
        json,
        Comment.fromJson,
      ),
    );
  }

  /// コメントを投稿
  Future<Comment> createComment(
    String answerId, {
    required String text,
  }) async {
    return _apiClient.post<Comment>(
      '/answers/$answerId/comments',
      data: {'text': text},
      fromJson: Comment.fromJson,
    );
  }
}
