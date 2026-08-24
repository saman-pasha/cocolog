EMACS ?= emacs
EL    := cocolog-engine.el cocolog-graph.el cocolog-color.el cocolog-mode.el \
         cocolog-markdown.el

.PHONY: all test compile clean examples doc swipl

all: compile test

compile:
	$(EMACS) -Q --batch -L . --eval '(setq byte-compile-error-on-warn t)' \
	  -f batch-byte-compile $(EL)

test:
	$(EMACS) -Q --batch -L . -L test -l test/cocolog-tests.el \
	  -f ert-run-tests-batch-and-exit

# regenerate the graphs inside the example files
examples:
	$(EMACS) -Q --batch -L . -l cocolog-mode.el \
	  --eval '(dolist (f (list "examples/family.colog" "examples/lists.colog" "examples/grammar.colog")) \
	            (with-current-buffer (find-file-noselect f) \
	              (cocolog-run-all-tests) (save-buffer)))'

# ask SWI-Prolog the same questions and compare the answers
swipl:
	tools/swipl-diff.sh

# regenerate the SVG pictures used by README.md
doc:
	$(EMACS) -Q --batch -L . -L tools -l tools/make-doc.el

clean:
	rm -f *.elc tools/*.elc examples/*~
