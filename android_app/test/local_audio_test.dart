import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/services/local_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalAudioService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('soundvibe_test_audio_');
    service = LocalAudioService();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('LocalAudioService scans directory and extracts valid audio files with metadata', () async {
    // Create test audio files and non-audio files
    final sep = Platform.pathSeparator;
    final song1 = File('${tempDir.path}${sep}Arijit Singh - Kesariya.mp3');
    await song1.writeAsString('fake mp3 audio data 1');

    final song2 = File('${tempDir.path}${sep}Believer.m4a');
    await song2.writeAsString('fake m4a audio data 2');

    final nonAudio = File('${tempDir.path}${sep}document.txt');
    await nonAudio.writeAsString('text file');

    final subDir = Directory('${tempDir.path}${sep}SubFolder');
    await subDir.create();
    final song3 = File('${subDir.path}${sep}Pawan Singh - Lollypop Lagelu.wav');
    await song3.writeAsString('fake wav audio data 3');

    final songs = await service.scanDirectories([tempDir]);

    expect(songs.length, 3);

    // Verify song1 with "Artist - Title" format
    final kesariya = songs.firstWhere((s) => s.title == 'Kesariya');
    expect(kesariya.artist, 'Arijit Singh');
    expect(kesariya.isOffline, true);
    expect(kesariya.source, 'device');
    expect(File(kesariya.localFilePath!).path, File(song1.path).path);

    // Verify song2 with single title format
    final believer = songs.firstWhere((s) => s.title == 'Believer');
    expect(believer.artist, 'Device Storage');
    expect(believer.isOffline, true);

    // Verify song3 in sub-directory
    final lollypop = songs.firstWhere((s) => s.title == 'Lollypop Lagelu');
    expect(lollypop.artist, 'Pawan Singh');
  });

  test('LocalAudioService search filters local tracks accurately', () async {
    final sep = Platform.pathSeparator;
    final song1 = File('${tempDir.path}${sep}Atif Aslam - Dil Diyan Gallan.mp3');
    await song1.writeAsString('fake audio');

    final song2 = File('${tempDir.path}${sep}Shreya Ghoshal - Deewani Mastani.mp3');
    await song2.writeAsString('fake audio');

    await service.scanDirectories([tempDir]);

    final searchResults = service.search('Atif');
    expect(searchResults.length, 1);
    expect(searchResults.first.title, 'Dil Diyan Gallan');
  });
}
