import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_session'),
      (MethodCall methodCall) async => null,
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  SongModel createMockSong({required String id, required String title, String artist = 'Arijit Singh'}) {
    return SongModel(
      id: id,
      title: title,
      artist: artist,
      album: 'Test Album',
      duration: 250,
      streamUrl: 'https://cdn.example.com/$id.mp3',
      artworkUrl: 'https://cdn.example.com/$id.jpg',
      language: 'hindi',
    );
  }

  group('Android Auto Car Display Browse & Operation Tests', () {
    test('getCarChildren returns root categories for car dashboard', () async {
      final playerService = AudioPlayerService();
      final rootItems = await playerService.getCarChildren('root');

      expect(rootItems.isNotEmpty, isTrue);
      expect(rootItems.any((item) => item.id == 'car_queue'), isTrue);
      expect(rootItems.any((item) => item.id == 'car_trending'), isTrue);
      expect(rootItems.any((item) => item.id == 'car_recent'), isTrue);
      for (final item in rootItems) {
        expect(item.playable, isFalse);
      }
    });

    test('getCarChildren returns queue tracks when car_queue is queried', () async {
      final playerService = AudioPlayerService();
      final song1 = createMockSong(id: 'song_1', title: 'Kesariya');
      final song2 = createMockSong(id: 'song_2', title: 'Apna Bana Le');
      
      await playerService.savePlaybackSessionManually(
        song: song1,
        position: Duration.zero,
        queue: [song1, song2],
      );
      await playerService.restorePlaybackSession(autoPreparePlayer: false);

      final queueItems = await playerService.getCarChildren('car_queue');
      expect(queueItems.length, equals(2));
      expect(queueItems.first.title, equals('Kesariya'));
      expect(queueItems.first.playable, isTrue);
      expect(queueItems.last.title, equals('Apna Bana Le'));
      expect(queueItems.last.playable, isTrue);
    });

    test('JustAudioBackground static callbacks handle car interactions', () async {
      final playerService = AudioPlayerService();
      final song = createMockSong(id: 'song_test', title: 'Heeriye');
      
      await playerService.savePlaybackSessionManually(
        song: song,
        position: Duration.zero,
        queue: [song],
      );
      await playerService.restorePlaybackSession(autoPreparePlayer: false);

      JustAudioBackground.onGetChildren = (parentMediaId, [options]) async {
        return playerService.getCarChildren(parentMediaId);
      };

      final items = await JustAudioBackground.onGetChildren!('car_queue');
      expect(items.length, equals(1));
      expect(items.first.title, equals('Heeriye'));
    });
  });
}
