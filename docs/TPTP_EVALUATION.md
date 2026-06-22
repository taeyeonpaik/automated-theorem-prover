# Reproducible TPTP evaluation

QED now includes a frozen **64-problem subset of TPTP 3.3.0**, a repeatable
evaluation command, raw result records, saved proof traces, and an evaluation
view in the application. This is a real TPTP evaluation, with a deliberately
limited scope. It is not a run over the entire current TPTP library.

## Completed results

All **366 measured runs** completed: 61 accepted problems × two modes × three
repetitions. The three unsupported cases remain in the 64-problem denominator.

| Stable outcome across all three repetitions | Baseline | Optimized |
|---|---:|---:|
| Correctly solved / all selected | 21/64 (32.8%) | 28/64 (43.8%) |
| Correctly solved / accepted inputs | 21/61 (34.4%) | 28/61 (45.9%) |
| Checked proofs / 54 positive cases | 20/54 (37.0%) | 27/54 (50.0%) |
| Correct negative decisions | 1 | 1 |
| Unknown | 40 | 33 |
| Unsupported | 3 | 3 |
| Answer mismatches / proof-check failures | 0 / 0 | 0 / 0 |

Optimizations increased the stable solved count by seven cases (**33.3% more
correctly solved problems**) and the distinct checked-proof count from 20 to 27
(**35% more proved positive cases**). These percentages describe this fixed
historical subset and these limits, not general first-order accuracy.

The report preserves **141 proof-run records** (60 baseline and 81 optimized),
including repeated runs. All corpus, dependency, source, executable, and saved
proof-record hashes were checked against the completed report. Full per-problem
outcomes and paired timing comparisons are in
[the generated report](../benchmarks/results-tptp.md).

Suggested resume wording, with its scope intact:

> Evaluated an OCaml first-order prover on 64 frozen TPTP 3.3.0 problems;
> indexing, subsumption, and fair clause selection increased checked proofs
> from 20 to 27 under identical 2-second/5,000-clause limits, consistently
> across three repetitions, with no observed answer mismatches.

## Run or reproduce

The snapshot is bundled, so normal evaluation needs no network access:

```sh
make
python3 benchmark.py --tptp --seconds 2 --max-clauses 5000 --repeat 3
```

To reconstruct the exact source snapshot from the official archive:

```sh
python3 fetch_tptp.py
# Or reuse a downloaded archive:
python3 fetch_tptp.py --archive /path/to/TPTP-v3.3.0.tgz
```

`make tptp-eval` performs the fetch and evaluation together. `fetch_tptp.py`
checks the archive SHA-256 before reading it. It copies only selected problems,
their axiom dependencies, the original README, and the archived bug list. It
does not execute downloaded code or unpack arbitrary archive paths.

Output files:

- `benchmarks/results-tptp.json`: raw run data, summaries, source hashes, and
  the frozen corpus manifest.
- `benchmarks/results-tptp.md`: generated tables of every problem and both modes.
- `benchmarks/results-tptp-proofs/`: JSON proof records for every checked proof
  run, with each record's hash stored in the report.
- `benchmarks/tptp-v3.3.0/manifest.json`: exact selection, archive URL/hash, and
  hashes for every original problem, dependency, and supporting document.

Reports are checkpointed after each pair of runs. An interrupted evaluation has
`complete: false`; it must not be presented as a finished result. Previously
saved files in the proof directory are not counted unless referenced by the
current report.

For a different corpus, pass a directory containing problems and its axiom
directory: `python3 benchmark.py --tptp /path/to/TPTP --seconds 5 --repeat 3`.
With a manifest, the exact manifest selection is used. Without one, all `.p`
files under the directory are considered, and the release is labelled unspecified.
Use a new output filename for a new protocol or corpus.

## Corpus and selection

Source: the official archive at
[TPTP-v3.3.0.tgz](https://tptp.org/TPTP/Archive/TPTP-v3.3.0.tgz).
The release README dates this version to June 28, 2007. The historical release
was chosen because it provides a small, accessible, versioned distribution
suitable for this educational prover. The current problem browser returned
missing-file errors when this evaluation was prepared. This choice is disclosed
explicitly; no results here are described as current CASC/TPTP performance.

Archive SHA-256:

```text
299e00b71c01a357626ff6238b005b2856bd1b16a24a7f5b939ec343ee526e3f
```

The selection was frozen **before running QED**, using no solve results or
difficulty ratings:

1. In each of SYN (syntactic logic), PUZ (puzzles), and ALG (algebra), take the
   first nine lexicographically sorted files matching `DDDnnn+1.p` and the first
   nine matching `DDDnnn-1.p`, excluding the parser-demo number `000`.
   This contributes 54 problems, split between FOF and CNF presentations.
2. Add the ten untyped examples listed in the
   [official TPTP Quick Guide](https://tptp.org/UserDocs/QuickGuide/):
   `SYN075-1`, `MGT031-1`, `MGT041-2`, `NLP114-1`, `BOO003-4`, `BOO027-1`,
   `SYN075+1`, `MGT019+2`, `KRS063+1`, and `KRS018+1`.

All ten guide examples exist in this archived release. None of the 64 selected
IDs appears in its archived bug list. The exact IDs are recorded in the
manifest and generated per-problem report, rather than inferred from a future
directory listing. FOF and CNF presentations can encode related underlying
problems; 64 problem files does not mean 64 unrelated mathematical theorems.

The frozen set contains 54 positive cases (`Theorem` or `Unsatisfiable`) and
10 negative cases (`CounterSatisfiable` or `Satisfiable`). It is intentionally
small and skewed toward early numbered problems and guide examples, not a
random or representative sample of the library.

## Supported inputs and exclusions

The adapter supports untyped FOF/CNF, local `include` records (including formula
selection lists), nested includes within the specified library root, and source
annotations. Annotations are ignored as metadata, never treated as premises.
All required included axioms are expanded at their original include position;
missing files, missing selected formula names, cycles, and escaping paths are
reported rather than silently dropped.

The actual OCaml parser checks every accepted problem before measurement.
Unsupported inputs are recorded individually and retained in the full-corpus
denominator. In this snapshot, the three large puzzle problems `PUZ065+1`,
`PUZ066+1`, and `PUZ067+1` exceed QED's existing 500-premise / 64,000-character
input limit after their axiom includes are expanded. They are **unsupported**,
not timeouts or counterexamples. They were not replaced with easier problems.

The importer remains a subset of TPTP: quoted symbols inside formulas, typed or
higher-order languages, interpreted arithmetic, overloaded arities, reverse
implication, XOR, NAND, and NOR are unsupported. Quoted formula names and quoted
include paths are supported. TPTP symbols colliding with QED's language keywords
are rejected instead of changing their meaning. Source annotations are accepted
but their internal semantic metadata is not interpreted.

## Measurement protocol

- Both modes receive the same premises and conjecture, a **two-second search
  budget**, and a **5,000-retained-clause limit**.
- Each accepted problem runs **three times per mode**, sequentially in fresh
  prover processes. Baseline/optimized order alternates between repetitions.
- QED's existing intermediate-CNF limit is 10,000 clauses. The Python worker
  enforces a hard timeout one second beyond the OCaml time budget. A hard
  timeout returns `unknown` with unavailable internal counters, never a proof.
- Expected answers and difficulty ratings are **not passed to proof search**.
  The Python process boundary strips them; the prover receives only formulas,
  mode, and resource limits.
- Benchmark runs are stored in report files, not mixed into the application's
  interactive run database.
- The baseline is FIFO with duplicate/tautology removal. Optimized mode adds
  indexing, forward subsumption, and fair age/weight selection. This evaluates
  the combined optimizations; it is not an ablation of each one individually.

`elapsed_ms` covers OCaml normalization, search, proof extraction, and replay;
it excludes parsing and process startup. `process_wall_ms` includes starting the
prover and handling its output, but not TPTP import or the outer Python worker's
startup. Peak RSS describes the individual prover process. Cumulative OCaml
allocation is a separate measurement and is not peak memory.

The report records source and executable hashes, compiler/Python versions,
platform, limits, repetition count, corpus hashes including dependencies, and
each run's status and measurements. The original local-suite report is retained
as an earlier measurement; its executable hash may differ from this revision,
which adds an input-validation CLI option without changing proof search.

## Scoring and correctness

| Published TPTP status | Expected QED answer |
|---|---|
| Theorem | `proved` |
| Unsatisfiable | `proved` (refutation of the clause/formula set) |
| CounterSatisfiable | `not_entailed` |
| Satisfiable | `not_entailed` (a contradiction does not follow) |

For CNF/no-positive-conjecture inputs, the adapter asks whether `false` follows
from all input clauses. A `negated_conjecture` is already negated and is included
as an input constraint; it is not negated a second time. With a positive FOF
conjecture, QED negates it once as part of its usual refutation procedure.

The headline solve rate requires the expected answer in **every repetition**.
Unknown, unsupported, and errors do not count as solved. The report shows both
the full selected denominator and the accepted-input denominator, plus separate
proof coverage over positive cases. An answer mismatch means an actual decision
contradicts the published status. No answer is inferred from a timeout. Repeated
proof runs are not counted as distinct problems.

A claimed proof counts only if QED's inference replay passes. The runner saves
the trace and rejects unverified proof claims in its scoring. The checker still
trusts parsing, clausification, equality axioms, and shared term operations;
this is not external independent certification or a formal correctness proof.
Saturation-based negative answers are compared to the library labels but have
no exported countermodel certificate in this version.

Runtime speedups are calculated only for known positive problems solved and
checked by both modes in every repetition. Timeouts are censored, not measured
proof times. Inspect per-problem medians; short runtimes can be noisy. Do not
present the largest individual speedup as a general improvement across TPTP.

## Application

Restart `python3 server.py` after updating the server. The **TPTP evaluation**
section shows the completed report (or explicitly marks an in-progress report),
the solve counts and exclusions, and a selector for every frozen problem.
**Load TPTP problem** fills the existing premise/conclusion controls and sets the
evaluation's limits, so you can try a case or inspect a new proof yourself.
Oversized cases remain visible and explain why they cannot load. Full repeated
evaluation runs from the CLI; **Refresh evaluation** reloads the saved report.

## Validation and attribution

Tests cover include selection, annotation handling, missing/cyclic/escaping
includes, the `<=>` versus `<=` distinction, reserved-word collisions, snapshot
tampering, status/verification scoring, unsupported-case denominators, partial
repetitions, and a complete miniature evaluation that saves proof artifacts.
The existing semantic and prover tests continue to run with `make test`.

TPTP is copyrighted by Geoff Sutcliffe and Christian Suttner. All bundled TPTP
problem and axiom files are **verbatim**, with headers intact; their original
conditions are in `benchmarks/tptp-v3.3.0/Documents/ReadMe`. These files are not
relicensed under QED's MIT license. The manifest is project-generated metadata.

During execution, comments/metadata are removed, whitespace is normalized,
includes are expanded, and the conjecture is separated from premises. QED then
adds its documented equality axioms and performs its ordinary normalization and
search ordering. No original premise is removed based on its header or expected
status. These transformations are disclosed to satisfy the source library's
evaluation conditions.
