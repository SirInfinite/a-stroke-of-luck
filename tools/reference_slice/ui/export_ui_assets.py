"""Prepare original generated equipment for the opt-in reference slice.

This is an export step, not a substitute illustration generator. Source artwork
is retained unchanged. The small UI frame is deliberately authored pixel geometry.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / "assets/reference_slice/ui"
ITEMS = ("overdrive_driver", "sand_cleats", "coin_magnet", "rangefinder_lens",
         "heavy_core", "lucky_putter", "power_club", "gust_guard")
manifest = []

for name in ITEMS:
    source = ASSETS / "source" / (name + ".png")
    if not source.exists():
        continue
    image = Image.open(source).convert("RGBA")
    alpha = image.getchannel("A")
    image.putalpha(alpha.point(lambda value: 255 if value >= 112 else 0))
    bounds = image.getbbox()
    cropped = image.crop(bounds)
    for density in (128, 32):
        inset = 7 if density == 128 else 1
        span = density - inset * 2
        factor = span / max(cropped.size)
        size = tuple(max(1, round(value * factor)) for value in cropped.size)
        fitted = cropped.resize(size, Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", (density, density))
        canvas.alpha_composite(fitted, ((density-size[0])//2, (density-size[1])//2))
        destination = ASSETS / "items" / (name + ("_icon" if density == 32 else "") + ".png")
        canvas.save(destination)
        manifest.append({"asset": str(destination.relative_to(ASSETS)), "source": source.name,
                         "source_size": image.size, "crop": bounds, "size": canvas.size,
                         "sha256": hashlib.sha256(destination.read_bytes()).hexdigest()})

def stepped(draw, rect, color, cut=4):
    x0, y0, x1, y1 = rect
    draw.polygon([(x0+cut,y0),(x1-cut,y0),(x1-cut,y0+2),(x1-2,y0+2),
                  (x1-2,y0+cut),(x1,y0+cut),(x1,y1-cut),(x1-2,y1-cut),
                  (x1-2,y1-2),(x1-cut,y1-2),(x1-cut,y1),(x0+cut,y1),
                  (x0+cut,y1-2),(x0+2,y1-2),(x0+2,y1-cut),(x0,y1-cut),
                  (x0,y0+cut),(x0+2,y0+cut),(x0+2,y0+2),(x0+cut,y0+2)], fill=color)

(ASSETS / "frames").mkdir(exist_ok=True)
families = {
    "panel": ((21,30,38,224),(181,164,106,255)),
    "card": ((16,25,32,222),(163,155,113,255)),
    "hover": ((28,43,47,237),(255,231,145,255)),
    "pressed": ((15,23,28,241),(230,177,79,255)),
    "primary": ((43,40,29,238),(247,212,116,255)),
    "disabled": ((24,29,34,230),(95,108,107,255)),
    "focus": ((0,0,0,0),(255,240,181,255)),
    "benefit": ((20,46,43,215),(74,112,95,255)),
    "curse": ((58,27,37,215),(139,76,83,255)),
    "light": ((238,225,179,245),(149,116,68,255)),
    "light_card": ((246,235,204,245),(157,132,87,255)),
}
for name, (fill, rim) in families.items():
    image = Image.new("RGBA", (40,40))
    draw = ImageDraw.Draw(image)
    stepped(draw,(0,0,39,39),(8,14,23,245),6)
    stepped(draw,(1,1,38,37),rim,6)
    stepped(draw,(3,3,36,35),fill,4)
    if name == "focus":
        stepped(draw,(3,3,36,35),(0,0,0,0),4)
    image.save(ASSETS / "frames" / (name + ".png"))
    destination = ASSETS / "frames" / (name + ".png")
    manifest.append({"asset": str(destination.relative_to(ASSETS)),
                     "source": "authored stepped UI frame in export_ui_assets.py",
                     "size": image.size,
                     "sha256": hashlib.sha256(destination.read_bytes()).hexdigest()})

# Semantic rating star: authored pixel icon, not an illustrated inventory item.
(ASSETS / "icons").mkdir(exist_ok=True)
star = Image.new("RGBA", (32,32))
draw = ImageDraw.Draw(star)
draw.polygon([(16,1),(20,11),(31,11),(23,18),(26,30),(16,24),(6,30),
              (9,18),(1,11),(12,11)], fill="#101d2a")
draw.polygon([(16,4),(19,13),(28,13),(21,18),(24,26),(16,21),(8,26),
              (11,18),(4,13),(13,13)], fill="#dfaa45")
draw.polygon([(16,4),(19,13),(16,17),(13,13)], fill="#fff0b0")
draw.polygon([(4,13),(13,13),(16,17),(11,18)], fill="#f8d76d")
draw.polygon([(16,17),(21,18),(24,26),(16,21)], fill="#b47332")
star.save(ASSETS / "icons/star.png")
manifest.append({"asset": "icons/star.png", "source": "authored semantic rating icon in export_ui_assets.py",
                 "size": star.size,
                 "sha256": hashlib.sha256((ASSETS / "icons/star.png").read_bytes()).hexdigest()})

# The wallet coin is a crop of this project's generated magnet illustration.
coin = Image.open(ASSETS / "source/coin_magnet.png").convert("RGBA").crop((792,154,978,354))
coin.putalpha(coin.getchannel("A").point(lambda value:255 if value>=112 else 0))
coin = coin.crop(coin.getbbox())
ratio = 29/max(coin.size)
coin = coin.resize(tuple(round(v*ratio) for v in coin.size),Image.Resampling.NEAREST)
coin_canvas = Image.new("RGBA",(32,32))
coin_canvas.alpha_composite(coin,((32-coin.width)//2,(32-coin.height)//2))
coin_canvas.save(ASSETS / "icons/coin.png")
manifest.append({"asset": "icons/coin.png", "source": "coin_magnet.png",
                 "crop": (792,154,978,354), "size": coin_canvas.size,
                 "sha256": hashlib.sha256((ASSETS / "icons/coin.png").read_bytes()).hexdigest()})

(ASSETS / "export_manifest.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")

# Clearly labelled artist-review sheet, not loaded by the game.
sheet = Image.new("RGB", (1024, 378), (24,32,41))
draw = ImageDraw.Draw(sheet)
for index, name in enumerate(ITEMS):
    path = ASSETS / "items" / (name+".png")
    if not path.exists():
        continue
    item = Image.open(path).resize((224,224), Image.Resampling.NEAREST)
    x = (index % 4)*256
    if index >= 4:
        continue
    sheet.paste(item,(x+16,24),item)
    icon = Image.open(ASSETS / "items" / (name+"_icon.png"))
    sheet.paste(icon,(x+20,281),icon)
    draw.text((x+62,290),name.replace("_"," "),fill=(248,235,204))
draw.text((18,349),"ORIGINAL PRODUCTION ITEMS | 128px source family at 224px; 32px rail versions below",fill=(211,197,157))
sheet.save(ROOT / "artifacts/reference_review/ui/equipment_scale_check.png")
print(f"Exported {len(manifest)} UI rasters including {len(families)} frame variants and 2 semantic icons.")
