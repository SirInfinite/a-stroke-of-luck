# Game Vision

## The Game

**A Stroke of Luck** is a top-down 2D golf roguelike about accepting trouble on purpose. Across a short course, the player aims predictable physics-based shots, manages strokes and time, and spends score-earned currency on powerful upgrades. Every upgrade carries a clearly disclosed curse or obstacle. Buying aggressively creates a stronger golfer and a more hostile course; refusing every offer preserves a cleaner course but leaves the player without tools to excel.

The player fantasy is not professional golf simulation. It is becoming a clever, increasingly over-equipped golfer who can read a compact course, build a strange combination of advantages, and survive the consequences of that build.

## Core Loop

1. Read the hole: route, cup, par, hazards, and active penalties.
2. Aim, choose power, shoot, and adapt to the result.
3. Finish the hole efficiently to earn currency.
4. Review the result, then decide which benefit-and-curse trades are worth buying.
5. Carry the build and its accumulating complications into the next hole.
6. Complete the course and compare total strokes and time.

One shot should be immediately understandable, but a whole run should produce meaningful decisions. The physical action supplies tactile satisfaction; the shop and stacking modifiers supply variety, risk, and stories.

## Desired Feel

Playing should feel readable, responsive, playful, and lightly tense. The player should usually understand why a shot succeeded or failed. A strong shot should feel earned through aim and power judgment, not hidden randomness. Hazards should create anticipation without making the course illegible. Purchases should feel exciting and dangerous at the same time.

The pace alternates between calm spatial planning and brief, energetic feedback: line up, release, watch, react, then make a consequential shop choice. Humor and exaggeration are welcome, but feedback must stay concise enough for a 10–15 minute session.

## What Makes It Distinctive

The defining promise is: **every upgrade comes with a penalty**. The downside is not fine print or a random surprise; it is half of the offer. The player builds both their power and their future problems. This creates an unusual form of ownership over difficulty: when the course becomes chaotic, it should feel like the result of understandable choices.

The two parallel performance lenses—stroke efficiency and real-time speed with stroke penalties—also let deliberate route planning and brisk execution coexist. Neither should erase the value of completing a satisfying golf shot.

## Design References

- **Cursed to Golf:** how golf can support roguelike progression, run structure, powerups, and unusual course challenges without losing its golf identity. Reference for combining recognizable golf mechanics with roguelike run structure, unusual modifiers, and escalating course challenges.

- **Peglin:** how a repeatable physics action, trajectory prediction, relic-like modifiers, and run building can remain satisfying. Reference for placing a repeatable physics-based action at the center of a roguelike. Particularly relevant to aiming, trajectory communication, satisfying physical feedback, and modifiers that change how the core interaction behaves.

- **Balatro:** clear presentation of stacked modifiers and a shop economy that makes simple underlying actions transform across a run. Reference for run-building, shops, stacking modifiers, readable effect communication, and making simple underlying mechanics become more complex through accumulated player choices.

- **Golf Peaks:** immediate top-down readability and compact levels whose routes and hazards communicate without excessive UI. Reference for compact golf level design, top-down readability, clean terrain communication, and visually understandable routes and hazards.

- **WHAT THE GOLF?:** approachable humor, brisk pacing, strong feedback, and the ability to introduce an idea quickly and move on. Reference for approachable controls, playful presentation, short-form pacing, and giving simple golf interactions strong visual and audio feedback.

### Secondary References

- **Golf Story:** top-down golf presentation and environmental readability.
- **Desert Golfing:** simplicity of aiming, power, terrain, and ball feel.
- **Slay the Spire:** meaningful run decisions and evaluating purchases by their long-term consequences.

These are references for principles. New features must fit **A Stroke of Luck** rather than reproduce another game’s mechanics or visual style.

## Boundaries

The game should not become a realistic golf simulator, a precision physics sandbox, a sprawling content roguelite, or a spectacle that hides course information. It does not need elevation, spin, detailed club simulation, or metaprogression. The six release biomes are data variations over one shared deterministic generator and gameplay foundation; they must not become six bespoke implementations. Randomness should vary decisions, not make outcomes feel arbitrary. More items are not valuable unless their benefit-and-penalty pair creates a legible choice.

The immediate audience is players who enjoy casual sports games and light roguelike strategy, including people who can learn and finish a demo in one sitting. Controls and terminology should remain welcoming to non-golfers.

## A Successful Session

A successful session completes all 18 compact holes in one sitting, teaches itself quickly, reaches a conclusive ending, and leaves the player able to explain both a favorite upgrade and the trouble it caused. Exact release duration remains a full-run playtest question. The player makes several intentional route or purchase decisions, experiences escalating but readable challenge, and wants another run to try a different build or improve strokes or time. Success does not require a perfect score; it requires clarity, agency, satisfying shots, and a memorable risk/reward arc.
