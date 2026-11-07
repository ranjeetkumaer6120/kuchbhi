import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/song_model.dart';
import '../theme/album_palette.dart';
import '../theme/app_theme.dart';

class StoryCardDialog extends StatefulWidget {
  final SongModel song;

  const StoryCardDialog({super.key, required this.song});

  @override
  State<StoryCardDialog> createState() => _StoryCardDialogState();
}

class _StoryCardDialogState extends State<StoryCardDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _captureAndShare() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _fallbackShare();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _fallbackShare();
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/kuchbhi_story_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Listening to "${widget.song.title}" by ${widget.song.artist} on Kuchbhi App (320kbps Master HD)!',
        );
      }
    } catch (_) {
      _fallbackShare();
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _fallbackShare() {
    // ignore: deprecated_member_use
    Share.share(
      'Listening to "${widget.song.title}" by ${widget.song.artist} on Kuchbhi App (320kbps Master HD)!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlbumPalette.fromSong(title: widget.song.title, artist: widget.song.artist);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // RepaintBoundary capturing the aesthetic 9:16 Canvas
          RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              width: 310,
              height: 480,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D12),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Ambient Glow Mesh Blob 1
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            palette.primary.withValues(alpha: 0.5),
                            palette.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Ambient Glow Mesh Blob 2
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            palette.secondary.withValues(alpha: 0.45),
                            palette.secondary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Foreground Story Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Header Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.music_note_rounded, size: 14, color: AppTheme.appleRed),
                                  const SizedBox(width: 4),
                                  Text(
                                    'NOW PLAYING',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Album Artwork
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: widget.song.artworkUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.song.artworkUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: AppTheme.surfaceLight),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppTheme.surfaceLight,
                                      child: const Icon(Icons.music_note, size: 64, color: Colors.white54),
                                    ),
                                  )
                                : Container(
                                    color: AppTheme.surfaceLight,
                                    child: const Icon(Icons.music_note, size: 64, color: Colors.white54),
                                  ),
                          ),
                        ),

                        // Title & Artist
                        Column(
                          children: [
                            Text(
                              widget.song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        // Bottom Branding Footer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.cyberCyan),
                                SizedBox(width: 6),
                                Text(
                                  'Listening on Kuchbhi App • 320kbps',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons: Share & Cancel
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 26),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.appleRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 20),
                label: Text(
                  _isSharing ? 'Generating...' : 'Share to Story',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isSharing ? null : _captureAndShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
