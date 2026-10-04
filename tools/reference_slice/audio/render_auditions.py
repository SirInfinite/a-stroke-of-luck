"""Original, editable 32-bar audition scores and material SFX.

Reference audio is never read by this renderer. VCSL recordings are verified by
the existing project's pinned manifest; newly authored synthesis is original.
Only finished Ogg files are runtime resources. PCM masters stay in artifacts.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
from render_audio_score import Sampler, RATE, add, envelope, midi, noise, PROTECTED

OUT = ROOT / "assets/reference_slice/audio"
EVIDENCE = ROOT / "artifacts/reference_review/audio"
OUT.mkdir(parents=True, exist_ok=True)
EVIDENCE.mkdir(parents=True, exist_ok=True)

# Each phrase contains four explicitly written bars. Durations sum to four.
# Rested endings, question/answer phrases and a thinner bridge are intentional.
SCORES = {
    "a_sunlit_circuit": {
        "title": "Sunlit Circuit", "bpm": 160, "form": "AABACDBE",
        "description": "Rounded pulse lead, half-time bass pocket, warm mallet replies and dry hand percussion.",
        "melodies": {
            "A": "-:.5 D5:.5 F5:.5 A5:.5 G5:1 F5:.5 E5:.5 | D5:1 -:.5 A4:.5 C5:.5 D5:.5 F5:1 | G5:.5 A5:.5 C6:1 A5:.5 G5:.5 F5:.5 D5:.5 | E5:.5 F5:.5 A5:1 E5:.5 D5:1 -:.5",
            "B": "A5:1 G5:.5 F5:.5 E5:.5 D5:.5 -:1 | F5:.5 E5:.5 D5:1 A4:.5 C5:.5 D5:1 | G5:1 -:.5 F5:.5 A5:.5 G5:.5 E5:.5 C5:.5 | D5:1 F5:.5 E5:.5 D5:1 -:1",
            "C": "F5:1 -:1 E5:.5 D5:.5 C5:1 | A4:1 C5:1 D5:1 -:1 | E5:1 G5:1 A5:.5 G5:.5 E5:1 | F5:1 E5:1 D5:1 -:1",
            "D": "D5:.5 F5:.5 A5:.5 C6:.5 D6:1 C6:.5 A5:.5 | G5:.5 A5:.5 F5:1 D5:.5 C5:.5 A4:1 | G5:.5 A5:.5 C6:.5 A5:.5 G5:1 F5:.5 E5:.5 | E5:.5 F5:.5 A5:1 D5:1 -:1",
            "E": "A5:.5 G5:.5 F5:1 E5:.5 D5:.5 C5:1 | D5:1 A4:.5 C5:.5 D5:1 -:1 | F5:.5 A5:.5 G5:1 E5:.5 F5:.5 D5:1 | C5:.5 E5:.5 A4:1 -:1 C5:.5 E5:.5",
        },
        "harmony": {
            "A": ["D2 F3 A3 C4 E4", "Bb1 F3 A3 C4 D4", "F2 F3 A3 C4 G4", "C2 E3 G3 A3 D4"],
            "B": ["G1 F3 Bb3 D4 A4", "D2 F3 A3 C4 E4", "Bb1 F3 A3 C4 D4", "C2 E3 G3 Bb3 D4"],
            "C": ["Bb1 F3 A3 C4 D4", "F2 E3 A3 C4 G4", "C2 E3 G3 A3 D4", "D2 F3 A3 C4 E4"],
            "D": ["D2 F3 A3 C4 E4", "Bb1 F3 A3 C4 D4", "G1 F3 Bb3 D4 A4", "C2 E3 G3 Bb3 D4"],
            "E": ["Bb1 F3 A3 C4 D4", "D2 F3 A3 C4 E4", "G1 F3 Bb3 D4 A4", "A1 E3 G3 B3 D4"],
        },
    },
    "b_amber_canopy": {
        "title": "Amber Canopy", "bpm": 156, "form": "ABACDBAE",
        "description": "The same quick pulse with acoustic mallet melody, soft pulse counterlines and more open responses.",
        "melodies": {
            "A": "-:.5 G5:.5 E5:1 D5:.5 E5:.5 G5:1 | A5:.5 G5:.5 E5:1 D5:.5 C5:.5 -:1 | E5:1 G5:.5 A5:.5 B5:.5 A5:.5 G5:1 | D5:.5 E5:.5 G5:1 E5:1 -:1",
            "B": "C6:1 B5:.5 G5:.5 A5:1 G5:.5 E5:.5 | D5:1 E5:.5 G5:.5 E5:1 -:1 | A5:1 G5:.5 E5:.5 D5:1 C5:1 | D5:.5 E5:.5 G5:.5 E5:.5 D5:1 -:1",
            "C": "G5:1 -:1 E5:1 D5:1 | C5:1 E5:1 -:2 | D5:1 G5:1 A5:1 G5:1 | E5:1 D5:1 -:2",
            "D": "E5:.5 G5:.5 A5:.5 B5:.5 D6:1 B5:.5 A5:.5 | G5:1 E5:.5 D5:.5 C5:1 -:1 | D5:.5 E5:.5 G5:.5 A5:.5 B5:1 G5:1 | A5:.5 G5:.5 E5:1 D5:1 -:1",
            "E": "G5:1 E5:.5 D5:.5 C5:1 E5:1 | G5:1 A5:.5 G5:.5 E5:1 -:1 | D5:1 E5:.5 G5:.5 A5:1 G5:1 | D5:1 C5:.5 D5:.5 -:1 D5:.5 E5:.5",
        },
        "harmony": {
            "A": ["C2 E3 G3 B3 D4", "A1 E3 G3 B3 C4", "F2 E3 A3 C4 G4", "G1 F3 A3 B3 E4"],
            "B": ["F2 E3 G3 A3 C4", "C2 E3 G3 B3 D4", "D2 F3 A3 C4 E4", "G1 F3 A3 B3 D4"],
            "C": ["A1 E3 G3 B3 C4", "F2 E3 G3 A3 C4", "D2 F3 A3 C4 E4", "G1 F3 A3 B3 D4"],
            "D": ["C2 E3 G3 B3 D4", "A1 E3 G3 B3 C4", "F2 E3 A3 C4 G4", "G1 F3 A3 B3 E4"],
            "E": ["F2 E3 A3 C4 G4", "C2 E3 G3 B3 D4", "D2 F3 A3 C4 E4", "G1 F3 A3 B3 D4"],
        },
    },
}


def parse_phrase(text):
    for bar, notes in enumerate(text.split("|")):
        cursor = 0.0
        for token in notes.split():
            pitch, value = token.split(":")
            length = float(value)
            if pitch != "-":
                yield bar, cursor, midi(pitch), length
            cursor += length
        if abs(cursor - 4) > 1e-6:
            raise ValueError(f"Invalid bar length {cursor}: {notes}")


def synth(pitch, duration, instrument="lead"):
    t = np.arange(round((duration + .10) * RATE)) / RATE
    hz = 440 * 2 ** ((pitch - 69) / 12)
    if instrument == "bass":
        body = np.sin(2 * np.pi * hz * t) + .23 * np.sin(4 * np.pi * hz * t)
        body += .055 * np.sin(6 * np.pi * hz * t)
        env = (1 - np.exp(-t * 160)) * (.62 + .38 * np.exp(-t * 10))
    elif instrument == "pad":
        body = np.zeros_like(t)
        for partial, level in [(1, .7), (2, .19), (3, .08), (4, .025)]:
            body += level * np.sin(2 * np.pi * hz * partial * t + .012 * np.sin(2 * np.pi * 1.3 * t))
        env = (1 - np.exp(-t * 12)) * (.8 + .2 * np.cos(t * 2.5))
    else:
        # Band-limited rounded pulse; fixed phase and restrained vibrato.
        phase = 2 * np.pi * hz * t + .021 * np.maximum(0, 1 - np.exp(-(t - .1) * 10)) * np.sin(2 * np.pi * 5.1 * t)
        body = np.sin(phase) + .21 * np.sin(2 * phase) + .16 * np.sin(3 * phase)
        body += .055 * np.sin(5 * phase) + .02 * np.sin(7 * phase)
        env = (1 - np.exp(-t * 280)) * (.68 + .32 * np.exp(-t * 16))
    release = np.clip((duration + .10 - t) / .10, 0, 1) ** 2
    return (body * env * release).astype(np.float32)


def kick():
    t = np.arange(round(.26 * RATE)) / RATE
    hz = 48 + 72 * np.exp(-t * 35)
    body = np.sin(2 * np.pi * np.cumsum(hz) / RATE) * np.exp(-t * 20)
    return envelope(body.astype(np.float32), .0008, .025)


def stereo_room(buffer, seconds=.04, gain=.12):
    dry = buffer.copy()
    for delay, amount in [(seconds, gain), (.079, .055), (.151, .028)]:
        buffer += np.roll(dry[:, ::-1], round(delay * RATE), axis=0) * amount
    return buffer


def meter(path):
    result = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af",
                             "loudnorm=I=-18:TP=-2:LRA=9:print_format=json", "-f", "null", "-"],
                            capture_output=True, text=True, check=True)
    measured, _ = json.JSONDecoder().raw_decode(result.stderr[result.stderr.rfind("{\n"):])
    integrated = float(measured["input_i"])
    return {"integrated_lufs": integrated if math.isfinite(integrated) else None, "true_peak_dbtp": float(measured["input_tp"]),
            "loudness_range_lu": float(measured["input_lra"])}


def finish(name, buffer, loop, target_lufs=-19.0, peak_db=-3.0):
    if buffer.ndim == 1:
        buffer = np.column_stack((buffer, buffer))
    buffer -= np.mean(buffer, axis=0)
    peak = float(np.max(np.abs(buffer)))
    buffer *= 10 ** (peak_db / 20) / max(peak, 1e-9)
    master = EVIDENCE / f"{name}_master.wav"
    sf.write(master, buffer, RATE, subtype="PCM_24")
    before = meter(master)
    loudness_gain = target_lufs - before["integrated_lufs"] if before["integrated_lufs"] is not None else 0.0
    gain = min(loudness_gain, peak_db - before["true_peak_dbtp"])
    buffer *= 10 ** (gain / 20)
    sf.write(master, buffer, RATE, subtype="PCM_24")
    path = OUT / f"{name}.ogg"
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(master),
                    "-c:a", "libvorbis", "-q:a", "6", str(path)], check=True)
    decoded, rate = sf.read(path, dtype="float32", always_2d=True)
    step = float(np.max(np.abs(decoded[0] - decoded[-1])))
    boundary = np.concatenate((decoded[-1024:], decoded[:1024]))
    neighboring = float(np.quantile(np.abs(np.diff(boundary, axis=0)), .99))
    return {"file": path.relative_to(ROOT).as_posix(), "seconds": len(decoded) / rate,
            "sample_rate": rate, "channels": decoded.shape[1], "loop": loop,
            "loop_seam_step": step if loop else None,
            "boundary_step_p99": neighboring if loop else None,
            "sample_peak_dbfs": float(20 * np.log10(max(np.abs(decoded).max(), 1e-9))),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), **meter(path)}


def music(sampler, key, score):
    beat = 60 / score["bpm"]
    track = np.zeros((round(32 * 4 * beat * RATE), 2), np.float32)
    alternate = key.startswith("b_")
    lead = np.zeros_like(track)
    pad = np.zeros_like(track)
    for section, letter in enumerate(score["form"]):
        for bar, offset, pitch, duration in parse_phrase(score["melodies"][letter]):
            position = (section * 16 + bar * 4 + offset) * beat
            velocity = .9 if offset % 1 == 0 else .78
            if alternate:
                add(lead, sampler.note("marimba", pitch, duration * beat + .12), position, .16 * velocity, -.12, True)
                if section in (3, 4, 6) and duration >= 1:
                    add(lead, synth(pitch - 12, duration * beat * .82), position + beat * .04, .023, .22, True)
            else:
                add(lead, synth(pitch, duration * beat * .84), position, .088 * velocity, -.12, True)
                add(lead, sampler.note("marimba", pitch - 12, duration * beat + .10), position, .035, .16, True)
        for bar, voicing in enumerate(score["harmony"][letter]):
            absolute_bar = section * 4 + bar
            start = absolute_bar * 4 * beat
            chord = [midi(note) for note in voicing.split()]
            thinner = letter == "C"
            bass_pattern = [(0, 0, 1.25), (1.5, 0, .45), (2.5, 7, .7), (3.5, 12 if bar % 2 == 0 else 0, .43)]
            if thinner:
                bass_pattern = [(0, 0, 1.6), (2.5, 7, .9)]
            for offset, interval, duration in bass_pattern:
                add(track, synth(chord[0] + interval, duration * beat, "bass"), start + beat * offset,
                    .17 if not alternate else .15, 0, True)
            for voice, pitch in enumerate(chord[1:]):
                add(pad, synth(pitch, beat * 3.9, "pad"), start, .014 if alternate else .011,
                    -.38 + voice * .23, True)
            for offset in ([.5, 2.5] if thinner else [.5, 1.5, 2.5, 3.5]):
                for voice, pitch in enumerate(chord[1:4]):
                    add(track, sampler.note("piano" if alternate else "vibes", pitch + 12,
                                            beat * .62), start + beat * offset + voice * .007,
                        .032 if alternate else .026, .28, True)
            # Replies occupy melody rests; short, sparse figures distinguish sections.
            if bar in (1, 3):
                for i, p in enumerate([chord[2] + 12, chord[3] + 12, chord[1] + 12]):
                    add(track, sampler.note("vibes" if alternate else "harp", p, beat * .52),
                        start + beat * (3.0 + .25 * i), .034, .37, True)
            for offset, amount in [(0, 1), (2.5, .78)]:
                add(track, kick(), start + beat * offset, .14 * amount if not thinner else .08, 0, True)
            for offset in (1, 3):
                add(track, sampler.note("cajon", 60, .18, alternate=absolute_bar), start + beat * offset,
                    .080 if not thinner else .04, .03, True)
                add(track, sampler.note("wood", 60, .06, alternate=absolute_bar), start + beat * offset,
                    .014, -.18, True)
            for step in range(8):
                if thinner and step % 2 == 0:
                    continue
                add(track, sampler.note("shaker", 60, .09, alternate=step), start + beat * (step * .5 + .017),
                    .021 if step % 2 else .009, -.38 if step % 2 else .31, True)
            # A written turnaround and a stronger penultimate-section lift, never random fills.
            if bar == 3 and letter != "C":
                for offset, amount in [(3.25, .031), (3.5, .048), (3.75, .039)]:
                    add(track, sampler.note("cajon", 60, .10, alternate=int(offset * 4)), start + beat * offset,
                        amount, .18, True)
    stereo_room(lead, .043, .105)
    stereo_room(pad, .062, .08)
    track += lead + pad
    record = finish(key, track, True)
    record.update({"title": score["title"], "bpm": score["bpm"], "bars": 32, "beats_per_bar": 4,
                   "form": score["form"], "description": score["description"],
                   "score_sha256": hashlib.sha256(json.dumps(score, sort_keys=True).encode()).hexdigest(),
                   "approval": "Provisional. Direct reference listening and owner musical approval pending."})
    return record


def sfx(sampler):
    records = []
    for name, length, modes, brightness in [
        ("strike", .19, [(740, 1), (1620, .21), (2850, .08)], 6500),
        ("wall", .24, [(240, 1), (611, .32), (1140, .08)], 3400),
        ("pendulum", .49, [(78, 1), (139, .55), (293, .26), (637, .08)], 4600),
    ]:
        t = np.arange(round(length * RATE)) / RATE
        body = np.zeros_like(t)
        for hz, weight in modes:
            body += weight * np.sin(2 * np.pi * hz * t) * np.exp(-t * (18 + hz / 115))
        body += noise(length, len(name) * 733, 400, brightness) * np.exp(-t * 130) * .16
        add(body, sampler.note("wood", 60, length * .55), .002, .21)
        if name == "pendulum":
            add(body, sampler.note("cajon", 60, .16), .018, .38)
        records.append(finish(name, envelope(body.astype(np.float32), .0007, .028), False, -19, -4))
    for name, intervals, length in [
        ("cup", [(0, 67, .10), (.064, 62, .06), (.132, 55, .045)], .36),
        ("success", [(0, 74, .11), (.095, 77, .10), (.19, 81, .13), (.38, 86, .14)], 1.2),
    ]:
        body = np.zeros((round(length * RATE), 2), np.float32)
        for onset, pitch, gain in intervals:
            add(body, sampler.note("wood" if name == "cup" else "vibes", pitch,
                                   .18 if name == "cup" else .7), onset, gain, .1, False)
            if name == "success":
                add(body, synth(pitch - 12, .16), onset, .025, -.12, False)
        records.append(finish(name, body, False, -21 if name == "cup" else -20, -4))
    for name, pitch, length in [("hover", 79, .045), ("select", 74, .080), ("back", 62, .11)]:
        t = np.arange(round(length * RATE)) / RATE
        body = sampler.note("wood", 60, length) * .3
        if len(body) < len(t):
            body = np.pad(body, (0, len(t) - len(body)))
        body += np.sin(2 * np.pi * (440 * 2 ** ((pitch - 69) / 12)) * t) * np.exp(-t * 65) * .065
        records.append(finish(name, envelope(body, .0015, .018), False, -28, -11))
    return records


def main():
    protected_before = {name: hashlib.sha256((ROOT / "assets/audio" / name).read_bytes()).hexdigest() for name in PROTECTED}
    for name, expected in PROTECTED.items():
        if protected_before[name] != expected:
            raise ValueError(f"Protected audio baseline unexpected: {name}")
    sampler = Sampler()  # Verifies all cached source Git blob hashes.
    records = [music(sampler, key, value) for key, value in SCORES.items()]
    records += sfx(sampler)
    for name, before in protected_before.items():
        if hashlib.sha256((ROOT / "assets/audio" / name).read_bytes()).hexdigest() != before:
            raise ValueError(f"Protected cue changed: {name}")
    manifest = {
        "creator": "A Stroke of Luck project / Codex; original scores and synthesis",
        "license": "Original project work plus VCSL CC0-1.0 instrument recordings",
        "reference_audio_used_in_production": False,
        "listening_status": "No subjective listening available in agent tooling; owner review pending",
        "source_library": "Versilian Community Sample Library / Versilian Studios and contributors",
        "source_revision": "c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e",
        "license_url": "https://raw.githubusercontent.com/sgossner/VCSL/c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e/LICENSE",
        "modifications": "Verified note sampling, pitch resampling, envelopes, stereo placement, original synthesis, original scores, cyclic short room, linear loudness/headroom mastering, Vorbis encoding.",
        "verified_source_samples": sampler.provenance, "protected_sources": protected_before,
        "assets": records,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(records, indent=2))


if __name__ == "__main__":
    main()
