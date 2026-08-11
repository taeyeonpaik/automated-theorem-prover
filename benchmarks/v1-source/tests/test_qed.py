import itertools
import json
import random
import subprocess
import tempfile
import unittest
from pathlib import Path

import client
import storage
import tptp


def direct(premises, goal, baseline=False):
    command = [str(client.ROOT / "bin/qed"), "--seconds", "1", "--max-clauses", "3000"]
    if baseline:
        command.append("--baseline")
    proc = subprocess.run(command, input="\n".join(premises + ["---", goal]),
                          capture_output=True, text=True, timeout=3)
    return json.loads(proc.stdout)


class SemanticTests(unittest.TestCase):
    def test_propositional_truth_table_oracle(self):
        # Independent semantics, rather than comparing the prover to itself.
        rng = random.Random(147)
        def generate(depth):
            if depth == 0 or rng.random() < .25:
                return rng.choice("pqr")
            op = rng.choice(["~", "&", "|", "->", "<->"])
            return (op, generate(depth-1)) if op == "~" else (op, generate(depth-1), generate(depth-1))
        def show(f):
            if isinstance(f, str):
                return f
            return "~(" + show(f[1]) + ")" if f[0] == "~" else f"({show(f[1])} {f[0]} {show(f[2])})"
        def evaluate(f, assignment):
            if isinstance(f, str):
                return assignment[f]
            a = evaluate(f[1], assignment)
            if f[0] == "~":
                return not a
            b = evaluate(f[2], assignment)
            return {"&": a and b, "|": a or b, "->": not a or b, "<->": a == b}[f[0]]
        for i in range(120):
            premise, goal = generate(2), generate(3)
            valid = all(not evaluate(premise, dict(zip("pqr", values))) or evaluate(goal, dict(zip("pqr", values)))
                        for values in itertools.product([False, True], repeat=3))
            for baseline in (False, True):
                with self.subTest(case=i, baseline=baseline):
                    result = direct([show(premise)], show(goal), baseline)
                    self.assertEqual(result["status"], "proved" if valid else "not_entailed")
                    self.assertEqual(result["proof_checked"], valid)

    def test_finite_model_counterexamples(self):
        # These each have an explicit countermodel. Saturation may not finish,
        # but proof search must never produce a proof of these implications.
        cases = [
            (["exists x. p(x)"], "forall x. p(x)"),
            (["forall x. exists y. r(x,y)"], "exists y. forall x. r(x,y)"),
            (["forall x. p(x) | q(x)"], "(forall x. p(x)) | (forall x. q(x))"),
            (["exists x. p(x)", "exists x. ~p(x)"], "false"),
            (["forall x. r(x,x)"], "forall x y. r(x,y)"),
            (["forall x. p(x) -> q(x)", "exists x. q(x)"], "exists x. p(x)"),
            (["p(a)", "~p(b)"], "a = b"),
            (["exists x. p(x)", "~p(sk1)", "~p(sk2)", "~p(sk3)"], "false"),
        ]
        for premises, goal in cases:
            with self.subTest(goal=goal):
                self.assertIn(direct(premises, goal)["status"], ["not_entailed", "unknown"])

    def test_inconsistent_arity_rejected(self):
        self.assertEqual(direct(["p(a)"], "p(a,b)")["status"], "error")

    def test_unknown_on_clause_limit(self):
        result = client.run({"premises": ["p(a)", "forall x. p(x) -> p(f(x))"],
                             "goal": "q", "max_clauses": 3})
        self.assertEqual(result["status"], "unknown")
        self.assertFalse(result["proof_checked"])


class BoundaryTests(unittest.TestCase):
    def test_validation(self):
        for p in [{"goal": ""}, {"goal": "p\n---\nq"}, {"goal": "p", "seconds": float("nan")},
                  {"goal": "p", "mode": "anything"}, {"goal": "p", "premises": ["# false"]}]:
            with self.subTest(problem=p), self.assertRaises(ValueError):
                client.validate(p)

    def test_worker_metrics_and_storage(self):
        result = client.run({"premises": ["p"], "goal": "p"})
        self.assertTrue(result["proof_checked"])
        self.assertGreater(result["metrics"]["peak_rss_bytes"], 0)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "qed.db"
            storage.save(result, path)
            storage.save(result, path)
            history = storage.history(path)
            self.assertEqual(history["counts"], {"problems": 1, "runs": 2, "checked_proof_runs": 2,
                "distinct_proved_problems": 1, "distinct_premise_texts": 1})
            self.assertEqual(history["runs"][0]["result"], result)

    def test_tptp_fof(self):
        problem = tptp.parse("""% Status : Theorem
            fof(rule,axiom, ! [X] : (p(X) => q(X))).
            fof(fact,axiom,p(a)). fof(goal,conjecture,q(a)).""")
        self.assertEqual(problem["expected_tptp_status"], "Theorem")
        self.assertTrue(client.run(problem)["proof_checked"])

    def test_tptp_cnf(self):
        problem = tptp.parse("cnf(a,axiom,p(X) | q(X)). cnf(b,negated_conjecture,~p(a)). cnf(c,axiom,~q(a)).")
        self.assertEqual(problem["goal"], "false")
        self.assertTrue(client.run(problem)["proof_checked"])

    def test_tptp_unsupported_is_explicit(self):
        for text in ["include('Axioms/a.ax').", "tff(a,type,p:$o).", 'fof(a,axiom,$distinct(a,b)).',
                     "fof(a,unknown,p).", "fof(a,axiom,p)",
                     "fof(a,conjecture,p). fof(b,conjecture,q)."]:
            with self.subTest(text=text), self.assertRaises(tptp.Unsupported):
                tptp.parse(text)


if __name__ == "__main__":
    unittest.main()
