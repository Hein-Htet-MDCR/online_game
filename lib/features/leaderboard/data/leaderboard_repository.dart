import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/leaderboard_entry.dart';
import '../domain/match_history_item.dart';

class LeaderboardRepository {
  final SupabaseClient _client;

  LeaderboardRepository(this._client);

  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 20}) async {
    final response =
        await _client.rpc('get_leaderboard', params: {'p_limit': limit})
            as List<dynamic>;

    return response
        .map(
          (e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<MatchHistoryItem>> getUserMatchHistory(
    String userId, {
    int limit = 20,
  }) async {
    final response =
        await _client.rpc(
              'get_user_match_history',
              params: {'p_user_id': userId, 'p_limit': limit},
            )
            as List<dynamic>;

    return response
        .map(
          (e) => MatchHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
