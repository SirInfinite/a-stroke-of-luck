# Hazard gameplay checkpoint — 2026-09-10

> Historical version 1 evidence below. The same catalog has now been refined to version 2; use [GAMEPLAY_DIRECTION_REVIEW.md](GAMEPLAY_DIRECTION_REVIEW.md) for current access, density, difficulty behavior, visual hooks and results. The old three-encounter counts and timing-only F8 description describe the earlier snapshot.

**Status: nine playable development experiments; owner feel approval pending.** This is the first checkpoint requested by the owner, not the production generator rollout. Chainlink #10 owns the work; #20 remains the related balance concern. One implementation agent worked on this slice. No commit, export, issue closure, or release approval occurred.

The approved target is risky, timing-heavy golf with purposeful hazards, substantial geometry changes, and recoverable mistakes. Rough remains visual only. The approximate two-thirds execution emphasis does not change rewards. The normal eighteen-hole/six-biome run, cards, curses, accounting, straight player preview, AI rules, and art/audio family retain their existing contracts.

## Play the checkpoint

From the project directory:

```powershell
godot4 --path . res://tests/procgen_inspector.tscn -- --benchmarks --benchmark=A1 --difficulty=normal
```

The existing inspector opens the real Main/GolfBall game with a temporary practice strip. F6/F7 move between the nine fixtures; F8 cycles Easy/Normal/Hard **pendulum timing only**; F9 starts a fresh practice attempt; H opens/closes the course brief. The normal mouse drag and arrow-key/Space controls shoot. Tab opens the existing overview. R remains an ordinary reset and keeps strokes/time. The strip starts compact so it does not obscure the course. The practice host repeats the selected fixture in Main's normal slots; F6/F7 are the intended way to change experiments, and F9 clears practice rewards/cards as well as strokes. It is not a separate release mode.

Fixture IDs select authored experiments. Their seeds are diagnostic identifiers, not production Run Setup seeds: entering 910101 in normal Run Setup does **not** select A1. To play a specific experiment, change `--benchmark=A1` in the command.

| ID / seed | Substantial geometry difference | Choice and consequence |
|---|---|---|
| A1 / 910101, Bell Bank | Compact elbow; upper bank shoulder; broad outside bay; south-facing cup | Set up above water and bank, or approach the swing and time a downward crossing. Water/swing contact costs the normal reset penalty. The outside bay and clear elbow permit another approach. |
| A2 / 910102, Long Fuse | Longer inlet, shallow wide upper chamber, additional exit bend, east-facing cup | Carry into a rail bank or stop before the swing. Losing too much speed costs a setup shot. The exit sand offers a stopping point before the final approach. |
| A3 / 910103, Hook Return | U-shaped return, deep outside bay, reversed cup approach | Bank into position, cross the swing, then double back. An overlong landing remains recoverable; return-lane sand changes the next shot. |
| B1 / 910201, Crosswind Fork | Early fork; upper bypass; straight shortcut; downward dead end | Counter the downward force or take the long sheltered route. A slow shortcut entry feeds a pocket; shoot along its clear shoulder to escape. Landing water still penalizes. |
| B2 / 910202, Offset Sluice | Wider force band; deeper pocket; offset dogleg reconnects farther down | A correctly positioned full-power shot can ride the force into the cup. A weaker entry reaches the pocket. An angled exit can recover directly toward the green; firing straight against the force can return to the pocket. |
| B3 / 910203, Late Fork | Longer inlet; southern bypass; hooked upper pocket; changed landing side | Counter an upward force after the late fork. The pocket changes the escape angle. Its right shoulder reconnects without requiring a reset. |
| C1 / 910301, Return Under | Compact outer return; raised shortcut; lower crossing beneath two deck cells | Use the exposed bridge swing, turn through the clear underpass, or follow the outer loop. The lower route avoids the upper threat but takes different turns. |
| C2 / 910302, Low Bow | Recessed shortcut with a side expansion; no covered crossing | Control the downward force on the lower terrace or remain on the outer loop. A sand bay catches an off-angle lower entry; both ends have ramps. |
| C3 / 910303, Offset Weave | Longer outer route, later crossing, additional return bend | The shifted bridge, crossing and return change setup and landing positions. Its lower crossing is clear; its upper swing must be observed before release. |

All variants preserve alternating square cells. Their exact signatures differ after rotation/reflection normalization. These are three geometry variants of each concept, not nine palette/hazard shuffles. The host reuses the existing builder, generated-course validator and native hazard classes; no replacement generator or physics engine was introduced.

## Current-game baseline

The final baseline is **6 seeds × 18 holes × 3 difficulties = 324 holes**, without active curses. Seeds are 7919, 15838, 23757, 31676, 39595, and 47514. The sample covers every biome, its three local positions, and the early/middle/late run thirds. Eight candidates were evaluated per hole: 2,592 candidates, zero static rejections, zero below-floor rejections, zero retries/fallbacks, and zero invalid selected holes. This establishes sampled validity, not golf feasibility or enjoyment.

An independent pressure metric groups a connected hazard formation by `cluster_id`, and counts each blocker/mover separately. Sand catches and ice are included in this broad encounter count; the type histogram keeps these distinct from reset threats. A moving footprint represents its swept area, not simultaneous occupancy. Corridor coverage is the union of footprint cells intersecting declared corridor cells **on the same elevation**, divided by corridor cells. It measures potential contact area, not hit probability or an unavoidable threat. The old 100% route-proximity result means every object is near some corridor; it does not mean every shot encounters danger.

| Difficulty (108 holes each) | Mean independent encounters | Mean corridor coverage | Movers per hole | Unique exact structures |
|---|---:|---:|---:|---:|
| Easy | 2.49 | 4.47% | 0.30 | 19 |
| Normal | 4.03 | 10.72% | 0.43 | 38 |
| Hard | 5.82 | 11.15% | 0.62 | 34 |

Early/middle/late mean encounters are **3.29 / 4.19 / 4.86**, but corridor coverage is **8.8% / 8.7% / 8.8%**. The course grows along with object count. Movers increase from **0.23 / 0.48 / 0.63** per hole. By biome, encounter means are Meadow 2.96, Desert 3.61, Autumn 4.19, Snow 4.20, Swamp 4.65, Volcanic 5.07. Natural generation produced **zero directional-force tiles** in this uncursed sample, despite their presence in general biome weight tables; the current grammar uses them for curse placements. Biome weight metadata alone is not evidence of biome gameplay.

Map bounds range from 9–23 cells wide and 3–18 high, averaging 16.44 × 11.56. Playable surfaces average 112.08 cells. Safe cardinal routes range from 1,400–4,100 px and average 2,458.95 px; these distances are not simulated shot counts. The declared ordinary corridors are 500 px on Easy and 300 px on Normal/Hard. Reserved clear setup/recovery cells average 32.89, alternatives 0.26, and dead ends 0.065 per hole. There are 31 elevated holes (9.57%), no underpasses in this sample, and 137 holes with movers (42.28%).

There are **73 distinct exact structural signatures across 324 holes** (251 occurrences repeat an earlier signature across the corpus). Exact signatures include cells/layers, tee/cup and ramp connections, normalize all eight grid symmetries and exclude hazard identities/colors. A separate approximate within-run test finds **118 repeated occurrences / 324 holes** with at least 90% cell/layer Jaccard similarity and tee/cup positions within one cell under some symmetry. That near-duplicate test does not compare ramp edges or rescale lengths; it is a diagnostic, not a definition of identical play.

Measured generation time, excluding the additional metrics pass, averages **50.44 ms**, with p95 **96.98 ms** and maximum **132.39 ms** on this Windows machine. Other local verification processes were running during parts of collection; treat these as observed timings, not isolated performance benchmarks. Per-hole dimensions, corridors, footprints, motif sequences, signatures, candidates, recovery areas and layer usage are in `baseline.json`; aggregates are in `summary.json`.

### What explains easy full-power play

**Measured implementation facts:** ordinary wall restitution is 0.35; a full-power normal-ground shot travels about 1,201 px in the isolated test. The current grammar constructs five base route ideas with shared stretch, rotations/reflections and bounded branches. Static validation reserves a route outside complete swept mover footprints, so generated hazards cannot force the only safe route to require timing. `GenerationChallenge` already centralizes difficulty, biome position, run stage and bounded curse count; rollout should evolve it rather than add a competing profile.

**Visual judgments:** all eighteen Normal holes at seed 7919 were inspected, along with representative Easy/Hard frames. Meadow 1–3 repeat long guarded lanes, with a similarly placed dead-end branch on 2–3. Several guards can be bypassed by staying along the same shoulder. Many bends open into large landing rooms. Snow introduces room/neck expansion and ice, but an extended glide often offers no visibly different payoff. Lower/raised shortcuts frequently bypass several outer guards at once. These observations support the owner's complaints about similar choices and weak combinations.

**Actual-shot diagnostics:** nine baseline holes (positions 3, 10, 18 on each difficulty, seed 7919) and all nine Normal prototypes were played using four bounded strategies. All shots used Main/GolfBall, normal penalties and the normal par + 4 limit. A forced result's sink animation is not counted as completing the cup.

| Strategy | Baseline completed | Prototypes completed | Prototype strokes, successful holes only |
|---|---:|---:|---:|
| Aim at cup, full power | 1/9 | 1/9 | 3.00 |
| Aim at cup, search 20 powers | 1/9 | 1/9 | 3.00 |
| Search angles in 5° increments, always full power, no deliberate wait | 8/9 | 9/9 | 2.56 |
| Existing strongest AI planner, route/power/timing search | 9/9 | 9/9 | 2.44 |

The stronger full-power comparison prevents a misleading claim based on the weak direct-to-cup strategy. It also limits the conclusion: **the prototypes do not yet demonstrate a meaningful whole-hole power/timing advantage over careful full-power angle selection.** They are interaction experiments for owner evaluation. They do not satisfy the eventual density/progression rollout target. The angle-search strategy knows the current course and phase through query simulation; it is much stronger than blind human full-power play. The AI uses a different candidate budget and deterministic execution error, so these are not controlled skill studies. The baseline and authored catalog are different courses, not a matched before/after generator corpus.

The hypotheses for rollout are: shorten broad unguarded sightlines, place a second consequence at likely rebound/landing positions, and make precise landings or timing save real turns relative to a broad safe bypass. Do not change power rewards, detect 100% shots, or weaken normal walls to manufacture these results. Those generator changes await owner feedback on the benchmark.

## Verified interactions and limitations

The catalog has exactly three independent encounter groups per hole: a reset formation, a sand catch, and either a mover or directional formation. Five of nine holes have a pendulum; three have elevation; two have an underpass. The catalog averages 114.11 playable surfaces and 2.86 encounters per 100 surfaces, versus 3.87 in the entire baseline. Its ground-corridor coverage is 7.4%; the separate `layered_routes` metrics describe bridge/lower threats excluded from that ground-only comparison. This is **not a claimed density increase**. Nine hand-selected unique structures are also not evidence of production procedural diversity.

- Three actual bank witnesses passed without reset, following query-only search from explicitly arranged setup positions. A1: raw cell (2,-1), -35° from right, 80%; A2: (4,-1), +5°, 80%; A3: (7,0), +110°, 100%. Raw coordinates are relative to the tee, with y increasing downward. The shots visibly/physically rebound once; predictions indicate approximately 405/766/531 px of route progress. These are setup-to-landing witnesses, not one-shot finishes from the tee. Long banks lose substantial speed; the brief now says so.
- Eighty actual timing shots tested five swing situations at sixteen release offsets, 0.2 seconds apart over the Normal 3.2-second period. Identical downward 65% shots incurred reset penalties at 4/16 offsets for each A hole and 8/16 for each bridge. The sampled pass/fail runs imply useful windows, not exact continuous window boundaries. No long waits or multi-gate sequence were introduced in this checkpoint.
- Both underpass shots crossed from arranged lower approaches, remained on elevation 0, and cleared the bridge without reset. The covered stretch is 200 px, with a 100 px passage and flared approaches. Native boundary walls sit outside the playable cells; a 24 px ball has about 76 px of center clearance through the straight passage. There are no lower-layer hazards under the bridge. Actual bridge shots traverse ramps 0→1→0; C2 traverses 0→-1→0.
- B1/B2/B3 weak 38% entries reach actual pockets. A following angled/shoulder shot leaves each pocket without a reset or free stroke. B2's recovery can reach the cup. An initial straight-against-force probe failed to escape B2/B3: it was a poor shot, not a disconnected layout. The successful recoveries use the real stopped position, without teleporting between entry and escape.
- B2's arranged setup at (3,0), rightward 100% shot reaches the cup through the force band. This success is retained deliberately. The force is continuous physical acceleration, not a special power detector.
- The isolated 500 px ice segment begins 450 px beyond the tee. At 35% power the ball stops before it in 3.73 s. At 40%, normal ground travels 478.45 px and stops in 3.83 s; the matching ice case travels 579.87 px and stops in 8.62 s. At full power the travel changes from 1,200.92 to 1,575.85 px. The extra wait and nonlinear response near entry are measured; whether these explain the owner's dislike is a hypothesis. No extra ice was placed in the playable catalog.
- One small production compatibility bug was fixed: `LevelValidator.cell_elevations()` returned an untyped conditional array for authored flat courses under Godot 4.6.2. It now constructs `Array[int]` explicitly. The regression verifies flat geometry, hand-authored rotation/mirror equivalence, and layer/endpoint differences. Generated-course rules are unchanged.

Remaining human concerns: whether banks are worth the setup; whether the clear bypasses are too generous; whether force-pocket escapes are discoverable; whether bridge entrances read as traversable beneath the current art; and whether timing feels tense rather than tedious. The current upper rails can visually dominate a lower entrance even though its collision passage works. Final art remains the art thread's responsibility.

## Proposed biome direction — awaiting selection

Use three shared building blocks: directional force, timed collision, and surface/contact response. Keep existing classes and shared shot simulation. The proposed additions are a bounded **pulsed directional field** and an optional **deterministic directional spring**, not six hazard frameworks. Existing random redirect pads stay optional. Exact new tuning and freeze/thaw behavior are not approved or implemented by this checkpoint.

| Biome | Proposed local gameplay | Introduction → combination → culmination |
|---|---|---|
| Meadow | Pendulum/water decisions; optional visible spring direction | Observe a swing → bank around water → spring landing plus swing timing |
| Desert | Constant gust lanes, sheltered shoulders, sand catches and banks | Counter a gust → choose a pocket/shortcut → change angle across a gust and guarded landing |
| Autumn | Rotating woodland gate using shared mover timing; leaf force feeds loops | Read a gate → force into a loop → choose bank/timing routes across the return |
| Snow | Short slippery runs with clear normal-ground/sand catches; existing triggered falling ice with a bypass | Learn one short glide → stop before a visible drop shadow → combine glide, safe catch and alternate approach; defer freeze/thaw until the ice feel is approved |
| Swamp | Predictable currents on winding routes; timed gate at a visible exit | Follow a current → choose its exit → change route around a gate; never opposing fields that sustain an endless cycle |
| Volcanic | Pulsed directional vents, existing rotating threat and lava pressure | Read a pulse → ride it toward a landing → combine already learned timing and angle skills with bounded recovery |

Choose geometry and consequence first. Resolve all scaling once in `GenerationChallenge`, retain the three-hole arc, and cap combined curse/Hard/late-run pressure. Candidate evaluation needs distinct geometric validity, plausible shot feasibility and joint timing feasibility. Safe timed windows may eventually replace some all-state swept-footprint avoidance, but only with a bounded joint validator and known-good fallback. None of these prospective rules weakens current validation in this checkpoint.

### Native hazard contracts exercised here

| Hazard | Trigger and bounded effect | Tell, safe response and reset |
|---|---|---|
| Pendulum | Same-layer ball contact; one normal reset penalty. Circular 44 px collider; radii 56/100/120 px; swing ±0.9 rad; periods Easy 3.8 / Normal 3.2 / Hard 2.7 s; initial phase 0 | Native moving ball and sweep tell. Observe on clear ground, release as the collision path clears, or take the bypass. Pause freezes elapsed time; manual/competitor reset restores authored phase. No radius/speed stacking in the catalog. |
| Direction | While overlapping on the active layer, native 950-unit directional force per physics tick, scaled by the existing personal modifier; each tile is 100×100 px | Arrow gives direction. Angle/speed determine exposure; leave through a clear shoulder. Exit/reset clears Main's active force sources. Adjacent tiles can overlap the ball near seams, as in the current shared simulation; no new intensity multiplier is implied. |
| Sand | On entry, native 0.35 velocity scale and damping 12 while inside, with existing personal terrain modifiers | Visible sand catch. Can be used to stop before a difficult approach or avoided for distance. Exit/reset restores the normal surface state. 1–2 connected cells in the catalog. |
| Water | Same-layer contact; normal sink/reset with one additional penalty stroke | Native water footprint; choose a shoulder/bank/alternate lane. Attempt reset clears forces/surface effects. 1–2 connected cells in the catalog. It never receives the OOB refund exception. |

## Art and simulation handoff

`tests/hazard_checkpoint_review.gd` publishes `art_contract.json` with JSON arrays for vectors, no private engine handles. Each sample contains the active layer, ball radius, cell-to-world origin, all surfaces/layers, ramps, structures, explicit layered routes, static hazard definitions/footprints, and mover position/origin/initial phase/elapsed time/current cycle fraction/period/collider/sweep. This is sampled data, not a second live state owner.

Use the following existing contracts for live presentation:

| Meaning | Authoritative data/event |
|---|---|
| Ball's current layer | `GolfBall.current_elevation`; `elevation_changed(previous, next, position)` |
| Upper/lower normal course surfaces | `elevation_cells: [{cell, levels}]`; use the same biome palette at each logical height |
| Real connections between layers | `elevation_transitions`, including from/to cells, from/to elevations and width; presentation must not create a connection at an ordinary screen-space crossing |
| Covered surfaces and occlusion | `elevation_structures` bridge/overpass/lower-area cells; overpass `lower_elevation` and `tunnel_length`; `LevelBuilder.set_active_elevation()` controls native emphasis |
| Exposed shadow/boundary edges | Adjacent surface membership **on the same layer**, excluding ramp-connected edges, using the same rule as `LevelBuilder._create_bounds()`; derive a presentation offset without moving physics |
| Significant hazard purpose | `placement_role` and cluster identity; footprints from `LevelValidator._definition_surfaces()` are conservative cell reservations, not precise visible collision shapes |
| Moving threat state | `MovingHazard` origin, elapsed, period, phase, actual position/rotation, active flag, collision shape; `get_telegraph_data()`, `telegraph_started`, `active_state_changed` |
| Contact/shot payoff | Existing `shot_started`, `shot_finished`, `wall_impact`, `hazard_triggered`, `body_hit`, and Main's authoritative sink/reset path |

Do not put hidden threats inside covered cells. Do not use visual z-offsets as logical elevation. `AICourseModel` receives defensive course snapshots and a collision-layer-zero query body; tests verify forecast calls cannot move the real ball, advance a live mover, or change the fixture. `LevelBuilder.reset_for_competitor()` restores native transient state. Player preview remains the documented straight, unobstructed-distance guide; these development diagnostics do not draw an AI ricochet forecast to the player.

## Reference evidence

The principal references were inspected through their official store pages and six downloaded official screenshots (indices 0, 2, 4 for each). A browser integration was unavailable because its trusted-module bootstrap failed; no footage playback is claimed. Screenshot URLs and local filenames are recorded in the evidence folder. No reference assets or proprietary course layouts were imported into the game.

- **Grandpa Golf is the identity reference.** Screenshot 0 shows a narrow recessed launch into a larger bordered chamber; 2 shows stepped landing regions and large water decisions; 4 pairs a strong slope/landing silhouette with conspicuous shot payoff and an item row. The concrete lesson is to make one golf situation and its build payoff legible together, with geometry that changes the next action. Screenshots do not establish exact upgrade rules or physics. [Official page](https://store.steampowered.com/app/4445020/Grandpa_Golf/).
- **Golf With Your Friends informs physical situations.** Screenshot 0 shows a themed vertical loop structure; 2 a forest windmill spanning a raised lane beside lower platforms; 4 a narrow exposed desert approach beside lower course structures. The lesson is for the theme to change a course situation, rather than only its colors. These are spatial observations, not claims about their collision/timing rules, and do not authorize 3D physics here. [Official page](https://store.steampowered.com/app/431240/Golf_With_Your_Friends/).
- **Into the Breach informs communication only.** Its official screenshot shows explicit attack-direction arrows, marked targets and a stated terrain consequence. The developers' postmortem discusses threat iconography and visible intended attacks. Apply this to arrow direction, swept collision regions, observation space and understandable combined consequences; retain real-time golf execution. [Official screenshot](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/590380/ss_6113590509c195f98fa64cd738df534762e0c358.1920x1080.jpg?t=1755610784), [developer GDC postmortem, especially slides 29–30](https://media.gdcvault.com/gdc2019/presentations/Into%20the%20Breach%20Postmortem%20Final.pdf).

## Evidence and verification

Evidence lives under `user://hazard_checkpoint_20260910` (Windows: `%APPDATA%\Godot\app_userdata\A Stroke Of Luck\hazard_checkpoint_20260910`). `baseline_source/` preserves the initial scripts/tests/docs snapshot and `baseline_unstaged.patch` the initial dirty worktree diff, since HEAD alone does not identify this build. HEAD at capture was `e2459b3495f57689a5ec493cb71e4e66816a3029`; branch `release/7-hour-ship` already contained extensive uncommitted work.

| Check | Completed evidence |
|---|---|
| Focused GUT | Six tests / 209 assertions: 27 fixture-tier validations, deterministic uniqueness, flat/symmetry/endpoint-layer regression, physical query isolation and competitor reset; included in the complete suite |
| Baseline | 324 selected courses; all pass; full candidate/route/footprint data retained |
| Focused production curse corpus | 432 holes: 2 seeds × 18 × 3 difficulties × none/direction/water/blocker; added counts 2 then 4; no invalid selection, fallback or curse shortfall. One candidate rejected for unfulfilled curse placement; exact context retained in `curse_corpus.json` |
| Actual diagnostic shots | 459 accepted shots across the latest basic/probe/strategy artifacts, including 80 phase trials, three bank witnesses, three two-shot pocket recoveries, two lower crossings, ten matched surface trials and whole-hole strategies; no rejected-shot/time-budget failures |
| Gallery | 54 baseline and 11 catalog layer captures; all eighteen Normal baseline holes and all nine catalog geometries inspected |
| Native practice input | F6/F7 all variants, F8, F9, H, held arrow/Space, Tab, R, moving-shot pause/resume; passed. Practice rendered at 1920×1080, 1600×900, 1280×720 |
| Solo / Tutorial | Existing rendered Solo-to-shot scenario: 12 assertions pass. Tutorial start/skip scenario: five assertions pass. No human tutorial-completion claim |
| VS AI | Existing full-match smoke: eighteen real AI turns, five shops, identical physical course per competitor, results and rematch pass. Player scores in this lifecycle test are explicit fixtures |
| Complete suite / canonical verifier | 257/257 tests passed before the final endpoint-layer diagnostic correction; the final rerun result is recorded in the handoff and `verifier.log`. Original inspector launch also passed |

Useful reruns:

```powershell
godot4 --headless --path . --script res://tests/hazard_baseline.gd -- --seed-count=6
godot4 --headless --path . --script res://tests/hazard_checkpoint_review.gd
godot4 --path . --rendering-method gl_compatibility --script res://tests/hazard_checkpoint_review.gd -- --gallery
godot4 --headless --path . --script res://tests/hazard_checkpoint_probe.gd
godot4 --headless --path . --script res://tests/hazard_checkpoint_probe.gd -- --strategies
godot4 --headless --path . --script res://tests/hazard_checkpoint_probe.gd -- --strategies --baseline
godot4 --path . --rendering-method gl_compatibility --script res://tests/hazard_practice_smoke.gd
python tools/summarize_hazard_checkpoint.py "$env:APPDATA/Godot/app_userdata/A Stroke Of Luck/hazard_checkpoint_20260910"
powershell -NoProfile -ExecutionPolicy Bypass -File .codex/skills/godot-verify/scripts/verify_godot.ps1
```

The 30-seed matched before/after rollout corpus, full-run density/diversity improvement, joint multi-gate feasibility, new biome mechanics and human enjoyment assessment remain **unperformed and unapproved**. The focused corpus misses `s_curve` in its two seeds; the larger rollout coverage requirement remains. The catalog is technically functional and exercised through existing lifecycle/simulation contracts. It is not human playtested, polished or release-ready.

Owner checkpoint: play at least A1/A3, B2/B3 and C1/C2, then compare their family variants. Judge whether the swing window, bank cost, pocket recovery and route tradeoff are worth expanding; identify bypasses that feel too easy. Select/revise the proposed biome building blocks before their implementation. The explicit mission requires stopping here for that approval.
