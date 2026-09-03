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
