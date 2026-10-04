"""Fetch the pinned CC0 instrument source cache; never invoked by the game.

Usage: python tools/fetch_audio_samples.py
Only WAV data from the manifest's fixed VCSL revision is downloaded. Existing
verified files are reused; unexpected files are preserved and reported.
"""
import hashlib
import json
import os
from pathlib import Path
from urllib.parse import quote
from urllib.request import urlopen


def main():
    root = Path(__file__).resolve().parents[1]
    manifest = json.loads((root / "tools/audio_sample_manifest.json").read_text())
    cache = Path(os.environ["APPDATA"]) / "Godot/app_userdata/A Stroke Of Luck/audio_sources/vcsl"
    cache.mkdir(parents=True, exist_ok=True)
    for entry in manifest["samples"]:
        destination = cache / Path(entry["path"]).name
        if destination.exists():
            raw = destination.read_bytes()
        else:
            url = f"https://raw.githubusercontent.com/sgossner/VCSL/{manifest['revision']}/{quote(entry['path'])}"
            with urlopen(url, timeout=30) as response:
                raw = response.read(entry["size"] + 1)
        digest = hashlib.sha1(f"blob {len(raw)}\0".encode() + raw).hexdigest()
        if len(raw) != entry["size"] or digest != entry["sha"]:
            raise ValueError(f"Source verification failed; existing file not modified: {destination.name}")
        if not destination.exists():
            destination.write_bytes(raw)
        print(f"VERIFIED {destination.name}")
    print(f"{len(manifest['samples'])} pinned CC0 samples ready in the Godot user-area cache.")


if __name__ == "__main__":
    main()
