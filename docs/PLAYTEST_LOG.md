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

## 2026-08-14 — Working tree — Agent repository audit

- **Environment:** Windows; Godot 4.6.2 stable; headless startup only.
- **Scope:** Project load and script/resource parse smoke check.
- **Session:** `godot4.cmd --headless --path . --quit` exited successfully with no reported errors.
- **What worked:** Project configuration loaded and the main scene initialized far enough for a clean headless exit.
- **Findings:** No gameplay was exercised. This is not evidence that shooting, tutorial progression, hazards, shops, UI, or the five-hole run work correctly.
- **Follow-up:** Perform a full interactive playtest using `MVP_TEST_CHECKLIST.md`; capture current reset accounting, every implemented card, every hazard, and final-hole behavior.

## Known Audit Targets (Not Yet Playtested)

- `R` clears current-hole strokes/time but leaves already recorded total strokes intact; verify the visible and final accounting.
- The shop appears after each non-final hole rather than only after odd holes.
- Normal run completion prints a console summary without a results screen or new-run action.
- The run timer appears to advance whenever a next-level load is not in progress, including UI phases; verify pause behavior.
- The current five cards and their effects differ from the intended design pool.
- Fixed-position UI has not been checked outside the 1920×1080 target.

## 2026-08-16 — Shot Tunability Pass

- Low power shots (0-20%) are easily predictable, and move smoothly. Trajectory preview for them appears longer than intended, gives illusion of more powerful shot.
- Medium power shots (30-50%) go further than what they feel like, and have a long stopping time.
- High power shots (60-100%), in comparision, are underwhelming and feel more abrupt near the end of their roll compared to medium power shots.
- Changing friction value in inspector & in physics material seemed to have 0 effect on ball actual friction.
- Stop threshold appears especially important to very short shots.
