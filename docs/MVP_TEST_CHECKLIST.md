# MVP Test Checklist

Use this checklist after each gameplay or stability change. Start from a fresh run unless a test says otherwise.

## Startup

- [ ] Game launches into the main menu without errors.
- [ ] The title screen contains the large integrated wordmark and exactly the primary PLAY, TUTORIAL, SETTINGS, and QUIT actions without explanatory paragraphs.
- [ ] The generated-course attract loop and cursor parallax remain subdued, loop cleanly, and do not change run/save/settings state.
- [ ] SETTINGS tabs expose only functional Video, Audio, Controls, and Gameplay / Accessibility options; changes apply, persist across relaunch, and Reset Controls restores defaults.
- [ ] A valid entered seed begins a run with that seed; invalid input stays on the menu with clear feedback; COPY SEED copies the visible run seed and confirms success.
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
- [ ] Hole Results shows the correct named golf result, one-to-five-star banner, strokes, par, time, and reward without internal/debug status text.
- [ ] Representative exceptional, solid, weak, and forced results match deterministic `HoleRating` boundaries; fast time never upgrades a poor stroke result to five stars.
- [ ] Expanding the hole selector shows a smooth five-row mechanical reel; mouse wheel and keyboard navigation can select only completed/current holes.
- [ ] Selecting history updates the six-stat snapshot and independently animates the biome/hole identity without replaying or mutating run state; every future hole remains visibly LOCKED and leaks no statline.

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
- [ ] Benefit and curse are the largest lower information bands, stack state has its own blue icon-led band, and the larger gold price remains readable at all target resolutions.
- [ ] Cards that cost more than current coins are disabled.
- [ ] Buying an affordable card subtracts the correct coin cost.
- [ ] Bought card appears in the HUD card summary.
- [ ] Card bonus effects apply to subsequent shots, terrain, rewards, or hazards as disclosed.
- [ ] Card curses apply to the next biome's 3 holes, display remaining duration, and expire after Hole 3 without removing the bonus.
- [ ] Duplicate cards stack deterministically and stay inside the documented safety bounds.
- [ ] Zero, one, or two affordable cards can be bought; a third purchase is blocked.
- [ ] Shop footer reads `PICK UP TO TWO`, then `PICK UP TO ONE` plus red singular `CURSE SELECTED`, then `PICK UP TO ZERO` plus red plural `CURSES SELECTED`.
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

## Course Containment And Moving Hazards

- [ ] Maximum-power shots into straight and corner boundaries do not tunnel through the course with shape-cast CCD active.
- [ ] If the ball does leave all playable surfaces, an `OUT OF BOUNDS` 3–2–1 warning pulses and returns it to the last accepted shot origin without a stroke refund, extra stroke, duplicate penalty, or stale hazard state.
- [ ] Re-entering playable terrain during the countdown cancels the return cleanly.
- [ ] Falling ice begins with only its circular landing shadow and no visible block or active wall collision.
- [ ] Crossing the shadow triggers one fair drop; the landed ice becomes and remains a physical blocker until rebuild, with no duplicate blocks.
- [ ] A direct ice landing crush produces failure feedback and exactly one authoritative reset.
- [ ] The pendulum visibly traverses both sides of its arc on a deterministic period; contact resets the ball exactly once, pause freezes it, and resume continues coherently.

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
- [ ] Copying and replaying a seed reproduces all 18 selected candidate definitions for the same version/configuration.
- [ ] Start and cup positions are playable and reachable on every generated hole.
- [ ] Generated hazards remain contained and a failed generation uses a playable authored fallback.
- [ ] Every accepted generated hole clears the deterministic quality floor for route continuity, width, endpoint safety, separation, recovery room, rhythm, and composition; failed seeds are logged for exact replay.
- [ ] No playable cell/elevation footprint contains more than one static hazard, blocker, or moving-hazard region; the main route and tee/cup recovery cells remain reserved.
- [ ] The large deterministic seed corpus has no disconnected/repeated main-route cell, sealed route, pathological one-cell corridor, or accepted impossible candidate.
- [ ] Secondary branches/shortcuts/dead ends occur routinely while the validated main route remains reachable and ordinary dead ends remain escapable.
- [ ] Later holes include readable ramps, pits, bridges, and overpass crossings; objects on different elevations do not collide.
- [ ] Lower/current/upper visual states update when the ball changes elevation: the current layer stays foreground while non-current layers darken/desaturate; normal bridges and raised paths are generally two-to-four cells wide.
- [ ] Meadow uses water/basic blockers/pendulum hazards; Snow demonstrates ice/falling ice; Volcanic demonstrates lava/rotating fire rods; later biomes increase hazard variety without impossible geometry.
- [ ] Circular bounce pads redirect deterministically for the recorded seed, retain bounded speed, and do not immediately retrigger.
- [ ] Ball begins visibly on a tee and cleanly leaves it after the first accepted shot.
- [ ] Ball cannot escape playable course bounds during normal play.

## Biome World Presentation

- [ ] Meadow includes subordinate lakes, lily flowers, frogs, bushes, trees, flowers, grass detail, and varied natural motion.
- [ ] Desert includes dunes, rocks, cacti with occasional pink flowers, tumbleweeds, and wind/sand motion.
- [ ] Autumn includes warm varied trees, fallen and drifting leaves, and rare apples.
- [ ] Snow includes snowfall, ice formations, snowbanks, penguins, and cool environmental detail.
- [ ] Swamp includes reeds, water, fog, bubbles, plants, and layered wet-organic detail.
- [ ] Volcanic includes cracks, pools, rock mounds, embers, smoke/heat detail, and particles that fade out before invisible recycle instead of teleporting visibly.
- [ ] Each biome's putting region uses the same local tile language at a darker value; the cup/flag brings no standalone grass, sand, or land patch.
- [ ] Course surround and ambience cover 1920×1080, 2560×1440, and the tested ultrawide frame during ordinary camera movement with no grey/clear-color edge.

## Game Feel And Audio

- [ ] Low-, medium-, and high-power shots show a readable strike pop and restrained camera impulse without moving the true ball position.
- [ ] A moving ball leaves a short bounded trail and emits one restrained yellow confetti burst when it becomes fully still.
- [ ] Sand, water/lava, ice, direction zones, bounce pads, blockers, and moving hazards trigger distinct readable reactions; visual rough never changes physics.
- [ ] Meaningful wall impacts produce clamped camera shake and physical wall audio; gentle scrapes produce tiny or no response.
- [ ] Title, tutorial, and all six biome themes are compositionally recognizable, crossfade cleanly, and never stack; biome ambience remains secondary.
- [ ] All eight music loops remain pleasant across a full run on speakers and headphones, have no irritating high-frequency fatigue or abrupt seam, and are not simple pitch/tempo variants.
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
