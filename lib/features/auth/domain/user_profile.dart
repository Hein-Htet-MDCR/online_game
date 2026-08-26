class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Player',
      avatarUrl: json['avatar_url'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
