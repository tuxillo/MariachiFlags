# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
make build          # compile for iPhone 17 simulator
make run            # build + install + launch in simulator
make clean          # clean build artifacts
```

No test suite exists. Manual testing in the simulator is the only verification path.

The project is managed via a hand-written `project.pbxproj` — there is no Xcode GUI workflow. When adding new Swift source files or resources, edit `MariachiFlags.xcodeproj/project.pbxproj` directly using the existing UUID patterns already in that file.

## Architecture

The app is a single-screen SwiftUI game with a SceneKit 3D globe. There are no third-party dependencies.

**Game flow (phases in `GamePhase` enum):**
```
start → listening → [guessing → result] × N → finished
         ↑                                         |
         └─────────────── (play again) ────────────┘
```

- `GameViewModel` owns all state and drives phase transitions. It holds `GlobeScene` and `GlobeAnimator` as singletons created once at init.
- During `.listening`, music plays and the globe spins idle. When `AudioManager` finishes its fade sequence, it calls back into `GameViewModel.prepareFlag()`, which selects a country and triggers `GlobeAnimator.flyToCountry()`.
- `GlobeAnimator.onArrivedAtCountry` fires after the 2s fly-in animation completes, calling `GameViewModel.revealFlag()` which starts the countdown and transitions to `.guessing`.
- After an answer or timeout, `.result` shows for 2s, then `GlobeAnimator.zoomOut()` runs; its `onReturnedToIdle` callback raises the music volume and the cycle repeats.

**Globe rendering (`GlobeScene.swift`):**
- `SCNSphere` with NASA Blue Marble texture (`earth_texture` in xcassets).
- Country borders loaded from `borders.geojson` (180 features, each with a `name` property). Borders are rendered as triangle-strip quads (not `.line` primitives — those are always 1px). Each edge segment becomes two triangles with a configurable `halfWidth`.
- `highlightCountry(named:)` renders the target country's border in bright green on a separate node (`highlightNode`) at a slightly larger radius. Cleared by `clearHighlight()` on zoom-out.
- `GlobeScene.nameToGeoJSON` maps our country names to GeoJSON names where they differ (e.g. `"United States"` → `"United States of America"`).

**Globe animation (`GlobeAnimator.swift`):**
- Idle: sphere rotates via `SCNAction.repeatForever(rotateBy y: 2π)`, camera fixed.
- Fly-to: idle action removed, current `presentation.orientation` snapshotted, then `simdOrientation` set to a target quaternion (`simd_quatf`) so SceneKit SLERPs smoothly. Camera zooms in on the Z axis simultaneously via `SCNTransaction`.
- The camera never moves laterally — the sphere always rotates to bring the target country to face the camera.

**Key files:**
| File | Role |
|------|------|
| `GameViewModel.swift` | All game logic, phase transitions, timer |
| `GameView.swift` | SwiftUI views; `GameplayView` keeps `GlobeView` persistent across gameplay phases |
| `GlobeScene.swift` | SceneKit scene, border rendering, country highlighting |
| `GlobeAnimator.swift` | Globe animation state machine |
| `AudioManager.swift` | AVAudioPlayer with `.ambient` session; `startMusic(completion:)` plays then fades after a random delay |
| `CountryData.swift` | 197 `Country` structs with name, flag emoji, latitude, longitude |
| `HighScoreManager.swift` | Top-10 scores in UserDefaults via Codable |

**Globe view persistence:** `GameplayView` wraps `GlobeView` + phase overlays in a `ZStack`. The globe is always rendered; only the overlay (`ListeningOverlay`, `GuessingOverlay`, `ResultOverlay`) changes. This avoids SceneKit teardown/rebuild between phases.
