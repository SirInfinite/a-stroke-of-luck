"""Validate replay parity, actual outcomes and media; never infer artistic quality."""
from pathlib import Path
from collections import Counter
import argparse
import json
import re
import subprocess

root = Path(__file__).resolve().parents[2]
evidence = root / "artifacts/pixel_sample"
parser = argparse.ArgumentParser()
parser.add_argument("--ffmpeg", required=True)
args = parser.parse_args()
ffprobe = str(Path(args.ffmpeg).with_name("ffprobe.exe"))
before = json.loads((evidence / "baseline/events.json").read_text())
after = json.loads((evidence / "after/events.json").read_text())
checks = []

def check(condition, description):
    checks.append({"passed": bool(condition), "check": description})


def gameplay(report):
    return [event for event in report["events"] if event["event"] != "audio"]


check(gameplay(before) == gameplay(after), "Identical per-frame inputs and actual gameplay events before/after")
check(after["physics_unchanged"], "Visual adapter preserves collision geometry and layers")
counts = Counter(event["event"] for event in after["events"])
for kind, minimum in [("shot", 3), ("wall", 1), ("hazard", 1), ("stop", 1), ("sink", 1), ("purchase", 1)]:
    check(counts[kind] >= minimum, f"Replay contains real {kind} event")
cues = Counter(event["cue"] for event in after["events"] if event["event"] == "audio")
for cue in ["cup_sink", "hole_completion", "crowd_success", "purchase", "curse", "sample_stone"]:
    check(cues[cue] == 1, f"Exactly one {cue} cue")
check(cues["failure_1"] == 0 and cues["failure_2"] == 0, "Hazard reset is not a forced-hole failure")
check(cues["ui_click"] == 0, "Purchase has no generic UI click duplicate")
measurements = {}
for name in ["baseline", "after"]:
    media = evidence / (name + ".mp4")
    metadata = json.loads(subprocess.run([ffprobe, "-v", "error", "-show_streams", "-show_format", "-of", "json", str(media)], capture_output=True, text=True, check=True).stdout)
    check(any(stream["codec_type"] == "audio" for stream in metadata["streams"]), f"{name} movie has an audio stream")
    video = next(stream for stream in metadata["streams"] if stream["codec_type"] == "video")
    check(video["width"] == 1920 and video["height"] == 1080, f"{name} movie is 1080p")
    analysis = subprocess.run([args.ffmpeg, "-i", str(media), "-af", "volumedetect", "-vn", "-f", "null", "-"], capture_output=True, text=True, check=True).stderr
    mean = float(re.search(r"mean_volume: ([-\d.]+)", analysis)[1])
    peak = float(re.search(r"max_volume: ([-\d.]+)", analysis)[1])
    check(-70 < mean and peak < -0.1, f"{name} mixed PCM is non-silent and unclipped")
    measurements[name] = {"mean_dbfs": mean, "peak_dbfs": peak, "seconds": float(metadata["format"]["duration"])}
report = {"checks": checks, "passed": all(item["passed"] for item in checks), "measurements": measurements,
          "cues": dict(cues), "subjective_listening": "Not performed"}
(evidence / "evidence_checks.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
raise SystemExit(0 if report["passed"] else 1)
