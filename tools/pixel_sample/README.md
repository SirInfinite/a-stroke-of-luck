# Play the presentation sample

From the repository root with the existing Godot 4.6.2 installation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/pixel_sample/launch_sample.ps1
```

`-Original` opens the original presentation around the identical review fixture. `-Track B` starts the alternative soundtrack. `-Resolution 1280x720`, `1920x1080`, `2560x1440` or `3440x1440` sets the review window. Supply `-GodotPath` if `godot4` is not on PATH.

PLAY SAMPLE starts the hole. Mouse drag/release and configured keyboard aiming/shooting remain the game's controls. Tab toggles overview, Escape/Menu pauses. F5 retries the fixture, F7 opens its shop, F8 opens the title; 1/2 selects or replays soundtrack candidates. After a purchase, REPLAY SAMPLE starts the same hole afresh with the review wallet. This is an approval fixture, not a production progression/economy change. The ordinary project entrypoint remains `scenes/main.tscn`.

Open `review.html` for before/after movies, images and playable music excerpts. See `docs/PIXEL_SAMPLE_REVIEW.md` for evidence and limitations, `docs/PIXEL_SAMPLE_REFERENCES.md` for observed reference lessons, and `assets/pixel_sample/PROVENANCE.md` for source/export details.

Reproduce a fixed 60 Hz movie:

```powershell
godot4 --path . --rendering-method gl_compatibility --fixed-fps 60 --quit-after 1850 --write-movie artifacts/pixel_sample/after.avi res://tools/pixel_sample/pixel_sample.tscn -- --sample-after --sample-record --sample-output=res://artifacts/pixel_sample/after
```

Omit `--sample-after` and choose baseline output paths for the original. `--sample-gallery` captures title/course/dark-shop/light-shop without replaying every shot. `--sample-checks` runs bounded feedback/purchase, keyboard, projection, disclosure and reduced-motion checks; use a separate output folder.
