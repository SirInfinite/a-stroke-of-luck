"""Cross-check recorded native event frames and the actual exported movie mix.

Source-template correlation establishes signal presence/timing, never subjective
musical character or listening comfort. All outputs are review-only artifacts.
"""
from pathlib import Path
import json
import subprocess

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "artifacts/reference_review/audio"
MOVIE = ROOT / "artifacts/reference_review/cycle2_motion.avi"
LOG = ROOT / "artifacts/reference_review/cycle2_motion/events.json"
FILES = {
    "golf_strike": "assets/reference_slice/audio/strike.ogg",
    "wall_impact": "assets/reference_slice/audio/wall.ogg",
    "slice_pendulum": "assets/reference_slice/audio/pendulum.ogg",
    "cup_sink": "assets/reference_slice/audio/cup.ogg",
    "hole_completion": "assets/reference_slice/audio/success.ogg",
    "purchase": "assets/audio/purchase_coins.wav",
    "curse": "assets/audio/curse.wav",
    "water": "assets/audio/water.wav",
}


def run(args):
    return subprocess.run(args, capture_output=True, check=True, text=True)


def detect_template(mix, rate, sample, source_rate, expected, template_seconds=.12):
    # Native pitch variation is ±1%; test a slightly broader range. Search only
    # near the logged event to avoid correlating musically similar material.
    search_start = round((expected - .10) * rate)
    best = {"correlation": -1}
    for pitch in np.linspace(.982, 1.018, 73):
        count = min(round(template_seconds * rate), round(len(sample) * rate / source_rate / pitch))
        template = np.interp(np.arange(count) * source_rate / rate * pitch,
                             np.arange(len(sample)), sample)
        template -= template.mean()
        segment = mix[search_start:round((expected + .20) * rate) + count]
        size = 1 << (len(segment) + len(template) - 1).bit_length()
        numerator = np.fft.irfft(np.fft.rfft(segment, size) * np.fft.rfft(template[::-1], size), size)[count - 1:len(segment)]
        sums = np.concatenate(([0], np.cumsum(segment)))
        squares = np.concatenate(([0], np.cumsum(segment * segment)))
        local_energy = squares[count:] - squares[:-count] - (sums[count:] - sums[:-count]) ** 2 / count
        denominator = np.sqrt(np.maximum(local_energy, 1e-12) * np.sum(template * template))
        correlations = numerator / denominator
        match = int(np.argmax(correlations))
        if correlations[match] > best["correlation"]:
            best = {"correlation": float(correlations[match]), "detected_seconds": (search_start + match) / rate,
                    "pitch_scale": float(pitch)}
    best["offset_from_frame_ms"] = (best["detected_seconds"] - expected) * 1000
    return best


def main():
    log = json.loads(LOG.read_text(encoding="utf-8"))
    probe = json.loads(run(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(MOVIE)]).stdout)
    video = next(stream for stream in probe["streams"] if stream["codec_type"] == "video")
    numerator, denominator = map(int, video["avg_frame_rate"].split("/"))
    fps = numerator / denominator
    decoded = OUT / "cycle2_motion_mix.wav"
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(MOVIE),
         "-map", "0:a:0", "-c:a", "pcm_s16le", str(decoded)])
    audio, rate = sf.read(decoded, always_2d=True)
    mono = audio.mean(axis=1)
    loud = run(["ffmpeg", "-hide_banner", "-i", str(decoded), "-af",
                "loudnorm=I=-18:TP=-2:LRA=9:print_format=json", "-f", "null", "-"])
    meter, _ = json.JSONDecoder().raw_decode(loud.stderr[loud.stderr.rfind("{\n"):])
    alignments = []
    for event in log["events"]:
        if event["event"] != "audio" or event["cue"] not in FILES:
            continue
        sample, source_rate = sf.read(ROOT / FILES[event["cue"]], always_2d=True)
        expected = event["frame"] / fps
        # The reversed-piano curse has a deliberately slow onset; include its
        # later wood transient to avoid ambiguous periodic-pitch correlation.
        match = detect_template(mono, rate, sample.mean(axis=1), source_rate, expected,
                                .36 if event["cue"] == "curse" else .12)
        alignments.append({"cue": event["cue"], "frame": event["frame"], "frame_seconds": expected, **match})
    events = log["events"]
    semantic_matches = []
    for event in events:
        wanted = {"shot": "golf_strike", "wall": "wall_impact", "purchase": "purchase"}.get(event["event"])
        if event["event"] == "hazard":
            wanted = {"pendulum": "slice_pendulum", "water": "water"}.get(event["kind"])
        if wanted:
            matched = [cue for cue in events if cue["event"] == "audio" and cue.get("cue") == wanted and cue["frame"] == event["frame"]]
            semantic_matches.append({"event": event["event"], "cue": wanted, "frame": event["frame"], "same_frame_cue_count": len(matched)})
    purchase_count = sum(event["event"] == "audio" and event.get("cue") == "purchase" for event in events)
    generic_click_count = sum(event["event"] == "audio" and event.get("cue") == "ui_click" for event in events)
    report = {
        "movie": MOVIE.relative_to(ROOT).as_posix(), "log": LOG.relative_to(ROOT).as_posix(),
        "video_size": [video["width"], video["height"]], "fps": fps, "movie_frames": int(video["nb_frames"]),
        "decoded_seconds": len(audio) / rate, "sample_rate": rate, "channels": audio.shape[1],
        "sample_peak_dbfs": float(20 * np.log10(np.max(np.abs(audio)))), "true_peak_dbtp": float(meter["input_tp"]),
        "integrated_lufs": float(meter["input_i"]), "rms_dbfs": float(20 * np.log10(np.sqrt(np.mean(audio ** 2)))),
        "loudness_range_lu": float(meter["input_lra"]), "clipped_samples": int(np.count_nonzero(np.abs(audio) >= .999)),
        "semantic_matches": semantic_matches, "source_template_signal_alignment": alignments,
        "purchase_cue_count": purchase_count, "generic_click_count": generic_click_count,
        "cue_pool_sizes_in_all_captures": sorted(set(item["audio_players"] for item in log["performance"])),
        "limits": "Native events plus decoded signal analysis only; no subjective listening. Frame time follows 60 Hz physics counter; decoded-template onset can differ by a mixer block/frame.",
    }
    (OUT / "integrated_movie_audit.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
