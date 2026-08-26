import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/vocabulary_item.dart';

class VocabularyRepository {
  final SupabaseClient _supabase;

  VocabularyRepository(this._supabase);

  /// Fetch vocabulary filtered by JLPT level ('N5' or 'N4') and optional difficulty
  Future<List<VocabularyItem>> getVocabulary({
    required String jlptLevel,
    String? difficulty,
    int limit = 20,
  }) async {
    assert(
      jlptLevel == 'N5' || jlptLevel == 'N4',
      'Only N5 and N4 levels are supported.',
    );

    var query = _supabase
        .from('vocabulary')
        .select()
        .eq('jlpt_level', jlptLevel);

    if (difficulty != null && difficulty.isNotEmpty) {
      query = query.eq('difficulty', difficulty);
    }

    final response = await query.limit(limit);
    final data = response as List<dynamic>;

    return data
        .map((item) => VocabularyItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetch 10 random word pairs for a game round matching criteria
  Future<List<VocabularyItem>> getRandomGamePairs({
    required String jlptLevel,
    required String difficulty,
    int count = 10,
  }) async {
    final list = await getVocabulary(
      jlptLevel: jlptLevel,
      difficulty: difficulty,
      limit: 50,
    );
    list.shuffle();
    return list.take(count).toList();
  }
}
