OCAMLOPT ?= ocamlopt
MODULES = src/syntax.ml src/parser.ml
.PHONY: all test clean run
all: bin/milestone_tests
bin/milestone_tests: $(MODULES) tests/milestone_tests.ml
	mkdir -p bin
	$(OCAMLOPT) -I src -I +unix unix.cmxa $(MODULES) tests/milestone_tests.ml -o $@
test: all
	./bin/milestone_tests
clean:
	rm -f src/*.cm[iox] src/*.o tests/*.cm[iox] tests/*.o bin/qed bin/core_tests bin/milestone_tests
