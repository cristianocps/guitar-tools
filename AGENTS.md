# AGENTS.md

Guidance for AI agents working on this repository.

## Project

Flutter mobile app (`music_tools`) with musician utilities for guitarists:
chromatic/string tuner, harmonic field visualizer, and metronome.
Target platforms: iOS and Android.

## Environment

- Toolchain is managed with **mise** and lives in **WSL (Ubuntu)**.
  Run Flutter/Dart/OpenSpec commands inside WSL, activating mise:
  ```bash
  export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
  eval "$(mise env -s bash)"
  ```
  Pinned runtimes: `flutter 3.19.0` (Dart 3.3.0), `node 21` (for the `openspec` CLI).
- Repo root IS the Flutter app root (`pubspec.yaml` at top level).

## Commands

- `flutter pub get` — install/resolve dependencies
- `flutter analyze` — static analysis (MUST pass clean)
- `flutter test` — run unit/widget tests (MUST pass)
- `flutter run` — run on a connected device/emulator

## Conventions

- State management: **Riverpod** (`flutter_riverpod`).
- Mic capture (raw 16-bit PCM): **`record`** (`AudioRecorder.startStream`).
- Metronome audio: **`audioplayers`** (`PlayerMode.lowLatency`), clicks synthesized in-memory.
- Code style (enforced by `analysis_options.yaml`):
  single quotes, trailing commas, `final` locals, declared return types,
  ordered directives, no `print`, `unawaited()` for fire-and-forget futures.
- Architecture:
  - `lib/core/theme`, `lib/core/design_system`
  - `lib/core/music_theory` (pure, unit-tested domain)
  - `lib/core/audio` (mic capture + YIN pitch detection)
  - `lib/core/metronome_engine` (clock-anchored scheduler)
  - `lib/features/{tuner,harmonic_field,metronome}`

## OpenSpec

Spec-driven changes live under `openspec/changes/`. Use the openspec CLI
(`openspec status`, `openspec instructions`) for workflow guidance.
