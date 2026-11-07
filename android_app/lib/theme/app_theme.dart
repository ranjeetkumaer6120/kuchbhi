import 'package:flutter/material.dart';

class AppTheme {
  // Spotify Signature Palette
  static const Color background = Color(0xFF121212); // Deep Spotify Dark Canvas
  static const Color surface = Color(0xFF181818);    // Spotify Card Surface
  static const Color surfaceLight = Color(0xFF242424); // Spotify Elevated Tile
  static const Color surfaceElevated = Color(0xFF2A2A2A); // Spotify Chip / Card Hover
  static const Color border = Color(0xFF282828);
  
  static const Color spotifyGreen = Color(0xFF1DB954);      // Iconic Spotify Vibrant Green
  static const Color spotifyGreenLight = Color(0xFF1ED760); // Bright Green Highlight
  static const Color spotifyBlack = Color(0xFF121212);

  // Backward-compatible aliases
  static const Color appleRed = spotifyGreen;
  static const Color applePink = spotifyGreenLight;
  static const Color emeraldGreen = spotifyGreen;
  static const Color cyberCyan = spotifyGreen;

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF727272);

  static LinearGradient get spotifyGradient => const LinearGradient(
        colors: [spotifyGreen, spotifyGreenLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get appleGradient => spotifyGradient;

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: spotifyGreen,
        colorScheme: const ColorScheme.dark(
          primary: spotifyGreen,
          secondary: spotifyGreenLight,
          surface: surface,
          surfaceContainerHighest: surfaceLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: background,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: textSecondary,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
        ),
      );
}
