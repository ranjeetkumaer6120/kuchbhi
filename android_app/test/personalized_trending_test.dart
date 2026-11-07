import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/user_taste_service.dart';

SongModel _createSong({
  required String id,
  required String title,
  required String artist,
  String album = 'Test Album',
}) {
  return SongModel(
    id: id,
    title: title,
    artist: artist,
    album: album,
    duration: 210,
    streamUrl: 'https://example.com/$id.mp3',
    artworkUrl: 'https://example.com/$id.jpg',
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

  group('UserTasteService Personalization & Icon-Free Tests', () {
    test('getPersonalizedVibePills returns zero emoji characters', () {
      final pills = tasteService.getPersonalizedVibePills(favorites: [
        _createSong(id: 'fav1', title: 'Kesariya', artist: 'Arijit Singh'),
      ]);

      expect(pills, isNotEmpty);
      final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true);

      for (final pill in pills) {
        final hasEmoji = emojiRegex.hasMatch(pill);
        expect(hasEmoji, isFalse, reason: 'Pill "$pill" contains emoji, which violates strict icon-free rule');
      }
    });

    test('cold-start getPersonalizedTrending returns initial global trending tracks', () {
      final globalTrending = [
        _createSong(id: 's1', title: 'Track 1', artist: 'Artist A'),
        _createSong(id: 's2', title: 'Track 2', artist: 'Artist B'),
        _createSong(id: 's3', title: 'Track 3', artist: 'Artist C'),
      ];

      final personalized = tasteService.getPersonalizedTrending(globalTrending);
      expect(personalized.length, equals(3));
      expect(personalized.map((s) => s.id).toList(), equals(['s1', 's2', 's3']));
    });

    test('searches and plays boost affinity and rank matching trending songs at top', () async {
      final globalTrending = [
        _createSong(id: 's1', title: 'Track 1', artist: 'Random Singer'),
        _createSong(id: 's2', title: 'Track 2', artist: 'Unknown Band'),
        _createSong(id: 's3', title: 'O Maahi', artist: 'Arijit Singh'),
      ];

      // User searches for Arijit Singh
      await tasteService.recordSearch('Arijit Singh');
      // User plays an Arijit Singh song
      await tasteService.recordPlay(
        _createSong(id: 'prev1', title: 'Tum Hi Ho', artist: 'Arijit Singh'),
      );

      final personalized = tasteService.getPersonalizedTrending(globalTrending);
      expect(personalized.isNotEmpty, isTrue);
      // Arijit Singh's trending track should shoot to the top position (index 0)
      expect(personalized.first.id, equals('s3'));
      expect(personalized.first.artist, equals('Arijit Singh'));
    });

    test('frequent skips penalize and demote trending tracks', () async {
      final globalTrending = [
        _createSong(id: 's1', title: 'Annoying Track', artist: 'Spam Artist'),
        _createSong(id: 's2', title: 'Decent Song', artist: 'Neutral Artist'),
      ];

      // User skips songs by Spam Artist twice within 10 seconds
      final skippedSong = _createSong(id: 's1', title: 'Annoying Track', artist: 'Spam Artist');
      await tasteService.recordSkip(skippedSong, playedSeconds: 8);
      await tasteService.recordSkip(skippedSong, playedSeconds: 5);

      final personalized = tasteService.getPersonalizedTrending(globalTrending);
      // Spam Artist should be demoted below Neutral Artist
      expect(personalized.first.id, equals('s2'));
      expect(personalized.last.id, equals('s1'));
    });
  });
}
