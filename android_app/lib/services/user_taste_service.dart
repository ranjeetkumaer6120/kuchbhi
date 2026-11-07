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
  static const String _searchCountsKey = 'soundvibe_search_counts_v2';
  static const String _artistSkipCountsKey = 'soundvibe_artist_skip_counts_v2';
  static const String _songSkipCountsKey = 'soundvibe_song_skip_counts_v2';

  // Advanced Taste Tracking Keys
  static const String _favoriteSongIdsKey = 'soundvibe_favorite_song_ids_v1';
  static const String _favoriteArtistCountsKey = 'soundvibe_favorite_artist_counts_v1';
  static const String _languagePlayCountsKey = 'soundvibe_language_play_counts_v1';
  static const String _instantSkipCountsKey = 'soundvibe_instant_skips_v1';
  static const String _timeSlotPlayCountsKey = 'soundvibe_timeslot_plays_v1';
  static const String _playTimestampsKey = 'soundvibe_song_timestamps_v1';
  static const String _shareCountsKey = 'soundvibe_share_counts_v1';

  final Map<String, SongModel> _songCatalog = {};
  final Map<String, int> _songPlayCounts = {};
  final Map<String, int> _songLastPlayed = {};
  final Map<String, int> _artistPlayCounts = {};
  final Map<String, int> _searchCounts = {};
  final Map<String, int> _artistSkipCounts = {};
  final Map<String, int> _songSkipCounts = {};

  // Advanced Taste Collections
  final Set<String> _favoriteSongIds = {};
  final Map<String, int> _favoriteArtistCounts = {};
  final Map<String, int> _languagePlayCounts = {};
  final Map<String, int> _instantSkipCounts = {};
  final Map<String, int> _timeSlotPlayCounts = {};
  final Map<String, List<int>> _songPlayTimestamps = {};
  final Map<String, int> _shareCounts = {};

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

      // Load Search Counts
      final searchJson = prefs.getString(_searchCountsKey);
      if (searchJson != null && searchJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(searchJson);
        _searchCounts.clear();
        decoded.forEach((k, count) {
          _searchCounts[k] = count is int ? count : int.tryParse(count.toString()) ?? 1;
        });
      }

      // Load Artist Skip Counts
      final artistSkipJson = prefs.getString(_artistSkipCountsKey);
      if (artistSkipJson != null && artistSkipJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(artistSkipJson);
        _artistSkipCounts.clear();
        decoded.forEach((artist, count) {
          _artistSkipCounts[artist] = count is int ? count : int.tryParse(count.toString()) ?? 1;
        });
      }

      // Load Song Skip Counts
      final songSkipJson = prefs.getString(_songSkipCountsKey);
      if (songSkipJson != null && songSkipJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(songSkipJson);
        _songSkipCounts.clear();
        decoded.forEach((id, count) {
          _songSkipCounts[id] = count is int ? count : int.tryParse(count.toString()) ?? 1;
        });
      }

      // Load Favorites
      final favList = prefs.getStringList(_favoriteSongIdsKey);
      if (favList != null) {
        _favoriteSongIds.clear();
        _favoriteSongIds.addAll(favList);
      }

      // Load Favorite Artist Counts
      final favArtistJson = prefs.getString(_favoriteArtistCountsKey);
      if (favArtistJson != null && favArtistJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(favArtistJson);
        _favoriteArtistCounts.clear();
        decoded.forEach((k, v) {
          _favoriteArtistCounts[k] = v is int ? v : int.tryParse(v.toString()) ?? 1;
        });
      }

      // Load Language Counts
      final langJson = prefs.getString(_languagePlayCountsKey);
      if (langJson != null && langJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(langJson);
        _languagePlayCounts.clear();
        decoded.forEach((k, v) {
          _languagePlayCounts[k] = v is int ? v : int.tryParse(v.toString()) ?? 1;
        });
      }

      // Load Instant Skips
      final instantJson = prefs.getString(_instantSkipCountsKey);
      if (instantJson != null && instantJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(instantJson);
        _instantSkipCounts.clear();
        decoded.forEach((k, v) {
          _instantSkipCounts[k] = v is int ? v : int.tryParse(v.toString()) ?? 1;
        });
      }

      // Load Time Slot Plays
      final timeSlotJson = prefs.getString(_timeSlotPlayCountsKey);
      if (timeSlotJson != null && timeSlotJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(timeSlotJson);
        _timeSlotPlayCounts.clear();
        decoded.forEach((k, v) {
          _timeSlotPlayCounts[k] = v is int ? v : int.tryParse(v.toString()) ?? 1;
        });
      }

      // Load Play Timestamps
      final timestampsJson = prefs.getString(_playTimestampsKey);
      if (timestampsJson != null && timestampsJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(timestampsJson);
        _songPlayTimestamps.clear();
        decoded.forEach((k, v) {
          if (v is List) {
            _songPlayTimestamps[k] = v.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
          }
        });
      }

      // Load Share Counts
      final shareJson = prefs.getString(_shareCountsKey);
      if (shareJson != null && shareJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(shareJson);
        _shareCounts.clear();
        decoded.forEach((k, v) {
          _shareCounts[k] = v is int ? v : int.tryParse(v.toString()) ?? 1;
        });
      }

      _initialized = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> recordPlay(SongModel song, {DateTime? timestamp}) async {
    if (song.id.isEmpty) return;

    final now = (timestamp ?? DateTime.now()).millisecondsSinceEpoch;
    _songCatalog[song.id] = song;
    _songPlayCounts[song.id] = (_songPlayCounts[song.id] ?? 0) + 1;
    _songLastPlayed[song.id] = now;

    // Track artist play count (clean artists)
    final cleanedArtist = _extractPrimaryArtist(song.artist);
    if (cleanedArtist.isNotEmpty) {
      _artistPlayCounts[cleanedArtist] = (_artistPlayCounts[cleanedArtist] ?? 0) + 1;
    }

    // Track language play
    if (song.language.isNotEmpty) {
      recordLanguagePlay(song.language);
    }

    // Track timestamp for heavy rotation
    _recordPlayTimestamp(song.id, now);

    // Track time-of-day slot
    final slot = getTimeSlot(timestamp ?? DateTime.now());
    _timeSlotPlayCounts['$slot:${song.id}'] = (_timeSlotPlayCounts['$slot:${song.id}'] ?? 0) + 1;
    if (cleanedArtist.isNotEmpty) {
      _timeSlotPlayCounts['$slot:$cleanedArtist'] = (_timeSlotPlayCounts['$slot:$cleanedArtist'] ?? 0) + 1;
    }

    notifyListeners();
    await _persist();
  }

  /// Records user search query to dynamically adapt interest profile
  Future<void> recordSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.length < 2) return;

    final key = trimmed.toLowerCase();
    _searchCounts[key] = (_searchCounts[key] ?? 0) + 1;

    // Also record primary word/artist token if multi-word query
    final primaryToken = trimmed.split(RegExp(r'\s+')).first.toLowerCase();
    if (primaryToken != key && primaryToken.length >= 3) {
      _searchCounts[primaryToken] = (_searchCounts[primaryToken] ?? 0) + 1;
    }

    notifyListeners();
    await _persist();
  }

  /// Records explicit favorite / un-favorite actions
  Future<void> recordFavorite(SongModel song, {required bool isFavorite}) async {
    if (song.id.isEmpty) return;
    _songCatalog[song.id] = song;

    final cleanedArtist = _extractPrimaryArtist(song.artist);

    if (isFavorite) {
      _favoriteSongIds.add(song.id);
      if (cleanedArtist.isNotEmpty) {
        _favoriteArtistCounts[cleanedArtist] = (_favoriteArtistCounts[cleanedArtist] ?? 0) + 1;
      }
    } else {
      _favoriteSongIds.remove(song.id);
      if (cleanedArtist.isNotEmpty && (_favoriteArtistCounts[cleanedArtist] ?? 0) > 0) {
        _favoriteArtistCounts[cleanedArtist] = _favoriteArtistCounts[cleanedArtist]! - 1;
        if (_favoriteArtistCounts[cleanedArtist]! <= 0) {
          _favoriteArtistCounts.remove(cleanedArtist);
        }
      }
    }

    notifyListeners();
    await _persist();
  }

  /// Records language listening
  Future<void> recordLanguagePlay(String rawLanguage) async {
    final clean = rawLanguage.trim().toLowerCase();
    if (clean.isEmpty) return;
    _languagePlayCounts[clean] = (_languagePlayCounts[clean] ?? 0) + 1;
    notifyListeners();
    await _persist();
  }

  /// Records story card generation or sharing
  Future<void> recordShare(SongModel song) async {
    if (song.id.isEmpty) return;
    _songCatalog[song.id] = song;
    _shareCounts[song.id] = (_shareCounts[song.id] ?? 0) + 1;
    notifyListeners();
    await _persist();
  }

  /// Comprehensive playback session analysis (instant skip, normal skip, full completion)
  Future<void> recordPlaybackSession(
    SongModel song, {
    required int playedSeconds,
    int totalDuration = 0,
    DateTime? timestamp,
  }) async {
    if (song.id.isEmpty) return;
    _songCatalog[song.id] = song;

    final cleanedArtist = _extractPrimaryArtist(song.artist);
    final now = (timestamp ?? DateTime.now()).millisecondsSinceEpoch;
    final slot = getTimeSlot(timestamp ?? DateTime.now());

    // 1. Instant Skip (<= 5 seconds): Severe dislike signal (Do NOT record time-slot or language)
    if (playedSeconds <= 5) {
      _instantSkipCounts[song.id] = (_instantSkipCounts[song.id] ?? 0) + 1;
      if (cleanedArtist.isNotEmpty) {
        _artistSkipCounts[cleanedArtist] = (_artistSkipCounts[cleanedArtist] ?? 0) + 2;
      }
      notifyListeners();
      await _persist();
      return;
    }

    // Record time slot
    _timeSlotPlayCounts['$slot:${song.id}'] = (_timeSlotPlayCounts['$slot:${song.id}'] ?? 0) + 1;
    if (cleanedArtist.isNotEmpty) {
      _timeSlotPlayCounts['$slot:$cleanedArtist'] = (_timeSlotPlayCounts['$slot:$cleanedArtist'] ?? 0) + 1;
    }

    // Record language
    if (song.language.isNotEmpty) {
      final clean = song.language.trim().toLowerCase();
      _languagePlayCounts[clean] = (_languagePlayCounts[clean] ?? 0) + 1;
    }

    // 2. Normal Skip (<= 20 seconds): Skip penalty
    if (playedSeconds <= 20) {
      _songSkipCounts[song.id] = (_songSkipCounts[song.id] ?? 0) + 1;
      if (cleanedArtist.isNotEmpty) {
        _artistSkipCounts[cleanedArtist] = (_artistSkipCounts[cleanedArtist] ?? 0) + 1;
      }
    }
    // 3. Positive Engagement (completion ratio or extended listen)
    else {
      final completionRatio = totalDuration > 0 ? (playedSeconds / totalDuration) : 0.0;
      if (completionRatio >= 0.80 || playedSeconds >= 120) {
        // High affinity completion
        if (cleanedArtist.isNotEmpty) {
          _artistPlayCounts[cleanedArtist] = (_artistPlayCounts[cleanedArtist] ?? 0) + 2;
        }
        _recordPlayTimestamp(song.id, now);
      } else if (completionRatio >= 0.40 || playedSeconds >= 45) {
        // Moderate affinity
        if (cleanedArtist.isNotEmpty) {
          _artistPlayCounts[cleanedArtist] = (_artistPlayCounts[cleanedArtist] ?? 0) + 1;
        }
        _recordPlayTimestamp(song.id, now);
      }
    }

    notifyListeners();
    await _persist();
  }

  void _recordPlayTimestamp(String songId, int epochMs) {
    final list = _songPlayTimestamps.putIfAbsent(songId, () => []);
    list.add(epochMs);
    // Keep only timestamps within last 48 hours
    final cutoff = epochMs - (48 * 60 * 60 * 1000);
    list.removeWhere((t) => t < cutoff);
  }

  /// Records quick skips to penalize irrelevant or annoying tracks (backward compatibility)
  Future<void> recordSkip(SongModel song, {int playedSeconds = 0}) async {
    await recordPlaybackSession(song, playedSeconds: playedSeconds, totalDuration: song.duration);
  }

  /// Records full completion (>30s) as strong positive affinity (backward compatibility)
  Future<void> recordCompletion(SongModel song) async {
    await recordPlaybackSession(song, playedSeconds: song.duration > 0 ? song.duration : 180, totalDuration: song.duration);
  }

  String _extractPrimaryArtist(String rawArtist) {
    if (rawArtist.isEmpty || rawArtist.toLowerCase() == 'device storage') return '';
    // Split on comma, &, feat., ft., /
    final firstPart = rawArtist.split(RegExp(r'[,&/]|\bfeat\.?|\bft\.?', caseSensitive: false)).first.trim();
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

      // Persist Searches
      await prefs.setString(_searchCountsKey, json.encode(_searchCounts));

      // Persist Skips
      await prefs.setString(_artistSkipCountsKey, json.encode(_artistSkipCounts));
      await prefs.setString(_songSkipCountsKey, json.encode(_songSkipCounts));

      // Persist Advanced
      await prefs.setStringList(_favoriteSongIdsKey, _favoriteSongIds.toList());
      await prefs.setString(_favoriteArtistCountsKey, json.encode(_favoriteArtistCounts));
      await prefs.setString(_languagePlayCountsKey, json.encode(_languagePlayCounts));
      await prefs.setString(_instantSkipCountsKey, json.encode(_instantSkipCounts));
      await prefs.setString(_timeSlotPlayCountsKey, json.encode(_timeSlotPlayCounts));
      await prefs.setString(_playTimestampsKey, json.encode(_songPlayTimestamps));
      await prefs.setString(_shareCountsKey, json.encode(_shareCounts));
    } catch (_) {}
  }

  int getPlayCount(String songId) {
    return _songPlayCounts[songId] ?? 0;
  }

  /// Returns whether a song is on heavy rotation (played 3+ times in the last 48 hours)
  bool isHeavyRotation(String songId, {DateTime? now}) {
    final list = _songPlayTimestamps[songId];
    if (list == null || list.isEmpty) return false;
    final currentEpoch = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final cutoff = currentEpoch - (48 * 60 * 60 * 1000);
    final count = list.where((t) => t >= cutoff).length;
    return count >= 3;
  }

  /// Returns songs currently on heavy rotation
  List<SongModel> getHeavyRotationSongs({int limit = 10, DateTime? now}) {
    final list = _songCatalog.values.where((s) => isHeavyRotation(s.id, now: now)).toList();
    list.sort((a, b) {
      final countA = _songPlayTimestamps[a.id]?.length ?? 0;
      final countB = _songPlayTimestamps[b.id]?.length ?? 0;
      return countB.compareTo(countA);
    });
    if (list.length > limit) return list.sublist(0, limit);
    return list;
  }

  /// Returns user's top languages sorted by play frequency
  List<String> getTopLanguages({int limit = 3}) {
    final entries = _languagePlayCounts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).take(limit).toList();
  }

  /// Returns current time slot string ('Morning', 'Afternoon', 'Evening', 'Night')
  String getTimeSlot([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  /// Calculates real-time affinity score for a song based on all user taste signals
  double calculateSongAffinity(SongModel song, {DateTime? contextualTime}) {
    double score = 0.0;
    final cleanedArtist = _extractPrimaryArtist(song.artist);

    // 1. Specific song repeat plays boost (+5.0 each)
    final songPlays = _songPlayCounts[song.id] ?? 0;
    score += songPlays * 5.0;

    // 2. Artist plays boost (+4.0 each)
    if (cleanedArtist.isNotEmpty) {
      final artistPlays = _artistPlayCounts[cleanedArtist] ?? 0;
      score += artistPlays * 4.0;
    }

    // 3. Explicit Favorite boost (+10.0 for favorited song, +4.0 for favorited artist)
    if (_favoriteSongIds.contains(song.id)) {
      score += 10.0;
    }
    if (cleanedArtist.isNotEmpty && (_favoriteArtistCounts[cleanedArtist] ?? 0) > 0) {
      score += (_favoriteArtistCounts[cleanedArtist] ?? 0) * 4.0;
    }

    // 4. Heavy Rotation / Binge boost (+6.0)
    if (isHeavyRotation(song.id, now: contextualTime)) {
      score += 6.0;
    }

    // 5. Language auto-preference boost
    final topLangs = getTopLanguages(limit: 3);
    final songLang = song.language.trim().toLowerCase();
    if (songLang.isNotEmpty && topLangs.isNotEmpty) {
      if (topLangs.first == songLang) {
        score += 4.5;
      } else if (topLangs.contains(songLang)) {
        score += 2.0;
      }
    }

    // 6. Time-of-day contextual affinity boost
    final slot = getTimeSlot(contextualTime);
    final songSlotPlays = _timeSlotPlayCounts['$slot:${song.id}'] ?? 0;
    final artistSlotPlays = cleanedArtist.isNotEmpty ? (_timeSlotPlayCounts['$slot:$cleanedArtist'] ?? 0) : 0;
    if (songSlotPlays > 0 || artistSlotPlays > 0) {
      score += 3.5;
    }

    // 7. Share / Story Card boost (+7.0)
    final shares = _shareCounts[song.id] ?? 0;
    score += shares * 7.0;

    // 8. Search keyword match in song title / artist
    final titleLower = song.title.toLowerCase();
    final artistLower = song.artist.toLowerCase();
    for (final searchEntry in _searchCounts.entries) {
      if (searchEntry.key.length >= 3) {
        if (titleLower.contains(searchEntry.key) || artistLower.contains(searchEntry.key)) {
          score += searchEntry.value * 2.5;
        }
      }
    }

    // 9. Instant Skips (<= 5s) heavy demotion (-10.0 song, -5.0 artist)
    final instantSkips = _instantSkipCounts[song.id] ?? 0;
    score -= instantSkips * 10.0;

    // 10. Normal Skips (<= 20s) demotion (-4.0 song, -2.5 artist)
    final songSkips = _songSkipCounts[song.id] ?? 0;
    score -= songSkips * 4.0;
    if (cleanedArtist.isNotEmpty) {
      final artistSkips = _artistSkipCounts[cleanedArtist] ?? 0;
      score -= artistSkips * 2.5;
    }

    return score;
  }

  /// Personalizes generic trending tracks by re-ranking them according to user's taste score.
  /// User's favorite artists, languages & vibes are pushed to the top, while irrelevant or skipped songs are demoted.
  List<SongModel> getPersonalizedTrending(List<SongModel> globalTrending, {int limit = 30, DateTime? contextualTime}) {
    if (globalTrending.isEmpty) return [];

    final hasAnyTaste = _songPlayCounts.isNotEmpty ||
        _searchCounts.isNotEmpty ||
        _artistSkipCounts.isNotEmpty ||
        _favoriteSongIds.isNotEmpty ||
        _languagePlayCounts.isNotEmpty ||
        _instantSkipCounts.isNotEmpty;

    if (!hasAnyTaste) {
      return globalTrending.take(limit).toList();
    }

    final scored = globalTrending.asMap().entries.map((entry) {
      final index = entry.key;
      final song = entry.value;
      final affinity = calculateSongAffinity(song, contextualTime: contextualTime);
      // Small momentum score so ties respect original trending rank
      final globalRankScore = (globalTrending.length - index) * 0.05;
      final totalScore = affinity + globalRankScore;
      return MapEntry(song, totalScore);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(limit).toList();
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

  /// Returns personalized mood pills based on all user interest signals
  /// STRICT ICON-FREE: Absolutely zero emoji icons
  List<String> getPersonalizedVibePills({List<SongModel>? favorites, DateTime? contextualTime}) {
    final pills = <String>[];
    final mostPlayed = getMostPlayedSongs();
    final heavyRotation = getHeavyRotationSongs(now: contextualTime);
    final topArtists = getTopArtists(limit: 3);
    final topLangs = getTopLanguages(limit: 2);
    final slot = getTimeSlot(contextualTime);

    if (mostPlayed.isNotEmpty) {
      pills.add('On Repeat');
    }

    if (heavyRotation.length >= 2) {
      pills.add('Heavy Rotation');
    }

    for (final artist in topArtists) {
      pills.add(artist);
    }

    // Time-of-day contextual vibe (clean text, no icons)
    switch (slot) {
      case 'Morning':
        pills.add('Morning Mix');
        break;
      case 'Afternoon':
        pills.add('Afternoon Chill');
        break;
      case 'Evening':
        pills.add('Evening Acoustic');
        break;
      case 'Night':
        pills.add('Late Night Lo-Fi');
        break;
    }

    // User's top language vibes
    for (final lang in topLangs) {
      final capitalized = lang.isNotEmpty ? '${lang[0].toUpperCase()}${lang.substring(1)}' : '';
      if (capitalized.isNotEmpty) {
        pills.add('$capitalized Hits');
      }
    }

    if (favorites != null && favorites.isNotEmpty) {
      pills.add('Favorites Mix');
    }

    // Neutral popular vibes - purely clean text, zero icons
    pills.addAll([
      'Trending Hits',
      'Chill Lo-Fi',
      'Bollywood Beats',
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
    _searchCounts.clear();
    _artistSkipCounts.clear();
    _songSkipCounts.clear();
    _favoriteSongIds.clear();
    _favoriteArtistCounts.clear();
    _languagePlayCounts.clear();
    _instantSkipCounts.clear();
    _timeSlotPlayCounts.clear();
    _songPlayTimestamps.clear();
    _shareCounts.clear();
    _initialized = false;
  }

  Future<void> clearHistory() async {
    _songCatalog.clear();
    _songPlayCounts.clear();
    _songLastPlayed.clear();
    _artistPlayCounts.clear();
    _searchCounts.clear();
    _artistSkipCounts.clear();
    _songSkipCounts.clear();
    _favoriteSongIds.clear();
    _favoriteArtistCounts.clear();
    _languagePlayCounts.clear();
    _instantSkipCounts.clear();
    _timeSlotPlayCounts.clear();
    _songPlayTimestamps.clear();
    _shareCounts.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_catalogKey);
      await prefs.remove(_playCountsKey);
      await prefs.remove(_lastPlayedKey);
      await prefs.remove(_artistCountsKey);
      await prefs.remove(_searchCountsKey);
      await prefs.remove(_artistSkipCountsKey);
      await prefs.remove(_songSkipCountsKey);
      await prefs.remove(_favoriteSongIdsKey);
      await prefs.remove(_favoriteArtistCountsKey);
      await prefs.remove(_languagePlayCountsKey);
      await prefs.remove(_instantSkipCountsKey);
      await prefs.remove(_timeSlotPlayCountsKey);
      await prefs.remove(_playTimestampsKey);
      await prefs.remove(_shareCountsKey);
    } catch (_) {}
  }
}
