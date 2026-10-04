# Reference-driven presentation checkpoint — 24 September 2026

**Historical sample report.** The owner's subsequent visual-correction request authorized
normal-game integration. F5 now uses the production pixel presentation described in
[PRODUCTION_VISUAL_INTEGRATION.md](PRODUCTION_VISUAL_INTEGRATION.md). The sample's audio
auditions remain excluded; its sample-only approval gate no longer applies to these visuals.

This is an **opt-in playable approval slice**, not the six-biome rollout. The normal
project entry remains `res://scenes/main.tscn` and displays the existing production
presentation. No commit, export, publication, issue closure or release approval occurred.

## Play and compare

Open **`C:\Users\Rony\Projects\a-stroke-of-luck`** in Godot Project Manager.
Open `tools/reference_slice/reference_slice.tscn`, then **F6 / Run Current Scene**.
Alternatively, from that exact project folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/reference_slice/launch_sample.ps1
```

The launcher resolves local `godot4` (Godot 4.6.2 console executable) and explicitly
uses WASAPI. `-GodotPath 'C:\path\to\Godot.exe'` selects another installed executable.
No automated shots, quit timer or headless mode run by default. The scene opens at
the title and remains open. Use **PLAY SAMPLE** to begin actual golf.
The actual launcher was tested with `-CaptureProof`: D3D12 Forward+, visible window,
GUI input enabled and active WASAPI music. Its title framebuffer was inspected;
the process remained open. That proves launch configuration, not mouse feel or listening.

| Control | Action |
|---|---|
| Mouse drag/release; configured arrows and Space | Native aiming, power and shot |
| Tab / configured overview binding | Course overview / ball follow |
| Escape / Menu | Pause over the frozen current course |
| F5 / F6 | Reload Meadow / Volcanic review fixture |
| F7 / F8 | Native shop / title |
| F9 | Toggle 48 / 32 source-pixel density |
| F10 | Cycle Easy / Normal / Hard shop; native 4/5/6 offers and 2/3/5 caps |
| 1 / 2 | Crossfade audition A / B |

`-Previous` uses the earlier correction's visuals with the same current audition audio;
the before movie retains the earlier audio. `-Chunky`, `-Volcanic`, `-Track B` and
`-Resolution 1280x720` are optional. The supported capture sizes also include 1920×1080,
2560×1440 and 3440×1440. Review shortcuts reset the fixture/wallet (12 coins); they are
development navigation, not production rules. Tutorial and normal Solo/VS remain native;
this slice's PLAY SAMPLE intentionally enters its single Solo fixture directly.

Open [comparison and listening page](../tools/reference_slice/review.html),
[audio-only audition page](../tools/reference_slice/audio/audition.html), or inspect
[reference index](REFERENCE_MEDIA_INDEX.md). HTML complements the interactive scene.

## Reference findings and selected treatment

All 16 unique 1920×1080 JPEGs and the 34.37-second recording were discovered and inspected
from `assets/references/`; no original was changed. Exact paths, descriptions, near-related
screens and observations are in the index. The recording is an edited montage, not a
continuous run or proof of a seamless soundtrack. Whole-duration frame coverage plus
closer timestamped sequences support composition, event order and approximate timing.

| Observed trait | Evidence | Implemented translation |
|---|---|---|
| Warm broad sky, cool silhouettes, dark foreground | `ss_2180…jpg`, `ss_850b…jpg`; recording 2–6 s | Original Meadow valley and Volcanic caldera, subdued outside the opaque top-down board |
| Quiet masses, fine continuous material edges | `ss_2180…jpg`, `ss_d346…jpg` | Calm checker interiors, joined stone caps, grass fringe and visible side shading |
| Recognizable individual equipment | `ss_d2ca…jpg`, `ss_67b…jpg` | Six original driver/cleats/magnet/lens/core/putter illustrations; no category medallions |
| Thin rims, translucent ink, strong outlined type | `ss_67b…jpg`; recording 11.7–12.9 and 20.0–20.8 s | Jersey 10 display type, pale numbers, yellow actions, explicit benefit/curse panels |
| Short traces and escalating resolved outcome | Recording 2.200–2.733 and 23.5–26.6 s | Native-event strikes, impact/water frames, restrained cup glint and real result values |

Chosen candidate: **48 source pixels per 100-world-unit tile**; 32 remains a live comparison.
The moderate density preserves chain/metal/stone definition better in the inspected renders.
This is our project scale, not an assertion about the reference's native resolution.
Backgrounds are 768×432; item illustrations 128 px and rail icons 32 px. Materials use
upper-left highlights, selective dark outlines and controlled shade ramps; nearest sampling
and clean transparent edges. Typography deliberately uses its own readable scale:
Jersey 10 (OFL 1.1) display/actions with existing Atkinson Hyperlegible supporting copy.
Meadow uses jade/moss, pale stone and teal distance; Volcanic uses plum/charcoal basalt,
orange joints and ochre atmosphere. Real water stays water even in the Volcanic fixture.

The approved logo is still the exact `assets/pixel_sample/ui/wordmark.png`, derived from
`assets/pixel_sample/source/wordmark.png`. Both are hash-identical to the initial snapshot.

## Actual specialist work and refinement

Exactly three Astra Max specialists worked in this shared checkout without nested teams.
They directly accessed the original media and shared index before implementation.
World owns `world/`, UI owns `ui/`, audio owns `audio/` under both `assets/reference_slice/`
and `tools/reference_slice/`. Root owns composition, feedback adapter, launch, comparisons,
verification and this checkpoint. Existing production source was not edited by specialists.

| Review cycle | Concrete shortcoming | Material revision |
|---|---|---|
| First integrated render | Turf/cracks repeated noisily; props appeared to float; bright scenery competed with play | Quiet source-derived interiors, stronger checker values, sparse fixed clusters, removed unsupported props, dimmed gameplay backdrop |
| First integrated render | Thin display font, redundant image-well frames, muddy light-mode text | Compared licensed fonts at actual size; selected Jersey 10, removed inner frames, thin rarity rim, corrected light ink ownership |
| Second integrated render/motion | Busy royal-blue water and synchronized ripples; legacy result medallion and weak numbers; tiny 720p supporting type | Calmer teal water, sparse fading glints with spatial phase; revised result stars/numeric hierarchy; larger semantic support labels and clearer title action |
| Root integration | Giant course fragments behind shop/results; old fixed decorative coin count at cup | Dedicated scenic backdrop for these overlays; cup glint without a fabricated reward count; native resolved reward remains authoritative |
| Audio technical review | Dense simultaneous attacks and positive-cue cancellation boundary | 35 ms duplicate-strike guard, substituted-positive-stream cancellation, latest-context crossfade completion |

Audio revisions are technical, **not claims of audible aesthetic iteration**.
Evidence folders retain `cycle1_integrated`, `cycle2_integrated`, `cycle2_motion` and final
captures so the improvements can be inspected. Failed early parse attempts are retained in
logs; they are not counted as passing evidence.

## Audio and provenance

Two original complete auditions: **A · Sunlit Circuit** (48 s, 160 BPM, 32 bars) and
**B · Amber Canopy** (49.23 s, 156 BPM, 32 bars), with independent melodies/harmonies and
related arrangement families. A is the demonstration default, **not an approved selection**.
Eight new cues supplement native protected sand, boost/failure, water/lava/ice and purchase.

No listening-capable model tool was available. WASAPI playback/recording, PCM analysis and
signal timing are verified; musical character, timbres, groove, balance and fatigue remain
unassessed by subjective listening. The reference is very quiet (−55.26 LUFS); a labelled
**reference-only +30 dB excerpt** supports owner comparison. The low-confidence 158/80 BPM
autocorrelation clue has half/double-time ambiguity and is not asserted musical tempo.
No extracted reference sound enters production assets.

Sources, licenses and modifications: [audio provenance](../assets/reference_slice/audio/PROVENANCE.md),
[world provenance](../assets/reference_slice/world/PROVENANCE.md),
[UI provenance](../assets/reference_slice/ui/PROVENANCE.md).
CC0 sample attribution and font licenses are retained; generated original visual sources
and export scripts remain editable. Protected supplied-file redistribution permissions
remain the existing owner-confirmation issue; this work does not approve them.
Eight distinct title/tutorial/biome compositions follow direction approval; they are not
claimed complete by these two auditions. [Audio timing and audit](../tools/reference_slice/audio/REVIEW.md).

## Migration coverage

| System | Existing / replacement | Runtime and visual status |
|---|---|---|
| Logo/title | Approved wordmark / unchanged logo, original scenic composition and new controls | Integrated in sample; native title parallax retained |
| Meadow/Volcanic | Earlier correction / two new terrain, rim and background families | Integrated and compared at both densities; exact same fixture geometry |
| Pendulum/water/sand/pad | Earlier sample / original mass/support/material sprites | Native motion/contact/reset; unchanged collider snapshots |
| HUD/shop/cards | Earlier panels/icons / shared frames/type, six illustrated offers, selected details | Integrated 4/5/6 offers, light/dark, native purchases and visible curses |
| Hole results | Native result data / stronger type, illustrated star treatment, scenic backdrop | Real resolved hole; history controls retained |
| Settings/run setup/pause | Existing functioning controls / shared component styling | Sample utility treatment; frozen course under pause |
| Desert/Autumn/Snow/Swamp; remaining hazards/equipment | Existing assets | Awaiting approval; no full migration claim |
| Tutorial/VS/full run results | Existing mechanics and production presentation | Regression checked; complete new presentation migration remains after approval |
| Music | Existing production soundtrack / two provisional auditions | Sample only; eight new context compositions pending selection |
| Normal F5/main launch | Existing production assets | Unchanged; does not use the reference slice |

## Verification and practical limits

Baseline repository verifier: **262/262 GUT tests**, 112,972 assertions, import/startup and
Git whitespace passed. The integrated verifier also passed **262/262**, 112,972 assertions.
The final frozen-code run also passed **262/262**, with zero failures; its complete output
is retained separately as `frozen_verifier.log`.
Independent generator regression: **864 holes**, zero selected validation failures/fallbacks.
VS smoke: five actual fixtures, no failures. Protected-audio audit: **386 checks**.
Audio native WASAPI probe: **68/68**; independent decoded-asset audit: **87/87**.
Sample input/lifecycle checks cover keyboard shot, ready recovery, pointer projection,
overview, pause, density/collider preservation, shop caps/tradeoffs/purchases, reduced motion,
bounded feedback/music pools and tutorial return cleanup.

Final gallery: **nine captures at each of 1280×720, 1920×1080, 2560×1440 and 3440×1440**,
plus nine for the 32 px trial. PNG dimensions were checked directly. All gallery assertions
passed. Four-resolution lifecycle checks passed **61/61 each**; the final added keyboard-focus
check passed **67/67 at 720p**, including changing actual selected identity and displayed
offer details across Easy/Normal/Hard. Post-review light-mode captures passed. The final
36.017-second replay passed all four assertions and preserves native collider snapshots.
The Sand Cleats selection is shown in `final_motion/05b_details.png`.

Final decoded movie mix: **−8.71 dBTP**, **−21.28 LUFS**, zero clipped samples. The same-frame
shot/wall/pendulum/purchase/water cue routes and source-template alignment are recorded in
`audio_final/integrated_movie_audit.json`; there is one purchase cue and no generic purchase
click. The +160 ms curse acknowledgement remains separate. These are signal measurements.

Asset growth before Godot import: **2,800,599 bytes** of runtime PNG/Ogg/font files
(world 950,711; UI 176,563; audio 1,673,325), with editable source images kept separately.
The snapshot checks all **531 existing files**: only `export_presets.cfg` changed, adding
the reference/artifact exclusions; all 17 originals and both logo files are unchanged.
Source art directories have `.gdignore`; originals, analysis, new assets and game captures
remain separate. No reference pixel or reference audio forms part of a shipped game asset.

Indicative 1080p MovieMaker rendering cost changed from **0.58 / 0.27 ms CPU/GPU** for the
28.7-second earlier replay to **0.68 / 0.61 ms** for the 36-second revised replay. These are
renderer averages with different ending coverage, not a controlled whole-frame benchmark.
Snapshot static memory grew from 86.6 to 107.8 MiB on Meadow and 90.9 to 117.1 MiB in the
six-offer shop; draw calls rose 221→232 and 310→384 respectively. Snapshot process-time
monitors include initialization and are not treated as steady frame time. World setup
measured about 129 ms at 48 px; repeated density changes kept node counts stable. Native
audio has ten pooled SFX players and two music players; feedback transients return to zero.

Commands actually exercised (from project root; repeated sizes/output directories omitted):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .codex/skills/godot-verify/scripts/verify_godot.ps1 -GodotPath 'C:\Users\Rony\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe'
godot4 --headless --path . --script res://tests/procgen_corpus.gd -- --seed-count=4 --output=res://artifacts/reference_review/generator_regression.json
godot4 --headless --path . --script res://tests/gameplay_direction_vs_smoke.gd
godot4 --path . --rendering-method gl_compatibility --fixed-fps 60 res://tools/reference_slice/reference_slice.tscn -- --sample-gallery --sample-size=1920x1080
godot4 --path . --audio-driver Dummy --rendering-method gl_compatibility --fixed-fps 60 res://tools/reference_slice/reference_slice.tscn -- --sample-checks --sample-size=1280x720
godot4 --path . --rendering-method gl_compatibility --fixed-fps 60 --write-movie artifacts/reference_review/revised.avi res://tools/reference_slice/reference_slice.tscn -- --sample-record --sample-output=res://artifacts/reference_review/final_motion --sample-size=1920x1080
python tools/verify_audio_assets.py --report artifacts/reference_review/protected_audio_audit.json
python tools/reference_slice/build_review_evidence.py
```

All final affected-scene logs were scanned for parser/runtime/resource errors; none remain.
Review HTML local media links resolve. Staged diff is empty; Git whitespace checks pass.
Specialists inspected their complete domain diffs and new files. Root reviewed composition,
event ownership, launch, source preservation, export exclusions and owning documentation.
The preexisting broad gameplay rewrite is preserved and tested, not newly approved here.

Actual replay includes wall impact, pendulum contact, cup/results, accepted purchase and water
reset. Its input is scripted through the real game. No native desktop input tool was available
(desktop bridge unavailable), so mouse ergonomics, camera comfort, pixel shimmer in motion,
audio character and full human runs remain owner checks. Screenshots and sequential frame
inspection do not establish a human playtest. No exported build was requested or produced.

The current project feature tag says 4.7; verification uses the repository's specified 4.6.2.
That inherited difference was preserved. Original references and analysis output are excluded
by the Windows preset; no export was performed to independently inspect a packed build.
The existing broad dirty worktree remains intact; its historical changes are not newly approved.

## Owner checkpoint

Compare edge/material craftsmanship, scenery outside the playable surface, density, item
silhouettes and strong but readable typography. Play both biomes in follow/overview, strike
the pendulum and water, inspect all shop sizes and curses, purchase with mouse/focus, pause,
and finish the hole. Listen to A and B for at least two loops each, then during golf.

Decision needed: whether the 48 px visual treatment is suitable for six-biome rollout,
which specific visual corrections remain, and whether A, B or neither is the right audio
direction. No rollout or eight-composition production begins until that approval.

**NEXT STATE: READY FOR OWNER STYLE APPROVAL.**
