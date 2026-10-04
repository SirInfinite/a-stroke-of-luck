# Sample audio credits and modifications

## Soundtrack candidates

**Peppers Funk** and **Rocker Chicks**, by Jason Shaw / Audionautix. Licensed under [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/), as stated on the [official Audionautix licensing page](https://audionautix.com/creative-commons-music). Commercial use within another work is permitted with attribution. See the [official rock catalog](https://audionautix.com/free-music/rock).

- [Peppers Funk original MP3](https://audionautix.com/Music/PepperFunk.mp3): 35.8 seconds; sample A excerpt is the first 30 seconds.
- [Rocker Chicks original MP3](https://audionautix.com/Music/RockerChicks.mp3): 90.1 seconds; sample B excerpt is the first 45 seconds.

Modifications: FFmpeg loudness normalization targeting -18 LUFS / -2 dBTP, resampling to 48 kHz stereo, Vorbis quality 5 for the game; excerpts encoded to MP3 with a 1.5-second closing fade. `mix_manifest.json` records exact source/export hashes and measured normalization output. Reproduction: `python tools/pixel_sample/prepare_audio.py --ffmpeg <existing ffmpeg executable>` with the original MP3s under `artifacts/pixel_sample/references/`.

The original full files are integrated as separate candidates. They are not seamless loops. In this approval scene a composition continues across title/course/results, and A/B selection uses the existing two music voices with a 0.8-second crossfade. Once a candidate ends, press its key again to replay it. No artificial short-loop soundtrack has been installed. Neither candidate is accepted for long-session use; A's short source is especially unsuitable for automatic repetition throughout a run.

The engine recording contains mixed output. Signal levels, duration and scheduling can be measured. **Subjective listening was unavailable:** the Windows Computer Use native helper failed recovery, and there is no tool providing auditory inspection to the agent. No claim is made about listening quality, instrumentation heard, seamless musical phrasing or fatigue. The owner must listen before selection.

## Material impacts

[Impact Sounds 1.0, Kenney](https://kenney.nl/assets/impact-sounds), **CC0**. The archive's complete license is retained in `Kenney-CC0.txt`. Extracted unchanged:

| Sample export | Original archive entry | Role |
|---|---|---|
| `strike.ogg` | `Audio/impactWood_light_000.ogg` | Compact wood contact sample at shot release |
| `wall.ogg` | `Audio/impactPlank_medium_000.ogg` | Timber wall contact, gain follows the existing impact strength |
| `stone.ogg` | `Audio/impactMining_000.ogg` | Pendulum impact; the existing reset outcome remains authoritative |

Archive: [official download](https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip). No third-party script or executable was run. The source identifies material sound effects; its recording technique and subjective physical quality have not been established here.

Purchase, curse/stack, cup, success/failure, sand, boost and utility cues retain the project's existing sources documented in [AUDIO_SOURCES.md](../../../AUDIO_SOURCES.md). The sample delays the secondary curse/stack accent by 0.24 seconds; it does not add a second purchase cue. Master/Music/SFX buses and settings persistence remain owned by the game. Offline Movie Maker captures use unmuted 0 dB buses only for the capture process, without saving those values.
