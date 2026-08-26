import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:online_game/features/game/data/game_repository.dart';
import 'package:online_game/features/game/domain/game_card_tile.dart';
import 'package:online_game/features/game/domain/game_session.dart';
import '../../../../core/providers/supabase_provider.dart';


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
  final String _sessionId;
  List<String> _syncedMatchedIds = [];

  GameBoardController(this._repository, this._sessionId)
    : super(const GameBoardState(tiles: []));

  /// Initialize and shuffle 20 card tiles (10 Japanese + 10 Myanmar)
  void initializeBoard(GameSession session) {
    if (state.tiles.isNotEmpty &&
        _syncedMatchedIds.length == session.matchedVocabIds.length) {
      return;
    }

    _syncedMatchedIds = List.from(session.matchedVocabIds);

    // If board empty, construct tiles
    if (state.tiles.isEmpty) {
      final List<GameCardTile> tilesList = [];
      for (var item in session.vocabItems) {
        // Japanese Tile
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
        // Myanmar Tile
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
      // Sync remote matches to local tiles
      final updatedTiles = state.tiles.map((tile) {
        final isRemoteMatched = session.matchedVocabIds.contains(tile.vocabId);
        return tile.copyWith(isMatched: tile.isMatched || isRemoteMatched);
      }).toList();
      state = state.copyWith(tiles: updatedTiles);
    }
  }

  /// Handle tile click logic
  Future<void> onTileTap(GameCardTile tappedTile) async {
    if (state.isChecking || tappedTile.isMatched || tappedTile.isSelected)
      return;

    final firstTile = state.selectedTile;

    // First tile selection
    if (firstTile == null) {
      final updatedTiles = state.tiles.map((t) {
        return t.tileId == tappedTile.tileId ? t.copyWith(isSelected: true) : t;
      }).toList();

      state = state.copyWith(tiles: updatedTiles, selectedTile: tappedTile);
      return;
    }

    // Tapped the same tile again -> deselect
    if (firstTile.tileId == tappedTile.tileId) {
      final updatedTiles = state.tiles.map((t) {
        return t.tileId == tappedTile.tileId
            ? t.copyWith(isSelected: false)
            : t;
      }).toList();

      state = state.copyWith(tiles: updatedTiles, clearSelected: true);
      return;
    }

    // Highlight second tile temporarily
    final tempTiles = state.tiles.map((t) {
      return t.tileId == tappedTile.tileId ? t.copyWith(isSelected: true) : t;
    }).toList();

    state = state.copyWith(tiles: tempTiles, isChecking: true);

    // Check Match
    final isMatch =
        (firstTile.vocabId == tappedTile.vocabId) &&
        (firstTile.type != tappedTile.type);

    if (isMatch) {
      // Correct Match!
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

      // Submit to RPC
      await _repository.submitMatch(
        sessionId: _sessionId,
        vocabId: firstTile.vocabId,
        points: 100,
      );
    } else {
      // Incorrect Match -> delay 600ms then flip back
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
      return GameBoardController(repo, sessionId);
    });
