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

  /// Returns 4-5 tailored music mood queries based on time of day
  static List<String> getCuratedMoods([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return [
        '☕ Morning Ragas',
        '🌸 Bhakti Hits',
        '☀️ Acoustic Hindi',
        '🧘 Peaceful Meditation',
      ];
    } else if (hour >= 12 && hour < 17) {
      return [
        '💻 Focus Lo-Fi',
        '☕ Coffee & Chill',
        '⚡ Bollywood Classics',
        '📖 Study Instrumental',
      ];
    } else if (hour >= 17 && hour < 22) {
      return [
        '🔥 Gym & Workout',
        '🥁 Punjabi Party',
        '🌾 Bhojpuri Beats',
        '⚡ Trending 2024',
      ];
    } else {
      return [
        '🌙 Midnight Romance',
        '💔 Heartbreak Arijit',
        '✨ Lo-Fi Slowed',
        '🌌 Deep Sleep Ambient',
      ];
    }
  }
}
