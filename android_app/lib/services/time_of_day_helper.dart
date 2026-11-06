class TimeOfDayHelper {
  /// Returns a contextual greeting with Apple Music style emoji
  static String getGreeting([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon ☕';
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening 🌆';
    } else {
      return 'Late Night Chill 🌙';
    }
  }

  /// Returns tailored modern music mood queries based on time of day
  /// (Strictly secular / musical; no devotional or rigid raga queries)
  static List<String> getCuratedMoods([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return [
        '☕ Morning Acoustic',
        '⚡ Fresh Hits',
        '☀️ Hindi Vibes',
        '🎧 Daily Mix',
      ];
    } else if (hour >= 12 && hour < 17) {
      return [
        '💻 Focus Lo-Fi',
        '☕ Coffee & Chill',
        '⚡ Bollywood Classics',
        '🎧 Chill Pop',
      ];
    } else if (hour >= 17 && hour < 22) {
      return [
        '🔥 Gym & Workout',
        '🥁 Punjabi Party',
        '🌾 Bhojpuri Beats',
        '⚡ Trending Hits',
      ];
    } else {
      return [
        '🌙 Midnight Romance',
        '💔 Heartbreak Hits',
        '✨ Lo-Fi Slowed',
        '🌌 Chill Acoustic',
      ];
    }
  }
}
