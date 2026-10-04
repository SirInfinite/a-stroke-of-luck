# Pixel-art approval checkpoint

**2026-09-11 update:** the owner approved this sample's logo and rejected its scenic world/UI direction. This sample is retained as comparison A. See the [arcade correction checkpoint](PIXEL_CORRECTION_REVIEW.md) for comparison B and current review status. The historical evidence below describes the original sample, not approval of its art direction.

2026-09-10. **Sample only; owner approval is pending.** No full biome/UI/audio rollout, engine conversion, commit, export, merge or issue closure is authorized by this checkpoint. `ART_DIRECTION.md` intentionally retains its existing production contract until the owner accepts the sample.

## Review and play

- [Local review page with videos and music](../tools/pixel_sample/review.html)
- [Before movie](../artifacts/pixel_sample/baseline.mp4) / [after movie](../artifacts/pixel_sample/after.mp4)
- [Playable-scene instructions](../tools/pixel_sample/README.md)
- [Observed reference lessons and source links](PIXEL_SAMPLE_REFERENCES.md)
- [Artwork, font and audio provenance](../assets/pixel_sample/PROVENANCE.md)

Launch `tools/pixel_sample/launch_sample.ps1` using PowerShell with the existing Godot 4.6.2 executable. `-Original` uses the same fixture with the existing presentation. The normal game still starts at `scenes/main.tscn`.

The review scene uses seed **9102026**, the authored 12×8 Meadow hole **THE OLD SWING**, and the existing Easy four-offer/two-purchase shop. Its 12-coin starting wallet is a review fixture. Results and the purchase use actual Main/RunState/ShopManager paths. REPLAY SAMPLE resets that fixture; production progression and starting currency are unchanged.

## What inspection established

The current source already implements the pendulum's authoritative sinusoidal motion and reset detector, ball-follow camera/overview, native mouse and keyboard aiming, trajectory prediction, connected walls, putting-region metadata, card rarity/benefit/curse/stacks, difficulty-based offer counts, persisted appearance/audio settings and owned audio buses. The production presentation is largely runtime/vector artwork. Its music uses existing independently written sampled arrangements; this pass does not misrepresent them as eight identical files or treat prior completion reports as proof.

The unfinished work for this request was a purpose-made raster identity and accepted musical direction. The sample addresses one representative scene and one shop, not all screens, all icons or all biomes. Existing utility icons and portions of HUD/results framing remain visible as integration context. Full icon, biome, tutorial, run setup, history and VS styling is deferred to approval.

Actual capabilities used: built-in image generation; measured raster cropping/export with Pillow; Godot sprite animation, visual rigging and UI material integration; FFmpeg audio editing/encoding/measurement; verified free CC0 and CC BY sources; Godot Movie Maker mixed audio capture. No purchase, new paid service or downloaded executable was used. Windows native UI inspection failed recovery with “Computer Use native pipe is unavailable”; subjective listening and native mouse playtesting are consequently unperformed.

## The sample treatment

The Meadow combines alternating textured turf and darker putting cells, connected iron-bound timber walls, water and raked sand, yellow spring-pad art, a separate tee/white ball/patch-free cup and flag, and three intentional garden clusters. The pendulum has a stone weight, visible attachment/bearing and individual chain links. The dashed center path derives from its existing travel radius and swing angle; it does not invent a new safe period or collision area.

Four distinct card scenes depict Overdrive Driver, Sand Cleats, Coin Magnet and Rangefinder Lens. Authored paper, felt, jade and burgundy materials separate price, rarity, illustration, benefit, curse, stack state and purchase action. Atkinson remains for large multiline effect copy. Dark and Light both retain readable ink on the dark effect regions. The original theme adapter continues to own other controls; the sample removes only its concrete raster-material labels from that adapter's deferred recoloring.

The wordmark places dimpled balls in both O positions, a bent golf club in the U, and flag/playing-card accents. A purpose-made dusk clubhouse landscape supplies its backdrop. All 42 exported raster assets and six source PNGs are inventoried in `assets/pixel_sample/export_manifest.json`.

## Feedback choreography

| Event | Anticipation / commit | Immediate response | Recovery |
|---|---|---|---|
| Shot | Existing responsive aim and distance preview; real accepted release | Wood contact sample, directional pixel strike, bounded trail; camera impulse scaled by power | Strike clears in 0.13 s; short trail fades at stop; no simulation slow motion |
| Timber impact | Visible connected collision boundary | Separate plank sound and dust; strength-based short camera impulse | Dust clears in 0.24 s; camera returns in 0.12 s |
| Pendulum | Moving weight/attachment and exact center-path marks | Mining impact, warm contact flash and larger dust at the real detector event | 0.18–0.32 s visual decay; native charged reset returns the ball to the tee |
| Stop | Native stopped-state threshold | Small settling puff, no success confetti | 0.19 s; input readiness remains owned by GolfBall |
| Cup | Real approach and physical sink animation | Existing cup/success audio, short pixel glint and three upward coins | Native result timing; existing 0.14 s completion pause; no global time-scale change |
| Purchase | Card hover/focus and explicit BUY; real transaction updates state immediately | One purchase cue; coins travel for 0.22 s with 0.045 s staggering; benefit acknowledgement at 0.15 s | Curse acknowledgement and secondary cue at 0.24 s; stamps clear by about 0.8 s; no mandatory input wait |

Forced-hole failure keeps the existing supplied failure files and distinct negative outcome routing. A pendulum reset does not falsely play a forced-hole failure or success. Reduced motion suppresses camera shake and travelling coins; essential hazard motion/timing remains intact. Effects have bounded lifetimes and a 20-sprite cap. Entering the menu clears pending purchase visuals and cancels its delayed secondary cue.

## Music audition

| Candidate | Playable excerpt | Full integrated source | Status |
|---|---|---:|---|
| A — Peppers Funk, Jason Shaw | [30 seconds](../artifacts/pixel_sample/a_pepper_funk_excerpt.mp3) | 35.8 s | Provisional groove-led brief; source too short for automatic full-run repetition |
| B — Rocker Chicks, Jason Shaw | [45 seconds](../artifacts/pixel_sample/b_rocker_chicks_excerpt.mp3) | 90.1 s | Alternative riff-led rock brief |

**Direction recommendation, pending listening:** one guitar/bass/drums family built around a syncopated groove, with stronger riffs reserved for higher tension. This leaves a useful conceptual role for the game's physical strikes and card sounds. It is a recommendation of the A-style brief, not a claim of having heard these recordings or accepted either composition. No eight-track selection has been made from titles or genre tags.

Full source/license/modification details are in [audio/SOURCES.md](../assets/pixel_sample/audio/SOURCES.md). Normalized pre-encode loudness is approximately -18.0 LUFS for A and -17.5 for B; runtime background gain is -4 dB before existing ducking/settings. Candidate switching retains two voices and a 0.8-second crossfade. These compositions end naturally and can be replayed with 1/2; they are not approved seamless loops. Musical phrase joins, long-session fatigue, speaker/headphone balance and whether either composition conveys the requested intensity need human listening.

## Automated and rendered evidence

- [Canonical Godot verifier output](../artifacts/pixel_sample/godot_verify.log): import, main launches, 257/257 current GUT tests, whitespace and working-tree inventory passed. This is separate from subjective acceptance.
- [Focused checks](../artifacts/pixel_sample/checks/checks.json): 78/78 assertions passed, covering exact collision snapshots around visual application, native keyboard commit/readiness, screen/course transform round trips, overview cancellation, twenty feedback cycles, twenty real purchases, duplicate rejection, reduced motion, both appearance modes, unclipped card copy, preserving tutorial/unsampled cards and direct sample shortcuts. Native mouse coordinates could not be injected into a Window; that attempt was not counted as a mouse pass.
- [Replay/media checks](../artifacts/pixel_sample/evidence_checks.json): 22/22 checks passed. Actual per-frame shot inputs and wall/stop/hazard/sink/result/purchase events match exactly; key cues occur once; both 28.53-second movies contain non-silent audio with measured peaks below -5 dBFS.
- [Existing audio asset verification](../artifacts/pixel_sample/protected_audio_check.log): 386 checks, including all six protected original files; no protected file was regenerated.
- Rendered captures: [720p](../artifacts/pixel_sample/720p/05_shop.png), [1080p](../artifacts/pixel_sample/after/05_shop.png), [1440p](../artifacts/pixel_sample/1440p/05_shop.png), [3440×1440](../artifacts/pixel_sample/wide/02_hole.png), and [default D3D12 Forward+ renderer](../artifacts/pixel_sample/default_renderer/02_hole.png). The matched movies use Compatibility OpenGL; default-renderer screenshots are a separate smoke check.

Visual inspection found and corrected HUD contrast and light-mode effect text. The 720p card copy is retained without ellipsis, but actual reading comfort still needs owner review. Texture filtering is nearest-neighbor; fractional camera/canvas scaling remains, so uniform integer pixel size across all resolutions is not claimed. Surface and wall footprints remain the original square cells and collision rectangles.

An earlier concurrent movie render emitted an additional weak wall notification. The existing GolfBall notification guard uses wall-clock milliseconds, so unusually slow offline frames can outlast that guard. An isolated final recording matched all native events; no collision or cooldown code was changed to force that result. The raw diagnostic remains in local evidence. This limits claims about arbitrary offline recording schedules, not the recorded shot inputs or physical outcomes.

## Integration and remaining approval

New work is limited to `tools/pixel_sample/`, `assets/pixel_sample/`, these two sample documents and ignored local evidence. The existing dirty production tree is preserved. Sample classes subclass the actual feedback/audio controllers and adapt the actual LevelBuilder/UICard nodes. Their internal field dependencies are intentional for this isolated checkpoint; an accepted rollout should replace these temporary adapters with narrow owning-system hooks.

**Diff review: PASS for this sample.** All new sample scripts, launcher, HTML, source/export tooling, manifests and provenance were inspected alongside their existing Main, ball, builder, shop, appearance, feedback and audio integration points. Asset hashes/dimensions and local review links were checked. This does not approve or take ownership of the unrelated pre-existing production diff. No sample code is installed in the production entrypoint.

The optional pseudo-isometric comparison was **deferred** to prioritize the complete top-down art/audio sample. No camera projection, input equation, elevation, bridge, underpass, collision or generation conversion was implemented or adopted.

Human approval checklist:

- [ ] Art: assess turf/cell readability, stone weight and chain, danger visibility, cards, logo and overall identity at normal game scale.
- [ ] Feel: aim and strike with mouse and keyboard, bank, hit the pendulum, sink and buy; repeat enough times to judge intensity and fatigue, including reduced motion.
- [ ] Sound: listen to both excerpts and the integrated movie; choose the musical direction and judge strike/wall/pendulum/purchase/cup mix.
- [ ] Approve the sample or give concrete revisions before production specifications, ART_DIRECTION.md changes, other biomes/screens or the full soundtrack proceed.

Automated tests and agent image inspection do not mark any checklist item approved, polished, manually playtested or release-ready.
