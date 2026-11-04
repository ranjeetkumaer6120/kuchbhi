import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/models/lyrics_model.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/api_service.dart';

void main() {
  group('LyricsData Tests', () {
    test('LyricsData.parse parses synchronized LRC format accurately', () {
      const lrc = '''
[00:09.44] Mujhko itna bataye koi
[00:19.02] Kaise tujhse dil na lagaye koi?
[00:29.91] Rabba ne tujhko banane me
''';
      final data = LyricsData.parse(syncedLyrics: lrc);
      expect(data.isSynced, isTrue);
      expect(data.lines.length, 3);
      expect(data.lines[0].text, 'Mujhko itna bataye koi');
      expect(data.lines[0].timestamp, const Duration(seconds: 9, milliseconds: 440));
      expect(data.lines[1].text, 'Kaise tujhse dil na lagaye koi?');
      expect(data.lines[1].timestamp, const Duration(seconds: 19, milliseconds: 20));
      expect(data.lines[2].text, 'Rabba ne tujhko banane me');
      expect(data.lines[2].timestamp, const Duration(seconds: 29, milliseconds: 910));
    });

    test('LyricsData.parse falls back to plain lyrics when synced not available', () {
      const plain = '''
Line one
Line two
Line three
''';
      final data = LyricsData.parse(plainLyrics: plain);
      expect(data.isSynced, isFalse);
      expect(data.lines.length, 3);
      expect(data.lines[0].text, 'Line one');
      expect(data.lines[1].text, 'Line two');
    });
  });
  group('SongModel Tests', () {
    test('SongModel.fromSaavnJson cleans entities and decrypts to 320kbps URL', () {
      final sample = {
        'id': 'test_123',
        'title': 'Kesariya &amp; Love',
        'subtitle': 'Arijit Singh, Pritam',
        'image': 'https://c.saavncdn.com/871/Kesariya-From-Brahmastra-Hindi-2022-20220717092820-150x150.jpg',
        'more_info': {
          'album': 'Brahmastra',
          'duration': '268',
          'encrypted_media_url': 'ID2ieOjCrwfgWvL5sXl4B1ImC5QfbsDyryhkSYK5IH2E7FCO52VR6yhNbcEbes5iCcja4+W8xhE0SwtCJToN4Bw7tS9a8Gtq',
        }
      };

      final song = SongModel.fromSaavnJson(sample);
      expect(song.title, 'Kesariya & Love');
      expect(song.artist, 'Arijit Singh, Pritam');
      expect(song.album, 'Brahmastra');
      expect(song.duration, 268);
      expect(song.artworkUrl, contains('500x500'));
      expect(song.streamUrl, contains('https://aac.saavncdn.com/'));
      expect(song.streamUrl, contains('_320.mp4'));
      expect(song.qualityBadge, 'Master HD');
    });

    test('SongModel toJson and fromJson serialization works for offline catalog', () {
      final original = SongModel(
        id: 'off_001',
        title: 'Chaleya',
        artist: 'Arijit Singh',
        album: 'Jawan',
        duration: 200,
        streamUrl: 'https://sample.com/audio.mp4',
        artworkUrl: 'https://sample.com/art.jpg',
        isOffline: true,
        localFilePath: '/storage/music/chaleya.mp3',
      );

      final jsonMap = original.toJson();
      final restored = SongModel.fromJson(jsonMap);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.artist, original.artist);
      expect(restored.isOffline, true);
      expect(restored.localFilePath, '/storage/music/chaleya.mp3');
    });

    test('SongModel.fromItunesJson parses Apple metadata and sets 256kbps quality', () {
      final sample = {
        'trackId': 1572911181,
        'trackName': 'Lover',
        'artistName': 'Diljit Dosanjh',
        'collectionName': 'MoonChild Era',
        'trackTimeMillis': 195000,
        'artworkUrl100': 'https://is1-ssl.mzstatic.com/image/thumb/Music/v4/100x100bb.jpg',
        'previewUrl': 'https://audio-ssl.itunes.apple.com/preview.m4a',
      };

      final song = SongModel.fromItunesJson(sample);
      expect(song.id, 'itunes_1572911181');
      expect(song.title, 'Lover');
      expect(song.artist, 'Diljit Dosanjh');
      expect(song.duration, 195);
      expect(song.artworkUrl, contains('600x600bb.jpg'));
      expect(song.qualityBadge, 'Hi-Fi Audio');
      expect(song.qualityScore, 256);
    });

    test('deduplicateByQuality keeps highest quality track and removes duplicates', () {
      final saavn320 = SongModel(
        id: 'saavn_1',
        title: 'Kesariya (From "Brahmastra")',
        artist: 'Arijit Singh, Pritam',
        album: 'Brahmastra',
        duration: 268,
        streamUrl: 'https://saavn.com/kesariya_320.mp4',
        artworkUrl: 'art.jpg',
        source: 'saavn',
        qualityBadge: 'Master HD',
      );

      final yt160 = SongModel(
        id: 'yt_1',
        title: 'Kesariya [Official Video]',
        artist: 'Arijit Singh',
        album: 'Single',
        duration: 268,
        streamUrl: 'https://yt.com/stream',
        artworkUrl: 'yt_art.jpg',
        source: 'youtube',
        qualityBadge: 'Studio HD',
      );

      final differentSong = SongModel(
        id: 'saavn_2',
        title: 'Chaleya',
        artist: 'Arijit Singh',
        album: 'Jawan',
        duration: 200,
        streamUrl: 'https://saavn.com/chaleya_320.mp4',
        artworkUrl: 'chaleya.jpg',
        source: 'saavn',
        qualityBadge: 'Master HD',
      );

      final deduplicated = ApiService.deduplicateByQuality([yt160, saavn320, differentSong]);

      // Should have only 2 unique songs, NOT 3
      expect(deduplicated.length, 2);
      // The Kesariya track that is retained MUST be the Master HD version
      final kesariya = deduplicated.firstWhere((s) => s.title.contains('Kesariya'));
      expect(kesariya.id, 'saavn_1');
      expect(kesariya.qualityBadge, 'Master HD');
      expect(kesariya.source, 'saavn');
    });
  });

  group('ApiService Tests', () {
    test('ApiService can be instantiated', () {
      final api = ApiService();
      expect(api, isNotNull);
    });
  });
}
