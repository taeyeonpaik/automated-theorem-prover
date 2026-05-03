"""Small process boundary around the OCaml prover; no Python proof search."""
import json
import math
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def validate(problem):
    if not isinstance(problem, dict):
        raise ValueError("Expected a problem object")
    premises, goal = problem.get("premises", []), problem.get("goal", "")
    if isinstance(premises, str):
        premises = [p.strip() for p in premises.splitlines() if p.strip()]
    if not isinstance(premises, list) or not all(isinstance(p, str) for p in premises):
        raise ValueError("Premises must be a list of formulas")
    if not isinstance(goal, str) or not goal.strip():
        raise ValueError("Enter a conclusion to prove")
    if any("\n" in p or "\r" in p or p.strip() == "---" or p.lstrip().startswith("#") for p in premises + [goal]):
        raise ValueError("Each formula must occupy one line")
    if len(premises) > 500 or sum(map(len, premises)) + len(goal) > 64000:
        raise ValueError("Input is too large (500 premises / 64,000 characters maximum)")
    mode = problem.get("mode", "optimized")
    if mode not in {"optimized", "baseline"}:
        raise ValueError("Choose optimized or baseline mode")
    seconds, cap = float(problem.get("seconds", 3)), int(problem.get("max_clauses", 5000))
    if not math.isfinite(seconds) or not 0.01 <= seconds <= 30 or not 1 <= cap <= 50000:
        raise ValueError("Use 0.01–30 seconds and 1–50,000 clauses")
    return {"premises": [p.strip() for p in premises], "goal": goal.strip(),
            "mode": mode, "seconds": seconds, "max_clauses": cap}


def run(problem):
    problem = validate(problem)
    if not (ROOT / "bin/qed").exists():
        raise RuntimeError("Compile the OCaml prover first: make")
    # A fresh worker makes RUSAGE_CHILDREN describe this prover alone, rather
    # than the largest child ever launched by the long-lived web server.
    result = subprocess.run([sys.executable, str(ROOT / "client.py"), "--worker"],
                            input=json.dumps(problem), text=True, capture_output=True,
                            timeout=problem["seconds"] + 5, cwd=ROOT)
    if result.returncode:
        raise RuntimeError("The prover worker failed: " + result.stderr[-1000:])
    return json.loads(result.stdout)


def worker(problem):
    import resource
    command = [str(ROOT / "bin/qed"), "--seconds", str(problem["seconds"]),
               "--max-clauses", str(problem["max_clauses"])]
    if problem["mode"] == "baseline":
        command.append("--baseline")
    source = "\n".join(problem["premises"] + ["---", problem["goal"]]) + "\n"
    start = time.perf_counter()
    try:
        process = subprocess.run(command, input=source, text=True, capture_output=True,
                                 timeout=problem["seconds"] + 1)
        if process.stdout.strip():
            result = json.loads(process.stdout)
        else:
            result = {"status": "error", "reason": f"Prover exited with code {process.returncode}"}
    except subprocess.TimeoutExpired:
        result = {"status": "unknown", "reason": "Hard process time limit"}
    usage = resource.getrusage(resource.RUSAGE_CHILDREN)
    metrics = result.setdefault("metrics", {})
    metrics["process_wall_ms"] = round((time.perf_counter() - start) * 1000, 4)
    metrics["peak_rss_bytes"] = int(usage.ru_maxrss * (1 if sys.platform == "darwin" else 1024))
    result.setdefault("mode", problem["mode"])
    result.setdefault("proof", [])
    result.setdefault("proof_checked", False)
    result["problem"] = problem
    return result


if __name__ == "__main__":
    if "--worker" in sys.argv:
        print(json.dumps(worker(validate(json.load(sys.stdin)))))
