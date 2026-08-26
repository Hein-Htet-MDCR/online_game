import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:online_game/features/room/data/room_repository.dart';
import 'package:online_game/features/room/domain/game_room.dart';
import 'package:online_game/features/room/domain/room_player.dart';
import '../../../../core/providers/supabase_provider.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return RoomRepository(supabase);
});

final roomStreamProvider = StreamProvider.family<GameRoom?, String>((
  ref,
  roomId,
) {
  final repo = ref.watch(roomRepositoryProvider);
  return repo.watchRoom(roomId);
});

final roomPlayersStreamProvider =
    StreamProvider.family<List<RoomPlayer>, String>((ref, roomId) {
      final repo = ref.watch(roomRepositoryProvider);
      return repo.watchRoomPlayers(roomId);
    });

class RoomController extends StateNotifier<AsyncValue<void>> {
  final RoomRepository _repository;

  RoomController(this._repository) : super(const AsyncValue.data(null));

  Future<String?> createRoom({
    required String jlptLevel,
    required String difficulty,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repository.createRoom(
        jlptLevel: jlptLevel,
        difficulty: difficulty,
      );
      state = const AsyncValue.data(null);
      return res['room_id'] as String?;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<String?> joinRoom({required String code}) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repository.joinRoom(code: code);
      state = const AsyncValue.data(null);
      return res['room_id'] as String?;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> toggleReady({
    required String roomId,
    required bool isReady,
  }) async {
    await _repository.toggleReady(roomId: roomId, isReady: isReady);
  }

  Future<void> startGame({required String roomId}) async {
    await _repository.startRoomGame(roomId: roomId);
  }

  Future<void> leaveRoom({required String roomId}) async {
    await _repository.leaveRoom(roomId: roomId);
  }
}

final roomControllerProvider =
    StateNotifierProvider<RoomController, AsyncValue<void>>((ref) {
      final repo = ref.watch(roomRepositoryProvider);
      return RoomController(repo);
    });
