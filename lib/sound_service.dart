import 'package:just_audio/just_audio.dart';

enum SoundEffect {
  tap,
  success,
  error,
  startWorkout,
  stopWorkout,
}

class SoundService {
  late final AudioPlayer _player;

  SoundService() {
    _player = AudioPlayer();
  }

  Future<void> play(SoundEffect effect) async {
    try {
      String? assetPath;
      switch (effect) {
        case SoundEffect.tap:
          assetPath = 'assets/sounds/tap.wav';
          break;
        case SoundEffect.success:
          assetPath = 'assets/sounds/success.wav';
          break;
        case SoundEffect.error:
          assetPath = 'assets/sounds/error.wav';
          break;
        case SoundEffect.startWorkout:
          assetPath = 'assets/sounds/start_workout.wav';
          break;
        case SoundEffect.stopWorkout:
          assetPath = 'assets/sounds/stop_workout.wav';
          break;
      }
      await _player.setAsset(assetPath);
      _player.play();
    } catch (e) {
      // Silently fail if sound doesn't play
      print("Error playing sound: $e");
    }
  }

  void dispose() {
    _player.dispose();
  }
}
