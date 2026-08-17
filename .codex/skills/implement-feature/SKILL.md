---
name: implement-feature
description: Implement an already specified or unambiguous feature, bug fix, polish task, or refactor in A Stroke of Luck through a complete, verified change set. Use after feature-discovery for significant gameplay work or directly for small tasks with clear acceptance criteria. Do not use for vague ideation, read-only review, architecture-wide audits, playtest triage, or integration-branch review.
---

# Implement Feature

Implement the smallest complete change that satisfies the agreed behavior while protecting the playable build.

## Chainlink Context and Updates

Follow the Chainlink control-plane rule in `AGENTS.md`; never initialize Chainlink from a feature worktree.

For issue-backed work, read the acceptance criteria, meaningful history, dependencies, and blockers from the control plane or an explicitly supplied snapshot. Stop when an open blocker prevents safe implementation. Use the acceptance criteria as the delivery contract, interpreted through authoritative project documentation.

During implementation, record from the control plane—or return ready-to-record text for—only consequential `observation`, `decision`, or `blocker` comments. Do not log routine edits. Report unrelated findings and propose separate issues; do not expand the active task unless the smallest necessary fix blocks its completion.

After `$godot-verify`, record a meaningful `result` with commands/checks run, PASS/FAIL, and remaining manual playtest or review requirements. Add a `handoff` when unfinished work needs continuation context. Do not close player-facing work before required human playtesting and review, and do not close any issue unless this workflow stage has explicit closing authority.

## Establish the Contract

1. Read `AGENTS.md` and the task-relevant project documentation. Always consult `docs/QUALITY_BAR.md`; consult `docs/ART_DIRECTION.md` for presentation work.
2. Inspect the actual implementation, current Git state, affected scenes/resources, and nearby tests before editing.
3. Derive acceptance criteria from the current conversation, approved plan, design authority, or issue. Treat `GAME_DESIGN.md` as intended behavior and `ARCHITECTURE.md` as current behavior.
4. Stop and ask only when a remaining ambiguity materially changes player experience, architecture, balance, persistence, controls, or system interaction. Use `$feature-discovery` instead if the feature is still materially underspecified.

Before editing, identify likely files, affected systems, integration points, state ownership, tuning needs, and regression risks. Resolve routine engineering decisions from the repository.

## Implement the Complete Slice

- Follow existing boundaries unless a deviation has a concrete reliability, testability, iteration, or merge-safety benefit.
- Prefer incremental changes, clear state ownership, focused components, reusable scenes where useful, data-driven `Resource` definitions where useful, and exported/configurable game-feel values.
- Avoid unrelated cleanup, speculative systems, broad rewrites, unnecessary abstractions, hidden redesigns, and hardcoded values likely to need tuning.
- Preserve the core loop and readable physics: hole play -> hole results -> shop when scheduled -> next hole -> run end.
- Keep every upgrade's benefit and curse equally explicit.

For player-facing work, cover the behavior plus relevant transitions, interruptions, failure paths, existing-system interactions, UI states, feedback, accessibility/readability, persistence, and tuning. Add audio hooks only when the project has an appropriate integration point; do not invent an audio architecture incidentally.

Use `docs/QUALITY_BAR.md` as the completion gate. Distinguish these states honestly:

- **Technically functional:** the primary code path operates.
- **Integrated:** lifecycle, related systems, edge cases, and reporting operate together.
- **Manually playtested:** a human completed the stated scenarios.
- **Polished:** feedback and presentation meet the quality and art direction in actual play.

Never claim the final two without evidence.

## Verify and Review

Invoke or follow `$godot-verify`; do not duplicate its command procedure. Add focused automated tests when the task changes deterministic rules or data validation.

Review the final diff for unrelated edits, duplicate logic, temporary/debug content, generated files, unexpected `project.godot` changes, unnecessary scene/resource churn, stale documentation, and tunable values buried in code.

## Report

Report:

- behavior delivered and important decisions;
- files/systems affected;
- automated verification performed and result;
- exact manual playtests still required;
- maturity: functional, integrated, playtested, and polished;
- known limitations and only high-value follow-up work.
