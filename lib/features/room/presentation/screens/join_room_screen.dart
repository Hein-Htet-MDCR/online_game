import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../providers/room_provider.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinRoom() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room code must be 6 characters long.')),
      );
      return;
    }

    final roomId = await ref
        .read(roomControllerProvider.notifier)
        .joinRoom(code: code);

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
      appBar: AppBar(title: const Text('Join Room')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.meeting_room_rounded,
              size: 72,
              color: AppColors.accent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter Room Code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your friend for the 6-character room code.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'XXXXXX',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            if (isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _handleJoinRoom,
                child: const Text('Join Lobby'),
              ),
          ],
        ),
      ),
    );
  }
}
