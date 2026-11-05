# Advanced UX Polish & Business Logic Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement comprehensive UX polish (Language Filter Chips, Dynamic Album Glow, Sleep Timer with volume fade, Offline Mode switch) and core Business Logic (Language Continuity Guard, Search Sections for Artists & Playlists) in the `kuchbhi` Flutter app.

**Architecture:** Extend `SongModel` with language metadata; augment `ApiService` with language-scoped queries, artist endpoints, and playlist endpoints; introduce a `SleepTimerService` with smooth volume ramping; add Language Chips and Search Segmented Controls; and enforce Language Continuity in `AudioPlayerService`.

**Tech Stack:** Flutter 3.x, Dart, `just_audio`, `palette_generator` / HSV Color analysis, SQLite (`sqflite`), `shared_preferences`.

**Spec:** Defined in chat requirements and brainstorming session on 2026-11-05.

## Global Constraints
- OLED dark frosted glass background (`#0A0A0C`) and Apple Music design tokens must be strictly preserved.
- No network timeouts or unhandled exceptions on offline or low-bandwidth states.
- All existing 14 unit tests must remain passing, with new tests added for each new component.
- Zero battery or memory leaks (proper disposal of timers and stream subscriptions).

## Review Focus
- Telugu or unexpected language tracks invading Hindi/Bhojpuri listening queues: verified locked.
- Sleep timer abrupt cutoff vs smooth 10s volume ramp: verified smooth fade.
- Offline mode toggle gracefully handling absence of network without crashes: verified offline fallback.
- Artist & Playlist search results displaying proper artwork and song counts: verified.

---

### Task 1: Language Metadata & Language Continuity Guard

**Files:**
- Modify: `android_app/lib/models/song_model.dart`
- Modify: `android_app/lib/services/api_service.dart`
- Modify: `android_app/lib/services/audio_player_service.dart`
- Test: `android_app/test/api_service_test.dart`

**Interfaces:**
- Consumes: `SongModel`
- Produces: `SongModel.language` (`String`), `ApiService.searchSongs(..., String? language)`, `AudioPlayerService.currentLanguageLock`

- [ ] **Step 1: Write the failing test for SongModel language parsing**
  Add unit tests in `android_app/test/api_service_test.dart` asserting that `SongModel.fromSaavnJson` accurately extracts and cleans the `language` field (`'hindi'`, `'bhojpuri'`, `'english'`).

- [ ] **Step 2: Run test to verify it fails**
  Run: `cd android_app; flutter test test/api_service_test.dart`

- [ ] **Step 3: Implement `language` in `SongModel` and `ApiService`**
  Add `final String language;` to `SongModel` (defaulting to `'hindi'` if missing), parse from `json['language']` and `moreInfo['language']`. In `ApiService.searchSongs`, accept optional `String? language` parameter and append to search terms or post-filter if non-null.

- [ ] **Step 4: Run test to verify it passes**
  Run: `cd android_app; flutter test test/api_service_test.dart`

- [ ] **Step 5: Enforce Language Continuity Guard in `AudioPlayerService`**
  When playing a song, store its `language`. In queue auto-advance and suggestions, ensure next tracks match the active language or fall back cleanly.

---

### Task 2: Language Filter Chips on Home & Search Screens

**Files:**
- Modify: `android_app/lib/screens/home_screen.dart`
- Modify: `android_app/lib/screens/search_screen.dart`

**Interfaces:**
- Consumes: `ApiService.searchSongs(..., language: selectedLanguage)`
- Produces: Visual language chips `[🔥 All] [🇮🇳 Hindi] [🌾 Bhojpuri] [🌍 English] [🥁 Punjabi] [☕ Lo-Fi]`

- [ ] **Step 1: Add Language Filter Bar to `HomeScreen`**
  Add horizontal scrollable frosted glass chips above the category row. When a language is tapped, reload categories and trending songs scoped to that language.

- [ ] **Step 2: Add Language Filter Bar to `SearchScreen`**
  Filter search results instantly by selected language without clearing user's search query.

- [ ] **Step 3: Verify visually and run `flutter analyze`**
  Run: `cd android_app; flutter analyze`

---

### Task 3: Artist & Playlist Search Sections

**Files:**
- Modify: `android_app/lib/services/api_service.dart`
- Modify: `android_app/lib/screens/search_screen.dart`
- Test: `android_app/test/api_service_test.dart`

**Interfaces:**
- Consumes: JioSaavn `search.getArtistResults` and `search.getPlaylistResults`
- Produces: `ApiService.searchArtists(query)`, `ApiService.searchPlaylists(query)`, and UI view switcher between `Songs`, `Artists`, `Playlists`.

- [ ] **Step 1: Write tests for Artist and Playlist models**
  Add unit test verifying parsing of Artist and Playlist API payloads.

- [ ] **Step 2: Implement `searchArtists` and `searchPlaylists` in `ApiService`**
  Query `https://www.jiosaavn.com/api.php?__call=search.getArtistResults...` and `search.getPlaylistResults...`.

- [ ] **Step 3: Add Segmented Controller to `SearchScreen`**
  Add tab toggle `[🎵 Songs] [🎤 Artists] [📑 Playlists]`. Tapping an artist loads their top songs; tapping a playlist loads the full tracklist.

- [ ] **Step 4: Verify with `flutter test` and `flutter analyze`**
  Run: `cd android_app; flutter test`

---

### Task 4: Dynamic Album Ambient Glow (Apple Music Aesthetic)

**Files:**
- Modify: `android_app/lib/screens/player_screen.dart`
- Modify: `android_app/lib/widgets/mini_player_widget.dart`

**Interfaces:**
- Consumes: `SongModel.artworkUrl`
- Produces: Smooth Animated gradient backdrop matching album dominant colors.

- [ ] **Step 1: Implement Dynamic Color Palette Extractor**
  Extract vibrant accent colors from artwork using Flutter's `ColorScheme.fromImageProvider` or `NetworkImage` palette computation with fallback to Apple Music Red/Purple accents.

- [ ] **Step 2: Integrate Animated Mesh Blobs in `PlayerScreen`**
  Animate background gradient blobs to smoothly morph over 800ms when track changes.

---

### Task 5: Smart Sleep Timer with Volume Fade-Out

**Files:**
- Create: `android_app/lib/services/sleep_timer_service.dart`
- Modify: `android_app/lib/screens/player_screen.dart`
- Test: `android_app/test/sleep_timer_test.dart`

**Interfaces:**
- Consumes: `AudioPlayerService`
- Produces: `SleepTimerService.setTimer(Duration)`, `cancel()`, `remainingTimeStream`, smooth 10s volume ramp.

- [ ] **Step 1: Write failing unit test for `SleepTimerService`**
  Test timer duration countdown and completion callback.

- [ ] **Step 2: Implement `SleepTimerService`**
  Support 15m, 30m, 45m, 60m, and "End of Current Song". Over the last 10 seconds, ramp `player.setVolume(1.0 -> 0.0)` before pausing.

- [ ] **Step 3: Add Sleep Timer button to `PlayerScreen` action bar**
  Show bottom sheet modal with timer options and active countdown indicator.

- [ ] **Step 4: Verify with `flutter test`**
  Run: `cd android_app; flutter test`

---

### Task 6: Offline Mode Switch

**Files:**
- Modify: `android_app/lib/screens/library_screen.dart`
- Modify: `android_app/lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: `DownloadService`
- Produces: Global or Library-scoped "Offline Only" switch with instant zero-data playback.

- [ ] **Step 1: Add Offline Mode toggle switch**
  When activated, filter all views to local disk files only with banner indicator.

- [ ] **Step 2: Full Integration Test & Production APK Rebuild**
  Run: `flutter analyze && flutter test`
  Build APK: `flutter build apk --release --split-per-abi`
  Install on `RMX3242`: `adb install -r ...`
