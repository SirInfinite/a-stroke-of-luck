"""Summarize local baseline/benchmark evidence; no third-party dependencies."""
import argparse
import collections
import json
import statistics
from pathlib import Path


def average(rows, key):
    return round(statistics.mean(row[key] for row in rows), 3)


def aggregate(rows):
    counts = collections.Counter()
    for row in rows:
        counts.update(row.get("independent_by_type", {}))
    signature_count = len({row["structural_signature"] for row in rows})
    result = {
        "holes": len(rows),
        "invalid": sum(not row["valid"] for row in rows),
        "fallbacks": sum(row["fallback"] for row in rows),
        "candidate_rejections": sum(row["rejections"] for row in rows),
        "generation_retries": sum(row["retries"] for row in rows),
        "quality_rejections": sum(row.get("quality_rejections", 0) for row in rows),
        "unique_structures": signature_count,
        "duplicate_occurrences_after_first": len(rows) - signature_count,
        "holes_with_movers": sum(row["movers"] > 0 for row in rows),
        "elevated_holes": sum(row["elevation"] for row in rows),
        "underpasses": sum(row["underpasses"] for row in rows),
        "threat_type_totals": dict(counts),
    }
    for key in ["width_cells", "height_cells", "surfaces", "route_length_px",
                "independent_threats", "threats_per_100_surfaces", "route_relevant_threats",
                "corridor_surface_fraction", "centerline_surface_fraction", "movers",
                "recovery_surfaces", "clear_recovery_surfaces", "alternatives", "dead_ends",
                "candidates", "generation_ms"]:
        if key in rows[0]:
            result[key + "_mean"] = average(rows, key)
    result["map_size_range_cells"] = {
        key: [min(row[key] for row in rows), max(row[key] for row in rows)]
        for key in ["width_cells", "height_cells", "route_length_px"]
    }
    if "generation_ms" in rows[0]:
        timings = sorted(row["generation_ms"] for row in rows)
        result["generation_ms_p95"] = round(timings[int((len(timings) - 1) * 0.95)], 3)
        result["generation_ms_max"] = round(timings[-1], 3)
    return result


def orientations(row):
    """All grid symmetries, translated only; lengths/widths are not rescaled."""
    variants = []
    for mirror in [False, True]:
        for turns in range(4):
            def turn(cell):
                x, y, z = cell
                if mirror:
                    x = -x
                for _ in range(turns):
                    x, y = -y, x
                return x, y, z

            cells = [turn(cell) for cell in row["geometry_cells"]]
            ox = min(cell[0] for cell in cells)
            oy = min(cell[1] for cell in cells)
            shift = lambda cell: (cell[0] - ox, cell[1] - oy, cell[2])
            variants.append((frozenset(shift(cell) for cell in cells),
                             shift(turn(row["start_cell"])), shift(turn(row["hole_cell"]))))
    return variants


def near(first, second):
    a, start_a, end_a = first[0]
    for b, start_b, end_b in second:
        if start_a[2] != start_b[2] or end_a[2] != end_b[2]:
            continue
        # An approach displaced by more than one tile is a different choice.
        if any(abs(p[0] - q[0]) + abs(p[1] - q[1]) > 1
               for p, q in [(start_a, start_b), (end_a, end_b)]):
            continue
        if len(a & b) / len(a | b) >= 0.9:
            return True
    return False


def diversity_within_runs(rows):
    grouped = collections.defaultdict(list)
    for row in rows:
        grouped[(row["difficulty"], row["seed"])].append(row)
    runs = []
    for (tier, seed), holes in grouped.items():
        previous = []
        repeated = 0
        for hole in sorted(holes, key=lambda item: item["hole"]):
            transformed = orientations(hole)
            repeated += any(near(transformed, earlier) for earlier in previous)
            previous.append(transformed)
        runs.append({"difficulty": tier, "seed": seed, "holes": len(holes), "near_repeat_occurrences": repeated})
    return {"definition": ">=90% cell/layer Jaccard after translation and D4 symmetry, tee and cup each within one cell; any earlier hole in the same run; ramp edges not compared by this approximate measure",
            "runs": runs, "near_repeat_occurrences": sum(run["near_repeat_occurrences"] for run in runs)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("evidence", type=Path)
    args = parser.parse_args()
    baseline = json.loads((args.evidence / "baseline.json").read_text(encoding="utf-8"))
    rows = baseline["records"]
    report = {"seed_formula": baseline["seed_formula"], "seed_count": baseline["seed_count"],
              "baseline": aggregate(rows), "by_difficulty": {}, "by_stage": {}, "by_biome": {}}
    for key in ["difficulty", "stage", "biome"]:
        for value in sorted({row[key] for row in rows}):
            report["by_" + key][value] = aggregate([row for row in rows if row[key] == value])
    report["within_run_diversity"] = diversity_within_runs(rows)
    physics_path = args.evidence / "checkpoint_physics.json"
    if physics_path.exists():
        records = json.loads(physics_path.read_text(encoding="utf-8"))["records"]
        benchmark = [row["metrics"] for row in records if row.get("kind") == "geometry"]
        report["benchmark"] = aggregate(benchmark)
        report["benchmark_holes"] = [dict(id=row["id"], **aggregate([row])) for row in benchmark]
    for name in ["strategies", "baseline_strategies"]:
        path = args.evidence / ("checkpoint_" + name + ".json")
        if not path.exists():
            continue
        strategies = json.loads(path.read_text(encoding="utf-8"))["records"]
        report[name] = {}
        for strategy in sorted({row["strategy"] for row in strategies}):
            selected = [row for row in strategies if row["strategy"] == strategy]
            winners = [row for row in selected if row["cup_completed"]]
            report[name][strategy] = {"holes": len(selected), "completed": len(winners),
                                      "strokes_on_completed_mean": average(winners, "strokes") if winners else None}
    (args.evidence / "summary.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"baseline": report["baseline"], "benchmark": report.get("benchmark"),
                      "strategies": report.get("strategies"), "baseline_strategies": report.get("baseline_strategies"),
                      "within_run_near_repeats": report["within_run_diversity"]["near_repeat_occurrences"]}, indent=2))


if __name__ == "__main__":
    main()
