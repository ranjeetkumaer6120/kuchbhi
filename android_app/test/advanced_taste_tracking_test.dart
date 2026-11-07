import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/user_taste_service.dart';

SongModel _createSong({
  required String id,
  required String title,
  required String artist,
  String language = 'hindi',
  int duration = 240,
}) {
  return SongModel(
    id: id,
    title: title,
    artist: artist,
    album: 'Album $id',
    duration: duration,
    streamUrl: 'https://example.com/$id.mp3',
    artworkUrl: 'https://example.com/$id.jpg',
    language: language,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserTasteService tasteService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tasteService = UserTasteService();
    tasteService.resetForTesting();
    await tasteService.init();
  });

  group('Advanced User Taste & Interest Tracking Tests', () {
    test('Favorite action boosts song and artist affinity; un-favorite removes boost', () async {
      final song = _createSong(id: 'fav_song', title: 'Kesariya', artist: 'Arijit Singh');

      final initialAffinity = tasteService.calculateSongAffinity(song);
      expect(initialAffinity, equals(0.0));

      // Mark favorite
      await tasteService.recordFavorite(song, isFavorite: true);
      final favoritedAffinity = tasteService.calculateSongAffinity(song);
      expect(favoritedAffinity, greaterThanOrEqualTo(14.0)); // +10 song, +4 artist

      // Other song by same artist also benefits
      final otherSong = _createSong(id: 'other_arijit', title: 'Apna Bana Le', artist: 'Arijit Singh');
      expect(tasteService.calculateSongAffinity(otherSong), greaterThanOrEqualTo(4.0));

      // Un-favorite
      await tasteService.recordFavorite(song, isFavorite: false);
      expect(tasteService.calculateSongAffinity(song), lessThan(favoritedAffinity));
    });

    test('Language auto-detection boosts preferred languages in trending', () async {
      final hindiSong = _createSong(id: 'h1', title: 'Hindi Track', artist: 'Hindi Singer', language: 'hindi');
      final punjabiSong = _createSong(id: 'p1', title: 'Punjabi Track', artist: 'Punjabi Singer', language: 'punjabi');
      final bhojpuriSong = _createSong(id: 'b1', title: 'Bhojpuri Track', artist: 'Bhojpuri Singer', language: 'bhojpuri');

      // User listens mostly to Bhojpuri
      await tasteService.recordLanguagePlay('bhojpuri');
      await tasteService.recordLanguagePlay('bhojpuri');
      await tasteService.recordLanguagePlay('bhojpuri');

      expect(tasteService.getTopLanguages().first, equals('bhojpuri'));

      final globalTrending = [hindiSong, punjabiSong, bhojpuriSong];
      final personalized = tasteService.getPersonalizedTrending(globalTrending);

      // Bhojpuri track should be ranked #1
      expect(personalized.first.id, equals('b1'));
      expect(personalized.first.language, equals('bhojpuri'));
    });

    test('Instant skip (<= 5s) applies heavy penalty compared to partial play', () async {
      final badSong = _createSong(id: 'spam_1', title: 'Clickbait Song', artist: 'Spam Artist');
      final neutralSong = _createSong(id: 'neutral_1', title: 'Neutral Song', artist: 'Neutral Artist');

      // Instant skip within 3 seconds
      await tasteService.recordPlaybackSession(badSong, playedSeconds: 3, totalDuration: 180);

      final affinity = tasteService.calculateSongAffinity(badSong);
      expect(affinity, lessThanOrEqualTo(-14.0)); // Heavy penalty (-10 song, -5 artist)

      final globalTrending = [badSong, neutralSong];
      final personalized = tasteService.getPersonalizedTrending(globalTrending);
      expect(personalized.first.id, equals('neutral_1'));
      expect(personalized.last.id, equals('spam_1'));
    });

    test('Heavy rotation (3+ plays in 48h) detects obsession and boosts ranking', () async {
      final bingeSong = _createSong(id: 'binge_1', title: 'Viral Banger', artist: 'Pop Icon');
      final regularSong = _createSong(id: 'reg_1', title: 'Casual Listen', artist: 'Casual Artist');

      final now = DateTime.now();

      // User plays bingeSong 3 times today
      await tasteService.recordPlay(bingeSong);
      await tasteService.recordPlaybackSession(bingeSong, playedSeconds: 200, totalDuration: 200, timestamp: now);
      await tasteService.recordPlaybackSession(bingeSong, playedSeconds: 200, totalDuration: 200, timestamp: now);
      await tasteService.recordPlaybackSession(bingeSong, playedSeconds: 200, totalDuration: 200, timestamp: now);

      expect(tasteService.isHeavyRotation('binge_1', now: now), isTrue);

      final heavyList = tasteService.getHeavyRotationSongs(now: now);
      expect(heavyList.any((s) => s.id == 'binge_1'), isTrue);

      final affinity = tasteService.calculateSongAffinity(bingeSong);
      expect(affinity, greaterThanOrEqualTo(15.0));
    });

    test('Time of day contextual affinity boosts songs frequented at that time', () async {
      final morningSong = _createSong(id: 'morn_1', title: 'Acoustic Sunrise', artist: 'Morning Artist');
      final nightSong = _createSong(id: 'night_1', title: 'Midnight Lo-Fi', artist: 'Night Artist');

      final morningTime = DateTime(2026, 11, 7, 8, 30); // 8:30 AM
      final nightTime = DateTime(2026, 11, 7, 23, 15); // 11:15 PM

      expect(tasteService.getTimeSlot(morningTime), equals('Morning'));
      expect(tasteService.getTimeSlot(nightTime), equals('Night'));

      // Listen to morningSong in the morning
      await tasteService.recordPlaybackSession(
        morningSong,
        playedSeconds: 150,
        totalDuration: 180,
        timestamp: morningTime,
      );

      final morningAffinity = tasteService.calculateSongAffinity(morningSong, contextualTime: morningTime);
      final nightAffinity = tasteService.calculateSongAffinity(morningSong, contextualTime: nightTime);

      // Morning affinity should be higher during morning hours
      expect(morningAffinity, greaterThan(nightAffinity));
    });

    test('Share action provides significant positive affinity boost', () async {
      final sharedSong = _createSong(id: 'share_1', title: 'Masterpiece', artist: 'Legend');

      final beforeShare = tasteService.calculateSongAffinity(sharedSong);
      await tasteService.recordShare(sharedSong);
      final afterShare = tasteService.calculateSongAffinity(sharedSong);

      expect(afterShare - beforeShare, greaterThanOrEqualTo(7.0));
    });

    test('getPersonalizedVibePills maintains 100% strict zero emoji constraint with dynamic pills', () async {
      final song = _createSong(id: 's_vibe', title: 'Vibe Track', artist: 'Vibe Artist');
      await tasteService.recordPlay(song);
      await tasteService.recordFavorite(song, isFavorite: true);
      await tasteService.recordLanguagePlay('punjabi');
      await tasteService.recordPlaybackSession(song, playedSeconds: 200, totalDuration: 200);
      await tasteService.recordPlaybackSession(song, playedSeconds: 200, totalDuration: 200);
      await tasteService.recordPlaybackSession(song, playedSeconds: 200, totalDuration: 200);

      final pills = tasteService.getPersonalizedVibePills(favorites: [song]);
      expect(pills, isNotEmpty);

      final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true);
      for (final pill in pills) {
        expect(emojiRegex.hasMatch(pill), isFalse, reason: 'Pill "$pill" contains an emoji!');
      }
    });
  });
}
