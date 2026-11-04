import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundvibe/services/download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('DownloadService initializes with empty catalog', () async {
      final service = DownloadService();
      await service.init();
      expect(service.offlineSongs, isEmpty);
    });

    test('isDownloaded reports false for non-downloaded song', () {
      final service = DownloadService();
      expect(service.isDownloaded('non_existent'), false);
    });
  });
}
