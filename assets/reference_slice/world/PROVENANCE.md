# Reference slice: world artwork

2026-09-24. Original candidate artwork for the isolated approval slice. Owner style
approval is pending; these files do not authorize a full six-biome rollout.

Five new source images were produced using the built-in imagegen tool from the
exact briefs in [source/prompts.json](source/prompts.json). The original generated
PNGs are retained unmodified in `source/`, with `.gdignore` to prevent their import.
No reference screenshot pixels, reference video frames, or extracted audio form
part of a runtime asset. No external asset package or purchased material was used.

| Source | Production use |
|---|---|
| `source/meadow_background.png` | Original 768×432 warm-sky / teal-forest panorama |
| `source/volcanic_background.png` | Original 768×432 ochre-sky / plum-caldera panorama |
| `source/terrain_sheet.png` | Meadow/basalt floor and putting variants, water, sand, lava, masonry materials |
| `source/object_sheet.png` | Stone mass, metal bearing, forged chain link, launch pad; willow/column illustrations retained but not placed after review |
| `source/effects_sheet.png` | Four poses each for strike, dust/chips and water splash |

Ball, two flag poses, tee and coin are resized copies of the existing original
`assets/pixel_correction/props/` illustrations. Their sources and earlier tool
generation are documented in `assets/pixel_correction/PROVENANCE.md`. The approved
logo is neither read as an export input nor modified.

`tools/reference_slice/world/export_world.py` crops the measured sheet boundaries,
normalizes sprite alpha to 0/255, clears transparent RGB, grades floor materials to
shared ramps, and exports nearest-neighbor density trials. The source images did
not match every requested canvas dimension: their actual dimensions, measured
crops, output dimensions and SHA-256 hashes are in [export_manifest.json](export_manifest.json).
No strict reference-native pixel resolution is asserted.

The source creator is the built-in image-generation service acting on the task's
original briefs. These are project-generated illustrations, not licensed imports
from Grandpa Golf. No third-party game asset license or owner artistic approval
is being claimed. Existing project font/audio provenance is outside this workstream.

Runtime sampling is nearest, with 48 or 32 source pixels per 100-world-unit cell.
Object sprites use corresponding density families; dangerous pendulum extents are
88×88 world units and the ball uses its actual 24-unit native collision diameter.
Rims are assembled from original stone textures with continuous exposed-edge ink,
light caps and side shade. Only cosmetic sprites/materials are written at runtime.

The first rendered review found dense repeated floor motifs. The refined export
uses calm source-material crops, stronger checker values, and isolated tufts or
cracks on fewer than one in ten cells. All putting cells remain in the same quiet
tile family. Unsupported floating props were removed; distant landmarks belong
to the panoramas instead. The original prop images remain recoverable source work.

The second integrated review found dense, saturated water ripples. The revised
water uses the original source's body shade and two isolated wave clusters in a
teal ramp. Its second pose dims the same highlights rather than moving them to
unrelated positions. Native areas receive separate deterministic decorative
phases, and a density-matched exposed bank preserves their exact footprint.

There are 96 runtime PNG exports (950,711 bytes at this revision), including both
density families, and five full-size source PNGs (7,602,475 bytes). These counts
are file inventory, not a claim that every prepared lava/prop variant is shown.

Full-size references and analysis evidence live separately in
`assets/references/` and `artifacts/reference_review/world/`. Both are development
material. Root owns export exclusions and integrated validation; no build was
exported by this workstream.
