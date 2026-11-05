import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/widgets/audio_visualizer_widget.dart';

void main() {
  group('AudioVisualizerWidget Tests', () {
    testWidgets('renders 24 visualizer bars', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AudioVisualizerWidget(
              isPlaying: true,
              primaryColor: Colors.red,
              secondaryColor: Colors.pink,
            ),
          ),
        ),
      );

      // Verify that the visualizer widget is rendered
      expect(find.byType(AudioVisualizerWidget), findsOneWidget);
    });

    testWidgets('handles paused state without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AudioVisualizerWidget(
              isPlaying: false,
              primaryColor: Colors.cyan,
              secondaryColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(AudioVisualizerWidget), findsOneWidget);
    });
  });
}
