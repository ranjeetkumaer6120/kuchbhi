# Personalized Trending & User Taste Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Store user musical interest (artists, genres, languages, searches, play completions, and skips) and dynamically personalize the Trending Songs feed so the user sees songs matching their taste rather than generic or irrelevant tracks, with strictly zero emoji/decorative icons across all text, pills, and headers.

**Architecture:** Extend `UserTasteService` into a comprehensive Taste Profile Engine that scores implicit and explicit user behaviors (artist frequency, search queries, completion rates, skip penalties). Implement `getPersonalizedTrending(List<SongModel> globalTrending)` which re-ranks and filters candidate trending songs using a weighted affinity formula (80% affinity match, 20% fresh discovery). Wire the personalized engine into `HomeScreen`, `SearchScreen`, and `AudioPlayerService` (which feeds Android Auto over USB). Purge all emoji icons from category pills, tabs, greetings, and labels.

**Tech Stack:** Flutter / Dart, `shared_preferences`, `just_audio`, `just_audio_background`.

**Spec:** User request:
1. USB car connection support with personalized media playback.
2. Store user interest and show personalized trending songs accordingly ("user ke intrest ko store ko asnd uske according tranding song mai bhi show karo oaky ye nhi ki all teading song show na hai behar and intrest ki kistype ka song unta hai").
3. Strict constraint: Do not use any icons or emoji icons ("koi icon use mat karna okay").

## Global Constraints
- Zero emoji icons anywhere in UI text, category chips, mood pills, greetings, or badges (e.g. NO 🔥, ⚡, ☕, ⭐, ❤️, 🎧, etc.).
- Plain, clean typography (e.g. "Trending for You", "Top Tracks", "On Repeat", "Favorites Mix", "3 plays").
- 100% offline-safe caching of user taste profiles using `SharedPreferences`.
- Fast, non-blocking $O(N \log N)$ in-memory re-ranking of trending songs.
- Backward-compatible with existing `SongModel` and `UserTasteService` APIs.

## Review Focus
1. Cold-start user (fresh install with zero plays): Returns raw deduplicated trending hits without crashing or dropping songs.
2. Heavy skip penalty: Songs with artists/keywords that user repeatedly skips within 15 seconds are demoted below all other tracks.
3. Search interest boost: Searching an artist (e.g. "Arijit Singh") boosts their trending songs even before the first full play completes.
4. Android Auto USB queue: Initial queue pre-armed on startup reflects the user's personalized trending list.
5. Strict icon-free assurance: No emoji characters in category pills, vibe pills, filter bars, or time-of-day greetings.

---

### Task 1: Extend `UserTasteService` with Search & Skip Profiling and Personalized Trending Algorithm

**Files:**
- Modify: `android_app/lib/services/user_taste_service.dart`
- Create: `android_app/test/personalized_trending_test.dart`

**Interfaces:**
- Produces:
  - `void recordSearch(String query)`
  - `void recordSkip(SongModel song, {int playedSeconds = 0})`
  - `void recordCompletion(SongModel song)`
  - `List<SongModel> getPersonalizedTrending(List<SongModel> globalTrending, {int limit = 30})`
  - `double calculateSongAffinity(SongModel song)`
  - `List<String> getPersonalizedVibePills({List<SongModel>? favorites})` (Purged of all emojis)

- [ ] **Step 1: Write the failing unit tests for `UserTasteService` personalization and icon-free pills**

Create `android_app/test/personalized_trending_test.dart` covering:
- Icon-free verification: check that `getPersonalizedVibePills()` contains zero emoji characters (matches regex `r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]'`).
- Recording search queries, plays, and skips updates internal affinities.
- `getPersonalizedTrending` elevates a user's favorite artist's trending song to the top of the list over unrelated songs.
- Cold-start returns global trending intact.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd android_app; flutter test test/personalized_trending_test.dart`
Expected: FAIL (missing methods `recordSearch`, `recordSkip`, `getPersonalizedTrending`, or emoji failure).

- [ ] **Step 3: Implement Taste Profile & Re-ranking Algorithm in `user_taste_service.dart`**

- Add storage keys:
  - `_searchCountsKey = 'soundvibe_search_counts_v1'`
  - `_genreCountsKey = 'soundvibe_genre_counts_v1'`
  - `_skipCountsKey = 'soundvibe_skip_counts_v1'`
- Implement `recordSearch(String query)`: cleans query, increments search counts for keywords and primary tokens.
- Implement `recordSkip(SongModel song, {int playedSeconds = 0})`: if skipped within 20s, increments `_skipCounts[cleanedArtist]` and `_songSkipCounts[song.id]`.
- Implement `calculateSongAffinity(SongModel song) -> double`:
  - Combines:
    - Artist play count weight ($+3.0$ per play)
    - Artist search count weight ($+2.0$ per search)
    - Song play count weight ($+4.0$ per repeat play)
    - Skip penalty ($-3.0$ per skip)
- Implement `getPersonalizedTrending(List<SongModel> globalTrending, {int limit = 30})`:
  - If no history exists, returns `globalTrending.take(limit).toList()`.
  - Calculates affinity score for each song.
  - Sorts candidate songs descending by `affinityScore + (globalRankWeight)`.
  - Dedupes and takes `limit` songs.
- Strip all emojis from `getPersonalizedVibePills()`: replace `'🔥 On Repeat'` with `'On Repeat'`, `'⭐ $artist'` with `artist`, `'❤️ Favorites Mix'` with `'Favorites Mix'`, `'⚡ Trending Hits'` with `'Trending Hits'`, `'☕ Chill Lo-Fi'` with `'Chill Lo-Fi'`, `'🎧 Top Hindi'` with `'Top Hindi'`, `'🌾 Bhojpuri Hits'` with `'Bhojpuri Hits'`, `'🥁 Punjabi Top'` with `'Punjabi Top'`, `'✨ Bollywood Beats'` with `'Bollywood Beats'`.

- [ ] **Step 4: Run unit test to verify it passes**

Run: `cd android_app; flutter test test/personalized_trending_test.dart`
Expected: PASS (all tests green).

- [ ] **Step 5: Commit Task 1**

```bash
git add android_app/lib/services/user_taste_service.dart android_app/test/personalized_trending_test.dart
git commit -m "feat: user interest tracking and personalized trending re-ranking algorithm"
```

---

### Task 2: Remove All Emojis & Wire Personalized Trending into `HomeScreen`

**Files:**
- Modify: `android_app/lib/screens/home_screen.dart`
- Modify: `android_app/lib/widgets/language_filter_bar.dart`
- Modify: `android_app/lib/services/time_of_day_helper.dart`

**Interfaces:**
- Consumes: `UserTasteService().getPersonalizedTrending()`
- Consumes: Clean icon-free vibe pills and category lists.

- [ ] **Step 1: Remove all emojis from `home_screen.dart`, `language_filter_bar.dart`, and `time_of_day_helper.dart`**

- In `home_screen.dart`:
  - Replace `_categories`:
    - `'🔥 Trending'` -> `'Trending for You'`
    - `'⚡ Bollywood Hits'` -> `'Bollywood Hits'`
    - `'☕ Lo-Fi Chill'` -> `'Lo-Fi Chill'`
  - Remove emoji stripping regexes like `.replaceAll('🔥', '').replaceAll('⚡', '')` since categories are now pure clean text.
  - Replace `'🔥 On Repeat'` with `'On Repeat'`.
  - Replace `'❤️ Favorites Mix'` with `'Favorites Mix'`.
  - Replace play count badge `'🔥 ${playCount}x'` with `'${playCount} plays'` or `'${playCount}x'`.
  - Replace snackbar `'Playing your most listened songs 🔥'` with `'Playing your most listened songs'`.
- In `language_filter_bar.dart`:
  - Remove emojis from `languages`:
    - `'🔥 All'` -> `'All'`
    - `'🌾 Bhojpuri'` -> `'Bhojpuri'`
    - `'🌍 English'` -> `'English'`
    - `'🥁 Punjabi'` -> `'Punjabi'`
    - `'☕ Lo-Fi'` -> `'Lo-Fi'`
- In `time_of_day_helper.dart`:
  - Remove all emoji characters from greetings (`Good Morning`, `Good Afternoon`, `Good Evening`, `Late Night Chill`) and default category suggestions.

- [ ] **Step 2: Connect Personalized Trending in `_loadCategorySongs`**

- When category is `'Trending for You'` (or default index 0):
  - Fetch global trending songs from `ApiService.getTrendingSongs()`.
  - Deduplicate with `ApiService.deduplicateByQuality()`.
  - Run through `UserTasteService().getPersonalizedTrending(deduplicated)`.
  - Update `_trendingSongs` with the personalized list!

- [ ] **Step 3: Run Flutter analyze to ensure zero compilation or linter errors**

Run: `cd android_app; flutter analyze lib`
Expected: 0 issues found.

- [ ] **Step 4: Run entire test suite**

Run: `cd android_app; flutter test`
Expected: All tests pass.

- [ ] **Step 5: Commit Task 2**

```bash
git add android_app/lib/screens/home_screen.dart android_app/lib/widgets/language_filter_bar.dart android_app/lib/services/time_of_day_helper.dart
git commit -m "feat: icon-free clean UI and personalized trending feed on home screen"
```

---

### Task 3: Clean `SearchScreen` Emojis & Wire Search Query Interest Tracking

**Files:**
- Modify: `android_app/lib/screens/search_screen.dart`
- Modify: `android_app/lib/widgets/song_tile_widget.dart`
- Modify: `android_app/lib/widgets/story_card_dialog.dart`
- Modify: `android_app/lib/screens/player_screen.dart`

**Interfaces:**
- Consumes: `UserTasteService().recordSearch(query)`
- Consumes: Clean text headers and search tabs.

- [ ] **Step 1: Clean emojis in `search_screen.dart`, `song_tile_widget.dart`, `player_screen.dart`, and `story_card_dialog.dart`**

- In `search_screen.dart`:
  - Replace quick categories:
    - `'🌟 All Music'` -> `'All Music'`
    - `'☕ Lo-Fi Chill'` -> `'Lo-Fi Chill'`
    - `'🏛️ Classic Hits'` -> `'Classic Hits'`
  - Replace section tab text:
    - `'🎵 Songs'` -> `'Songs'`
    - `'🎤 Artists'` -> `'Artists'`
    - `'📑 Playlists'` -> `'Playlists'`
  - Replace subtitleExtra `'🔥 ${playCount}x'` with `'${playCount} plays'`.
  - In `_performSearch(query)`: call `UserTasteService().recordSearch(query)` so user searches instantly impact taste profile and personalized trending.
- In `song_tile_widget.dart` & `player_screen.dart` & `story_card_dialog.dart`:
  - Clean copy/share text strings to remove `🎵` emoji.

- [ ] **Step 2: Run Flutter analyze and tests**

Run: `cd android_app; flutter analyze lib; flutter test`
Expected: 0 analyze issues, all tests pass.

- [ ] **Step 3: Commit Task 3**

```bash
git add android_app/lib/screens/search_screen.dart android_app/lib/widgets/song_tile_widget.dart android_app/lib/widgets/story_card_dialog.dart android_app/lib/screens/player_screen.dart
git commit -m "feat: search interest tracking and icon-free search screen"
```

---

### Task 4: Connect Play Duration, Skips & Car USB Startup Pre-arming

**Files:**
- Modify: `android_app/lib/services/audio_player_service.dart`
- Modify: `android_app/lib/main.dart`

**Interfaces:**
- In `AudioPlayerService`:
  - Monitor position and track changes.
  - When a song is changed before 15 seconds, call `UserTasteService().recordSkip(previousSong, playedSeconds: seconds)`.
  - When a song plays for more than 30 seconds, call `UserTasteService().recordCompletion(currentSong)`.
- In `main.dart`:
  - When pre-filling the initial queue on startup (for USB/Android Auto/Bluetooth car head-unit), pass the fetched trending tracks through `UserTasteService().getPersonalizedTrending(...)` so the car display immediately gets the user's personalized queue upon connecting!

- [ ] **Step 1: Implement skip & completion tracking in `AudioPlayerService`**

- [ ] **Step 2: Update startup queue pre-arming in `main.dart` with personalized trending**

- [ ] **Step 3: Run Flutter analyze and full test suite**

Run: `cd android_app; flutter analyze lib; flutter test`
Expected: 0 analyze issues, all tests pass.

- [ ] **Step 4: Commit Task 4**

```bash
git add android_app/lib/services/audio_player_service.dart android_app/lib/main.dart
git commit -m "feat: skip and completion tracking with personalized car queue pre-arming"
```

---

### Task 5: Build Release APKs, Verify on Device, and Push

**Files:**
- Build: `android_app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- Update: `downloads/kuchbhi.apk`, `downloads/kuchbhi-release.apk`, `downloads/kuchbhi-car-display.apk`

- [ ] **Step 1: Build release APKs with split-per-abi**

Run: `cd android_app; flutter build apk --release --split-per-abi`
Expected: Build succeeds.

- [ ] **Step 2: Copy updated APKs to `downloads/`**

- [ ] **Step 3: Install APK to connected device via ADB**

Run: `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "android_app\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"`
Expected: Success.

- [ ] **Step 4: Commit binaries and push to GitHub `main`**

```bash
git add downloads/
git commit -m "chore: release apks with personalized trending and icon-free UI"
git push origin main
```
