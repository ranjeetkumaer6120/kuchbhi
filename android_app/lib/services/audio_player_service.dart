import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song_model.dart';
import 'api_service.dart';

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

  SongModel? get currentSong => _currentSong;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  bool get isLoop => _loopMode != LoopMode.off;

  AudioPlayer get player => _player;

  AudioPlayerService() {
    _initStreams();
  }

  void _initStreams() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        if (_loopMode == LoopMode.all) {
          _player.seek(Duration.zero, index: 0);
        }
      }
      notifyListeners();
    });

    _player.currentIndexStream.listen((index) async {
      if (index != null && index >= 0 && index < _queue.length) {
        _currentIndex = index;
        _currentSong = _queue[index];

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
      notifyListeners();
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
      if (playlist != null && playlist.isNotEmpty) {
        _queue = List.from(playlist);
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

      _currentSong = song;
      _isBuffering = true;
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
            isOffline: song.isOffline,
            localFilePath: song.localFilePath,
          );
          _queue[_currentIndex] = song;
          _currentSong = song;
        }
      } else if (song.source == 'itunes' || song.streamUrl.contains('itunes.apple.com')) {
        final fullSaavn = await _apiService.searchSongs('${song.title} ${song.artist}');
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
    } catch (e) {
      _isBuffering = false;
      notifyListeners();
    }
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
    }
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
