import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/time_of_day_helper.dart';
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
    '🔥 Trending',
    '⚡ Bollywood Hits',
    '☕ Lo-Fi Chill',
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
    } else {
      final query = category.replaceAll('🔥', '').replaceAll('⚡', '').trim();
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
    final query = category.replaceAll('🔥', '').replaceAll('⚡', '').trim();
    final lang = _selectedLanguage == 'All' ? null : _selectedLanguage;
    final moreSongs = await widget.apiService.searchSongs(query, page: _currentPage, limit: 25, language: lang);

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

  @override
  Widget build(BuildContext context) {
    final heroSong = _trendingSongs.isNotEmpty ? _trendingSongs.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listen Now'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadCategorySongs(_categories[_selectedCategoryIndex]),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.appleRed,
        onRefresh: () => _loadCategorySongs(_categories[_selectedCategoryIndex]),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frosted Glass Language Filter Row
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

              const SizedBox(height: 10),

              // Time of Day Contextual Greeting Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TimeOfDayHelper.getGreeting(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.appleRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.appleRed.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'LIVE FLOW',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.applePink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Curated Mood Pills Carousel
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: TimeOfDayHelper.getCuratedMoods().length,
                  itemBuilder: (context, index) {
                    final mood = TimeOfDayHelper.getCuratedMoods()[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          mood,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        backgroundColor: AppTheme.surfaceLight,
                        side: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () {
                          final cleanQuery = mood.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                          _loadCategorySongs(cleanQuery);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Category Pills Carousel
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          _categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.appleRed,
                        backgroundColor: AppTheme.surface,
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : AppTheme.border,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategoryIndex = index);
                            _loadCategorySongs(_categories[index]);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Featured Hero Banner (Apple Music Big Card style)
              if (heroSong != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => widget.playerService.playSong(heroSong, playlist: _trendingSongs),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.appleRed.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Hero Artwork Image
                            Positioned.fill(
                              child: heroSong.artworkUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: heroSong.artworkUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: AppTheme.surfaceLight),
                            ),
                            // Gradient Overlay for Readability
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.4),
                                      Colors.black.withValues(alpha: 0.95),
                                    ],
                                    stops: const [0.3, 0.65, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.appleRed,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'FEATURED TRACK • MASTER AUDIO',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          heroSong.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          heroSong.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Big Play Button
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.appleGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.appleRed.withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Section: Unlimited Top Songs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Tracks (${_categories[_selectedCategoryIndex]})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Text('Master HD', style: TextStyle(fontSize: 12, color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.appleRed),
                  ),
                )
              else if (_trendingSongs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No songs found. Check your internet connection.', style: TextStyle(color: AppTheme.textSecondary)),
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
                      child: CircularProgressIndicator(color: AppTheme.appleRed, strokeWidth: 2),
                    ),
                  ),

                // Footer Developer Credit (Requested by user)
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
                          Icon(Icons.favorite_rounded, size: 13, color: AppTheme.appleRed),
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
    );
  }
}
