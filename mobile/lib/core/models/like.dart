/// いいね
class Like {
  final String id;
  final String answerId;
  final String userId;
  final DateTime createdAt;

  const Like({
    required this.id,
    required this.answerId,
    required this.userId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] as String,
      answerId: json['answerId'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answerId': answerId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
