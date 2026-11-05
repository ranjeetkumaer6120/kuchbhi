import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/lyrics_model.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/sleep_timer_service.dart';
import '../theme/album_palette.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_favorite_button.dart';
import '../widgets/audio_visualizer_widget.dart';
import '../widgets/story_card_dialog.dart';

class PlayerScreen extends StatelessWidget {
  final AudioPlayerService playerService;
  final DownloadService downloadService;
  final PlaylistService playlistService;
  final ApiService? apiService;

  const PlayerScreen({
    super.key,
    required this.playerService,
    required this.downloadService,
    required this.playlistService,
    this.apiService,
  });

  void _copySongDetails(BuildContext context, SongModel song) {
    final shareLink = song.streamUrl.isNotEmpty ? song.streamUrl : 'kuchbhi app';
    final copyText = '🎵 ${song.title} - ${song.artist}\nAlbum: ${song.album}\nQuality: ${song.qualityBadge}\nLink: $shareLink';
    Clipboard.setData(ClipboardData(text: copyText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceLight,
        content: Text('Copied "${song.title}" link & info to clipboard!',
            style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLyricsModal(BuildContext context, SongModel song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return LiveLyricsSheet(
          song: song,
          playerService: playerService,
          apiService: apiService ?? ApiService(),
        );
      },
    );
  }

  void _showStoryCardModal(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (ctx) => StoryCardDialog(song: song),
    );
  }

  void _showAddToFolder(BuildContext context, SongModel song) {
    final folders = playlistService.folderNames;
    final folderController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add to Folder / Playlist',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_rounded, color: AppTheme.appleRed),
                    onPressed: () {
                      showDialog(
                        context: ctx,
                        builder: (diagCtx) => AlertDialog(
                          backgroundColor: AppTheme.surfaceLight,
                          title: const Text('New Folder', style: TextStyle(color: Colors.white)),
                          content: TextField(
                            controller: folderController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Folder name...',
                              hintStyle: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                              onPressed: () => Navigator.pop(diagCtx),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.appleRed),
                              child: const Text('Create', style: TextStyle(color: Colors.white)),
                              onPressed: () async {
                                if (folderController.text.trim().isNotEmpty) {
                                  await playlistService.createFolder(folderController.text.trim());
                                  await playlistService.addSongToFolder(folderController.text.trim(), song);
                                  if (diagCtx.mounted) Navigator.pop(diagCtx);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (folders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No folders yet. Create one with the "+" icon above.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                )
              else
                ...folders.map(
                  (fName) => ListTile(
                    leading: const Icon(Icons.folder_rounded, color: AppTheme.cyberCyan),
                    title: Text(fName, style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      await playlistService.addSongToFolder(fName, song);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to "$fName"')),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoFiButton(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final isLoFi = playerService.isLoFiMode;
        final speed = playerService.playbackSpeed;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            playerService.toggleLoFiMode();
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showSpeedSelectorModal(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isLoFi
                  ? AppTheme.cyberCyan.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLoFi ? AppTheme.cyberCyan : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: isLoFi ? AppTheme.cyberCyan : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  isLoFi ? 'Lo-Fi 0.85x' : (speed != 1.0 ? '${speed}x' : 'Lo-Fi'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isLoFi ? FontWeight.bold : FontWeight.w600,
                    color: isLoFi ? AppTheme.cyberCyan : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpeedSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final speeds = [0.75, 0.85, 1.0, 1.25, 1.5];
        final labels = ['0.75x Slow', '0.85x Lo-Fi Slowed', '1.0x Normal', '1.25x Fast', '1.5x Speed Up'];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Playback Speed & Lo-Fi Pitch',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                ...List.generate(speeds.length, (i) {
                  final s = speeds[i];
                  final isSelected = (playerService.playbackSpeed == s);
                  return ListTile(
                    leading: Icon(
                      s == 0.85 ? Icons.auto_awesome_rounded : Icons.speed_rounded,
                      color: isSelected ? AppTheme.appleRed : Colors.white70,
                    ),
                    title: Text(labels[i], style: TextStyle(color: isSelected ? AppTheme.appleRed : Colors.white)),
                    trailing: isSelected ? const Icon(Icons.check, color: AppTheme.appleRed) : null,
                    onTap: () {
                      playerService.setSpeed(s);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleepTimerButton(BuildContext context) {
    return ListenableBuilder(
      listenable: SleepTimerService.instance,
      builder: (context, _) {
        final timer = SleepTimerService.instance;
        final isActive = timer.isActive;
        return IconButton(
          icon: Icon(
            isActive ? Icons.bedtime_rounded : Icons.bedtime_outlined,
            size: 24,
            color: isActive ? AppTheme.cyberCyan : Colors.white70,
          ),
          tooltip: 'Sleep Timer (${timer.formattedRemainingTime})',
          onPressed: () => _showSleepTimerModal(context),
        );
      },
    );
  }

  void _showSleepTimerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: SleepTimerService.instance,
          builder: (ctx, _) {
            final timer = SleepTimerService.instance;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bedtime_rounded, color: AppTheme.cyberCyan, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Sleep Timer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (timer.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.cyberCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              timer.formattedRemainingTime,
                              style: const TextStyle(
                                color: AppTheme.cyberCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Audio will gently fade out over the last 10 seconds before pausing.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 14),
                    _buildTimerOption(context, ctx, '15 Minutes', const Duration(minutes: 15)),
                    _buildTimerOption(context, ctx, '30 Minutes', const Duration(minutes: 30)),
                    _buildTimerOption(context, ctx, '45 Minutes', const Duration(minutes: 45)),
                    _buildTimerOption(context, ctx, '1 Hour', const Duration(minutes: 60)),
                    ListTile(
                      leading: const Icon(Icons.music_note_rounded, color: AppTheme.appleRed),
                      title: const Text('End of Current Track', style: TextStyle(color: Colors.white)),
                      trailing: timer.isEndOfSongMode
                          ? const Icon(Icons.check_circle_rounded, color: AppTheme.cyberCyan)
                          : null,
                      onTap: () {
                        timer.enableEndOfSongMode(
                          onTimerComplete: () async => playerService.pause(),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sleep timer set: Audio will pause at end of track'),
                            backgroundColor: AppTheme.surfaceLight,
                          ),
                        );
                      },
                    ),
                    if (timer.isActive) ...[
                      const Divider(color: AppTheme.border),
                      ListTile(
                        leading: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
                        title: const Text('Turn Off Timer', style: TextStyle(color: Colors.redAccent)),
                        onTap: () {
                          timer.cancelTimer();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sleep timer turned off'),
                              backgroundColor: AppTheme.surfaceLight,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimerOption(BuildContext screenContext, BuildContext sheetContext, String label, Duration duration) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined, color: Colors.white70),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        SleepTimerService.instance.startTimer(
          duration: duration,
          onTimerComplete: () async => playerService.pause(),
          onVolumeRamp: (vol) async => playerService.player.setVolume(vol),
        );
        Navigator.pop(sheetContext);
        ScaffoldMessenger.of(screenContext).showSnackBar(
          SnackBar(
            content: Text('Sleep timer set for $label with smooth volume fade'),
            backgroundColor: AppTheme.appleRed,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = playerService.currentSong;
    if (song == null) {
      return const Scaffold(body: Center(child: Text('No song playing')));
    }

    final isDownloaded = downloadService.isDownloaded(song.id);
    final isDownloading = downloadService.downloadProgress.containsKey(song.id);
    final progress = downloadService.downloadProgress[song.id] ?? 0.0;
    final palette = AlbumPalette.fromSong(title: song.title, artist: song.artist);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Dynamic Blurred Artwork Background
          Positioned.fill(
            child: song.artworkUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.artworkUrl,
                    fit: BoxFit.cover,
                  )
                : Container(color: AppTheme.background),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),

          // Dynamic Album Ambient Glow Mesh Blobs (Apple Music 2024 Aesthetic)
          Positioned(
            top: 40,
            left: -40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.primary.withValues(alpha: 0.45),
                    palette.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.secondary.withValues(alpha: 0.40),
                    palette.secondary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Player Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSleepTimerButton(context),
                          IconButton(
                            icon: const Icon(Icons.ios_share_rounded, size: 22, color: Colors.white70),
                            tooltip: 'Share Story Card',
                            onPressed: () => _showStoryCardModal(context, song),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz_rounded, size: 26, color: Colors.white),
                            onPressed: () => _showAddToFolder(context, song),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Big Rounded Artwork (Apple Music scale) with Left/Right Swipe for Next/Previous
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! < -180) {
                          // Swiped Left -> Next Song
                          HapticFeedback.mediumImpact();
                          playerService.playNext();
                        } else if (details.primaryVelocity! > 180) {
                          // Swiped Right -> Previous Song
                          HapticFeedback.mediumImpact();
                          playerService.playPrevious();
                        }
                      }
                    },
                    child: AnimatedScale(
                      scale: playerService.isPlaying ? 1.0 : 0.92,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: 290,
                        height: 290,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 36,
                              spreadRadius: 4,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: song.artworkUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: song.artworkUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: AppTheme.surfaceLight),
                                  errorWidget: (context, url, error) => Container(color: AppTheme.surfaceLight),
                                )
                              : Container(
                                  color: AppTheme.surfaceLight,
                                  child: const Icon(Icons.music_note, size: 80, color: AppTheme.textSecondary),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Live Harmonic Audio Soundwave Visualizer
                  AudioVisualizerWidget(
                    isPlaying: playerService.isPlaying,
                    primaryColor: palette.primary,
                    secondaryColor: palette.secondary,
                  ),
                  const SizedBox(height: 12),

                  // Title & Artist & Favorite Heart
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Smooth Animated Favorite Button
                      ListenableBuilder(
                        listenable: playlistService,
                        builder: (context, _) {
                          final isFavorite = playlistService.isFavorite(song.id);
                          return AnimatedFavoriteButton(
                            isFavorite: isFavorite,
                            size: 28,
                            inactiveColor: Colors.white70,
                            onToggle: () => playlistService.toggleFavorite(song, downloadService: downloadService),
                          );
                        },
                      ),
                      // Copy Info & Link
                      IconButton(
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => _copySongDetails(context, song),
                      ),
                      const SizedBox(width: 4),
                      // Quality Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: song.isOffline
                              ? AppTheme.cyberCyan.withValues(alpha: 0.2)
                              : AppTheme.emeraldGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: song.isOffline ? AppTheme.cyberCyan : AppTheme.emeraldGreen,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          song.isOffline ? 'OFFLINE' : song.qualityBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: song.isOffline ? AppTheme.cyberCyan : AppTheme.emeraldGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress Scrubber
                  ProgressBar(
                    progress: playerService.position,
                    total: playerService.duration,
                    onSeek: (pos) => playerService.seek(pos),
                    baseBarColor: Colors.white.withValues(alpha: 0.18),
                    progressBarColor: Colors.white,
                    bufferedBarColor: Colors.white.withValues(alpha: 0.3),
                    thumbColor: Colors.white,
                    thumbRadius: 6,
                    thumbGlowRadius: 16,
                    timeLabelTextStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Transport Controls (Previous, Play/Pause, Next, Shuffle, Loop)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: playerService.isShuffle ? AppTheme.appleRed : Colors.white.withValues(alpha: 0.6),
                          size: 24,
                        ),
                        onPressed: () => playerService.toggleShuffle(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                        onPressed: () => playerService.playPrevious(),
                      ),
                      // Big Play/Pause Button
                      GestureDetector(
                        onTap: () => playerService.togglePlayPause(),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 40,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                        onPressed: () => playerService.playNext(),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.repeat_rounded,
                          color: playerService.isLoop ? AppTheme.appleRed : Colors.white.withValues(alpha: 0.6),
                          size: 24,
                        ),
                        onPressed: () => playerService.toggleLoop(),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Bottom Action Bar: Lyrics & Download MP3 Button & Offline Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Lyrics Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        icon: const Icon(Icons.lyrics_rounded, size: 18, color: AppTheme.applePink),
                        label: const Text('Lyrics', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () => _showLyricsModal(context, song),
                      ),

                      // Lo-Fi Slowed & Speed Mode Button
                      _buildLoFiButton(context),

                      if (isDownloading)
                        Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                value: progress > 0 ? progress : null,
                                strokeWidth: 2,
                                color: AppTheme.appleRed,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        )
                      else if (isDownloaded)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Downloaded',
                                style: TextStyle(fontSize: 12.5, color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloading: ${song.title}...'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            await downloadService.downloadSong(song);
                          },
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: Center(
                      child: Text(
                        'kuchbhi • Developed by Ranjeet Kumar',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Apple Music style Real-Time Live Synchronized Lyrics Sheet
class LiveLyricsSheet extends StatefulWidget {
  final SongModel song;
  final AudioPlayerService playerService;
  final ApiService apiService;

  const LiveLyricsSheet({
    super.key,
    required this.song,
    required this.playerService,
    required this.apiService,
  });

  @override
  State<LiveLyricsSheet> createState() => _LiveLyricsSheetState();
}

class _LiveLyricsSheetState extends State<LiveLyricsSheet> {
  late Future<LyricsData?> _lyricsFuture;
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _lyricsFuture = widget.apiService.getLyrics(widget.song);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || index < 0) return;
    const double approxLineHeight = 58.0;
    final double targetOffset = (index * approxLineHeight) - 150.0;
    final double clamped = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Grab Handle
            Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.appleRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lyrics_rounded, color: AppTheme.applePink, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        Text(
                          widget.song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            // Lyrics Body
            Expanded(
              child: FutureBuilder<LyricsData?>(
                future: _lyricsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.appleRed),
                    );
                  }

                  final lyricsData = snapshot.data;
                  if (lyricsData == null || lyricsData.lines.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.music_off_rounded, size: 48, color: AppTheme.textSecondary),
                            SizedBox(height: 14),
                            Text(
                              'Lyrics not available for this track',
                              style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Check back later or try another track',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // If Plain lyrics (without exact timestamps)
                  if (!lyricsData.isSynced) {
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      itemCount: lyricsData.lines.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            lyricsData.lines[index].text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.7,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Real-Time Synchronized Lyrics with Active Line Highlighting!
                  return StreamBuilder<Duration>(
                    stream: widget.playerService.player.positionStream,
                    builder: (context, posSnapshot) {
                      final currentPos = posSnapshot.data ?? widget.playerService.position;

                      // Calculate current active line
                      int activeIndex = -1;
                      for (int i = 0; i < lyricsData.lines.length; i++) {
                        if (currentPos >= lyricsData.lines[i].timestamp) {
                          activeIndex = i;
                        } else {
                          break;
                        }
                      }

                      // Auto-scroll when active line changes
                      if (activeIndex != _lastActiveIndex && activeIndex >= 0) {
                        _lastActiveIndex = activeIndex;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToIndex(activeIndex);
                        });
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
                        itemCount: lyricsData.lines.length,
                        itemBuilder: (context, index) {
                          final line = lyricsData.lines[index];
                          final isActive = index == activeIndex;
                          final isPast = index < activeIndex;

                          return GestureDetector(
                            onTap: () {
                              widget.playerService.seek(line.timestamp);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: EdgeInsets.symmetric(
                                horizontal: isActive ? 16 : 10,
                                vertical: isActive ? 12 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.appleRed.withValues(alpha: 0.16)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: isActive
                                    ? Border.all(
                                        color: AppTheme.appleRed.withValues(alpha: 0.4),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (isActive) ...[
                                    const Icon(
                                      Icons.graphic_eq_rounded,
                                      color: AppTheme.applePink,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: Text(
                                      line.text,
                                      style: TextStyle(
                                        fontSize: isActive ? 22 : 17,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                        color: isActive
                                            ? Colors.white
                                            : (isPast
                                                ? Colors.white.withValues(alpha: 0.45)
                                                : Colors.white.withValues(alpha: 0.22)),
                                        height: 1.4,
                                        letterSpacing: isActive ? 0.2 : 0.0,
                                        shadows: isActive
                                            ? [
                                                Shadow(
                                                  color: AppTheme.appleRed.withValues(alpha: 0.8),
                                                  blurRadius: 18,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
