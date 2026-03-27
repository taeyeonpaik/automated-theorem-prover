OCAMLOPT ?= ocamlopt
MODULES = src/syntax.ml src/parser.ml src/clausify.ml src/inference.ml src/prover.ml
.PHONY: all test clean run
all: bin/qed
bin/qed: $(MODULES) src/main.ml
	mkdir -p bin
	$(OCAMLOPT) -I src -I +unix unix.cmxa $(MODULES) src/main.ml -o $@
test: all
	./bin/qed examples/socrates.qed
clean:
	rm -f src/*.cm[iox] src/*.o tests/*.cm[iox] tests/*.o bin/qed bin/core_tests bin/milestone_tests
