# Structural and audio release-hardening review

2026-09-06. Scope: the existing working release candidate, not another gameplay or generation overhaul. No commit, issue closure, export or release approval is authorized by this report.

## Audit and migration decisions

| Priority | Before / concrete risk | Implemented response |
|---|---|---|
| BLOCKING | No initial startup blocker. Human listening, touched-interaction testing and current exported-build smoke were not available as approval evidence. | Keep those release gates explicit; do not substitute screenshots or signal tests. |
| HIGH | Main, RunStats and ShopManager held overlapping accounting/card/wallet truth. | Scene-local RunState owns mutable round data; RunStats is its cumulative ledger; the production shop forwards to the same wallet. Reward/effect formulas are moved unchanged. |
| HIGH | Phase changes and async work relied on permissive state assignment and cooperating booleans. | Guarded transition table, explicit PREPARE_HOLE/HOLE_RESOLVING phases and generation checks reject duplicate/stale work. A live menu remains a pause overlay, not a second run phase. |
| HIGH | A queued or running ball sink could survive reset and move/hide a later shot. | GolfBall invalidates deferred starts and kills its own sink tween. Completion callbacks do not await a killed tween. The regression was reproduced before the fix. |
| HIGH | Audio semantics crossed FeedbackDirector and direct Main calls; UI discovery reached outside the game's HUD. | Visual-only FeedbackDirector; one local event route into AudioController; scoped, disconnectable UI binding and dedicated purchase/bounce/outcome paths. |
| HIGH | A par+4 cup could start positive sink feedback before failure was determined. | Determine the existing stroke-limit outcome before audio; both supplied failure layers, no positive sink/completion cue. |
| HIGH | The old low-boost audio cutoff was below the actual minimum launch ratio, making that supplied sample unreachable in normal launches. | Test the actual GameplayHazard output; audio-only 0.60/0.82 cutoffs cover low/medium/high. No launch tuning changed. |
| MEDIUM | TutorialManager depended on the complete Main object; power-meter drawing lived inside Main. | Tutorial receives the ball, a point resolver and a copied effect-presence snapshot. Extract the unchanged power-meter presentation into its existing UI family. |
| MEDIUM | A card's initial minimum height could leave a +110 px bottom offset after row layout. | Refit child anchors on slot resize. A failing-before/passing-after purchase/layout regression and rendered capture cover the fix. |
| MEDIUM | Short synthetic score textures and tonal ordinary-action cues lacked the requested physical/acoustic identity. | Eight separately written sampled-acoustic scores, longer ambience, physical-transient SFX and a noise-only high-speed layer. Preserve approved/supplied cues. |
| MEDIUM | Overlapping cues reached the master limiter in the first default-volume recording. | Central -8 dB SFX mix trim before user controls; the repeated live tour peaks at -7.88 dBFS. |
| LEAVE ALONE | Mature generator/validator/builder, flat physics tuning, card/difficulty data, save format, settings buses, authored fallbacks and existing visual system. | Preserve the pre-task snapshot. Do not add a framework, autoload, event bus, redundant RunController or broad asset relocation. Main's remaining UI composition/terrain glue is deliberately retained. |

## Implemented ownership

See `ARCHITECTURE.md` for the runtime tree and contracts. Main now coordinates nodes and transitions, while RunState owns run accounting, card membership, curse duration and the resolved effect cache. Existing typed CardDefinition/CardEffectSet and dictionary level contracts remain intact. HUD/results receive copied collections; ShopManager owns eligibility/deduction, not UICard. There is no second wallet in production.

GolfBall still owns aiming, accepted shots, motion, discrete elevation and sink animation. Only animation cancellation changed here. LevelBuilder, hazards, FeedbackDirector, TutorialManager, TransitionPresentation, ShopManager and AudioController each clean their own transient state. The state table retains existing public phase values and adds preparation/resolution states; tutorial and normal-run ordering remain behaviorally tested.

One accepted semantic event is routed once to each relevant presentation owner. FeedbackDirector produces VFX only. AudioController selects/playbacks cues and owns crossfades, ambience, mixing and bounded players. Dedicated water/lava/sand/bounce paths exclude the generic hazard echo. A falling-ice landing owns its impact cue. Purchase plays one purchase cue plus an intentionally quieter curse/stack accent, not an additional generic click.

## Audio content and mix

`AUDIO_SOURCES.md` is the complete source/provenance record. Eight explicit original scores use 25 verified, pinned CC0 VCSL instrument recordings, not downloaded compositions. Their written melodies, harmony, A/B/C phrasing, instrumentation and meter differ. Runtime plays finished WAVs, never the sampler or network downloader.

The chamber-arcade palette is piano, vibraphone, wooden mallets, harp/strumstick, recorder and restrained hand percussion. The eight loops last 43.636–68.571 seconds. Six cyclic ambience beds last 32–42 seconds. Repeated-action cues use small controlled variation; normal rolling is silent; the 520–1100 px/s swoosh has smoothed gain and fixed pitch. Surface cues are events, not constant loops. The sand cue, all three supplied boosts and both supplied failures remain byte-exact.

The existing Master/Music/SFX buses are unchanged. Two music and two quieter ambience players support cancellable 0.8-second fades; ten SFX voices and one swoosh voice bound playback. Reopening the same music state preserves its playhead. Pause trims music without restarting it and stops movement audio. Purchase, failure and final completion briefly duck music. The existing limiter is a safety net; the authored mix leaves headroom before user volume controls.

## Verification evidence

QA files live outside the repository in `user://structural_audio_overhaul_20260906/`. Before editing, the real Main was run through a 34-screen tour and a keyboard title-to-shot smoke. `source_baseline/` preserves the pre-task dirty source so earlier visual/procgen changes can be distinguished from this migration.

| Check | Evidence / result |
|---|---|
| Canonical import, startup, complete GUT and whitespace | `verify_final.log`: PASS, 167/167 tests and 64,604 assertions. Expected malformed-level validator warnings are negative-test evidence, not runtime failures. No ObjectDB leak warning remains. |
| Independent PCM/score/source audit | `audio_asset_audit.json`: 371 checks, zero failures; 31 newly rendered files and six protected cues. Eight unique music hashes and melodies, complete musical measures, no silent seams, finite PCM and source headroom. |
| Real audio lifecycle | `audio_lifecycle_report.json`: 86 checks, zero failures, WASAPI; maximum two music/two ambience voices during crossfade, one target afterward; -7.88 dBFS peak at default bus settings. A roughly 29-second master recording and four screenshots accompany it. |
| Settings persistence | Structural GUT uses an isolated settings file, checks actual Master/Music/SFX values/mutes/defaults, and restores bus state. It does not overwrite player preferences. |
| Deterministic generator corpus | 6,912 holes / 55,296 candidates, zero invalid selected holes, zero fallback and zero curse shortfall; 29 candidate rejections (0.0524%). Mean/min quality 95.83194/87.57, mean/min geometric route relevance 1.0. |
| Corpus distributions | 2,384 branching holes; 472 dead ends; 668 elevated holes (9.66%); three short tunnels; 4,096 moving-hazard holes; 703 bounce-pad holes. Mean generation 29.02 ms, p95 51.01 ms on this machine. These are regression measurements, not new generation changes or fun ratings. |
| Rendered generation | `generation_render.log`: 140 actual LevelBuilder captures passed, using two seeds, all difficulties/biomes and corpus-selected feature examples. |
| Rendered main smoke | `visual_smoke_scenario.result.json`: 11 assertions, seven captures, no engine error. Synthetic keyboard input reached an accepted moving shot. |
| Release showcase | `visual_release_showcase_scenario.result.json`: 11 assertions, 23 captures, no engine error. |
| Actual Main UI | All four 1280×720, 1600×900, 1920×1080, 2560×1440 scenarios: 34 captures and 1,292 layout checks per size, zero failures. Captures remain under `user://visual_overhaul_20260906/after/`. |
| Windows export path | `export_preflight.json`: native Godot ConfigFile parsing passed; Windows preset, 4.6.2.stable debug/release templates, target and development exclusions exist. No build was exported, overwritten or smoke-tested. |

The imported generic export helper's preflight misread the multiline Godot preset and versioned template directory. It was not modified; the narrowly scoped native-parser preflight above checks the real configuration instead. The existing project feature tag says 4.7 while the repository's authorized verification engine is 4.6.2; this preexisting metadata was preserved, and all reported runs used the actual 4.6.2 binary.

### Review and refinements

Reviewed the title, settings, tutorial, six-biome HUD, shop/purchase, failure and ending captures. The prior visual identity stayed intact. The purchased-card overflow led to the slot-refit regression/fix. Reset tests exposed the stale animation; replacing cancelled-tween awaits removed the associated ObjectDB leak warning. Actual launch-speed tests corrected the low boost mapping. Default-volume recording exposed limiter contact, leading to the mix trim and a stricter recorded-peak check.

Screenshots and synthetic state arrangements are not an eighteen-hole human playthrough. The audio recording establishes real playback and lifecycle behavior, not comfortable music or believable impacts. No human listening approval is recorded.

### Repeatable commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .codex/skills/godot-verify/scripts/verify_godot.ps1
godot4.cmd --headless --path . --script tests/procgen_corpus.gd -- --seed-count=32
godot4.cmd --path . res://tests/procgen_review.tscn
godot4.cmd --headless --path . --script tests/export_preflight.gd
$env:PYTHONDONTWRITEBYTECODE = '1'
python tools/verify_audio_assets.py
python .codex/skills/godot/scripts/debug/run_scenario.py . tests/audio_lifecycle_scenario.json --no-headless --timeout 85
python .codex/skills/godot/scripts/debug/run_scenario.py . tests/visual_smoke_scenario.json --no-headless
python .codex/skills/godot/scripts/debug/run_scenario.py . tests/visual_release_showcase_scenario.json --no-headless
```

Use the console Godot executable via `-GodotPath` / `--godot-bin` when automatic discovery selects a non-console build. The four `tests/visual_overhaul_<width>x<height>.json` files provide the Main screen tours.

## Diff / resource hygiene

Review the migration against `source_baseline/` as well as Git: this worktree already contained a large uncommitted visual/procgen refinement. Generation, validator, builder, hazard physics, card/effect/difficulty/seed data, project settings and bus/preset files were not rewritten by this migration. GolfBall's task diff is restricted to sink cancellation. Existing supplied/sand files were hash-checked; all 37 shipped WAVs are catalogued. No confidently unused shipped resource warranted deletion. Two renderer bytecode cache files were moved from `tools/__pycache__/` into the recoverable user-area QA directory. Engine-generated UIDs were not manually edited. No commit, push, issue closure or executable export occurred.

## Human acceptance still required

Follow the focused checklist in `MVP_TEST_CHECKLIST.md`: hear each full track through at least two wraps, then play long enough to judge fatigue and the real mix. Test reset/pause during shots/sinks, tutorial skip/restart, shop purchases/stacking/Continue and complete hole/biome/run/new-run progression. Confirm the external redistribution rights for the five owner-supplied recordings before distribution; their missing license information is explicitly documented, not invented. Finally export an authorized current build and smoke-test its audio, settings and Quit path outside the editor.

Status: **READY FOR FINAL HUMAN RELEASE TEST**, not final release approval. Human listening, touched gameplay retest and an authorized exported-build smoke remain open.
