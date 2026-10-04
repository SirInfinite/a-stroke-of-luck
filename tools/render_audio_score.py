"""Offline PCM renderer; no Python, sampler, or network dependency ships in-game.

Uses NumPy + SoundFile, already available in the development environment.
VCSL samples are pinned/verified by tools/audio_sample_manifest.json. Only the
finished original arrangements are distributed; the cache stays in user://.
"""
from __future__ import annotations

import hashlib
import json
import math
import os
import re
from pathlib import Path

import numpy as np
import soundfile as sf

from audio_score import SCORES

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/audio"
CACHE = Path(os.environ["APPDATA"]) / "Godot/app_userdata/A Stroke Of Luck/audio_sources/vcsl"
RATE = 44100
PROTECTED = {
    "terrain_impact.wav": "2e371ca8e048dd0ebca67bad303a77a4426ee67e933032484bd568427ad66de4",
    "boost_pad_slow.wav": "2ebf220b4d1b9cedd3e2a42af1739e105c14f1877e1bddb80145124a61f38cc1",
    "boost_pad_med.wav": "2915a27ba866acbad3ed8ccfc2488a6ae5cece5aea1f06bb584e33fc3d25e996",
    "boost_pad_fast.wav": "c872e472f03c01380daab3686fce0ff8d5047819bcc9fe1d0b396b7fc8876b12",
    "fail_sound_1.wav": "7a41c6a80596db9ae26e44dae5498905bedab6a77889eca963ac2a14aa50da1b",
    "fail_sound_2.wav": "f5d2ac2b046e7f9277dde0dcd55e341e7177d0c792bf5740f94fd80ba46e8292",
}


def midi(name: str) -> int:
    match = re.fullmatch(r"([A-G])([#b]?)(-?\d+)", name)
    if not match:
        raise ValueError(f"Invalid score pitch {name!r}")
    letter, accidental, octave = match.groups()
    return (int(octave) + 1) * 12 + {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}[letter] + {"": 0, "#": 1, "b": -1}[accidental]


def phrase_events(phrase: str, beats: float):
    for bar, text in enumerate(phrase.split("|")):
        cursor = 0.0
        for token in text.split():
            note, duration = token.split(":")
            length = float(duration)
            if note != "-":
                yield bar, cursor, midi(note), length
            cursor += length
        if not math.isclose(cursor, beats):
            raise ValueError(f"Bar {bar}: {cursor} beats, expected {beats}: {text}")


def noise(seconds: float, seed: int, low=100.0, high=6000.0) -> np.ndarray:
    """Broadband circular filtered noise, not a handful of tonal oscillators."""
    count = round(seconds * RATE)
    rng = np.random.default_rng(seed)
    spectrum = np.fft.rfft(rng.standard_normal(count))
    frequencies = np.fft.rfftfreq(count, 1 / RATE)
    shape = (frequencies / (frequencies + low)) ** 2 / (1 + (frequencies / high) ** 4)
    shaped = np.fft.irfft(spectrum * shape, n=count)
    return (shaped / max(np.std(shaped), 1e-9)).astype(np.float32)


def envelope(samples: np.ndarray, attack=0.002, release=0.04) -> np.ndarray:
    result = samples.copy()
    a, r = min(len(result), round(attack * RATE)), min(len(result), round(release * RATE))
    if a:
        result[:a] *= np.linspace(0, 1, a)
    if r:
        result[-r:] *= np.linspace(1, 0, r)
    return result


class Sampler:
    def __init__(self):
        self.bank = {}
        manifest = json.loads((ROOT / "tools/audio_sample_manifest.json").read_text())
        self.provenance = []
        for entry in manifest["samples"]:
            path = CACHE / Path(entry["path"]).name
            raw = path.read_bytes()
            blob_hash = hashlib.sha1(f"blob {len(raw)}\0".encode() + raw).hexdigest()
            if blob_hash != entry["sha"]:
                raise ValueError(f"Unverified source sample: {path.name}")
            audio, rate = sf.read(path, dtype="float32", always_2d=True)
            mono = audio.mean(axis=1)
            # Preserve attacks while trimming recording leader, not musical notes.
            active = np.flatnonzero(np.abs(mono) > max(np.max(np.abs(mono)) * 0.012, 0.0001))
            if len(active):
                mono = mono[max(0, active[0] - round(rate * 0.002)):]
            mono = np.interp(np.arange(round(len(mono) * RATE / rate)) * rate / RATE, np.arange(len(mono)), mono).astype(np.float32)
            mono -= np.mean(mono)
            mono /= max(np.max(np.abs(mono)), 0.0001)
            filename = path.name
            pitch_match = re.search(r"_(C[2345]|D[234]|A3|F[234]|G[234])_", filename)
            root_note = midi(pitch_match[1]) if pitch_match else 60
            # The source library labels C3 = MIDI 60 (one octave above scientific).
            # Root pitch verified from the recorded fundamental during source audit.
            if pitch_match:
                root_note += 12
            families = {"GPiano": "piano", "EWHarp": "harp", "Strumstick": "strum", "AltRecorder": "recorder", "Marimba": "marimba", "Vibes": "vibes", "Cajon": "cajon", "Claves": "claves", "Mid_Shaker": "shaker", "wood_click": "wood", "BDrum": "drum"}
            family = next(value for prefix, value in families.items() if filename.startswith(prefix))
            self.bank.setdefault(family, []).append((root_note, mono))
            self.provenance.append({"file": filename, "sha256": hashlib.sha256(raw).hexdigest(), "git_blob": blob_hash})
        self.cache = {}

    def note(self, instrument, pitch, seconds, velocity=1.0, alternate=0):
        key = instrument, pitch, round(seconds, 3), alternate % 2
        if key not in self.cache:
            sources = self.bank[instrument]
            source_note, sample = min(sources, key=lambda item: abs(item[0] - pitch)) if instrument not in ("wood", "cajon", "shaker", "drum", "claves") else sources[alternate % len(sources)]
            ratio = 2 ** ((pitch - source_note) / 12) if instrument not in ("wood", "cajon", "shaker", "drum", "claves") else 1.0
            length = min(round(seconds * RATE), int(len(sample) / ratio))
            wave = np.interp(np.arange(length) * ratio, np.arange(len(sample)), sample).astype(np.float32)
            self.cache[key] = envelope(wave, 0.001, min(0.12, seconds * 0.2))
        return self.cache[key] * velocity


def add(buffer, samples, seconds, gain=1.0, pan=0.0, wrap=False):
    start = round(seconds * RATE)
    if buffer.ndim == 2:
        samples = samples[:, None] * np.array([math.sqrt((1 - pan) / 2), math.sqrt((1 + pan) / 2)])
    if wrap:
        start %= len(buffer)
        head = min(len(samples), len(buffer) - start)
        buffer[start:start + head] += samples[:head] * gain
        if head < len(samples):
            buffer[:len(samples) - head] += samples[head:] * gain
    else:
        count = min(len(samples), len(buffer) - start)
        if count > 0 and start >= 0:
            buffer[start:start + count] += samples[:count] * gain


def write(name, samples, peak=0.7, rms_target=None, loop=False):
    if name in PROTECTED:
        raise ValueError(f"Refusing to overwrite preserved cue {name}")
    samples -= samples.mean(axis=0)
    gain = peak / max(np.max(np.abs(samples)), 1e-9)
    if rms_target:
        gain = min(gain, rms_target / max(np.sqrt(np.mean(samples ** 2)), 1e-9))
    samples *= gain
    sf.write(OUTPUT / name, samples, RATE, subtype="PCM_16")
    return {"file": name, "seconds": round(len(samples) / RATE, 5), "peak_dbfs": round(20 * math.log10(max(float(np.max(np.abs(samples))), 1e-9)), 2), "rms_dbfs": round(20 * math.log10(max(float(np.sqrt(np.mean(samples ** 2))), 1e-9)), 2), "loop_seam_step": round(float(np.max(np.abs(samples[-1] - samples[0]))), 6) if loop else None, "sha256": hashlib.sha256((OUTPUT / name).read_bytes()).hexdigest()}


def render_music(sampler, key, score):
    beat = 60 / score["bpm"]
    beats = score["beats"]
    bars = len(score["form"]) * 4
    duration = bars * beats * beat
    result = np.zeros((round(duration * RATE), 2), np.float32)
    groove = score["groove"]
    rng = np.random.default_rng(918 + list(SCORES).index(key))
    for section, letter in enumerate(score["form"]):
        # Written phrases have breathing room; middle sections reduce backing.
        for bar, offset, pitch, length in phrase_events(score["melody"][letter], beats):
            absolute_bar = section * 4 + bar
            onset = (absolute_bar * beats + offset) * beat
            if groove == "swing" and offset % 1 == 0.5:
                onset += beat * 0.10
            velocity = (0.78 + 0.12 * math.sin((offset + 1) * 1.4)) * (0.94 if section % 3 == 2 else 1.0)
            add(result, sampler.note(score["lead"], pitch, length * beat + 0.18, velocity), onset + float(rng.uniform(0, 0.007)), 0.18, -0.15, True)
        for bar, chord_text in enumerate(score["harmony"][letter]):
            absolute_bar = section * 4 + bar
            chord = [midi(note) for note in chord_text.split()]
            start = absolute_bar * beats * beat
            root = chord[0]
            # Sparse counterweight, with roots/fifths rather than a random walk.
            bass_steps = [0] if groove in ("practice", "air", "waltz") else ([0, 1.5, 2.5] if groove == "caravan" else [0, 2.0, 3.5])
            for index, offset in enumerate(bass_steps):
                pitch = root + (7 if index == 1 else 0)
                add(result, sampler.note(score["bass"], pitch, beat * 1.4), start + offset * beat, 0.21 if groove == "embers" else 0.14, 0.05, True)
            comp_steps = {"swing": [0.7, 2.6], "practice": [1], "meadow": [0.5, 1.5, 2.5, 3.5], "caravan": [0, 1.5, 2.5], "waltz": [1, 2], "air": [0, 3], "swamp": [0.5, 2.5, 3.5], "embers": [0.5, 1.5, 2.5, 3.5]}[groove]
            for comp_index, offset in enumerate(comp_steps):
                for voice, pitch in enumerate(chord[1:]):
                    add(result, sampler.note(score["comp"], pitch + 12, beat * (2.2 if groove == "air" else 0.8)), start + offset * beat + voice * 0.009, (0.035 if groove in ("practice", "air") else 0.052) * (0.75 if letter == "C" else 1.0), 0.34, True)
            if groove == "air":
                continue
            # Accented sparse physical percussion; not one loop pasted eight times.
            steps = [0, 1.5, 2.5] if groove == "caravan" else ([0, 2] if groove == "waltz" else [0, 1, 2, 3])
            for step in steps:
                if groove == "practice" and (absolute_bar % 2 or step != 0):
                    continue
                instrument = "drum" if groove == "embers" and step in (0, 2) else "cajon"
                add(result, sampler.note(instrument, 60, 0.5, alternate=absolute_bar + int(step)), start + beat * step + 0.008, 0.08 if groove == "embers" else 0.028, 0.0, True)
            if groove in ("swing", "meadow", "swamp", "caravan", "embers"):
                for step in np.arange(0.5, beats, 0.5):
                    swing = 0.09 if groove in ("swing", "swamp") and step % 1 else 0
                    add(result, sampler.note("shaker", 60, 0.13, alternate=int(step * 2)), start + beat * (step + swing), 0.018 if step % 1 else 0.012, -0.4, True)
            if absolute_bar % 4 == 3 and groove not in ("practice", "waltz"):
                for offset in [beats - 0.75, beats - 0.25]:
                    add(result, sampler.note("wood", 60, 0.14), start + beat * offset, 0.018, 0.3, True)
    # Small shared room; all tails wrap into the next downbeat, never fade to silence.
    dry = result.copy()
    for delay, gain in [(0.043, 0.12), (0.087, 0.075), (0.173, 0.055), (0.281, 0.03)]:
        result += np.roll(dry[:, ::-1], round(delay * RATE), axis=0) * gain
    record = write(f"theme_{key}.wav", result, 0.60, 0.11 if key != "tutorial" else 0.085, True)
    record.update({"title": score["title"], "bpm": score["bpm"], "beats_per_bar": beats, "bars": bars, "form": score["form"], "identity": score["identity"], "origin": "Original project score; VCSL CC0 instrument recordings", "score_sha256": hashlib.sha256(json.dumps(score, sort_keys=True).encode()).hexdigest()})
    return record


def render_ambience(key, index):
    duration = 32.0 + index * 2
    count = round(duration * RATE)
    time = np.arange(count) / RATE
    result = noise(duration, 400 + index, 80 if key != "volcanic" else 24, 1900 if key != "snow" else 3500) * 0.07
    result *= 0.68 + 0.18 * np.sin(2 * np.pi * time / duration) + 0.14 * np.sin(6 * np.pi * time / duration + 1)
    rng = np.random.default_rng(620 + index)
    for event in range(7 if key in ("meadow", "swamp") else 4):
        seconds = float(rng.uniform(1, duration - 2))
        length = float(rng.uniform(0.12, 0.6))
        t = np.arange(round(length * RATE)) / RATE
        if key == "meadow":
            frequency = float(rng.uniform(1800, 3000))
            sound = np.sin(2 * np.pi * (frequency * t + 350 * t ** 2)) * np.sin(np.pi * t / length) ** 2 * 0.10
        elif key == "swamp":
            sound = np.sin(2 * np.pi * (180 * t + 35 * np.sin(t * 25))) * np.maximum(np.sin(t * 60), 0) * np.exp(-t * 7) * 0.05
        elif key == "volcanic":
            sound = noise(length, 800 + event, 800, 7000) * np.exp(-t * 23) * 0.04
        else:
            sound = noise(length, 800 + event, 900, 4800) * np.sin(np.pi * t / length) ** 2 * 0.035
        add(result, envelope(sound, 0.01, 0.03), seconds)
    if key == "volcanic":
        result += noise(duration, 555, 20, 110) * 0.08
    if key == "swamp":
        insect = noise(duration, 711, 3000, 4300) * 0.012
        result += insect * (0.5 + 0.5 * np.sin(time * 2 * np.pi * 48 / duration))
    return write(f"ambience_{key}.wav", result, 0.40, 0.09, True)


def render_sfx(sampler):
    records = []
    def impact(name, duration, low, high, gain, body=None):
        t = np.arange(round(duration * RATE)) / RATE
        wave = noise(duration, sum(map(ord, name)), low, high) * np.exp(-t * 65) * gain
        if body:
            add(wave, sampler.note(body, 60, duration), 0.0, 0.65)
        records.append(write(name, envelope(wave, 0.0003, 0.025), 0.70))
    impact("golf_strike.wav", 0.14, 1300, 9000, 0.32, "wood")
    impact("wall_impact.wav", 0.19, 400, 3800, 0.12, "wood")
    impact("ui_hover.wav", 0.045, 1600, 6500, 0.03, "shaker")
    impact("ui_click.wav", 0.075, 900, 4200, 0.04, "wood")
    impact("ui_back.wav", 0.095, 500, 2400, 0.03, "wood")
    impact("card_stack.wav", 0.14, 600, 8000, 0.09, "claves")
    for name, duration in [("water.wav", 0.72), ("lava.wav", 0.85), ("ice_impact.wav", 0.38)]:
        t = np.arange(round(duration * RATE)) / RATE
        wave = noise(duration, sum(map(ord, name)), 100 if name == "water.wav" else 700, 3600 if name == "water.wav" else 9500)
        wave *= np.exp(-t * (8 if name == "ice_impact.wav" else 5)) * 0.2
        if name == "water.wav":
            # Pressure-decaying bubble resonances; no melodic splash arpeggio.
            for onset, frequency in [(0.015, 170), (0.055, 350), (0.13, 230)]:
                local = np.maximum(t - onset, 0)
                wave += (t >= onset) * np.sin(2 * np.pi * (frequency * local - 100 * local ** 2)) * np.exp(-local * 25) * 0.14
        elif name == "ice_impact.wav":
            add(wave, sampler.note("claves", 60, 0.18), 0, 0.2)
        else:
            wave += noise(duration, 91, 25, 140) * np.exp(-t * 6) * 0.10
        records.append(write(name, envelope(wave), 0.65))
    cup = np.zeros(round(0.5 * RATE), np.float32)
    for onset, gain in [(0, 0.45), (0.075, 0.26), (0.15, 0.13)]:
        add(cup, sampler.note("wood", 60, 0.16, alternate=int(onset * 100)), onset, gain)
    records.append(write("cup_sink.wav", cup, 0.65))
    purchase = np.zeros(round(0.60 * RATE), np.float32)
    add(purchase, sampler.note("wood", 60, 0.10), 0, 0.24)
    for onset, note in [(0.035, "E6"), (0.105, "G6"), (0.23, "C6")]:
        add(purchase, sampler.note("vibes", midi(note), 0.32), onset, 0.23)
    records.append(write("purchase.wav", purchase, 0.70))
    dark = np.zeros(round(0.48 * RATE), np.float32)
    add(dark, sampler.note("piano", midi("D3"), 0.3)[::-1], 0, 0.4)
    add(dark, sampler.note("wood", 60, 0.15), 0.28, 0.2)
    records.append(write("curse.wav", envelope(dark, 0.035, 0.07), 0.48))
    error = np.zeros(round(0.18 * RATE), np.float32)
    add(error, sampler.note("wood", 60, 0.085), 0, 0.4)
    add(error, sampler.note("wood", 60, 0.085, alternate=1), 0.075, 0.3)
    records.append(write("ui_error.wav", error, 0.50))
    for name, notes, seconds in [
        ("hole_completion.wav", [(0, "E5"), (0.12, "G5"), (0.26, "C6")], 0.9),
        ("biome_transition.wav", [(0, "C5"), (0.16, "G5"), (0.32, "A5"), (0.48, "E6")], 1.3),
        ("final_run_completion.wav", [(0, "C5"), (0.18, "E5"), (0.36, "G5"), (0.54, "A5"), (0.78, "G5"), (1.03, "C6")], 2.8),
    ]:
        sound = np.zeros(round(seconds * RATE), np.float32)
        for onset, note in notes:
            add(sound, sampler.note("vibes", midi(note), 1.0), onset, 0.3)
        if name == "final_run_completion.wav":
            for pitch in ["C3", "E4", "G4", "A4"]:
                add(sound, sampler.note("piano", midi(pitch), 1.6), 1.03, 0.22)
        records.append(write(name, sound, 0.65))
    records.append(write("high_speed_swoosh.wav", noise(4.0, 99, 600, 5500), 0.42, 0.10, True))
    return records


def main():
    for name, expected in PROTECTED.items():
        if hashlib.sha256((OUTPUT / name).read_bytes()).hexdigest() != expected:
            raise ValueError(f"Protected cue changed before generation: {name}")
    sampler = Sampler()
    records = render_sfx(sampler)
    for key, score in SCORES.items():
        record = render_music(sampler, key, score)
        records.append(record)
        print(f"Rendered {key}: {record['seconds']:.2f}s, {record['rms_dbfs']} dBFS RMS", flush=True)
    for index, key in enumerate(list(SCORES)[2:]):
        records.append(render_ambience(key, index))
    report = {"score_revision": 2, "sample_rate": RATE, "source_samples": sampler.provenance, "assets": records, "protected": PROTECTED, "subjective_listening": "NOT PERFORMED - human approval required"}
    report_path = OUTPUT / "audio_manifest.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    for name, expected in PROTECTED.items():
        assert hashlib.sha256((OUTPUT / name).read_bytes()).hexdigest() == expected
    print(f"Rendered {len(records)} assets; preserved six approved/supplied cues byte-exact.")


if __name__ == "__main__":
    main()
