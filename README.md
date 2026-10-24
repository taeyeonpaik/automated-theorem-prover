# QED

A small first-order theorem prover in OCaml, with a JavaScript interface and a Python server. Based on John Harrison’s *Handbook of Practical Logic and Automated Reasoning*.

Uses resolution and paramodulation, with clause indexing and subsumption to reduce search. Supports a subset of TPTP FOF/CNF and includes benchmark results.

## Run

Requires OCaml 4.13+, Python 3.10+, and make.

```sh
make
python3 server.py
```

Open http://127.0.0.1:8000, load an example, and click **Prove**.

Run tests with `make test`.

This is an educational prover: searches can hit resource limits, and known proof-replay failures remain in the saved evaluation.

[Walkthrough](docs/WALKTHROUGH.md) · [TPTP evaluation](docs/FULL_TPTP_EVALUATION.md)
