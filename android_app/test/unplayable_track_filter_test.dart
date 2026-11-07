import 'package:flutter_test/flutter_test.dart';
import 'package:soundvibe/models/song_model.dart';
import 'package:soundvibe/services/api_service.dart';

void main() {
  group('Unplayable Track & Jukebox Filtering Tests', () {
    test('isPlayableSingleTrack filters out jukeboxes, compilations, and full albums', () {
      expect(
        ApiService.isPlayableSingleTrack("90's Kumar Sanu Golden Hits | Audio Jukebox", 3600),
        isFalse,
        reason: 'Audio jukebox should be filtered out',
      );

      expect(
        ApiService.isPlayableSingleTrack("Kumar Sanu All Songs Non Stop 90s Hits", 4200),
        isFalse,
        reason: 'Non stop compilations should be filtered out',
      );

      expect(
        ApiService.isPlayableSingleTrack("Arijit Singh Mega Mashup 2024", 1800),
        isFalse,
        reason: 'Mashups should be filtered out',
      );

      expect(
        ApiService.isPlayableSingleTrack("Aashiqui Full Album Audio Songs", 2500),
        isFalse,
        reason: 'Full albums should be filtered out',
      );

      expect(
        ApiService.isPlayableSingleTrack("Best of Kumar Sanu - Top 20 Songs", 4800),
        isFalse,
        reason: 'Top songs collections should be filtered out',
      );

      expect(
        ApiService.isPlayableSingleTrack("Bollywood Live Stream 24/7", 0),
        isFalse,
        reason: 'Live streams should be filtered out',
      );
    });

    test('isPlayableSingleTrack filters out tracks exceeding 12 minutes (720s) or shorter than 45s', () {
      expect(
        ApiService.isPlayableSingleTrack("Kumar Sanu Romantic Song", 780),
        isFalse,
        reason: 'Track > 12 minutes is not a standard single',
      );

      expect(
        ApiService.isPlayableSingleTrack("Song Teaser Promo", 30),
        isFalse,
        reason: 'Track < 45 seconds is a teaser/clip',
      );
    });

    test('isPlayableSingleTrack accepts valid single tracks', () {
      expect(
        ApiService.isPlayableSingleTrack("Dheere Dheere Se Meri Zindagi", 312),
        isTrue,
        reason: 'Standard single track should pass filter',
      );

      expect(
        ApiService.isPlayableSingleTrack("Kesariya - Brahmastra", 268),
        isTrue,
        reason: 'Standard single track should pass filter',
      );

      expect(
        ApiService.isPlayableSingleTrack("Tum Hi Ho - Aashiqui 2", 262),
        isTrue,
        reason: 'Standard single track should pass filter',
      );
    });

    test('deduplicateByQuality prioritizes 320kbps JioSaavn tracks over YouTube', () {
      final saavnTrack = SongModel(
        id: 'saavn_1',
        title: 'Dheere Dheere Se',
        artist: 'Kumar Sanu',
        album: 'Aashiqui',
        duration: 312,
        streamUrl: 'https://aac.saavncdn.com/test_320.mp4',
        artworkUrl: 'https://c.saavncdn.com/test.jpg',
        source: 'saavn',
        qualityBadge: '320kbps HD',
      );

      final ytTrack = SongModel(
        id: 'yt_1',
        title: 'Dheere Dheere Se (Official Video)',
        artist: 'Kumar Sanu',
        album: 'Single',
        duration: 315,
        streamUrl: '',
        artworkUrl: 'https://img.youtube.com/test.jpg',
        source: 'youtube',
        qualityBadge: 'Studio HD',
      );

      final deduped = ApiService.deduplicateByQuality([ytTrack, saavnTrack]);
      expect(deduped.length, equals(1));
      expect(deduped.first.source, equals('saavn'));
      expect(deduped.first.qualityBadge, equals('320kbps HD'));
      expect(deduped.first.streamUrl, equals('https://aac.saavncdn.com/test_320.mp4'));
    });
  });
}
