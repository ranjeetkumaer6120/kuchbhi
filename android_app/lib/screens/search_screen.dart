import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../theme/app_theme.dart';
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

  final List<String> _sourceModes = [
    '🌟 All Music',
    'Master HD',
    'Studio Audio',
    '📻 Live Radio',
    '☕ Lo-Fi Chill',
    '🏛️ Classic Hits',
  ];
  int _selectedSourceIndex = 0;

  List<SongModel> _searchResults = [];
  bool _isSearching = false;

  List<String> _recentSearches = [];

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
    setState(() => _isSearching = true);
    List<SongModel> results;

    switch (_selectedSourceIndex) {
      case 0:
        results = await widget.apiService.searchAllSourcesAndRank(clean);
        break;
      case 1:
        results = await widget.apiService.searchSongs(clean);
        break;
      case 2:
        results = await widget.apiService.searchYouTube(clean);
        break;
      case 3:
        results = await widget.apiService.getLiveRadioStations(query: clean);
        break;
      case 4:
        results = await widget.apiService.getFreeToUseTracks();
        break;
      case 5:
        results = await widget.apiService.searchArchive(clean);
        break;
      default:
        results = await widget.apiService.searchAllSourcesAndRank(clean);
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
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
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _performSearch,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Artists, songs, lyrics, Bhojpuri, live radio...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.appleRed),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Multi-Source Selector Chips (Best Quality on Top)
          SizedBox(
            height: 40,
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
          const SizedBox(height: 8),

          // Search Results or Suggestions
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppTheme.appleRed))
                : _searchResults.isNotEmpty
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
                            // Section: Recent Searches (if any)
                            if (_recentSearches.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Recent Searches',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                  TextButton(
                                    onPressed: _clearRecentSearches,
                                    child: const Text('Clear', style: TextStyle(color: AppTheme.appleRed, fontSize: 13)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _recentSearches.map((term) {
                                  return ActionChip(
                                    avatar: const Icon(Icons.history_rounded, size: 16, color: AppTheme.cyberCyan),
                                    backgroundColor: AppTheme.surfaceLight,
                                    side: const BorderSide(color: AppTheme.border),
                                    label: Text(term, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    onPressed: () {
                                      _searchController.text = term;
                                      _performSearch(term);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Section: Trending Searches
                            const Text(
                              'Trending Searches',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _suggestions.map((query) {
                                return ActionChip(
                                  backgroundColor: AppTheme.surface,
                                  side: const BorderSide(color: AppTheme.border),
                                  label: Text(query, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  onPressed: () {
                                    _searchController.text = query;
                                    _performSearch(query);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 36),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 50, color: AppTheme.applePink),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Unlimited Music & Live Radio',
                                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
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
                      ),
          ),
        ],
      ),
    );
  }
}
