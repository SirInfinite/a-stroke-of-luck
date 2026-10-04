# Local repository consolidation — 2026-10-04

Use **`C:\Users\Rony\Projects\a-stroke-of-luck-consolidated`** on **`integration/consolidated-20261004-000614`** for further game development and testing. The accepted implementation is `b0567da2fb0287190ab809b612bdad6a13220c47`; the subsequent report commit adds this handoff and verification notes. Obtain the current exact tip with `git rev-parse HEAD` in that directory.

```powershell
godot4 --path "C:\Users\Rony\Projects\a-stroke-of-luck-consolidated"
# To edit, open this same project with Godot 4.6.2, then use F5.
```

The normal entrypoint remains `res://scenes/main.tscn`. This result preserves top-down golf, procedural generation, hazards, six biomes, shops, Solo and VS AI, the approved logo, Jersey 10, complete pixel card silhouettes, course-following backgrounds, and the single tee owned by LevelBuilder. Native GolfBall/LevelBuilder/LevelValidator and signal ownership remain intact. No engine upgrade, export, push, release, issue closure, existing-history rewrite, branch/worktree deletion, or stash consumption occurred.

## Initial inventory and ownership

Git was `2.53.0.windows.1`. No other implementation agent, active editing job, existing Git operation, unresolved index, or Git lock was observed. File/index stability was checked before recovery writes. GitHub Desktop, idle terminals, and a Godot 4.7.2 Project Manager were left running; no unsaved editor content was touched. No detached HEAD or submodule was found. Existing project records did not identify another active independent clone. Historical extracted source under `.export/` is archived release material, not a separate active checkout. The only configured remote is `origin` (`SirInfinite/a-stroke-of-luck` on GitHub); no fetch or push was performed.

Paths below are under `C:\Users\Rony\Projects\` unless stated otherwise. Counts distinguish staged, unstaged, and untracked entries; the same path can appear in multiple categories.

| Initial checkout | Original branch | Original HEAD | Staged / unstaged / untracked | Purpose / access |
|---|---|---|---|---|
| `a-stroke-of-luck` | `release/7-hour-ship` | `e2459b3495f57689a5ec493cb71e4e66816a3029` | 6,153 / 98 / 1,599 | Shared accumulated production, samples, tests, documentation and review captures; fully accessible |
| `a-stroke-of-luck-audio` | `ship/audio-revision` | `dd8362be70e106ad2ea4cd293349166c5a0c3c1b` | 0 / 0 / 0 | Earlier audio work, already in release ancestry |
| `a-stroke-of-luck-gameplay` | `ship/gameplay-revision` | `83ce118fc2c340eb68d8fc604e6f12a882d8a9c4` | 0 / 0 / 0 | Earlier generation/gameplay work, already in release ancestry |
| `a-stroke-of-luck-visual` | `ship/visual-revision` | `617b9707437b9d017c904da3fc22e855dceeb9ca` | 0 / 0 / 0 | Earlier visual work, already in release ancestry |

The primary also had 3,823 ignored entries. Chainlink's `locks list` command unexpectedly created an auxiliary `chainlink/locks` branch and `.chainlink/.locks-cache` worktree at `9315f444653d3ebf7b5248bbdbff99ca9d0227bf` during inspection. That runtime-only checkout is separately backed up, remains clean, and was not integrated into the game. No further lock-management commands were used. This is an inspection side effect, not a previously hidden game workstream.

## Recovery material

Private backup root: **`C:\Users\Rony\Projects\_recovery\a-stroke-of-luck\20261004-000614`**. It sits outside the tracked checkouts. Its ACL grants the user and SYSTEM access; do not publish its config, tracker data, or raw logs.

- `initial-inventory.json`, `branches.txt`, `refs.txt`, `history.txt`, and `stashes.txt` retain original paths, full IDs, operations and file inventories.
- `worktrees/<name>/files/` contains raw working files, source/assets, supplied references, ignored import sidecars, review recordings, and private local runtime data. Every copied file was SHA-256 verified. The primary copy contains 9,508 files / 5,799,525,597 bytes; the three original linked copies contain 767, 771 and 763 files respectively. The auxiliary lock checkout has one file.
- The initial primary `staged.patch` (3,440,947,906 bytes) and `unstaged.patch` (151,515,757 bytes) were written directly from Git stdout as binary data. They retain binary changes without PowerShell encoding conversion. Original indexes, refs, reflogs and relevant repository state are under `git-state/`.
- Durable `refs/recovery/20261004-000614/` references protect original local/remote tips, tags, worktree HEADs and all three stash commits. `recovery-refs.json` lists exact names and IDs.
- `history.bundle` is the verified complete initial Git history backup. `consolidated-history.bundle` is the separately verified final history backup, including checkpoints and integration. Neither replaces the raw working-file backup.
- `export-archive/` separately preserves all 1,103 files / 599,214,420 bytes under the original `.export/`; `export-checksums.json` verifies each copy. Original exports were not rebuilt or overwritten.
- Only regenerable `.godot/`, `.import/` and `__pycache__/` directories were omitted from raw copying; they remain in their original locations. `EXCLUSIONS.md` explains this and the complete supplemental export coverage. No repository LFS paths or pointer assets were found; installed global LFS filters are unused here.
- `checkpoint-manifest.json` lists all 1,015 deliberately committed production/development paths. `outside-git-accounting.json` gives an exact path and exclusion reason for all 6,835 changed files kept outside the checkpoint. `imported-file-accounting.json` compares the integrated files to raw source bytes; all 422 binary assets match exactly.
- A redundant combined HEAD patch was stopped after excessive duplication and retained as `redundant-combined.partial`. It is incomplete and **must not be used for recovery**. Both required separate patches and raw/index backups are complete.

To recover committed history, clone the appropriate bundle into a **new** directory or fetch its recovery refs into an isolated repository. Select the recorded original tip or a named checkpoint. Recover raw files from the corresponding `worktrees/<name>/files/` directory, checking the accompanying checksums. To reconstruct original staging, use the saved original index and separate patches in an isolated copy; do not overwrite the current live index blindly. All original stashes remain available by the stable IDs below and can be applied without dropping them in a new worktree at their recorded base.

## Checkpoints and integration sequence

1. Created `recovery/20261004-000614-production` at the original release tip before committing the primary's work. The original release branch remains at `e2459b3`. Reviewed source/assets/tests/docs were committed together because they form the shared accumulated workstream; no worker histories were invented.
2. **`8646d01d1940c1a28576326bbe03c28ac65ba968`** — `chore(recovery): checkpoint accumulated production and review source`: 1,015 paths, including required production assets, existing UID metadata, font licenses/provenance, development samples and verification tools. This was initially a preservation checkpoint, not readiness certification. Thousands of staged captures were unstaged only after raw/index backup; their files remain intact.
3. Started a clean dedicated integration checkout from the established release lineage, then a trial branch. The release already contained the three ship workstreams; current dirty source and the 2026-09-24 production art decision contained the newer native production implementation. This evidence determined the baseline rather than branch age/name alone.
4. **`557788d6f0138cdd2297fbe839c222dec8f352c0`** — ordinary inspected merge of the production checkpoint (`--no-ff --no-commit` before acceptance). There were no semantic merge conflicts. Six license/prompt files received whitespace-only normalization; their words and all binary assets were retained.
5. **`f6e207cb0b1dfd0d86ba647c8edb6451292d788a`** — selectively recovered unique raw 2026-08-16 shot-tuning observations from `fd41ff7`; old physics were not adopted. **`1c20ed4`** corrects a Windows text-decoding mistake made during that append. The final log equals the pre-append UTF-8 bytes plus the ten new historical lines; the correction is explicit history, not a rewrite.
6. **`1079e7c2b9dbee7209a98bdd4c071be05ba44b88`** and **`b0567da2fb0287190ab809b612bdad6a13220c47`** repair the archived vector reproduction tool. Its original export palette is now independent of the newer runtime UI palette; ART_DIRECTION records the distinction. The first repair omitted one toggle color, caught by its check and added in the second. Existing SVG/raster art, the approved logo, fonts and runtime colors remain byte-identical. Final check: 154 reproducible outputs. No gameplay redesign was needed.
7. In `a-stroke-of-luck-stash-recovery`, applied stable stash `41f4432` with its original index at base `3fff9fc`, without consuming it. **`5227578d5f9b47e938dbae97f2203a8b05d04868`** — `chore(recovery): preserve earlier combined release stash`: 89 reviewed paths on `recovery/20261004-000614-stash0`. This older alternative was verified separately and preserved, not merged back over newer behavior.
8. The trial passed full automated, rendered, generation and VS AI verification before `integration/consolidated-20261004-000614` advanced by fast-forward to the accepted result. The trial branch remains as evidence. The final documentation commit records the handoff; no existing commit was rebased, squashed or rewritten.

No central architecture conflict met the escalation condition, so isolated Max review was unnecessary.

## Candidate accounting

Classification uses ancestry plus actual source comparisons, stash reconstruction, current contracts and feature tests. Remote-tracking aliases are grouped with their identical source tips.

| Source | Original tip | Final classification | Reason / disposition |
|---|---|---|---|
| `main`, `origin/main`, `origin/HEAD` | `ee8db371f8d70062e117d6a690b46db537d356b9` | ALREADY INCLUDED | Established production ancestry; unchanged |
| `dev`, `origin/dev` | `6192df1e2d973f5ee16b85a44b92e891acb6f2da` | ALREADY INCLUDED | Ancestor of release and consolidation |
| `release/7-hour-ship` | `e2459b3495f57689a5ec493cb71e4e66816a3029` | ALREADY INCLUDED | Baseline; original tip and alpha tag unchanged |
| `feature/hazards-plus`, `feature/upgrades-plus` | `f8acf64b0599423e8fa12f50e6b68e1b3a3b03db` | ALREADY INCLUDED | Identical branch tips and release ancestors |
| `ship/audio-revision` | `dd8362be70e106ad2ea4cd293349166c5a0c3c1b` | ALREADY INCLUDED | Already merged into release; newer audio in production checkpoint |
| `ship/gameplay-revision` | `83ce118fc2c340eb68d8fc604e6f12a882d8a9c4` | ALREADY INCLUDED | Already merged into release; current generation/physics retained |
| `ship/visual-revision` | `617b9707437b9d017c904da3fc22e855dceeb9ca` | ALREADY INCLUDED | Already merged; approved newer native pixel presentation retained |
| `tooling/cl-2-workflow-baseline` | `d96723031cfef363fbf29a64e401c9ed8cfec300` | ALREADY INCLUDED | Existing workflow ancestry |
| `tooling/cl-23-bmad-integration` | `1d52748d0e757e62ce45899d022099353992bc23` | ALREADY INCLUDED | Existing tooling ancestry; no new imported architecture adoption |
| `origin/tooling/cl-4-gut-characterization` | `c5bff3e39189b00b9b1680ab1c4ab0bbcffed304` | ALREADY INCLUDED | Test lineage already in release |
| Primary production recovery checkpoint | `8646d01d1940c1a28576326bbe03c28ac65ba968` | MERGED | Ordinary merge retains the full checkpoint history and current production files |
| `feature/cl-1-shot-tuning`, `origin/feature/cl-1-shot-tuning` | `fd41ff7386523a04f3dc234ff1b04f7d793236a0` | PARTIAL / code SUPERSEDED | Unique human observations recovered; older export renames and 1000-friction / 377.55 PhysicsMaterial experiment conflict with current documented, tested physics. Branch retained |
| `feature/ui-rehaul`, `origin/feature/main-menu` | `a25d3ac5dcc2a83fd262d6bd957375a0c013ae1b` | SUPERSEDED | Older title/AudioManager placeholders and asset reorganization replaced by native title, current audio lifecycle and approved pixel production assets; retained as alternative history |
| Earlier combined release stash / reconstructed branch | `41f44328e00201f02736ba3c037e91737254ca19` / `5227578d5f9b47e938dbae97f2203a8b05d04868` | SUPERSEDED / PRESERVED | Provisional generation, gameplay, audio and vector presentation preceded release descendants/current production. Old test differences were compared to strengthened or intentional newer contracts; no unique useful production logic identified |
| Stash 1 | `3818201893041b121c3a5f9fd9fa95ab66291659` | UNRELATED / PRESERVED | Tracker DB and comment-only local `_bmad/custom/config.user.toml`; not game source |
| Stash 2 | `cba618c3254f485fc6a0ae68e6554bf11acf5f2b` | UNRELATED / PRESERVED | Tracker DB snapshot only |
| `chainlink/locks` | `9315f444653d3ebf7b5248bbdbff99ca9d0227bf` | UNRELATED / PRESERVED | Auxiliary tracker lock cache created by inspection command |

Stash 0 parents: base `3fff9fc326776ebcb02798ffe07b2533f9d67cf0`, index `aea08eb9d5f2cefdaa9f74e4c0926b28ae794ebd`, untracked `99af37a201f62a9ace2940519898ef0c57108173`. Stash 1 base is `f8acf64b0599423e8fa12f50e6b68e1b3a3b03db`, index `44eb7117addfde384d81c51bb78b9ad1de84d3d8`. Stash 2 base is `ee8db371f8d70062e117d6a690b46db537d356b9`, index `eb3fd61e65132b3e8b172a8a7e676618e1a34061`. Displayed stash numbers can change; use these stable IDs.

No unique unresolved production branch is parked behind a semantic conflict. Existing development-only hazard fixtures, sample art/audio alternatives and review tooling are preserved in the source checkpoint; their presence does not adopt those experiments into normal gameplay. No empty/ours merge was used to claim omitted changes were integrated.

## Verification evidence and limits

All command logs, reports and captures below are in the private backup root. The engine used was **Godot 4.6.2 stable**, the version specified by current repository policy and architecture. The working project already advertises a 4.7 feature tag; this existing metadata was preserved. The open 4.7.2 Project Manager does not establish 4.7 gameplay validation.

| Check actually run | Result | Evidence |
|---|---|---|
| Canonical verifier on preserved primary baseline | PASS: import, main startup, 267/267 GUT | `baseline-verifier.log` |
| Canonical verifier on production trial | PASS: import, main startup, 267/267 GUT, whitespace | `trial-verifier-complete.log` |
| Canonical verifier on restored older stash | PASS: 86/86 GUT; preservation only | `stash0-verifier.log` |
| Complete deterministic generation corpus, 8 seeds × 18 holes × 3 difficulties × 4 course-effect contexts | 1,728 holes; zero invalid, fallback or curse shortfall; all 26 motifs covered; minimum quality 86 | `corpus.json`, `corpus.log` |
| Native production presentation, 1920×1080 and 1280×720 | Each: 1,467 checks, zero failures, 55 captures | `presentation-1920x1080/`, `presentation-1280x720/` |
| Dark and light rendered layout/lifecycle at 1280×720 | Each: 3,227 checks, zero failures, 37 captures | `layout-dark/1280x720/`, `layout-light/1280x720/` |
| Full VS AI smoke | PASS: 18 actual AI turns, five shops, shared courses, final results and rematch | `vs-full-match.log` |
| Audio asset integrity | 386 checks; 34 generated and six protected WAVs verified | `audio-assets.json` |
| WASAPI audio lifecycle | 89 checks, zero failures; recorded peak −8.27 dBFS; bounded crossfade voices | `audio-lifecycle/audio_lifecycle_report.json`, recorded mix |
| `python tools/build_card_art.py --check` | PASS: eight runtime sprites and eight source masters | Original art retained |
| `python tools/build_brand_assets.py --check` | PASS after repair: 71 glyphs, two tiers, 154 deterministic outputs | Archived vector palette preserved |
| Godot `tools/export_brand_rasters.gd -- --check` | PASS: five raster sizes and ICO, zero failures | `brand-raster-check.log` |
| Net integration `git diff --check`, staged/unstaged inspection and resource-path review | PASS; no missing literal runtime resource paths; all 422 imported binaries match original backup | `source-review.diff`, `imported-file-accounting.json` |
| Git connectivity and initial/final bundle verification | PASS | `bundle-verify.txt`, final backup verification |

Normal production rendering used Windows D3D12 Forward+ on RTX 5070 Ti, not an isolated presentation adapter. The rendered scenarios exercised actual Main creation, Solo launch and shots, six biome courses, course/background movement, overview return, one tee and reset behavior, 4/5/6-card shops, settings/pause, tutorial restart/exit cleanup, VS presentation, and New Run. Agent inspection covered title, Meadow tee, Snow overview, Hard shops, tutorial, VS opponent and light appearance captures. Automated layout counts do not establish human readability or comfort.

Baseline exceptions were recorded rather than hidden: the initial staged artifact dump had whitespace errors from nested historical patches; those captures were preserved outside Git. The archived vector check initially reported eight stale outputs, repaired without recoloring art. One trial verifier was intentionally interrupted to avoid concurrent GUT save-file interference with the baseline, then rerun sequentially to a complete pass; its original `trial-verifier.log` remains. Intermediate documentation encoding and missing-palette-key errors were corrected in follow-up commits, not rewritten away.

The canonical verifier is run again after the final documentation change; its independent completion evidence is `final-verifier.log` and `final-inventory.json` in the backup. This table records completed implementation checks, not a claim of human acceptance or release readiness.

**Remaining limitations:** no human playtest, listening judgment, mouse/keyboard feel approval, full human Solo run, export/build validation, or Godot 4.7 runtime validation was performed. VS player scores are controlled fixtures while AI uses real ball physics. Generation is a representative corpus, not every possible seed. Existing provenance records and release approval obligations remain; this task does not establish additional rights for supplied material. Continue with QUALITY_BAR and MVP_TEST_CHECKLIST human review before closing player-facing work.

## Work retained outside the consolidated result

- **6,835 excluded changed paths** remain in the original primary checkout and its raw backup, with individual reasons in `outside-git-accounting.json`: generated review captures/recordings, nested baseline snapshots/patches, temporary runtime output, Python bytecode, and supplied development references. They were not deleted or hidden with new ignore rules.
- `C:\Users\Rony\Projects\a-stroke-of-luck\assets\references\` (17 supplied files) and `assets\IMAGE2.png` remain intact and SHA-256 backed up at their same relative paths. They are development reference material, not runtime dependencies, and were deliberately not committed/copied into the clean integration checkout. Reference-analysis tools may need their original/backup location. Existing review documents can refer to captures retained in the primary/backup rather than shipped in the new checkout.
- Old exports remain in the primary `.export/` and `export-archive/`; no existing EXE/PCK/ZIP was staged or overwritten. Regenerable caches remain in their original directories. A bytecode file generated by this task's target-side audio check was moved to backup `generated-verification/` so the new checkout stays clean.
- Older shot physics, placeholder title/audio and the combined release-stash alternative remain in their named original/recovery branches, original stashes, durable refs and bundles. Tracker-only snapshots remain private stashes; their contents were not integrated or exposed.

Every meaningful original changed path is covered by the checkpoint manifest or exact outside-Git manifest; original branch and stash work is classified above. There was no inaccessible meaningful source/assets inventory.

## Final local state and next development location

| Checkout | Final branch | State / use |
|---|---|---|
| `a-stroke-of-luck-consolidated` | `integration/consolidated-20261004-000614` | Clean; **use this for development and testing** |
| `a-stroke-of-luck` | `recovery/20261004-000614-production` | No tracked/staged changes; 6,835 retained untracked review/reference/runtime files. Remains Chainlink control plane and original evidence location |
| `a-stroke-of-luck-audio` | `ship/audio-revision` | Clean; unchanged original tip |
| `a-stroke-of-luck-gameplay` | `ship/gameplay-revision` | Clean; unchanged original tip |
| `a-stroke-of-luck-visual` | `ship/visual-revision` | Clean; unchanged original tip |
| `a-stroke-of-luck-stash-recovery` | `recovery/20261004-000614-stash0` | Clean; preserved older alternative |
| `a-stroke-of-luck\.chainlink\.locks-cache` | `chainlink/locks` | Clean auxiliary tracker cache |

Original local branches, remote-tracking refs, the `v0.1.0-alpha` tag (object `5d4e8a1074049628639db50a53faffb25774fea3`, target `e2459b3`) and all three stashes remain unchanged. `final-inventory.json` records the exact final commit, per-worktree state, ref/stash equality and absence of active Git operations. The older clean ship checkouts/branches and the trial workspace reference are potential **later explicitly authorized** cleanup candidates because their source is retained/included; none were removed. The divergent alternatives, tracker snapshots and original QA/reference material still need owner review before any cleanup.

**CONSOLIDATED WITH DOCUMENTED LIMITATIONS**
