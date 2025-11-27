import '../api/api_client.dart';
import '../models/championship.dart';
import '../models/enums.dart';
import '../models/pagination.dart';

/// 選手権API
class ChampionshipApi {
  final ApiClient _apiClient;

  ChampionshipApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 選手権一覧を取得
  Future<PaginatedResponse<Championship>> getChampionships({
    int page = 1,
    int limit = 20,
    ChampionshipStatus? status,
    ChampionshipSort sort = ChampionshipSort.newest,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort.toJson(),
    };
    if (status != null) {
      queryParams['status'] = status.toJson();
    }

    return _apiClient.get<PaginatedResponse<Championship>>(
      '/championships',
      queryParameters: queryParams,
      fromJson: (json) => PaginatedResponse.fromJson(
        json,
        Championship.fromJson,
      ),
    );
  }

  /// 選手権詳細を取得
  Future<ChampionshipDetail> getChampionship(String id) async {
    return _apiClient.get<ChampionshipDetail>(
      '/championships/$id',
      fromJson: ChampionshipDetail.fromJson,
    );
  }

  /// 選手権を作成
  Future<Championship> createChampionship({
    required String title,
    required String description,
    required int durationDays,
  }) async {
    return _apiClient.post<Championship>(
      '/championships',
      data: {
        'title': title,
        'description': description,
        'durationDays': durationDays,
      },
      fromJson: Championship.fromJson,
    );
  }

  /// 選手権を強制終了
  Future<Championship> forceEndChampionship(String id) async {
    return _apiClient.post<Championship>(
      '/championships/$id/force-end',
      fromJson: Championship.fromJson,
    );
  }

  /// 結果を発表
  Future<Championship> publishResult(
    String id, {
    String? summaryComment,
  }) async {
    return _apiClient.post<Championship>(
      '/championships/$id/publish-result',
      data: {
        if (summaryComment != null) 'summaryComment': summaryComment,
      },
      fromJson: Championship.fromJson,
    );
  }
}
