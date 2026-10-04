"""Private reference analysis, never a source for shipped audio.

Signal measurements cannot establish instruments, groove, mix comfort or likeness.
"""
from pathlib import Path
import hashlib
import json
import subprocess

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/references/Screen Recording 2026-09-24 143837.mp4"
OUT = ROOT / "artifacts/reference_review/audio"
OUT.mkdir(parents=True, exist_ok=True)


def run(args):
    return subprocess.run(args, check=True, capture_output=True, text=True)


def main():
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    full = OUT / "reference_only_full.wav"
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(SOURCE),
         "-map", "0:a:0", "-c:a", "pcm_s16le", str(full)])
    y, rate = sf.read(full, always_2d=True, dtype="float32")
    meter = run(["ffmpeg", "-hide_banner", "-i", str(full), "-af",
                 "loudnorm=I=-18:TP=-2:LRA=9:print_format=json", "-f", "null", "-"])
    stats, _ = json.JSONDecoder().raw_decode(meter.stderr[meter.stderr.rfind("{\n"):])
    # Onset autocorrelation over gameplay only. Half/double-time ambiguity and
    # SFX/edit contamination mean these are candidate periodicities, not tempo.
    mono = y[round(1.5 * rate):round(26.6 * rate)].mean(axis=1)
    hop, size = round(rate / 100), 2048
    windows = np.lib.stride_tricks.sliding_window_view(mono, size)[::hop]
    spectrum = np.abs(np.fft.rfft(windows * np.hanning(size), axis=1))
    frequency = np.fft.rfftfreq(size, 1 / rate)
    bands = []
    for lo, hi in [(70, 300), (300, 1600), (1600, 7000)]:
        flux = np.maximum(np.diff(np.log1p(spectrum[:, (frequency >= lo) & (frequency < hi)]), axis=0), 0).sum(axis=1)
        flux /= max(float(flux.std()), 1e-9)
        bands.append(flux)
    onset = np.mean(bands, axis=0)
    onset -= onset.mean()
    ac = np.correlate(onset, onset, mode="full")[len(onset) - 1:]
    candidates = []
    for lag in range(32, 111):
        if ac[lag] > ac[lag - 1] and ac[lag] > ac[lag + 1]:
            candidates.append({"bpm_equivalent": round(6000 / lag, 2),
                               "normalized_correlation": round(float(ac[lag] / ac[0]), 4)})
    candidates.sort(key=lambda value: -value["normalized_correlation"])
    excerpts = []
    for name, start, duration, subject in [
        ("reference_only_gameplay", 1.5, 25.1, "Gameplay, edits, music and mixed SFX"),
        ("reference_only_shop", 11.4, 1.8, "Edited shop appearance; no isolated UI stem"),
        ("reference_only_reward", 23.5, 3.2, "Cup approach and result escalation"),
    ]:
        path = OUT / f"{name}.wav"
        run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", str(start),
             "-i", str(SOURCE), "-t", str(duration), "-map", "0:a:0", "-c:a", "pcm_s16le", str(path)])
        excerpts.append({"file": str(path.relative_to(ROOT)), "source_start_seconds": start,
                         "duration_seconds": duration, "subject": subject})
    boosted = OUT / "reference_only_gameplay_plus30db.wav"
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(OUT / "reference_only_gameplay.wav"),
         "-af", "volume=30dB", str(boosted)])
    report = {
        "source": str(SOURCE.relative_to(ROOT)), "source_sha256": digest,
        "source_preserved": hashlib.sha256(SOURCE.read_bytes()).hexdigest() == digest,
        "listening": "UNAVAILABLE. Audio output can be made playable; no model audio-input listening tool is exposed.",
        "sample_rate": rate, "channels": y.shape[1], "decoded_seconds": len(y) / rate,
        "sample_peak_dbfs": round(float(20 * np.log10(max(np.abs(y).max(), 1e-9))), 3),
        "rms_dbfs": round(float(20 * np.log10(max(np.sqrt(np.mean(y ** 2)), 1e-9))), 3),
        "integrated_loudness_lufs": float(stats["input_i"]),
        "true_peak_dbtp": float(stats["input_tp"]), "loudness_range_lu": float(stats["input_lra"]),
        "onset_periodicity_candidates_not_tempo": candidates[:6],
        "subjective_findings": {key: "Pending direct human listening" for key in
                                 ["rhythmic_feel", "instrumentation", "bass_percussion_roles", "melodic_density",
                                  "energy_changes", "ui_sound_character", "impact_sound_character", "mix_balance"]},
        "excerpts": excerpts,
        "listening_gain_excerpt": {"file": boosted.relative_to(ROOT).as_posix(), "gain_db": 30,
                                   "other_processing": "None; analysis only, never production audio"},
    }
    (OUT / "reference_audio_analysis.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
