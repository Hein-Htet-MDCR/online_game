class VocabularyItem {
  final String id;
  final String japanese;
  final String hiragana;
  final String romaji;
  final String english;
  final String myanmar;
  final String jlptLevel; // 'N5' or 'N4'
  final String category;
  final String difficulty; // 'easy', 'medium', 'hard'

  const VocabularyItem({
    required this.id,
    required this.japanese,
    required this.hiragana,
    required this.romaji,
    required this.english,
    required this.myanmar,
    required this.jlptLevel,
    required this.category,
    required this.difficulty,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id']?.toString() ?? '',
      japanese: json['japanese']?.toString() ?? '',
      hiragana: json['hiragana']?.toString() ?? '',
      romaji: json['romaji']?.toString() ?? '',
      english: json['english']?.toString() ?? '',
      myanmar: json['myanmar']?.toString() ?? '',
      jlptLevel: json['jlpt_level']?.toString() ?? 'N5',
      category: json['category']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'easy',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'japanese': japanese,
      'hiragana': hiragana,
      'romaji': romaji,
      'english': english,
      'myanmar': myanmar,
      'jlpt_level': jlptLevel,
      'category': category,
      'difficulty': difficulty,
    };
  }
}
