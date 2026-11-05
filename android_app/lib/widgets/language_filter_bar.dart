import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LanguageFilterBar extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageSelected;
  final EdgeInsetsGeometry padding;

  const LanguageFilterBar({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  static const List<Map<String, String>> languages = [
    {'label': '🔥 All', 'code': 'All'},
    {'label': '🇮🇳 Hindi', 'code': 'Hindi'},
    {'label': '🌾 Bhojpuri', 'code': 'Bhojpuri'},
    {'label': '🌍 English', 'code': 'English'},
    {'label': '🥁 Punjabi', 'code': 'Punjabi'},
    {'label': '☕ Lo-Fi', 'code': 'Lo-Fi'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        itemCount: languages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = languages[index];
          final code = item['code']!;
          final label = item['label']!;
          final isSelected = selectedLanguage.toLowerCase() == code.toLowerCase();

          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onLanguageSelected(code),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.appleRed.withValues(alpha: 0.85)
                          : const Color(0xFF1E1F29).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.appleRed
                            : Colors.white.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.appleRed.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
