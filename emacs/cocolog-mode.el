;;; cocolog-mode.el --- Prolog with colours for variables and inline execution graphs -*- lexical-binding: t; -*-

;; Author: cocolog-mode
;; Version: 1.0.0
;; Keywords: languages, prolog, tools
;; Package-Requires: ((emacs "27.1"))
;; URL: https://example.invalid/cocolog-mode

;;; Commentary:

;; cocolog-mode is a Prolog mode with two ideas of its own.
;;
;; 1. A variable can be a *colour* instead of a name.  Press C-c C-v,
;;    pick a colour from the palette, and a variable is inserted.  The
;;    same colour used anywhere else in the same clause is the same
;;    variable -- which is exactly how Prolog scopes variables anyway.
;;    On disk the variable is written `C' plus the six hex digits of the
;;    colour, so the file stays valid Prolog; the mode only *renders* it
;;    as a swatch.
;;
;; 2. A test case is written as a comment above (or below) a rule:
;;
;;        %% ?- ancestor(tom, X).
;;
;;    C-c C-t runs it with the built-in engine and writes the execution
;;    graph -- the whole SLD tree, with the clauses tried, what unified
;;    and what failed -- underneath the rule, as comments.
;;
;; Everything is plain text: colours and graphs survive git, diff and
;; any other editor.
;;
;; Quick start:
;;
;;   (add-to-list 'load-path "/path/to/cocolog-mode")
;;   (require 'cocolog-mode)
;;
;; Files ending in .colog use the mode automatically.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'cocolog-engine)
(require 'cocolog-graph)
(require 'cocolog-color)

;;;; ------------------------------------------------------------------
;;;; Options and faces
;;;; ------------------------------------------------------------------

(defcustom cocolog-indent-width 4
  "Number of columns a clause body is indented by."
  :type 'integer :group 'cocolog)

(defcustom cocolog-swatch-style 'name
  "How colour variables are displayed.

`name'  the default: a variable with a name of its own shows that name
        on a background of its colour, and one without shows its colour
        and nothing else.  Either way the `Cxxxxxx\=' part is not shown,
        and point steps over the variable rather than into it, so the
        colour cannot be edited by accident.  Use
        \\[cocolog-name-variable-at-point] to name a variable and
        \\[cocolog-recolor-variable-at-point] to recolour it.

`raw'   the text as it stands in the file, coloured.  For reading a file
        as another editor would see it, or for repairing one by hand.

\\[cocolog-cycle-swatch-style] switches between them."
  :type '(choice (const name) (const raw))
  :group 'cocolog)

(defcustom cocolog-swatch-text "   "
  "Text used to draw a colour swatch when `cocolog-swatch-style' is `block'."
  :type 'string :group 'cocolog)

(defcustom cocolog-comment-prefix "%% "
  "Comment prefix used for generated execution graphs."
  :type 'string :group 'cocolog)

(defcustom cocolog-color-plain-variables nil
  "When non-nil, ordinary variables are coloured on screen.

An ordinary variable such as `Grandad\=' is given a colour when the file
is shown, and keeps it for as long as the buffer is open; nothing is
written to the file.  Each buffer draws its own colours, so a file looks
different from one session to the next -- what matters is that two
occurrences of a variable look the same and its neighbours look
different, not which colour it happens to have.
\\[cocolog-shuffle-colors] deals a new hand.

Variables whose colour *is* their name -- the `Cxxxxxx\=' ones -- keep
the colour written in the file, since there is nothing else to call
them by.  Variables beginning with an underscore are left alone.

Off to begin with: a file you open is shown as it was written, and the
colours are something you ask for with \\[cocolog-toggle-plain-colors].
It is also what font lock spends its time on in a large file, so leaving
it off is what keeps a big buffer quick."
  :type 'boolean :group 'cocolog)

(defcustom cocolog-adopt-known-variables t
  "When non-nil, a name the clause already knows is written as that variable.
A clause that says `Ce6194b_Grandad\=' has a variable called Grandad in
it; type `Grandad\=' in the same clause and it becomes that variable
rather than a second one that happens to read the same.  Prolog would
treat the two as different, and nothing on screen would say so."
  :type 'boolean :group 'cocolog)

(defcustom cocolog-auto-color nil
  "When non-nil, a variable you type in a clause is coloured at once.
Finish typing an ordinary variable -- that is, type the comma, bracket
or space after it -- and it becomes a colour variable keeping the name
you gave it.  Typing the same name again in the same clause gives back
the same colour, since it is the same variable.

Nothing else is touched: a variable that already has a colour is left
alone, and so is anything inside a comment or a quoted item, which is
why the queries in your test cases keep their plain names.

This *writes* the colour into the file, as `Ce6194b_Parent\='.  With
`cocolog-color-plain-variables\=' on -- \\[cocolog-toggle-plain-colors]
-- you do not need it: a variable you type is coloured on screen anyway
and the file keeps the plain name.  Turn it on when you want a particular colour
pinned to a variable for everyone who opens the file.

Turn it off with \\[cocolog-toggle-auto-color] to type plain Prolog."
  :type 'boolean :group 'cocolog)

(defcustom cocolog-refresh-idle nil
  "Seconds of quiet after which a rule\='s graph is drawn again, or nil.
Off: a graph is drawn when you ask for one, with
\\[cocolog-run-test-at-point] or \\[cocolog-run-all-tests], and not
before.  A rule being written is half a rule, and running half a rule
over and over while it is typed is how an editor comes to feel slow --
the more so with the very rules a graph helps most with, the ones that
do not terminate yet.

Set it to a number of seconds to have the graph under the rule at point
redrawn once you stop typing.  Nothing happens where there is no graph
to redraw, or while the clause does not parse."
  :type '(choice (const :tag "Only when a command asks" nil) number)
  :group 'cocolog)

(defcustom cocolog-run-tests-on-save nil
  "When non-nil, refresh every execution graph in the buffer on save."
  :type 'boolean :group 'cocolog)

(defface cocolog-test-face
  '((t :inherit font-lock-comment-face :weight bold))
  "Face for a test case written in a comment."
  :group 'cocolog)

(defface cocolog-trace-face
  '((t :inherit shadow))
  "Face for the generated execution graph."
  :group 'cocolog)

(defface cocolog-cut-face
  '((t :inherit font-lock-warning-face))
  "Face for the cut."
  :group 'cocolog)

;;;; ------------------------------------------------------------------
;;;; Syntax
;;;; ------------------------------------------------------------------

(defvar cocolog-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?% "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?/ ". 14" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?\\ "\\" table)
    ;; `|' and `$' are a symbol and a word character in the table this one
    ;; inherits from, which would glue them to the variable next to them:
    ;; the T of [H|T] has to start a symbol of its own
    (dolist (c '(?+ ?- ?= ?< ?> ?: ?. ?? ?@ ?# ?& ?~ ?^ ?\; ?| ?$ ?!))
      (modify-syntax-entry c "." table))
    table)
  "Syntax table for `cocolog-mode'.")

(defconst cocolog-builtin-predicates
  '("is" "true" "fail" "false" "not" "call" "findall" "bagof" "setof"
    "forall" "aggregate_all" "between" "succ" "length" "functor" "arg"
    "copy_term" "var" "nonvar" "atom" "number" "integer" "float" "atomic"
    "compound" "callable" "is_list" "ground" "msort" "sort" "compare"
    "write" "writeln" "print" "nl" "tab" "throw" "catch" "halt"
    "atom_codes" "atom_length" "atom_number" "atom_concat"
    "append" "member" "memberchk" "reverse" "last" "nth0" "nth1" "select"
    "permutation" "maplist" "sum_list" "max_list" "min_list" "numlist"
    "include" "exclude" "dynamic" "discontiguous")
  "Predicates highlighted as builtins.")

(defconst cocolog--syntax-propertize
  (syntax-propertize-rules
   ;; 0'' is the quote character, 0'\n an escape, 0'c any other one.  The
   ;; apostrophe there is not a quote: without this rule it would open a
   ;; quoted atom, and the rest of the file would look like one -- which
   ;; breaks every question about what is code and what is a comment.
   ("0\\('\\)\\('\\)" (1 ".") (2 "."))
   ("0\\('\\)\\\\" (1 "."))
   ("0\\('\\)" (1 ".")))
  "Syntax rules for the character literals Prolog writes with an apostrophe.")

(defconst cocolog--trace-begin-re
  "^[ \t]*%+[ \t]*\\(?:╭──\\|\\+--\\)[ \t]*cocolog trace"
  "Regexp matching the first line of a generated graph block.")

(defconst cocolog--trace-end-re
  "^[ \t]*%+[ \t]*\\(?:╰──\\|\\+--\\)[ \t]*cocolog:"
  "Regexp matching the last line of a generated graph block.")

(defconst cocolog--trace-body-re
  "^[ \t]*%+[ \t]*\\(?:│\\||\\) "
  "Regexp matching a body line of a generated graph block.")

;;;; ------------------------------------------------------------------
;;;; Font lock
;;;; ------------------------------------------------------------------

(defun cocolog--syntax (&optional pos)
  "Parser state at POS.
Unlike `syntax-ppss' this moves neither point nor the match data, both
of which callers in this file rely on."
  (save-excursion (save-match-data (syntax-ppss (or pos (point))))))

(defun cocolog--swatch-face (hex)
  "The face a colour variable of colour HEX is drawn with.
See `cocolog-swatch-face': the text on the swatch is readable whatever
the theme, and the swatch is outlined when its colour is so close to
the frame background that it would otherwise disappear."
  (cocolog-swatch-face hex))

(defun cocolog--swatch-display (hex &optional label width)
  "Return what is displayed in place of a colour variable.
HEX is its colour and LABEL the name the developer gave it, if any.

The `Cxxxxxx\=' part is never shown: it is how the colour is written
down, not something to read.  A variable with a name of its own shows
that name on its colour; one without shows the colour and nothing else,
because there the colour is the name.

WIDTH is how many columns the text being replaced takes up.  A swatch is
shorter than the `Cxxxxxx_Name\=' it stands for, and where the text is
drawn in columns -- a generated graph is -- taking those columns back
would pull the results out of line.  Given a WIDTH, the swatch keeps
them: the colour stays as tight as it was, and the space the name saved
is left blank."
  (pcase cocolog-swatch-style
    ('raw nil)
    (_ (let* ((text (if label (concat " " label " ") cocolog-swatch-text))
              (swatch (propertize text 'face (cocolog--swatch-face hex))))
         (if (and width (> width (string-width text)))
             (concat swatch (make-string (- width (string-width text)) ?\s))
           swatch)))))

(defconst cocolog--graph-line-re
  "^[ \t]*%+[ \t]*[│╭╰├┼|+]"
  "How a line of a generated graph begins.
The graph is drawn in columns -- the result of a goal has a column of
its own -- so what is shown in place of the text there has to take up
the room the text did.")

(defun cocolog--graph-line-at-p (pos)
  "Non-nil when POS is on a line of a generated graph."
  (save-excursion
    (save-match-data
      (goto-char pos)
      (beginning-of-line)
      (looking-at-p cocolog--graph-line-re))))

(defmacro cocolog--with-syntax (&rest body)
  "Run BODY with the syntax table of the mode, if it is not in force already.
Setting the syntax table throws away the parser\='s cache, and these are
the innermost loops of font lock: in a cocolog buffer the table is
already the right one, so nothing needs to be set."
  (declare (indent 0) (debug t))
  `(if (eq (syntax-table) cocolog-mode-syntax-table)
       (progn ,@body)
     (with-syntax-table cocolog-mode-syntax-table ,@body)))

(defun cocolog--match-color-var (limit)
  "Font lock matcher for a colour variable up to LIMIT.
Binds `case-fold-search' and the syntax table itself, so that it works
the same in a foreign buffer: Markdown, for one, folds case and treats
the underscore as punctuation, which would split `Ce6194b_Grandad\=' in
two and colour the halves separately."
  (let ((case-fold-search nil))
    (cocolog--with-syntax
      (re-search-forward cocolog-color-var-regexp limit t))))

(defun cocolog--fontify-color-var ()
  "Font lock helper: swatch the colour variable that was just matched.
While the swatch stands in for the text, point is kept out of it and the
whole variable reads as one thing: the colour written inside it is not
there to be edited a character at a time."
  (let* ((beg (match-beginning 0))
         (end (match-end 0))
         ;; without -no-properties the swatch would carry whatever the
         ;; buffer had on those characters into the display string
         (hex (concat "#" (downcase (match-string-no-properties 1))))
         (label (match-string-no-properties 2))
         ;; in a graph the text is laid out in columns, so the swatch has
         ;; to take up the room the text it stands for took up
         (display (cocolog--swatch-display
                   hex label (and (cocolog--graph-line-at-p beg) (- end beg)))))
    (when display
      (put-text-property beg end 'display display)
      (put-text-property beg end 'cursor-intangible t)
      ;; a function, not a string: naming a colour means measuring it
      ;; against the palette, and that is not worth doing for a tooltip
      ;; nobody has asked to see yet
      (put-text-property beg end 'help-echo
                         (lambda (&rest _)
                           (format "%s%s -- %s"
                                   (if label (concat label ", ") "")
                                   (cocolog-color-name hex) hex))))
    (cocolog--swatch-face hex)))

(defvar-local cocolog--color-seed 0
  "What makes this buffer\='s colours its own.  See `cocolog-shuffle-colors'.")

(defvar-local cocolog--code-block-cache nil
  "Colours of the code block last looked at, as (BEG END ALIST).")

(defvar-local cocolog--code-block-cache nil
  "Colours of the code block last looked at, as (REGION . ALIST).")

(defvar-local cocolog--plain-cache nil
  "Colours of the clause last looked at, as (BEG END ALIST).")

(defvar-local cocolog--dealt-cache (make-hash-table :test 'equal)
  "Colours already dealt, keyed by the names they were dealt to.")

(defvar-local cocolog--pinned-cache nil
  "The colours written into this buffer, or nil before they are looked for.")

(defun cocolog-pinned-colors ()
  "Return every colour written into this buffer as a Cxxxxxx variable.
These were chosen by hand and stand for particular variables, so a
colour dealt to an ordinary variable should not look like one of them
even in another clause: two swatches of one colour a line apart read as
one thing."
  (or cocolog--pinned-cache
      (setq cocolog--pinned-cache
            (save-match-data
              (save-excursion
                (goto-char (point-min))
                (let ((case-fold-search nil) (out '()))
                  (while (re-search-forward cocolog-color-var-regexp nil t)
                    (cl-pushnew (concat "#" (downcase (match-string-no-properties 1)))
                                out :test #'equal))
                  (or out 'none)))))
      nil))

(defun cocolog--shun-for-dealing (hex)
  "Non-nil when HEX should not be dealt to an ordinary variable.
A colour that would melt into the frame is no use, and one that looks
like a colour written into the file somewhere would be worse than no
colour at all: the reader would take the two swatches for one variable."
  (or (cocolog-swatch-needs-outline-p hex)
      (let ((pinned (cocolog-pinned-colors)))
        (and (listp pinned)
             (cl-some (lambda (other)
                        (< (cocolog-color-distance hex other)
                           cocolog-color-min-distance))
                      pinned)
             t))))

(defun cocolog--pick-plain-color (name taken)
  "Return a colour for the variable NAME that is not one of TAKEN.
The colour follows from the name and from this buffer\='s seed, so a
name keeps its colour while you edit and tends to keep it from clause to
clause; a colour too close to one the clause already uses is passed
over, because telling two variables of a rule apart matters more than
either particular colour."
  ;; a colour that would need an outline to stand out from the frame is
  ;; not dealt: the outline is for a colour someone chose deliberately
  (cocolog-distinct-color name taken cocolog--color-seed
                          #'cocolog--shun-for-dealing))

(defun cocolog--plain-colors-in (beg end)
  "Return an alist of NAME -> HEX for the ordinary variables between BEG and END.
Only variables count: a capitalised word in a prose comment is passed
over, or the words of the commentary at the top of a file would take
colours away from the clauses below it.  Graphs and test cases are not
prose, so what they name does count.  Colours already written into the
text are left out of the pool."
  (save-match-data
    (save-excursion
      (let ((case-fold-search nil)
            (taken '()) (names '()) (out '()))
        ;; one walk for both: the colours already written here, which are
        ;; not to be dealt again, and the ordinary variables, which want a
        ;; colour.  Two walks over the same text cost twice as much and
        ;; this runs whenever the buffer changes.
        (goto-char beg)
        (while (re-search-forward cocolog-color-var-regexp end t)
          (cl-pushnew (concat "#" (downcase (match-string-no-properties 1)))
                      taken :test #'equal))
        (setq taken (nreverse taken))
        (goto-char beg)
        ;; the table is used for the search alone; the checks below need
        ;; the buffer's own, and `syntax-ppss' caches what it is told
        (while (cocolog--with-syntax
                 (re-search-forward "\\_<\\([A-Z][A-Za-z0-9_]*\\)\\_>" end t))
          (let ((start (match-beginning 0))
                (name (match-string-no-properties 0)))
            (when (and (not (member name names))
                       (not (cocolog-color-var-p name))
                       (cocolog--colourable-position-p start))
              (push name names))))
        (setq names (nreverse names))
        ;; Dealing is the expensive part, and it depends on nothing but
        ;; the names, what is already taken and the seed.  Typing inside
        ;; a clause changes none of those most of the time, so the answer
        ;; is kept and looked up by them rather than worked out again.
        (let ((key (list names taken cocolog--color-seed
                         cocolog-color-min-distance
                         (cocolog-pinned-colors))))
          (or (gethash key cocolog--dealt-cache)
              (puthash key
                       (dolist (name names (nreverse out))
                         (let ((hex (cocolog--pick-plain-color name taken)))
                           (push hex taken)
                           (push (cons name hex) out)))
                       cocolog--dealt-cache)))))))

(defun cocolog--clause-functor-at (pos)
  "Return the name of the predicate whose clause begins at or after POS.
Whitespace and comment lines in the way are stepped over."
  (save-match-data
    (save-excursion
      (goto-char pos)
      (let ((go t))
        (while go
          (skip-chars-forward " \t\n\r")
          (if (and (not (eobp)) (eq (char-after) ?%))
              (forward-line 1)
            (setq go nil))))
      (when (looking-at "\\([a-z][A-Za-z0-9_]*\\)")
        (match-string-no-properties 1)))))

(defun cocolog--predicate-region (pos)
  "Return the bounds of the clauses around POS that make up one predicate.
A predicate is usually written as a run of clauses, and the graph under
them names the variables of all of them, so it is the run -- graphs
included -- that has to share one set of colours.  Two clauses of a
predicate that use the same name then show it in the same colour, which
is what a reader expects even though Prolog scopes the two apart."
  (save-match-data
    (let* ((beg (or (cocolog--previous-clause-end pos) (point-min)))
           (end (or (cocolog--next-clause-end pos) (point-max)))
           (name (cocolog--clause-functor-at beg)))
      (when name
        ;; earlier clauses of the same predicate
        (let ((start beg) (go t))
          (while go
            (if (<= start (point-min))
                (setq go nil)
              (let ((prev (or (cocolog--previous-clause-end
                               (max (point-min) (- start 2)))
                              (point-min))))
                (if (and (< prev start)
                         (equal name (cocolog--clause-functor-at prev)))
                    (setq start prev)
                  (setq go nil)))))
          (setq beg (cocolog--skip-graphs-forward start)))
        ;; later ones
        (let ((stop end) (go t))
          (while go
            (if (or (>= stop (point-max))
                    (not (equal name (cocolog--clause-functor-at stop))))
                (setq go nil)
              (let ((next (cocolog--next-clause-end stop)))
                (if (and next (> next stop)) (setq stop next) (setq go nil)))))
          ;; and the graphs written under the last of them
          (save-excursion
            (goto-char stop)
            (forward-line 1)
            (let ((go t))
              (while go
                (cond
                 ((eobp) (setq go nil))
                 ((looking-at-p "[ \t]*$") (forward-line 1))
                 ((looking-at-p cocolog--trace-begin-re)
                  (let ((block-end (cocolog--trace-block-end)))
                    (if block-end (progn (setq stop block-end) (goto-char block-end))
                      (setq go nil))))
                 ((looking-at-p "[ \t]*%") (forward-line 1))
                 (t (setq go nil))))))
          (setq end stop)))
      (cons beg end))))

(defun cocolog--plain-colors-at (pos &optional region exact)
  "Return the colours of the ordinary variables of the clause around POS.
REGION, a cons of two positions, keeps the clause inside it -- in a
Markdown buffer the clause must not run out of its code block and into
the prose, where a full stop means something else entirely.  With EXACT,
REGION is the text to colour and no clause is looked for at all."
  (save-match-data
   (unless (and cocolog--plain-cache
                (>= pos (nth 0 cocolog--plain-cache))
                (<= pos (nth 1 cocolog--plain-cache))
                ;; a cached answer is only good for the same question: an
                ;; exact region and a clause region can cover the same
                ;; position and hand out different colours
                (equal (nth 3 cocolog--plain-cache) (and exact region)))
    (let* ((whole (unless exact (cocolog--predicate-region pos)))
           (beg (if exact (car region)
                  (max (or (car region) (point-min)) (car whole))))
           (end (if exact (cdr region)
                  (min (or (cdr region) (point-max)) (cdr whole)))))
      (setq cocolog--plain-cache
            (list beg end (cocolog--plain-colors-in beg end) (and exact region))))))
  (nth 2 cocolog--plain-cache))

(defun cocolog--forget-plain-colors (&rest _)
  "Drop the cached colours; the text they were worked out from has changed."
  (setq cocolog--plain-cache nil)
  (setq cocolog--code-block-cache nil))

(defun cocolog-forget-pinned-colors (&rest _)
  "Look for the colours written into the buffer again.
Not on every keystroke: that means reading the whole buffer, and a
colour is written into it by a command, not by ordinary typing."
  (setq cocolog--pinned-cache nil))

(defun cocolog--trace-block-start (pos)
  "Return where the graph block around POS begins, or nil if POS is not in one.
One search backwards, rather than a walk line by line: this is asked
once per variable in a graph, and a graph can be long."
  (save-match-data
    (save-excursion
      (goto-char pos)
      (beginning-of-line)
      (when (cocolog--in-trace-block-p (point))
        (if (looking-at-p cocolog--trace-begin-re)
            (point)
          (and (re-search-backward cocolog--trace-begin-re nil t)
               (point)))))))

(defun cocolog--commented-position-p (pos)
  "Non-nil when POS is inside a comment or a quoted item.
Outside a cocolog buffer -- inside a Markdown code block, say -- the
mode\='s comment syntax is not in force, so the `%\=' is looked for on the
line instead; without that, the words of a remark written beside a rule
would be taken for variables."
  (or
   ;; the cheap answer first: a line that begins with a comment character
   ;; is a comment, and a graph is nothing but such lines.  Asking the
   ;; parser about every word of a graph is what made typing slow.
   (save-match-data
     (save-excursion
       (goto-char pos)
       (cocolog--comment-line-p)))
   (nth 8 (cocolog--syntax pos))
   (and (not (derived-mode-p 'cocolog-mode))
        (save-match-data
          (save-excursion
            (goto-char pos)
            (and (search-backward "%" (line-beginning-position) t) t))))))

(defun cocolog--in-test-query-p (pos)
  "Non-nil when POS is inside a `?-\=' test case written in a comment.
A test case is a query, so what looks like a variable there is one, and
it should read the same as it does in the graph underneath."
  (save-match-data
    (save-excursion
      (and (cocolog--commented-position-p pos)
           (progn
             (goto-char pos)
             (let ((bol (line-beginning-position))
                   (eol (line-end-position)))
               (goto-char bol)
               (and (re-search-forward "\\?-" eol t)
                    (<= (point) pos)
                    ;; the query ends at its period; a remark written after
                    ;; that on the same line is prose again
                    (let ((end (save-excursion
                                 (if (re-search-forward "\\.\\([ \t]\\|$\\)" eol t)
                                     (match-beginning 0)
                                   eol))))
                      (<= pos end)))))))))

(defun cocolog--colourable-position-p (pos)
  "Non-nil when the variable at POS is one the mode may colour.
Code always counts.  Inside a comment only a generated graph and a test
case do: the words of a sentence are not variables."
  (or (not (cocolog--commented-position-p pos))
      (cocolog--in-trace-block-p pos)
      (cocolog--in-test-query-p pos)))

(defun cocolog--match-plain-var (limit)
  "Font lock matcher for an ordinary variable up to LIMIT.
Prose comments and quoted items are skipped -- a capitalised word in a
sentence is not a variable -- but a generated graph is all goals and a
test case is a query, so the variables in those count."
  (and cocolog-color-plain-variables
       (let ((case-fold-search nil) (found nil))
         (while (and (not found)
                     (re-search-forward "\\_<\\([A-Z][A-Za-z0-9_]*\\)\\_>" limit t))
           (let ((start (match-beginning 0))
                 (name (match-string-no-properties 0)))
             (unless (or (cocolog-color-var-p name)
                         (not (cocolog--colourable-position-p start)))
               (setq found t))))
         found)))

(defun cocolog--plain-colors-covering (pos)
  "Return the colours to use at POS, from the cache where it can.
The cache is consulted before anything is worked out: a graph holds many
variables and they all fall inside one region, so the region should be
found once, not once for each of them."
  (if (and cocolog--plain-cache
           (null (nth 3 cocolog--plain-cache))
           (>= pos (nth 0 cocolog--plain-cache))
           (<= pos (nth 1 cocolog--plain-cache)))
      (nth 2 cocolog--plain-cache)
    ;; from inside a graph, step back into the predicate it belongs to;
    ;; its region reaches forward over the graph again
    (let* ((block (and (cocolog--in-trace-block-p pos)
                       (cocolog--trace-block-start pos)))
           (anchor (or (and block
                            (let ((after (cocolog--previous-clause-end
                                          (max (point-min) (1- block)))))
                              (and after (max (point-min) (- after 2)))))
                       pos)))
      (cocolog--plain-colors-at anchor))))

(defun cocolog--fontify-plain-var ()
  "Font lock helper: colour the ordinary variable that was just matched."
  ;; both are read out of the match data first: working out the colours
  ;; of a clause runs regexps of its own
  (let* ((name (match-string-no-properties 0))
         (pos (match-beginning 0))
         (hex (cdr (assoc name (cocolog--plain-colors-covering pos)))))
    (and hex (cocolog--swatch-face hex))))

;;;###autoload
(defun cocolog-shuffle-colors ()
  "Deal this buffer\='s variables a new set of colours.
Only the ordinary variables move: the ones whose colour is written in
the file stay as they are."
  (interactive)
  (setq cocolog--color-seed (random 100000))
  (cocolog-forget-pinned-colors)
  (cocolog--forget-plain-colors)
  (font-lock-flush)
  (message "New colours dealt"))

(defun cocolog--menu-changed ()
  "Tell the frame that a tick in the Coco menu has moved.
The menu bar is drawn from a copy that Emacs rebuilds only when it is
told the copy may be out of date.  Without this a toggle changes the
setting and leaves its own tick box showing the old answer -- for as
long as the frame is left alone, which on a Mac can be the whole
session, since the menu bar there lives outside the frame."
  (force-mode-line-update t))

;;;###autoload
(defun cocolog-toggle-plain-colors ()
  "Turn colouring of ordinary variables on or off.
See `cocolog-color-plain-variables'."
  (interactive)
  (setq cocolog-color-plain-variables (not cocolog-color-plain-variables))
  (cocolog--forget-plain-colors)
  (font-lock-flush)
  (cocolog--menu-changed)
  (message (if cocolog-color-plain-variables
               "Ordinary variables are coloured on screen"
             "Ordinary variables are left plain")))

;;;###autoload
(defun cocolog-toggle-run-tests-on-save ()
  "Turn running every test case on save on or off.
See `cocolog-run-tests-on-save\='."
  (interactive)
  (setq cocolog-run-tests-on-save (not cocolog-run-tests-on-save))
  (cocolog--menu-changed)
  (message (if cocolog-run-tests-on-save
               "Every test case runs when the file is saved"
             "Saving the file runs nothing")))

(defun cocolog--graph-style-changed (what)
  "Say that WHAT changed, and how to see it."
  (cocolog--menu-changed)
  (message "%s.  %s" what
           (if (cocolog--buffer-has-graphs-p)
               (substitute-command-keys
                "Run \\[cocolog-run-all-tests] to draw the graphs again")
             "It applies to the next run")))

(defun cocolog--buffer-has-graphs-p ()
  "Non-nil when this buffer holds a graph that the change would alter."
  (save-excursion
    (save-match-data
      (goto-char (point-min))
      (and (re-search-forward cocolog--trace-begin-re nil t) t))))

;;;###autoload
(defun cocolog-toggle-graph-unicode ()
  "Draw graphs with box drawing characters, or with ASCII.
See `cocolog-graph-unicode\='."
  (interactive)
  (setq cocolog-graph-unicode (not cocolog-graph-unicode))
  (cocolog--graph-style-changed
   (if cocolog-graph-unicode
       "Graphs are drawn with box drawing characters"
     "Graphs are drawn with ASCII")))

;;;###autoload
(defun cocolog-toggle-graph-clauses ()
  "Show, or stop showing, every clause the solver tried.
See `cocolog-graph-show-clauses\='."
  (interactive)
  (setq cocolog-graph-show-clauses (not cocolog-graph-show-clauses))
  (cocolog--graph-style-changed
   (if cocolog-graph-show-clauses
       "Graphs show the clauses that were tried"
     "Graphs show the goals alone")))

;;;###autoload
(defun cocolog-toggle-collapse-failures ()
  "Put a run of failed head unifications on one line, or on several.
See `cocolog-graph-collapse-failures\='."
  (interactive)
  (setq cocolog-graph-collapse-failures (not cocolog-graph-collapse-failures))
  (cocolog--graph-style-changed
   (if cocolog-graph-collapse-failures
       "Clauses that did not match are merged into one line"
     "Every clause that did not match has a line")))

;;;###autoload
(defun cocolog-toggle-clause-detail ()
  "Show a whole clause in the graph, or its head alone.
See `cocolog-graph-clause-detail\='."
  (interactive)
  (setq cocolog-graph-clause-detail
        (if (eq cocolog-graph-clause-detail 'full) 'head 'full))
  (cocolog--graph-style-changed
   (if (eq cocolog-graph-clause-detail 'full)
       "Graphs show the whole clause"
     "Graphs show the head of the clause")))

(defun cocolog--match-test-query (limit)
  "Font lock matcher for a `?-' test case inside a comment, up to LIMIT."
  (let (found)
    (while (and (not found) (re-search-forward "\\?-.*$" limit t))
      (when (and (nth 4 (cocolog--syntax (match-beginning 0)))
                 (not (save-excursion
                        (goto-char (match-beginning 0))
                        (beginning-of-line)
                        (looking-at-p cocolog--trace-begin-re))))
        (setq found t)))
    found))

(defun cocolog--match-trace-line (limit)
  "Font lock matcher for a generated graph line, up to LIMIT."
  (let (found)
    (while (and (not found) (not (eobp)) (< (point) limit))
      (beginning-of-line)
      (if (or (looking-at cocolog--trace-begin-re)
              (looking-at cocolog--trace-end-re)
              (looking-at cocolog--trace-body-re))
          (progn (set-match-data (list (line-beginning-position)
                                       (min limit (line-end-position))))
                 (goto-char (min limit (1+ (line-end-position))))
                 (setq found t))
        (forward-line 1)))
    found))

(defvar cocolog-font-lock-keywords
  `(;; head of a clause, at the beginning of a line
    ("^[ \t]*\\([a-z][A-Za-z0-9_]*\\)\\(?:(\\|[ \t]*\\(?::-\\|-->\\|\\.\\)\\)"
     (1 font-lock-function-name-face))
    ;; directives
    ("^[ \t]*\\(:-\\|\\?-\\)" (1 font-lock-preprocessor-face))
    ;; neck and control
    ("\\(:-\\|-->\\|->\\|;\\)" (1 font-lock-keyword-face))
    ("\\(\\\\\\+\\)" (1 font-lock-keyword-face))
    ("!" . 'cocolog-cut-face)
    ;; builtins
    (,(concat "\\_<" (regexp-opt cocolog-builtin-predicates t) "\\_>")
     (1 font-lock-builtin-face))
    ;; numbers
    ("\\_<[0-9]+\\(?:\\.[0-9]+\\)?\\(?:[eE][-+]?[0-9]+\\)?\\_>"
     (0 font-lock-constant-face))
    ;; ordinary variables
    ("\\_<\\([A-Z_][A-Za-z0-9_]*\\)\\_>" (1 font-lock-variable-name-face))
    ;; generated graphs are dimmed ...
    (cocolog--match-trace-line (0 'cocolog-trace-face t))
    ;; ... test cases stand out ...
    (cocolog--match-test-query (0 'cocolog-test-face t))
    ;; ordinary variables are coloured for as long as the buffer lives ...
    (cocolog--match-plain-var (0 (cocolog--fontify-plain-var) t))
    ;; ... and colour variables win everywhere, comments included.
    (cocolog--match-color-var (0 (cocolog--fontify-color-var) t)))
  "Font lock rules for `cocolog-mode'.")

(defun cocolog--color-var-bounds (&optional pos)
  "Return the bounds of the colour variable around POS, or nil."
  (save-excursion
    (goto-char (or pos (point)))
    (let ((case-fold-search nil)
          (target (or pos (point)))
          (res nil))
      (beginning-of-line)
      (while (and (not res)
                  (re-search-forward cocolog-color-var-regexp
                                     (line-end-position) t))
        (when (and (<= (match-beginning 0) target) (>= (match-end 0) target))
          (setq res (cons (match-beginning 0) (match-end 0)))))
      res)))

;;;; ------------------------------------------------------------------
;;;; Clauses
;;;; ------------------------------------------------------------------

(defun cocolog-buffer-db (&optional buffer)
  "Consult BUFFER (default the current one) and return the database."
  (with-current-buffer (or buffer (current-buffer))
    (cocolog-consult-string
     (buffer-substring-no-properties (point-min) (point-max))
     nil (point-min))))

(defun cocolog--in-trace-block-p (&optional pos)
  "Non-nil when POS is inside a generated graph block."
  (save-excursion
    (goto-char (or pos (point)))
    (beginning-of-line)
    (or (looking-at-p cocolog--trace-begin-re)
        (looking-at-p cocolog--trace-end-re)
        (looking-at-p cocolog--trace-body-re))))

(defun cocolog-clause-at-point (db &optional pos)
  "Return the clause record of DB that POS belongs to."
  (let* ((p (or pos (point)))
         (recs (cocolog-db-order db))
         (inside nil) (before nil) (after nil))
    (dolist (r recs)
      (cond
       ((and (<= (cocolog-clause-start r) p) (<= p (cocolog-clause-end r)))
        (setq inside r))
       ((< (cocolog-clause-end r) p) (setq before r))
       ((and (null after) (> (cocolog-clause-start r) p)) (setq after r))))
    (or inside
        (if (cocolog--in-trace-block-p p) (or before after) (or after before)))))

(defun cocolog-clause-bounds-at-point ()
  "Return (START . END) of the clause around point, or nil."
  (let* ((db (cocolog-buffer-db))
         (rec (cocolog-clause-at-point db)))
    (and rec (cons (cocolog-clause-start rec) (cocolog-clause-end rec)))))

(defun cocolog--clause-text ()
  (let ((b (cocolog-clause-bounds-at-point)))
    (and b (buffer-substring-no-properties (car b) (cdr b)))))

(defun cocolog-clause-color-usage (&optional text)
  "Return an alist of (HEX . COUNT) for the colours used in the clause at point.
TEXT defaults to the text of that clause."
  (let ((case-fold-search nil)
        (text (or text (cocolog--clause-text) ""))
        (res '()) (pos 0))
    (while (string-match cocolog-color-var-regexp text pos)
      ;; read everything out of the match data before calling anything that
      ;; might run a regexp of its own and overwrite it
      (let* ((end (match-end 0))
             (hex (concat "#" (downcase (match-string 1 text))))
             (cell (assoc hex res)))
        (setq pos end)
        (if cell (setcdr cell (1+ (cdr cell))) (push (cons hex 1) res))))
    (nreverse res)))

(defun cocolog-clause-color-tokens (&optional text)
  "Return an alist of (HEX . TOKEN) for the colour variables of this clause.
TOKEN is the variable as it is written, name included, so that picking
the same colour again reuses the very same variable.  TEXT defaults to
the text of the clause at point."
  (let ((case-fold-search nil)
        (text (or text (cocolog--clause-text) ""))
        (res '()) (pos 0))
    (while (string-match cocolog-color-var-regexp text pos)
      (let ((end (match-end 0))
            (hex (concat "#" (downcase (match-string 1 text))))
            (token (match-string 0 text)))
        (setq pos end)
        (unless (assoc hex res) (push (cons hex token) res))))
    (nreverse res)))

(defun cocolog-clause-color-conflicts (&optional text)
  "Return the colours of TEXT that stand for more than one variable.
Each element is (HEX NAME...).  Two variables of the same colour are
told apart by their names, but they do look alike, so the mode points
them out."
  (let ((case-fold-search nil)
        (text (or text (cocolog--clause-text) ""))
        (seen '()) (pos 0))
    (while (string-match cocolog-color-var-regexp text pos)
      (let* ((end (match-end 0))
             (hex (concat "#" (downcase (match-string 1 text))))
             (label (match-string 2 text)))
        ;; `cocolog-color-display-name' runs a regexp, so the match data is
        ;; gone after this point: take END and the groups out first
        (setq pos end)
        (let* ((name (or label (cocolog-color-display-name hex)))
               (cell (assoc hex seen)))
          (if cell
              (unless (member name (cdr cell))
                (setcdr cell (append (cdr cell) (list name))))
            (push (list hex name) seen)))))
    (cl-remove-if-not (lambda (c) (cdr (cdr c))) (nreverse seen))))

(defun cocolog-clause-name-conflicts (&optional text)
  "Return the names TEXT uses both plainly and as a colour variable.
`Grandad\=' and `Ce6194b_Grandad\=' are two variables to Prolog and one
to the eye, which is worth saying out loud.  Typing makes no such pair;
pasted code can."
  (let ((case-fold-search nil)
        (text (or text (cocolog--clause-text) ""))
        (labels '()) (plain '()) (pos 0))
    (while (string-match cocolog-color-var-regexp text pos)
      (let ((end (match-end 0)) (label (match-string 2 text)))
        (setq pos end)
        (when label (cl-pushnew label labels :test #'equal))))
    (setq pos 0)
    (while (string-match "\\_<\\([A-Z][A-Za-z0-9_]*\\)\\_>" text pos)
      (let ((end (match-end 0)) (name (match-string 1 text)))
        (setq pos end)
        (unless (cocolog-color-var-p name)
          (cl-pushnew name plain :test #'equal))))
    (nreverse (cl-remove-if-not (lambda (l) (member l plain)) labels))))

(defun cocolog--variable-at-point ()
  "Return (NAME BEG . END) for the Prolog variable at point, or nil."
  (save-excursion
    (let ((case-fold-search nil)
          (p (point)))
      (skip-chars-backward "A-Za-z0-9_")
      (if (and (looking-at "\\_<\\([A-Z_][A-Za-z0-9_]*\\)\\_>")
               (>= (match-end 0) p))
          (cons (match-string-no-properties 1)
                (cons (match-beginning 0) (match-end 0)))
        nil))))

(defun cocolog--replace-in-region (from to beg end &optional comments)
  "Replace the whole-word variable FROM by TO between BEG and END.
Comments and quoted items are left alone unless COMMENTS says otherwise,
which is how a generated graph -- all comment, all goals -- is rewritten
along with the rule it belongs to.  Return the number of replacements."
  (let ((case-fold-search nil)
        (re (concat "\\_<" (regexp-quote from) "\\_>"))
        (stop (copy-marker end))
        (n 0))
    (save-excursion
      (goto-char beg)
      (while (re-search-forward re stop t)
        (when (or comments (not (nth 8 (cocolog--syntax (match-beginning 0)))))
          (replace-match to t t)
          (cl-incf n))))
    (set-marker stop nil)
    n))

(defun cocolog--test-case-regions (bounds)
  "Return the bounds of the test cases written beside the clause at BOUNDS.
A query is its own scope, but it is written by the same hand as the rule
and names the same variables on purpose, so renaming one renames the
other.  Only a comment block holding a `?-\=' counts; prose is left alone."
  (let ((regions '()))
    (save-excursion
      (dolist (probe (list (cons 'above (car bounds)) (cons 'below (cdr bounds))))
        (let* ((where (car probe))
               (pos (cdr probe))
               (text (if (eq where 'above)
                         (cocolog--comment-block-above pos)
                       (cocolog--comment-block-below pos))))
          (when (and text (string-match-p "\\?-" text))
            (goto-char pos)
            (if (eq where 'above)
                (push (cons (- pos (length text)) pos) regions)
              (let ((beg (progn (goto-char pos) (forward-line 1)
                                (line-beginning-position))))
                (push (cons beg (+ beg (length text))) regions)))))))
    regions))

(defun cocolog--clause-graph-regions (&optional pos)
  "Return the bounds of the graph blocks belonging to the clause at POS."
  (save-excursion
    (let* ((db (cocolog-buffer-db))
           (rec (cocolog-clause-at-point db (or pos (point))))
           (anchor (and rec (cocolog--graph-anchor db rec)))
           (regions '()))
      (when anchor
        (goto-char (cocolog-clause-end anchor))
        (forward-line 1)
        (let ((go t))
          (while go
            (cond
             ((eobp) (setq go nil))
             ((looking-at-p "[ \t]*$") (forward-line 1))
             ((looking-at-p cocolog--trace-begin-re)
              (let* ((beg (point)) (end (cocolog--trace-block-end)))
                (if (null end)
                    (setq go nil)
                  (push (cons beg end) regions)
                  (goto-char end))))
             ((looking-at-p "[ \t]*%") (forward-line 1))
             (t (setq go nil))))))
      (nreverse regions))))

(defun cocolog-refresh-clause-graphs (&optional pos)
  "Draw the graphs under the clause at POS again.
A graph names the variables of every clause of its predicate, so it
cannot be patched when one of them is recoloured: it is run again.
Nothing happens where there is no graph to begin with."
  (interactive)
  (let* ((db (cocolog-buffer-db))
         (rec (cocolog-clause-at-point db (or pos (point))))
         (queries (and rec (cocolog-clause-queries db rec))))
    (when (and queries (cocolog--clause-graph-regions
                        (and rec (cocolog-clause-start rec))))
      (cocolog--insert-graph (cocolog--graph-anchor db rec)
                             (cocolog--run-queries db queries) rec)
      t)))

(defvar-local cocolog--refresh-timer nil
  "Timer waiting to draw the graph of the clause last edited.")

(defvar cocolog--refreshing nil
  "Bound while a graph is being drawn, so that it does not ask for another.")

(defvar cocolog--refresh-idle-last 2.0
  "The wait `cocolog-toggle-refresh-idle\=' puts back when it turns it on.
Toggling off and on again keeps the wait the user chose rather than
quietly replacing it with the default.")

;;;###autoload
(defun cocolog-toggle-refresh-idle ()
  "Turn redrawing a graph after an edit on or off.
See `cocolog-refresh-idle\='.  Turning it off also drops a redraw that
was already waiting to happen, which is what makes it stop at once."
  (interactive)
  (if cocolog-refresh-idle
      (progn
        (setq cocolog--refresh-idle-last cocolog-refresh-idle
              cocolog-refresh-idle nil)
        (when (timerp cocolog--refresh-timer)
          (cancel-timer cocolog--refresh-timer)
          (setq cocolog--refresh-timer nil))
        (cocolog--menu-changed)
        (message "Graphs are left alone until you run them"))
    (setq cocolog-refresh-idle (or cocolog--refresh-idle-last 2.0))
    (cocolog--menu-changed)
    (message "Graphs are drawn again %s seconds after you stop typing"
             cocolog-refresh-idle)))

(defun cocolog--schedule-graph-refresh (&rest _)
  "Arrange for the graph of the clause at point to be drawn again, later.
Later, because this runs from `after-change-functions\=' and a rule is
not worth running in the middle of being typed."
  (when (and cocolog-refresh-idle (not cocolog--refreshing) (not undo-in-progress))
    (when (timerp cocolog--refresh-timer)
      (cancel-timer cocolog--refresh-timer))
    (let ((buffer (current-buffer))
          (where (copy-marker (point))))
      (setq cocolog--refresh-timer
            (run-with-idle-timer
             cocolog-refresh-idle nil
             (lambda ()
               (when (buffer-live-p buffer)
                 (with-current-buffer buffer
                   (setq cocolog--refresh-timer nil)
                   (cocolog-forget-pinned-colors)
                   (let ((cocolog--refreshing t))
                     ;; reading the buffer is the expensive part, so look
                     ;; for a graph to draw before doing any of it
                     (when (save-excursion
                             (goto-char (point-min))
                             (re-search-forward cocolog--trace-begin-re nil t))
                       ;; a clause that does not parse has no graph to draw,
                       ;; and an error here would be an error while typing
                       (ignore-errors
                         (save-excursion
                           (cocolog-refresh-clause-graphs
                            (marker-position where))))))
                   (set-marker where nil)))))))))

(defun cocolog--replace-in-clause (from to &optional bounds skip-graphs)
  "Replace the whole-word variable FROM by TO inside the clause at point.
Any graph written under that clause is run again afterwards, so a rule
and its execution graph never disagree about what a variable is called.
SKIP-GRAPHS leaves the graphs alone, for a caller that will refresh them
itself or does not want the delay.  BOUNDS, when given, says where the
clause is.  Return the number of replacements."
  (let ((bounds (or bounds (cocolog-clause-bounds-at-point)))
        (n 0))
    (unless bounds (user-error "Point is not inside a clause"))
    (cocolog-forget-pinned-colors)
    (setq n (cocolog--replace-in-region from to (car bounds) (cdr bounds)))
    ;; the test case beside the rule names the same variables on purpose
    (dolist (region (cocolog--test-case-regions bounds))
      (cl-incf n (cocolog--replace-in-region from to (car region) (cdr region) t)))
    (unless skip-graphs
      (save-excursion (cocolog-refresh-clause-graphs (car bounds))))
    n))

;;;; ------------------------------------------------------------------
;;;; Colour commands
;;;; ------------------------------------------------------------------

;;;; ------------------------------------------------------------------
;;;; Colouring a variable as it is typed
;;;; ------------------------------------------------------------------

(defun cocolog--next-clause-end (pos)
  "Return the position after the `.' that ends the clause starting at POS."
  (save-match-data
   (save-excursion
    (goto-char pos)
    (let ((res nil))
      (while (and (not res) (re-search-forward "\\.\\([ \t\n\r]\\|\\'\\)" nil t))
        (let ((dot (match-beginning 0)))
          ;; the search has eaten the whitespace after the period, so point
          ;; may already be on the next line: ask about the period's line
          (unless (or (save-excursion (goto-char dot) (cocolog--comment-line-p))
                      (nth 8 (cocolog--syntax dot)))
            (setq res (1+ dot)))))
      res))))

(defun cocolog--one-clause-p (beg end)
  "Non-nil when the buffer text between BEG and END is exactly one clause."
  (let ((text (buffer-substring-no-properties beg end)))
    (condition-case nil
        (let ((r (cocolog-read-term text)))
          (and r (>= (plist-get r :end) (length (string-trim-right text)))))
      (error nil))))

(defun cocolog--skip-graphs-forward (pos)
  "Return POS advanced past any graph blocks that begin there.
A clause begins after the period of the one before it, which leaves that
clause\='s graphs on this side of the line; they quote other rules and
their variables are not ours.  Ordinary comments are not skipped: the
test case above a rule belongs to it."
  (save-excursion
    (goto-char pos)
    (let ((go t))
      (while go
        (skip-chars-forward " \t\n")
        (beginning-of-line)
        (if (and (not (eobp)) (looking-at-p cocolog--trace-begin-re))
            (let ((block-end (cocolog--trace-block-end)))
              (if block-end (goto-char block-end) (setq go nil)))
          (setq go nil))))
    (point)))

(defun cocolog--typing-bounds (pos)
  "Return the bounds of the clause the text typed up to POS belongs to.
While a clause is still being written it has no terminating period yet,
and the next period in the buffer belongs to a later clause.  In that
case the region stops at POS, so that typing never rewrites a clause
further down the file."
  (let* ((beg (cocolog--skip-graphs-forward
               (or (cocolog--previous-clause-end pos) (point-min))))
         (end (cocolog--next-clause-end pos)))
    (cons beg (if (and end (cocolog--one-clause-p beg end)) end pos))))

(defun cocolog--auto-color-for (name text)
  "Return the colour NAME should have in a clause whose text is TEXT.
A name already used in that clause keeps its colour; a new one takes the
first colour of the palette that the clause does not use yet.  Return
nil when every colour is taken."
  (let* ((tokens (cocolog-clause-color-tokens text))
         (same (cl-find-if (lambda (c) (equal (cocolog-var-label (cdr c)) name))
                           tokens)))
    (if same
        (car same)
      (let* ((used (mapcar #'car tokens))
             (free (cl-remove-if (lambda (c) (member (downcase (cdr c)) used))
                                 cocolog-palette)))
        (cdr (car free))))))

(defun cocolog--token-with-label (label text)
  "Return the colour variable in TEXT that is called LABEL, or nil."
  (let ((case-fold-search nil) (pos 0) (found nil))
    (while (and (not found) (string-match cocolog-color-var-regexp text pos))
      (let ((end (match-end 0))
            (token (match-string 0 text))
            (name (match-string 2 text)))
        (setq pos end)
        (when (equal name label) (setq found token))))
    found))

(defun cocolog--variable-before (pos)
  "Return (NAME . BEGINNING) for the ordinary variable ending at POS, or nil."
  (let ((beg (save-excursion
               (goto-char pos)
               (skip-chars-backward "A-Za-z0-9_")
               (point)))
        (case-fold-search nil))
    (let ((name (buffer-substring-no-properties beg pos)))
      (when (and (> pos beg)
                 ;; an ordinary variable: a capital, then the usual characters
                 (string-match-p "\\`[A-Z][A-Za-z0-9_]*\\'" name)
                 (not (cocolog-color-var-p name))
                 ;; never inside a comment or a quoted item
                 (not (nth 8 (cocolog--syntax beg))))
        (cons name beg)))))

(defun cocolog--adopt-before (pos)
  "Make the variable ending at POS the one of that name the clause already has.
A clause that says `Ce6194b_Grandad\=' already has a variable called
Grandad; writing `Grandad\=' next to it would be a second variable that
reads exactly like the first, which is never what was meant.  Return the
text it was turned into, or nil."
  (let ((var (cocolog--variable-before pos)))
    (when var
      ;; the bounds are worked out from the end of the variable: the one
      ;; just written has to be inside the region that is rewritten
      (let* ((bounds (cocolog--typing-bounds pos))
             (text (buffer-substring-no-properties (car bounds) (cdr bounds)))
             (token (cocolog--token-with-label (car var) text)))
        (when token
          (cocolog--replace-in-clause (car var) token bounds t)
          token)))))

(defun cocolog--auto-color-before (pos)
  "Colour the ordinary variable that ends at POS, if there is one.
Return the new text of the variable, or nil when nothing was done."
  (let ((var (cocolog--variable-before pos)))
    (when var
      (let* ((bounds (cocolog--typing-bounds pos))
             (text (buffer-substring-no-properties (car bounds) (cdr bounds)))
             (hex (cocolog--auto-color-for (car var) text)))
        (when hex
          (let ((new (cocolog-color-to-var hex (car var))))
            (cocolog--replace-in-clause (car var) new bounds t)
            new))))))

(defun cocolog--post-self-insert ()
  "Deal with the variable just finished.
A variable is finished by the character typed after it, so this runs
only when that character cannot itself be part of a variable.  A name
the clause already knows is adopted whatever the settings -- that is
about what the clause means, not about how it looks -- and only then
does `cocolog-auto-color' write a colour for a new one."
  (when (and (characterp last-command-event)
             (> (point) (point-min))
             (not (string-match-p "[A-Za-z0-9_]"
                                  (char-to-string last-command-event))))
    ;; the marker point sits after the character just typed, and the
    ;; variable ends before it, so the replacement leaves point alone
    (save-excursion
      (let ((pos (1- (point))))
        (or (and cocolog-adopt-known-variables (cocolog--adopt-before pos))
            (and cocolog-auto-color (cocolog--auto-color-before pos)))))))

;;;###autoload
(defun cocolog--color-var-around (pos)
  "Return the bounds of the colour variable covering POS, or nil."
  (and pos (>= pos (point-min)) (<= pos (point-max))
       (cocolog--color-var-bounds pos)))

(defun cocolog--delete-active-region (n)
  "Delete the region the way plain backspace does, and say so, or return nil.
`delete-backward-char\=' and `delete-forward-char\=' both take a marked
region as what the user meant to delete, and `delete-active-region\='
says whether it is killed or thrown away.  The commands of this mode
stand in for those two, so they have to do the same thing: a mode whose
backspace quietly leaves a selection alone is a mode that eats work.
N is the repeat count: with one of those, backspace means characters."
  (when (and (use-region-p) delete-active-region (= n 1))
    (if (eq delete-active-region 'kill)
        (kill-region (region-beginning) (region-end))
      (funcall region-extract-function 'delete-only))
    t))

(defun cocolog--delete-variable (n killflag forward fallback)
  "Delete a colour variable whole, or do what FALLBACK would have done.
FORWARD says which side of point to look at.  N and KILLFLAG are the
argument and the kill flag of the key that was pressed, and FALLBACK is
the command this one stands in for, called with both -- so the key keeps
everything it does apart from the one case this mode is here for.

The whole variable goes only on a plain press: a region, or a count,
means the user is talking about text, not about a variable."
  (let* ((n (or n 1))
         (bounds (and (= n 1) (not (use-region-p))
                      (cocolog--color-var-around
                       (if forward (point) (max (point-min) (1- (point))))))))
    (cond
     ((cocolog--delete-active-region n))
     ((and bounds (= (if forward (car bounds) (cdr bounds)) (point)))
      (delete-region (car bounds) (cdr bounds))
      (save-excursion (cocolog-refresh-clause-graphs)))
     (t (funcall fallback n killflag)))))

;;;###autoload
(defun cocolog-delete-variable-backward (&optional n killflag)
  "Delete the colour variable before point in one go.
A colour variable is one thing, not a name with a colour spelled out
inside it, so the whole of it goes at once.  Anything else is deleted
the way backspace deletes it: a marked region, or N characters, with
KILLFLAG saying whether they are killed."
  (interactive "p\nP")
  (cocolog--delete-variable n killflag nil
                            (lambda (n killflag) (delete-char (- n) killflag))))

;;;###autoload
(defun cocolog-delete-variable-backward-untabify (&optional n killflag)
  "Delete the colour variable before point in one go, or untabify.
What `backward-delete-char-untabify\=' is to backspace, this is to
\\[cocolog-delete-variable-backward]: where there is no colour variable
to take whole, it turns a tab into spaces and deletes one of them, the
way `backward-delete-char-untabify-method\=' says."
  (interactive "p\nP")
  (cocolog--delete-variable n killflag nil #'backward-delete-char-untabify))

;;;###autoload
(defun cocolog-delete-variable-forward (&optional n killflag)
  "Delete the colour variable after point in one go.
See `cocolog-delete-variable-backward\='."
  (interactive "p\nP")
  (cocolog--delete-variable n killflag t
                            (lambda (n killflag) (delete-char n killflag))))

;; `delete-selection-mode' asks the command itself what to do with a live
;; region; without this it would leave ours alone, and the two ways of
;; deleting a selection would disagree
(put 'cocolog-delete-variable-backward 'delete-selection 'supersede)
(put 'cocolog-delete-variable-backward-untabify 'delete-selection 'supersede)
(put 'cocolog-delete-variable-forward 'delete-selection 'supersede)

;;;###autoload
(defun cocolog-toggle-auto-color ()
  "Turn colouring variables as you type them on or off.
See `cocolog-auto-color'."
  (interactive)
  (setq cocolog-auto-color (not cocolog-auto-color))
  (cocolog--menu-changed)
  (message (if cocolog-auto-color
               "Variables you type are coloured as you go"
             "Variables you type are left alone")))

;;;###autoload
(defun cocolog-insert-color-variable (&optional name-it)
  "Pick a colour and insert the variable that stands for it.

A variable is called after its colour -- crimson, gold -- until it is
given a name of its own.  Press `n\=' in the palette, or call this
command with a prefix argument NAME-IT, to name it right away; the name
is written after the colour, so `Ce6194b_Parent\=' is the crimson
variable called Parent.

Picking a colour that this clause already uses inserts that very
variable again, name included."
  (interactive "P")
  (let* ((used (cocolog-clause-color-usage))
         (tokens (cocolog-clause-color-tokens))
         (picked (cocolog-read-color "Colour for this variable" used))
         (hex (cocolog-picked-color picked)))
    (when hex
      (let* ((known (cdr (assoc hex tokens)))
             (label (or (cocolog-picked-label picked)
                        (and name-it (cocolog--read-label hex))))
             (token (cond
                     ;; the clause already has this colour: same variable
                     ((and known (null label)) known)
                     (t (cocolog-color-to-var hex label)))))
        (insert token)
        (save-excursion (cocolog-refresh-clause-graphs))
        (message "%s%s"
                 (cocolog--describe-variable token)
                 (let ((n (cdr (assoc hex used))))
                   (cond
                    ((and n known (equal token known))
                     (format "  -- the same variable as the %d other occurrence%s"
                             n (if (= n 1) "" "s")))
                    (n "  -- careful: this clause already uses that colour")
                    (t "  -- a new variable in this clause"))))))))

(defun cocolog--read-label (hex &optional current)
  "Read the name of a HEX coloured variable, CURRENT being its name now."
  (let* ((default (or current (cocolog-color-display-name hex)))
         (label (string-trim (read-string
                              (format "Name for this %s variable: "
                                      (cocolog-color-display-name hex))
                              nil nil default))))
    (cond
     ((string-empty-p label) nil)
     ((cocolog-valid-label-p label) label)
     (t (user-error "`%s\=' cannot be the name of a variable: %s"
                    label "a letter, then letters, digits or underscores")))))

(defun cocolog--describe-variable (token)
  "Return a short description of the colour variable TOKEN."
  (let ((hex (cocolog-var-to-color token)))
    (if (null hex)
        token
      (format "%s (%s %s)" (cocolog-var-display-name token)
              (cocolog-color-name hex) hex))))

(defcustom cocolog-dcg-snippets
  '(
    ("terminals"
     ("[<Item>]"   "one item, read from the list"
      "phrase(([X], [Y]), [a,b])"  "X = a, Y = b")
     ("\"<text>\"" "a run of characters, as codes"
      "phrase(\"ab\", \"ab\")"  "yes")
     ("[]"         "matches nothing and reads nothing"
      "phrase([], [])"  "yes"))
    ("control"
     ("{ <Goal> }"                    "a plain Prolog goal: it must hold, and reads nothing"
      "phrase(([X], { X > 2 }), [5])"  "X = 5")
     ("!"                             "no going back on what this rule has matched so far"
      "phrase((digits(D), !), \"12\")"  "D = [49, 50]")
     ("( <A> ; <B> )"                 "either one or the other"
      "phrase(( \"a\" ; \"b\" ), \"b\")"  "yes")
     ("( <Cond> -> <Then> ; <Else> )" "if the first matches, the second, else the third"
      "phrase(( \"a\" -> [X] ; [X] ), \"ab\")"  "X = 98")
     ("\\+ <Goal>"                    "the rest must not match this"
      "phrase((\\+ \"b\", [C]), \"a\")"  "C = 97"))
    ("text"
     ("blank"                            "one space, tab or newline"
      "phrase(blank, \" \")"  "yes")
     ("blanks"                           "any amount of white space, none included"
      "phrase(blanks, \"   \")"  "yes")
     ("white"                            "one space or tab, but not a newline"
      "phrase(white, \" \")"  "yes")
     ("whites"                           "spaces and tabs, none included"
      "phrase(whites, \"  \")"  "yes")
     ("nonblank(<C>)"                    "one character that is not white space"
      "phrase(nonblank(C), \"x\")"  "C = 120")
     ("nonblanks(<Cs>)"                  "characters up to the next white space"
      "phrase(nonblanks(Cs), \"ab\")"  "Cs = [97, 98]")
     ("eol"                              "the end of a line"
      "phrase(eol, [10])"  "yes")
     ("blanks_to_nl"                     "white space up to the end of the line"
      "phrase(blanks_to_nl, \"  \")"  "yes")
     ("string(<Cs>)"                     "any run of characters -- backtracks, shortest first"
      "phrase((string(A), \"-\", string(B)), \"ab-c\")"  "A = [97, 98], B = [99]")
     ("string_without(\"<Stop>\", <Cs>)" "characters up to one of the stop characters"
      "phrase((string_without(\"=\", K), \"=\", remainder(V)), \"a=b\")"  "K = [97], V = [98]"))
    ("numbers"
     ("digit(<C>)"    "one digit, as its character code"
      "phrase(digit(C), \"7\")"  "C = 55")
     ("digits(<Cs>)"  "a run of digits, as character codes"
      "phrase(digits(Cs), \"42\")"  "Cs = [52, 50]")
     ("integer(<N>)"  "an integer, sign and all, as a number"
      "phrase(integer(N), \"-42\")"  "N = -42")
     ("number(<N>)"   "an integer or a float, as a number"
      "phrase(number(N), \"3.5\")"  "N = 3.5")
     ("float(<F>)"    "a number that has a fraction"
      "phrase(float(F), \"2.75\")"  "F = 2.75")
     ("xdigit(<D>)"   "one hexadecimal digit, as its value 0..15"
      "phrase(xdigit(D), \"f\")"  "D = 15")
     ("xdigits(<Ds>)" "a run of hexadecimal digits, as values"
      "phrase(xdigits(Ds), \"1aF\")"  "Ds = [1, 10, 15]")
     ("xinteger(<N>)" "a hexadecimal number, as a number"
      "phrase(xinteger(N), \"ff\")"  "N = 255"))
    ("reading a token"
     ("nonblanks(<Cs>), { atom_codes(<Token>, <Cs>) }" "the next word, as a name"
      "phrase((nonblanks(Cs), { atom_codes(T, Cs) }), \"func\")"  "Cs = [102, 117, 110, 99], T = func")
     ("\"%\", string(_), ( eol ; eos )" "a remark, to the end of its line"
      "phrase((\"%\", string(_), ( eol ; eos )), \"%a remark\")"  "yes")
     ("blanks, <Rule>"           "white space first, then the rule"
      "phrase((blanks, nonblanks(Cs)), \"  ab\")"  "Cs = [97, 98]")
     ("( <A> ; <B> )"            "either one or the other -- `|\=' is a list bar, not this"
      "phrase(( \"a\" ; \"b\" ), \"b\")"  "yes"))
    ("names"
     ("csym(<Name>)"        "a name: a letter or underscore, then letters, digits, underscores"
      "phrase(csym(Name), \"hello_1\")"  "Name = hello_1")
     ("csyms(<Cs>)"         "letters, digits and underscores, as character codes"
      "phrase(csyms(Cs), \"ab1\")"  "Cs = [97, 98, 49]")
     ("alpha_to_lower(<L>)" "one letter, as its lower case code"
      "phrase(alpha_to_lower(L), \"Q\")"  "L = 113")
     ("atom(<A>)"           "writes an atom or number out as characters"
      "phrase(atom(hello), L)"  "L = [104, 101, 108, 108, 111]"))
    ("what is left"
     ("eos"               "the end of the list: nothing may remain"
      "phrase((digits(D), eos), \"12\")"  "D = [49, 50]")
     ("remainder(<Rest>)" "whatever is left, however much"
      "phrase((digits(D), remainder(Rest)), \"12ab\")"  "D = [49, 50], Rest = [97, 98]"))
    ("a whole rule"
     ("tokens(<Ts>) -->\n    blanks,\n    more_tokens(<Ts>).\n\nmore_tokens([]) --> eos, !.\nmore_tokens(<Ts>) -->\n    \"%\", string(_), ( eol ; eos ), !,\n    blanks,\n    more_tokens(<Ts>).\nmore_tokens([<Token>|<Ts>]) -->\n    nonblanks(<Cs>),\n    { <Cs> \\= [], atom_codes(<Token>, <Cs>) },\n    blanks,\n    more_tokens(<Ts>).\n"
      "a tokenizer: words, remarks, and the white space between them"
      "phrase(tokens(Ts), \"go on %r\\nlast\")"  "Ts = [go, on, last]"))
    ("running one"
     ("phrase(<Rule>, <List>)"         "Rule describes the whole of List"
      "phrase(digits(D), \"42\")"  "D = [52, 50]")
     ("phrase(<Rule>, <List>, <Rest>)" "Rule describes the front of List, Rest is left"
      "phrase(digits(D), \"4x\", Rest)"  "D = [52], Rest = [120]")))
  "The grammar half of what \\[cocolog-insert-goal] offers, by group.
Shaped like `cocolog-builtin-snippets\\=': the text to insert, a line
about it, and an example query with the answer the engine gives it."
  :type '(repeat (cons string (repeat (list string string string string))))
  :group 'cocolog)

(defconst cocolog--placeholder-regexp "<\\([A-Za-z][A-Za-z0-9_]*\\)>"
  "How a placeholder is written in a picker's pieces.
Only a name may stand between the brackets: `<\=' is also less-than, and
a looser pattern reads `<X> < <Y>\=' as one placeholder.")

(defcustom cocolog-builtin-snippets
  '(
    ("control"
     ("( <A> ; <B> )"                          "either one or the other"
      "( fail ; member(X, [a,b]) )"  "X = a ; X = b")
     ("( <Cond> -> <Then> ; <Else> )"          "if the first holds, the second, else the third"
      "( member(a, [a]) -> X = yes ; X = no )"  "X = yes")
     ("( <Cond> *-> <Then> ; <Else> )"         "the same, but every way the first holds counts"
      "( member(X, [a,b]) *-> true ; X = none )"  "X = a ; X = b")
     ("\\+ <Goal>"                             "the goal must not hold"
      "\\+ member(c, [a,b])"  "yes")
     ("!"                                      "no going back on the choices made so far"
      "member(X, [a,b]), !"  "X = a")
     ("true"                                   "holds, always"
      "true"  "yes")
     ("fail"                                   "never holds"
      "fail"  "no")
     ("call(<Goal>)"                           "call a goal held in a variable"
      "G = member(X, [a]), call(G)"  "G = member(a, [a]), X = a")
     ("call(<Goal>, <Arg>)"                    "call it with one more argument added"
      "call(member, X, [a])"  "X = a")
     ("[<X>]>><Goal>"                          "a goal with a name for its argument, to hand to maplist"
      "maplist([X]>>(X > 1), [2, 3])"  "yes")
     ("forall(<Cond>, <Action>)"               "no way of holding Cond breaks Action"
      "forall(member(X, [1,2]), X > 0)"  "yes")
     ("findall(<X>, <Goal>, <Xs>)"             "every X there is, gathered into a list"
      "findall(X, member(X, [a,b]), Xs)"  "Xs = [a, b]")
     ("aggregate_all(count, <Goal>, <N>)"      "how many ways the goal holds"
      "aggregate_all(count, member(_, [a,b,c]), N)"  "N = 3")
     ("aggregate_all(sum(<X>), <Goal>, <Sum>)" "the sum of X over every way it holds"
      "aggregate_all(sum(X), member(X, [1,2,3]), Sum)"  "Sum = 6")
     ("throw(<Ball>)"                          "give up, with something to say"
      "member(X, [a]), throw(sorry)"  "stops: sorry"))
    ("the same, or in order"
     ("<X> = <Y>"                  "make the two the same, if they can be"
      "f(X, b) = f(a, Y)"  "X = a, Y = b")
     ("<X> \\= <Y>"                "they cannot be made the same"
      "f(a) \\= f(b)"  "yes")
     ("<X> == <Y>"                 "already the very same term, nothing made equal"
      "X = a, X == a"  "X = a")
     ("<X> \\== <Y>"               "not the very same term"
      "X \\== a"  "yes")
     ("<X> @< <Y>"                 "before, in the standard order of terms"
      "1 @< a"  "yes")
     ("<X> @> <Y>"                 "after, in the standard order of terms"
      "f(b) @> f(a)"  "yes")
     ("compare(<Order>, <X>, <Y>)" "<, = or > for the two terms"
      "compare(Order, 1, a)"  "Order = (<)"))
    ("numbers"
     ("<X> is <Expr>"               "work the sum out and give it to X"
      "X is 3 * (2 + 5)"  "X = 21")
     ("<X> =:= <Y>"                 "the two sums come to the same"
      "2 + 2 =:= 4"  "yes")
     ("<X> =\\= <Y>"                "the two sums differ"
      "2 + 2 =\\= 5"  "yes")
     ("<X> < <Y>"                   "less than"
      "2 < 10"  "yes")
     ("<X> > <Y>"                   "greater than"
      "10 > 2"  "yes")
     ("<X> =< <Y>"                  "less than or equal -- written this way round"
      "2 =< 2"  "yes")
     ("<X> >= <Y>"                  "greater than or equal"
      "3 >= 2"  "yes")
     ("between(<Low>, <High>, <X>)" "every whole number from Low to High"
      "between(1, 3, X)"  "X = 1 ; X = 2 ; X = 3")
     ("succ(<X>, <Y>)"              "Y is one more than X, either way round"
      "succ(X, 4)"  "X = 3"))
    ("what kind of thing is it"
     ("var(<X>)"      "still unbound"
      "var(_)"  "yes")
     ("nonvar(<X>)"   "bound to something"
      "nonvar(hello)"  "yes")
     ("atom(<X>)"     "a name, like hello or []"
      "atom(hello)"  "yes")
     ("number(<X>)"   "a number of any kind"
      "number(3.5)"  "yes")
     ("integer(<X>)"  "a whole number"
      "integer(42)"  "yes")
     ("float(<X>)"    "a number with a fraction"
      "float(2.5)"  "yes")
     ("atomic(<X>)"   "a name or a number: nothing with parts"
      "atomic(42)"  "yes")
     ("compound(<X>)" "something with parts, like f(x) or [a]"
      "compound(f(a))"  "yes")
     ("callable(<X>)" "a name or a compound: something you could call"
      "callable(f(a))"  "yes")
     ("is_list(<X>)"  "a list, all the way to the end"
      "is_list([a,b])"  "yes")
     ("ground(<X>)"   "no unbound variable anywhere inside"
      "ground(f(a, _))"  "no"))
    ("taking terms apart"
     ("functor(<Term>, <Name>, <Arity>)" "the name and the number of parts"
      "functor(point(1,2), Name, Arity)"  "Name = point, Arity = 2")
     ("arg(<N>, <Term>, <Arg>)"          "the Nth part, counting from one"
      "arg(2, point(1,2), Arg)"  "Arg = 2")
     ("<Term> =.. <List>"                "the term as a list: name first, then its parts"
      "point(1,2) =.. L"  "L = [point, 1, 2]")
     ("copy_term(<Term>, <Copy>)"        "the same term with fresh variables"
      "copy_term(f(a, b), Copy)"  "Copy = f(a, b)"))
    ("lists"
     ("append(<A>, <B>, <AB>)"          "one list after the other -- also splits a list"
      "append([a], [b], L)"  "L = [a, b]")
     ("append(<Lists>, <All>)"          "a list of lists, run together"
      "append([[a], [b,c]], L)"  "L = [a, b, c]")
     ("member(<X>, <List>)"             "every member in turn"
      "member(X, [a,b])"  "X = a ; X = b")
     ("memberchk(<X>, <List>)"          "the first member that fits, and no more"
      "memberchk(X, [a,b])"  "X = a")
     ("length(<List>, <N>)"             "how long it is -- also makes a list of fresh variables"
      "length([a,b,c], N)"  "N = 3")
     ("nth0(<I>, <List>, <X>)"          "the Ith, counting from zero"
      "nth0(1, [a,b,c], X)"  "X = b")
     ("nth1(<I>, <List>, <X>)"          "the Ith, counting from one"
      "nth1(1, [a,b,c], X)"  "X = a")
     ("last(<List>, <X>)"               "the last one"
      "last([a,b,c], X)"  "X = c")
     ("reverse(<List>, <Back>)"         "the same list, back to front"
      "reverse([a,b,c], Back)"  "Back = [c, b, a]")
     ("select(<X>, <List>, <Rest>)"     "take one out, every way there is"
      "select(b, [a,b,c], Rest)"  "Rest = [a, c]")
     ("permutation(<List>, <P>)"        "every order the list could be in"
      "permutation([a,b], P)"  "P = [a, b] ; P = [b, a]")
     ("msort(<List>, <Sorted>)"         "sorted, keeping every copy"
      "msort([b,a,b], Sorted)"  "Sorted = [a, b, b]")
     ("sort(<List>, <Sorted>)"          "sorted, one of each"
      "sort([b,a,b], Sorted)"  "Sorted = [a, b]")
     ("numlist(<Low>, <High>, <List>)"  "the whole numbers from Low to High, as a list"
      "numlist(1, 4, L)"  "L = [1, 2, 3, 4]")
     ("sum_list(<List>, <Sum>)"         "everything added up"
      "sum_list([1,2,3], Sum)"  "Sum = 6")
     ("max_list(<List>, <Max>)"         "the largest number in it"
      "max_list([1,9,3], Max)"  "Max = 9")
     ("min_list(<List>, <Min>)"         "the smallest number in it"
      "min_list([4,1,3], Min)"  "Min = 1")
     ("maplist(<Goal>, <List>)"         "the goal holds of every member"
      "maplist(integer, [1,2])"  "yes")
     ("maplist(<Goal>, <Xs>, <Ys>)"     "the goal relates the two lists, member by member"
      "maplist([X,Y]>>(Y is X * 2), [1,2], Ys)"  "Ys = [2, 4]")
     ("include(<Goal>, <List>, <Kept>)" "the members the goal holds of"
      "include(integer, [a,1,b,2], Kept)"  "Kept = [1, 2]")
     ("exclude(<Goal>, <List>, <Left>)" "the members it does not"
      "exclude(integer, [a,1,b], Left)"  "Left = [a, b]"))
    ("names and text"
     ("atom_codes(<A>, <Codes>)"    "a name as a list of character codes, either way round"
      "atom_codes(ab, Codes)"  "Codes = [97, 98]")
     ("atom_length(<A>, <N>)"       "how many characters"
      "atom_length(hello, N)"  "N = 5")
     ("atom_number(<A>, <N>)"       "a name and the number it spells"
      "atom_number('42', N)"  "N = 42")
     ("atom_concat(<A>, <B>, <AB>)" "one name after the other -- also splits a name"
      "atom_concat(foo, bar, AB)"  "AB = foobar"))
    ("saying something"
     ("write(<X>)"   "write the term out"
      "write(f(a))"  "writes f(a)")
     ("writeln(<X>)" "write it, and start a new line"
      "writeln(hello)"  "writes hello⏎")
     ("print(<X>)"   "write it the way the graph would"
      "print([a,b])"  "writes [a, b]")
     ("nl"           "a new line"
      "write(a), nl, write(b)"  "writes a⏎b")
     ("tab(<N>)"     "N spaces"
      "write(a), tab(3), write(b)"  "writes a   b"))
    ("grammar rules"
     ("phrase(<Rule>, <List>)"         "the rule describes the whole of the list"
      "phrase(digits(D), \"42\")"  "D = [52, 50]")
     ("phrase(<Rule>, <List>, <Rest>)" "it describes the front; Rest is what is left"
      "phrase(digits(D), \"4x\", Rest)"  "D = [52], Rest = [120]")))
  "The goal half of what \\[cocolog-insert-goal] offers, by group.
Each piece is the text to insert, a line saying what it does, and an
example: a query, and the answer the engine gives it.  A placeholder is
written in angle brackets.

The examples are checked: a test runs every one of them and compares the
answer, so an example that has gone stale is a failing test rather than
a wrong line on the screen."
  :type '(repeat (cons string (repeat (list string string string string))))
  :group 'cocolog)

(defcustom cocolog-pick-columns 2
  "How many columns the picker lays its groups out in.
One list holds everything that can be written in a clause, which is a
long list; side by side, most of it is on the screen at once.  Set this
to 1 for one group under another, in a narrow window."
  :type 'integer :group 'cocolog)

(defcustom cocolog-torch-pick-columns 3
  "How many columns \\[cocolog-insert-torch-rule] lays its groups out in.
The torch list has three groups -- building a net, training, a trained
model -- and three columns put one group in each, so the whole surface
is one glance.  Set this to 1 in a narrow window."
  :type 'integer :group 'cocolog)

(defcustom cocolog-torch-snippets
  '(
    ("building a net"
     ("torch_seed(<N>)"
      "seed before building: the same numbers every run"
      "torch_seed(7)"  "yes -- and the whole run repeats exactly")
     ("model_new([input(<In>), dense(<H>, relu), dense(<Out>)], <M>)"
      "a fresh network from its layer list, handle out"
      "model_new([input(16), dense(32, relu), dense(4)], M)"
      "M = a handle -- 24-q-learning's net")
     ("model_new([image(<C>, <H>, <W>), conv(<F>, <K>, relu), pool(2), flatten, dense(<Out>, log_softmax)], <M>)"
      "a small CNN: channels through convolution to a class head"
      "model_new([image(1, 8, 8), conv(4, 3, relu), pool(2), flatten, dense(2, log_softmax)], M)"
      "M = a handle -- 17-cnn-bars's net")
     ("model_new([sequence(<L>), embedding(<V>, <D>), lstm(<H>), dense(<Out>, log_softmax)], <M>)"
      "token ids through a learned embedding into an lstm"
      "model_new([sequence(6), embedding(8, 4), lstm(16), dense(2, log_softmax)], M)"
      "M = a handle -- 22-embedding-lstm's net")
     ("tensor_from_list(<Rows>, <T>)"
      "a tensor from nested lists, one row per example"
      "tensor_from_list([[0.0, 0.0], [0.0, 1.0]], X)"
      "X = a tensor handle")
     ("tensor_to_list(<T>, <Rows>)"
      "and back to lists, for reading answers with forall"
      "model_predict(M, X, P), tensor_to_list(P, Out)"
      "Out = a row of outputs per row of X")
     ("torch_device(<D>)"
      "cpu, cuda or cuda(N); absent hardware refuses, never falls back"
      "torch_device(cuda)"
      "throws domain_error(cuda_available, ...) without a GPU"))
    ("training"
     ("model_train(<M>, <X>, <Y>, [epochs(<E>), batch(<B>), lr(<R>), optimiser(adam)])"
      "fit the model to X -> Y; the loss is mse unless told otherwise"
      "model_train(M, X, Y, [epochs(40), batch(14), lr(0.01), optimiser(adam)])"
      "yes -- 24-q-learning's Bellman regression")
     ("model_train(<M>, <X>, <Y>, [epochs(<E>), batch(<B>), lr(<R>), optimiser(adam), loss(nll), final_loss(<L>)])"
      "the classification pairing: integer labels against log_softmax, last loss out"
      "model_train(M, X, Y, [epochs(200), batch(16), lr(0.02), optimiser(adam), loss(nll), final_loss(L)])"
      "L = 0.0117 -- 22-embedding-lstm's run")
     ("schedule(step, <Every>, <Gamma>)"
      "inside the options: scale the learning rate by Gamma every Every epochs"
      "model_train(M, X, Y, [epochs(1500), batch(32), lr(0.1), optimiser(sgd), schedule(step, 400, 0.5), final_loss(L)])"
      "L = the last mse under the decayed rate -- 12-lr-schedule")
     ("model_evaluate(<M>, <X>, <Y>, <Metric>, <Score>)"
      "score a model: rmse, accuracy or mae"
      "model_evaluate(M, X, Y, accuracy, A)"
      "A = 1.0 -- 07-xor's four clean corners"))
    ("a trained model"
     ("model_predict(<M>, <X>, <P>)"
      "run the net forward: a row of outputs per row of X"
      "model_predict(M, X, P)"
      "P = a tensor -- 22's predict reads [3,0,0,0,0,0] -> contains token 3")
     ("model_save(<Name>, <M>)"
      "assert the model as terms; the knowledge base keeps it like any fact"
      "model_save(t07_xor, M)"
      "yes -- and any process can load it")
     ("model_load(<Name>, <M>)"
      "a model back from the store, in a process that trained nothing"
      "model_load(t07_xor, M)"
      "M = a fresh handle over the stored params")
     ("train :-\n    torch_seed(<N>),\n    tensor_from_list(<Rows>, X), tensor_from_list(<Labels>, Y),\n    model_new([input(<In>), dense(<H>, relu), dense(<Out>, log_softmax)], M),\n    model_train(M, X, Y, [epochs(<E>), batch(<B>), lr(<R>), optimiser(adam),\n                          loss(nll), final_loss(L)]),\n    format(\"trained: final nll ~4f~n\", [L]),\n    model_save(<Name>, M),\n    write(saved), nl.\n\ntest :-\n    model_load(<Name>, M),\n    tensor_from_list(<Rows>, X), tensor_from_list(<Labels>, Y),\n    model_evaluate(M, X, Y, accuracy, A),\n    ( A >= 0.95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).\n\npredict :-\n    model_load(<Name>, M),\n    tensor_from_list(<Rows>, X),\n    model_predict(M, X, P),\n    tensor_to_list(P, Out),\n    forall(nth0(I, Out, Row), format(\"~w -> ~w~n\", [I, Row])).\n"
      "a whole tutorial: train, test and predict, three goals for three processes"
      "train"
      "trained: final nll 0.0000 then saved -- 07-xor's own shape")))
  "The torch rules \\[cocolog-insert-torch-rule] offers, by group.
Shaped like `cocolog-builtin-snippets\\=': the text to insert, a line
about it, and an example with what it says.  The examples are lines of
tutorials/ in the cocolog repository, proven by its tutorials suite
under cocolog-full -- the engine of this mode traces no tensors, so
unlike the other two tables these examples are not run by the engine's
own tests.  Consulting and proving them is the cocolog binary's job,
which `make coco\\=' holds it to for everything the engine can answer."
  :type '(repeat (cons string (repeat (list string string string string))))
  :group 'cocolog)

(defun cocolog-goal-snippets ()
  "The two lists as one: what a goal is written out of, then a grammar rule.
The grammar groups keep a heading of their own, since `atom(A)\=' in a
rule writes a name out where `atom(X)\=' in a goal asks whether it is
one, and the two must not read as the same line twice.  A piece that
appears in both lists -- `phrase/2\=' does -- is kept once."
  (let ((seen '()))
    (mapcar
     (lambda (group)
       (cons (car group)
             (cl-remove-if (lambda (entry)
                             (if (member (nth 0 entry) seen) t
                               (push (nth 0 entry) seen) nil))
                           (cdr group))))
     (append cocolog-builtin-snippets
             (mapcar (lambda (group)
                       (cons (concat "grammar: " (car group)) (cdr group)))
                     cocolog-dcg-snippets)))))

(defun cocolog--pick-first-of-group (rows match)
  "Return the index of the first row of the first group matching MATCH."
  (or (cl-position-if (lambda (row) (string-match-p match (nth 2 row))) rows) 0))

;;;###autoload
(defun cocolog-insert-goal (&optional half)
  "Insert a goal, picked from a list grouped by what each thing is for.
One list holds the lot: what an ordinary goal is written out of --
unifying, arithmetic, the type tests, taking terms apart, the list
predicates, findall and friends -- and, under headings of their own, the
pieces a grammar rule is made of.

HALF says which end to open on: `grammar\=' for the grammar groups,
`goal\=' for the rest.  Called with no argument it decides by where
point is, so writing a rule with `-->\=' in it opens on the grammar and
anything else opens on the goals.  With a prefix argument, it opens on
the other half from the one it would have chosen.

Where the piece has a placeholder, the region is left over it, so the
name you want can simply be typed."
  (interactive (list (if current-prefix-arg
                         (if (cocolog--in-grammar-rule-p) 'goal 'grammar)
                       nil)))
  (let* ((half (or half (if (cocolog--in-grammar-rule-p) 'grammar 'goal)))
         (groups (cocolog-goal-snippets))
         (rows (cocolog--pick-rows groups))
         (start (if (eq half 'grammar)
                    (cocolog--pick-first-of-group rows "\\`grammar: ")
                  0))
         (pick (cocolog-read-snippet groups "Insert a goal" "Goal"
                                     "*cocolog goals*" start)))
    (when (and pick (not (string-empty-p pick)))
      (cocolog--insert-snippet pick))))

(defun cocolog--in-grammar-rule-p ()
  "Non-nil when point is in a clause written with `-->\='."
  (save-match-data
    (let* ((bounds (ignore-errors (cocolog--typing-bounds (point))))
           (text (and bounds (buffer-substring-no-properties
                              (car bounds) (min (point) (cdr bounds))))))
      (and text (string-match-p "-->" text)))))

;;;###autoload
(defun cocolog-insert-builtin ()
  "Open the picker on the goals: see \\[cocolog-insert-goal]."
  (interactive)
  (cocolog-insert-goal 'goal))

;;;###autoload
(defun cocolog-insert-dcg-item ()
  "Open the picker on the pieces of a grammar rule: see \\[cocolog-insert-goal]."
  (interactive)
  (cocolog-insert-goal 'grammar))

;;;###autoload
(defun cocolog-insert-torch-rule ()
  "Insert one of the torch rules a training program is written out of.
The three groups -- building a net, training, a trained model -- sit
side by side, one column each (`cocolog-torch-pick-columns\\='), so the
whole surface is one glance.  The pieces and their examples are the
shapes of tutorials/ in the cocolog repository; they run under
cocolog-full, which carries the torch module -- the engine of this mode
traces no tensors.

Where the piece has a placeholder, the region is left over it, so the
name you want can simply be typed."
  (interactive)
  (let* ((cocolog-pick-columns cocolog-torch-pick-columns)
         (pick (cocolog-read-snippet cocolog-torch-snippets
                                     "Insert a torch rule" "Torch rule"
                                     "*cocolog torch*")))
    (when (and pick (not (string-empty-p pick)))
      (cocolog--insert-snippet pick))))

(defun cocolog--pick-rows (groups)
  "Return GROUPS -- a table shaped like `cocolog-dcg-snippets\=' -- flattened
into a list of (TEXT DOC GROUP).  The order of the table is kept, groups
and all, so the picker shows the headings in the order they are written."
  (apply #'append
         (mapcar (lambda (group)
                   (mapcar (lambda (entry)
                             ;; TEXT DOC GROUP QUERY ANSWER
                             (list (nth 0 entry) (nth 1 entry) (car group)
                                   (nth 2 entry) (nth 3 entry)))
                           (cdr group)))
                 groups)))

(defun cocolog--pick-plain (text)
  "Return TEXT as it will be inserted: without the placeholder brackets."
  (replace-regexp-in-string cocolog--placeholder-regexp "\\1" text))

(defun cocolog--pick-oneline (text)
  "Return TEXT as one line, for a picker that has one line per piece.
A piece can be a whole rule -- several clauses of it -- and what the
grid shows of that is its first line and a mark to say there is more."
  (let* ((plain (cocolog--pick-plain text))
         (first (car (split-string plain "\n"))))
    (if (string-match-p "\n[ \t]*[^ \t\n]" plain)
        (concat first " " (cocolog-glyph "…" "..."))
      first)))

(defvar cocolog--pick-index 0
  "Which row the picker is standing on, while it is open.")

(defvar cocolog--pick-shown nil
  "The layout the picker last drew, so that moving follows what is on screen.")

(defvar cocolog--pick-last nil
  "Where each picker was left, as an alist of TITLE to row.
Opening the same list again starts where it was left, which is nearly
always the piece next to the one wanted.")

(defun cocolog--pick-blocks (rows)
  "Return ROWS as a list of blocks, one per group: (GROUP INDEX...)."
  (let ((blocks '()) (i 0))
    (dolist (row rows)
      (if (and blocks (equal (car (car blocks)) (nth 2 row)))
          (setcdr (car blocks) (append (cdr (car blocks)) (list i)))
        (push (list (nth 2 row) i) blocks))
      (setq i (1+ i)))
    (nreverse blocks)))

(defun cocolog--pick-packs-p (heights columns limit)
  "Non-nil when blocks of HEIGHTS fit in COLUMNS columns of LIMIT lines each.
The blocks keep their order: a picker whose groups moved about between
one opening and the next would be no use at all."
  (let ((used 0) (need 1) (ok t))
    (dolist (h heights ok)
      (cond ((> h limit) (setq ok nil))
            ((<= (+ used h) limit) (setq used (+ used h)))
            (t (setq need (1+ need) used h)
               (when (> need columns) (setq ok nil)))))))

(defun cocolog--pick-layout (rows &optional columns)
  "Lay the groups of ROWS out in COLUMNS columns.
Return a list of columns, each a list of lines: (heading . GROUP),
\(row . INDEX), or nil for the gap between two groups.  Groups are kept
whole -- one never straddles two columns -- and the shortest column
length that still fits is used, so the columns come out even."
  (let* ((blocks (cocolog--pick-blocks rows))
         (columns (max 1 (or columns cocolog-pick-columns)))
         (heights (mapcar (lambda (b) (+ 2 (length (cdr b)))) blocks))
         (total (apply #'+ 0 heights))
         (limit total)
         (out '()) (this '()) (used 0))
    ;; the shortest column that still holds every group, found by halving
    (let ((low (apply #'max 1 heights)) (high total))
      (while (< low high)
        (let ((mid (/ (+ low high) 2)))
          (if (cocolog--pick-packs-p heights columns mid)
              (setq high mid)
            (setq low (1+ mid)))))
      (setq limit low))
    (cl-loop for block in blocks
             for height in heights
             do (when (and this (> (+ used height) limit))
                  (push (nreverse this) out)
                  (setq this '() used 0))
                (when this (push nil this))
                (push (cons 'heading (car block)) this)
                (dolist (i (cdr block)) (push (cons 'row i) this))
                (setq used (+ used height)))
    (when this (push (nreverse this) out))
    (nreverse out)))

(defun cocolog--pick-cell (rows line width selected)
  "Return the text of LINE -- a cell of the layout -- WIDTH columns wide."
  (pcase line
    (`(heading . ,group)
     (propertize (concat " " group) 'face 'font-lock-keyword-face))
    (`(row . ,i)
     (let ((text (cocolog--pick-oneline (nth 0 (nth i rows)))))
       (propertize (concat "  " (if selected (cocolog-glyph "▸" ">") " ") " "
                           (truncate-string-to-width text (max 4 (- width 5))))
                   'face (if selected 'highlight 'default)
                   'cocolog-pick-index i
                   'mouse-face 'highlight
                   'help-echo (nth 1 (nth i rows)))))
    (_ "")))

(defun cocolog--pick-widths (layout rows)
  "Return how wide each column of LAYOUT has to be to hold its pieces."
  (mapcar (lambda (column)
            (+ 6 (apply #'max 8
                        (mapcar (lambda (line)
                                  (pcase line
                                    (`(heading . ,g) (length g))
                                    (`(row . ,i)
                                     (length (cocolog--pick-oneline (nth 0 (nth i rows)))))
                                    (_ 0)))
                                column))))
          layout))

(defun cocolog--pick-fit (rows width)
  "Return a layout of ROWS as wide as WIDTH allows, and no wider.
`cocolog-pick-columns\=' says how many columns to aim for; a window too
narrow for that many gets fewer rather than pieces cut in half."
  (let ((want (max 1 cocolog-pick-columns)) (layout nil))
    (while (and (> want 1)
                (progn (setq layout (cocolog--pick-layout rows want))
                       (> (apply #'+ 0 (cocolog--pick-widths layout rows)) width)))
      (setq want (1- want) layout nil))
    (or layout (cocolog--pick-layout rows want))))

(defconst cocolog--pick-keys
  "↑/↓ move   ←/→ column   TAB next group   / by name   RET insert   q cancel"
  "The keys of the picker, shown in its mode line.")

(defun cocolog--pick-header (rows)
  "What the piece the cursor is on is, as a line.
It goes in a line of the window rather than in the buffer so that it
stays in sight: the list is longer than the window, and a line drawn at
the top of the buffer is the first thing to scroll away."
  (let ((row (nth cocolog--pick-index rows)))
    (concat " " (propertize (cocolog--pick-oneline (nth 0 row))
                            'face 'font-lock-function-name-face)
            "   " (propertize (nth 1 row) 'face 'font-lock-doc-face))))

(defun cocolog--pick-example (rows)
  "The example of the piece the cursor is on: a query, and its answer.
Reading what a thing does is one thing; seeing it run is another, so the
picker carries a worked example for every piece it offers."
  (let* ((row (nth cocolog--pick-index rows))
         (query (nth 3 row))
         (answer (nth 4 row)))
    (if (null query)
        ""
      (concat " " (propertize (concat "?- " query ".") 'face 'font-lock-string-face)
              "   " (propertize (cocolog-glyph "⇒" "=>") 'face 'shadow)
              " " (propertize answer 'face 'font-lock-constant-face)))))

(defun cocolog--pick-mode-line (title)
  "What the picker shows in its mode line: TITLE, and the keys."
  (concat " " (propertize title 'face 'bold) "    "
          (propertize cocolog--pick-keys 'face 'shadow)))

(defun cocolog--pick-render (buffer rows title &optional columns)
  "Draw ROWS into BUFFER under TITLE, grouped, in COLUMNS columns.
The piece the cursor is on, and the line about it, go in the header
line, and the keys in the mode line, so that neither scrolls out of
sight when the list is longer than the window.  Return the position of
that piece, so the window can be scrolled to it."
  (with-current-buffer buffer
    (let* ((inhibit-read-only t)
           (layout (if columns
                       (cocolog--pick-layout rows columns)
                     (cocolog--pick-fit
                      rows (let ((window (get-buffer-window buffer)))
                             (if window (window-body-width window) (frame-width))))))
           (widths (cocolog--pick-widths layout rows))
           (deep (apply #'max 0 (mapcar #'length layout)))
           (here nil))
      (erase-buffer)
      (dotimes (line deep)
        (let ((at 0) (c 0))
          (dolist (column layout)
            (let* ((cell (nth line column))
                   (selected (equal cell (cons 'row cocolog--pick-index))))
              (when selected (setq here (point)))
              (insert (cocolog--pick-cell rows cell (nth c widths) selected))
              (setq at (+ at (nth c widths)))
              (when (< (1+ c) (length layout))
                (insert (propertize " " 'display (list 'space :align-to at))))
              (setq c (1+ c)))))
        (insert "\n"))
      (setq cocolog--pick-shown layout)
      ;; `%\=' means something of its own in these two, and a piece could
      ;; hold one
      ;; three lines that do not scroll: what the piece is, an example of it
      ;; running, and the keys.  `%\=' means something of its own in all
      ;; three, and a piece or an answer could hold one
      (let ((quoted (lambda (text) (replace-regexp-in-string "%" "%%" text t t))))
        (when (boundp 'tab-line-format)
          (setq tab-line-format (funcall quoted (cocolog--pick-header rows))))
        (setq header-line-format
              (funcall quoted (if (boundp 'tab-line-format)
                                  (cocolog--pick-example rows)
                                ;; nowhere to put both: the line about the
                                ;; piece is the one that must be there
                                (concat (cocolog--pick-header rows) "   "
                                        (cocolog--pick-example rows)))))
        (setq mode-line-format (funcall quoted (cocolog--pick-mode-line title))))
      (setq-local display-line-numbers nil)
      (setq-local truncate-lines t)
      (goto-char (or here (point-min)))
      (set-buffer-modified-p nil)
      (or here (point-min)))))

(defun cocolog--pick-group-step (rows step)
  "Return the index of the first piece of the group STEP groups away."
  (let* ((groups (delete-dups (mapcar (lambda (r) (nth 2 r)) rows)))
         (here (nth 2 (nth cocolog--pick-index rows)))
         (at (or (cl-position here groups :test #'equal) 0))
         (want (nth (mod (+ at step) (length groups)) groups)))
    (or (cl-position want rows :test #'equal :key (lambda (r) (nth 2 r))) 0)))

(defun cocolog--pick-current-layout (rows)
  "The layout the picker is showing, or a fresh one when it is not open."
  (or cocolog--pick-shown (cocolog--pick-fit rows (frame-width))))

(defun cocolog--pick-where (layout index)
  "Return (COLUMN . LINE) of the row INDEX in LAYOUT, or nil."
  (let ((c 0) (found nil))
    (dolist (column layout found)
      (let ((line (cl-position (cons 'row index) column :test #'equal)))
        (when line (setq found (cons c line))))
      (setq c (1+ c)))))

(defun cocolog--pick-nearest (column line)
  "Return the row of COLUMN nearest LINE, or nil when it holds none."
  (let ((best nil) (distance nil) (l 0))
    (dolist (cell column best)
      (when (eq (car-safe cell) 'row)
        (let ((d (abs (- l line))))
          (when (or (null distance) (< d distance))
            (setq best (cdr cell) distance d))))
      (setq l (1+ l)))))

(defun cocolog--pick-vertical (rows step)
  "Return the row STEP rows down its own column from the one point is on.
The column is walked round, so going down from its last piece comes back
to its first: no move ever leaves the group of columns."
  (let* ((layout (cocolog--pick-current-layout rows))
         (at (cocolog--pick-where layout cocolog--pick-index)))
    (if (null at)
        (mod (+ cocolog--pick-index step) (length rows))
      (let* ((column (nth (car at) layout))
             (here (cl-remove-if-not (lambda (c) (eq (car-safe c) 'row)) column))
             (n (length here))
             (i (cl-position (cons 'row cocolog--pick-index) here :test #'equal)))
        (cdr (nth (mod (+ i step) n) here))))))

(defun cocolog--pick-horizontal (rows step)
  "Return the row nearest across, STEP columns over from the one point is on."
  (let* ((layout (cocolog--pick-current-layout rows))
         (at (cocolog--pick-where layout cocolog--pick-index)))
    (if (or (null at) (< (length layout) 2))
        cocolog--pick-index
      (or (cocolog--pick-nearest
           (nth (mod (+ (car at) step) (length layout)) layout)
           (cdr at))
          cocolog--pick-index))))

(defun cocolog--pick-action (event rows)
  "What EVENT means in the picker standing on `cocolog--pick-index\='.
Return (move . INDEX), (pick . TEXT), `ask\=', `cancel\=', or nil for a
key the picker does not use.  ROWS is the list the picker is showing."
  (let ((n (length rows)))
    (pcase event
      ((or 'down ?j ?n ?\C-n) (cons 'move (cocolog--pick-vertical rows 1)))
      ((or 'up ?k ?p ?\C-p) (cons 'move (cocolog--pick-vertical rows -1)))
      ((or 'right ?l ?\C-f) (cons 'move (cocolog--pick-horizontal rows 1)))
      ((or 'left ?h ?\C-b) (cons 'move (cocolog--pick-horizontal rows -1)))
      ((or ?\t 'M-right) (cons 'move (cocolog--pick-group-step rows 1)))
      ((or 'backtab 'M-left) (cons 'move (cocolog--pick-group-step rows -1)))
      ('home (cons 'move 0))
      ('end (cons 'move (1- n)))
      ((or 'next ?\C-v) (cons 'move (cocolog--pick-vertical rows 10)))
      ((or 'prior ?\M-v) (cons 'move (cocolog--pick-vertical rows -10)))
      (?/ 'ask)
      ((or ?\r ?\s) (cons 'pick (nth 0 (nth cocolog--pick-index rows))))
      ((or ?q ?\e ?\C-g) 'cancel)
      (_ nil))))

(defun cocolog--pick-mouse-action (event rows buffer)
  "What a mouse EVENT over BUFFER means in the grammar picker.
The first click moves to the piece under the pointer, a second one on
the same piece takes it, the way the palette behaves."
  (let* ((pos (event-start event))
         (p (posn-point pos)))
    (when (and p (eq (window-buffer (posn-window pos)) buffer))
      (let ((i (get-text-property p 'cocolog-pick-index buffer)))
        (when i
          (if (eq i cocolog--pick-index)
              (cons 'pick (nth 0 (nth i rows)))
            (cons 'move i)))))))

(defun cocolog-read-snippet (groups title prompt buffer-name &optional start)
  "Let the user pick from GROUPS, shown under a heading for each group.
GROUPS is a table shaped like `cocolog-dcg-snippets\='.  TITLE heads the
window, PROMPT names the thing being picked, and BUFFER-NAME is the
buffer to draw in.  START is the row to open on; without one the picker
opens where it was last left.  Return the text of the piece,
placeholders and all, or nil.

Off a display -- in batch, or with no window -- the same list is offered
in the minibuffer, still grouped, for a completion frontend that shows
`group-function\=' headings."
  (let ((rows (cocolog--pick-rows groups)))
    (if (or noninteractive (not (display-graphic-p)))
        (cocolog--pick-in-minibuffer rows prompt)
      (let* ((buffer (get-buffer-create buffer-name))
             (cocolog--pick-index
              (min (or start (cdr (assoc title cocolog--pick-last)) 0)
                   (1- (length rows))))
             (lines (+ 2 (apply #'max 0 (mapcar #'length
                                                (cocolog--pick-layout rows)))))
             (window nil) (result nil) (done nil))
        (unwind-protect
            (progn
              (with-current-buffer buffer
                (setq buffer-read-only t cursor-type nil))
              (setq window (display-buffer-at-bottom
                            buffer `((window-height
                                      . ,(min lines (max 12 (/ (frame-height) 2)))))))
              (while (not done)
                (let ((here (cocolog--pick-render buffer rows title)))
                  (when (window-live-p window)
                    (set-window-point window here)
                    (unless (pos-visible-in-window-p here window)
                      (with-selected-window window (recenter)))))
                (let* ((event (read-key
                               (format "%s: %s" prompt
                                       (cocolog--pick-oneline
                                        (nth 0 (nth cocolog--pick-index rows))))))
                       (act (if (consp event)
                                (cocolog--pick-mouse-action event rows buffer)
                              (cocolog--pick-action event rows))))
                  (pcase act
                    (`(move . ,i) (setq cocolog--pick-index i))
                    (`(pick . ,text) (setq result text done t))
                    ('ask (let ((pick (cocolog--pick-in-minibuffer rows prompt)))
                            (when pick (setq result pick done t))))
                    ('cancel (setq done t))
                    (_ nil)))))
          (setf (alist-get title cocolog--pick-last nil nil #'equal)
                cocolog--pick-index)
          (when (window-live-p window) (quit-window nil window))
          (kill-buffer buffer))
        result))))

(defun cocolog--pick-in-minibuffer (rows prompt)
  "Read one of ROWS in the minibuffer, grouped as the picker groups them.
PROMPT names the thing being picked."
  (let* ((width (apply #'max 8 (mapcar (lambda (r) (length (nth 0 r))) rows)))
         (table (lambda (string predicate action)
                  (if (eq action 'metadata)
                      `(metadata
                        (group-function
                         . ,(lambda (candidate transform)
                              (if transform candidate
                                (nth 2 (assoc candidate rows)))))
                        (annotation-function
                         . ,(lambda (candidate)
                              (let ((row (assoc candidate rows)))
                                (when row
                                  (concat (make-string
                                           (max 1 (- width (length candidate) -2)) ?\s)
                                          (propertize (nth 1 row)
                                                      'face 'font-lock-doc-face)))))))
                    (complete-with-action action (mapcar #'car rows) string predicate))))
         (pick (completing-read (format "%s: " prompt) table nil t)))
    (and pick (not (string-empty-p pick)) pick)))

(defun cocolog--insert-snippet (text)
  "Insert TEXT, leaving the region over its first <placeholder>."
  (let ((start (point))
        (mark nil) (end nil))
    (insert (replace-regexp-in-string cocolog--placeholder-regexp "\\1" text))
    (save-excursion
      (goto-char start)
      (save-match-data
        (when (string-match cocolog--placeholder-regexp text)
          (let* ((before (replace-regexp-in-string
                          cocolog--placeholder-regexp "\\1"
                          (substring text 0 (match-beginning 0))))
                 (word (match-string 1 text)))
            (setq mark (+ start (length before))
                  end (+ mark (length word)))))))
    (when mark
      (goto-char mark)
      (push-mark end t t))))

;;;###autoload
(defun cocolog-insert-clause-variable ()
  "Insert one of the variables this clause already has.

The palette offers every colour there is; this offers only what the
clause is already talking about, in the order the clause writes them,
and offers them the way they are read: as a row of swatches to pick
from, not as a list of names.  Every
variable of the clause is there, with the colour it is shown in --
including a plain one, whose colour the mode deals rather than the file.

It is the only way to write an unnamed colour variable a second time
without hunting through the palette: it has no name to type, so there is
nothing for `cocolog-adopt-known-variables\=' to recognise."
  (interactive)
  (let* ((case-fold-search nil)
         ;; the clause is usually half written when this is wanted.  The
         ;; database would then read it together with the rule below --
         ;; one clause, as far as the reader can tell -- and offer that
         ;; rule's variables; these bounds stop at point instead.
         (bounds (cocolog--typing-bounds (point)))
         (text (if bounds
                   (buffer-substring-no-properties (car bounds) (cdr bounds))
                 ""))
         (found '())
         (pos 0))
    ;; one walk, so that the variables come out in the order they are
    ;; written: a colour variable and an ordinary one are both variables
    ;; of this clause, and grouping them by kind puts them out of order
    (while (string-match "\\_<\\([A-Z][A-Za-z0-9_]*\\)\\_>" text pos)
      (let ((end (match-end 0)) (token (match-string 1 text)))
        (setq pos end)
        (unless (member token found) (push token found))))
    (let ((choices (nreverse found)))
      (unless choices
        (user-error "This clause has no variables yet -- %s inserts one"
                    (substitute-command-keys "\\[cocolog-insert-color-variable]")))
      ;; every variable of the clause has a colour on screen, whether the
      ;; file says so or not, so they can be chosen the way they are read:
      ;; by colour, out of the same grid the palette uses
      (let* ((entries
              (mapcar (lambda (token)
                        (let ((hex (or (cocolog-var-to-color token)
                                       (cdr (assoc token
                                                   (cocolog--plain-colors-at (point)))))))
                          (list (or (cocolog-var-label token)
                                    (and (cocolog-var-to-color token)
                                         (cocolog-color-name
                                          (cocolog-var-to-color token)))
                                    token)
                                (or hex "#808080")
                                token)))
                      choices))
             (cocolog--palette-entries
              (mapcar (lambda (e) (cons (nth 0 e) (nth 1 e))) entries))
             (cocolog--palette-restricted t)
             (picked (cocolog-read-color "Variable of this clause"))
             (hex (cocolog-picked-color picked)))
        (when hex
          (let ((token (nth 2 (or (cl-find (downcase hex) entries
                                           :key (lambda (e) (downcase (nth 1 e)))
                                           :test #'equal)
                                  (car entries)))))
            (insert token)
            (save-excursion (cocolog-refresh-clause-graphs))
            (message "%s" (cocolog--describe-variable token))))))))

;;;###autoload
(defun cocolog-recolor-variable-at-point ()
  "Give the variable at point another colour, everywhere in its clause.
The name it carries is kept; only the colour changes."
  (interactive)
  (let* ((v (or (cocolog--variable-at-point)
                (user-error "Point is not on a variable")))
         (token (car v))
         (current (cocolog-var-to-color token))
         (label (or (cocolog-var-label token)
                    (and (null current) token)))
         (used (assoc-delete-all (or current "") (cocolog-clause-color-usage)))
         (tokens (cocolog-clause-color-tokens))
         (picked (cocolog-read-color
                  (format "New colour for %s"
                          (if current (cocolog-var-display-name token) token))
                  used current))
         (hex (cocolog-picked-color picked)))
    (when hex
      (let* ((label (or (cocolog-picked-label picked) label))
             (taken (cdr (assoc hex tokens)))
             (taken-label (and taken (cocolog-var-display-name taken))))
        ;; the target colour may already stand for another variable here
        (when (and taken-label label (not (equal taken-label label))
                   (y-or-n-p (format "%s is already %s in this clause; \
use that name too (the two become one variable)? "
                                     (cocolog-color-display-name hex)
                                     taken-label)))
          (setq label (cocolog-var-label taken)))
        (let* ((new (cocolog-color-to-var hex label))
               (n (cocolog--replace-in-clause token new)))
          (message "%d occurrence%s of %s %s now %s"
                   n (if (= n 1) "" "s")
                   (if current (cocolog-var-display-name token) token)
                   (if (= n 1) "is" "are")
                   (cocolog--describe-variable new)))))))

;;;###autoload
(defun cocolog-name-variable-at-point (name)
  "Give the variable at point the name NAME, everywhere in its clause.
A colour variable keeps its colour and is written `Cxxxxxx_NAME\=';
that is how two variables of a similar colour stay apart.  An empty
name gives a colour variable its colour name back.  An ordinary
variable is simply renamed."
  (interactive
   (list (let* ((v (or (cocolog--variable-at-point)
                       (user-error "Point is not on a variable")))
                (token (car v))
                (hex (cocolog-var-to-color token)))
           (if hex
               (or (cocolog--read-label hex (cocolog-var-label token)) "")
             (read-string (format "New name for %s: " token) nil nil token)))))
  (let* ((v (or (cocolog--variable-at-point)
                (user-error "Point is not on a variable")))
         (token (car v))
         (hex (cocolog-var-to-color token))
         (new (cond
               (hex (cocolog-color-to-var hex (and (not (string-empty-p name))
                                                   name)))
               ((cocolog-valid-label-p name)
                (if (string-match-p "\\`[A-Z_]" name)
                    name
                  (user-error "An ordinary Prolog variable starts with a \
capital or an underscore")))
               (t (user-error "`%s\=' is not a valid name" name)))))
    (let ((n (cocolog--replace-in-clause token new)))
      (message "%d occurrence%s renamed to %s" n (if (= n 1) "" "s")
               (cocolog--describe-variable new)))))

;;;###autoload
(defun cocolog-uncolor-variable-at-point (name)
  "Turn the colour variable at point into an ordinary variable NAME.
The colour is dropped; NAME defaults to the name the variable already
carries, capitalised so that Prolog still reads it as a variable."
  (interactive
   (list (let* ((v (or (cocolog--variable-at-point)
                       (user-error "Point is not on a variable")))
                (token (car v))
                (shown (or (cocolog-var-display-name token) token))
                (default (capitalize (replace-regexp-in-string
                                      "\\`#" "C" shown))))
           (read-string (format "Ordinary name for %s: " shown)
                        nil nil default))))
  (let* ((v (or (cocolog--variable-at-point)
                (user-error "Point is not on a variable")))
         (token (car v)))
    (unless (cocolog-var-to-color token)
      (user-error "%s is not a colour variable" token))
    (unless (let ((case-fold-search nil))
              (string-match-p "\\`[A-Z_][A-Za-z0-9_]*\\'" name))
      (user-error "`%s\=' is not a valid Prolog variable name" name))
    (let ((n (cocolog--replace-in-clause token name)))
      (message "%d occurrence%s of %s are now %s" n (if (= n 1) "" "s")
               (cocolog-var-display-name token) name))))

;;;###autoload
(defun cocolog-drop-stored-colors ()
  "Rewrite every `Cxxxxxx_Name\=' in the buffer as plain `Name\='.
The colours are then dealt by the mode when the file is opened, and the
file itself carries ordinary Prolog variables.

Variables with no name of their own are left as they are: their colour
is the only thing that tells them apart.  So is any clause where two
colours share a name, since dropping the colours there would quietly
turn two variables into one."
  (interactive)
  (let ((db (cocolog-buffer-db))
        (case-fold-search nil)
        (changed 0)
        (skipped 0))
    (save-excursion
      ;; bottom up, so that the positions of the clauses above stay right
      (dolist (rec (reverse (cocolog-db-order db)))
        (let* ((beg (cocolog-clause-start rec))
               (end (copy-marker (cocolog-clause-end rec)))
               (text (buffer-substring-no-properties beg (marker-position end)))
               (seen '()) (clash nil) (pos 0))
          (while (string-match cocolog-color-var-regexp text pos)
            (let* ((stop (match-end 0))
                   (hex (downcase (match-string 1 text)))
                   (label (match-string 2 text)))
              (setq pos stop)
              (when label
                (let ((cell (assoc label seen)))
                  (if (and cell (not (equal (cdr cell) hex)))
                      (setq clash t)
                    (push (cons label hex) seen))))))
          (if clash
              (cl-incf skipped)
            (goto-char beg)
            (while (re-search-forward cocolog-color-var-regexp
                                      (marker-position end) t)
              (let ((label (match-string-no-properties 2)))
                (when label
                  (replace-match label t t)
                  (cl-incf changed)))))
          (set-marker end nil))))
    (cocolog-forget-pinned-colors)
    (cocolog--forget-plain-colors)
    (when (and (> changed 0)
               (save-excursion
                 (goto-char (point-min))
                 (re-search-forward cocolog--trace-begin-re nil t)))
      (cocolog-run-all-tests))
    (font-lock-flush)
    (message "%d variable%s now carr%s a plain name%s"
             changed (if (= changed 1) "" "s") (if (= changed 1) "ies" "y")
             (if (> skipped 0)
                 (format "; %d clause%s left alone, two colours share a name there"
                         skipped (if (= skipped 1) "" "s"))
               ""))))

;;;###autoload
(defun cocolog-colorize-clause ()
  "Give every ordinary variable of the clause at point its own colour."
  (interactive)
  (let* ((bounds (or (cocolog-clause-bounds-at-point)
                     (user-error "Point is not inside a clause")))
         (case-fold-search nil)
         (text (buffer-substring-no-properties (car bounds) (cdr bounds)))
         (names '()) (pos 0)
         (used (mapcar #'car (cocolog-clause-color-usage))))
    (while (string-match "\\_<\\([A-Z][A-Za-z0-9_]*\\)\\_>" text pos)
      (let ((end (match-end 0))
            (n (match-string 1 text)))
        (setq pos end)
        (unless (or (member n names) (cocolog-color-var-p n)) (push n names))))
    (setq names (nreverse names))
    (unless names (user-error "No ordinary variables in this clause"))
    (when (> (length names) (- (length cocolog-palette) (length used)))
      (user-error "Not enough free colours for %d variables" (length names)))
    (let ((total 0))
      (dolist (n names)
        ;; each variable takes a colour that does not look like the ones
        ;; the clause already has
        ;; no seed here: a command that writes colours into the file should
        ;; give the same clause the same colours every time
        (let ((hex (cocolog-distinct-color n used)))
          (push hex used)
          (cl-incf total (cocolog--replace-in-clause
                          n (cocolog-color-to-var hex n) nil t))))
      (save-excursion (cocolog-refresh-clause-graphs))
      (message "%d variable%s coloured (%d occurrence%s)"
               (length names) (if (= (length names) 1) "" "s")
               total (if (= total 1) "" "s")))))

;;;###autoload
(defun cocolog-set-swatch-style (style)
  "Show colour variables as STYLE from now on.
STYLE is `name' to show what a variable is called, or `raw' to show the
text as it stands in the file."
  (interactive
   (list (intern (completing-read "Show colour variables as: "
                                  '("name" "raw") nil t nil nil
                                  (symbol-name cocolog-swatch-style)))))
  (setq-default cocolog-swatch-style style)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (or (derived-mode-p 'cocolog-mode)
                (bound-and-true-p cocolog-swatch-mode))
        (with-silent-modifications
          (remove-text-properties (point-min) (point-max) '(display nil)))
        (font-lock-flush))))
  (cocolog--menu-changed)
  (message "Colour variables shown as: %s" style))

;;;###autoload
(defun cocolog-cycle-swatch-style ()
  "Switch between showing a variable\='s name and the text of the file."
  (interactive)
  (cocolog-set-swatch-style
   (pcase cocolog-swatch-style ('name 'raw) (_ 'name))))

;;;###autoload
(defun cocolog-clause-legend ()
  "Show which colour is which variable in the clause at point."
  (interactive)
  (let ((used (cocolog-clause-color-usage))
        (tokens (cocolog-clause-color-tokens)))
    (if (null used)
        (message "No colour variables in this clause")
      (let ((parts '()))
        (dolist (c used)
          (let* ((hex (car c))
                 (token (cdr (assoc hex tokens))))
            (push (concat (propertize "   " 'face (cocolog--swatch-face hex))
                          (format " %s (%s, %d×)"
                                  (if token (cocolog-var-display-name token)
                                    (cocolog-color-display-name hex))
                                  hex (cdr c)))
                  parts)))
        (message "%s%s%s" (mapconcat #'identity (nreverse parts) "    ")
                 (let ((clashes (cocolog-clause-color-conflicts)))
                   (if clashes
                       (format "  --  %s stands for %s here!"
                               (cocolog-color-display-name (car (car clashes)))
                               (mapconcat #'identity (cdr (car clashes)) " and "))
                     ""))
                 (let ((names (cocolog-clause-name-conflicts)))
                   (if names
                       (format "  --  %s is two variables here, one with a \
colour and one without!" (car names))
                     "")))))))

;;;; ------------------------------------------------------------------
;;;; Test cases and execution graphs
;;;; ------------------------------------------------------------------

(defun cocolog--strip-comment-line (line)
  (replace-regexp-in-string "\\`[ \t]*%+ ?" "" line))

(defun cocolog--extract-queries (text)
  "Return every `?- Goal.' query found in the comment block TEXT."
  (let ((body (mapconcat #'cocolog--strip-comment-line (split-string text "\n") "\n"))
        (queries '()) (pos 0))
    (while (string-match "\\?-" body pos)
      (let* ((start (match-end 0))
             (r (condition-case nil (cocolog-read-term body start) (error nil))))
        (if r
            (progn
              (push (string-trim (substring body start (plist-get r :end))) queries)
              (setq pos (plist-get r :end)))
          ;; the reader has overwritten the match data, so use START, which
          ;; is where this match ended
          (setq pos start))))
    (nreverse queries)))

(defun cocolog--comment-block-above (pos)
  "Return the text of the comment lines directly above POS, or nil."
  (save-excursion
    (goto-char pos)
    (beginning-of-line)
    (let ((end (point)) (beg (point)))
      (while (and (> (point) (point-min))
                  (save-excursion
                    (forward-line -1)
                    (and (looking-at-p "[ \t]*%")
                         (not (cocolog--in-trace-block-p (point))))))
        (forward-line -1)
        (setq beg (point)))
      (and (< beg end) (buffer-substring-no-properties beg end)))))

(defun cocolog--comment-block-below (pos)
  "Return the text of the comment lines directly below POS, or nil."
  (save-excursion
    (goto-char pos)
    (forward-line 1)
    (let ((beg (point)))
      (while (and (not (eobp))
                  (looking-at-p "[ \t]*%")
                  (not (cocolog--in-trace-block-p (point))))
        (forward-line 1))
      (and (> (point) beg) (buffer-substring-no-properties beg (point))))))

(defun cocolog--clause-own-queries (rec)
  "Return the test queries written right next to the clause REC.
Only the comment block just above it and the one just below it count,
not the one belonging to the predicate as a whole."
  (append (cocolog--extract-queries
           (or (cocolog--comment-block-above (cocolog-clause-start rec)) ""))
          (cocolog--extract-queries
           (or (cocolog--comment-block-below (cocolog-clause-end rec)) ""))))

(defun cocolog-clause-queries (db rec)
  "Return the test queries attached to the clause REC of DB.
Queries are looked for in the comment block just above the clause, then
in the comment block just below it, and finally above the first clause
of the same predicate."
  (let* ((start (cocolog-clause-start rec))
         (qs (cocolog--clause-own-queries rec)))
    (or qs
        (let* ((key (cocolog--indicator (cocolog-clause-head rec)))
               (first (car (cl-remove-if-not
                            (lambda (r) (equal (cocolog--indicator
                                                (cocolog-clause-head r))
                                               key))
                            (cocolog-db-order db)))))
          (when (and first (/= (cocolog-clause-start first) start))
            (cocolog--extract-queries
             (or (cocolog--comment-block-above (cocolog-clause-start first)) "")))))))

(defun cocolog--trace-block-end ()
  "With point on a graph begin line, return the position after the block."
  (save-excursion
    (forward-line 1)
    (let ((found nil))
      (while (and (not (eobp)) (not found) (looking-at-p "[ \t]*%"))
        (if (looking-at-p cocolog--trace-end-re)
            (progn (forward-line 1) (setq found t))
          (forward-line 1)))
      (and found (point)))))

(defun cocolog--clauses-adjacent-p (a b)
  "Non-nil when only blank lines and comments separate the clauses A and B."
  (let ((from (cocolog-clause-end a)) (to (cocolog-clause-start b)))
    (and (<= from to)
         (string-match-p "\\`\\(?:[ \t\n]*\\|[ \t]*%[^\n]*\n\\)*\\'"
                         (buffer-substring-no-properties from to)))))

(defun cocolog--graph-anchor (db rec)
  "Return the clause the graph of REC belongs under.
A predicate is usually written as a run of clauses; the graph goes after
the last of them rather than in the middle.  A clause that carries a
test case of its own stops the run, so its own graph still lands there."
  (let* ((tail (memq rec (cocolog-db-order db)))
         (best rec)
         (key (cocolog--indicator (cocolog-clause-head rec))))
    (while (and (cdr tail)
                (let ((next (cadr tail)))
                  (and (equal key (cocolog--indicator (cocolog-clause-head next)))
                       (cocolog--clauses-adjacent-p best next)
                       (null (cocolog--clause-own-queries next)))))
      (setq best (cadr tail) tail (cdr tail)))
    best))

(defun cocolog--goto-graph-position (end)
  "Move point where the graph of a clause ending at END belongs.
Any graph already there is deleted."
  (goto-char end)
  (end-of-line)
  (if (eobp) (insert "\n") (forward-line 1))
  ;; keep hand written comments (the test case may live below the rule)
  (while (and (not (eobp))
              (looking-at-p "[ \t]*%")
              (not (looking-at-p cocolog--trace-begin-re)))
    (forward-line 1))
  ;; delete every graph block that is already there: a rule may carry
  ;; several test cases, and therefore several blocks
  (let ((here (point)) (again t))
    (while again
      (setq again nil)
      (while (and (not (eobp)) (looking-at-p "[ \t]*$")) (forward-line 1))
      (when (looking-at-p cocolog--trace-begin-re)
        (let ((stop (cocolog--trace-block-end)))
          (when stop
            (delete-region here stop)
            (setq again t))))
      (goto-char here))
    (goto-char here)))

(defun cocolog--delete-trace-blocks (from to)
  "Delete every graph block between FROM and TO.
TO must be a marker: the region shrinks as blocks go."
  (save-excursion
    (goto-char from)
    (beginning-of-line)
    (while (< (point) (marker-position to))
      (if (not (looking-at-p cocolog--trace-begin-re))
          (forward-line 1)
        (let ((stop (cocolog--trace-block-end)))
          (if stop (delete-region (point) stop) (forward-line 1)))))))

(defun cocolog--insert-graph (rec lines &optional origin)
  "Write LINES as the execution graph of the clause REC.
ORIGIN is the clause the test case was written next to, when that is an
earlier clause of the same predicate; any graph left between the two by
an older run is cleaned up."
  (let ((indent (save-excursion
                  (goto-char (cocolog-clause-start rec))
                  (make-string (current-indentation) ?\s)))
        (anchor (copy-marker (cocolog-clause-end rec))))
    (save-excursion
      (when (and origin (< (cocolog-clause-end origin) (marker-position anchor)))
        (cocolog--delete-trace-blocks (cocolog-clause-end origin) anchor))
      (cocolog--goto-graph-position (marker-position anchor))
      (dolist (l lines)
        (insert indent l "\n")))
    (set-marker anchor nil)))

(defun cocolog--run-queries (db queries)
  "Run QUERIES against DB and return the comment lines of all their graphs."
  (let ((lines '()))
    (dolist (q queries)
      (let ((result (condition-case err
                        (cocolog-run-query db q)
                      (cocolog-error
                       (cocolog--result-make
                        :goal nil :vars nil :solutions nil
                        :root (cocolog--node-create :kind 'root :label q :depth 0)
                        :status 'error :message (cadr err) :inferences 0)))))
        (setq lines (append lines (cocolog-graph-block result cocolog-comment-prefix)))))
    lines))

;;;###autoload
(defun cocolog-run-test-at-point (&optional all)
  "Run the test case of the rule at point and draw its execution graph.
With a prefix argument ALL, run every test case in the buffer."
  (interactive "P")
  (if all
      (cocolog-run-all-tests)
    (let* ((db (cocolog-buffer-db))
           (rec (or (cocolog-clause-at-point db)
                    (user-error "No clause here")))
           (queries (cocolog-clause-queries db rec)))
      (cocolog--report-db-errors db)
      (unless queries
        (user-error
         "No test case for this rule -- write one in a comment, e.g. %s?- %s"
         cocolog-comment-prefix
         (let ((h (cocolog-clause-head rec)))
           (concat (cocolog-term-to-string h) "."))))
      (cocolog--insert-graph (cocolog--graph-anchor db rec)
                             (cocolog--run-queries db queries) rec)
      (cocolog--coco-after-tests db queries))))

;;;###autoload
(defun cocolog-run-all-tests ()
  "Run every test case in the buffer and refresh all execution graphs."
  (interactive)
  (let* ((db (cocolog-buffer-db))
         (recs (reverse (cocolog-db-order db)))
         (n 0))
    (cocolog--report-db-errors db)
    (let ((asked '()))
      (dolist (rec recs)
        (let ((queries (cocolog-clause-queries db rec)))
          ;; only the clause the comment sits next to gets the graph
          (when (and queries (cocolog--clause-own-queries rec))
            (cocolog--insert-graph (cocolog--graph-anchor db rec)
                                   (cocolog--run-queries db queries) rec)
            (setq asked (append asked queries))
            (cl-incf n (length queries)))))
      (cocolog--coco-after-tests db asked))))

;;;###autoload
(defun cocolog-clear-trace-at-point (&optional all)
  "Delete the execution graph below the rule at point.
With a prefix argument ALL, delete every generated graph in the buffer."
  (interactive "P")
  (if all
      (let ((n 0))
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward cocolog--trace-begin-re nil t)
            (beginning-of-line)
            (let ((stop (cocolog--trace-block-end)))
              (if stop (progn (delete-region (point) stop) (cl-incf n))
                (forward-line 1)))))
        (message "%d graph%s removed" n (if (= n 1) "" "s")))
    (let* ((db (cocolog-buffer-db))
           (rec (or (cocolog-clause-at-point db) (user-error "No clause here")))
           (before (buffer-size)))
      (save-excursion
        (cocolog--goto-graph-position
         (cocolog-clause-end (cocolog--graph-anchor db rec))))
      (message (if (= before (buffer-size))
                   "No graph below this rule"
                 "Graph removed")))))

(defun cocolog--color-clashes (db)
  "Return (POSITION . MESSAGE) for every clause of DB with a confusing name."
  (let ((out '()))
    (dolist (rec (cocolog-db-order db) (nreverse out))
      (dolist (clash (cocolog-clause-color-conflicts (cocolog-clause-text rec)))
        (push (cons (cocolog-clause-start rec)
                    (format "%s stands for two variables here: %s"
                            (cocolog-color-display-name (car clash))
                            (mapconcat #'identity (cdr clash) ", ")))
              out))
      (dolist (name (cocolog-clause-name-conflicts (cocolog-clause-text rec)))
        (push (cons (cocolog-clause-start rec)
                    (format "%s is two variables here, one with a colour \
and one without" name))
              out)))))

(defun cocolog--report-db-errors (db)
  (when (cocolog-db-errors db)
    (message "cocolog: %d syntax error%s in this buffer (%s)"
             (length (cocolog-db-errors db))
             (if (= 1 (length (cocolog-db-errors db))) "" "s")
             (substitute-command-keys "\\[cocolog-check-buffer] to list them"))))

;;;###autoload
(defun cocolog-check-buffer ()
  "List the syntax errors of the buffer in a separate window."
  (interactive)
  (let* ((db (cocolog-buffer-db))
         (errors (append (cocolog-db-errors db) (cocolog--color-clashes db)))
         (src (current-buffer)))
    (setq errors (sort errors #'car-less-than-car))
    (if (null errors)
        (message "cocolog: no syntax errors and no colour clashes, %d clause%s"
                 (length (cocolog-db-order db))
                 (if (= 1 (length (cocolog-db-order db))) "" "s"))
      (with-current-buffer (get-buffer-create "*cocolog checks*")
        (let ((inhibit-read-only t))
          (erase-buffer)
          (dolist (e errors)
            (insert (format "%s:%d: %s\n"
                            (buffer-name src)
                            (with-current-buffer src
                              (line-number-at-pos (min (point-max) (car e))))
                            (cdr e))))
          (goto-char (point-min)))
        (special-mode)
        (display-buffer (current-buffer)))
      (message "cocolog: %d problem%s" (length errors)
               (if (= 1 (length errors)) "" "s")))))

;;;###autoload
(defun cocolog-query (query)
  "Run QUERY against the current buffer and show the graph in a window."
  (interactive
   (list (read-string "?- " (let* ((db (ignore-errors (cocolog-buffer-db)))
                                   (rec (and db (cocolog-clause-at-point db)))
                                   (qs (and rec (cocolog-clause-queries db rec))))
                              (or (car qs) "")))))
  (let* ((db (cocolog-buffer-db))
         (result (cocolog-run-query db query))
         (buffer (get-buffer-create "*cocolog*")))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (dolist (l (cocolog-graph-block result "")) (insert l "\n"))
        (goto-char (point-min)))
      (cocolog-view-mode))
    (display-buffer buffer)
    (cocolog--coco-after-tests db (list query))
    result))

(defvar cocolog-view-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") #'quit-window)
    map)
  "Keymap of `cocolog-view-mode'.")

(define-derived-mode cocolog-view-mode special-mode "cocolog-view"
  "Major mode showing the result of a cocolog query."
  (setq-local font-lock-defaults
              (list (list (list cocolog-color-var-regexp
                                '(0 (cocolog--fontify-color-var) t)))
                    nil nil))
  (setq-local font-lock-extra-managed-props
              '(display cursor-intangible help-echo))
  (font-lock-mode 1))

;;;; ------------------------------------------------------------------
;;;; Indentation
;;;; ------------------------------------------------------------------

(defun cocolog--comment-line-p ()
  "Non-nil when the line point is on begins with a comment."
  (save-excursion
    (beginning-of-line)
    (looking-at-p "[ \t]*%")))

(defun cocolog--previous-clause-end (pos)
  "Return the position after the `.' that ends the clause before POS.
The whitespace that follows the period is not searched for: a backward
search only finds a match that *ends* at or before POS, so looking for
\".\" and whitespace together would step over the very clause POS sits
just behind -- which is exactly where a graph, or point after a newline,
usually is."
  (save-match-data
   (save-excursion
    (goto-char pos)
    (let ((res nil))
      (while (and (not res) (re-search-backward "\\." nil t))
        (let ((after (char-after (1+ (point)))))
          ;; A graph is made of comment lines and most of them hold a
          ;; period, so this loop meets hundreds of them.  Asking the
          ;; parser about each is what made typing slow; a line that
          ;; begins with a comment character is one at a glance, and the
          ;; parser is left for the few that are not.
          (when (and (or (null after) (memq after '(?\s ?\t ?\n ?\r)))
                     (not (cocolog--comment-line-p))
                     (not (nth 8 (cocolog--syntax (point)))))
            (setq res (1+ (point))))))
      res))))

(defun cocolog--code-starts-before-p (here)
  "Non-nil when the clause around HERE already has code before HERE."
  (let ((prev (or (cocolog--previous-clause-end here) (point-min))))
    (save-excursion
      (goto-char prev)
      (let (verdict)
        (while (not verdict)
          (skip-chars-forward " \t\n" here)
          (cond
           ((>= (point) here) (setq verdict 'no))
           ((eq (char-after) ?%) (forward-line 1))
           ((and (eq (char-after) ?/) (eq (char-after (1+ (point))) ?*))
            (unless (search-forward "*/" here t) (setq verdict 'no)))
           (t (setq verdict 'yes))))
        (eq verdict 'yes)))))

(defun cocolog--clause-indent (here)
  "Indentation of the first line of the clause that HERE belongs to."
  (let ((prev (or (cocolog--previous-clause-end here) (point-min))))
    (save-excursion
      (goto-char prev)
      (let (found)
        (while (not found)
          (skip-chars-forward " \t\n" here)
          (cond
           ((>= (point) here) (setq found t))
           ((eq (char-after) ?%) (forward-line 1))
           ((and (eq (char-after) ?/) (eq (char-after (1+ (point))) ?*))
            (unless (search-forward "*/" here t) (setq found t)))
           (t (setq found t))))
        (current-indentation)))))

(defun cocolog--calculate-indent ()
  "Return the column the current line should be indented to."
  (save-excursion
    (beginning-of-line)
    (let* ((here (point))
           (ppss (cocolog--syntax here))
           (depth (nth 0 ppss))
           (open (nth 1 ppss)))
      (cond
       ((nth 4 ppss) (current-indentation))
       ((nth 3 ppss) (current-indentation))
       ((> depth 0)
        (save-excursion
          (let ((closing (looking-at-p "[ \t]*\\(;\\|)\\|->\\||\\)")))
            (goto-char open)
            (cond
             (closing (- open (line-beginning-position)))
             ((looking-at ".[ \t]*\\(%.*\\)?$")
              (+ (current-indentation) cocolog-indent-width))
             (t (+ 1 (- open (line-beginning-position))))))))
       ((cocolog--code-starts-before-p here)
        (+ (cocolog--clause-indent here) cocolog-indent-width))
       (t 0)))))

(defun cocolog-indent-line ()
  "Indent the current line as cocolog (Prolog) code."
  (interactive)
  (let* ((target (cocolog--calculate-indent))
         (pos (- (point-max) (point))))
    (beginning-of-line)
    (skip-chars-forward " \t")
    (unless (= (current-column) target)
      (delete-region (line-beginning-position) (point))
      (indent-to target))
    (when (> (- (point-max) pos) (point))
      (goto-char (- (point-max) pos)))))

;;;; ------------------------------------------------------------------
;;;; Following the theme
;;;; ------------------------------------------------------------------

(defun cocolog-refresh-swatches (&rest _)
  "Draw the swatches of every cocolog buffer again.
The colours themselves do not depend on the theme, but whether a swatch
needs an outline to stand out from the background does, so this runs
when the theme changes."
  (cocolog-forget-faces)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (or (derived-mode-p 'cocolog-mode)
                (bound-and-true-p cocolog-swatch-mode))
        (with-silent-modifications
          (remove-text-properties (point-min) (point-max) '(display nil)))
        (font-lock-flush)))))

(when (boundp 'enable-theme-functions)
  (add-hook 'enable-theme-functions #'cocolog-refresh-swatches))
(when (boundp 'disable-theme-functions)
  (add-hook 'disable-theme-functions #'cocolog-refresh-swatches))

;;;; ------------------------------------------------------------------
;;;; Colour swatches outside cocolog-mode
;;;; ------------------------------------------------------------------

(defcustom cocolog-swatch-mode-style 'name
  "How `cocolog-swatch-mode' shows a colour variable in a foreign buffer.
The default `name' reads the way a cocolog buffer does; `raw' shows the
text as it stands, which is what you want when the point of the passage
is the text on disk.  See `cocolog-swatch-style'."
  :type '(choice (const block) (const name) (const text))
  :group 'cocolog)

(defcustom cocolog-swatch-code-languages '("prolog" "cocolog" "colog")
  "Languages of the fenced code blocks `cocolog-swatch-mode' colours.
A block of some other language is left alone: the `Q\=' of `emacs -Q\='
in a shell block is not a Prolog variable."
  :type '(repeat string) :group 'cocolog)

(defun cocolog--code-region-at (pos)
  "Return the bounds of the Prolog code block POS is in, or nil.

The fence is looked for in the text rather than read off the text
properties Markdown lays down: those are laid down lazily, and reading
half a block would colour its first lines from one set of variables and
the rest from another.  The language on the opening fence decides
whether the block is ours at all, so prose, shell and elisp blocks are
left alone."
  (save-match-data
    (save-excursion
      (goto-char pos)
      (let ((open (and (re-search-backward "^[ \t]*\\(?:```\\|~~~\\)\\(.*\\)$" nil t)
                       (list (match-end 0)
                             (string-trim (match-string-no-properties 1))))))
        (when (and open
                   (member (downcase (nth 1 open)) cocolog-swatch-code-languages)
                   (> pos (nth 0 open)))
          (let ((end (save-excursion
                       (goto-char (nth 0 open))
                       (if (re-search-forward "^[ \t]*\\(?:```\\|~~~\\)[ \t]*$" nil t)
                           (match-beginning 0)
                         (point-max)))))
            (when (< pos end)
              (cons (1+ (nth 0 open)) end))))))))

(defun cocolog--match-plain-var-in-code (limit)
  "Font lock matcher for an ordinary variable inside a code block, up to LIMIT.
The syntax table of the mode is used for the search, so that a variable
is one token here as it is in a cocolog buffer."
  (and cocolog-color-plain-variables
       (let ((case-fold-search nil) (found nil))
         ;; the table is used for the search alone: `syntax-ppss' must see
         ;; the buffer's own table, and caches what it sees
         (while (and (not found)
                     (cocolog--with-syntax
                       (re-search-forward "\\_<\\([A-Z][A-Za-z0-9_]*\\)\\_>" limit t)))
           (when (and (cocolog--code-region-at (match-beginning 0))
                      (not (cocolog-color-var-p (match-string-no-properties 0)))
                      ;; a remark written beside a rule is prose here too
                      (cocolog--colourable-position-p (match-beginning 0)))
             (setq found t)))
         found)))

(defun cocolog--fontify-plain-var-in-code ()
  "Font lock helper: colour an ordinary variable inside a code block.
The colours are worked out for the whole block at once and kept in a
cache of its own, so every line of a block is coloured from the same set
of variables.  The clause by clause reckoning of a cocolog buffer is no
use here: a code block has no reliable clause boundaries around it."
  (let ((name (match-string-no-properties 0))
        (pos (match-beginning 0)))
    (let ((region (cocolog--code-region-at pos)))
      (when region
        (unless (and cocolog--code-block-cache
                     (equal (car cocolog--code-block-cache) region))
          (setq cocolog--code-block-cache
                (cons region (cocolog--plain-colors-in (car region) (cdr region)))))
        (let ((hex (cdr (assoc name (cdr cocolog--code-block-cache)))))
          (and hex (cocolog--swatch-face hex)))))))

(defconst cocolog--swatch-keywords
  '((cocolog--match-plain-var-in-code (0 (cocolog--fontify-plain-var-in-code) t))
    (cocolog--match-color-var (0 (cocolog--fontify-color-var) t)))
  "The font lock rules `cocolog-swatch-mode' adds.")

;;;###autoload
(define-minor-mode cocolog-swatch-mode
  "Paint cocolog colour variables in their own colour in any buffer.

Turn this on in a Markdown, Org or diff buffer and every `Cxxxxxx'
mentioned there shows up in that colour, the same way it does in a
`cocolog-mode' buffer.  `cocolog-swatch-mode-style' decides whether a
swatch, a colour name or the coloured name itself is shown."
  :lighter " Csw"
  :group 'cocolog
  (if cocolog-swatch-mode
      (progn
        (setq-local cocolog-swatch-style cocolog-swatch-mode-style)
        ;; a buffer of documentation is here to be read, not edited, so the
        ;; examples in it are shown the way the pictures beside them were
        ;; drawn -- whatever the editing default is
        (setq-local cocolog-color-plain-variables t)
        ;; documentation reads better when it looks the same every time,
        ;; and this has to agree with the scratch buffer Markdown uses to
        ;; fontify a code block; \[cocolog-shuffle-colors] still deals again
        (setq cocolog--color-seed 0)
        (add-hook 'after-change-functions #'cocolog--forget-plain-colors nil t)
        (dolist (prop '(display cursor-intangible help-echo))
          (unless (memq prop font-lock-extra-managed-props)
            (setq-local font-lock-extra-managed-props
                        (cons prop font-lock-extra-managed-props))))
        ;; what is typed after a swatch must not inherit its properties
        (setq-local text-property-default-nonsticky
                    (append '((cursor-intangible . t) (help-echo . t))
                            text-property-default-nonsticky))
        (font-lock-add-keywords nil cocolog--swatch-keywords 'append)
        (cursor-intangible-mode 1))
    (font-lock-remove-keywords nil cocolog--swatch-keywords)
    (cursor-intangible-mode -1)
    (remove-hook 'after-change-functions #'cocolog--forget-plain-colors t)
    (with-silent-modifications
      (remove-text-properties (point-min) (point-max) '(display nil))))
  (cocolog--menu-changed)
  (when font-lock-mode
    (font-lock-flush)
    (font-lock-ensure)))

;;;; ------------------------------------------------------------------
;;;; Mode
;;;; ------------------------------------------------------------------


;;;; ------------------------------------------------------------------
;;;; Running under coco: the real interpreter, and its four-port tracer
;;;; ------------------------------------------------------------------
;; The engine in cocolog-engine.el answers what cocolog answers -- `make
;; coco' holds it there -- but it is a shadow all the same: no store, no
;; torch, no other processes.  \\[cocolog-coco-trace] runs a goal over
;; this buffer's FILE under the real cocolog binary with `--trace' on,
;; and the Call/Exit/Redo/Fail ports -- SWI's format, held to SWI by
;; cocolog's own suite -- land in a buffer of their own.  Which
;; knowledge base the run uses is a setting, the same four arrangements
;; the binary has.

(defgroup cocolog-coco nil
  "Running a buffer under the cocolog binary, tracer and all."
  :group 'cocolog)

(defcustom cocolog-coco-program
  (let ((here (and load-file-name (file-name-directory load-file-name))))
    (or (and here
             (let ((guess (expand-file-name "../cocolog" here)))
               (and (file-executable-p guess) guess)))
        "cocolog"))
  "The cocolog binary.
When this file loads from a cocolog checkout the binary two doors up is
found by itself; anywhere else, name one here or have `cocolog' on PATH."
  :type 'string :group 'cocolog-coco)

(defcustom cocolog-coco-arrangement 'local
  "Which knowledge base a coco run uses -- the binary's four, as symbols.
`local' is memory and needs nothing; `embed' opens the store directory
`cocolog-coco-store' inside the process; `server' talks to a ZiguratIP
server; `http' reads over Zeytun.  \\[cocolog-set-arrangement] switches
it for the session."
  :type '(choice (const local) (const embed) (const server) (const http))
  :group 'cocolog-coco)

(defcustom cocolog-coco-store "./KB"
  "The store directory of the `embed' arrangement.
Relative names are relative to the traced file's directory, which is
where the binary runs."
  :type 'string :group 'cocolog-coco)

(defcustom cocolog-coco-kb "main"
  "The knowledge base name, for the arrangements that name one."
  :type 'string :group 'cocolog-coco)

(defcustom cocolog-coco-host "127.0.0.1"
  "The server host of the `server' and `http' arrangements."
  :type 'string :group 'cocolog-coco)

(defcustom cocolog-coco-port "2160"
  "The binary-protocol port of the `server' arrangement."
  :type 'string :group 'cocolog-coco)

(defcustom cocolog-coco-http-port ""
  "The Zeytun page port of the `http' arrangement.  Empty means unset."
  :type 'string :group 'cocolog-coco)

(defun cocolog-coco-arguments ()
  "The arrangement half of a cocolog command line, from the settings."
  (pcase cocolog-coco-arrangement
    ('local  (list "--local"))
    ('embed  (list "--store" cocolog-coco-store "--kb" cocolog-coco-kb))
    ('server (list "--kb" cocolog-coco-kb
                   "--host" cocolog-coco-host "--port" cocolog-coco-port))
    ('http
     (when (string-empty-p cocolog-coco-http-port)
       (user-error "Set `cocolog-coco-http-port' before reading over Zeytun"))
     (list "--kb" cocolog-coco-kb
           "--host" cocolog-coco-host "--http" cocolog-coco-http-port))))

;;;###autoload
(defun cocolog-set-arrangement (arrangement)
  "Pick which knowledge base coco runs use, for this session.
ARRANGEMENT is one of the binary's four; the customisable options of the
`cocolog-coco' group carry the store directory, kb name, host and ports."
  (interactive
   (list (intern (completing-read "Arrangement: "
                                  '("local" "embed" "server" "http")
                                  nil t nil nil
                                  (symbol-name cocolog-coco-arrangement)))))
  (setq cocolog-coco-arrangement arrangement)
  (message "coco runs: cocolog %s"
           (mapconcat #'identity (cocolog-coco-arguments) " ")))

(defface cocolog-trace-call-face '((t :inherit font-lock-function-name-face))
  "The Call port." :group 'cocolog-coco)
(defface cocolog-trace-exit-face '((t :inherit success))
  "The Exit port." :group 'cocolog-coco)
(defface cocolog-trace-redo-face '((t :inherit warning))
  "The Redo port." :group 'cocolog-coco)
(defface cocolog-trace-fail-face '((t :inherit error))
  "The Fail port." :group 'cocolog-coco)

(defconst cocolog-trace-font-lock
  '(("^\\s-*\\(Call\\):" 1 'cocolog-trace-call-face)
    ("^\\s-*\\(Exit\\):" 1 'cocolog-trace-exit-face)
    ("^\\s-*\\(Redo\\):" 1 'cocolog-trace-redo-face)
    ("^\\s-*\\(Fail\\):" 1 'cocolog-trace-fail-face)
    ("^\\s-*\\(?:Call\\|Exit\\|Redo\\|Fail\\): \\((\\([0-9]+\\))\\)"
     1 'font-lock-comment-face))
  "Font lock for the four ports.")

(define-derived-mode cocolog-trace-mode special-mode "coco-trace"
  "The buffer \\[cocolog-coco-trace] writes the ports into.
`q' buries it; the process, if still running, dies with the buffer."
  (setq-local font-lock-defaults '(cocolog-trace-font-lock))
  (setq-local truncate-lines t))

(defun cocolog--coco-goal-at-point ()
  "The test query of the rule at point, as a goal, or nil.
The same comment \\[cocolog-run-test-at-point] runs -- so the goal a
rule is normally proven by is the goal offered for tracing it."
  (let* ((db (ignore-errors (cocolog-buffer-db)))
         (rec (and db (ignore-errors (cocolog-clause-at-point db))))
         (queries (and rec (ignore-errors (cocolog-clause-queries db rec)))))
    (and queries (string-trim (car queries)))))

(defvar cocolog--coco-goal-history nil)

(defun cocolog--coco-filter (proc text)
  "Append TEXT to PROC's buffer, read-only or not."
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (let ((inhibit-read-only t)
            (at-end (= (point) (point-max))))
        (save-excursion (goto-char (point-max)) (insert text))
        (when at-end (goto-char (point-max)))))))

(defun cocolog--coco-sentinel (proc event)
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-max))
          (insert (propertize (format "-- %s" event)
                              'face 'font-lock-comment-face)))))))

;;;###autoload
(defun cocolog-coco-trace (goal &optional no-trace)
  "Run GOAL over this buffer's file under the cocolog binary, traced.
The four ports -- Call, Exit, Redo, Fail, in SWI's format -- land in
the *coco trace* buffer as the proof runs, under whichever knowledge
base `cocolog-coco-arrangement' names (\\[cocolog-set-arrangement]
switches it).  The goal offered is the rule at point's own test query.
With a prefix argument NO-TRACE, run without the tracer and show only
what the goal prints -- the way to run a torch tutorial's `train' from
the buffer it is written in."
  (interactive
   (list (read-string "Goal: " (cocolog--coco-goal-at-point)
                      'cocolog--coco-goal-history)
         current-prefix-arg))
  (unless buffer-file-name
    (user-error "This buffer has no file for cocolog to consult"))
  (when (buffer-modified-p)
    (if (y-or-n-p "Save the buffer first? ")
        (save-buffer)
      (user-error "cocolog reads the file, and the file is behind")))
  (cocolog--coco-trace-start buffer-file-name goal (cocolog-coco-arguments)
                             no-trace)
  (display-buffer "*coco trace*"))

(defun cocolog--coco-trace-start (file goal arrangement &optional no-trace)
  "Refresh *coco trace* with GOAL's ports over FILE, under ARRANGEMENT.
The plumbing of \\[cocolog-coco-trace], shared with the quiet refresh a
test run makes."
  (let* ((goal (string-remove-suffix "." (string-trim goal)))
         (args (append arrangement
                       (and (not no-trace) (list "--trace"))
                       (list "run" file goal)))
         (default-directory (file-name-directory file))
         (buffer (get-buffer-create "*coco trace*")))
    ;; one trace at a time: a predecessor still running would write its
    ;; tail -- or its sentinel's last word -- into the fresh trace
    (let ((old (get-buffer-process buffer)))
      (when old
        (set-process-filter old #'ignore)
        (set-process-sentinel old #'ignore)
        (delete-process old)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t)) (erase-buffer))
      (cocolog-trace-mode)
      (let ((inhibit-read-only t))
        (insert (propertize
                 (format "?- %s.    [cocolog %s]\n" goal
                         (mapconcat #'identity arrangement " "))
                 'face 'font-lock-comment-face))))
    (make-process :name "coco-trace"
                  :buffer buffer
                  :command (cons cocolog-coco-program args)
                  :filter #'cocolog--coco-filter
                  :sentinel #'cocolog--coco-sentinel)))

;;;; The engine draws, coco certifies.  The engine in cocolog-engine.el
;;;; is a SHADOW of the interpreter: held to it offline by `make coco',
;;;; and -- from here -- checked against it live.  Every test run whose
;;;; machine has a cocolog binary re-asks the real interpreter the same
;;;; queries and refreshes the live port trace, so a graph the mode
;;;; draws is never quietly wrong about what cocolog would say.

(defcustom cocolog-coco-check t
  "Certify every drawn graph against the cocolog binary.
When the binary is reachable, each test run's queries are re-asked of
the real interpreter -- in memory, touching no store -- and the answers
compared; agreement is a word in the echo area, disagreement a loud
warning.  Without a binary the graphs stand on the engine alone, as
they always did."
  :type 'boolean :group 'cocolog-coco)

(defcustom cocolog-coco-trace-on-test t
  "Refresh the *coco trace* buffer on every test run.
The rule's first query is traced under the real interpreter -- always
in memory, whatever `cocolog-coco-arrangement' says, so a redraw can
never write into a store -- and the four ports wait in the buffer.
Nothing pops up: the buffer refreshes where it is."
  :type 'boolean :group 'cocolog-coco)

(defun cocolog--coco-available-p ()
  "Non-nil when the cocolog binary can actually be run."
  (and cocolog-coco-program
       (or (file-executable-p cocolog-coco-program)
           (executable-find cocolog-coco-program))))

(defvar cocolog--coco-buffer-copy nil
  "One temporary file per session for consulting an unsaved buffer.
Reused rather than made fresh, so the asynchronous trace never has its
file deleted from underneath it.")

(defun cocolog--coco-source-file ()
  "The file coco should consult: the buffer's own when it is current,
a temporary copy of the buffer's text otherwise."
  (if (and buffer-file-name (not (buffer-modified-p)))
      buffer-file-name
    (unless cocolog--coco-buffer-copy
      (setq cocolog--coco-buffer-copy (make-temp-file "coco-buffer" nil ".pl")))
    (write-region (point-min) (point-max) cocolog--coco-buffer-copy nil 'silent)
    cocolog--coco-buffer-copy))

(defun cocolog--coco-goal-variables (goal)
  "The variables written in GOAL, in order of first appearance.
A name inside a quoted atom or a string is text, and an underscore
name says nothing worth comparing -- the same reading `make coco'
makes."
  (let ((case-fold-search nil)
        (bare (replace-regexp-in-string
               "'\\(?:[^'\\\\]\\|\\\\.\\)*'" "''"
               (replace-regexp-in-string
                "\"\\(?:[^\"\\\\]\\|\\\\.\\)*\"" "\"\"" goal)))
        (vars '()) (pos 0))
    ;; maximal identifier runs, by hand: `\\_<' would read the current
    ;; buffer's syntax table and `case-fold-search' starts out t, so
    ;; neither says "a Prolog variable" reliably
    (while (string-match "[A-Za-z0-9_]+" bare pos)
      (let ((name (match-string 0 bare)))
        (setq pos (match-end 0))
        (when (and (string-match-p "\\`[A-Z]" name)
                   (not (member name vars)))
          (push name vars))))
    (nreverse vars)))

(defun cocolog--coco-plain-goal (query)
  "QUERY as a goal: no leading ?-, no trailing period."
  (let ((q (string-trim query)))
    (when (string-prefix-p "?-" q) (setq q (string-trim (substring q 2))))
    (string-remove-suffix "." q)))

(defun cocolog--coco-answers (file query)
  "What cocolog answers for QUERY over FILE, as one conformance line.
One --local run: consult, prove a goal that prints each solution's
bindings on a line of its own, join the first ten.  `error' when the
run died -- an uncaught exception, usually."
  (let* ((goal (cocolog--coco-plain-goal query))
         (vars (cocolog--coco-goal-variables goal))
         (wrapped (if vars
                      (format "forall((%s), format(\"~n%s~n\", [%s]))"
                              goal
                              (mapconcat (lambda (v) (concat v "=~q")) vars ",")
                              (mapconcat #'identity vars ", "))
                    (format "( (%s) -> format(\"~ncoco_true~n\", []) ; true )"
                            goal)))
         (keep (if vars (concat "^" (regexp-quote (car vars)) "=")
                 "^coco_true$")))
    (with-temp-buffer
      (let ((status (call-process cocolog-coco-program nil (list t nil) nil
                                  "--local" "run" file wrapped)))
        (if (not (eq status 0))
            'error
          (let ((lines '()))
            (goto-char (point-min))
            (while (not (eobp))
              (let ((line (buffer-substring-no-properties
                           (line-beginning-position) (line-end-position))))
                (when (string-match-p keep line) (push line lines)))
              (forward-line 1))
            (setq lines (nreverse lines))
            (cond ((null lines) "no solutions")
                  ((null vars) "true")
                  (t (mapconcat #'identity (seq-take lines 10) " ; ")))))))))

(defun cocolog--engine-answer (result)
  "The engine's RESULT as the same one-line answer, or `error'."
  (let ((sols (cocolog-result-solutions result)))
    (cond ((cocolog-result-message result) 'error)
          ((null sols) "no solutions")
          ((cl-every #'null sols) "true")
          (t (mapconcat (lambda (s)
                          (mapconcat (lambda (b) (format "%s=%s" (car b) (cdr b)))
                                     s ","))
                        (seq-take sols 10) " ; ")))))

(defun cocolog--coco-norm (answer)
  "ANSWER reduced to what it says: no spacing, no variable names.
Every capital-initial word becomes `_' -- variables are the only words
Prolog spells that way, and the two writers name theirs differently."
  (if (not (stringp answer)) answer
    (let ((case-fold-search nil)
          (s (replace-regexp-in-string "[ \t]+" "" answer)))
      (setq s (replace-regexp-in-string
               "[A-Za-z0-9_]+"
               (lambda (tok)
                 (if (string-match-p "\\`[A-Z_]" tok) "_" tok))
               s t t))
      (replace-regexp-in-string "(\\([<>=]\\))" "\\1" s))))

(defun cocolog--coco-agree-p (engine coco)
  (cond ((eq engine 'error) (eq coco 'error))
        ((eq coco 'error) nil)
        (t (equal (cocolog--coco-norm engine) (cocolog--coco-norm coco)))))

(defun cocolog--coco-certify (db queries)
  "Ask the binary QUERIES and compare with the engine over DB.
Returns the disagreements: a list of (QUERY ENGINE COCO)."
  (let ((file (cocolog--coco-source-file))
        (bad '()))
    (dolist (q queries)
      (let ((engine (cocolog--engine-answer (cocolog-run-query db q 10)))
            (coco (cocolog--coco-answers file q)))
        (unless (cocolog--coco-agree-p engine coco)
          (push (list q engine coco) bad))))
    (nreverse bad)))

(defun cocolog--coco-after-tests (db queries)
  "The word after a test run: certify against coco, refresh the trace.
Certifying and the quiet trace both run in memory whatever the chosen
arrangement says, so a redraw can never write into a store."
  (let ((n (length queries)))
    (if (not (and cocolog-coco-check (cocolog--coco-available-p)))
        (message "%d test case%s run" n (if (= n 1) "" "s"))
      (let ((bad (cocolog--coco-certify db queries)))
        (when (and cocolog-coco-trace-on-test queries)
          (cocolog--coco-trace-start (cocolog--coco-source-file)
                                     (cocolog--coco-plain-goal (car queries))
                                     (list "--local")))
        (if (null bad)
            (message "%d test case%s run · cocolog agrees"
                     n (if (= n 1) "" "s"))
          (dolist (d bad)
            (display-warning
             'cocolog
             (format "the graph disagrees with cocolog\n  ?- %s.\n    engine : %s\n    cocolog: %s"
                     (nth 0 d) (nth 1 d) (nth 2 d))))
          (message "%d test case%s run · %d DISAGREE with cocolog -- see *Warnings*"
                   n (if (= n 1) "" "s") (length bad)))))))

(defvar cocolog-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-v") #'cocolog-insert-color-variable)
    (define-key map (kbd "C-c C-r") #'cocolog-recolor-variable-at-point)
    (define-key map (kbd "C-c C-n") #'cocolog-name-variable-at-point)
    (define-key map (kbd "C-c C-u") #'cocolog-uncolor-variable-at-point)
    (define-key map (kbd "C-c C-y") #'cocolog-insert-clause-variable)
    (define-key map (kbd "C-c C-g") #'cocolog-insert-torch-rule)
    (define-key map (kbd "C-c C-e") #'cocolog-coco-trace)
    (define-key map (kbd "C-c C-i") #'cocolog-insert-goal)
    (define-key map (kbd "C-c C-w") #'cocolog-shuffle-colors)
    (define-key map (kbd "C-c C-d") #'cocolog-drop-stored-colors)
    (define-key map [remap delete-backward-char] #'cocolog-delete-variable-backward)
    (define-key map [remap backward-delete-char-untabify]
                #'cocolog-delete-variable-backward-untabify)
    (define-key map [remap delete-char] #'cocolog-delete-variable-forward)
    (define-key map [remap delete-forward-char] #'cocolog-delete-variable-forward)
    (define-key map (kbd "C-c C-b") #'cocolog-colorize-clause)
    (define-key map (kbd "C-c C-c") #'cocolog-toggle-plain-colors)
    (define-key map (kbd "C-c C-s") #'cocolog-cycle-swatch-style)
    (define-key map (kbd "C-c C-p") #'cocolog-clause-legend)
    (define-key map (kbd "C-c C-t") #'cocolog-run-test-at-point)
    (define-key map (kbd "C-c C-a") #'cocolog-run-all-tests)
    (define-key map (kbd "C-c C-k") #'cocolog-clear-trace-at-point)
    (define-key map (kbd "C-c C-q") #'cocolog-query)
    (define-key map (kbd "C-c C-l") #'cocolog-check-buffer)
    map)
  "Keymap for `cocolog-mode'.")

(defconst cocolog-mode-menu-spec
  '("Coco"
    ("Colours"
     ["Insert a colour variable..." cocolog-insert-color-variable
      :help "Pick a colour from the palette and insert it as a variable"]
     ["Insert a variable this clause has..." cocolog-insert-clause-variable
      :help "Pick by colour among the variables the clause already talks about"]
     ["Recolour the variable at point..." cocolog-recolor-variable-at-point
      :enable (cocolog--variable-at-point)
      :help "Give this variable another colour, everywhere in its clause"]
     ["Name the variable at point..." cocolog-name-variable-at-point
      :enable (cocolog--variable-at-point)
      :help "Give this variable a name of its own, colour and all"]
     ["Drop the colour of the variable at point..."
      cocolog-uncolor-variable-at-point
      :enable (and (cocolog--variable-at-point)
                   (cocolog-var-to-color (car (cocolog--variable-at-point))))
      :help "Turn this colour variable back into an ordinary one"]
     ["Colour every variable of the clause" cocolog-colorize-clause
      :help "Write a colour into the file for each variable of this clause"]
     ["Delete the variable before point" cocolog-delete-variable-backward
      :help "A colour variable is deleted whole, colour and name together"]
     ["Delete the variable after point" cocolog-delete-variable-forward
      :help "A colour variable is deleted whole, colour and name together"]
     ["Drop the colours written in the file..." cocolog-drop-stored-colors
      :help "Rewrite Cxxxxxx_Name as Name and let the mode colour it instead"]
     ["Colour ordinary variables on screen" cocolog-toggle-plain-colors
      :style toggle :selected cocolog-color-plain-variables
      :help "Colour Grandad and Kid too, without writing anything to the file"]
     ["Deal new colours" cocolog-shuffle-colors
      :enable cocolog-color-plain-variables
      :help "Give the ordinary variables of this buffer another set of colours"]
     ["Write the colour into the file as you type" cocolog-toggle-auto-color
      :style toggle :selected cocolog-auto-color
      :help "Turn a variable you type into Cxxxxxx_Name, pinning its colour"]
     "---"
     ["Show the colour legend" cocolog-clause-legend
      :help "Echo which colour is which variable in this clause"]
     ("Show colour variables as"
      ["Their name" (cocolog-set-swatch-style 'name)
       :style radio :selected (eq cocolog-swatch-style 'name)
       :help "The name of the variable, or its colour alone when it has none"]
      ["The text of the file" (cocolog-set-swatch-style 'raw)
       :style radio :selected (eq cocolog-swatch-style 'raw)
       :help "Cxxxxxx_Name as it stands on disk, for repairing a file by hand"]
      "---"
      ["Switch between the two" cocolog-cycle-swatch-style
       :help "Go from one of these to the other and back"])
     ["Colour swatches in other buffers" cocolog-swatch-mode
      :style toggle :selected (bound-and-true-p cocolog-swatch-mode)
      :help "Paint Cxxxxxx names in this buffer even outside cocolog-mode"])

    ["Insert a goal..." cocolog-insert-goal
     :help "Everything that can be written in a clause, by group, in columns"]
    ["Insert a goal: the builtins..." cocolog-insert-builtin
     :help "The same list, opened on unifying, arithmetic, the tests, the lists"]
    ["Insert a goal: a piece of a grammar rule..." cocolog-insert-dcg-item
     :help "The same list, opened on white space, a number, the rest of the line"]
    ["Insert a torch rule..." cocolog-insert-torch-rule
     :help "Building a net, training, a trained model -- one column each"]

    ("Under coco"
     ["Trace a goal (four ports)..." cocolog-coco-trace
      :help "Run a goal over this file under the cocolog binary with --trace"]
     ["Pick the knowledge base arrangement..." cocolog-set-arrangement
      :help "local, embed, server or http -- what a coco run opens"])

    ("Test cases"
     ["Run the test case at point" cocolog-run-test-at-point
      :help "Run the ?- comment of this rule and draw its execution graph"]
     ["Run every test case in the buffer" cocolog-run-all-tests
      :help "Refresh every execution graph in this buffer"]
     ["Ask a query..." cocolog-query
      :help "Run a one-off query against this buffer"]
     "---"
     ["Draw the graph again" cocolog-refresh-clause-graphs
      :help "Run this rule's test cases again, in place"]
     "---"
     ["Remove the graph below this rule" cocolog-clear-trace-at-point
      :help "Delete the generated comment block under this rule"]
     ["Remove every graph in the buffer" (cocolog-clear-trace-at-point t)
      :help "Delete all generated comment blocks"]
     "---"
     ["Redraw a graph after an edit" cocolog-toggle-refresh-idle
      :style toggle :selected (and cocolog-refresh-idle t)
      :help "Draw a rule's graph again once you stop typing"]
     ["Refresh the graphs when saving" cocolog-toggle-run-tests-on-save
      :style toggle :selected cocolog-run-tests-on-save
      :help "Re-run every test case on every save of the file"])

    ("Graph style"
     ["Box drawing characters" cocolog-toggle-graph-unicode
      :style toggle :selected cocolog-graph-unicode
      :help "Draw the graph with box drawing characters instead of ASCII"]
     ["Show the clauses that were tried" cocolog-toggle-graph-clauses
      :style toggle :selected cocolog-graph-show-clauses
      :help "Show every clause of a predicate the solver tried"]
     ["Merge the clauses that did not match" cocolog-toggle-collapse-failures
      :style toggle :selected cocolog-graph-collapse-failures
      :help "Put a run of failed head unifications on one line"]
     ["Show a clause body, not only its head" cocolog-toggle-clause-detail
      :style toggle :selected (eq cocolog-graph-clause-detail 'full)
      :help "Print the whole clause in the graph instead of its head"]
     "---"
     "---"
     ["Draw the graphs of this buffer again" cocolog-run-all-tests
      :help "A change of style shows up the next time a graph is drawn"])

    ("Move"
     ["Beginning of this clause" cocolog-beginning-of-clause
      :help "Go to the first character of the clause point is in"]
     ["End of this clause" cocolog-end-of-clause
      :help "Go past the period that ends the clause point is in"])

    "---"
    ["Check the syntax of the buffer" cocolog-check-buffer
     :help "List the clauses that do not parse"]
    "---"
    ["Customize cocolog..." (customize-group 'cocolog)
     :help "Every setting of the mode, with what each one does"]
    ["Describe cocolog mode" describe-mode
     :help "The help of the mode: every key, and what it is for"])
  "The Coco menu.  Also walked by the test that keeps it complete.")

(easy-menu-define cocolog-mode-menu cocolog-mode-map
  "The Coco menu of `cocolog-mode'."
  cocolog-mode-menu-spec)

(defun cocolog--maybe-run-tests-on-save ()
  (when cocolog-run-tests-on-save (ignore-errors (cocolog-run-all-tests))))

;;;###autoload
(define-derived-mode cocolog-mode prog-mode "Cocolog"
  "Major mode for Prolog with colour variables and inline execution graphs.

Colours, and names
------------------
\\[cocolog-insert-color-variable] opens a palette; the colour you pick
becomes a variable.  Picking the same colour again in the same clause
means the same variable.

A variable is called after its colour -- crimson, gold -- until you give
it a name of your own with \\[cocolog-name-variable-at-point], or by
pressing `n\=' in the palette.  The name is written after the colour, so
`Ce6194b_Parent\=' is the crimson variable called Parent, and two
variables of a similar colour still read apart.

Ordinary variables are coloured too, on screen only: `Grandad\=' keeps
its plain name in the file and is drawn in a colour of its own for as
long as the buffer is open.  \\[cocolog-shuffle-colors] deals another
hand of colours and \\[cocolog-toggle-plain-colors] turns that off.
Use \\[cocolog-toggle-auto-color] when you would rather have the colour
written into the file, as `Ce6194b_Grandad\='.

\\[cocolog-recolor-variable-at-point] changes the colour of the variable
at point everywhere in its clause and keeps its name,
\\[cocolog-uncolor-variable-at-point] drops the colour again and
\\[cocolog-colorize-clause] gives every variable of the clause a colour
while keeping the names they have.  \\[cocolog-cycle-swatch-style] switches between a plain swatch,
the colour name and the underlying text, and \\[cocolog-clause-legend]
lists the colours of the current clause.

Test cases and graphs
---------------------
Write a test case as a comment next to a rule:

    %% ?- ancestor(tom, X).
    ancestor(X, Z) :- parent(X, Y), ancestor(Y, Z).

\\[cocolog-run-test-at-point] runs it and writes the execution graph
below the rule as comments; \\[cocolog-run-all-tests] does the whole
buffer and \\[cocolog-clear-trace-at-point] removes a graph again.
\\[cocolog-query] asks a one-off query instead.

\\{cocolog-mode-map}"
  :syntax-table cocolog-mode-syntax-table
  (setq-local case-fold-search nil)
  (setq-local syntax-propertize-function cocolog--syntax-propertize)
  (setq-local parse-sexp-lookup-properties t)
  (setq-local comment-start "% ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "%+[ \t]*")
  (setq-local comment-column 48)
  (setq-local parse-sexp-ignore-comments t)
  (setq-local font-lock-defaults '(cocolog-font-lock-keywords nil nil nil))
  (setq-local font-lock-extra-managed-props
              '(display cursor-intangible help-echo))
  (setq-local indent-line-function #'cocolog-indent-line)
  (setq-local electric-indent-chars '(?\n))
  (setq-local imenu-generic-expression
              '((nil "^\\([a-z][A-Za-z0-9_]*\\)\\s-*\\(?:(\\|:-\\|\\.\\)" 1)))
  (setq-local beginning-of-defun-function #'cocolog-beginning-of-clause)
  (setq-local end-of-defun-function #'cocolog-end-of-clause)
  ;; A swatch keeps point out of itself, but that must not rub off on
  ;; what is typed after it: without this, the comma you type next
  ;; inherits the property and cannot be reached to be deleted.
  (setq-local text-property-default-nonsticky
              (append '((cursor-intangible . t) (help-echo . t))
                      text-property-default-nonsticky))
  (cursor-intangible-mode 1)
  (add-hook 'post-self-insert-hook #'cocolog--post-self-insert nil t)
  ;; A file gets its own hand of colours each time it is opened.  A buffer
  ;; that is not a file does not: Markdown fontifies a code block by
  ;; running this mode in a scratch buffer of its own, and if that dealt
  ;; its own hand the block would come out in two sets of colours.
  (setq cocolog--color-seed (if buffer-file-name (random 100000) 0))
  (add-hook 'after-change-functions #'cocolog--forget-plain-colors nil t)
  (add-hook 'after-change-functions #'cocolog--schedule-graph-refresh nil t)
  (add-hook 'before-save-hook #'cocolog--maybe-run-tests-on-save nil t))

(defun cocolog-beginning-of-clause (&optional _arg)
  "Move to the beginning of the current clause."
  (interactive)
  (let ((prev (cocolog--previous-clause-end (point))))
    (if (null prev)
        (goto-char (point-min))
      (goto-char prev)
      (skip-chars-forward " \t\n")
      (while (and (not (eobp)) (looking-at-p "[ \t]*%")) (forward-line 1)))))

(defun cocolog-end-of-clause (&optional _arg)
  "Move past the end of the current clause."
  (interactive)
  (let ((res nil))
    (while (and (not res) (re-search-forward "\\.\\([ \t\n\r]\\|\\'\\)" nil t))
      (unless (nth 8 (cocolog--syntax (match-beginning 0)))
        (setq res t)
        (goto-char (1+ (match-beginning 0)))))
    res))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.colog\\'" . cocolog-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.cocolog\\'" . cocolog-mode))

(provide 'cocolog-mode)

;;; cocolog-mode.el ends here
