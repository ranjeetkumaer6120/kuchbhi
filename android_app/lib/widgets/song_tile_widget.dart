import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song_model.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../theme/app_theme.dart';
import 'animated_favorite_button.dart';

class SongTileWidget extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;
  final DownloadService downloadService;
  final PlaylistService? playlistService;
  final String? subtitleExtra;

  const SongTileWidget({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.downloadService,
    this.playlistService,
    this.subtitleExtra,
  });

  void _showAddToFolderDialog(BuildContext context) {
    if (playlistService == null) return;

    final folders = playlistService!.folderNames;
    final folderController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.surfaceLight,
                              title: const Text('Create New Folder', style: TextStyle(color: Colors.white)),
                              content: TextField(
                                controller: folderController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Folder name (e.g. Gym, Chill)',
                                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.appleRed),
                                  child: const Text('Create', style: TextStyle(color: Colors.white)),
                                  onPressed: () async {
                                    if (folderController.text.trim().isNotEmpty) {
                                      await playlistService!.createFolder(folderController.text.trim());
                                      await playlistService!.addSongToFolder(folderController.text.trim(), song);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (context.mounted) Navigator.pop(context);
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No folders created yet.\nTap "+" icon above to create one!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: folders.length,
                        itemBuilder: (context, idx) {
                          final fName = folders[idx];
                          final count = playlistService!.getFolderSongs(fName).length;

                          return ListTile(
                            leading: const Icon(Icons.folder_rounded, color: AppTheme.cyberCyan),
                            title: Text(fName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            subtitle: Text('$count songs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            trailing: const Icon(Icons.add_rounded, color: Colors.white70),
                            onTap: () async {
                              await playlistService!.addSongToFolder(fName, song);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Added to "$fName"!')),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloaded = downloadService.isDownloaded(song.id);
    final downloading = downloadService.downloadProgress.containsKey(song.id);
    final progress = downloadService.downloadProgress[song.id] ?? 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: song.artworkUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.artworkUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.surfaceLight,
                          child: const Icon(Icons.music_note, color: AppTheme.textSecondary),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.surfaceLight,
                          child: const Icon(Icons.music_note, color: AppTheme.textSecondary),
                        ),
                      )
                    : Container(
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.music_note, color: AppTheme.textSecondary),
                      ),
              ),
            ),
            const SizedBox(width: 14),

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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isPlaying ? AppTheme.appleRed : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Audio Quality Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: song.isOffline
                              ? AppTheme.cyberCyan.withValues(alpha: 0.15)
                              : (song.source == 'youtube'
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : AppTheme.emeraldGreen.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: song.isOffline
                                ? AppTheme.cyberCyan.withValues(alpha: 0.3)
                                : (song.source == 'youtube'
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : AppTheme.emeraldGreen.withValues(alpha: 0.3)),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          downloading
                              ? '${(progress * 100).toInt()}%'
                              : (song.isOffline ? 'OFFLINE' : song.qualityBadge),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: downloading
                                ? Colors.amber
                                : (song.isOffline
                                    ? AppTheme.cyberCyan
                                    : (song.source == 'youtube' ? Colors.redAccent : AppTheme.emeraldGreen)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (subtitleExtra != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.appleRed.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            subtitleExtra!,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.applePink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Smooth Animated Favorite Button with live reactivity
            if (playlistService != null)
              ListenableBuilder(
                listenable: playlistService!,
                builder: (context, _) {
                  final isFavorite = playlistService!.isFavorite(song.id);
                  return AnimatedFavoriteButton(
                    isFavorite: isFavorite,
                    size: 22,
                    onToggle: () => playlistService!.toggleFavorite(song),
                  );
                },
              ),

            // More Options (Add to Folder / Download)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 20),
              color: AppTheme.surfaceLight,
              onSelected: (val) async {
                if (val == 'folder') {
                  _showAddToFolderDialog(context);
                } else if (val == 'copy') {
                  final shareLink = song.streamUrl.isNotEmpty ? song.streamUrl : 'kuchbhi app';
                  final copyText = '${song.title} - ${song.artist}\nQuality: ${song.qualityBadge}\nLink: $shareLink';
                  Clipboard.setData(ClipboardData(text: copyText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.surfaceLight,
                      content: Text('Copied "${song.title}" info & link to clipboard!',
                          style: const TextStyle(color: Colors.white)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else if (val == 'download') {
                  if (!downloaded && !downloading) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading: ${song.title}...')),
                    );
                    await downloadService.downloadSong(song);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'folder',
                  child: Row(
                    children: [
                      Icon(Icons.create_new_folder_rounded, color: AppTheme.cyberCyan, size: 18),
                      SizedBox(width: 8),
                      Text('Add to Folder', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, color: AppTheme.applePink, size: 18),
                      SizedBox(width: 8),
                      Text('Copy Link / Info', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(
                        downloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                        color: downloaded ? AppTheme.emeraldGreen : AppTheme.appleRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(downloaded ? 'Downloaded' : 'Download MP3',
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
