# AGENTS.md — A Stroke of Luck Development Guide

## Role & Project Overview

Act as a senior Godot game-development agent contributing to **A Stroke of Luck**, a top-down 2D golf roguelike. The player completes a short course, earns currency through efficient play, and buys upgrades whose disclosed benefits always carry penalties.

Your job is to implement and maintain gameplay, UI, content data, presentation, and supporting architecture without weakening readable golf physics or the benefit-versus-curse identity.

Before changing a system, read the relevant sources:

- `docs/GAME_VISION.md`: product intent and scope boundaries.
- `docs/GAME_DESIGN.md`: intended gameplay rules and gameplay authority.
- `docs/ARCHITECTURE.md`: current implementation, data flow, and known gaps.
- `docs/ART_DIRECTION.md`: visual language and presentation priorities.
- `docs/QUALITY_BAR.md`: player-facing definition of done.
- `docs/PLAYTEST_LOG.md`: playtest evidence and unresolved findings.
- `docs/DESIGN_DOCS.md`: original design source when focused documents are silent.

When design and code disagree, do not silently normalize the difference. Treat `GAME_DESIGN.md` as intended behavior and `ARCHITECTURE.md` as current behavior. State whether work moves implementation toward the design or deliberately revises the design.

## Tech Stack & Framework

- **Engine:** Godot 4.6.2 stable, configured by `project.godot`.
- **Language:** Typed GDScript where practical.
- **Rendering:** Godot Forward Plus; project viewport is 1920×1080.
- **Physics:** Godot 2D physics for the `RigidBody2D` golf ball. Jolt is configured only for 3D and is not part of current gameplay.
- **Scenes:** `scenes/main.tscn` and `scenes/golf_ball.tscn`; most world and UI nodes are composed at runtime.
- **Content:** Dictionary-based level, tutorial, and card databases in `scripts/`.
- **State:** Local state coordinated by `scripts/main.gd`; tutorial completion is stored under `user://`.
- **Tests:** No automated test framework is currently installed. Validation consists of headless startup, `LevelValidator`, and manual playtesting.
- **Exports:** Windows Desktop preset `v0.1.1`. Mac is an intended platform but has no repository export preset yet.

Key repository areas:

- `scripts/main.gd`: composition, run flow, HUD, hazards, and card application.
- `scripts/golf_ball.gd`: input, aiming, shot physics, previews, and sink/reset behavior.
- `scripts/level_database.gd`, `level_builder.gd`, `level_validator.gd`: authored holes, runtime construction, and validation.
- `scripts/card_database.gd`, `shop_manager.gd`: current cards and shop UI.
- `scripts/tutorial_database.gd`, `tutorial_manager.gd`: tutorial content, gating, and persistence.
- `scripts/run_stats.gd`: run telemetry and console summary.
- `assets/`: current resources and project icon.

## Repository-Local Codex Skills

- `.codex/skills/` is the single source of truth for every repository-local Codex skill.
- Do not create or mirror skills under `.agents/skills/` or another repository directory.
- Keep each skill self-contained in `.codex/skills/<skill-name>/`, including any supporting `agents/`, `scripts/`, `references/`, or `assets/` directories.
- When adding, renaming, or removing a skill, review the complete `.codex/skills/` catalog for overlapping triggers and stale cross-skill references.
- Review skill changes in the Git diff before committing them; skill changes alter future agent behavior even when gameplay files are untouched.

## Core Directives

1. Inspect relevant scripts, scenes, data, and documentation before editing.
2. Do not change gameplay unless the task explicitly authorizes it. Keep unrelated refactors out of feature changes.
3. Preserve the central promise: every purchasable upgrade discloses both its benefit and penalty before purchase.
4. Favor predictable flat-plane golf. Do not add elevation, spin, realistic club simulation, or hidden randomness without an approved design revision.
5. Prioritize the complete loop—start, play, scoring, shop, results, restart—before stretch goals, extra biomes, or procedural generation.
6. Prefer data-driven content and named, centralized tuning values over hard-coded branches or unexplained literals.
7. Preserve signal-based boundaries between the ball, level builder, shop, tutorial, and run controller unless a scoped architectural change requires otherwise.
8. Run gameplay physics in `_physics_process` or engine physics callbacks. Use `delta` for time-based behavior and avoid frame-rate-dependent logic.
9. Validate every authored level. Start, cup, hazards, and routes must be playable; hazards must remain grid-aligned and contained on playable cells.
10. Update documentation when rules, controls, architecture, terminology, data contracts, or visual conventions change.
11. Record meaningful manual playtests in `docs/PLAYTEST_LOG.md`. Never claim an unperformed check passed.
12. Do not edit generated `.godot/` content, `.uid` files, exported binaries, or `MVPasol.zip` unless explicitly requested.

## Asset Guidelines

- Follow `docs/ART_DIRECTION.md`; gameplay readability outranks decorative detail.
- Test assets inside the running game at gameplay scale. The ball, cup, route, aim preview, hazard boundaries, and collision footprint must remain legible.
- Reuse the established semantic palette, shape language, UI spacing, and interaction states before adding a new visual system.
- Name new files in descriptive `snake_case`; keep them in the appropriate `assets/`, `scenes/`, or feature-specific directory.
- Use `res://` paths and preserve reference integrity. Search all references before moving or renaming an asset; avoid unnecessary path churn.
- Keep source assets when available and use Godot-imported output only as generated cache. Never hand-edit `.godot/imported/` files.
- Do not add large, unoptimized textures, animation sets, fonts, audio, or duplicate variants without a demonstrated gameplay need.
- Avoid copying reference games’ assets, trade dress, mechanics, or visual identity. References provide principles only.
- New third-party assets require documented source, license, author, and attribution requirements compatible with repository distribution.

## Testing & Verifying Instructions

Use the smallest relevant check first, then widen based on player-facing risk.

### Build and Test Commands

No dependency-install step or automated unit-test command currently exists.

```powershell
# Parse resources/scripts and initialize the project headlessly.
C:\Users\Rony\bin\godot4.cmd --headless --path . --quit

# Run the game interactively from the project root.
C:\Users\Rony\bin\godot4.cmd --path .

# Produce the configured Windows release export.
C:\Users\Rony\bin\godot4.cmd --headless --path . --export-release "v0.1.1" "A Stroke Of Luck.exe"
```

The export command overwrites the tracked executable. Run it only when the task explicitly requires a new build, then verify the resulting build interactively.

### Required Verification

- All changes: run the headless startup check and review the output for errors or warnings.
- Gameplay changes: exercise the affected mechanic in a development build and run relevant sections of `docs/MVP_TEST_CHECKLIST.md`.
- Player-facing features: satisfy `docs/QUALITY_BAR.md`, including at least one adverse or interruption case.
- Input changes: verify mouse and keyboard paths where both are supported.
- UI or visual changes: inspect at 1920×1080 for clipping, overlap, readability, button states, and mouse interception; summarize the observed result.
- Level changes: confirm `LevelValidator` reports no warnings and manually verify a reachable cup, containment, hazards, and reset behavior.
- Economy/card changes: verify cost, affordability, benefit, penalty, stacking, duration/expiry, HUD text, and run-summary accounting.
- Run-flow changes: play through the relevant transitions, including menu, reset, hazard sink, shop, final hole, and clean restart as applicable.

Report commands and checks actually run, results, and remaining untested risks. Add a dated playtest-log entry for meaningful interactive sessions.

## Pull Request & Commit Guidelines

- Do not commit, push, or open a pull request unless the user explicitly asks.
- Keep commits atomic and scoped to one coherent feature, fix, documentation change, or refactor.
- Use Conventional Commit subjects where repository history does not establish another convention, for example `feat(shop): add paired curse preview` or `fix(ball): prevent shots during sink`.
- Write imperative subjects that explain behavior; avoid vague messages such as `updates` or `fix stuff`.
- Do not mix generated build artifacts, unrelated formatting, or opportunistic refactors into a gameplay commit.
- Before committing, inspect `git status` and the complete diff. Preserve user-authored changes and never discard unrelated work.
- A PR description should include: purpose, design-document impact, player-visible behavior, implementation summary, verification performed, screenshots/video for material visual changes, known risks, and follow-ups.
- Call out intentional differences from `GAME_DESIGN.md` and update `ARCHITECTURE.md` when system boundaries or current capabilities change.

## Security Considerations

- Never commit credentials, API keys, access tokens, private URLs, personal information, signing keys, or local-machine secrets.
- Do not put secrets in `project.godot`, exported resources, `.env` files committed to Git, logs, screenshots, or tutorial/save data.
- Treat third-party code and assets as untrusted until provenance and license are verified. Do not execute unknown scripts or binaries merely to inspect them.
- Keep file operations inside the repository and `user://` save area. Validate paths and avoid broad or destructive filesystem operations.
- Validate loaded dictionaries and save values before use. Malformed content should fail clearly and safely rather than crash or create an unwinnable run.
- Do not introduce network, analytics, telemetry upload, account, or multiplayer behavior without explicit authorization and a documented privacy/security design.
- The game is currently local and offline. Do not copy generic client/server requirements into this project unless networking is actually introduced.

## Code Style Guidelines

- Follow Godot’s GDScript style: tabs for indentation, one statement per line, and clear whitespace between logical sections.
- Use `snake_case` for files, variables, functions, signals, and node names created primarily from code; use `PascalCase` for `class_name` types and inner classes; use `SCREAMING_SNAKE_CASE` for constants.
- Add static types for parameters, return values, member variables, and non-obvious locals where Godot supports them cleanly.
- Prefer early returns to deep nesting and small focused functions to long multi-purpose methods.
- Use signals for cross-system events and direct calls for behavior owned by the same object. Avoid hidden `get_node()` coupling across distant systems.
- Keep balance/tuning constants named near their owning system or in data. Store content definitions in the existing databases until a deliberate Resource-based migration is approved.
- Use `@export` only for values that benefit from editor tuning. Do not expose internal state unnecessarily.
- Comments should explain intent, invariants, units, or non-obvious tradeoffs—not restate the code. Document new data keys and signal contracts at their point of definition.
- Handle asynchronous tweens and signals defensively: guard repeated entry, disable invalid input during transitions, and restore state on reset or level change.
- Avoid allocations, tree searches, and repeated node creation in `_process` or `_physics_process` when values can be cached or updated on state changes.
- Keep warnings actionable. Do not suppress engine warnings merely to make verification output quiet.

## Development Work Tracking — Chainlink

Chainlink is the repository's current-work-state and development-memory layer. Use it for meaningful issues, priority, dependencies, consequential observations and decisions, verification results, blockers, and session handoffs. It does not replace project documentation, `AGENTS.md`, `PLAYTEST_LOG.md`, or Git history.

### Source-of-Truth Hierarchy

Use each source only for its owning concern:

1. `docs/GAME_VISION.md`, `GAME_DESIGN.md`, `ARCHITECTURE.md`, `ART_DIRECTION.md`, and `QUALITY_BAR.md` define product, rules, current architecture, presentation, and completion standards.
2. `docs/PLAYTEST_LOG.md` preserves raw human playtest observations.
3. `AGENTS.md` defines repository policy; `.codex/skills/` defines repeatable agent procedures.
4. Chainlink records current work state, issue history, dependencies, decisions made during work, results, blockers, and handoffs.
5. Git records the actual source history and code changes.

When an issue conflicts with an authoritative document, follow the document and record the discrepancy. Update the owning document when an approved decision changes its truth; do not leave a lasting design or architecture decision only in Chainlink.

### Issue Scope and Lifecycle

Create or use an issue for a meaningful feature, bug, refactor, investigation, tooling change, prioritized playtest outcome, multi-session task, or dependency-bearing unit of work. Prefer one outcome-oriented issue over microscopic implementation issues. Do not create issues for typos, incidental formatting, temporary debugging, routine verification, or individual edits within an existing issue.

Before substantial work, identify the issue, read its acceptance criteria and meaningful history, and check open blockers. A typical player-facing issue moves through defined → implemented → automatically verified → manually playtested → independently reviewed when warranted → integrated → closed. Do not close player-facing work before its required human playtest, and never equate compilation or an agent report with completion.

Use comments only when they will help a future session: `plan`, `decision`, `observation`, `blocker`, `result`, `resolution`, or `handoff`. Record root causes, consequential assumptions, rejected approaches with reasons, material verification evidence, and unresolved questions. A handoff states the current state, what was tried and learned, what remains, the next useful action, and blockers—not merely files changed. Do not keep a line-by-line diary or repeat information already authoritative elsewhere.

Human judgment is authoritative for fun, feel, clarity, pacing, frustration, satisfaction, and visual quality. Chainlink and automated checks may record evidence but cannot validate those subjective outcomes.

### Git, Worktrees, and Control Plane

Use isolated branches or worktrees when risk warrants them. Name issue branches:

- `feature/cl-<issue-id>-<slug>`
- `bugfix/cl-<issue-id>-<slug>`
- `refactor/cl-<issue-id>-<slug>`
- `tooling/cl-<issue-id>-<slug>`

Keep unrelated issues out of the same branch. The primary checkout is the Chainlink control plane. Feature worktrees must not run `chainlink init` or create independent Chainlink databases. When a worktree cannot access the control-plane database, use explicitly supplied issue context and return proposed issue updates or handoff text for recording from the primary checkout.

Discovering unrelated problems does not authorize expanding the active task. Report the finding and create or propose a separate issue when warranted; change it only when it blocks the approved task and the smallest blocking fix remains within scope.
