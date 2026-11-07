import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  SongModel createTestSong({required String id, required String title, String artist = 'Arijit Singh'}) {
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

  test('AudioPlayerService persists and restores last played song, position and queue', () async {
    final playerService = AudioPlayerService();
    final testSong = createTestSong(id: 'song_kesariya', title: 'Kesariya');
    final queue = [
      testSong,
      createTestSong(id: 'song_apna', title: 'Apna Bana Le'),
    ];

    // Save playback session at 85 seconds (1m 25s)
    await playerService.savePlaybackSessionManually(
      song: testSong,
      position: const Duration(seconds: 85),
      queue: queue,
    );

    // Create fresh player instance and restore
    final restoredService = AudioPlayerService();
    final restored = await restoredService.restorePlaybackSession(autoPreparePlayer: false);

    expect(restored, isTrue);
    expect(restoredService.currentSong?.id, 'song_kesariya');
    expect(restoredService.currentSong?.title, 'Kesariya');
    expect(restoredService.position.inSeconds, 85);
    expect(restoredService.queue.length, 2);
    expect(restoredService.queue[1].id, 'song_apna');
  });

  test('AudioPlayerService restore returns false when no session saved', () async {
    final playerService = AudioPlayerService();
    final restored = await playerService.restorePlaybackSession(autoPreparePlayer: false);
    expect(restored, isFalse);
    expect(playerService.currentSong, isNull);
  });
}
