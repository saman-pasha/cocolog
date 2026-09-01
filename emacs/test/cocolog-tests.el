;;; cocolog-tests.el --- Tests for cocolog-mode -*- lexical-binding: t; -*-

;;; Commentary:

;; Run with:
;;   emacs -Q --batch -L . -L test -l test/cocolog-tests.el \
;;         -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'cocolog-mode)
(require 'cocolog-markdown)

(defun cocolog-test--db (source)
  (cocolog-consult-string source))

(defconst cocolog-test-family "
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).
parent(pat, jim).
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Z) :- parent(X, Y), ancestor(Y, Z).
fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F1), F is N * F1.
childless(X) :- \\+ parent(X, _).
")

(defun cocolog-test--solutions (db query &optional n)
  (mapcar (lambda (sol) (mapcar #'cdr sol))
          (cocolog-result-solutions (cocolog-run-query db query n))))

;;;; ------------------------------------------------------------------
;;;; Reader and writer
;;;; ------------------------------------------------------------------

(defun cocolog-test--roundtrip (s)
  (cocolog-term-to-string (plist-get (cocolog-read-term s) :term)))

(ert-deftest cocolog-test-read-atoms-and-numbers ()
  (should (equal (cocolog-test--roundtrip "foo.") "foo"))
  (should (equal (cocolog-test--roundtrip "'hello world'.") "'hello world'"))
  (should (equal (cocolog-test--roundtrip "42.") "42"))
  (should (equal (cocolog-test--roundtrip "-7.") "-7"))
  (should (equal (cocolog-test--roundtrip "3.25.") "3.25"))
  (should (equal (cocolog-test--roundtrip "0'a.") "97"))
  (should (equal (cocolog-test--roundtrip "0xff.") "255")))

(ert-deftest cocolog-test-read-compound-and-lists ()
  (should (equal (cocolog-test--roundtrip "f(a, B, [1,2|T]).") "f(a, B, [1, 2|T])"))
  (should (equal (cocolog-test--roundtrip "[].") "[]"))
  (should (equal (cocolog-test--roundtrip "[a].") "[a]"))
  (should (equal (cocolog-test--roundtrip "{a, b}.") "{a, b}")))

(ert-deftest cocolog-test-read-operators ()
  (should (equal (cocolog-test--roundtrip "a :- b, c.") "a :- b, c"))
  (should (equal (cocolog-test--roundtrip "X is 1 + 2 * 3.") "X is 1 + 2 * 3"))
  (should (equal (cocolog-test--roundtrip "X is (1 + 2) * 3.") "X is (1 + 2) * 3"))
  (should (equal (cocolog-test--roundtrip "a ; b -> c.") "a ; b -> c"))
  (should (equal (cocolog-test--roundtrip "\\+ a.") "\\+ a")))

(ert-deftest cocolog-test-read-errors ()
  (should-error (cocolog-read-term "foo(.") :type 'cocolog-syntax-error)
  (should-error (cocolog-read-term "f(a) g(b).") :type 'cocolog-syntax-error)
  (should (null (cocolog-read-term "   % just a comment\n"))))

(ert-deftest cocolog-test-consult-collects-errors ()
  (let ((db (cocolog-test--db "good(1).\nbad( .\nalso_good(2).\n")))
    (should (= 1 (length (cocolog-db-errors db))))
    (should (cocolog-db-defined-p db (cocolog-mk (intern "also_good") 1)))))

;;;; ------------------------------------------------------------------
;;;; Unification and standard order
;;;; ------------------------------------------------------------------

(ert-deftest cocolog-test-unify ()
  (let* ((cocolog--trail nil)
         (v (cocolog--var-make "X")))
    (should (cocolog-unify v 'foo))
    (should (eq (cocolog-deref v) 'foo))
    (should-not (cocolog-unify v 'bar))))

(ert-deftest cocolog-test-trail-undo ()
  (let* ((cocolog--trail nil)
         (v (cocolog--var-make "X"))
         (mark (cocolog--mark)))
    (cocolog-unify v 42)
    (should (equal (cocolog-deref v) 42))
    (cocolog--undo-to mark)
    (should (cocolog-var-p (cocolog-deref v)))))

(ert-deftest cocolog-test-standard-order ()
  (should (< (cocolog-compare 1 'a) 0))
  (should (< (cocolog-compare 'a (cocolog-mk 'f 'a)) 0))
  (should (= (cocolog-compare 'a 'a) 0))
  (should (> (cocolog-compare 'b 'a) 0)))

;;;; ------------------------------------------------------------------
;;;; Solving
;;;; ------------------------------------------------------------------

(ert-deftest cocolog-test-facts-and-rules ()
  (let ((db (cocolog-test--db cocolog-test-family)))
    (should (equal (cocolog-test--solutions db "parent(tom, X)") '(("bob") ("liz"))))
    (should (equal (cocolog-test--solutions db "grandparent(tom, Z)")
                   '(("ann") ("pat"))))
    (should (equal (cocolog-test--solutions db "ancestor(tom, X)" 20)
                   '(("bob") ("liz") ("ann") ("pat") ("jim"))))))

(ert-deftest cocolog-test-cut-and-negation ()
  (let ((db (cocolog-test--db cocolog-test-family)))
    (should (equal (cocolog-test--solutions db "fact(6, F)") '(("720"))))
    (should (equal (cocolog-test--solutions db "childless(ann)") '(nil)))
    (should (equal (cocolog-test--solutions db "childless(tom)") '()))))

(ert-deftest cocolog-test-arithmetic ()
  (let ((db (cocolog-test--db "dummy.")))
    (should (equal (cocolog-test--solutions db "X is 2 + 3 * 4") '(("14"))))
    (should (equal (cocolog-test--solutions db "X is 7 // 2") '(("3"))))
    (should (equal (cocolog-test--solutions db "X is 7 mod 3") '(("1"))))
    (should (equal (cocolog-test--solutions db "X is max(2, 5)") '(("5"))))
    (should (equal (cocolog-test--solutions db "X is 2 ** 10") '(("1024"))))
    (should (eq 'error (cocolog-result-status (cocolog-run-query db "X is 1 / 0"))))))

(ert-deftest cocolog-test-library-predicates ()
  (let ((db (cocolog-test--db "dummy.")))
    (should (equal (cocolog-test--solutions db "append([1],[2],X)") '(("[1, 2]"))))
    (should (= 3 (length (cocolog-test--solutions db "append(X, Y, [1,2])"))))
    (should (equal (cocolog-test--solutions db "reverse([1,2,3], X)") '(("[3, 2, 1]"))))
    (should (equal (cocolog-test--solutions db "msort([c,a,b], X)") '(("[a, b, c]"))))
    (should (equal (cocolog-test--solutions db "numlist(1, 4, L)") '(("[1, 2, 3, 4]"))))
    (should (equal (cocolog-test--solutions db "maplist([X,Y]>>(Y is X+1), [1,2], L)")
                   '(("X" "Y" "[2, 3]"))))))

(ert-deftest cocolog-test-control-constructs ()
  (let ((db (cocolog-test--db cocolog-test-family)))
    (should (equal (cocolog-test--solutions db "( parent(tom,bob) -> R = yes ; R = no )")
                   '(("yes"))))
    (should (equal (cocolog-test--solutions db "( parent(zz,bob) -> R = yes ; R = no )")
                   '(("no"))))
    (should (equal (cocolog-test--solutions db "findall(X, parent(bob,X), L)")
                   '(("X" "[ann, pat]"))))
    (should (equal (cocolog-test--solutions db "forall(parent(bob,X), parent(bob,X))")
                   '(("X"))))
    (should (equal (cocolog-test--solutions db "aggregate_all(count, parent(_,_), N)")
                   '(("5"))))))

(ert-deftest cocolog-test-unknown-predicate-is-an-error ()
  (let* ((db (cocolog-test--db "a."))
         (r (cocolog-run-query db "nope(1)")))
    (should (eq 'error (cocolog-result-status r)))
    (should (string-match-p "nope/1" (cocolog-result-message r)))))

(ert-deftest cocolog-test-inference-limit ()
  (let* ((cocolog-max-inferences 400)
         (cocolog-max-depth 10000)
         (db (cocolog-test--db "loop(X) :- loop(X).\n"))
         (r (cocolog-run-query db "loop(1)")))
    (should (eq 'limit (cocolog-result-status r)))))

(ert-deftest cocolog-test-depth-limit-fails-the-branch ()
  (let* ((cocolog-max-depth 20)
         (db (cocolog-test--db "loop(X) :- loop(X).\n"))
         (r (cocolog-run-query db "loop(1)")))
    (should (eq 'done (cocolog-result-status r)))
    (should (null (cocolog-result-solutions r)))))

(ert-deftest cocolog-test-solution-limit ()
  (let* ((db (cocolog-test--db cocolog-test-family))
         (r (cocolog-run-query db "parent(X, Y)" 2)))
    (should (eq 'more (cocolog-result-status r)))
    (should (= 2 (length (cocolog-result-solutions r))))))

;;;; ------------------------------------------------------------------
;;;; Graphs
;;;; ------------------------------------------------------------------

(ert-deftest cocolog-test-graph-block-shape ()
  (let* ((db (cocolog-test--db cocolog-test-family))
         (block (cocolog-graph-block (cocolog-run-query db "grandparent(tom, Z)"))))
    (should (string-match-p cocolog--trace-begin-re (car block)))
    (should (string-match-p cocolog--trace-end-re (car (last block))))
    (should (cl-some (lambda (l) (string-match-p "solution 1" l)) block))
    (should (cl-some (lambda (l) (string-match-p "parent(tom, Y)" l)) block))
    (should (cl-every (lambda (l) (string-prefix-p "%% " l)) block))))

(ert-deftest cocolog-test-graph-ascii ()
  (let* ((cocolog-graph-unicode nil)
         (db (cocolog-test--db cocolog-test-family))
         (block (cocolog-graph-block (cocolog-run-query db "parent(tom, X)"))))
    (should (string-match-p cocolog--trace-begin-re (car block)))
    (should (string-match-p cocolog--trace-end-re (car (last block))))
    (should (cl-every (lambda (l) (cl-every (lambda (c) (< c 128)) l)) block))))

(ert-deftest cocolog-test-graph-reports-failure ()
  (let* ((db (cocolog-test--db cocolog-test-family))
         (block (cocolog-graph-block (cocolog-run-query db "parent(zz, X)"))))
    (should (cl-some (lambda (l) (string-match-p "no solutions" l)) block))))

(ert-deftest cocolog-test-graph-width ()
  (let* ((db (cocolog-test--db cocolog-test-family))
         (block (cocolog-graph-block (cocolog-run-query db "ancestor(tom, X)" 20))))
    (should (cl-every (lambda (l)
                        (<= (length l)
                            (+ (length "%% ") 2 cocolog-graph-max-width)))
                      block))))

;;;; ------------------------------------------------------------------
;;;; Colours
;;;; ------------------------------------------------------------------

(ert-deftest cocolog-test-color-normalize ()
  (should (equal (cocolog-normalize-hex "#FF0000") "#ff0000"))
  (should (equal (cocolog-normalize-hex "f00") "#ff0000"))
  (should (equal (cocolog-normalize-hex "ff0000") "#ff0000"))
  (should (equal (cocolog-normalize-hex "SteelBlue") "#4682b4"))
  (should (null (cocolog-normalize-hex "not a colour at all"))))

(ert-deftest cocolog-test-color-variable-roundtrip ()
  (should (equal (cocolog-color-to-var "#e6194b") "Ce6194b"))
  (should (equal (cocolog-var-to-color "Ce6194b") "#e6194b"))
  (should (cocolog-color-var-p "Cff0000"))
  (should-not (cocolog-color-var-p "X"))
  (should-not (cocolog-color-var-p "Cff00"))
  (should-not (cocolog-color-var-p "Cff0000x")))

(ert-deftest cocolog-test-color-variable-names ()
  ;; a variable is called after its colour until it is given a name
  (should (equal (cocolog-var-display-name "Ce6194b") "crimson"))
  (should (null (cocolog-var-label "Ce6194b")))
  ;; ... and then it carries both
  (should (equal (cocolog-color-to-var "#e6194b" "Parent") "Ce6194b_Parent"))
  (should (equal (cocolog-var-label "Ce6194b_Parent") "Parent"))
  (should (equal (cocolog-var-display-name "Ce6194b_Parent") "Parent"))
  (should (equal (cocolog-var-to-color "Ce6194b_Parent") "#e6194b"))
  (should (cocolog-color-var-p "Ce6194b_Parent"))
  ;; naming it after its own colour is the default, so it is not written out
  (should (equal (cocolog-color-to-var "#e6194b" "crimson") "Ce6194b"))
  ;; a colour that has no palette name falls back to the hex
  (should (equal (cocolog-var-display-name "Ce6194c") "#e6194c"))
  ;; what may be a name
  (should (cocolog-valid-label-p "Parent"))
  (should (cocolog-valid-label-p "x1"))
  (should-not (cocolog-valid-label-p "1x"))
  (should-not (cocolog-valid-label-p "_x"))
  (should-not (cocolog-valid-label-p "a b"))
  (should-not (cocolog-color-var-p "Ce6194b_")))

(ert-deftest cocolog-test-named-colors-are-distinct-variables ()
  "Same colour, same variable; a different name makes a different one."
  (let* ((r (cocolog-read-term "p(Ce6194b, Ce6194b, Ce6194b_Kid, C4363d8)."))
         (args (cocolog-args (plist-get r :term))))
    (should (eq (nth 0 args) (nth 1 args)))
    (should-not (eq (nth 0 args) (nth 2 args)))
    (should-not (eq (nth 2 args) (nth 3 args)))))

(ert-deftest cocolog-test-contrast ()
  (should (equal (cocolog-contrast-color "#ffffff") "#000000"))
  (should (equal (cocolog-contrast-color "#000000") "#ffffff")))

(ert-deftest cocolog-test-color-name ()
  (should (equal (cocolog-color-name "#e6194b") "crimson"))
  (should (string-prefix-p "~" (cocolog-color-name "#e6194c"))))

(ert-deftest cocolog-test-color-variables-are-prolog-variables ()
  (let* ((r (cocolog-read-term "p(Cff0000, Cff0000, C4363d8)."))
         (args (cocolog-args (plist-get r :term))))
    (should (cocolog-var-p (nth 0 args)))
    (should (eq (nth 0 args) (nth 1 args)))
    (should-not (eq (nth 0 args) (nth 2 args)))))

;;;; ------------------------------------------------------------------
;;;; Buffer level
;;;; ------------------------------------------------------------------

(defmacro cocolog-test--with-buffer (text &rest body)
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,text)
     (cocolog-mode)
     (goto-char (point-min))
     ,@body))

(defconst cocolog-test-buffer-text "\
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).

%% ?- grandparent(tom, Z).
grandparent(Cff0000, C4363d8) :-
    parent(Cff0000, C3cb44b),
    parent(C3cb44b, C4363d8).
")

(ert-deftest cocolog-test-clause-bounds ()
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (search-forward "parent(bob, ann)")
    (let ((b (cocolog-clause-bounds-at-point)))
      (should (equal (buffer-substring-no-properties (car b) (cdr b))
                     "parent(bob, ann).")))))

(ert-deftest cocolog-test-clause-at-point-from-test-comment ()
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (search-forward "?- grandparent")
    (let* ((db (cocolog-buffer-db))
           (rec (cocolog-clause-at-point db)))
      (should (string-prefix-p "grandparent"
                               (cocolog-term-to-string (cocolog-clause-head rec)))))))

(ert-deftest cocolog-test-extract-queries ()
  (should (equal (cocolog--extract-queries "%% ?- foo(X).\n") '("foo(X).")))
  (should (equal (cocolog--extract-queries "% ?- a. \n% ?- b(1).") '("a." "b(1).")))
  (should (equal (cocolog--extract-queries "%% ?- f(\n%%      X).") '("f(\n     X).")))
  (should (equal (cocolog--extract-queries "%% nothing here") '())))

(ert-deftest cocolog-test-clause-color-usage ()
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (search-forward "grandparent(Cff0000")
    (should (equal (cocolog-clause-color-usage)
                   '(("#ff0000" . 2) ("#4363d8" . 2) ("#3cb44b" . 2))))))

(ert-deftest cocolog-test-run-test-inserts-and-replaces-graph ()
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (search-forward "grandparent(Cff0000")
    (cocolog-run-test-at-point)
    (let ((first (buffer-string)))
      (should (string-match-p "cocolog trace" first))
      (should (string-match-p "solution 1:  Z = ann" first))
      ;; a second run replaces the block instead of adding one
      (goto-char (point-min))
      (search-forward "grandparent(Cff0000")
      (cocolog-run-test-at-point)
      (should (equal first (buffer-string)))
      (should (= 1 (cl-count "cocolog trace" (split-string (buffer-string) "\n")
                             :test (lambda (a b) (string-match-p a b))))))))

(ert-deftest cocolog-test-two-test-cases-one-rule ()
  (cocolog-test--with-buffer "\
parent(tom, bob).

%% ?- childless(bob).
%% ?- childless(tom).
childless(X) :- \\+ parent(X, _).
"
    (search-forward "childless(X)")
    (cocolog-run-test-at-point)
    (let ((once (buffer-string)))
      (should (= 2 (cl-count-if (lambda (l) (string-match-p cocolog--trace-begin-re l))
                                (split-string once "\n"))))
      ;; re-running replaces both blocks, it does not stack them
      (goto-char (point-min))
      (search-forward "childless(X)")
      (cocolog-run-test-at-point)
      (should (equal once (buffer-string))))))

(ert-deftest cocolog-test-clear-trace ()
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (search-forward "grandparent(Cff0000")
    (cocolog-run-test-at-point)
    (should (string-match-p "cocolog trace" (buffer-string)))
    (cocolog-clear-trace-at-point t)
    (should (equal (buffer-string) cocolog-test-buffer-text))))

(ert-deftest cocolog-test-run-all-tests ()
  (cocolog-test--with-buffer
      (concat cocolog-test-buffer-text
              "\n%% ?- parent(bob, X).\nchild(X) :- parent(_, X).\n")
    (cocolog-run-all-tests)
    (should (= 2 (cl-count-if (lambda (l) (string-match-p cocolog--trace-begin-re l))
                              (split-string (buffer-string) "\n"))))
    ;; and running them again keeps exactly two graphs
    (cocolog-run-all-tests)
    (should (= 2 (cl-count-if (lambda (l) (string-match-p cocolog--trace-begin-re l))
                              (split-string (buffer-string) "\n"))))))

(ert-deftest cocolog-test-test-case-below-the-rule ()
  (cocolog-test--with-buffer "\
parent(tom, bob).
uncle(X) :- parent(X, _).
%% ?- uncle(tom).
"
    (search-forward "uncle(X)")
    (cocolog-run-test-at-point)
    (let ((lines (split-string (buffer-string) "\n")))
      ;; the hand written comment survives and the graph goes below it
      (should (cl-position-if (lambda (l) (string-match-p "?- uncle(tom)" l)) lines))
      (should (< (cl-position-if
                  (lambda (l) (string-match-p "\\`%% \\?- uncle(tom)\\.\\'" l)) lines)
                 (cl-position-if (lambda (l) (string-match-p cocolog--trace-begin-re l))
                                 lines))))))

(ert-deftest cocolog-test-graph-keeps-file-valid-prolog ()
  "The generated graph is only comments, so the file still parses."
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (search-forward "grandparent(Cff0000")
    (cocolog-run-test-at-point)
    (let ((db (cocolog-buffer-db)))
      (should (null (cocolog-db-errors db)))
      (should (= 4 (length (cocolog-db-order db)))))))

(ert-deftest cocolog-test-insert-a-variable-the-clause-already-has ()
  "Only the clause's own variables are offered, unnamed ones included."
  (with-temp-buffer
    (cocolog-mode)
    (insert "grandparent(Ce6194b_Grandad, C4363d8, Kid) :-\n    parent(")
    (setq cocolog--color-seed 314)
    (font-lock-ensure)
    (let (grid)
      (cl-letf (((symbol-function 'cocolog-read-color)
                 (lambda (&rest _)
                   ;; the picker is the palette grid, holding just these
                   (setq grid (copy-sequence cocolog--palette-entries))
                   (should cocolog--palette-restricted)
                   ;; take the unnamed one: it cannot be typed by name
                   (cdr (nth 1 cocolog--palette-entries)))))
        (cocolog-insert-clause-variable))
      ;; every variable of the clause, each with the colour it is read by:
      ;; a named one, an unnamed one, and a plain one with its dealt colour
      (should (equal (mapcar #'car grid) '("Grandad" "blue" "Kid")))
      (should (equal (nth 0 (mapcar #'cdr grid)) "#e6194b"))
      (should (equal (nth 1 (mapcar #'cdr grid)) "#4363d8"))
      (should (nth 2 (mapcar #'cdr grid)))
      ;; and what was inserted is the variable itself
      (should (string-suffix-p "parent(C4363d8" (buffer-string)))))
  ;; a clause with nothing in it yet says so rather than offering nothing
  (with-temp-buffer
    (cocolog-mode)
    (insert "p(")
    (should-error (cocolog-insert-clause-variable) :type 'user-error)))

(ert-deftest cocolog-test-clause-picker-follows-the-written-order ()
  "The variables are offered in the order the clause writes them.
A colour variable and an ordinary one are both variables of the clause;
sorting them into two groups puts them out of the order they are read
in."
  (with-temp-buffer
    (cocolog-mode)
    (insert "rule(Alpha, Ce6194b_Beta, C4363d8) :-\n"
            "    first(Gamma, Ce6194b_Beta),\n"
            "    second(")
    (font-lock-ensure)
    (let (grid)
      (cl-letf (((symbol-function 'cocolog-read-color)
                 (lambda (&rest _)
                   (setq grid (mapcar #'car cocolog--palette-entries))
                   nil)))
        (cocolog-insert-clause-variable))
      ;; Alpha is plain, Beta wears a colour, the third has only a colour,
      ;; Gamma is plain again -- and that is the order they were written
      (should (equal grid '("Alpha" "Beta" "blue" "Gamma"))))))

(ert-deftest cocolog-test-clause-picker-keeps-to-the-rule-being-written ()
  "The variables offered are the ones of this rule, finished or not.
A half written rule reads as one clause with the rule below it, and
sits below the graph of the rule above; neither of those has anything
to do with the variables of this one."
  (cl-flet ((offered ()
              (let (grid)
                (cl-letf (((symbol-function 'cocolog-read-color)
                           (lambda (&rest _)
                             (setq grid (mapcar #'car cocolog--palette-entries))
                             nil)))
                  (ignore-errors (cocolog-insert-clause-variable)))
                grid)))
    ;; a rule still being typed, with a finished rule below it
    (with-temp-buffer
      (cocolog-mode)
      (insert "greet(Ce6194b_Hi, C4363d8, Who) -->\n    word(")
      (save-excursion (insert ")\n\nverb(Cffd700_V, Other) --> [sees].\n"))
      (should (equal (offered) '("Hi" "blue" "Who"))))
    ;; and one written under the graph of the rule above it
    (cocolog-test--with-buffer
        (concat "%% ?- p(a, Out).\np(Ce6194b_In, Ce6194b_In).\n")
      (cocolog-run-all-tests)
      (goto-char (point-max))
      (insert "\nrhyme(Cffd700_Word, Rest) -->\n    syllable(")
      (should (equal (offered) '("Word" "Rest"))))))

(ert-deftest cocolog-test-recolor-variable ()
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (cl-letf (((symbol-function 'cocolog-read-color) (lambda (&rest _) "#ffd700")))
      (search-forward "grandparent(Cff0000")
      (goto-char (match-beginning 0))
      (search-forward "Cff0000")
      (goto-char (- (point) 2))
      (cocolog-recolor-variable-at-point)
      (should (string-match-p "grandparent(Cffd700, C4363d8)" (buffer-string)))
      (should (string-match-p "parent(Cffd700, C3cb44b)" (buffer-string)))
      (should-not (string-match-p "Cff0000" (buffer-string))))))

(ert-deftest cocolog-test-name-variable-keeps-the-colour ()
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (search-forward "grandparent(Cff0000")
    (goto-char (- (point) 3))
    (cocolog-name-variable-at-point "Grandad")
    (should (string-match-p "grandparent(Cff0000_Grandad, C4363d8)" (buffer-string)))
    (should (string-match-p "parent(Cff0000_Grandad, C3cb44b)" (buffer-string)))
    ;; still one variable, still red, now also called Grandad
    (should (equal (cocolog-clause-color-usage)
                   '(("#ff0000" . 2) ("#4363d8" . 2) ("#3cb44b" . 2))))
    (should (equal (cdr (assoc "#ff0000" (cocolog-clause-color-tokens)))
                   "Cff0000_Grandad"))
    ;; and an empty name gives the colour name back
    (goto-char (point-min))
    (search-forward "Cff0000_Grandad")
    (goto-char (- (point) 3))
    (cocolog-name-variable-at-point "")
    (should (string-match-p "grandparent(Cff0000, C4363d8)" (buffer-string)))))

(ert-deftest cocolog-test-uncolor-variable ()
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (search-forward "grandparent(Cff0000")
    (goto-char (- (point) 3))
    (cocolog-uncolor-variable-at-point "Grandad")
    (should (string-match-p "grandparent(Grandad, C4363d8)" (buffer-string)))
    (should (string-match-p "parent(Grandad, C3cb44b)" (buffer-string)))))

(ert-deftest cocolog-test-recolor-keeps-the-name ()
  (cocolog-test--with-buffer "p(Ce6194b_Parent) :- q(Ce6194b_Parent).\n"
    (cl-letf (((symbol-function 'cocolog-read-color) (lambda (&rest _) "#ffd700")))
      (goto-char (point-min))
      (search-forward "Ce6194b_Parent")
      (goto-char (- (point) 3))
      (cocolog-recolor-variable-at-point)
      (should (equal (buffer-string)
                     "p(Cffd700_Parent) :- q(Cffd700_Parent).\n")))))

(ert-deftest cocolog-test-variables-after-a-list-bar-are-seen ()
  "The tail of [H|T] starts a symbol of its own, whatever the table says."
  (cocolog-test--with-buffer "p([Ce6194b|C4363d8_Rest]) :- q(Ce6194b, C4363d8_Rest).\n"
    (font-lock-ensure)
    ;; both occurrences of each colour are counted, the ones after | included
    (should (equal (cocolog-clause-color-usage)
                   '(("#e6194b" . 2) ("#4363d8" . 2))))
    ;; and the one straight after the bar is coloured
    (goto-char (point-min))
    (search-forward "|")
    (should (equal (plist-get (get-text-property (point) 'face) :background)
                   "#4363d8"))
    ;; renaming reaches it too
    (goto-char (point-min))
    (search-forward "|C4363d8")
    (goto-char (- (point) 3))
    (cocolog-name-variable-at-point "Tail")
    (should (equal (buffer-string)
                   "p([Ce6194b|C4363d8_Tail]) :- q(Ce6194b, C4363d8_Tail).\n"))))

(ert-deftest cocolog-test-a-clause-gets-colours-that-differ ()
  "No two variables of one rule are given colours that look alike."
  (dolist (source '("p(A, B) :- q(A, B).\n"
                    "p(One, Two, Three) :- q(One, Two, Three).\n"
                    "p(V1, V2, V3, V4, V5) :- q(V1, V2, V3, V4, V5).\n"))
    (cocolog-test--with-buffer source
      (cocolog-colorize-clause)
      (let* ((colors (mapcar #'car (cocolog-clause-color-usage)))
             (worst 1000))
        (should (> (length colors) 1))
        (dolist (a colors)
          (dolist (b colors)
            (unless (equal a b)
              (setq worst (min worst (cocolog-color-distance a b))))))
        ;; the pair that is closest together is still clearly two colours
        (should (>= worst cocolog-color-min-distance)))))
  ;; and the same clause always comes out the same way
  (let (first)
    (dotimes (_ 2)
      (cocolog-test--with-buffer "p(A, B, C) :- q(A, B, C).\n"
        (cocolog-colorize-clause)
        (if first
            (should (equal first (buffer-string)))
          (setq first (buffer-string)))))))

(defun cocolog-test--run-pending-refresh ()
  "Fire the idle refresh the way Emacs would once typing stops."
  (when (timerp cocolog--refresh-timer)
    (let ((fn (timer--function cocolog--refresh-timer))
          (args (timer--args cocolog--refresh-timer)))
      (cancel-timer cocolog--refresh-timer)
      (setq cocolog--refresh-timer nil)
      (apply fn args))))

(ert-deftest cocolog-test-every-change-redraws-the-graph ()
  "A graph is an answer about the rule above it; editing the rule redraws it."
  ;; inserting a variable makes the rule a different one, and says so
  (cocolog-test--with-buffer "%% ?- p(a, Out).\np(Ce6194b_In, Ce6194b_In).\n"
    (cocolog-run-all-tests)
    (should (string-match-p "▸1 p(Ce6194b_In, Ce6194b_In)" (buffer-string)))
    (cl-letf (((symbol-function 'cocolog-read-color) (lambda (&rest _) "#3cb44b")))
      (goto-char (point-min))
      (search-forward "p(Ce6194b_In")
      (insert ", ")
      (cocolog-insert-color-variable))
    (should (string-match-p "unknown procedure p/2" (buffer-string))))
  ;; typing redraws it too, once you stop -- for those who ask for that
  (let ((cocolog-refresh-idle 2.0))
    (cocolog-test--with-buffer "%% ?- p(a, Out).\np(Ce6194b_In, Ce6194b_In).\n"
      (cocolog-run-all-tests)
      (goto-char (point-min))
      (search-forward "p(Ce6194b_In")
      (cocolog-test--type ", Extra")
      (should (timerp cocolog--refresh-timer))
      (cocolog-test--run-pending-refresh)
      (should (string-match-p "unknown procedure p/2" (buffer-string))))
    ;; a rule that does not parse yet is not run: there is nothing to say
    (cocolog-test--with-buffer "%% ?- p(a, Out).\np(Ce6194b_In, Ce6194b_In).\n"
      (cocolog-run-all-tests)
      (goto-char (point-min))
      (search-forward "p(Ce6194b_In")
      (cocolog-test--type ", ")
      (cocolog-test--run-pending-refresh)
      (should (string-match-p "▸1 p(Ce6194b_In, Ce6194b_In)" (buffer-string))))))

(ert-deftest cocolog-test-typing-runs-nothing-of-its-own-accord ()
  "By default a rule is run when you ask, and at no other time.
A rule being written is half a rule, and the rules a graph helps most
with are the ones that do not terminate yet."
  (should-not cocolog-refresh-idle)
  (cocolog-test--with-buffer "%% ?- p(a, Out).\np(Ce6194b_In, Ce6194b_In).\n"
    (cocolog-run-all-tests)
    (let ((drawn (buffer-string)))
      (goto-char (point-min))
      (search-forward "p(Ce6194b_In")
      (cocolog-test--type ", Extra")
      (should-not (timerp cocolog--refresh-timer))
      ;; the graph is left exactly as it was, stale and untouched
      (should (string-match-p "▸1 p(Ce6194b_In, Ce6194b_In)" (buffer-string)))
      (should (equal (length (split-string drawn "\n"))
                     (length (split-string (buffer-string) "\n"))))
      ;; and C-c C-t draws it again
      (cocolog-run-test-at-point)
      (should (string-match-p "unknown procedure p/2" (buffer-string))))))

(ert-deftest cocolog-test-recolouring-a-clause-draws-its-graph-again ()
  "A graph is run again when the rule under it is recoloured."
  (cocolog-test--with-buffer
      (concat "%% ?- last([a,b], X).\n"
              "last([Ce6194b_Item], Ce6194b_Item).\n"
              "last([_|C3cb44b_Rest], Ce6194b_Item) :- last(C3cb44b_Rest, Ce6194b_Item).\n")
    (cocolog-run-all-tests)
    (should (string-match-p "▸1 last(\\[Ce6194b_Item\\]" (buffer-string)))
    (cl-letf (((symbol-function 'cocolog-read-color) (lambda (&rest _) "#ffd700")))
      (goto-char (point-min))
      (search-forward "Ce6194b_Item")
      (goto-char (- (point) 4))
      (cocolog-recolor-variable-at-point))
    (let ((text (buffer-string)))
      ;; the graph followed the clause that changed ...
      (should (string-match-p "▸1 last(\\[Cffd700_Item\\]" text))
      ;; ... and the other clause of the predicate, which did not change,
      ;; is still shown with its own colours
      (should (string-match-p "^last(\\[_|C3cb44b_Rest\\], Ce6194b_Item)" text))
      (should (string-match-p "▸2 last(\\[_|C3cb44b_Rest\\], Ce6194b_Item)" text))
      ;; and it is still one graph, not two
      (should (= 1 (cl-count ?╭ text))))))

(ert-deftest cocolog-test-clause-color-tokens-and-clashes ()
  (cocolog-test--with-buffer "p(Ce6194b_Parent, Ce6194b_Kid, C4363d8) :- q(Ce6194b_Parent).\n"
    (goto-char (point-min))
    (should (equal (cocolog-clause-color-tokens)
                   '(("#e6194b" . "Ce6194b_Parent") ("#4363d8" . "C4363d8"))))
    ;; one colour, two variables: the mode says so
    (let ((clashes (cocolog-clause-color-conflicts)))
      (should (= 1 (length clashes)))
      (should (equal (car clashes) '("#e6194b" "Parent" "Kid"))))
    (cocolog-check-buffer)
    (with-current-buffer "*cocolog checks*"
      (should (string-match-p "crimson stands for two variables here: Parent, Kid"
                              (buffer-string))))
    (kill-buffer "*cocolog checks*")))

(ert-deftest cocolog-test-colorize-clause ()
  (cocolog-test--with-buffer "p(X, Y) :- q(X), r(Y, X).\n"
    (cocolog-colorize-clause)
    ;; the variables keep the names they had, and gain a colour
    (should (string-match-p "\\`p(C4b0082_X, C9370db_Y)" (buffer-string)))
    (let ((text (buffer-string)))
      (should-not (string-match-p "\\_<X\\_>" text))
      (should-not (string-match-p "\\_<Y\\_>" text))
      (should-not (string-match-p "\\_<Cp\\|\\_<Cq\\|\\_<Cr" text))
      ;; X occurred three times, Y twice
      (should (equal (mapcar #'cdr (cocolog-clause-color-usage)) '(3 2)))
      ;; and the clause is still the same clause, with two variables
      (should (= 2 (length (plist-get (cocolog-read-term text) :order)))))))

(ert-deftest cocolog-test-lowercase-atoms-are-not-variables ()
  (cocolog-test--with-buffer "p(x, Y).\n"
    (goto-char (point-min))
    (search-forward "x")
    (goto-char (match-beginning 0))
    (should (null (cocolog--variable-at-point)))))

(ert-deftest cocolog-test-palette-grid-is-a-table ()
  "Every cell is pinned to its column, whatever it has inside it."
  (let ((buffer (get-buffer-create " *cocolog palette test*"))
        (cocolog--palette-index 20)
        ;; used colours carry a marker glyph that need not be one column wide
        (cocolog--palette-used '(("#e6194b" . 2) ("#4363d8" . 1))))
    (unwind-protect
        (progn
          (cocolog--palette-render buffer)
          (with-current-buffer buffer
            (let ((rows '()))
              (goto-char (point-min))
              (forward-line 2)
              (dotimes (_ 3)
                (let ((pos (line-beginning-position))
                      (eol (line-end-position))
                      (stops '()))
                  (while (< pos eol)
                    (let ((spec (get-text-property pos 'display)))
                      (when (and (consp spec) (eq (car spec) 'space))
                        (push (plist-get (cdr spec) :align-to) stops)))
                    (setq pos (1+ pos)))
                  (push (nreverse stops) rows))
                (forward-line 1))
              ;; each row stops at the same columns as the one above it
              (should (= 1 (length (delete-dups (mapcar #'copy-sequence rows)))))
              ;; and those columns are the ones the grid is laid out on
              (should (equal (car rows)
                             (cl-loop for c from 0 below cocolog-palette-columns
                                      append (list (+ 2 (* c 5) 4)
                                                   (+ 2 (* c 5) 5))))))))
      (kill-buffer buffer))))

(ert-deftest cocolog-test-palette-renders ()
  (let ((buffer (get-buffer-create " *cocolog palette test*"))
        (cocolog--palette-index 0)
        (cocolog--palette-used '(("#e6194b" . 2))))
    (unwind-protect
        (progn
          (cocolog--palette-render buffer)
          (with-current-buffer buffer
            (should (string-match-p "crimson" (buffer-string)))
            (should (string-match-p "already used 2" (buffer-string)))
            (goto-char (point-min))
            (should (text-property-search-forward 'cocolog-color "#e6194b" t))))
      (kill-buffer buffer))))

(ert-deftest cocolog-test-swatch-hides-the-colour-part ()
  "The Cxxxxxx part is never shown: a name if there is one, a colour if not."
  (cocolog-test--with-buffer "p(Cd62728, Ce6194b_Parent).\n"
    (font-lock-ensure)
    ;; a variable with no name of its own is its colour and nothing else
    (goto-char (point-min))
    (search-forward "Cd62728")
    (let ((swatch (get-text-property (match-beginning 0) 'display)))
      (should (equal swatch cocolog-swatch-text))
      (should (equal (plist-get (get-text-property 0 'face swatch) :background)
                     "#d62728")))
    ;; one with a name shows the name, never the colour written before it
    (goto-char (point-min))
    (search-forward "Ce6194b_Parent")
    (should (equal (get-text-property (match-beginning 0) 'display) " Parent "))
    ;; the whole variable is one thing as far as point is concerned
    (should (get-text-property (match-beginning 0) 'cursor-intangible))
    ;; the tooltip is a function: naming a colour is not worth doing until
    ;; someone points at it
    (let ((echo (get-text-property (match-beginning 0) 'help-echo)))
      (should (functionp echo))
      (should (string-match-p "crimson" (funcall echo))))
    ;; nothing on screen spells the colour out
    (let ((shown "") (pos (point-min)))
      (while (< pos (point-max))
        (let ((next (or (next-property-change pos) (point-max)))
              (disp (get-text-property pos 'display)))
          (setq shown (concat shown (if (stringp disp) disp
                                      (buffer-substring-no-properties pos next))))
          (setq pos next)))
      (should-not (string-match-p "C[0-9a-f]\\{6\\}" shown))
      (should (string-match-p "Parent" shown)))))

(ert-deftest cocolog-test-raw-style-shows-the-file-as-it-is ()
  (let ((cocolog-swatch-style 'raw))
    (cocolog-test--with-buffer "p(Ce6194b_Parent).\n"
      (font-lock-ensure)
      (goto-char (point-min))
      (search-forward "Ce6194b_Parent")
      (should-not (get-text-property (match-beginning 0) 'display))
      ;; still coloured, just not hidden
      (should (equal (plist-get (get-text-property (match-beginning 0) 'face)
                                :background)
                     "#e6194b")))))

(ert-deftest cocolog-test-a-colour-variable-is-deleted-whole ()
  "The colour cannot be edited a character at a time."
  (cocolog-test--with-buffer "p(Ce6194b_Parent, X).\n"
    (goto-char (point-min))
    (search-forward "Ce6194b_Parent")
    (cocolog-delete-variable-backward)
    (should (equal (buffer-string) "p(, X).\n"))
    ;; and forwards
    (erase-buffer)
    (insert "p(Ce6194b_Parent, X).\n")
    (goto-char (point-min))
    (search-forward "p(")
    (cocolog-delete-variable-forward)
    (should (equal (buffer-string) "p(, X).\n"))
    ;; anywhere else it deletes a character, as it always did
    (erase-buffer)
    (insert "p(abc).\n")
    (goto-char (point-min))
    (search-forward "abc")
    (cocolog-delete-variable-backward)
    (should (equal (buffer-string) "p(ab).\n"))))

(ert-deftest cocolog-test-a-swatch-does-not-rub-off-on-what-follows ()
  "What you type after a swatch is ordinary text, reachable and deletable.
Text inherits the properties of the character before it, and a swatch
keeps point out of itself; without care the comma typed after one could
not be reached to be deleted."
  (with-temp-buffer
    (cocolog-mode)
    (insert "p(Cff7f50_Argi")
    (font-lock-ensure)
    ;; carry on typing, as after the picker has put a variable in
    (dolist (c (append "), " nil))
      (let ((last-command-event c)) (call-interactively #'self-insert-command)))
    ;; the characters just typed are plain text, right away, before
    ;; anything has been fontified again
    (dolist (offset '(1 2 3))
      (let ((pos (- (point-max) offset)))
        (should (equal (list (char-to-string (char-after pos))
                             (get-text-property pos 'cursor-intangible)
                             (get-text-property pos 'display))
                       (list (char-to-string (char-after pos)) nil nil)))))
    ;; and deleting the comma takes the comma, not the variable
    (goto-char (1- (point-max)))
    (cocolog-delete-variable-backward)
    (should (equal (buffer-string) "p(Cff7f50_Argi) "))))

(ert-deftest cocolog-test-point-steps-over-a-colour-variable ()
  "Point is kept out of a swatch, so the colour cannot be typed into."
  (cocolog-test--with-buffer "p(Ce6194b_Parent).\n"
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward "Ce6194b_Parent")
    (let ((beg (match-beginning 0)) (end (match-end 0)))
      ;; the whole variable is marked, from its first character to its last
      (should (get-text-property beg 'cursor-intangible))
      (should (get-text-property (1- end) 'cursor-intangible))
      ;; and it stays hidden wherever point is, which is what the old
      ;; reveal-at-point behaviour used to undo
      (goto-char (+ beg 3))
      (should (equal (get-text-property beg 'display) " Parent ")))))

(ert-deftest cocolog-test-indentation ()
  (cocolog-test--with-buffer "\
grandparent(X, Z) :-
parent(X, Y),
parent(Y, Z).
foo(1).
"
    (indent-region (point-min) (point-max))
    (should (equal (buffer-string) "\
grandparent(X, Z) :-
    parent(X, Y),
    parent(Y, Z).
foo(1).
"))))

(ert-deftest cocolog-test-check-buffer-reports-errors ()
  (cocolog-test--with-buffer "good(1).\nbad( .\n"
    (cocolog-check-buffer)
    (should (get-buffer "*cocolog checks*"))
    (with-current-buffer "*cocolog checks*"
      (should (string-match-p "syntax error\\|expected\\|unexpected" (buffer-string))))
    (kill-buffer "*cocolog checks*")))

(ert-deftest cocolog-test-query-command ()
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (let ((r (cocolog-query "parent(tom, X)")))
      (should (= 2 (length (cocolog-result-solutions r))))
      (with-current-buffer "*cocolog*"
        (should (string-match-p "solution 2" (buffer-string))))
      (kill-buffer "*cocolog*"))))

;;;; ------------------------------------------------------------------
;;;; Grammar rules
;;;; ------------------------------------------------------------------

(defun cocolog-test--dcg (source)
  "Return the translation of the grammar rule SOURCE, as text.
The fresh variables the translation invents are renumbered from one, as
the engine\='s own counter runs on across a session."
  (let ((text (cocolog-term-to-string
               (cocolog-dcg-translate (plist-get (cocolog-read-term source) :term))))
        (seen '())
        (n 0))
    (replace-regexp-in-string
     "_G[0-9]+"
     (lambda (m)
       (or (cdr (assoc m seen))
           (let ((new (format "_G%d" (cl-incf n))))
             (push (cons m new) seen)
             new)))
     text t t)))

(ert-deftest cocolog-test-dcg-translation ()
  (should (equal (cocolog-test--dcg "greeting --> [hello].")
                 "greeting(S0, S) :- S0 = [hello|S]"))
  (should (equal (cocolog-test--dcg "s --> np, vp.")
                 "s(S0, S) :- np(S0, _G1), vp(_G1, S)"))
  (should (equal (cocolog-test--dcg "nothing --> [].")
                 "nothing(S0, S) :- S0 = S"))
  ;; an argument of the nonterminal keeps its place, the lists go last
  (should (equal (cocolog-test--dcg "n(cat) --> [cat].")
                 "n(cat, S0, S) :- S0 = [cat|S]"))
  ;; a braced goal reads nothing, so it needs no list variable of its own
  (should (equal (cocolog-test--dcg "d(X) --> [C], { X is C - 1 }.")
                 "d(X, S0, S) :- S0 = [C|S], X is C - 1"))
  ;; ... and neither does a cut
  (should (equal (cocolog-test--dcg "c --> [a], !, [b].")
                 "c(S0, S) :- S0 = [a|_G1], !, _G1 = [b|S]"))
  ;; a disjunction offers both sides the same list
  (should (equal (cocolog-test--dcg "opt(X) --> ( [X] ; [] ).")
                 "opt(X, S0, S) :- S0 = [X|S] ; S0 = S"))
  ;; a string is a run of terminals
  (should (equal (cocolog-test--dcg "ab --> \"ab\".")
                 "ab(S0, S) :- S0 = [97, 98|S]"))
  ;; a pushback puts something back on the list
  (should (equal (cocolog-test--dcg "a, [b] --> [c].")
                 "a(S0, S) :- S0 = [c|_G1], S = [b|_G1]"))
  ;; a variable body is resolved when it is known
  (should (equal (cocolog-test--dcg "x --> Y.")
                 "x(S0, S) :- phrase(Y, S0, S)"))
  ;; anything that is not a grammar rule is left alone
  (should (equal (cocolog-test--dcg "p(X) :- q(X).") "p(X) :- q(X)")))

(defconst cocolog-test-grammar "
sentence(s(NP, VP)) --> noun_phrase(NP), verb_phrase(VP).
noun_phrase(np(D, N)) --> det(D), noun(N).
verb_phrase(vp(V)) --> verb(V).
det(the) --> [the].
noun(cat) --> [cat].
noun(mouse) --> [mouse].
verb(sleeps) --> [sleeps].
ab --> [].
ab --> [a], ab, [b].
digit(D) --> [C], { C >= 0'0, C =< 0'9, D is C - 0'0 }.
digits([D|T]) --> digit(D), digits(T).
digits([D]) --> digit(D).
")

(ert-deftest cocolog-test-dcg-is-stored-with-two-more-arguments ()
  (let ((db (cocolog-consult-string cocolog-test-grammar)))
    (should (null (cocolog-db-errors db)))
    (should (= 1 (length (gethash "sentence/3" (cocolog-db-preds db)))))
    (should (= 2 (length (gethash "ab/2" (cocolog-db-preds db)))))
    ;; the graph shows a grammar rule as it was written
    (should (equal (cocolog--clause-label
                    (car (gethash "verb_phrase/3" (cocolog-db-preds db))))
                   "verb_phrase(vp(V)) --> verb(V)."))))

(ert-deftest cocolog-test-dcg-parses-and-generates ()
  (let ((db (cocolog-consult-string cocolog-test-grammar)))
    (should (equal (cocolog-test--solutions
                    db "phrase(sentence(T), [the, cat, sleeps])")
                   '(("s(np(the, cat), vp(sleeps))"))))
    ;; phrase/3 hands back what was not read
    (should (equal (cocolog-test--solutions db "phrase(noun(N), [cat, sleeps], R)")
                   '(("cat" "[sleeps]"))))
    ;; the same rules generate
    (should (equal (cocolog-test--solutions db "length(L, 4), phrase(ab, L)")
                   '(("[a, a, b, b]"))))
    (should (null (cocolog-test--solutions db "phrase(ab, [a, b, b])")))
    ;; a braced goal, and a string of character codes
    (should (equal (cocolog-test--solutions db "phrase(digits(Ds), \"407\")")
                   '(("[4, 0, 7]"))))))

(ert-deftest cocolog-test-colour-commands-work-on-grammar-rules ()
  "A rule written with --> is a clause like any other to these commands."
  ;; a name the rule already knows is adopted while typing
  (with-temp-buffer
    (cocolog-mode)
    (insert "sentence(s(Ce6194b_NP, C4363d8_VP)) -->\n    ")
    (cocolog-test--type "noun_phrase(NP), verb_phrase(VP).")
    (should (string-match-p "noun_phrase(Ce6194b_NP), verb_phrase(C4363d8_VP)"
                            (buffer-string))))
  ;; every variable of a grammar rule can be given a colour at once
  (cocolog-test--with-buffer "digits([D|T]) --> digit(D), digits(T).\n"
    (cocolog-colorize-clause)
    (let ((text (buffer-string)))
      (should-not (string-match-p "\\_<[DT]\\_>" text))
      (should (string-match-p "digits(\\[C[0-9a-f]\\{6\\}_D|C[0-9a-f]\\{6\\}_T\\])"
                              text))
      ;; still one rule about two variables
      (should (= 2 (length (plist-get (cocolog-read-term text) :order)))))))

(ert-deftest cocolog-test-recolouring-carries-the-test-case-along ()
  "The query beside a rule names the same variables, so it follows too."
  (cocolog-test--with-buffer
      (concat "%% ?- phrase(greet(Cffd700_Who), [hello, world]).\n"
              "greet(Cffd700_Who) --> [hello], name(Cffd700_Who).\n"
              "name(world) --> [world].\n")
    (cocolog-run-all-tests)
    (cl-letf (((symbol-function 'cocolog-read-color) (lambda (&rest _) "#3cb44b")))
      (goto-char (point-min))
      (search-forward "greet(Cffd700_Who) -->")
      (goto-char (- (point) 8))
      (cocolog-recolor-variable-at-point))
    (let ((text (buffer-string)))
      ;; nothing anywhere still names the old colour
      (should-not (string-match-p "Cffd700_Who" text))
      ;; the test case, the rule and the graph all agree
      (should (string-match-p "%% \\?- phrase(greet(C3cb44b_Who)" text))
      (should (string-match-p "^greet(C3cb44b_Who) -->" text))
      (should (string-match-p "solution 1:  C3cb44b_Who = world" text)))))

(ert-deftest cocolog-test-dcg-graph-anchors-below-the-last-clause ()
  "A graph goes under the whole predicate, not between two of its clauses."
  (cocolog-test--with-buffer
      "%% ?- phrase(ab, [a, b]).\nab --> [].\nab --> [a], ab, [b].\n"
    (cocolog-run-all-tests)
    (let ((lines (split-string (buffer-string) "\n")))
      (should (equal (nth 1 lines) "ab --> []."))
      (should (equal (nth 2 lines) "ab --> [a], ab, [b]."))
      (should (string-match-p "cocolog trace" (nth 3 lines))))
    ;; and running again replaces it rather than piling up
    (let ((before (buffer-size)))
      (cocolog-run-all-tests)
      (should (= before (buffer-size))))))

;;;; ------------------------------------------------------------------
;;;; Colours for variables that carry none
;;;; ------------------------------------------------------------------

(defmacro cocolog-test--with-seeded-buffer (seed text &rest body)
  "Run BODY in a cocolog buffer of TEXT whose colours come from SEED.
Colouring the ordinary variables is off unless asked for, and asking for
it is what every test using this is about, so it is turned on here."
  (declare (indent 2))
  `(with-temp-buffer
     (insert ,text)
     (cocolog-mode)
     (setq-local cocolog-color-plain-variables t)
     (setq cocolog--color-seed ,seed)
     (cocolog--forget-plain-colors)
     (font-lock-ensure)
     (goto-char (point-min))
     ,@body))

(defun cocolog-test--colors ()
  "Return an alist of (NAME . BACKGROUND) for the capitalised words of the buffer."
  (let ((case-fold-search nil) (out '()))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "\\_<\\([A-Z][A-Za-z0-9_]*\\)\\_>" nil t)
        (push (cons (match-string-no-properties 0)
                    (plist-get (get-text-property (match-beginning 0) 'face)
                               :background))
              out)))
    (nreverse out)))

(ert-deftest cocolog-test-plain-variables-are-coloured-on-screen ()
  "An ordinary variable is coloured without anything being written down."
  (cocolog-test--with-seeded-buffer 7
      "grandparent(Grandad, Kid) :-\n    parent(Grandad, Between),\n    parent(Between, Kid).\n"
    (let ((colors (cocolog-test--colors)))
      ;; the file itself is untouched
      (should (string-match-p "grandparent(Grandad, Kid)" (buffer-string)))
      (should-not (string-match-p "C[0-9a-f]\\{6\\}" (buffer-string)))
      ;; every occurrence of a name has the same colour ...
      (should (= 1 (length (delete-dups
                            (mapcar #'cdr (cl-remove-if-not
                                           (lambda (c) (equal (car c) "Grandad"))
                                           colors))))))
      ;; ... and the three variables of the clause have three different ones
      (let ((distinct (delete-dups (mapcar #'cdr colors))))
        (should (= 3 (length distinct)))
        (should-not (memq nil distinct))))))

(ert-deftest cocolog-test-graph-variables-take-the-rule-s-colours ()
  "A generated graph is drawn in the colours of the rule it belongs to."
  (cocolog-test--with-seeded-buffer 314
      "%% ?- last(([a,b]), Answer).\nlast([Item], Item).\nlast([_|Rest], Item) :- last(Rest, Item).\n"
    (cocolog-run-all-tests)
    (font-lock-flush)
    (font-lock-ensure)
    (cl-flet ((bg (re) (goto-char (point-min))
                  (should (re-search-forward re nil t))
                  (plist-get (get-text-property (match-beginning 1) 'face)
                             :background)))
      (let ((item (bg "^last(\\[\\(Item\\)\\], Item)"))
            (rest (bg "^last(\\[_|\\(Rest\\)\\]")))
        (should item)
        (should rest)
        (should-not (equal item rest))
        ;; the same names inside the graph, which is a comment, match
        (should (equal item (bg "%%.*▸1 last(\\[\\(Item\\)\\]")))
        (should (equal rest (bg "%%.*▸2 last(\\[_|\\(Rest\\)\\]")))
        ;; a variable only the query mentions gets one of its own
        (let ((answer (bg "solution 1:  \\(Answer\\)")))
          (should answer)
          (should-not (member answer (list item rest))))))))

(ert-deftest cocolog-test-a-predicate-shares-one-set-of-colours ()
  "Every clause of a predicate, and the graph under them, agree."
  (cocolog-test--with-seeded-buffer 314
      (concat "%% Commentary about Recursion in Prolog, mentioning Item.\n\n"
              "%% ?- last([a,b], Answer).\n"
              "last([Item], Item).\n"
              "last([_|Rest], Item) :- last(Rest, Item).\n")
    (cocolog-run-all-tests)
    (font-lock-flush)
    (font-lock-ensure)
    (cl-flet ((bg (re) (goto-char (point-min))
                  (should (re-search-forward re nil t))
                  (plist-get (get-text-property (match-beginning 1) 'face)
                             :background)))
      (let ((item (bg "^last(\\[\\(Item\\)\\], Item)")))
        (should item)
        ;; the other clause of the predicate says the same
        (should (equal item (bg "^last(\\[_|Rest\\], \\(Item\\))")))
        ;; and so does every line of the graph, whichever clause it is showing
        (should (equal item (bg "▸1 last(\\[\\(Item\\)\\]")))
        (should (equal item (bg "▸2 last(\\[_|Rest\\], \\(Item\\))")))
        ;; a word in the commentary is not a variable and takes no colour
        (should-not (bg "about \\(Recursion\\)"))
        (should-not (bg "in \\(Prolog\\)"))
        ;; ... not even one that is spelled like a variable of the rule
        (should-not (bg "mentioning \\(Item\\)"))))))

(ert-deftest cocolog-test-example-files-are-coloured-consistently ()
  "In every example, one name means one colour throughout its predicate.
This covers the clauses, the test case above them and every line of the
graph below: they are all the same variables."
  (let ((dir (file-name-directory (locate-library "cocolog-mode"))))
    (dolist (name '("family.colog" "lists.colog" "grammar.colog"))
      (let ((file (expand-file-name (concat "examples/" name) dir)))
        (skip-unless (file-readable-p file))
        (with-temp-buffer
          (insert-file-contents file)
          (cocolog-mode)
          (setq cocolog--color-seed 15)
          (cocolog--forget-plain-colors)
          (font-lock-ensure)
          (let ((db (cocolog-buffer-db))
                (case-fold-search nil)
                (checked 0))
            (dolist (rec (cocolog-db-order db))
              (let ((region (cocolog--predicate-region (cocolog-clause-start rec)))
                    (seen (make-hash-table :test 'equal)))
                (save-excursion
                  (goto-char (car region))
                  (while (re-search-forward "\\_<\\([A-Z][A-Za-z0-9_]*\\)\\_>"
                                            (cdr region) t)
                    (let ((token (match-string-no-properties 0))
                          (bg (plist-get (get-text-property (match-beginning 0) 'face)
                                         :background)))
                      (when bg
                        (puthash token (cons bg (gethash token seen)) seen)))))
                (maphash
                 (lambda (token colors)
                   (cl-incf checked)
                   (let ((distinct (delete-dups (copy-sequence colors))))
                     (should (equal (list name token (length distinct))
                                    (list name token 1)))))
                 seen)))
            ;; the files really do have variables in them
            (should (> checked 3))))))))

(ert-deftest cocolog-test-a-query-and-its-graph-agree ()
  "A test case, and every line of the graph it produced, name one colour."
  (cocolog-test--with-seeded-buffer 314
      (concat "%% ?- grand(tom, Who).\n"
              "grand(A, C) :- link(A, B), link(B, C).\n"
              "link(tom, bob).\nlink(bob, ann).\n")
    (cocolog-run-all-tests)
    (font-lock-flush)
    (font-lock-ensure)
    (let ((case-fold-search nil) (colors '()))
      (goto-char (point-min))
      (while (re-search-forward "\\_<Who\\_>" nil t)
        (push (plist-get (get-text-property (match-beginning 0) 'face) :background)
              colors))
      ;; the query, the graph header, the goals and the solution lines
      (should (> (length colors) 3))
      (should (= 1 (length (delete-dups (copy-sequence colors)))))
      (should (car colors)))))

(ert-deftest cocolog-test-a-clause-ends-even-when-a-comment-follows ()
  "The period of a clause is judged by its own line, not the next one.
Whether a period ends a clause or sits in a comment is answered by
looking at its line, which is much quicker than asking the parser -- but
the search stops after the whitespace that follows the period, and that
can be a newline, so the line to look at is the period's own."
  (cocolog-test--with-buffer
      (concat "p(1).\n"
              "%% ╭── cocolog trace ── ?- p(X).\n"
              "%% ╰── cocolog: 1 solution\n"
              "q(2).\n")
    (goto-char (point-min))
    ;; the period of p(1) ends a clause even though a comment follows it
    (should (= (cocolog--next-clause-end (point-min)) 6))
    ;; and the graph in between is not mistaken for one
    (should (= (cocolog--next-clause-end 6) (- (point-max) 1)))
    ;; backwards likewise
    (should (= (cocolog--previous-clause-end (point-max)) (- (point-max) 1)))))

(ert-deftest cocolog-test-character-literals-do-not-open-a-quoted-atom ()
  "0'c is a character, not the start of a quoted atom.
An odd number of them on a line would otherwise leave the rest of the
file looking like one long quoted atom, and every question about what
is code and what is a comment would answer wrongly."
  (cocolog-test--with-buffer
      "p(X) :- X >= 0'0, X =< 0'9, Y is 0'0 - 1.\nq(Y) :- r(Y).\n"
    (syntax-propertize (point-max))
    ;; the apostrophe of a character literal is punctuation
    (goto-char (point-min))
    (search-forward "0'0")
    (should (equal (get-text-property (- (point) 2) 'syntax-table) '(1)))
    ;; so the clause after it is ordinary code
    (goto-char (point-min))
    (search-forward "q(Y)")
    (should-not (nth 8 (syntax-ppss (point))))
    ;; and it still parses as the character code it is
    (should (equal (cocolog-test--solutions
                    (cocolog-consult-string "c(X) :- X is 0'a.") "c(X)")
                   '(("97"))))))

(ert-deftest cocolog-test-clause-end-behind-point-is-found ()
  "A backward clause scan must see the clause point sits just behind.
The period and the newline after it are two characters, and a backward
search only finds a match ending at or before point."
  (cocolog-test--with-buffer "a(1).\nb(X) :- c(X).\nd(2).\n"
    ;; from the newline that ends `b', the clause behind it is `b' itself
    (goto-char (point-min))
    (search-forward "c(X).")
    (should (= (cocolog--previous-clause-end (point)) (point)))
    (should (= (cocolog--previous-clause-end (1+ (point))) (point)))
    ;; and from inside `d', it is still the end of `b'
    (let ((end-of-b (point)))
      (search-forward "d(2)")
      (should (= (cocolog--previous-clause-end (point)) end-of-b)))))

(ert-deftest cocolog-test-plain-colours-skip-comments-and-strings ()
  (cocolog-test--with-seeded-buffer 7
      "%% ?- p(Who, X).  The Cat sees.\np(X) :- q(X, \"A string with X\").\n"
    (dolist (probe (cocolog-test--colors))
      (pcase probe
        ;; a test case is a query: what it names are variables
        (`("Who" . ,bg) (should bg))
        ;; a remark after the query, on the same line, is prose again
        (`("The" . ,bg) (should (null bg)))
        (`("Cat" . ,bg) (should (null bg)))
        ;; and so is the inside of a string
        (`("A" . ,bg) (should (null bg)))))
    ;; the variable in the code got one, the same one the query shows
    (goto-char (point-min))
    (search-forward "p(X)")
    (let ((in-code (plist-get (get-text-property (- (point) 2) 'face) :background)))
      (should in-code)
      (goto-char (point-min))
      (search-forward "?- p(Who, X)")
      (should (equal in-code
                     (plist-get (get-text-property (- (point) 2) 'face) :background))))))

(ert-deftest cocolog-test-plain-colours-avoid-the-written-ones ()
  "A colour written into the clause is not dealt to anything else."
  (cocolog-test--with-seeded-buffer 7 "mixed(X, Ce6194b) :- q(X, Ce6194b).\n"
    (let ((colors (cocolog-test--colors)))
      (should (equal (cdr (assoc "Ce6194b" colors)) "#e6194b"))
      (should-not (equal (cdr (assoc "X" colors)) "#e6194b")))))

(ert-deftest cocolog-test-dealt-colours-keep-away-from-pinned-ones ()
  "A dealt colour never looks like one written into the file, anywhere.
Two swatches of one colour a line apart read as one variable, and a
colour someone pinned is the one with a claim to it."
  (cocolog-test--with-seeded-buffer 314
      (concat "%% ?- phrase(def(Na, As), [def, sum, a]).\n"
              "def(Name, Cff7f50_Argi) --> [def], [Name], [Cff7f50_Argi], [As].\n"
              "\n"
              "%% ?- phrase(swap(A, B), [12, 15]).\n"
              "swap(Cbfef45, Cf0f0f0), [Cf0f0f0], [Cbfef45] --> "
              "[Cbfef45], [Cf0f0f0].\n")
    (let ((pinned (cocolog-pinned-colors)))
      (should (equal (sort (copy-sequence pinned) #'string<)
                     '("#bfef45" "#f0f0f0" "#ff7f50")))
      (dolist (entry (cocolog-test--colors))
        (let ((name (car entry)) (hex (cdr entry)))
          (when (and hex (not (cocolog-color-var-p name)))
            (dolist (other pinned)
              ;; not merely different: far enough not to be mistaken
              (should (equal (list name other
                                   (>= (cocolog-color-distance hex other)
                                       cocolog-color-min-distance))
                             (list name other t))))))))))

(ert-deftest cocolog-test-plain-colours-change-with-the-seed ()
  "Opening the file again deals another hand."
  (let (first second)
    (cocolog-test--with-seeded-buffer 7 "p(X, Y) :- q(X, Y).\n"
      (setq first (cocolog-test--colors)))
    (cocolog-test--with-seeded-buffer 99 "p(X, Y) :- q(X, Y).\n"
      (setq second (cocolog-test--colors)))
    (should-not (equal first second))
    ;; but each of them is consistent in itself
    (dolist (colors (list first second))
      (should (= 2 (length (delete-dups (mapcar #'cdr colors))))))))

(ert-deftest cocolog-test-plain-colours-are-off-until-they-are-asked-for ()
  "A file opens as it was written; the colours are something you ask for."
  (let ((before cocolog-color-plain-variables))
    (unwind-protect
        (with-temp-buffer
          (insert "p(X) :- q(X).\n")
          (cocolog-mode)
          (should-not cocolog-color-plain-variables)   ; the default
          (font-lock-ensure)
          (goto-char (point-min))
          (should (cl-every (lambda (c) (null (cdr c))) (cocolog-test--colors)))
          ;; and C-c C-c brings them out
          (call-interactively (key-binding (kbd "C-c C-c")))
          (font-lock-flush)
          (font-lock-ensure)
          (goto-char (point-min))
          (should (cl-some #'cdr (cocolog-test--colors))))
      (setq cocolog-color-plain-variables before))))

;;;; ------------------------------------------------------------------
;;;; Swatches against the theme
;;;; ------------------------------------------------------------------

(ert-deftest cocolog-test-swatch-text-does-not-depend-on-the-theme ()
  "Black or white on a swatch is decided by the swatch, not the frame."
  (dolist (background '(0.02 0.5 0.99))
    (cl-letf (((symbol-function 'cocolog-background-luminance)
               (lambda () background)))
      (should (equal (plist-get (cocolog-swatch-face "#e6194b") :foreground)
                     "#ffffff"))
      (should (equal (plist-get (cocolog-swatch-face "#fffac8") :foreground)
                     "#000000")))))

(ert-deftest cocolog-test-swatch-outline-follows-the-background ()
  "A swatch is outlined only when it would melt into the background."
  (cl-letf (((symbol-function 'cocolog-background-luminance) (lambda () 0.05)))
    ;; a dark theme: dark colours need the outline, bright ones do not
    (should (cocolog-swatch-needs-outline-p "#4b0082"))
    (should-not (cocolog-swatch-needs-outline-p "#fffac8"))
    (should-not (cocolog-swatch-needs-outline-p "#e6194b")))
  (cl-letf (((symbol-function 'cocolog-background-luminance) (lambda () 0.98)))
    ;; a light theme: the other way round
    (should (cocolog-swatch-needs-outline-p "#fffac8"))
    (should (cocolog-swatch-needs-outline-p "#f0f0f0"))
    (should-not (cocolog-swatch-needs-outline-p "#4b0082"))))

(ert-deftest cocolog-test-swatch-outline-is-a-box-or-an-underline ()
  (cl-letf (((symbol-function 'cocolog-background-luminance) (lambda () 0.05)))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda (&rest _) t)))
      (let ((edge (plist-get (plist-get (cocolog-swatch-face "#4b0082") :box)
                             :color)))
        ;; an edge, not a highlight: a tint of the swatch, not stark white
        (should edge)
        (should-not (equal edge "#ffffff"))
        (should (< (cocolog-color-distance "#4b0082" edge)
                   (cocolog-color-distance "#4b0082" "#ffffff"))))
      (should-not (plist-get (cocolog-swatch-face "#4b0082") :underline)))
    ;; a terminal has no boxes
    (cl-letf (((symbol-function 'display-graphic-p) (lambda (&rest _) nil)))
      (should (stringp (plist-get (cocolog-swatch-face "#4b0082") :underline)))
      (should-not (plist-get (cocolog-swatch-face "#4b0082") :box)))))

(ert-deftest cocolog-test-dealt-colours-need-no-outline ()
  "A colour that would melt into the frame is not dealt to a variable.
The outline is there for a colour someone pinned deliberately; one the
mode chooses itself should simply be visible."
  (dolist (background '(0.05 0.5 0.96))
    (cl-letf (((symbol-function 'cocolog-background-luminance)
               (lambda () background)))
      (let ((taken '()))
        (dotimes (i 12)
          (let ((hex (cocolog--pick-plain-color (format "Var%d" i) taken)))
            (push hex taken)
            (should (equal (list background hex
                                 (cocolog-swatch-needs-outline-p hex))
                           (list background hex nil)))))))))

(ert-deftest cocolog-test-swatch-outline-can-be-turned-off ()
  (cl-letf (((symbol-function 'cocolog-background-luminance) (lambda () 0.05)))
    (let ((cocolog-swatch-outline nil))
      (should-not (cocolog-swatch-needs-outline-p "#4b0082"))
      (should (equal (cocolog-swatch-face "#4b0082")
                     '(:background "#4b0082" :foreground "#ffffff"))))
    (let ((cocolog-swatch-outline t))
      (should (cocolog-swatch-needs-outline-p "#4b0082"))
      ;; even a colour that stands out perfectly well
      (should (cocolog-swatch-needs-outline-p "#fffac8")))))

(ert-deftest cocolog-test-theme-change-redraws-the-swatches ()
  (should (memq #'cocolog-refresh-swatches
                (and (boundp 'enable-theme-functions) enable-theme-functions)))
  (cocolog-test--with-buffer "p(Ce6194b).\n"
    (font-lock-ensure)
    (should (get-text-property (+ (point-min) 2) 'display))
    ;; a theme change drops the swatches and asks for them to be drawn again
    (cocolog-refresh-swatches)
    (should-not (get-text-property (+ (point-min) 2) 'display))
    (font-lock-ensure)
    (should (get-text-property (+ (point-min) 2) 'display))))

;;;; ------------------------------------------------------------------
;;;; Colouring a variable as it is typed
;;;; ------------------------------------------------------------------

(defun cocolog-test--type (text)
  "Type TEXT into the current buffer, one self-inserting character at a time."
  (dolist (c (append text nil))
    (let ((last-command-event c))
      (call-interactively #'self-insert-command))))

(ert-deftest cocolog-test-a-known-name-is-adopted ()
  "Writing the name of a variable the clause already has means that variable."
  (with-temp-buffer
    (cocolog-mode)
    (insert "grandparent(Ce6194b_Grandad, C4363d8_Kid) :-\n    ")
    (cocolog-test--type "parent(Grandad, Between),")
    ;; the name the clause already knows became that very variable ...
    (should (string-match-p "parent(Ce6194b_Grandad, Between)" (buffer-string)))
    ;; ... so the clause still speaks of three variables, not four
    (should (= 3 (length (plist-get (cocolog-read-term
                                     (concat (buffer-string) " true."))
                                    :order))))
    ;; a name it does not know is left as it is: colouring the file is
    ;; `cocolog-auto-color', which is a separate matter and off by default
    (should (string-match-p "\\_<Between\\_>" (buffer-string))))
  ;; the same name in another clause is another variable, and stays plain
  (with-temp-buffer
    (cocolog-mode)
    (insert "p(Ce6194b_Item).\nq(X) :- ")
    (cocolog-test--type "r(Item, X).")
    (should (string-match-p "^q(X) :- r(Item, X)\\." (buffer-string))))
  ;; and it can be turned off
  (with-temp-buffer
    (cocolog-mode)
    (let ((cocolog-adopt-known-variables nil))
      (insert "p(Ce6194b_Grandad) :- ")
      (cocolog-test--type "q(Grandad).")
      (should (string-match-p "q(Grandad)\\." (buffer-string))))))

(ert-deftest cocolog-test-a-name-both-with-and-without-a-colour-is-reported ()
  "Pasted code can put Grandad next to Ce6194b_Grandad; say so."
  (cocolog-test--with-buffer "p(Ce6194b_Grandad, Grandad) :- q(Grandad).\n"
    (should (equal (cocolog-clause-name-conflicts) '("Grandad")))
    (cocolog-check-buffer)
    (with-current-buffer "*cocolog checks*"
      (should (string-match-p "Grandad is two variables here" (buffer-string))))
    (kill-buffer "*cocolog checks*"))
  ;; a clause with no such pair says nothing
  (cocolog-test--with-buffer "p(Ce6194b_Grandad) :- q(Ce6194b_Grandad, Kid).\n"
    (should (null (cocolog-clause-name-conflicts)))))

(ert-deftest cocolog-test-auto-color-as-you-type ()
  "Every variable typed in a clause is coloured, one colour per name."
  (let ((cocolog-auto-color t))
   (with-temp-buffer
    (cocolog-mode)
    (cocolog-test--type "grandparent(X, Y) :- parent(X, Z), parent(Z, Y).")
    (should (equal (buffer-string)
                   (concat "grandparent(Ce6194b_X, Cd62728_Y) :- "
                           "parent(Ce6194b_X, Cff6347_Z), "
                           "parent(Cff6347_Z, Cd62728_Y).")))
    ;; point is left where the typing left it
    (should (= (point) (point-max)))
    ;; and the clause means what it says: three variables, not six
    (let ((r (cocolog-read-term (buffer-string))))
      (should (= 3 (length (plist-get r :order))))))))

(ert-deftest cocolog-test-auto-color-leaves-comments-and-strings-alone ()
  (let ((cocolog-auto-color t))
   (with-temp-buffer
    (cocolog-mode)
    (cocolog-test--type "%% ?- p(Who, X).\n")
    (cocolog-test--type "q(\"X in a string\", Y).")
    (should (string-match-p "%% \\?- p(Who, X)\\." (buffer-string)))
    (should (string-match-p "\"X in a string\"" (buffer-string)))
    (should (string-match-p "C[0-9a-f]\\{6\\}_Y" (buffer-string))))))

(ert-deftest cocolog-test-auto-color-stops-at-the-clause-being-typed ()
  "An unfinished clause must not rewrite the clause below it."
  (let ((cocolog-auto-color t))
   (with-temp-buffer
    (cocolog-mode)
    (insert "old(X, Y) :- q(X).\n")
    (goto-char (point-min))
    (cocolog-test--type "new(A) :- r(A,")
    (should (string-match-p "^new(Ce6194b_A) :- r(Ce6194b_A," (buffer-string)))
    ;; the clause below still has its plain variables
    (should (string-match-p "old(X, Y) :- q(X)\\." (buffer-string))))))

(ert-deftest cocolog-test-auto-color-inside-a-finished-clause ()
  "Typing into a clause that already ends in a period colours all of it."
  (let ((cocolog-auto-color t))
   (with-temp-buffer
    (cocolog-mode)
    (insert "p(A) :- q(A).\n")
    (goto-char (point-min))
    (search-forward "q(A")
    (cocolog-test--type ", B")
    ;; the comma finished the A that was already there, and the clause is
    ;; complete, so the occurrence in the head was rewritten too
    (should (equal (buffer-string) "p(Ce6194b_A) :- q(Ce6194b_A, B).\n"))
    ;; B is only coloured once something is typed after it: a variable is
    ;; finished by the character that follows it
    (cocolog-test--type " ")
    (should (equal (buffer-string)
                   "p(Ce6194b_A) :- q(Ce6194b_A, Cd62728_B ).\n")))))

(ert-deftest cocolog-test-auto-color-can-be-turned-off ()
  (with-temp-buffer
    (cocolog-mode)
    (let ((cocolog-auto-color nil))
      (cocolog-test--type "p(X, Y)."))
    (should (equal (buffer-string) "p(X, Y).")))
  ;; an already coloured variable is never touched either
  (with-temp-buffer
    (cocolog-mode)
    (cocolog-test--type "p(Ce6194b_Kid).")
    (should (equal (buffer-string) "p(Ce6194b_Kid)."))))

;;;; ------------------------------------------------------------------
;;;; The Coco menu
;;;; ------------------------------------------------------------------

(defun cocolog-test--menu-symbols (spec)
  "Every symbol mentioned anywhere in the menu SPEC."
  (cond
   ((symbolp spec) (and spec (list spec)))
   ((vectorp spec) (cocolog-test--menu-symbols (append spec nil)))
   ((consp spec) (append (cocolog-test--menu-symbols (car spec))
                         (cocolog-test--menu-symbols (cdr spec))))
   (t nil)))

(defconst cocolog-test-menu-exempt
  '(cocolog-mode cocolog-view-mode cocolog-trace-mode cocolog-indent-line
    cocolog-lint-mode cocolog-clauses-mode
    cocolog-delete-variable-backward-untabify
    cocolog-markdown-setup cocolog-markdown-display-images
    cocolog-markdown-remove-images cocolog-markdown-images-mode)
  "Commands that belong in no Coco menu, or in the Markdown one.
`cocolog-mode', `cocolog-view-mode', `cocolog-trace-mode',
`cocolog-lint-mode' and `cocolog-clauses-mode' are the modes
themselves -- the last two are what the findings of cocolint and the
clause list are shown in -- and `cocolog-indent-line' is what TAB runs.
`cocolog-delete-variable-backward-untabify' stands in for a key only
some people bind, and the menu already offers the plain one; the rest live in the Markdown
menu, which `cocolog-test-markdown-menu-is-complete\=' checks.")

(defun cocolog-test--commands-of (file)
  "Every interactive cocolog command defined in FILE.
FILE is a base name without extension, since the tests may run against
either the source or the byte compiled file."
  (let ((res '()))
    (mapatoms
     (lambda (sym)
       (when (and (string-prefix-p "cocolog-" (symbol-name sym))
                  (commandp sym)
                  ;; `easy-menu-define' makes the menu symbol a command too
                  (not (string-suffix-p "-menu" (symbol-name sym)))
                  (equal (file-name-base (or (symbol-file sym 'defun) "")) file))
         (push sym res))))
    (sort res #'string<)))

(ert-deftest cocolog-test-swatch-style-switches-and-returns ()
  "C-c C-s shows the text of the file, and then hides it again."
  (let ((cocolog-swatch-style (default-value 'cocolog-swatch-style)))
    (should (eq cocolog-swatch-style 'name))
    (cocolog-cycle-swatch-style)
    (should (eq cocolog-swatch-style 'raw))
    (cocolog-cycle-swatch-style)
    (should (eq cocolog-swatch-style 'name))))

(ert-deftest cocolog-test-menu-is-installed ()
  (should (keymapp (lookup-key cocolog-mode-map [menu-bar coco])))
  (should (equal "Coco" (car cocolog-mode-menu-spec))))

(ert-deftest cocolog-test-menu-is-complete ()
  "Every command of the mode must be reachable from the Coco menu."
  (let* ((in-menu (cocolog-test--menu-symbols cocolog-mode-menu-spec))
         (commands (cocolog-test--commands-of "cocolog-mode"))
         (missing (cl-remove-if (lambda (c) (or (memq c in-menu)
                                                (memq c cocolog-test-menu-exempt)))
                                commands)))
    (should (> (length commands) 10))
    (should (equal missing '()))))

(ert-deftest cocolog-test-markdown-menu-is-complete ()
  (let* ((in-menu (cocolog-test--menu-symbols cocolog-markdown-menu-spec))
         (commands (cocolog-test--commands-of "cocolog-markdown"))
         (missing (cl-remove-if (lambda (c) (memq c in-menu)) commands)))
    (should (equal missing '()))
    (should (equal "Coco" (car cocolog-markdown-menu-spec)))))

(ert-deftest cocolog-test-menu-forms-are-safe ()
  "The :enable and :selected forms must not error while a menu opens."
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (dolist (spec (list cocolog-mode-menu-spec cocolog-markdown-menu-spec))
      (dolist (item (flatten-tree spec))
        (ignore item))
      (cl-labels
          ((walk (node)
             (cond
              ((vectorp node)
               (let ((plist (append (nthcdr 2 (append node nil)) nil)))
                 (dolist (key '(:enable :selected :active :visible))
                   (when (plist-member plist key)
                     (should (progn (eval (plist-get plist key) t) t))))))
              ((consp node) (mapc #'walk node)))))
        (walk spec)))))

;;;; ------------------------------------------------------------------
;;;; Colour swatches and pictures in other buffers
;;;; ------------------------------------------------------------------

(defun cocolog-test--project-dir ()
  (file-name-directory (locate-library "cocolog-mode")))

(ert-deftest cocolog-test-swatch-mode-shows-the-name-by-default ()
  "In prose too, a colour variable shows what it is called."
  (should (eq cocolog-swatch-mode-style 'name))
  (with-temp-buffer
    (insert "a rule about Ce6194b_Grandad and Cffd700\n")
    (text-mode)
    (cocolog-swatch-mode 1)
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward "Ce6194b_Grandad")
    (should (equal (get-text-property (match-beginning 0) 'display) " Grandad "))
    ;; the swatch carries its own colour and nothing of the buffer it was
    ;; made in -- no stray `fontified' or mode specific properties
    (let ((props (text-properties-at
                  1 (get-text-property (match-beginning 0) 'display))))
      (should (equal (cl-loop for (key _) on props by #'cddr collect key)
                     '(face))))
    ;; one with no name of its own is shown as its colour, not as a word
    (goto-char (point-min))
    (search-forward "Cffd700")
    (should (equal (get-text-property (match-beginning 0) 'display)
                   cocolog-swatch-text))))

(ert-deftest cocolog-test-swatch-mode-in-a-foreign-buffer ()
  (with-temp-buffer
    (insert "prose about Ce6194b and `C3cb44b` in a text buffer\n")
    (text-mode)
    (let ((cocolog-swatch-mode-style 'raw))
      (cocolog-swatch-mode 1))
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward "Ce6194b")
    (should (equal (get-text-property (match-beginning 0) 'face)
                   '(:background "#e6194b" :foreground "#ffffff")))
    ;; `raw' style paints the text and hides nothing
    (should (null (get-text-property (match-beginning 0) 'display)))
    (goto-char (point-min))
    (search-forward "C3cb44b")
    (should (equal (get-text-property (match-beginning 0) 'face)
                   '(:background "#3cb44b" :foreground "#000000")))
    ;; and turning it off puts the buffer back
    (cocolog-swatch-mode -1)
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward "Ce6194b")
    (should (null (get-text-property (match-beginning 0) 'display)))))

(ert-deftest cocolog-test-swatch-mode-hides-the-colour-part ()
  (with-temp-buffer
    (insert "Ce6194b and Ce6194b_Kid\n")
    (text-mode)
    (cocolog-swatch-mode 1)
    (font-lock-ensure)
    (should (equal (get-text-property (point-min) 'display) cocolog-swatch-text))
    (goto-char (point-min))
    (search-forward "Ce6194b_Kid")
    (should (equal (get-text-property (match-beginning 0) 'display) " Kid "))))

(ert-deftest cocolog-test-markdown-picks-the-picture-for-the-theme ()
  (let ((html (concat "<picture>\n"
                      "  <source media=\"(prefers-color-scheme: dark)\""
                      " srcset=\"doc/graph-dark.svg\">\n"
                      "  <img alt=\"a graph\" src=\"doc/graph.svg\">\n"
                      "</picture>\n")))
    (cl-letf (((symbol-function 'cocolog-markdown--dark-p) (lambda () t)))
      (should (equal (cocolog-markdown--pick-source html) "doc/graph-dark.svg")))
    (cl-letf (((symbol-function 'cocolog-markdown--dark-p) (lambda () nil)))
      (should (equal (cocolog-markdown--pick-source html) "doc/graph.svg")))
    (should (equal (cocolog-markdown--alt html) "a graph"))
    ;; a bare <img> has no dark variant to choose
    (cl-letf (((symbol-function 'cocolog-markdown--dark-p) (lambda () t)))
      (should (equal (cocolog-markdown--pick-source "<img src=\"doc/x.svg\">")
                     "doc/x.svg")))))

(ert-deftest cocolog-test-markdown-displays-pictures ()
  (skip-unless (image-type-available-p 'svg))
  (let ((dir (cocolog-test--project-dir)))
    (skip-unless (file-readable-p (expand-file-name "doc/graph.svg" dir)))
    (with-temp-buffer
      (setq default-directory dir)
      (insert "text\n\n<picture>\n"
              "  <source media=\"(prefers-color-scheme: dark)\""
              " srcset=\"doc/graph-dark.svg\">\n"
              "  <img alt=\"a graph\" src=\"doc/graph.svg\">\n"
              "</picture>\n\nmore text\n"
              "<img alt=\"nope\" src=\"doc/does-not-exist.svg\">\n")
      (text-mode)
      (should (= 1 (cocolog-markdown-display-images)))
      (let ((overlays (cl-remove-if-not
                       (lambda (o) (overlay-get o 'cocolog-markdown-image))
                       (overlays-in (point-min) (point-max)))))
        (should (= 1 (length overlays)))
        (should (eq 'image (car (overlay-get (car overlays) 'display))))
        ;; the whole <picture> element is covered, tags included
        (should (string-prefix-p "<picture>"
                                 (buffer-substring-no-properties
                                  (overlay-start (car overlays))
                                  (overlay-end (car overlays)))))
        (should (string-suffix-p "</picture>"
                                 (buffer-substring-no-properties
                                  (overlay-start (car overlays))
                                  (overlay-end (car overlays))))))
      (cocolog-markdown-remove-images)
      (should (null (cl-remove-if-not
                     (lambda (o) (overlay-get o 'cocolog-markdown-image))
                     (overlays-in (point-min) (point-max))))))))

(ert-deftest cocolog-test-a-code-block-is-coloured-as-one ()
  "Every line of a fenced block draws on the same set of variables.
The test case, the clauses and the graph under them all name the same
things, so they have to come out in the same colours."
  (skip-unless (require 'markdown-mode nil t))
  (with-temp-buffer
    (insert "Prose about Who and Grandad.\n\n"
            "```prolog\n"
            "%% ?- grandparent(tom, Who).\n"
            "grandparent(Grandad, Kid) :- parent(Grandad, Kid).\n"
            "%% ╭── cocolog trace ── ?- grandparent(tom, Who).\n"
            "%% │ grandparent(tom, Who)                    ✔ grandparent(tom, ann)\n"
            "%% │ ✔ solution 1:  Who = ann\n"
            "%% ╰── cocolog: 1 solution · 2 inferences\n"
            "```\n")
    (markdown-mode)
    (cocolog-markdown-setup)
    (font-lock-ensure)
    (let ((case-fold-search nil) (seen (make-hash-table :test 'equal)))
      (goto-char (point-min))
      (while (re-search-forward "\\_<\\([A-Z][A-Za-z0-9_]*\\)\\_>" nil t)
        (let ((name (match-string-no-properties 0))
              (bg (plist-get (get-text-property (match-beginning 0) 'face) :background))
              (in-code (cocolog--code-region-at (match-beginning 0))))
          (if in-code
              (when bg (puthash name (cons bg (gethash name seen)) seen))
            ;; the sentence above the block is prose, whatever it mentions
            (should (null bg)))))
      (should (equal (sort (hash-table-keys seen) #'string<)
                     '("Grandad" "Kid" "Who")))
      (maphash (lambda (name colors)
                 (should (equal (list name (length (delete-dups colors)))
                                (list name 1))))
               seen))))

(ert-deftest cocolog-test-swatch-mode-colours-prolog-fences-only ()
  "In a Markdown buffer only Prolog code blocks have variables in them."
  (skip-unless (require 'markdown-mode nil t))
  (with-temp-buffer
    (insert "Prose about Emacs and Prolog, mentioning Grandad.\n\n"
            "```prolog\n"
            "grandparent(Grandad, Kid) :- parent(Grandad, Kid).\n"
            "```\n\n"
            "```bash\n"
            "emacs -Q --batch -L .\n"
            "```\n")
    (markdown-mode)
    (cocolog-swatch-mode 1)
    (syntax-propertize (point-max))
    (font-lock-ensure)
    (cl-flet ((bg (pos) (plist-get (get-text-property pos 'face) :background)))
      ;; the variables of the Prolog block are coloured, one colour each
      (goto-char (point-min))
      (search-forward "grandparent(Grandad")
      (let ((grandad (bg (- (point) 7))))
        (should grandad)
        ;; and the same name in the same clause has the same colour
        (should (equal grandad
                       (progn (search-forward "parent(Grandad")
                              (bg (- (point) 7))))))
      ;; the shell block is not Prolog: its -Q is not a variable
      (goto-char (point-min))
      (search-forward "emacs -Q")
      (should-not (bg (1- (point))))
      ;; and neither is a capitalised word in a sentence
      (goto-char (point-min))
      (search-forward "Grandad.")
      (should-not (bg (- (point) 8)))
      (goto-char (point-min))
      (search-forward "Emacs")
      (should-not (bg (- (point) 5))))))

(ert-deftest cocolog-test-markdown-code-fence-is-fontified-by-cocolog ()
  (skip-unless (require 'markdown-mode nil t))
  (let ((markdown-fontify-code-blocks-natively t)
        (markdown-code-lang-modes (cons '("prolog" . cocolog-mode)
                                        (bound-and-true-p markdown-code-lang-modes))))
    (with-temp-buffer
      (insert "text\n\n```prolog\np(Ce6194b) :- q(Ce6194b).\n```\n")
      (markdown-mode)
      (font-lock-ensure)
      (goto-char (point-min))
      (search-forward "p(Ce6194b")
      ;; markdown adds `markdown-code-face' under ours, so the property is a
      ;; list of faces with the colour first, which is what wins
      (let ((face (ensure-list (get-text-property (+ 2 (match-beginning 0)) 'face))))
        (should (equal (car face) '(:background "#e6194b" :foreground "#ffffff")))))))

(ert-deftest cocolog-test-dcg-snippet-inserts-and-marks-the-placeholder ()
  (with-temp-buffer
    (cocolog-mode)
    (insert "line(X) --> ")
    (cocolog--insert-snippet "string_without(\"<Stop>\", <Cs>)")
    (should (equal (buffer-string) "line(X) --> string_without(\"Stop\", Cs)"))
    ;; the region is left over the first placeholder, so typing replaces it
    (should mark-active)
    (should (equal (buffer-substring (point) (mark)) "Stop"))))

(ert-deftest cocolog-test-dcg-snippet-without-a-placeholder-leaves-no-region ()
  (with-temp-buffer
    (cocolog-mode)
    (cocolog--insert-snippet "blanks")
    (should (equal (buffer-string) "blanks"))
    (should-not mark-active)))

(defun cocolog-test--split-goals (text)
  "Split TEXT into its top level goals, the way a body is read.
A piece the picker offers can be a whole little body -- a goal, a comma,
a brace -- and every predicate named in it has to be one the engine
has, not only the first."
  (let ((depth 0) (quote nil) (start 0) (out '()) (i 0) (n (length text)))
    (while (< i n)
      (let ((c (aref text i)))
        (cond
         (quote (when (eq c quote) (setq quote nil)))
         ((memq c '(?\" ?')) (setq quote c))
         ((memq c '(?\( ?\[ ?{)) (cl-incf depth))
         ((memq c '(?\) ?\] ?})) (cl-decf depth))
         ((and (zerop depth) (memq c '(?, ?\;)))
          (push (substring text start i) out)
          (setq start (1+ i)))))
      (cl-incf i))
    (push (substring text start) out)
    (mapcar #'string-trim (nreverse out))))

(defun cocolog-test--goal-indicator (goal)
  "Return (NAME . ARITY) for GOAL, or nil when it names no predicate."
  (let* ((case-fold-search nil)          ; `X' is a variable, not a predicate
         (goal (string-trim goal))
         ;; a goal may be wrapped: ( ... ), { ... }, or led by \\+ or !
         (goal (if (string-match "\\`[({][ \t]*\\(.*[^ \t]\\)[ \t]*[)}]\\'" goal)
                   (match-string 1 goal)
                 goal))
         (goal (string-trim (replace-regexp-in-string "\\`\\(\\\\\\+\\|!\\)[ \t]*" "" goal))))
    (cond
     ((string-empty-p goal) nil)
     ;; a nested body: check what is inside it instead
     ((and (string-match "\\`[({]" goal)) nil)
     ((not (string-match "\\`\\([a-z][a-zA-Z0-9_]*\\)" goal)) nil)
     (t (let ((name (match-string 1 goal))
              (rest (substring goal (match-end 1))))
          (cons name
                (if (string-prefix-p "(" rest)
                    (length (cocolog-test--split-goals
                             (substring rest 1 (or (cl-position ?\) rest :from-end t)
                                                   (length rest)))))
                  0)))))))

(defun cocolog-test--known-to-the-engine-p (text extra)
  "Non-nil when every predicate the piece TEXT names is one the engine has.
EXTRA is how many arguments the translation adds -- two for a grammar
rule, none for an ordinary goal."
  (let* ((plain (replace-regexp-in-string cocolog--placeholder-regexp "\\1" text))
         (db (cocolog-db-preds (cocolog-library-db)))
         ;; a piece that is a whole rule defines predicates of its own, and
         ;; those are not the engine's business
         (own (and (string-match-p "-->\\|:-" plain)
                   (cocolog-db-preds (cocolog-consult-string plain)))))
    (cl-every
     (lambda (goal)
       (let* ((indicator (cocolog-test--goal-indicator goal))
              (name (car indicator))
              (args (cdr indicator)))
         (or (null indicator)
             ;; the solver knows these itself; they are in no table
             (member name '("call" "true" "fail" "not"))
             ;; a goal inside a grammar rule is translated; one written in
             ;; braces, or in a query, is not
             (cl-some (lambda (arity)
                        (or (gethash (format "%s/%d" name arity) db)
                            (and own (gethash (format "%s/%d" name arity) own))
                            (assoc (format "%s/%d" name arity) cocolog--builtins)))
                      (list (+ args extra) args)))))
     (cocolog-test--split-goals plain))))

(ert-deftest cocolog-test-every-snippet-is-known-to-the-engine ()
  "Neither picker may offer something the engine has never heard of.
A list that drifts from the engine is worse than no list, since what it
offers looks like a promise that the piece will run."
  (dolist (row (cocolog--pick-rows cocolog-dcg-snippets))
    (should (cocolog-test--known-to-the-engine-p (nth 0 row) 2)))
  (dolist (row (cocolog--pick-rows cocolog-builtin-snippets))
    (should (cocolog-test--known-to-the-engine-p
             (nth 0 row)
             ;; the grammar group of the builtin list is called, not translated
             0))))

(ert-deftest cocolog-test-builtin-picker-covers-what-the-engine-has ()
  "Every builtin of the engine is on the list, or deliberately left off."
  (let ((offered (mapcar (lambda (row)
                           (let ((plain (cocolog--pick-plain (nth 0 row))))
                             (if (string-match "\\`\\([a-z][a-zA-Z0-9_]*\\)" plain)
                                 (match-string 1 plain)
                               plain)))
                         (cocolog--pick-rows cocolog-builtin-snippets)))
        ;; these are the operators, which the list writes as terms, and the
        ;; two the picker has no business inserting
        (written-as-operators '("=" "\\=" "==" "\\==" "@<" "@>" "@=<" "@>=" "is"
                                "=:=" "=\\=" "<" ">" "=<" ">=" "=.."))
        (left-off '("halt")))
    (dolist (bi cocolog--builtins)
      (let ((name (car (split-string (car bi) "/"))))
        (should (or (member name offered)
                    (member name written-as-operators)
                    (member name left-off)))))))

(ert-deftest cocolog-test-dcg-picker-shows-its-groups ()
  "The picker lists every piece under the heading of its group."
  (let ((rows (cocolog--pick-rows cocolog-dcg-snippets))
        (cocolog--pick-index 0)
        (buffer (get-buffer-create " *cocolog grammar test*")))
    (unwind-protect
        (progn
          (cocolog--pick-render buffer rows "Insert a piece of a grammar rule")
          (with-current-buffer buffer
            (let ((text (buffer-substring-no-properties (point-min) (point-max))))
              ;; every group is there as a heading
              (dolist (group cocolog-dcg-snippets)
                (should (string-search (car group) text)))
              ;; and every piece is there: a whole rule by its first line,
              ;; since the grid gives each piece one line
              (dolist (row rows)
                (should (string-search (cocolog--pick-oneline (nth 0 row)) text)))
              ;; the piece the cursor is on is the marked one, and only it
              (let ((marker (cocolog-glyph "▸" ">")))
                (should (= 1 (cl-count-if
                              (lambda (line) (string-search (concat "  " marker " ") line))
                              (split-string text "\n"))))
                (should (string-search (concat marker " [Item]") text))))))
      (kill-buffer buffer))))

(ert-deftest cocolog-test-torch-snippets-are-well-formed ()
  "Every torch piece carries its four strings and reads as Prolog.
The examples are tutorial lines proven by cocolog-full's own suite, not
run by the engine -- it traces no tensors -- so what is held here is
the shape: the piece must consult, under a head when it is not a rule
of its own, and its placeholders must be placeholders."
  (dolist (row (cocolog--pick-rows cocolog-torch-snippets))
    (should (= 5 (length row)))
    (dolist (s row)
      (should (stringp s))
      (should-not (string-empty-p s)))
    (let ((plain (cocolog--pick-plain (nth 0 row))))
      (should (cocolog-consult-string
               (if (string-match-p "-->\\|:-" plain)
                   plain
                 (concat "torch_piece :- " plain ".")))))))

(ert-deftest cocolog-test-the-two-pickers-are-on-their-keys ()
  "C-c C-i opens the goal picker and C-c C-g the torch rules."
  (should (eq (lookup-key cocolog-mode-map (kbd "C-c C-i"))
              #'cocolog-insert-goal))
  (should (eq (lookup-key cocolog-mode-map (kbd "C-c C-g"))
              #'cocolog-insert-torch-rule)))

(ert-deftest cocolog-test-torch-picker-shows-its-three-columns ()
  "The torch picker draws its three groups, every piece under its own."
  (let* ((rows (cocolog--pick-rows cocolog-torch-snippets))
         (cocolog--pick-index 0)
         (buffer (get-buffer-create " *cocolog torch test*")))
    (unwind-protect
        (progn
          (cocolog--pick-render buffer rows "Insert a torch rule"
                                cocolog-torch-pick-columns)
          (with-current-buffer buffer
            (let ((text (buffer-substring-no-properties (point-min) (point-max))))
              (dolist (group cocolog-torch-snippets)
                (should (string-search (car group) text)))
              (dolist (row rows)
                (should (string-search (cocolog--pick-oneline (nth 0 row))
                                       text))))))
      (kill-buffer buffer))))

(ert-deftest cocolog-test-dcg-picker-tab-moves-between-groups ()
  (let* ((rows (cocolog--pick-rows cocolog-dcg-snippets))
         (groups (delete-dups (mapcar (lambda (r) (nth 2 r)) rows))))
    ;; from the first piece of the first group, forward lands on the first
    ;; piece of the second, and back wraps round to the last group
    (let ((cocolog--pick-index 0))
      (should (equal (nth 2 (nth (cocolog--pick-group-step rows 1) rows))
                     (nth 1 groups)))
      (should (equal (nth 2 (nth (cocolog--pick-group-step rows -1) rows))
                     (car (last groups)))))
    ;; and it lands on the *first* piece of that group, not on the heading
    (let ((cocolog--pick-index 0))
      (let ((i (cocolog--pick-group-step rows 1)))
        (should (or (zerop i) (not (equal (nth 2 (nth (1- i) rows))
                                          (nth 2 (nth i rows))))))))))

(defun cocolog-test--dcg-drive (keys &optional table)
  "Follow KEYS through the picker for TABLE; return what it would insert."
  (let ((rows (cocolog--pick-rows (or table cocolog-dcg-snippets)))
        (cocolog--pick-index 0)
        (result nil))
    (catch 'done
      (dolist (key keys)
        (pcase (cocolog--pick-action key rows)
          (`(move . ,i) (setq cocolog--pick-index i))
          (`(pick . ,text) (setq result text) (throw 'done nil))
          ('cancel (throw 'done nil))
          (_ nil))))
    result))

(ert-deftest cocolog-test-dcg-picker-keys-walk-the-groups ()
  (should (equal (cocolog-test--dcg-drive '(?\r)) "[<Item>]"))
  ;; down the first group
  (should (equal (cocolog-test--dcg-drive '(down down ?\r)) "[]"))
  ;; TAB to the next group takes its first piece
  (should (equal (cocolog-test--dcg-drive '(?\t ?\r)) "{ <Goal> }"))
  ;; and S-TAB back again
  (should (equal (cocolog-test--dcg-drive '(?\t ?\t backtab ?\r)) "{ <Goal> }"))
  ;; up from the first piece wraps round inside its own column
  (should (equal (cocolog-test--dcg-drive '(up ?\r)) "string_without(\"<Stop>\", <Cs>)"))
  ;; and the other column is one step to the right
  (should (equal (cocolog-test--dcg-drive '(right ?\r)) "digit(<C>)"))
  ;; q takes nothing
  (should-not (cocolog-test--dcg-drive '(down ?q)))
  ;; and a key the picker does not use changes nothing
  (should (equal (cocolog-test--dcg-drive '(?z ?\r)) "[<Item>]")))

(ert-deftest cocolog-test-builtin-picker-walks-its-own-groups ()
  "The same picker, driven over the builtins."
  (let ((table cocolog-builtin-snippets))
    (should (equal (cocolog-test--dcg-drive '(?\r) table) "( <A> ; <B> )"))
    ;; TAB leaves control for the group after it
    (should (equal (nth 2 (nth (let ((cocolog--pick-index 0))
                                 (cocolog--pick-group-step
                                  (cocolog--pick-rows table) 1))
                               (cocolog--pick-rows table)))
                   "the same, or in order"))
    ;; four groups along is where the lists are
    (should (equal (cocolog-test--dcg-drive '(?\t ?\t ?\t ?\t ?\t ?\r) table)
                   "append(<A>, <B>, <AB>)"))
    (should-not (cocolog-test--dcg-drive '(?\t ?q) table))))

(ert-deftest cocolog-test-dcg-picker-mouse-takes-the-second-click ()
  (let* ((rows (cocolog--pick-rows cocolog-dcg-snippets))
         (cocolog--pick-index 0)
         (buffer (get-buffer-create " *cocolog grammar mouse*")))
    (unwind-protect
        (progn
          (cocolog--pick-render buffer rows "Insert a piece of a grammar rule")
          (let* ((p (with-current-buffer buffer
                      (text-property-any (point-min) (point-max) 'cocolog-pick-index 5)))
                 (window (display-buffer buffer))
                 (event (list 'mouse-1 (list window p '(0 . 0) 0))))
            (should (equal (cocolog--pick-mouse-action event rows buffer) '(move . 5)))
            (let ((cocolog--pick-index 5))
              (should (equal (cocolog--pick-mouse-action event rows buffer)
                             (cons 'pick (nth 0 (nth 5 rows))))))))
      (kill-buffer buffer))))

(ert-deftest cocolog-test-picker-opens-on-the-half-that-fits ()
  "In a grammar rule the picker opens on the grammar, elsewhere on the goals."
  (with-temp-buffer
    (cocolog-mode)
    (insert "greeting --> [hello], ")
    (should (cocolog--in-grammar-rule-p))
    (erase-buffer)
    (insert "p(X) :- ")
    (should-not (cocolog--in-grammar-rule-p)))
  (let* ((rows (cocolog--pick-rows (cocolog-goal-snippets)))
         (start (cocolog--pick-first-of-group rows "\\`grammar: ")))
    (should (string-prefix-p "grammar: " (nth 2 (nth start rows))))
    ;; and it is the *first* of the grammar groups
    (should-not (string-prefix-p "grammar: " (nth 2 (nth (1- start) rows))))))

(ert-deftest cocolog-test-the-two-lists-are-one ()
  "Everything from both tables is in the picker, and nothing twice."
  (let* ((rows (cocolog--pick-rows (cocolog-goal-snippets)))
         (texts (mapcar (lambda (r) (nth 0 r)) rows)))
    (should (equal texts (delete-dups (copy-sequence texts))))
    (dolist (table (list cocolog-builtin-snippets cocolog-dcg-snippets))
      (dolist (row (cocolog--pick-rows table))
        (should (member (nth 0 row) texts))))
    ;; a piece both tables have is kept once, under the goal heading
    (should (equal 1 (cl-count "phrase(<Rule>, <List>)" texts :test #'equal)))))

(ert-deftest cocolog-test-picker-columns-are-even-and-whole ()
  "The columns come out about the same length, and no group is split."
  (let* ((rows (cocolog--pick-rows (cocolog-goal-snippets)))
         (layout (cocolog--pick-layout rows 2))
         (lengths (mapcar #'length layout)))
    (should (= 2 (length layout)))
    ;; every piece is drawn exactly once
    (should (equal (sort (mapcan (lambda (column)
                                   (delq nil (mapcar (lambda (c)
                                                       (and (eq (car-safe c) 'row)
                                                            (cdr c)))
                                                     column)))
                                 (copy-tree layout))
                         #'<)
                   (number-sequence 0 (1- (length rows)))))
    ;; a group is never spread over two columns
    (let ((seen '()))
      (dolist (column layout)
        (let ((groups (delete-dups
                       (delq nil (mapcar (lambda (c)
                                           (and (eq (car-safe c) 'row)
                                                (nth 2 (nth (cdr c) rows))))
                                         column)))))
          (dolist (g groups)
            (should-not (member g seen))
            (push g seen)))))
    ;; one column is not twice the other
    (should (< (- (apply #'max lengths) (apply #'min lengths))
               (apply #'max lengths)))))

(ert-deftest cocolog-test-picker-moves-by-column ()
  "Down walks a column, right crosses to the next one."
  (let* ((rows (cocolog--pick-rows (cocolog-goal-snippets)))
         (layout (cocolog--pick-layout rows 2))
         (cocolog--pick-shown layout)
         (cocolog--pick-index 0))
    ;; down the first column
    (should (equal (cocolog--pick-vertical rows 1) 1))
    ;; right lands in the second column, on a piece
    (let ((across (cocolog--pick-horizontal rows 1)))
      (should (equal (car (cocolog--pick-where layout across)) 1))
      ;; and back again
      (let ((cocolog--pick-index across))
        (should (equal (car (cocolog--pick-where
                             layout (cocolog--pick-horizontal rows -1)))
                       0))))
    ;; up from the top of a column wraps inside that column, never off it
    (let ((up (cocolog--pick-vertical rows -1)))
      (should (equal (car (cocolog--pick-where layout up)) 0)))))

(defun cocolog-test--example-answer (query &optional program)
  "Run QUERY through the engine and say what came back, in one line.
PROGRAM is what to run it against, if the example needs one.  The same
reading of a result the examples in the pickers are written against, so
that a stale example is a failing test."
  (let* ((db (cocolog-consult-string (or program "")))
         (result (cocolog-run-query db query 4)))
    (cond
     ((eq (cocolog-result-status result) 'error)
      (format "stops: %s" (replace-regexp-in-string "\\`uncaught exception: " ""
                                                    (cocolog-result-message result))))
     ((and (cocolog-result-output result)
           (not (string-empty-p (cocolog-result-output result))))
      (format "writes %s" (string-trim (replace-regexp-in-string
                                        "\n" "⏎" (cocolog-result-output result)))))
     ((null (cocolog-result-solutions result)) "no")
     (t (let* ((solutions (mapcar (lambda (solution)
                                    ;; a variable left unbound says nothing
                                    (cl-remove-if (lambda (b) (equal (car b) (cdr b)))
                                                  solution))
                                  (cocolog-result-solutions result)))
               (more (> (length solutions) 3))
               (shown (seq-take solutions 3)))
          (if (null (car shown))
              "yes"
            (concat (mapconcat (lambda (solution)
                                 (mapconcat (lambda (b)
                                              (format "%s = %s" (car b) (cdr b)))
                                            solution ", "))
                               shown " ; ")
                    (if more " ; ..." ""))))))))

(defun cocolog-test--snippet-program (text)
  "The program a piece brings with it: itself, when it is a whole rule."
  (let ((plain (replace-regexp-in-string cocolog--placeholder-regexp "\\1" text)))
    (if (string-match-p "-->\\|:-" plain) plain "")))

(ert-deftest cocolog-test-every-example-runs-and-says-what-it-says ()
  "Every piece the picker offers carries an example, and the example holds.
An example is a promise about what the engine does; running them all is
the only way to keep the promise true -- and a piece that is a whole
rule is run as the program of its own example, so the rule the picker
writes for you is one that works."
  (dolist (table (list cocolog-builtin-snippets cocolog-dcg-snippets))
    (dolist (row (cocolog--pick-rows table))
      (let ((query (nth 3 row))
            (answer (nth 4 row)))
        (should (stringp query))
        (should (stringp answer))
        (should-not (string-empty-p query))
        (should (equal (cons (nth 0 row)
                             (cocolog-test--example-answer
                              query (cocolog-test--snippet-program (nth 0 row))))
                       (cons (nth 0 row) answer)))))))

(ert-deftest cocolog-test-the-example-is-shown-where-it-cannot-scroll-away ()
  "The piece and its example are in lines of the window, not of the buffer."
  (let* ((rows (cocolog--pick-rows (cocolog-goal-snippets)))
         (cocolog--pick-index (1- (length rows)))   ; the very last piece
         (buffer (get-buffer-create " *cocolog pinned*")))
    (unwind-protect
        (progn
          (cocolog--pick-render buffer rows "Insert a goal" 2)
          (with-current-buffer buffer
            (let ((text (buffer-substring-no-properties (point-min) (point-max)))
                  (row (nth cocolog--pick-index rows)))
              ;; neither line is in the buffer, where it would scroll away
              (should-not (string-search (nth 1 row) text))
              (should-not (string-search (concat "?- " (nth 3 row)) text))
              ;; both are in lines of the window instead
              (should (string-search (nth 1 row)
                                     (substring-no-properties tab-line-format)))
              (should (string-search (nth 4 row)
                                     (substring-no-properties header-line-format)))
              (should (string-search "RET insert"
                                     (substring-no-properties mode-line-format))))))
      (kill-buffer buffer))))

(defun cocolog-test--menu-items (spec)
  "Every item of the menu SPEC, as a list of vectors."
  (cond
   ((vectorp spec) (list spec))
   ((consp spec) (apply #'append (mapcar #'cocolog-test--menu-items spec)))
   (t nil)))

(defun cocolog-test--menu-keyword (item keyword)
  "The value of KEYWORD in the menu ITEM, or nil."
  (plist-get (nthcdr 2 (append item nil)) keyword))

(defun cocolog-test--menu-run (binding)
  "Run what a menu item is bound to: a command, or a form."
  (if (and (symbolp binding) (commandp binding))
      (call-interactively binding)
    (eval binding t)))

(ert-deftest cocolog-test-every-menu-item-is-a-command ()
  "What a menu item is bound to must be something that can be run."
  (dolist (item (append (cocolog-test--menu-items cocolog-mode-menu-spec)
                        (cocolog-test--menu-items cocolog-markdown-menu-spec)))
    (let ((label (elt item 0))
          (binding (elt item 1)))
      (should (stringp label))
      (should (or (and (symbolp binding) (commandp binding))
                  ;; a form is allowed, and must at least be a call
                  (and (consp binding) (fboundp (car binding))))))))

(ert-deftest cocolog-test-every-menu-item-says-what-it-does ()
  "Every item of either menu carries a :help, so the menu explains itself."
  (dolist (item (append (cocolog-test--menu-items cocolog-mode-menu-spec)
                        (cocolog-test--menu-items cocolog-markdown-menu-spec)))
    (should (equal (cons (elt item 0) t)
                   (cons (elt item 0)
                         (stringp (cocolog-test--menu-keyword item :help)))))))

(ert-deftest cocolog-test-menu-guards-can-be-evaluated ()
  "The :enable and :selected forms must work wherever the menu opens."
  (with-temp-buffer
    (cocolog-mode)
    (insert "p(Ce6194b_Kid) :- q(Ce6194b_Kid).\n")
    (dolist (where (list (point-min) (point-max) (+ 3 (point-min))))
      (goto-char where)
      (dolist (item (cocolog-test--menu-items cocolog-mode-menu-spec))
        (dolist (keyword '(:enable :active :visible :selected))
          (let ((form (cocolog-test--menu-keyword item keyword)))
            (when form
              ;; the value does not matter; being able to ask does
              (should (progn (eval form t) t)))))))))

(defconst cocolog-test--menu-variables
  '(cocolog-color-plain-variables cocolog-auto-color cocolog-swatch-style
    cocolog-refresh-idle cocolog-run-tests-on-save cocolog-lint-on-save
    cocolog-graph-unicode
    cocolog-graph-show-clauses cocolog-graph-collapse-failures
    cocolog-graph-clause-detail)
  "What the menu's toggles and radios change, so a test can put them back.")

(defun cocolog-test--menu-state ()
  (mapcar (lambda (v) (cons v (symbol-value v))) cocolog-test--menu-variables))

(defun cocolog-test--menu-restore (state)
  (dolist (cell state) (set (car cell) (cdr cell))))

(ert-deftest cocolog-test-every-toggle-toggles ()
  "Running a toggle must change what its own tick box shows.
A menu that says one thing and does another is worse than no menu, so
each toggle is run and its `:selected\=' form asked again."
  (let ((state (cocolog-test--menu-state)))
    (unwind-protect
        (with-temp-buffer
          (cocolog-mode)
          (dolist (item (cocolog-test--menu-items cocolog-mode-menu-spec))
            (when (eq (cocolog-test--menu-keyword item :style) 'toggle)
              (let* ((label (elt item 0))
                     (selected (cocolog-test--menu-keyword item :selected))
                     (before (and (eval selected t) t)))
                (cocolog-test--menu-run (elt item 1))
                (should (equal (cons label (not before))
                               (cons label (and (eval selected t) t))))
                ;; and back again, so a toggle really is its own opposite
                (cocolog-test--menu-run (elt item 1))
                (should (equal (cons label before)
                               (cons label (and (eval selected t) t))))))))
      (cocolog-test--menu-restore state))))

(ert-deftest cocolog-test-every-radio-picks-itself ()
  "Choosing a radio item must leave that item, and only it, marked."
  (let ((state (cocolog-test--menu-state)))
    (unwind-protect
        (with-temp-buffer
          (cocolog-mode)
          (let ((radios (cl-remove-if-not
                         (lambda (item)
                           (eq (cocolog-test--menu-keyword item :style) 'radio))
                         (cocolog-test--menu-items cocolog-mode-menu-spec))))
            (should (> (length radios) 1))
            (dolist (item radios)
              (cocolog-test--menu-run (elt item 1))
              (dolist (other radios)
                (should (equal
                         (cons (elt other 0) (eq other item))
                         (cons (elt other 0)
                               (and (eval (cocolog-test--menu-keyword other :selected) t)
                                    t))))))))
      (cocolog-test--menu-restore state))))

(ert-deftest cocolog-test-turning-the-idle-redraw-off-drops-a-waiting-one ()
  "Switching the redraw off stops the one already waiting to happen."
  (let ((cocolog-refresh-idle 2.0)
        (cocolog--refresh-idle-last 2.0))
    (with-temp-buffer
      (cocolog-mode)
      (cocolog--schedule-graph-refresh)
      (should (timerp cocolog--refresh-timer))
      (cocolog-toggle-refresh-idle)
      (should-not cocolog-refresh-idle)
      (should-not cocolog--refresh-timer)
      ;; and turning it back on keeps the wait that was set, not the default
      (setq cocolog--refresh-idle-last 5.0)
      (cocolog-toggle-refresh-idle)
      (should (equal cocolog-refresh-idle 5.0)))))

(ert-deftest cocolog-test-the-menu-removes-every-graph ()
  "The item that says it removes every graph removes every graph."
  (cocolog-test--with-buffer cocolog-test-buffer-text
    (cocolog-run-all-tests)
    (should (cocolog--buffer-has-graphs-p))
    (let ((item (cl-find "Remove every graph in the buffer"
                         (cocolog-test--menu-items cocolog-mode-menu-spec)
                         :key (lambda (i) (elt i 0)) :test #'equal)))
      (should item)
      (cocolog-test--menu-run (elt item 1)))
    (should-not (cocolog--buffer-has-graphs-p))))

(ert-deftest cocolog-test-a-toggle-asks-for-the-menu-to-be-drawn-again ()
  "Changing what a tick box shows must ask for the menu bar to be redrawn.
The bar is drawn from a copy Emacs only rebuilds when told to, so
without this the setting changes and its own tick keeps the old answer
-- which on a Mac it can do for the rest of the session."
  (let ((state (cocolog-test--menu-state)))
    (unwind-protect
        (with-temp-buffer
          (cocolog-mode)
          (dolist (item (append (cocolog-test--menu-items cocolog-mode-menu-spec)
                                (cocolog-test--menu-items cocolog-markdown-menu-spec)))
            (when (memq (cocolog-test--menu-keyword item :style) '(toggle radio))
              (let ((asked nil))
                (cl-letf* ((original (symbol-function 'force-mode-line-update))
                           ((symbol-function 'force-mode-line-update)
                            (lambda (&optional all)
                              ;; only a non-nil argument reaches the menu bar
                              (when all (setq asked t))
                              (funcall original all))))
                  (cocolog-test--menu-run (elt item 1)))
                (should (equal (cons (elt item 0) t)
                               (cons (elt item 0) asked)))))))
      (cocolog-test--menu-restore state))))

(defun cocolog-test--select-all ()
  "Mark the whole buffer, the way dragging over it does."
  (transient-mark-mode 1)
  (goto-char (point-min))
  (push-mark (point) t t)
  (goto-char (point-max)))

(ert-deftest cocolog-test-backspace-deletes-a-marked-region ()
  "A marked region is what backspace deletes, as everywhere else in Emacs."
  (with-temp-buffer
    (insert "exclude(\n    Goal, List, Left, call(Goal, Arg))\n")
    (cocolog-mode)
    (should (eq (key-binding (kbd "DEL")) 'cocolog-delete-variable-backward))
    (cocolog-test--select-all)
    (call-interactively #'cocolog-delete-variable-backward)
    (should (equal (buffer-string) "")))
  ;; and forward delete likewise
  (with-temp-buffer
    (insert "p(Ce6194b_Kid) :- q(Ce6194b_Kid).\n")
    (cocolog-mode)
    (cocolog-test--select-all)
    (call-interactively #'cocolog-delete-variable-forward)
    (should (equal (buffer-string) ""))))

(ert-deftest cocolog-test-backspace-still-deletes-a-colour-variable-whole ()
  "With no region, backspace keeps taking a colour variable in one go."
  (cocolog-test--with-buffer "p(Ce6194b_Kid).\n"
    (goto-char (point-min))
    (search-forward "Ce6194b_Kid")
    (call-interactively #'cocolog-delete-variable-backward)
    (should (equal (buffer-string) "p().\n")))
  (cocolog-test--with-buffer "p(Ce6194b_Kid).\n"
    (goto-char (point-min))
    (search-forward "p(")
    (call-interactively #'cocolog-delete-variable-forward)
    (should (equal (buffer-string) "p().\n")))
  ;; an ordinary character still goes one at a time
  (cocolog-test--with-buffer "abc\n"
    (goto-char (point-min))
    (forward-char 2)
    (call-interactively #'cocolog-delete-variable-backward)
    (should (equal (buffer-string) "ac\n"))))

(ert-deftest cocolog-test-delete-selection-mode-knows-these-commands ()
  "`delete-selection-mode\=' must treat them as the deletions they are."
  (should (eq (get 'cocolog-delete-variable-backward 'delete-selection) 'supersede))
  (should (eq (get 'cocolog-delete-variable-forward 'delete-selection) 'supersede))
  ;; and the region goes even when the region is left where it was
  (with-temp-buffer
    (insert "one two\n")
    (cocolog-mode)
    (let ((delete-active-region 'kill)
          (kill-ring nil))
      (cocolog-test--select-all)
      (call-interactively #'cocolog-delete-variable-backward)
      (should (equal (buffer-string) ""))
      ;; killed, not thrown away, because that is what the setting says
      (should (equal (current-kill 0) "one two\n")))))

(defconst cocolog-test-remaps
  '((delete-backward-char . cocolog-delete-variable-backward)
    (backward-delete-char-untabify . cocolog-delete-variable-backward-untabify)
    (delete-char . cocolog-delete-variable-forward)
    (delete-forward-char . cocolog-delete-variable-forward))
  "Which standard command each of the mode's own stands in for.")

(ert-deftest cocolog-test-the-remaps-are-the-ones-expected ()
  "Nothing is remapped that is not accounted for by a test below.
A remap takes a key away from the command everyone knows, so each one
has to be worth it, and has to keep doing what that command did."
  (with-temp-buffer
    (cocolog-mode)
    (let ((found '()))
      (map-keymap (lambda (event definition)
                    (when (eq event 'remap)
                      (map-keymap (lambda (command replacement)
                                    (push (cons command replacement) found))
                                  definition)))
                  cocolog-mode-map)
      (should (equal (sort (copy-sequence found)
                           (lambda (a b) (string< (car a) (car b))))
                     (sort (copy-sequence cocolog-test-remaps)
                           (lambda (a b) (string< (car a) (car b)))))))))

(ert-deftest cocolog-test-every-remap-keeps-the-count-and-the-kill ()
  "A count means characters, and a kill puts them on the kill ring.
The special case of this mode is one press on one variable; everything
else the key could be asked to do must still happen."
  (dolist (pair cocolog-test-remaps)
    (let ((command (cdr pair))
          (backward (not (memq (car pair) '(delete-char delete-forward-char)))))
      ;; a count deletes characters, colour variable or no colour variable
      (cocolog-test--with-buffer "p(Ce6194b_Kid).\n"
        (goto-char (point-min))
        (if backward (search-forward "Ce6194b_Kid") (search-forward "p("))
        (funcall command 3)
        (should (equal (cons command (buffer-string))
                       (cons command (if backward "p(Ce6194b_).\n" "p(194b_Kid).\n")))))
      ;; and a kill flag puts what went on the kill ring
      (cocolog-test--with-buffer "abcdef\n"
        (let ((kill-ring nil))
          (goto-char (point-min))
          (forward-char 3)
          (funcall command 2 t)
          (should (equal (cons command (current-kill 0))
                         (cons command (if backward "bc" "de")))))))))

(ert-deftest cocolog-test-the-untabify-remap-still-untabifies ()
  "The key that expands a tab before deleting must keep doing that."
  (let ((backward-delete-char-untabify-method 'untabify))
    (with-temp-buffer
      (insert "p\t.")
      (cocolog-mode)
      (goto-char (point-min))
      (search-forward "\t")
      (cocolog-delete-variable-backward-untabify 1)
      ;; the tab became spaces and one of them went
      (should (equal (buffer-string)
                     (concat "p" (make-string 6 ?\s) ".")))))
  ;; and the plain backspace of the mode does not untabify, as it should not
  (with-temp-buffer
    (insert "p\t.")
    (cocolog-mode)
    (goto-char (point-min))
    (search-forward "\t")
    (cocolog-delete-variable-backward 1)
    (should (equal (buffer-string) "p."))))

(ert-deftest cocolog-test-c-c-c-c-toggles-the-colours ()
  "C-c C-c is the switch for colouring ordinary variables."
  (with-temp-buffer
    (cocolog-mode)
    (should (eq (key-binding (kbd "C-c C-c")) 'cocolog-toggle-plain-colors))
    (let ((before cocolog-color-plain-variables))
      (unwind-protect
          (progn
            (call-interactively (key-binding (kbd "C-c C-c")))
            (should (eq cocolog-color-plain-variables (not before))))
        (setq cocolog-color-plain-variables before)))))

(ert-deftest cocolog-test-swatch-mode-colours-the-examples-it-shows ()
  "A buffer of documentation shows its examples the way the pictures are drawn."
  (let ((cocolog-color-plain-variables nil))
    (with-temp-buffer
      (insert "Some prose about Grandad.\n")
      (cocolog-swatch-mode 1)
      (should (local-variable-p 'cocolog-color-plain-variables))
      (should cocolog-color-plain-variables)
      ;; and the editing default is left where it was
      (should-not (default-value 'cocolog-color-plain-variables)))))

(ert-deftest cocolog-test-ordinary-recursion-is-not-cut-short ()
  "A program that recurses as programs do must get its answer.
A limit that a real program reaches turns a yes into a no, which reads
as a bug in the program rather than a limit of the mode."
  (let ((db (cocolog-consult-string
             "count(0) :- !.\ncount(N) :- N > 0, M is N - 1, count(M).\n")))
    (dolist (n '(50 200 500))
      (let ((result (cocolog-run-query db (format "count(%d)" n))))
        (should (equal (cons n (and (cocolog-result-solutions result) t))
                       (cons n t)))
        (should-not (cocolog-result-depth-cut result))))))

(ert-deftest cocolog-test-a-branch-cut-for-depth-says-so ()
  "Giving up on a branch must not read as an answer."
  (let* ((cocolog-max-depth 40)
         (db (cocolog-consult-string
              "count(0) :- !.\ncount(N) :- N > 0, M is N - 1, count(M).\n"))
         (result (cocolog-run-query db "count(200)")))
    (should-not (cocolog-result-solutions result))
    (should (cocolog-result-depth-cut result))
    (let ((summary (cocolog-graph-summary result)))
      (should (string-search "no solutions" summary))
      (should (string-search "cocolog-max-depth" summary)))))

(ert-deftest cocolog-test-no-graph-line-is-wider-than-it-may-be ()
  "The width in the setting is the width in the file, bar and all."
  (let* ((db (cocolog-consult-string
              "long_name_for_a_predicate(Something, OrOther) :-
                 helper(Something, Middle), helper(Middle, OrOther).
               helper(a, bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb).
               helper(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb, c).\n")))
    (dolist (width '(60 96 120))
      (let* ((cocolog-graph-max-width width)
             (result (cocolog-run-query db "long_name_for_a_predicate(a, X)")))
        (dolist (line (cocolog-graph-block result))
          (should (equal (cons width t)
                         (cons width (<= (length line) width)))))))))

(ert-deftest cocolog-test-a-runaway-is-still-stopped-quickly ()
  "The limits have to hold a runaway program, whatever they are set to.
They are the reason a rule can be run from inside the editor at all: a
left recursion and an endless search both have to come back, and come
back soon enough that nobody reaches for C-g."
  (dolist (case '(("loop(X) :- loop(X).\nloop(a).\n" . "loop(b)")
                  ("wide(X) :- between(1, 100000, X), X > 999999.\n" . "wide(X)")))
    (let* ((db (cocolog-consult-string (car case)))
           (started (current-time))
           (result (cocolog-run-query db (cdr case)))
           (seconds (float-time (time-since started))))
      (should-not (cocolog-result-solutions result))
      ;; and it says which limit it was, rather than just failing
      (should (or (cocolog-result-depth-cut result)
                  (eq (cocolog-result-status result) 'limit)))
      (should (equal (cons (cdr case) t) (cons (cdr case) (< seconds 10)))))))

(ert-deftest cocolog-test-the-graph-numbers-agree-with-each-other ()
  "The place a result is printed has to be inside the line it is printed on."
  (should (< cocolog-graph-status-column
             (- cocolog-graph-max-width (length cocolog-comment-prefix) 2)))
  ;; and a graph is drawn in comments, so the prefix has to be one
  (should (string-prefix-p "%" (string-trim-left cocolog-comment-prefix)))
  ;; the palette has to fill its rows, or the grid has a ragged last line
  (should (zerop (mod (length cocolog-palette) cocolog-palette-columns)))
  ;; the colours it deals must be far enough apart to tell apart, and there
  ;; must be enough of them left to deal at all
  (should (> (length cocolog-palette) 20))
  (should (> cocolog-color-min-distance 100)))

(ert-deftest cocolog-test-a-runaway-grammar-comes-back ()
  "A grammar that never finishes must not take the editor with it.
This one is real: a rule that recurses with no base case, building a
longer list at every step, so that every step costs more than the last.
Counting steps is no promise about time; the clock is."
  (let* ((cocolog-max-seconds 2)
         (cocolog-max-inferences 10000000)
         (db (cocolog-consult-string
              "tokenize(TKs) --> ( [_], { append(TKs, [x], TKs2) } ), tokenize(TKs2).\n"))
         (started (current-time))
         (result (cocolog-run-query db "phrase(tokenize(T), \"abcdefghij\")"))
         (seconds (float-time (time-since started))))
    (should (eq (cocolog-result-status result) 'limit))
    (should (string-search "cocolog-max-seconds" (cocolog-result-message result)))
    (should (equal t (< seconds 8)))))

(ert-deftest cocolog-test-a-goal-that-succeeds-over-and-over-is-not-written-out-each-time ()
  "What a goal came back with is recorded only while anyone will see it."
  (let* ((cocolog-max-exits 3)
         (db (cocolog-consult-string "n(1).\nn(2).\nn(3).\nn(4).\nn(5).\n"))
         (result (cocolog-run-query db "n(X)")))
    (should (cocolog-result-solutions result))
    ;; the node for the goal holds no more than it may
    (letrec ((walk (lambda (node)
                     (should (<= (length (cocolog-node-exits node)) cocolog-max-exits))
                     (mapc walk (cocolog-node-children node)))))
      (funcall walk (cocolog-result-root result))))
  ;; and a node the graph had no room for records nothing at all
  (let* ((cocolog-trace-max-nodes 3)
         (db (cocolog-consult-string "n(1).\nn(2).\nn(3).\nloop(X) :- n(X).\n"))
         (result (cocolog-run-query db "loop(X)")))
    (should (cocolog-result-truncated result))))

(ert-deftest cocolog-test-html-written-as-code-is-not-shown-as-a-picture ()
  "A page about HTML shows the tag it is talking about, not the picture.
The code span is put first as well as last: asking whether a match is
code runs a search of its own, and a match read after that one would be
the wrong text."
  (skip-unless (require 'markdown-mode nil t))
  (with-temp-buffer
    (insert "How you write one: `<img src=\"doc/lists.svg\">`\n\n"
            "Here is a picture:\n\n"
            "<img src=\"doc/lists.svg\" alt=\"a picture\">\n\n"
            "and again: `<img src=\"doc/lists.svg\">`\n")
    (setq buffer-file-name
          (expand-file-name "README.md"
                            (file-name-directory (locate-library "cocolog-mode"))))
    (markdown-mode)
    (font-lock-ensure)
    (unwind-protect
        (progn
          (cocolog-markdown-display-images)
          (should (equal 1 (length (seq-filter
                                    (lambda (o) (overlay-get o 'cocolog-markdown-image))
                                    (overlays-in (point-min) (point-max)))))))
      (setq buffer-file-name nil))))

(ert-deftest cocolog-test-a-quoted-percent-is-not-a-comment ()
  "The line the graph shows for a rule must be the rule, all of it.
A rule that reads a remark says so with \"%\", and cutting its body off
there shows the rule as something it is not."
  (should (equal (cocolog--squeeze
                  "skip(Ts) --> \"%\", string(_), eol, !, more(Ts).")
                 "skip(Ts) --> \"%\", string(_), eol, !, more(Ts)."))
  (should (equal (cocolog--squeeze "p(X) :- q(X).   % a remark") "p(X) :- q(X)."))
  (should (equal (cocolog--squeeze "r(0'%).  % the code of it") "r(0'%)."))
  (should (equal (cocolog--squeeze "t('a % b').  % remark") "t('a % b')."))
  ;; and the graph shows it that way too
  (let* ((db (cocolog-consult-string
              "skip --> \"%\", string(_), eol.\nskip --> [].\n"))
         (result (cocolog-run-query db "phrase(skip, \"%r\\n\")"))
         (text (string-join (cocolog-graph-block result) "\n")))
    (should (string-search "\"%\", string(_), eol" text))))

(defun cocolog-test--shown-text (beg end)
  "The text between BEG and END as the screen shows it.
A swatch stands in for the text of a colour variable, so what is in the
buffer and what is on the screen are two different strings."
  (let ((out "") (pos beg))
    (while (< pos end)
      (let* ((next (next-single-property-change pos 'display nil end))
             (display (get-text-property pos 'display)))
        (setq out (concat out (if (stringp display) display
                                (buffer-substring-no-properties pos next)))
              pos next)))
    out))

(ert-deftest cocolog-test-a-swatch-keeps-the-columns-of-a-graph ()
  "A graph is drawn in columns, and a swatch must not take them back.
The result of a goal has a column of its own; a swatch is shorter than
the `Cxxxxxx_Name\\=' it stands for, so without keeping the room the text
took, every line with a variable in it would pull its result left."
  (let ((dir (file-name-directory (locate-library "cocolog-mode"))))
    (dolist (name '("family.colog" "grammar.colog" "lists.colog"))
      (let ((file (expand-file-name (concat "examples/" name) dir)))
        (skip-unless (file-readable-p file))
        (with-temp-buffer
          (insert-file-contents file)
          (cocolog-mode)
          (setq-local cocolog-color-plain-variables t)
          (font-lock-ensure)
          (goto-char (point-min))
          (let ((checked 0))
            (while (not (eobp))
              (let* ((raw (buffer-substring-no-properties (line-beginning-position)
                                                          (line-end-position)))
                     (shown (cocolog-test--shown-text (line-beginning-position)
                                                      (line-end-position))))
                (when (string-match-p cocolog--graph-line-re raw)
                  (let ((in-file (string-match "[✔✘·]" raw))
                        (on-screen (string-match "[✔✘·]" shown)))
                    (when (and in-file on-screen)
                      (cl-incf checked)
                      (should (equal (list name in-file) (list name on-screen)))))))
              (forward-line 1))
            (should (> checked 10))))))))

(ert-deftest cocolog-test-a-swatch-in-code-is-not-padded ()
  "Only a graph is drawn in columns; code is not, and is left alone."
  (with-temp-buffer
    (insert "p(Ce6194b_Kid) :- q(Ce6194b_Kid).\n")
    (cocolog-mode)
    (font-lock-ensure)
    (should (equal (cocolog-test--shown-text (point-min) (1- (point-max)))
                   "p( Kid ) :- q( Kid )."))))


;;;; running under coco

(ert-deftest cocolog-test-coco-arguments-name-each-arrangement ()
  "The settings become the binary's own options, one arrangement each."
  (let ((cocolog-coco-store "./KB") (cocolog-coco-kb "main")
        (cocolog-coco-host "127.0.0.1") (cocolog-coco-port "2160")
        (cocolog-coco-http-port "8008"))
    (let ((cocolog-coco-arrangement 'local))
      (should (equal (cocolog-coco-arguments) '("--local"))))
    (let ((cocolog-coco-arrangement 'embed))
      (should (equal (cocolog-coco-arguments)
                     '("--embed" "./KB" "--kb" "main"))))
    (let ((cocolog-coco-arrangement 'server))
      (should (equal (cocolog-coco-arguments)
                     '("--kb" "main" "--host" "127.0.0.1" "--tcp" "2160"))))
    (let ((cocolog-coco-arrangement 'http))
      (should (equal (cocolog-coco-arguments)
                     '("--kb" "main" "--host" "127.0.0.1" "--http" "8008"))))))

(ert-deftest cocolog-test-coco-http-without-a-port-refuses ()
  (let ((cocolog-coco-arrangement 'http) (cocolog-coco-http-port ""))
    (should-error (cocolog-coco-arguments) :type 'user-error)))

(ert-deftest cocolog-test-coco-trace-is-on-its-key ()
  (should (eq (lookup-key cocolog-mode-map (kbd "C-c C-e")) #'cocolog-coco-trace)))

(ert-deftest cocolog-test-coco-trace-runs-the-real-binary ()
  "End to end when the binary is beside the checkout: the ports arrive.
SKIPs (passes vacuously) without a built cocolog, the way the shell
suite's database cases do without a server."
  (let ((program cocolog-coco-program))
    (when (and program (file-executable-p program))
      (let ((pl (make-temp-file "coco-trace" nil ".pl"
                                "anc(X, Y) :- parent(X, Y).\nparent(a, b).\n")))
        (unwind-protect
            (with-temp-buffer
              (insert-file-contents pl)
              (setq buffer-file-name pl)
              ;; the file IS the buffer here; a modified flag would make
              ;; the command ask about saving, and batch has nobody to ask
              (set-buffer-modified-p nil)
              (let ((cocolog-coco-arrangement 'local))
                (cocolog-coco-trace "anc(a, X)"))
              (let ((buffer (get-buffer "*coco trace*"))
                    (deadline (+ (float-time) 20)))
                (should buffer)
                (with-current-buffer buffer
                  ;; wait for the SENTINEL, not the ports: the process is
                  ;; then dead and the cleanup below kills nothing live
                  (while (and (< (float-time) deadline)
                              (not (save-excursion
                                     (goto-char (point-min))
                                     (search-forward "-- finished" nil t))))
                    (accept-process-output nil 0.1))
                  (should (save-excursion
                            (goto-char (point-min))
                            (search-forward "Call: (1) anc(a," nil t)))
                  (should (save-excursion
                            (goto-char (point-min))
                            (search-forward "Exit: (1) anc(a,b)" nil t))))))
          (ignore-errors (delete-file pl))
          (let ((buffer (get-buffer "*coco trace*")))
            (when buffer
              (let ((proc (get-buffer-process buffer)))
                (when proc (delete-process proc)))
              (let ((kill-buffer-query-functions nil))
                (kill-buffer buffer)))))))))


(ert-deftest cocolog-test-coco-norm-compares-what-is-said ()
  "The comparator sees through naming and spacing, not through meaning."
  (should (cocolog--coco-agree-p "X=X" "X=_G3"))
  (should (cocolog--coco-agree-p "X=f(Y),L=[1, 2]" "X=f(_G9),L=[1,2]"))
  (should (cocolog--coco-agree-p "O=(<)" "O=<"))
  (should-not (cocolog--coco-agree-p "X=a" "X=b"))
  (should-not (cocolog--coco-agree-p "no solutions" "true"))
  (should (cocolog--coco-agree-p 'error 'error))
  (should-not (cocolog--coco-agree-p "true" 'error)))

(ert-deftest cocolog-test-coco-goal-variables-read-like-the-harness ()
  (should (equal (cocolog--coco-goal-variables "anc(a, X), r(Y, X)")
                 '("X" "Y")))
  (should (equal (cocolog--coco-goal-variables
                  "memb(X, \"ABC\"), atom('Q b'), p(_Hidden)")
                 '("X"))))

(ert-deftest cocolog-test-coco-certify-catches-a-drifted-program ()
  "A graph drawn from one program, certified against another, is caught.
SKIPs (passes vacuously) without a built cocolog."
  (when (cocolog--coco-available-p)
    (with-temp-buffer
      (insert "parent(a, b).\n")
      (cocolog-mode)
      (let ((db (cocolog-buffer-db)))
        ;; the engine answered over parent(a,b); the buffer now says c
        (erase-buffer)
        (insert "parent(a, c).\n")
        (let ((bad (cocolog--coco-certify db (list "parent(a, X)"))))
          (should (= (length bad) 1))
          (should (equal (nth 1 (car bad)) "X=b"))
          (should (equal (nth 2 (car bad)) "X=c")))))))

;;;; ------------------------------------------------------------------
;;;; cocolint, and the reader it stands on
;;;; ------------------------------------------------------------------

(ert-deftest cocolog-test-lint-findings-are-errors-to-walk ()
  "A cocolint finding is read as file, line and column -- HARD louder.
The severity is the whole point of two rules rather than one: a HARD
finding is a compilation error and a WARN one a warning, so
`next-error\=' walks them in the order Emacs walks any others."
  (with-temp-buffer
    (cocolog-lint-mode)
    (let ((hard (assq 'cocolint-hard compilation-error-regexp-alist-alist))
          (warn (assq 'cocolint-warn compilation-error-regexp-alist-alist))
          (finding "tutorials/library/29-ray.pl:111:8 HARD S1 [H1] halt/0 sets")
          (spaced "/a directory/p.pl:1:1 WARN T1 `library(files)' is TIER 1"))
      (should (equal (nth 5 hard) 2))
      (should (equal (nth 5 warn) 1))
      (should (equal (list (nth 2 hard) (nth 3 hard) (nth 4 hard)) '(1 2 3)))
      (should (string-match (nth 1 hard) finding))
      (should (equal (match-string 1 finding) "tutorials/library/29-ray.pl"))
      (should (equal (match-string 2 finding) "111"))
      (should (equal (match-string 3 finding) "8"))
      (should-not (string-match (nth 1 warn) finding))
      ;; a directory with a space in its name is a directory
      (should (string-match (nth 1 warn) spaced))
      (should (equal (match-string 1 spaced) "/a directory/p.pl")))))

(ert-deftest cocolog-test-clause-dump-rows-are-read ()
  "The reader's answer is read row by row, and a directive defines nothing."
  (let* ((text (concat "/tmp/p.pl\t0\t1\t1\t12\tp\t1\tplain\n"
                       "/tmp/p.pl\t20\t3\t1\t18\tdigits\t3\tdcg\n"
                       "/tmp/p.pl\t60\t7\t1\t21\t-\t-1\tdirective(dynamic,1)\n"))
         (rows (cocolog--clauses-parse text)))
    (should (equal rows '((1 1 "p" 1 "plain")
                          (3 1 "digits" 3 "dcg")
                          (7 1 "-" -1 "directive(dynamic,1)"))))
    (should (equal (cocolog--clauses-definitions rows)
                   '((1 1 "p" 1 "plain") (3 1 "digits" 3 "dcg"))))
    ;; and a name written with a doubled quote is one quote to the mode
    (should (equal (cocolog--clauses-indicator '(4 1 "it''s" 1 "plain"))
                   "it's/1"))))

(ert-deftest cocolog-test-the-mode-reads-a-file-as-cocolog-does ()
  "The Elisp reader and clauses.pl agree over the shapes that fool readers.
A 0'c literal that is four characters and not three, a grammar head at
arity+2, a quoted head with a doubled quote, and a directive that
defines nothing.  SKIPs (passes vacuously) without a built cocolog or a
checkout to find the reader in."
  (when (and (cocolog--coco-available-p) cocolog-clauses-program)
    (let ((file (make-temp-file "cocolog-clauses" nil ".pl")))
      (unwind-protect
          (let (theirs)
            (with-temp-file file
              (insert ":- dynamic seen/1.\n"
                      "p(0'c).\n"
                      "digits([D|T]) --> digit(D), digits(T).\n"
                      "'it''s'(X) :- p(X).\n"))
            (setq theirs
                  (mapcar (lambda (row)
                            (cons (nth 0 row) (cocolog--clauses-indicator row)))
                          (cocolog--clauses-definitions
                           (cocolog--clauses-dump file))))
            (should (equal theirs '((2 . "p/1") (3 . "digits/3") (4 . "it's/1"))))
            (with-temp-buffer
              (insert-file-contents file)
              (cocolog-mode)
              (should (equal (cocolog--clauses-of-buffer) theirs))))
        (delete-file file)))))

(provide 'cocolog-tests)

;;; cocolog-tests.el ends here
