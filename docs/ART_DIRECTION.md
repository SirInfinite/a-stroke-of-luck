# Art Direction

## 2026-09-24 approved production direction

The latest owner direction supersedes the older sample's toy-like, minimal-vector and
atmosphere-limiting advice. The supplied Grandpa Golf library in `assets/references/`
is the primary presentation evidence: rich atmospheric layers outside the top-down
course, crafted continuous material edges, individually illustrated equipment, compact
dark translucent panels, thin contrasting rims, pale outlined type and yellow actions.
See [the source index](REFERENCE_MEDIA_INDEX.md) and the current [measured reconstruction and comparison ledger](REFERENCE_RECONSTRUCTION.md).
The owner's subsequent correction explicitly authorizes this presentation throughout normal
`scenes/main.tscn`, including every biome, tutorial and Solo/VS flow. The earlier sample-only
gate is superseded. Production audio remains unchanged; the sample soundtrack auditions are
not part of this rollout.

- **Typography:** Jersey 10 is the sole ordinary text family, centralized in `UIStyle` and
  `release_theme.tres`, using `assets/fonts/Jersey10/Jersey10-Regular.ttf` (OFL). Size,
  outline, shadow and ink establish hierarchy. Use icons or supported punctuation for
  unavailable symbols rather than silently falling back to Fredoka or Atkinson.
- **Brand:** `assets/brand/approved_wordmark.png` is a byte-identical production copy of
  `assets/pixel_sample/ui/wordmark.png`; preserve that export and its source unchanged.
- **World:** 48-pixel terrain textures cover the existing 100-unit course cells. Calm
  alternating interiors, continuous crafted rims and material shading retain physical
  footprints. Pixel landmarks have stable course coordinates; distant layers respond
  separately to camera travel, while bounded ambient particles have their own animation.
  Original six-material illustrated rim strips concentrate detail at the boundary. A narrow
  dark bank follows the real occupied cells beneath world-fixed plant roots; it has no
  collision and does not expand playable space. Meadow uses a warm sky and upright cool
  forest silhouettes. Distant layers remain beyond the bank, including in course overview.
- **Cards:** restore the September cartoon object family, with expressive proportions,
  bold highlights and dark pixel outlines. Eight square 80-pixel production illustrations
  share complete silhouettes and deliberate breathing room; larger square masters and
  the export script retain that composition. Rarity belongs to the enclosing frame.
- **Hierarchy:** thin translucent stepped frames, large pale names/numbers, yellow outlined
  purchase actions, and quieter benefit/curse bands. Both disclosures remain visible.
  The single horizontal power meter reports real shot power with a marker and striped fill;
  it adds no critical-hit rule. Result emphasis animates already-resolved values only.
- **Tee:** LevelBuilder owns one stationary tee with its seat centered beneath the ball.
  It disappears after the first shot and returns on manual hole/tutorial/VS start reset;
  ordinary hazard and OOB recovery keep their established behavior. Ball art has no tee.

Game rules, collision geometry, deterministic generation and the normal main scene remain
authoritative. Automated verification and human visual/input acceptance remain separate.

## Historical 2026-09-11 sample correction

This paragraph records an earlier, superseded decision: the September 11 correction favored a restrained arcade playset and retained a sample-only gate. The later reference-led direction and explicit production authorization at the top of this document now govern. Preserve the earlier comparison and approved logo sources for history; do not revive the older atmosphere restrictions or approval gate. See [the historical correction comparison](PIXEL_CORRECTION_REVIEW.md).

## North Star

**A Stroke of Luck** should look simple enough that every mechanic reads instantly, polished enough that every action feels intentional, and playful enough that stacked bonuses and curses give each run visible personality.

The style is atmospheric pixel-art top-down golf: quiet checker surfaces, crafted material edges, large scenic depth layers and expressive object illustrations. Selective pixel clusters establish material and personality without obscuring route geometry.

## Visual Pillars

1. **Golf comes first.** The ball, route, cup, terrain, hazards, and aim must read before decoration or UI.
2. **Simple shapes, strong presentation.** Consistent silhouettes, layering, motion, and feedback matter more than asset detail.
3. **Calm play, controlled chaos.** Ordinary golf is pleasant and stable; purchases, curses, and stacked run effects add concentrated visual energy without obscuring play.
4. **Benefit and penalty have equal clarity.** Never hide the downside through hierarchy, wording, or color. Never rely on color alone.

## Biome Foundation

Meadow is the visual foundation and remains bright, inviting, lightly whimsical, and uncluttered. Release mode adds Desert, Autumn, Snow, Swamp, and Volcanic as reversible data profiles using the same production pixel renderer and gameplay systems. Each has an authored silhouette and environmental character as well as a palette: pond gardens, cactus dunes, amber groves, ice shelves, reed pools, and basalt/lava shelves. These details remain cosmetic and subordinate to the route.

| Element | Treatment | Working color |
|---|---|---|
| Fairway | Smooth, quiet primary route | `#63B75D` |
| Putting region | The biome's same tile language, darkened to mark the destination without changing physics | Biome-derived |
| Visual rough | Darker/denser grass variation away from the cup; no mechanical boundary | `#3F7D44` |
| Sand | Warm, strong silhouette; sparse texture | `#D9BC78` |
| Water | Cool separation; subtle ripple/highlight motion | `#4FA6D8` |
| Course surround | Darker and less prominent than play space | `#245C3A` |

The alternating course cells are deliberate miniature-golf geometry. Subtle variation, grain, integrated putting cells, connected hazard banks, and bevelled wall caps make the grid tactile without disguising its boundaries. Rough uses sparse grass tufts, not a dark outlined patch that could be mistaken for a hazard. Decoration can have softer organic silhouettes outside the playable route.

Water or its biome equivalent is the primary environmental reset hazard. Course boundary walls must read as one continuous connected structure, with square connected sides and bevel/rounding only on exposed corners. Any object with collision should visually communicate approximately the same footprint and occupied elevation.

Boundary joins use square fills rather than rounded inside corners or background slivers. Lower-elevation entrances/exits have no explicit arrows, circles or labels: ramps, walls and active-layer shading explain the change. Falling ice uses an exact full-tile square warning and matching landed block. Pendulum chain art follows the moving damaging ball. Ordinary non-putting tiles receive deterministic sparse 1–2 tiny darker blades (about one tile in seven); Volcanic uses equally small cracks. These marks are decoration, not shot-direction arrows.

Wall top faces and longitudinal rails follow each segment's axis, including vertical side walls. Sparse world-spaced joinery replaces a repeated transverse end cap on every cell; adjacent segments read as one constructed boundary.

### Release Biome Kit

All production biomes use the same shared pixel material and sprite kit for the ball, tee marker, cup, flag, course boundary, hazards, aim preview, and decorations. `CourseVisualFactory` owns reusable world visuals and the production raster catalog; biome profiles select colors and decoration identifiers. The putting region is not a separate silhouette: `LevelBuilder` applies the biome's `green_a`/`green_b` treatment to the existing alternating course cells so their boundaries and detail stay visible. The cup asset is only the dark opening, pole, and flag: surrounding terrain owns every biome surface. `BiomeAmbience` adds deterministic, low-contrast motion outside the main route so it never changes collision or competes with the course. Background fill and decoration fields extend substantially beyond the expected camera view so ordinary 1440p and ultrawide framing never reveals the engine clear color.

| Biome | Readable identity | Reused decoration set |
|---|---|---|
| Meadow | Warm sky, green forest depth, willow groves and pollen | illustrated willow groups |
| Desert | Sandstone formations, amber sky, cactus clusters and wind streaks | cactus groups and dry mineral ramps |
| Autumn | Amber woodland, maple silhouettes and drifting leaves | warm maple groups |
| Snow | Mountain shelves, cold ramps, spruce silhouettes and snowfall | snow-covered spruce groups |
| Swamp | Wet forest, cypress roots, dark green water atmosphere and rising motes | cypress groups |
| Volcanic | Basalt silhouettes, lava light, dark rock and embers | basalt columns |

Surrounds are composed as seeded landscape groups, not independent scattered props: Meadow alternates tree/flower clearings and lily ponds; Desert layers dune ridges and cactus/rock groups; Autumn combines leaf-litter groves and fallen logs; Snow separates fir banks, frozen lakes and penguin pairs; Swamp uses rooted cypress/reed pools; Volcanic contrasts basalt columns and hot fissure shelves. Group contours, sizes and secondary details vary within bounded limits. These remain outside the course and quieter than hazards, with pollen, wind, leaves, snow, fog/bubbles or embers as appropriate.

Hazards embed into their environment instead of sitting in board-like outlined cards: sand uses grains/ridges, water uses ripples, ice uses facets/highlights, lava uses glowing cracks, and direction pads keep their arrow. Circular bounce pads use saturated warm yellow/gold, a dark lightning mark, and four outward energy arrows so they read as launch surfaces rather than sand, currency, cups, or reset hazards. Blockers, pendulums, falling ice, and rotating fire rods retain shared collision silhouettes and non-color cues. Moving hazards show path, timing, and dangerous region without obscuring the route.

## Semantic Language

- Bonus: green (`#43B96B`) plus a positive icon/label.
- Curse/danger: red (`#D9534F`) plus warning icon/shape.
- Currency/reward: gold (`#E2B84B`).
- Selection/aim: high-contrast off-white (`#F4F0E6`) or a reserved accent.
- Neutral fixtures: deep jade ink, with warm ivory scorecard paper for reading surfaces.
- Disabled/unaffordable: a muted action and explicit status stamp; card benefit and curse disclosures retain full contrast.

Strong colors communicate meaning. Do not introduce a new saturated color casually. Ordinary golf uses rounded, stable shapes; curses and hazards may use sharper angles, asymmetry, pulses, or directional motion.

## Focal Gameplay Elements

- **Ball:** light, dimensional enough to separate from terrain, restrained dark outline, visible everywhere. Effects never obscure its true position.
- **Cup:** dark opening plus flag pole/flag and local biome-darkened `green_a`/`green_b` course cells. Keep the normal tile grid, checker variation, and detail visible; do not draw a target ring, grass patch, sand patch, universal land tile, or smooth putting overlay around it.
- **Aim:** originates at the ball and contrasts across every surface. Power and direction must be more legible than decoration.
- **Power:** `PowerPalette` supplies the same gold-to-danger-red ramp to pullback and meter; current power is the hot end of the pullback gradient, with a dark backing for Snow/bright surfaces. The terminal trajectory arrow's tip sits at the forecast stop rather than beyond it.
- **Trajectory preview:** one straight, translucent, adaptively spaced line with a terminal arrow at the uninterrupted resting point. Do not display ricochet chains. It remains subordinate but must retain foreground/backing contrast on Snow and every other biome; a low-power shot must look genuinely short.
- **Hazards:** distinguishable by silhouette, value, and motion before the player reads a label.
- **Elevation:** lower course areas, ramps, raised paths, bridges, and sparse overpasses use 2D shadow, offset, darker perimeter edges, higher-wall shadow, occlusion, and layer order so depth reads without 3D rendering. Lower terrain always reuses the active biome's normal surface and hazard language; it must never read as a separate cave texture family. The ball's current elevation retains full value/saturation while both non-current levels darken and lose contrast subtly. Generated decks are normally three cells wide, pinching to two only at rare crossings; tunnels never exceed two cells. Ramp ascent marks follow the ramp's entry-to-exit axis, not its transverse edge.

## UI and Shop

The production UI uses compact translucent dark panels, thin stepped pixel rims, pale display text and yellow primary actions. Benefit and curse wells remain distinct, with text and symbols as well as color. Light mode uses the same component geometry with readable paper-colored stock. Menus, native cards, the equipment rail and result numbers share this family.

The approved main logo remains unchanged raster artwork. The title leaves explanatory copy out, gives PLAY/TUTORIAL/SETTINGS/QUIT large targets and places the composition over the approved Meadow landscape with smoothly damped cursor parallax. Reduced Motion suppresses that parallax. PLAY proceeds through the native mode choice to run setup. Pause instead shows the frozen current course.

Typography uses the approved Jersey 10 family for headings, names, numbers, descriptions, controls and secondary copy. Central sizes, pale/yellow ink, deliberate dark outlines and offset shadows preserve hierarchy. The approved logo is protected artwork, not rendered text. Historical font licenses remain archived; the production license is `assets/fonts/Jersey10/OFL.txt`.

Original native vector icons share a simple filled silhouette with a light keyline. Repeated concepts such as strokes, par, timer, currency, hole, biome, hazards, bonuses, curses, shop, restart, continue, and menu should lead with their symbol and retain short text where precision or accessibility requires it. Do not use emoji or unrelated icon-pack art.

Keep the course dominant. The HUD uses compact edge clusters: large biome/hole identity at top-left, strokes/par and time near top-center, currency at top-right, semantic bonus/curse bands below, and shot information bottom-center. The results hole reel uses the same nested ticket as Seed: an outer Hole label, recessed XX/18 value, and translucent adjacent played-hole values on hover/focus. Wheel/arrow-key changes slide the central value and update the historical snapshot; future data is unavailable. Active effects use distinct badge silhouettes and icons rather than long prose. Permanent frames must not encroach on the playable route.

The shop is visually more energetic than hole play. Every card gives equivalent weight to:

1. category icon, name, and cost;
2. a large, complete cartoon equipment illustration;
3. a concise green benefit region;
4. a concise red curse region;
5. stack information plus buy, disabled, hover, focus, and purchased state.

Purchase feedback should connect currency loss, acquired benefit, and accepted curse in one brief sequence. Active penalties need distinct silhouettes and accessible descriptions; group them rather than flooding the HUD when they stack.

Four- and five-offer shops keep one readable row. Six-offer shops use a balanced 3+3 composition with no empty placeholder slots. Benefit and curse copy both use 22 logical pixels, wrap without trimming, and remain equally opaque even when unaffordable or purchased. A central equipment illustration, category, gold cost tag, and separate stack strip establish hierarchy without hiding risk. The actual stacking rule remains available through the stack region/tooltip. Power Club's club/ball/chevrons and Overdrive's lightning/speed lines are intentionally distinct.

Common, Rare, Epic and Legendary use restrained sage, blue, violet and ochre six-unit frames and lightly tinted physical card stock, with distinct gems and explicit tier labels. Category emblems keep their equipment colors; rarity never washes out the illustration, price or equally prominent benefit/curse boxes. Curse headings disclose their 3/3/4/5-hole durations.

Dark is the default appearance. Light uses warm scorecard paper, deep jade text and pale green/blue/red semantic reading surfaces, not inversion. Both share gold currency, readable danger/benefit states and rarity labels. Only UI paint changes: world palettes, title-attract course, logo artwork and collectible art stay intact. A compact `2 SHOTS LEFT` / `FINAL SHOT` strip warns before the shot without repeated modal popups.

Buttons use a shared skewed/notched silhouette with icon-led labels. Primary actions are gold, secondary actions are dark and light-keylined, danger actions use the curse color, and quiet controls recede. Hover raises slightly, press squashes quickly, keyboard focus remains obvious, and disabled controls retain readable contrast. Cards may lift and scale on hover, while result badges, currency, warnings, and the logo use brief arrival or value-change motion. Motion must never delay input or continuously wobble the interface.

Runtime layout remains container- and anchor-led. The project uses a 1920×1080 logical canvas with `canvas_items` stretch: 1280×720, 1600×900, 1920×1080, and 2560×1440 windows share the same composition at different physical scales. Compact branches respond to a smaller logical canvas, not the window's pixel width. All tested sizes must preserve the focal point, complete card disclosures, readable controls, and unobstructed gameplay. Settings use a large tabbed screen with centered option rows and explicit percentage readouts. The tutorial uses a multiline-safe paper coach below the course and above shot controls. Overview framing reserves space for these permanent UI regions; Ball View remains centered on the ball. A run pause never substitutes the title attract course: it freezes and blurs/dims the real course beneath a centered action panel, with a translucent-dim fallback when effects are reduced.

Results use a large named golf outcome, star rating, and ink-on-paper stat tickets. Seed values must remain complete rather than ellipsized. The eighteen-hole run scorecard carries a trophy seal, all six biome stamps, and a wrapped summary of the collected card names and counts; the ending repeats the seal/stamps with a short closing beat. New Run and Menu remain distinct actions.

Seed uses one outer label and a darker inset value well in both appearances. Only the value reacts to hover/focus: seed → Copy → green Seed copied! after activation → seed after about one second. Fades are short and cancellable; reduced motion uses immediate changes. Settings toggles keep identical box/padding in On/Off, checked hover and focus states. Descriptions appear only in one consistent footer on row hover or control focus. Tutorial score/time, coins and effect tickets reveal when introduced, not at lesson start.

### Gameplay camera

Ball View keeps one readable 1.25× logical gameplay scale and a responsive, bounded follow lag. The ball stays near the viewport center on every elevation. Only explicit Course Overview fits the playable course; occupied cells, walls and hazard travel determine its frame, with 64 world units of padding and clearance for visible HUD, tutorial and VS controls. Distant scenery never determines zoom.

The compact flag-icon OVERVIEW ticket sits beside Menu. Its gold pressed state and the bottom COURSE OVERVIEW readout communicate inspection; the readout shows the selected return binding. It uses the existing ticket, glyph, typography and Dark/Light language, without a modal. Enter/exit uses a 0.35-second eased pan and zoom. Overview suppresses shake; normal impacts retain their existing offset feedback. Cup emphasis remains brief and resets to Ball View. Reduced Motion removes follow lag/cup flourish and uses a short 0.15-second functional transition.

## Motion and Feedback

Use short, readable micro-animation:

- shot: impact flash/particles, restrained squash or camera response, speed trail only when useful;
- sand/water/ice/lava: distinct puff, splash/ripple, shard, or heat response;
- fully stopped ball: one restrained yellow confetti burst from ball center;
- meaningful wall impact: aggressively clamped camera shake, with tiny or no response for scraping;
- cup: brief drop, flag response, score cue, then prompt transition;
- purchase: coin change, card confirmation, and paired bonus/curse acknowledgement.

Effects communicate impact, speed, terrain, reward, punishment, selection, or completion. If removing an effect would not reduce understanding or feel, it is low priority.

The release feedback kit is deliberately shared. Shot strike rings, sampled trail, stopped confetti, terrain/hazard bursts, bounded wall shake, cup feedback, and transition flashes are palette-driven primitive effects from `FeedbackDirector`; biome variants come from profile colors rather than bespoke effect scenes. Shop feedback uses the same semantic colors: a small card scale response, gold coin pulse, and brief red curse warning. Durations and intensities are named exported values on owning feedback nodes so a feel pass can tune them without touching gameplay rules.

Gold launch rays, diamond stop-confetti, and four-point cup stars reuse the printed mark language. Reduced motion suppresses decorative lift, pulse, parallax, surface motion, and camera/ball flourish while preserving functional hazard telegraphs and immediate input. Ambient and surface animation update at a bounded 24 Hz; static decoration is not redrawn at unrestricted frame rate.

Audio follows the printed-clubhouse identity through a small acoustic chamber-arcade palette: piano, wooden mallets, harp/strumstick, flute, vibraphone and restrained hand percussion. Title anticipation, relaxed tutorial questions and each biome have independently written melodies, harmony and phrasing, with contrasting sections over 44–69 seconds rather than short scale walks. Desert uses a dry 3+2+2 pulse, Autumn a warm waltz, Snow spacious five-beat phrases, Swamp offbeat wooden replies and Volcanic stronger low-piano/drum drive. Cyclic room tails preserve musical loop continuity; fades and short ducking protect important feedback.

Normal golf uses a sharp club/ball transient, strength-sensitive wood wall contacts, watery plop, icy scrape and hot hiss. Preserve the approved sand cue. Ordinary rolling is nearly silent; high speed alone receives smoothed broadband air, never a steady synthetic note. The three supplied boosts retain their intentional magical character. Cup contact, hole reward and a short recorded crowd applause remain smaller than the final cadence. Failure plays both supplied layers plus a restrained disappointed crowd, never positive cup/score/applause cues. Purchases use one baked physical chip/register hit with a quieter dark card or stack accent; generic clicks do not double it. Subordinate biome air/leaf/insect/rumble details have 32–42 second loops. Provenance is explicit in `AUDIO_SOURCES.md`; artistic success requires human listening over a complete run.

## Asset Rules

### Legacy vector icon source and archived wordmark specification

The following describes the preserved vector tooling and remaining small semantic glyphs. It does not authorize regenerating the protected raster wordmark or replacing the production cartoon equipment family. Production equipment is owned by `tools/build_card_art.py` and `assets/presentation/cards/`; current brand and typography requirements above take precedence.

- **Construction:** flat, front-facing print glyphs on a 64×64 viewBox. One
  dominant silhouette and normally one to three interior details; repeated
  pips/dimples count as one texture motif and simplify at small size. Use 4-unit
  outlines, 5-unit action strokes, round caps/joins and 4-unit corners. Heavier
  7–9-unit stems/tabs construct filled silhouettes, not extra outlines; display
  detail may use 3 units. No double outlines, gradients, perspective or baked backdrop.
- **Optical bounds:** normally 8–56; slender clubs/flags may reach 6–58. Center
  the apparent mass, not merely the path bounds. Keep strokes inside the canvas.
- **Tiers:** small 16–32 rendered pixels uses the simplified `_small` glyph;
  medium 33–64 and display 65–160 use the regular vector. Equipment centerpieces
  reuse regular glyphs in a common printed field, not a separate illustration pack.
  Tier selection accounts for viewport stretch, not just logical control size.
- **Paint:** transparent white source glyphs are tinted by `UIIcon.icon_color`.
  `UIStyle` owns paper/ink foreground, gold value/reward, green benefit, coral
  curse, blue stack, warning and six biome accents. `UIAppearance` remaps UI ink
  for light mode; collectible fields and postcards retain authored paint.
  The wordmark has a controlled dark-ink light variant of the same outlines,
  selected for actual light surfaces. Main's scenic title stays dark in both UI
  modes, so its wordmark keeps ivory/gold ink.
  Rarity uses the existing profile accent, a distinct gem silhouette and text.
- **Containers:** HUD, stat and navigation symbols are freestanding. Active
  effects live in the existing semantic tickets; no extra icon backgrounds.
  Cards use one equipment field; results use the existing award seal. Landscape
  postcards remain illustrations, not alternate biome emblems.
- **Meaning:** sand is dunes, not equipment; ice is a cracked tile, Snow a flake;
  lava is a hot pool, Volcanic a mountain. Back and Continue point opposite ways.
  Difficulty is a family of one/two/three flag marks, not benefit/curse icons.
  Color reinforces shape and text; it never replaces them.
- **Brand:** Fredoka Bold outlines, two ball-O's, the U-shaped club swing, and one
  card-corner rule. The compact mark retains the ball/card construction. Never
  shrink the entire wordmark into an app icon.
- **Source/export:** `tools/build_brand_assets.py` is the editable vector source
  and deterministic SVG generator. Runtime assets are semantic
  `assets/ui/icons/icon_<meaning>[_small].svg`; `IconCatalog` is the sole lookup.
  `tools/export_brand_rasters.gd` uses Godot's SVG rasterizer to produce the five
  app sizes and their Windows ICO. Do not hand-edit generated outputs or add
  numbered “final” variants. `--check` verifies vector/source parity.

The audit and human-review evidence belong in `ICON_BRAND_REVIEW.md`.

The six biome glyphs share this grid and tint system: Meadow bloom/leaf stem, Desert cactus/sun, Autumn leaf/vein, Snow radial flake, Swamp reeds/lily and Volcanic mountain/crack/plume. Small variants simplify interiors; hazard glyphs retain their separate mechanical meanings.

Reproduce with Python/fontTools and Godot 4.6.2 available as `godot4`:

```powershell
python tools/build_brand_assets.py
godot4 --headless --path . --script res://tools/export_brand_rasters.gd
python tools/build_brand_assets.py --check
godot4 --headless --path . --script res://tools/export_brand_rasters.gd -- --check
```

- Match top-down perspective, scale, outline weight, lighting direction, texture density, saturation, and contrast.
- Judge assets inside the running game at gameplay scale, not in isolation.
- Decoration must not resemble collision, hazards, currency, or interactables.
- Favor simple polished assets over complex inconsistent ones.
- Reuse established palette, spacing, components, and animation timing before creating new systems.
- Keep tunable presentation values centralized where practical.

## VS AI presentation

VS screens reuse the clipped scorecard/ticket shapes, approved Jersey typography hierarchy, semantic palette and existing golf-stroke emblem. Opponents use text names plus restrained accent colors, never portraits, sponsor marks or real-world branding. Selection includes tier and short playstyle text; no color-only difficulty signal. Keep the chosen golfer visible in run setup. A compact lower-left comparison identifies the active golfer, selected spectator speed and one chosen aim; candidate sampling remains development-only. The AI ball adds a narrow opponent-colored ring, not a new sprite style. Hole/final comparisons use the existing scorecard hierarchy, and both card builds are readable in either appearance mode.

Shared course effects must be explicit: **COURSE CURSE • BOTH**, visible duration, explanatory tooltip, and shared-course HUD summaries. Personal curse styling remains unchanged. Reveal AI purchases briefly after the player's shop; do not create a second shopping interface. Focus handoffs must reject removed controls during rapid transitions.

## Production Priorities

1. Ball, shot, cup, and route readability.
2. Terrain/hazard distinction and interaction feedback.
3. HUD and shop clarity.
4. Completion/results feedback.
5. Stacked curse presentation.
6. Environmental decoration.

Keep Meadow as the clarity baseline for every profile. Additional release biomes must reuse the shared renderer, keep the surround quieter and darker than the playable route, and retain the accepted pixel-art treatment across all six biomes. Placeholders may support unfinished systems, but final player-facing features must meet `QUALITY_BAR.md`.

## Avoid

Photorealism, simulation-style presentation, noisy textures, ornate permanent HUD frames, excessive particles, tiny decorative detail, inconsistent asset styles, or copying the mechanics/visual identity of reference games.

The approved Jersey family, protected raster logo and pixel-art UI identity are established. More detailed biome identity remains reversible and data-driven until human playtesting validates the full run. Use consistent moderate outlines, restrained shadows, quiet surface texture, and the shared presentation components before adding one-off treatment.
