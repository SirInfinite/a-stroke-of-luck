"""Read-only preservation and portable-runtime audit for this visual migration."""
from pathlib import Path
import fnmatch
import hashlib
import json
import re
import argparse

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--evidence', default='artifacts/production_visual')
parser.add_argument('--reconstruction', action='store_true')
args = parser.parse_args()
EVIDENCE = ROOT / args.evidence
baseline = json.loads((EVIDENCE / "baseline_hashes.json").read_text(encoding="utf-8"))
checks = []

def check(name, passed, details=None):
    checks.append({"check": name, "passed": bool(passed), "details": details})

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

protected_code = {
    "ball_motion.gd", "trajectory_predictor.gd", "hole_generator.gd",
    "course_grammar.gd", "course_quality.gd", "course_motifs.gd",
    "level_validator.gd", "gameplay_hazard.gd", "moving_hazard.gd",
    "elevation_ramp.gd", "card_database.gd", "card_definition.gd",
    "card_effect_resolver.gd", "card_rarity_profile.gd", "run_state.gd",
    "run_stats.gd", "difficulty_database.gd", "difficulty_profile.gd",
    "game_settings.gd", "course_camera.gd", "vs_match_state.gd",
    "vs_match_controller.gd", "ai_shot_planner.gd", "ai_course_model.gd",
    "audio_controller.gd", "audio_cue_catalog.gd", "feedback_director.gd",
}
if args.reconstruction:
    protected_code.remove('feedback_director.gd')
    protected_code.update({'golf_ball.gd', 'shop_manager.gd'})
for relative, sha in baseline.items():
    path = ROOT / relative
    protected = (
        relative.startswith(("assets/references/", "assets/audio/", "assets/presentation/cards/"))
        or relative in ("assets/pixel_sample/source/wordmark.png", "assets/pixel_sample/ui/wordmark.png", "project.godot")
        or path.name in protected_code
        or path.suffix.lower() in (".wav", ".ogg", ".mp3", ".flac", ".mp4", ".mov")
    )
    if protected:
        check("unchanged " + relative, path.is_file() and digest(path) == sha)

approved = ROOT / "assets/pixel_sample/ui/wordmark.png"
production = ROOT / "assets/brand/approved_wordmark.png"
check("production logo exactly matches approval", digest(approved) == digest(production))
font = ROOT / "assets/fonts/Jersey10/Jersey10-Regular.ttf"
check("production font exactly matches approval", digest(font) == digest(ROOT / "assets/reference_slice/ui/fonts/Jersey10-Regular.ttf"))
check("production font license retained", (font.parent / "OFL.txt").is_file())

config = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
patterns = re.search(r'exclude_filter="([^"]*)"', config)[1].split(", ")
def excluded(relative):
    return any(fnmatch.fnmatch(relative, pattern) for pattern in patterns)

runtime_files = [p for base in ("scripts", "scenes") for p in (ROOT / base).rglob("*") if p.suffix in (".gd", ".tscn", ".tres")]
runtime_files.append(ROOT / "assets/release_theme.tres")
for path in runtime_files:
    text = path.read_text(encoding="utf-8")
    check("no legacy ordinary font " + path.relative_to(ROOT).as_posix(), not re.search("Fredoka|Atkinson", text))
    for reference in sorted(set(re.findall(r'res://([^"\n]+)', text))):
        if "%" in reference or not Path(reference).suffix:
            continue
        target = ROOT / reference
        check("runtime dependency " + reference, target.is_file() and not excluded(reference))

for folder in ("assets/world", "assets/presentation/cards", "assets/ui/panels", "assets/fonts/Jersey10"):
    for path in (ROOT / folder).rglob("*"):
        if path.suffix.lower() not in (".png", ".ttf") or "source" in path.parts:
            continue
        check("export includes " + path.relative_to(ROOT).as_posix(), not excluded(path.relative_to(ROOT).as_posix()))
for folder in ("assets/references", "assets/pixel_sample", "assets/pixel_correction", "assets/reference_slice", "artifacts", "tools", "tests"):
    check("export excludes development " + folder, excluded(folder + "/example.png"))

# Compare non-presentation functions against the preserved pre-task sources.
def functions(text):
    matches = list(re.finditer(r"^func ([A-Za-z0-9_]+)\(", text, re.M))
    return {m[1]: text[m.start():matches[i+1].start() if i+1 < len(matches) else len(text)].strip() for i, m in enumerate(matches)}
allowed = {
    "scripts/golf_ball.gd": {"_create_ball_art"},
    "scripts/main.gd": {"_update_status", "_create_main_menu_overlay", "_reset_current_level"},
}
if args.reconstruction:
    allowed = {
        'scripts/main.gd': {'_create_world'},
        'scripts/feedback_director.gd': {'setup'},
        'scripts/tutorial_manager.gd': {'_create_overlay', '_fit_overlay_to_viewport'},
        'scripts/level_builder.gd': {'_create_background'},
    }
for relative, cosmetic in allowed.items():
    old = functions((EVIDENCE / "baseline_sources" / relative).read_text(encoding="utf-8"))
    new = functions((ROOT / relative).read_text(encoding="utf-8"))
    for name, body in old.items():
        if name not in cosmetic:
            check("preserved function " + relative + "::" + name, new.get(name) == body)

failures = [item for item in checks if not item["passed"]]
result = {"checks": len(checks), "failures": failures, "results": checks}
(EVIDENCE / "preservation_report.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
print(f"Production preservation: {len(checks)} checks, {len(failures)} failures")
for item in failures:
    print(item["check"])
raise SystemExit(bool(failures))
