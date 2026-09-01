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

- seven melodic loops: menu, Meadow, Desert, Autumn, Snow, Swamp, and Volcanic;
- six biome ambience loops: wind/birds, dry wind, leaves, icy wind/chimes, wet insects/bubbles, and volcanic rumble/crackle;
- physical-action cues for golf strike, high-speed wind/swoosh, water, cup/drop, purchase, UI, terrain/sand, progression, and completion.

`assets/audio/terrain_impact.wav` remains the existing intended sand sound. The shipping pass did not replace its synthesis or semantic mapping.

## Reusable-audio research not incorporated

The shipping pass reviewed clearly reusable options before choosing original generated loops for a cohesive seven-theme set and deterministic repository regeneration. No audio was downloaded or copied from these references:

| Reference | Listed creator | Listed license | URL |
|---|---|---|---|
| Digital Audio pack | Kenney | Creative Commons CC0 | https://kenney.nl/assets/digital-audio |
| Menu Loop | Akikazer | CC0 | https://opengameart.org/content/menu-loop |
| Desert Travel (Loop) | DJ CrisP | CC0 | https://opengameart.org/content/desert-travel-loop |
| Snow Theme / Through the Snow | Cleyton Kauffman | CC0 | https://opengameart.org/content/snow-theme |
| Swamp Theme Loop | beardalaxy | CC0 | https://opengameart.org/content/swamp-theme-loop |

Because these files are not part of the repository, their licenses impose no attribution or redistribution requirements on this project’s current audio set.
