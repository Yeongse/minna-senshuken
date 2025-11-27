import 'enums.dart';
import 'user.dart';

/// 回答
class Answer {
  final String id;
  final String championshipId;
  final String userId;
  final String text;
  final String? imageUrl;
  final AwardType? awardType;
  final String? awardComment;
  final int likeCount;
  final int commentCount;
  final int score;
  final UserSummary user;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Answer({
    required this.id,
    required this.championshipId,
    required this.userId,
    required this.text,
    this.imageUrl,
    this.awardType,
    this.awardComment,
    required this.likeCount,
    required this.commentCount,
    required this.score,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    final awardTypeJson = json['awardType'] as String?;
    return Answer(
      id: json['id'] as String,
      championshipId: json['championshipId'] as String,
      userId: json['userId'] as String,
      text: json['text'] as String,
      imageUrl: json['imageUrl'] as String?,
      awardType:
          awardTypeJson != null ? AwardTypeExtension.fromJson(awardTypeJson) : null,
      awardComment: json['awardComment'] as String?,
      likeCount: json['likeCount'] as int,
      commentCount: json['commentCount'] as int,
      score: json['score'] as int,
      user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'championshipId': championshipId,
      'userId': userId,
      'text': text,
      'imageUrl': imageUrl,
      'awardType': awardType?.toJson(),
      'awardComment': awardComment,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'score': score,
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
