# Gameplay direction approval sample — 2026-09-11

**Scope: nine playable experiments, pending owner approval.** One implementation agent refined the existing catalog under Chainlink #10. This is a review checkpoint for constructed arcade golf: observe a mechanism, choose a line, set angle/power, time the release, then recover from a visible consequence. Execution has priority over planning; neither rewards nor scoring were changed to encode a ratio.

The production generator, normal main scene, six-biome/eighteen-hole run, shops, curses, personal modifiers and opponent profiles remain in place. The approved logo and the visual thread's assets/modules were not edited. These nine holes use existing runtime art while the pixel-art correction awaits approval. No commit, build export, issue closure or production expansion is part of this checkpoint.

## Play it

Project directory: **`C:\Users\Rony\Projects\a-stroke-of-luck`**. There is no separate worktree.

Scene: **`res://tests/gameplay_direction.tscn`**. It opens the real Main/GolfBall game immediately, accepts normal input and stays open until you close it. No launch arguments are required for A1 Normal.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Rony\Projects\a-stroke-of-luck\tools\gameplay_direction\launch_sample.ps1" -Hole A1 -Difficulty normal
```

The launcher resolves the installed Godot 4.6.2 executable. Supply `-GodotPath 'C:\path\to\Godot.exe'` if needed. Its optional holes are A1–C3 and ART; difficulty is easy/normal/hard. It opens a visible 1600×900 window, with no autoplay, recording or automatic quit.

In the Godot editor, import/open `C:\Users\Rony\Projects\a-stroke-of-luck\project.godot`, open `tests/gameplay_direction.tscn` in FileSystem, then **Run Current Scene (F6)**. Once running, the game's F6 means previous sample. **F5 / ordinary project launch still opens the normal title and run flow through `scenes/main.tscn`.** The project currently declares 4.7 features; this checkpoint was exercised with 4.6.2, without modifying project settings or the owner's running editor.

| Control | Action |
| --- | --- |
| Drag from ball and release | Normal mouse shot |
| Arrow keys + Space/Shoot | Normal keyboard angle, power and shot |
| Selector / F6 / F7 | Pick a hole / previous / next |
| F8 | Easy → Normal → Hard; rebuilds a fresh attempt |
| F9 | Fresh practice attempt: clears strokes/time and practice cards/rewards |
| R | Ordinary reset; keeps strokes/time |
| Tab | Existing course overview; return to ball to aim |
| Menu / Escape | Existing pause/resume flow |
| H | Show/hide intended decision, consequence and recovery brief |
| F10 / ART entry | Exact physical Meadow fixture shared with the visual thread |

The practice host repeats the selected fixture in Main's normal slots. Results/continue still work; use the selector to change experiments. The ART companion is **The Old Swing**, seed **9102026**, read directly from `tools/pixel_sample/sample_level.gd`. Its physical fields match the visual sample; F8 does not retune that fixed reference. It is additional coordination material, not a substitute for any of the nine variants.

## Nine holes and their decisions

All use 100 px square cells and a 12 px ball radius. Ordinary corridors are 300 px wide, with wider deliberate setup/recovery chambers. A1 remains par 3 / ceiling 7; the other eight remain par 4 / ceiling 8. No par inflation was used.

| Family / variant | Seed | Substantial geometry and intended shot | Recovery |
| --- | --- | --- | --- |
| A1 Pendulum Bank — Bell Bank | 910101 | Compact elbow, low bank face, inner sand stop, large outer bay. Bank past water or release through the swinging stone's window. | Outside catch and inner sand permit another approach; water/stone retain normal penalties. |
| A2 Pendulum Bank — Long Fuse | 910102 | Longer inlet, offset east exit, shoulder rail and **two** opposed-phase stones separated by setup space. Carry the first section, settle in the elbow, then cross the second gate. | Broad elbow permits a new angle; the rail has a longer bypass. A stopped ball under a stone can still be hit while waiting. |
| A3 Pendulum Bank — Hook Return | 910103 | Hook-shaped return, additional inside dogleg, different rebound face and reversed cup approach. Choose exposed chamber or protected inner approach. | Wide outside bay and a new shoulder provide recovery; water guards punish the wrong return angle. |
| B1 Force-fed Fork — Crosswind Fork | 910201 | Early fork, straight shortcut, upper bank loop and broad pocket below a two-cell down-force band. Carry/counter the gust, then time the exit. | Clear pocket shoulder leads out of the force band; the upper loop bypasses the combined shortcut threats. |
| B2 Force-fed Fork — Offset Sluice | 910202 | Three-cell force band, deeper pocket, dogleg shortcut and displaced reconnection. The stone guards the offset exit; the protected upper route costs distance. | Escape from the pocket's actual landing is possible; sand at the offset exit offers a stopping choice. |
| B3 Force-fed Fork — Late Fork | 910203 | Longer inlet, late fork, southern bypass and upward force into a hooked dead end. Arrival speed and the final guarded landing differ from B1/B2. | The pocket shoulder rejoins the fork; the southern loop includes a sand setup catch and bank rail. |
| C1 Crossing Loop — Return Under | 910301 | Compact outer loop, exposed raised shortcut and a two-cell covered lower crossing. Choose layer before crossing; upper and outer routes have separate timing threats. | The underpass is clear; its exit opens into sand and an optional bank. Full-width ramps reconnect the deck. |
| C2 Crossing Loop — Low Bow | 910302 | Compact loop with a **recessed open cut**, side sand bay and downward force. No covered crossing here: choose the lower early-return line or the timed outer loop. | Normal biome terrain remains below; wide ramps at both ends and the side bay allow escape. |
| C3 Crossing Loop — Offset Weave | 910303 | Longer loop, later short underpass, offset return and additional approach bend. A more exposed upper route trades turns for timing; lower crossing changes the return angle. | Clear lower passage and flared openings; visible landing water and a return rail preserve consequences after emerging. |

These are authored variations through the generator's actual CourseGrammar carving/normalization helpers, normal profile metadata/scoring, LevelValidator and LevelBuilder. They do not establish that production random generation already produces equivalent variety. Structural signatures normalize rotations/reflections and remain distinct for all nine.

## Hazard interactions and fairness

- **Swing + bank:** A visible moving mass guards a direct or fast line. Solid rails offer deliberate rebounds; broad shoulders permit setup and observation. Contact adds the normal hazard penalty and returns to the tee. No collision immunity is granted to either competitor.
- **Force + pocket + timed exit:** The existing directional acceleration rewards entry speed/angle. An insufficient entry can drift into a bounded pocket without an automatic penalty. The next shot escapes the actual landing. A stone at the exit makes arrival timing relevant; the longer fork bypass remains available.
- **Sand + guarded landing:** Sand can intentionally stop an arrival before a dangerous approach. Missing it changes distance and angle; visible water beyond a landing provides the normal reset consequence. There is no hidden full-power punishment.
- **Loop + layers:** Raised, lower and outer routes expose different threats and shot angles. C1/C3 cover exactly 200 px of lower travel with 100 px physical width (76 px center clearance for a 24 px ball). Hidden lower cells contain no hazard. Crossing screen positions never join layers without a ramp; C2 demonstrates an open lower route instead.

Each physical object carries `interaction.shot_or_route`, `observe`, `execution_skill`, `failure` and `recovery`, alongside its placement role. These are available in the generated art contract. Tee and clear recovery reservations are preserved; the automatic OOB refund exception remains separate from intentional hazard penalties.

Normal independent encounter groups increase **3 → 6 per hole**, and actual moving bodies increase **5 → 12 across nine holes**. A multi-cell surface formation counts once. Easy keeps six groups with 60 px stones and slower cycles; Normal generally uses 76 px stones; Hard generally uses 88 px stones, shorter cycles and a seventh shoulder guard. C1's compact upper mechanism stays 60 px across tiers. Base periods are 4.2 / 3.2 / 2.6 seconds, multiplied by the variant's 1.08 / 1.00 / 0.94 scale. No timing adapts to the player's aim or shot.

Ground-corridor affected counts increase A1–A3: **2/3/3 → 2/3/4**, B1–B3: **3/3/3 → 4/5/5**, C1–C3: **1/1/2 → 2/3/3**. These are geometry proxies: the metric omits some upper-route/landing pressure and does not establish fun or practical shot difficulty. Counts, covered surface fraction, layered-route threats, alternatives and clear recovery reservations are in `after/metrics.json`, alongside the original baseline. The sample has substantially more interacting pressure, but only the owner can decide whether six groups feels exciting or exhausting.

## Visual handoff

Use `after/art_contract.json` for all nine definitions, active-layer surfaces, ramps, structure/occlusion data, hazard footprints and live mover snapshots. Units are Godot world pixels; Y increases down; elevations are -1/0/1. Stable sample object IDs include family/variant/version and normalized cell. `cluster_id` groups related surface cells without replacing individual identity.

| Object | Authority and presentation contract |
| --- | --- |
| Pendulum | `MovingHazard.get_presentation_state()`: stable `id`, `anchor`, actual world `position`/`transform`, `footprint`, shape, elevation, orientation, phase, initial phase, period, analytic velocity/direction, collision-active and paused/state fields. Read actual transform for contact-aligned art. `get_telegraph_data()` supplies the arc. |
| Pendulum contact | Native CCD contact, overlap and relative-motion sweep all converge on one latched `body_hit`. Main owns score/reset; art/audio consume the event once. `state_reset` rearms the presentation; ordinary penalty recovery does not arbitrarily restart the swing's timeline. |
| Surface / bank | Stable definition ID, type, footprint, world position, direction, intensity, elevation and placement/interaction metadata. Existing surface entry/exit and wall-impact events remain authoritative. |
| Elevation | `LevelBuilder.get_elevation_presentation_data()`, `elevation_cells`, `elevation_transitions`, `elevation_structures` and active layer. Openings, shadow edges and occlusion must follow the actual lower/upper masks. No entrance labels or cave semantics. |
| Ball | Existing shot-started/finished, wall-impact, terrain, elevation, hazard and sink lifecycle. Smooth physics stays independent of pixel quantization; the player aid remains straight. |

The pendulum's visible child, native collider and detector share its moving body transform. The swept contact helper uses observed world positions; AI uses the same analytic motion and relative sweep with copied state. The existing pixel sample's 88 px drawing is appropriate for its unchanged ART fixture. Before applying that artwork to the nine variants, read each actual footprint (60/76/88 px), anchor and layer; do not assume a fixed 88 px collision body. No final sprites, textures, palette, UI styling, effects or audio were changed here.

## Before / after evidence and observations

Evidence root: [`artifacts/gameplay_direction/`](../artifacts/gameplay_direction/). These local artifacts are ignored and are not release assets.

- [Before recording](../artifacts/gameplay_direction/before.mp4) and [after recording](../artifacts/gameplay_direction/after.mp4): separate scripted runtime sessions, clearly captioned arranged starts. They show A1 releases, a C1 lower crossing, and B2 pocket entry/escape. They are not manual-play mode or human performance.
- Matched layouts: [A1 before](../artifacts/gameplay_direction/before/A1.png) / [after](../artifacts/gameplay_direction/after/A1_layer0.png); [B2 before](../artifacts/gameplay_direction/before/B2.png) / [after](../artifacts/gameplay_direction/after/B2_layer0.png); [C1 before](../artifacts/gameplay_direction/before/C1.png) / [after lower](../artifacts/gameplay_direction/after/C1_layer0.png) / [after upper](../artifacts/gameplay_direction/after/C1_layer1.png). The folders include every variant and relevant layer.
- [216 actual interaction records](../artifacts/gameplay_direction/after/probes.json): three bank diagnostics, 192 phase-controlled crossing shots, two underpass shots, six pocket entry/escape shots and thirteen surface diagnostics. All accepted/settled; no diagnostic failures in the final run. A1/A3 bank witnesses produced native wall events; A2's searched witness did not reproduce its predicted bank, while whole-hole A2 strategy shots did bank. Forecasts are not substituted for contact evidence.
- At sixteen sampled waits, clear/hit outcomes were A1 entry **9/7**, A2 **12/4**, A3 **10/6**, C1 **8/8**, C3 **8/8**. Exit-gate clear/hit results: A2/B1/B2/C1/C2 **6/10** each, B3 **4/12**, C3 **7/9**. Entry tests use the same 65% downward shot; exit tests use the same 18% downward shot. Starts are explicitly arranged. These discrete samples demonstrate choices, not exact continuous window boundaries or feasible arbitrary two-gate shots.
- C1/C3 actual lower shots traveled about **608/779 px** at 65%, without a hazard reset or elevation change. B1/B2/B3 escaped their actual force-fed pocket landings using **60/80/60%** follow-up shots; no teleport was used between entry and escape.
- C3 and B2 initially failed the sampled-window check. Their swing radii were increased to 100 px. Failed probes and the earlier stale-wait benchmark are retained as `probes_b2_window_failure.json` and `strategies_wait_failure.json`; they are not counted as passes.

### Fixed strategy comparison

Same four decision algorithms, current physics, 1/60 simulation delta, fixed 480 fps with an 8× clock. Original nine dictionaries were frozen before edits and replayed through the same current runtime. This isolates layout changes; it is not an old-binary/new-binary comparison. The harness resets each initial phase, records real penalties and cancels a stale plan if hit while waiting. Both sides use the same corrected harness. Before/after JSON includes every legal shot and outcome.

| Strategy | Before: completed / total strokes | After: completed / total strokes |
| --- | --- | --- |
| Immediate full power directly toward cup | 1/9 · 67 | 1/9 · 66 |
| Direct cup aim, search 20 powers | 1/9 · 69 | 3/9 · 63 |
| Search 72 angles, immediate full power only | 9/9 · 23 | 9/9 · 24 |
| Existing Legend route/power/timing planner | 9/9 · 22 | 9/9 · 24 |

Totals include penalties and failed holes. Revised route-planner stroke counts A1–C3 are **3, 4, 2, 2, 2, 2, 3, 3, 3**, all below their ceilings. Low power serves approaches and short crossings, medium power serves pocket recovery and controlled entries, and high power can carry/bank well. **Careful full-power angle search remains strong:** these results do not demonstrate an overall power/timing advantage over that stronger comparator. The planner's budgets, lookahead and seeded error differ from the angle sweep. Neither solver success nor failure answers human enjoyment, impossibility or mastery.

### Ice investigation

In the same flat lane, a 40% shot stopped in **3.83 s** on normal ground and **8.62 s** after entering a 500 px ice patch at intensity 0.22. This supports the concern about extended helpless sliding. A diagnostic 100 px patch at existing intensity 0.55 followed by a sand stop produced **5.15 / 1.55 / 1.02 s** shot durations at 40/65/100%; the latter two stopped in the sand. This is a construction/tuning candidate, not an approved Snow mechanic. No production ice value/frequency changed, and no claim of improved enjoyment is made.

## Later biome candidates — not implemented or approved

Use existing mechanics first. Meadow samples test physical timing/water/banks; Desert samples test force/sand and sheltered routes; Autumn samples test offset loops/layers/woodland mechanisms. Snow, Swamp and Volcanic proposals below require their own small playable approval checkpoint before biome-wide use.

| Candidate | Trigger / effect / magnitude / duration | Warning, counterplay, interactions and reset |
| --- | --- | --- |
| Snow short slide + stop | Enter a 100 px ice footprint; existing intensity 0.55 applies while overlapping; no added impulse or stun. | Visible short ice and sand/clear recovery beyond it. Choose entry speed/angle. Surface exit restores normal friction; rebuild restores definitions. Do not place falling blocks so landing seals the only route. |
| Swamp directional current | Enter a visible directional band; reuse direction acceleration and speed cap, with a local bounded footprint; continuous only while overlapping. Exact tuning awaits sample selection. | Show direction before entry; offer a bank/clear shoulder and bypass. No indefinite force loop, hidden pull or post-shot changes. Reset clears contact/overlap state. |
| Volcanic timed crossing | Reuse deterministic rotating threat and visible lava footprint. A new vent would need explicit warning/active/cooldown durations and footprint before code approval. | Observe repeatable phase from safe setup; preserve an escape route and normal hazard penalties. Both competitors receive the same initial transient state; no invisible threat under a crossing. |

Existing global `GenerationChallenge` combines difficulty, run/biome/local position and course modifiers. The sample records those inputs but intentionally uses authored local pressure. It does not replace that resolver or retune production biome arcs. Future establish/combine/culminate pacing should vary geometry, include simpler moments and preserve shop rules and stroke ceilings.

## Verification and limits

The canonical verifier imports/starts the project and runs the complete GUT suite, then checks whitespace and inventories the worktree. Its final exact totals and other final checks are recorded in [`verification_summary.json`](../artifacts/gameplay_direction/verification_summary.json) and [`verifier_final.log`](../artifacts/gameplay_direction/verifier_final.log). No placeholder test counts are used here.

Additional evidence includes all 27 difficulty/fixture combinations, actual ball-radius static route sweeps, native 400/1600/4000/8000 px/s contact tests (8000 is beyond the 4000 card cap), signal coalescing/reset/layer checks, rendered mouse/keyboard/selector/pause/overview smoke, real sample VS turns and the existing eighteen-hole VS regression. The production corpus covers **432 holes**, two seeds (7919/15838), all 18 positions, all three difficulties, and none/direction/water/blocker curse cases at requested counts 2/4. It had zero invalid holes, fallbacks or curse shortfalls. Geometry validity is not shot feasibility proof.

Reproduction identity: base Git HEAD **`e2459b3495f57689a5ec493cb71e4e66816a3029`**, dirty branch `release/7-hour-ship`, Godot **4.6.2**, grammar version recorded in each definition, sample version **2**, exact seeds above, difficulty **Normal** for comparison, no personal modifiers, `added_hazard_count=0`, `cup_scale=1`. Before/after binary fixture dictionaries, source hashes and preservation audit accompany the evidence. Cosmetic randomness is not used by the catalog or physics-planning RNG; replay tests perturb the global RNG and compare full fixture dictionaries.

The initial pre-edit full verifier was interrupted during its long GUT run and is not a baseline PASS. The first completed revised suite was 261/262: the new contact guard called Godot's `can_process()` on an off-tree unit-test fixture. The guard now checks tree membership before querying pause state, preserving the existing isolated contact contract and live pause behavior. That failed verifier is retained as `verifier_off_tree_failure.log`. Early diagnostic failures also remain visible. Final automated evidence is separate from owner gameplay/art/audio approval. Real mouse hardware feel, sustained play, difficulty balance, art fit and fatigue are untested by a human.

## Owner review — leave unanswered until played

- [ ] Do the obstacles make you want to attempt the shot, and can you see why it fails?
- [ ] Does observing a cycle improve timing? Is the stone threatening and fair?
- [ ] Does controlling power feel useful, and are risky routes tempting?
- [ ] Can you recover from ordinary misses without helpless sliding or repeated unavoidable resets?
- [ ] Do the three variants in each family feel substantially different?
- [ ] Does the underpass create a useful choice, with clear collision/layer behavior?
- [ ] Is the denser arrangement exciting or exhausting?
- [ ] Does this feel like a constructed arcade challenge compatible with the pending chunky pixel-art direction?

**Stop here for owner gameplay direction approval.** Production rollout, new biome mechanics, commits, merges and issue closure require later authorization.
