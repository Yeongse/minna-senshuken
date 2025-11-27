/// ページング情報
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
    };
  }
}

/// ページングレスポンス
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationInfo pagination;

  const PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  /// 次のページが存在するかどうか
  bool get hasNextPage => pagination.page < pagination.totalPages;

  /// 次のページのオフセット
  int get nextPageOffset => pagination.page * pagination.limit;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final itemsJson = json['items'] as List<dynamic>;
    final items = itemsJson
        .map((item) => fromJsonT(item as Map<String, dynamic>))
        .toList();
    final pagination = PaginationInfo.fromJson(
      json['pagination'] as Map<String, dynamic>,
    );

    return PaginatedResponse<T>(
      items: items,
      pagination: pagination,
    );
  }
}

/// ページングパラメータ
class PaginationParams {
  final int page;
  final int limit;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParameters() => {
        'page': page.toString(),
        'limit': limit.toString(),
      };
}
