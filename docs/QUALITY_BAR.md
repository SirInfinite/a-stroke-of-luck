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
| Shot/physics | Tested at low, medium, and high power and preview distance; terrain entry/exit; menu pause/resume while moving; reset while moving; no duplicate or refunded stroke. |
| Card/economy | Affordability, deduction, disclosed effects, stacking, duration/expiry, and HUD/results reporting. |
| Hole/hazard | Validator-builder contract pass, quality-scored reachable main route, exclusive placement occupancy, escapable branches/dead ends, boundary/OOB containment, elevation transitions/crossings, readable static/moving telegraphs, and tested reset behavior. |
| UI/screen | Mouse and keyboard usability, all button/settings/history states, long text/value cases, transition in/out, 1920×1080 reference captures, 1600×900 plus 1280×720 fit checks, and no clear-color exposure at tested large/ultrawide sizes. |
| Audio/music | All eight distinct theme streams load, one exclusive music/ambience state, physical semantic cues, failure/success separation, no duplicate/stuck voices, provenance, and full-run listening on speakers/headphones. |
| Tutorial | Fresh save, completed save, skip/restart, required event, blocker, and return to normal run. |
| Run progression | Full 18-hole/six-biome run, correct local and overall indices, five biome shops, results timing, timer pause, ending, and clean new-run reset. |

## Release Gate

A build is demo-ready only when the intended 18-hole run is completable without developer intervention; all required screens and at least eight tradeoff items work; no critical/high findings remain; scoring and economy reconcile at run end; mouse and keyboard controls are usable; and a clean-machine Windows build completes a smoke playtest. Mac remains a target only after an exported build is tested on macOS.
