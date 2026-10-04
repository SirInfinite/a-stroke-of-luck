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
- PLAY opens Run Setup, where the player chooses Easy, Normal, or Hard and may enter, paste, randomize, or leave blank a positive-integer seed. Blank generates a fresh seed; the same seed, difficulty, and game version reproduce the same corresponding 18-hole run.

## Shot and Player Abilities

- The ball uses flat 2D physics with no spin or vertical ballistics. A small discrete elevation state (`-1`, `0`, `1`) separates lower course areas, ground routes, and raised routes; explicit ramps transition between levels.
- Mouse: click/drag from the stopped ball to set direction and power; release to shoot.
- Keyboard: left/right adjust direction, up/down adjust power, and the configured Shoot action fires; Space is the default and Enter remains a fallback.
- An aim indicator, power display, and straight-line resting-position forecast are standard. Pullback and meter share the same power palette. The terminal tip uses launch modifiers, discrete damping and known sand/ice at the current elevation, assuming uninterrupted straight travel. The player guide deliberately does not predict ricochets: walls, reset hazards, moving obstacles, ramps, wind and pads interrupt that line. Effects do not enable or disable the preview. AI decision-making retains its internal collision-aware forecasts, never displayed as candidate paths.
- The player may shoot only while the ball is stopped, not sinking/resetting, and outside Course Overview.
- Ordinary play uses a ball-centered camera at one fixed gameplay zoom across all holes. It follows movement on every elevation without cup bias or velocity-based zoom. Course Overview toggles with Tab by default or the HUD overview control; it smoothly fits the actual playable course, including all layers, tee/cup, walls and hazards, inside HUD-safe margins. It cancels aiming without firing and blocks new player shots without pausing simulation or the timer. Toggle again to return to the ball's current position. Hole resolution, manual hole reset, next hole and new run clear overview; a pause/resume preserves it. Impact shake is suppressed in overview.
- The configured Reset action (`R` by default) returns the ball to the start without erasing accepted strokes, elapsed hole time, rewards, or cumulative run statistics. At par + 4 it resolves the forced hole outcome instead of resetting play.
- Player settings persist between launches. Only options connected to working systems are exposed: window mode, supported resolution, VSync, screen shake, visual-effects intensity, Master/Music/SFX levels and mutes, Shoot/Reset/Course Overview bindings, aim sensitivity, trajectory visibility, reduced motion, and UI appearance (Dark by default, or Light). Appearance never recolors the course. Controls reject conflicting overview bindings; older saves that already use Tab for Shoot/Reset receive an available overview key. Tab retains focus navigation in menus. Reduced Motion removes camera follow lag and cup flourish and shortens the functional overview transition.

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
| Bounce pad | Redirects the ball in a seeded random outgoing direction with the existing strong minimum launch speed, bounded multiplier and maximum speed. |
| Blocker / moving hazard | Collides predictably at its occupied elevation and never permanently blocks the validated main route. |

Entering the cup completes the hole. Hazard effects must end on exit, reset, or level transition. A playable cell/elevation surface may contain at most one static hazard, blocker, or moving-hazard footprint; incompatible hazards and multiple moving anchors never overlap.

Falling ice begins as a square, full-tile ground shadow only. Entering the marked region triggers one fair drop; the landed art and collision occupy exactly one 100×100 course tile and remain a blocker until reset/rebuild. A direct landing crush uses exactly one normal authoritative hazard reset/penalty, with no refund or duplicate block. Pendulum art and damaging collision traverse the same deterministic visible arc continuously, pause with gameplay, and use the same reset boundary when they hit the ball.

Shape-cast CCD plus a bounded static-wall sweep contain legitimate boosted shots without lowering power. If the ball nevertheless remains outside playable terrain, a visible three-second countdown returns it to the last accepted shot origin and refunds exactly that attempted shot once. Both current-hole and total strokes decrease together; prior shots and water/lava/crush penalties remain charged. Returning to playable terrain cancels the countdown without a refund. No new shot is accepted outside the course. OOB recovery resolves before the stroke ceiling, so a refunded final shot may be retried.

Static wall reflection preserves the incident angle about the surface normal and applies restitution to the complete outgoing velocity. Wall friction must not independently flatten the tangential component. Corners retain bounded collision iterations and separation; moving hazards retain their existing native contact behavior.

## Tutorial

Six deterministic lessons introduce aim/power, sand, water, obstacles, cards and continuation. Sand and water use the real Meadow surface palette and a one-tile-deep transverse band, requiring contact once. After the first normal water reset, most of that band opens into a bypass; the remaining water still has normal reset/penalty behavior. A fresh tutorial restores the teaching band.

Initially only course identity and aiming controls are shown. The first accepted shot introduces strokes/time, the shop lesson introduces coins, and opening that shop introduces benefits/curses. The seed and unrelated run information stay hidden. Completion and Skip return to the main menu; starting a real run remains an explicit player choice.

## Scoring, Time, and Loss

- Every accepted shot counts immediately as one stroke, exactly once. Hazard penalties add strokes.
- Par is authored per hole. Demo holes should normally be par 3 or 4.
- Relative score is strokes minus par: birdie or better is under par, par is even, bogey is +1, and double bogey is +2.
- A hole ends automatically at par + 4 strokes and advances with that recorded score.
- The HUD shows `2 SHOTS LEFT` and then `FINAL SHOT` using the authoritative remaining count. A successful OOB refund restores the corresponding warning; ordinary hazard/manual resets do not grant free shots.
- The run timer advances during hole play and pauses during results and shops.
- Hole Results awards a deterministic one-to-five-star performance rating. Stroke efficiency relative to par is primary; completion time may refine the result inside bounded limits but can never turn a poor stroke result into an exceptional rating. The expected time window is `22 + par × 14` seconds: eagle-or-better starts at five stars, birdie/par at four, bogey at three, double bogey at two, and worse or forced completion at one, with documented time caps/bonuses applied by `HoleRating`.
- Hole Results names Albatross, Eagle, Birdie, Par, Bogey, Double Bogey, Triple Bogey+, or Stroke Limit as applicable and shows stars, strokes, par, time, and reward.
- Completed-hole statlines are recorded for the current run. The HUD/result history selector may display completed holes and the current hole, including their biome and six recorded stats; future holes remain inaccessible and reveal no data. Selecting history never replays or mutates a hole.
- Completing the final hole is the run win state. Reaching a hole’s stroke ceiling is a hole-level loss/forced advance, not a failed run.

## Economy and Shop

- Start each run with 2 coins.
- Award coins after a hole: birdie or better 3; par 2; bogey 1; double bogey or worse 0.
- Easy offers 4 seeded-randomized items and permits 0–2 purchases. Normal offers 5 and permits 0–3. Hard offers 6 and permits 0–5. Offers do not carry forward.
- Each card shows name, cost, benefit, and penalty before purchase. Unaffordable offers remain readable but disabled.
- Release bonuses persist for the run. Common/Rare curses last three resolved holes, Epic four, Legendary five; completing or forcing a hole advances duration once, while manual/OOB/hazard resets do not consume a duration step. Longer curses may cross a biome boundary and are disclosed before purchase.
- Card data stores one base curse value. Easy applies it at `1.0×`, Normal at `1.25×`, and Hard at `1.6×`; displayed curse copy reports the scaled value. Stacked and scaled effects remain deterministic, visible, and centrally clamped so a run remains completable.

## Upgrade Pool

The original 15-item pool remains in `DESIGN_DOCS.md`, Section 3.3. Release mode uses the smallest eight-card functional pool supported by the central effect resolver; expansion to the full original pool is deferred. The table below lists Common cards and Easy/base curse values before rarity/difficulty scaling.

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

### Rarity: a stronger, more dangerous deal

`CardRarityProfile` owns numeric scaling, category-specific progression, price rounding, duration, offer weight and visual identity. Base identities still stack together; each offered card owns independent effect data.

| Tier | Numeric benefit | Numeric curse | Price (ceil of base ×) | Duration | Easy / Normal / Hard weight |
|---|---:|---:|---:|---:|---|
| Common | 1× | 1× | 1× | 3 holes | 78 / 70 / 62% |
| Rare | 1.5× | 1.35× | 1.75× | 3 holes | 18 / 23 / 27% |
| Epic | 2.25× | 1.8× | 2.75× | 4 holes | 3.5 / 6 / 9% |
| Legendary | 3.25× | 2.5× | 4.5× | 5 holes | 0.5 / 1 / 2% |

Relief effects approach the existing 75% mitigation ceiling instead of multiplying to immunity; integer rewards round upward; extra-guard curses advance by whole placements (1–4). Existing global safety clamps still apply. Difficulty multiplies the rarity-scaled curse independently. The tutorial retains its explicit Common pool. Production rarity uses a separate deterministic shop RNG stream, preserving base-card selection order.

Double Down must duplicate both sides of one selected item. Curse Breaker removes one active obstacle but skips the shop after the next hole. Effects that alter future layout or shops must be resolved before the affected hole/shop is built.

## Level Structure and Difficulty

- A hole has one tee, one reachable cup, authored par, a validated main route, playable terrain, boundaries, and zero or more hazards/obstacles.
- All six biomes share one deterministic, authored-motif route grammar. Difficulty grows through angles, useful banks, optional branches, route guards, timing and deliberate approaches—not hazard spam, extreme corridor narrowing or unpredictable shot physics.
- Water/lava resets, sand, ice, direction zones, blockers, bounce pads, pendulums, falling ice, and rotating fire rods use shared contracts with biome-weighted profiles.
- Circular bounce pads choose their outgoing direction from the recorded seed, guarantee a strong minimum exit speed, multiply ordinary incoming speed, clamp extreme exits to a safe maximum, and separate the ball beyond the pad before their retrigger cooldown begins.
- Difficulty should come from readable geometry, accumulated tradeoffs, and route decisions—not hidden physics changes.
- One resolved generation challenge profile combines difficulty, overall run progress, the local introduce/develop/climax arc and active generation curses. Easy favors smaller shoulder guards, wider recovery and sparse movers/elevation; Normal combines moderate route guards and optional routes; Hard adds staggered blockers, larger guards, more timing sections and riskier alternatives. Late holes raise these budgets and combinations without reducing tee/cup safety. Every placement preserves a clear primary route and recoverable free surfaces. Corpus distributions, not rigid per-hole count ordering, must demonstrate both difficulty and run progression.
- Most holes have one primary route. Some add an alternate, guarded shortcut or overshoot/bait dead end with a clear exit and turnaround pocket. Optional routes must not silently replace the primary corridor during validation.
- Ordinary water, sand, and lava use compact connected one-to-five-cell formations. Small formations are common, four-cell formations are occasional, and five-cell formations are rare; disconnected checkerboards and overlapping blobs are invalid.
- Hazards and obstacles favor the tee-to-cup shot corridor, route corners, and cells immediately beside the intended route. They may guard the obvious line, divide a lane, or tighten a decision point while preserving endpoint safety, a valid route, and recovery room.
- Most holes are flat. A minority contain one structural elevation idea: a three-cell-wide raised or recessed alternative, with a rare two-cell pinch for a short crossing. A hole may contain at most one crossing; its tunnel covers one or two cells. Lower terrain retains normal biome surfaces. Generated parallel ramps span their full cells; authored ramps retain their existing width unless explicitly specified.

## Procedural Generation

Procedural generation is the production course source. A run records one seed and deterministically produces all 18 holes through the shared generator. Generation must:

- produce a connected playable route from start to cup;
- keep start, cup, and hazards on valid terrain;
- assign reachable par based on tested routes, not distance alone;
- preserve enough clear landing space for the ball and cup;
- validate discrete surfaces, ramps, bridges, lower areas, sparse overpasses, and cross-elevation collision occupancy;
- preserve a connected main route while allowing bounded branches and dead ends;
- introduce compact hazards according to the run’s difficulty and active penalties, with placements scored for route relevance and useful shot interaction;
- reserve each placement footprint so hazards, blockers, moving regions, the primary route, and tee/cup recovery cells cannot conflict;
- score route continuity, navigable width, endpoint safety, exclusive occupancy, recovery room, turn rhythm, visual composition, and route interaction;
- validate every result and fall back to an authored hole on failure;
- use a recordable seed for reproduction and playtesting.

### Authored grammar and shot rhythm

Grammar revision 3 chooses a course idea before placing hazards: guarded lane, bank corner, dogleg, S-curve or switchback. These are stretched/rotated/reflected route skeletons, not completed holes. Independent terrain, blocker, timing, branch, elevation and approach motifs compose the actual challenge. The vocabulary contains 26 motifs, listed in `PROCGEN_OVERHAUL_REVIEW.md`.

The design route joins tee, intermediate landing zones and cup. Cardinal shot sections supply meaningful placement slots; the tee, cup and turning/recovery centers reserve clear 3×3 regions. Easy carves five-cell-wide lanes, while Normal and Hard retain three-cell-wide lanes. Snow and Easy carve larger recovery terrain. Terrain templates form connected singles, pairs, elbows, short lines and irregular groups of up to five cells. Separate formations keep a gap. Blockers guard the center or alternating shoulders; moving hazards reserve their entire swept region, not just the anchor. The safe route is then found within the original primary corridor while excluding every occupied cell. All unoccupied surfaces must remain recoverable, including optional branches and elevation states.

Bounce placement searches a bounded set of seeds for an initial launch into the onward lane, with a clear two-cell runway. It does not change the pad's existing seeded-random physics: subsequent launches can differ and still require human speed/angle testing. The immediate tee and cup regions remain clear; difficulty belongs to their opening and approach sections.

### Biomes and three-hole arcs

| Biome | Structural emphasis |
|---|---|
| Meadow | Clear lanes and banks, water guards, no elevation, pendulum introduced at the climax. |
| Desert | Longer stretches, sand formations and water decisions, stronger bounce-bank opportunities. |
| Autumn | Doglegs, S-curves and switchbacks, pendulum/blocker combinations, optional recessed routes. |
| Snow | Ice runouts, wider landing terrain, falling-ice gates and occasional elevated alternatives. |
| Swamp | Bending wet lanes, more optional wet shortcuts, recessed alternatives. |
| Volcanic | Lava guards, rotating gates, more elevation/shortcuts; strongest late Hard timing pressure. |

Each biome introduces its concept, develops it with another obstacle section, then reaches a climax with a larger challenge budget. Easy reduces branching/elevation odds and favors moving hazards toward the third hole, with smaller chances earlier where the biome allows them. Normal uses the standard three-cell corridor and moderate combinations. Hard adds guarded sections and more optional routes without further narrowing the corridor; late Swamp/Volcanic develop and climax holes may use two moving gates.

Generation-affecting curses rerun the same selected course idea with deterministic effect-specific candidate variation. They add disclosed direction zones, grow connected terrain guards, or introduce lane/corner blockers, subject to the same safety and quality gates. The current card pool still adds direction zones only; water/blocker modes are supported generation contracts and developer test cases, not new purchasable cards. Requests are bounded to four placements and cannot silently shortfall on accepted grammar layouts.

### Candidate selection and replay

For each seed/biome/hole/difficulty/grammar-revision/effect-state combination, the generator evaluates eight deterministic candidates and selects the first highest-scoring valid candidate at or above 72/100. Candidate variation cannot replace the chosen course idea solely to accumulate more scoring points. Invalid-candidate, below-floor and fallback counts are separate diagnostics.

Score maxima are route clarity 10, shot interaction 20, estimated shot rhythm 15, direct-line pressure 15, clear recovery 15, challenge fit 10, bank/choice geometry 8 and composition 7. Penalties cover density, excess moving/elevation complexity, unguarded shortcuts and empty challenge sets. Direct-line sampling considers missing terrain as well as occupied surfaces. Shot estimates are bounded line-of-sight approximations, not golf simulation or proof of fun.

If no candidate clears validation and quality, a validated authored fallback receives the active biome, difficulty and effects. Fallbacks are reported rather than disguised as quality passes. Replay uses local RNGs only; the same revision, seed, difficulty and generation effects reproduce the same candidate scores and selected hole. Layouts from before this grammar revision are intentionally different. Seed parsing, saves, scoring, economy, audio, ball physics and the card pool are unchanged by this overhaul.

## VS AI: one course, two private golfers

PLAY offers Solo or VS AI. VS selects a text-only named opponent before the existing course difficulty/seed setup. Arnold Palmer (Beginner), Phil Mickelson (Intermediate), Rory McIlroy (Advanced), Tiger Woods (Expert), and Jack Nicklaus (Legend) are fictional game AI identities, not likenesses or endorsements. Course difficulty and opponent ability are separate choices.

Each hole runs Player → AI → comparison. Both play the **same generated, validated physical course instance**. The AI turn resets transient hazards, pad counters, ramps, tee and ball state; it never regenerates geometry, hazard placement, elevation, cup size, or the seed-derived starting hazard configuration. Shots use GolfBall's normal accepted-shot interface, collision, terrain, resets, OOB refund and par + 4 resolution. No AI-only movement or outcome substitution is permitted.

In VS only, both builds' course-affecting effects become shared **MATCH-COURSE** modifiers before that hole is generated. Persistent course bonuses and unexpired course curses from both owners add together, with each owner's existing difficulty curse multiplier, then the existing release clamps apply once: 0–4 extra hazards and 55–150% cup scale. Contributions have a stable sorted summation order. Current placement cards all add direction zones; the existing single preferred-hazard contract resolves mixed types by largest summed contribution, then lexical tie-break. Any future geometry/shared-physics effect must be explicitly classified and implemented at this boundary, never applied privately after construction. Personal power, control, rolling/terrain response, rewards, wallets and purchases remain private. Solo still uses its original owner-only resolver and generation path.

Curse lifetime advances once per owner's completed hole. The shared course stays frozen even if a curse expires after the player's turn; the next hole resolves both updated builds afresh. Cards label this exception **COURSE CURSE • BOTH**, retain their duration, and explain it in tooltips; the active-course HUD includes either owner's contribution.

Both golfers see the exact same deterministic shop offers, including rarity and price, and independently spend their own earned coins under the same purchase limit. AI choices occur when the shop opens, without observing subsequent player choices. Its heuristic considers private benefit/cost, stacking and the marginal *shared* course consequence after clamps. A short reveal follows player shopping.

Opponent ability comes from bounded candidate search, legal power choices, route-aware landing evaluation, limited next-shot probes, observable moving-hazard timing and seeded execution error. Stronger golfers test a small execution-error envelope; control cards affect only their owner's power precision. Predictions are approximations, not guaranteed outcomes or knowledge of unobservable randomness. Spectators see only the chosen aim, with 1×/2×/4× controls. Skip plays out the real turn at accelerated simulation speed; it does not invent a score.

Beginner is deliberately very forgiving to play against; Intermediate remains beatable by a new player. Both use coarse approach-power choices, larger bounded aim/power errors and no next-shot probes. Advanced provides the middle challenge, Expert plays reliably and Legend remains strongest. Their preparation eases only the aim/pullback toward the selected shot over roughly 0.6–0.74 seconds; the resting ball never moves before a legal shot. This presentation consumes existing thinking time, preserving hazard timing and spectator-speed rules.

Per-hole and final comparison use strokes first, then completion time rounded to displayed tenths. Results include score versus par, holes won/tied, time and both builds. Rematch repeats seed/opponent/course difficulty; New Opponent and Main Menu cleanly reset the match. AI behavior is replayable within the same game/engine version, starting configuration and card choices. Human evaluation of opponent strength, pacing and difficult-course competence remains required.

## Hazard gameplay benchmark checkpoint (2026-09-10)

The owner has authorized a development-only checkpoint of three bank/swing, three force/split/pocket, and three loop/elevation variants. The desired direction is risky, timing-heavy execution with recoverable consequences and much stronger eventual hazard placement. The playable catalog and measured limitations are in [HAZARD_CHECKPOINT.md](HAZARD_CHECKPOINT.md). The existing inspector opens it with `--benchmarks`; Main's normal physics and accounting apply. F9 is an explicitly fresh practice attempt; R preserves its ordinary stroke/time behavior.

This checkpoint does not adopt new biome identities, alter rewards, increase ice frequency, or replace production generation. Owner feel approval and selection of the proposed biome mechanics are required before rollout. The normal eighteen-hole/six-biome rules remain in force. Approximate two-thirds execution emphasis is a design target, not a reward formula.

### Gameplay direction correction sample (2026-09-11)

Version 2 refines those same nine fixtures into Pendulum Bank, Force-fed Fork and Crossing Loop. Each Normal fixture now has six independent mechanisms/formations, purposeful rebound surfaces, guarded landings and clear recovery space. Easy uses smaller/slower swinging masses; Hard adds an exposed guard and shorter periods. The three family variants change geometry and decisions, not just orientation. Sample tuning and the measured limitations are in [GAMEPLAY_DIRECTION_REVIEW.md](GAMEPLAY_DIRECTION_REVIEW.md).

The isolated sample preserves par and the normal stroke ceiling, normal intentional hazard penalties, the automatic OOB refund exception, straight aiming aid, shops and card/curse semantics. No hidden response to aim or power, post-shot retiming, new scoring formula or random-direction mechanic is introduced. Underpasses stay short, clear and layer-separated. Ice is investigated with isolated diagnostics only; no biome receives wider ice adoption. New biome mechanics and generator-wide density/pacing changes remain proposals pending owner approval.

## Results Tuning

The release run grade uses total score relative to the 18-hole par: A at -6 or better, B from -5 through even, C from +1 through +8, D from +9 through +16, and F at +17 or worse. Manual reset is explicitly behavior-preserving: it adds no separate penalty, but it never refunds an accepted shot or elapsed time.
