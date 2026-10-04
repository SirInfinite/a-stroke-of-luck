# Procedural Generation Overhaul — Review and Handoff

2026-09-06 · grammar revision 2 · uncommitted release-candidate working tree

Status: **READY FOR HUMAN GENERATION PLAYTEST**. This is implementation, automated verification and agent screenshot review, not human approval of fun, balance or release readiness.

## Scope and ownership

The existing `HoleGenerator` API, `LevelValidator` authority, `LevelBuilder`, authored fallbacks, local seeded RNGs and discrete 2.5D physics remain in place. Three focused helpers separate the spatial vocabulary (`CourseMotifs`), candidate composition (`CourseGrammar`) and geometric evaluation (`CourseQuality`). No new global state, physics solver or gameplay architecture was introduced.

This task changes generation, its independent validator, live biome generation parameters, tests and development-only inspection tools. The only builder/presentation integration changes are optional full-cell ramp widths and ascent arrows aligned with the actual transition. Ball physics, moving-hazard behavior, seed parsing, saves, card pool, economy, audio, UI and run-state ownership were not changed by this task. Preexisting dirty-worktree work was preserved and compared with a task-start source snapshot. Nothing was committed or exported.

`GAME_DESIGN.md` owns the intended rules; `ARCHITECTURE.md` documents the implemented contract. Both now describe revision 2. Old seeds intentionally produce different layouts than the previous grammar; replay is deterministic within the same grammar revision, difficulty and generation-effect state.

## Design grammar

The generation sequence is:

1. Choose a biome- and difficulty-weighted course idea using the hole identity.
2. Rotate, mirror and stretch its route skeleton into cardinal shot sections.
3. Carve the primary corridor, clear tee/cup areas and intermediate recovery zones.
4. Optionally connect a branch, recoverable bait pocket or structural elevation alternative.
5. Place biome terrain formations, lane guards, timing gates and approach challenges at route-relative slots.
6. Apply generation curses through those same slots and connected formations.
7. Independently validate, score eight bounded candidates, and select the first highest-scoring acceptable result.

The primary corridor is recorded before alternates are added. A safe route must remain within it; an easy shortcut cannot conceal a broken main route. Every free surface must be reachable, including branches and separate elevation states. Dead-end bait has a useful turnaround pocket, not a stranded tile.

### Implemented motif vocabulary

These are composable situations, not 26 complete prebuilt holes:

- Route: guarded lane, bank corner, dogleg, S-curve, switchback.
- Terrain and blockers: water gate, sand choke, ice runout, offset blocker, staggered slalom.
- Timing and launch: pendulum gate, falling-ice gate, rotating gate, bounce bank.
- Choice and recovery: split route, risky shortcut, recovery pocket, dead-end bait.
- Elevation: raised bridge, recessed cut, short tunnel.
- Approach: open green, guarded green, angled green, sand approach, water approach.

All 26 appeared in the measured corpus. A motif name is diagnostic vocabulary, not proof that a player will choose the intended shot.

### Route pressure and occupancy

Placement uses broad lines between useful shot zones, partial lane obstructions, alternating shoulders and approach guards. Connected water/sand/lava templates produce singles, pairs, elbows, short lines and irregular formations of up to five cells. Distinct formations keep separation; curse growth can enlarge a connected formation without exceeding that bound.

The generator reserves actual footprints, full moving-hazard sweeps, transition landings and endpoint/recovery regions. Tentative placements are rejected if they break primary-route connectivity, strand free terrain or occupy a bounce runway. The validator recomputes occupancy from geometry rather than trusting reservation labels. It also rejects malformed or non-finite footprints before attempting spatial iteration.

Bounce placement searches a bounded sequence of seeds for an initial exit aligned with the onward lane and a clear 200-unit runway. The existing minimum launch speed and subsequent seeded-random launches are unchanged. This is safe-exit potential, not a guarantee for every incoming speed or repeat trigger.

### Biomes, arc and difficulty

| Biome | Structural emphasis |
|---|---|
| Meadow | Clear lanes/banks and water guards; flat; pendulum introduced at the third hole. |
| Desert | Longer stretches, sand formations, water decisions and bounce opportunities. |
| Autumn | More doglegs, S-curves and switchbacks; blocker/pendulum combinations. |
| Snow | Ice runouts, larger recovery terrain, falling-ice gates, occasional raised alternatives. |
| Swamp | Bending wet routes, more optional lane choices and recessed alternatives. |
| Volcanic | Lava guards, rotating gates, more structural alternatives and late Hard timing pressure. |

Each three-hole biome introduces, develops and combines its concept through increasing section/challenge budgets. Easy uses five-cell primary lanes, larger recovery terrain and moving hazards only at each biome's climax. Normal uses three-cell lanes with moderate combinations. Hard retains that width, adding stronger guard combinations, optional routes and two moving gates on some late climaxes rather than shrinking passages.

Most holes are flat. An elevated alternative is normally three cells wide, with full-width parallel ramp entrances. A rare crossing has a two-cell-wide deck pinch and a two-cell-long lower passage. Recessed sections use ordinary biome terrain. This revision generates at most one major elevation idea per hole.

### Curses and fallback

Generation effects rerun the same course idea with deterministic effect-specific candidate variation. Direction zones guard useful lines; water grows/adds connected route guards; blockers guard lanes and corners. Counts are bounded to four, and accepted grammar candidates must fulfill the requested count. The current purchasable card pool still adds direction zones only; water/blocker modes are supported generator contracts and test fixtures, not newly invented cards.

The authored fallback path is retained and independently tested for all 18 hole positions across multiple seeds. Additional forced Hard fallback tests cover direction, water and blocker requests, including correct types, exact bounded counts and replay. The full generation corpus separately covers all three difficulties. Normal generation reports rejected candidates, below-floor candidates, retries and fallback reasons separately.

## Candidate quality and diagnostics

The chosen course idea stays fixed across the eight candidates so scoring cannot repeatedly select a different, more score-friendly idea. Scores are geometric proxies, not claims of fun:

| Component | Maximum points |
|---|---:|
| Route clarity | 10 |
| Obstacle interaction with shot sections | 20 |
| Estimated shot rhythm | 15 |
| Direct-line pressure | 15 |
| Clear recovery | 15 |
| Challenge fit | 10 |
| Bank/choice geometry | 8 |
| Composition | 7 |

Penalties cover excess density, excessive moving/elevation complexity, unguarded flat shortcuts and empty challenge sets. The acceptance floor is 72/100. Direct-line sampling considers missing terrain and occupied cells. A bounded line-of-sight estimate approximates shot count without changing par or running full physics simulation.

`tests/procgen_inspector.tscn` is explicitly development-only and is not connected to the production UI. It displays seed, biome, hole, difficulty, motif list, candidate scores, selected score, rejection/fallback information, primary route, shot sections, recovery zones, reservations and elevation layers. Left/right change hole, N changes seed, D changes difficulty, C cycles curse count, E changes viewed elevation, and Tab toggles overlays. CLI options select the seed, hole, difficulty, curse type/count and modifier seed.

## Corpus results

Measured matrix: **32 seeds × 18 holes × 3 difficulties × 4 effect states = 6,912 selected holes**, evaluating **55,296 candidates**. Seeds are `index * 7919`; effects are none/direction/water/blocker, with two placements on odd seed indices and four on even indices, and modifier seed `index * 104729`.

| Measure | Result |
|---|---:|
| Invalid selected holes | 0 |
| Fallback count / rate | 0 / 0% |
| Unfulfilled curse requests | 0 |
| Rejected candidates / retry count | 29 / 29 |
| Candidate rejection rate | 0.05245% |
| Candidates below the quality floor | 0 |
| Mean / minimum selected quality | 95.83 / 87.57 |
| Mean / minimum obstacle-route relevance | 100% / 100% |
| Unpressured direct tee-to-cup lines | 0 |
| Holes with branches | 2,384 / 34.49% |
| Holes with recoverable bait dead ends | 472 / 6.83% |
| Holes with elevation | 668 / 9.66% |
| Raised / recessed alternatives | 285 / 383 |
| Short tunnels | 3 / 0.0434%, all two cells long |
| Holes with moving hazards | 4,096 / 59.26% |
| Holes with bounce pads | 703 / 10.17% |

Rejections reported missing primary routes, unfulfilled requested placements or disconnected free surfaces; reason counts can overlap for a single rejected candidate. No such candidate reached gameplay.

Terrain-only connected cluster counts (excluding bounce/direction tiles): size 1 **6,037**, size 2 **4,926**, size 3 **4,291**, size 4 **930**, size 5 **338**. This is 16,522 formations, with larger formations genuinely uncommon.

| Difficulty (2,304 holes each) | Branch holes | Elevated holes | Moving hazard instances |
|---|---:|---:|---:|
| Easy | 532 | 116 | 768 |
| Normal | 892 | 260 | 1,664 |
| Hard | 960 | 292 | 2,048 |

The approximate shot-section estimate increases from introduction to climax in all six biomes. For example, Meadow averages 2.54 → 3.25 → 3.99 and Volcanic 2.69 → 3.39 → 4.22. These are not simulated strokes or approved par/balance results.

The final measured run took 201.11 seconds, averaging 29.10 ms per hole including corpus validation/reporting. Generation-only median was 25.77 ms, p95 51.10 ms and maximum 157.17 ms on this development machine. This is not a latency guarantee for slower hardware or an entire synchronous 18-hole setup. Repeated complete runs produced identical non-timing metrics and feature examples.

The 100% relevance result means actual footprints lie near broad shot sections; it does not prove that every obstacle meaningfully changes a real shot. Likewise, a blocked direct line can be a wall/turn rather than a required bank. The old and new quality formulas differ and their numeric scores are not a valid before/after quality comparison.

## Screenshot and level-design review

Before editing, the running game and representative generated holes were inspected. The baseline capture set contains 108 frames: seeds 7919 and 8675309, all 18 holes, all three difficulties. Recurring weaknesses included broad empty carpets, visually arbitrary grid bends, near-routine branching, peripheral timing hazards and thin elevated strips. Existing validity/proximity scores overstated those layouts' design quality.

The revised generation capture set contains **140 frames**: the same 108 configurations plus 32 feature/layer frames selected from the corpus's actual motif/cluster examples. Agent inspection covered all 18 Normal holes at seed 7919, alternate seeds/difficulties across all six biomes, and specific water/sand guards, single/small/five-cell formations, banks, moving gates, branches, bait pockets, bounce pads, recessed/raised routes and both short-tunnel layers. The actual Main integration fixture additionally captured 34 screen states at 1920×1080 with 1,292 layout checks and zero failures; Meadow, Snow and Volcanic gameplay frames were inspected with the production HUD.

Review-driven refinements:

- Keep the course idea fixed during scoring to prevent structural variety collapsing into the easiest idea to score highly.
- Separate the primary route from optional routes; prioritize timing-gate reservations before minor guards.
- Grow bounded curse formations instead of adding isolated scatter, and retain clear recovery centers.
- Widen generated ramp entrances to their full cells and align ascent marks with the transition direction.
- Capture real corpus-selected motifs, including both tunnel layers, rather than assuming an old seed still contains the intended feature.

The strongest reviewed situations are alternating water guards, sand-protected turns, readable switchbacks and short elevation alternatives. Cardinal geometry and recurring L/U concepts remain visible by design. Large Easy recovery areas can still feel generous; the challenge value of every shoulder guard, shortcut and launch requires human judgment.

Useful replay fixtures:

| Situation | Seed | Difficulty / hole | Effect |
|---|---:|---|---|
| Water guard and bank corner | 7919 | Easy / 1 | None |
| Bounce launch and recoverable bait | 7919 | Easy / 2 | None |
| Sand approach and staggered guards | 7919 | Easy / 6 | None |
| Recessed alternate route | 7919 | Easy / 8 | None |
| Five-cell water formation | 7919 | Easy / 4 | Water ×2, modifier seed 104729 |
| S-curve with irregular lava | 15838 | Normal / 18 | None |
| Actual short tunnel and upper crossing | 55433 | Hard / 18 | Blocker ×2, modifier seed 733103 |
| Late volcanic timing pressure | 7919 | Hard / 18 | None |

## Reproduction and verification

Evidence is local and intentionally outside Git: `user://procgen_overhaul_20260906/`. It contains `corpus.json`, corpus/test/verifier/scenario logs, `before/`, `after/` and inspector screenshots. Main integration screenshots use the existing fixture location `user://visual_overhaul_20260906/after/1920x1080/`; its `layout_report.json` records the latest generated-course integration run.

Run from the project root with Godot 4.6.2 available as `godot4.cmd`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .codex/skills/godot-verify/scripts/verify_godot.ps1
godot4.cmd --headless --path . --script res://tests/procgen_corpus.gd -- --seed-count=32
godot4.cmd --path . res://tests/procgen_review.tscn
godot4.cmd --path . res://tests/procgen_inspector.tscn -- --seed=55433 --hole=18 --difficulty=hard --curse=blocker --count=2 --modifier-seed=733103
python .codex/skills/godot/scripts/debug/run_scenario.py . tests/visual_generation_review_scenario.json
python .codex/skills/godot/scripts/debug/run_scenario.py . tests/procgen_inspector_scenario.json
python .codex/skills/godot/scripts/debug/run_scenario.py . tests/visual_smoke_scenario.json
python .codex/skills/godot/scripts/debug/run_scenario.py . tests/visual_overhaul_1920x1080.json
git diff --check
git diff --cached --check
```

Use the verifier's `-GodotPath` and the scenario runner's `--godot-bin` option to select the console executable if local PATH resolution uses the non-console Windows binary. Run the corpus before the 140-frame review to provide its feature-example manifest. The old general release showcase's fixed elevation search is not the evidence source for revision-2 crossings; use the updated generation showcase and corpus-selected review instead.

Automated evidence: import and main startup PASS; complete GUT **148/148 tests, 64,310 assertions** PASS; focused new grammar suite **23/23 tests, 930 assertions** PASS; 6,912-hole corpus PASS; 140-frame generation capture PASS; eight-feature rendered showcase PASS; dev inspector PASS; actual Main integration PASS; rendered title-to-shot smoke PASS. Validator warnings in deliberately malformed negative fixtures are expected and inspected. No unresolved parser/runtime/test failure remained.

Diff review: complete staged/unstaged changes and relevant untracked sources were inspected, with task-start snapshot comparison separating this implementation from preexisting work. No unrelated system mutation was introduced by this task; engine-generated UID files were not manually edited. Whitespace checks passed. Human acceptance and issue closure remain outstanding.

## Required human generation playtest

- Play seeds 7919 and 8675309 across Easy/Normal/Hard using normal mouse aiming and keyboard controls, at 1280×720 and 1920×1080 or higher. Judge the first shot, bank opportunities and three-hole arc in every biome; record strokes, confusion and repetitive situations.
- Try both routes on branches, deliberately enter bait pockets, and attempt recovery after each difficult guard. Expected: a visible escape and useful landing room, not repeated unavoidable punishment or an always-superior shortcut.
- Test pendulum, falling-ice and rotating gates with real shots, including pause/resume before and during the hazard cycle. Expected: readable timing and a practical entry/exit window.
- Hit bounce pads at low/normal/maximum card-modified speed, from grazing angles and on repeat triggers. Expected: no sticking, routine out-of-bounds launch or confusing mandatory gamble.
- Traverse raised, recessed and actual short-tunnel routes in both directions and near ramp edges. Expected: continuous collision, correct layer transitions and readable foreground separation while the ball moves.
- Buy the existing generation-affecting cards, replay the same seed/difficulty/card history, and compare courses across biome boundaries. Use the dev fixtures separately for supported water/blocker effects; confirm they are not presented as purchasable cards.
- Complete representative 18-hole runs, assess transition/startup latency on the target machine, and judge whether late Hard pressure remains fair. Automation and screenshots do not establish that the generated holes are enjoyable or release-ready.
