---
name: integration-review
description: Perform an initially read-only review of a branch that combines multiple completed features or refactors for A Stroke of Luck, focusing on failures created by their interaction before merging to main. Use after individual feature review and integration-branch assembly. Do not use during independent implementation, for a single-feature review, vague architecture analysis, or as the primary implementation workflow.
---

# Integration Review

Determine whether combined changes behave safely together. Do not re-review every feature from scratch; concentrate on shared assumptions and interaction failures.

## Establish the Integration Surface

1. Read `AGENTS.md`, `docs/GAME_VISION.md`, `docs/ARCHITECTURE.md`, `docs/QUALITY_BAR.md`, and available feature specifications/reviews.
2. Compare the integration branch with `main` or the user-specified base. Inspect history, the full diff, merged feature boundaries, and files edited by multiple branches.
3. State each feature's intended responsibility and shared integration points.
4. Keep the initial review read-only except for non-destructive verification.

## Inspect Interactions

Prioritize:

- **State:** duplicated ownership, stale/reset state, modifier count, and lifecycle transitions.
- **Signals/events:** duplicate or missing connections, ordering assumptions, repeated events, and irrelevant listeners.
- **Scenes/Resources:** broken references, duplicate nodes, ownership conflicts, and unintended shared Resource mutation.
- **Input/UI:** focus conflicts, UI consuming gameplay input, transition-specific controls, overlap, hidden feedback, and duplicate notifications.
- **Run flow:** hole play, completion, results, scheduled shop, next-hole construction, run end, restart, and persistence where implemented or changed.
- **Gameplay:** shot/physics, terrain, procedural generation, bonuses, curses, obstacle injection, economy, HUD, and results interactions affected by the combined work.
- **Merge quality:** duplicate implementations, conflicting architectural assumptions, central-file growth, temporary conflict fixes, unresolved markers/TODOs, and accidental resolutions.

Protect predictable physics, valid generated holes, clear bonus-and-curse communication, correct stacking, and clean run-state resets.

## Verify and Smoke-Test

Invoke or follow `$godot-verify`; do not restate its commands.

Recommend a focused manual integration smoke test based on features actually present. Usually cover launch, new run, aim/shot, affected terrain or hazard, hole completion, results when implemented, rewards, shop purchase, bonus and curse on a later hole, another transition, run end when reachable, and a fresh run with cleared state. Do not claim absent systems were tested.

## Report

Classify findings as `BLOCKING`, `HIGH`, `MEDIUM`, or `LOW`. For each include:

- affected systems;
- failed interaction and whether it is a `FEATURE BUG` or `INTEGRATION BUG`;
- evidence;
- likely consequence;
- recommended fix;
- confidence.

Finish with `INTEGRATION STATUS` and exactly one verdict:

- `SAFE TO MERGE TO MAIN`
- `SAFE TO MERGE AFTER LISTED FIXES`
- `DO NOT MERGE`

Then list `MANUAL TESTS STILL REQUIRED`. Wait for user approval before fixing anything.

## Chainlink Integration

Follow the Chainlink control-plane rule in `AGENTS.md`; never initialize Chainlink from an integration or feature worktree.

Identify represented issue IDs from the required `cl-<issue-id>` branch names, merge history, or an explicit mapping. Read each issue's intended behavior, acceptance criteria, dependencies, blockers, and material feature-review results from the control plane or supplied snapshots. Use issue state as context, then inspect the integrated code and behavior independently.

For each represented issue, classify the outcome as no new problem, feature regression, integration regression, or manual coverage remaining. Record from the control plane—or provide ready-to-record text for—significant `result` or `blocker` comments with evidence.

Do not close or mark complete any issue while integration is blocked, a dependency remains open, or required verification, human playtesting, review, or integration evidence is missing.
