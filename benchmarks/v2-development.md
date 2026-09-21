# QED v2 development comparison

A fixed, balanced 64-file sample from TPTP 9.3.1; two seconds and 5,000 stored clauses per engine. One sequential run each, with order alternated by problem.

| Engine | Proved | Correct negative decisions | Unknown | Mismatches |
|---|---:|---:|---:|---:|
| v1 | 6 | 2 | 56 | 0 |
| v2 | 7 | 2 | 55 | 0 |

All returned decisions match the reference labels, and all proofs passed internal replay. One additional case, SWV347-2, was proved; no resolved case regressed. This is a modest development result, not evidence of a large full-library improvement.

Selection: First 16 by SHA256(QED-v2-development-931: + name) in each positive/negative and equality/no-equality stratum of accepted, scored TPTP 9.3.1 inputs. No solver outcomes used. Development sample, not full-library coverage.

The JSON contains exact inputs, dependency hashes, proof records, limits, source/executable hashes and raw results.

## Reproduce

```sh
make
make -C benchmarks/v1-source
python3 compare_upgrade.py
```
