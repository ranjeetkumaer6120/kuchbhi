class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  @override
  String toString() => '[${timestamp.inMinutes}:${(timestamp.inSeconds % 60).toString().padLeft(2, '0')}] $text';
}

class LyricsData {
  final bool isSynced;
  final List<LyricLine> lines;
  final String rawText;

  const LyricsData({
    required this.isSynced,
    required this.lines,
    required this.rawText,
  });

  static LyricsData parse({String? syncedLyrics, String? plainLyrics}) {
    // 1. Check synced lyrics with timestamps [mm:ss.xx]
    if (syncedLyrics != null && syncedLyrics.trim().isNotEmpty) {
      final parsed = <LyricLine>[];
      final regex = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');

      for (final rawLine in syncedLyrics.split('\n')) {
        final line = rawLine.trim();
        final match = regex.firstMatch(line);
        if (match != null) {
          final min = int.tryParse(match.group(1) ?? '0') ?? 0;
          final secD = double.tryParse(match.group(2) ?? '0') ?? 0.0;
          final sec = secD.floor();
          final ms = ((secD - sec) * 1000).round();
          final text = match.group(3)?.trim() ?? '';
          if (text.isNotEmpty) {
            parsed.add(LyricLine(
              timestamp: Duration(minutes: min, seconds: sec, milliseconds: ms),
              text: text,
            ));
          }
        }
      }

      if (parsed.isNotEmpty) {
        return LyricsData(
          isSynced: true,
          lines: parsed,
          rawText: syncedLyrics,
        );
      }
    }

    // 2. Fallback to plain lyrics
    if (plainLyrics != null && plainLyrics.trim().isNotEmpty) {
      final plainLines = plainLyrics
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => LyricLine(timestamp: Duration.zero, text: l))
          .toList();

      return LyricsData(
        isSynced: false,
        lines: plainLines,
        rawText: plainLyrics.trim(),
      );
    }

    return const LyricsData(
      isSynced: false,
      lines: [],
      rawText: '',
    );
  }
}
