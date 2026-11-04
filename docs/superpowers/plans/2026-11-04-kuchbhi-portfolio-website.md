# kuchbhi Apple Music Portfolio Website Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or inline execution. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Separate Android Flutter app into `android_app/` directory and build an Apple Music-styled showcase and developer portfolio website at `E:\mp3\index.html`.

**Architecture:** Monorepo structure with `android_app/` for the Flutter mobile codebase, `downloads/` for ready APKs, and responsive static web assets (`index.html`, `assets/css/style.css`, `assets/js/player.js`, `assets/images/`) offering an interactive web music player, live lyrics visualizer, app mockups, QR download codes, and developer portfolio for Ranjeet Kumar.

**Tech Stack:** HTML5, CSS3 (Apple Dark Glassmorphism, OLED `#0A0A0C`, Apple Red `#FC3C44`, Flexbox/Grid, Canvas Audio Visualizer), Vanilla JavaScript, QR Code API, Flutter 3.x (inside `android_app/`).

## Task 1: Project Reorganization & Directory Separation
- [ ] Create `android_app/` and `downloads/` directories.
- [ ] Move Flutter source folders (`lib/`, `android/`, `test/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`, `build/`, `pubspec.yaml`, `pubspec.lock`, etc.) into `android_app/`.
- [ ] Move APK files (`kuchbhi.apk`, `kuchbhi-car-display.apk`, `kuchbhi-release.apk`) into `downloads/`.
- [ ] Verify `flutter test` runs cleanly in `android_app/`.

## Task 2: Web Assets & Visual Styling Setup
- [ ] Set up `assets/images/`, `assets/css/`, `assets/js/`.
- [ ] Copy icon `kuchbhi_icon.jpg` and screenshot `image.png` into `assets/images/`.
- [ ] Create `assets/css/style.css` with Apple Music design tokens (colors, blur cards, typography, glowing badges, animated equalizers).

## Task 3: Interactive Web Music Player & Synced Lyrics Engine
- [ ] Implement `assets/js/player.js` with Web Audio API / HTML5 Audio:
  - Play/Pause demo audio stream
  - Progress bar with seek
  - Real-time timestamped live lyrics (LRC highlight line-by-line as song plays)
  - Interactive Canvas audio visualizer sound waves

## Task 4: Apple Music Portfolio Landing Page (`index.html`)
- [ ] Navigation bar with blurred frosted glass, app logo, and direct download links.
- [ ] Hero section with Apple Music style headline, big CTA buttons, 3D phone mockup, and instant QR code for mobile scanning.
- [ ] Live Interactive Web Music Player demo section.
- [ ] Core Features Grid (Master HD 320k, Live Synced Lyrics, 24/7 Live Radio FM, Gestures, Car Android Support).
- [ ] Car Display & Android Auto dedicated showcase card.
- [ ] Creator & Engineer Section: "Crafted by Ranjeet Kumar" with architecture overview, tech stack, and social links.
- [ ] Footer with copyright, download mirrors, and version badges.

## Task 5: Verification & Browser Testing
- [ ] Verify website in browser or local HTTP server.
- [ ] Ensure all download links (`./downloads/kuchbhi.apk`, `./downloads/kuchbhi-car-display.apk`) resolve properly.
- [ ] Confirm mobile responsiveness, accessibility, and smooth animations.
