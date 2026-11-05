import 'dart:async';
import 'package:flutter/foundation.dart';

enum SleepTimerDuration {
  fifteen(Duration(minutes: 15), '15 minutes'),
  thirty(Duration(minutes: 30), '30 minutes'),
  fortyFive(Duration(minutes: 45), '45 minutes'),
  sixty(Duration(minutes: 60), '1 hour'),
  endOfSong(Duration.zero, 'End of track');

  final Duration duration;
  final String label;
  const SleepTimerDuration(this.duration, this.label);
}

class SleepTimerService extends ChangeNotifier {
  static final SleepTimerService instance = SleepTimerService();

  Timer? _ticker;
  int _remainingSeconds = 0;
  bool _isEndOfSongMode = false;
  Future<void> Function()? _onTimerComplete;
  Future<void> Function(double volume)? _onVolumeRamp;

  bool get isActive => (_ticker != null && _ticker!.isActive) || _isEndOfSongMode;
  int get remainingSeconds => _remainingSeconds;
  bool get isEndOfSongMode => _isEndOfSongMode;

  String get formattedRemainingTime {
    if (_isEndOfSongMode) return 'End of track';
    if (!isActive || _remainingSeconds <= 0) return 'Off';

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startTimer({
    required Duration duration,
    required Future<void> Function() onTimerComplete,
    required Future<void> Function(double volume) onVolumeRamp,
  }) {
    cancelTimer();

    _onTimerComplete = onTimerComplete;
    _onVolumeRamp = onVolumeRamp;
    _remainingSeconds = duration.inSeconds;
    _isEndOfSongMode = false;

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;

        // Over the last 10 seconds, smoothly ramp down volume (1.0 -> 0.0)
        if (_remainingSeconds <= 10 && _remainingSeconds >= 0) {
          final rampVolume = (_remainingSeconds / 10.0).clamp(0.0, 1.0);
          if (_onVolumeRamp != null) {
            await _onVolumeRamp!(rampVolume);
          }
        }

        notifyListeners();
      } else {
        await _triggerCompletion();
      }
    });

    notifyListeners();
  }

  void enableEndOfSongMode({
    required Future<void> Function() onTimerComplete,
  }) {
    cancelTimer();
    _isEndOfSongMode = true;
    _onTimerComplete = onTimerComplete;
    notifyListeners();
  }

  Future<void> onSongCompleted() async {
    if (_isEndOfSongMode) {
      await _triggerCompletion();
    }
  }

  Future<void> _triggerCompletion() async {
    _ticker?.cancel();
    _ticker = null;
    _remainingSeconds = 0;
    _isEndOfSongMode = false;

    if (_onTimerComplete != null) {
      await _onTimerComplete!();
    }

    // Restore volume to 1.0 for future playback
    if (_onVolumeRamp != null) {
      await _onVolumeRamp!(1.0);
    }

    notifyListeners();
  }

  Future<void> cancelTimer() async {
    _ticker?.cancel();
    _ticker = null;
    _remainingSeconds = 0;
    _isEndOfSongMode = false;

    // Restore volume to 1.0
    if (_onVolumeRamp != null) {
      await _onVolumeRamp!(1.0);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
