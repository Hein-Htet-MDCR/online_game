import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../providers/room_provider.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  String _selectedLevel = 'N5';
  String _selectedDifficulty = 'easy';

  Future<void> _handleCreateRoom() async {
    final roomId = await ref
        .read(roomControllerProvider.notifier)
        .createRoom(jlptLevel: _selectedLevel, difficulty: _selectedDifficulty);

    if (mounted && roomId != null) {
      context.go('/lobby/$roomId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(roomControllerProvider);
    final isLoading = controllerState.isLoading;

    ref.listen<AsyncValue<void>>(roomControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create Private Room')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'JLPT Level',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['N5', 'N4'].map((level) {
                final isSelected = _selectedLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ChoiceChip(
                    label: Text(
                      level,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (val) {
                      if (val) setState(() => _selectedLevel = level);
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            const Text(
              'Difficulty Level',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children:
                  [
                    {'key': 'easy', 'title': 'Easy (Basic Words)'},
                    {'key': 'medium', 'title': 'Medium (Mixed Vocabulary)'},
                    {'key': 'hard', 'title': 'Hard (Advanced Challenge)'},
                  ].map((diff) {
                    final isSelected = _selectedDifficulty == diff['key'];
                    return RadioListTile<String>(
                      title: Text(diff['title']!),
                      value: diff['key']!,
                      groupValue: _selectedDifficulty,
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _selectedDifficulty = val);
                      },
                    );
                  }).toList(),
            ),

            const Spacer(),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _handleCreateRoom,
                child: const Text('Create Room Code & Enter Lobby'),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
