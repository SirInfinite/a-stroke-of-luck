# Game Design

This document is the authority for intended gameplay. The current prototype does not implement every rule here; see `ARCHITECTURE.md` for current behavior. Unless deliberately revised, implementation should move toward these rules.

## Run Structure

- A demo run contains 5–7 holes in the Meadow biome; five is the minimum.
- Each hole proceeds through play, hole results, an optional shop, then the next hole.
- Shops appear after odd-numbered holes (1, 3, 5). If no later hole remains, proceed to run results instead.
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
- A shop offers 3–4 randomized items. The player may buy 0–2, then continue. Offers do not carry forward.
- Each card shows name, cost, benefit, and penalty before purchase. Unaffordable offers remain readable but disabled.
- Purchased bonuses persist unless their text says otherwise. Penalties apply for the duration stated by the item; one-hole penalties expire after that hole.
- Stacked effects must be deterministic, visible, and bounded so a run remains completable.

## Upgrade Pool

The intended 15-item demo pool is defined in `DESIGN_DOCS.md`, Section 3.3. Preserve those item names, costs, paired effects, and duration wording until an explicit balance revision. A complete demo implements at least eight distinct items; the full prototype target is all fifteen.

Double Down must duplicate both sides of one selected item. Curse Breaker removes one active obstacle but skips the shop after the next hole. Effects that alter future layout or shops must be resolved before the affected hole/shop is built.

## Level Structure and Difficulty

- A hole has one start, one reachable cup, authored par, playable terrain, boundaries, and zero or more hazards/obstacles.
- The Meadow run begins wide and forgiving, then introduces bends, route choices, water, sand, wind, and narrower fairways.
- Hole 1 teaches shooting; Hole 2 teaches approach angle; Hole 3 presents a water lay-up/risk choice; Hole 4 emphasizes sand routing; Hole 5 combines narrow routing with wind and out-of-bounds pressure.
- Difficulty should come from readable geometry, accumulated tradeoffs, and route decisions—not hidden physics changes.
- One optional shortcut per suitable hole is encouraged when both safe and risky routes read clearly.

## Procedural Generation

Procedural generation is a stretch goal, not a demo requirement. Authored holes are canonical until generation is proven.

If added, generation must:

- produce a connected playable route from start to cup;
- keep start, cup, and hazards on valid terrain;
- assign reachable par based on tested routes, not distance alone;
- preserve enough clear landing space for the ball and cup;
- introduce hazards according to the run’s difficulty and active penalties;
- validate every result and fall back to an authored hole on failure;
- use a recordable seed for reproduction and playtesting.

## Unresolved Tuning

Stroke-to-time penalty, grade thresholds, exact putting success behavior, final item durations where the source wording is ambiguous, and whether a manual reset carries a penalty require playtesting decisions. Record resolutions here before treating related features as finished.
