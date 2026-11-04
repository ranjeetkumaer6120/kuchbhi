import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/playlist_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaylistService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('PlaylistService toggles favorites and persists', () async {
      final service = PlaylistService();
      await service.init();

      final song = SongModel(
        id: 'fav_1',
        title: 'Kesariya',
        artist: 'Arijit Singh',
        album: 'Brahmastra',
        duration: 268,
        streamUrl: 'https://example.com/audio.mp4',
        artworkUrl: 'https://example.com/art.jpg',
      );

      expect(service.isFavorite(song.id), false);
      await service.toggleFavorite(song);
      expect(service.isFavorite(song.id), true);
      expect(service.favorites.length, 1);

      await service.toggleFavorite(song);
      expect(service.isFavorite(song.id), false);
      expect(service.favorites.isEmpty, true);
    });

    test('PlaylistService creates folder and adds songs', () async {
      final service = PlaylistService();
      await service.init();

      await service.createFolder('Gym Tracks');
      expect(service.folderNames, contains('Gym Tracks'));

      final song = SongModel(
        id: 'gym_1',
        title: 'Animal Entry',
        artist: 'Various',
        album: 'Animal',
        duration: 180,
        streamUrl: 'https://example.com/audio.mp4',
        artworkUrl: 'https://example.com/art.jpg',
      );

      await service.addSongToFolder('Gym Tracks', song);
      expect(service.getFolderSongs('Gym Tracks').length, 1);
      expect(service.getFolderSongs('Gym Tracks').first.title, 'Animal Entry');

      await service.removeSongFromFolder('Gym Tracks', song.id);
      expect(service.getFolderSongs('Gym Tracks').isEmpty, true);
    });
  });
}
