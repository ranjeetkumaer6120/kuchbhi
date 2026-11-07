import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/widgets/language_filter_bar.dart';

void main() {
  group('LanguageFilterBar Widget Tests', () {
    testWidgets('renders all language chips with correct labels', (tester) async {
      String selected = 'All';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageFilterBar(
              selectedLanguage: selected,
              onLanguageSelected: (lang) => selected = lang,
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Hindi'), findsOneWidget);
      expect(find.text('Bhojpuri'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Punjabi'), findsOneWidget);
      expect(find.text('Lo-Fi'), findsOneWidget);
    });

    testWidgets('tapping language chip invokes onLanguageSelected callback', (tester) async {
      String selected = 'All';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LanguageFilterBar(
                  selectedLanguage: selected,
                  onLanguageSelected: (lang) {
                    setState(() => selected = lang);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap Bhojpuri
      await tester.tap(find.text('Bhojpuri'));
      await tester.pumpAndSettle();

      expect(selected, 'Bhojpuri');

      // Tap Punjabi
      await tester.tap(find.text('Punjabi'));
      await tester.pumpAndSettle();

      expect(selected, 'Punjabi');

      // Scroll slightly to bring Lo-Fi fully into view in 800px test viewport
      await tester.drag(find.byType(ListView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Tap Lo-Fi
      await tester.tap(find.text('Lo-Fi'));
      await tester.pumpAndSettle();

      expect(selected, 'Lo-Fi');
    });
  });
}
