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
- Every production run has a visible positive-integer seed. The player may copy it or enter a seed before starting; the same valid seed reproduces the same 18 generated holes for the same game version and generation configuration.

## Shot and Player Abilities

- The ball uses flat 2D physics with no spin or vertical ballistics. A small discrete elevation state (`-1`, `0`, `1`) separates pits, ground routes, and raised routes; explicit ramps transition between levels.
- Mouse: click/drag from the stopped ball to set direction and power; release to shoot.
- Keyboard: left/right adjust direction, up/down adjust power, and the configured Shoot action fires; Space is the default and Enter remains a fallback.
- An aim indicator, power display, and proportional trajectory preview are standard for every player. Low-, medium-, and high-power previews use the same relevant launch and friction assumptions as the shot; effects do not enable or disable the preview.
- The player may shoot only while the ball is stopped and not sinking/resetting.
- The configured Reset action (`R` by default) returns the ball to the start without erasing accepted strokes, elapsed hole time, rewards, or cumulative run statistics. At par + 4 it resolves the forced hole outcome instead of resetting play.
- Player settings persist between launches. Only options connected to working systems are exposed: window mode, supported resolution, VSync, screen shake, visual-effects intensity, Master/Music/SFX levels and mutes, Shoot/Reset bindings, aim sensitivity, trajectory visibility, and reduced motion.

## Terrain and Hazards

| Type | Rule |
|---|---|
| Fairway / normal grass | Normal movement. Grass farther from the cup may look rougher but has identical physics. |
| Sand | Strongly slows/stops the ball and makes escape costly. |
| Water | Resets the ball to the hole start and adds one penalty stroke. |
| Putting region | Clear destination region around the cup, rendered as a darker version of the current biome's own terrain tile; physics are unchanged. |
| Ice | Reduces bounded roll friction while occupied. |
| Lava | Uses water-equivalent reset and penalty semantics with Volcanic presentation. |
| Wind/direction zone | Pushes the moving ball in a visible direction while occupied. |
| Bounce pad | Redirects the ball in a seeded random outgoing direction while retaining a bounded fraction of speed. |
| Blocker / moving hazard | Collides predictably at its occupied elevation and never permanently blocks the validated main route. |

Entering the cup completes the hole. Hazard effects must end on exit, reset, or level transition. A playable cell/elevation surface may contain at most one static hazard, blocker, or moving-hazard footprint; incompatible hazards and multiple moving anchors never overlap.

Falling ice begins as a ground shadow only. Entering the marked region triggers one fair drop; after impact the ice remains as a physical blocker until the level is rebuilt. A direct landing crush uses exactly one normal authoritative hazard reset/penalty, with no refund or duplicate block. Pendulums traverse a deterministic visible arc continuously, pause with gameplay, and use the same reset boundary when they hit the ball.

Shape-cast continuous collision detection and substantial course boundaries are the primary high-speed containment. If the ball nevertheless remains outside playable terrain, a visible three-second countdown returns it to the last accepted shot origin. Returning to playable terrain cancels the countdown; the failsafe never charges, refunds, or duplicates a stroke or hazard penalty.

## Scoring, Time, and Loss

- Every accepted shot counts immediately as one stroke, exactly once. Hazard penalties add strokes.
- Par is authored per hole. Demo holes should normally be par 3 or 4.
- Relative score is strokes minus par: birdie or better is under par, par is even, bogey is +1, and double bogey is +2.
- A hole ends automatically at par + 4 strokes and advances with that recorded score.
- The run timer advances during hole play and pauses during results and shops.
- Hole Results awards a deterministic one-to-five-star performance rating. Stroke efficiency relative to par is primary; completion time may refine the result inside bounded limits but can never turn a poor stroke result into an exceptional rating. The expected time window is `22 + par × 14` seconds: eagle-or-better starts at five stars, birdie/par at four, bogey at three, double bogey at two, and worse or forced completion at one, with documented time caps/bonuses applied by `HoleRating`.
- Hole Results names Albatross, Eagle, Birdie, Par, Bogey, Double Bogey, Triple Bogey+, or Stroke Limit as applicable and shows stars, strokes, par, time, and reward.
- Completed-hole statlines are recorded for the current run. The HUD/result history selector may display completed holes and the current hole, including their biome and six recorded stats; future holes remain visibly locked and reveal no data. Selecting history never replays or mutates a hole.
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
| Rangefinder Lens | 2 | Power control is 12% more precise | -10% shot power |
| Sand Cleats | 2 | Sand slows 35% less | Direction zones push 25% harder |
| Heavy Core | 2 | -20% normal roll damping | Sand slows 15% more |
| Lucky Putter | 3 | Birdie or better earns +2 coins | Cup is 25% smaller |
| Power Club | 2 | +20% shot power | One extra direction zone per hole |
| Coin Magnet | 1 | +1 coin after every hole | Cup is 12% smaller |
| Gust Guard | 2 | Direction-zone push reduced by 50% | One extra direction zone per hole |

Copies stack additively. Central safety bounds keep shot/control/roll multipliers, terrain and direction mitigation, rewards, cup scale, and curse-added hazard count within completable limits. Shop text must disclose the implemented bonus, curse, duration, and stacking behavior exactly.

Double Down must duplicate both sides of one selected item. Curse Breaker removes one active obstacle but skips the shop after the next hole. Effects that alter future layout or shops must be resolved before the affected hole/shop is built.

## Level Structure and Difficulty

- A hole has one tee, one reachable cup, authored par, a validated main route, playable terrain, boundaries, and zero or more hazards/obstacles.
- All six biomes share one deterministic route generator. Difficulty grows through route complexity, routine secondary branches/dead ends, blockers, moving hazards, elevation, and biome hazards—not extreme corridor narrowing or unpredictable shot physics.
- Water/lava resets, sand, ice, direction zones, blockers, bounce pads, pendulums, falling ice, and rotating fire rods use shared contracts with biome-weighted profiles.
- Difficulty should come from readable geometry, accumulated tradeoffs, and route decisions—not hidden physics changes.
- Suitable holes routinely include compact alternate branches, tempting shortcuts, different shot angles, or ordinary dead ends with a playable escape; the main route always remains valid.

## Procedural Generation

Procedural generation is the production course source. A run records one seed and deterministically produces all 18 holes through the shared generator. Generation must:

- produce a connected playable route from start to cup;
- keep start, cup, and hazards on valid terrain;
- assign reachable par based on tested routes, not distance alone;
- preserve enough clear landing space for the ball and cup;
- validate discrete surfaces, ramps, bridges, pits, overpasses, and cross-elevation collision occupancy;
- preserve a connected main route while allowing bounded branches and dead ends;
- introduce hazards according to the run’s difficulty and active penalties;
- reserve each placement footprint so hazards, blockers, moving regions, the primary route, and tee/cup recovery cells cannot conflict;
- score route continuity, navigable width, endpoint safety, hazard separation, recovery room, turn rhythm, and visual composition;
- validate every result and fall back to an authored hole on failure;
- use a recordable seed for reproduction and playtesting.

For each seed/hole pair, the generator evaluates eight deterministic candidates, rejects contract failures, and selects the highest-scoring candidate at or above the 72/100 quality floor. The score weights route continuity (24), navigable width (18), endpoint safety (14), hazard separation (14), recovery room (14), turn rhythm (9), and composition (7). If no candidate clears both validation and quality, a validated authored fallback receives the active biome's presentation data. Candidate choice never changes replay determinism.

## Results Tuning

The release run grade uses total score relative to the 18-hole par: A at -6 or better, B from -5 through even, C from +1 through +8, D from +9 through +16, and F at +17 or worse. Manual reset is explicitly behavior-preserving: it adds no separate penalty, but it never refunds an accepted shot or elapsed time.
