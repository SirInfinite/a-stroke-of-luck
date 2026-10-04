"""Export reviewed original raster sheets; no procedural artwork generation.

The owner explicitly permits coding tools to assist asset production. This tool
only crops the generated source sheets, removes transparent gutters, chooses
the sample's pixel density, and exports nearest-neighbour PNGs. Source pixels
and their provenance remain available for review.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2] / "assets" / "pixel_sample"
manifest = []


def export(source, box, name, size, opaque=False, trim=False):
    image = Image.open(ROOT / "source" / source).convert("RGBA").crop(box)
    if opaque:
        image.putalpha(255)
    else:
        image.putalpha(image.getchannel("A").point(lambda a: 255 if a >= 110 else 0))
    if trim:
        bounds = image.getbbox()
        if bounds:
            image = image.crop(bounds)
    if isinstance(size, int):
        ratio = size / max(image.size)
        size = tuple(max(1, round(v * ratio)) for v in image.size)
    image = image.resize(size, Image.Resampling.NEAREST)
    target = ROOT / (name + ".png")
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)
    manifest.append({"file": str(target.relative_to(ROOT)), "source": source,
                     "crop": box, "size": image.size,
                     "sha256": hashlib.sha256(target.read_bytes()).hexdigest()})


# Boundaries measured from the generated sheet, which did not obey requested
# 1024 dimensions. Source dimensions and rectangles are explicit, not assumed.
xs = [0, 313, 627, 940, 1254]
ys = [0, 313, 627, 916, 1254]
tiles = ["fairway_a", "fairway_b", "green_a", "green_b", "water_a", "water_b",
         "sand_a", "sand_b", "wall_h", "wall_v", "wall_join", "garden"]
for index, name in enumerate(tiles):
    x, y = index % 4, index // 4
    export("meadow_atlas.png", (xs[x] + 2, ys[y] + 2, xs[x+1] - 2, ys[y+1] - 2),
           "terrain/" + name, (50, 50), opaque=True)
for x, name in enumerate(["willow", "flowers", "lotus", "sign"]):
    export("meadow_atlas.png", (xs[x] + 3, 921, xs[x+1] - 3, 1254),
           "props/" + name, 112, trim=True)

objects = [("pendulum", (26, 13, 358, 378), 64),
           ("chain", (444, 48, 661, 371), 24),
           ("pivot", (738, 64, 1045, 370), 40),
           ("ball", (1170, 137, 1364, 330), 16),
           ("flag_a", (101, 385, 330, 710), 64),
           ("flag_b", (439, 385, 675, 710), 64),
           ("tee", (765, 470, 1025, 680), 32),
           ("pad", (1115, 432, 1415, 713), 48),
           ("coin", (42, 725, 328, 1064), 32),
           ("bag", (435, 715, 695, 1085), 80),
           ("strike", (750, 778, 1080, 1080), 48),
           ("dust", (1100, 755, 1447, 1084), 48)]
for name, rect, size in objects:
    export("objects_atlas.png", rect, "props/" + name, size, trim=True)

for index, name in enumerate(["overdrive_driver", "sand_cleats", "coin_magnet", "rangefinder_lens"]):
    x, y = index % 2, index // 2
    export("card_illustrations.png", (x*627, y*627, (x+1)*627, (y+1)*627),
           "cards/" + name, (144, 144), opaque=True)

ui = Image.open(ROOT / "source" / "ui_atlas.png")
w, h = ui.size
for index, name in enumerate(["felt", "card", "benefit", "curse", "gold_button", "teal_button", "scorepaper", "epic_card"]):
    x, y = index % 4, index // 4
    export("ui_atlas.png", (round(x*w/4), round(y*h/2), round((x+1)*w/4), round((y+1)*h/2)),
           "ui/" + name, (64, 64))
export("wordmark.png", (20, 45, 1515, 960), "ui/wordmark", 600, trim=True)
landscape = Image.open(ROOT / "source" / "title_landscape.png")
export("title_landscape.png", (0, 0, *landscape.size), "ui/title_landscape", (960, 540), opaque=True)

sources = [{"file": p.name, "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
            "size": Image.open(p).size} for p in sorted((ROOT / "source").glob("*.png"))]
(ROOT / "export_manifest.json").write_text(json.dumps({"sources": sources, "exports": manifest}, indent=2) + "\n")
print(f"Exported {len(manifest)} original raster assets.")
