# Visual Overhaul Review — 2026-09-06

## Direction and scope

An illustrated mini-golf clubhouse: jade fixtures, warm ivory scorepaper, gold reward tickets, and coral clipped-corner curse warnings. Equipment cards, travel-postcard biome introductions, a ball/flag wordmark, and a trophy scorecard make golf and risk recurring visual motifs. Original native vector art and the existing licensed Fredoka / Atkinson Hyperlegible pair keep the implementation reusable and resolution-independent. No new third-party assets were imported.

This is a presentation delta over an already dirty release-candidate checkout. Existing difficulty, generation, bounce physics, economy, seed, and save work is not part of this overhaul. The original working-tree scripts/docs/tests were copied to a local evidence baseline before implementation. No architecture rewrite, new gameplay rule, commit, export, or issue closure is authorized by this review.

## Bounded reference pass

These are borrowed principles, not copied assets or layouts:

- [Balatro](https://www.playbalatro.com/): physical card silhouette, clear hierarchy, collectible identity, and responsive purchase/hover feedback.
- [Cursed to Golf](https://blog.playstation.com/2022/07/07/cursed-to-golf-tees-off-on-august-18-for-ps5-and-ps4/): golf equipment as identity and hazards that belong to the course.
- [Golf Peaks](https://afterburn.games/golf): quiet geometry and intentional negative space that make a route easy to read.
- [GamePigeon](https://gamepigeonapp.com/): clean golf-line legibility. This is the brief's design principle; the official landing page is not detailed evidence about its course layouts. Generation and obstacle placement were not changed in this pass.
- [Peglin](https://rednexus.games/): short, energetic impact cues with a calm baseline between events.
- [Slay the Spire](https://www.megacrit.com/games/): concise effect hierarchy and practical icon-led communication.
- [WHAT THE GOLF?](https://triband.net/): playful arrival timing and memorable golf-specific visual quirks.

## Baseline and refinement

The baseline had a small focal title, repeated dark rounded panels, tiny card descriptions around weak central art, an unthemed setup screen, a tutorial competing with the HUD, generic background ellipses, rough patches that resembled hazards, and weak active-elevation separation.

The reusable overhaul covers title/menu buttons; settings/setup/tutorial; HUD/stat/curse clusters; all eight illustrated cards and 4/5/6-offer shops; biome postcard intros; connected tile/hazard banks, green/cup/walls and depth shading; six asymmetric environmental kits; launch/stop/cup/purchase feedback; and hole/run/ending scorecards. Camera framing and reduced-motion propagation are narrow visual integration hooks.

Review refinements included quieter rough texture, organic pond silhouettes, stronger Swamp/Volcanic fairways, larger card disclosures, a distinct Power Club emblem, percentage readouts, safer tutorial clearance, full-length final seeds, and camera zoom restoration after cup feedback. A final image review exposed an intermittent blank trophy during the ending reveal; the intro now requests a settled redraw, and the render fixture checks actual trophy ink as well as layout bounds. The gold-card/ivory-results relationship and the six environment palettes were the strongest cohesive elements in the inspected set. This is agent visual judgment, not human quality approval.

## Evidence and repeatability

Evidence is local, deliberately outside tracked source and exported artifacts:

- `user://visual_overhaul_20260906/source_baseline`: pre-edit working-tree copy used for scope comparison.
- `user://visual_overhaul_20260906/before`: title, UI, course, and six-biome baseline captures.
- `user://visual_overhaul_20260906/after/<resolution>`: 34 named Main-screen captures per resolution, a final frame, and `layout_report.json` containing exact check counts/findings.
- `user://overhaul_full_gut.log`: complete 125/125 test, 66,917 assertion run after fixture-lifetime cleanup.
- `user://overhaul_review_<resolution>.log`: four-resolution render logs; inspect for engine errors as well as scenario success.
- `user://overhaul_final_visual_*_scenario.log`: rendered smoke, tutorial, release showcase, bounce/green showcase, and settings logs.

The four requested windows are 1280×720, 1600×900, 1920×1080, and 2560×1440. They share the configured 1920×1080 logical canvas. Each review fixture covers title; all four settings tabs; setup; tutorial/longest hint; pause; run intro; all six biome intros and gameplay HUDs; Easy/Normal/Hard shop; purchased/unaffordable states; full card bag; one/three/five-star results; history; run results with a ten-digit seed; and ending. Separate rendered showcases cover launch-pad approach/exit, cup closeups, lower/ground/raised views, falling ice and pendulums. They do not substitute for physically completing eighteen holes.

Run the repository baseline after edits:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .codex/skills/godot-verify/scripts/verify_godot.ps1
```

Run the four Main-screen review scenarios through the existing Godot scenario runner, substituting the desired resolution and installed console executable:

```powershell
python .codex/skills/godot/scripts/debug/run_scenario.py . tests/visual_overhaul_1280x720.json --godot-bin <Godot-console-path>
```

Additional scenarios: `visual_smoke_scenario.json`, `visual_ui_tutorial_scenario.json`, `visual_release_showcase_scenario.json`, `visual_bounce_green_showcase_scenario.json`, and `visual_settings_scenario.json`. Raw logs are authoritative for script/runtime errors; screenshot counts and a scenario's status alone are insufficient. Single-frame performance samples during concurrent tests are not a steady-state benchmark.

## Human acceptance remains open

Use the Visual Overhaul Human Acceptance section in `MVP_TEST_CHECKLIST.md`. Review real mouse/keyboard ergonomics, text at normal viewing distance, moving-shot route/depth readability, purchase temptation versus curse clarity, motion comfort, tutorial comprehension, and a complete eighteen-hole payoff. Latest-overhaul ultrawide, other aspect ratios, localization expansion, exported binaries, and sustained performance have not been validated by the four-resolution matrix. Automated readiness means ready for human playtest, not approval to ship.
