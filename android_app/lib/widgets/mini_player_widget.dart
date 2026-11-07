import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class MiniPlayerWidget extends StatelessWidget {
  final AudioPlayerService playerService;
  final VoidCallback onTap;

  const MiniPlayerWidget({
    super.key,
    required this.playerService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final song = playerService.currentSong;
    if (song == null) return const SizedBox.shrink();

    final pos = playerService.position.inMilliseconds.toDouble();
    final dur = playerService.duration.inMilliseconds.toDouble();
    final progress = (dur > 0 && pos <= dur) ? (pos / dur) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF242424),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Row(
                  children: [
                    // Spotify Square Thumbnail (Swipe left/right for Next/Previous)
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity! < -180) {
                            HapticFeedback.mediumImpact();
                            playerService.playNext();
                          } else if (details.primaryVelocity! > 180) {
                            HapticFeedback.mediumImpact();
                            playerService.playPrevious();
                          }
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: song.artworkUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: song.artworkUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: AppTheme.surfaceLight),
                                  errorWidget: (context, url, error) => Container(color: AppTheme.surfaceLight),
                                )
                              : Container(color: AppTheme.surfaceLight),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title & Artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (song.isOffline)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.download_done_rounded, color: AppTheme.spotifyGreen, size: 12),
                                ),
                              Flexible(
                                child: Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Device connection indicator
                    IconButton(
                      icon: const Icon(
                        Icons.devices_rounded,
                        color: AppTheme.spotifyGreen,
                        size: 19,
                      ),
                      onPressed: onTap,
                      tooltip: 'Connected Device',
                    ),

                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => playerService.togglePlayPause(),
                    ),
                  ],
                ),
              ),

              // Spotify Green Thin Scrubber Line
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.2,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.spotifyGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
