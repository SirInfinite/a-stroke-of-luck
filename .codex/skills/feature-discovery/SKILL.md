---
name: feature-discovery
description: Inspect-first product discovery for significant gameplay ideas in A Stroke of Luck. Use when proposing or materially changing mechanics, progression, economy, upgrades, level rules, difficulty, controls, scoring, run structure, or another multi-system player-facing experience. Gather established repository truth, ask 3-7 consequential design questions, then produce acceptance criteria and a decision-complete implementation plan before any editing.
---

# Feature Discovery

Use discovery to turn a meaningful gameplay idea into an implementation-ready specification without prematurely changing the project.

## 1. Decide Whether Discovery Is Needed

Use this workflow for a new system or a change that affects player decisions, game rules, multiple systems, or the run's identity.

Skip it for a narrow bug fix, a user-specified tuning value, a mechanical refactor with no behavior change, documentation-only work, or a small presentation correction whose intended result is already explicit. If uncertain, use discovery when a wrong product assumption would cause substantial rework.

## 2. Inspect Before Asking

Do not edit files.

1. Read `AGENTS.md` and relevant parts of `docs/GAME_VISION.md`, `docs/GAME_DESIGN.md`, `docs/ARCHITECTURE.md`, `docs/QUALITY_BAR.md`, and `docs/PLAYTEST_LOG.md`.
2. Read relevant gameplay scripts, scenes, content databases, input configuration, and the current Git diff.
3. Identify established rules, reusable systems, architectural constraints, known gaps, and conflicts between design and code.
4. Resolve engineering facts through inspection. Never ask where code lives, which engine version is used, or another routine question the repository answers.

Briefly summarize the relevant current state before asking questions so the user can correct a false premise.

## 3. Ask Consequential Questions

Ask 3-7 product/design questions before planning or editing. Prefer one concise batch and structured user-input tooling when available.

Ask only questions whose answers materially change:

- player fantasy, decision, or emotional outcome;
- rules, costs, rewards, duration, stacking, or failure behavior;
- run placement, progression, difficulty, or content scope;
- information shown before, during, or after the interaction;
- accessibility, control, feedback, or learning expectations;
- acceptance thresholds or deliberate exclusions.

Offer meaningful alternatives and a recommended default when useful. Do not ask for approval of routine engineering choices that follow from existing architecture. Ask a focused follow-up if an essential answer remains ambiguous.

## 4. Produce the Discovery Result

After the user answers, produce both sections below. Do not implement the feature in the same discovery invocation.

### Acceptance Criteria

Write testable, player-observable criteria covering:

- entry conditions and the normal player flow;
- exact visible rules and state changes;
- relevant scoring, economy, upgrades, hazards, reset, and progression interactions;
- boundary, interruption, stacking, and failure cases;
- feedback and readability;
- explicit exclusions;
- manual outcomes required by `docs/QUALITY_BAR.md`.

Use Given/When/Then only where it improves precision. Avoid criteria based solely on internal implementation.

### Implementation Plan

Make the plan decision-complete. Specify affected systems and responsibilities, data/interface changes, state ownership, runtime flow, integration points, compatibility behavior, failure handling, automated checks, manual playtests, and documentation updates.

Name files only when necessary to prevent ambiguity. Distinguish design-authority changes from implementation work toward existing design.

## Chainlink Integration

Follow the Chainlink control-plane rule in `AGENTS.md`; never initialize Chainlink from a feature worktree.

Before asking questions for an existing issue:

1. Read its description, acceptance criteria, meaningful history, dependencies, and blockers from the control plane or an explicitly supplied snapshot.
2. Use the issue as problem context. Project documentation remains authoritative, and an issue comment is not an approved design decision merely because it was recorded.
3. Reuse consequential decisions already settled by the user or authoritative documentation; do not repeat resolved questions.

After the user answers, produce the agreed behavior, acceptance criteria, and implementation plan. Record from the control plane—or provide ready-to-record text for—a concise `decision` or `plan` comment containing only consequential agreed choices. Update the owning project document when a decision changes lasting design truth.

Leave implementation, verification, review, status transitions, and issue closure to later workflow stages. If discovery exposes multiple independent outcomes, recommend separate related issues or subissues instead of expanding the active issue.
