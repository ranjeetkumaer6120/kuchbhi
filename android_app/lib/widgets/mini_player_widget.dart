import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        blur: 24,
        opacity: 0.85,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Thumbnail (Swipe left/right for Next/Previous)
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
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 44,
                      height: 44,
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
                const SizedBox(width: 12),

                // Title & Subtitle
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls
                IconButton(
                  icon: Icon(
                    playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppTheme.textPrimary,
                    size: 28,
                  ),
                  onPressed: () => playerService.togglePlayPause(),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.fast_forward_rounded,
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                  onPressed: () => playerService.playNext(),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Progress Bar Line
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.appleRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
