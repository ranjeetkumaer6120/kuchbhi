import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/local_audio_service.dart';
import '../services/playlist_service.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile_widget.dart';

class LibraryScreen extends StatefulWidget {
  final AudioPlayerService playerService;
  final DownloadService downloadService;
  final PlaylistService playlistService;
  final LocalAudioService localAudioService;

  LibraryScreen({
    super.key,
    required this.playerService,
    required this.downloadService,
    required this.playlistService,
    LocalAudioService? localAudioService,
  }) : localAudioService = localAudioService ?? LocalAudioService();

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOfflineOnlyMode = false;
  String _deviceSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    widget.localAudioService.scanDeviceStorage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Create New Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Folder name (e.g. Gym, Driving, Chill)',
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
              if (controller.text.trim().isNotEmpty) {
                await widget.playlistService.createFolder(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _openFolderView(String folderName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: widget.playlistService,
          builder: (ctx, _) {
            final songs = widget.playlistService.getFolderSongs(folderName);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.folder_rounded, color: AppTheme.cyberCyan, size: 28),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folderName,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Text(
                                    '${songs.length} songs',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (songs.isNotEmpty)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.appleRed,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                  label: const Text('Play All'),
                                  onPressed: () {
                                    widget.playerService.playSong(songs.first, playlist: songs);
                                    Navigator.pop(ctx);
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () async {
                                  await widget.playlistService.deleteFolder(folderName);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppTheme.border),

                    // Songs List
                    Expanded(
                      child: songs.isEmpty
                          ? const Center(
                              child: Text(
                                'Folder is empty.\nAdd songs from Search or Home!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: songs.length,
                              itemBuilder: (ctx, idx) {
                                final s = songs[idx];
                                return Dismissible(
                                  key: Key('folder_${folderName}_${s.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.redAccent,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                                  ),
                                  onDismissed: (_) {
                                    widget.playlistService.removeSongFromFolder(folderName, s.id);
                                  },
                                  child: SongTileWidget(
                                    song: s,
                                    isPlaying: widget.playerService.currentSong?.id == s.id && widget.playerService.isPlaying,
                                    downloadService: widget.downloadService,
                                    playlistService: widget.playlistService,
                                    onTap: () {
                                      widget.playerService.playSong(s, playlist: songs);
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.downloadService,
        widget.playlistService,
        widget.localAudioService,
      ]),
      builder: (context, _) {
        final offlineSongs = widget.downloadService.offlineSongs;
        var favSongs = widget.playlistService.favorites;
        if (_isOfflineOnlyMode) {
          favSongs = favSongs.where((s) => widget.downloadService.isDownloaded(s.id)).toList();
        }
        final folders = widget.playlistService.folderNames;
        final deviceSongs = widget.localAudioService.songs;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Library'),
            actions: [
              // Offline Only Mode Switch
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isOfflineOnlyMode ? Icons.cloud_off_rounded : Icons.cloud_queue_rounded,
                    size: 18,
                    color: _isOfflineOnlyMode ? AppTheme.emeraldGreen : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: _isOfflineOnlyMode,
                    activeThumbColor: AppTheme.emeraldGreen,
                    onChanged: (val) {
                      setState(() => _isOfflineOnlyMode = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val
                              ? 'Offline Only Mode Enabled (Zero data usage)'
                              : 'Online Mode Enabled (All tracks available)'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: val ? AppTheme.emeraldGreen : AppTheme.surfaceLight,
                        ),
                      );
                    },
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder_rounded, color: AppTheme.appleRed),
                tooltip: 'Create New Folder',
                onPressed: _showCreateFolderDialog,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.appleRed,
              labelColor: AppTheme.appleRed,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.cloud_done_rounded, size: 18),
                  text: 'Offline (${offlineSongs.length})',
                ),
                Tab(
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  text: 'Favorites (${favSongs.length})',
                ),
                Tab(
                  icon: const Icon(Icons.folder_rounded, size: 18),
                  text: 'Folders (${folders.length})',
                ),
                Tab(
                  icon: const Icon(Icons.phone_android_rounded, size: 18),
                  text: 'Device (${deviceSongs.length})',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              if (_isOfflineOnlyMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.offline_pin_rounded, color: AppTheme.emeraldGreen, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Offline Mode Active • Playing strictly saved storage files',
                        style: TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Offline Downloaded Songs
                    _buildOfflineTab(offlineSongs),

                    // Tab 2: Favorites
                    _buildFavoritesTab(favSongs),

                    // Tab 3: Custom Folders / Playlists
                    _buildFoldersTab(folders),

                    // Tab 4: Local Device Audio Files
                    _buildDeviceMusicTab(deviceSongs),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineTab(List<SongModel> offlineSongs) {
    if (offlineSongs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.download_for_offline_rounded, size: 68, color: AppTheme.surfaceLight),
              SizedBox(height: 16),
              Text(
                'No Offline Songs Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Search any song and tap download to listen anywhere with 0% internet!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        // Offline Banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 24),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${offlineSongs.length} Songs Downloaded',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      const Text('Zero-internet offline ready', style: TextStyle(fontSize: 12, color: AppTheme.emeraldGreen)),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.appleRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  if (offlineSongs.isNotEmpty) {
                    widget.playerService.playSong(offlineSongs.first, playlist: offlineSongs);
                  }
                },
              ),
            ],
          ),
        ),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offlineSongs.length,
          itemBuilder: (context, index) {
            final song = offlineSongs[index];
            final isCurrent = widget.playerService.currentSong?.id == song.id;

            return Dismissible(
              key: Key(song.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              onDismissed: (_) {
                widget.downloadService.deleteSong(song.id);
              },
              child: SongTileWidget(
                song: song,
                isPlaying: isCurrent && widget.playerService.isPlaying,
                downloadService: widget.downloadService,
                playlistService: widget.playlistService,
                onTap: () => widget.playerService.playSong(song, playlist: offlineSongs),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFavoritesTab(List<SongModel> favSongs) {
    if (favSongs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.favorite_rounded, size: 68, color: AppTheme.surfaceLight),
              SizedBox(height: 16),
              Text(
                'No Favorite Songs Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the heart icon on any song to add it to your Favorites!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${favSongs.length} Liked Songs',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.appleRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Play All'),
                onPressed: () {
                  widget.playerService.playSong(favSongs.first, playlist: favSongs);
                },
              ),
            ],
          ),
        ),

        // Auto-Download Favorites Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppTheme.cyberCyan, size: 22),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Download Favorites',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      Text(
                        'Save loved tracks offline automatically',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: widget.playlistService.autoDownloadFavorites,
                activeThumbColor: AppTheme.cyberCyan,
                onChanged: (val) {
                  widget.playlistService.setAutoDownloadFavorites(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val
                          ? 'Auto-download enabled: Future favorites will be cached offline'
                          : 'Auto-download disabled'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: val ? AppTheme.cyberCyan : AppTheme.surfaceLight,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: favSongs.length,
          itemBuilder: (context, index) {
            final song = favSongs[index];
            final isCurrent = widget.playerService.currentSong?.id == song.id;

            return SongTileWidget(
              song: song,
              isPlaying: isCurrent && widget.playerService.isPlaying,
              downloadService: widget.downloadService,
              playlistService: widget.playlistService,
              onTap: () => widget.playerService.playSong(song, playlist: favSongs),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFoldersTab(List<String> folders) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 120, top: 12),
      children: [
        // Create Folder Card Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            onTap: _showCreateFolderDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: Row(
                children: const [
                  CircleAvatar(
                    backgroundColor: AppTheme.appleRed,
                    child: Icon(Icons.add_rounded, color: Colors.white),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create New Folder / Playlist',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                      Text('Group your songs into custom playlists',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        if (folders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text('No folders created yet.', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          )
        else
          ...folders.map((folderName) {
            final count = widget.playlistService.getFolderSongs(folderName).length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: InkWell(
                onTap: () => _openFolderView(folderName),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.cyberCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.folder_rounded, color: AppTheme.cyberCyan, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(folderName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('$count tracks', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            );
          }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'Developed by Ranjeet Kumar',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceMusicTab(List<SongModel> deviceSongs) {
    final filtered = _deviceSearchQuery.isEmpty
        ? deviceSongs
        : widget.localAudioService.search(_deviceSearchQuery);

    return ListView(
      padding: const EdgeInsets.only(bottom: 120, top: 12),
      children: [
        // Device Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            onChanged: (val) => setState(() => _deviceSearchQuery = val),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search device songs & audio files...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
              suffixIcon: _deviceSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                      onPressed: () => setState(() => _deviceSearchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Device Storage Scanner Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_android_rounded, color: AppTheme.cyberCyan, size: 24),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${deviceSongs.length} Local Tracks Found',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      Text(
                        widget.localAudioService.isScanning ? 'Scanning internal storage...' : 'Storage / SD Card Ready',
                        style: const TextStyle(fontSize: 12, color: AppTheme.cyberCyan),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: widget.localAudioService.isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyberCyan),
                          )
                        : const Icon(Icons.refresh_rounded, color: AppTheme.cyberCyan),
                    tooltip: 'Rescan Storage',
                    onPressed: widget.localAudioService.isScanning
                        ? null
                        : () => widget.localAudioService.scanDeviceStorage(),
                  ),
                  if (filtered.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.appleRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        widget.playerService.playSong(filtered.first, playlist: filtered);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.audio_file_rounded, size: 68, color: AppTheme.surfaceLight),
                  const SizedBox(height: 16),
                  Text(
                    _deviceSearchQuery.isEmpty ? 'No Local Audio Files Found' : 'No Results for "$_deviceSearchQuery"',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Place .mp3, .m4a, or .flac files in your Music or Download folders, then tap Rescan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Scan Device Storage'),
                    onPressed: () => widget.localAudioService.scanDeviceStorage(),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final song = filtered[index];
              final isCurrent = widget.playerService.currentSong?.id == song.id;

              return SongTileWidget(
                song: song,
                isPlaying: isCurrent && widget.playerService.isPlaying,
                downloadService: widget.downloadService,
                playlistService: widget.playlistService,
                onTap: () => widget.playerService.playSong(song, playlist: filtered),
              );
            },
          ),
      ],
    );
  }
}
