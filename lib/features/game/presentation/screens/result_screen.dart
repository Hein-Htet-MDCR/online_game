import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String gameId;
  const ResultScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Game Over - ID: $gameId'));
  }
}
