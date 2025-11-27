import 'user.dart';

/// コメント
class Comment {
  final String id;
  final String answerId;
  final String userId;
  final String text;
  final UserSummary user;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.answerId,
    required this.userId,
    required this.text,
    required this.user,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      answerId: json['answerId'] as String,
      userId: json['userId'] as String,
      text: json['text'] as String,
      user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answerId': answerId,
      'userId': userId,
      'text': text,
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
