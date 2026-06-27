# MVP Test Checklist

Use this checklist after each gameplay or stability change. Start from a fresh run unless a test says otherwise.

## Startup

- [ ] Game launches into Hole 1 without errors.
- [ ] Ball, hole, flag, course bounds, HUD, and power meter are visible.
- [ ] HUD shows hole count, strokes, total strokes, par, timer, tokens, obstacles, cards, power, and aim.
- [ ] Timer counts up while playing a hole.

## Mouse Aim And Shot

- [ ] Clicking directly on or near the ball selects it only when stopped.
- [ ] Dragging away from the ball shows the aim line, trajectory dots, aim angle, and power meter.
- [ ] Longer drags increase power up to the cap.
- [ ] Releasing the left mouse button shoots the ball in the expected direction.
- [ ] Aim line and trajectory preview disappear after release.
- [ ] Stroke count increases by 1 only after the ball stops.
- [ ] Total stroke count increases with each completed shot.
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
- [ ] Shop opens after the sink animation finishes.
- [ ] Continuing from the shop loads the next hole.
- [ ] Strokes reset to 0 on the next hole.
- [ ] Total strokes carry forward across holes.
- [ ] Timer resets on the next hole.
- [ ] After Hole 5, continuing loads Hole 1 again without crashing.

## Token Rewards

- [ ] Starting tokens are 2.
- [ ] Finishing under par awards 3 tokens plus any reward bonus.
- [ ] Finishing at par awards 2 tokens plus any reward bonus.
- [ ] Finishing one over par awards 1 token plus any reward bonus.
- [ ] Finishing two or more over par awards 0 tokens plus any reward bonus.
- [ ] Token total updates before or when the shop appears.
- [ ] Token total persists across holes.

## Shop Cards

- [ ] Shop shows 3 card buttons and a continue button.
- [ ] Each card shows name, cost, upside, and downside.
- [ ] Cards that cost more than current tokens are disabled.
- [ ] Buying an affordable card subtracts the correct token cost.
- [ ] Bought card appears in the HUD card summary.
- [ ] Card effects apply immediately to future shots or hazards.
- [ ] Multiple affordable cards can be bought before continuing.
- [ ] Continue button closes the shop and advances to the next hole.
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
- [ ] Stroke count does not reset after water unless the reset key is pressed.
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
- [ ] Pressing `R` resets current-hole strokes to 0.
- [ ] Pressing `R` resets the current-hole timer.
- [ ] Pressing `R` does not reset total strokes.
- [ ] Pressing `R` does not reset tokens or owned cards.
- [ ] Pressing `R` clears sand and direction-pad effects.
- [ ] Pressing `R` while the ball is moving leaves the game in a playable state.
- [ ] Pressing `R` during sink, water reset, or shop does not corrupt progression.

## Debug HUD

- [ ] Debug HUD is visible by default.
- [ ] Pressing the configured debug toggle key hides the HUD.
- [ ] Pressing the debug toggle key again shows the HUD.
- [ ] Power meter remains usable when the debug HUD is hidden.
- [ ] HUD values update correctly after shots, resets, card purchases, and level changes.

## Five-Hole Course Loop

- [ ] Hole 1: basic course can be completed.
- [ ] Hole 2: sand and wall obstacle appear and work.
- [ ] Hole 3: water and two wall obstacles appear and work.
- [ ] Hole 4: direction pad, sand, and wall obstacles appear and work.
- [ ] Hole 5: water, direction pads, and wall obstacles appear and work.
- [ ] Start and hole positions are playable on every hole.
- [ ] Ball cannot escape playable course bounds during normal play.

## Regression Notes

- [ ] No console errors or warnings appear during normal play.
- [ ] No duplicate stroke events occur from one shot.
- [ ] No stale aim line or trajectory preview remains after reset, sink, or level load.
- [ ] No hazard effect persists into a later hole.
- [ ] No shop interaction leaves buttons disabled incorrectly.
- [ ] No level transition happens twice from one hole sink.
