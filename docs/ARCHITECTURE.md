# Current Architecture

This describes the repository as it exists now, not the intended finished design. The project is a Godot 4.6.2 application with one runtime-composed main scene and vendored GUT coverage for run state, generation, cards, and statistics.

## Runtime Shape

`scenes/main.tscn` contains a `Node2D` with `scripts/main.gd`. At startup, `main.gd` creates the camera, ball, level builder, HUD, menu, shop, and tutorial manager in code. `scenes/golf_ball.tscn` is the only substantive reusable scene; its script owns input and ball behavior. Course geometry and most UI are not authored scene trees.

```text
main.gd (composition and run state)
├─ golf_ball.gd (input, aiming, physics, sink/reset)
├─ feedback_director.gd (shared shot, movement, terrain, cup, and transition VFX)
├─ audio_controller.gd (generated ambience, pooled SFX, UI hooks, and rolling loop)
├─ hole_generator.gd ← biome_database.gd / biome_profile.gd
├─ level_builder.gd ← generated definitions / level_database.gd fallback / tutorial_database.gd
│  ├─ course_visual_factory.gd (shared primitive assets and decoration silhouettes)
│  └─ biome_ambience.gd (deterministic, non-interactive background motion)
├─ shop_manager.gd ← typed card_database.gd definitions
├─ card_effect_resolver.gd ← persistent owned cards / active_card_curse.gd
├─ tutorial_manager.gd
└─ run_stats.gd
```

Signals carry ball completion and hazard contacts from the ball/builder into `main.gd`, and shop/tutorial actions back into the run controller. `main.gd` is the orchestration hub and also owns substantial UI, rules, and effect state.

## Systems

- **Ball:** `RigidBody2D`; supports mouse drag and keyboard aim/power, an approximate dotted preview, shot-power/control/roll-damping modifiers, stopped-frame detection, and tweened sink/reset animations.
- **Feedback:** `FeedbackDirector` listens at existing ball, terrain, cup, shop, and progression boundaries. It owns primitive transient shapes, a bounded sampled trail, restrained camera offset/zoom, screen flashes, and named duration/intensity exports; it never changes collision or shot outcomes. `GameAudioController` routes a deterministic generated music bed, rolling loop, pooled event cues, and UI sounds through separate Music and SFX buses.
- **Biomes:** Six `BiomeProfile` instances contain identifiers, display names, terrain/background palettes, decoration identifiers, hazard weights, generator difficulty values, and ambience identifiers. They are data consumed by shared systems, not separate gameplay implementations.
- **Levels:** `HoleGenerator` deterministically creates three holes per biome from a recorded run seed. Hole metadata carries zero-based biome/local indices and one-based overall numbering. `LevelDatabase` remains the authored fallback source.
- **Construction:** `LevelBuilder` converts generated 100-pixel grid cells into palette-driven floor, background, collision bounds, hazards, cup, flag, decorations, and obstacles at runtime. `CourseVisualFactory` supplies shared primitive-vector silhouettes and non-color hazard patterns; `BiomeAmbience` supplies deterministic background-only effects. Biome profiles vary those systems through palette and decoration identifiers without changing collision geometry or gameplay rules.
- **Validation:** `LevelValidator` checks map shape, playable start/cup, grid connectivity, and grid-aligned hazards contained on playable cells. Generation retries at most four times and uses a validated authored fallback; `main.gd` revalidates before construction, so invalid normal-run data never reaches `LevelBuilder`.
- **Run flow:** `main.gd` owns the explicit `MAIN_MENU`, `RUN_START`, `BIOME_INTRO`, `HOLE_PLAY`, `HOLE_RESULTS`, `SHOP`, `RUN_RESULTS`, and `ENDING` phases plus indices, seed, strokes, tokens, elapsed play time, owned-card bonuses, three-hole curse states, hazards, transitions, and runtime UI.
- **Shop:** Four unique seeded-random offers are drawn from eight implemented tradeoff cards. At most two distinct cards can be bought per visit; unaffordable cards are disabled and Skip / Continue is always available. Shops appear after biomes 1–5.
- **Card effects:** `CardDefinition` owns typed identity, price, disclosures, stacking text, separate `CardEffectSet` bonus/curse values, and curse duration. `CardEffectResolver` additively resolves persistent owned-card bonuses with currently active curses, then applies release safety clamps. `main.gd` decrements each `ActiveCardCurse` once when a hole resolves.
- **Tutorial:** Ten tutorial levels gate completion on demonstrated events. Completion is stored in `user://tutorial_complete.cfg`; first launch enters the tutorial, later launches enter a normal run.
- **Telemetry:** `RunStats` tracks strokes, cards, hazards, resets, and elapsed play time, then prints a summary when Hole 18 reaches run results.

## Current Content and Rules

- Eighteen generated production holes: Meadow, Desert, Autumn, Snow, Swamp, and Volcanic, with introductory/normal/hardest progression inside each biome.
- Hazards implemented: rough, sand, water, out-of-bounds, and direction pads.
- Cards implemented: Overdrive Driver, Rangefinder Lens, Sand Cleats, Heavy Core, Lucky Putter, Power Club, Coin Magnet, and Gust Guard.
- Starting currency and score-based rewards match the intended 2/3/2/1/0 structure, but the code calls currency “tokens.”
- Card bonuses stack for the run. Curses stack for the next three holes, are shown in the HUD/interstitials with remaining duration, and expire together after their third resolved hole. Power Club and Gust Guard add deterministic direction zones to a duplicate of the generated level before authoritative validation; Lucky Putter scales the next three cups.
- Hole results, five biome shops, run results, a fixed placeholder grade, ending, and clean new-run reset are present. Par + 4 forces safe hole advancement. Presentation uses primitive tweened feedback and original synthesized WAV cues; there is no adjusted speed score, GPU particle dependency, or randomized biome order.
- `R` resets current-hole strokes and time without changing cumulative strokes already recorded, producing inconsistent per-hole and run accounting.

## Data Contracts

A normal level dictionary requires `map`, `start_cell`, `hole_cell`, `par`, `hazards`, and `obstacles`. Generated levels also carry biome, local-hole, overall-hole, seed, attempt/fallback, palette, decoration, difficulty, and ambience metadata. Active card generation may add `card_hazard_count` and `card_cup_radius_scale`. Hazards require `type`, `pos`, and `size`; direction hazards also require `direction`. Tutorial levels add lesson/step fields and may force tokens or cards.

Level dictionaries remain flexible and untyped, so adding level keys requires coordinated changes across the generator, validator, builder/controller, and documentation. Cards no longer use dictionaries: `CardDefinition`, `CardEffectSet`, and `ActiveCardCurse` form the typed economy boundary.

## Technical Constraints and Risks

- `main.gd` is a large mixed-responsibility file; rule, UI, state, and transition changes can interact unexpectedly.
- Runtime-created UI uses a shared `release_theme.tres` for typography, panels, and interaction states, but retains fixed pixel offsets designed around the 1920×1080 viewport and has no demonstrated responsive layout.
- The explicit phase enum remains owned inside the large `main.gd`; booleans and a transition generation counter additionally guard asynchronous sink/reset work.
- Generated layouts guarantee grid connectivity and keep a clear center route, but physical reachability, difficulty, and hazard readability still require full human playtesting.
- Physics feel depends on engine settings and hard-coded tuning constants; changes require hands-on playtesting.
- The exported Windows executable and archive are build artifacts and may lag source. There is no Mac export preset despite the design target.

## Verification Surface

The project starts headlessly with:

```powershell
C:\Users\Rony\bin\godot4.cmd --headless --path . --quit
```

Manual regression coverage is listed in `MVP_TEST_CHECKLIST.md`. Player-facing completion must also satisfy `QUALITY_BAR.md` and be recorded in `PLAYTEST_LOG.md`.
