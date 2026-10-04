# Grandpa Golf reference media

Current reconstruction, dense PTS review, implementation and rendered comparisons are
maintained in [REFERENCE_RECONSTRUCTION.md](REFERENCE_RECONSTRUCTION.md). The earlier
candidate specification below is historical; it no longer imposes a sample-only gate.

Inspected 2026-09-24 in `C:/Users/Rony/Projects/a-stroke-of-luck/assets/references/`.
Originals are read-only development references, never production assets. Sixteen JPEGs
are all 1920×1080. All open successfully; no exact duplicates. Similar shots share
materials but show distinct geometry, items or states; they are not independent style votes.
Metadata and SHA-256 inventory: `artifacts/reference_review/source_inventory.json`.
Labelled overview sheets: `artifacts/reference_review/screenshots_1.jpg` and `screenshots_2.jpg`.

| Exact project-relative path | Type / tags | Observed content |
|---|---|---|
| `assets/references/ss_0cddf672c38bf5e0f0dc6b50fd3244a47fae7462.1920x1080.jpg` | JPEG; alternate material, HUD | Burgundy solid masses with warm layered trim; transparent blue water, item rail, curved shot trail. |
| `assets/references/ss_2180c7021aa89135fcb5fbfc0f5e5ceff5d4f42a.1920x1080.jpg` | JPEG; forest, background, HUD | Dark rock against yellow sky and cool pointed tree layers; fine green edge fringe, pale outlined numbers. |
| `assets/references/ss_508f4ce6ea5aad8d5ec720353f87d936d3f01e5b.1920x1080.jpg` | JPEG; alternate material, water | Same burgundy/water family as 0cdd, distinct room; thin inner water bands and sparse highlights. |
| `assets/references/ss_5c71f7f281de672054c04fdf71eaa7e0a8abd1da.1920x1080.jpg` | JPEG; upgrade menu, typography, panels/buttons | Three stacked dark translucent rows, large pale outlined title, yellow Select; blue Godot-like icons appear placeholder-like and are excluded from target art. |
| `assets/references/ss_67b19c56802de57a61d4643e18c14a940ee60360.1920x1080.jpg` | JPEG; shop, item art, typography | Left Boot details; three upright offers with individually shaded boot/glove; compact thin gold rims, yellow Buy. |
| `assets/references/ss_6b3c566d83f89800c6dc7703ad141fb80a1b4ee4.1920x1080.jpg` | JPEG; forest, course edges | Stepped/sloped green-edged dark route, calm large interior mass and rich background separation. |
| `assets/references/ss_73d22969ecc4b72687e3e89df8e65ce67210e02d.1920x1080.jpg` | JPEG; forest, HUD, feedback | Enclosed forest arch; prominent flame/ice score emphasis, many small equipment sprites. |
| `assets/references/ss_74ce2d225215af0bb3cddc8f7825e568c29758a9.1920x1080.jpg` | JPEG; forest, background | Warm skyline, red cup flag, narrow tree clusters; dark slab and green lip separate terrain from vista. |
| `assets/references/ss_850b529563d9e26c059d2b470441dc0b7b3de3dd.1920x1080.jpg` | JPEG; forest, background, HUD | Broad warm sky, cool tree silhouettes and stepped route; sparse inventory highlights large negative space. |
| `assets/references/ss_880dfb99f3d9004c75de926fda3527c73c761fe5.1920x1080.jpg` | JPEG; alternate material, background | Open V course, sunset bands and reddish distant terrain; blue sloping surfaces against layered trim. |
| `assets/references/ss_8e0e8c6ecbad86b67353ec61af994acbdfa917c2.1920x1080.jpg` | JPEG; alternate material, water | Arched burgundy room with blue water and tiny grass landings, restrained interior shading. |
| `assets/references/ss_d2ca6ce182fd4edbae96056d4a0fd01552d8c6ee.1920x1080.jpg` | JPEG; inventory/items, panels/buttons | Twenty distinct object slots beside selected golf-ball details; single-item silhouettes, rim highlights, thin dark/gold slot frames. |
| `assets/references/ss_d34662dc31c80937bf2aae7b4cfd27646bd1a9f3.1920x1080.jpg` | JPEG; alternate material, course edges | Tall trimmed brown structures with tiny green ledges; distant sunset landscape visible through negative space. |
| `assets/references/ss_dcae3a23ba86cd381900f3c94fcbc3a90ea66049.1920x1080.jpg` | JPEG; alternate material, HUD | Diagonal stair course; pale/gold rim around calm brown masses, large outlined score. |
| `assets/references/ss_e3bf0ca5605a027ea649fdcc65f75f9d7278a368.1920x1080.jpg` | JPEG; forest, background | Related forest ramp composition to 850b; distinct hole and foreground route; broad warm/cool bands. |
| `assets/references/ss_eaf4d0747eee69e4380a6dbeb0ec3449c30b0f68.1920x1080.jpg` | JPEG; background, material, aiming | Opening brown-room composition, thin layered boundaries, broad sunset layers, white ball and pale trajectory. |
| `assets/references/Screen Recording 2026-09-24 143837.mp4` | H.264 video; gameplay feedback, shop, music, SFX | 34.366633 s, 806×452, 30 fps; embedded AAC stereo 48 kHz, 34.239979 s. Edited gameplay montage, shop and item selection, promotional ending, then restart. Not a continuous playthrough or loop demonstration. |

## Recording coverage and limits

Whole-duration 1 Hz coverage appears in `recording_1.jpg` through `recording_3.jpg`.
Frame sheets establish composition and event order only; closer sequential-frame review
is used for timing. Audio presence is verified, but subjective listening is pending unless
an actual listening-capable tool is demonstrated. Storefront arrows/transport controls
at 0–1 s and near the end, edit cuts, compression and promotional end card are not style requirements.

| Range in the recording above | Directly visible subject |
|---|---|
| 0–1.5 s | Storefront player overlay, then start of montage. |
| 1.5–6.7 s | Released moving ball, short fading trail, contacts and camera following across brown rooms. |
| 6.7–8.8 s | Cup-area sequence and large changing result numbers. |
| 11.7–12.9 s | Shop with item details and yellow Buy actions; short edited appearance, not proof of full purchase flow. |
| 14.0–19.9 s | Moving ball/water passages, rebound trails, later item selection transition. |
| 20.0–20.8 s | Pick an Item overlay: illustrated object rows and yellow Select. |
| 21.0–27.1333 s | Water-column gameplay into cup; ordered result updates, settled 9,600 at 26.7333 s. |
| 27.1667–32.7 s | Promotional logo/end card; separate from in-game title evidence. |
| 32.8–34.37 s | Recording returns to opening gameplay image/player. |

## Shared implementation contract for the approval slice

Root creative direction from the current owner request: atmospheric arcade pixel art,
top-down solid course, original recognizable equipment, compact translucent UI and bold
outlined display type. Earlier flat-vector, toy-like and atmosphere-prohibiting guidance
does not constrain this candidate. The approved logo remains byte-identical.

| Observed reference trait | Source / timestamp | Application | Implementation target | Check |
|---|---|---|---|---|
| Warm sky / cool layered silhouettes | 850b screenshot; recording 2–6 s | Scenic depth outside an opaque top-down board | Meadow and Volcanic backdrop assets | Overview/follow capture; scenery never fills playable tiles |
| Calm masses, crafted continuous edges | 2180 and d346 screenshots | Checker turf with connected grass/stone rims; wall caps and side shading | Sample world adapter only | Same collider/geometry snapshot before/after |
| Distinct material clusters | 0cdd and 508f screenshots | Water/sand/pad artwork coherent with course | Surface sprite family | Actual collision/response capture |
| Individually recognizable objects | d2ca inventory and 67b shop | Driver, cleats, magnet, lens (plus real offers needed for 5/6 layout) | Original transparent item sprites | Inspect at actual card and effect-rail sizes |
| Thin warm rims, translucent ink panels | 67b shop; recording 12 s and 20 s | Shared panels/buttons/details, benefit and curse always visible | Sample UI skin | 4/5/6 offers; focus, purchase, long copy |
| Large pale numbers and yellow actions | 5c71 and 67b screenshots | Strokes/par/coins; gold Buy/Continue, strong results | Typography/theme/HUD | 720p–1440p and wide; no clipping |
| Brief motion traces and escalating outcome | recording 2–6 s, 24–26.6 s | Native shot/impact/cup/purchase event choreography | Cosmetic feedback/audio adapters | Frame-indexed real game event recording; no rule delays |

Pixel-density trials use the same geometry: 48 source pixels per 100-world-unit cell
versus 32. Item art nominally 96–128 px with deliberate smaller clusters; icons 24–32 px;
background approximately 768×432. These are project trials, not asserted reference-native
resolutions. Nearest texture sampling, clean alpha, upper-left material light, dark
selective outlines, three-to-five-tone material ramps. UI type may use a separate readable scale.
Meadow: yellow light, blue-green distance, moss/jade turf, warm pale rim. Volcanic:
ochre atmospheric light, plum/charcoal peaks, basalt course, orange rim and lava.
No physics snapping, generator changes, new gameplay rules or default-scene switch.

## Exclusive ownership in the shared checkout

- World specialist: `tools/reference_slice/world/`, `assets/reference_slice/world/`, its provenance and analysis subfolder.
- UI specialist: `tools/reference_slice/ui/`, `assets/reference_slice/ui/`, its provenance and analysis subfolder.
- Audio specialist: `tools/reference_slice/audio/`, `assets/reference_slice/audio/`, its provenance and analysis subfolder.
- Root: shared index/specification, scene/harness integration, feedback composition, launchers, evidence and review documents, export exclusions.

Exactly three specialists; no nested teams. Existing files are read-only to specialists
unless root agrees a specific shared-file change. Original references and approved logo/audio
sources are never changed. All work stops at the integrated owner approval checkpoint.
