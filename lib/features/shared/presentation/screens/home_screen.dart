import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vocabulary/presentation/providers/vocabulary_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedLevel = 'N5';
  String? _selectedDifficulty;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final vocabFilter = VocabularyFilter(
      jlptLevel: _selectedLevel,
      difficulty: _selectedDifficulty,
    );
    final vocabAsync = ref.watch(vocabularyListProvider(vocabFilter));

    return Column(
      children: [
        const SizedBox(height: 12),
        // User Profile Header
        profileAsync.when(
          data: (profile) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  backgroundImage:
                      (profile?.avatarUrl != null &&
                          profile!.avatarUrl.isNotEmpty)
                      ? NetworkImage(profile.avatarUrl)
                      : null,
                  child:
                      (profile?.avatarUrl == null || profile!.avatarUrl.isEmpty)
                      ? Text(
                          profile?.displayName.isNotEmpty == true
                              ? profile!.displayName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? 'Player',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        profile?.email ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (err, stack) => Text('Error loading profile: $err'),
        ),

        const SizedBox(height: 16),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.createRoom),
                child: const Text(
                  'Create Room',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.joinRoom),
                child: const Text('Join Room', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.push(AppRoutes.matchmaking),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: const Text('Random Matchmaking'),
        ),

        const SizedBox(height: 16),

        // Phase 3 Vocabulary Filter & List Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vocabulary Explorer (N5 / N4 Only)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Level Selector
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('N5'),
                    selected: _selectedLevel == 'N5',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedLevel = 'N5');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('N4'),
                    selected: _selectedLevel == 'N4',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedLevel = 'N4');
                    },
                  ),
                  const Spacer(),
                  // Difficulty Selector
                  DropdownButton<String?>(
                    value: _selectedDifficulty,
                    hint: const Text(
                      'All Diff',
                      style: TextStyle(fontSize: 12),
                    ),
                    dropdownColor: AppColors.background,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedDifficulty = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Vocabulary Cards
        Expanded(
          child: vocabAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No vocabulary items found.'));
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    color: AppColors.background.withOpacity(0.8),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        '${item.japanese} (${item.hiragana})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '${item.romaji} • ${item.english} • MM: ${item.myanmar}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.jlptLevel} [${item.difficulty}]',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
