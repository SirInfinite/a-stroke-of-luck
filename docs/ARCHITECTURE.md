# Current Architecture

This describes the repository as it exists now, not the intended finished design. The project is a Godot 4.6.2 application with one runtime-composed main scene and no automated test suite.

## Runtime Shape

`scenes/main.tscn` contains a `Node2D` with `scripts/main.gd`. At startup, `main.gd` creates the camera, ball, level builder, HUD, menu, shop, and tutorial manager in code. `scenes/golf_ball.tscn` is the only substantive reusable scene; its script owns input and ball behavior. Course geometry and most UI are not authored scene trees.

```text
main.gd (composition and run state)
├─ golf_ball.gd (input, aiming, physics, sink/reset)
├─ level_builder.gd ← level_database.gd / tutorial_database.gd
├─ shop_manager.gd ← card_database.gd
├─ tutorial_manager.gd
└─ run_stats.gd
```

Signals carry ball completion and hazard contacts from the ball/builder into `main.gd`, and shop/tutorial actions back into the run controller. `main.gd` is the orchestration hub and also owns substantial UI, rules, and effect state.

## Systems

- **Ball:** `RigidBody2D`; supports mouse drag and keyboard aim/power, an approximate dotted preview, impulse modifiers, stopped-frame detection, and tweened sink/reset animations.
- **Levels:** `LevelDatabase` returns five dictionary-defined 10×6 authored grids. Any non-space character is playable. Start/cup cells, par, rectangular hazards, and static wall rectangles are data.
- **Construction:** `LevelBuilder` converts 100-pixel grid cells into floor, collision bounds, hazards, cup, flag, and obstacles at runtime. Visuals are primitive polygons and lines.
- **Validation:** `LevelValidator` checks map shape, playable start/cup, grid connectivity, and grid-aligned hazards contained on playable cells. Its boolean result is currently logged but does not block building.
- **Run flow:** `main.gd` owns level index, strokes, tokens, elapsed hole time, cumulative card modifiers, hazards, transitions, and status UI.
- **Shop:** Three deterministic rotating offers are drawn from five implemented cards. Multiple affordable cards can be bought. The shop currently appears after every non-final hole.
- **Tutorial:** Ten tutorial levels gate completion on demonstrated events. Completion is stored in `user://tutorial_complete.cfg`; first launch enters the tutorial, later launches enter a normal run.
- **Telemetry:** `RunStats` tracks strokes, cards, hazards, resets, and elapsed time, then prints a summary to the console after Hole 5.

## Current Content and Rules

- Five normal authored holes with pars 2, 3, 4, 4, and 5.
- Hazards implemented: rough, sand, water, out-of-bounds, and direction pads.
- Cards implemented: Overdrive Driver, Rangefinder Lens, Sand Cleats, Heavy Core, and Lucky Putter. These differ from the 15-item intended pool.
- Starting currency and score-based rewards match the intended 2/3/2/1/0 structure, but the code calls currency “tokens.”
- Card effects stack for the entire run; no injected next-hole obstacle system exists.
- The last hole stops after printing statistics. There are no hole-results or run-results screens, enforced maximum strokes, adjusted speed score, grades, audio, particles, procedural generation, or randomized hole order.
- `R` resets current-hole strokes and time without changing cumulative strokes already recorded, producing inconsistent per-hole and run accounting.

## Data Contracts

A normal level dictionary requires `map`, `start_cell`, `hole_cell`, `par`, `hazards`, and `obstacles`. Hazards require `type`, `pos`, and `size`; direction hazards also require `direction`. Tutorial levels add lesson/step fields and may force tokens, cards, or purchase gating. Cards contain `name`, `cost`, display strings, and an `effects` dictionary interpreted centrally by `main.gd`.

These dictionaries are flexible but untyped. Adding keys requires coordinated changes across the database, validator, builder/controller, and documentation.

## Technical Constraints and Risks

- `main.gd` is a large mixed-responsibility file; rule, UI, state, and transition changes can interact unexpectedly.
- Runtime-created UI uses fixed pixel offsets designed around the 1920×1080 viewport and has no demonstrated responsive layout.
- There is no explicit run-state machine; booleans such as `loading_next_level` and `hazard_resetting` guard asynchronous transitions.
- Level validation warns but allows invalid content to continue.
- Physics feel depends on engine settings and hard-coded tuning constants; changes require hands-on playtesting.
- The exported Windows executable and archive are build artifacts and may lag source. There is no Mac export preset despite the design target.

## Verification Surface

The project starts headlessly with:

```powershell
C:\Users\Rony\bin\godot4.cmd --headless --path . --quit
```

Manual regression coverage is listed in `MVP_TEST_CHECKLIST.md`. Player-facing completion must also satisfy `QUALITY_BAR.md` and be recorded in `PLAYTEST_LOG.md`.
