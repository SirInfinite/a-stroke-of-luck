---
name: godot-verify
description: Repeatable verification for the A Stroke of Luck Godot repository. Use after code, scene, resource, level, UI, gameplay, or documentation changes; when diagnosing parser/runtime/resource failures; or when asked to test, validate, review, or report repository readiness. Resolve the installed Godot executable, import and briefly launch the project, run available tests, inspect all relevant Git changes, and report PASS, FAIL, and manual playtesting requirements.
---

# Godot Verify

Verify evidence, not assumptions. A clean headless launch proves startup only; it never proves gameplay correctness or feel.

## 1. Establish Scope

Read `AGENTS.md` and identify the requested change. Unless the user names another comparison, review all working-tree changes: staged, unstaged, and untracked. Preserve unrelated user work and do not modify source files while verifying.

## 2. Run the Automated Baseline

From the repository root, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .codex/skills/godot-verify/scripts/verify_godot.ps1
```

The runner resolves Godot, prints its version, imports the project, launches the main scene for three iterations, runs GUT tests when installed, checks Git whitespace, and inventories changes. Pass `-ProjectPath` or `-GodotPath` only for another checkout or executable.

Treat a nonzero exit as `FAIL`. Read the full output; do not rely on exit code alone.

## 3. Run Additional Available Tests

Inspect `AGENTS.md`, addons, and test directories for test commands the runner does not recognize. Run documented tests applicable to the changed system. If test-like files exist without a runnable framework or documented command, report them as unconfigured rather than passed.

Do not export or overwrite `A Stroke Of Luck.exe` unless explicitly requested.

## 4. Review the Actual Diff

Inspect, do not merely summarize:

```powershell
git diff --check
git diff --
git diff --cached --
git status --short
```

Open every relevant untracked text file because ordinary `git diff` omits it. Review for unintended gameplay/data changes, parser/type/resource/path errors, stale scene/signal references, incorrect state lifetimes, documentation mismatches, missing verification, generated files, binaries, credentials, and unrelated changes.

Diff review may fail verification even when Godot exits successfully.

## 5. Determine Manual Coverage

Use `docs/QUALITY_BAR.md` and relevant `docs/MVP_TEST_CHECKLIST.md` sections. Require manual playtesting for physics feel, collisions, hazards, scoring, economy, card stacking, run progression, input, interruption timing, UI/visual presentation, tutorial comprehension, full-run behavior, and exported-platform behavior as applicable.

State the exact scenario, expected result, input method, and display/build conditions needed.

## 6. Report the Verdict

Always report:

### PASS

List each successful automated command and supported conclusion.

### FAIL

List command failures, error signatures, failed tests, and blocking diff findings with evidence. Write `None` when empty.

### MANUAL PLAYTEST REQUIRED

List unverified player-facing scenarios. Write `None` only when no material interactive or visual behavior changed.

End with `OVERALL: PASS` when automation and diff review pass, or `OVERALL: FAIL` when any automated check, test, or blocking diff review fails. Manual requirements remain separate unless attempted and failed.

## Chainlink Integration

Follow the Chainlink control-plane rule in `AGENTS.md`; never initialize Chainlink from a feature worktree.

For issue-backed verification, record from the control plane—or provide ready-to-record text for—a concise `result` when the outcome will help later work. Include commands/actions performed, PASS/FAIL, important errors, relevant tests and scenarios, and the exact subjective or manual checks still outstanding.

Do not close or otherwise complete the issue. A PASS covers only the checks actually run; it does not verify game feel, fun, pacing, clarity, visual quality, or another unperformed human judgment.
