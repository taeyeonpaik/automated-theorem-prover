"""Sequential, reproducible local/TPTP evaluation with auditable proof records."""
import argparse
from datetime import datetime, timezone
import json
import platform
from pathlib import Path
import re
import subprocess

import client
import evaluation as ev
import tptp

ROOT = Path(__file__).resolve().parent


def load_corpus(directory):
    manifest, files = ev.snapshot(directory)
    if not files:
        raise ValueError("No .p problems found")
    problems, descriptors, hashes = [], [], {}
    for path in files:
        name = str(path.relative_to(directory))
        status = re.search(r"^%\s*Status\s*:\s*(\w+)", path.read_text(), flags=re.M)
        status = status.group(1) if status else None
        descriptor = {"name": name, "expected_tptp_status": status,
                      "expected": ev.EXPECTED.get(status), "unsupported": None}
        hashes[name] = ev.digest(path)
        try:
            problem = tptp.load(path, root=directory)
            hashes.update(problem["source_hashes"])
            client.check_input(problem)
            problems.append({**problem, "name": name, "expected": descriptor["expected"]})
        except (ValueError, OSError) as error:
            descriptor["unsupported"] = str(error)
        descriptors.append(descriptor)
    return manifest, problems, descriptors, hashes


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tptp", nargs="?", type=Path, const=ROOT / "benchmarks/tptp-v3.3.0",
                        help="Use bundled frozen corpus, or specify a TPTP library/subset root")
    parser.add_argument("--seconds", type=float, default=1)
    parser.add_argument("--max-clauses", type=int, default=5000)
    parser.add_argument("--repeat", type=int, default=3)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.repeat < 1:
        parser.error("--repeat must be positive")
    limits = {"seconds": args.seconds, "max_clauses": args.max_clauses}
    client.validate({"goal": "true", **limits})
    if not (ROOT / "bin/qed").exists():
        parser.error("Run make first")
    if args.tptp:
        manifest, problems, descriptors, hashes = load_corpus(args.tptp.resolve())
        corpus = f"QED TPTP 64 — TPTP {manifest['tptp_version']}" if manifest else "User-supplied TPTP subset (version unspecified)"
    else:
        path = ROOT / "benchmarks/suite.json"
        problems = json.loads(path.read_text())
        descriptors = [{"name": p["name"], "expected": p.get("expected"),
                        "expected_tptp_status": None, "unsupported": None} for p in problems]
        manifest, hashes = None, {path.name: ev.digest(path)}
        corpus = "QED local educational/synthetic suite (not TPTP)"
    output = (args.output or ROOT / ("benchmarks/results-tptp.json" if args.tptp else "benchmarks/results-local.json")).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    proof_dir = output.parent / (output.stem + "-proofs")
    proof_dir.mkdir(exist_ok=True)
    rows = []
    unsupported = [{"name": p["name"], "reason": p["unsupported"]} for p in descriptors if p["unsupported"]]
    source_paths = sorted([*ROOT.glob("*.py"), *ROOT.glob("src/*.ml"), ROOT / "Makefile"])
    provenance = {"corpus": corpus, "created_utc": datetime.now(timezone.utc).isoformat(),
                  "platform": platform.platform(), "processor": platform.machine(),
                  "python": platform.python_version(), "ocaml": subprocess.check_output(["ocamlopt", "-version"], text=True).strip(),
                  "limits": limits, "repeat": args.repeat, "selection": manifest,
                  "input_hashes": hashes, "prover_sha256": ev.digest(ROOT / "bin/qed"),
                  "source_hashes": {str(p.relative_to(ROOT)): ev.digest(p) for p in source_paths},
                  "total_problems": len(descriptors), "accepted_problems": len(problems), "unsupported": unsupported,
                  "measurement_notes": "Sequential fresh processes; mode order alternates by repetition. Metadata is not passed to proof search. "
                    "Search/normalization/replay time excludes parsing and startup; process_wall_ms includes prover startup; peak_rss_bytes is per prover. "
                    "Both modes use the same CNF limit (10000), clause cap, and wall-time budget. Python adds a 1-second hard-timeout grace."}
    def write_report(complete=False):
        table = ev.per_problem(descriptors, rows, args.repeat)
        report = {**provenance, "complete": complete, "runs": rows, "problems": table,
                  "mismatches": sum(r["mismatch"] for r in rows),
                  "verification_failures": sum(r["verification_failure"] for r in rows),
                  "inconsistent_decisions": sum(p[m]["inconsistent_decisions"] for p in table for m in ev.MODES),
                  "summary": {m: ev.summarize(rows, m, table) for m in ev.MODES},
                  "common_solved_comparisons": ev.comparisons(rows, table)}
        temporary = output.with_suffix(".tmp")
        temporary.write_text(json.dumps(report, indent=2) + "\n")
        temporary.replace(output)
        output.with_suffix(".md").write_text(ev.markdown(report))
        return report
    write_report()
    print(f"{corpus}: {len(problems)}/{len(descriptors)} inputs accepted; {len(unsupported)} unsupported", flush=True)
    try:
        for repetition in range(args.repeat):
            for number, problem in enumerate(problems, 1):
                for mode in (ev.MODES if repetition % 2 == 0 else tuple(reversed(ev.MODES))):
                    try:
                        result = client.run({**problem, "mode": mode, **limits})
                    except (RuntimeError, subprocess.TimeoutExpired, OSError, ValueError) as error:
                        result = {"status": "error", "reason": str(error), "proof_checked": False, "metrics": {}}
                    row = {"name": problem["name"], "repetition": repetition + 1, "mode": mode,
                           "status": result["status"], "reason": result["reason"], "metrics": result["metrics"],
                           **ev.annotate(result, problem.get("expected"))}
                    if row["proof_checked"]:
                        filename = re.sub(r"[^A-Za-z0-9_.+-]", "_", problem["name"]) + f".{mode}.r{repetition+1}.json"
                        artifact = proof_dir / filename
                        artifact.write_text(json.dumps(result, indent=2) + "\n")
                        row["proof_artifact"] = str(artifact.relative_to(output.parent))
                        row["proof_sha256"] = ev.digest(artifact)
                    rows.append(row)
                write_report()
                print(f"Repeat {repetition+1}/{args.repeat}, {number}/{len(problems)}: {problem['name']} — "
                      + ", ".join(f"{r['mode']}={r['status']}" for r in rows[-2:]), flush=True)
    except KeyboardInterrupt:
        write_report()
        print("Interrupted; partial report saved (complete=false)")
        raise SystemExit(130)
    report = write_report(complete=True)
    print(json.dumps({"summary": report["summary"], "mismatches": report["mismatches"]}, indent=2))
    print(f"Saved {output} and {output.with_suffix('.md')}")
    if report["mismatches"] or report["verification_failures"] or report["inconsistent_decisions"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
