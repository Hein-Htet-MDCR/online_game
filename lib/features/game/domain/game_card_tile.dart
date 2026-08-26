enum CardTileType { japanese, myanmar }

class GameCardTile {
  final String tileId;
  final String vocabId;
  final String displayText;
  final String secondaryText;
  final CardTileType type;
  final bool isMatched;
  final bool isSelected;

  const GameCardTile({
    required this.tileId,
    required this.vocabId,
    required this.displayText,
    required this.secondaryText,
    required this.type,
    this.isMatched = false,
    this.isSelected = false,
  });

  GameCardTile copyWith({bool? isMatched, bool? isSelected}) {
    return GameCardTile(
      tileId: tileId,
      vocabId: vocabId,
      displayText: displayText,
      secondaryText: secondaryText,
      type: type,
      isMatched: isMatched ?? this.isMatched,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
