import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioService {
  final AudioPlayer _sfxPlayer = AudioPlayer();

  AudioService() {
    // Release mode for low latency sound effects
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // Gracefully handle browser autoplay restrictions or missing asset
    }
  }

  void playCardTap() => _playSound('audio/card_tap.wav');
  void playMatchSuccess() => _playSound('audio/match_success.wav');
  void playMatchError() => _playSound('audio/match_error.wav');
  void playVictory() => _playSound('audio/victory.wav');
  void playDefeat() => _playSound('audio/defeat.wav');

  void dispose() {
    _sfxPlayer.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
