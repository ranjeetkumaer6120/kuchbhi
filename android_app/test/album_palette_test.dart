import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/theme/album_palette.dart';

void main() {
  group('AlbumPalette Tests', () {
    test('AlbumPalette generates vibrant pair of colors from song metadata', () {
      final palette1 = AlbumPalette.fromSong(title: 'Kesariya', artist: 'Arijit Singh');
      expect(palette1.primary, isA<Color>());
      expect(palette1.secondary, isA<Color>());
      expect(palette1.primary, isNot(Colors.transparent));

      final palette2 = AlbumPalette.fromSong(title: 'Chaleya', artist: 'Anirudh');
      expect(palette2.primary, isA<Color>());
      expect(palette2.secondary, isA<Color>());
    });

    test('Same song produces identical deterministic palette', () {
      final palA = AlbumPalette.fromSong(title: 'Lover', artist: 'Diljit Dosanjh');
      final palB = AlbumPalette.fromSong(title: 'Lover', artist: 'Diljit Dosanjh');
      expect(palA.primary.toARGB32(), palB.primary.toARGB32());
      expect(palA.secondary.toARGB32(), palB.secondary.toARGB32());
    });
  });
}
