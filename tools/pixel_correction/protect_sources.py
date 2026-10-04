"""Snapshot source bytes before this sample and verify their preservation later."""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "artifacts/pixel_correction/protected_sources.json"
PATHS = ["scripts", "scenes", "data", "assets", "tests"]
EXTRA = ["project.godot", "export_presets.cfg", "tools/pixel_sample"]


def inventory():
    result = {}
    for entry in PATHS + EXTRA:
        path = ROOT / entry
        files = path.rglob("*") if path.is_dir() else [path]
        for file in files:
            if not file.is_file() or file.suffix in {".import", ".uid"}:
                continue
            if "pixel_correction" in file.parts:
                continue
            result[file.relative_to(ROOT).as_posix()] = hashlib.sha256(file.read_bytes()).hexdigest()
    return result


if "--snapshot" in sys.argv:
    if DEST.exists():
        raise SystemExit("Snapshot already exists; refusing to replace baseline.")
    DEST.write_text(json.dumps(inventory(), indent=2) + "\n")
    print("Saved source baseline.")
else:
    before, after = json.loads(DEST.read_text()), inventory()
    # Two virtual factory seams preserve the old harness's default behavior.
    permitted = {"tools/pixel_sample/pixel_sample.gd"}
    changed = [name for name, digest in before.items() if after.get(name) != digest]
    unexpected = sorted(set(changed) - permitted)
    report = {"protected_files": len(before), "changed": changed,
              "unexpected": unexpected, "passed": not unexpected,
              "approved_logo_unchanged": before["assets/pixel_sample/ui/wordmark.png"] == after["assets/pixel_sample/ui/wordmark.png"]}
    (DEST.parent / "preservation_check.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report["passed"] and report["approved_logo_unchanged"] else 1)
