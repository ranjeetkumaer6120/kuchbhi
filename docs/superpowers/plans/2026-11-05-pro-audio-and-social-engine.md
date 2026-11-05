# Implementation Plan: Pro Audio, Virality & Intelligence Engine for Kuchbhi App

**Plan Date**: 2026-11-05  
**Execution Strategy**: Subagent-Driven Development (SDD) & Strict TDD  
**Target Device**: `RMX3242` (`adb-VOU8O7EIFISGMFX4-SgQSmb._adb-tls-connect._tcp`)

---

## 1. Overview & Objectives

Transform the `kuchbhi` music app into an addictive, Spotify/Apple-Music beating experience by delivering:
1. **Lo-Fi Slowed + Reverb Engine**: 1-tap pitch/speed modifier (0.85x slowed audio with warm reverb tone) & speed control.
2. **Dynamic "Time-of-Day" Mixes & Infinite Autoplay**: Morning/Work/Evening/Late Night contextual greeting and auto-populating similar tracks on queue end.
3. **Live Soundwave Visualizer**: 20-bar pulsing audio visualizer responding to playback in `PlayerScreen`.
4. **Smart Auto-Download for Favorites (❤️)**: Auto-caches loved songs in background for guaranteed 0% internet travel playback.
5. **Instagram / WhatsApp Aesthetic Story Card Generator**: 1-tap renders high-res dark glass card with artwork, title, waveform, and branding badge to system share sheet.
6. **Local Device MP3 Scanner**: Scans device audio files (`/storage/emulated/0/Music`, `Download`) directly into Library.

---

## 2. Tasks & Step Breakdown

### Task 1: Lo-Fi Slowed Mode & Playback Speed Engine
**Files:**
- Modify: `android_app/lib/services/audio_player_service.dart`
- Modify: `android_app/lib/screens/player_screen.dart`
- Test: `android_app/test/audio_player_service_speed_test.dart`

- [ ] **Step 1: Write unit tests for Lo-Fi mode and speed changes**
  Test `setSpeed(double)`, `toggleLoFiMode()`, `isLoFiMode`, verifying speed (0.85x) and pitch adjustment.
- [ ] **Step 2: Implement speed & Lo-Fi in `AudioPlayerService`**
  Add `double _playbackSpeed = 1.0`, `bool _isLoFiMode = false`, `setSpeed(double speed)`, and `toggleLoFiMode()`.
- [ ] **Step 3: Add Lo-Fi & Speed controls to `PlayerScreen`**
  Add aesthetic `[✨ Lo-Fi]` frosted glass button next to playback controls. Tapping toggles 0.85x slowed vibe with haptic feedback. Long press / tap opens Speed sheet (`0.75x`, `0.85x Lo-Fi`, `1.0x Normal`, `1.25x`, `1.5x`).
- [ ] **Step 4: Verify with `flutter test` and `flutter analyze`**

---

### Task 2: Dynamic "Time-of-Day" Mood Mixes & Infinite Autoplay
**Files:**
- Modify: `android_app/lib/screens/home_screen.dart`
- Modify: `android_app/lib/services/audio_player_service.dart`
- Test: `android_app/test/time_mix_test.dart`

- [ ] **Step 1: Write unit test for Time-of-Day Greeting & Mood mapping**
  Test hour-to-greeting helper (`5-11`: Morning Ragas, `12-16`: Lo-Fi Focus, `17-21`: Evening Hits, `22-4`: Midnight Romance & Slowed).
- [ ] **Step 2: Add dynamic header & quick mood pills in `HomeScreen`**
  Above category pills, render contextual greeting with weather/mood emoji and 4 instant curated query pills.
- [ ] **Step 3: Enhance Infinite Autoplay in `AudioPlayerService`**
  When queue has <= 1 track remaining, automatically fetch and append 5 top peer songs for the active artist or language so music never stops abruptly.
- [ ] **Step 4: Verify with `flutter test` and `flutter analyze`**

---

### Task 3: Live Soundwave Visualizer in `PlayerScreen`
**Files:**
- Create: `android_app/lib/widgets/audio_visualizer_widget.dart`
- Modify: `android_app/lib/screens/player_screen.dart`
- Test: `android_app/test/visualizer_test.dart`

- [ ] **Step 1: Write unit test for `AudioVisualizerWidget`**
  Test widget initialization and state binding to `isPlaying`.
- [ ] **Step 2: Implement animated 20-bar soundwave visualizer**
  Custom painter / animated bar layout with randomized harmonic frequencies that smoothly animate when playing and flatten to a sleek line when paused.
- [ ] **Step 3: Integrate below Album Art in `PlayerScreen`**
  Position between album art and song title with dynamic gradient colors matching `AlbumPalette`.
- [ ] **Step 4: Verify with `flutter test` and `flutter analyze`**

---

### Task 4: Smart Auto-Download for Loved Songs (❤️)
**Files:**
- Modify: `android_app/lib/services/playlist_service.dart`
- Modify: `android_app/lib/screens/library_screen.dart`
- Test: `android_app/test/auto_download_test.dart`

- [ ] **Step 1: Write unit test for auto-download preference & trigger**
  Test that toggling favorite triggers `downloadService.downloadSong` when auto-download is enabled.
- [ ] **Step 2: Implement auto-download hook in `PlaylistService`**
  Add `bool _autoDownloadFavorites = true` (persisted in SharedPreferences) and wire `downloadService.downloadSong(song)` on favorite add.
- [ ] **Step 3: Add setting switch in `LibraryScreen`**
  Add "Auto-download Favorites" toggle card in Library tab with offline badge.
- [ ] **Step 4: Verify with `flutter test` and `flutter analyze`**

---

### Task 5: Instagram / WhatsApp Aesthetic Story Card Generator
**Files:**
- Create: `android_app/lib/widgets/story_card_dialog.dart`
- Modify: `android_app/lib/screens/player_screen.dart`
- Test: `android_app/test/story_card_test.dart`

- [ ] **Step 1: Write unit test for Story Card data model & widget**
  Test rendering of song title, artist, branding, and RepaintBoundary key.
- [ ] **Step 2: Create `StoryCardDialog` with RepaintBoundary**
  Aesthetic 9:16 vertical card with album art, ambient glow, lyrics excerpt, and "Listening on Kuchbhi App • 320kbps Master HD".
- [ ] **Step 3: Integrate with `share_plus` to export PNG & open system share sheet**
  Capture boundary to Uint8List PNG, write to temp directory, and call `Share.shareXFiles([XFile(path)])`.
- [ ] **Step 4: Add Share button to `PlayerScreen` action bar**
- [ ] **Step 5: Verify with `flutter test` and `flutter analyze`**

---

### Task 6: Local Device MP3 Storage Scanner
**Files:**
- Modify: `android_app/lib/screens/library_screen.dart`
- Test: `android_app/test/local_audio_test.dart`

- [ ] **Step 1: Write unit test for local MP3 file scanning logic**
- [ ] **Step 2: Implement device audio directory scanner in `LibraryScreen`**
  Scan local storage directories for `.mp3` and `.m4a` files and render as 4th Tab: `📱 Device Music`.
- [ ] **Step 3: Connect to `AudioPlayerService.playSong` for seamless local playback**
- [ ] **Step 4: Verify with `flutter test` and `flutter analyze`**

---

### Task 7: Full Verification & Device Deployment
- [ ] **Step 1: Run complete `flutter test` & `flutter analyze lib`**
- [ ] **Step 2: Build release APK (`flutter build apk --release --split-per-abi`)**
- [ ] **Step 3: Install on `RMX3242` via ADB and launch app**
- [ ] **Step 4: Git commit & push clean commits to `origin/main`**
