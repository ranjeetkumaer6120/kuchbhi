import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/services/api_service.dart';

void main() {
  group('Artist & Playlist API Integration Tests', () {
    test('ApiService provides searchArtists and searchPlaylists signatures', () {
      final api = ApiService();
      expect(api.searchArtists, isNotNull);
      expect(api.searchPlaylists, isNotNull);
      expect(api.getPlaylistSongs, isNotNull);
      expect(api.getArtistTopSongs, isNotNull);
    });
  });
}
