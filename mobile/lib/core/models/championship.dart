import 'enums.dart';
import 'user.dart';

/// 選手権
class Championship {
  final String id;
  final String title;
  final String description;
  final ChampionshipStatus status;
  final DateTime startAt;
  final DateTime endAt;
  final String? summaryComment;
  final UserSummary user;
  final int answerCount;
  final int totalLikes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Championship({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.startAt,
    required this.endAt,
    this.summaryComment,
    required this.user,
    required this.answerCount,
    required this.totalLikes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Championship.fromJson(Map<String, dynamic> json) {
    return Championship(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: ChampionshipStatusExtension.fromJson(json['status'] as String),
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      summaryComment: json['summaryComment'] as String?,
      user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
      answerCount: json['answerCount'] as int,
      totalLikes: json['totalLikes'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toJson(),
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'summaryComment': summaryComment,
      'user': user.toJson(),
      'answerCount': answerCount,
      'totalLikes': totalLikes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// 選手権詳細（選手権 + 追加情報）
class ChampionshipDetail extends Championship {
  const ChampionshipDetail({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.startAt,
    required super.endAt,
    super.summaryComment,
    required super.user,
    required super.answerCount,
    required super.totalLikes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChampionshipDetail.fromJson(Map<String, dynamic> json) {
    return ChampionshipDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: ChampionshipStatusExtension.fromJson(json['status'] as String),
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      summaryComment: json['summaryComment'] as String?,
      user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
      answerCount: json['answerCount'] as int,
      totalLikes: json['totalLikes'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
