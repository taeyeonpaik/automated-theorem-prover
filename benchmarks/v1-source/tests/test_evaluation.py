import json
from pathlib import Path
import subprocess
import tempfile
import unittest

import benchmark
import client
import evaluation as ev
import tptp


class TPTPAdapterTests(unittest.TestCase):
    def test_biconditional_is_not_reverse_implication(self):
        p = tptp.parse("fof(goal,conjecture,(~ ~ p <=> p)).")
        self.assertTrue(client.run(p)["proof_checked"])

    def test_annotations_are_not_assumptions(self):
        p = tptp.parse("fof('a.b',conjecture,p,file('p%q.p','a.b'),[description('/*hi*/')]).")
        self.assertEqual(p["premises"], [])
        self.assertEqual(client.run(p)["status"], "not_entailed")

    def test_includes_selection_and_source_hashes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Axioms").mkdir()
            (root / "Axioms/a.ax").write_text("fof(a,axiom,p). fof(unused,axiom,$false).")
            (root / "Axioms/b.ax").write_text("include('Axioms/a.ax',[a]).")
            (root / "test.p").write_text("% Status : Theorem\ninclude('Axioms/b.ax'). fof(g,conjecture,p).")
            p = tptp.load(root / "test.p", root=root)
            self.assertEqual(p["premises"], ["p"])
            self.assertEqual(len(p["source_hashes"]), 3)
            self.assertTrue(client.run(p)["proof_checked"])
            (root / "test.p").write_text("include('Axioms/a.ax',[]). fof(g,conjecture,p).")
            p = tptp.load(root / "test.p", root=root)
            self.assertEqual(p["premises"], [])
            self.assertEqual(client.run(p)["status"], "not_entailed")

    def test_include_errors_are_not_silently_skipped(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for content in ["include('a.p').", "include('../outside.p').",
                            "include('b.p',[missing]).", "include('missing.p')."]:
                (root / "a.p").write_text(content)
                (root / "b.p").write_text("fof(b,axiom,p).")
                with self.subTest(content=content), self.assertRaises((tptp.Unsupported, OSError)):
                    tptp.load(root / "a.p", root=root)

    def test_reserved_symbols_not_misinterpreted(self):
        for formula in ("true", "false", "forall(a)"):
            with self.assertRaises(tptp.Unsupported):
                tptp.parse(f"fof(g,conjecture,{formula}).")
        self.assertTrue(client.run(tptp.parse("fof(g,conjecture,$true)."))["proof_checked"])

    def test_actual_ocaml_preflight(self):
        client.check_input({"goal": "p <-> p"})
        with self.assertRaises(ValueError):
            client.check_input({"premises": ["p(a)"], "goal": "p(a,b)"})


class EvaluationTests(unittest.TestCase):
    def test_status_and_checker_accounting(self):
        self.assertTrue(ev.annotate({"status": "proved", "proof_checked": True}, "not_entailed")["mismatch"])
        self.assertFalse(ev.annotate({"status": "unknown"}, "not_entailed")["correct"])
        self.assertFalse(ev.annotate({"status": "unknown"}, "proved")["mismatch"])
        self.assertTrue(ev.annotate({"status": "proved", "proof_checked": False}, "proved")["verification_failure"])
        self.assertFalse(ev.annotate({"status": "proved", "proof_checked": True}, None)["correct"])

    def test_denominators_include_unsupported_and_unknown(self):
        problems = [{"name": "a", "expected": "proved", "unsupported": None},
                    {"name": "b", "expected": "proved", "unsupported": "too large"},
                    {"name": "c", "expected": "not_entailed", "unsupported": None}]
        rows = []
        for repeat in (1, 2):
            for name, status, expected in [("a", "proved", "proved"), ("c", "unknown", "not_entailed")]:
                rows.append({"name": name, "mode": "optimized", "repetition": repeat,
                             "status": status, "metrics": {"elapsed_ms": 1},
                             **ev.annotate({"status": status, "proof_checked": status == "proved"}, expected)})
        table = ev.per_problem(problems, rows, 2)
        summary = ev.summarize(rows, "optimized", table)
        self.assertEqual(summary["correct_all_repetitions"], 1)
        self.assertEqual(summary["solve_rate_all_selected"], 1/3)
        self.assertEqual(summary["solve_rate_accepted"], 1/2)
        self.assertEqual(summary["proof_coverage"], 1/2)
        self.assertEqual(ev.summarize(rows[:-1], "optimized", ev.per_problem(problems, rows[:-1], 3))["correct_all_repetitions"], 0)

    def test_snapshot_rejects_tampering(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = root / "a.p"
            path.write_text("fof(a,axiom,p).")
            (root / "manifest.json").write_text(json.dumps({"problem_paths": ["a.p"], "files": {"a.p": ev.digest(path)}}))
            self.assertEqual(ev.snapshot(root)[1], [path.resolve()])
            path.write_text("fof(a,axiom,~p).")
            with self.assertRaises(ValueError):
                ev.snapshot(root)

    def test_runner_end_to_end_with_unsupported(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "yes.p").write_text("% Status : Theorem\nfof(g,conjecture,(p => p)).")
            (root / "no.p").write_text("% Status : CounterSatisfiable\nfof(g,conjecture,p).")
            (root / "typed.p").write_text("% Status : Theorem\ntff(g,conjecture,$true).")
            output = root / "report.json"
            subprocess.run(["python3", str(client.ROOT / "benchmark.py"), "--tptp", str(root),
                            "--repeat", "1", "--output", str(output)], check=True, capture_output=True, timeout=15)
            report = json.loads(output.read_text())
            self.assertTrue(report["complete"])
            self.assertEqual(report["total_problems"], 3)
            self.assertEqual(report["summary"]["optimized"]["correct_all_repetitions"], 2)
            self.assertEqual(report["mismatches"], 0)
            for row in report["runs"]:
                if row["proof_checked"]:
                    self.assertEqual(ev.digest(root / row["proof_artifact"]), row["proof_sha256"])

    def test_frozen_selection_and_known_statuses(self):
        root = client.ROOT / "benchmarks/tptp-v3.3.0"
        if not root.exists():
            self.skipTest("Run fetch_tptp.py for the optional corpus test")
        manifest, problems, descriptors, _ = benchmark.load_corpus(root)
        self.assertEqual(manifest["tptp_version"], "3.3.0")
        self.assertEqual(len(descriptors), 64)
        self.assertEqual(len(problems), 61)
        self.assertTrue(all(p["expected"] in {"proved", "not_entailed"} for p in descriptors))


if __name__ == "__main__":
    unittest.main()
