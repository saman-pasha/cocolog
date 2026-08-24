;;; cocolog-graph.el --- Render a cocolog execution as an ASCII graph -*- lexical-binding: t; -*-

;;; Commentary:

;; Turns the trace recorded by `cocolog-engine' into the block of
;; comment lines that `cocolog-mode' writes underneath a rule.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'cocolog-engine)

(defcustom cocolog-graph-unicode t
  "When non-nil draw the execution graph with box drawing characters."
  :type 'boolean :group 'cocolog)

(defcustom cocolog-graph-show-clauses t
  "When non-nil show which clause was tried at every resolution step."
  :type 'boolean :group 'cocolog)

(defcustom cocolog-graph-show-failures t
  "When non-nil keep clauses whose head did not unify in the graph."
  :type 'boolean :group 'cocolog)

(defcustom cocolog-graph-collapse-failures t
  "When non-nil, merge a run of clauses whose head did not unify
into a single line of the graph."
  :type 'boolean :group 'cocolog)

(defcustom cocolog-graph-clause-detail 'head
  "How much of a clause is shown in the graph.
`head' shows only its head, `full' shows head and body."
  :type '(choice (const head) (const full))
  :group 'cocolog)

(defcustom cocolog-graph-status-column 52
  "Column (inside the graph) at which the result of a goal is printed."
  :type 'integer :group 'cocolog)

(defcustom cocolog-graph-max-width 96
  "How wide a line of a graph may be, as it stands in the file.
Everything counts: the comment prefix, the bar down the left, and the
graph itself.  What you set is what the longest line in the buffer comes
to, which is the only reading of it that helps you keep a file inside
the width you write to."
  :type 'integer :group 'cocolog)

(defvar cocolog--line-budget nil
  "How wide the graph itself may be, once the comment prefix is paid for.
Bound while a block is built; nil means the whole of
`cocolog-graph-max-width\=' is available, which is what a caller
building a bare line without a prefix wants.")

(defun cocolog--budget ()
  "How many columns a graph line has to work with."
  (or cocolog--line-budget cocolog-graph-max-width))

(defface cocolog-graph-face '((t :inherit font-lock-comment-face))
  "Face for generated graph comments."
  :group 'cocolog)

(defun cocolog--glyph (uni ascii)
  (if cocolog-graph-unicode uni ascii))

(defun cocolog--status-mark (status)
  (pcase status
    ('success (cocolog--glyph "✔" "OK "))
    ('fail    (cocolog--glyph "✘" "no "))
    ('error   (cocolog--glyph "⚠" "!! "))
    ('limit   (cocolog--glyph "⚠" "!! "))
    (_        (cocolog--glyph "·" ".. "))))

(defun cocolog--truncate (s n)
  (if (<= (length s) n) s
    (concat (substring s 0 (max 0 (1- n))) (cocolog--glyph "…" "~"))))

(defun cocolog--graph-line (prefix branch label status detail)
  "Assemble one graph line out of PREFIX, BRANCH, LABEL, STATUS and DETAIL."
  (let ((left (concat prefix branch label))
        (right (string-trim-right (concat status (and detail (concat " " detail))))))
    (string-trim-right
     (if (string-empty-p right)
         (cocolog--truncate left (cocolog--budget))
       ;; keep room for at least a bit of the result
       (setq left (cocolog--truncate left (- (cocolog--budget) 6)))
       (cocolog--truncate
        (concat left
                (make-string (max 1 (- cocolog-graph-status-column (length left))) ?\s)
                right)
        (cocolog--budget))))))

(defun cocolog--failed-head-p (node)
  (and (eq (cocolog-node-kind node) 'clause)
       (eq (cocolog-node-status node) 'fail)
       (null (cocolog-node-children node))))

(defun cocolog--collapse-failures (nodes)
  "Merge runs of failed head unifications in NODES into single notes."
  (if (not cocolog-graph-collapse-failures)
      nodes
    (let ((out '()) (run '()))
      (cl-flet ((flush ()
                  (cond
                   ((null run) nil)
                   ((null (cdr run)) (push (car run) out))
                   (t (let ((n (cocolog--node-create
                                :kind 'note
                                :label (format "%s%s no matching head"
                                               (cocolog--glyph "▸" ">")
                                               (mapconcat
                                                (lambda (x)
                                                  (replace-regexp-in-string
                                                   "clause " "" (cocolog-node-label x)))
                                                (reverse run) ","))
                                :depth (cocolog-node-depth (car run))
                                :finished t)))
                        (setf (cocolog-node-status n) 'fail)
                        (push n out))))
                  (setq run '())))
        (dolist (c nodes)
          (if (cocolog--failed-head-p c)
              (push c run)
            (flush)
            (push c out)))
        (flush))
      (nreverse out))))

(defun cocolog--visible-children (node)
  "Children of NODE, honouring `cocolog-graph-show-clauses' and friends."
  (let ((kids (cocolog-node-children (cocolog--node-finish node)))
        (out '()))
    (setq kids (cocolog--collapse-failures kids))
    (dolist (c kids (nreverse out))
      (cond
       ((and (eq (cocolog-node-kind c) 'clause) (not cocolog-graph-show-clauses))
        (if (eq (cocolog-node-status c) 'fail)
            (when (and cocolog-graph-show-failures (cocolog-node-children c))
              (dolist (g (cocolog--visible-children c)) (push g out)))
          (dolist (g (cocolog--visible-children c)) (push g out))))
       ((and (eq (cocolog-node-kind c) 'clause)
             (eq (cocolog-node-status c) 'fail)
             (null (cocolog-node-children c))
             (not cocolog-graph-show-failures))
        nil)
       (t (push c out))))))

(defun cocolog--node-label (node)
  (pcase (cocolog-node-kind node)
    ('clause
     (let ((text (or (cocolog-node-detail node) "")))
       ;; a grammar rule is shown whole: its head says almost nothing,
       ;; the list it describes is in the body
       (when (and (eq cocolog-graph-clause-detail 'head)
                  (string-match " :- " text)
                  (not (string-match-p " --> " text)))
         (setq text (concat (substring text 0 (match-beginning 0))
                            " :- " (cocolog--glyph "…" "..."))))
       (concat (cocolog--glyph "▸" ">")
               (replace-regexp-in-string "clause " "" (cocolog-node-label node))
               " " text)))
    (_ (cocolog-node-label node))))

(defun cocolog--node-status-text (node)
  "Return (MARK . DETAIL) describing the outcome of NODE."
  (let* ((status (or (cocolog-node-status node)
                     (and (cocolog-node-exits node) 'success)))
         (exits (cocolog-node-exits (cocolog--node-finish node)))
         (mark (cocolog--status-mark status))
         (n (length exits))
         (detail
          (cond
           ((memq status '(error limit)) (cocolog-node-detail node))
           ((and exits (eq (cocolog-node-kind node) 'call))
            (let ((uniq (delete-dups (copy-sequence exits))))
              (concat (if (> n 1) (format "%s%d " (cocolog--glyph "×" "x") n) "")
                      (if (equal uniq (list (cocolog-node-label node)))
                          ""
                        (mapconcat #'identity uniq " ; ")))))
           ((and (eq (cocolog-node-kind node) 'control) (cocolog-node-detail node))
            (cocolog-node-detail node))
           (t nil))))
    (cons mark (and detail (string-trim detail)))))

(defun cocolog--render-node (node prefix last lines)
  "Render NODE and its subtree, pushing strings onto LINES (a cons cell)."
  (let* ((branch (if (string-empty-p prefix)
                     ""
                   (if last (cocolog--glyph "╰── " "`-- ") (cocolog--glyph "├── " "|-- "))))
         (st (cocolog--node-status-text node)))
    (push (cocolog--graph-line prefix branch (cocolog--node-label node)
                               (car st) (cdr st))
          (car lines))
    (let* ((kids (cocolog--visible-children node))
           (child-prefix (if (string-empty-p prefix)
                             ""
                           (concat prefix (if last "    " (cocolog--glyph "│   " "|   ")))))
           (n (length kids))
           (i 0))
      (dolist (c kids)
        (cl-incf i)
        (cocolog--render-node c (if (string-empty-p prefix) " " child-prefix)
                              (= i n) lines)))))

(defun cocolog-graph-lines (result)
  "Return the execution graph of RESULT as a list of plain strings."
  (let* ((lines (list '()))
         (root (cocolog--node-finish (cocolog-result-root result)))
         (kids (cocolog--visible-children root))
         (n (length kids))
         (i 0))
    (dolist (c kids)
      (cl-incf i)
      (cocolog--render-node c "" (= i n) lines))
    (nreverse (car lines))))

(defun cocolog--solution-lines (result)
  (let ((out '()) (i 0))
    (dolist (sol (cocolog-result-solutions result))
      (cl-incf i)
      (push (format "%s solution %d:%s"
                    (cocolog--glyph "✔" "OK") i
                    (if sol
                        (concat "  " (mapconcat (lambda (b)
                                                  (format "%s = %s" (car b) (cdr b)))
                                                sol ",  "))
                      "  true"))
            out))
    (nreverse out)))

(defun cocolog-graph-summary (result)
  "One line summarising RESULT."
  (let* ((n (length (cocolog-result-solutions result)))
         (status (cocolog-result-status result)))
    (concat
     (pcase status
       ('error (format "error: %s" (cocolog-result-message result)))
       ('limit (format "stopped: %s" (cocolog-result-message result)))
       ('more  (format "%d solutions (more may exist)" n))
       (_ (pcase n
            (0 "no solutions")
            (1 "1 solution")
            (_ (format "%d solutions" n)))))
     (format " %s %d inferences" (cocolog--glyph "·" "-")
             (cocolog-result-inferences result))
     (if (cocolog-result-truncated result)
         (format " %s graph truncated" (cocolog--glyph "·" "-")) "")
     ;; a branch given up on for being too deep fails, and a failure that
     ;; is really "I stopped looking" must not read as an answer
     (if (cocolog-result-depth-cut result)
         (format " %s gave up below depth %d (cocolog-max-depth)"
                 (cocolog--glyph "·" "-") cocolog-max-depth)
       ""))))

(defun cocolog-graph-block (result &optional prefix)
  "Return the full comment block for RESULT as a list of strings.
PREFIX defaults to \"%% \" and is prepended to every line."
  (let* ((prefix (or prefix "%% "))
         (bar (cocolog--glyph "│ " "| "))
         ;; the width in the setting is the width in the file, so the
         ;; prefix and the bar come out of it before the graph is drawn
         (cocolog--line-budget (max 20 (- cocolog-graph-max-width
                                          (length prefix) (length bar))))
         (out '()))
    (push (concat prefix (cocolog--glyph "╭── " "+-- ") "cocolog trace "
                  (cocolog--glyph "── " "-- ")
                  "?- " (string-trim (cocolog-node-label (cocolog-result-root result))))
          out)
    (dolist (l (cocolog-graph-lines result))
      (push (string-trim-right (concat prefix bar l)) out))
    (when (cocolog-result-output result)
      (push (string-trim-right (concat prefix bar)) out)
      (dolist (l (split-string (string-trim-right (cocolog-result-output result)) "\n"))
        (push (concat prefix bar "output: " l) out)))
    (let ((sols (cocolog--solution-lines result)))
      (when sols
        (push (string-trim-right (concat prefix bar)) out)
        (dolist (l sols) (push (concat prefix bar l) out))))
    (when (and (memq (cocolog-result-status result) '(error limit))
               (cocolog-result-message result))
      (push (string-trim-right (concat prefix bar)) out)
      (push (concat prefix bar (cocolog--glyph "⚠ " "!! ")
                    (cocolog-result-message result))
            out))
    (push (concat prefix (cocolog--glyph "╰── " "+-- ")
                  "cocolog: " (cocolog-graph-summary result))
          out)
    (nreverse out)))

(provide 'cocolog-graph)

;;; cocolog-graph.el ends here
