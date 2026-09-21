# Paired TPTP efficiency metrics

QED TPTP 64 — TPTP 3.3.0

Status: complete

20 problems proved and internally checked by both modes in every measured repetition.
3 repetitions per problem and mode; sequential execution.

| Metric | Baseline median | Optimized median | Reduction |
|---|---:|---:|---:|
| OCaml pipeline time (ms) | 0.2951 | 0.1461 | 50.50% |
| Candidate literal comparisons | 1,577.5000 | 25.5000 | 98.38% |

First take the median of repeated runs for each problem/mode, then the median across the same problems for both modes. Reduction = 100 × (1 − optimized median / baseline median). This is not the median of per-problem percentage reductions; the JSON includes that separate statistic and arithmetic means as well. Timeouts, unsupported files, unscored labels, and one-mode-only successes are excluded from the paired efficiency cohort, but remain in the full coverage report. These are shared-success timing results, not an all-library average. Very short runtimes are noisy.

Candidate shared successes: 20. Full per-problem medians and identifiers are preserved in the JSON.
