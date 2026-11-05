import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/widgets/story_card_dialog.dart';

void main() {
  group('StoryCardDialog Widget Tests', () {
    testWidgets('renders story card dialog with song info and branding', (tester) async {
      final song = SongModel(
        id: 'test-story-1',
        title: 'Heeriye',
        artist: 'Arijit Singh',
        album: 'Single',
        duration: 195,
        streamUrl: 'https://example.com/stream.mp3',
        artworkUrl: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCardDialog(song: song),
          ),
        ),
      );

      expect(find.text('Heeriye'), findsOneWidget);
      expect(find.text('Arijit Singh'), findsOneWidget);
      expect(find.textContaining('Kuchbhi App'), findsOneWidget);
    });
  });
}
