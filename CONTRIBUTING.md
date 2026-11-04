# Contributing to kuchbhi

First off, thank you for considering contributing to **kuchbhi**! Community contributions are what make open-source software incredible.

---

## 📋 Code of Conduct

Please help maintain a respectful, inclusive, and collaborative environment. Be kind and constructive in issues, discussions, and pull requests.

---

## 🛠️ How Can You Contribute?

### 1. Reporting Bugs
- Before submitting an issue, search existing issues to see if it has already been reported.
- Provide a clear and descriptive title.
- Include your Android OS version, device model (e.g., Realme, OnePlus, or Car Head Unit model like Woodman/Hypersonic).
- Describe the exact steps to reproduce the issue.

### 2. Suggesting Features & Enhancements
- Open a feature request describing the use case and why it would benefit users.
- UI suggestions that adhere to the **Apple Music dark frosted glass theme** are especially appreciated.

### 3. Submitting Pull Requests
1. **Fork** the repository and clone it locally.
2. Create a new topic branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Navigate to the app directory:
   ```bash
   cd android_app
   ```
4. Make your code changes following clean architecture guidelines.
5. **Run tests & linter** to ensure no regressions:
   ```bash
   flutter analyze
   flutter test
   ```
6. Commit your changes with descriptive commit messages following the Conventional Commits specification (e.g. `feat: add sleep timer`, `fix: handle car audio focus`).
7. Push to your fork and submit a **Pull Request** against the `main` branch.

---

## 🎨 UI Guidelines

- **Theme Palette**:
  - Background: Pitch Black / Dark OLED (`#0A0A0C` / `#121216`)
  - Accent: Apple Red (`#FC3C44`) & Neon Pink (`#FF6482`)
  - Frosted Glass: `BackdropFilter` with blur (`sigmaX: 20`, `sigmaY: 20`) and translucent borders (`rgba(255, 255, 255, 0.08)`).
- **Audio Service**:
  - Never break foreground persistence (`stopWithTask: false`).
  - Always maintain lockscreen action handlers (Play/Pause, Seek, SkipNext, SkipPrevious).
- **Automotive Safety**:
  - Keep touch targets generous (minimum 48x48 dp) for car touchscreen safety.
  - Never introduce intrusive fullscreen popups or distracting banners.

---

## 📄 License Notice

By contributing to kuchbhi, you agree that your contributions will be licensed under its **GNU General Public License v3.0 (GPL-3.0)**.
