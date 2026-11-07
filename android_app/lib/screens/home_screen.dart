import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/time_of_day_helper.dart';
import '../services/user_taste_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_filter_bar.dart';
import '../widgets/song_tile_widget.dart';

class HomeScreen extends StatefulWidget {
  final AudioPlayerService playerService;
  final DownloadService downloadService;
  final ApiService apiService;
  final PlaylistService playlistService;

  const HomeScreen({
    super.key,
    required this.playerService,
    required this.downloadService,
    required this.apiService,
    required this.playlistService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'Trending for You',
    'Bollywood Hits',
    'Lo-Fi Chill',
    'Bhojpuri Hits',
    'Pawan Singh',
    'Khesari Lal',
    'Hindi Hits',
    'Punjabi Top',
    'Arijit Singh',
    'Lo-Fi Slowed',
    'English Pop',
  ];

  int _selectedCategoryIndex = 0;
  String _selectedLanguage = 'All';
  List<SongModel> _trendingSongs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategorySongs(_categories[0]);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreSongs();
    }
  }

  Future<void> _loadCategorySongs(String category) async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    List<SongModel> songs;
    if (category.contains('Lo-Fi Chill') && _selectedLanguage == 'All') {
      songs = await widget.apiService.getFreeToUseTracks(limit: 30);
    } else if (category.contains('Trending')) {
      final lang = _selectedLanguage == 'All' ? null : _selectedLanguage;
      final rawSongs = await widget.apiService.getTrendingSongs(language: lang);
      final deduplicated = ApiService.deduplicateByQuality(rawSongs);
      songs = UserTasteService().getPersonalizedTrending(deduplicated, limit: 30);
    } else {
      final query = category.trim();
      final lang = _selectedLanguage == 'All' ? null : _selectedLanguage;
      songs = await widget.apiService.searchSongs(query, page: 1, limit: 25, language: lang);
    }

    if (mounted) {
      setState(() {
        _trendingSongs = ApiService.deduplicateByQuality(songs);
        _isLoading = false;
        if (songs.length < 20 || (category.contains('Lo-Fi Chill') && _selectedLanguage == 'All')) {
          _hasMore = false;
        }
      });
    }
  }

  Future<void> _loadMoreSongs() async {
    if (_isLoadingMore || !_hasMore) return;
    final category = _categories[_selectedCategoryIndex];
    if (category.contains('Lo-Fi Chill') && _selectedLanguage == 'All') {
      return;
    }

    setState(() => _isLoadingMore = true);

    _currentPage++;
    final lang = _selectedLanguage == 'All' ? null : _selectedLanguage;
    List<SongModel> moreSongs;
    if (category.contains('Trending')) {
      final rawMore = await widget.apiService.getTrendingSongs(page: _currentPage, language: lang);
      moreSongs = UserTasteService().getPersonalizedTrending(rawMore, limit: 25);
    } else {
      final query = category.trim();
      moreSongs = await widget.apiService.searchSongs(query, page: _currentPage, limit: 25, language: lang);
    }

    if (mounted) {
      setState(() {
        if (moreSongs.isEmpty) {
          _hasMore = false;
        } else {
          final combined = List<SongModel>.from(_trendingSongs)..addAll(moreSongs);
          final deduplicated = ApiService.deduplicateByQuality(combined);
          if (deduplicated.length == _trendingSongs.length) {
            _hasMore = false;
          } else {
            _trendingSongs = deduplicated;
          }
        }
        _isLoadingMore = false;
      });
    }
  }

  List<SongModel> _getQuickGridItems() {
    final taste = UserTasteService();
    final mostPlayed = taste.getMostPlayedSongs(limit: 6);
    if (mostPlayed.length >= 6) {
      return mostPlayed.take(6).toList();
    }

    final recent = taste.getRecentlyPlayedSongs(limit: 6);
    final combined = <SongModel>[...mostPlayed];
    for (final r in recent) {
      if (!combined.any((s) => s.id == r.id)) combined.add(r);
    }

    for (final t in _trendingSongs) {
      if (combined.length >= 6) break;
      if (!combined.any((s) => s.id == t.id)) combined.add(t);
    }

    return combined.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final quickItems = _getQuickGridItems();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.spotifyGreen,
          backgroundColor: AppTheme.surfaceLight,
          onRefresh: () => _loadCategorySongs(_categories[_selectedCategoryIndex]),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spotify Top Greeting Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TimeOfDayHelper.getGreeting(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                            onPressed: () {
                              final recent = UserTasteService().getRecentlyPlayedSongs();
                              if (recent.isNotEmpty) {
                                widget.playerService.playSong(recent.first, playlist: recent);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                            onPressed: () => _loadCategorySongs(_categories[_selectedCategoryIndex]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Spotify Quick Filter Pills (All / Music / Personalized Vibes)
                ListenableBuilder(
                  listenable: Listenable.merge([UserTasteService(), widget.playlistService]),
                  builder: (context, _) {
                    final tastePills = UserTasteService().getPersonalizedVibePills(
                      favorites: widget.playlistService.favorites,
                    );
                    return SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tastePills.length,
                        itemBuilder: (context, index) {
                          final pill = tastePills[index];
                          final isPersonalized = pill == 'On Repeat' ||
                              pill == 'Heavy Rotation' ||
                              pill == 'Favorites Mix' ||
                              UserTasteService().getTopArtists().contains(pill);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(
                                pill,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: isPersonalized
                                  ? AppTheme.spotifyGreen.withValues(alpha: 0.22)
                                  : AppTheme.surfaceLight,
                              side: BorderSide(
                                color: isPersonalized
                                    ? AppTheme.spotifyGreen.withValues(alpha: 0.5)
                                    : Colors.transparent,
                                width: 0.8,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onPressed: () {
                                if (pill == 'On Repeat') {
                                  final mostPlayed = UserTasteService().getMostPlayedSongs();
                                  if (mostPlayed.isNotEmpty) {
                                    widget.playerService.playSong(mostPlayed.first, playlist: mostPlayed);
                                    return;
                                  }
                                } else if (pill == 'Heavy Rotation') {
                                  final heavy = UserTasteService().getHeavyRotationSongs();
                                  if (heavy.isNotEmpty) {
                                    widget.playerService.playSong(heavy.first, playlist: heavy);
                                    return;
                                  }
                                } else if (pill == 'Favorites Mix') {
                                  final favs = widget.playlistService.favorites;
                                  if (favs.isNotEmpty) {
                                    widget.playerService.playSong(favs.first, playlist: favs);
                                    return;
                                  }
                                }
                                _loadCategorySongs(pill);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Spotify's Signature 6-Tile Quick Access Grid (2 columns x 3 rows)
                if (quickItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: quickItems.length,
                      itemBuilder: (context, index) {
                        final song = quickItems[index];
                        final isPlayingThis = widget.playerService.currentSong?.id == song.id &&
                            widget.playerService.isPlaying;

                        return Material(
                          color: const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(4),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => widget.playerService.playSong(song, playlist: quickItems),
                            child: Row(
                              children: [
                                // Left Square Artwork
                                SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: song.artworkUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: song.artworkUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) => Container(color: AppTheme.surfaceLight),
                                          errorWidget: (_, _, _) => Container(
                                            color: AppTheme.surfaceLight,
                                            child: const Icon(Icons.music_note, color: Colors.white54),
                                          ),
                                        )
                                      : Container(
                                          color: AppTheme.surfaceLight,
                                          child: const Icon(Icons.music_note, color: Colors.white54),
                                        ),
                                ),
                                const SizedBox(width: 8),

                                // Title
                                Expanded(
                                  child: Text(
                                    song.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: isPlayingThis ? AppTheme.spotifyGreen : Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ),

                                // Play Indicator or Icon
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: isPlayingThis
                                      ? const Icon(Icons.equalizer_rounded, color: AppTheme.spotifyGreen, size: 20)
                                      : Container(
                                          width: 26,
                                          height: 26,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.spotifyGreen,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.black,
                                            size: 18,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // Spotify Language Selector Row
                LanguageFilterBar(
                  selectedLanguage: _selectedLanguage,
                  onLanguageSelected: (lang) {
                    if (_selectedLanguage != lang) {
                      setState(() {
                        _selectedLanguage = lang;
                        _selectedCategoryIndex = 0;
                      });
                      _loadCategorySongs(_categories[0]);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Spotify Carousel 1: "Jump Back In" / "Recently Played"
                ListenableBuilder(
                  listenable: UserTasteService(),
                  builder: (context, _) {
                    final recentOrMostPlayed = UserTasteService().getMostPlayedSongs(limit: 8);
                    if (recentOrMostPlayed.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Jump Back In',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  widget.playerService.playSong(recentOrMostPlayed.first, playlist: recentOrMostPlayed);
                                },
                                child: const Text(
                                  'Play All',
                                  style: TextStyle(
                                    color: AppTheme.spotifyGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 195,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: recentOrMostPlayed.length,
                            itemBuilder: (context, index) {
                              final song = recentOrMostPlayed[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: GestureDetector(
                                  onTap: () => widget.playerService.playSong(song, playlist: recentOrMostPlayed),
                                  child: SizedBox(
                                    width: 135,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: SizedBox(
                                            width: 135,
                                            height: 135,
                                            child: song.artworkUrl.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: song.artworkUrl,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (_, _, _) => Container(color: AppTheme.surfaceLight),
                                                  )
                                                : Container(
                                                    color: AppTheme.surfaceLight,
                                                    child: const Icon(Icons.music_note, color: Colors.white54),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          song.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),

                // Spotify Carousel 2: "Popular Artists"
                ListenableBuilder(
                  listenable: UserTasteService(),
                  builder: (context, _) {
                    final topArtists = UserTasteService().getTopArtists(limit: 6);
                    if (topArtists.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Text(
                            'Your Favorite Artists',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 145,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: topArtists.length,
                            itemBuilder: (context, index) {
                              final artist = topArtists[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: GestureDetector(
                                  onTap: () => _loadCategorySongs(artist),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.surfaceLight,
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                                        ),
                                        child: Center(
                                          child: Text(
                                            artist.isNotEmpty ? artist[0].toUpperCase() : 'A',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.spotifyGreen,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),

                // Spotify Section Header: Trending or Selected Category
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategoryIndex == 0
                            ? 'Trending for You'
                            : _categories[_selectedCategoryIndex],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.spotifyGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.spotifyGreen.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          '320KBPS HD',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.spotifyGreen,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Song Tiles List
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppTheme.spotifyGreen),
                    ),
                  )
                else if (_trendingSongs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No songs found. Check your internet connection.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _trendingSongs.length,
                    itemBuilder: (context, index) {
                      final song = _trendingSongs[index];
                      final isCurrent = widget.playerService.currentSong?.id == song.id;

                      return SongTileWidget(
                        song: song,
                        isPlaying: isCurrent && widget.playerService.isPlaying,
                        downloadService: widget.downloadService,
                        playlistService: widget.playlistService,
                        onTap: () => widget.playerService.playSong(song, playlist: _trendingSongs),
                      );
                    },
                  ),

                  // Infinite Scroll Loading Indicator
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.spotifyGreen, strokeWidth: 2),
                      ),
                    ),

                  // Footer Credit
                  Padding(
                    padding: const EdgeInsets.only(top: 28, bottom: 12),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.favorite_rounded, size: 13, color: AppTheme.spotifyGreen),
                            SizedBox(width: 6),
                            Text(
                              'Developed by Ranjeet Kumar',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
