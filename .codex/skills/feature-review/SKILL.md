---
name: feature-review
description: Perform an independent, skeptical, initially read-only review of one completed feature or change set in A Stroke of Luck before branch acceptance. Use especially from a fresh agent after implementation and verification. Do not use to implement the feature, audit the whole architecture, triage playtests, re-review a combined integration branch, or justify theoretical rewrites.
---

# Feature Review

Review whether one change is safe, complete, maintainable, and good for the player. Keep the first pass read-only and independent from the implementation agent's conclusions.

## Establish Intent and Evidence

1. Read `AGENTS.md`, `docs/GAME_VISION.md`, `docs/ARCHITECTURE.md`, `docs/QUALITY_BAR.md`, and task-relevant design. Read `docs/ART_DIRECTION.md` when presentation is involved.
2. Identify the feature's specification and acceptance criteria. If unavailable, state the inferred contract and lower confidence rather than inventing requirements.
3. Inspect the branch, relevant diff and history, surrounding implementation, affected scenes/resources, tests, and existing verification evidence.
4. Do not modify files. Invoke `$godot-verify` only as non-destructive evidence; do not repeat its procedure here.

## Review the Change

Check only material risks:

- **Correctness:** broken states, incorrect assumptions, edge cases, regressions, and failure handling.
- **Godot:** node ownership, scene paths, signal lifecycle, process-loop cost, shared/mutated Resources, input handling, persistence, and hidden scene dependencies.
- **Architecture:** duplicated truth, misplaced responsibility, tight coupling, unnecessary global state or complexity, and violations of established boundaries.
- **Game quality:** unclear state or consequences, incomplete feedback/transitions, weak tunability, inconsistent presentation, and interactions that remain prototype-like.
- **Testing:** missing high-value coverage, weak assertions, untested failure paths, and subjective claims presented as automated facts.
- **Scope:** unrelated cleanup, speculative additions, accidental behavior changes, temporary files, and unnecessary refactors.

Do not request cleanup merely because another pattern is aesthetically preferable.

## Report Findings

Order findings by severity:

- **BLOCKING:** likely breakage, corrupted state, severe regression, or unsafe merge.
- **HIGH:** material correctness, architecture, maintainability, or player-experience harm.
- **MEDIUM:** worth fixing before or soon after merge.
- **LOW:** minor cleanup or optional improvement.

For every meaningful finding provide: title, severity, affected file/system, evidence, consequence, recommended fix, and confidence (`High`, `Medium`, or `Low`). Separate observed defects from hypotheses.

Include `KEEP AS IS` and name sound choices that should survive review.

Finish with exactly one verdict and rationale:

- `MERGE READY`
- `MERGE READY WITH MINOR FOLLOW-UP`
- `NOT MERGE READY`

After presenting the review, wait. Modify only user-approved findings in a later turn.

## Chainlink Integration

Follow the Chainlink control-plane rule in `AGENTS.md`; never initialize Chainlink from a feature worktree.

For issue-backed review, read the issue's acceptance criteria, approved decisions, dependencies, implementation observations, and prior results from the control plane or an explicitly supplied snapshot. Use them to understand intent, not as proof: independently inspect the diff, code, scenes/resources, and test evidence.

After the read-only pass, record from the control plane—or provide ready-to-record text for—a concise `result` containing the review verdict and material findings. Leave the issue open when findings block acceptance, required human playtesting is incomplete, or review evidence is insufficient. Route unrelated findings to separate issues rather than expanding the reviewed feature. Do not close an issue unless closing authority is explicitly assigned after all required gates.
