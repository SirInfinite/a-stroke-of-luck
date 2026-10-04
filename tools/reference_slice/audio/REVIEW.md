# Audio and audiovisual slice handoff

Reference accessed directly: `assets/references/Screen Recording 2026-09-24 143837.mp4`.
FFmpeg decoded its original AAC audio. Recording sheets spanning 0–34 s and the closer
23.5–26.5 s sequence were visually inspected. The 34.24 s decoded stereo stream is
48 kHz, −55.26 LUFS, −36.39 dBTP. It is unusually quiet. The clearly labelled
`reference_only_gameplay_plus30db.wav` excerpt applies only +30 dB linear gain to
1.5–26.6 s, with no compression, extraction for production, or change to the original.

No model audio-input/listening tool is exposed in this environment. Output playback and
WASAPI recording are available, but they do not let this agent subjectively listen.
Instrumentation, groove, melodic density, bass/percussion roles, music/SFX balance and
sound character therefore remain **unassessed by listening**. Onset autocorrelation
has peaks equivalent to 157.89 BPM and 80 BPM; edits and SFX contaminate this measurement.
That is a low-confidence pulse clue with half/double-time ambiguity, not a measured
musical tempo or proof of a soundtrack loop. The production auditions are deliberately
related around that pulse, with their timbral direction provisional.

## Playable auditions

Open `tools/reference_slice/audio/audition.html` locally. It contains the full reference
video, the boosted reference-only excerpt, both full original auditions with native loop
controls, eight separate SFX and the actual native mixer capture. Playback starts only
on user input; starting a player pauses the others.

The integrated game adapter is `res://tools/reference_slice/audio/reference_audio.gd`.
Set this script on Main's existing AudioController **before** adding Main to the tree.
`candidate = 0` selects A initially; `select_candidate(0/1)` crossfades; `candidate_label()`
returns the display name. Both choices continue through title, Meadow, Volcanic and
results while native ambience changes with the actual biome. They are not claimed as
eight distinct context compositions. Those follow approval of a direction.

Candidate A **Sunlit Circuit** is 48.000 s / 32 bars at 160 BPM, with explicit melodic
questions, answers, a thinner bridge and return. Candidate B **Amber Canopy** is
49.231 s / 32 bars at 156 BPM, a related acoustic-forward arrangement with its own
melody and harmony. Their shared bass/percussion family makes the comparison focused.
Neither is selected or represented as heard/approved.

## Event choreography

Reference: the recording named above. These timings are **project proposals/implementation
values**, not alleged measurements of unheard reference sounds. At 1.5–6.7 s the short
trail and camera follow keep the moving ball primary. At 23.5–26.5 s (200 ms sampled
sequential frames, approximate visual timing) the ball reaches the cup before the
result escalates through discrete number changes. The brief edited shop/item shots at
11.7–12.9 and 20.0–20.8 s do not establish a complete purchase/hover animation.

| Native authoritative event | Visual start / emphasis proposal | Audio start / emphasis | Recovery / interruption |
|---|---|---|---|
| Aim/power update | Same frame; meter follows authoritative input | No continuous pitched loop; existing focus cue only | Cancel clears aim through native owner; no sound-driven state |
| Accepted shot | Same frame; club/ball impulse and short trail | Strike at event, 190 ms material cue | 35 ms duplicate guard; native reset stops voice |
| Wall impact | Same frame; local dust/spark and clamped response | Impact at event; strength-dependent native gain, 240 ms | Native 120 ms guard; no physics change |
| Launch pad event | Same frame; tile pulse around actual collider | Existing protected low/medium/high boost at event | Native boost guard; reset/pause lifecycle preserved |
| Pendulum contact | Same frame; recoil spark at actual contact | Distinct 490 ms stone/metal mass, immediate attack | 120 ms guard; no change to dangerous window |
| Water/lava/sand/ice contact | Local material response at native event | Existing dedicated material cue once | Dedicated route excludes generic duplicate; protected sand unchanged |
| Ball stopped | Native stop confetti/trail settle | Intentional quiet; no normal rolling loop added | Native movement voice stops immediately |
| Cup entry | Native resolved sink animation | Three diminishing contacts over 360 ms | Failure cancels positive substituted voices; reset clears |
| Successful resolved result | Already-awarded result appears; number/star emphasis | Original four-note reward, peaks at 0/.095/.19/.38 s, 1.2 s tail; native restrained crowd retained | Does not award currency or wait for music; failure guard wins |
| Accepted purchase | Price/payment response immediately; item/effect rail change from resolved state | One native purchase cue at 0; quiet curse/stack acknowledgement at +160 ms | Native duck; generation token cancels delayed accent on reset; generic click suppressed |
| Curse acknowledgement | Visible downside remains before purchase; acquired accent may follow | Quiet native dark accent at +160 ms | No extra reward or hidden rule |
| Biome arrival | Native arrival presentation / optional brief rim sweep | Same audition continues; native signpost and 0.8 s ambience crossfade | Latest state wins; menu clears ambience |
| Run completion | Actual resolved outcome hierarchy | Native final accent and music duck | No new fake score events; normal new-run cleanup |

Root owns visual integration. All audio changes remain scene-local and cosmetic.
Reduced-motion/shake settings remain with the native visual owners. Audio does not
modify timing, physics, rewards, random seeds or VS fairness.

## Technical iteration and evidence

1. The first native event-storm check reached the existing limiter at −0.50 dBFS.
   A 35 ms guard on repeated strike presentation removed simultaneous duplicate attacks;
   normal accepted-shot timing is untouched. The final probe peaks at −11.05 dBFS.
2. Review of positive-cue substitution exposed a cancellation boundary: the native failure
   routine knows native streams only. The adapter explicitly stops its substituted cup
   and completion voices before calling the unchanged failure routine. A real-player
   probe confirms cancellation plus suppression of later positive events.

3. A biome can change during an A/B fade while the audition keeps playing. The completion
   signal now reports the latest native context; the 68th lifecycle check covers this
   interruption explicitly.

These are technical improvements. No invented subjective listening/refinement is claimed.

Commands actually run:

```powershell
python tools/reference_slice/audio/inspect_reference.py
python tools/reference_slice/audio/render_auditions.py
python tools/reference_slice/audio/verify_auditions.py
Godot_v4.6.2-stable_win64_console.exe --headless --path . --import --quit
Godot_v4.6.2-stable_win64_console.exe --headless --audio-driver WASAPI --path . --script res://tools/reference_slice/audio/audio_probe.gd
```

The final native lifecycle probe passes **68 checks, zero failures**, with WASAPI output
and a real master-bus recording. Both Ogg loops really wrap; rapid candidate changes
settle to one voice; two music/two ambience/ten SFX/one movement player remain bounded;
pause, menu, reset and failure clear the correct voices; purchase has one cue; bus
volumes/mutes are unchanged. The 7.115 s native recording measures −11.05 dBFS peak,
−29.37 dBFS RMS at the existing settings. It is an automated lifecycle sequence, not
an owner playtest or evidence of listening comfort. Report/log/recording:
`artifacts/reference_review/audio/native_lifecycle.{json,log,wav}`.

The independent asset/link/source audit passes **87 checks, zero failures**. It decodes
all ten Ogg files again, checks hashes/headroom/finite PCM, complete musical measures,
non-silent boundaries, protected originals, actual local audition links and reference
source preservation. Runtime audio growth is **1,673,325 bytes**. Report:
`artifacts/reference_review/audio/asset_verification.json`.

Integrated evidence: `artifacts/reference_review/cycle2_motion/events.json` and the
actual `cycle2_motion.avi` were reviewed together, including selected movie frames and
the decoded 48 kHz stereo mix. The movie is 1920×1080, 60 fps, 36.017 s. Shot/cue frames
match at **316, 670, 1105, 1794**; wall **330**, pendulum **742**, purchase **1558** and
water **1870** each have exactly one corresponding same-frame cue. Cup audio begins at
**1245** (20.750 s), sink finishes at **1266**, and the visible results/completion/crowd
appear at **1275** (21.250 s). Purchase emits **one** purchase cue and **zero** generic
clicks; its quiet curse follows at **1568**, ten frames (166.7 ms) later. Source-template
correlation in the actual mixed audio places all eleven checked cue onsets within
**−13.3 to +10.7 ms** of frame/60; correlations span 0.29–0.80 because music and other
voices remain in the mix. This corroborates event timing, not listening quality.
The decoded full mix measures **−8.71 dBTP**, **−21.28 LUFS**, **−22.45 dBFS RMS**,
with **zero clipped samples** and ten SFX voices in every logged capture. The movie
uses the root's process-local 0 dB bus settings for repeatable evidence; it does not
alter saved preferences. Reproduce with
`python tools/reference_slice/audio/audit_integrated_movie.py`; detailed signal results
and a playable decoded mix are `artifacts/reference_review/audio/integrated_movie_audit.json`
and `cycle2_motion_mix.wav`. Subjective listening remains unperformed.

Scoped integration review found no audio adapter blocker. The inherited unstaged
`AUDIO_SOURCES.md`, AudioController, cue catalog, audio tests, offline render/fetch
tools, manifests and the new slice files were inspected; there are no staged changes
in this audio scope. All **45 audio-domain files present in the pre-edit hash inventory**
remain unchanged. The adapter retains the current catalog's protected mappings,
scoped UI binding, ten-voice SFX pool, native gain/duck ownership and failure guards;
its Ogg looping, same-composition biome handling and substituted-positive cancellation
are separately exercised by the native probe. Production dirty work was not edited.
Review corrected only the new provenance table's per-candidate instrument list and
added this recorded integration evidence. Human musical likeness/mix comfort and the
already-documented supplied-file redistribution provenance remain unresolved.

Eight new SFX and two audition loops are integrated by the adapter. Existing eight
production compositions remain unchanged; production launch remains root-controlled.
Protected source SHA-256 values are checked before and after rendering. No commit,
export, issue closure, source replacement or reference redistribution occurred.

Focused owner listening decisions: which candidate is closer to the recording's
character; whether the lead or acoustic mallet balance should dominate; whether
impacts/purchase remain clear without becoming tiring across two loops. A is the
provisional default for demonstration, not a selected direction.
