import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:online_game/features/game/data/game_repository.dart';
import 'package:online_game/features/game/domain/game_card_tile.dart';
import 'package:online_game/features/game/domain/game_session.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/services/audio_service.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return GameRepository(supabase);
});

final gameSessionStreamProvider = StreamProvider.family<GameSession?, String>((
  ref,
  roomId,
) {
  final repo = ref.watch(gameRepositoryProvider);
  return repo.watchSession(roomId);
});

class GameBoardState {
  final List<GameCardTile> tiles;
  final GameCardTile? selectedTile;
  final bool isChecking;

  const GameBoardState({
    required this.tiles,
    this.selectedTile,
    this.isChecking = false,
  });

  GameBoardState copyWith({
    List<GameCardTile>? tiles,
    GameCardTile? selectedTile,
    bool clearSelected = false,
    bool? isChecking,
  }) {
    return GameBoardState(
      tiles: tiles ?? this.tiles,
      selectedTile: clearSelected ? null : (selectedTile ?? this.selectedTile),
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

class GameBoardController extends StateNotifier<GameBoardState> {
  final GameRepository _repository;
  final AudioService _audioService;
  final String _sessionId;
  List<String> _syncedMatchedIds = [];

  GameBoardController(this._repository, this._audioService, this._sessionId)
    : super(const GameBoardState(tiles: []));

  void initializeBoard(GameSession session) {
    if (state.tiles.isNotEmpty &&
        _syncedMatchedIds.length == session.matchedVocabIds.length) {
      return;
    }

    _syncedMatchedIds = List.from(session.matchedVocabIds);

    if (state.tiles.isEmpty) {
      final List<GameCardTile> tilesList = [];
      for (var item in session.vocabItems) {
        tilesList.add(
          GameCardTile(
            tileId: 'jp_${item.id}',
            vocabId: item.id,
            displayText: item.japanese,
            secondaryText: item.hiragana,
            type: CardTileType.japanese,
            isMatched: session.matchedVocabIds.contains(item.id),
          ),
        );
        tilesList.add(
          GameCardTile(
            tileId: 'mm_${item.id}',
            vocabId: item.id,
            displayText: item.myanmar,
            secondaryText: item.romaji,
            type: CardTileType.myanmar,
            isMatched: session.matchedVocabIds.contains(item.id),
          ),
        );
      }
      tilesList.shuffle();
      state = GameBoardState(tiles: tilesList);
    } else {
      final updatedTiles = state.tiles.map((tile) {
        final isRemoteMatched = session.matchedVocabIds.contains(tile.vocabId);
        return tile.copyWith(isMatched: tile.isMatched || isRemoteMatched);
      }).toList();
      state = state.copyWith(tiles: updatedTiles);
    }
  }

  Future<void> onTileTap(GameCardTile tappedTile) async {
    if (state.isChecking || tappedTile.isMatched || tappedTile.isSelected)
      return;

    _audioService.playCardTap();
    final firstTile = state.selectedTile;

    if (firstTile == null) {
      final updatedTiles = state.tiles.map((t) {
        return t.tileId == tappedTile.tileId ? t.copyWith(isSelected: true) : t;
      }).toList();

      state = state.copyWith(tiles: updatedTiles, selectedTile: tappedTile);
      return;
    }

    if (firstTile.tileId == tappedTile.tileId) {
      final updatedTiles = state.tiles.map((t) {
        return t.tileId == tappedTile.tileId
            ? t.copyWith(isSelected: false)
            : t;
      }).toList();

      state = state.copyWith(tiles: updatedTiles, clearSelected: true);
      return;
    }

    final tempTiles = state.tiles.map((t) {
      return t.tileId == tappedTile.tileId ? t.copyWith(isSelected: true) : t;
    }).toList();

    state = state.copyWith(tiles: tempTiles, isChecking: true);

    final isMatch =
        (firstTile.vocabId == tappedTile.vocabId) &&
        (firstTile.type != tappedTile.type);

    if (isMatch) {
      _audioService.playMatchSuccess();

      final matchedTiles = state.tiles.map((t) {
        if (t.vocabId == firstTile.vocabId) {
          return t.copyWith(isMatched: true, isSelected: false);
        }
        return t;
      }).toList();

      state = state.copyWith(
        tiles: matchedTiles,
        clearSelected: true,
        isChecking: false,
      );

      await _repository.submitMatch(
        sessionId: _sessionId,
        vocabId: firstTile.vocabId,
        points: 100,
      );
    } else {
      _audioService.playMatchError();

      await Future.delayed(const Duration(milliseconds: 600));

      final resetTiles = state.tiles.map((t) {
        if (t.tileId == firstTile.tileId || t.tileId == tappedTile.tileId) {
          return t.copyWith(isSelected: false);
        }
        return t;
      }).toList();

      state = state.copyWith(
        tiles: resetTiles,
        clearSelected: true,
        isChecking: false,
      );
    }
  }
}

final gameBoardControllerProvider = StateNotifierProvider.family
    .autoDispose<GameBoardController, GameBoardState, String>((ref, sessionId) {
      final repo = ref.watch(gameRepositoryProvider);
      final audio = ref.watch(audioServiceProvider);
      return GameBoardController(repo, audio, sessionId);
    });
