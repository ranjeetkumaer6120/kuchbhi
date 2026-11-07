import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/main.dart';
import 'package:soundvibe/services/api_service.dart';
import 'package:soundvibe/services/audio_player_service.dart';
import 'package:soundvibe/services/download_service.dart';
import 'package:soundvibe/services/playlist_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SoundVibeApp smoke test renders tabs', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final downloadService = DownloadService();
    await downloadService.init();

    final playlistService = PlaylistService();
    await playlistService.init();

    final audioPlayerService = AudioPlayerService();
    final apiService = ApiService();

    await tester.pumpWidget(SoundVibeApp(
      audioPlayerService: audioPlayerService,
      downloadService: downloadService,
      apiService: apiService,
      playlistService: playlistService,
    ));

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Your Library'), findsOneWidget);
  });
}
