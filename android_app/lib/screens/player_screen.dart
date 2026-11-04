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
import '../theme/app_theme.dart';
import '../widgets/animated_favorite_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final song = playerService.currentSong;
    if (song == null) {
      return const Scaffold(body: Center(child: Text('No song playing')));
    }

    final isDownloaded = downloadService.isDownloaded(song.id);
    final isDownloading = downloadService.downloadProgress.containsKey(song.id);
    final progress = downloadService.downloadProgress[song.id] ?? 0.0;

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
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded, size: 26, color: Colors.white),
                        onPressed: () => _showAddToFolder(context, song),
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
                            onToggle: () => playlistService.toggleFavorite(song),
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
