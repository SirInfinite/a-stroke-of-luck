# Audio Sources and Provenance

Revision 3, 2026-09-07. Every shipped WAV is inventoried here and in `assets/audio/audio_manifest.json` plus `assets/audio/playtest_audio_manifest.json`. This distinguishes original project arrangements, verified third-party recordings and owner-supplied recordings. It does not imply human composition or listening approval.

## Original chamber-arcade score

Codex wrote eight explicit scores for A Stroke of Luck in `tools/audio_score.py`: separate melodies, harmony, A/B/C phrases, meter and orchestration. `tools/render_audio_score.py` renders them offline; `tools/generate_audio_assets.py` remains the entrypoint. No track is a pitch/filter/speed variant of another, and no melody is generated at runtime.

The 25 instrument recordings come from **Versilian Community Sample Library (VCSL)**, by **Versilian Studios / VCSL contributors**, under **CC0 1.0 Universal**. The arrangement/code is original project work; incorporated instrument recordings have the verified CC0 provenance below. No third-party musical composition was copied.

- Library: https://versilian-studios.com/vcsl/
- Repository: https://github.com/sgossner/VCSL
- Pinned revision: `c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e`
- Verified license: https://github.com/sgossner/VCSL/blob/c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e/LICENSE
- Exact source filenames/paths, Git blob hashes and sizes: `tools/audio_sample_manifest.json`.
- Actual source SHA-256 and output SHA-256/measurements: `assets/audio/audio_manifest.json`.

Each source URL is `https://raw.githubusercontent.com/sgossner/VCSL/<revision>/<URL-encoded path>`. The sources comprise piano, folk harp, strumstick, alto recorder, marimba, vibraphone, cajon, wood clicks, shaker, claves and bass drum.

All files below are under `assets/audio/`. Each has the same original-score + CC0 VCSL origin described above.

| File / state | Composition | Identity | Loop length | Structure |
|---|---|---|---:|---|
| `theme_menu.wav` | House Rules | A winking clubhouse shuffle: brushed wood, piano sixths, vibraphone call-and-response. | 68.571 s | 112 BPM; ABACABCA, 32 bars |
| `theme_tutorial.wav` | First Putt | Unhurried four-bar questions, soft marimba and open harp voicings; room for instructions. | 43.636 s | 88 BPM; ABAC, 16 bars |
| `theme_meadow.wav` | Clover Club | Skipping wooden flute over picked harp and light cajon, with a sunny answering phrase. | 54.340 s | 106 BPM; ABACBA, 24 bars |
| `theme_desert.wav` | Dry Bank | A dry 3+2+2 pulse, plucked strumstick and low wooden percussion with spacious modal phrases. | 52.500 s | 96 BPM; ABACBA, 24 bars |
| `theme_autumn.wav` | Last Light | A warm piano waltz with falling phrases, suspended harmony and soft vibraphone answers. | 51.429 s | 84 BPM; ABACBA, 24 bars |
| `theme_snow.wav` | Glass Green | Spare five-beat bell phrases, open fifths and long acoustic tails; no driving drum loop. | 63.158 s | 76 BPM; ABCA, 16 bars |
| `theme_swamp.wav` | Crooked Reeds | An offbeat wooden groove: low marimba, clipped piano ninths and lopsided little replies. | 58.776 s | 98 BPM; ABCABA, 24 bars |
| `theme_volcanic.wav` | Double or Cinders | Driving low piano and timpani-like drum weight, syncopated mallets, a tense contrasting middle. | 58.182 s | 132 BPM; ABACBCAB, 32 bars |

Meters: Title/Tutorial/Meadow/Swamp/Volcanic 4/4; Desert 7/8 grouped 3+2+2; Autumn 3/4; Snow 5/4. Common modifications to source samples: trimmed recording leaders, mono preparation, pitch resampling from verified source roots, note envelopes, restrained timing/gain variation, stereo placement and a short shared room. Note/room tails wrap into the next downbeat. Music outputs are 44.1 kHz stereo 16-bit PCM with shared peak/RMS limits. Instrument retuning occurs inside independent scores, not as an alternative to writing separate tracks.

## Ambience and SFX

Creator of the original arrangements/DSP: A Stroke of Luck project, implemented by Codex. “Original DSP” means code-authored noise/envelopes/resonances, without third-party recordings. Sample-derived cues use the same CC0 VCSL sources above; no separate copyrighted composition was copied.

| Shipped file(s), under `assets/audio/` | Title / use | Origin and modifications |
|---|---|---|
| `ambience_meadow.wav` | Meadow air / birds; 32 s | Original cyclic broadband air and sparse birdlike chirps |
| `ambience_desert.wav` | Desert wind / sand; 34 s | Original dry air and sparse granular swells |
| `ambience_autumn.wav` | Autumn wind / leaves; 36 s | Original softer air and leaf-shaped noise envelopes |
| `ambience_snow.wav` | Snow cold air; 38 s | Original brighter wind/ice-like grains |
| `ambience_swamp.wav` | Swamp insects / frogs; 40 s | Original insect-noise modulation and low organic calls |
| `ambience_volcanic.wav` | Volcanic rumble / crackle; 42 s | Original low broadband rumble and sparse hot transients |
| `golf_strike.wav` | Club/ball strike | CC0 wood click + original sharp broadband transient; short physical body |
| `wall_impact.wav` | Wall tap/knock | CC0 wood click + original filtered impact; runtime gain follows strength |
| `high_speed_swoosh.wav` | High-speed air; 4 s | Original cyclic broadband noise, no periodic rolling pitch |
| `water.wav` | Splash/plop | Original noise splash and pressure-decaying bubble resonances |
| `lava.wav` | Hot hiss/crackle | Original noise transient and low impact body |
| `ice_impact.wav` | Crisp ice scrape | Original high-frequency grain + CC0 claves transient |
| `cup_sink.wav` | Ball into cup | Three decaying CC0 wood contacts |
| `purchase.wav` | Previous coin/register reward; retained offline-render bank output, no longer selected at runtime | CC0 vibraphone coin-like hits and wood register transient |
| `curse.wav` | Dark secondary card accent | Reversed CC0 piano envelope and paper-like wood transient |
| `card_stack.wav` | Stack increment | CC0 claves + original short grain |
| `ui_hover.wav` | Hover/focus | CC0 shaker + original brief air transient |
| `ui_click.wav`, `ui_back.wav` | Action/return | CC0 wood clicks, filtered and separately enveloped |
| `ui_error.wav` | Rejected/unaffordable action | Paired CC0 wood contacts |
| `hole_completion.wav` | Hole success | Original three-note CC0 vibraphone accent |
| `biome_transition.wav` | Biome arrival | Original four-note CC0 vibraphone signpost |
| `final_run_completion.wav` | Eighteen-hole completion | Original longer CC0 vibraphone/piano cadence |

`assets/audio/terrain_impact.wav` is the **preserved human-preferred sand cue**, synthesized in the project's earlier audio generator. It is not a VCSL recording and was not regenerated in this migration. SHA-256: `2e371ca8e048dd0ebca67bad303a77a4426ee67e933032484bd568427ad66de4`.

## Focused human-playtest crowd and purchase cues

These three additions do not replace or regenerate the eight compositions, ambience, sand or supplied boost/failure assets. Source pages explicitly identify CC0; the Kenney archive also contains a verified CC0 `License.txt`. `tools/render_playtest_audio.py` checks pinned source SHA-256 before reading audio, and `playtest_audio_manifest.json` records exact source/output hashes and modifications.

| Runtime file | Title / creator | Source and license | Modifications |
|---|---|---|---|
| `crowd_success.wav` (2.800 s) | Applause in a large hall or church / eXpl0it3r | [OpenGameArt source](https://opengameart.org/content/applause-in-a-large-hall-or-church), CC0 | 0.4–3.2 s excerpt of the original WAV, onset/release fades, DC removal, peak normalization; a restrained hole crowd, not a championship sting |
| `crowd_failure.wav` (1.997 s) | aww.wav / phmiller42 | [Freesound source](https://freesound.org/people/phmiller42/sounds/124996/), CC0 | Public HQ MP3 preview decoded to PCM, edge fades, DC removal and normalization; original source is a small audience pity/moan reaction |
| `purchase_coins.wav` (0.850 s) | Casino Audio 1.1 / Kenney, with original project register-bell DSP | [Kenney source](https://kenney.nl/assets/casino-audio), CC0 for the incorporated recordings | `Audio/chips-handle-2.ogg` + `Audio/chips-collide-2.ogg`, mono mix, short original inharmonic register bell, fades and normalization, baked into one purchase cue |

Download locations used: [applause WAV](https://opengameart.org/sites/default/files/applause-clapping-church-crowd-immersive.wav), [public aww HQ preview](https://cdn.freesound.org/previews/124/124996_687791-hq.mp3), [Casino Audio archive](https://kenney.nl/media/pages/assets/casino-audio/2472606a04-1721639069/kenney_casino-audio.zip). No third-party code or executable is used; the archive is read in memory for its license and two audio entries only. Source cache: `user://audio_sources/human_fix/` (`applause.wav`, `aww.mp3`, `casino.zip`).

To reproduce only these cues, run `python tools/render_playtest_audio.py --source-dir <absolute Godot user audio_sources/human_fix path>`, then `python tools/verify_audio_assets.py`. The source recording called a large hall/church is not presented as a golf-course field recording; the casino recordings are chips, augmented with the original bell for a purchase identity. Human listening must still judge the final mix.

## Project-owner-supplied WAV files

These five files were supplied directly by the project owner. The renderer refuses to modify them and verifies their SHA-256 before and after regeneration. No source URL, creator metadata beyond “project owner supplied,” or separate license statement was provided; this document does not invent one.

| File | Intended use | Supplied provenance | SHA-256 |
|---|---|---|---|
| `assets/audio/boost_pad_slow.wav` | Low-strength bounce/boost-pad response | Supplied directly by project owner; source URL/license not provided | `2ebf220b4d1b9cedd3e2a42af1739e105c14f1877e1bddb80145124a61f38cc1` |
| `assets/audio/boost_pad_med.wav` | Medium-strength bounce/boost-pad response | Supplied directly by project owner; source URL/license not provided | `2915a27ba866acbad3ed8ccfc2488a6ae5cece5aea1f06bb584e33fc3d25e996` |
| `assets/audio/boost_pad_fast.wav` | High-strength bounce/boost-pad response | Supplied directly by project owner; source URL/license not provided | `c872e472f03c01380daab3686fce0ff8d5047819bcc9fe1d0b396b7fc8876b12` |
| `assets/audio/fail_sound_1.wav` | First layer of the simultaneous forced-hole/failure response | Supplied directly by project owner; source URL/license not provided | `7a41c6a80596db9ae26e44dae5498905bedab6a77889eca963ac2a14aa50da1b` |
| `assets/audio/fail_sound_2.wav` | Second layer of the simultaneous forced-hole/failure response | Supplied directly by project owner; source URL/license not provided | `f5d2ac2b046e7f9277dde0dcd55e341e7177d0c792bf5740f94fd80ba46e8292` |

## Reproduction and review

Windows development commands (NumPy and SoundFile are offline-render dependencies, not runtime dependencies):

```powershell
$env:PYTHONDONTWRITEBYTECODE = '1'
python tools/fetch_audio_samples.py
python tools/generate_audio_assets.py
python tools/verify_audio_assets.py
```

The downloader fetches pinned WAV data only, verifies expected length and Git blob SHA-1, and preserves unexpected existing files. The cache lives under Godot's `user://audio_sources/vcsl/`, outside shipped resources. The renderer verifies source hashes again and refuses to replace any of the six protected cues. The independent verifier reopens PCM and checks hashes, headroom, non-silence, score bar lengths, distinct files and non-anomalous loop boundaries. No cache, Python runtime or network dependency is used by the game.

The short inspiration pass considered deliberate constraints, a small shared palette and varied breathing room, including [Disasterpeace's discussion of restrictions](https://designingsound.org/2015/10/12/interview-with-rich-vreeland-disasterpeace-on-restrictions/). No reference-game soundtrack audio or compositions were incorporated.

**Human listening is pending.** Licensing and clean signal measurements do not approve melody, pacing, physical believability, balance or fatigue. The five supplied files remain existing owner-authorized project inputs; their absent external license details are not fabricated here and should be confirmed by the owner before external distribution.
