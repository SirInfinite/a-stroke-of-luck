# MVP Test Checklist

Use this checklist after each gameplay or stability change. Start from a fresh run unless a test says otherwise.

## Startup

- [ ] Game launches into the main menu without errors.
- [ ] Play opens Run Intro (`RUN_START`), then the Meadow biome intro, then Hole 1.
- [ ] Ball, hole, flag, course bounds, HUD, and power meter are visible.
- [ ] Player HUD clearly prioritizes biome, overall hole, strokes/par, timer, coins, active bonuses, and a distinct `ACTIVE CURSES / PENALTIES` band; debug-only values remain hidden until toggled.
- [ ] Timer counts up while playing a hole.

## Mouse Aim And Shot

- [ ] Clicking directly on or near the ball selects it only when stopped.
- [ ] Dragging away from the ball shows the aim line, trajectory dots, aim angle, and power meter.
- [ ] Longer drags increase power up to the cap.
- [ ] Very low power produces a genuinely short preview; medium and high power increase predicted distance proportionally with readable adaptive dot spacing.
- [ ] Releasing the left mouse button shoots the ball in the expected direction.
- [ ] Aim line and trajectory preview disappear after release.
- [ ] Stroke count increases by 1 exactly when the shot is accepted, never again when it stops.
- [ ] Total stroke count increases with each accepted shot.
- [ ] Ball cannot be shot again while moving.

## Keyboard Aim

- [ ] Left/right arrow keys rotate keyboard aim when the ball is stopped.
- [ ] Up/down arrow keys adjust keyboard shot power.
- [ ] Keyboard aim shows trajectory dots, aim angle, and power meter.
- [ ] Space shoots with the current keyboard aim.
- [ ] Enter also shoots with the current keyboard aim.
- [ ] Keyboard aim is disabled when mouse-selecting the ball.
- [ ] Keyboard aim does not shoot while the ball is moving or sunk.

## Hole Progression And Sinking

- [ ] Ball sinks when it enters the hole.
- [ ] Ball visually moves into the hole and scales down.
- [ ] Ball collision/input stops during the sink animation.
- [ ] Hole Results opens after the sink animation finishes.
- [ ] Continuing loads the next hole after local holes 1–2.
- [ ] Continuing opens the shop after local Hole 3 in biomes 1–5.
- [ ] Continuing from a biome shop opens the next biome intro, then its first hole.
- [ ] Strokes reset to 0 on the next hole.
- [ ] Total strokes carry forward across holes.
- [ ] Timer resets on the next hole.
- [ ] After Volcanic Hole 3 / overall Hole 18, continuing reaches Run Results, then Ending.
- [ ] New Run clears run state and returns to Run Start with a fresh seed.

## Coin Rewards

- [ ] Starting coins are 2.
- [ ] Finishing under par awards 3 coins plus any reward bonus.
- [ ] Finishing at par awards 2 coins plus any reward bonus.
- [ ] Finishing one over par awards 1 coin plus any reward bonus.
- [ ] Finishing two or more over par awards 0 coins plus any reward bonus.
- [ ] Coin total updates before or when the shop appears.
- [ ] Coin total persists across holes.

## Shop Cards And Economy

- [ ] Shops appear after biomes 1–5 and never after Volcanic / biome 6.
- [ ] Shop shows 4 unique seeded-random card buttons and a Skip / Continue button.
- [ ] Each card shows name, cost, persistent bonus, three-hole curse, and stacking behavior.
- [ ] Cards that cost more than current coins are disabled.
- [ ] Buying an affordable card subtracts the correct coin cost.
- [ ] Bought card appears in the HUD card summary.
- [ ] Card bonus effects apply to subsequent shots, terrain, rewards, or hazards as disclosed.
- [ ] Card curses apply to the next biome's 3 holes, display remaining duration, and expire after Hole 3 without removing the bonus.
- [ ] Duplicate cards stack deterministically and stay inside the documented safety bounds.
- [ ] Zero, one, or two affordable cards can be bought; a third purchase is blocked.
- [ ] Skip / Continue works with no purchase and advances to the next biome intro.
- [ ] Starting coins, score rewards, purchases, and final coins reconcile.
- [ ] Shop animation finishes in a usable position.

## Sand

- [ ] Entering sand slows the ball immediately.
- [ ] Ball damping is higher while inside sand.
- [ ] Leaving sand restores normal ball damping.
- [ ] Sand effects do not remain after resetting the hole.
- [ ] Sand effects do not remain after loading the next hole.
- [ ] Sand Cleats card reduces sand slowdown as described.

## Water

- [ ] Entering water starts the hazard sink animation.
- [ ] Ball cannot be controlled during the water sink animation.
- [ ] Ball resets to the current hole start after water sink finishes.
- [ ] Accepted strokes remain recorded after water; the water penalty adds exactly one additional stroke.
- [ ] Direction-pad and sand effects are cleared after water reset.
- [ ] Re-entering water repeatedly does not duplicate reset behavior or crash.

## Direction Pads

- [ ] Entering a direction pad pushes the ball in the arrow direction.
- [ ] Leaving a direction pad stops applying that push.
- [ ] Direction pad push is cleared by water reset.
- [ ] Direction pad push is cleared by manual reset.
- [ ] Direction pad push is cleared when loading the next hole.
- [ ] Sand Cleats card increases direction pad push as described.

## Reset Key

- [ ] Pressing `R` resets the ball to the current hole start.
- [ ] Pressing `R` preserves current-hole strokes and elapsed hole time.
- [ ] Pressing `R` preserves total strokes, reward accounting, and cumulative run statistics.
- [ ] Pressing `R` does not reset coins or owned cards.
- [ ] Pressing `R` clears sand/direction effects, resets moving hazards, and returns without placing the ball back on the tee.
- [ ] Pressing `R` while the ball is moving leaves the game in a playable state.
- [ ] Pressing `R` during sink, water reset, or shop does not corrupt progression.
- [ ] Pressing `R` at par + 4 resolves the forced failure result and cannot refund the final accepted shot.

## Menu Pause

- [ ] Opening Menu during a moving shot freezes ball velocity, collision, hazard timers, hole time, and gameplay state behind the overlay.
- [ ] Pause overlay leaves the active biome music in place and stops any invalid high-speed swoosh.
- [ ] Resume restores the same in-progress shot and moving-hazard cycle coherently without a duplicate stroke or stuck camera/audio state.

## Debug HUD

- [ ] Debug HUD is hidden by default.
- [ ] Pressing the configured debug toggle key shows the debug HUD without duplicating the player HUD.
- [ ] Pressing the debug toggle key again hides it.
- [ ] Power meter remains usable when the debug HUD is hidden.
- [ ] HUD values update correctly after shots, resets, card purchases, and level changes.

## Eighteen-Hole Generated Course Loop

- [ ] Meadow holes 1–3 use the Meadow presentation and rise from introductory to hardest.
- [ ] Desert holes 4–6 use the Desert presentation and rise from introductory to hardest.
- [ ] Autumn holes 7–9 use the Autumn presentation and rise from introductory to hardest.
- [ ] Snow holes 10–12 use the Snow presentation and rise from introductory to hardest.
- [ ] Swamp holes 13–15 use the Swamp presentation and rise from introductory to hardest.
- [ ] Volcanic holes 16–18 use the Volcanic presentation and rise from introductory to hardest.
- [ ] All holes use the shared generator and show the recorded run seed.
- [ ] Start and cup positions are playable and reachable on every generated hole.
- [ ] Generated hazards remain contained and a failed generation uses a playable authored fallback.
- [ ] Secondary branches/shortcuts/dead ends occur routinely while the validated main route remains reachable and ordinary dead ends remain escapable.
- [ ] Later holes include readable ramps, pits, bridges, and overpass crossings; objects on different elevations do not collide.
- [ ] Meadow uses water/basic blockers/pendulum hazards; Snow demonstrates ice/falling ice; Volcanic demonstrates lava/rotating fire rods; later biomes increase hazard variety without impossible geometry.
- [ ] Circular bounce pads redirect deterministically for the recorded seed, retain bounded speed, and do not immediately retrigger.
- [ ] Ball begins visibly on a tee and cleanly leaves it after the first accepted shot.
- [ ] Ball cannot escape playable course bounds during normal play.

## Game Feel And Audio

- [ ] Low-, medium-, and high-power shots show a readable strike pop and restrained camera impulse without moving the true ball position.
- [ ] A moving ball leaves a short bounded trail and emits one restrained yellow confetti burst when it becomes fully still.
- [ ] Sand, water/lava, ice, direction zones, bounce pads, blockers, and moving hazards trigger distinct readable reactions; visual rough never changes physics.
- [ ] Meaningful wall impacts produce clamped camera shake and physical wall audio; gentle scrapes produce tiny or no response.
- [ ] Menu plus all six biome themes are recognizable, crossfade cleanly, and never stack; biome ambience remains secondary.
- [ ] Strike, high-speed-only swoosh, sand, water, lava, ice, wall, cup, UI, purchase, boost, failure, biome, and final-completion cues are audible, balanced, and routed without clipping.
- [ ] Normal/slow ball movement has no continuous rolling sound; all three supplied boost sounds map to strength; both supplied failure sounds play together at par + 4 without the positive completion cue.
- [ ] Cup entry plays a sink cue, brief camera emphasis, readable completion effect, and short pause before Hole Results.
- [ ] Shop cards respond on hover; purchase pulses the card and coins and briefly warns that a curse was accepted.
- [ ] Each biome intro has a restrained palette-colored transition; Hole 18, Run Results, and Ending have distinct final feedback without obscuring text.
- [ ] Repeated shots, rapid resets, skipped shops, and new runs leave no stuck trail, camera offset, audio loop, flash, or scaled UI control.

## Regression Notes

- [ ] No console errors or warnings appear during normal play.
- [ ] No duplicate stroke events occur from one shot.
- [ ] No stale aim line or trajectory preview remains after reset, sink, or level load.
- [ ] No hazard effect persists into a later hole.
- [ ] No shop interaction leaves buttons disabled incorrectly.
- [ ] No level transition happens twice from one hole sink.
- [ ] Par + 4 opens Hole Results and cannot softlock the run.
- [ ] Restarting during sink, hazard reset, results, shop, or ending does not leak stale state into the new run.

## Tutorial

- [ ] Fresh tutorial teaches aim, power, standard trajectory, normal grass/green, sand, water reset, blocker/moving hazard, shop, card benefit, active curse, and continuation in that order.
- [ ] Only the shop lesson opens the tutorial shop; it offers the same deterministic four simple cards and blocks Continue until one affordable card is purchased.
- [ ] The final lesson demonstrates both the purchased benefit and disclosed curse without normal-run RNG.
- [ ] Tutorial contains no mechanical rough, red/out penalty, or trajectory-gating card reference.
- [ ] Skip/restart and completed-save paths still enter a clean normal six-biome run.
