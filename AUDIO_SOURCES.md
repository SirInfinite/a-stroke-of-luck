# Audio Sources and Provenance

This file records the origin and intended use of audio distributed with **A Stroke of Luck**. It distinguishes project-owner-supplied recordings from original generated assets. No downloaded third-party audio is currently included.

## Project-owner-supplied WAV files

These five files were supplied directly by the project owner. They are intentionally excluded from `tools/generate_audio_assets.py` so regeneration cannot replace or modify them. No source URL, creator metadata beyond “project owner supplied,” or separate license statement was provided; this document does not invent one.

| File | Intended use | Supplied provenance | SHA-256 |
|---|---|---|---|
| `assets/audio/boost_pad_slow.wav` | Low-strength bounce/boost-pad response | Supplied directly by project owner; source URL/license not provided | `2ebf220b4d1b9cedd3e2a42af1739e105c14f1877e1bddb80145124a61f38cc1` |
| `assets/audio/boost_pad_med.wav` | Medium-strength bounce/boost-pad response | Supplied directly by project owner; source URL/license not provided | `2915a27ba866acbad3ed8ccfc2488a6ae5cece5aea1f06bb584e33fc3d25e996` |
| `assets/audio/boost_pad_fast.wav` | High-strength bounce/boost-pad response | Supplied directly by project owner; source URL/license not provided | `c872e472f03c01380daab3686fce0ff8d5047819bcc9fe1d0b396b7fc8876b12` |
| `assets/audio/fail_sound_1.wav` | First layer of the simultaneous forced-hole/failure response | Supplied directly by project owner; source URL/license not provided | `7a41c6a80596db9ae26e44dae5498905bedab6a77889eca963ac2a14aa50da1b` |
| `assets/audio/fail_sound_2.wav` | Second layer of the simultaneous forced-hole/failure response | Supplied directly by project owner; source URL/license not provided | `f5d2ac2b046e7f9277dde0dcd55e341e7177d0c792bf5740f94fd80ba46e8292` |

## Original programmatically generated audio

All other WAV files under `assets/audio/` are original deterministic compositions or sound designs generated from code in `tools/generate_audio_assets.py`. The generator uses only Python’s standard library and mathematical waveform/noise synthesis; it reads no samples and downloads no source material.

The generated set includes:

- eight distinct melodic loops: title, tutorial, Meadow, Desert, Autumn, Snow, Swamp, and Volcanic;
- six biome ambience loops: wind/birds, dry wind, leaves, icy wind/chimes, wet insects/bubbles, and volcanic rumble/crackle;
- physical-action cues for golf strike, high-speed wind/swoosh, water, cup/drop, purchase, UI, terrain/sand, progression, and completion.

`assets/audio/terrain_impact.wav` remains the existing intended sand sound. The shipping pass did not replace its synthesis or semantic mapping.

### Original music manifest

These compositions share a restrained synthetic palette, but each has its own meter, form, melody, harmony, bass motion, and percussion arrangement. The source is the repository generator rather than an online recording, so there is no external source URL or third-party modification chain.

| File | Track title | Creator | Source | License / distribution status | Modifications |
|---|---|---|---|---|---|
| `assets/audio/theme_menu.wav` | Lucky on the Turn | A Stroke of Luck project | `tools/generate_audio_assets.py` (`lucky_waltz`) | Original project asset; no third-party material | Deterministic 3/4 synthesis, mastered to the shared music peak |
| `assets/audio/theme_tutorial.wav` | Practice Makes Par | A Stroke of Luck project | `tools/generate_audio_assets.py` (`practice_steps`) | Original project asset; no third-party material | Deterministic 4/4 instructional motif and metronome-like accents |
| `assets/audio/theme_meadow.wav` | Open Fairway | A Stroke of Luck project | `tools/generate_audio_assets.py` (`open_fairway`) | Original project asset; no third-party material | Deterministic bright 4/4 pluck arrangement with moving arpeggio |
| `assets/audio/theme_desert.wav` | Seven-Step Caravan | A Stroke of Luck project | `tools/generate_audio_assets.py` (`seven_step_caravan`) | Original project asset; no third-party material | Deterministic 7/8 reed/drone arrangement with asymmetric frame-drum pulse |
| `assets/audio/theme_autumn.wav` | Leaves on the Green | A Stroke of Luck project | `tools/generate_audio_assets.py` (`leaf_ballad`) | Original project asset; no third-party material | Deterministic mellow 3/4 mallet ballad with counterline |
| `assets/audio/theme_snow.wav` | Crystal Air | A Stroke of Luck project | `tools/generate_audio_assets.py` (`crystal_air`) | Original project asset; no third-party material | Deterministic sparse 5/4 bell composition with long air tones |
| `assets/audio/theme_swamp.wav` | Bog Shuffle | A Stroke of Luck project | `tools/generate_audio_assets.py` (`bog_shuffle`) | Original project asset; no third-party material | Deterministic slow compound-meter reed/marimba shuffle |
| `assets/audio/theme_volcanic.wav` | Magma Drive | A Stroke of Luck project | `tools/generate_audio_assets.py` (`magma_drive`) | Original project asset; no third-party material | Deterministic driving 4/4 ostinato, tom pattern, and minor-mode motif |

## Reusable-audio research not incorporated

The refinement pass reviewed clearly reusable options before choosing original generated loops for a cohesive eight-theme set and deterministic repository regeneration. No audio was downloaded or copied from these references:

| Reference | Listed creator | Listed license | URL |
|---|---|---|---|
| Digital Audio pack | Kenney | Creative Commons CC0 | https://kenney.nl/assets/digital-audio |
| Menu Loop | Akikazer | CC0 | https://opengameart.org/content/menu-loop |
| Desert Travel (Loop) | DJ CrisP | CC0 | https://opengameart.org/content/desert-travel-loop |
| Snow Theme / Through the Snow | Cleyton Kauffman | CC0 | https://opengameart.org/content/snow-theme |
| Swamp Theme Loop | beardalaxy | CC0 | https://opengameart.org/content/swamp-theme-loop |

Because these files are not part of the repository, their licenses impose no attribution or redistribution requirements on this project’s current audio set.
