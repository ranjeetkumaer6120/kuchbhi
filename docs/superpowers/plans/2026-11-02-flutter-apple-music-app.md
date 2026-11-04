# Apple Music Style Flutter Android App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, functional Flutter Android music streaming and downloading app with Apple Music aesthetics, 320kbps JioSaavn audio streaming, ad-free YouTube audio extraction, in-app offline MP3 downloads, and background playback.

**Architecture:** Flutter client application with clean layered architecture (Models, API Service, Audio Player Engine, Local Download/Metadata Manager, Glassmorphic UI Screens). The app talks to public high-speed Saavn REST endpoints for 320kbps audio and extracts YouTube streams for unreleased/remix tracks.

**Tech Stack:** Flutter 3.44.1, Dart 3.12.1, `just_audio`, `audio_service`, `http`, `path_provider`, `cached_network_image`, `shared_preferences`, Material 3 + Cupertino icons.

**Spec:** `docs/superpowers/specs/2026-11-02-flutter-music-app-design.md`

## Global Constraints
- Target: Android 8.0+ (API level 26 to 36).
- 100% Free: No paid subscription or paid API tokens required.
- Audio Quality: 320kbps direct stream where available; fallback to YouTube audio.
- UI Style: Apple Music Dark theme with frosted glass (`BackdropFilter`) and Crimson-Rose accent (`#FC3C44`).
- Offline Playback: Downloaded tracks must play immediately without network connection.

## Review Focus
1. **Network Disconnection:** When in airplane mode, the app must smoothly allow playing all downloaded songs without throwing unhandled exceptions.
2. **Audio Stream URL Expiration:** If a stream URL expires, the app should re-fetch metadata before failing.
3. **Background Media Playback:** Audio must continue playing when the app is minimized or the screen turns off.
4. **Fast Search Debouncing:** Rapid typing in the search bar should not trigger excessive simultaneous HTTP requests.
5. **Storage Cleanup & Deletion:** Deleting a downloaded song removes both the file on disk and its metadata entry from local storage.

---

### Task 1: Scaffold Flutter Project & Configure Dependencies

**Files:**
- Create: `pubspec.yaml`
- Create: `android/app/build.gradle` (verify Android permissions: `INTERNET`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`)
- Create: `android/app/src/main/AndroidManifest.xml`

**Steps:**
- [ ] Initialize/scaffold Flutter app in `E:\mp3` if not already initialized (`flutter create --org com.antigravity.soundvibe --project-name soundvibe .`)
- [ ] Add required dependencies in `pubspec.yaml`: `just_audio`, `audio_video_progress_bar`, `http`, `path_provider`, `shared_preferences`, `cached_network_image`, `cupertino_icons`
- [ ] Add Android permissions for media playback and internet in `AndroidManifest.xml`
- [ ] Run `flutter pub get` and verify that all dependencies resolve cleanly
- [ ] Commit changes: `git add . && git commit -m "feat: scaffold flutter project with audio dependencies"`

---

### Task 2: Data Models & Service Layer (JioSaavn 320kbps + YouTube API)

**Files:**
- Create: `lib/models/song_model.dart`
- Create: `lib/services/api_service.dart`
- Test: `test/api_service_test.dart`

**Steps:**
- [ ] Write unit test in `test/api_service_test.dart` verifying `SongModel.fromJson` parses 320kbps URLs, title, artist, album, and high-res artwork.
- [ ] Implement `SongModel` with JSON serialization, local file path storage, and offline status.
- [ ] Implement `ApiService` with endpoints for:
  - `searchSongs(query)`: Queries Saavn API (`https://saavn.dev/api/search/songs?query=...`) and parses results with 320kbps stream links.
  - `getTrending()`: Fetches trending Hindi, Punjabi, and English top charts.
  - `getYouTubeAudioStream(queryOrUrl)`: Extracts raw audio streams for YouTube searches/links.
- [ ] Run `flutter test test/api_service_test.dart` and verify tests pass.
- [ ] Commit changes: `git commit -am "feat: add song model and multi-source API service"`

---

### Task 3: Local Storage & Offline Download Manager

**Files:**
- Create: `lib/services/download_service.dart`
- Test: `test/download_service_test.dart`

**Steps:**
- [ ] Write unit test for `DownloadService` verifying catalog indexing, saving songs to app directory, and reading offline list.
- [ ] Implement `DownloadService`:
  - `downloadSong(SongModel song)`: Streams MP3 bytes to local file in `getApplicationDocumentsDirectory()/music/`, updates track's `localFilePath`, and records to `offline_catalog.json`.
  - `getOfflineSongs()`: Returns list of downloaded songs with zero internet latency.
  - `deleteDownloadedSong(String id)`: Removes file from disk and updates catalog.
- [ ] Run `flutter test test/download_service_test.dart` and ensure tests pass.
- [ ] Commit changes: `git commit -am "feat: implement download service and offline storage"`

---

### Task 4: Audio Player Engine (Background Playback & State)

**Files:**
- Create: `lib/services/audio_player_service.dart`
- Modify: `lib/main.dart`

**Steps:**
- [ ] Implement `AudioPlayerService` wrapping `just_audio.AudioPlayer`:
  - Manages current song, playlist/queue, play, pause, seek, next, previous.
  - Seamlessly handles both remote streaming URLs (`AudioSource.uri(Uri.parse(streamUrl))`) and offline local files (`AudioSource.file(localFilePath)`).
  - Exposes playback streams: `positionStream`, `durationStream`, `playerStateStream`, `currentSongStream`.
- [ ] Write test or verification script for playback state management.
- [ ] Commit changes: `git commit -am "feat: implement audio player engine with local and remote source support"`

---

### Task 5: Apple Music Design System & Glassmorphic UI Components

**Files:**
- Create: `lib/theme/app_theme.dart`
- Create: `lib/widgets/glass_container.dart`
- Create: `lib/widgets/song_tile_widget.dart`
- Create: `lib/widgets/mini_player_widget.dart`

**Steps:**
- [ ] Implement `AppTheme` with Apple Music aesthetic (`#0A0A0C` background, `#FC3C44` Apple Music Crimson, frosted surface colors, SF-style typography).
- [ ] Implement `GlassContainer` using `BackdropFilter` with Gaussian blur (`sigmaX: 20`, `sigmaY: 20`) for authentic frosted glass look.
- [ ] Implement `SongTileWidget` displaying album artwork, song title, artist, audio quality pill (`320kbps HD` or `YouTube`), download indicator button, and play trigger.
- [ ] Implement `MiniPlayerWidget` that floats above the navigation bar with translucent blur, track title, progress line, and play/pause controls.
- [ ] Commit changes: `git commit -am "feat: implement apple music theme and glassmorphic widgets"`

---

### Task 6: Screens Implementation (Listen Now, Search, Library, Full Player)

**Files:**
- Create: `lib/screens/home_screen.dart` (Listen Now with hero cards, trending Hindi & Global charts)
- Create: `lib/screens/search_screen.dart` (Universal search with live results & quality badges)
- Create: `lib/screens/library_screen.dart` (Online Favorites & Offline Downloaded library)
- Create: `lib/screens/player_screen.dart` (Full-screen player with dynamic blurred album art, big rotating/rounded artwork, scrubber, play/pause, download button)
- Modify: `lib/main.dart` (Bottom Navigation Shell linking all tabs)

**Steps:**
- [ ] Build `HomeScreen` with Apple Music style carousel and top charts.
- [ ] Build `SearchScreen` with debounced search query, instant 320kbps results, and YouTube mode toggle.
- [ ] Build `LibraryScreen` displaying both Online and Offline tracks, with clear "Offline Ready" badges.
- [ ] Build `PlayerScreen` modal sheet with dynamic backdrop blur derived from current song, interactive progress scrubber, playback controls, and 1-tap download MP3 button.
- [ ] Wire everything into `main.dart` with bottom navigation (Listen Now, Search, Library) and persistent MiniPlayer.
- [ ] Commit changes: `git commit -am "feat: implement all apple music styled screens and navigation"`

---

### Task 7: Full System Verification & APK Build Check

**Steps:**
- [ ] Run all unit and widget tests: `flutter test`
- [ ] Run Flutter analyze to ensure zero errors/warnings: `flutter analyze`
- [ ] Run Flutter build check: `flutter build apk --debug` (or run on connected Windows/Android device)
- [ ] Verify search returns 320kbps streams, playback works, and offline download functions properly.
- [ ] Final commit and documentation update.
