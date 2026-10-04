# Production visual integration — 24 September 2026

The owner's correction authorizes normal-game rollout. The real entrypoint remains
`res://scenes/main.tscn`; no sample scene, style flag, fixture hole or audio audition
is installed in its place. Existing dirty work is preserved. No commit, publication,
issue closure or executable export was performed.

## Play the delivered game

Open **`C:\Users\Rony\Projects\a-stroke-of-luck`** in Godot Project Manager and press
**F5 / Run Project**. The tested engine is Godot **4.6.2**. From PowerShell:

```powershell
godot4 --path "C:\Users\Rony\Projects\a-stroke-of-luck" --audio-driver WASAPI
```

Normal startup now shows the protected logo, Jersey controls and scenic title.
PLAY opens the native Solo/VS selection and run setup, then procedural gameplay.
Tutorial, six biomes, shops, pause/settings, results, history and ending use the same
production family. No development flag is required. Historical sample scenes remain
available under `tools/`, but their alternate soundtrack auditions are not integrated.

Use mouse drag/release at the stopped ball, or Left/Right to aim, Up/Down for power
and Space/Enter to shoot. Tab toggles overview, R resets the current hole and Escape
opens pause. Existing rebinding, reduced motion, shake and volume preferences apply.

## Font and native UI

Approved resource: `assets/fonts/Jersey10/Jersey10-Regular.ttf`, with `OFL.txt` beside it.
It is byte-identical to the approved sample font. `UIStyle` and `release_theme.tres`
centralize every role; script overrides, dynamic controls, tooltips, settings, HUD,
cards, transitions/history and VS use this family. System fallback is disabled;
unsupported decorative triangles use supported punctuation or semantic icons.
Fredoka/Atkinson production references are removed; archival font files/licenses remain.

The logo's source and approved export remain unchanged. Production uses the exact copy
`assets/brand/approved_wordmark.png`. Native components were promoted individually,
including 4/5/6-offer shops with visible benefits/curses, selected details and purchase
feedback. ShopManager's 17 non-presentation functions remain unchanged. Review fixed
seed baseline clipping, header/menu overlap, VS/power-meter overlap and equipment
count labels with zero layout width.

## World, camera and tee

`LevelBuilder` selects production art through `scripts/presentation/world_art.gd`.
48-pixel material tiles cover the original 100-unit cells. Six distinct landscapes,
biome landmarks, joined wall materials, hazards and elevation surfaces are integrated.
Nearby props and ground contacts retain fixed world coordinates. `WorldDistance`
reads the native camera and draws distant/middle layers with 0.12/0.30 travel responses;
inverse-canvas coverage and mirrored repeat pairs handle overview and wide displays.
Title cursor parallax remains separate. Pause shows the frozen current course.

Ambient particles use private seeded placement, independent faded lifetimes and no
global clock reset. Reduced motion freezes decorative clocks and parallax travel.
Review corrected an obscured depth layer, mismatched quiet/detail tile values and
floating opaque ground patches; broad tapered contact bands now preserve scenic depth.
Some repeated prop pairs still read as illustrated clusters over a scenic field;
their aesthetic integration and camera comfort remain human retest items.

The old tee source contained **two orange tees**. Production exports only the left
object and aligns its measured seat beneath the physical ball origin. LevelBuilder
is the sole tee owner; ball art contains no tee. The stationary tee hides on the first
accepted shot and returns on manual reset, new hole, tutorial restart and VS turn reset.
Manual reset previously left it hidden; the restored visual state changes no position,
velocity, collision, power or stroke accounting. Hazard/OOB recovery behavior is retained.
Flag frames also exclude their baked cup edge; the native cup owns that presentation.

## Cartoon card artwork

The recovered family is `assets/pixel_correction/source/cards_cutout.png`: orange
Overdrive Driver, yellow Sand Cleats, red Coin Magnet and violet Rangefinder Lens.
Four matching original cartoons complete Heavy Core, Lucky Putter, Power Club and
Gust Guard. Power Club/Lucky Putter source poses were refined with shorter shafts and
larger heads after actual-size review. All eight use square masters and 80×80 exports,
with complete silhouettes and at least five transparent pixels of gutter. IDs,
tutorial aliases, rarity, prices, effects and stacks are unchanged.

The recovered cartoons were already complete; alpha inspection did not establish
missing edges in those sources. This pass restores complete object compositions,
replaces tight nonsquare exports, and corrects club proportions at source level.
It does not claim to have reconstructed nonexistent missing pixels.

- [All icons at 32/80/160 pixels](../artifacts/production_visual/cards/actual_sizes.png)
- [Square source-scale sheet](../artifacts/production_visual/cards/source_scale.png)
- [Source-family comparison](../artifacts/production_visual/cards/source_recovery_comparison.png)
- [Club source-composition refinement](../artifacts/production_visual/cards/composition_refinement.png)
- [Card provenance and regeneration](../assets/presentation/cards/PROVENANCE.md)
- [World provenance](../assets/world/PROVENANCE.md), [UI provenance](../assets/ui/PRESENTATION_PROVENANCE.md)

## Integrated evidence

Evidence is from actual Main rendering and native systems, with scripted input/state
arrangements clearly distinguished from human play. Scoreboard fixtures only arrange
review screens; production awards and results remain authoritative.

| Coverage | Evidence |
|---|---|
| Before normal launch | `artifacts/production_visual/before/` |
| Final normal keyboard launch, menu to procedural aim/shot | `normal_launch/{resolution}/`, `normal_{width}.log` |
| Six-biome follow/overview, tee/shot/reset, shops/focus/purchase, tutorial/VS/New Run | `delivered/{resolution}/` — 55 captures each |
| All major UI/results/history/ending at four sizes | `delivered_gallery_dark/{resolution}/` — 34 captures each |
| Light UI | `delivered_gallery/1280x720/` — 34 captures |
| VS mode/opponents/AI/comparison/shop/card reveal/final dark and light | `vs_delivered_720/` |
| Full bag, 1984×1684 generated course, live resize, paused resize, reduced motion and generated ramp endpoints | `world_stress/` — endpoints arranged for visual inspection |

All paths in the table are below `artifacts/production_visual/` except the explicit
before path. Sizes: 1280×720, 1920×1080, 2560×1440 and 3440×1440.

[Six-biome camera recording](../artifacts/production_visual/six_biomes_camera_travel.mp4)
contains actual shots, overview and return in Meadow, Desert, Autumn, Snow, Swamp,
Volcanic order (2.2 seconds per segment; 396 sampled frames encoded at 30 fps).
It is silent, frame-sampled visual evidence, not a real-time timing benchmark.
Production audio was preserved; WASAPI lifecycle evidence is separate.

## Verification and remaining limits

- Full canonical verifier: **267/267 tests passed, 114,684 assertions**, clean import/startup and staged/unstaged
  whitespace checks; final log is `canonical_verification_final.log`.
- Four gameplay reviews: **1,467 checks, zero failures each**.
- Four final dark UI galleries plus light gallery: **2,871 layout/font/glyph checks,
  zero failures each**. Only Jersey 10 appears in rendered ordinary text.
- Normal main-entry keyboard replay: **12/12 assertions at each of four sizes**.
  The default D3D12/Forward+ renderer also passed the 1080p replay with WASAPI.
- Actual viewport pointer events purchased once at all four sizes, debited the exact
  price and requested one purchase cue plus the intended curse acknowledgement.
- Generator corpus: **864 holes, zero validation failures and zero fallbacks**.
- VS full match: **18 real AI turns, five shops, shared courses, final results and rematch**.
- Audio lifecycle: **89 checks, zero failures**, real WASAPI playback/recording.
  Music, SFX, buses and source files are unchanged; no new subjective listening claim.
- Preservation/export-path audit and card regeneration check passed. Runtime resources
  use production directories; references, sample assets, source masters, tools, tests
  and artifacts are excluded by the Windows preset. No executable was overwritten.
- The separate whole-brand generator check still reports eight stale legacy outputs
  (wordmark/emblem/icon/control SVGs). They were not regenerated over protected or
  unrelated artwork. The scoped card exporter and generated icon catalog checks pass.
- Initial verification failures were retained in the evidence: manual tee restoration,
  missing imported textures, blank custom-drawn card textures, obsolete vector/font
  test expectations and layout overlap. Concrete fixes and stronger raster/visibility
  checks replaced those failures; tests were not removed.

The Windows desktop-control helper was unavailable after its prescribed recovery.
Input evidence uses Godot's real input pipeline with synthetic events, not native
mouse interaction or an owner playtest. Actual rendering was visually inspected.
Noninteger-scale shimmer, camera comfort, mouse feel and long-session aesthetic/audio
comfort still require human play. Exported-platform behavior was not tested.

## Migration and human retest

Production coverage is complete for the requested font, six-biome world, tee, eight
card illustrations and normal UI flows. Only historical comparison tools and audio
auditions remain sample-only; production has no dependency on them. The three existing
workstreams handled world art, native UI and card recovery; the former audio specialist
performed card recovery under the explicit no-audio-change scope. Root integrated
Main/ball/export paths, preservation checks and cross-system verification.

Retest F5 startup, read long card/tooltips/settings copy, take fast shots and toggle
overview/resize in several biomes, inspect the tee before/after R and VS handoff, and
purchase/inspect cartoon cards in each difficulty. Check that the revised style stays
coherent during an ordinary run and the existing audio remains comfortable.

**Next state: READY FOR FINAL INTEGRATED PLAYTEST.** Automated success is not owner
aesthetic or release approval.
