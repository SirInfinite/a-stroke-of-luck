"""Generate the original audio layer for A Stroke of Luck.

The output is deterministic 44.1 kHz, 16-bit mono PCM. No third-party samples
or copyrighted recordings are used; every waveform is synthesized below.
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
    duration = 0.58
    notes = [(0.00, 523.25), (0.11, 659.25), (0.23, 783.99), (0.34, 1046.50)]
    samples = _render(duration, lambda t: sum(
        _pulse(t, start, 0.22) * (_tone(freq, t - start) + 0.24 * _tone(freq * 2.0, t - start))
        for start, freq in notes
    ))
    _write_wav("purchase.wav", _fade(samples, 0.003, 0.06))


def generate_error() -> None:
    duration = 0.34
    samples = _render(duration, lambda t: (
        _tone(255.0 - 105.0 * t / duration, t)
        + 0.32 * _tone((255.0 - 105.0 * t / duration) * 2.03, t)
    ) * (1.0 - t / duration) ** 1.2)
    _write_wav("ui_error.wav", _fade(samples, 0.003, 0.035))


def generate_golf_strike() -> None:
    duration = 0.22
    noise = _filtered_noise(duration, 23, 0.24)
    samples = _render(duration, lambda t: (
        0.95 * _tone(112.0 - 68.0 * t / duration, t) * math.exp(-18.0 * t)
        + 0.35 * _tone(890.0, t) * math.exp(-44.0 * t)
    ))
    for index, value in enumerate(noise):
        samples[index] += 0.65 * value * math.exp(-38.0 * index / SAMPLE_RATE)
    _write_wav("golf_strike.wav", _fade(samples, 0.001, 0.035))


def generate_ball_roll() -> None:
    duration = 1.2
    rng = random.Random(37)
    components = []
    for _ in range(28):
        target_frequency = rng.uniform(170.0, 2400.0)
        frequency = round(target_frequency * duration) / duration
        components.append((frequency, rng.uniform(0.0, TAU), rng.uniform(0.25, 1.0)))
    samples = _render(duration, lambda t: (
        0.35 + 0.65 * (0.5 + 0.5 * _tone(5.0, t))
    ) * sum(weight * _tone(frequency, t, phase) for frequency, phase, weight in components))
    _write_wav("ball_roll.wav", samples, 0.56)


def generate_terrain_impact() -> None:
    duration = 0.31
    noise = _filtered_noise(duration, 41, 0.09)
    samples = _render(duration, lambda t: 0.72 * _tone(138.0 - 50.0 * t / duration, t) * math.exp(-15.0 * t))
    for index, value in enumerate(noise):
        time = index / SAMPLE_RATE
        samples[index] += value * math.exp(-12.0 * time) * 1.2
    _write_wav("terrain_impact.wav", _fade(samples, 0.001, 0.05))


def generate_water() -> None:
    duration = 0.72
    noise = _filtered_noise(duration, 53, 0.025)
    samples = _render(duration, lambda t: sum(
        _pulse(t, start, 0.18) * _tone(frequency, t - start)
        for start, frequency in [(0.08, 420.0), (0.22, 570.0), (0.39, 760.0)]
    ))
    for index, value in enumerate(noise):
        time = index / SAMPLE_RATE
        samples[index] += value * math.exp(-3.8 * time) * 1.5
    _write_wav("water.wav", _fade(samples, 0.002, 0.09))


def generate_cup_sink() -> None:
    duration = 0.62
    samples = _render(duration, lambda t: (
        0.7 * _tone(610.0 - 390.0 * t / duration, t) * math.exp(-6.0 * t)
        + _pulse(t, 0.31, 0.27) * (_tone(880.0, t - 0.31) + 0.35 * _tone(1320.0, t - 0.31))
    ))
    _write_wav("cup_sink.wav", _fade(samples, 0.002, 0.08))


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


def generate_ambience_loop() -> None:
    duration = 12.0
    chord = [(130.81, 0.38), (164.81, 0.30), (196.00, 0.32), (261.63, 0.16)]
    aligned = [(round(frequency * duration) / duration, weight) for frequency, weight in chord]
    air = [(round(frequency * duration) / duration, phase, weight) for frequency, phase, weight in [
        (733.0, 0.7, 0.012), (947.0, 2.1, 0.009), (1213.0, 4.4, 0.007), (1549.0, 5.2, 0.005)
    ]]
    samples = _render(duration, lambda t: (
        (0.72 + 0.13 * _tone(1.0 / duration, t) + 0.08 * _tone(2.0 / duration, t, 1.2))
        * sum(weight * (_tone(frequency, t) + 0.14 * _tone(frequency * 2.0, t)) for frequency, weight in aligned)
        + sum(weight * _tone(frequency, t, phase) for frequency, phase, weight in air)
    ))
    _write_wav("ambience_loop.wav", samples, 0.42)


def main() -> None:
    generators = [
        generate_ui_hover,
        generate_ui_click,
        generate_purchase,
        generate_error,
        generate_golf_strike,
        generate_ball_roll,
        generate_terrain_impact,
        generate_water,
        generate_cup_sink,
        generate_hole_completion,
        generate_biome_transition,
        generate_final_run_completion,
        generate_ambience_loop,
    ]
    for generator in generators:
        generator()
    print(f"Generated {len(generators)} original WAV assets in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
