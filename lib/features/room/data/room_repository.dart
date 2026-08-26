import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/game_room.dart';
import '../domain/room_player.dart';

class RoomRepository {
  final SupabaseClient _supabase;

  RoomRepository(this._supabase);

  /// Create a new private room via RPC
  Future<Map<String, dynamic>> createRoom({
    required String jlptLevel,
    required String difficulty,
  }) async {
    final response = await _supabase.rpc(
      'create_friend_room',
      params: {'p_jlpt_level': jlptLevel, 'p_difficulty': difficulty},
    );
    return response as Map<String, dynamic>;
  }

  /// Join an existing room via 6-character code RPC
  Future<Map<String, dynamic>> joinRoom({required String code}) async {
    final response = await _supabase.rpc(
      'join_friend_room',
      params: {'p_code': code.trim().toUpperCase()},
    );
    return response as Map<String, dynamic>;
  }

  /// Toggle ready status for the current player
  Future<void> toggleReady({
    required String roomId,
    required bool isReady,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('room_players').update({'is_ready': isReady}).match({
      'room_id': roomId,
      'player_id': userId,
    });
  }

  /// Host starts the game: status transitions to 'starting'
  Future<void> startRoomGame({required String roomId}) async {
    await _supabase
        .from('game_rooms')
        .update({'status': 'starting'})
        .eq('id', roomId);
  }

  /// Leave room via RPC
  Future<void> leaveRoom({required String roomId}) async {
    await _supabase.rpc('leave_friend_room', params: {'p_room_id': roomId});
  }

  /// Stream single room updates (status changes, host changes)
  Stream<GameRoom?> watchRoom(String roomId) {
    return _supabase
        .from('game_rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .map(
          (event) => event.isNotEmpty ? GameRoom.fromJson(event.first) : null,
        );
  }

  /// Stream players in a room with profile joins
  Stream<List<RoomPlayer>> watchRoomPlayers(String roomId) {
    return _supabase
        .from('room_players')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .asyncMap((events) async {
          if (events.isEmpty) return <RoomPlayer>[];

          final playerIds = events
              .map((e) => e['player_id'] as String)
              .toList();
          final profilesData = await _supabase
              .from('profiles')
              .select()
              .filter('id', 'in', playerIds);

          final profilesMap = {
            for (var p in (profilesData as List)) p['id'] as String: p,
          };

          return events.map((e) {
            final pid = e['player_id'] as String;
            final fullJson = Map<String, dynamic>.from(e);
            fullJson['profiles'] = profilesMap[pid];
            return RoomPlayer.fromJson(fullJson);
          }).toList();
        });
  }
}
