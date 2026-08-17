---
name: playtest-triage
description: Convert actual human playtest observations for A Stroke of Luck into a prioritized, evidence-aware development backlog while preserving subjective meaning. Use when the user supplies playtest notes or asks to triage recent PLAYTEST_LOG findings. Do not use for general ideation without playtest evidence, code review, implementation, technical verification, or integration review.
---

# Playtest Triage

Turn human observations into focused development decisions. Human playtest evidence is authoritative for feel, clarity, fun, and pacing; it is not automatically proof of a technical cause.

## Gather Evidence

Read the newest relevant entries in `docs/PLAYTEST_LOG.md`, plus `docs/GAME_VISION.md`, `docs/GAME_DESIGN.md`, and `docs/QUALITY_BAR.md`. Include notes supplied in the conversation and distinguish tester, build, environment, and frequency when known.

Preserve the observation's meaning. For example, keep "short shots feel difficult to control" as an observed player-experience problem until investigation establishes why.

## Triage

Group evidence under:

- `BUGS`
- `GAME FEEL`
- `UX / CLARITY`
- `BALANCE`
- `PACING`
- `POLISH / FEEDBACK`
- `CONTENT`
- `TECHNICAL / ARCHITECTURE`
- `NEW FEATURE IDEAS`

For each actionable item separate:

- **Observed symptom:** what occurred or was felt.
- **Possible cause:** a labeled hypothesis, not fact.
- **Proposed action:** investigation, experiment, fix, or discovery task.

Estimate:

- player impact: `Critical`, `High`, `Medium`, `Low`;
- frequency: `Constant`, `Common`, `Occasional`, `Rare`, `Unknown`;
- confidence: `High`, `Medium`, `Low`;
- effort: `Small`, `Medium`, `Large`;
- priority: `P0`, `P1`, `P2`, `P3`.

Prioritize blocked play, the core shot, repeated frustration, confusing feedback, run-wide problems, obscured bonus/curse decisions, and cohesion. Prefer improving existing experience over adding systems unless evidence supports the new feature.

For weak evidence, request a focused replay, reproduction, instrumentation, deterministic seed, logging, or experiment. Do not inflate priority because an idea sounds exciting.

## Output

Use these sections:

1. `PLAYTEST SUMMARY`
2. `TOP 3 PROBLEMS`
3. `PRIORITIZED BACKLOG`
4. `NEEDS MORE EVIDENCE`
5. `POSITIVE SIGNALS` - preserve what players liked.
6. `SUGGESTED NEXT TASK`

Route the next task to `$feature-discovery` when a design decision remains open, or `$implement-feature` when behavior and acceptance criteria are already clear.

If `PLAYTEST_LOG.md` needs an entry, propose text first and preserve all prior observations. Do not edit or implement during triage unless separately requested later.

## Chainlink Integration

Keep raw human observations in `docs/PLAYTEST_LOG.md`; Chainlink stores only actionable outcomes derived from that evidence. Follow the Chainlink control-plane rule in `AGENTS.md` and never initialize Chainlink from a feature worktree.

Before proposing an issue, search open and closed issues for conceptual duplicates by player symptom or desired outcome, not only exact wording. Add material new evidence to an existing issue when it represents the same problem.

For each proposed or updated issue, preserve three separate fields of reasoning:

- observed symptom from the playtest record;
- hypothesized cause, explicitly labeled and confidence-rated;
- proposed investigation or solution.

Title an issue around the player problem or outcome—such as `Improve control of very short shots`—unless evidence has established a technical cause. Carry over player impact, frequency, confidence, priority, and a reference to the relevant playtest entry. Prioritize impact and dependencies over novelty. Record from the control plane or return ready-to-record issue text; do not replace or rewrite the raw playtest record.
