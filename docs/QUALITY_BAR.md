# Quality Bar

A player-facing feature is finished only when it is correct, understandable, satisfying, integrated, resilient, and verified. “Works on the happy path” is not done.

## Definition of Done

### Correct

- Behavior matches `GAME_DESIGN.md` or an explicitly approved revision.
- Rules, costs, rewards, durations, stacking, scoring, and state transitions are deterministic and accurate.
- The feature works throughout a run, after restart/reset, and when combined with existing cards and hazards.
- No new engine errors, warnings, invalid resources, or stale state appear.

### Clear to the Player

- A first-time player can identify the feature, its state, and its consequence without developer explanation.
- Inputs and outcomes have timely visual feedback; important effects also have non-color cues.
- Shop text states both benefit and penalty before purchase and agrees with actual behavior.
- HUD and results use consistent terms, values, icon language, and hierarchy; repeated text does not substitute for a readable visual symbol where one is established.
- Hole history never exposes future data, result stars visibly prioritize stroke efficiency, seed copy/input feedback is plain-language, and every settings control demonstrably changes its advertised system.
- Generated challenges routinely influence the tee-to-cup decision space instead of collecting at irrelevant edges; ordinary hazard clusters look connected and intentional, preserve recovery room, and never overlap another occupied surface.
- Generation quality is more than validity: recognizable route ideas, useful banks, readable approaches, optional alternatives and setup/challenge/recovery rhythm must survive representative human play. Heuristic scores and proximity percentages are not approval of difficulty or fun.
- Generator changes require deterministic replay, independent malformed-contract/occupancy/recovery tests, a corpus spanning all 18 positions, three difficulties and representative effect states, and rendered before/after inspection. Report real candidate rejections, fallback rate, quality/relevance metrics, motif/cluster/elevation/branch/moving distributions and bounded generation cost.
- Tutorial-only copy and highlights are absent after completion, skip, menu exit, reset, and every later normal run.

### Good Game Feel

- Input is responsive and cannot be double-triggered during movement or transitions.
- Motion and feedback reinforce impact, danger, reward, or completion without hiding the ball or course.
- Timing, animation, camera response, and audio (when present) support the game’s brisk pace.
- A repeated core action remains pleasant over a complete run, not only in isolation.

### Visually Integrated

- Presentation follows `ART_DIRECTION.md` at gameplay scale.
- Collision footprints, hazard boundaries, aim information, disabled states, and active penalties are legible.
- Layout works at 1920×1080, 1600×900, 1280×720, and the explicitly tested large/ultrawide frames with no overlap, clipping, unreadable text, hidden card disclosure, engine-clear-color exposure, or mouse-blocking decoration.
- Placeholders are acceptable only when explicitly outside the requested polish scope and clearly tracked.

### Resilient

- Reset, menu, shop, sink, hazard, level transition, final-hole, and rapid/repeated input cases are safe where relevant.
- Mouse and keyboard paths both work for shared actions.
- Saved tutorial state and a fresh-user state are considered.
- Invalid or missing data fails visibly and safely; it does not create an unwinnable or silent broken state.

### Verified

- The project passes a headless startup check.
- Relevant items in `MVP_TEST_CHECKLIST.md` have been exercised manually.
- The complete affected flow is played in a development build, including at least one adverse/edge case.
- A dated entry in `PLAYTEST_LOG.md` records build/commit, scope, environment, observations, failures, and follow-ups.
- Unperformed checks are reported as untested, never implied to pass.

## Additional Gates by Feature Type

| Feature | Required evidence |
|---|---|
| Shot/physics | Actual low/medium/high/modifier forecast-versus-stop comparisons; legitimate maximum/boosted straight, diagonal and corner wall containment; terrain entry/exit; pause/reset while moving; no duplicate stroke; automatic OOB refunds exactly its accepted shot once while ordinary hazards/manual reset remain charged. |
| Card/economy | Easy/Normal/Hard offer and purchase limits, affordability, deduction, scaled disclosure/effect agreement, stacking, duration/expiry, clamps, and HUD/results reporting. |
| Hole/hazard | Validator-builder contract pass, quality-scored reachable main route, measured route relevance, connected cluster variety, exclusive placement occupancy, escapable branches/dead ends, boundary/OOB containment, sparse one-to-two-tile elevation crossings, readable static/moving telegraphs, bounce-pad sweep coverage at low/normal/maximum legitimate speed with one bounded separated trigger, and tested reset behavior. |
| UI/screen | Mouse and keyboard usability, title Run Setup, all 4/5/6-card shop layouts, all button/settings/history states, longest copy/value cases, transition in/out, 1920×1080 reference captures, 1600×900 plus 1280×720 fit checks, and no clear-color exposure at 2560×1440/ultrawide sizes. |
| Audio/music | Eight independently scored, loadable themes; verified provenance and preserved supplied/sand hashes; substantive loops with measured seams/headroom; real-driver bounded crossfades/cleanup; strength/speed-based cues; failure/success separation; persistent Master/Music/SFX controls; no generic purchase duplicate; full-run human listening on speakers/headphones. Signal/PCM checks do not approve musical quality. |
| Tutorial | Fresh save, completed save, skip/restart/menu/reset cleanup, required hazard interaction, progressive HUD, multiline copy, zero leaked overlays, return to Main Menu and a subsequent explicitly started normal run. |
| Run progression | Full 18-hole/six-biome run, correct local and overall indices, five biome shops, results timing, timer pause, ending, and clean new-run reset. |

The final human-fix pass additionally requires separate Easy/Normal/Hard and early/mid/late corpus aggregates, rare fallbacks, full-tile falling-ice collision/art, live pendulum art/collision agreement, all four gameplay rarities, persisted Dark/Light readability, authoritative two-shot/final-shot warnings, and success/failure/purchase audio exclusivity. Automation cannot approve the high-speed wall fix or generation difficulty feel; representative human retesting remains mandatory.

## Release Gate

A build is demo-ready only when the intended 18-hole run is completable without developer intervention; all required screens and at least eight tradeoff items work; no critical/high findings remain; scoring and economy reconcile at run end; mouse and keyboard controls are usable; and a clean-machine Windows build completes a smoke playtest. Mac remains a target only after an exported build is tested on macOS.
