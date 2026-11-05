import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/models/lyrics_model.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/api_service.dart';
import 'package:soundvibe/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('com.ryanheise.just_audio.methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'init':
            return {'id': methodCall.arguments['id']};
          case 'load':
            return {'duration': 120000000};
          case 'disposeAllPlayers':
            return <dynamic, dynamic>{};
          default:
            return <dynamic, dynamic>{};
        }
      },
    );

    const sessionChannel = MethodChannel('com.ryanheise.audio_session');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      sessionChannel,
      (MethodCall methodCall) async => null,
    );
  });
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
        'language': 'Hindi',
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
      expect(song.language, 'hindi');
      expect(song.artworkUrl, contains('500x500'));
      expect(song.streamUrl, contains('https://aac.saavncdn.com/'));
      expect(song.streamUrl, contains('_320.mp4'));
      expect(song.qualityBadge, 'Master HD');
    });

    test('SongModel.fromSaavnJson parses language from json, more_info, and defaults to hindi', () {
      // 1. Language from top-level json
      final bhojpuriSample = {
        'id': 'bhoj_1',
        'title': 'Lollipop Lagelu',
        'language': 'Bhojpuri',
        'more_info': {'encrypted_media_url': 'ID2ieOjCrwfgWvL5sXl4B1ImC5QfbsDyryhkSYK5IH2E7FCO52VR6yhNbcEbes5iCcja4+W8xhE0SwtCJToN4Bw7tS9a8Gtq'},
      };
      final bhojpuriSong = SongModel.fromSaavnJson(bhojpuriSample);
      expect(bhojpuriSong.language, 'bhojpuri');

      // 2. Language from more_info
      final englishSample = {
        'id': 'eng_1',
        'title': 'Shape of You',
        'more_info': {
          'language': 'English',
          'encrypted_media_url': 'ID2ieOjCrwfgWvL5sXl4B1ImC5QfbsDyryhkSYK5IH2E7FCO52VR6yhNbcEbes5iCcja4+W8xhE0SwtCJToN4Bw7tS9a8Gtq',
        },
      };
      final englishSong = SongModel.fromSaavnJson(englishSample);
      expect(englishSong.language, 'english');

      // 3. Defaults to hindi when omitted
      final defaultSample = {
        'id': 'def_1',
        'title': 'Default Track',
        'more_info': {'encrypted_media_url': 'ID2ieOjCrwfgWvL5sXl4B1ImC5QfbsDyryhkSYK5IH2E7FCO52VR6yhNbcEbes5iCcja4+W8xhE0SwtCJToN4Bw7tS9a8Gtq'},
      };
      final defaultSong = SongModel.fromSaavnJson(defaultSample);
      expect(defaultSong.language, 'hindi');
    });

    test('SongModel toJson and fromJson serialization works for offline catalog and retains language', () {
      final original = SongModel(
        id: 'off_001',
        title: 'Chaleya',
        artist: 'Arijit Singh',
        album: 'Jawan',
        duration: 200,
        streamUrl: 'https://sample.com/audio.mp4',
        artworkUrl: 'https://sample.com/art.jpg',
        language: 'hindi',
        isOffline: true,
        localFilePath: '/storage/music/chaleya.mp3',
      );

      final jsonMap = original.toJson();
      expect(jsonMap['language'], 'hindi');

      final restored = SongModel.fromJson(jsonMap);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.artist, original.artist);
      expect(restored.language, 'hindi');
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

    test('ApiService.searchSongs accepts language parameter', () async {
      final api = ApiService();
      // Verifies method signature and execution with language parameter
      final results = await api.searchSongs('', language: 'hindi');
      expect(results, isEmpty);
    });
  });

  group('AudioPlayerService Language Continuity Guard', () {
    test('currentLanguageLock defaults to null and can be set', () {
      final service = AudioPlayerService();
      expect(service.currentLanguageLock, isNull);

      service.setLanguageLock('bhojpuri');
      expect(service.currentLanguageLock, 'bhojpuri');
    });

    test('playSong sets currentLanguageLock and filters mixed playlist to active language', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final service = AudioPlayerService();

      final hindi1 = SongModel(
        id: 'h_1',
        title: 'Apna Bana Le',
        artist: 'Arijit Singh',
        album: 'Bhediya',
        duration: 260,
        streamUrl: 'https://saavn.com/h1.mp4',
        artworkUrl: 'h1.jpg',
        language: 'hindi',
      );

      final punjabi1 = SongModel(
        id: 'p_1',
        title: 'Trending Nakhra',
        artist: 'Amrit Maan',
        album: 'Single',
        duration: 240,
        streamUrl: 'https://saavn.com/p1.mp4',
        artworkUrl: 'p1.jpg',
        language: 'punjabi',
      );

      final hindi2 = SongModel(
        id: 'h_2',
        title: 'Kesariya',
        artist: 'Arijit Singh',
        album: 'Brahmastra',
        duration: 268,
        streamUrl: 'https://saavn.com/h2.mp4',
        artworkUrl: 'h2.jpg',
        language: 'hindi',
      );

      final telugu1 = SongModel(
        id: 't_1',
        title: 'Oo Antava',
        artist: 'Indravathi Chauhan',
        album: 'Pushpa',
        duration: 220,
        streamUrl: 'https://saavn.com/t1.mp4',
        artworkUrl: 't1.jpg',
        language: 'telugu',
      );

      final mixedTrendingPlaylist = [punjabi1, hindi1, telugu1, hindi2];

      // User plays hindi1 from mixed trending playlist
      await service.playSong(hindi1, playlist: mixedTrendingPlaylist);

      expect(service.currentLanguageLock, 'hindi');
      // Queue must preserve continuity: contain only the Hindi tracks
      expect(service.queue.length, 2);
      expect(service.queue.every((s) => s.language == 'hindi'), isTrue);
      expect(service.queue[0].id, 'h_1');
      expect(service.queue[1].id, 'h_2');
    });

    test('playSong falls back cleanly to full playlist if only 1 track matches language', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final service = AudioPlayerService();

      final english1 = SongModel(
        id: 'e_1',
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        album: 'Divide',
        duration: 230,
        streamUrl: 'https://sample.com/e1.mp4',
        artworkUrl: 'e1.jpg',
        language: 'english',
      );

      final hindi1 = SongModel(
        id: 'h_1',
        title: 'Kesariya',
        artist: 'Arijit Singh',
        album: 'Brahmastra',
        duration: 268,
        streamUrl: 'https://saavn.com/h1.mp4',
        artworkUrl: 'h1.jpg',
        language: 'hindi',
      );

      final mixedPlaylist = [english1, hindi1];

      // User plays english1, which has no other english songs in playlist
      await service.playSong(english1, playlist: mixedPlaylist);

      expect(service.currentLanguageLock, 'english');
      // Falls back to full playlist without crashing or discarding
      expect(service.queue.length, 2);
    });
  });
}
