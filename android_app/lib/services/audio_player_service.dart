import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'api_service.dart';
import 'sleep_timer_service.dart';
import 'user_taste_service.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final ApiService _apiService = ApiService();

  SongModel? _currentSong;
  List<SongModel> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  String? _currentLanguageLock;
  double _playbackSpeed = 1.0;
  bool _isLoFiMode = false;

  SongModel? get currentSong => _currentSong;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  bool get isLoop => _loopMode != LoopMode.off;
  String? get currentLanguageLock => _currentLanguageLock;
  double get playbackSpeed => _playbackSpeed;
  bool get isLoFiMode => _isLoFiMode;

  void setLanguageLock(String? language) {
    _currentLanguageLock = language?.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    _isLoFiMode = (speed == 0.85);
    try {
      await _player.setSpeed(speed);
      await _player.setPitch(speed);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleLoFiMode() async {
    if (_isLoFiMode) {
      await setSpeed(1.0);
    } else {
      await setSpeed(0.85);
    }
  }

  AudioPlayer get player => _player;

  SongModel? _lastTrackForAnalytics;
  Duration _lastTrackDurationPlayed = Duration.zero;

  void _onTrackTransition(SongModel newSong) {
    if (_lastTrackForAnalytics != null && _lastTrackForAnalytics!.id != newSong.id) {
      if (_lastTrackDurationPlayed.inSeconds <= 15) {
        UserTasteService().recordSkip(_lastTrackForAnalytics!, playedSeconds: _lastTrackDurationPlayed.inSeconds);
      } else if (_lastTrackDurationPlayed.inSeconds >= 30) {
        UserTasteService().recordCompletion(_lastTrackForAnalytics!);
      }
    }
    _lastTrackForAnalytics = newSong;
    _lastTrackDurationPlayed = Duration.zero;
  }

  AudioPlayerService() {
    _initStreams();
  }

  void _initStreams() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        if (_currentSong != null) {
          UserTasteService().recordCompletion(_currentSong!);
        }
        if (SleepTimerService.instance.isEndOfSongMode) {
          SleepTimerService.instance.onSongCompleted();
          return;
        }
        if (_loopMode == LoopMode.all) {
          _player.seek(Duration.zero, index: 0);
        } else if (!_player.hasNext) {
          _autoPopulateNextTracks();
        }
      }
      notifyListeners();
    });

    _player.currentIndexStream.listen((index) async {
      if (index != null && index >= 0 && index < _queue.length) {
        _currentIndex = index;
        _currentSong = _queue[index];
        if (_currentSong != null) {
          _onTrackTransition(_currentSong!);
          _currentLanguageLock = _currentSong!.language.toLowerCase().trim();
          UserTasteService().recordPlay(_currentSong!);
        }

        // Resolve YouTube stream on demand if entering a track without pre-resolved URL
        if (_currentSong!.source == 'youtube' &&
            (_currentSong!.streamUrl.isEmpty || _currentSong!.streamUrl.contains('kuchbhi.app'))) {
          final directUrl = await _apiService.getYouTubeAudioStream(_currentSong!.id);
          if (directUrl != null && directUrl.isNotEmpty) {
            final resolved = SongModel(
              id: _currentSong!.id,
              title: _currentSong!.title,
              artist: _currentSong!.artist,
              album: _currentSong!.album,
              duration: _currentSong!.duration,
              streamUrl: directUrl,
              artworkUrl: _currentSong!.artworkUrl,
              source: _currentSong!.source,
              qualityBadge: _currentSong!.qualityBadge,
              language: _currentSong!.language,
              isOffline: _currentSong!.isOffline,
              localFilePath: _currentSong!.localFilePath,
            );
            _queue[index] = resolved;
            _currentSong = resolved;

            if (index < _player.audioSources.length) {
              await _player.removeAudioSourceAt(index);
              await _player.insertAudioSource(
                index,
                AudioSource.uri(Uri.parse(directUrl), tag: _createMediaItem(resolved)),
              );
              await _player.seek(Duration.zero, index: index);
            }
          }
        }
        notifyListeners();
      }
    });

    _player.positionStream.listen((pos) {
      _position = pos;
      _lastTrackDurationPlayed = pos;
      notifyListeners();
      // Periodically persist seek position every 5 seconds so on sudden minimize/kill, exact position is preserved
      if (pos.inSeconds > 0 && pos.inSeconds % 5 == 0) {
        saveCurrentPlaybackSession();
      }
    });

    _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
  }

  MediaItem _createMediaItem(SongModel song) {
    return MediaItem(
      id: song.id,
      album: song.album,
      title: song.title,
      artist: song.artist,
      artUri: song.artworkUrl.isNotEmpty ? Uri.tryParse(song.artworkUrl) : null,
      playable: true,
    );
  }

  Future<void> playSong(SongModel song, {List<SongModel>? playlist}) async {
    try {
      _currentLanguageLock = song.language.toLowerCase().trim();

      if (playlist != null && playlist.isNotEmpty) {
        // Enforce language continuity: if playlist contains mixed languages,
        // filter/preserve tracks matching the active song's language so the queue
        // maintains uninterrupted language continuity.
        final activeLanguage = _currentLanguageLock!;
        final matchingTracks = playlist.where((s) => s.language.toLowerCase().trim() == activeLanguage).toList();

        if (matchingTracks.length > 1 && matchingTracks.any((s) => s.id == song.id)) {
          _queue = matchingTracks;
        } else {
          _queue = List.from(playlist);
        }

        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) {
          _queue.insert(0, song);
          _currentIndex = 0;
        }
      } else {
        if (!_queue.any((s) => s.id == song.id)) {
          _queue.add(song);
        }
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) _currentIndex = 0;
      }

      _onTrackTransition(song);
      _currentSong = song;
      _isBuffering = true;
      UserTasteService().recordPlay(song);
      notifyListeners();

      // Resolve stream URL for current track if needed
      if (song.source == 'youtube' || song.streamUrl.isEmpty) {
        final directUrl = await _apiService.getYouTubeAudioStream(song.id);
        if (directUrl != null && directUrl.isNotEmpty) {
          song = SongModel(
            id: song.id,
            title: song.title,
            artist: song.artist,
            album: song.album,
            duration: song.duration,
            streamUrl: directUrl,
            artworkUrl: song.artworkUrl,
            source: song.source,
            qualityBadge: song.qualityBadge,
            language: song.language,
            isOffline: song.isOffline,
            localFilePath: song.localFilePath,
          );
          _queue[_currentIndex] = song;
          _currentSong = song;
        }
      } else if (song.source == 'itunes' || song.streamUrl.contains('itunes.apple.com')) {
        final fullSaavn = await _apiService.searchSongs('${song.title} ${song.artist}', language: song.language);
        if (fullSaavn.isNotEmpty && fullSaavn.first.streamUrl.isNotEmpty) {
          song = SongModel(
            id: song.id,
            title: song.title,
            artist: song.artist,
            album: song.album,
            duration: song.duration,
            streamUrl: fullSaavn.first.streamUrl,
            artworkUrl: song.artworkUrl,
            source: song.source,
            qualityBadge: song.qualityBadge,
            language: song.language,
            isOffline: song.isOffline,
            localFilePath: song.localFilePath,
          );
          _queue[_currentIndex] = song;
          _currentSong = song;
        }
      }

      // Set playlist audio sources so ExoPlayer natively handles background track transitions
      // and system notification displays Skip to Previous / Skip to Next buttons!
      final audioSources = <AudioSource>[];
      for (final s in _queue) {
        final tag = _createMediaItem(s);
        if (s.isOffline && s.localFilePath != null && File(s.localFilePath!).existsSync()) {
          audioSources.add(AudioSource.file(s.localFilePath!, tag: tag));
        } else if (s.streamUrl.isNotEmpty) {
          audioSources.add(AudioSource.uri(Uri.parse(s.streamUrl), tag: tag));
        } else {
          audioSources.add(AudioSource.uri(Uri.parse('https://audio.kuchbhi.app/placeholder.mp3'), tag: tag));
        }
      }

      await _player.setAudioSources(
        audioSources,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );

      await _player.play();
      await saveCurrentPlaybackSession();
    } catch (e) {
      _isBuffering = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    await saveCurrentPlaybackSession();
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  Future<void> playNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_loopMode == LoopMode.all && _queue.isNotEmpty) {
      await _player.seek(Duration.zero, index: 0);
    } else if (_currentLanguageLock != null && _currentLanguageLock!.isNotEmpty) {
      await _autoPopulateNextTracks();
    }
  }

  Future<void> _autoPopulateNextTracks() async {
    final lang = (_currentLanguageLock != null && _currentLanguageLock!.isNotEmpty)
        ? _currentLanguageLock!
        : (_currentSong?.language.isNotEmpty == true ? _currentSong!.language : 'hindi');
    final query = (_currentSong != null && _currentSong!.artist.isNotEmpty && _currentSong!.artist != 'Unknown')
        ? _currentSong!.artist
        : 'Trending $lang';

    try {
      final suggestions = await _apiService.searchSongs(query, language: lang);
      final freshTracks = suggestions.where((s) => !_queue.any((q) => q.id == s.id)).toList();
      if (freshTracks.isNotEmpty) {
        final startIndex = _queue.length;
        _queue.addAll(freshTracks);
        for (final track in freshTracks) {
          final tag = _createMediaItem(track);
          if (track.streamUrl.isNotEmpty) {
            await _player.addAudioSource(
              AudioSource.uri(Uri.parse(track.streamUrl), tag: tag),
            );
          }
        }
        notifyListeners();
        if (_currentIndex < _queue.length - 1) {
          await _player.seek(Duration.zero, index: startIndex);
          await _player.play();
        }
      }
    } catch (_) {}
  }

  Future<void> playPrevious() async {
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _player.setShuffleModeEnabled(_isShuffle);
    notifyListeners();
  }

  void toggleLoop() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }
    _player.setLoopMode(_loopMode);
    notifyListeners();
  }

  static const String _keyLastSong = 'soundvibe_last_played_song_v1';
  static const String _keyLastPos = 'soundvibe_last_played_pos_ms_v1';
  static const String _keyLastQueue = 'soundvibe_last_played_queue_v1';

  Future<void> savePlaybackSessionManually({
    required SongModel song,
    required Duration position,
    required List<SongModel> queue,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSong, json.encode(song.toJson()));
      await prefs.setInt(_keyLastPos, position.inMilliseconds);
      await prefs.setString(
        _keyLastQueue,
        json.encode(queue.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> saveCurrentPlaybackSession() async {
    if (_currentSong == null) return;
    await savePlaybackSessionManually(
      song: _currentSong!,
      position: _position,
      queue: _queue,
    );
  }

  Future<bool> restorePlaybackSession({bool autoPreparePlayer = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songJson = prefs.getString(_keyLastSong);
      if (songJson == null || songJson.isEmpty) return false;

      final songMap = json.decode(songJson) as Map<String, dynamic>;
      final restoredSong = SongModel.fromJson(songMap);

      final posMs = prefs.getInt(_keyLastPos) ?? 0;
      final restoredPosition = Duration(milliseconds: posMs);

      final queueJson = prefs.getString(_keyLastQueue);
      List<SongModel> restoredQueue = [restoredSong];
      if (queueJson != null && queueJson.isNotEmpty) {
        final List<dynamic> list = json.decode(queueJson);
        final parsed = list.map((item) => SongModel.fromJson(item as Map<String, dynamic>)).toList();
        if (parsed.isNotEmpty) {
          restoredQueue = parsed;
        }
      }

      _currentSong = restoredSong;
      _position = restoredPosition;
      _queue = restoredQueue;
      _currentIndex = _queue.indexWhere((s) => s.id == restoredSong.id);
      if (_currentIndex == -1) _currentIndex = 0;
      _currentLanguageLock = restoredSong.language.toLowerCase().trim();

      if (autoPreparePlayer) {
        final audioSources = <AudioSource>[];
        for (final s in _queue) {
          final tag = _createMediaItem(s);
          if (s.isOffline && s.localFilePath != null && File(s.localFilePath!).existsSync()) {
            audioSources.add(AudioSource.file(s.localFilePath!, tag: tag));
          } else if (s.streamUrl.isNotEmpty) {
            audioSources.add(AudioSource.uri(Uri.parse(s.streamUrl), tag: tag));
          } else {
            audioSources.add(AudioSource.uri(Uri.parse('https://audio.kuchbhi.app/placeholder.mp3'), tag: tag));
          }
        }

        if (audioSources.isNotEmpty) {
          await _player.setAudioSources(
            audioSources,
            initialIndex: _currentIndex,
            initialPosition: _position,
          );
        }
      }

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> prefillInitialQueue(List<SongModel> songs) async {
    if (_currentSong != null || songs.isEmpty) return;
    _queue = List.from(songs);
    _currentIndex = 0;
    _currentSong = songs.first;
    _position = Duration.zero;

    final audioSources = <AudioSource>[];
    for (final s in _queue) {
      final tag = _createMediaItem(s);
      if (s.streamUrl.isNotEmpty) {
        audioSources.add(AudioSource.uri(Uri.parse(s.streamUrl), tag: tag));
      }
    }

    if (audioSources.isNotEmpty) {
      try {
        await _player.setAudioSources(
          audioSources,
          initialIndex: 0,
          initialPosition: Duration.zero,
        );
      } catch (_) {}
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
