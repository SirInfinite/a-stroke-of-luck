# Arcade pixel-art correction checkpoint

2026-09-11. **Revised playable comparison; human style approval pending.** The owner approved the existing logo and rejected the scenic world/UI direction. The specified `assets/ref1.png`, `ref2.png` and `ref3.png` were inspected before the final correction. This checkpoint does not authorize a production rollout, commit, export, merge or issue closure.

## Open and play

- [Side-by-side review page](../tools/pixel_correction/review.html): matched stills, four-item comparison, synchronized movies and local review checkboxes.
- [A: previous pixel sample video](../artifacts/pixel_correction/previous.mp4) / [B: arcade correction video](../artifacts/pixel_correction/revised.mp4): actual Godot captures, 1920×1080, 60 fps, 28.7 seconds each, with existing audio.
- [Launcher and reproduction commands](../tools/pixel_correction/README.md).
- Side-by-side screenshots: [Meadow](../artifacts/pixel_correction/comparison_meadow.png), [hazard contact](../artifacts/pixel_correction/comparison_hazard.png), [shop](../artifacts/pixel_correction/comparison_shop.png).

Run `tools/pixel_correction/launch_sample.ps1` in PowerShell for B, or add `-Previous` for A. The previous sample's original launcher remains usable. The normal game still starts at `scenes/main.tscn`.

Both treatments use seed **9102026**, the same authored 12×8 Meadow hole **THE OLD SWING**, the same four shop offers and native gameplay. The recorded bank, pendulum contact/reset, sink, results and purchase are real game events. The 12-coin initial wallet is an inherited review fixture, not a revised production economy.

## Inspection before the draft

The prior rendered hole and shop were inspected before editing. Their detailed turf clusters, granular water highlights, realistic timber grain, fine willow foliage, stone modeling and scene-like equipment illustrations competed with the relatively quiet ball and hazard silhouettes. The title backdrop supplied a distant scenic vista with more atmospheric depth than the play space needed.

No new image attachments were available in the task. The draft used the written brief plus saved, previously sourced Balatro, Grandpa Golf and Into the Breach screenshots under `artifacts/pixel_sample/references`. Their relevant lessons were strong enclosed forms, compact color groups, readable objects inside explicit board spaces, restrained environmental layers, emphatic card framing and clear interaction hierarchy. No screenshot assets, compositions or interface placements were copied. See [the existing reference provenance](PIXEL_SAMPLE_REFERENCES.md).

The owner then identified the intended local set. All three images were opened and visually inspected before the final UI correction:

| Owner reference | Specific observed language | Application to this sample |
|---|---|---|
| [ref1.png](../assets/ref1.png) | Repeated broad tree silhouettes, bright continuous playable rims, deep side faces, large outlined numbers | Quieter silhouette layers and explicit board top/side separation; stronger ink outline on HUD values |
| [ref2.png](../assets/ref2.png) | Angular constructed route shapes, continuous ledges, sparse interior shading, a simple bright ball and clear target flag | Preserve the top-down cell board and native geometry while making walls, hazards, white ball and flag visually distinct |
| [ref3.png](../assets/ref3.png) | One isolated equipment sprite per card, a few confident shade groups, large type, strongly emphasized gold purchase actions | Large outlined driver/cleat/magnet/lens sprites; enlarged 63-unit BUY controls and 30px purchase labels, 31px card names |

These are style references only. Their side-view hole geometry, orange skyline, HUD placements, inventory row, shop layout, displayed items and proprietary artwork were not transplanted. Their warmth and oversized score presentation were balanced against this brief's requirement for a quieter background and ball-first top-down composition. The new gold actions, shaded side faces and object silhouettes express related visual principles within this game's existing layout. In particular, both benefit and curse remain visible on every offer even though that requires more text than the reference shop.

## Direct comparison

| Area | A: previous sample | B: current arcade draft | Deliberate tradeoff |
|---|---|---|---|
| Realism and course surface | Dense grass/grain and modeled surface textures | Large alternating square cells, sparse authored turf marks and distinct green destination cells | Less natural variation; the gameboard structure is more explicit |
| Construction and depth | Textured timber boundaries around a terrain slice | Flat warm wall caps and side bands, dark connected edges, solid board base and small corner studs | Less timber realism; more assembled playset character |
| Shading | Numerous intermediate material tones | Broad shade regions, hard highlights, flat UI inks and strong outline groups | Reduced reflected light and soft volume; no strict indexed-color claim |
| Active hazard | Subtle stone mass and fine chain detail | Broad stone facets, orange binding and bearing, thick chain links, discrete arc marks and short contact flash | Exaggerated construction makes the mechanism and danger easier to identify |
| Passive surfaces | Small texture details carry material identity | Blue water with large wave marks, warm sand grooves, yellow lightning launch pad | Less surface nuance; surfaces separate quickly from active threats |
| Background and Meadow identity | Scenic title vista and more garden texture | Few broad title silhouette bands; quiet flat gameplay surround with two small willow/flower/lily groups | Less scenic depth and exploration detail; course contrast takes priority |
| Cards and items | Small scenes, hands, surroundings and reflection detail | Four transparent equipment silhouettes on rust, ochre, teal and plum stages | Loses miniature illustration storytelling; gains fast object recognition |
| UI and icons | Textured paper/felt with thinner material frames | Stepped pixel borders, offset lower edges, bold gold buy buttons, shared small symbols and category sprites | Some subtle paper texture is removed; utility controls outside the sample retain existing art |
| Feedback | Softly fading raster stamps | Short held impact poses, outlined score values, brief purchase acknowledgement, decisive press compression and card tilt | Less cinematic lingering; simulation and native timing remain unchanged |

The draft follows the written priority order: ball/aim, playable surfaces and boundaries, active threat, cup, HUD, background. This is an art-direction intention, not a claim of owner approval or proven human readability.

| Requested evidence | A: previous | B: revised |
|---|---|---|
| Representative Meadow hole | [Overview](../artifacts/pixel_correction/previous/02_hole.png) | [Overview](../artifacts/pixel_correction/revised/02_hole.png) |
| Hazard-heavy shot moment | [Contact](../artifacts/pixel_correction/previous/03c_hazard_contact.png) | [Contact](../artifacts/pixel_correction/revised/03c_hazard_contact.png) |
| Shop screen | [Shop](../artifacts/pixel_correction/previous/05_shop.png) | [Shop](../artifacts/pixel_correction/revised/05_shop.png) |
| Updated cards/items | [Four old card illustrations](../tools/pixel_correction/review.html) | [Four new item sprites](../tools/pixel_correction/review.html) |
| Background treatment | [Title and logo](../artifacts/pixel_correction/previous/01_title.png) | [Title and same logo](../artifacts/pixel_correction/revised/01_title.png) |
| Buttons and purchase feedback | [Benefit/curse response](../artifacts/pixel_correction/previous/06b_tradeoff_feedback.png) | [Benefit/curse response](../artifacts/pixel_correction/revised/06b_tradeoff_feedback.png) |

The review page also exposes card hover. Both capture folders contain press, aiming, results and purchased-state stills. The movies show motion and timing; isolated screenshots cannot establish responsiveness or feel. Hover and press signals were triggered by the capture harness, not a human mouse recording.

## Implementation boundaries

The correction scene subclasses the existing sample harness and chooses between its old skin and a second cosmetic skin. Two small virtual factories were added to the old harness; their defaults return the original skin and feedback scripts. All production sources, scene entrypoints, collision sizes/transforms/layers/masks, generation, flat 2D physics, aiming, replay, economy, card values and ownership boundaries remain unchanged from the pre-task workspace.

The stone follows the actual MovingHazard position and swing clock. Its path is the real center trajectory, not a safe-period promise. Essential motion remains active under Reduced Motion; decorative card/world animation and flying coins follow existing reduction settings. The block power display reads the native meter. Purchase feedback still uses the actual ShopManager transaction and separate benefit/curse acknowledgements.

The approved `assets/pixel_sample/ui/wordmark.png` is loaded directly. It was not re-exported, recolored or redesigned. All old sample assets remain byte-identical. A pre-edit snapshot covers 456 files; its [preservation check](../artifacts/pixel_correction/preservation_check.json) allows only the old harness factory seams.

This is one **flat Meadow** fixture and four existing items. Ramp/elevation/overpass art, five other biome kits, additional hazards/cards, settings/tutorial/history/VS screens and production integration are outside this checkpoint. Sample extensions should be evaluated after the owner accepts a direction.

## Verification evidence

| Check | Observed result |
|---|---|
| Repository verifier, initial implementation | PASS: Godot import, main startup, 257/257 GUT tests and whitespace checks. [Log](../artifacts/pixel_correction/godot_verify_initial.log) |
| Repository verifier after final edits | Exact final verdict and complete output: [final verifier log](../artifacts/pixel_correction/godot_verify_final.log); [verification summary](../artifacts/pixel_correction/verification_summary.json) records the result separately from human approval |
| Focused input/lifecycle/shop checks | 78/78 at [720p](../artifacts/pixel_correction/720p_checks/checks.json), 78/78 at [1080p](../artifacts/pixel_correction/1080p_checks/checks.json), including appearance, Reduced Motion and benefit/curse disclosures |
| Raster, capture, replay and media contracts | [135/135 PASS](../artifacts/pixel_correction/artifact_checks.json); exact per-frame non-audio event parity across A/B, matching duration, actual wall/hazard/stop/sink/purchase events, one each of key semantic audio cues |
| Source/logo preservation | PASS: [456-file pre-task comparison](../artifacts/pixel_correction/preservation_check.json), no unexpected source changes and unchanged approved logo |
| Rendered galleries | 1600×900, 2560×1440 and 3440×1440: title, overview, dark/light shop; collision snapshot unchanged and no engine error signatures |
| Default project renderer | D3D12 Forward+ gallery passes in addition to Compatibility captures |
| Browser review workflow | 15 checks pass: all subjects/assets, full-size A/B, synchronized playback/pause/seek/restart, B-only audio and narrow viewport layout. [Run log](../artifacts/pixel_correction/browser_checks.log); no console errors |
| Audio in both movies | Non-silent, peak -5.8 dBFS, mean -21.9 dBFS; subjective listening is not asserted |
| Human quality and native mouse/keyboard feel | Unperformed; still required |

The complete dirty worktree predates this correction. The runner tests that integrated tree; passing it does not accept or authorize unrelated pending changes. The source snapshot protects those changes from this pass.

Browser QA used Playwright after the in-app browser reported no available connection. Video seeking was verified through a loopback-only range-capable static server; Python's basic `http.server` does not provide the byte ranges needed by this browser. The native game input/feel still needs human playtesting. The inherited check report's older desktop-helper annotation is not a fresh native-input test.

## Files changed by this pass

- `tools/pixel_correction/correction.tscn`, `correction.gd`: isolated A/B playable and capture entrypoint.
- `tools/pixel_correction/arcade_assets.gd`, `arcade_world.gd`, `arcade_pendulum.gd`, `arcade_power.gd`, `arcade_skin.gd`, `arcade_feedback.gd`: presentation adapters and native pixel materials.
- `tools/pixel_correction/export_assets.gd`, `protect_sources.py`, `verify_artifacts.py`: reproducible export and preservation/media checks.
- `tools/pixel_correction/launch_sample.ps1`, `README.md`, `review.html`: local play/review workflow.
- `assets/pixel_correction/`: six generated source PNGs, 29 exported raster assets, manifest, exact prompts and provenance. [Asset record](../assets/pixel_correction/PROVENANCE.md).
- `tools/pixel_sample/pixel_sample.gd`: two default-preserving factory seams only.
- `docs/ART_DIRECTION.md`, `docs/PIXEL_SAMPLE_REVIEW.md`, this document: current checkpoint status and evidence.
- `artifacts/pixel_correction/`: ignored local captures, movies, source snapshot, verification logs and reports.

Godot-created import/cache/UID files are not authored implementation changes. No new third-party game assets or code were added; existing font/audio licenses remain in place. Raster generation and export provenance are explicit. The generated sources are not strict indexed-color masters, and fractional camera zooms can produce uneven screen pixel sizes; neither limitation is disguised as pixel-perfect completion.

## Human review checklist

- Compare against `assets/ref1.png` through `ref3.png`; judge whether the correction uses their shape/shading/readability language without copying their artwork or composition.
- At play scale, find the ball and aim first; confirm the course and collision boundaries read before the background/HUD.
- Judge the stone's mass, chain/support, arc, anticipation and hit. Confirm it feels mechanically clear and threatening.
- Compare water, sand, launch pad, turf and boundary materials; judge whether the board feels assembled and toy-like.
- Identify all four items at a glance, then read price, rarity, benefit, curse and owned stack. Check hover, press, bought and unaffordable states.
- Judge whether the quieter Meadow has enough personality and whether flatter shading sacrifices too much richness.
- Play with mouse and keyboard at 720p/1080p and Reduced Motion. Give a style decision separately from input/animation feel observations.

Maturity: technically functional and integrated **within the isolated sample**. Human-playtested, polished-to-owner-standard and direction-approved remain pending. No full rollout has begun.
