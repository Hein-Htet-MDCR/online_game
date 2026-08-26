import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/leaderboard_entry.dart';
import '../../domain/match_history_item.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LeaderboardRepository(supabase);
});

final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((
  ref,
) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.getLeaderboard();
});

final userMatchHistoryProvider =
    FutureProvider.autoDispose<List<MatchHistoryItem>>((ref) async {
      final repo = ref.watch(leaderboardRepositoryProvider);
      final currentUser = ref.watch(supabaseClientProvider).auth.currentUser;

      if (currentUser == null) return [];
      return repo.getUserMatchHistory(currentUser.id);
    });
