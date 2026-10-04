# MVP Test Checklist

Use this checklist after each gameplay or stability change. Start from a fresh run unless a test says otherwise.

## Startup

- [ ] Game launches into the main menu without errors.
- [ ] The title screen contains the large integrated wordmark and exactly the primary PLAY, TUTORIAL, SETTINGS, and QUIT actions without explanatory paragraphs.
- [ ] The generated-course attract loop and cursor parallax remain subdued, loop cleanly, and do not change run/save/settings state.
- [ ] SETTINGS tabs expose only functional Video, Audio, Controls, and Gameplay / Accessibility options; changes apply, persist across relaunch, and Reset Controls restores defaults.
- [ ] PLAY opens Run Setup; Easy/Normal/Hard cards show the correct pick, offer, and curse summaries, and the last difficulty persists.
- [ ] A valid entered or pasted seed begins a run with that seed; blank/randomized seed creates a positive seed; invalid input stays in Run Setup with clear feedback; COPY SEED copies the visible run seed and confirms success.
- [ ] START RUN opens Run Intro (`RUN_START`), then the Meadow biome intro, then Hole 1.
- [ ] Ball, hole, flag, course bounds, HUD, and power meter are visible.
- [ ] Player HUD clearly prioritizes biome, overall hole, strokes/par, timer, coins, active bonuses, and a distinct `ACTIVE CURSES / PENALTIES` band; debug-only values remain hidden until toggled.
- [ ] Timer counts up while playing a hole.

## Ball Camera and Course Overview

Use the development build with mouse and keyboard at 1280×720, 1600×900, 1920×1080, 2560×1440 and, where available, 3440×1440. These are human acceptance checks; rendered automation alone does not mark them complete.

- [ ] At the tee and after low/full-power shots, maximum legal boosts, pad launches and wall rebounds, the ball stays comfortably centered; normal zoom remains consistent, follow never overshoots, and shake settles without residual offset.
- [ ] Tab and the flag-icon OVERVIEW button enter/exit with a short smooth transition. The pressed state and COURSE OVERVIEW readout are clear in Dark and Light. Return follows the current ball, including after moving shots.
- [ ] Small, wide, tall, long, branch-heavy, lower-route, raised/overpass and difficult late-run holes fit completely with padding. Tee, cup/flag, walls and significant hazards remain clear of HUD, tutorial coach and VS watch controls. No engine-clear-color edge appears.
- [ ] Toggle while mouse-dragging and while keyboard-aiming: aim/power previews clear and releasing/confirming never fires. Neither input method starts a new shot in overview. An existing shot, hazard cycle and timer continue; stopping leaves overview active.
- [ ] Rapid toggles, resize, pause/resume, OOB/water recovery, manual reset, hole results, next hole and new run preserve correct input and framing. New tees start in Ball View, and results never retain overview zoom.
- [ ] Rebind Course Overview in Controls, relaunch, and verify the selected key and HUD hint; conflicting keys are rejected and Reset Controls restores Tab. Tab still navigates menus. Reduced Motion and screen-shake settings remain effective.
- [ ] In VS AI, overview continues watching a live opponent without stalling shots; turn handoff starts centered on the new tee and watch-speed changes preserve short camera transitions.

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
- [ ] Easy shows 4 unique offers with up to 2 purchases, Normal shows 5 with up to 3, and Hard shows 6 with up to 5; every layout retains Skip / Continue.
- [ ] Each card shows name, cost, persistent bonus, three-hole curse, and stacking behavior.
- [ ] Benefit and curse are the largest lower information bands, stack state has its own blue icon-led band, and the larger gold price remains readable at all target resolutions.
- [ ] Cards that cost more than current coins are disabled.
- [ ] Buying an affordable card subtracts the correct coin cost.
- [ ] Bought card appears in the HUD card summary.
- [ ] Card bonus effects apply to subsequent shots, terrain, rewards, or hazards as disclosed.
- [ ] Card curses apply to the next biome's 3 holes, display remaining duration, and expire after Hole 3 without removing the bonus.
- [ ] Duplicate cards stack deterministically and stay inside the documented safety bounds.
- [ ] Purchases stop exactly at the active difficulty's 2/3/5 limit without allowing the same offer twice.
- [ ] Shop footer counts the active remaining-pick limit down to zero using the same numeral/word style throughout.
- [ ] Easy shows base curses, Normal shows `1.25×` curse magnitudes, and Hard shows `1.6×`; persistent bonuses are unchanged and clamps prevent broken movement/control/cup values.
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
- [ ] Pressing `R` clears sand/direction effects, resets moving hazards, and restores one visible tee beneath the ball at the original start. Coins, cards and accepted strokes remain unchanged.
- [ ] Pressing `R` while the ball is moving leaves the game in a playable state.
- [ ] Pressing `R` during sink, water reset, or shop does not corrupt progression.
- [ ] Pressing `R` at par + 4 resolves the forced failure result and cannot refund the final accepted shot.

## Course Containment And Moving Hazards

- [ ] Maximum-power shots into straight and corner boundaries do not tunnel through the course with shape-cast CCD active.
- [ ] If the ball leaves all playable surfaces, the `OUT OF BOUNDS` 3–2–1 warning returns it to the last accepted shot origin and refunds exactly that shot once in current/total/history accounting. Prior shots and ordinary hazard penalties remain charged, including near par + 4.
- [ ] Re-entering playable terrain during the countdown cancels the return cleanly.
- [ ] Falling ice begins with only its full-tile square shadow and no visible block or active wall collision; after landing, art and collision fill exactly one tile.
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
- [ ] Every accepted generated hole clears the deterministic quality floor for route continuity, width, endpoint safety, exclusive occupancy, recovery room, rhythm, composition, and route interaction; failed seeds are logged for exact replay.
- [ ] Most hazards/blockers/moving hazards guard the direct line, a route turn, or a route-adjacent lane instead of irrelevant outer terrain; the hole still has readable recovery space.
- [ ] Water, sand, and lava show connected one-to-five-cell cluster variety without checkerboards, overlap, or route closure; large formations remain rare.
- [ ] No playable cell/elevation footprint contains more than one static hazard, blocker, or moving-hazard region; the main route and tee/cup recovery cells remain reserved.
- [ ] The large deterministic seed corpus has no disconnected/repeated main-route cell, sealed route, pathological one-cell corridor, or accepted impossible candidate.
- [ ] Branches are optional, recognizable decisions rather than a feature forced onto every hole; the primary corridor remains playable, shortcuts reconnect, and bait dead ends have room to shoot back.
- [ ] Compare all three holes of every biome on Easy/Normal/Hard: introduction, development and climax should feel distinct without an abrupt or impossible spike.
- [ ] Replay the same seed, difficulty, grammar revision and card choices: candidate selection and modified courses match exactly, including after reset/pause.
- [ ] Try the obvious direct shot and useful wall banks; hazards should change an angle, landing zone or timing choice, with clear recovery afterward.
- [ ] Use the developer inspector and corpus feature seeds to play connected singles/pairs/large guards, moving gates, a bounce bank, a wet shortcut, a recessed route and both levels of a short tunnel.
- [ ] Cross generated three-cell-wide ramp entrances at their center and tile seams in both directions; ascent marks, active-layer contrast and collision transitions agree.
- [ ] Later holes include readable ramps, lower course areas, raised paths, and sparse overpass crossings; objects on different elevations do not collide.
- [ ] Lower terrain uses the current biome's normal surface/hazard language with perimeter depth cues rather than a cave texture; current elevation stays foreground while other layers darken subtly.
- [ ] A hole has at most one overpass, and every lower-path tunnel is one or two tiles long with readable entry/exit sightlines.
- [ ] Meadow uses water/basic blockers/pendulum hazards; Snow demonstrates ice/falling ice; Volcanic demonstrates lava/rotating fire rods; later biomes increase hazard variety without impossible geometry.
- [ ] Circular bounce pads catch low-, normal-, and maximum-speed crossings (including a one-step tunnel), redirect deterministically for the recorded seed, guarantee the tuned minimum boost, remain under the safe maximum, separate cleanly, and trigger exactly once per crossing.
- [ ] Ball begins visibly on a tee and cleanly leaves it after the first accepted shot.
- [ ] Ball cannot escape playable course bounds during normal play.

## Biome World Presentation

- [ ] Meadow includes subordinate lakes, lily flowers, frogs, bushes, trees, flowers, grass detail, and varied natural motion.
- [ ] Desert includes dunes, rocks, cacti with occasional pink flowers, tumbleweeds, and wind/sand motion.
- [ ] Autumn includes warm varied trees, fallen and drifting leaves, and rare apples.
- [ ] Snow includes snowfall, ice formations, snowbanks, penguins, and cool environmental detail.
- [ ] Swamp includes reeds, water, fog, bubbles, plants, and layered wet-organic detail.
- [ ] Volcanic includes cracks, pools, rock mounds, embers, smoke/heat detail, and particles that fade out before invisible recycle instead of teleporting visibly.
- [ ] Each biome's putting region tints the existing alternating course cells with local `green_a`/`green_b` values, preserving square boundaries and tile detail; there is no smooth overlay and the cup/flag brings no standalone grass, sand, or land patch.
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

## Visual Overhaul Human Acceptance

- [ ] At 1280×720, 1600×900, 1920×1080, and 2560×1440, inspect title, all settings tabs, setup, tutorial, HUD, shop, hole results, and ending; no clipped copy or overlapping controls, with comfortable text at normal viewing distance.
- [ ] Use mouse hover/click and keyboard focus/activation on menus, difficulty choices, seed entry, cards, history, and results. Focus remains visible, actions respond immediately, and purchase feedback clearly acknowledges both benefit and curse.
- [ ] Read all eight cards in 4/5/6-offer shops, including unaffordable and purchased states. Benefit, difficulty-scaled curse, cost, and stack disclosure remain legible without relying on color alone.
- [ ] Play moving shots in all six biomes and across lower/raised crossings. The ball and active route remain foreground, hazard banks and telegraphs stay clear, and cup feedback never leaves the camera at an incorrect zoom.
- [ ] Play the tutorial through its longest instruction; the coach does not cover the course or shot controls. Skip, pause/resume, and restart leave no stale coach or scaled UI.
- [ ] Toggle reduced motion, then revisit title, shop, gameplay, results, and ending. Decorative movement recedes while hazard timing and necessary shot feedback remain understandable.
- [ ] Complete an eighteen-hole run and assess result pacing, the final trophy/biome/card summary, ten-digit seed readability, and New Run / Menu transitions. Record human reactions rather than inferring delight from screenshots.

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
- [ ] Completion and Skip return to Main Menu without starting/generating a real run; replaying Tutorial restores its initial lesson bands. PLAY still starts a clean run afterward.
- [ ] Sand/water use correct Meadow colors and a full transverse band. Touch each; the first water reset opens a bypass without erasing the accepted shot or normal penalty.
- [ ] Score/time remain hidden until the first shot, coins until the shop lesson and effects until cards are introduced. No empty wide panels or undisclosed seed UI remain.
- [ ] Completion, skip, opening the menu, reset, and a later New Run leave the tutorial coach, blocker copy, skip button, and highlight circle fully hidden; subsequent processing cannot resurrect them.
- [ ] Every tutorial message is one short concept and the coach wraps multiline copy without clipping at 1280×720 through 2560×1440.

## Current polish retest

- [ ] Read both ball-O's and the club-swing U at 720p and 1440p; inspect all six background/emblem pairs for coherent identity, quiet motion and course readability.
- [ ] Disable Reduced Motion and move the cursor across the title; layers ease without snaps. Re-enable it and verify no decorative parallax or AI aiming flourish. The saved preference remains respected.
- [ ] Check On/Off and checked/unchecked hover states in both appearances. Settings help stays absent until row hover or control focus; all toggles still persist their actual values.
- [ ] Hover/click Seed, including repeated clicks and leaving the value during confirmation: Copy and Seed copied! fade cleanly, then restore the full seed. Use keyboard focus/activation too.
- [ ] Hover the results Hole value, wheel both ways, then use Up/Down: translucent neighboring played holes appear, snapshots change, and no future hole is accessible.
- [ ] Compare straight preview endpoints on open grass/sand/ice at low/medium/full power. A wall interrupts the line rather than producing a displayed ricochet.
- [ ] Fire oblique and boosted shots into horizontal/vertical walls and corners; reflection angles stay believable, walls stay solid and resets restore the actual tee.
- [ ] Compare all five AI tiers on matched holes. Beginner/Intermediate should be weak but purposeful; selected aim eases before the shot without moving the resting ball or delaying hazard timing.

## Structural / Audio Migration Human Gate

- [ ] Listen to Title, Tutorial, Meadow, Desert, Autumn, Snow, Swamp and Volcanic for at least two complete loop wraps on headphones and speakers. Judge identity, seam continuity, melody/percussion fatigue and comfort beneath instructions.
- [ ] At default and preferred volume, compare strike, soft/strong wall knock, sand, water, ice, lava, all three boosts and high-speed air. Ordinary rolling stays quiet; ambience stays subordinate; no clipping or masking.
- [ ] Buy and stack cards, attempt an unaffordable purchase, hover/focus/back through settings, and change volume/mute. No generic click doubles the purchase cue; curse/stack accents are quieter. Restart the game to confirm saved controls affect the real buses.
- [ ] Compare ordinary cup success, biome completion and the final completion. At par + 4, including entering the cup, both supplied failure layers play together with no positive sink/completion sound.
- [ ] Rapidly reset during a moving shot/water sink, pause/resume during a hazard cycle, skip/restart tutorial, and restart from results/shop/ending. No stale sink moves or hides a new ball, old audio/camera/coach state returns, or accounting is duplicated.
- [ ] Purchase in 4/5/6-offer shops and revisit a shop after a new run: cards finish their animation inside their slots, wallet/history/curse durations agree, and Continue occurs once.
- [ ] Complete a biome transition and run ending, start another run, and return to title. Track/ambience selection follows the screen; same-state settings/pause does not restart music.
- [ ] After an explicitly authorized export, smoke-test the current Windows build outside Godot: boot/audio, settings persistence, one shot/hazard, menu/new run and normal Quit. Confirm supplied-audio redistribution rights before external distribution.

## VS AI human retest

These remain human gates; automated outcomes do not approve opponent personality or pacing.

- [ ] Play Beginner, Intermediate, Expert and Legend. Separate opponent skill from Easy/Normal/Hard course difficulty; weaker opponents are imperfect but purposeful.
- [ ] Watch straight, bank, water, moving-gate, elevation/underpass and bounce-pad holes. Look for controlled approaches, safe setups, timing choices and no wall/hazard immunity or repeated tiny correction shots.
- [ ] Compare the tee, cup size, geometry, elevation, pads and initial moving hazards before/after the turn swap. Trigger landed ice/pad state during the player turn and verify a fresh identical initial course for AI.
- [ ] Buy a course curse on each side, then together. Confirm shared-course disclosure, safe clamped stacking and expiry only on the next generated hole. Verify private power/control/terrain response, coins, purchases and personal curses stay separate.
- [ ] Exercise AI OOB refunds, water/lava resets, forced par + 4, pause/resume, menu cancellation and a new run. No private state crossover or stalled turn.
- [ ] Use 1×, 2×, 4× and Skip; pause and return to menu at each speed. Score and physics stay consistent, audio remains comfortable and normal speed is restored.
- [ ] Finish 18 holes with shops, inspect both builds and cumulative/tie-break scoring, then Rematch the same seed and choose a new opponent. Solo, Tutorial and settings still behave normally.
- [ ] Inspect mode/opponent setup, both turn HUDs, chosen aim, comparison, shared shop, AI reveal and final results in Dark/Light at 1280×720–2560×1440. Navigate with mouse and keyboard.

## Final Human Fix Retest — A–M

Use the current development build, both input methods where applicable, and inspect Dark/Light at 1280×720 through 2560×1440. These are pending human checks, not automated passes.

- [ ] A. Shoot maximum-speed ball directly into walls and corners. Include stacked power/roll cards and repeated impacts; no escape, seam or stuck ball.
- [ ] B. Bounce-pad boost directly into a wall. One launch, visible collision and safe recovery.
- [ ] C. Trigger OOB and verify the shot is refunded once. Repeat near par + 4; current/total/history, reward and remaining-shot warning agree. Water/lava are still costly.
- [ ] D. Compare trajectory arrow endpoint with actual stop at low/medium/high power and with power/roll modifiers, sand/ice and static banks. Moving gates, ramps, wind and pads are stated forecast limitations.
- [ ] E. Watch spiky pendulum for several cycles; art and collision swing together. Contact resets once; pause/resume and rebuild are coherent.
- [ ] F. Trigger falling ice and inspect warning, falling block and landed footprint. Crush resets once; the full tile stays blocked until reset/rebuild.
- [ ] G. Complete a hole and listen for restrained crowd cheer/applause, without disappointed crowd.
- [ ] H. Fail by stroke limit and listen for crowd “aww” plus both supplied failure layers, without success applause.
- [ ] I. Buy a card and hear one kaching. An unaffordable attempt has error only. Compare Common/Rare/Epic/Legendary disclosures, prices and actual effects, including 3/3/4/5-hole curse expiry.
- [ ] J. Switch Dark/Light UI and restart the game. Preference persists; world colors do not change; all screen text and focus/disabled/rarity states stay readable.
- [ ] K. Reach two shots remaining and final shot. The warning arrives before aiming and updates correctly after an OOB refund.
- [ ] L. Compare generated Easy/Normal/Hard holes at comparable seeds/positions. Hard should demand meaningful route/timing decisions, not clutter or unavoidable hazards.
- [ ] M. Compare early versus late run generation and each biome's introduce/develop/climax arc. Late pressure is stronger but recovery remains fair.
