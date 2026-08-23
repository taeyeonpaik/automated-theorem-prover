# Full TPTP 9.3.1 evaluation

This evaluation selects **all 17,912 untyped first-order problem files** in the
official TPTP 9.3.1 release: **9,436 FOF and 8,476 CNF**, across every domain.
The archive contains 26,990 problem files altogether; 9,078 typed/higher-order
or other problem files are outside QED's untyped first-order scope. No selected
problem is filtered out by difficulty, expected answer, size, or search outcome.
The original 64-problem historical subset remains a quick regression suite.

See [live report](../benchmarks/full-tptp-9.3.1/REPORT.md) and
[machine-readable progress](../benchmarks/full-tptp-9.3.1/summary.json).
Only a report with `complete: true` is a completed evaluation. Counts during
preflight and proof search are partial, not final coverage statistics.

## Sources and selection

- [Official release archive](https://tptp.org/TPTP/Distribution/TPTP-v9.3.1.tgz)
- [Official current bug list](https://tptp.org/TPTP/Distribution/BuggedProblems-v9.3.1.txt)
- [Library manual](https://tptp.org/UserDocs/ProblemLibraryManual/TPTPTR.shtml)

Downloaded archive SHA-256:

```
8e9462d9443a2250000224cf4f7002a64ea02cbe07fa5cdcdecfd0fe8cd81f03
```

The archive is inventoried in full. The standard `+` and `-` filename language
codes select FOF and CNF respectively. Each selected file is then parsed,
including its referenced axiom files and any formula-name selections in
`include(...)` directives. Unsupported constructs are reported; they are never
silently discarded. The original files are retained without modification.
Only axiom sets referenced by that particular problem become its premises.
Annotations, including previously published proofs, are not premises.

All original file hashes, the full inventory (including out-of-scope files),
and the selection rule are saved in `manifest.json`. Source file hashes are
verified before running or resuming; per-problem dependency hashes and the exact
normalized input are retained in `results.sqlite3`.

The 42 selected names mentioned in the downloaded bug list are still attempted,
but excluded from correctness scoring as a conservative policy. Most of these
entries concern metadata, not logical defects. Their exclusion is explicit,
not an assertion that all 42 formulas are wrong.

## Protocol

- Baseline and optimized search each receive every accepted problem once.
- Two seconds of wall-clock search time and 5,000 retained clauses per run.
- Four concurrent problem workers. Within each worker, the two modes run
  sequentially; a deterministic name hash balances which mode runs first.
- **Parallel timings are not controlled speedup measurements.** CPU contention
  can affect coverage near the time limit. Use the sequential small suite or a
  separate one-worker rerun to make timing claims. This pass has one repetition,
  so it does not establish repeatability across multiple runs.
- Existing QED input limits remain: 500 premises and 64,000 formula characters.
  No premise is truncated to meet a limit. The importer additionally bounds
  source expansion to 8 MiB and preflight to 15 seconds per problem. Syntax/size
  failures are `unsupported`; other preflight failures are `preflight_error`.
- CNF expansion and term nesting retain the prover's existing resource limits.
- The process boundary allows a one-second hard-timeout grace around the OCaml
  process; an outer worker timeout also exists. A limit produces **unknown**.

Expected labels are used only by the evaluator, never supplied to proof search.
`Theorem`, `Unsatisfiable`, and `ContradictoryAxioms` are positive refutation
cases. `Satisfiable` and `CounterSatisfiable` are negative cases. `Open` and
`Unknown` cases are attempted but unscored. QED may terminate by saturation on
a negative case; it does not export a countermodel. Failure to find a proof
within a limit does not establish satisfiability.

For a positive conjecture, QED searches the premises plus its negation. For
CNF and problems without a positive conjecture, it searches all input clauses
for inconsistency. An already negated conjecture is included as a premise and
is not negated a second time.

## Results and artifacts

The application exposes progress and lets you load an accepted problem by ID,
including its expanded premises. Use **Refresh full evaluation** to update it.

- `summary.json`: progress, aggregate outcomes, unsupported reasons, anomalies,
  source/compiler/environment provenance, and explicit completion flag.
- `REPORT.md`: readable aggregate results; partial until all attempts finish.
- `results.sqlite3`: per-problem preflight decisions, normalized inputs, source
  hashes, and raw measurements for both modes. Each completed pair is committed.
- `results.csv`: generated on completion, with unsupported files and both-mode
  outcomes for accepted files.
- `proofs/*.json.gz`: compressed proof records for every internally checked proof,
  including the exact submitted input; their hashes are recorded in the database.
- `manifest.json` and `BuggedProblems-v9.3.1.txt`: frozen corpus inventory and
  the dated bug-list snapshot used for scoring.

Unsupported and preflight-error cases stay in the selected denominator.
The `scored_selected` denominator additionally excludes known-bug and unknown
reference labels; `positive_selected` counts scored positive cases. A checked
proof is counted as a *correct* proof only if it agrees with a scored positive
label. Unexpected answers and replay failures are explicit anomalies.

Internal replay checks resolution/factoring steps. It trusts parsing,
clausification, equality-axiom generation, and shared term operations. This is
not independent end-to-end formal verification. Keep these limits when writing
resume claims, and distinguish problem files from unrelated mathematical
statements: alternate presentations may encode the same abstract problem.

## Reproduce or resume

Download the official archive and bug list to a local working directory, then:

```sh
make
python3 prepare_full_tptp.py /path/to/TPTP-v9.3.1.tgz \
  /path/to/BuggedProblems-v9.3.1.txt /path/to/library
python3 full_evaluation.py /path/to/library \
  --workers 4 --seconds 2 --max-clauses 5000
```

Run the same evaluation command to resume: completed preflight results and
completed mode pairs are reused. The runner refuses to mix source, corpus,
compiler, or protocol versions. Use `--output /path/to/new-results` for a new
protocol. Do not run two coordinators against the same output database at once.
The large downloaded/extracted corpus stays in the working directory, outside
the source ZIP; the code needs no new third-party Python dependencies.

## Median efficiency metrics on real TPTP problems

After full coverage evaluation finishes, measure its common positive successes
in isolation from the parallel benchmark:

```sh
python3 tptp_metrics.py --full benchmarks/full-tptp-9.3.1 \
  --repeat 3 --output benchmarks/full-tptp-9.3.1/paired-metrics.json
```

This runs baseline and optimized modes sequentially, with three repetitions per
problem and alternating mode order. Only problems proved and internally checked
by both modes in every sequential repetition contribute to the final medians.
The candidate cohort and any cases excluded after remeasurement are recorded.

For each problem/mode, first take its median runtime over the three repetitions;
then take the median across the identical problem cohort for baseline and
optimized. The percentage reduction is `100 * (1 - optimized / baseline)` using
those two medians. Apply the same calculation to `literal_pair_checks`, which
counts candidate literal pairs considered for resolution (not all CPU operations
and not factoring work). `elapsed_ms` covers clausification, generated equality
axioms, proof search and replay; it excludes parsing and process startup.

The JSON also reports arithmetic means of per-problem medians, and the distinct
statistic *median of per-problem percentage reductions*. Do not substitute one
for another. Runtimes below a millisecond are noisy; report the cohort size,
version, limits and measurement scope with any resume claim. This is efficiency
on shared successes, not mean runtime over all 17,912 selected files.

The currently completed historical TPTP 3.3.0 report has 20 shared successes:
median runtime 0.29505 → 0.14605 ms (50.50% lower), and median candidate literal
comparisons 1,577.5 → 25.5 (98.38% lower). These are real TPTP measurements, not
the synthetic suite, and not results for the full 9.3.1 release. Reproduce their
aggregation without rerunning the prover:

```sh
python3 tptp_metrics.py --historical benchmarks/results-tptp.json \
  --output benchmarks/metrics-tptp-3.3.0.json
```

## QED v2 full rerun

The v1 result directory is preserved. The v2 run uses the same frozen library,
selection, four workers, two-second search limit, and 5,000-clause limit, writing
to `benchmarks/full-tptp-9.3.1-v2`. Start or resume the whole pipeline with:

```sh
python3 run_full_evaluation.py /path/to/library
```

It runs full coverage, then three sequential measurements of shared positive
successes, then verifies the saved proof hashes and SQLite integrity. Progress
is recorded in `pipeline-status.json`; `stage: complete` means all three stages
finished. A failure is recorded explicitly. Completed coverage reports are not
rewritten when resuming the timing stage. Do not run two coordinators against
the same output directory.

The application now displays the v2 run under **Full TPTP 9.3.1 evaluation ·
QED v2**, with links to the preserved v1 summaries. Click **Refresh full
evaluation** to update it. Only compare final v1/v2 coverage after the new pass
finishes. Resolution-generator comparison counts do not include the new unit
simplification and paramodulation work; end-to-end runtime and solved counts
remain the primary comparisons across versions.
