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
        "root": 60, "scale": (0, 2, 4, 7, 9), "tempo": 112.0,
        "chords": (0, 3, 1, 4, 0, 3, 4, 1),
        "motif": (0, 2, 4, 2, 1, -1, 0, 2, 4, 5, 4, 2, 1, 2, 0, -1),
        "instrument": "pluck", "drums": 0.35,
    },
    "meadow": {
        "root": 62, "scale": (0, 2, 4, 7, 9), "tempo": 120.0,
        "chords": (0, 3, 4, 1, 0, 4, 3, 1),
        "motif": (0, 2, 4, 5, 4, 2, 1, -1, 2, 4, 6, 4, 3, 2, 0, -1),
        "instrument": "pluck", "drums": 0.42,
    },
    "desert": {
        "root": 57, "scale": (0, 1, 4, 5, 7, 8, 10), "tempo": 108.0,
        "chords": (0, 3, 1, 0, 4, 3, 1, 0),
        "motif": (0, 1, 2, 1, 0, -1, 4, 3, 2, 1, 0, 1, 3, 2, 1, -1),
        "instrument": "reed", "drums": 0.55,
    },
    "autumn": {
        "root": 57, "scale": (0, 2, 3, 5, 7, 8, 10), "tempo": 104.0,
        "chords": (0, 5, 3, 4, 0, 2, 3, 4),
        "motif": (4, 3, 2, 0, 2, -1, 3, 4, 5, 4, 3, 1, 2, 1, 0, -1),
        "instrument": "mallet", "drums": 0.30,
    },
    "snow": {
        "root": 65, "scale": (0, 2, 3, 7, 9), "tempo": 96.0,
        "chords": (0, 2, 3, 1, 0, 3, 2, 1),
        "motif": (0, 2, 4, 2, 3, -1, 1, 2, 4, 6, 4, 3, 2, 1, 0, -1),
        "instrument": "bell", "drums": 0.18,
    },
    "swamp": {
        "root": 50, "scale": (0, 3, 5, 6, 7, 10), "tempo": 88.0,
        "chords": (0, 3, 1, 0, 4, 1, 3, 0),
        "motif": (0, -1, 1, 0, 3, 2, 1, -1, 0, 2, 4, 3, 2, 1, 0, -1),
        "instrument": "reed", "drums": 0.28,
    },
    "volcanic": {
        "root": 45, "scale": (0, 1, 3, 5, 6, 8, 10), "tempo": 128.0,
        "chords": (0, 1, 0, 4, 0, 3, 1, 0),
        "motif": (0, 1, 3, 1, 0, 4, 3, 1, 0, 1, 5, 4, 3, 1, 0, -1),
        "instrument": "mallet", "drums": 0.72,
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


def generate_music_theme(name: str, config: dict) -> None:
    root = int(config["root"])
    scale = tuple(config["scale"])
    tempo = float(config["tempo"])
    chords = tuple(config["chords"])
    motif = tuple(config["motif"])
    instrument = str(config["instrument"])
    drums = float(config["drums"])
    eighth = 30.0 / tempo
    steps = 64
    duration = eighth * steps

    def sample(time: float) -> float:
        step = min(int(time / eighth), steps - 1)
        local = time - step * eighth
        bar = step // 8
        chord_degree = int(chords[bar % len(chords)])
        motif_degree = int(motif[step % len(motif)])
        variation = 1 if step >= 32 and step % 16 in (10, 12) else 0
        melody = 0.0
        if motif_degree >= 0:
            note = _scale_note(root + 12, scale, motif_degree + variation)
            melody_env = _note_envelope(local, eighth * 0.93, 0.012, eighth * (0.34 if instrument != "bell" else 0.55))
            melody = _instrument_sample(instrument, _midi(note), local) * melody_env * 0.43

        beat = step // 2
        beat_local = time - beat * eighth * 2.0
        bass_note = _scale_note(root - 12, scale, chord_degree)
        bass = _tone(_midi(bass_note), beat_local) * _note_envelope(beat_local, eighth * 1.75, 0.008, eighth * 0.58) * 0.34

        half_bar = eighth * 4.0
        chord_local = time % half_bar
        chord = 0.0
        chord_env = _note_envelope(chord_local, half_bar * 0.96, 0.09, 0.25)
        for offset, weight in ((0, 0.16), (2, 0.12), (4, 0.10)):
            chord_note = _scale_note(root, scale, chord_degree + offset)
            chord += _tone(_midi(chord_note), chord_local) * weight * chord_env

        beat_phase = time % (eighth * 2.0)
        kick = _tone(76.0 - 24.0 * min(beat_phase / 0.11, 1.0), beat_phase) * math.exp(-32.0 * beat_phase) if beat_phase < 0.16 else 0.0
        hat_phase = time % eighth
        hat = (_tone(3920.0, hat_phase) + 0.45 * _tone(5710.0, hat_phase)) * math.exp(-74.0 * hat_phase) if hat_phase < 0.06 else 0.0
        backbeat_phase = (time - eighth * 2.0) % (eighth * 4.0)
        backbeat = _triangle(185.0, backbeat_phase) * math.exp(-34.0 * backbeat_phase) if backbeat_phase < 0.12 else 0.0
        percussion = drums * (0.15 * kick + 0.035 * hat + 0.07 * backbeat)
        return melody + bass + chord + percussion

    _write_wav("theme_%s.wav" % name, _render(duration, sample), 0.70)


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
