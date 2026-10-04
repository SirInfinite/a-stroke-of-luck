"""Actual-size type specimens. Analysis only, not game artwork."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[3]
specimens = [
    ("Pixelify Sans / previous candidate", root / "assets/pixel_sample/fonts/PixelifySans.ttf"),
    ("Jersey 10 / compact bold", root / "assets/reference_slice/ui/fonts/Jersey10-Regular.ttf"),
    ("Jersey 15 / compact medium", root / "artifacts/reference_review/ui/Jersey15-Regular.ttf"),
]
image = Image.new("RGB", (1536,840), "#19252b")
draw = ImageDraw.Draw(image)
for index, (name,path) in enumerate(specimens):
    y=index*280
    draw.text((22,y+12),name,fill="#b4c4b2")
    for size,words,offset in [(64,"Buy!   12 Coins   Birdie",40),(38,"Overdrive Driver / Rangefinder Lens",130),(24,"STROKES  02   PAR 4   CURSE 3 HOLES",202)]:
        font=ImageFont.truetype(str(path),size)
        if index==0:
            font.set_variation_by_axes([700])
        draw.text((24,y+offset+3),words,font=font,fill="#070e18",stroke_width=2,stroke_fill="#070e18")
        draw.text((22,y+offset),words,font=font,fill="#ffe34d" if size==64 else "#fff0cf",stroke_width=2 if size>=38 else 0,stroke_fill="#111b27")
image.save(root / "artifacts/reference_review/ui/font_comparison_1080.png")
image.resize((1024,560),Image.Resampling.NEAREST).save(root / "artifacts/reference_review/ui/font_comparison_720.png")
