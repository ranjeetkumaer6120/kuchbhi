import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'download_service.dart';
import 'user_taste_service.dart';

class PlaylistService extends ChangeNotifier {
  static const String _favKey = 'soundvibe_favorites_v1';
  static const String _foldersKey = 'soundvibe_folders_v1';
  static const String _autoDownloadKey = 'soundvibe_auto_download_favs';

  final Map<String, SongModel> _favorites = {};
  final Map<String, List<SongModel>> _folders = {};
  bool _autoDownloadFavorites = false;

  List<SongModel> get favorites => _favorites.values.toList();
  List<String> get folderNames => _folders.keys.toList();
  bool get autoDownloadFavorites => _autoDownloadFavorites;

  bool isFavorite(String songId) => _favorites.containsKey(songId);

  List<SongModel> getFolderSongs(String folderName) {
    return _folders[folderName] ?? [];
  }

  Future<void> setAutoDownloadFavorites(bool enable) async {
    _autoDownloadFavorites = enable;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoDownloadKey, enable);
    } catch (_) {}
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoDownloadFavorites = prefs.getBool(_autoDownloadKey) ?? false;

      // Load favorites
      final favJson = prefs.getString(_favKey);
      if (favJson != null && favJson.isNotEmpty) {
        final List<dynamic> list = json.decode(favJson);
        _favorites.clear();
        for (final item in list) {
          final s = SongModel.fromJson(item as Map<String, dynamic>);
          _favorites[s.id] = s;
        }
      }

      // Load folders
      final folderJson = prefs.getString(_foldersKey);
      if (folderJson != null && folderJson.isNotEmpty) {
        final Map<String, dynamic> map = json.decode(folderJson);
        _folders.clear();
        map.forEach((folderName, songsList) {
          final List<dynamic> sList = songsList as List<dynamic>;
          _folders[folderName] = sList.map((item) => SongModel.fromJson(item as Map<String, dynamic>)).toList();
        });
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _favorites.values.map((s) => s.toJson()).toList();
      await prefs.setString(_favKey, json.encode(list));
    } catch (_) {}
  }

  Future<void> _persistFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = {};
      _folders.forEach((name, songs) {
        map[name] = songs.map((s) => s.toJson()).toList();
      });
      await prefs.setString(_foldersKey, json.encode(map));
    } catch (_) {}
  }

  Future<void> toggleFavorite(SongModel song, {DownloadService? downloadService}) async {
    final bool isFavNow;
    if (_favorites.containsKey(song.id)) {
      _favorites.remove(song.id);
      isFavNow = false;
    } else {
      _favorites[song.id] = song;
      isFavNow = true;
      if (_autoDownloadFavorites && downloadService != null && !downloadService.isDownloaded(song.id)) {
        downloadService.downloadSong(song);
      }
    }
    // Update user taste profile with explicit favorite feedback
    UserTasteService().recordFavorite(song, isFavorite: isFavNow);

    notifyListeners();
    await _persistFavorites();
  }

  Future<void> createFolder(String name) async {
    final cleanName = name.trim();
    if (cleanName.isNotEmpty && !_folders.containsKey(cleanName)) {
      _folders[cleanName] = [];
      notifyListeners();
      await _persistFolders();
    }
  }

  Future<void> deleteFolder(String name) async {
    if (_folders.containsKey(name)) {
      _folders.remove(name);
      notifyListeners();
      await _persistFolders();
    }
  }

  Future<void> addSongToFolder(String folderName, SongModel song) async {
    if (_folders.containsKey(folderName)) {
      final list = _folders[folderName]!;
      if (!list.any((s) => s.id == song.id)) {
        list.add(song);
        notifyListeners();
        await _persistFolders();
      }
    }
  }

  Future<void> removeSongFromFolder(String folderName, String songId) async {
    if (_folders.containsKey(folderName)) {
      _folders[folderName]!.removeWhere((s) => s.id == songId);
      notifyListeners();
      await _persistFolders();
    }
  }
}
