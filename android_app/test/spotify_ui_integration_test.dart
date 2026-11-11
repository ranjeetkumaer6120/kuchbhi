import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/services/spotify_service.dart';

void main() {
  group('Spotify Curated Playlists & UI Tests', () {
    test('Curated Playlists constant contains all 6 major Indian & global playlists', () {
      final playlists = SpotifyService.curatedPlaylists;
      expect(playlists.containsKey('Hot Hits Hindi'), isTrue);
      expect(playlists.containsKey('Bollywood Butter'), isTrue);
      expect(playlists.containsKey('Top 50 - India'), isTrue);
      expect(playlists.containsKey('Top 50 - Global'), isTrue);
      expect(playlists.containsKey('Punjabi 101'), isTrue);
      expect(playlists.containsKey('Mega Hit Mix'), isTrue);
    });

    test('All curated playlist IDs are valid Spotify playlist IDs', () {
      final playlists = SpotifyService.curatedPlaylists;
      for (final entry in playlists.entries) {
        expect(entry.value.length, greaterThanOrEqualTo(20));
        expect(entry.value.startsWith('37i9dQZ') || entry.value.startsWith('37i9dQE'), isTrue);
      }
    });
  });
}
