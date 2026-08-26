import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:online_game/core/services/audio_service.dart';
import 'package:online_game/features/game/domain/game_card_tile.dart';
import 'package:online_game/features/game/domain/game_session.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_routes.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/game_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String roomId;
  const GameScreen({super.key, required this.roomId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkAndStartGame();
  }

  Future<void> _checkAndStartGame() async {
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final repo = ref.read(gameRepositoryProvider);

    try {
      // Host initializes session if not already started
      await repo.startSession(widget.roomId);
    } catch (_) {
      // Guest or session already running, ignore error
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing Japanese-Myanmar match cards...'),
            ],
          ),
        ),
      );
    }

    final sessionAsync = ref.watch(gameSessionStreamProvider(widget.roomId));
    final currentUserId = ref
        .watch(supabaseClientProvider)
        .auth
        .currentUser
        ?.id;

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('Game session missing.')),
          );
        }

        final isHost = session.hostId == currentUserId;
        final myScore = isHost ? session.hostScore : session.guestScore;
        final opponentScore = isHost ? session.guestScore : session.hostScore;
        final matchedCount = session.matchedVocabIds.length;

        // Initialize board tiles once session arrives
        final boardNotifier = ref.read(
          gameBoardControllerProvider(session.id).notifier,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          boardNotifier.initializeBoard(session);
        });

        final boardState = ref.watch(gameBoardControllerProvider(session.id));

        // Show Game Over Dialog if finished
        if (session.status == 'finished') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showGameOverDialog(context, session, currentUserId);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Matching Battle'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Scoreboard Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ScoreItem(label: 'YOU', score: myScore, isMe: true),
                      Column(
                        children: [
                          const Text(
                            'PAIRS',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$matchedCount / 10',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      _ScoreItem(
                        label: 'OPPONENT',
                        score: opponentScore,
                        isMe: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Match Progress Indicator
                LinearProgressIndicator(
                  value: matchedCount / 10.0,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),

                const SizedBox(height: 16),

                // 4x5 Cards Grid
                Expanded(
                  child: boardState.tiles.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: boardState.tiles.length,
                          itemBuilder: (context, index) {
                            final tile = boardState.tiles[index];
                            return _CardTileWidget(
                              tile: tile,
                              onTap: () {
                                boardNotifier.onTileTap(tile);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  void _showGameOverDialog(
    BuildContext context,
    GameSession session,
    String? currentUserId,
  ) {
    final audio = ref.read(audioServiceProvider);
    final bool isDraw = session.winnerId == null;
    final bool isWinner = session.winnerId == currentUserId;

    if (isWinner) {
      audio.playVictory();
    } else if (!isDraw) {
      audio.playDefeat();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          isDraw
              ? 'IT\'S A DRAW!'
              : isWinner
              ? 'VICTORY! 🎉'
              : 'DEFEAT 💔',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDraw
                ? Colors.orange
                : isWinner
                ? Colors.green
                : Colors.redAccent,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Host Score: ${session.hostScore}'),
            Text('Guest Score: ${session.guestScore}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go(AppRoutes.home);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final int score;
  final bool isMe;

  const _ScoreItem({
    required this.label,
    required this.score,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isMe ? AppColors.primary : Colors.white60,
          ),
        ),
        Text(
          '$score',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _CardTileWidget extends StatelessWidget {
  final GameCardTile tile;
  final VoidCallback onTap;

  const _CardTileWidget({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (tile.isMatched) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(
          child: Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 24,
          ),
        ),
      );
    }

    final isSelected = tile.isSelected;
    final isJapanese = tile.type == CardTileType.japanese;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.8)
              : isJapanese
              ? Colors.blueGrey.shade800
              : Colors.deepPurple.shade900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tile.displayText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isJapanese ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (tile.secondaryText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                tile.secondaryText,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Colors.white60),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
