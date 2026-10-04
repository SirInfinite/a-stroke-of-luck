# Presentation approval sample — provenance

2026-09-10. These assets belong to the opt-in sample scene, not an approved full-game rollout.

## Original raster artwork

Six source PNGs were generated specifically for this project with the available OpenAI image-generation tool. No reference-game image was supplied for copying or editing. These are AI-generated original project assets; this record does not claim human pixel authorship or exclusivity. Reference screenshots are kept only in local review evidence, outside the game asset directory.

| Source | Production brief, condensed | Exports |
|---|---|---|
| `source/meadow_atlas.png` | Jade and petrol miniature garden; alternating turf and darker putting turf; moving water and raked sand; iron-bound timber; willow, flower/stone, lotus and golf-sign clusters. Upper-left warm light, deep material outlines. | 12 terrain tiles and 4 props |
| `source/objects_atlas.png` | Heavy cracked round stone on iron suspension, chain, bearing, white golf ball, patch-free cup/flag frames, tee markers, yellow spring pad, coin, card-filled bag, strike and dust frames. | 12 object/feedback sprites |
| `source/card_illustrations.png` | Four separate scenes: an overpowered driver with loose lightning coil; cleated boots crossing sand against a windsock; magnet pulling coins toward a smaller cup; a brass lens revealing the flag beside a strained battery. | 4 illustrations |
| `source/wordmark.png` | Arcadey ivory/gold title; golf balls replace both O letters, a club forms the U, with flag and playing-card corners. | Wordmark |
| `source/ui_atlas.png` | Stitched petrol felt, ivory card stock, jade benefit and burgundy curse bands, gold/teal buttons, scorepaper, lavender rare-card stock. Quiet centers for text. | 8 nine-slice UI materials |
| `source/title_landscape.png` | Dusk clubhouse with a dark quiet center, willow at left, card pack and putter on a foreground bench, lotus pond at right and small warm windows. | Menu landscape |

`export_manifest.json` records source and export dimensions, SHA-256, and crop rectangles. `tools/pixel_sample/export_assets.py` only crops, trims transparent gutters, thresholds alpha and exports with nearest-neighbor resampling. It does not generate geometry or noise, or rasterize the previous vector artwork. The generated sheets did not exactly follow requested grid dimensions; the exporter records measured boundaries.

The sample uses 50-pixel terrain tiles over the existing 100-unit cells, 16–112-pixel objects, 144-pixel card illustrations, 64-pixel UI materials, a 600-pixel-wide wordmark and 960×540 menu landscape. Nearest-neighbor filtering is explicit. The current canvas/camera can produce fractional display scaling; strict integer pixel scaling is not claimed. These are experimental choices, not the post-approval production specification.

## Font

`fonts/PixelifySans.ttf`: Pixelify Sans Project Authors, SIL Open Font License 1.1. Downloaded unmodified from the [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/pixelifysans). Full license is `fonts/OFL.txt`. Pixelify is used for headings and short labels; existing Atkinson text remains for long card descriptions.

## Sound

See [audio/SOURCES.md](audio/SOURCES.md). The existing sand and five owner-supplied boost/failure files are not regenerated. Original game music and sound routing remain the default outside this sample.
