# Arcade correction sample assets

Created 2026-09-11 for the isolated comparison scene. **Human approval is pending.**

All new raster artwork was generated with the built-in image-generation tool from original, task-specific briefs. No proprietary game assets or screenshot crops are included in these source sheets. The saved Balatro, Grandpa Golf and Into the Breach reference screenshots were inspected for shape, shading and readability principles only. New reference attachments were not available in the conversation.

The owner subsequently specified `assets/ref1.png`, `assets/ref2.png` and `assets/ref3.png`. All three were visually inspected, and the final UI refinement follows their outlined numerical feedback, isolated item sprites and emphatic purchase actions. The analysis is recorded in [the correction review](../../docs/PIXEL_CORRECTION_REVIEW.md). These local references were not cropped into assets, sent as image-edit targets or used to copy their compositions.

The approved logo remains at `assets/pixel_sample/ui/wordmark.png`, used directly without editing or re-export. Its hash is covered by `artifacts/pixel_correction/protected_sources.json` and `preservation_check.json`.

| Source | Role | Runtime use |
|---|---|---|
| `source/terrain_flat.png` | Targeted correction to remove the initial water glow and soften the overly bright turf palette | Eight 32×32 surface textures |
| `source/objects.png` | Original chunky stone/chain/bearing, ball/flag/tee/pad, coin/bag/VFX and Meadow props | Sixteen sprites, maximum 48 pixels on their long side |
| `source/cards_cutout.png` | Targeted transparent-sprite correction of the four original equipment designs | Four sprites, maximum 64 pixels on their long side |
| `source/background.png` | Broad Meadow silhouette bands and quiet center space | 480×270 title background |
| `source/terrain.png`, `source/cards.png` | Initial candidates retained as source history | Not loaded by the sample |

The complete generation and revision prompts are in [PROMPTS.md](PROMPTS.md). [export_manifest.json](export_manifest.json) records the source, crop, final dimensions and SHA-256 for all 29 exported assets. `tools/pixel_correction/export_assets.gd` performs measured extraction, opaque material/binary sprite alpha normalization, and nearest-neighbor density export. It preserves the generated color design; it does not process the approved logo.

The original generated sheets are not perfectly indexed-color masters. The exported art deliberately reduces spatial detail and uses broad shade groups, but a strict two/three-color palette per texture is not claimed. No painterly water glow is retained in the selected source. A uniform integer pixel size across fractional camera zooms is also not claimed.

UI frames, wall top/side faces, power blocks and tiny semantic symbols are original native Godot pixel constructions in `arcade_assets.gd`, `arcade_world.gd` and `arcade_power.gd`. Their flat inks and stepped geometry are shared within this sample. These are functional controls/materials, not downloaded icon-kit art.

Pixelify Sans, Atkinson Hyperlegible and the music/SFX are reused from the previous sample/project. No new fonts, music, recordings, code libraries or third-party assets were added. Existing font licenses remain alongside their files; existing audio attribution and modifications remain in [the previous sample sources](../pixel_sample/audio/SOURCES.md).
