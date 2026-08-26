class GameRoom {
  final String id;
  final String code;
  final String hostId;
  final String status; // 'waiting', 'starting', 'playing', 'finished', 'cancelled'
  final String jlptLevel; // 'N5', 'N4'
  final String difficulty; // 'easy', 'medium', 'hard'
  final DateTime createdAt;

  const GameRoom({
    required this.id,
    required this.code,
    required this.hostId,
    required this.status,
    required this.jlptLevel,
    required this.difficulty,
    required this.createdAt,
  });

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'] as String,
      code: json['code'] as String,
      hostId: json['host_id'] as String,
      status: json['status'] as String,
      jlptLevel: json['jlpt_level'] as String,
      difficulty: json['difficulty'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'host_id': hostId,
      'status': status,
      'jlpt_level': jlptLevel,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
    };
  }
}