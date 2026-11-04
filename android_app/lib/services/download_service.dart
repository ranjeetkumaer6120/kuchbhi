import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'api_service.dart';

class DownloadService extends ChangeNotifier {
  static const String _catalogKey = 'soundvibe_offline_catalog_v1';
  final Map<String, SongModel> _offlineSongs = {};
  final Map<String, double> _downloadProgress = {};

  List<SongModel> get offlineSongs => _offlineSongs.values.toList();
  Map<String, double> get downloadProgress => _downloadProgress;

  bool isDownloaded(String songId) => _offlineSongs.containsKey(songId);
  bool isDownloading(String songId) => _downloadProgress.containsKey(songId);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_catalogKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonStr);
        _offlineSongs.clear();
        for (final item in list) {
          final song = SongModel.fromJson(item as Map<String, dynamic>);
          // Verify file still exists on disk
          if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
            _offlineSongs[song.id] = song;
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _offlineSongs.values.map((s) => s.toJson()).toList();
      await prefs.setString(_catalogKey, json.encode(list));
    } catch (_) {}
  }

  Future<String?> downloadSong(
    SongModel song, {
    Function(double progress)? onProgress,
  }) async {
    if (isDownloaded(song.id)) return song.localFilePath;

    try {
      _downloadProgress[song.id] = 0.01;
      notifyListeners();

      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/soundvibe_music');
      if (!musicDir.existsSync()) {
        musicDir.createSync(recursive: true);
      }

      // Safe clean filename
      final sanitizedTitle = song.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final targetFile = File('${musicDir.path}/${song.id}_$sanitizedTitle.mp3');

      String downloadUrl = song.streamUrl;
      if (song.source == 'youtube' || downloadUrl.isEmpty) {
        final ytUrl = await ApiService().getYouTubeAudioStream(song.id);
        if (ytUrl != null && ytUrl.isNotEmpty) {
          downloadUrl = ytUrl;
        } else {
          _downloadProgress.remove(song.id);
          notifyListeners();
          return null;
        }
      } else if (song.source == 'itunes' || downloadUrl.contains('itunes.apple.com')) {
        // Resolve full track from JioSaavn or YouTube so the downloaded file is a complete song, not a 30s preview
        final fullSaavn = await ApiService().searchSongs('${song.title} ${song.artist}');
        if (fullSaavn.isNotEmpty && fullSaavn.first.streamUrl.isNotEmpty) {
          downloadUrl = fullSaavn.first.streamUrl;
        } else {
          final ytSearch = await ApiService().searchYouTube('${song.title} ${song.artist}');
          if (ytSearch.isNotEmpty) {
            final ytUrl = await ApiService().getYouTubeAudioStream(ytSearch.first.id);
            if (ytUrl != null && ytUrl.isNotEmpty) {
              downloadUrl = ytUrl;
            }
          }
        }
      }

      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await http.Client().send(request);

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;
      final sink = targetFile.openWrite();

      await response.stream.listen((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final p = receivedBytes / totalBytes;
          _downloadProgress[song.id] = p;
          onProgress?.call(p);
          notifyListeners();
        }
      }).asFuture();

      await sink.flush();
      await sink.close();

      song.isOffline = true;
      song.localFilePath = targetFile.path;
      _offlineSongs[song.id] = song;
      _downloadProgress.remove(song.id);

      await _persistCatalog();
      notifyListeners();

      return targetFile.path;
    } catch (e) {
      _downloadProgress.remove(song.id);
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteSong(String songId) async {
    final song = _offlineSongs[songId];
    if (song != null && song.localFilePath != null) {
      final file = File(song.localFilePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
      _offlineSongs.remove(songId);
      await _persistCatalog();
      notifyListeners();
    }
  }
}
