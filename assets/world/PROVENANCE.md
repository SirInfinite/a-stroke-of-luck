# Production world artwork

2026-09-24. The owner's subsequent task authorizes production integration of the
reference-led presentation. These exports are used by the normal `LevelBuilder`
and `WorldArt` catalog; the older approval scenes remain separate historical
comparisons. No reference screenshot, video frame or extracted audio is a
production input.

## Sources and creator

The original illustrations were made with the built-in image-generation service
from the project's original briefs. Their unmodified outputs and exact prompts
are retained in `source/`, excluded from import by `.gdignore` and from export by
the project's source-art exclusion. No purchased asset, external asset package,
third-party game artwork or new audio was added by this workstream. This records
generation provenance; it does not assert owner aesthetic approval or a license
to redistribute Grandpa Golf material.

| Original source | Actual dimensions | Exported use |
|---|---:|---|
| `source/biome_panoramas.png` | 1672 × 941 | Four separately composed Desert, Autumn, Snow and Swamp landscapes |
| `source/biome_objects.png` | 1536 × 1024 | Cactus, maple, spruce, cypress, square ice block, fire rod, directional mechanism and flowers |
| `source/material_rims.png` | 1254 × 1254 | Six illustrated continuous material strips, exported by `tools/world_art/export_rims.py` |
| `source/meadow_reconstruction.png` | 1672 × 941 | Replacement original Meadow panorama with broad warm sky and upright cool forest layers |

The last two sources were generated during the reconstruction pass with actual
reference crops supplied as visual inputs, then measured, cropped, palette-limited
and inspected in game. Exact prompts and reference roles are retained in
`source/reconstruction_prompts.json`; rim crop coordinates are in `source/material_rims.json`.
Reference images themselves are never read by the production exporters.

The panorama source has SHA-256
`83a58a4fb28dfee4d65ad991e9add30fefd4706cc7f49a3743181f6eebd313f9`.
The object source has SHA-256
`9841521dc9bf44428f62ff87f70a3f4063cc57a7cb72515348e850fdda574087`.

Volcanic landscape, terrain materials, stone mass, bearing, chain,
launch pad, willow and basalt columns reuse the project's original reference
slice illustrations. Their preserved source sheets, prompts and production
history are documented in
[`assets/reference_slice/world/PROVENANCE.md`](../reference_slice/world/PROVENANCE.md).
The export tool reads those source assets during authoring; normal game resources
load only their independent copies under `assets/world/`.

Ball, coin, tee and flag art originates from the earlier project-generated object
sheet documented in
[`assets/pixel_correction/PROVENANCE.md`](../pixel_correction/PROVENANCE.md).
The original tee export contains a pair of tees. Production crops only its left
object, exports an 11 × 16 image, and places source coordinate (5.5, 3) exactly at
the authoritative ball center. The ball export is a separate 12 × 12 ball with no
tee. Both flag poses end at source row 34 (35 pixels high), before any baked cup edge;
the pole is placed at y = -70 with scale 2, preserving the native cup's sole ownership.
All earlier source files remain unchanged. The approved logo is not an input to
this world exporter.

## Export and material conventions

Run `python tools/world_art/export_world.py`. The script records the exact source,
measured crop, dimensions and hash of every output in `manifest.json`. It performs
measured cropping, nearest-neighbor resizing, transparent-edge cleanup, palette
grading and mirrored background assembly. It does not create gameplay geometry.

There are 107 runtime PNG exports, totaling 11,488,927 bytes at this revision,
and four preserved source PNGs. The 21 object exports have binary
alpha (0 or 255), with zero nonzero RGB pixels behind alpha zero. Background
middle layers deliberately use partial alpha for atmospheric separation.

The runtime family uses 48 source pixels per 100 world units. Nearest filtering
preserves deliberate clusters. Terrain retains the native alternating square
cells, quieter putting variants and sparse material accents. The fixed source
ramp is shared by quiet and detailed exports: an accent cannot change the whole
tile's base value. Snow uses a cool mid-value floor to separate the white ball
and ice faces. Walls use world-aligned material sampling and exposed cap/side
bands, leaving joined edges continuous.

The six landscapes are 768 × 432. Each camera depth layer uses a 1536 × 432 mirrored
pair with matching repeat edges. Nearby plants remain at fixed world coordinates;
two distant layers respond to camera travel at different rates. Bounded ambient
particles use separate faded lifetimes. Pausing freezes inherited decorative
processing, and reduced motion suppresses decorative clocks and parallax travel.
No particle clock globally wraps to a mismatched lifetime.

Native `MovingHazard` remains the sole position, collider, danger-window and reset
owner. The pendulum support reads its actual body position; the illustrated mass
does not run a second swing clock. Falling ice uses the native full-tile footprint.
Elevation surfaces, ramps and short underpasses keep the same material family and
native dimensions. Terrain animation, impact tint and scenery do not consume
generation or AI randomness.

## Review evidence and limits

The reconstruction comparisons replaced weak gray rims with illustrated material
bands, reduced repeated paired props, and strengthened warm/cool depth. A broad
opaque ground trial was rejected because it concealed the panorama. Final nearby
roots sit on narrow merged banks following the actual occupied-cell boundary;
the banks have no collision and the distant scene remains outside them.
Current comparisons and verification supersede the earlier sample evidence:
[`docs/REFERENCE_RECONSTRUCTION.md`](../../docs/REFERENCE_RECONSTRUCTION.md).

Focused course-art verification is recorded in
`artifacts/production_world/course_visual_tests_after_flag.log`: 8 tests and 1,857 assertions
passed. The checks include six-biome resource families, exact world footprints,
single tee seat, exposed layer order, anchored contact points, pause/reduced motion
and consistent quiet/detail base values. They do not establish subjective art
quality, camera comfort or final owner approval. Integration and complete-project
verification belong to the root production report. No build was exported here.
