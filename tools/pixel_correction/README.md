# Play and compare the art correction

Open [review.html](review.html) for directly matched screenshots, four-item comparisons and synchronized movies. Both sides use the same authored Meadow hole, seed 9102026, native shot outcomes, shop offers and audio. A is the previous **pixel-art sample**, not the earlier production vector treatment.

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/pixel_correction/launch_sample.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/pixel_correction/launch_sample.ps1 -Previous
```

The first command plays B (arcade correction); `-Previous` plays A. `-Resolution` accepts 1280x720, 1600x900, 1920x1080, 2560x1440 and 3440x1440. `-GodotPath` selects the existing Godot 4.6.2 executable when necessary.

PLAY SAMPLE enters the hole. Mouse drag/release and configured keyboard shooting remain native. Tab toggles overview; Escape/Menu pauses. F5 retries, F7 opens the shop, F8 returns to title. The prior soundtrack shortcuts 1/2 remain available. REPLAY SAMPLE resets this review fixture and its wallet.

The production entrypoint stays `scenes/main.tscn`. The previous sample's launcher and review page still work. No full biome rollout, gameplay revision, logo redesign, commit, export or approval is implied.

## Reproduce the evidence

Run captures sequentially so offline encoding does not interfere with the existing wall-clock audio notification guard. Select fresh output paths to retain earlier evidence.

```powershell
godot4 --path . --rendering-method gl_compatibility --fixed-fps 60 --quit-after 2000 --write-movie artifacts/pixel_correction/previous.avi res://tools/pixel_correction/correction.tscn -- --correction-previous --sample-record --sample-output=res://artifacts/pixel_correction/previous
godot4 --path . --rendering-method gl_compatibility --fixed-fps 60 --quit-after 2000 --write-movie artifacts/pixel_correction/revised.avi res://tools/pixel_correction/correction.tscn -- --sample-record --sample-output=res://artifacts/pixel_correction/revised
```

Use the existing FFmpeg installation to encode each AVI with `-c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart`. `verify_artifacts.py --ffmpeg <path>` checks the resulting MP4s, replay parity, actual outcomes, cue counts, screenshots and raster contracts.

`--sample-gallery` captures title, overview and both shop appearances. `--sample-checks` runs the prior sample's actual input/lifecycle/purchase/disclosure checks with the new skin. `--sample-size=1280x720` selects a small viewport. Choose a separate `--sample-output=res://artifacts/pixel_correction/<folder>` for each run.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .codex/skills/godot-verify/scripts/verify_godot.ps1
python tools/pixel_correction/protect_sources.py
```

The source preservation check uses the local snapshot taken before editing. It protects production scripts, scenes, data, assets, tests, settings and the approved logo; only two small factory seams in the previous sample harness are allowed to differ. Do not replace that snapshot to conceal a failed preservation check.

The asset export command is `godot4 --headless --path . --script res://tools/pixel_correction/export_assets.gd`. It is source tooling, not part of game startup.

See [the review record](../../docs/PIXEL_CORRECTION_REVIEW.md) for the style analysis, evidence and human checklist.
