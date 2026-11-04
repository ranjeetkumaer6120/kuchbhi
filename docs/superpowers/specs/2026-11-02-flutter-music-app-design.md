# Flutter Android Music App - Design Specification (Apple Music Style)

**Date:** 2026-11-02  
**Target Platform:** Android (Flutter 3.44.1, Android SDK 36.1.0)  
**Execution Target:** Rapid delivery (within 30-40 minutes)

---

## 1. Intent & Purpose (The "Why")
The user wants a personal, 100% free, high-fidelity music streaming and downloading Android application styled with **Apple Music's iconic UI/UX aesthetic** (glassmorphism, vibrant blurred backdrop, sleek typography, clean cards). The app allows seamless discovery, streaming at true 320kbps, direct YouTube audio extraction with zero ads, and offline downloads that are stored and playable directly inside the app with both online and offline modes clearly visible.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **Apple Music UI/UX Aesthetic:** Frosted glass navigation bars, dynamic background artwork blur, Apple Music vibrant accent (`#FC3C44` / Crimson-Rose), elegant typography, and rounded album art with soft drop shadows.
- **True 320kbps Audio Quality:** Direct high-bitrate streaming via JioSaavn API.
- **YouTube Audio Extractor (Ad-Free):** Stream/download any track or remix directly from YouTube without video bandwidth or ads.
- **Dual Online & Offline Modes:**
  - Clear tabs for Online Discovery and Offline Library.
  - Downloaded tracks display an "Offline Ready" badge and play instantly with zero internet.
- **In-App Offline Storage:** Downloaded MP3s are stored in app storage for lightning-fast indexing and playback without Android 14 permission friction.
- **Background & Lock-Screen Playback:** Smooth media notifications with lock-screen controls.

### Non-Goals
- Social profiles, public user commenting, or accounts.
- Paid subscriptions or payment gateways.

### Anti-Goals
- Generic or ugly interface that doesn't feel like Apple Music.
- Buffering delays or ads.
- Downloaded songs failing to play when offline (airplane mode).

---

## 3. Architecture & Technical Decisions

- **Framework:** Flutter 3.44.1 / Dart 3.12.1.
- **Audio & Media Engine:** `just_audio` + `audio_service` for robust background playback and notification controls.
- **APIs:**
  - Primary (320kbps): JioSaavn public REST API endpoints (`saavn.dev`) for metadata, 500x500 artwork, and direct 320kbps audio URLs.
  - Secondary: YouTube stream extraction engine for ad-free audio.
- **Storage:** Local app storage using `path_provider` + JSON track catalog database.
- **UI Architecture (Apple Music Style):**
  - Background: Deep Dark (`#0A0A0C`) with dynamic blurred glow from the currently playing album art.
  - Accent Color: Apple Music Crimson-Rose (`#FC3C44`) & Coral Gradient.
  - Glassmorphic translucent bottom bar & mini-player.
  - Tabs:
    1. **Listen Now (Home):** Top charts, trending playlists, quick recommendations.
    2. **Search:** Universal search with 320kbps badge & YouTube mode.
    3. **Library (Offline & Online):** Downloaded songs, favorites, recently played.

---

## 4. UI/UX Screens Specification
1. **Home / Listen Now:** Apple Music style big hero cards, recently added, top charts.
2. **Search Screen:** Real-time search with quality badges (`320kbps Studio` / `YouTube`).
3. **Now Playing Screen:** Full-screen frosted blur backdrop, large centered album art, animated scrubber, Apple Music style control buttons, download MP3 action.
4. **Mini-Player:** Floating translucent pill above the navigation bar.
5. **Library / Downloads:** Tab showing both Online favorites and Offline downloaded tracks with offline status badge.
