import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/song_model.dart';

class LocalAudioService extends ChangeNotifier {
  static final LocalAudioService _instance = LocalAudioService._internal();
  factory LocalAudioService() => _instance;
  LocalAudioService._internal();

  final List<SongModel> _songs = [];
  bool _isScanning = false;
  String _statusMessage = '';

  List<SongModel> get songs => List.unmodifiable(_songs);
  bool get isScanning => _isScanning;
  String get statusMessage => _statusMessage;

  static const Set<String> supportedExtensions = {
    '.mp3',
    '.m4a',
    '.wav',
    '.aac',
    '.flac',
    '.ogg',
  };

  static const List<String> standardAndroidPaths = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/storage/emulated/0/Podcasts',
    '/storage/emulated/0/Audiobooks',
    '/sdcard/Music',
    '/sdcard/Download',
  ];

  /// Scan specific list of directories (useful for testing or custom folders)
  Future<List<SongModel>> scanDirectories(List<Directory> dirs) async {
    _isScanning = true;
    _statusMessage = 'Scanning device directories...';
    notifyListeners();

    final found = <SongModel>[];
    final seenPaths = <String>{};

    for (final dir in dirs) {
      if (!dir.existsSync()) continue;
      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final ext = _getExtension(entity.path).toLowerCase();
            if (supportedExtensions.contains(ext) && !seenPaths.contains(entity.path)) {
              seenPaths.add(entity.path);
              found.add(_fileToSong(entity, ext));
            }
          }
        }
      } catch (_) {
        // Silently skip inaccessible or permission-restricted subdirectories
      }
    }

    // Sort alphabetically by title
    found.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    _songs.clear();
    _songs.addAll(found);
    _isScanning = false;
    _statusMessage = 'Found ${_songs.length} device songs';
    notifyListeners();
    return _songs;
  }

  /// Automatically scan standard Android music storage locations
  Future<List<SongModel>> scanDeviceStorage() async {
    final dirs = <Directory>[];
    for (final path in standardAndroidPaths) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        dirs.add(dir);
      }
    }

    return scanDirectories(dirs);
  }

  List<SongModel> search(String query) {
    if (query.trim().isEmpty) return _songs;
    final q = query.toLowerCase().trim();
    return _songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q);
    }).toList();
  }

  String _getExtension(String path) {
    final idx = path.lastIndexOf('.');
    if (idx == -1) return '';
    return path.substring(idx);
  }

  SongModel _fileToSong(File file, String ext) {
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : file.path.split(Platform.pathSeparator).last;

    final dotIdx = fileName.lastIndexOf('.');
    final baseName = dotIdx != -1 ? fileName.substring(0, dotIdx) : fileName;

    String artist = 'Device Storage';
    String title = baseName;

    if (baseName.contains(' - ')) {
      final parts = baseName.split(' - ');
      artist = parts[0].trim();
      title = parts.sublist(1).join(' - ').trim();
    }

    String badge = 'MP3 320kbps';
    if (ext == '.flac') {
      badge = 'FLAC Lossless';
    } else if (ext == '.wav') {
      badge = 'WAV Hi-Fi';
    } else if (ext == '.m4a' || ext == '.aac') {
      badge = 'AAC 256kbps';
    }

    final parentDir = file.parent.uri.pathSegments.where((p) => p.isNotEmpty).toList();
    final albumName = parentDir.isNotEmpty ? parentDir.last : 'Device Audio';

    return SongModel(
      id: 'device_${file.path.hashCode.abs()}',
      title: title.isEmpty ? 'Unknown Track' : title,
      artist: artist.isEmpty ? 'Device Storage' : artist,
      album: albumName,
      duration: 0,
      streamUrl: file.path,
      artworkUrl: '',
      source: 'device',
      qualityBadge: badge,
      language: 'Hindi', // fallback language matching default
      isOffline: true,
      localFilePath: file.path,
    );
  }

  void clear() {
    _songs.clear();
    notifyListeners();
  }
}
