class MatchHistoryItem {
  final String sessionId;
  final String opponentName;
  final String? opponentAvatar;
  final int userScore;
  final int opponentScore;
  final bool isWinner;
  final bool isDraw;
  final DateTime createdAt;

  const MatchHistoryItem({
    required this.sessionId,
    required this.opponentName,
    this.opponentAvatar,
    required this.userScore,
    required this.opponentScore,
    required this.isWinner,
    required this.isDraw,
    required this.createdAt,
  });

  factory MatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return MatchHistoryItem(
      sessionId: json['session_id']?.toString() ?? '',
      opponentName: json['opponent_name']?.toString() ?? 'Opponent',
      opponentAvatar: json['opponent_avatar']?.toString(),
      userScore: json['user_score'] as int? ?? 0,
      opponentScore: json['opponent_score'] as int? ?? 0,
      isWinner: json['is_winner'] as bool? ?? false,
      isDraw: json['is_draw'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
}