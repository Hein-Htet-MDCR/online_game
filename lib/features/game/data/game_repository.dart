import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/game_session.dart';

class GameRepository {
  final SupabaseClient _supabase;

  GameRepository(this._supabase);

  /// Start or initialize a game session via RPC
  Future<String> startSession(String roomId) async {
    final response = await _supabase.rpc(
      'start_game_session',
      params: {'p_room_id': roomId},
    );
    final data = response as Map<String, dynamic>;
    return data['session_id'] as String;
  }

  /// Submit a successfully matched pair to Supabase RPC
  Future<void> submitMatch({
    required String sessionId,
    required String vocabId,
    int points = 100,
  }) async {
    await _supabase.rpc(
      'submit_card_match',
      params: {
        'p_session_id': sessionId,
        'p_vocab_id': vocabId,
        'p_points': points,
      },
    );
  }

  /// Stream active game session changes for real-time score and board sync
  Stream<GameSession?> watchSession(String roomId) {
    return _supabase
        .from('game_sessions')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map(
          (event) =>
              event.isNotEmpty ? GameSession.fromJson(event.first) : null,
        );
  }
}
