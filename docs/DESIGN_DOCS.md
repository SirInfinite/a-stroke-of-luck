---
title: "A Stroke of Luck"
document_type: "game_design_document"
version: "1.0"
date: "May 2026"
author: "Rony Kaul"
genre: "Top-Down 2D Golf Roguelike"
target_platform:
  - "PC (Windows)"
  - "Mac"
engine_tech: "Godot 5 Engine"
demo_scope:
  holes: "5-7"
  biomes: 1
  shop_stops: 1
  approximate_items: 15
  win_conditions: 2
target_completion: "2-3 months from project start"
source_format: "DOCX"
conversion_purpose: "Agent-readable project reference"
---

# A Stroke of Luck

Golf Roguelike w/ Random Levels

## Agent Parsing Notes

- This Markdown preserves the design decisions, requirements, item data, timeline, risks, and glossary from the source document.
- YAML frontmatter contains high level project metadata for fast retrieval.
- Tables use explicit column headers where possible.
- Open questions and deferred decisions remain unresolved exactly as design decisions in the source.

## Project Metadata

| Field | Value |
|---|---|
| Project Title | A Stroke of Luck |
| Genre | Top-Down 2D Golf Roguelike |
| Target Platform | PC (Windows / Mac) |
| Engine / Tech | Godot 5 Engine |
| Demo Scope | 5-7 holes across 1 biome, 1 shop stop, ~15 items, 2 win conditions |
| Target Completion | 2-3 months from project start |
| Author | Rony Kaul |
| Version | 1.0 (Initial) |

# 1. Game Overview
## 1.1 Concept Summary
A Stroke of Luck is a top-down 2D golf roguelike. Each run, the player works through a short course of procedurally generated courses & holes. Between rounds, they visit a shop where they can purchase items that provide meaningful advantages (faster swing power, wider fairways, scoring bonuses, etc.) but every item purchased also introduces a concrete obstacle/handicap to the next hole.

The core loop: a player who buys everything available will be overwhelmed by obstacles, while a player who buys nothing will lack the tools to score well.

## 1.2 Catchphrase

*"Golf, but every club you buy comes with a curse."*

## 1.3 Target Audience
- Players who enjoy casual sports games with light strategy
- Roguelike/roguelite fans comfortable with short, punchy run structures
- Capstone reviewers and classmates (accessible enough to play in 10-15 minutes)

## 1.4 Win Conditions (Player Goals)
The demo supports two parallel scoring tracks. Players can chase either or both:

- Speed Run - Complete the course in the fewest real-time seconds. Each stroke adds a time penalty.
- Stroke Efficiency - Complete the course in the fewest total strokes. Par is defined per hole.

Both scores are displayed on a results screen after the final hole. In future versions, separate leaderboards could track each. For the demo, showing both values at run end is sufficient.

# 2. Core Game Loop
## 2.1 Run Structure
A complete demo run follows this sequence:

| Step | Description |
|---|---|
| Step 1 - Hole Play    | The player completes the current hole using the shot mechanic.                                                                              |
| Step 2 - Hole Results | Stroke count and time elapsed are shown. A brief summary of obstacles triggered this hole is displayed.                                     |
| Step 3 - Shop Phase   | After every odd hole (1, 3, 5…), the player visits the shop and may purchase 0–2 items. Each item shows its bonus and its obstacle upfront. |
| Step 4 - Next Hole    | The next hole loads with any newly purchased obstacle(s) applied. Previously bought debuffs stack.                                          |
| Step 5 - Run End      | After all holes are completed, the results screen shows final stroke count, total time, items purchased, and a simple letter grade.         |

## 2.2 The Shot Mechanic
The player aims and shoots using a simple two-input system. The design is intentionally approachable - no complex physics simulation is required for the demo.

### Aiming
- A direction indicator (line or arrow) rotates around the ball.
- The player adjusts the angle with left/right arrow keys or by dragging a mouse.
- An optional ghost-trail preview shows an estimated trajectory (can be toggled for difficulty).

### Power
- A power meter fills and empties on a loop (oscillating bar) or the player holds and releases a key.
- Releasing the key / clicking fires the shot at the current power level.
- Power range: 0%–100%. Shots above 80% risk going out of bounds on narrow fairways.

### Physics (Simplified)
- The ball travels in the aimed direction, decelerating over distance.
- Obstacles alter physics: wind zones drift the ball mid-flight, rough tiles slow roll, water hazards reset position with a +1 stroke penalty.
- No spin, no elevation - keep it 2D and predictable for the demo.

## 2.3 Scoring
| Result | Scoring Rule |
|---|---|
| Hole-in-One  | -2 strokes from par (time bonus: -5 seconds on the run clock) |
| Eagle        | -1 stroke from par                                            |
| Birdie       | Par - 1 (good)                                                |
| Par          | Expected strokes for the hole                                 |
| Bogey        | Par + 1 (acceptable)                                          |
| Double Bogey | Par + 2 (bad)                                                 |
| Max Strokes  | Par + 4 is the ceiling - hole ends, player moves on           |

# 3. Shop System
## 3.1 Shop Overview
The shop appears after every odd-numbered hole. The player is presented with a randomized selection of 3–4 items drawn from the item pool. Each item has a visible cost (paid in coins earned from good scores) and a clearly labeled obstacle that will appear on the next hole.

The player may purchase at most 2 items per shop visit. Unpurchased items are discarded - they do not carry over. This keeps the economy simple and ensures variety across runs.

## 3.2 Currency
- Players earn coins at the end of each hole based on score relative to par:
  - Birdie or better: +3 coins
  - Par: +2 coins
  - Bogey: +1 coin
  - Double Bogey or worse: +0 coins
- Starting coins: 2 (enough for one cheap item before hole 2).
- Coins do not carry over between demo runs.

## 3.3 Item Pool (Demo - 15 Items)
All items must display their obstacle clearly in the shop UI before purchase. The player is never surprised by a penalty they did not read.

| Item Name       | Cost | Bonus                                               | Obstacle / Penalty                              |
|---------------------|----------|---------------------------------------------------------|-----------------------------------------------------|
| Power Club      | 2    | Shot power cap raised to 120%                           | Wind always blows against shot direction next hole  |
| Lucky Ball      | 1    | One free stroke reset per hole (no penalty)             | Hole cup is 25% smaller next hole                   |
| Fairway Wax     | 2    | Ball rolls 20% farther on grass tiles                   | Rough patches expanded - cover 40% more of the hole |
| Eagle Eye       | 3    | Trajectory preview line shown for all shots             | Preview line removed for 1 shot per hole (random)   |
| Turbo Tee       | 2    | First shot of each hole +15% power automatically        | Out-of-bounds tiles added along right edge of hole  |
| Sand Wedge      | 1    | Ball exits sand traps in 1 shot instead of 2            | One extra sand trap added to next hole              |
| Steady Hands    | 2    | Power meter speed reduced (easier to hit target %)      | Aim indicator wobbles ±5° randomly each shot        |
| Rain Coat       | 1    | Water hazard penalty reduced to +0 strokes (just reset) | Water hazard tile size doubled next hole            |
| Short Game Guru | 2    | Putting distance range tripled (wider success zone)     | Hole is placed in the rough, not on the green       |
| Coin Magnet     | 1    | Earn +1 extra coin regardless of score this hole        | Shop item count reduced to 2 next visit             |
| Gust Guard      | 2    | Wind effect on ball reduced by 50%                      | A new persistent wind zone added to hole layout     |
| Time Warp       | 3    | -8 seconds removed from run timer on purchase           | Next hole has a 20-second mandatory delay at start  |
| Iron Will       | 1    | Max stroke ceiling raised by 1 (par+5 allowed)          | Par for next hole increased by 1                    |
| Double Down     | 2    | Pick one item and apply its bonus twice                 | Its obstacle is also applied twice next hole        |
| Curse Breaker   | 3    | Remove one active obstacle from your obstacle stack     | Shop is skipped entirely after the next hole        |

# 4. Level Design
## 4.1 Demo Scope - The Meadow Biome
The demo features a single biome: The Meadow. All 5–7 holes share a visual theme (green fairways, simple terrain) to minimize art overhead while demonstrating the full game loop. Biome variety can be added in future milestones beyond the capstone.

## 4.2 Hole Structure
Each hole is a self-contained top-down 2D layout. For the demo, holes can be hand-crafted (no procedural generation required). Procedural generation is a stretch goal.

| Property | Specification |
|---|---|
| Hole Count (Demo)  | 5–7 holes (5 is the MVP minimum; 7 is the stretch target)                                                                             |
| Par Range          | Holes are par 3 or par 4 only - no par 5 for the demo                                                                                 |
| Hole Shape         | Linear paths, slight bends, one optional shortcut route per hole                                                                      |
| Tile Types         | Fairway (normal), Rough (slows ball), Sand (stops ball), Water (penalty + reset), Green (putting zone around cup)                     |
| Obstacle Injection | Obstacles from purchased items are injected into the hole at load time - specific tiles are added or modified based on active effects |

## 4.3 Hand-Crafted Hole Descriptions (Demo)
Each hole below is described at a layout level. Exact tile maps will be built in the engine.

### Hole 1 - The Warm-Up (Par 3)
- Straight fairway, no hazards, wide landing zone.
- Purpose: Teach the shot mechanic. Player should almost always make par or better.
- No shop before this hole - player starts fresh.

### Hole 2 - The Dogleg (Par 4)
- Fairway bends 45° left halfway through. Rough lines outside of the bend.
- First hole where obstacle injection from shop items can appear.
- Teaches the player to consider angle on approach shots.

### Hole 3 - The Pond Hole (Par 3)
- Water hazard bisects the fairway. Players must choose: aim short and lay up, or power over the water.
- Small green with a tight cup placement.
- A shop appears after this hole.

### Hole 4 - The Bunker Alley (Par 4)
- Three sand traps scattered across the fairway.
- Items like Sand Wedge become visibly useful here.
- Obstacles injected here can dramatically change the routing challenge.

### Hole 5 - The Windy Finish (Par 4)
- Persistent wind zone in the upper third of the hole - a fixture of this hole regardless of items.
- Narrow fairway. Out-of-bounds tiles flank both sides.
- Final shop before this hole if run is 7 holes; otherwise this is the penultimate hole.

### Holes 6–7 (Stretch Goal - Par 3 & Par 4)
- Two additional holes with combined hazard types (sand near water, wind plus rough).
- These holes serve as the climax of a fully stacked obstacle run.

# 5. User Interface & UX
## 5.1 Screens Required for Demo
| Screen | Requirements |
|---|---|
| Main Menu      | Title, Play button, brief how-to-play tooltip. No settings required for demo.                                       |
| Hole View      | Top-down golf hole. HUD: stroke count, par, run timer, coin total, active obstacles list.                           |
| Shot Interface | Aim indicator on ball, power meter on screen edge, Fire button or keyboard prompt.                                  |
| Shop Screen    | 3–4 item cards. Each shows: name, cost, bonus (green), obstacle (red). Buy / Skip buttons. Coin total is prominent. |
| Hole Results   | Strokes taken vs. par, coins earned, time split for this hole. 'Next Hole' button.                                  |
| Run Results    | Total strokes, total time, items purchased, obstacles encountered, final letter grade.                              |

## 5.2 HUD Layout (Hole View)
- Top-left: Stroke counter (e.g., '2 / Par 3') and run timer (MM:SS).
- Top-right: Coin total and a small icon stack showing active obstacles (1 icon per active obstacle, tappable for description).
- Bottom-center: Shot controls (aim angle display, power meter, fire prompt).
- Keep the HUD minimal - the course should be the visual focus.

## 5.3 Shop Card Layout
- Card header: Item name (large, bold) and coin cost.
- Bonus line: Green text, starts with a ✦ icon - what the player gains.
- Obstacle line: Red text, starts with a ⚠ icon - what is added next hole.
- Buy button (disabled if insufficient coins). Skip button always available.
- Items the player cannot afford should be visually desaturated but still readable - the player may want to plan around them.

# 6. Testable Demo Requirements
## 6.1 MVP Feature Checklist
The following features define the minimum viable demo. The demo is considered complete when all items below are functional and playable without crashes.

| Feature | Completion Requirement |
|---|---|
| Shot Mechanic       | Player can aim and fire a shot. Ball travels, decelerates, and stops. The hole is completed when the ball enters the cup. |
| Stroke Counter      | Accurate stroke count per hole. Max stroke ceiling enforced.                                                              |
| Run Timer           | Real-time clock runs during hole play. Pauses in shop and results screens.                                                |
| At Least 5 Holes    | Holes 1–5 are playable in sequence with correct par values.                                                               |
| Shop Screen         | The shop appears after holes 1 and 3 (or every odd hole). Player can view items, see costs, and purchase up to 2.         |
| Coin Economy        | Coins awarded correctly after each hole. Purchases deduct correctly.                                                      |
| At Least 8 Items    | 8 of the 15 listed items are implemented with functional bonuses and obstacles.                                           |
| Obstacle Injection  | At least 3 obstacle types visibly alter the next hole when their parent item is purchased.                                |
| Hole Results Screen | Shows strokes, time split, and coins earned after each hole.                                                              |
| Run Results Screen  | Shows cumulative strokes, total time, and items bought. Displays a letter grade.                                          |
| Win/Lose Clarity    | Player understands the run is over and can start a new run.                                                               |
| Stable Playthrough  | One full 5-hole run can be completed without crashing or soft-locking.                                                    |

## 6.2 Stretch Goals (Nice-to-Have, Not Required)
- All 7 holes are implemented.
- All 15 items are implemented.
- Trajectory preview ghost line (Eagle Eye item becomes more meaningful).
- Sound effects: swing, ball roll, water splash, hole-in sound.
- Background music loop for the Meadow biome.
- Basic particle effects (ball splash, sand puff).
- Leaderboard / high score persistence (local save only).
- A second biome with different tile aesthetics.

# 7. Development Timeline
## 7.1 Assumptions
- ~10–15 hours of development time per week available.
- Solo developer or small team of 2.
- Engines and tools are already chosen before Week 1 begins.
- Art is simple (colored rectangles and circles are acceptable for demo).

## 7.2 12-Week Schedule
| Week | Milestone       | Deliverable / Success Criteria                                                                                           |
|----------|---------------------|------------------------------------------------------------------------------------------------------------------------------|
| 1        | Foundation          | Engine project set up. The ball moves in 2D. Basic aim + power mechanic working. The ball stops when it hits the cup hitbox. |
| 2        | Hole 1 Complete     | Hole 1 is fully playable. Stroke counter works. Hole results screen appears after completion.                                |
| 3        | Core Tile Types     | Fairway, Rough, Sand, Water tiles all have correct physics behavior. Ball resets correctly on water.                         |
| 4        | Holes 2 & 3 Built   | Dogleg and Pond Hole are playable. Run timer implemented. Coin award logic coded.                                            |
| 5        | Shop System         | The shop screen appears after hole 1. 4 items implemented (bonus + obstacle logic). Coin deduction working.                  |
| 6        | Obstacle Injection  | 3 obstacle types can visibly modify hole layout on load. Active obstacle HUD icon strip working.                             |
| 7        | Holes 4 & 5 Built   | Bunker Alley and Windy Finish are playable. Wind zone physics implemented.                                                   |
| 8        | Full Item Pool (8+) | 8 items fully implemented. The shop appears on the correct holes. Item limit of 2 enforced.                                  |
| 9        | Run Results Screen  | The end-of-run screen shows all stats and letter grades. New runs can be started from results.                               |
| 10       | Polish Pass 1       | Fix any crash bugs. Balance coin economy (playtest with classmates). Adjust par values if holes feel too hard/easy.          |
| 11       | Stretch Goals       | Implement stretch goals from Section 6.2 in priority order, stopping when time runs out.                                     |
| 12       | Final Polish & Demo | Freeze features. Bug fix only. Record a gameplay demo video. Prepare capstone presentation build.                            |

# 8. Risks & Mitigations
| Risk                                    | Severity | Mitigation                                                                                                                          |
|---------------------------------------------|--------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| Physics complexity grows beyond scope       | Medium   | Keep physics to a single flat plane. No elevation, no spin. Use engine built-ins where possible.                                        |
| Obstacle injection system is too complex    | High     | Define obstacles as simple data flags (e.g., 'add 2 sand tiles at positions X'). Inject at hole load, not at runtime.                   |
| Item balance makes game trivially easy/hard | Medium   | Playtest in Week 10. Adjust coin costs and obstacle severity. Keep a spreadsheet of playtester feedback.                                |
| Art scope creep delays core features        | Medium   | Use placeholder geometry (colored shapes) for the entire demo. Polish art only after all MVP features work.                             |
| Scope grows and demo is unfinished          | High     | The MVP checklist in Section 6.1 is the north star. No stretch goal work begins until every MVP item is checked off.                    |
| Engine learning curve takes too long        | Low      | Choose the engine in Week 0 (before the timeline starts) based on prior experience. Godot and Unity both have strong 2D golf tutorials. |

# 9. Open Questions & Design Decisions
## 9.1 Decisions to Make Before Week 1
- Which engine? (Godot is recommended for a solo capstone project - fast 2D workflow, free, exportable to web.)
- Mouse-and-click controls or keyboard only? (Mouse is more intuitive; keyboard is easier to implement for a demo.)
- Is the run timer visible during shots, or only between holes? (Visible timer adds pressure - good for the speed-run track.)
- Letter grade formula - define what A/B/C/D/F means in strokes-relative-to-total-par terms before coding the results screen.

## 9.2 Deferred Decisions (Post-Demo)
- Multiple biomes - art and tile set design.
- Procedural hole generation algorithm.
- Online leaderboard vs. local high score.
- Full item pool expansion beyond 15 items.
- Multiplayer or async ghost runs.

# 10. Glossary
| Term | Definition |
|---|---|
| Biome        | A visual and mechanical theme applied to a set of holes (e.g., Meadow, Desert, Arctic).     |
| Bogey        | A score of one stroke over par on a hole.                                                   |
| Cup          | The target hole on the golf green. The ball must enter the cup to complete the hole.        |
| Eagle        | A score of two strokes under par on a hole.                                                 |
| Fairway      | The main playing surface of a hole. Normal ball physics.                                    |
| Green        | The close-cut area surrounding the cup. Shortest grass, best roll.                          |
| Hole         | One complete golf layout from tee to cup.                                                   |
| Item         | A purchasable object in the shop that provides a bonus and an obstacle.                     |
| Obstacle     | A handicap or hazard added to the next hole as a consequence of purchasing an item.         |
| Par          | The expected number of strokes to complete a hole.                                          |
| Power Meter  | An oscillating UI element the player uses to set shot power.                                |
| Rough        | Tall-grass tiles that slow ball roll speed.                                                 |
| Run          | One complete playthrough from hole 1 to the final hole, including all shop visits.          |
| Roguelike    | A genre featuring permadeath, randomized content, and run-based progression.                |
| Sand Trap    | A hazard tile that stops the ball and costs an extra stroke to exit.                        |
| Stroke       | One shot attempt. Each press of the fire button counts as one stroke.                       |
| Water Hazard | A tile that resets ball position and adds a one-stroke penalty (unless Rain Coat is owned). |
