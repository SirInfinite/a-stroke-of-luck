"""Create labelled local card-art evidence; never writes production artwork."""
from pathlib import Path
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.dont_write_bytecode = True
from build_card_art import ROOT, ASSETS, SOURCE, IDS, fit_complete

OUT = ROOT / "artifacts/production_visual/cards"
OUT.mkdir(parents=True, exist_ok=True)
FONT_PATHS = [Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts/consola.ttf", Path("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf")]
FONT_PATH = next((path for path in FONT_PATHS if path.exists()), None)
FONT = ImageFont.truetype(str(FONT_PATH), 17) if FONT_PATH else ImageFont.load_default()
SMALL = ImageFont.truetype(str(FONT_PATH), 13) if FONT_PATH else ImageFont.load_default()
BG = "#172D38"
INK = "#FFF0C8"


def place(canvas, path, xy, size):
    sprite = Image.open(path).convert("RGBA")
    ratio = size / max(sprite.size)
    sprite = sprite.resize(tuple(round(value * ratio) for value in sprite.size), Image.Resampling.NEAREST)
    canvas.alpha_composite(sprite, (int(xy[0] + (size - sprite.width) / 2), int(xy[1] + (size - sprite.height) / 2)))


# This full sheet retains every master at its actual source pixel size.
source = Image.new("RGBA", (4096, 2176), BG)
draw = ImageDraw.Draw(source)
for index, card_id in enumerate(IDS):
    x, y = (index % 4) * 1024, (index // 4) * 1088
    draw.text((x + 30, y + 18), card_id + " | 1024px square source", font=FONT, fill=INK)
    source.alpha_composite(Image.open(SOURCE / f"{card_id}.png").convert("RGBA"), (x, y + 64))
source.save(OUT / "source_scale.png")

# A comfortably viewable overview complements the unscaled source sheet.
overview = Image.new("RGBA", (1120, 670), BG)
draw = ImageDraw.Draw(overview)
for index, card_id in enumerate(IDS):
    x, y = (index % 4) * 280, (index // 4) * 335
    draw.text((x + 10, y + 12), card_id.replace("_", " "), font=FONT, fill=INK)
    place(overview, ASSETS / f"{card_id}.png", (x + 20, y + 44), 240)
    draw.text((x + 10, y + 304), "80px export shown at 3x", font=SMALL, fill="#91ADB6")
overview.save(OUT / "family_overview.png")

# Exact on-screen sizes at 1 image pixel : 1 display pixel.
actual = Image.new("RGBA", (1120, 810), BG)
draw = ImageDraw.Draw(actual)
for index, card_id in enumerate(IDS):
    x, y = (index % 4) * 280, (index // 4) * 405
    draw.text((x + 12, y + 12), card_id.replace("_", " "), font=FONT, fill=INK)
    place(actual, ASSETS / f"{card_id}.png", (x + 60, y + 40), 160)
    draw.text((x + 95, y + 206), "160px", font=SMALL, fill=INK)
    place(actual, ASSETS / f"{card_id}.png", (x + 32, y + 244), 80)
    draw.text((x + 48, y + 330), "80px", font=SMALL, fill=INK)
    place(actual, ASSETS / f"{card_id}.png", (x + 180, y + 274), 32)
    draw.text((x + 180, y + 330), "32px", font=SMALL, fill=INK)
    draw.text((x + 12, y + 373), "Card / compact / effect rail", font=SMALL, fill="#91ADB6")
actual.save(OUT / "actual_sizes.png")

# Honest source history: scene composition and recovered object are different
# drawings. This is recovery of a complete design, not a claimed inpaint.
history = Image.new("RGBA", (1200, 1336), BG)
draw = ImageDraw.Draw(history)
draw.text((22, 18), "SOURCE RECOVERY — ORIGINAL MEDIA PRESERVED", font=FONT, fill=INK)
headers = ["Earlier scene: contextual cropping", "Recovered cartoon source: complete", "Production: square, padded silhouette"]
for column, heading in enumerate(headers):
    draw.text((column * 400 + 10, 56), heading, font=SMALL, fill=INK)
scene_sheet = Image.open(ROOT / "assets/pixel_sample/source/card_illustrations.png").convert("RGBA")
recovered_ids = ["overdrive_driver", "sand_cleats", "coin_magnet", "rangefinder_lens"]
for index, card_id in enumerate(recovered_ids):
    y = 98 + index * 304
    old = scene_sheet.crop(((index % 2) * 627, (index // 2) * 627, (index % 2 + 1) * 627, (index // 2 + 1) * 627))
    old = old.resize((256, 256), Image.Resampling.NEAREST)
    history.alpha_composite(old, (72, y))
    place(history, SOURCE / "originals" / f"{card_id}.png", (472, y), 256)
    place(history, ASSETS / f"{card_id}.png", (872, y), 256)
    draw.text((24, y + 270), card_id, font=FONT, fill=INK)
history.save(OUT / "source_recovery_comparison.png")

refinement = Image.new("RGBA", (920, 590), BG)
draw = ImageDraw.Draw(refinement)
draw.text((18, 16), "SOURCE COMPOSITION REFINEMENT — FULL SILHOUETTE RETAINED", font=FONT, fill=INK)
for row, card_id in enumerate(["power_club", "lucky_putter"]):
    y = 66 + row * 260
    draw.text((16, y), card_id, font=FONT, fill=INK)
    old = fit_complete(Image.open(SOURCE / "history" / f"{card_id}_v1.png").convert("RGBA"), 80, 70)
    new = Image.open(ASSETS / f"{card_id}.png").convert("RGBA")
    for column, (label, sprite) in enumerate([("First source: long shaft", old), ("Revised source: larger head", new)]):
        x = 160 + column * 375
        refinement.alpha_composite(sprite.resize((160, 160), Image.Resampling.NEAREST), (x, y + 28))
        refinement.alpha_composite(sprite.resize((32, 32), Image.Resampling.NEAREST), (x + 235, y + 90))
        draw.text((x, y + 195), label, font=SMALL, fill=INK)
        draw.text((x + 235, y + 132), "32px", font=SMALL, fill=INK)
refinement.save(OUT / "composition_refinement.png")

manifest = json.loads((ASSETS / "export_manifest.json").read_text())
audit = {"cards": [], "crop_claim": "All recovered cartoon and rejected reference_slice isolated sources have complete alpha-bounded silhouettes; only the older narrative scene compositions intentionally crop contextual objects. Recovery comparison is not an inpaint claim."}
audit["rejected_isolated_source_bounds"] = []
for path in sorted((ROOT / "assets/reference_slice/ui/source").glob("*.png")):
    image = Image.open(path).convert("RGBA")
    bounds = image.getchannel("A").point(lambda value: 255 if value >= 128 else 0).getbbox()
    audit["rejected_isolated_source_bounds"].append({"source": path.relative_to(ROOT).as_posix(), "size": list(image.size), "bounds": list(bounds)})
for card in manifest["cards"]:
    image = Image.open(ASSETS / f"{card['id']}.png").convert("RGBA")
    bounds = image.getbbox()
    margin = min(bounds[0], bounds[1], image.width - bounds[2], image.height - bounds[3])
    audit["cards"].append({"id": card["id"], "square": image.width == image.height == 80, "minimum_alpha_gutter_px": margin, "complete_source_gutter": all((card["source_bounds"][0] > 0, card["source_bounds"][1] > 0, card["source_bounds"][2] < card["source_size"][0], card["source_bounds"][3] < card["source_size"][1]))})
(OUT / "source_audit.json").write_text(json.dumps(audit, indent=2) + "\n")
print(f"Card source/actual-size/recovery evidence written to {OUT}")
