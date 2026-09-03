# Art Direction

## North Star

**A Stroke of Luck** should look simple enough that every mechanic reads instantly, polished enough that every action feels intentional, and playful enough that stacked bonuses and curses give each run visible personality.

The style is clean, stylized top-down 2D: soft geometry, restrained outlines, minimal texture, subtle value shifts, and exaggerated but readable proportions. It should feel like an idealized miniature golf landscape, not a realistic country club or simulation.

## Visual Pillars

1. **Golf comes first.** The ball, route, cup, terrain, hazards, and aim must read before decoration or UI.
2. **Simple shapes, strong presentation.** Consistent silhouettes, layering, motion, and feedback matter more than asset detail.
3. **Calm play, controlled chaos.** Ordinary golf is pleasant and stable; purchases, curses, and stacked run effects add concentrated visual energy without obscuring play.
4. **Benefit and penalty have equal clarity.** Never hide the downside through hierarchy, wording, or color. Never rely on color alone.

## Biome Foundation

Meadow is the visual foundation and remains bright, inviting, lightly whimsical, and uncluttered. Release mode adds Desert, Autumn, Snow, Swamp, and Volcanic as reversible data profiles using the same primitive rendering and gameplay systems. Their immediate purpose is readable palette and hazard-weight variation, not bespoke art production.

| Element | Treatment | Working color |
|---|---|---|
| Fairway | Smooth, quiet primary route | `#63B75D` |
| Putting region | The biome's same tile language, darkened to mark the destination without changing physics | Biome-derived |
| Visual rough | Darker/denser grass variation away from the cup; no mechanical boundary | `#3F7D44` |
| Sand | Warm, strong silhouette; sparse texture | `#D9BC78` |
| Water | Cool separation; subtle ripple/highlight motion | `#4FA6D8` |
| Course surround | Darker and less prominent than play space | `#245C3A` |

The existing alternating dark-green grid, brown collision walls, polygonal ball, cup, and striped flag are functional prototype language, not a mandate to preserve checkerboarding or rectangular terrain in final art. Preserve their clarity while moving toward softer course shapes.

Water or its biome equivalent is the primary environmental reset hazard. Course boundary walls must read as one continuous connected structure, with square connected sides and bevel/rounding only on exposed corners. Any object with collision should visually communicate approximately the same footprint and occupied elevation.

### Release Biome Kit

All production biomes use the same procedural vector kit for the ball, tee marker, putting region, cup, flag, course boundary, hazards, aim preview, and decorations. `CourseVisualFactory` owns the reusable primitive silhouettes; biome profiles select colors and decoration identifiers. The cup asset is only the dark opening, pole, and flag: surrounding terrain owns every biome surface. `BiomeAmbience` adds deterministic, low-contrast motion outside the main route so it never changes collision or competes with the course. Background fill and decoration fields extend substantially beyond the expected camera view so ordinary 1440p and ultrawide framing never reveals the engine clear color.

| Biome | Readable identity | Reused decoration set |
|---|---|---|
| Meadow | Clean greens, lakes, lilies with pink flowers, frogs, shrubs, trees, grass, flowers, drifting pollen | water garden and soft foliage |
| Desert | Warm sand and dry earth, dunes, cacti with rare pink flowers, rocks, tumbleweeds, wind streaks | dry silhouettes and lateral motion |
| Autumn | Amber fairways, varied warm trees, ground/falling leaves, rare apples | layered foliage and drifting leaves |
| Snow | Pale snow/ice, snowbanks, ice formations, penguins, restrained snowfall | cool clustered silhouettes and flakes |
| Swamp | Dark wet greens, ponds, reeds, fog, bubbles, plants, wet organic detail | water plants and rising/fading motion |
| Volcanic | Dark basalt, lava pools/cracks, rock mounds, embers, smoke and heat detail | glowing fissures and phased particles |

Hazards embed into their environment instead of sitting in board-like outlined cards: sand uses grains/ridges, water uses ripples, ice uses facets/highlights, lava uses glowing cracks, and direction pads keep their arrow. Bounce pads, blockers, pendulums, falling ice, and rotating fire rods retain shared collision silhouettes and non-color cues. Moving hazards show path, timing, and dangerous region without obscuring the route.

## Semantic Language

- Bonus: green (`#43B96B`) plus a positive icon/label.
- Curse/danger: red (`#D9534F`) plus warning icon/shape.
- Currency/reward: gold (`#E2B84B`).
- Selection/aim: high-contrast off-white (`#F4F0E6`) or a reserved accent.
- Neutral UI: dark charcoal (`#252A2C`) and off-white.
- Disabled/unaffordable: desaturated, but still readable.

Strong colors communicate meaning. Do not introduce a new saturated color casually. Ordinary golf uses rounded, stable shapes; curses and hazards may use sharper angles, asymmetry, pulses, or directional motion.

## Focal Gameplay Elements

- **Ball:** light, dimensional enough to separate from terrain, restrained dark outline, visible everywhere. Effects never obscure its true position.
- **Cup:** dark opening plus flag pole/flag and local biome-darkened putting contrast. Do not draw a target ring, grass patch, sand patch, or universal land tile around it.
- **Aim:** originates at the ball and contrasts across every surface. Power and direction must be more legible than decoration.
- **Trajectory preview:** translucent, segmented/fading, adaptively spaced, and palette-aware. It remains subordinate but must retain foreground/backing contrast on Snow and every other biome; a low-power shot must look genuinely short.
- **Hazards:** distinguishable by silhouette, value, and motion before the player reads a label.
- **Elevation:** raised/depressed routes, ramps, bridges, pits, and overpasses use 2D shadow, offset, edge light, occlusion, and layer order so depth reads without 3D rendering. The ball's current elevation retains full value/saturation while both non-current levels darken and lose contrast dynamically. Elevated structures are generally two-to-four tiles wide; one-cell bridges are reserved for intentional precision moments.

## UI and Shop

The release UI identity combines a calm golf foundation, bold roguelike choices, and quick arcade response. Its recurring mark is a golf ball and flag paired with a card/club underline. Dark navy-charcoal structures, clipped or notched corners, off-white type, gold rewards, green benefits, and coral-red curses make the interface recognizable without recoloring every screen to match the current biome.

The title treatment itself carries the identity: the wordmark integrates the dimpled golf ball, card corner, flag/cup, and club-swing curve into readable letterforms instead of surrounding plain text with unrelated marks. The title screen leaves explanatory copy out, gives PLAY/TUTORIAL/SETTINGS/QUIT large tactile targets, and places the composition over a subdued deterministic generated-hole attract loop with gentle cursor parallax.

Typography uses Fredoka SemiBold/Bold for the authored wordmark, display headings, biome names, cards, and large results. Atkinson Hyperlegible Regular/Bold owns descriptions, controls, HUD values, and secondary labels. Hierarchy also comes from case, tracking, alignment, weight, and grouped silhouettes; size alone is not sufficient. Font provenance and bundled licenses live in `assets/fonts/README.md`.

Original native vector icons share a simple filled silhouette with a light keyline. Repeated concepts such as strokes, par, timer, currency, hole, biome, hazards, bonuses, curses, shop, restart, continue, and menu should lead with their symbol and retain short text where precision or accessibility requires it. Do not use emoji or unrelated icon-pack art.

Keep the course dominant. The HUD uses compact edge clusters: large biome/hole identity at top-left, strokes/par and time near top-center, currency at top-right, semantic bonus/curse bands below, and shot information bottom-center. A mechanical five-row hole reel may expand from the identity cluster; completed/current holes show their historical six-stat snapshot, future rows say LOCKED, and biome/hole labels animate independently. Active effects use distinct badge silhouettes and icons rather than long prose. Permanent frames must not encroach on the playable route.

The shop is visually more energetic than hole play. Every card gives equivalent weight to:

1. category icon, name, and cost;
2. a large mechanic-specific symbolic centerpiece;
3. a concise green benefit region;
4. a concise red curse region;
5. stack information plus buy, disabled, hover, focus, and purchased state.

Purchase feedback should connect currency loss, acquired benefit, and accepted curse in one brief sequence. Active penalties need distinct silhouettes and accessible descriptions; group them rather than flooding the HUD when they stack.

Buttons use a shared skewed/notched silhouette with icon-led labels. Primary actions are gold, secondary actions are dark and light-keylined, danger actions use the curse color, and quiet controls recede. Hover raises slightly, press squashes quickly, keyboard focus remains obvious, and disabled controls retain readable contrast. Cards may lift and scale on hover, while result badges, currency, warnings, and the logo use brief arrival or value-change motion. Motion must never delay input or continuously wobble the interface.

Runtime layout remains container- and anchor-led. The full composition targets 1920×1080, remains fluid at 1600×900, and switches to compact spacing and type at 1280×720. All three 16:9 sizes must preserve the focal point, complete card disclosures, readable controls, and unobstructed gameplay.

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

Audio follows the same restrained hierarchy. Title, tutorial, and six biome-specific musical loops are genuinely distinct compositions that share a cohesive synthetic palette and crossfade without stacking; subtle biome ambience remains secondary. Ordinary golf uses physical strike/cup/water/sand/purchase cues and no normal-speed rolling loop; only sufficiently fast movement receives a bounded swoosh. Synth character is reserved for anomalous effects such as the bounce pad. Music and SFX use separate buses and must never mask shot readability.

## Asset Rules

- Match top-down perspective, scale, outline weight, lighting direction, texture density, saturation, and contrast.
- Judge assets inside the running game at gameplay scale, not in isolation.
- Decoration must not resemble collision, hazards, currency, or interactables.
- Favor simple polished assets over complex inconsistent ones.
- Reuse established palette, spacing, components, and animation timing before creating new systems.
- Keep tunable presentation values centralized where practical.

## Production Priorities

1. Ball, shot, cup, and route readability.
2. Terrain/hazard distinction and interaction feedback.
3. HUD and shop clarity.
4. Completion/results feedback.
5. Stacked curse presentation.
6. Environmental decoration.

Keep Meadow as the clarity baseline for every profile. Additional release biomes must reuse the shared renderer, keep the surround quieter and darker than the playable route, and remain primitive until the complete 18-hole run passes human playtesting. Placeholders may support unfinished systems, but final player-facing features must meet `QUALITY_BAR.md`.

## Avoid

Photorealism, simulation-style presentation, noisy textures, ornate permanent HUD frames, excessive particles, tiny decorative detail, inconsistent asset styles, or copying the mechanics/visual identity of reference games.

The release font pairing and core UI identity are established. More detailed biome identity remains reversible and data-driven until human playtesting validates the full run. Use consistent moderate outlines, restrained shadows, quiet surface texture, and the shared presentation components before adding one-off treatment.
