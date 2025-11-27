import '../api/api_client.dart';
import '../models/answer.dart';
import '../models/championship.dart';
import '../models/pagination.dart';
import '../models/user.dart';

/// ユーザーAPI
class UserApi {
  final ApiClient _apiClient;

  UserApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// ユーザープロフィールを取得
  Future<UserProfile> getUser(String id) async {
    return _apiClient.get<UserProfile>(
      '/users/$id',
      fromJson: UserProfile.fromJson,
    );
  }

  /// 自分のプロフィールを更新
  Future<UserProfile> updateMyProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? twitterUrl,
  }) async {
    return _apiClient.patch<UserProfile>(
      '/users/me',
      data: {
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (twitterUrl != null) 'twitterUrl': twitterUrl,
      },
      fromJson: UserProfile.fromJson,
    );
  }

  /// ユーザーの選手権一覧を取得
  Future<PaginatedResponse<Championship>> getUserChampionships(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return _apiClient.get<PaginatedResponse<Championship>>(
      '/users/$userId/championships',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      fromJson: (json) => PaginatedResponse.fromJson(
        json,
        Championship.fromJson,
      ),
    );
  }

  /// ユーザーの回答一覧を取得
  Future<PaginatedResponse<Answer>> getUserAnswers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return _apiClient.get<PaginatedResponse<Answer>>(
      '/users/$userId/answers',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      fromJson: (json) => PaginatedResponse.fromJson(
        json,
        Answer.fromJson,
      ),
    );
  }
}
