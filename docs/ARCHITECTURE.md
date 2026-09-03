# Current Architecture

This describes the repository as it exists now, not the intended finished design. The project is a Godot 4.6.2 application with one runtime-composed main scene and vendored GUT coverage for run state, generation, cards, and statistics.

## Runtime Shape

`scenes/main.tscn` contains a `Node2D` with `scripts/main.gd`. At startup, `main.gd` creates the camera, ball, level builder, HUD, menu, shop, and tutorial manager in code. `scenes/golf_ball.tscn` is the only substantive reusable scene; its script owns input and ball behavior. Course geometry and most UI are not authored scene trees.

```text
main.gd (composition and run state)
├─ golf_ball.gd (input, aiming, flat physics, discrete elevation, sink/reset)
│  ├─ trajectory_predictor.gd (deterministic prediction data)
│  └─ trajectory_renderer.gd (biome-aware dotted presentation)
├─ feedback_director.gd (shared shot, movement, terrain, cup, and transition VFX)
├─ audio_controller.gd (crossfaded themes/ambience, pooled physical SFX, and high-speed swoosh)
├─ hole_generator.gd ← biome_database.gd / biome_profile.gd
├─ level_builder.gd ← generated definitions / level_database.gd fallback / tutorial_database.gd
│  ├─ course_visual_factory.gd (shared primitive assets and decoration silhouettes)
│  ├─ gameplay_hazard.gd / moving_hazard.gd / elevation_ramp.gd
│  ├─ hazard_telegraph.gd (presentation-only moving-hazard timing/path cues)
│  └─ biome_ambience.gd (deterministic, non-interactive background motion)
├─ shop_manager.gd ← typed card_database.gd definitions
│  └─ shop_presentation.gd
├─ card_effect_resolver.gd ← persistent owned cards / active_card_curse.gd
├─ tutorial_manager.gd
├─ release_hud.gd / transition_presentation.gd
│  └─ ui/ (shared style, icons, backdrop, logo, action button, card, settings, title-attract, and history components)
├─ game_settings.gd / seed_codec.gd / hole_rating.gd
└─ run_stats.gd
```

Signals carry ball completion and hazard contacts from the ball/builder into `main.gd`, and shop/tutorial actions back into the run controller. `main.gd` is the orchestration hub and also owns substantial UI, rules, and effect state.

## Systems

- **Ball:** `RigidBody2D` with shape-cast continuous collision detection; supports mouse drag and configurable keyboard aim/power, proportional trajectory prediction, shot-power/control/roll-damping modifiers, stopped-frame detection, discrete `-1/0/1` elevation masks, ice damping, tee state, pause-safe live shots, and tweened sink/reset animations. Accepted shots are accounted on `shot_started`; `ball_stopped` is emitted only for a true moving-to-still transition. `main.gd` separately watches playable-surface containment and owns a cancellable three-second return-to-last-shot-origin failsafe that does not alter stroke accounting.
- **Feedback:** `FeedbackDirector` consumes semantic stopped, wall-impact, terrain, hazard, cup, and progression events. It owns transient primitive shapes, yellow stop confetti, a bounded sampled trail, clamped camera response, screen flashes, and named duration/intensity exports; it never changes collision or shot outcomes. `GameAudioController` crossfades eight original musical themes and six ambience beds, plays pooled physical event/UI cues through SFX, and permits only a bounded high-speed swoosh—there is no normal rolling loop.
- **Biomes:** Six `BiomeProfile` instances contain identifiers, display names, terrain/background palettes, decoration identifiers, hazard weights, generator difficulty values, and ambience identifiers. They are data consumed by shared systems, not separate gameplay implementations.
- **Levels:** `HoleGenerator` deterministically creates three holes per biome from a recorded or player-entered run seed. It validates and scores eight candidates for each hole, selects the highest candidate at or above the 72-point quality floor, and otherwise uses `LevelDatabase` as the authored fallback. Hole metadata carries indices, candidate/quality evidence, and the selected seed.
- **Construction:** `LevelBuilder` converts generated 100-pixel grid cells into palette-driven floor, oversized background surround, substantial collision bounds, elevation surfaces, ramps, bridges/overpasses, tee, cup/flag, static and moving hazards, telegraphs, decorations, and blockers at runtime. It exposes playable-surface containment and dynamically attenuates non-current elevation visuals. Reusable hazard nodes own deterministic collision behavior; `CourseVisualFactory` and bounded `BiomeAmbience` own presentation only.
- **Validation:** `LevelValidator` checks every field dereferenced by `LevelBuilder`: map/start/cup/par, arrays and palettes, cardinally continuous ordered main route, static/moving hazard contracts, branches, discrete surfaces, structures, and connected elevation transitions. Its elevation-aware occupancy pass rejects any overlap among static hazards, blockers, and moving-hazard footprints, plus any placement on the main route or tee/cup recovery cells. `main.gd` revalidates after card modifiers and before construction.
- **Run flow:** `main.gd` owns the explicit `MAIN_MENU`, `RUN_START`, `BIOME_INTRO`, `HOLE_PLAY`, `HOLE_RESULTS`, `SHOP`, `RUN_RESULTS`, and `ENDING` phases plus indices, seed, strokes, tokens, elapsed play time, owned-card bonuses, three-hole curse states, hazards, transitions, and runtime UI. `SeedCodec` owns player seed validation; `HoleRating` owns deterministic result stars/names; `GameSettings` persists and applies only wired options.
- **Shop:** Four unique seeded-random offers are drawn from eight implemented tradeoff cards. At most two distinct cards can be bought per production visit; unaffordable cards are disabled and Skip / Continue is available. The tutorial passes an explicit deterministic four-card pool and requires exactly the demonstrated minimum purchase before continuation. Production shops appear after biomes 1–5.
- **Card effects:** `CardDefinition` owns typed identity, price, disclosures, stacking text, separate `CardEffectSet` bonus/curse values, and curse duration. `CardEffectResolver` additively resolves persistent owned-card bonuses with currently active curses, then applies release safety clamps. `main.gd` decrements each `ActiveCardCurse` once when a hole resolves.
- **Tutorial:** Six deterministic tutorial holes teach aim/power/trajectory, normal grass/green, sand, water reset, blockers/moving hazards, the shop, a card benefit, its curse, and continuation. Only the shop lesson opens a shop. Completion is stored in `user://tutorial_complete.cfg`; first launch enters the tutorial, later launches enter a normal run.
- **Presentation UI:** `release_theme.tres` provides the Atkinson Hyperlegible UI face, Fredoka display variants, semantic colors, and button/panel states. `UIStyle` centralizes spacing, palette, category metadata, and compact display copy; `UIIcon` draws the original vector symbol set; `UIBackdrop`, `UILogo`, `UIActionButton`, and `UICard` provide reusable composition and motion. `TitleAttractMode` renders a side-effect-free deterministic generated-hole demo; `SettingsScreen` and `HoleHistorySelector` own their presentation/input. `ReleaseHUD`, `ShopPresentation`, `TransitionPresentation`, `ShopManager`, and `TutorialManager` consume those components without owning gameplay rules. Presentation reads typed card and run data but never mutates prices, effects, scoring, generation, or progression.
- **Telemetry:** `RunStats` tracks strokes, cards, hazards, resets, elapsed play time, and immutable per-hole history snapshots, then prints a summary when Hole 18 reaches run results. Its history API exposes only completed holes and the current hole; future holes remain locked.

## Current Content and Rules

- Eighteen generated production holes: Meadow, Desert, Autumn, Snow, Swamp, and Volcanic, with introductory/normal/hardest progression inside each biome.
- Mechanical hazards implemented through shared contracts: sand, water/lava reset areas, ice, direction pads, seeded circular bounce pads, blockers, pendulums, falling ice, and rotating fire rods. Rough grass is visual-only; legacy mechanical rough and red/out penalty tiles are rejected.
- Falling ice begins as a detector plus shadow, drops once when entered, enables collision only when landed, and remains until rebuild; landing on the ball and active pendulum/fire-rod contacts relay through the existing authoritative reset signal. Pausing freezes their level-root simulation.
- Cards implemented: Overdrive Driver, Rangefinder Lens, Sand Cleats, Heavy Core, Lucky Putter, Power Club, Coin Magnet, and Gust Guard.
- Starting currency and score-based rewards match the intended 2/3/2/1/0 structure, but the code calls currency “tokens.”
- Card bonuses stack for the run. Curses stack for the next three holes, are shown in the HUD/interstitials with remaining duration, and expire together after their third resolved hole. Power Club and Gust Guard add deterministic direction zones to a duplicate of the generated level before authoritative validation; Lucky Putter scales the next three cups.
- Hole results with one-to-five-star `HoleRating`, five biome shops, run results, a run grade, ending, and clean new-run reset are present. Par + 4 produces a one-star Stroke Limit outcome and safe advancement without a positive completion cue. Presentation uses primitive tweened feedback and original generated music/SFX; there is no adjusted speed score, GPU particle dependency, or randomized biome order.
- `R` preserves accepted current-hole strokes and elapsed time, resets transient hazards/audio coherently, and cannot refund score/reward cost. If the accepted-stroke count has reached par + 4, reset resolves the forced result instead.
- Opening the menu during a live shot freezes both the ball and level-root simulation. Resume restores the captured shot velocity and hazard cycle coherently without allowing behind-overlay collisions or state changes.

## Data Contracts

A normal level dictionary requires `map`, `start_cell`, `hole_cell`, `par`, `hazards`, and `obstacles`. Flat legacy definitions receive elevation-zero defaults. Generated definitions additionally carry static/moving hazards, ordered `main_route_cells`, routine `branches`, `elevation_cells`, `elevation_transitions`, `elevation_structures`, tee/start/cup elevation, biome/local/overall indices, seed/attempt/fallback, quality score/breakdown/candidate count, palettes, decorations, difficulty, ambience, and visual rough cells. Typed per-hazard fields cover direction, ice intensity, bounce seed/retention/cooldown, and moving timing/path data. Active card generation may add `card_hazard_count` and `card_cup_radius_scale`; tutorial definitions add lesson/step and optional deterministic-shop fields.

Level dictionaries remain flexible and untyped, so adding level keys requires coordinated changes across the generator, validator, builder/controller, and documentation. Cards no longer use dictionaries: `CardDefinition`, `CardEffectSet`, and `ActiveCardCurse` form the typed economy boundary.

## Technical Constraints and Risks

- `main.gd` is a large mixed-responsibility file; rule, UI, state, and transition changes can interact unexpectedly.
- Runtime-created UI uses shared presentation components and a common `release_theme.tres`. Containers and anchors own the primary layout; `TransitionPresentation` applies a compact 16:9 profile at 1366 pixels wide or 780 pixels high. Rendered scenarios cover 1920×1080, 1600×900, and 1280×720. Large/ultrawide coverage, 4:3, localization expansion, and platform-safe-area behavior must be reported from their dedicated scenarios rather than inferred.
- The explicit phase enum remains owned inside the large `main.gd`; booleans and a transition generation counter additionally guard asynchronous sink/reset work.
- Generated layouts validate a main route plus secondary branches and discrete transitions, but physical reachability, elevation readability, difficulty, and moving-hazard timing still require full human playtesting.
- Physics feel depends on engine settings and hard-coded tuning constants; changes require hands-on playtesting.
- The exported Windows executable and archive are build artifacts and may lag source. There is no Mac export preset despite the design target.

## Verification Surface

The project starts headlessly with:

```powershell
C:\Users\Rony\bin\godot4.cmd --headless --path . --quit
```

Manual regression coverage is listed in `MVP_TEST_CHECKLIST.md`. Player-facing completion must also satisfy `QUALITY_BAR.md` and be recorded in `PLAYTEST_LOG.md`.
