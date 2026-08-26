class RoomPlayer {
  final String id;
  final String roomId;
  final String playerId;
  final bool isHost;
  final bool isReady;
  final DateTime joinedAt;
  final String? displayName;
  final String? avatarUrl;

  const RoomPlayer({
    required this.id,
    required this.roomId,
    required this.playerId,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  factory RoomPlayer.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return RoomPlayer(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      playerId: json['player_id'] as String,
      isHost: json['is_host'] as bool? ?? false,
      isReady: json['is_ready'] as bool? ?? false,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      displayName: profile?['display_name'] as String? ?? 'Player',
      avatarUrl: profile?['avatar_url'] as String? ?? '',
    );
  }

  RoomPlayer copyWith({bool? isReady, String? displayName, String? avatarUrl}) {
    return RoomPlayer(
      id: id,
      roomId: roomId,
      playerId: playerId,
      isHost: isHost,
      isReady: isReady ?? this.isReady,
      joinedAt: joinedAt,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
