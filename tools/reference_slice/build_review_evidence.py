"""Labelled comparison evidence and read-only preservation audit for the approval slice."""
from pathlib import Path
import hashlib
import json
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/reference_review"
FONT = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 18)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


baseline = json.loads((OUT / "pre_edit_hashes.json").read_text())
changed = [p for p, digest in baseline.items() if not (ROOT / p).exists() or sha(ROOT / p) != digest]
sources = json.loads((OUT / "source_inventory.json").read_text())
reference_changes = [p["path"] for p in sources if sha(ROOT / p["path"]) != p["sha256"]]
groups = {}
for group in ["world", "ui", "audio"]:
    files = [p for p in (ROOT / "assets/reference_slice" / group).rglob("*") if p.is_file() and p.suffix not in {".import", ".uid"}]
    runtime = [p for p in files if "source" not in p.relative_to(ROOT / "assets/reference_slice" / group).parts and p.suffix in {".png", ".ogg", ".ttf"}]
    groups[group] = {"files": len(files), "all_bytes": sum(p.stat().st_size for p in files), "runtime_files": len(runtime), "runtime_bytes": sum(p.stat().st_size for p in runtime)}
preservation = {"baseline_files": len(baseline), "changed": changed, "unexpected_changes": [p for p in changed if p != "export_presets.cfg"], "reference_count": len(sources), "reference_changes": reference_changes, "assets": groups}
(OUT / "preservation.json").write_text(json.dumps(preservation, indent=2))


def sheet(items, name, cols=3, width=640, height=410):
    result = Image.new("RGB", (cols * width, ((len(items) + cols - 1) // cols) * height), "#101b22")
    draw = ImageDraw.Draw(result)
    for n, (label, path) in enumerate(items):
        if not path.exists():
            continue
        im = Image.open(path).convert("RGB")
        im.thumbnail((width - 10, height - 48))
        x, y = (n % cols) * width, (n // cols) * height
        result.paste(im, (x + 5, y + 5))
        draw.text((x + 8, y + height - 40), label, font=FONT, fill="#fff0cb")
    result.save(OUT / name)


for name, source, before, after in [
    ("world_comparison.jpg", "ss_2180c7021aa89135fcb5fbfc0f5e5ceff5d4f42a.1920x1080.jpg", "02_hole", "02_meadow_48"),
    ("shop_comparison.jpg", "ss_67b19c56802de57a61d4643e18c14a940ee60360.1920x1080.jpg", "05_shop", "05_shop_easy"),
]:
    sheet([("REFERENCE ONLY - Grandpa Golf", ROOT / "assets/references" / source), ("BEFORE - previous correction sample", OUT / "before" / (before + ".png")), ("REVISED - actual Godot approval scene", OUT / "final_1080" / (after + ".png"))], name)

# Source crops keep nearby context, and retain exact source identities in metadata.
crops = [
    ("course_edge_reference.png", "ss_2180c7021aa89135fcb5fbfc0f5e5ceff5d4f42a.1920x1080.jpg", (200, 480, 1500, 1010)),
    ("item_reference.png", "ss_d2ca6ce182fd4edbae96056d4a0fd01552d8c6ee.1920x1080.jpg", (230, 100, 1380, 880)),
    ("shop_reference.png", "ss_67b19c56802de57a61d4643e18c14a940ee60360.1920x1080.jpg", (200, 180, 1770, 970)),
]
for name, source, rect in crops:
    im = Image.open(ROOT / "assets/references" / source).crop(rect)
    labelled = Image.new("RGB", (im.width, im.height + 55), "#101b22")
    labelled.paste(im)
    ImageDraw.Draw(labelled).text((8, im.height + 8), "REFERENCE ONLY - " + source, font=FONT, fill="#fff0cb")
    labelled.save(OUT / name)

movie = OUT / "revised.mp4"
if movie.exists():
    frames = OUT / "implemented_motion"
    frames.mkdir(exist_ok=True)
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(movie), "-vf", "fps=0.5", "-y", str(frames / "overview_%03d.png")], check=True)
    sheet([(f"REVISED {i*2:02d}s | real scripted golf", p) for i,p in enumerate(sorted(frames.glob("overview_*.png")))], "implemented_motion_overview.jpg", cols=3)
    for name, start, duration in [("impact", 12.2, .65), ("cup", 20.6, 1.0), ("purchase", 25.8, .9), ("water", 31.0, .7)]:
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-ss", str(start), "-i", str(movie), "-t", str(duration), "-vf", "fps=10", "-y", str(frames / (name + "_%03d.png"))], check=True)
        sheet([(f"REVISED {name} {start+i*.1:.1f}s", p) for i,p in enumerate(sorted(frames.glob(name + "_*.png")))], name + "_sequence.jpg", cols=3, width=480, height=310)
print(json.dumps(preservation, indent=2))
if preservation["unexpected_changes"] or reference_changes:
    raise SystemExit("Preservation audit failed")
