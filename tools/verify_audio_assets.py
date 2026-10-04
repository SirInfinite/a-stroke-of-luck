"""Independent file/score audit, not an assertion of musical taste.

Reads the actual shipped PCM through SoundFile, independently of renderer
measurements. Requires NumPy and SoundFile; --report writes optional QA evidence.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
import soundfile as sf

from audio_score import SCORES


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    audio_dir = root / "assets/audio"
    manifest = json.loads((audio_dir / "audio_manifest.json").read_text())
    playtest_assets = json.loads((audio_dir / "playtest_audio_manifest.json").read_text())["assets"]
    records, failures = [], []
    checks = 0

    def check(condition, description):
        nonlocal checks
        checks += 1
        if not condition:
            failures.append(description)

    check(set(SCORES) == {"menu", "tutorial", "meadow", "desert", "autumn", "snow", "swamp", "volcanic"}, "eight required scores")
    score_fingerprints, file_hashes = set(), set()
    for key, score in SCORES.items():
        score_fingerprints.add(json.dumps(score["melody"], sort_keys=True))
        for section, phrase in score["melody"].items():
            bars = phrase.split("|")
            check(len(bars) == 4, f"{key}/{section}: four-bar phrase")
            check(len(score["harmony"][section]) == 4, f"{key}/{section}: four-bar harmony")
            for index, bar in enumerate(bars):
                length = sum(float(token.split(":")[1]) for token in bar.split())
                check(math.isclose(length, score["beats"]), f"{key}/{section}/{index}: metrical completeness")
        check(len(set(score["form"])) >= 3, f"{key}: contrasting written sections")
    check(len(score_fingerprints) == 8, "all eight written melodies differ")

    for entry in manifest["assets"] + playtest_assets:
        path = audio_dir / entry["file"]
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        check(digest == entry["sha256"], f"{path.name}: current render hash")
        samples, rate = sf.read(path, always_2d=True)
        peak = float(np.max(np.abs(samples)))
        rms = float(np.sqrt(np.mean(samples ** 2)))
        seconds = len(samples) / rate
        check(rate == 44100, f"{path.name}: expected sample rate")
        check(np.isfinite(samples).all(), f"{path.name}: finite PCM")
        check(0 < peak <= 0.701, f"{path.name}: at least 3 dB source headroom")
        check(rms > 0.001, f"{path.name}: non-silent signal")
        row = {"file": path.name, "seconds": round(seconds, 3), "peak_dbfs": round(20 * math.log10(peak), 2), "rms_dbfs": round(20 * math.log10(rms), 2)}
        if entry["loop_seam_step"] is not None:
            seam = float(np.max(np.abs(samples[-1] - samples[0])))
            ordinary_step = float(np.quantile(np.abs(np.diff(samples, axis=0)), 0.95))
            # A broadband noise seam need not equal zero: it must be no more
            # abrupt than its normal adjacent samples. Music gets a low floor.
            check(seam <= max(0.008, ordinary_step * 6), f"{path.name}: non-anomalous cyclic boundary")
            edge = np.concatenate((samples[-round(rate * 0.15):], samples[:round(rate * 0.15)]))
            check(float(np.sqrt(np.mean(edge ** 2))) > 0.0001, f"{path.name}: no silent seam")
            row.update({"seam_step": round(seam, 6), "ordinary_step_p95": round(ordinary_step, 6)})
        if path.name.startswith("theme_"):
            key = path.stem.removeprefix("theme_")
            score = SCORES[key]
            expected = len(score["form"]) * 4 * score["beats"] * 60 / score["bpm"]
            check(abs(seconds - expected) < 1 / rate, f"{key}: whole musical measures")
            check(30 <= seconds <= 90, f"{key}: substantive loop duration")
            check(samples.shape[1] == 2, f"{key}: stereo mix")
            file_hashes.add(digest)
        records.append(row)
    check(len(file_hashes) == 8, "eight distinct rendered music files")
    for name, expected in manifest["protected"].items():
        check(hashlib.sha256((audio_dir / name).read_bytes()).hexdigest() == expected, f"{name}: supplied/approved cue byte-exact")
    declared = {item["file"] for item in manifest["assets"] + playtest_assets} | set(manifest["protected"])
    check(declared == {path.name for path in audio_dir.glob("*.wav")}, "all shipped WAVs have provenance")
    report = {"passed": not failures, "checks": checks, "failures": failures, "generated_files": len(records), "protected_files": len(manifest["protected"]), "measurements": records, "subjective_listening": "NOT PERFORMED - human review required"}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
