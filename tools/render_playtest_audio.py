"""Prepare three verified CC0 playtest cues; never touch the approved audio bank.

Pass --source-dir pointing to the Godot user://audio_sources/human_fix cache.
Only audio bytes are read from the downloaded archive; no files are extracted.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile

import numpy as np
import soundfile as sf

SOURCES = {
    "applause.wav": {"sha256": "0d3bfde5a050f3c5e6685bd7f1efc7ab1d289fbad65c88c1ce9b4691228c69c9", "creator": "eXpl0it3r", "title": "Applause in a large hall or church", "url": "https://opengameart.org/content/applause-in-a-large-hall-or-church"},
    "aww.mp3": {"sha256": "6648ca3ec87a6d4ccaafc139bf1c7b6a3629c1888101630c4003428df152ce3b", "creator": "phmiller42", "title": "aww.wav (public HQ MP3 preview)", "url": "https://freesound.org/people/phmiller42/sounds/124996/"},
    "casino.zip": {"sha256": "f36250766ac5bc378c13708ddf12a23a8e54a3251f8d482c7536e51b5dbafa18", "creator": "Kenney", "title": "Casino Audio 1.1", "url": "https://kenney.nl/assets/casino-audio"},
}
RATE = 44100


def read_audio(source):
    samples, rate = sf.read(source, always_2d=True)
    if rate != RATE:
        times = np.arange(round(len(samples) * RATE / rate)) * rate / RATE
        samples = np.column_stack([np.interp(times, np.arange(len(samples)), channel) for channel in samples.T])
    return samples


def prepare(samples, fade_in=0.012, fade_out=0.18):
    samples = samples.copy()
    samples -= np.mean(samples, axis=0)
    onset = min(round(fade_in * RATE), len(samples))
    release = min(round(fade_out * RATE), len(samples))
    samples[:onset] *= np.linspace(0, 1, onset)[:, None]
    samples[-release:] *= np.linspace(1, 0, release)[:, None]
    samples *= 0.63 / max(float(np.max(np.abs(samples))), 0.0001)
    return samples


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, required=True)
    args = parser.parse_args()
    for filename, source in SOURCES.items():
        assert hashlib.sha256((args.source_dir / filename).read_bytes()).hexdigest() == source["sha256"], filename
    applause = read_audio(args.source_dir / "applause.wav")
    applause = prepare(applause[round(0.4 * RATE):round(3.2 * RATE)], 0.06, 0.8)
    disappointment = prepare(read_audio(args.source_dir / "aww.mp3"), 0.015, 0.15)
    with zipfile.ZipFile(args.source_dir / "casino.zip") as archive:
        license_text = archive.read("License.txt").decode("utf-8-sig")
        assert "CC0" in license_text and "Kenney" in license_text
        print(license_text)
        chips = read_audio(io.BytesIO(archive.read("Audio/chips-handle-2.ogg"))).mean(axis=1)
        tap = read_audio(io.BytesIO(archive.read("Audio/chips-collide-2.ogg"))).mean(axis=1)
    # Physical chip rattle + a short inharmonic register bell, baked as ONE cue.
    coins = np.zeros(round(RATE * 0.85))
    for sound, offset, gain in [(chips, 0.0, 0.8), (tap, 0.13, 0.65)]:
        start = round(offset * RATE)
        count = min(len(sound), len(coins) - start)
        coins[start:start + count] += sound[:count] * gain
    t = np.arange(len(coins)) / RATE - 0.06
    for frequency, decay, gain in [(1760, 0.22, 0.16), (2831, 0.14, 0.09), (4097, 0.065, 0.04)]:
        coins += (t >= 0) * np.exp(-np.maximum(t, 0) / decay) * np.sin(t * frequency * np.pi * 2) * gain
    coins = prepare(coins[:, None])
    audio_dir = Path(__file__).resolve().parents[1] / "assets/audio"
    records = []
    for filename, samples, origin, edits in [
        ("crowd_success.wav", applause, "applause.wav", "0.4-3.2 second excerpt; onset/release fades, DC removal, peak normalization"),
        ("crowd_failure.wav", disappointment, "aww.mp3", "HQ preview decoded to PCM; edge fades, DC removal, peak normalization"),
        ("purchase_coins.wav", coins, "casino.zip", "chips-handle-2 and chips-collide-2, mono mix, original inharmonic register bell, fades and normalization"),
    ]:
        path = audio_dir / filename
        sf.write(path, samples, RATE, subtype="PCM_16")
        records.append({"file": filename, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "source": SOURCES[origin], "license": "CC0-1.0", "modifications": edits, "loop_seam_step": None})
    (audio_dir / "playtest_audio_manifest.json").write_text(json.dumps({"revision": 1, "assets": records}, indent=2) + "\n")


if __name__ == "__main__":
    main()
