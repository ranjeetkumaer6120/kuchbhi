import 'package:flutter/material.dart';

class AlbumPalette {
  final Color primary;
  final Color secondary;
  final Color background;

  const AlbumPalette({
    required this.primary,
    required this.secondary,
    required this.background,
  });

  /// 8 Harmonious Apple Music Dark OLED aesthetic color pairs
  static const List<List<Color>> _curatedPalettes = [
    [Color(0xFFFF2D55), Color(0xFF5856D6)], // Apple Rose + Violet
    [Color(0xFFFF9500), Color(0xFFFF3B30)], // Warm Sunset + Coral
    [Color(0xFF007AFF), Color(0xFF00C7BE)], // Azure Blue + Cyan
    [Color(0xFF5E5CE6), Color(0xFFAF52DE)], // Royal Indigo + Magenta
    [Color(0xFF34C759), Color(0xFF30B0C7)], // Emerald Mint + Ocean
    [Color(0xFFFF375F), Color(0xFFFF7A00)], // Neon Crimson + Tangerine
    [Color(0xFF64D2FF), Color(0xFF5E5CE6)], // Ice Blue + Deep Iris
    [Color(0xFFFFD60A), Color(0xFFFF375F)], // Gold Neon + Strawberry
  ];

  /// Generates a deterministic harmonious ambient glow palette from song title & artist
  factory AlbumPalette.fromSong({required String title, required String artist}) {
    final seed = '${title.toLowerCase().trim()}-${artist.toLowerCase().trim()}';
    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0x7FFFFFFF;
    }

    final selectedPair = _curatedPalettes[hash % _curatedPalettes.length];

    return AlbumPalette(
      primary: selectedPair[0],
      secondary: selectedPair[1],
      background: const Color(0xFF0A0A0C),
    );
  }
}
