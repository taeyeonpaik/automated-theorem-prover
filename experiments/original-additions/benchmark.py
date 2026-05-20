"""Reproducible comparisons; local fixtures are explicitly NOT TPTP results."""
import argparse
from collections import Counter
import hashlib
import json
import platform
import statistics
import subprocess
from datetime import datetime, timezone
from pathlib import Path

import client
import tptp

ROOT = Path(__file__).resolve().parent


def summarize(rows, mode):
    runs = [r for r in rows if r["mode"] == mode]
    counts = Counter(r["status"] for r in runs)
    times = [r["metrics"]["elapsed_ms"] for r in runs if r["status"] == "proved"]
    return {"attempts": len(runs), "statuses": dict(counts),
            "checked_proof_runs": sum(r["proof_checked"] for r in runs),
            "median_solved_ms": statistics.median(times) if times else None,
            "peak_rss_bytes": max((r["metrics"]["peak_rss_bytes"] for r in runs), default=None)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tptp", type=Path, help="Directory of self-contained .p files (restricted subset)")
    parser.add_argument("--seconds", type=float, default=1)
    parser.add_argument("--max-clauses", type=int, default=5000)
    parser.add_argument("--repeat", type=int, default=3)
    parser.add_argument("--output", type=Path, default=ROOT / "benchmarks/results.json")
    args = parser.parse_args()
    if args.repeat < 1:
        parser.error("--repeat must be positive")
    unsupported, hashes = [], {}
    if args.tptp:
        problems = []
        files = sorted(args.tptp.rglob("*.p"))
        if not files:
            parser.error("No .p files found")
        for path in files:
            name = str(path.relative_to(args.tptp))
            hashes[name] = hashlib.sha256(path.read_bytes()).hexdigest()
            try:
                problems.append({**tptp.load(path), "name": name})
            except (ValueError, OSError) as error:
                unsupported.append({"name": name, "reason": str(error)})
        corpus = "user-supplied TPTP subset"
    else:
        path = ROOT / "benchmarks/suite.json"
        hashes[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
        problems = json.loads(path.read_text())
        corpus = "QED local educational/synthetic suite (not TPTP)"
    rows = []
    mapping = {"Theorem": "proved", "Unsatisfiable": "proved", "CounterSatisfiable": "not_entailed", "Satisfiable": "not_entailed"}
    for repetition in range(args.repeat):
        for problem in problems:
            for mode in (["baseline", "optimized"] if repetition % 2 == 0 else ["optimized", "baseline"]):
                result = client.run({**problem, "mode": mode, "seconds": args.seconds, "max_clauses": args.max_clauses})
                expected = problem.get("expected", mapping.get(problem.get("expected_tptp_status")))
                mismatch = expected is not None and result["status"] in {"proved", "not_entailed"} and result["status"] != expected
                rows.append({"name": problem["name"], "repetition": repetition + 1,
                             "mode": mode, "status": result["status"], "reason": result["reason"],
                             "expected": expected, "mismatch": mismatch,
                             "proof_checked": result["proof_checked"], "metrics": result["metrics"]})
        print(f"Completed repetition {repetition + 1}/{args.repeat}", flush=True)
    common = []
    for problem in problems:
        group = {m: [r for r in rows if r["name"] == problem["name"] and r["mode"] == m] for m in ["baseline", "optimized"]}
        if all(all(r["status"] == "proved" for r in g) for g in group.values()):
            median = {m: statistics.median(r["metrics"]["elapsed_ms"] for r in g) for m, g in group.items()}
            pairs = {m: statistics.median(r["metrics"]["literal_pair_checks"] for r in g) for m, g in group.items()}
            common.append({"name": problem["name"], "median_ms": median, "median_pair_checks": pairs,
                           "speedup": median["baseline"] / max(median["optimized"], 0.0001)})
    report = {"corpus": corpus, "created_utc": datetime.now(timezone.utc).isoformat(),
              "platform": platform.platform(), "processor": platform.machine(),
              "python": platform.python_version(), "ocaml": subprocess.check_output(["ocamlopt", "-version"], text=True).strip(),
              "limits": {"seconds": args.seconds, "max_clauses": args.max_clauses}, "repeat": args.repeat,
              "input_hashes": hashes,
              "prover_sha256": hashlib.sha256((ROOT / "bin/qed").read_bytes()).hexdigest(),
              "total_problems": len(problems) + len(unsupported), "accepted_problems": len(problems),
              "unsupported": unsupported, "mismatches": sum(r["mismatch"] for r in rows),
              "summary": {m: summarize(rows, m) for m in ["baseline", "optimized"]},
              "common_solved_comparisons": common, "runs": rows}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"corpus": corpus, "summary": report["summary"], "mismatches": report["mismatches"]}, indent=2))
    print(f"Saved {args.output}")
    if report["mismatches"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
