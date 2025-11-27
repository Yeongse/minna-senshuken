/// ユーザーサマリー（他モデルの参照用）
class UserSummary {
  final String id;
  final String displayName;
  final String? avatarUrl;

  const UserSummary({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
    };
  }
}

/// ユーザープロフィール
class UserProfile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String? twitterUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.twitterUrl,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      twitterUrl: json['twitterUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'twitterUrl': twitterUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
