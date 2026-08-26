class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int wins;
  final int totalGames;
  final int totalScore;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.wins,
    required this.totalGames,
    required this.totalScore,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Player',
      avatarUrl: json['avatar_url']?.toString(),
      wins: json['wins'] as int? ?? 0,
      totalGames: json['total_games'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? 0,
    );
  }
}
