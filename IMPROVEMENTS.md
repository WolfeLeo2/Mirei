# Mirei Improvement Roadmap

This document tracks actionable improvements across architecture, UI/UX, data, performance, build size, testing, and developer experience. Check items as they’re completed and link PRs.

- Last updated: <add date>
- Owner: <add name>
- Conventions:
  - [ ] = not started, [~] = in progress, [x] = done
  - Link PRs/issues next to items as you complete them

## Top Priorities (Next 1–2 sprints)

- [x] Split `lib/screens/journal_writing.dart` into modular widgets + BLoC/service layers - _COMPLETED: Full BLoC migration with events for image/audio/mood selection, text input, recording, and save validation requiring title + (content OR attachments)_
- [x] Move Realm watching and audio controllers out of `lib/screens/journal_view.dart` into BLoC - _Created JournalViewBloc with proper separation_
- [ ] Enable Android release shrinking and ABI splits; publish AAB; analyze size report
- [ ] Introduce a design system: `AppSpacing`, `AppTextStyles`, `AppRadius`, `AppIcons`
- [x] Centralize audio in a `PlayerService` (wrap `just_audio`) + `RecorderService` (wrap `flutter_sound`) - _Lazy-initialized singletons, not in main.dart startup_
- [ ] Add Realm configuration (schema version, migrations, compaction, encryption key)
- [ ] Replace `.env` in `assets:` with a safer approach for release builds
- [ ] Add golden tests for `journal_view` and widget tests for mood selector/carousel/audio

---

## Architecture & State Management

- [ ] Adopt a consistent state management pattern (`flutter_bloc` already present)
- [x] Extract business logic from widgets into BLoC/ViewModels
  - [x] `journal_writing.dart` → `JournalWritingBloc`, `RecorderService`, `MediaStore` - _COMPLETED: Complete BLoC refactor with proper save validation (title + content/attachments), removed template system, restored waveform visualization in audio chips_
  - [x] `journal_view.dart` → `JournalViewBloc` (Realm watch, mood lookup, audio controllers) - _Moved all business logic to BLoC_
- [ ] Define repository interfaces and inject implementations
  - [ ] `MoodRepository`, `JournalRepository`, `MediaRepository`
- [ ] Create feature folders: `features/journal`, `features/mood`, `features/meditation`

## Realm Data Layer

- [ ] Centralize Realm configuration
  - [ ] Schema version and migration strategy
  - [ ] Compaction on launch
  - [ ] Encryption key from secure storage (optional)
- [ ] Add indexes on frequently queried fields (e.g., `createdAt` on mood/journal)
- [ ] Enforce UTC at persistence boundaries; convert to local for UI
  - [ ] Helpers: `nowUtc()`, `formatLocal(DateTime)`
- [ ] Freeze results passed to UI or map to DTOs to avoid live view hazards
- [ ] Consolidate writes through repository methods; remove direct Realm writes from widgets

## Testing & Quality

- [ ] Strengthen unit tests for serialization, repositories, and services
- [ ] Widget tests
  - [ ] Mood selector states and edge-to-edge scroll behavior
  - [ ] Image carousel (no images, 1 image, many images; tap-through)
  - [ ] Audio list (no audio, some audio; play/pause state)
  - [ ] FAB overlay interactions (tap targets, positioning)
- [ ] Golden tests for `journal_view` key states
- [ ] Integration test: create journal with images+audio, open `journal_view`, verify layout
- [ ] Add `analysis_options.yaml` with stricter rules and enable CI to fail on warnings

## UI/UX

- [ ] Material 3 (`useMaterial3: true`), dynamic color, and dark mode parity
- [ ] Design system
  - [ ] `AppSpacing` constants and usage
  - [ ] `AppTextStyles` for headings/body/captions
  - [ ] `AppRadius` for corners
- [ ] Accessibility
  - [ ] Semantics/tooltip for icon buttons (edit/share/delete)
  - [ ] Minimum 48×48 tap targets
  - [ ] Contrast checks on mood chip colors
- [ ] Scrolling and layout
  - [ ] Prefer Slivers for complex scrolls (e.g., `journal_view`)
  - [ ] Avoid nested `SingleChildScrollView`; ensure `RefreshIndicator` works reliably
- [ ] Carousel polish
  - [ ] Neighbor prefetch
  - [ ] Placeholder/error visuals
  - [ ] Optional pinch-to-zoom on tap-through
- [ ] Text scaling verification at 1.3–1.5× (no clipping)
- [ ] Journal writing keyboard toolbar (Notion-style) with formatting affordances and actions (bold, italic, bullets, checklist, quote, mic, photo, audio) — implement after base UI approval

## Audio & Media

- [x] `PlayerService` wrapping `just_audio` with exposed streams - _Singleton service with waveform controllers_
  - [ ] Handle audio focus and noisy (headphones removed)
  - [ ] Lifecycle pause/resume
- [x] `RecorderService` for `flutter_sound`; decouple from UI timing - _Full service with streams for recording state_
- [ ] Waveforms
  - [ ] Debounce updates
  - [ ] Wrap in `RepaintBoundary`
  - [ ] Offload heavy work to isolates when necessary
- [ ] Media paths
  - [ ] Persist relative paths; resolve via a `MediaStore` service
  - [ ] One directory policy, migration helpers

## Performance

- [ ] Reduce rebuilds
  - [ ] Add `const` constructors
  - [ ] Split heavy widgets into smaller ones
  - [ ] Use `BlocBuilder.buildWhen`/`Selector` to limit rebuild scope
- [ ] Wrap heavy paint regions (`WavePainter`, charts) in `RepaintBoundary`
- [ ] Offload expensive operations to isolates (`compute`) where appropriate
- [ ] Cache `File(path).exists()` and image dimensions; avoid redundant I/O in builds
- [ ] Unify animation durations/easings; stop controllers aggressively when off‑screen

## Build & Size (Android)

- [ ] Gradle (release): enable shrinking and resource stripping
  - [ ] `android/app/build.gradle.kts`
  - [ ] Build per-ABI or AAB and analyze size
  - [ ] Assets optimization
  - [ ] Dependency audit

## Navigation & Flow

- [ ] Adopt typed routing (e.g., `go_router`) with guarded routes for auth
- [ ] Centralize route definitions and deep link handling
- [ ] Replace ad‑hoc `Navigator.push/pop` with route intents

## Security & Privacy

- [ ] Avoid shipping secrets in `.env` (currently under `assets:`)
  - [ ] Use remote config/server for secrets; treat `.env` as dev only
- [ ] Realm encryption key stored in `flutter_secure_storage` (optional)
- [ ] Consent and privacy disclosures for analytics
- [ ] Redact PII in logs; switch to structured logging

## Observability

- [ ] Introduce `logger` with build‑mode gating
- [ ] Add Crashlytics/Analytics events for key flows
- [ ] In‑app non‑blocking error reporting (SnackBars with retry)

## Developer Experience & CI

- [ ] Add scripts: `format`, `analyze`, `test`, `build-release`
- [ ] GitHub Actions: run analyze/tests on PR; build AAB on tags
- [ ] Pre‑commit hooks for `dart format` + `dart fix --apply`

## File‑Specific Quick Wins

- [ ] `lib/screens/journal_writing.dart`: split into `Header`, `MoodSelector`, `ImageGrid`, `RecorderPanel`, `ContentEditor`, `SaveBar`
- [ ] `lib/screens/journal_view.dart`: move Realm watch + audio controllers to BLoC; ensure `_entrySub` disposed
- [ ] `lib/main.dart`: gate background init/logging by build mode; lazy‑init after first frame
- [ ] `pubspec.yaml`: remove duplicate assets; audit heavy packages
- [ ] `android/app/build.gradle.kts`: add release shrink/minify; release signing; ABI strategy

## How We’ll Maintain This File

- After merging each improvement, update the checkbox and add a PR link/date.
- If scope changes, add a brief note under the item.
- Keep the top priorities list to 5–8 items to maintain focus.

## Useful Commands

```bash
# Analyze size
flutter build appbundle --release --analyze-size

# Smallest sideloadable APKs per-ABI
flutter build apk --release --split-per-abi \
  --tree-shake-icons --obfuscate --split-debug-info=build/symbols

# Static checks
flutter clean && flutter pub get && flutter analyze && flutter test
```
