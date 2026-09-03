"""Generate original audio for A Stroke of Luck.

The output is deterministic 44.1 kHz, 16-bit mono PCM. No third-party samples
or copyrighted recordings are used; every waveform emitted by this script is
synthesized below. The five project-owner-supplied boost/failure WAV files are
deliberately outside this generator and must never be overwritten here.
"""

from __future__ import annotations

import math
import random
import wave
from pathlib import Path


SAMPLE_RATE = 44_100
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "audio"
TAU = math.tau


def _render(duration: float, sample_fn) -> list[float]:
    return [sample_fn(index / SAMPLE_RATE) for index in range(round(duration * SAMPLE_RATE))]


def _fade(samples: list[float], fade_in: float = 0.005, fade_out: float = 0.025) -> list[float]:
    fade_in_samples = max(1, round(fade_in * SAMPLE_RATE))
    fade_out_samples = max(1, round(fade_out * SAMPLE_RATE))
    total = len(samples)
    for index in range(total):
        gain = min(1.0, index / fade_in_samples, (total - index - 1) / fade_out_samples)
        samples[index] *= max(0.0, gain)
    return samples


def _write_wav(name: str, samples: list[float], peak: float = 0.88) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    sample_peak = max((abs(sample) for sample in samples), default=1.0)
    gain = peak / sample_peak if sample_peak > 0.0 else 1.0
    pcm = bytearray()
    for sample in samples:
        value = max(-1.0, min(1.0, sample * gain))
        pcm.extend(int(round(value * 32767.0)).to_bytes(2, "little", signed=True))
    with wave.open(str(OUTPUT_DIR / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm)


def _tone(frequency: float, time: float, phase: float = 0.0) -> float:
    return math.sin(TAU * frequency * time + phase)


def _triangle(frequency: float, time: float, phase: float = 0.0) -> float:
    return 2.0 / math.pi * math.asin(_tone(frequency, time, phase))


def _midi(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def _note_envelope(local_time: float, duration: float, attack: float = 0.015, release: float = 0.13) -> float:
    if local_time < 0.0 or local_time >= duration:
        return 0.0
    return min(1.0, local_time / max(attack, 0.0001), (duration - local_time) / max(release, 0.0001)) ** 1.35


def _scale_note(root: int, scale: tuple[int, ...], degree: int) -> int:
    octave, wrapped = divmod(degree, len(scale))
    return root + scale[wrapped] + octave * 12


def _pulse(time: float, start: float, length: float) -> float:
    if time < start or time >= start + length:
        return 0.0
    progress = (time - start) / length
    return math.sin(math.pi * progress) ** 1.5


def _filtered_noise(duration: float, seed: int, smoothing: float) -> list[float]:
    rng = random.Random(seed)
    state = 0.0
    samples: list[float] = []
    for _ in range(round(duration * SAMPLE_RATE)):
        state += (rng.uniform(-1.0, 1.0) - state) * smoothing
        samples.append(state)
    return samples


def generate_ui_hover() -> None:
    duration = 0.09
    _write_wav("ui_hover.wav", _fade(_render(duration, lambda t: _tone(720.0 + 430.0 * t / duration, t) * math.exp(-24.0 * t))))


def generate_ui_click() -> None:
    duration = 0.11
    noise = _filtered_noise(duration, 11, 0.38)
    samples = _render(duration, lambda t: 0.75 * _tone(390.0 - 90.0 * t / duration, t) * math.exp(-32.0 * t))
    for index, value in enumerate(noise):
        samples[index] += value * math.exp(-70.0 * index / SAMPLE_RATE) * 0.35
    _write_wav("ui_click.wav", _fade(samples))


def generate_purchase() -> None:
    duration = 0.62
    coin_hits = [(0.00, 1320.0), (0.065, 1661.2), (0.15, 2093.0)]
    samples = _render(duration, lambda t: (
        sum(
            _pulse(t, start, 0.12)
            * (_tone(frequency, t - start) + 0.42 * _tone(frequency * 1.51, t - start))
            * math.exp(-11.0 * max(0.0, t - start))
            for start, frequency in coin_hits
        )
        + _pulse(t, 0.27, 0.28) * _triangle(235.0, t - 0.27) * math.exp(-7.0 * max(0.0, t - 0.27))
    ))
    _write_wav("purchase.wav", _fade(samples, 0.001, 0.08), 0.78)


def generate_error() -> None:
    duration = 0.34
    samples = _render(duration, lambda t: (
        _tone(255.0 - 105.0 * t / duration, t)
        + 0.32 * _tone((255.0 - 105.0 * t / duration) * 2.03, t)
    ) * (1.0 - t / duration) ** 1.2)
    _write_wav("ui_error.wav", _fade(samples, 0.003, 0.035))


def generate_golf_strike() -> None:
    duration = 0.18
    noise = _filtered_noise(duration, 23, 0.34)
    samples = _render(duration, lambda t: (
        0.88 * _tone(155.0 - 72.0 * t / duration, t) * math.exp(-31.0 * t)
        + 0.54 * _tone(1260.0, t) * math.exp(-61.0 * t)
        + 0.22 * _tone(2480.0, t) * math.exp(-85.0 * t)
    ))
    for index, value in enumerate(noise):
        samples[index] += 0.46 * value * math.exp(-58.0 * index / SAMPLE_RATE)
    _write_wav("golf_strike.wav", _fade(samples, 0.0005, 0.028), 0.82)


def generate_high_speed_swoosh() -> None:
    duration = 1.6
    rng = random.Random(37)
    components = []
    for _ in range(20):
        target_frequency = rng.uniform(380.0, 4100.0)
        frequency = round(target_frequency * duration) / duration
        components.append((frequency, rng.uniform(0.0, TAU), rng.uniform(0.12, 0.7)))
    samples = _render(duration, lambda t: (
        0.62 + 0.20 * _tone(2.0 / duration, t) + 0.10 * _tone(5.0 / duration, t, 1.7)
    ) * sum(weight * _tone(frequency, t, phase) for frequency, phase, weight in components))
    _write_wav("high_speed_swoosh.wav", samples, 0.42)


def generate_terrain_impact() -> None:
    duration = 0.31
    noise = _filtered_noise(duration, 41, 0.09)
    samples = _render(duration, lambda t: 0.72 * _tone(138.0 - 50.0 * t / duration, t) * math.exp(-15.0 * t))
    for index, value in enumerate(noise):
        time = index / SAMPLE_RATE
        samples[index] += value * math.exp(-12.0 * time) * 1.2
    _write_wav("terrain_impact.wav", _fade(samples, 0.001, 0.05))


def generate_water() -> None:
    duration = 0.76
    noise = _filtered_noise(duration, 53, 0.035)
    samples = _render(duration, lambda t: (
        _pulse(t, 0.0, 0.24) * _tone(118.0 - 52.0 * t / duration, t) * math.exp(-8.0 * t)
        + sum(
            _pulse(t, start, 0.15) * _tone(frequency, t - start) * math.exp(-7.0 * max(0.0, t - start))
            for start, frequency in [(0.08, 420.0), (0.19, 570.0), (0.34, 760.0)]
        )
    ))
    for index, value in enumerate(noise):
        time = index / SAMPLE_RATE
        samples[index] += value * math.exp(-4.2 * time) * 1.65
    _write_wav("water.wav", _fade(samples, 0.002, 0.09))


def generate_lava() -> None:
    duration = 0.82
    noise = _filtered_noise(duration, 57, 0.055)
    samples = _render(duration, lambda t: (
        0.46 * _tone(64.0 - 12.0 * t / duration, t) * math.exp(-3.4 * t)
        + sum(
            _pulse(t, start, 0.11) * (_tone(frequency, t - start) + 0.35 * _tone(frequency * 1.7, t - start))
            for start, frequency in ((0.07, 760.0), (0.24, 1180.0), (0.43, 910.0), (0.61, 1360.0))
        )
    ))
    for index, value in enumerate(noise):
        samples[index] += value * math.exp(-2.6 * index / SAMPLE_RATE) * 1.15
    _write_wav("lava.wav", _fade(samples, 0.001, 0.08), 0.78)


def generate_ice_impact() -> None:
    duration = 0.48
    noise = _filtered_noise(duration, 61, 0.32)
    frequencies = (980.0, 1470.0, 2130.0, 2980.0)
    samples = _render(duration, lambda t: sum(
        weight * _tone(frequency, t) * math.exp(-(16.0 + index * 7.0) * t)
        for index, (frequency, weight) in enumerate(zip(frequencies, (0.62, 0.46, 0.31, 0.18)))
    ))
    for index, value in enumerate(noise):
        samples[index] += 0.38 * value * math.exp(-42.0 * index / SAMPLE_RATE)
    _write_wav("ice_impact.wav", _fade(samples, 0.0005, 0.06), 0.76)


def generate_wall_impact() -> None:
    duration = 0.25
    noise = _filtered_noise(duration, 63, 0.30)
    samples = _render(duration, lambda t: (
        0.75 * _tone(104.0 - 35.0 * t / duration, t) * math.exp(-23.0 * t)
        + 0.25 * _tone(410.0, t) * math.exp(-46.0 * t)
    ))
    for index, value in enumerate(noise):
        samples[index] += 0.24 * value * math.exp(-52.0 * index / SAMPLE_RATE)
    _write_wav("wall_impact.wav", _fade(samples, 0.0005, 0.035), 0.78)


def generate_cup_sink() -> None:
    duration = 0.56
    noise = _filtered_noise(duration, 59, 0.28)
    samples = _render(duration, lambda t: (
        0.82 * _tone(142.0 - 62.0 * t / duration, t) * math.exp(-15.0 * t)
        + _pulse(t, 0.17, 0.20) * (_tone(1040.0, t - 0.17) + 0.28 * _tone(1560.0, t - 0.17))
        * math.exp(-13.0 * max(0.0, t - 0.17))
    ))
    for index, value in enumerate(noise):
        samples[index] += 0.34 * value * math.exp(-45.0 * index / SAMPLE_RATE)
    _write_wav("cup_sink.wav", _fade(samples, 0.001, 0.07), 0.80)


def generate_hole_completion() -> None:
    duration = 0.98
    notes = [(0.00, 392.00), (0.15, 523.25), (0.31, 659.25), (0.47, 783.99)]
    samples = _render(duration, lambda t: sum(
        _pulse(t, start, 0.42) * (_tone(freq, t - start) + 0.18 * _tone(freq * 2.0, t - start))
        for start, freq in notes
    ))
    _write_wav("hole_completion.wav", _fade(samples, 0.002, 0.12))


def generate_biome_transition() -> None:
    duration = 1.35
    noise = _filtered_noise(duration, 67, 0.008)
    samples = _render(duration, lambda t: (
        _tone(220.0 + 330.0 * t / duration, t) * math.sin(math.pi * t / duration) ** 1.7
        + 0.32 * _tone(440.0 + 440.0 * t / duration, t) * math.sin(math.pi * t / duration) ** 2.0
    ))
    for index, value in enumerate(noise):
        progress = index / max(1, len(noise) - 1)
        samples[index] += value * math.sin(math.pi * progress) * 1.2
    _write_wav("biome_transition.wav", _fade(samples, 0.015, 0.12))


def generate_final_run_completion() -> None:
    duration = 2.45
    notes = [
        (0.00, 261.63), (0.18, 329.63), (0.36, 392.00),
        (0.65, 523.25), (0.82, 659.25), (0.99, 783.99),
        (1.30, 523.25), (1.30, 659.25), (1.30, 783.99),
    ]
    samples = _render(duration, lambda t: sum(
        _pulse(t, start, 0.55 if start < 1.2 else 1.05)
        * (_tone(freq, t - start) + 0.20 * _tone(freq * 2.0, t - start))
        for start, freq in notes
    ))
    _write_wav("final_run_completion.wav", _fade(samples, 0.002, 0.2))


MUSIC_THEMES = {
    "menu": {
        "style": "lucky_waltz", "root": 60, "scale": (0, 2, 4, 7, 9),
        "tempo": 80.0, "bar_beats": 3, "bars": 16,
        "chords": (0, 3, 1, 4, 0, 2, 4, 1),
        "motif": (0, 2, 4, -1, 5, 4, 2, -1, 1, 3, 5, -1),
    },
    "tutorial": {
        "style": "practice_steps", "root": 60, "scale": (0, 2, 4, 5, 7, 9),
        "tempo": 92.0, "bar_beats": 4, "bars": 16,
        "chords": (0, 3, 4, 0, 1, 3, 4, 0),
        "motif": (0, -1, 2, -1, 4, -1, 2, -1, 1, -1, 3, -1, 4, 3, 2, -1),
    },
    "meadow": {
        "style": "open_fairway", "root": 62, "scale": (0, 2, 4, 7, 9),
        "tempo": 116.0, "bar_beats": 4, "bars": 20,
        "chords": (0, 3, 4, 1, 0, 4, 3, 1, 2, 4),
        "motif": (0, 2, 4, 5, -1, 4, 2, 1, 2, 4, 6, -1, 5, 4, 2, -1),
    },
    "desert": {
        "style": "seven_step_caravan", "root": 57, "scale": (0, 1, 4, 5, 7, 8, 10),
        "tempo": 106.0, "bar_beats": 3.5, "bars": 20,
        "chords": (0, 3, 1, 0, 4, 3, 1, 0, 5, 1),
        "motif": (0, 1, 2, -1, 1, 4, -1, 3, 2, 1, 0, -1, 5, -1),
    },
    "autumn": {
        "style": "leaf_ballad", "root": 57, "scale": (0, 2, 3, 5, 7, 8, 10),
        "tempo": 84.0, "bar_beats": 3, "bars": 16,
        "chords": (0, 5, 3, 4, 0, 2, 3, 4),
        "motif": (4, -1, 3, 2, -1, 0, 2, -1, 3, 5, -1, 4, 3, 1, 2, -1, 1, 0),
    },
    "snow": {
        "style": "crystal_air", "root": 65, "scale": (0, 2, 3, 7, 9),
        "tempo": 72.0, "bar_beats": 5, "bars": 8,
        "chords": (0, 2, 3, 1, 0, 3, 2, 1),
        "motif": (0, -1, -1, 2, -1, 4, -1, -1, 3, -1, 1, -1, -1, 4, -1, 6, -1, -1, 2, -1),
    },
    "swamp": {
        "style": "bog_shuffle", "root": 50, "scale": (0, 3, 5, 6, 7, 10),
        "tempo": 72.0, "bar_beats": 6, "bars": 8,
        "chords": (0, 3, 1, 0, 4, 1, 3, 0),
        "motif": (0, -1, 1, 0, -1, 3, 2, -1, 1, -1, 0, -1, 4, 3, -1, 2, 1, -1, 0, -1, 2, -1, 5, -1),
    },
    "volcanic": {
        "style": "magma_drive", "root": 45, "scale": (0, 1, 3, 5, 6, 8, 10),
        "tempo": 132.0, "bar_beats": 4, "bars": 24,
        "chords": (0, 1, 0, 4, 0, 3, 1, 0, 5, 1, 0, 4),
        "motif": (0, 1, 3, 1, 0, -1, 4, 3, 1, 0, 1, 5, 4, 3, 1, -1),
    },
}


def _instrument_sample(kind: str, frequency: float, time: float) -> float:
    if kind == "bell":
        return _tone(frequency, time) + 0.38 * _tone(frequency * 2.01, time) + 0.18 * _tone(frequency * 3.97, time)
    if kind == "reed":
        return 0.72 * _triangle(frequency, time) + 0.20 * _tone(frequency * 2.0, time) + 0.08 * _tone(frequency * 3.0, time)
    if kind == "mallet":
        return _tone(frequency, time) + 0.30 * _tone(frequency * 2.0, time) + 0.12 * _tone(frequency * 3.0, time)
    return 0.78 * _triangle(frequency, time) + 0.22 * _tone(frequency * 2.0, time)


def _sequence_voice(
    time: float,
    step_duration: float,
    sequence: tuple[int, ...],
    root: int,
    scale: tuple[int, ...],
    octave: int,
    instrument: str,
    gate: float,
    gain: float,
    phase_steps: int = 0,
) -> float:
    step_index = int(time / step_duration) + phase_steps
    degree = int(sequence[step_index % len(sequence)])
    if degree < 0:
        return 0.0
    local = time % step_duration
    note = _scale_note(root + octave * 12, scale, degree)
    envelope = _note_envelope(local, step_duration * gate, 0.012, step_duration * (0.42 if instrument == "bell" else 0.24))
    return _instrument_sample(instrument, _midi(note), local) * envelope * gain


def _chord_bed(
    time: float,
    bar_duration: float,
    bar: int,
    root: int,
    scale: tuple[int, ...],
    chords: tuple[int, ...],
    gain: float,
) -> float:
    local = time % bar_duration
    envelope = _note_envelope(local, bar_duration * 0.985, min(0.16, bar_duration * 0.08), min(0.42, bar_duration * 0.14))
    degree = int(chords[bar % len(chords)])
    sound = 0.0
    for offset, weight in ((0, 0.44), (2, 0.31), (4, 0.25)):
        note = _scale_note(root, scale, degree + offset)
        sound += _tone(_midi(note), local) * weight
    return sound * envelope * gain


def generate_music_theme(name: str, config: dict) -> None:
    style = str(config["style"])
    root = int(config["root"])
    scale = tuple(config["scale"])
    tempo = float(config["tempo"])
    bar_beats = float(config["bar_beats"])
    bars = int(config["bars"])
    chords = tuple(config["chords"])
    motif = tuple(config["motif"])
    beat = 60.0 / tempo
    bar_duration = beat * bar_beats
    duration = bar_duration * bars

    def sample(time: float) -> float:
        bar = min(int(time / bar_duration), bars - 1)
        bar_local = time - bar * bar_duration
        section = bar // max(1, bars // 4)
        chord_degree = int(chords[bar % len(chords)])
        bed_gain = {
            "lucky_waltz": 0.18,
            "practice_steps": 0.15,
            "open_fairway": 0.12,
            "seven_step_caravan": 0.10,
            "leaf_ballad": 0.20,
            "crystal_air": 0.13,
            "bog_shuffle": 0.11,
            "magma_drive": 0.09,
        }[style]
        bed = _chord_bed(time, bar_duration, bar, root, scale, chords, bed_gain)

        if style == "lucky_waltz":
            melody = _sequence_voice(time, beat / 2.0, motif, root, scale, 1, "pluck", 0.78, 0.28)
            reply = _sequence_voice(max(0.0, time - beat * 0.75), beat, (4, -1, 3, -1, 2, -1), root, scale, 1, "bell", 0.82, 0.11, section)
            bass_local = bar_local
            bass_note = _scale_note(root - 12, scale, chord_degree)
            bass = _tone(_midi(bass_note), bass_local) * _note_envelope(bass_local, beat * 1.55, 0.02, 0.4) * 0.23
            waltz_step = int(bar_local / beat)
            strum_local = bar_local % beat
            strum = _triangle(_midi(_scale_note(root, scale, chord_degree + (2 if waltz_step else 0))), strum_local)
            strum *= _note_envelope(strum_local, beat * 0.62, 0.01, 0.18) * (0.06 if waltz_step else 0.035)
            return bed + melody + reply + bass + strum

        if style == "practice_steps":
            melody = _sequence_voice(time, beat / 2.0, motif, root, scale, 1, "pluck", 0.58, 0.24)
            bass = _sequence_voice(time, beat, (0, 2, 4, 2), root - 12, scale, 0, "pluck", 0.66, 0.18, bar)
            tick_local = time % beat
            tick = _tone(880.0 if int(time / beat) % 4 == 0 else 660.0, tick_local) * math.exp(-42.0 * tick_local) * 0.025
            answer = _sequence_voice(max(0.0, time - bar_duration * 0.5), beat, (4, -1, 3, -1), root, scale, 1, "mallet", 0.5, 0.09, section)
            return bed + melody + bass + tick + answer

        if style == "open_fairway":
            melody = _sequence_voice(time, beat / 2.0, motif, root, scale, 1, "pluck", 0.72, 0.26, section)
            arpeggio = _sequence_voice(time, beat / 4.0, (0, 2, 4, 2, 1, 3, 5, 3), root, scale, 0, "pluck", 0.42, 0.075, bar)
            bass = _sequence_voice(time, beat, (0, 2, 3, 4), root - 12, scale, 0, "reed", 0.7, 0.17, bar)
            kick_local = time % beat
            kick = _tone(72.0 - 18.0 * min(kick_local / 0.1, 1.0), kick_local) * math.exp(-31.0 * kick_local) * 0.075
            clap_local = (time - beat) % (beat * 2.0)
            clap = _triangle(210.0, clap_local) * math.exp(-38.0 * clap_local) * 0.03 if clap_local < 0.12 else 0.0
            return bed + melody + arpeggio + bass + kick + clap

        if style == "seven_step_caravan":
            eighth = beat / 2.0
            melody = _sequence_voice(time, eighth, motif, root, scale, 1, "reed", 0.9, 0.24, section * 2)
            drone = (_triangle(_midi(root - 12), time) * 0.12 + _tone(_midi(root - 5), time) * 0.06)
            drone *= 0.72 + 0.28 * math.sin(math.pi * bar_local / bar_duration) ** 2
            step = int(bar_local / eighth)
            drum_local = bar_local % eighth
            drum = 0.0
            if step in (0, 3, 5):
                drum = _tone(112.0 if step == 0 else 168.0, drum_local) * math.exp(-27.0 * drum_local) * (0.12 if step == 0 else 0.07)
            pluck = _sequence_voice(time, beat, (0, -1, 3, 1), root - 12, scale, 0, "pluck", 0.48, 0.14, bar)
            return bed + melody + drone + drum + pluck

        if style == "leaf_ballad":
            melody = _sequence_voice(time, beat / 2.0, motif, root, scale, 1, "mallet", 0.88, 0.25, section)
            counter = _sequence_voice(max(0.0, time - beat), beat, (0, 2, -1, 4, 3, -1), root, scale, 0, "reed", 0.82, 0.09, bar)
            bass_local = bar_local % beat
            bass_note = _scale_note(root - 12, scale, chord_degree + (2 if int(bar_local / beat) == 2 else 0))
            bass = _tone(_midi(bass_note), bass_local) * _note_envelope(bass_local, beat * 0.74, 0.02, 0.28) * 0.17
            brush_local = bar_local % beat
            brush = (_tone(1180.0, brush_local) + _tone(1530.0, brush_local, 0.4)) * math.exp(-58.0 * brush_local) * 0.012
            return bed + melody + counter + bass + brush

        if style == "crystal_air":
            melody = _sequence_voice(time, beat / 2.0, motif, root, scale, 1, "bell", 0.98, 0.19, section)
            echo = _sequence_voice(max(0.0, time - beat * 1.5), beat, (4, -1, 2, -1, 5), root, scale, 1, "bell", 0.96, 0.065, bar)
            low_note = _scale_note(root - 12, scale, chord_degree)
            low_air = (_tone(_midi(low_note), time) + 0.3 * _tone(_midi(low_note) * 2.0, time)) * 0.075
            low_air *= 0.7 + 0.3 * _tone(1.0 / bar_duration, time)
            return bed + melody + echo + low_air

        if style == "bog_shuffle":
            triplet = beat / 3.0
            melody = _sequence_voice(time, triplet, motif, root, scale, 1, "reed", 0.82, 0.22, section * 3)
            marimba = _sequence_voice(time, triplet * 2.0, (0, 3, 1, 4, 2, 1), root, scale, 0, "mallet", 0.5, 0.11, bar)
            bass = _sequence_voice(max(0.0, time - triplet), beat, (0, 0, 3, 1, 4, 1), root - 12, scale, 0, "reed", 0.88, 0.18, bar)
            bubble_local = (time - beat * 1.5) % (beat * 3.0)
            bubble = _tone(440.0 - 160.0 * min(bubble_local / 0.18, 1.0), bubble_local) * math.exp(-22.0 * bubble_local) * 0.045 if bubble_local < 0.28 else 0.0
            return bed + melody + marimba + bass + bubble

        eighth = beat / 2.0
        melody = _sequence_voice(time, eighth, motif, root, scale, 1, "mallet", 0.62, 0.22, section)
        ostinato = _sequence_voice(time, beat / 4.0, (0, 0, 1, 0, 3, 0, 1, 4), root - 12, scale, 0, "reed", 0.62, 0.12, bar)
        bass = _sequence_voice(time, beat, (0, 0, 4, 1), root - 12, scale, 0, "mallet", 0.74, 0.18, bar)
        step = int(bar_local / eighth)
        drum_local = bar_local % eighth
        tom = 0.0
        if step in (0, 2, 5, 7):
            tom = _tone(84.0 if step in (0, 5) else 132.0, drum_local) * math.exp(-29.0 * drum_local) * (0.16 if step == 0 else 0.10)
        pulse = _triangle(228.0, drum_local) * math.exp(-44.0 * drum_local) * 0.025
        return bed + melody + ostinato + bass + tom + pulse

    _write_wav("theme_%s.wav" % name, _render(duration, sample), 0.62)


def generate_biome_ambience(name: str, seed: int) -> None:
    duration = 8.0
    rng = random.Random(seed)
    components = []
    for _ in range(9):
        target = rng.uniform(45.0, 1900.0)
        frequency = round(target * duration) / duration
        components.append((frequency, rng.uniform(0.0, TAU), rng.uniform(0.08, 0.34)))

    def air(time: float) -> float:
        return sum(weight * _tone(frequency, time, phase) for frequency, phase, weight in components)

    def sample(time: float) -> float:
        bed = air(time) * (0.55 + 0.16 * _tone(1.0 / duration, time))
        if name == "meadow":
            birds = sum(_pulse(time, start, 0.24) * _tone(freq + 520.0 * (time - start), time - start)
                        for start, freq in ((1.1, 1420.0), (3.4, 1810.0), (6.2, 1530.0)))
            return bed * 0.22 + birds * 0.16
        if name == "desert":
            return bed * 0.31 + 0.05 * _tone(92.0, time)
        if name == "autumn":
            leaves = sum(_pulse(time, start, 0.34) * _tone(freq, time - start)
                         for start, freq in ((0.8, 920.0), (2.7, 1260.0), (5.0, 1080.0), (6.7, 1420.0)))
            return bed * 0.25 + leaves * 0.10
        if name == "snow":
            chimes = sum(_pulse(time, start, 0.5) * (_tone(freq, time - start) + 0.3 * _tone(freq * 2.0, time - start))
                         for start, freq in ((1.5, 1240.0), (4.6, 1660.0), (6.4, 1390.0)))
            return bed * 0.20 + chimes * 0.07
        if name == "swamp":
            insects = 0.09 * _tone(2380.0, time) * max(0.0, _tone(2.0, time))
            bubbles = sum(_pulse(time, start, 0.18) * _tone(freq - 180.0 * (time - start), time - start)
                          for start, freq in ((0.9, 620.0), (3.2, 540.0), (5.8, 710.0)))
            return bed * 0.19 + insects + bubbles * 0.12
        rumble = 0.18 * _tone(47.0, time) + 0.10 * _tone(71.0, time, 0.8)
        crackles = sum(_pulse(time, start, 0.09) * _tone(freq, time - start)
                       for start, freq in ((0.7, 980.0), (2.4, 1330.0), (4.1, 860.0), (6.6, 1510.0)))
        return bed * 0.17 + rumble + crackles * 0.08

    _write_wav("ambience_%s.wav" % name, _render(duration, sample), 0.42)


def main() -> None:
    generators = [
        generate_ui_hover,
        generate_ui_click,
        generate_purchase,
        generate_error,
        generate_golf_strike,
        generate_high_speed_swoosh,
        generate_terrain_impact,
        generate_water,
        generate_lava,
        generate_ice_impact,
        generate_wall_impact,
        generate_cup_sink,
        generate_hole_completion,
        generate_biome_transition,
        generate_final_run_completion,
    ]
    for generator in generators:
        generator()
    for theme_name, theme_config in MUSIC_THEMES.items():
        generate_music_theme(theme_name, theme_config)
    for ambience_index, ambience_name in enumerate(("meadow", "desert", "autumn", "snow", "swamp", "volcanic")):
        generate_biome_ambience(ambience_name, 100 + ambience_index * 17)
    total = len(generators) + len(MUSIC_THEMES) + 6
    print(f"Generated {total} original WAV assets in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
