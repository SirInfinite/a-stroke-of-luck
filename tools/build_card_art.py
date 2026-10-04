"""Export complete original cartoon equipment into one portable production family.

This is a measured crop, alpha cleanup, uniform fit and nearest-neighbor export.
It neither invents missing object parts nor rasterizes the legacy SVG symbols.
The four recovered drawings and four new image-generation originals are retained
under assets/presentation/cards/source/originals; that source folder is ignored
by Godot, while the eight runtime PNGs sit directly in the production directory.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/presentation/cards"
SOURCE = ASSETS / "source"
IDS = (
    "overdrive_driver", "rangefinder_lens", "sand_cleats", "heavy_core",
    "lucky_putter", "power_club", "coin_magnet", "gust_guard",
)
MASTER_SIZE = 1024
MASTER_CONTENT = 896
RUNTIME_SIZE = 80
RUNTIME_CONTENT = 70
RECOVERED = {"overdrive_driver", "rangefinder_lens", "sand_cleats", "coin_magnet"}


def png_bytes(image: Image.Image) -> bytes:
    output = io.BytesIO()
    image.save(output, format="PNG", optimize=True)
    return output.getvalue()


def fit_complete(image: Image.Image, canvas_size: int, content_size: int) -> Image.Image:
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    image.putalpha(alpha)
    bounds = alpha.getbbox()
    if not bounds:
        raise ValueError("Empty equipment source")
    # A touching source edge is a repair obligation, not something padding can fix.
    if bounds[0] == 0 or bounds[1] == 0 or bounds[2] == image.width or bounds[3] == image.height:
        raise ValueError("Source silhouette touches its canvas: inspect and repair the source")
    item = image.crop(bounds)
    ratio = content_size / max(item.size)
    dimensions = tuple(max(1, round(value * ratio)) for value in item.size)
    item = item.resize(dimensions, Image.Resampling.NEAREST)
    output = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    output.alpha_composite(item, ((canvas_size - item.width) // 2, (canvas_size - item.height) // 2))
    return output


def make_outputs() -> tuple[dict[Path, bytes], dict]:
    outputs: dict[Path, bytes] = {}
    records = []
    for card_id in IDS:
        original = SOURCE / "originals" / f"{card_id}.png"
        image = Image.open(original).convert("RGBA")
        source_bounds = image.getchannel("A").point(lambda value: 255 if value >= 128 else 0).getbbox()
        master = fit_complete(image.copy(), MASTER_SIZE, MASTER_CONTENT)
        runtime = fit_complete(image.copy(), RUNTIME_SIZE, RUNTIME_CONTENT)
        master_bytes, runtime_bytes = png_bytes(master), png_bytes(runtime)
        outputs[SOURCE / f"{card_id}.png"] = master_bytes
        outputs[ASSETS / f"{card_id}.png"] = runtime_bytes
        records.append({
            "id": card_id,
            "origin": "recovered pixel_correction cartoon drawing" if card_id in RECOVERED else "new original matching cartoon illustration",
            "source": original.relative_to(ROOT).as_posix(),
            "source_size": list(image.size),
            "source_bounds": list(source_bounds),
            "source_sha256": hashlib.sha256(original.read_bytes()).hexdigest(),
            "master": (SOURCE / f"{card_id}.png").relative_to(ROOT).as_posix(),
            "master_size": list(master.size),
            "master_bounds": list(master.getbbox()),
            "master_sha256": hashlib.sha256(master_bytes).hexdigest(),
            "runtime": (ASSETS / f"{card_id}.png").relative_to(ROOT).as_posix(),
            "runtime_size": list(runtime.size),
            "runtime_bounds": list(runtime.getbbox()),
            "runtime_sha256": hashlib.sha256(runtime_bytes).hexdigest(),
            "runtime_bytes": len(runtime_bytes),
        })
    manifest = {"method": "Complete original objects; binary alpha; centered uniform fit; nearest-neighbor export; no clipped-source padding workaround", "cards": records}
    outputs[ASSETS / "export_manifest.json"] = (json.dumps(manifest, indent=2) + "\n").encode()
    return outputs, manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Read-only deterministic source/output parity and silhouette checks")
    args = parser.parse_args()
    outputs, manifest = make_outputs()
    mismatches = []
    for destination, contents in outputs.items():
        if args.check:
            if not destination.exists() or destination.read_bytes() != contents:
                mismatches.append(destination.relative_to(ROOT).as_posix())
        else:
            destination.parent.mkdir(parents=True, exist_ok=True)
            if not destination.exists() or destination.read_bytes() != contents:
                destination.write_bytes(contents)
    if mismatches:
        print("STALE CARD OUTPUTS:\n" + "\n".join(mismatches))
        return 1
    total_bytes = sum(card["runtime_bytes"] for card in manifest["cards"])
    print(f"CARD {'CHECK' if args.check else 'BUILD'} PASS: 8 complete square sprites, 8 square source masters; {total_bytes:,} runtime bytes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
