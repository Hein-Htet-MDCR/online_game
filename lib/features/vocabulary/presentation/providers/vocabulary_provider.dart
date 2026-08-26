import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/vocabulary_repository.dart';
import '../../domain/vocabulary_item.dart';

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return VocabularyRepository(supabase);
});

class VocabularyFilter {
  final String jlptLevel; // 'N5' or 'N4'
  final String? difficulty; // null, 'easy', 'medium', 'hard'

  const VocabularyFilter({
    required this.jlptLevel,
    this.difficulty,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyFilter &&
          runtimeType == other.runtimeType &&
          jlptLevel == other.jlptLevel &&
          difficulty == other.difficulty;

  @override
  int get hashCode => jlptLevel.hashCode ^ difficulty.hashCode;
}

final vocabularyListProvider =
    FutureProvider.family<List<VocabularyItem>, VocabularyFilter>((ref, filter) async {
  final repository = ref.watch(vocabularyRepositoryProvider);
  return await repository.getVocabulary(
    jlptLevel: filter.jlptLevel,
    difficulty: filter.difficulty,
  );
});