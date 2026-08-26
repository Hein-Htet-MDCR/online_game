import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:online_game/features/room/domain/room_player.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_routes.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/room_provider.dart';

class LobbyScreen extends ConsumerWidget {
  final String roomId;
  const LobbyScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomStreamProvider(roomId));
    final playersAsync = ref.watch(roomPlayersStreamProvider(roomId));
    final currentUserId = ref
        .watch(supabaseClientProvider)
        .auth
        .currentUser
        ?.id;

    ref.listen(roomStreamProvider(roomId), (prev, next) {
      next.whenData((room) {
        if (room == null || room.status == 'cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room was closed by host.')),
          );
          context.go(AppRoutes.home);
        } else if (room.status == 'starting' || room.status == 'playing') {
          context.go('/game/${room.id}');
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await ref
                .read(roomControllerProvider.notifier)
                .leaveRoom(roomId: roomId);
            if (context.mounted) context.go(AppRoutes.home);
          },
        ),
      ),
      body: roomAsync.when(
        data: (room) {
          if (room == null)
            return const Center(child: Text('Room unavailable.'));

          return playersAsync.when(
            data: (players) {
              final me = players.firstWhere(
                (p) => p.playerId == currentUserId,
                orElse: () => RoomPlayer(
                  id: '',
                  roomId: '',
                  playerId: '',
                  isHost: false,
                  isReady: false,
                  joinedAt: DateTime.now(),
                ),
              );
              final isHost = me.isHost;
              final opponent = players.firstWhere(
                (p) => p.playerId != currentUserId,
                orElse: () => RoomPlayer(
                  id: '',
                  roomId: '',
                  playerId: '',
                  isHost: false,
                  isReady: false,
                  joinedAt: DateTime.now(),
                ),
              );
              final hasOpponent = opponent.playerId.isNotEmpty;
              final canStart = isHost && hasOpponent && opponent.isReady;

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Room Code Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'ROOM CODE',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                room.code,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                  color: AppColors.accent,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  color: AppColors.accent,
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: room.code),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Room code copied!'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Text(
                            'Level: ${room.jlptLevel} • Difficulty: ${room.difficulty.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Players Section
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _PlayerCard(player: me, isMe: true)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: hasOpponent
                                ? _PlayerCard(player: opponent, isMe: false)
                                : Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white24,
                                        style: BorderStyle.solid,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 12),
                                          Text(
                                            'Waiting for\nfriend...',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Controls
                    if (!isHost)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: me.isReady
                              ? Colors.orange
                              : AppColors.primary,
                        ),
                        onPressed: () {
                          ref
                              .read(roomControllerProvider.notifier)
                              .toggleReady(
                                roomId: roomId,
                                isReady: !me.isReady,
                              );
                        },
                        child: Text(me.isReady ? 'Unready' : 'I am Ready!'),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canStart
                              ? AppColors.primary
                              : Colors.grey.shade800,
                        ),
                        onPressed: canStart
                            ? () {
                                ref
                                    .read(roomControllerProvider.notifier)
                                    .startGame(roomId: roomId);
                              }
                            : null,
                        child: Text(
                          canStart
                              ? 'Start Game'
                              : 'Waiting for Guest to Ready',
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading room: $err')),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final RoomPlayer player;
  final bool isMe;

  const _PlayerCard({required this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: player.isReady ? Colors.green : Colors.white12,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary,
            child: Text(
              player.displayName != null && player.displayName!.isNotEmpty
                  ? player.displayName![0].toUpperCase()
                  : 'P',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            player.displayName ?? 'Player',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            player.isHost ? 'Host' : 'Guest',
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Chip(
            backgroundColor: player.isReady
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            avatar: Icon(
              player.isReady ? Icons.check_circle : Icons.hourglass_empty,
              size: 16,
              color: player.isReady ? Colors.green : Colors.redAccent,
            ),
            label: Text(
              player.isReady ? 'READY' : 'NOT READY',
              style: TextStyle(
                color: player.isReady ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
