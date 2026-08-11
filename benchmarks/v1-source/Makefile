OCAMLOPT ?= ocamlopt
MODULES = src/syntax.ml src/parser.ml src/clausify.ml src/inference.ml src/prover.ml

.PHONY: all test run clean benchmark tptp-eval
all: bin/qed

bin/qed: $(MODULES) src/main.ml
	mkdir -p bin
	$(OCAMLOPT) -w +a-4-40-42-70 -I src -I +unix unix.cmxa $(MODULES) src/main.ml -o $@

bin/core_tests: $(MODULES) tests/core_tests.ml
	mkdir -p bin
	$(OCAMLOPT) -I src -I +unix unix.cmxa $(MODULES) tests/core_tests.ml -o $@

test: bin/qed bin/core_tests
	./bin/core_tests
	python3 -m unittest discover -s tests -v

run: bin/qed
	python3 server.py

benchmark: bin/qed
	python3 benchmark.py

tptp-eval: bin/qed
	python3 fetch_tptp.py
	python3 benchmark.py --tptp --seconds 2 --repeat 3

clean:
	rm -f src/*.cm[iox] src/*.o tests/*.cm[iox] tests/*.o bin/qed bin/core_tests
