# UI reference observations and sample contract

Directly opened the original local 1920 × 1080 shop `ss_67b19c56802de57a61d4643e18c14a940ee60360.1920x1080.jpg`, inventory `ss_d2ca6ce182fd4edbae96056d4a0fd01552d8c6ee.1920x1080.jpg`, upgrade `ss_5c71f7f281de672054c04fdf71eaa7e0a8abd1da.1920x1080.jpg`, and HUD `ss_850b529563d9e26c059d2b470441dc0b7b3de3dd.1920x1080.jpg` in `C:/Users/Rony/Projects/a-stroke-of-luck/assets/references`. All were accessible and readable.

- Shop and inventory use recognizable, isolated shaded objects with delicate pale material glints and a dark contour. Boot stitching and glove folds describe material; their silhouettes read without badges.
- Thin warm rims surround dark translucent panels. Scenery remains visible through quiet surfaces. Yellow Buy/Select text and pale item names sit above smaller supporting copy. Compact outlined display lettering carries numerical hierarchy.
- Inventory and shop use different object scales. The candidate therefore retains both 128 px display sprites and 32 px rail exports.

Sequential contact sheets extracted from **`Screen Recording 2026-09-24 143837.mp4`** appear in `artifacts/reference_review/ui/reference_shop_timing.png` (11.7–12.9 s at 10 fps), `reference_item_timing.png` (20–20.8 s at 10 fps), and `reference_result_timing.png` (24–26.6 s at 5 fps). These are sampled temporal evidence, not native playback or listening. Shop details change from ball to coil around 12.3–12.4 s without a long transition; an item overlay appears around 20.3 s in an edited montage; accumulating reward lines and number changes around 24.9–26.6 s follow the visible cup sequence. The montage does not establish a complete purchase animation or menu opening duration. This workstream makes no audio listening claim.

The candidate uses a 120 ms item focus enlargement, immediate details replacement and the native resolved-purchase event. Its acknowledgement has a 140 ms entrance and recovery. These are original timing choices informed by responsive reference behavior, not measured matches. Reduced motion bypasses movement. Presentation never calculates or awards currency.

Integration: instantiate `reference_ui.gd`, add it as a Node, call `setup(main)`, call `apply_hole()` after native level builds and `apply_shop()` after native offers. `fx_layer` and `_style_results()` support the root harness. The adapter reads existing CardDefinition / RunState values and forwards explicit Buy controls to native UICard signals. Main and ShopManager retain rules, purchase gates, effects, results and audio ownership. Root owns the central scene, world, camera and title background composition.

Four offers receive selected details beside the row. Five and six offers use one tall row and a details strip beneath, retaining benefit and curse copy with fixed type sizes per role. The sample utility adapter restyles after native screen opening, difficulty selection and seed validation. It preserves native inputs, persistence, non-color selection text and validation meaning. The unchanged approved logo is referenced directly. TitleAttractMode is preserved. No default scene, production script, approved asset, physics or generation file is edited by this workstream.

## Refinement cycle 1

Reviewed `artifacts/reference_review/cycle1_integrated/`: title, Meadow and all four shops. The six-offer layout retained disclosures, but display type was too thin, nested image frames over-structured cards, light-mode details had dark ink against a dark panel, and the HUD seed value sat too low.

Material changes: selected licensed Jersey 10 after actual-size comparison; removed image-well frames; gave rarity a thin top rim; reclaimed selected-detail ink after deferred appearance registration; removed outlines and shadows for dark text on light stock; refit seed anchors. Increased primary title action type. The next integrated gallery confirmed these improvements.

## Refinement cycle 2

Reviewed `cycle2_integrated/`, `cycle2_720/` and actual three-shot sink / resolved-results evidence in `cycle2_motion/04_results.png`. Small supporting labels at 720p needed more weight. The results retained an oversized vector medallion, redundant stat pictograms and small numbers inside a large quiet area.

Material changes: moved small section and stacking copy to larger Atkinson role sizes; enlarged card names uniformly; redistributed image and disclosure height without per-card shrinking; increased primary action rim contrast. Replaced the results medallion with a compact original pixel rating star, replaced earned-star marks with the same raster while retaining native alpha states, hid redundant stat pictograms, elevated resolved strokes / par / reward / wallet numbers, and kept history navigation and seed copy. A derived original coin now supports the wallet.

Inspected the resulting `final_1080/01_title.png`, `final_720/05_shop_hard.png`, `final_720/06_shop_light.png`, utility captures, and `final_motion/04_results.png` / `06_purchase.png`. The six-offer card names and full curse disclosures fit at 720p. The resolved PAR screen retains four earned stars, four strokes, reward +2 and wallet 14 with stronger numerical hierarchy. The title keeps the unchanged logo; transparent framing preserves its scenic setting. The results and purchase frames come from the actual integrated game systems.

Utility screens retain inherited vector backgrounds, tabs and toggle glyphs. They have partial component styling; complete utility, tutorial and VS AI presentation migration remains pending approval. The first final-motion capture focused the initially selected offer and did not demonstrate a changed selection. Review identified this evidence gap; the root's final harness now focuses the second Buy control to capture Sand Cleats details and adds selected-identity / title assertions across all three shop sizes. The root owns the final rerun result.

## Verification boundary

All four UI GDScript files passed explicit Godot 4.6.2 check-only parsing. Generated item sheets and integrated title / gameplay / 4–6 offer / light-mode / 720p screens were visually inspected. The root coordinates imports, affected-scene captures, shared canonical verification and final evidence. Native-input comfort, listening, visual approval and full-screen rollout remain owner gates. This is a playable sample adapter, not a completed production migration.

Reviewed the complete existing UI-domain unstaged diff (shared theme, HUD, shop, transition presentation, UI scripts and relevant changed presentation checks); the staged UI-domain diff was empty. Read the supporting untracked UI controls and the full new sample implementation. The native purchase transaction remains authoritative; history continues to reject future holes. Review found and fixed the sample SeedTicket light-mode ink restoration after native hover/copy updates and added three bounded appearance-settle passes for newly built results labels. Final runtime functions changed: `_process()` and `_style_results(settle := true)`. Root reruns focused integration checks after that fix.

`git diff --check` passed. Asset validation confirmed all 25 manifest rasters are nonempty with matching dimensions and SHA-256 values; the runtime rasters plus Jersey 10 font occupy 176,563 bytes before Godot import. The inherited 152-file SVG UI inventory parsed without scripts or external links. Approved source and exported logo hashes still match the initial values. These checks do not approve inherited or sample aesthetics.
