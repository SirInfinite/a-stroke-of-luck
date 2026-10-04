# Icon and brand migration — 2026-09-07

## Before-edit audit

Baseline: the real Main scene, `human_fix_review.tscn`, 1280×720;
37 captures, 1,444 layout checks, zero failures. Title, setup, settings,
tutorial, shop, all rarities, results and all six biome HUDs were inspected.
Evidence lives in `user://icon_brand_20260907/before/1280x720`.

The unit counted below is a **source treatment**, not every repeated on-screen
instance or alias: 38 UIIcon drawing branches, eight equipment illustrations,
four rarity treatments, three Theme controls, wordmark, app icon, six postcards,
result seal, history chevrons, purchase tick and trailing action triangle = 65.
Also audited: two native Theme treatments (dropdown and selection state), and
four contextual illustration treatments (backdrop ball, flag and card
silhouettes, plus the tutorial targeting pointer) = **71 source treatments**.

| Classification | Count | Treatments / reason |
|---|---:|---|
| KEEP | 11 | Six authored landscape postcards, result seal and four contextual illustration treatments. These are containers/world illustrations, not competing UI symbol packs. |
| REFINE | 52 | 33 UIIcon branches (all except the five listed below); eight equipment centerpieces; four rarity treatments; toggles on/off and slider grip; wordmark; history chevrons; native dropdown and selection state. Concepts work, but variable double outlines, arbitrary polygon insets, tiny detail and inconsistent bounds do not. |
| REDESIGN | 3 | Coin: nested rings and unexplained interior marks; seed: pseudo-3D die among flat symbols; app icon: stock Godot robot, unrelated to the game. |
| REMOVE / DUPLICATE | 5 | `control` duplicates the target drawing; `score_good` duplicates star; `score_bad` duplicates curse. Consolidate geometry, retain useful semantic aliases. Remove redundant purchased Unicode tick and trailing primary-button triangle. Text/action icons already communicate these states. |

Additional **mapping** defects (not extra assets): sand points to a boot;
ice and Snow share a snowflake; lava and Volcanic share a mountain; Back points
to Continue/Menu; randomize points to seed; difficulty points to settings or
unrelated benefit/card/curse symbols. Separate these meanings without changing
the actions. Preserve terrain rendering, card values and UI composition.

## Migration contract

The style specification lives in `ART_DIRECTION.md`, not in this review.
Preserve the printed-clubhouse palette, Fredoka lettering, ball-O and flag
motifs. Use authored, editable vector geometry, with deterministic SVG/raster
exports. No raster generation or external icon pack is needed.

Replace the UIIcon drawing implementation behind its existing API. Equipment
centerpieces reuse the same glyphs at display size, with one consistent field.
All ordinary symbols are tintable and background-free. Rarity stays secondary
to the disclosed benefit, curse, stack and price.

## Verification and human handoff

### Implemented mapping

| Old | New |
|---|---|
| UIIcon's separate primitive drawing branches | One catalog of 71 canonical glyphs, regular and simplified small SVG tiers; semantic aliases resolve once. |
| Eight independent equipment draw routines | Catalog equipment glyph + common cut-card field and one mechanic-specific supporting mark. |
| Runtime letter labels + pasted letter overlays | Outlined Fredoka wordmark, ball-O and U pennant; same outlines with surface-appropriate ink. |
| Stock Godot `assets/icon.svg` | Derived ball/card emblem at the same path; five PNG sizes and multi-resolution Windows ICO. |
| toggle_on/off.svg, slider_knob.svg | Refined at their stable paths; same print corners, ink and check glyph. |
| Engine-default dropdown/radio marks | Three native-size masks from the same geometry, with centralized light-Theme tinting. |
| Sand/boot, ice/flake, lava/mountain conflation | Separate terrain and equipment/biome glyphs. |
| Back → Continue/Menu; randomize → seed | Dedicated Back and Randomize; one/two/three-flag difficulty family. |
| Three duplicated drawing routines, purchase tick, trailing button arrow | Aliases or removal of redundant marks; actions/text unchanged. |

No original font, audio, world asset or unrelated image was deleted. Source
drawing code was superseded in place; four redundant intermediate SVG outputs
created during this migration were removed after alias consolidation.

### Review findings addressed

- Replaced bowling-like three dots with a shallow golf-dimple texture (large
  brand/ball only; small icons remain simple).
- Widened the club silhouette optically; balanced Heavy Core's mass; made Epic
  a flat faceted gem rather than a cube.
- Removed extra registration ticks from card art and darkened supporting marks
  on ivory stock.
- Corrected the wallet coin's foreground after removing baked two-color art.
- Fixed repeated palette signal connections on reparented controls and retained
  canonical icon ink across dark/light switches.
- Main's scenic background does not become light: its wordmark must stay
  ivory/gold even with Light UI. Dark-ink wordmark is for genuine light surfaces.
- Rebound rating fill to foreground ink so earned stars remain distinct from
  unearned slots, and gave the biome-intro row dark ink on its ivory surface.
- Corrected OOB copy's missing horizontal expansion: the warning retains both
  its explanation and its new symbol. Countdown/recovery rules are unchanged.

### Measured visual / structural evidence

- Actual Main screen review: **42 captures and 2,609 layout checks per run**,
  Dark and Light at 1280×720, 1600×900, 1920×1080 and 2560×1440. Total:
  **336 captures / 20,872 checks / zero layout failures**. Includes all six
  biomes, all eight card centerpieces, four rarities, active effects, warnings,
  settings tabs, authored sand/water tutorial instructions, results and ending.
- Optical review: two 1920×1600 sheets show all 71 glyphs at 64/24/16px, the
  wordmark, compact emblem, app sizes and eight card illustrations. Six actual
  before/after screen pairs are preserved on two additional sheets.
- Existing rendered smoke: 11 assertions, seven screenshots, no errors.
  Existing release showcase: 11 assertions, 23 screenshots, no errors.
- Twelve focused icon tests (1,144 assertions) cover reference completeness, unique canonical
  geometry, small variants, passive input, dynamic Theme changes/reparenting,
  native Theme texture immutability, rarity disclosures, PNG/ICO payloads,
  earned-rating visibility, biome-intro contrast and warning-copy width.
- The first full GUT run found one obsolete logo assertion referring to the
  removed `kicker_label`. It now checks the full accessible wordmark instead;
  the complete 18-hole lifecycle test then passed (433 assertions). No runtime
  lifecycle code was changed to satisfy this test.
- Screenshot-fixture corrections hold the injected OOB snapshot against normal
  in-bounds clearing, assert its actual visibility and copy width, and free Main
  before shutdown. An intermediate teardown warning was not treated as a pass;
  final capture runs exit cleanly. No production debug hook was added.
- Vector/source parity: 154 outputs; app parity: five PNG sizes plus ICO.
  Both deterministic `--check` commands pass.

The canonical verifier is rerun after these changes. Its complete final output
is `user://icon_brand_20260907/verification/godot-verify-final.txt`; report its
actual result rather than treating these visual checks as a full-suite pass.

Evidence paths under `user://icon_brand_20260907/`:

- `before/1280x720/` and `after/{dark,light}/{resolution}/layout_report.json`
- `family/family_dark.png`, `family/family_light.png`
- `comparison_1.png`, `comparison_2.png`
- `verification/rendered_smoke.log`, `verification/release_showcase.log`

### Reproduction and scope

`tools/build_brand_assets.py` is the editable original geometry source. It uses
the already approved Fredoka Bold font (existing OFL provenance); no icon pack
or new third-party art was included. The vector build uses Python plus
fontTools (verified with 4.54.1); raster exports use the project's Godot 4.6.2
SVG renderer. Rebuild/check commands are in `ART_DIRECTION.md`.

Run `tests/icon_brand_showcase.tscn` for the family sheets. Run
`tests/icon_brand_review.tscn -- --review-size=1280x720 --appearance=dark
--output-root=user://icon_brand_20260907/after/dark` for one actual-screen pass;
substitute the required resolution and theme. Run `tests/icon_brand_compare.tscn`
after the captures exist. All are development-only and excluded from exports.

The starting worktree already contained unrelated release work. SHA-256
comparison against the before-edit inventory preserves 269 of 292 inspected
existing files byte-for-byte; the 23 changed existing files are presentation,
Theme/icon assets, the icon export setting, owning documentation and the logo
test assertion. Main, RunState, GolfBall, course rendering/generation/validation,
card definitions/rarity/effects, settings persistence and audio are unchanged.
ShopManager changed only wallet-icon ink. Nothing was committed or exported;
the Windows ICO is configured for the next separately authorized build.

### Human visual review still required

Review both family sheets and the title together; judge 16–32px optical weight,
card identities and rarity shapes without color alone. Then check real HUD,
shop disclosures, settings dropdowns, warnings and tutorial symbols in both
themes with keyboard focus and resizing. Inspect the compact emblem in Windows
after the next authorized build. This record is **not human visual approval**.
