import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioPlayerService Speed & Lo-Fi Tests', () {
    test('default playback speed is 1.0 and isLoFiMode is false', () {
      final service = AudioPlayerService();
      expect(service.playbackSpeed, 1.0);
      expect(service.isLoFiMode, isFalse);
    });

    test('setSpeed updates playback speed', () async {
      final service = AudioPlayerService();
      await service.setSpeed(1.25);
      expect(service.playbackSpeed, 1.25);
      expect(service.isLoFiMode, isFalse);
    });

    test('toggleLoFiMode switches to 0.85x slowed speed and toggles back', () async {
      final service = AudioPlayerService();
      await service.toggleLoFiMode();
      expect(service.isLoFiMode, isTrue);
      expect(service.playbackSpeed, 0.85);

      await service.toggleLoFiMode();
      expect(service.isLoFiMode, isFalse);
      expect(service.playbackSpeed, 1.0);
    });
  });
}
