;;; make-doc.el --- Regenerate the pictures used by README.md -*- lexical-binding: t; -*-

;;; Commentary:

;; Run with `make doc'.  Every picture is rendered from a real
;; `cocolog-mode' buffer, so what README.md shows is what Emacs shows.

;;; Code:

(require 'cocolog-mode)
(require 'cocolog-svg)

;; No outlines in the pictures: a swatch is drawn as a plain block of
;; colour.  The seed below is chosen so that every colour dealt in them
;; stands out on a white page and on a dark one alike, which is what the
;; outline would otherwise have to rescue.
(setq cocolog-swatch-outline nil)

;; Colours dealt to ordinary variables come from the buffer's seed, which
;; is random; the pictures have to come out the same every time.
(defconst doc--seed 15)    ; a hand that reads on a white page and a dark one

;; Colouring ordinary variables is off until it is asked for; the pictures
;; are here to show what it looks like, so they ask for it.
(setq cocolog-color-plain-variables t)

(defun doc--lines (text &optional style)
  "Fontify TEXT in `cocolog-mode' with swatch STYLE and collect its runs."
  (let ((cocolog-swatch-style (or style cocolog-swatch-style)))
    (with-temp-buffer
      (insert text)
      (cocolog-mode)
      (setq cocolog--color-seed doc--seed)
      (cocolog--forget-plain-colors)
      (font-lock-ensure)
      (cocolog-svg--runs (point-min) (point-max)))))

(defun doc--file-lines (file from to &optional style)
  "Collect the runs of FILE between the lines matching FROM and TO.
The file is read into a buffer of its own and fontified exactly once,
after the seed is pinned: opening it with `find-file-noselect' would
fontify it first with the random seed the mode starts with, and those
colours would survive here and there."
  (let ((cocolog-swatch-style (or style cocolog-swatch-style)))
    (with-temp-buffer
      (insert-file-contents file)
      (cocolog-mode)
      (setq cocolog--color-seed doc--seed)
      (cocolog--forget-plain-colors)
      (font-lock-ensure)
      (let ((region (cocolog-svg-region-of from to)))
        (cocolog-svg--runs (car region) (cdr region))))))

;;;; the colour variables of a rule

(cocolog-svg-write
 "doc/colours.svg"
 (append
  (doc--lines "%% a variable can be a colour and nothing else ...\n")
  (doc--file-lines "examples/family.colog" "^sibling(" "Ce6194b \\\\== C4363d8\\.")
  (doc--lines "\n%% ... or a colour with a name of its own\n")
  (doc--file-lines "examples/family.colog"
                   "^grandparent(" "parent(C3cb44b_Between, C4363d8_Kid)\\.")
  (doc--lines "\n%% ... or a plain name, dealt a colour when the file is opened\n")
  (doc--lines (concat "grandparent(Grandad, Kid) :-\n"
                      "    parent(Grandad, Between),\n"
                      "    parent(Between, Kid).\n")))
 "One rule written three ways: colours for names, colours with names, \
and plain names coloured on screen")

;;;; a rule and the graph of its test case

(cocolog-svg-write
 "doc/graph.svg"
 (doc--file-lines "examples/family.colog"
                  "^%% \\?- grandparent" "^%% ╰── cocolog: 2 solutions")
 "A test case in a comment and the execution graph below the rule")

;;;; the three ways of showing a colour variable

(cocolog-svg-write
 "doc/styles.svg"
 (let ((rule "sibling(Ce6194b_Kid, C4363d8) :- parent(Cffd700_Mum, Ce6194b_Kid).\n"))
   (append (doc--lines "%% what you see: a name where there is one, a colour where there is not\n")
           (doc--lines rule 'name)
           (doc--lines "\n%% C-c C-s: the text of the file, for reading it as another editor would\n")
           (doc--lines rule 'raw)))
 "A rule as the mode shows it, and as it stands in the file")

;;;; a file that writes no colours of its own

(cocolog-svg-write
 "doc/lists.svg"
 (doc--file-lines "examples/lists.colog"
                  "^%% \\?- last_element" "^%% ╰── cocolog: 1 solution")
 "A file of ordinary Prolog, with the colouring switched on")

;;;; a grammar rule and the graph of its test case

(cocolog-svg-write
 "doc/grammar.svg"
 (doc--file-lines "examples/grammar.colog"
                  "^%% \\?- phrase(sentence(Ce6194b_Tree)"
                  "^%% │      │           ╰── ▸2 noun(mouse)")
 "A grammar rule, and the graph of the list it reads")

;;;; the palette

(let ((buffer (get-buffer-create "*cocolog palette*"))
      (cocolog--palette-index 20)
      (cocolog--palette-used '(("#e6194b" . 2) ("#4363d8" . 2) ("#3cb44b" . 2)))
      (cocolog--palette-prompt "Colour for this variable"))
  (cocolog--palette-render buffer)
  (with-current-buffer buffer
    (cocolog-svg-write "doc/palette.svg"
                       (cocolog-svg--runs (point-min) (point-max))
                       "The palette opened by C-c C-v"))
  (kill-buffer buffer))


;;;; the tokenizer, and the top of its graph

(cocolog-svg-write
 "doc/tokens.svg"
 (doc--file-lines "examples/grammar.colog"
                  "^%% \\?- phrase(tokens(Ce6194b_Ts), \"go on\")"
                  "^%% │          ╰── ▸3 more_tokens")
 "A tokenizer, and the graph of the list it reads")

;;;; the picker

(let ((buffer (get-buffer-create "*cocolog goals*"))
      (cocolog--pick-index 30))
  (let ((rows (cocolog--pick-rows (cocolog-goal-snippets))))
    (cocolog--pick-render buffer rows "Insert a goal" 2)
    ;; the picture is of the buffer alone, so the header line and the mode
    ;; line -- which is where the picker really keeps these -- are drawn in
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (goto-char (point-min))
        (insert (cocolog--pick-header rows) "\n"
                (cocolog--pick-example rows) "\n\n")
        (goto-char (point-max))
        (insert "\n" (cocolog--pick-mode-line "Insert a goal") "\n"))))
  (with-current-buffer buffer
    (cocolog-svg-write "doc/goal-picker.svg"
                       (cocolog-svg--runs (point-min) (point-max))
                       "The list offered by C-c C-i: goals and grammar, by group"))
  (kill-buffer buffer))

(dolist (f (directory-files "doc" t "\\.svg\\'"))
  (princ (format "%s  %d bytes\n" f (nth 7 (file-attributes f)))))

;;; make-doc.el ends here
