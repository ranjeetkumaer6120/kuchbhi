import 'dart:convert';
import 'package:dart_des/dart_des.dart';

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final String streamUrl;
  final String artworkUrl;
  final String source; // 'saavn', 'youtube', 'itunes', 'archive', 'offline'
  final String qualityBadge; // '320kbps HD', 'Apple 256k', 'YouTube HD', 'Archive MP3', 'Offline'
  bool isOffline;
  String? localFilePath;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.streamUrl,
    required this.artworkUrl,
    this.source = 'saavn',
    this.qualityBadge = 'Master HD',
    this.isOffline = false,
    this.localFilePath,
  });

  /// Numerical score to rank results by audio quality (highest quality shown at the very top)
  int get qualityScore {
    if (isOffline) return 400; // Offline downloads take highest priority
    if (qualityBadge.contains('320') || qualityBadge.contains('Master')) return 320; // Master Audio
    if (source == 'radio' || qualityBadge.contains('LIVE')) return 280; // Live Radio stream
    if (qualityBadge.contains('256') || source == 'itunes' || qualityBadge.contains('Hi-Fi')) return 256; // Hi-Fi Audio
    if (source == 'youtube' || qualityBadge.contains('Studio')) return 192; // Studio HD audio
    if (source == 'archive') return 160;
    return 128;
  }

  /// Decrypts JioSaavn encrypted_media_url to true 320kbps CDN URL
  static String decryptSaavnUrl(String encryptedBase64) {
    try {
      final key = utf8.encode('38346591');
      final des = DES(key: key, mode: DESMode.ECB, paddingType: DESPaddingType.PKCS5);
      final encryptedBytes = base64.decode(encryptedBase64);
      final decryptedBytes = des.decrypt(encryptedBytes);
      final decrypted = utf8.decode(decryptedBytes);
      return decrypted.replaceAll(RegExp(r'_(96|160)\.mp4'), '_320.mp4');
    } catch (_) {
      return '';
    }
  }

  /// Clean HTML entities like &quot; &amp; &#039;
  static String cleanText(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Factory for JioSaavn official API song result (320kbps)
  factory SongModel.fromSaavnJson(Map<String, dynamic> json) {
    final moreInfo = json['more_info'] as Map<String, dynamic>? ?? {};
    final encryptedUrl = moreInfo['encrypted_media_url'] as String? ?? '';
    final decryptedStream = encryptedUrl.isNotEmpty ? decryptSaavnUrl(encryptedUrl) : '';

    String artistName = 'Unknown Artist';
    if (json['subtitle'] != null && json['subtitle'].toString().isNotEmpty) {
      artistName = cleanText(json['subtitle'].toString());
    } else if (moreInfo['music'] != null && moreInfo['music'].toString().isNotEmpty) {
      artistName = cleanText(moreInfo['music'].toString());
    }

    String art = json['image'] as String? ?? '';
    art = art.replaceAll('150x150', '500x500');

    String title = cleanText(json['title'] as String? ?? json['song'] as String? ?? 'Untitled Track');
    String album = cleanText(moreInfo['album'] as String? ?? 'Single');

    int dur = 0;
    if (moreInfo['duration'] != null) {
      dur = int.tryParse(moreInfo['duration'].toString()) ?? 0;
    }

    return SongModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      artist: artistName,
      album: album,
      duration: dur,
      streamUrl: decryptedStream,
      artworkUrl: art,
      source: 'saavn',
      qualityBadge: 'Master HD',
    );
  }

  /// Factory for Apple iTunes Search API (256kbps HQ preview + 600x600 artwork)
  factory SongModel.fromItunesJson(Map<String, dynamic> json) {
    final art = (json['artworkUrl100'] as String? ?? '').replaceAll('100x100bb', '600x600bb');
    final durMillis = (json['trackTimeMillis'] as num?)?.toInt() ?? 0;

    return SongModel(
      id: 'itunes_${json['trackId'] ?? DateTime.now().millisecondsSinceEpoch}',
      title: cleanText(json['trackName'] as String? ?? 'Unknown Title'),
      artist: cleanText(json['artistName'] as String? ?? 'Unknown Artist'),
      album: cleanText(json['collectionName'] as String? ?? 'Single'),
      duration: (durMillis / 1000).round(),
      streamUrl: json['previewUrl'] as String? ?? '',
      artworkUrl: art,
      source: 'itunes',
      qualityBadge: 'Hi-Fi Audio',
    );
  }

  /// Factory for Internet Archive audio search
  factory SongModel.fromArchiveJson(Map<String, dynamic> json) {
    final identifier = json['identifier'] as String? ?? '';
    final creator = json['creator'] is List ? (json['creator'] as List).join(', ') : (json['creator']?.toString() ?? 'Archive Community');

    return SongModel(
      id: 'ia_$identifier',
      title: cleanText(json['title']?.toString() ?? identifier),
      artist: cleanText(creator),
      album: 'Classic Hits',
      duration: 0,
      streamUrl: 'https://archive.org/download/$identifier/${identifier}_vbr.mp3',
      artworkUrl: 'https://archive.org/services/img/$identifier',
      source: 'archive',
      qualityBadge: 'Classic HD',
    );
  }

  /// Factory for Live Radio Stations (Radio Browser API)
  factory SongModel.fromRadioJson(Map<String, dynamic> json) {
    final name = cleanText(json['name']?.toString() ?? 'Live Radio');
    final tags = (json['tags']?.toString() ?? 'Live FM').split(',').take(2).join(', ');

    return SongModel(
      id: 'radio_${json['stationuuid'] ?? DateTime.now().millisecondsSinceEpoch}',
      title: name,
      artist: 'Live Radio • ${tags.isNotEmpty ? tags : 'India'}',
      album: 'Live Radio',
      duration: 0, // Continuous live stream
      streamUrl: json['url_resolved']?.toString() ?? json['url']?.toString() ?? '',
      artworkUrl: json['favicon']?.toString() ?? '',
      source: 'radio',
      qualityBadge: 'LIVE FM',
    );
  }

  /// Factory for Royalty-Free Lo-Fi & Chill Beats
  factory SongModel.fromFreeToUseJson(Map<String, dynamic> json) {
    final title = cleanText(json['title']?.toString() ?? 'Chill Beat');
    final artistsList = json['artists'] as List<dynamic>? ?? [];
    final artistName = artistsList.isNotEmpty ? cleanText(artistsList.first['name']?.toString() ?? 'Lo-Fi Chill') : 'Lo-Fi Chill';
    final genre = json['genre']?.toString() ?? 'Lo-Fi Chill';
    final mp3Url = json['files']?['mp3']?.toString() ?? '';
    final thumbnails = json['thumbnails'] as Map<String, dynamic>? ?? {};
    final cover = thumbnails['card']?.toString() ?? thumbnails['large']?.toString() ?? '';
    final dur = (json['duration'] as num?)?.round() ?? 180;

    return SongModel(
      id: 'ftu_${json['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      title: title,
      artist: artistName,
      album: 'Lo-Fi • $genre',
      duration: dur,
      streamUrl: mp3Url,
      artworkUrl: cover,
      source: 'freetouse',
      qualityBadge: 'Lo-Fi Chill',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'streamUrl': streamUrl,
      'artworkUrl': artworkUrl,
      'source': source,
      'qualityBadge': qualityBadge,
      'isOffline': isOffline,
      'localFilePath': localFilePath,
    };
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      artist: json['artist'] as String? ?? 'Unknown',
      album: json['album'] as String? ?? 'Unknown',
      duration: json['duration'] as int? ?? 0,
      streamUrl: json['streamUrl'] as String? ?? '',
      artworkUrl: json['artworkUrl'] as String? ?? '',
      source: json['source'] as String? ?? 'offline',
      qualityBadge: json['qualityBadge'] as String? ?? '320kbps HD',
      isOffline: json['isOffline'] as bool? ?? false,
      localFilePath: json['localFilePath'] as String?,
    );
  }
}
