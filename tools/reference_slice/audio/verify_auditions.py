"""Independent decoded-asset, source-integrity and local audition-link check."""
from pathlib import Path
import hashlib
import json
import math
import re
from urllib.parse import unquote

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "artifacts/reference_review/audio"
manifest = json.loads((ROOT / "assets/reference_slice/audio/manifest.json").read_text(encoding="utf-8"))
checks = 0
failures = []


def expect(condition, label):
    global checks
    checks += 1
    if not condition:
        failures.append(label)


decoded_hashes = []
for asset in manifest["assets"]:
    path = ROOT / asset["file"]
    expect(path.is_file(), f"present: {path.name}")
    expect(hashlib.sha256(path.read_bytes()).hexdigest() == asset["sha256"], f"manifest hash: {path.name}")
    audio, rate = sf.read(path, always_2d=True, dtype="float32")
    expect(np.isfinite(audio).all(), f"finite decoded PCM: {path.name}")
    expect(rate == 44100 and audio.shape[1] == 2, f"44.1 kHz stereo: {path.name}")
    expect(.002 < np.max(np.abs(audio)) < .9, f"non-silent headroom: {path.name}")
    expect(abs(audio.mean()) < .001, f"DC offset: {path.name}")
    if asset["loop"]:
        expect(45 <= len(audio) / rate <= 60, f"full audition length: {path.name}")
        expect(abs(len(audio) / rate - 32 * 4 * 60 / asset["bpm"]) < 1 / rate, f"32 complete bars: {path.name}")
        edge = np.concatenate((audio[-1024:], audio[:1024]))
        seam = np.max(np.abs(audio[-1] - audio[0]))
        ordinary_step = np.quantile(np.abs(np.diff(edge, axis=0)), .99)
        expect(seam < ordinary_step * 1.1, f"boundary discontinuity below ordinary steps: {path.name}")
        expect(np.sqrt(np.mean(audio[-round(rate * .2):] ** 2)) > .005, f"no silent fade-out masquerading as loop: {path.name}")
        expect(-20 < asset["integrated_lufs"] < -18, f"matched audition loudness: {path.name}")
        decoded_hashes.append(hashlib.sha256(audio.tobytes()).hexdigest())
expect(len(set(decoded_hashes)) == 2, "two distinct decoded musical recordings; not approval of compositional difference")
for name, digest in manifest["protected_sources"].items():
    expect(hashlib.sha256((ROOT / "assets/audio" / name).read_bytes()).hexdigest() == digest, f"protected original: {name}")
html_path = ROOT / "tools/reference_slice/audio/audition.html"
for url in re.findall(r'(?:src|href)="([^"]+)"', html_path.read_text(encoding="utf-8")):
    if not url.startswith(("http", "#")):
        expect((html_path.parent / unquote(url)).resolve().exists(), f"playable local link: {url}")
expect(not manifest["reference_audio_used_in_production"], "reference audio explicitly excluded from production provenance")
reference_report = json.loads((OUT / "reference_audio_analysis.json").read_text(encoding="utf-8"))
source = ROOT / reference_report["source"]
expect(hashlib.sha256(source.read_bytes()).hexdigest() == reference_report["source_sha256"], "original reference recording preserved")
native_path = OUT / "native_lifecycle.wav"
native, native_rate = sf.read(native_path, always_2d=True, dtype="float32")
peak_db = 20 * math.log10(float(np.max(np.abs(native))))
expect(peak_db < -6, "native overlapping event recording leaves over 6 dB headroom")
report = {"checks": checks, "failures": failures, "assets": len(manifest["assets"]),
          "runtime_asset_bytes": sum((ROOT / item["file"]).stat().st_size for item in manifest["assets"]),
          "native_recording_seconds": len(native) / native_rate, "native_peak_dbfs": peak_db,
          "native_rms_dbfs": 20 * math.log10(float(np.sqrt(np.mean(native ** 2)))),
          "decoded_music_sha256": decoded_hashes,
          "listening_approval": "Pending; signal tests do not establish musical or subjective quality"}
(OUT / "asset_verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report, indent=2))
raise SystemExit(1 if failures else 0)
