"""Reproduce the approval mix from verified Audionautix source downloads.

Requires an existing FFmpeg installation. Downloads are evidence under artifacts;
this script neither downloads nor executes third-party code.
"""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--ffmpeg", required=True)
args = parser.parse_args()
target = root / "assets/pixel_sample/audio"
evidence = root / "artifacts/pixel_sample"
records = []
for source, output, title, duration in [
    ("pepper_funk", "a_pepper_funk", "Peppers Funk", 30),
    ("rocker_chicks", "b_rocker_chicks", "Rocker Chicks", 45),
]:
    original = evidence / "references" / (source + ".mp3")
    result = target / (output + ".ogg")
    command = [args.ffmpeg, "-y", "-i", str(original), "-af",
               "loudnorm=I=-18:TP=-2:LRA=9:print_format=json", "-ar", "48000",
               "-c:a", "libvorbis", "-q:a", "5", str(result)]
    mix = subprocess.run(command, capture_output=True, text=True, check=True)
    (evidence / (output + "_mix.log")).write_text(mix.stderr)
    stats, _ = json.JSONDecoder().raw_decode(mix.stderr[mix.stderr.rfind("{\n"):])
    excerpt = evidence / (output + "_excerpt.mp3")
    subprocess.run([args.ffmpeg, "-y", "-i", str(result), "-t", str(duration),
                    "-af", f"afade=t=out:st={duration-1.5}:d=1.5",
                    "-c:a", "libmp3lame", "-q:a", "2", str(excerpt)],
                   capture_output=True, check=True)
    records.append({"title": title, "artist": "Jason Shaw / Audionautix",
                    "source_sha256": hashlib.sha256(original.read_bytes()).hexdigest(),
                    "export_sha256": hashlib.sha256(result.read_bytes()).hexdigest(),
                    "excerpt_seconds": duration, "mix": stats,
                    "license": "CC BY 4.0", "sample_rate": 48000,
                    "subjective_listening": "Unavailable; owner approval required"})
(target / "mix_manifest.json").write_text(json.dumps(records, indent=2) + "\n")
print(json.dumps(records, indent=2))
