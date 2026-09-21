# Paired TPTP efficiency metrics

TPTP 9.3.1 — sequential rerun of all shared positive successes

Status: complete

594 problems proved and internally checked by both modes in every measured repetition.
3 repetitions per problem and mode; sequential execution.

| Metric | Baseline median | Optimized median | Reduction |
|---|---:|---:|---:|
| OCaml pipeline time (ms) | 0.3890 | 0.1035 | 73.39% |
| Candidate literal comparisons | 607.0000 | 1.0000 | 99.84% |

First take the median of repeated runs for each problem/mode, then the median across the same problems for both modes. Reduction = 100 × (1 − optimized median / baseline median). This is not the median of per-problem percentage reductions; the JSON includes that separate statistic and arithmetic means as well. Timeouts, unsupported files, unscored labels, and one-mode-only successes are excluded from the paired efficiency cohort, but remain in the full coverage report. These are shared-success timing results, not an all-library average. Very short runtimes are noisy.

Candidate shared successes: 594. Full per-problem medians and identifiers are preserved in the JSON.
