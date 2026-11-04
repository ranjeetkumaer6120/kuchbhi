import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/lyrics_model.dart';
import '../models/song_model.dart';

class ApiService {
  final YoutubeExplode _yt = YoutubeExplode();

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json',
  };

  /// Search JioSaavn catalog with 320kbps direct audio streams (Rank 1: 320kbps)
  /// Supports infinite scroll pagination via [page] and [limit].
  Future<List<SongModel>> searchSongs(String query, {int page = 1, int limit = 20}) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=search.getResults&p=$page&n=$limit&q=${Uri.encodeComponent(query)}&_format=json&_marker=0&api_version=4&ctx=android',
      );

      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final results = decoded['results'] as List<dynamic>? ?? [];

        final songs = <SongModel>[];
        for (final item in results) {
          try {
            final song = SongModel.fromSaavnJson(item as Map<String, dynamic>);
            if (song.streamUrl.isNotEmpty) {
              songs.add(song);
            }
          } catch (_) {}
        }
        return deduplicateByQuality(songs);
      }
    } catch (_) {}
    return [];
  }

  /// Search Apple iTunes Search API (Rank 2: 256kbps HQ preview)
  Future<List<SongModel>> searchItunes(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=15',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final results = decoded['results'] as List<dynamic>? ?? [];

        final songs = <SongModel>[];
        for (final item in results) {
          try {
            final song = SongModel.fromItunesJson(item as Map<String, dynamic>);
            if (song.streamUrl.isNotEmpty) {
              songs.add(song);
            }
          } catch (_) {}
        }
        return songs;
      }
    } catch (_) {}
    return [];
  }

  /// Search Internet Archive Audio (Rank 4: Public Domain / Community audio)
  Future<List<SongModel>> searchArchive(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        'https://archive.org/advancedsearch.php?q=${Uri.encodeComponent(query)}+AND+mediatype:audio&fl[]=identifier,title,creator,description&rows=10&output=json',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final docs = decoded['response']?['docs'] as List<dynamic>? ?? [];

        final songs = <SongModel>[];
        for (final item in docs) {
          try {
            songs.add(SongModel.fromArchiveJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
        return songs;
      }
    } catch (_) {}
    return [];
  }

  /// Search / Fetch Live 24/7 FM Radio Stations (Radio Browser Public API)
  Future<List<SongModel>> getLiveRadioStations({String query = 'bollywood', int limit = 30}) async {
    try {
      final tag = query.toLowerCase().replaceAll('🔥', '').trim();
      final endpoint = tag.contains('india') || tag.contains('all')
          ? 'https://all.api.radio-browser.info/json/stations/bycountry/india?limit=$limit'
          : 'https://all.api.radio-browser.info/json/stations/bytag/${Uri.encodeComponent(tag.isNotEmpty ? tag : 'bollywood')}?limit=$limit';

      final response = await http.get(Uri.parse(endpoint), headers: _headers).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as List<dynamic>? ?? [];
        final stations = <SongModel>[];
        for (final item in decoded) {
          try {
            final song = SongModel.fromRadioJson(item as Map<String, dynamic>);
            if (song.streamUrl.isNotEmpty) {
              stations.add(song);
            }
          } catch (_) {}
        }
        return stations;
      }
    } catch (_) {}
    return [];
  }

  /// Search / Fetch Royalty-Free Lo-Fi & Chill Beats (FreeToUse Public API)
  Future<List<SongModel>> getFreeToUseTracks({int limit = 30}) async {
    try {
      final uri = Uri.parse('https://api.freetouse.com/v3/music/tracks/all?limit=$limit');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded['data'] as List<dynamic>? ?? [];
        final tracks = <SongModel>[];
        for (final item in list) {
          try {
            final song = SongModel.fromFreeToUseJson(item as Map<String, dynamic>);
            if (song.streamUrl.isNotEmpty) {
              tracks.add(song);
            }
          } catch (_) {}
        }
        return tracks;
      }
    } catch (_) {}
    return [];
  }

  /// Search YouTube Audio Streams via official direct client extraction (Rank 3: 160-192kbps)
  Future<List<SongModel>> searchYouTube(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final searchList = await _yt.search.search(query);
      final ytSongs = <SongModel>[];

      for (final video in searchList.take(20)) {
        ytSongs.add(SongModel(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: 'Single',
          duration: video.duration?.inSeconds ?? 0,
          streamUrl: '', // Will be resolved dynamically on tap or download
          artworkUrl: video.thumbnails.highResUrl,
          source: 'youtube',
          qualityBadge: 'Studio HD',
        ));
      }
      return deduplicateByQuality(ytSongs);
    } catch (_) {
      return [];
    }
  }

  /// Normalizes song title for fuzzy duplicate detection
  static String normalizeSongTitle(String title) {
    return title
        .toLowerCase()
        // Remove text in parentheses/brackets e.g. (From "Brahmastra"), [Official Video], (Full Song), (Audio), (Lyrics), (Remastered)
        .replaceAll(RegExp(r'\((from\s+[^)]*|official\s+[^)]*|audio|video|full\s+song|lyrics|remastered|hd|4k|lo-fi|slowed)[^)]*\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[(from\s+[^\]]*|official\s+[^\]]*|audio|video|full\s+song|lyrics|remastered|hd|4k|lo-fi|slowed)[^\]]*\]', caseSensitive: false), '')
        // Clean special characters
        .replaceAll(RegExp(r'[^\w\s]'), '')
        // Collapse multiple spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Normalizes artist name for fuzzy duplicate detection
  static String normalizeArtist(String artist) {
    return artist
        .toLowerCase()
        .split(',')
        .first
        .split('&')
        .first
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Smart Deduplication Engine:
  /// Keeps ONLY the highest quality version of any song and discards lower quality duplicates.
  static List<SongModel> deduplicateByQuality(List<SongModel> songs) {
    if (songs.isEmpty) return [];

    // Sort by quality score descending so highest quality track is processed first
    final sorted = List<SongModel>.from(songs)..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

    final seenKeys = <String>{};
    final result = <SongModel>[];

    for (final song in sorted) {
      final cleanTitle = normalizeSongTitle(song.title);
      final cleanArtist = normalizeArtist(song.artist);

      // Create unique match key
      final key = cleanArtist.isNotEmpty && cleanArtist != 'unknown' && !cleanArtist.contains('youtube')
          ? '$cleanTitle::$cleanArtist'
          : cleanTitle;

      if (!seenKeys.contains(key) && cleanTitle.isNotEmpty) {
        seenKeys.add(key);
        result.add(song);
      }
    }

    return result;
  }

  /// Multi-API Aggregator: Fetches 100% FULL LENGTH tracks from JioSaavn (320kbps Master)
  /// and YouTube HD, ensuring NO 30-second preview clips and NO duplicates are ever served.
  Future<List<SongModel>> searchAllSourcesAndRank(String query) async {
    if (query.trim().isEmpty) return [];

    final results = await Future.wait([
      searchSongs(query),
      searchYouTube(query),
      getLiveRadioStations(query: query, limit: 5),
    ]);

    final saavnList = results[0];
    final ytList = results[1];
    final radioList = results[2];

    final combined = <SongModel>[];
    // Full 320kbps CD/Master quality tracks from JioSaavn
    combined.addAll(saavnList);
    // Full length ad-free audio streams from YouTube
    combined.addAll(ytList);
    // Live 24/7 Radio stations matching search
    combined.addAll(radioList);

    // Smart deduplication: keeps ONLY the highest quality track per song
    return deduplicateByQuality(combined);
  }

  /// Get Trending & Featured Indian / International tracks for Apple Music "Listen Now"
  Future<List<SongModel>> getTrendingSongs({String category = 'Trending Hindi', int page = 1}) async {
    return searchSongs(category, page: page);
  }

  /// Extract direct raw googlevideo.com audio stream URL for a YouTube video
  Future<String?> getYouTubeAudioStream(String videoId) async {
    try {
      final cleanId = videoId.replaceFirst('yt_', '');
      final manifest = await _yt.videos.streamsClient.getManifest(cleanId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      return audioStream.url.toString();
    } catch (_) {
      return null;
    }
  }

  /// Fetch song lyrics from Lrclib (synchronized LRC) or JioSaavn database
  Future<LyricsData?> getLyrics(SongModel song) async {
    // 1. Try Lrclib first for synchronized real-time lyrics
    try {
      final cleanTitle = song.title
          .split('(').first
          .split('[').first
          .split('-').first
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();
      final cleanArtist = song.artist
          .split(',').first
          .split('&').first
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();

      final uri = Uri.parse(
        'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(cleanArtist)}&track_name=${Uri.encodeComponent(cleanTitle)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final synced = decoded['syncedLyrics']?.toString();
        final plain = decoded['plainLyrics']?.toString();
        final data = LyricsData.parse(syncedLyrics: synced, plainLyrics: plain);
        if (data.lines.isNotEmpty) return data;
      }
    } catch (_) {}

    // 2. Try JioSaavn official lyrics endpoint
    if (song.source == 'saavn') {
      try {
        final uri = Uri.parse(
          'https://www.jiosaavn.com/api.php?__call=lyrics.getLyrics&lyrics_id=${song.id}&ctx=web6dot0&api_version=4&_format=json',
        );
        final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded['lyrics'] != null) {
            String lyr = decoded['lyrics'].toString();
            lyr = lyr
                .replaceAll('<br/>', '\n')
                .replaceAll('<br>', '\n')
                .replaceAll('&quot;', '"')
                .replaceAll('&amp;', '&')
                .replaceAll('&#039;', "'")
                .trim();
            if (lyr.isNotEmpty) {
              return LyricsData.parse(plainLyrics: lyr);
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }
}
