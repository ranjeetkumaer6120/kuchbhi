import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/time_of_day_helper.dart';
import 'package:soundvibe/services/user_taste_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    UserTasteService().resetForTesting();
  });

  test('TimeOfDayHelper getCuratedMoods does NOT contain bhakti or morning ragas', () {
    // Test across all 24 hours of the day
    for (int hour = 0; hour < 24; hour++) {
      final time = DateTime(2026, 1, 1, hour, 0);
      final moods = TimeOfDayHelper.getCuratedMoods(time);
      for (final mood in moods) {
        final lower = mood.toLowerCase();
        expect(lower.contains('bhakti'), isFalse, reason: 'Mood "$mood" at hour $hour should not contain bhakti');
        expect(lower.contains('raga'), isFalse, reason: 'Mood "$mood" at hour $hour should not contain raga');
        expect(lower.contains('meditation'), isFalse, reason: 'Mood "$mood" at hour $hour should not contain meditation');
      }
    }
  });

  test('UserTasteService records plays and calculates most played songs and top artists', () async {
    final tasteService = UserTasteService();
    await tasteService.init();

    final song1 = SongModel(
      id: 'song_1',
      title: 'Kesariya',
      artist: 'Arijit Singh',
      album: 'Brahmastra',
      duration: 268,
      streamUrl: 'https://cdn.example.com/1.mp3',
      artworkUrl: 'https://cdn.example.com/1.jpg',
      language: 'hindi',
    );

    final song2 = SongModel(
      id: 'song_2',
      title: 'Lollypop Lagelu',
      artist: 'Pawan Singh',
      album: 'Lollypop',
      duration: 210,
      streamUrl: 'https://cdn.example.com/2.mp3',
      artworkUrl: 'https://cdn.example.com/2.jpg',
      language: 'bhojpuri',
    );

    // Record 3 plays for Kesariya, 1 play for Lollypop
    await tasteService.recordPlay(song1);
    await tasteService.recordPlay(song1);
    await tasteService.recordPlay(song1);
    await tasteService.recordPlay(song2);

    expect(tasteService.getPlayCount('song_1'), 3);
    expect(tasteService.getPlayCount('song_2'), 1);

    final mostPlayed = tasteService.getMostPlayedSongs();
    expect(mostPlayed.length, 2);
    expect(mostPlayed.first.id, 'song_1'); // Kesariya is #1 most played
    expect(mostPlayed[1].id, 'song_2');

    final topArtists = tasteService.getTopArtists();
    expect(topArtists.first, 'Arijit Singh');

    // Taste pills should now prioritize user's actual favorite artists
    final pills = tasteService.getPersonalizedVibePills();
    expect(pills.any((p) => p.contains('Arijit Singh')), isTrue);
    expect(pills.any((p) => p.contains('Pawan Singh')), isTrue);
  });

  test('UserTasteService provides neutral secular music starters when history is empty', () async {
    final tasteService = UserTasteService();
    await tasteService.init();

    final pills = tasteService.getPersonalizedVibePills();
    expect(pills.isNotEmpty, isTrue);

    for (final pill in pills) {
      final lower = pill.toLowerCase();
      expect(lower.contains('bhakti'), isFalse);
      expect(lower.contains('raga'), isFalse);
    }
  });
}
