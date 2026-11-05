import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/services/time_of_day_helper.dart';

void main() {
  group('TimeOfDayHelper Tests', () {
    test('returns Morning greeting and moods between 5 AM and 11:59 AM', () {
      final morningTime = DateTime(2026, 11, 5, 8, 30);
      expect(TimeOfDayHelper.getGreeting(morningTime), contains('Good Morning'));
      final moods = TimeOfDayHelper.getCuratedMoods(morningTime);
      expect(moods, contains('☕ Morning Ragas'));
    });

    test('returns Afternoon greeting and moods between 12 PM and 4:59 PM', () {
      final afternoonTime = DateTime(2026, 11, 5, 14, 0);
      expect(TimeOfDayHelper.getGreeting(afternoonTime), contains('Good Afternoon'));
      final moods = TimeOfDayHelper.getCuratedMoods(afternoonTime);
      expect(moods, contains('💻 Focus Lo-Fi'));
    });

    test('returns Evening greeting and moods between 5 PM and 9:59 PM', () {
      final eveningTime = DateTime(2026, 11, 5, 19, 0);
      expect(TimeOfDayHelper.getGreeting(eveningTime), contains('Good Evening'));
      final moods = TimeOfDayHelper.getCuratedMoods(eveningTime);
      expect(moods, contains('🔥 Gym & Workout'));
    });

    test('returns Late Night greeting and moods between 10 PM and 4:59 AM', () {
      final nightTime = DateTime(2026, 11, 5, 23, 30);
      expect(TimeOfDayHelper.getGreeting(nightTime), contains('Late Night'));
      final moods = TimeOfDayHelper.getCuratedMoods(nightTime);
      expect(moods, contains('🌙 Midnight Romance'));
    });
  });
}
