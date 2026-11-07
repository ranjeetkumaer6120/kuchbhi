import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/services/time_of_day_helper.dart';

void main() {
  group('TimeOfDayHelper Tests', () {
    final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true);

    test('returns Morning greeting and moods between 5 AM and 11:59 AM (strictly icon-free)', () {
      final morningTime = DateTime(2026, 11, 5, 8, 30);
      final greeting = TimeOfDayHelper.getGreeting(morningTime);
      expect(greeting, contains('Good Morning'));
      expect(emojiRegex.hasMatch(greeting), isFalse);

      final moods = TimeOfDayHelper.getCuratedMoods(morningTime);
      expect(moods, contains('Morning Acoustic'));
      expect(moods.any((m) => emojiRegex.hasMatch(m)), isFalse);
      expect(moods.any((m) => m.toLowerCase().contains('bhakti')), isFalse);
      expect(moods.any((m) => m.toLowerCase().contains('raga')), isFalse);
    });

    test('returns Afternoon greeting and moods between 12 PM and 4:59 PM (strictly icon-free)', () {
      final afternoonTime = DateTime(2026, 11, 5, 14, 0);
      final greeting = TimeOfDayHelper.getGreeting(afternoonTime);
      expect(greeting, contains('Good Afternoon'));
      expect(emojiRegex.hasMatch(greeting), isFalse);

      final moods = TimeOfDayHelper.getCuratedMoods(afternoonTime);
      expect(moods, contains('Focus Lo-Fi'));
      expect(moods.any((m) => emojiRegex.hasMatch(m)), isFalse);
    });

    test('returns Evening greeting and moods between 5 PM and 9:59 PM (strictly icon-free)', () {
      final eveningTime = DateTime(2026, 11, 5, 19, 0);
      final greeting = TimeOfDayHelper.getGreeting(eveningTime);
      expect(greeting, contains('Good Evening'));
      expect(emojiRegex.hasMatch(greeting), isFalse);

      final moods = TimeOfDayHelper.getCuratedMoods(eveningTime);
      expect(moods, contains('Gym & Workout'));
      expect(moods.any((m) => emojiRegex.hasMatch(m)), isFalse);
    });

    test('returns Late Night greeting and moods between 10 PM and 4:59 AM (strictly icon-free)', () {
      final nightTime = DateTime(2026, 11, 5, 23, 30);
      final greeting = TimeOfDayHelper.getGreeting(nightTime);
      expect(greeting, contains('Late Night'));
      expect(emojiRegex.hasMatch(greeting), isFalse);

      final moods = TimeOfDayHelper.getCuratedMoods(nightTime);
      expect(moods, contains('Midnight Romance'));
      expect(moods.any((m) => emojiRegex.hasMatch(m)), isFalse);
    });
  });
}
