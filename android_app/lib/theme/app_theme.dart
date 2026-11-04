import 'package:flutter/material.dart';

class AppTheme {
  // Apple Music Iconic Colors
  static const Color background = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF16171E);
  static const Color surfaceLight = Color(0xFF22232E);
  static const Color border = Color(0xFF2C2D3A);
  
  static const Color appleRed = Color(0xFFFC3C44);
  static const Color applePink = Color(0xFFFF6482);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color cyberCyan = Color(0xFF06B6D4);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9898A0);
  static const Color textMuted = Color(0xFF636366);

  static LinearGradient get appleGradient => const LinearGradient(
        colors: [appleRed, applePink],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: appleRed,
        colorScheme: const ColorScheme.dark(
          primary: appleRed,
          secondary: applePink,
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: appleRed,
          unselectedItemColor: textSecondary,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
        ),
      );
}
