"""Dataset integrity, correct denominators, and human-readable benchmark reports."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import statistics

EXPECTED = {"Theorem": "proved", "Unsatisfiable": "proved",
            "CounterSatisfiable": "not_entailed", "Satisfiable": "not_entailed"}
MODES = ("baseline", "optimized")


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def snapshot(root):
    """Fail closed on a modified/missing snapshot, instead of re-labelling it."""
    root = Path(root).resolve()
    manifest_path = root / "manifest.json"
    if not manifest_path.exists():
        return None, sorted(root.rglob("*.p"))
    manifest = json.loads(manifest_path.read_text())
    for name, expected_hash in manifest["files"].items():
        path = (root / name).resolve()
        if not path.is_relative_to(root) or not path.is_file() or digest(path) != expected_hash:
            raise ValueError("Snapshot integrity failure: " + name)
    files = []
    for name in manifest["problem_paths"]:
        if name not in manifest["files"]:
            raise ValueError("Unhashed manifest problem: " + name)
        files.append(root / name)
    if len(files) != len(set(files)):
        raise ValueError("Duplicate problem in manifest")
    return {**manifest, "manifest_sha256": digest(manifest_path)}, files


def annotate(result, expected):
    status = result["status"]
    mismatch = expected is not None and status in {"proved", "not_entailed"} and status != expected
    checked = bool(result.get("proof_checked")) and status == "proved"
    verification_failure = status == "proved" and not checked
    correct = expected is not None and status == expected and not verification_failure
    return {"expected": expected, "mismatch": mismatch, "correct": correct,
            "verification_failure": verification_failure, "proof_checked": checked}


def per_problem(problems, rows, repeats):
    table = []
    for problem in problems:
        row = {k: problem.get(k) for k in ("name", "expected", "expected_tptp_status", "unsupported")}
        for mode in MODES:
            runs = [r for r in rows if r["name"] == problem["name"] and r["mode"] == mode]
            all_done = len(runs) == repeats
            statuses = Counter(r["status"] for r in runs)
            verified_all = all_done and all(r["proof_checked"] for r in runs)
            correct_all = all_done and all(r["correct"] for r in runs)
            row[mode] = {"statuses": dict(statuses), "correct_all_repetitions": correct_all,
                         "checked_proof_all_repetitions": verified_all,
                         "inconsistent_decisions": "proved" in statuses and "not_entailed" in statuses,
                         "median_ms": statistics.median(r["metrics"]["elapsed_ms"] for r in runs)
                         if runs and all("elapsed_ms" in r["metrics"] for r in runs) else None}
        table.append(row)
    return table


def summarize(rows, mode, table):
    runs = [r for r in rows if r["mode"] == mode]
    accepted = sum(not p["unsupported"] for p in table)
    correct = sum(p[mode]["correct_all_repetitions"] for p in table)
    proved = sum(p[mode]["checked_proof_all_repetitions"] and p["expected"] == "proved" for p in table)
    positive = sum(p["expected"] == "proved" for p in table)
    return {"attempts": len(runs), "statuses": dict(Counter(r["status"] for r in runs)),
            "total_selected": len(table), "accepted": accepted, "unsupported": len(table) - accepted,
            "correct_all_repetitions": correct, "checked_proved_problems": proved,
            "positive_problems": positive,
            "solve_rate_all_selected": correct / len(table) if table else None,
            "solve_rate_accepted": correct / accepted if accepted else None,
            "proof_coverage": proved / positive if positive else None,
            "checked_proof_runs": sum(r["proof_checked"] for r in runs),
            "answer_mismatches": sum(r["mismatch"] for r in runs),
            "verification_failures": sum(r["verification_failure"] for r in runs),
            "peak_rss_bytes": max((r["metrics"].get("peak_rss_bytes", 0) for r in runs), default=0)}


def comparisons(rows, table):
    common = []
    for problem in table:
        if problem["expected"] != "proved" or not all(problem[m]["correct_all_repetitions"] for m in MODES):
            continue
        runs = {m: [r for r in rows if r["name"] == problem["name"] and r["mode"] == m] for m in MODES}
        times = {m: statistics.median(r["metrics"]["elapsed_ms"] for r in rs) for m, rs in runs.items()}
        pairs = {m: statistics.median(r["metrics"]["literal_pair_checks"] for r in rs) for m, rs in runs.items()}
        memory = {m: statistics.median(r["metrics"]["peak_rss_bytes"] for r in rs) for m, rs in runs.items()}
        common.append({"name": problem["name"], "median_ms": times, "median_pair_checks": pairs,
                       "median_peak_rss_bytes": memory, "speedup": times["baseline"] / max(times["optimized"], .0001)})
    return common


def markdown(report):
    def label(p, mode):
        if p["unsupported"]:
            return "unsupported"
        return ", ".join(f"{status} × {n}" for status, n in p[mode]["statuses"].items())
    lines = [f"# {report['corpus']}", "", f"Recorded: {report['created_utc']}", "",
             f"{report['total_problems']} selected problems; {report['accepted_problems']} accepted; "
             f"{len(report['unsupported'])} unsupported. {report['repeat']} repetitions per mode.", "",
             f"Limits: {report['limits']['seconds']} seconds / {report['limits']['max_clauses']} retained clauses per run.", "",
             "| Mode | Correct in every repetition / all selected | Checked proved / positive problems | Unsupported | Mismatches |",
             "|---|---:|---:|---:|---:|"]
    for mode, s in report["summary"].items():
        rate = 100 * (s["solve_rate_all_selected"] or 0)
        lines.append(f"| {mode} | {s['correct_all_repetitions']}/{s['total_selected']} ({rate:.1f}%) | "
                     f"{s['checked_proved_problems']}/{s['positive_problems']} | {s['unsupported']} | {s['answer_mismatches']} |")
    lines += ["", "A correct result must agree with the library status in every repetition. Unknown, error, and unsupported are not solved. "
              "Satisfiable cases count as correct decisions, not constructed proofs. Proof checks cover resolution/factoring, not preprocessing.", "",
              "This is a small, deliberately selected historical TPTP subset, not a representative sample of the current library or a competition result.", "",
              "## Per-problem results", "", "| Problem | Library status | Baseline | Optimized |", "|---|---|---|---|"]
    for p in report["problems"]:
        lines.append(f"| {p['name']} | {p['expected_tptp_status'] or p['expected']} | {label(p, 'baseline')} | {label(p, 'optimized')} |")
    lines += ["", "## Unsupported inputs", ""]
    lines += [f"- {p['name']}: {p['reason']}" for p in report["unsupported"]] or ["None."]
    lines += ["", "## Paired proof timings", "", "Only known positive problems proved and checked by both modes in every repetition are compared. "
              "These medians measure the OCaml pipeline; timeouts are excluded, never treated as measured proof times. "
              "Very short timings are noisy.", "", "| Problem | Baseline median ms | Optimized median ms | Speedup | Candidate pairs, baseline → optimized |",
              "|---|---:|---:|---:|---:|"]
    for c in report["common_solved_comparisons"]:
        lines.append(f"| {c['name']} | {c['median_ms']['baseline']:.4f} | {c['median_ms']['optimized']:.4f} | "
                     f"{c['speedup']:.2f}× | {c['median_pair_checks']['baseline']:g} → {c['median_pair_checks']['optimized']:g} |")
    lines += ["", "The JSON report contains the corpus manifest, hashes (including axiom dependencies), environment, source and executable hashes, "
              "per-run timings and memory, and proof-record paths. See docs/TPTP_EVALUATION.md for methodology and reproduction.", ""]
    return "\n".join(lines)
