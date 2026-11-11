import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class SpotifyService {
  static final SpotifyService instance = SpotifyService._internal();
  SpotifyService._internal();

  static const String _prefClientId = 'sp_client_id';
  static const String _prefClientSecret = 'sp_client_secret';
  static const String _prefToken = 'sp_access_token';
  static const String _prefTokenExpiry = 'sp_token_expiry';

  String? _clientId;
  String? _clientSecret;
  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Curated Spotify Playlists for instant browse
  static const Map<String, String> curatedPlaylists = {
    'Hot Hits Hindi': '37i9dQZF1DX0XUfTFmNBRM',
    'Bollywood Butter': '37i9dQZF1DXdFESNN9TzQT',
    'Top 50 - India': '37i9dQZF1DX4JAvHpjipBk',
    'Top 50 - Global': '37i9dQZEVXbMDoHDwVN2tF',
    'Punjabi 101': '37i9dQZF1DWZq9z102V7U6',
    'Mega Hit Mix': '37i9dQZF1DXbYM3nMM0oPk',
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _clientId = prefs.getString(_prefClientId);
    _clientSecret = prefs.getString(_prefClientSecret);
    _accessToken = prefs.getString(_prefToken);
    final expiryMs = prefs.getInt(_prefTokenExpiry);
    if (expiryMs != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    }
  }

  bool get isConfigured =>
      _clientId != null &&
      _clientId!.trim().isNotEmpty &&
      _clientSecret != null &&
      _clientSecret!.trim().isNotEmpty;

  String? get clientId => _clientId;
  String? get clientSecret => _clientSecret;

  Future<void> setCredentials(String clientId, String clientSecret) async {
    _clientId = clientId.trim();
    _clientSecret = clientSecret.trim();
    _accessToken = null;
    _tokenExpiry = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefClientId, _clientId!);
    await prefs.setString(_prefClientSecret, _clientSecret!);
    await prefs.remove(_prefToken);
    await prefs.remove(_prefTokenExpiry);
  }

  Future<void> clearCredentials() async {
    _clientId = null;
    _clientSecret = null;
    _accessToken = null;
    _tokenExpiry = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefClientId);
    await prefs.remove(_prefClientSecret);
    await prefs.remove(_prefToken);
    await prefs.remove(_prefTokenExpiry);
  }

  Future<String?> getAccessToken({http.Client? client}) async {
    if (!isConfigured) return null;

    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      return _accessToken;
    }

    final httpClient = client ?? http.Client();
    try {
      final creds = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      final response = await httpClient.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $creds',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int? ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefToken, _accessToken!);
        await prefs.setInt(_prefTokenExpiry, _tokenExpiry!.millisecondsSinceEpoch);
        return _accessToken;
      }
    } catch (_) {} finally {
      if (client == null) {
        httpClient.close();
      }
    }
    return null;
  }

  Future<List<SongModel>> searchTracks(String query, {int limit = 20, http.Client? client}) async {
    if (query.trim().isEmpty) return [];
    final token = await getAccessToken(client: client);
    if (token == null) return [];

    final httpClient = client ?? http.Client();
    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final uri = Uri.parse(
          'https://api.spotify.com/v1/search?q=$encodedQuery&type=track&limit=$limit');
      final response = await httpClient.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['tracks']?['items'] as List<dynamic>? ?? [];
        return items.map((item) => parseSpotifyTrack(item)).toList();
      }
    } catch (_) {} finally {
      if (client == null) {
        httpClient.close();
      }
    }
    return [];
  }

  Future<List<SongModel>> getPlaylistTracks(String playlistId, {int limit = 25, http.Client? client}) async {
    final token = await getAccessToken(client: client);
    if (token == null) return [];

    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse(
          'https://api.spotify.com/v1/playlists/$playlistId/tracks?limit=$limit');
      final response = await httpClient.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        final tracks = <SongModel>[];
        for (final item in items) {
          final track = item['track'];
          if (track != null && track['name'] != null) {
            tracks.add(parseSpotifyTrack(track));
          }
        }
        return tracks;
      }
    } catch (_) {} finally {
      if (client == null) {
        httpClient.close();
      }
    }
    return [];
  }

  static SongModel parseSpotifyTrack(Map<String, dynamic> track) {
    final id = track['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final title = track['name']?.toString() ?? 'Unknown Track';
    final artistsList = track['artists'] as List<dynamic>? ?? [];
    final artist = artistsList
        .map((a) => a['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    final albumName = track['album']?['name']?.toString() ?? 'Single';
    final images = track['album']?['images'] as List<dynamic>? ?? [];
    final artworkUrl = images.isNotEmpty ? (images[0]['url']?.toString() ?? '') : '';
    final durationMs = track['duration_ms'] as int? ?? 0;

    return SongModel(
      id: 'sp_$id',
      title: title,
      artist: artist.isNotEmpty ? artist : 'Spotify Artist',
      album: albumName,
      duration: (durationMs / 1000).round(),
      streamUrl: '', // Resolved on demand to 320kbps JioSaavn / YouTube
      artworkUrl: artworkUrl,
      source: 'spotify',
      qualityBadge: 'Studio HD',
      language: 'all',
      isOffline: false,
    );
  }
}
