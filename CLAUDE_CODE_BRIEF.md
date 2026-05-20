# Emulator Hub — Claude Code project brief

## What this is

A Flutter Android app that acts as a personal emulator hub:
- Browse a JSON-driven catalog of emulators
- Tap to open GitHub releases page or Play Store entry (no silent install — user installs manually)
- Push config profiles (bundled presets or user-imported files) to emulator config folders via Android's Storage Access Framework (SAF), with a root-optional direct-write path

No sync, no backend, no accounts. Fully self-contained.

---

## Repository structure

```
emulator_hub/
├── pubspec.yaml
├── assets/
│   ├── catalog.json                          ← bundled fallback catalog
│   └── configs/
│       ├── retroarch/generic/retroarch.cfg
│       ├── retroarch/generic/retroarch-core-options.cfg
│       └── ppsspp/generic/ppsspp.ini
└── lib/
    ├── main.dart
    ├── core/
    │   ├── models/emulator.dart              ← all data models
    │   ├── services/
    │   │   ├── catalog_service.dart          ← remote fetch → cache → bundled fallback
    │   │   ├── github_service.dart           ← latest release tag lookup
    │   │   ├── config_service.dart           ← SAF + root push logic
    │   │   └── providers.dart               ← all Riverpod providers
    │   └── utils/router.dart
    ├── features/
    │   ├── catalog/presentation/
    │   │   ├── screens/catalog_screen.dart
    │   │   └── widgets/emulator_card.dart
    │   ├── detail/presentation/
    │   │   └── screens/detail_screen.dart
    │   └── config/presentation/
    │       └── screens/config_screen.dart
    └── shared/theme/app_theme.dart
```

---

## Tech stack

| Concern | Package |
|---|---|
| State management | flutter_riverpod 2.x |
| Navigation | go_router 13.x |
| HTTP | dio 5.x |
| Image cache | cached_network_image |
| Local storage | shared_preferences, path_provider |
| File picking / SAF | file_picker 8.x |
| URL launching | url_launcher 6.x |
| Root detection | flutter_jailbreak_detection |

---

## Key design decisions already made

**Catalog loading priority:** remote GitHub raw URL → shared_prefs cache (6h TTL) → bundled `assets/catalog.json`. Never fails to show something.

**Config push — two paths:**
- No root: `file_picker` folder picker, SAF URI persisted per emulator in shared_preferences, reused on subsequent pushes without repicking
- Root detected: `Process.run('su', ['-c', 'cp ...'])` direct write, no picker

**Store linking:** Play Store uses `market://details?id=...` first, falls back to `https://play.google.com/...` via `url_launcher`. GitHub always opens the `/releases/latest` page.

**Theme:** dark-only. Primary accent `#3DCA8F` (beacon green), secondary `#EF9F27` (amber), background `#0A0A0A`, surface `#1C1C1C`, text `#D8D6CF`.

**Root detection:** `flutter_jailbreak_detection` — provider stub is in `providers.dart`, needs the actual import uncommented once the package resolves.

---

## What needs to be built / completed

The scaffold and all core logic exist. The following tasks remain:

### 1. Wire flutter_jailbreak_detection
In `lib/core/services/providers.dart`, uncomment the import and real call in `isRootedProvider`. The stub returns `false`.

### 2. Android manifest permissions
`android/app/src/main/AndroidManifest.xml` needs:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>
<!-- For file_picker SAF: -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
    tools:ignore="ScopedStorage"/>
<!-- For url_launcher Play Store intent: -->
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="market"/>
  </intent>
</queries>
```

### 3. Catalog JSON remote URL
In `lib/core/services/catalog_service.dart`, replace `YOUR_USERNAME` in `_kCatalogUrl` with the actual GitHub username and repo once the catalog repo is created.

### 4. Catalog screen — platform filter chips
Below the search bar in `catalog_screen.dart`, add a horizontal scrollable row of filter chips for platforms (pulled dynamically from the catalog: `multi`, `psp`, `ps1`, `gamecube`, `wii`, etc.). Tapping a chip sets `catalogFilterProvider`'s `platform` field. Tapping the active chip clears the filter.

### 5. Imported profiles — persistence across sessions
Currently imported profiles are created in memory in `config_service.dart` but not persisted to the provider layer. Add a `Hive` or `shared_preferences` backed notifier that stores imported profile metadata (id, name, emulator_id, importedBasePath) and surfaces them alongside bundled profiles in `config_screen.dart`.

### 6. Config screen — folder path display + re-pick
After a SAF folder is granted, show the resolved path (or a truncated version) in `config_screen.dart` with a "Change folder" button that calls `clearFolderUri()` then re-triggers the picker on the next push.

### 7. Error handling polish
- Network errors in `catalog_service.dart` and `github_service.dart` should surface a dismissible banner (not a full error state) so the UI remains usable with cached/bundled data.
- `config_service.dart` `_pushViaRoot` should catch `ProcessException` explicitly and surface a human-readable message.

### 8. Add more emulators to catalog.json
Current entries: RetroArch, PPSSPP, Dolphin, DuckStation.
Suggested additions (verify GitHub owners/repos before adding):
- Lemuroid (`lemuroid`) — `https://github.com/Swordfish90/Lemuroid`
- AetherSX2 / NetherSX2 (`nethersx2`) — sideload only, no Play Store
- Citra (`citra`) — `https://github.com/citra-emu/citra`
- melonDS (`melonds`) — `https://github.com/melonDS-emu/melonDS`
- Flycast (`flycast`) — `https://github.com/flyinghead/flycast`

### 9. Add device-specific config profiles
For RetroArch, add an `ayn_thor` profile alongside `generic`:
- Vulkan renderer, 1TB SD path hints, dual-AMOLED optimised shaders
For PPSSPP, add an `ayaneo_pocket_dmg` profile:
- 4:3 locked, OLED settings, vertical layout hints

---

## Running the project

```bash
flutter pub get
flutter run --release   # release mode recommended for emulation perf testing
```

Target: Android 8+ (API 26). Test on API 33+ for SAF behaviour.

---

## Out of scope (intentional)

- Silent APK install (requires device owner or ADB — not viable for distribution)
- Cloud sync of profiles
- In-app APK download manager (GitHub/Play Store handle this)
- iOS support
