# Art Direction

## North Star

**A Stroke of Luck** should look simple enough that every mechanic reads instantly, polished enough that every action feels intentional, and playful enough that stacked bonuses and curses give each run visible personality.

The style is clean, stylized top-down 2D: soft geometry, restrained outlines, minimal texture, subtle value shifts, and exaggerated but readable proportions. It should feel like an idealized miniature golf landscape, not a realistic country club or simulation.

## Visual Pillars

1. **Golf comes first.** The ball, route, cup, terrain, hazards, and aim must read before decoration or UI.
2. **Simple shapes, strong presentation.** Consistent silhouettes, layering, motion, and feedback matter more than asset detail.
3. **Calm play, controlled chaos.** Ordinary golf is pleasant and stable; purchases, curses, and stacked run effects add concentrated visual energy without obscuring play.
4. **Benefit and penalty have equal clarity.** Never hide the downside through hierarchy, wording, or color. Never rely on color alone.

## Meadow Biome

The first and only production-priority biome is bright, inviting, lightly whimsical, and uncluttered.

| Element | Treatment | Working color |
|---|---|---|
| Fairway | Smooth, quiet primary route | `#63B75D` |
| Green | Cleaner and brighter destination surface | `#8DCF63` |
| Rough | Darker/denser; boundary obvious before shooting | `#3F7D44` |
| Sand | Warm, strong silhouette; sparse texture | `#D9BC78` |
| Water | Cool separation; subtle ripple/highlight motion | `#4FA6D8` |
| Course surround | Darker and less prominent than play space | `#245C3A` |

The existing alternating dark-green grid, brown collision walls, polygonal ball, cup, and striped flag are functional prototype language, not a mandate to preserve checkerboarding or rectangular terrain in final art. Preserve their clarity while moving toward softer course shapes.

Out-of-bounds must not resemble harmless background grass. Use a consistent boundary/drop-off/warning treatment. Any object with collision should visually communicate approximately the same footprint.

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
- **Cup:** dark opening plus flag/pin and green-area contrast. Important, but not collectible-like.
- **Aim:** originates at the ball and contrasts across every surface. Power and direction must be more legible than decoration.
- **Trajectory preview:** translucent and segmented/fading so it reads as prediction, not the physical path.
- **Hazards:** distinguishable by silhouette, value, and motion before the player reads a label.

## UI and Shop

Keep the course dominant. Intended HUD hierarchy: strokes and run timer top-left; currency and compact active-penalty icons top-right; shot information bottom-center. Use clear type hierarchy, generous spacing, moderate rounding, restrained borders, and consistent interaction states.

The shop is visually more energetic than hole play. Every card gives equivalent weight to:

1. name and cost;
2. benefit;
3. curse/obstacle;
4. buy, disabled, and purchased state.

Purchase feedback should connect currency loss, acquired benefit, and accepted curse in one brief sequence. Active penalties need distinct silhouettes and accessible descriptions; group them rather than flooding the HUD when they stack.

## Motion and Feedback

Use short, readable micro-animation:

- shot: impact flash/particles, restrained squash or camera response, speed trail only when useful;
- rough/sand/water: distinct grass disturbance, puff, or splash/ripple;
- cup: brief drop, flag response, score cue, then prompt transition;
- purchase: coin change, card confirmation, and paired bonus/curse acknowledgement.

Effects communicate impact, speed, terrain, reward, punishment, selection, or completion. If removing an effect would not reduce understanding or feel, it is low priority.

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

Finish the Meadow before exploring a second biome. Placeholders may support unfinished systems, but final player-facing features must meet `QUALITY_BAR.md`.

## Avoid

Photorealism, simulation-style presentation, noisy textures, ornate permanent HUD frames, excessive particles, tiny decorative detail, inconsistent asset styles, or copying the mechanics/visual identity of reference games.

Final font, outline thickness, texture level, shadows, and future-biome identity remain open. Until tested, choose reversible treatments that preserve clarity and keep production scope small.
