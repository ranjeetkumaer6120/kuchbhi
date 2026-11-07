import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/user_taste_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_filter_bar.dart';
import '../widgets/song_tile_widget.dart';

class SearchScreen extends StatefulWidget {
  final AudioPlayerService playerService;
  final DownloadService downloadService;
  final ApiService apiService;
  final PlaylistService playlistService;

  const SearchScreen({
    super.key,
    required this.playerService,
    required this.downloadService,
    required this.apiService,
    required this.playlistService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  int _searchSectionIndex = 0; // 0: Songs, 1: Artists, 2: Playlists
  List<Map<String, dynamic>> _artistResults = [];
  List<Map<String, dynamic>> _playlistResults = [];

  final List<String> _sourceModes = [
    'All Music',
    'Master HD',
    'Studio Audio',
    'Lo-Fi Chill',
    'Classic Hits',
  ];
  int _selectedSourceIndex = 0;
  String _selectedLanguage = 'All';

  List<SongModel> _searchResults = [];
  bool _isSearching = false;

  List<SongModel> _trendingSongs = [];
  List<SongModel> _suggestedSongs = [];
  bool _isLoadingTrending = false;

  List<String> _recentSearches = [];

  final List<Map<String, dynamic>> _browseGenres = const [
    {'title': 'Bollywood', 'color': Color(0xFFE13300), 'query': 'Bollywood Hits'},
    {'title': 'Punjabi', 'color': Color(0xFF7358FF), 'query': 'Punjabi Top'},
    {'title': 'Bhojpuri', 'color': Color(0xFF1E3264), 'query': 'Bhojpuri Hits'},
    {'title': 'Hindi Pop', 'color': Color(0xFFE8115B), 'query': 'Hindi Pop'},
    {'title': 'Lo-Fi Chill', 'color': Color(0xFF148A08), 'query': 'Lo-Fi Chill'},
    {'title': 'Arijit Singh', 'color': Color(0xFF503750), 'query': 'Arijit Singh'},
    {'title': 'Party Hits', 'color': Color(0xFFBC5900), 'query': 'Party Hits'},
    {'title': 'Romance', 'color': Color(0xFF0D73EC), 'query': 'Romantic Hindi'},
    {'title': 'Slowed & Reverb', 'color': Color(0xFF8D67AB), 'query': 'Lo-Fi Slowed'},
    {'title': 'Indie India', 'color': Color(0xFFD84000), 'query': 'Indie India'},
  ];

  final List<String> _suggestions = [
    'Bhojpuri Top 50',
    'Pawan Singh',
    'Khesari Lal Yadav',
    'Shilpi Raj',
    'Arijit Singh',
    'Sidhu Moosewala',
    'Diljit Dosanjh',
    'Animal',
    'Chaleya',
    'Lo-Fi Bollywood',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadTrendingSongs();
  }

  Future<void> _loadTrendingSongs() async {
    if (!mounted) return;
    setState(() => _isLoadingTrending = true);
    try {
      final lang = _selectedLanguage == 'All' ? null : _selectedLanguage;
      final topArtists = UserTasteService().getTopArtists(limit: 2);
      final suggestQuery = topArtists.isNotEmpty
          ? topArtists.first
          : ((lang != null && lang != 'All') ? '$lang Top Hits' : 'Top Hindi Songs');
      final query = (lang != null && lang != 'All') ? '$lang Trending Hits' : 'Trending Hits';

      final results = await Future.wait([
        widget.apiService.searchSongs(query, page: 1, limit: 10, language: lang),
        widget.apiService.searchSongs(suggestQuery, page: 1, limit: 10, language: lang),
      ]);

      if (mounted) {
        final dedupeTrending = ApiService.deduplicateByQuality(results[0]);
        final dedupeSuggested = ApiService.deduplicateByQuality(results[1]);
        setState(() {
          _trendingSongs = UserTasteService().getPersonalizedTrending(dedupeTrending, limit: 10);
          _suggestedSongs = UserTasteService().getPersonalizedTrending(dedupeSuggested, limit: 10);
          _isLoadingTrending = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final recents = prefs.getStringList('kuchbhi_recent_searches') ?? [];
    if (mounted) {
      setState(() => _recentSearches = recents);
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final updated = List<String>.from(_recentSearches);
    updated.remove(clean);
    updated.insert(0, clean);
    if (updated.length > 15) {
      updated.removeLast();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('kuchbhi_recent_searches', updated);

    if (mounted) {
      setState(() => _recentSearches = updated);
    }
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kuchbhi_recent_searches');
    if (mounted) {
      setState(() => _recentSearches = []);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _artistResults = [];
        _playlistResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    _saveRecentSearch(clean);
    UserTasteService().recordSearch(clean);
    setState(() => _isSearching = true);

    final lang = _selectedLanguage == 'All' ? null : _selectedLanguage;

    if (_searchSectionIndex == 1) {
      // Search Artists
      final queryWithLang = (lang != null && !clean.toLowerCase().contains(lang.toLowerCase()))
          ? '$clean $lang'
          : clean;
      final artists = await widget.apiService.searchArtists(queryWithLang);
      if (mounted) {
        setState(() {
          _artistResults = artists;
          _isSearching = false;
        });
      }
      return;
    } else if (_searchSectionIndex == 2) {
      // Search Playlists
      final queryWithLang = (lang != null && !clean.toLowerCase().contains(lang.toLowerCase()))
          ? '$clean $lang'
          : clean;
      final playlists = await widget.apiService.searchPlaylists(queryWithLang);
      if (mounted) {
        setState(() {
          _playlistResults = playlists;
          _isSearching = false;
        });
      }
      return;
    }

    List<SongModel> results;

    switch (_selectedSourceIndex) {
      case 0:
        results = await widget.apiService.searchAllSourcesAndRank(clean, language: lang);
        break;
      case 1:
        results = await widget.apiService.searchSongs(clean, language: lang);
        break;
      case 2:
        final ytQuery = (lang != null && !clean.toLowerCase().contains(lang.toLowerCase()))
            ? '$clean $lang'
            : clean;
        results = await widget.apiService.searchYouTube(ytQuery);
        break;
      case 3:
        results = await widget.apiService.getFreeToUseTracks();
        break;
      case 4:
        final archiveQuery = (lang != null && !clean.toLowerCase().contains(lang.toLowerCase()))
            ? '$clean $lang'
            : clean;
        results = await widget.apiService.searchArchive(archiveQuery);
        break;
      default:
        results = await widget.apiService.searchAllSourcesAndRank(clean, language: lang);
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _playArtistTopSongs(Map<String, dynamic> artist) async {
    final name = artist['name'] ?? 'Artist';
    final id = artist['id'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading top songs for $name...'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.surfaceLight,
      ),
    );
    final songs = await widget.apiService.getArtistTopSongs(id);
    if (songs.isNotEmpty && mounted) {
      widget.playerService.playSong(songs.first, playlist: songs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing $name - Top Hits (320kbps)'),
          backgroundColor: AppTheme.appleRed,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tracks found for $name'),
          backgroundColor: Colors.grey[800],
        ),
      );
    }
  }

  Future<void> _playPlaylist(Map<String, dynamic> playlist) async {
    final title = playlist['title'] ?? 'Playlist';
    final id = playlist['id'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading $title...'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.surfaceLight,
      ),
    );
    final songs = await widget.apiService.getPlaylistSongs(id);
    if (songs.isNotEmpty && mounted) {
      widget.playerService.playSong(songs.first, playlist: songs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing $title'),
          backgroundColor: AppTheme.appleRed,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tracks found in $title'),
          backgroundColor: Colors.grey[800],
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Widget _buildSectionTab(int index, String title) {
    final isSelected = _searchSectionIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_searchSectionIndex != index) {
            setState(() {
              _searchSectionIndex = index;
            });
            if (_searchController.text.trim().isNotEmpty) {
              _performSearch(_searchController.text);
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.appleRed : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemCount: _artistResults.length,
      itemBuilder: (context, index) {
        final artist = _artistResults[index];
        final name = artist['name'] ?? 'Artist';
        final img = artist['image'] ?? '';
        return GestureDetector(
          onTap: () => _playArtistTopSongs(artist),
          child: Column(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: img.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppTheme.surfaceLight),
                          errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white54, size: 40),
                        )
                      : Container(
                          color: AppTheme.surfaceLight,
                          child: const Icon(Icons.person, color: Colors.white54, size: 40),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Artist • Tap to Play',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylistGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemCount: _playlistResults.length,
      itemBuilder: (context, index) {
        final playlist = _playlistResults[index];
        final title = playlist['title'] ?? 'Playlist';
        final img = playlist['image'] ?? '';
        final count = playlist['songCount'] ?? '';
        return GestureDetector(
          onTap: () => _playPlaylist(playlist),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: img.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppTheme.surfaceLight),
                            errorWidget: (context, url, error) => const Icon(Icons.queue_music, color: Colors.white54, size: 48),
                          )
                        : Container(
                            color: AppTheme.surfaceLight,
                            child: const Icon(Icons.queue_music, color: Colors.white54, size: 48),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count.isNotEmpty ? '$count Songs • 320kbps' : 'Curated Playlist',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _performSearch,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: _searchSectionIndex == 1
                      ? 'Search Artists (Arijit, Pawan Singh...)'
                      : (_searchSectionIndex == 2
                          ? 'Search Playlists (Top 50, Party, Lo-Fi...)'
                          : 'What do you want to listen to?'),
                  hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Search Section Switcher: [Songs] [Artists] [Playlists]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  _buildSectionTab(0, 'Songs'),
                  _buildSectionTab(1, 'Artists'),
                  _buildSectionTab(2, 'Playlists'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Frosted Glass Language Filter Bar
          LanguageFilterBar(
            selectedLanguage: _selectedLanguage,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            onLanguageSelected: (lang) {
              if (_selectedLanguage != lang) {
                setState(() => _selectedLanguage = lang);
                if (_searchController.text.trim().isNotEmpty) {
                  _performSearch(_searchController.text);
                } else {
                  _loadTrendingSongs();
                }
              }
            },
          ),
          const SizedBox(height: 6),

          // Multi-Source Selector Chips (Only when Songs section active)
          if (_searchSectionIndex == 0) ...[
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _sourceModes.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedSourceIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(
                        _sourceModes[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: index == 0
                          ? AppTheme.appleRed
                          : (index == 1
                              ? AppTheme.emeraldGreen.withValues(alpha: 0.8)
                              : (index == 2 ? Colors.redAccent : AppTheme.cyberCyan)),
                      backgroundColor: AppTheme.surface,
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : AppTheme.border,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedSourceIndex = index);
                          if (_searchController.text.isNotEmpty) {
                            _performSearch(_searchController.text);
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Search Results or Suggestions
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppTheme.appleRed))
                : _searchSectionIndex == 1
                    ? (_artistResults.isNotEmpty
                        ? _buildArtistGrid()
                        : _buildSectionSuggestions(
                            'Featured Artists',
                            [
                              'Arijit Singh',
                              'Pawan Singh',
                              'Khesari Lal Yadav',
                              'Sidhu Moosewala',
                              'Shilpi Raj',
                              'Diljit Dosanjh',
                              'Neha Kakkar',
                              'Badshah',
                              'Taylor Swift',
                              'Ed Sheeran',
                            ],
                          ))
                    : _searchSectionIndex == 2
                        ? (_playlistResults.isNotEmpty
                            ? _buildPlaylistGrid()
                            : _buildSectionSuggestions(
                                'Featured Playlists',
                                [
                                  'Bhojpuri Top 50',
                                  'Bollywood Romance',
                                  'Punjabi 100',
                                  'Lo-Fi Beats India',
                                  'Workout Energy',
                                  'Party Hits 2024',
                                  'Old Classics Hindi',
                                ],
                              ))
                        : (_searchResults.isNotEmpty
                            ? ListView.builder(
                                padding: const EdgeInsets.only(bottom: 120),
                                itemCount: _searchResults.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _searchResults.length) {
                                    return Padding(
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
                                    );
                                  }

                                  final song = _searchResults[index];
                                  final isCurrent = widget.playerService.currentSong?.id == song.id;

                                  return SongTileWidget(
                                    song: song,
                                    isPlaying: isCurrent && widget.playerService.isPlaying,
                                    downloadService: widget.downloadService,
                                    playlistService: widget.playlistService,
                                    onTap: () => widget.playerService.playSong(song, playlist: _searchResults),
                                  );
                                },
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section: Most Played by You (Jo Song Zyada Sunta Hai)
                                    ListenableBuilder(
                                      listenable: UserTasteService(),
                                      builder: (context, _) {
                                        final mostPlayed = UserTasteService().getMostPlayedSongs(limit: 6);
                                        if (mostPlayed.isEmpty) return const SizedBox.shrink();

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.repeat_rounded, color: AppTheme.appleRed, size: 20),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Most Played by You',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                TextButton.icon(
                                                  icon: const Icon(Icons.play_arrow_rounded, size: 18, color: AppTheme.appleRed),
                                                  label: const Text(
                                                    'Play All',
                                                    style: TextStyle(
                                                      color: AppTheme.appleRed,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    widget.playerService.playSong(mostPlayed.first, playlist: mostPlayed);
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            ...mostPlayed.map((song) {
                                              final isCurrent = widget.playerService.currentSong?.id == song.id;
                                              final playCount = UserTasteService().getPlayCount(song.id);
                                              return SongTileWidget(
                                                song: song,
                                                isPlaying: isCurrent && widget.playerService.isPlaying,
                                                downloadService: widget.downloadService,
                                                playlistService: widget.playlistService,
                                                subtitleExtra: '$playCount plays',
                                                onTap: () => widget.playerService.playSong(song, playlist: mostPlayed),
                                              );
                                            }),
                                            const SizedBox(height: 24),
                                          ],
                                        );
                                      },
                                    ),

                                    // Section: Live Trending Songs (Abhi Jo Trending Wala Hai)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.trending_up_rounded, color: AppTheme.cyberCyan, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedLanguage == 'All'
                                                  ? 'Trending Now • Top Hits'
                                                  : 'Trending in $_selectedLanguage',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_trendingSongs.isNotEmpty)
                                          TextButton.icon(
                                            icon: const Icon(Icons.play_arrow_rounded, size: 18, color: AppTheme.cyberCyan),
                                            label: const Text(
                                              'Play All',
                                              style: TextStyle(
                                                color: AppTheme.cyberCyan,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            onPressed: () {
                                              widget.playerService.playSong(_trendingSongs.first, playlist: _trendingSongs);
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (_isLoadingTrending)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 24),
                                          child: CircularProgressIndicator(color: AppTheme.cyberCyan),
                                        ),
                                      )
                                    else if (_trendingSongs.isNotEmpty)
                                      ..._trendingSongs.take(8).map((song) {
                                        final isCurrent = widget.playerService.currentSong?.id == song.id;
                                        return SongTileWidget(
                                          song: song,
                                          isPlaying: isCurrent && widget.playerService.isPlaying,
                                          downloadService: widget.downloadService,
                                          playlistService: widget.playlistService,
                                          onTap: () => widget.playerService.playSong(song, playlist: _trendingSongs),
                                        );
                                      }),
                                    const SizedBox(height: 24),

                                    // Section: Recent Searches (if any)
                                    if (_recentSearches.isNotEmpty) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Recent Searches',
                                            style: TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                          ),
                                          TextButton(
                                            onPressed: _clearRecentSearches,
                                            child: const Text('Clear',
                                                style: TextStyle(color: AppTheme.appleRed, fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _recentSearches.map((term) {
                                          return ActionChip(
                                            avatar: const Icon(Icons.history_rounded,
                                                size: 16, color: AppTheme.cyberCyan),
                                            backgroundColor: AppTheme.surfaceLight,
                                            side: const BorderSide(color: AppTheme.border),
                                            label:
                                                Text(term, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                            onPressed: () {
                                              _searchController.text = term;
                                              _performSearch(term);
                                            },
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 24),
                                    ],

                                    // Section: Suggested Songs for You (Real Song suggestions, not just text!)
                                    if (_suggestedSongs.isNotEmpty) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.auto_awesome_rounded, color: AppTheme.applePink, size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                'Suggested Songs for You',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            icon: const Icon(Icons.play_arrow_rounded, size: 18, color: AppTheme.applePink),
                                            label: const Text(
                                              'Play All',
                                              style: TextStyle(
                                                color: AppTheme.applePink,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            onPressed: () {
                                              widget.playerService.playSong(_suggestedSongs.first, playlist: _suggestedSongs);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ..._suggestedSongs.take(8).map((song) {
                                        final isCurrent = widget.playerService.currentSong?.id == song.id;
                                        return SongTileWidget(
                                          song: song,
                                          isPlaying: isCurrent && widget.playerService.isPlaying,
                                          downloadService: widget.downloadService,
                                          playlistService: widget.playlistService,
                                          onTap: () => widget.playerService.playSong(song, playlist: _suggestedSongs),
                                        );
                                      }),
                                      const SizedBox(height: 24),
                                    ],

                                    // Spotify Signature "Browse all" Colorful Cards Grid
                                    _buildBrowseAllGrid(),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Column(
                                        children: [
                                          const Icon(Icons.auto_awesome_rounded, size: 50, color: AppTheme.applePink),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Unlimited Music & Live Radio',
                                            style: TextStyle(
                                                color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Master HD • Studio Sound • Live FM 24/7',
                                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                          ),
                                          const SizedBox(height: 20),
                                          Container(
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
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseAllGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse all',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _browseGenres.length,
          itemBuilder: (context, index) {
            final item = _browseGenres[index];
            final title = item['title'] as String;
            final color = item['color'] as Color;
            final query = item['query'] as String;

            return Material(
              color: color,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -6,
                      right: -8,
                      child: Transform.rotate(
                        angle: 0.35,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white60,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionSuggestions(String title, List<String> items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: items.map((item) {
              return ActionChip(
                backgroundColor: AppTheme.surface,
                side: const BorderSide(color: AppTheme.border),
                label: Text(item, style: const TextStyle(color: Colors.white, fontSize: 13)),
                onPressed: () {
                  _searchController.text = item;
                  _performSearch(item);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
