import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/playlist_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlaylistService Auto-Download Favorites Tests', () {
    test('autoDownloadFavorites defaults to false and can be toggled', () async {
      final playlistService = PlaylistService();
      await playlistService.init();

      expect(playlistService.autoDownloadFavorites, isFalse);

      await playlistService.setAutoDownloadFavorites(true);
      expect(playlistService.autoDownloadFavorites, isTrue);

      await playlistService.setAutoDownloadFavorites(false);
      expect(playlistService.autoDownloadFavorites, isFalse);
    });

    test('toggleFavorite retains song in favorites', () async {
      final playlistService = PlaylistService();
      await playlistService.init();

      final song = SongModel(
        id: 'fav-1',
        title: 'Kesariya',
        artist: 'Arijit Singh',
        album: 'Brahmastra',
        duration: 268,
        streamUrl: 'https://example.com/stream.mp3',
        artworkUrl: 'https://example.com/art.jpg',
      );

      await playlistService.toggleFavorite(song);
      expect(playlistService.isFavorite('fav-1'), isTrue);

      await playlistService.toggleFavorite(song);
      expect(playlistService.isFavorite('fav-1'), isFalse);
    });
  });
}
