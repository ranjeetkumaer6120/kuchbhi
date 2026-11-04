import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/player_screen.dart';
import 'screens/search_screen.dart';
import 'services/api_service.dart';
import 'services/audio_player_service.dart';
import 'services/download_service.dart';
import 'services/playlist_service.dart';
import 'theme/app_theme.dart';
import 'widgets/mini_player_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Android status bar media notification for background playback
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.antigravity.soundvibe.audio',
    androidNotificationChannelName: 'kuchbhi Music Playback',
    androidNotificationChannelDescription: 'Background audio playback for kuchbhi music',
    notificationColor: AppTheme.appleRed,
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: false,
    androidNotificationClickStartsActivity: true,
  );

  // Set system UI style (dark navigation & status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final downloadService = DownloadService();
  await downloadService.init();

  final playlistService = PlaylistService();
  await playlistService.init();

  final audioPlayerService = AudioPlayerService();
  final apiService = ApiService();

  runApp(SoundVibeApp(
    audioPlayerService: audioPlayerService,
    downloadService: downloadService,
    apiService: apiService,
    playlistService: playlistService,
  ));
}

class SoundVibeApp extends StatelessWidget {
  final AudioPlayerService audioPlayerService;
  final DownloadService downloadService;
  final ApiService apiService;
  final PlaylistService playlistService;

  const SoundVibeApp({
    super.key,
    required this.audioPlayerService,
    required this.downloadService,
    required this.apiService,
    required this.playlistService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kuchbhi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainShell(
        playerService: audioPlayerService,
        downloadService: downloadService,
        apiService: apiService,
        playlistService: playlistService,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final AudioPlayerService playerService;
  final DownloadService downloadService;
  final ApiService apiService;
  final PlaylistService playlistService;

  const MainShell({
    super.key,
    required this.playerService,
    required this.downloadService,
    required this.apiService,
    required this.playlistService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTabIndex = 0;

  void _openPlayerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            widget.playerService,
            widget.downloadService,
            widget.playlistService,
          ]),
          builder: (context, _) {
            return PlayerScreen(
              playerService: widget.playerService,
              downloadService: widget.downloadService,
              playlistService: widget.playlistService,
              apiService: widget.apiService,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        playerService: widget.playerService,
        downloadService: widget.downloadService,
        apiService: widget.apiService,
        playlistService: widget.playlistService,
      ),
      SearchScreen(
        playerService: widget.playerService,
        downloadService: widget.downloadService,
        apiService: widget.apiService,
        playlistService: widget.playlistService,
      ),
      LibraryScreen(
        playerService: widget.playerService,
        downloadService: widget.downloadService,
        playlistService: widget.playlistService,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Current Screen
          IndexedStack(
            index: _currentTabIndex,
            children: screens,
          ),

          // Floating Mini Player (Apple Music style)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ListenableBuilder(
              listenable: widget.playerService,
              builder: (context, _) {
                if (widget.playerService.currentSong == null) {
                  return const SizedBox.shrink();
                }
                return MiniPlayerWidget(
                  playerService: widget.playerService,
                  onTap: _openPlayerModal,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.98),
          border: const Border(
            top: BorderSide(color: AppTheme.border, width: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTap: (index) => setState(() => _currentTabIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.play_circle_outline_rounded),
                  activeIcon: Icon(Icons.play_circle_fill_rounded),
                  label: 'Listen Now',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  activeIcon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(Icons.library_music_rounded),
                  label: 'Library',
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 6, top: 0),
              alignment: Alignment.center,
              child: const Text(
                'Developed by Ranjeet Kumar',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
