"""Check actual replay/media and raster contracts, without judging visual quality."""
from collections import Counter
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets/pixel_correction"
EVIDENCE = ROOT / "artifacts/pixel_correction"
parser = argparse.ArgumentParser()
parser.add_argument("--ffmpeg", required=True)
args = parser.parse_args()
ffprobe = str(Path(args.ffmpeg).with_name("ffprobe.exe"))
checks = []


def check(passed, label):
    checks.append({"passed": bool(passed), "check": label})


manifest = json.loads((ART / "export_manifest.json").read_text())
for entry in manifest["exports"]:
    path = ART / entry["file"]
    im = Image.open(path).convert("RGBA")
    check(hashlib.sha256(path.read_bytes()).hexdigest() == entry["sha256"], "Recorded hash: " + entry["file"])
    check(list(im.size) == entry["size"], "Export dimensions: " + entry["file"])
    alpha = set(im.getchannel("A").getdata())
    if entry["file"].startswith(("terrain/", "ui/")):
        check(alpha == {255}, "Opaque material cannot blend with hidden terrain: " + entry["file"])
    else:
        check(alpha == {0, 255}, "Crisp transparent sprite edges: " + entry["file"])

before = json.loads((EVIDENCE / "previous/events.json").read_text())
after = json.loads((EVIDENCE / "revised/events.json").read_text())
gameplay = lambda report: [event for event in report["events"] if event["event"] != "audio"]
check(gameplay(before) == gameplay(after), "Exact per-frame input, collision, stop, reset, sink and purchase event parity")
check(before["frames"] == after["frames"], "Matched replay duration")
check(before["physics_unchanged"] and after["physics_unchanged"], "Both skins preserve collision shapes, transforms, layers and masks")
for report in [before, after]:
    counts = Counter(event["event"] for event in report["events"])
    for kind in ["wall", "hazard", "stop", "sink", "purchase"]:
        check(counts[kind] >= 1, report["treatment"] + " has actual " + kind)
    cues = Counter(event["cue"] for event in report["events"] if event["event"] == "audio")
    for cue in ["sample_stone", "cup_sink", "hole_completion", "purchase", "curse"]:
        check(cues[cue] == 1, report["treatment"] + " emits one " + cue)

measurements = {}
for treatment in ["previous", "revised"]:
    media = EVIDENCE / (treatment + ".mp4")
    metadata = json.loads(subprocess.run([ffprobe, "-v", "error", "-show_streams", "-show_format", "-of", "json", str(media)], capture_output=True, text=True, check=True).stdout)
    video = next(stream for stream in metadata["streams"] if stream["codec_type"] == "video")
    check((video["width"], video["height"]) == (1920, 1080), treatment + " movie is 1080p")
    check(any(stream["codec_type"] == "audio" for stream in metadata["streams"]), treatment + " movie contains audio")
    analysis = subprocess.run([args.ffmpeg, "-i", str(media), "-af", "volumedetect", "-vn", "-f", "null", "-"], capture_output=True, text=True, check=True).stderr
    peak = float(re.search(r"max_volume: ([-\d.]+)", analysis)[1])
    mean = float(re.search(r"mean_volume: ([-\d.]+)", analysis)[1])
    check(-70 < mean and peak < -0.1, treatment + " audio is non-silent and unclipped")
    measurements[treatment] = {"seconds": float(metadata["format"]["duration"]), "mean_dbfs": mean, "peak_dbfs": peak}
    for filename in ["01_title", "02_hole", "03b_hazard_aim", "03c_hazard_contact", "05_shop", "05b_hover", "05c_press", "06b_tradeoff_feedback", "07_purchased"]:
        with Image.open(EVIDENCE / treatment / (filename + ".png")) as screenshot:
            check(screenshot.size == (1920, 1080), treatment + " capture: " + filename)

check(measurements["previous"]["seconds"] == measurements["revised"]["seconds"], "Movies have equal encoded duration")
report = {"passed": all(item["passed"] for item in checks), "count": len(checks), "checks": checks, "measurements": measurements, "human_style_approval": "Pending"}
(EVIDENCE / "artifact_checks.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({"passed": report["passed"], "count": len(checks), "failed": [item for item in checks if not item["passed"]], "measurements": measurements}, indent=2))
raise SystemExit(0 if report["passed"] else 1)
