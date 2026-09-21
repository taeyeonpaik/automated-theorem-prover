# Full TPTP 9.3.1 evaluation

Status: complete

Selected 17,912 FOF/CNF files from 26,990 total problem files.
Preflight completed: 17,912; states: {'unsupported': 4948, 'accepted': 12964}.
Measured runs completed: 25,928. One repetition per mode.

Limits: 2.0 seconds / 5000 clauses; 4 concurrent problem workers.
Parallel wall-clock timings are descriptive, not isolated speedup measurements.

| Mode | Correct proofs | Correct negative decisions | Unknown | Errors | Mismatches |
|---|---:|---:|---:|---:|---:|
| baseline | 599 | 56 | 12309 | 0 | 0 |
| optimized | 1225 | 72 | 11666 | 0 | 0 |

Known bug-list entries and Open/Unknown labels are attempted but excluded from correctness scoring. Unsupported inputs remain in the selected/scored denominators. ContradictoryAxioms is a positive refutation case. A timeout is unknown, never a disproof. Internal proof replay checks resolution/factoring, not preprocessing.

Per-problem inputs, dependency hashes and raw measurements are checkpointed in results.sqlite3. The inventory and original source hashes are in manifest.json. Checked proof records are in proofs/.

## Unsupported / preflight error reasons

- 3134: Input is too large (500 premises / 64,000 characters maximum)
- 661: A TPTP symbol collides with a reserved QED keyword
- 554: Source expansion exceeds benchmark byte budget
- 286: Quoted formula symbols and distinct objects are not supported
- 179: Reverse implication, XOR, NAND and NOR are not supported
- 121: Repeated variable in a quantifier
- 6: Duplicate formula name: reserved_2Eho_2Eboolext
- 3: Duplicate formula name: con1
- 2: Only untyped fof, cnf, and local include records are supported
- 1: Duplicate formula name: initiates_all_defn
- 1: Duplicate formula name: reserved_2Eho_2Eeq__ext
