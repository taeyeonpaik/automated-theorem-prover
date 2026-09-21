# QED implementation walkthrough

## 1. What the program proves

QED asks whether premises A1, …, An entail a conclusion G. It searches for a
contradiction in A1 ∧ … ∧ An ∧ ¬G. If that set is inconsistent, G follows.
This is an automated prover: the user does not supply a proof. The separate
replay code checks the inference steps discovered by the search.

QED uses classical, untyped first-order logic with equality and
a nonempty domain. Functions are total and otherwise uninterpreted. To reason
about a mathematical structure, supply its axioms explicitly.

## 2. Representation: syntax.ml

A term is either `Var name` or `Fn (name, arguments)`. Thus `socrates` is
`Fn ("socrates", [])`, while `f(x)` has one argument. A formula is an algebraic
data type with constructors for atoms, connectives, and quantifiers.

After normalization, a literal is a sign paired with a predicate and its terms.
A clause is a list of literals interpreted as a disjunction. A set of clauses
is interpreted as a conjunction. An empty clause is false.

These representations let pattern matching express the algorithms directly.
Lists and association lists keep the code small. Hash tables serve the few
places where efficient lookup is useful.

## 3. Parsing and variable scope: parser.ml

The tokenizer recognizes identifiers and a small set of logical operators.
Recursive descent encodes precedence: negation, conjunction, disjunction,
implication, then equivalence. Implication is right associative.

Quantifier parsing carries a list of bound variable names, so `x` in
`forall x. p(x)` is a variable while `a` in `p(a)` is a constant. Uppercase term
names may also be free variables. Each formula is universally closed before
the goal is negated. Closing the goal afterward would change its meaning.

For example, from `p(a)` one cannot prove `p(X)`: the latter asks for `p` of
every object. A regression test covers this distinction.

## 4. Clausification: clausify.ml

The pipeline is deliberately close to Harrison's first-order material:

1. Eliminate implications and equivalences and push negations to atoms.
2. Rename universally bound variables to fresh internal names. Each binder
   gets its own name, including when an input name is shadowed.
3. Replace existential variables with fresh Skolem functions of the surrounding
   universal variables. An existential with no universal dependencies becomes
   a fresh constant.
4. Remove universal binders; all variables in a clause are implicitly universal.
5. Split into clauses, using fresh definition predicates when estimated
   distributive expansion exceeds 32 clauses in optimized mode. Their arguments
   contain all free variables; small formulas retain direct CNF.

QED uses a direct recursive transformation instead of constructing an explicit
prenex intermediate representation. Fresh scoped variables make that safe.
Skolem symbols are fresh across the entire problem, not just one premise. The
generator checks input function names to avoid collisions. Skolemization
preserves satisfiability in an expanded signature, not ordinary equivalence.

Distributive CNF is easy to understand but can grow exponentially. QED limits
the intermediate clause expansion to 10,000 and reports `unknown` on overflow.
Optimized mode now avoids large distributive products with definitional CNF.
NNF construction and all other preprocessing still have resource limits.

## 5. Unification and inference: inference.ml

Unification finds a substitution that makes two terms identical. For example,
`human(X)` and `human(socrates)` unify with `X := socrates`. The occurs check
rejects `X := f(X)`, preventing cyclic/infinite terms. The substitution is fully
composed before recording it in a proof step.

Binary resolution uses two clauses with complementary unifiable literals:

```text
~human(X) | mortal(X)
human(socrates)
-----------------------------
mortal(socrates)
```

The two parent clauses are renamed apart before unification, using `l:` and
`r:` prefixes. Variables are local to clauses; accidentally sharing them would
change the inference. Self-resolution uses two independently renamed copies too.

Factoring unifies two same-sign literals within a clause and removes one after
applying the substitution throughout the clause:

```text
p(X) | p(Y)     becomes     p(Y), with X := Y
```

Factoring is essential to the completeness of the binary-resolution calculus,
not just a speed tweak. A regression problem requires it to find a contradiction.

## 6. Equality: clausify.ml

In baseline mode, QED adds reflexivity, symmetry, and transitivity, plus
congruence clauses for the function and predicate symbols in the problem.
For example, equality and predicate congruence let `a = b` and `p(a)` yield `p(b)`.
Function congruence lets `a = b` yield `f(a) = f(b)`.

This follows the elementary approach in Harrison's `equal.ml`. It avoids the
complexity of superposition but creates more work for resolution. Optimized mode
now uses paramodulation in both directions, equality resolution, and terminating
unit rewriting instead. See [the upgrade walkthrough](UPGRADES.md). No arithmetic
meaning is attached to symbols such as `plus` or `zero`. A CAS is not needed to
carry out these first-order inferences.

## 7. Search and optimizations: prover.ml

The given-clause loop maintains passive (waiting) and active (processed) clauses.
It selects a passive clause, computes its factors, resolves it against relevant
active clauses (including itself), and adds useful conclusions to the passive
set. Every new clause records its origin. It stops on the empty clause, exhausted
passive set, or a resource limit.

Both modes discard exact tautologies and duplicates. Tautology removal requires
the *same* atom with opposite signs. Merely unifiable opposites, such as
`p(X) | ~p(a)`, do not make a tautology. The cheap alpha key normalizes variable
names; it may miss some permuted variants but never merges unrelated clauses.

The baseline uses FIFO selection and scans all active clauses and literal pairs.
Optimized mode includes:

- **Indexing:** an active-clause hash table keyed by predicate, arity, and sign
  retrieves only clauses that could contain a complementary literal. Matching
  keys do not guarantee unification, so arguments are still checked.
- **Forward subsumption:** discard a new clause if an existing clause already
  implies it by one-way matching. Target variables are rigid. Multiset matching
  uses distinct target literals so that a longer parent does not suppress its
  own useful factor. Backward subsumption also retires older clauses subsumed
  by a newly retained one; their proof ancestors remain archived.
- **Age/weight selection:** usually select the smallest clause by symbol count,
  with variables weighted 1 and functions/constants 2. Every fifth selection
  instead takes the oldest clause. This retains fairness instead of starving
  large clauses forever. There is no restrictive set-of-support assumption that
  would depend on the premises being consistent.

We retain simple list-based queues. A heap or sophisticated term index would
add complexity before we have benchmark evidence that it is needed. Subsumption
itself costs time, so optimized mode is not guaranteed to win on every input.
CLI ablation switches can disable each new feature independently. The original
full TPTP report describes v1; it has not been relabelled as v2 performance.

## 8. Proof replay

Each derived node records parent IDs, zero-based pivot positions, substitution,
and derivation depth. Once the empty clause is found, graph traversal extracts
only its ancestors and sorts them into a valid replay order.

The checker does **not** rerun the unifier or the search. It takes the recorded
substitution, instantiates the parents, verifies the pivot relationship, and
reconstructs the conclusion. Input leaves must match the prepared clause set.
Equality resolution and paramodulation are also replayed. Paramodulation records
its direction and term position. Tests corrupt conclusions, pivots, positions,
directions, substitutions and input sources to ensure rejection.

The trusted boundary includes parsing, clausification, equality axioms, the
term representation, and shared substitution/canonicalization helpers. This
is not a fully independently formalized proof kernel. Exported JSON is a readable
record of the run; there is no standalone JSON-certificate verifier yet.

## 9. Application and database

`web/app.js` constructs the browser UI using native DOM elements. It submits
JSON to the Python HTTP server. The server invokes `client.py`, which launches
the OCaml executable in a separate process and enforces an outer timeout.
No Python or JavaScript code performs proof search. The UI has no CSS or
handwritten HTML page; the server emits only a minimal browser bootstrap.

SQLite stores each submitted problem and each resulting run. Problems are
deduplicated by the exact premise list and goal. Running a problem twice creates
two runs but one distinct problem. Stored problems do not supply global axioms.

The worker measures peak RSS for its one prover child, avoiding the misleading
high-water mark of every child ever launched by the web server. All application
dependencies are in the Python standard library or native browser APIs.

## 10. Evaluation and what to claim

Unit tests cover scope, Skolem freshness, occurs checks, composition, factoring,
equality, input validation, persistence, certificate tampering, and limits.
The independent truth-table oracle evaluates 120 seeded propositional problems
under every valuation and compares both search modes with that semantic answer.
Additional non-theorems have known finite countermodels and must never be proved.
Passing these tests is evidence, not a mathematical proof of implementation soundness.

The original 20-case suite is small and partly synthetic. Five repetitions under
fixed limits produce 200 runs. Use `docs/RESULTS.md` for those initial numbers.
The project now also includes a frozen 64-problem TPTP 3.3.0 subset with local
axiom includes, source hashes, repeated baseline/optimized runs, and preserved
proof records. See `docs/TPTP_EVALUATION.md` and `benchmarks/results-tptp.md`.
The importer remains an untyped subset, and unsupported cases remain in the
reported denominator. The core search algorithms are unchanged.

Do not call solve rate "accuracy" without explaining the denominator. Count
verified proofs and independently known answer mismatches separately. Compare
runtime on problems solved by both modes; a timeout is censored data, not a
measured proof time. For quick problems, deterministic clause/pair counts are
more informative than tiny wall-clock differences.

## Source map and attribution

QED is an original compact implementation of these algorithms, written for this
project. It is not a claim to have invented resolution or these optimizations.
Harrison's publicly released companion code was consulted directly; the full
book was not supplied. The relevant source correspondence is:

| QED | Harrison's companion material |
|---|---|
| `syntax.ml`, `parser.ml` | `formulas.ml`, `fol.ml` |
| `clausify.ml` | `skolem.ml`, basic CNF material, `equal.ml` |
| `inference.ml` | `unif.ml`, `resolution.ml` |
| `prover.ml` | `resolution.ml` given-clause loop, redundancy and matching |

Harrison's source is available from
https://www.cl.cam.ac.uk/~jrh13/atp/index.html. Its redistribution notice is
preserved in `HARRISON-LICENSE.txt` as attribution to the consulted source.

The supplied Adam Pease transcripts cover: the first-order/refutation overview;
normalization and Skolemization; resolution and unification; and PyRes/JavaRes,
factoring, clause selection, subsumption, indexing, proof output, and benchmarking.
The spatial-transitivity demo adapts their ostrich/elephant example. Sources:

- https://www.youtube.com/watch?v=eQJkqMnrfic
- https://www.youtube.com/watch?v=rEPLQ7pv05Y
- https://www.youtube.com/watch?v=07Ea_q3CM6Q
- https://www.youtube.com/watch?v=J3Pm43O48Uo

TPTP syntax/role reference:
https://tptp.org/UserDocs/TPTPLanguage/TPTPLanguage.shtml

The code deliberately corrects informal shortcuts: Skolemization preserves
satisfiability, normalization distributes **or over and**, and first-order
search may return unknown despite classical logic having two truth values.
