import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/services/sleep_timer_service.dart';

void main() {
  group('SleepTimerService Tests', () {
    test('SleepTimerService initializes in inactive state', () {
      final timer = SleepTimerService();
      expect(timer.isActive, isFalse);
      expect(timer.remainingSeconds, 0);
      expect(timer.formattedRemainingTime, 'Off');
    });

    test('startTimer activates timer and sets duration', () {
      final timer = SleepTimerService();
      timer.startTimer(
        duration: const Duration(minutes: 15),
        onTimerComplete: () async {},
        onVolumeRamp: (vol) async {},
      );

      expect(timer.isActive, isTrue);
      expect(timer.remainingSeconds, 15 * 60);
      expect(timer.formattedRemainingTime, '15:00');
      timer.cancelTimer();
      expect(timer.isActive, isFalse);
    });

    test('cancelTimer resets state and restores volume', () async {
      final timer = SleepTimerService();
      double? setVolume;
      timer.startTimer(
        duration: const Duration(minutes: 30),
        onTimerComplete: () async {},
        onVolumeRamp: (vol) async {
          setVolume = vol;
        },
      );

      expect(timer.isActive, isTrue);
      await timer.cancelTimer();
      expect(timer.isActive, isFalse);
      expect(timer.remainingSeconds, 0);
      expect(setVolume, 1.0);
    });
  });
}
