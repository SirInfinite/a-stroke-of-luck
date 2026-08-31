# Game Design

This document is the authority for intended gameplay. The current prototype does not implement every rule here; see `ARCHITECTURE.md` for current behavior. Unless deliberately revised, implementation should move toward these rules.

## Run Structure

- A production run contains 18 holes: three holes in each of six biomes, in order: Meadow, Desert, Autumn, Snow, Swamp, and Volcanic.
- Each biome uses the same generator and gameplay systems. Its profile supplies palettes, decoration identifiers, hazard weights, generator difficulty values, and ambience.
- Within each biome, Hole 1 is introductory, Hole 2 is normal, and Hole 3 is that biome's hardest layout.
- Each hole proceeds through play and hole results, then the next hole. A shop appears after Hole 3 of biomes 1–5; no shop appears after the Volcanic finale.
- The production lifecycle is `MAIN_MENU -> RUN_START -> BIOME_INTRO -> HOLE_PLAY -> HOLE_RESULTS`, with `SHOP` between biomes 1–5 and `RUN_RESULTS -> ENDING` after Hole 18.
- At run end, show total strokes, score relative to total par, total adjusted time, purchases, obstacles encountered, and a letter grade. The player can start a new run.
- Currency, upgrades, and penalties reset between runs.

## Shot and Player Abilities

- The ball moves on a flat 2D plane with no spin or elevation and decelerates predictably.
- Mouse: click/drag from the stopped ball to set direction and power; release to shoot.
- Keyboard: left/right adjust direction, up/down adjust power, and Space or Enter shoots.
- An aim indicator and power display communicate the planned shot. A trajectory preview may be granted, removed, or modified by effects.
- The player may shoot only while the ball is stopped and not sinking/resetting.
- `R` resets the current hole to its starting state. This is a prototype recovery control, not a score-optimization mechanic; production behavior must prevent it from erasing legitimate run cost.

## Terrain and Hazards

| Type | Rule |
|---|---|
| Fairway | Normal movement. |
| Rough | Slows roll relative to fairway. |
| Sand | Strongly slows/stops the ball and makes escape costly. |
| Water | Resets the ball to the hole start and adds one penalty stroke. |
| Green | Clear destination surface around the cup. |
| Out of bounds | Resets the ball and adds one penalty stroke. |
| Wind/direction zone | Pushes the moving ball in a visible direction while occupied. |

Entering the cup completes the hole. Hazard effects must end on exit, reset, or level transition.

## Scoring, Time, and Loss

- Every completed shot counts as one stroke. Hazard penalties add strokes.
- Par is authored per hole. Demo holes should normally be par 3 or 4.
- Relative score is strokes minus par: birdie or better is under par, par is even, bogey is +1, and double bogey is +2.
- A hole ends automatically at par + 4 strokes and advances with that recorded score.
- The run timer advances during hole play and pauses during results and shops.
- The speed score is elapsed play time plus a time penalty for each stroke. The exact penalty and letter-grade thresholds remain tuning decisions and must be fixed before results-screen completion.
- Completing the final hole is the run win state. Reaching a hole’s stroke ceiling is a hole-level loss/forced advance, not a failed run.

## Economy and Shop

- Start each run with 2 coins.
- Award coins after a hole: birdie or better 3; par 2; bogey 1; double bogey or worse 0.
- A shop offers exactly 4 seeded-randomized items. The player may buy 0–2, then skip/continue. Offers do not carry forward.
- Each card shows name, cost, benefit, and penalty before purchase. Unaffordable offers remain readable but disabled.
- Release bonuses persist for the run. Every release curse applies to the next biome's three holes, then expires; completing, forcing, or resetting a hole never consumes more than that hole's one duration step.
- Stacked effects must be deterministic, visible, and bounded so a run remains completable.

## Upgrade Pool

The original 15-item pool remains in `DESIGN_DOCS.md`, Section 3.3. Release mode uses the smallest eight-card functional pool supported by the central effect resolver; expansion to the full original pool is deferred.

| Card | Cost | Persistent run bonus | Next-biome curse (3 holes) |
|---|---:|---|---|
| Overdrive Driver | 3 | +25% shot power | Power control is 15% less precise |
| Rangefinder Lens | 2 | +4 trajectory dots | -10% shot power |
| Sand Cleats | 2 | Sand and rough slow 35% less | Direction zones push 25% harder |
| Heavy Core | 2 | -20% normal roll damping | Sand and rough slow 15% more |
| Lucky Putter | 3 | Birdie or better earns +2 coins | Cup is 25% smaller |
| Power Club | 2 | +20% shot power | One extra direction zone per hole |
| Coin Magnet | 1 | +1 coin after every hole | -2 trajectory dots |
| Gust Guard | 2 | Direction-zone push reduced by 50% | One extra direction zone per hole |

Copies stack additively. Central safety bounds keep shot/control/roll multipliers, trajectory dots, terrain and direction mitigation, rewards, cup scale, and curse-added hazard count within completable limits. Shop text must disclose the implemented bonus, curse, duration, and stacking behavior exactly.

Double Down must duplicate both sides of one selected item. Curse Breaker removes one active obstacle but skips the shop after the next hole. Effects that alter future layout or shops must be resolved before the affected hole/shop is built.

## Level Structure and Difficulty

- A hole has one start, one reachable cup, authored par, playable terrain, boundaries, and zero or more hazards/obstacles.
- All six biomes share one deterministic route generator. Difficulty increases within each biome through narrower routes, more hazards, and smaller cups, without hidden physics changes.
- Biome profiles weight rough, sand, water, direction, and out-of-bounds hazards differently while retaining the same hazard behaviors.
- Difficulty should come from readable geometry, accumulated tradeoffs, and route decisions—not hidden physics changes.
- One optional shortcut per suitable hole is encouraged when both safe and risky routes read clearly.

## Procedural Generation

Procedural generation is the production course source. A run records one seed and deterministically produces all 18 holes through the shared generator. Generation must:

- produce a connected playable route from start to cup;
- keep start, cup, and hazards on valid terrain;
- assign reachable par based on tested routes, not distance alone;
- preserve enough clear landing space for the ball and cup;
- introduce hazards according to the run’s difficulty and active penalties;
- validate every result and fall back to an authored hole on failure;
- use a recordable seed for reproduction and playtesting.

Generation attempts are bounded. An invalid candidate is never sent to `LevelBuilder`; after the retry budget is exhausted, a validated authored fallback receives the active biome's presentation data.

## Results Tuning

The release placeholder grade uses total score relative to the 18-hole par: A at -6 or better, B from -5 through even, C from +1 through +8, D from +9 through +16, and F at +17 or worse. Stroke-to-time penalty, exact putting success behavior, final item durations where source wording is ambiguous, and whether a manual reset carries a penalty still require playtesting decisions.
