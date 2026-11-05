<div align="center">

  <img src="assets/images/kuchbhi_icon.jpg" alt="kuchbhi Music Logo" width="100" style="border-radius: 22px; box-shadow: 0 10px 25px rgba(252,60,68,0.4);" />

  # kuchbhi Music

  **An Apple Music-inspired Master HD audio streaming and download client for Android and Car Dashboards.**

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?logo=android&logoColor=white)](https://android.com)
  [![Android Auto](https://img.shields.io/badge/Android_Auto-Compatible-blue?logo=android-auto&logoColor=white)](https://android.com/auto)
  [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
  [![Tests](https://img.shields.io/badge/Tests-14%20Passed-brightgreen)](android_app/test/)
  [![Zero Ads](https://img.shields.io/badge/Ads-Zero%20Ads-red)](#features)

  [Download APK](#-downloads) • [Live Web Demo](https://ranjeetkumaer6120.github.io/kuchbhi/) • [Features](#-features) • [Build from Source](#-build-from-source) • [Car Stereo Setup](#-car-android-display-setup)

</div>

---

## 📖 Overview

**kuchbhi** is an open-source, lightweight, high-performance music client designed around the iconic **Apple Music dark frosted glass aesthetic**. Built from the ground up to solve common playback regressions found in typical third-party players:
- **No background pauses** when the screen is locked.
- **Full lockscreen & notification controls** (Previous, Play/Pause, Next).
- **Millisecond LRC synchronized karaoke lyrics** with tap-to-seek.
- **Dedicated 32-bit ARM build** for aftermarket Android car touchscreens (Hypersonic, Woodman, Droid, Allwinner) where standard 64-bit phone APKs fail to install.
- **100% Free**: Zero subscriptions, zero paywalls, zero ads, no account registration required.

---

## 📥 Downloads

| Edition | Target Device | Architecture | File Size | Direct Download |
|:---|:---|:---|:---|:---|
| **Phone & Tablet Edition** | Modern Android Smartphones | `arm64-v8a` (64-bit) | ~20.7 MB | [⬇️ Download kuchbhi.apk](downloads/kuchbhi.apk) |
| **Car Display Edition** | Aftermarket Car Touchscreen Stereos | `armeabi-v7a` (32-bit) | ~18.4 MB | [⬇️ Download Car Stereo APK](downloads/kuchbhi-car-display.apk) |

---

## ✨ Features

- **🎧 True 320kbps Master HD Streaming & Downloading**: High-bitrate CD Master audio without 30-second preview clips or compression loss.
- **🎤 Real-Time Synced Karaoke Lyrics**: Millisecond-precision LRC lyrics highlighting the sung line with smooth auto-scroll and interactive tap-to-seek.
- **🚗 Car Android Display & Android Auto Ready**: Pre-configured `MediaBrowserService` and horizontal landscape optimization for car touchscreens.
- **👆 Gesture Navigation**: Swipe left or right directly on the large album artwork with tactile haptic feedback to seamlessly switch tracks.
- **⚡ Instant 0ms Favorite Reactivity**: Spring-pop animated heart button that updates UI immediately with optimistic local caching.
- **✨ Smart Quality Deduplication**: Multi-source aggregator automatically picks the highest bitrate 320kbps stream with zero duplicate tracks.
- **🔒 Persistent Background Playback**: Foreground media service integration that never stops when your screen turns off or apps are minimized.
- **💾 Offline MP3 Storage**: Downloaded songs stored locally with proper ID3 metadata, album art, and artist tags.

---

## 📱 Screenshots

<div align="center">
  <img src="assets/images/app_screenshot.png" alt="kuchbhi App Interface Preview" width="300" style="border-radius: 20px; box-shadow: 0 20px 40px rgba(0,0,0,0.8);" />
</div>

---

## 🏗️ Architecture & Technology Stack

The project is structured with strict separation of concerns, test-driven models, and reactive state management:

```
kuchbhi/
├── android_app/               # Flutter Android mobile application codebase
│   ├── lib/
│   │   ├── models/            # Song, Playlist, and LRC Lyrics models
│   │   ├── screens/           # Player, Home, Search, and Library views
│   │   ├── services/          # ExoPlayer Just_Audio, API queries, Download manager
│   │   ├── theme/             # Apple Music OLED (#0A0A0C) & Frosted Glass tokens
│   │   └── widgets/           # Mini-player, animated favorite button, song tiles
│   └── test/                  # 14 Unit & Integration tests (all passing)
│
├── assets/                    # Showcase website styling, scripts, and imagery
│   ├── css/style.css          # Responsive Apple Dark UI stylesheet
│   └── js/player.js           # Interactive browser demo with live synced lyrics
│
├── downloads/                 # Pre-compiled production APK binaries
│   ├── kuchbhi.apk            # 64-bit Phone build
│   └── kuchbhi-car-display.apk# 32-bit Car Touchscreen build
│
├── index.html                 # Apple Music showcase landing page & portfolio
└── LICENSE                    # GNU General Public License v3.0
```

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x)
- **Audio Engine**: `just_audio` + native Android `ExoPlayer`
- **Background Service**: `audio_service` with foreground notification controls
- **Database**: `sqflite` (Offline-first favorites & download history)
- **Networking**: `http` with resilient retry pipelines and automatic mirror fallback

---

## 🛠️ Build from Source

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.24.0)
- Android Studio / Android SDK (API 34)
- Java 17

### Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/kuchbhi.git
   cd kuchbhi/android_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run unit tests**:
   ```bash
   flutter test
   ```

4. **Run on a connected Android phone**:
   ```bash
   flutter run
   ```

5. **Build Split Production APKs (Phone + Car)**:
   ```bash
   flutter build apk --release --split-per-abi
   ```
   Output APKs:
   - Phone (64-bit ARM): `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
   - Car Stereo (32-bit ARM): `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`

---

## 🚗 Car Android Display Setup

Most aftermarket Android touchscreen car stereos (Woodman, Hypersonic, Droid, Allwinner, Rockchip) run on **32-bit ARM (armeabi-v7a)** architecture. Standard phone APKs will fail with `"Parse Error: App not installed"`.

### Installation Steps for Car Touchscreens:
1. Download **`kuchbhi-car-display.apk`** (18.4 MB) onto your computer.
2. Copy the APK file to a USB pen drive.
3. Plug the pen drive into your car stereo's USB port.
4. Open the **File Manager** / **File Browser** app on your car dashboard screen.
5. Tap the APK file and select **Install** (allow unknown sources if prompted).
6. Enjoy full-screen landscape music playback with steering wheel Previous/Next button support!

---

## 🤝 Contributing

Contributions are warmly welcomed! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) guide before submitting pull requests.

1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Verify your changes pass all unit tests (`flutter test && flutter analyze`).
4. Commit your Changes (`git commit -m 'feat: add AmazingFeature'`).
5. Push to the Branch (`git push origin feature/AmazingFeature`).
6. Open a Pull Request.

---

## ⚖️ Legal & Educational Disclaimer

> [!NOTE]
> **kuchbhi** is developed as an open-source educational media client to demonstrate cross-platform Flutter audio engineering, foreground media services, and automotive touchscreen optimization.
>
> - The application does not host, store, or distribute any copyrighted music files on its servers.
> - All media playback resolves URLs through public, third-party internet endpoints.
> - The creators and contributors assume no liability for individual end-user usage.

---

## 📄 License

Distributed under the **GNU General Public License v3.0**. See [`LICENSE`](LICENSE) for more information.

---

<div align="center">
  <sub>Designed & Built by <strong>Ranjeet Kumar</strong></sub>
</div>
