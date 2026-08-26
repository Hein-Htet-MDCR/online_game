import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stats & Leaderboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.leaderboard), text: 'Global Ranking'),
              Tab(icon: Icon(Icons.history), text: 'Match History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_GlobalLeaderboardTab(), _MatchHistoryTab()],
        ),
      ),
    );
  }
}

class _GlobalLeaderboardTab extends ConsumerWidget {
  const _GlobalLeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('No ranked games recorded yet.'));
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(leaderboardProvider),
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final rank = index + 1;

              Widget rankBadge;
              if (rank == 1) {
                rankBadge = const Text('🥇', style: TextStyle(fontSize: 24));
              } else if (rank == 2) {
                rankBadge = const Text('🥈', style: TextStyle(fontSize: 24));
              } else if (rank == 3) {
                rankBadge = const Text('🥉', style: TextStyle(fontSize: 24));
              } else {
                rankBadge = CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    '$rank',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                );
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: SizedBox(width: 40, child: Center(child: rankBadge)),
                  title: Text(
                    entry.username,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${entry.wins} Wins • ${entry.totalGames} Games Played',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    '${entry.totalScore} pts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Failed to load leaderboard: $err')),
    );
  }
}

class _MatchHistoryTab extends ConsumerWidget {
  const _MatchHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(userMatchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const Center(child: Text('No match history available.'));
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(userMatchHistoryProvider),
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];

              Color statusColor = Colors.orange;
              String resultText = 'DRAW';

              if (!item.isDraw) {
                if (item.isWinner) {
                  statusColor = Colors.green;
                  resultText = 'WIN';
                } else {
                  statusColor = Colors.redAccent;
                  resultText = 'LOSS';
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      resultText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'vs ',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.opponentName,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Score: ${item.userScore} - ${item.opponentScore}\n'
                    '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Failed to load match history: $err')),
    );
  }
}
