# QED v2: four improvements

Optimized mode now implements all four requested changes in OCaml. The original
FIFO baseline algorithm stays available with `--baseline`. No external prover,
CAS, or new dependency is used. Old proof ancestors remain stored even when a
clause is removed from active search.

## Relation to Harrison's textbook

The official [companion-code index](https://www.cl.cam.ac.uk/~jrh13/atp/index.html)
provides the following anchors:

| QED change | Textbook companion material | QED-specific part |
|---|---|---|
| Unit simplification and backward subsumption | `resolution.ml`: resolution, rigid matching and bi-subsumption | Eager simplification of active/passive clauses, with recorded proof parents |
| Indexed redundancy checks | The matching/subsumption algorithms in `resolution.ml` | The concrete anchor and signature posting lists are our engineering design, not a copied textbook indexing implementation |
| Definitional CNF | `defcnf.ml` | Lift fresh propositions to predicates with free-variable arguments; use definitions only when estimated distribution exceeds 32 clauses |
| Equality reasoning | `paramodulation.ml`, `rewrite.ml`, `order.ml` | Integrate equality resolution, paramodulation, and checked simplification into our existing given-clause loop |

The LPO implementation adapts Harrison's ordering code; retain
[his license](HARRISON-LICENSE.txt) with source and binary distributions. The
textbook's educational code is not a promise of competitive TPTP performance.

## 1. Simplification

A unit clause can shorten another clause **only by one-way matching**. For
example, `p(X)` simplifies `~p(a) | q(a)` to `q(a)`. In contrast, `p(a)` must not
replace the general clause `~p(X) | q(X)` with just `q(a)`: doing so would lose
its other instances. Ordinary resolution can still derive that instance without
deleting the parent.

New unit clauses simplify both waiting and already processed clauses. Each
replacement gets a resolution or paramodulation certificate. Backward
subsumption retires clauses already implied by a newly retained clause. Deleted
clauses and their derivation parents remain available for proof replay.

## 2. Subsumption index

The sign, predicate name and arity of a literal must match before its terms can
match. `clause_index.ml` keeps posting lists for these signatures. Forward
subsumption stores one anchor signature per clause; backward subsumption starts
with the shortest relevant posting list. Length/signature checks filter out
impossible matches before the existing rigid multiset matcher runs.

Indexes are candidate filters, not logical decision procedures. Removing a
clause removes its index entries. Resolution retains its complementary-literal
index; equality search retrieves only positive equality sources when the given
clause has no equality of its own.

## 3. Hybrid definitional CNF

For large distributive products, fresh predicates name subformulas and small
clauses constrain each definition. For example, a definition for `p(X) & q(X)`
has argument `X`; a fresh propositional constant would be incorrect here.
Names avoid all input predicate names, and Skolem symbols remain fresh.

The converter estimates output size without constructing the product. Small
formulas (at most 32 estimated clauses) keep direct CNF to avoid burdening the
search with unnecessary predicates. Already clausal input keeps its structure.
The 10,000-clause preprocessing limit and time limits still apply. This avoids
large distributive products; it does not promise a linear bound for every
preceding NNF transformation (nested biconditionals can still expand).

## 4. Equality

Optimized mode no longer adds general symmetry/transitivity/congruence axioms.
Instead, it uses unrestricted paramodulation in both directions, factoring,
resolution, and equality resolution. A negative equality whose sides unify can
be resolved away with that substitution, providing the reflexivity inference.
Paramodulation replaces a non-variable subterm using a positive equality and
retains the other literals of both parent clauses. Clauses are renamed apart,
and self-inferences remain possible.

For simplification only, unit equations are oriented by a lexicographic path
ordering (LPO) with fixed symbol precedence. Rewriting uses matching, preserves
target variables, and strictly decreases this ordering. Incomparable equations
remain available for paramodulation; they are not arbitrarily oriented or
discarded. Ordered rewriting does not impose an unproved restriction on the
complete paramodulation search. This is intentionally simpler than a full
ordered-superposition implementation and may still generate many inferences.

The replay checker validates the recorded equality, substitution, direction,
target literal and term position. It does not call the search or unifier.
Clausification and shared term/substitution helpers remain trusted.

## Test and reproduce

```sh
make test
./bin/qed --seconds 2 --max-clauses 5000 examples/socrates.qed
```

CLI switches for one-feature-at-a-time experiments (optimized mode only):

```sh
./bin/qed --no-simplify problem.qed
./bin/qed --no-subsumption-index problem.qed
./bin/qed --no-defcnf problem.qed
./bin/qed --no-paramodulation problem.qed
```

`--no-simplify` disables unit simplification, unit rewriting and backward
subsumption. `--no-paramodulation` restores equality axioms and disables the new
equality engine, while retaining ordinary unit resolution. These groups overlap
in their use of rewriting; do not claim perfectly independent optimization
contributions without accounting for that interaction.

New counters include full subsumption-matcher calls, simplification steps,
backward-subsumed clauses, and paramodulation candidate checks. Existing
`literal_pair_checks` counts resolution generator comparisons; it does not
measure all work in simplification, matching, factoring or equality. Compare
end-to-end prover time and solved counts when comparing v1 with v2.
The clause limit includes archived proof-history nodes, so it also bounds
memory retained for replay, not just the currently active clauses.

## Preserved measurements

`benchmarks/v1-source` contains the exact previous core, executable and Python
runner sources. `benchmarks/full-tptp-9.3.1` remains the completed v1 evaluation,
including all 25,928 runs and the sequential timing reruns. The application
labels these as v1 measurements; running a new interactive proof uses v2.

`benchmarks/v2-development.json` compares the engines on a deterministic
64-problem development sample from the accepted, scored TPTP 9.3.1 inputs.
Sixteen files are selected in each positive/negative × equality/no-equality
stratum by a fixed SHA-256 ordering, without using solver outcomes. Both engines
run sequentially with 2-second/5,000-clause limits; order alternates by problem.
This is a development check, not a representative full-library performance
claim. Only completed reports may be cited.

Completed development result: v1 resolved 8/64 cases (6 proofs, 2 negative decisions); v2 resolved 9/64 (7 proofs, 2 negative decisions), with no answer mismatches or proof-check failures. No previously resolved case regressed. This modest result does not establish a large full-library coverage gain. See [the development report](../benchmarks/v2-development.md).
