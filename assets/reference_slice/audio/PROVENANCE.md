# Approval-slice audio

No musical direction has owner approval yet. These are two original, related auditions,
not a completed soundtrack rollout and not a verified match to Grandpa Golf's music.
No reference-game recording, melody or sound effect is incorporated into these assets.

| Asset | Original content | Incorporated source |
|---|---|---|
| `a_sunlit_circuit.ogg` | **Sunlit Circuit**, 160 BPM, 32 bars, 48.000 s; rounded pulse lead, half-time bass, mallet replies; written AABACDBE form | Verified VCSL vibraphone, marimba, harp, cajon, shaker and wood recordings; original synthesized lead/bass/pad/kick |
| `b_amber_canopy.ogg` | **Amber Canopy**, 156 BPM, 32 bars, 49.231 s; acoustic mallet melody, pulse answers, open middle; written ABACDBAE form | Verified VCSL piano, marimba, vibraphone, cajon, shaker and wood recordings; different melody, chords and arrangement; original synthesis |
| `strike.ogg`, `wall.ogg`, `pendulum.ogg` | Original resonant material impacts; 0.19/0.24/0.49 s | Verified VCSL wood/cajon transients plus original filtered noise/resonances |
| `cup.ogg` | Three diminishing physical contacts, 0.36 s | Verified VCSL wood sample, original contact timing/envelopes |
| `success.ogg` | Original four-note D–F–A–D reward phrase, 1.2 s | Verified VCSL vibraphone plus original rounded-pulse reinforcement |
| `hover.ogg`, `select.ogg`, `back.ogg` | Distinct quiet tactile UI transients, 0.045/0.080/0.110 s | Verified VCSL wood plus original restrained resonant component |

Scores, arrangement, synthesis and render code: A Stroke of Luck project, implemented
by Codex in `tools/reference_slice/audio/render_auditions.py`. This is the editable source.
All sample paths and Git blob identifiers come from `tools/audio_sample_manifest.json`.
The source cache remains in Godot `user://audio_sources/vcsl/`; it is not copied into the build.

Instrument library: **Versilian Community Sample Library**, **Versilian Studios / VCSL
contributors**, **CC0 1.0 Universal**, pinned revision
`c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e`.
[Primary pinned license](https://raw.githubusercontent.com/sgossner/VCSL/c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e/LICENSE)
was opened and verified on 2026-09-24. The existing sample loader verifies all 25 cached
source Git blob hashes before reading any audio. `manifest.json` records their SHA-256
and the finished asset measurements/hashes.

Modifications: onset trimming, verified-root pitch resampling, note envelopes, explicit
original scores, stereo placement, cyclic short room, linear gain mastering and Vorbis
encoding. No external composition was sampled. Original procedural synthesis runs only
offline. The game only reads the finished Ogg files.

`GameAudioController` continues to supply the existing ambience, water/lava/ice, purchase,
curse/stack, transition, crowd and failure cues. Their sources remain documented in
`AUDIO_SOURCES.md`; this slice does not relicense them. In particular, the approved sand
and five owner-supplied boost/failure files retain their exact protected SHA-256 values.
The supplied files' external creator/license information remains unknown, as documented
in the owning provenance file. This pass does not declare it approved.

Reference audio is available only as **reference-only analysis material** under
`artifacts/reference_review/audio/`. It is never loaded by the runtime adapter or renderer.
Source media, decoded reference excerpts and analysis outputs must remain excluded from
exports and must not be committed/published automatically.

Both music files measure −18.96 LUFS. Peaks are −8.03/−6.36 dBTP. The boundary sample
steps are below neighboring 99th-percentile sample differences; the native WASAPI probe
also verifies both players continue across their boundaries. These are signal and
runtime checks, **not subjective loop, groove, fatigue or musical approval**.

Reproduce with `python tools/reference_slice/audio/render_auditions.py` (NumPy,
SoundFile, FFmpeg and the existing verified sample cache). PCM masters stay under
`artifacts/reference_review/audio/`; only Oggs and provenance are runtime asset outputs.
