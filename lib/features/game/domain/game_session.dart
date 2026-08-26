import '../../vocabulary/domain/vocabulary_item.dart';

class GameSession {
  final String id;
  final String roomId;
  final List<VocabularyItem> vocabItems;
  final List<String> matchedVocabIds;
  final String hostId;
  final String guestId;
  final int hostScore;
  final int guestScore;
  final String status;
  final String? winnerId;
  final DateTime createdAt;

  const GameSession({
    required this.id,
    required this.roomId,
    required this.vocabItems,
    required this.matchedVocabIds,
    required this.hostId,
    required this.guestId,
    required this.hostScore,
    required this.guestScore,
    required this.status,
    this.winnerId,
    required this.createdAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final rawVocab = json['vocab_items'] as List<dynamic>? ?? [];
    final items = rawVocab
        .map(
          (e) => VocabularyItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    final rawMatched = json['matched_vocab_ids'] as List<dynamic>? ?? [];
    final matchedList = rawMatched.map((e) => e.toString()).toList();

    return GameSession(
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      vocabItems: items,
      matchedVocabIds: matchedList,
      hostId: json['host_id']?.toString() ?? '',
      guestId: json['guest_id']?.toString() ?? '',
      hostScore: json['host_score'] as int? ?? 0,
      guestScore: json['guest_score'] as int? ?? 0,
      status: json['status']?.toString() ?? 'playing',
      winnerId: json['winner_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
}
