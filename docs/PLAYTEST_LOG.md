# Playtest Log

Record observed playtests and verification here. Keep entries factual; do not convert assumptions into passes. Newest entries go first.

## Entry Template

### YYYY-MM-DD — Build or commit — Tester

- **Environment:** OS, Godot/build version, input method, display.
- **Scope:** Feature or flow tested.
- **Session:** Duration and route/build used.
- **What worked:** Direct observations.
- **Findings:** Severity (`critical`, `high`, `medium`, `low`), reproduction steps, expected vs. actual.
- **Player response:** Confusion, delight, strategy, pacing, and comments—not interpretation presented as fact.
- **Follow-up:** Owner/action and retest need.

### 2026-09-24 — Integrated production visual corrections — Agent verification

- **Environment:** Windows, Godot 4.6.2, Compatibility galleries and default D3D12/Forward+ normal-entry replay, WASAPI. Four sizes: 1280×720, 1920×1080, 2560×1440 and 3440×1440. Real Main with synthetic Godot input and explicitly arranged review states; not an owner playtest.
- **Observed:** Normal startup uses the revised logo composition, Jersey controls and native procedural game. Six biome captures, travel/overview/return, tee/shot/reset/tutorial/VS states, source-complete cartoon cards, purchase/details, settings and results render through production components. Default-renderer keyboard startup reaches an accepted shot; viewport mouse events purchase exactly once at all four sizes. Full bag counts now render.
- **Concrete refinements:** Restored manual tee visibility; cropped a paired tee source to one object; retained strong card texture references after blank native draw quads; fixed seed clipping, HUD/menu and VS/power-meter overlap, hidden equipment labels, backdrop depth order, quiet/detail palette mismatch and a baked cup edge in flag frames. Rejected an opaque ground-apron trial because it hid scenic art.
- **Verification:** Canonical verifier passes 267/267 tests. Four gameplay reviews each pass 1,467 checks; four dark UI galleries and one light gallery each pass 2,871 layout/font/glyph checks. Generator corpus: 864 valid holes, zero fallbacks. Eighteen real AI turns/five shops/final/rematch pass. WASAPI lifecycle: 89 checks, zero failures; production audio is unchanged. Evidence and exact launch instructions: `PRODUCTION_VISUAL_INTEGRATION.md`.
- **Limits / follow-up:** Desktop helper unavailable after recovery, so no native desktop mouse session or subjective listening claim. Owner should retest camera comfort, noninteger-scale shimmer, full-run readability, tee alignment and cartoon card appeal. Repeated near-prop pairs can still look pasted onto the scenic field despite fixed world positions. No export, commit, issue closure or release approval.

### 2026-09-24 — Production visual corrections — Owner feedback

- **Environment:** Owner reviewed the presentation sample; exact display, input and session duration were not supplied.
- **What worked:** The owner approves the new font, unchanged main logo, overall pixel-art direction and successful revised interface elements.
- **Findings:** Old curvy text remains in some states; backgrounds feel like static screen images; tees appear duplicated or beside the ball; newer card objects lost the earlier cartoonish pixel character; some symbols are cropped in the artwork; normal game startup still shows the old presentation.
- **Authorized follow-up:** Integrate corrected visuals throughout normal Main, six procedural biomes, tutorial, Solo/VS, shops, settings/pause and results. Restore course-linked scenery and the earlier complete cartoonish object family. Preserve gameplay, the logo and approved production audio. The prior sample-only gate is explicitly superseded for this scope.
- **Retest:** Font consistency/readability, camera travel/overview scenery, one centered tee across lifecycle resets, complete card silhouettes and ordinary project launch. Implementation evidence is recorded separately from these human observations.

### 2026-09-24 — Reference presentation slice — Agent scripted review; owner approval pending

- **Environment:** Actual Main/fixture on Windows, Godot 4.6.2 Compatibility rendering at 720p, 1080p, 1440p and 3440×1440. Exactly three specialists; shared checkout. Native desktop input bridge was unavailable; no human playtest or subjective listening is claimed.
- **Scope:** Opt-in Meadow/Volcanic art, illustrated pendulum/materials, six equipment illustrations, title/HUD/shop/results, two audio auditions and event feedback. Approved logo and preexisting game sources remain hash-identical. Default main scene is unchanged.
- **Session:** Reviewed all 17 local references; full recording frame coverage and selected temporal sequences. Two material refinement cycles reduced noisy terrain/water, removed floating props/legacy result badge, strengthened type, and corrected light-mode legibility. Real scripted shots hit a wall/pendulum, resolve PAR, purchase an item and enter water. Native keyboard focus changes selected shop details.
- **Evidence:** `REFERENCE_SLICE_REVIEW.md` and `tools/reference_slice/review.html` link actual captures, gameplay movies, reference index and audio auditions. Repository suite passed 262/262; four-size slice checks passed 61 each, with an additional 67-check focus/lifecycle pass. Generator regression covered 864 holes with zero selected invalid/fallback holes. WASAPI audio lifecycle passed 68 checks; audio asset audit passed 87.
- **Player response:** None. Scene readability in images and frame/cue alignment do not establish mouse comfort, visual similarity, motion comfort or soundtrack appeal. Utility backgrounds, remaining biomes/hazards/items and full tutorial/VS migration remain pending.
- **Follow-up:** Owner should play the visible manual scene, compare density/atmosphere/materials, inspect all shop sizes and active curses, assess pause/follow/overview and audition both compositions for two loops. Stop at style/audio approval before full rollout. No commit, export, issue closure or release approval occurred.

### 2026-09-11 — Gameplay direction correction — Agent verification; owner play pending

- **Environment:** Windows, Godot 4.6.2, dirty `release/7-hour-ship` at `e2459b3495f57689a5ec493cb71e4e66816a3029`; version 2 fixtures and exact seeds listed in `GAMEPLAY_DIRECTION_REVIEW.md`. One implementation agent; no human gameplay observations collected in this pass.
- **Scope:** Refined the existing nine approval fixtures, pendulum contact/shared simulation, sample access and independent diagnostic tooling. The art thread's modules/assets, approved logo and production generator remain untouched.
- **Session:** Real Main/GolfBall shots, native input event smoke, rendered courses/layers, separate labelled scripted recordings, fixed strategies, phase sweeps, pocket escapes and VS handoffs. Detailed machine results and failed attempts are retained under `artifacts/gameplay_direction/`; the review document explains each comparison's limits.
- **Findings:** C3 and B2 initially had no clear release among sixteen sampled waits for a tested crossing; larger travel arcs restored observable passing windows. A waiting solver could be hit at rest and then submit a stale shot after reset; the diagnostic now retains that real penalty and cancels the stale submission. A 500 px ice patch at intensity 0.22 extended a 40% shot from 3.83 s to 8.62 s. A short 0.55-intensity patch with sand is measured separately, without changing production ice.
- **Player response:** Pending. Automation cannot answer appeal, challenge, fatigue, fair timing, useful underpass choice or compatibility with the pending pixel-art presentation.
- **Follow-up:** Owner reviews all nine variants, both inputs, power/timing choices, ordinary recovery and density using the checklist in `GAMEPLAY_DIRECTION_REVIEW.md`. No commit, export, issue closure or production expansion is authorized by automated results.

### 2026-09-10 — Hazard benchmark request — Owner observations and separate agent evidence

- **Owner evidence:** The owner reports too few meaningful decisions, hazards without purpose, similar motif instances, insufficient pressure and insufficient biome-specific play. They favor dead ends, banks, loops, splits and the swinging rock ball; ice is least enjoyable. Exact prior playtest build, controls and session duration were not supplied.
- **Authorized scope:** Build three concepts with three substantial geometry variants each, obtain owner approval of feel, then expand. Desired character is chaotic, risky, timing-heavy and hard but fair. Biome mechanic candidates are hypotheses awaiting selection. One agent; no commit/export/issue closure.
- **Agent environment:** Windows, Godot 4.6.2, existing dirty `release/7-hour-ship` tree based on `e2459b3`; real Main/GolfBall with synthetic input and fixed 1/60 physics delta. Native practice rendering at 1920×1080, 1600×900 and 1280×720. This is not a human retest.
- **Observed:** The nine fixtures validate and replay. Actual shots bank, enter and escape force-fed pockets, traverse both logical layers, and alternate between passing and ordinary hazard penalties at different swing phases. The isolated 40% ice-entry trial extends stopping time from 3.83 to 8.62 seconds. The interpretation that this explains the owner's dislike remains a hypothesis.
- **Findings:** All nine prototypes remain solvable by a full-power strategy that searches its angle carefully. Thus they do not yet prove the requested whole-hole power/timing advantage. Broad bypasses, rebound catches, swing readability and pocket escape discovery need human evaluation. A straight escape against force failed in B2/B3; an angled shoulder escape succeeded from each actual stopped ball. A flat authored-course typed-array validator error found by the new regression was corrected.
- **Evidence:** `HAZARD_CHECKPOINT.md` links launch instructions, 324 baseline holes, a 432-hole focused curse corpus, actual-shot/phase/strategy diagnostics, galleries, native input/pause/reset checks, Solo/Tutorial smoke and eighteen real VS AI turns. Full verifier results are recorded in the final handoff. No generator score or automated completion is treated as enjoyment.
- **Player response / follow-up:** No human has played or approved these benchmark variants yet. Owner to compare A/B/C feel and select/revise the proposed shared biome mechanics before production rollout. No release-readiness claim.

### 2026-09-07 — Final human-playtest fix request — User-supplied human evidence

- **Environment:** External release-candidate human playtest. Exact build hash, hardware, controls, display and session length were not supplied; this entry does not invent them.
- **Scope:** Ball containment, OOB accounting, trajectory, pendulum/ice, generator difficulty/progression, card rarity, UI appearance/warnings, crowd/purchase audio and small course details.
- **Observations supplied:** Legitimate high-speed shots still passed through walls; the spiky pendulum could look stationary; the trajectory head did not represent the resting position; falling ice did not occupy a clear full tile; Easy/Normal/Hard hazard distributions felt too similar. Lower-area markers, wall seams and weak feedback needed refinement.
- **Approved revisions:** Refund only the automatic OOB attempt, add meaningful benefit/curse/price rarities, strengthen difficulty × run progression, persist Dark/Light UI, warn at two/final shots, add success/disappointed crowd and purchase kaching, share power colors and add sparse tile motifs. The user's exact A–M retest list is preserved in `MVP_TEST_CHECKLIST.md`.
- **Agent evidence, not a human retest:** Current-game baseline ran before edits. Live physics reproduced native CCD/corner and pendulum-transform failures. The focused final suite passed 14/14 tests (31,436 assertions), including real constructed boundaries, 4,000 px/s legal card power, 1,450 boost and 8,000 stress cases, exact-once refunds, real surface forecasts and UI/rarity contracts. A 6,912-hole corpus had zero invalid/fallback holes and no curse shortfall. Main rendered smoke and 23-screen showcase passed; 140 generation frames were captured. The WASAPI lifecycle tour passed 89 checks with -8.28 dBFS peak, and the file/PCM audit passed 386 checks. Full canonical verification is reported separately in the task handoff and evidence log.
- **Refinements from agent inspection:** Static sweep plus bounded solver-separation guard; atomic pendulum transform; full-tile ice merge overwrite; per-reservation route/recovery check; one-physics-step surface-notification timing in prediction; Light-mode header/backdrop contrast with unchanged wordmark/art; category colors retained inside rarity frames.
- **Follow-up:** Human A–M retest is still required, especially maximum-speed walls/corners, boosted wall shots, difficulty/run progression fairness, rarity economy and listening. No human replay/listening approval, export, commit, issue closure or final release approval occurred in this session. Detailed measurements and commands: `HUMAN_PLAYTEST_FIX_REVIEW.md`.

### 2026-09-06 — Structural / audio migration — Agent scripted review, not human listening

- **Environment:** Windows, Godot 4.6.2 console, D3D12/Forward+, real WASAPI playback/recording and headless GUT. Synthetic input/state arrangements; no human listening session.
- **Scope:** RunState authority, transition/reset guards, visual/audio event separation, tutorial boundary, shop wallet/layout lifecycle, eight new acoustic scores and semantic audio mixing/cleanup. Existing generator, gameplay tuning, card/difficulty data and saves were preserved.
- **Session:** Before editing, ran the actual Main 34-screen tour and title-to-shot smoke. After implementation, 167/167 GUT tests and 64,604 assertions passed; the 6,912-hole corpus had zero invalid selected holes or fallbacks. Rendered Main passed 34 captures / 1,292 layout checks at each of four target resolutions; smoke passed 11 assertions / seven captures, release showcase 11 / 23, and generator showcase rendered 140 cases.
- **What worked:** The real audio tour passed 86 checks through menu/settings/tutorial, six biomes, pause/resume, shop, failure, results/ending, new run and rapid crossfades. Music/ambience stayed within two-voice transition pools and settled to the target only. Default-volume recording peaked at -7.88 dBFS. Independent PCM/score audit passed 371 checks and all six supplied/approved cue hashes remained unchanged.
- **Findings:** High: queued/running sink animations could survive reset; invalidation and non-await completion callbacks fixed the reproduced bug without changing physics or timing. High: the low boost cutoff was unreachable at the real minimum launch; audio-only cutoffs now reach all three supplied sounds. Medium: first default-volume recording hit the limiter; central SFX trim corrected headroom. Medium: purchased-card capture exposed a persistent 110 px layout offset; slot-refit regression/fix removed the overflow. Earlier implementation parser errors and a cancelled-tween leak were resolved before the final green run.
- **Player response:** Not applicable. A real-driver recording is not human approval of music, acoustic believability, balance, fatigue or gameplay feel.
- **Follow-up:** `STRUCTURAL_AUDIO_REVIEW.md` and the focused `MVP_TEST_CHECKLIST.md` gate contain commands and remaining checks. Human listening and indirectly touched gameplay need approval. Native Windows export preflight passed, but no current build was exported or smoke-tested. Supplied-file external license details remain owner-confirmation items before distribution. No commit, issue closure or release approval occurred.

### 2026-09-06 — Procedural-grammar revision 2 — Agent scripted review, not human playtesting

- **Environment:** Windows; Godot 4.6.2; headless deterministic tests and rendered 1920×1080 generation/Main scenarios with synthetic input.
- **Scope:** Route-first motif composition, meaningful guard placement, occupancy/validator hardening, candidate quality, biome/difficulty arcs, curses, sparse elevation, fallback/replay and development diagnostics. Preexisting visual/gameplay work was preserved.
- **Session:** Captured 108 baseline and 140 revised generation frames. Inspected all eighteen Normal holes at seed 7919, alternate seed/difficulty examples across all biomes and targeted feature/layer fixtures. Complete GUT passed 148/148 tests with 64,310 assertions; the expanded 6,912-hole corpus had zero invalid selected holes, fallbacks or curse shortfalls. Rendered generation showcase, inspector, title-to-shot smoke and the actual Main 34-screen integration scenario passed.
- **What worked:** Course ideas persisted across candidate selection; route-relative guards, clear recovery centers and optional branches produced more legible shot sections in the inspected frames. Independent validation rejected malformed footprints, conflicting occupancy, stranded surfaces and invalid transitions. Observed elevation frequency was 9.66%; all three corpus tunnels covered two cells.
- **Findings:** Review prompted separated primary/optional routes, bounded curse-cluster growth, reservation priority for timing gates, full-cell ramp entrances, correctly aligned ascent arrows and corpus-selected showcase fixtures. Mean/minimum quality scores of 95.83/87.57 and 100% geometric route proximity are proxies, not evidence of fun or real-shot difficulty. Cardinal geometry remains recognizable and Easy recovery areas remain generous.
- **Player response:** Not applicable. No human played or approved the generated holes; no subjective balance, fairness, authorship or release claim is made.
- **Follow-up:** Use `PROCGEN_OVERHAUL_REVIEW.md` for exact evidence, fixtures and commands. Human testing must cover complete biome arcs on all difficulties, banks, shortcut tradeoffs, dead-end recovery, moving-hazard timing/pause, repeat bounce launches, ramp/tunnel traversal, curse replay and transition latency. No commit, export or issue closure is authorized by these results.

### 2026-09-06 — Visual-overhaul working tree — Agent scripted review, not human playtesting

- **Environment:** Windows; Godot 4.6.2; headless GUT and rendered scenarios with synthetic input. Real Main-screen review at 1280×720, 1600×900, 1920×1080, and 2560×1440.
- **Scope:** Presentation only: title/wordmark, shared UI, setup/settings/tutorial, HUD, equipment cards/shop, results/ending, course/hazards/elevation, six biome environments, and feedback. Existing dirty-worktree gameplay changes were preserved separately.
- **Session:** Baseline game/screenshots inspected before editing. Four-resolution fixtures each captured 34 screen states and checked layout/disclosure bounds. The complete GUT suite passed 125/125 tests with 66,917 assertions. Rendered title-to-shot smoke, tutorial skip, six-biome/hazard/results showcase, bounce/cup showcase, and settings scenarios passed. Evidence locations and rerunnable commands are in `VISUAL_OVERHAUL_REVIEW.md`.
- **What worked:** Shared paper/ticket/fixture shapes replaced repeated dark panels; equipment illustrations and equal-weight benefit/curse copy stayed readable in all shop sizes; all six biomes had distinct low-contrast landmarks; course fitting kept the playable surface between permanent UI; final results used scorecard hierarchy and a trophy/biome/card payoff.
- **Findings:** Screenshot review led to higher Swamp/Volcanic route contrast, quieter rough tufts, joined hazard banks, larger disclosures, tutorial clearance, distinct Power Club/Overdrive silhouettes, complete ten-digit seed values, and stable post-cup camera framing. A full-suite stall was isolated to the bounce test retaining watched freed fixtures; explicit watcher cleanup resolved the rerun without changing gameplay assertions or physics. The showcase's falling-ice trigger call was brought up to date with its existing argument contract.
- **Player response:** Not applicable. No human played or approved the overhaul; screenshots and scripted input cannot establish comfort, charm, pacing, or sustained readability.
- **Follow-up:** Human acceptance checklist in `MVP_TEST_CHECKLIST.md`: both input methods at all four resolutions, every card state, all biomes/elevations with moving shots, reduced motion, tutorial lifecycle, and a complete eighteen-hole run. No commit, export, or release approval is implied.

### 2026-09-05 — Release-candidate working tree — Agent automated/rendered verification

- **Environment:** Windows; Godot 4.6.2 stable; headless focused/full GUT plus deterministic rendered scenarios at 1920×1080.
- **Scope:** Narrow bounce-pad tunneling/boost fix and biome-aware putting-region tile presentation.
- **Session:** Focused bounce/gameplay suite: 15/15 tests and 104 assertions. Focused course-visual suite: 6/6 tests and 498 assertions. Repository verifier: 120/120 tests and 66,786 assertions. The main rendered smoke and six-state bounce/green showcase both passed; Meadow full/close cup, yellow pad, approach, immediate exit, and Desert cup screenshots were inspected against `assets/IMAGE2.png`.
- **What worked:** Low-, normal-, and maximum legitimate-speed segment crossings each produced one bounded seeded bounce, including a simulated one-step path from one side of the pad to the other. The ball was separated beyond the combined collision radii. Meadow and Desert captures retained square cell boundaries, alternating tile values, and local detail through the putting region with no standalone putting overlay. The pad read in saturated yellow/gold with a lightning/energy motif.
- **Findings:** No automated or rendered failure remained. One verifier attempt using the non-console Windows executable made unusually slow progress during GUT and was interrupted; the identical verifier was rerun with the 4.6.2 console executable and completed successfully. Scripted screenshots do not establish real-shot feel, edge-angle behavior, or human visual recognition.
- **Player response:** Not applicable; no human participated in this verification session.
- **Follow-up:** A human must hit pads at very low, ordinary, and maximum powered/card-modified speeds from center and grazing angles, verify one launch without sticking, and review Meadow plus at least one non-Meadow cup area at gameplay zoom.

### 2026-09-04 — `release/7-hour-ship` working tree — Agent automated/rendered verification

- **Environment:** Windows; Godot 4.6.2 stable; headless GUT and generation runners plus deterministic rendered scenarios using synthetic keyboard/mouse input at 1280×720, 1600×900, 1920×1080, 2560×1440, and 3440×1440.
- **Scope:** Final generation/UX refinement: route-relative placement, compact hazard clusters, discrete lower/raised elevation, Run Setup, difficulty/economy scaling, tutorial cleanup/copy, pause/settings behavior, responsive HUD/interstitials, and 4/5/6-card shops.
- **Session:** Complete GUT: 118/118 tests and 66,556 assertions. Expanded corpus: 144 seeds × 3 difficulties × 18 holes = 7,776 generated holes. Rendered main flow, tutorial skip, pause/settings, generation-review, shop-layout, full release-showcase, result, and ending scenarios completed and screenshots were inspected.
- **What worked:** All 7,776 holes validated with zero fallback, occupancy conflict, unreachable cell, quality failure, or elevation anomaly. Mean route-relevant placement was 99.863% (80% minimum); 99.961% of holes had a direct-line interaction and 100% had a tagged meaningful challenge. Connected hazard clusters covered sizes 1–5, minimum measured route width was 4, and all 621 overpasses used a one-tile tunnel. Rendered UI stayed within every tested viewport, Hard used a balanced 3+3 shop, tutorial presentation disappeared after skip, and the live course remained frozen and visible behind the pause blur.
- **Findings:** The first rendered lower-area pass still read too much like a trapdoor/cave; it was revised to continuous normal biome tiles with perimeter edge/shadow cues and re-rendered. No remaining automated failure was observed. This was agent inspection with scripted input, not hands-on human golf play, so obstacle fairness, route authorship, difficulty feel, blur comfort, and real mouse/keyboard ergonomics remain unapproved.
- **Player response:** Not applicable; no human participated in this verification session.
- **Follow-up:** Conduct multiple complete human seeded runs across Easy/Normal/Hard, emphasizing whether route guards cause fair decisions instead of nuisance, whether lower/overpass depth reads during moving shots, and whether the full UI/settings/shop flow remains comfortable at target resolutions.

### 2026-09-02 — Release-candidate working tree — External human playtester

- **Environment:** External interactive release-candidate playtest; exact OS, build hash, input method, display, and session duration were not supplied with the feedback.
- **Scope:** Title/menu, HUD/results/shop, generated courses, ball containment, depth, all biome environments, moving hazards, and music.
- **Session:** Human observations were supplied directly as the authoritative refinement brief for this pass; this entry does not infer routes or conditions that were not reported.
- **What worked:** The build was mechanically complete; the existing stat-box direction, discrete 2.5D system, current card illustrations, shared biome systems, and core run architecture were explicitly retained as useful foundations.
- **Findings:** **High** — generated holes could feel randomly tiled or anomalous instead of authored, with route, width, recovery, hazard stacking, and obstacle-placement concerns. **High** — sufficiently fast shots could escape the course; falling ice and the spiky pendulum did not meet their intended trigger/motion/reset behavior. **Medium** — title identity, settings, seed replay, HUD prominence/history, results rating, shop scan hierarchy, elevation separation, biome putting treatment, cup asset, large-resolution coverage, and biome environmental richness needed refinement. **Medium** — the existing music set remained repetitive/unpleasant and did not provide eight genuinely distinct title/tutorial/biome compositions.
- **Player response:** The UI read as smaller and more explanatory than desired; historical performance, hole quality, elevation, benefit/curse/stack information, and biome identity needed to read faster. The player requested richer but subordinate environment motion and music sustainable over a complete run.
- **Follow-up:** Implement the scoped refinement without rewriting stable architecture, then conduct a fresh human playtest across the checklist below. Automated tests and rendered screenshots may establish correctness/presentation evidence but cannot resolve subjective course quality, feel, motion comfort, or listening fatigue.

## 2026-08-14 — Working tree — Agent repository audit

- **Environment:** Windows; Godot 4.6.2 stable; headless startup only.
- **Scope:** Project load and script/resource parse smoke check.
- **Session:** `godot4.cmd --headless --path . --quit` exited successfully with no reported errors.
- **What worked:** Project configuration loaded and the main scene initialized far enough for a clean headless exit.
- **Findings:** No gameplay was exercised. This is not evidence that shooting, tutorial progression, hazards, shops, UI, or the five-hole run work correctly.
- **Follow-up:** Perform a full interactive playtest using `MVP_TEST_CHECKLIST.md`; capture current reset accounting, every implemented card, every hazard, and final-hole behavior.

## Current Manual Retest Targets

- Complete multiple seeded 18-hole runs and judge primary-route clarity, shot decisions, recovery space, branch usefulness, difficulty curve, and fallback rarity.
- Stress maximum-power boundary impacts plus the full out-of-bounds countdown/cancel path; confirm stroke, penalty, reward, and history accounting by hand.
- Trigger falling ice both beside and directly over the ball; collide with, pause, resume, and rebuild every moving hazard.
- Browse historical stats across biome boundaries and verify future locking with mouse wheel, keyboard, and controller-equivalent input where available.
- Exercise every settings control across relaunch, plus title seed entry/copy/replay and remapped Shoot/Reset controls.
- Review every reference screen at 1920×1080, 1600×900, 1280×720, 2560×1440, and the tested ultrawide size; specifically look for exposed clear color, overlap, hidden card disclosure, and motion discomfort.
- Listen through title, tutorial, all six biome tracks, crossfades, pause/resume, shops, results, and a full run on speakers and headphones; assess seams, balance, fatigue, and compositional distinction.

## 2026-08-16 — Shot Tunability Pass

- Low power shots (0-20%) are easily predictable, and move smoothly. Trajectory preview for them appears longer than intended, gives illusion of more powerful shot.
- Medium power shots (30-50%) go further than what they feel like, and have a long stopping time.
- High power shots (60-100%), in comparision, are underwhelming and feel more abrupt near the end of their roll compared to medium power shots.
- Changing friction value in inspector & in physics material seemed to have 0 effect on ball actual friction.
- Stop threshold appears especially important to very short shots.

Historical observations recovered during consolidation from `feature/cl-1-shot-tuning`, commit `fd41ff7386523a04f3dc234ff1b04f7d793236a0`. They describe that earlier build; they are not observations of the consolidated game.
