import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class UserTasteService extends ChangeNotifier {
  static final UserTasteService _instance = UserTasteService._internal();
  factory UserTasteService() => _instance;
  UserTasteService._internal();

  static const String _catalogKey = 'soundvibe_taste_catalog_v2';
  static const String _playCountsKey = 'soundvibe_song_play_counts_v2';
  static const String _lastPlayedKey = 'soundvibe_song_last_played_v2';
  static const String _artistCountsKey = 'soundvibe_artist_play_counts_v2';

  final Map<String, SongModel> _songCatalog = {};
  final Map<String, int> _songPlayCounts = {};
  final Map<String, int> _songLastPlayed = {};
  final Map<String, int> _artistPlayCounts = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;
  int get totalPlayedCount => _songPlayCounts.values.fold(0, (sum, count) => sum + count);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Catalog
      final catalogJson = prefs.getString(_catalogKey);
      if (catalogJson != null && catalogJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(catalogJson);
        _songCatalog.clear();
        decoded.forEach((id, item) {
          _songCatalog[id] = SongModel.fromJson(item as Map<String, dynamic>);
        });
      }

      // Load Play Counts
      final countsJson = prefs.getString(_playCountsKey);
      if (countsJson != null && countsJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(countsJson);
        _songPlayCounts.clear();
        decoded.forEach((id, count) {
          _songPlayCounts[id] = count is int ? count : int.tryParse(count.toString()) ?? 1;
        });
      }

      // Load Last Played
      final lastPlayedJson = prefs.getString(_lastPlayedKey);
      if (lastPlayedJson != null && lastPlayedJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(lastPlayedJson);
        _songLastPlayed.clear();
        decoded.forEach((id, time) {
          _songLastPlayed[id] = time is int ? time : int.tryParse(time.toString()) ?? 0;
        });
      }

      // Load Artist Counts
      final artistJson = prefs.getString(_artistCountsKey);
      if (artistJson != null && artistJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(artistJson);
        _artistPlayCounts.clear();
        decoded.forEach((artist, count) {
          _artistPlayCounts[artist] = count is int ? count : int.tryParse(count.toString()) ?? 1;
        });
      }

      _initialized = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> recordPlay(SongModel song) async {
    if (song.id.isEmpty) return;

    _songCatalog[song.id] = song;
    _songPlayCounts[song.id] = (_songPlayCounts[song.id] ?? 0) + 1;
    _songLastPlayed[song.id] = DateTime.now().millisecondsSinceEpoch;

    // Track artist play count (clean artists)
    final cleanedArtist = _extractPrimaryArtist(song.artist);
    if (cleanedArtist.isNotEmpty) {
      _artistPlayCounts[cleanedArtist] = (_artistPlayCounts[cleanedArtist] ?? 0) + 1;
    }

    notifyListeners();
    await _persist();
  }

  String _extractPrimaryArtist(String rawArtist) {
    if (rawArtist.isEmpty || rawArtist.toLowerCase() == 'device storage') return '';
    // Split on comma, &, feat., ft.
    final firstPart = rawArtist.split(RegExp(r'[,&]|\bfeat\.?|\bft\.?', caseSensitive: false)).first.trim();
    return firstPart;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Persist Catalog
      final catalogMap = _songCatalog.map((id, s) => MapEntry(id, s.toJson()));
      await prefs.setString(_catalogKey, json.encode(catalogMap));

      // Persist Play Counts
      await prefs.setString(_playCountsKey, json.encode(_songPlayCounts));

      // Persist Last Played
      await prefs.setString(_lastPlayedKey, json.encode(_songLastPlayed));

      // Persist Artist Counts
      await prefs.setString(_artistCountsKey, json.encode(_artistPlayCounts));
    } catch (_) {}
  }

  int getPlayCount(String songId) {
    return _songPlayCounts[songId] ?? 0;
  }

  /// Returns songs ordered by play count descending (Jo song zyada sunta hai)
  List<SongModel> getMostPlayedSongs({int limit = 20}) {
    final list = _songCatalog.values.where((s) => (_songPlayCounts[s.id] ?? 0) > 0).toList();
    list.sort((a, b) {
      final countA = _songPlayCounts[a.id] ?? 0;
      final countB = _songPlayCounts[b.id] ?? 0;
      return countB.compareTo(countA);
    });
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  /// Returns songs ordered by last played timestamp descending
  List<SongModel> getRecentlyPlayedSongs({int limit = 20}) {
    final list = _songCatalog.values.toList();
    list.sort((a, b) {
      final timeA = _songLastPlayed[a.id] ?? 0;
      final timeB = _songLastPlayed[b.id] ?? 0;
      return timeB.compareTo(timeA);
    });
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  /// Returns top artists the user listens to most
  List<String> getTopArtists({int limit = 6}) {
    final entries = _artistPlayCounts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).where((name) => name.isNotEmpty).take(limit).toList();
  }

  /// Returns personalized mood pills based on user interest
  /// (Strictly secular / modern / artist-driven; NO bhakti / NO morning ragas)
  List<String> getPersonalizedVibePills({List<SongModel>? favorites}) {
    final pills = <String>[];
    final mostPlayed = getMostPlayedSongs();
    final topArtists = getTopArtists(limit: 3);

    if (mostPlayed.isNotEmpty) {
      pills.add('🔥 On Repeat');
    }

    for (final artist in topArtists) {
      pills.add('⭐ $artist');
    }

    if (favorites != null && favorites.isNotEmpty) {
      pills.add('❤️ Favorites Mix');
    }

    // Always include modern popular vibes
    pills.addAll([
      '⚡ Trending Hits',
      '☕ Chill Lo-Fi',
      '🎧 Top Hindi',
      '🌾 Bhojpuri Hits',
      '🥁 Punjabi Top',
      '✨ Bollywood Beats',
    ]);

    // Deduplicate
    return pills.toSet().toList();
  }

  @visibleForTesting
  void resetForTesting() {
    _songCatalog.clear();
    _songPlayCounts.clear();
    _songLastPlayed.clear();
    _artistPlayCounts.clear();
    _initialized = false;
  }

  Future<void> clearHistory() async {
    _songCatalog.clear();
    _songPlayCounts.clear();
    _songLastPlayed.clear();
    _artistPlayCounts.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_catalogKey);
      await prefs.remove(_playCountsKey);
      await prefs.remove(_lastPlayedKey);
      await prefs.remove(_artistCountsKey);
    } catch (_) {}
  }
}
