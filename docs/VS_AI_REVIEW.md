# VS AI implementation and shared-course review

## Implemented boundary

This adds a scene-local competitive layer, not a second golf game. Main still routes actual GolfBall, hazard, score, reward and OOB events. Two RunStates own private builds, wallets and histories. One frozen, validated course definition and one physical LevelBuilder instance serve both turns.

The approved exception is **MATCH-COURSE effects**: both owners' course bonuses and active curses add together before generation, then existing safety clamps apply once. Placement count is bounded to four, cup scale to 55–150%. Current placement cards add direction zones. The generator's single preferred-type contract uses largest contribution, lexical tie-break for mixed future types. New effect kinds require explicit scope coverage. Private response/control/reward effects never enter shared geometry. Solo retains its original generation/effect path and generic reset behavior.

AI turn setup resets seeded mover phase, armed falling ice, pad counters/cooldowns, ramp tracking, telegraphs, ball/tee and active layer. It does not regenerate or mutate the frozen course. Expiry during the player turn cannot change the AI's course. AI shopping sees the identical offers before the player's choices and evaluates marginal shared consequences after clamps. Cards, tooltips, opponent selection and the active-course HUD disclose the rule.

## Runtime structure

```text
Main — existing active-golfer events/accounting
├─ GolfBall / LevelBuilder / hazards — unchanged rules
└─ VsMatchController — turns, cancellation, spectator clock
   ├─ VsMatchState — two RunStates, frozen courses, comparisons
   │  └─ MatchCourseRules — explicit effect scope + shared clamps
   ├─ AIShotPlanner / AICourseModel / AIDifficultyProfile — shot intents
   ├─ AICardPicker → existing ShopManager transaction
   └─ VsPresentation — snapshots and player intents
```

No networking, autoload, third-party asset, physics/economy/procgen rewrite or export was introduced. Debug diagnostics use the existing development-only HUD. Query bodies have collision layer zero and are disposed at lifecycle boundaries. Their motion tests use actual course collision masks and BallMotion; only the real ball can produce a result.

## Benchmark evidence (2026-09-07)

The benchmark uses actual GolfBall simulation and Main's accounting, not predicted scores. Player turns are explicitly synthetic harness fixtures. Four seeds (424242, 432161, 440080, 447999), all 18 positions, Normal course difficulty, and empty initial builds give 72 holes per tier. These independent holes measure baseline ability, not full-run build balance.

| Opponent | Mean strokes | Completed | Par + 4 | Max-power shots | Mean decision | Actual bank shots |
|---|---:|---:|---:|---:|---:|---:|
| Palmer / Beginner | 4.38 | 83.3% | 16.7% | 25.9% | 96 ms | 52.8% |
| Mickelson / Intermediate | 3.76 | 95.8% | 4.2% | 26.7% | 213 ms | 54.3% |
| McIlroy / Advanced | 3.47 | 95.8% | 4.2% | 28.5% | 329 ms | 62.0% |
| Woods / Expert | 3.04 | 100% | 0% | 33.3% | 460 ms | 48.4% |
| Nicklaus / Legend | 3.00 | 100% | 0% | 34.4% | 633 ms | 53.5% |

Final comparison: 360 holes, 18 ordinary forced outcomes, **zero OOB recoveries and zero timeouts**. There were 47 hazard resets. Mean power ranges from 67% to 70%; maximum-power means at least 98%. Banks are actual wall-impact events, not inferred planner intentions. Only two actual pad uses occurred in this sample; shortcut use is not separately classified. Pad strategy, rare underpasses and relative Expert/Legend strength therefore need human checks rather than a broad competence claim.

The first four rows come from `user://vs_ai_20260907/ai_final_benchmark.json`. The Legend row comes from `ai_legend_refinement.json`, rerun on the identical 72 seed/position pairs after a Legend-only local bank/landing search. The expanded sample establishes the expected average-stroke order, but the Expert/Legend gap is small. Timings include some concurrent local QA: Legend p95 was 1121 ms and worst 1550 ms, so the preferred sub-second target is not met on every difficult shot. Search remains strictly bounded (maximum observed 700 queries); hardware/pacing review is required.

A separate real-AI full match (`full_match_smoke.json`, seed 573921, Woods, Normal) completed all 18 turns with five shops, private builds, clamped shared-course curses, final histories and rematch. The AI used 54 strokes. The synthetic player used par; this is a lifecycle/integration check, **not** evidence of beating a human. An independent 864-hole generator corpus covered all biomes/positions, three difficulties and four curse states: zero validation failures/fallbacks, one rejected candidate, minimum quality 86.6. Generator source and tuning were not changed.

## Review/refinement

- Actual shot traces exposed unsafe nominal cup/bank lines; stronger opponents now probe a small execution-error envelope rather than reading their future random error. Advanced improved on the same first 36 holes from 91.7% to 97.2% completion. Legend adds at most 18 local refinement probes; no physical privileges are introduced.
- Rendered review caught clipped action labels, a missing Solo glyph, and crowded AI-card text. Buttons now size to their actual labels, the Solo glyph uses the existing hole symbol, and AI picks use separate compact tickets with benefit/curse/duration hierarchy.
- Cards retain visible curse lifetime while explicitly stating both-golfer scope. Dark/light rendered fixtures cover selection/setup, both turn HUDs, chosen aim, comparison, shared shop, purchase reveal, shared-course HUD, final builds and Solo regression. Screenshots are not human approval.
- Fast navigation tests caught deferred focus targeting removed controls. Focus now validates a live, visible instance. Ramp/telegraph cleanup is VS-specific so Solo's existing reset dispatch stays unchanged.
- Outcome audio is requested after transient turn cleanup, using the completed golfer's captured success/failure result. This prevents the player celebration being immediately silenced or replaced by the next golfer's stale outcome.

## Reproduction and verification surface

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .codex/skills/godot-verify/scripts/verify_godot.ps1
godot4 --headless --path . --script addons/gut/gut_cmdln.gd -gtest=res://tests/test_vs_match.gd -gexit
godot4 --headless --path . --fixed-fps 60 --script res://tests/vs_ai_benchmark.gd -- --seeds=4
godot4 --headless --path . --fixed-fps 60 --script res://tests/vs_full_match_smoke.gd
godot4 --path . --fixed-fps 60 --script res://tests/vs_visual_review.gd -- --size=1280x720
```

Benchmark options include `--opponents=woods`, zero-based `--holes=4,11`, `--speed=1/2/4/8`, and `--output=user://...`. Compare decisions, actual endpoints and scores across speeds, excluding performance timestamps. Skip runs the same fixed-step physics at 8×; it never synthesizes a result. Gameplay forecasts remain approximations for interacting surfaces/ramps/movers and repeated pad contacts. A predicted line is not a physics proof.

`test_vs_match.gd` covers all eight shared-course acceptance requirements, scope enumeration, expiry freezing, common shop transactions and deterministic choices, private modifiers, real simple-hole completion, static-water avoidance, observed timing, reset ownership, OOB accounting, clock restoration and full lifecycle/rematch. Canonical verifier output remains the authority for current import/startup/full-suite totals; `vs_tests.log` records focused totals. `MVP_TEST_CHECKLIST.md` owns the pending human VS checklist.

No commit or exported build is part of this change. Human opponent-quality, timing, watch-mode audio/UX and Solo/Tutorial regression checks remain release gates.
