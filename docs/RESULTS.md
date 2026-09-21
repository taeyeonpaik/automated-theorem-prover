# Initial measured results

These are **local educational/synthetic benchmark results, not TPTP results**.
They establish that this version runs and give a reproducible baseline. They do
not estimate performance on the general population of first-order problems.

## Protocol

- Corpus: `benchmarks/suite.json`, 20 fixed problems: 18 entailments and two
  non-entailments. Includes elementary logic, equality, factoring, transitivity,
  and synthetic rule chains with/without irrelevant predicates.
- Five repetitions per problem per mode: **200 measured runs**.
- Budget: 1 second and 5,000 retained clauses per run; 10,000 intermediate CNF
  clauses. The outer process timeout is one second beyond the search budget.
- The runner alternates baseline/optimized ordering between repetitions.
- Environment: macOS 26.6.2, arm64, OCaml 5.5.1, Python 3.13.7.
- Recorded at 2026-09-21 01:06 UTC. This corresponds to September 20 locally.
- `benchmarks/results-local.json` contains raw runs, input SHA-256, compiler and
  platform versions, and the matching compiled-prover SHA-256.

Reproduce from the project directory:

```sh
make
python3 benchmark.py --repeat 5 --output benchmarks/results-local.json
```

## Outcomes

| Outcome per repetition | Baseline | Optimized |
|---|---:|---:|
| Entailments proved and inference-checked | 17 / 18 | 18 / 18 |
| Non-entailments correctly saturated | 2 / 2 | 2 / 2 |
| Unknown due to resource limits | 1 / 20 | 0 / 20 |
| Known-answer mismatches | 0 | 0 |

The same outcome counts held across all five repetitions. The baseline's
unknown problem was the equality-substitution demonstration. Across repeated
runs there were 85 checked baseline proofs and 90 checked optimized proofs;
these are repeated runs, not 175 distinct theorems.

"18 / 18" is proof coverage on this deliberately small selection. It is not a
general accuracy claim. The non-entailments contribute to correct decisions,
not to the number of constructed proofs.

## A representative optimization comparison

On **Rule chain 16, 40 irrelevant predicates**, both modes proved the same goal
on every repetition:

| Measurement | Baseline | Optimized |
|---|---:|---:|
| Median OCaml elapsed time | 3.0410 ms | 0.8328 ms |
| Median candidate literal pairs checked | 33,776 | 34 |

That is **3.65× faster** on this fixture and **99.90% fewer candidate literal
pair checks**. Counts are deterministic for the fixed problem and implementation;
sub-millisecond timings are sensitive to system noise. The optimization bundle
combines indexing, forward subsumption, and fair age/weight selection, so this
is not an isolated measurement of indexing alone.

The transitivity example improved from median 573.0731 ms to 0.6828 ms. This
large example-specific gain reflects a poor FIFO search order and should not be
advertised as a general speedup. On the tiny Socrates problem, the optimized
median was slightly slower (0.0250 vs 0.0241 ms), despite fewer candidate pairs.

Maximum measured prover RSS across the entire suite was 15,630,336 bytes in
baseline mode and 5,619,712 bytes in optimized mode. These maxima may come from
different workloads and are **not a paired memory-improvement claim**.

## Validation completed

- **106 OCaml checks**: parsing, unification, scope, Skolem freshness, factoring,
  equality, non-entailments, inference replay, certificate corruption, and limits.
- **Nine Python test methods**, including **120 generated propositional problems
  in both modes** compared against exhaustive truth tables (240 comparisons).
- Worker memory reporting, SQLite deduplication and run counts, restricted
  TPTP FOF/CNF conversion, and explicit unsupported-input rejection.
- Browser checks: load/edit examples, prove, compare modes, expand proof traces,
  show a non-entailment, report invalid input, and report a timeout as unknown.
- No browser console errors in the tested flows.

These checks give practical confidence, not a formal soundness proof. The proof
replayer trusts preprocessing, as explained in the walkthrough.

## Resume wording supported now

> Built QED, an OCaml first-order automated theorem prover with resolution,
> factoring, equality reasoning, and inference-checked proof traces, exposed
> through a JavaScript interface and Python API.

> Added predicate indexing, forward subsumption, and fair clause selection;
> reduced candidate literal comparisons from 33,776 to 34 and median proof time
> by 3.65× on a fixed synthetic rule-chain benchmark across five repetitions.

Use the second bullet only with its benchmark qualification. A subsequent,
separate TPTP evaluation is now available in `benchmarks/results-tptp.md`, with
the protocol in `docs/TPTP_EVALUATION.md`. These original local-suite results
remain unchanged and must not be relabelled as TPTP results.
