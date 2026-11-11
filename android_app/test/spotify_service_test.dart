import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/services/spotify_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SpotifyService Tests', () {
    test('SpotifyService initializes with empty state and isConfigured is false', () async {
      final service = SpotifyService.instance;
      await service.init();

      expect(service.isConfigured, isFalse);
      expect(service.clientId, isNull);
      expect(service.clientSecret, isNull);
    });

    test('setCredentials sets clientId, clientSecret and marks isConfigured true', () async {
      final service = SpotifyService.instance;
      await service.setCredentials('test_client_id_123', 'test_client_secret_456');

      expect(service.isConfigured, isTrue);
      expect(service.clientId, equals('test_client_id_123'));
      expect(service.clientSecret, equals('test_client_secret_456'));
    });

    test('clearCredentials removes stored credentials and marks isConfigured false', () async {
      final service = SpotifyService.instance;
      await service.setCredentials('test_id', 'test_secret');
      expect(service.isConfigured, isTrue);

      await service.clearCredentials();
      expect(service.isConfigured, isFalse);
      expect(service.clientId, isNull);
      expect(service.clientSecret, isNull);
    });

    test('parseSpotifyTrack correctly converts Spotify JSON track to SongModel', () {
      final mockSpotifyTrackJson = {
        'id': '4cOdK2wGLETKBW3PvgPWqT',
        'name': 'Kesariya',
        'artists': [
          {'name': 'Pritam'},
          {'name': 'Arijit Singh'},
          {'name': 'Amitabh Bhattacharya'}
        ],
        'album': {
          'name': 'Brahmastra',
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273'}
          ]
        },
        'duration_ms': 268000,
      };

      final song = SpotifyService.parseSpotifyTrack(mockSpotifyTrackJson);

      expect(song.id, equals('sp_4cOdK2wGLETKBW3PvgPWqT'));
      expect(song.title, equals('Kesariya'));
      expect(song.artist, equals('Pritam, Arijit Singh, Amitabh Bhattacharya'));
      expect(song.album, equals('Brahmastra'));
      expect(song.duration, equals(268));
      expect(song.artworkUrl, equals('https://i.scdn.co/image/ab67616d0000b273'));
      expect(song.source, equals('spotify'));
      expect(song.streamUrl, isEmpty);
    });

    test('getAccessToken exchanges client credentials for bearer token via mock client', () async {
      final service = SpotifyService.instance;
      await service.setCredentials('mock_client', 'mock_secret');

      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'https://accounts.spotify.com/api/token') {
          return http.Response(
            jsonEncode({
              'access_token': 'test_token_abc_123',
              'token_type': 'Bearer',
              'expires_in': 3600,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final token = await service.getAccessToken(client: mockClient);
      expect(token, equals('test_token_abc_123'));
    });

    test('searchTracks returns parsed Spotify SongModels using mock client', () async {
      final service = SpotifyService.instance;
      await service.setCredentials('mock_client', 'mock_secret');

      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'https://accounts.spotify.com/api/token') {
          return http.Response(
            jsonEncode({
              'access_token': 'test_token_abc_123',
              'token_type': 'Bearer',
              'expires_in': 3600,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.toString().contains('https://api.spotify.com/v1/search')) {
          return http.Response(
            jsonEncode({
              'tracks': {
                'items': [
                  {
                    'id': 'track_1',
                    'name': 'Apna Bana Le',
                    'artists': [{'name': 'Arijit Singh'}],
                    'album': {
                      'name': 'Bhediya',
                      'images': [{'url': 'https://example.com/cover.jpg'}]
                    },
                    'duration_ms': 260000,
                  }
                ]
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final tracks = await service.searchTracks('Apna Bana Le', client: mockClient);
      expect(tracks.length, equals(1));
      expect(tracks.first.title, equals('Apna Bana Le'));
      expect(tracks.first.artist, equals('Arijit Singh'));
      expect(tracks.first.source, equals('spotify'));
    });
  });
}
