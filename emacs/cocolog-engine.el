;;; cocolog-engine.el --- Prolog reader, writer and solver for cocolog-mode -*- lexical-binding: t; -*-

;; Author: cocolog-mode
;; Keywords: languages, prolog
;; Package-Requires: ((emacs "27.1"))

;;; Commentary:

;; A small, self-contained Prolog engine written in Emacs Lisp.  It is
;; used by `cocolog-mode' to execute the test cases a developer writes
;; in comments and to build a graph (an SLD tree) of that execution.
;;
;; The engine is deliberately independent from any external Prolog
;; system: everything runs inside Emacs so the trace can be recorded
;; exactly as the graph renderer wants it.
;;
;; Term representation:
;;
;;   number     -> Emacs Lisp number
;;   atom       -> Emacs Lisp symbol            (foo, [], 'hello world')
;;   variable   -> `cocolog-var' struct         (mutable, trailed)
;;   compound   -> (FUNCTOR-SYMBOL . ARGS-LIST) (f(a,b) -> (f a b))
;;
;; Lists are ordinary '.'/2 compounds ending in the atom [].

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(define-error 'cocolog-error "cocolog error")
(define-error 'cocolog-syntax-error "cocolog syntax error" 'cocolog-error)
(define-error 'cocolog-limit "cocolog resource limit exceeded" 'cocolog-error)

(defgroup cocolog nil
  "Prolog with colour-named variables."
  :group 'languages
  :prefix "cocolog-")

(defcustom cocolog-max-inferences 60000
  "Abort a query after this many resolution steps."
  :type 'integer :group 'cocolog)

(defcustom cocolog-max-depth 1000
  "Maximum resolution depth; a branch deeper than this fails.
Ordinary Prolog recurses: counting down from 500, or walking a list of
200, goes deeper than a first guess at this number would allow, and a
branch cut short here fails, which reads exactly like a program that is
wrong.  So it is set well above what a program does on purpose and left
to `cocolog-max-inferences\=' to stop a runaway, which it does in a
couple of seconds.  When this does bite, the answer says so rather than
reporting no solutions and leaving it at that.

There is a ceiling: the solver recurses as it goes, so a few thousand
here reaches the limit of the Lisp stack.  That is reported as an
error."
  :type 'integer :group 'cocolog)

(defcustom cocolog-max-seconds 5
  "Give up on a query after this many seconds of work.
The other limits count what the engine does, not how long it takes, and
the two are not the same: a program building an ever longer term costs
more with every step it takes.  This one is the promise that the editor
comes back, whatever the program is doing.  Set it to nil to count steps
alone."
  :type '(choice (const :tag "No limit" nil) number)
  :group 'cocolog)

(defcustom cocolog-max-solutions 10
  "Maximum number of solutions collected for one test case."
  :type 'integer :group 'cocolog)

;;;; ------------------------------------------------------------------
;;;; Terms
;;;; ------------------------------------------------------------------

(defconst cocolog--unbound (make-symbol "cocolog-unbound")
  "Marker stored in the value slot of an unbound variable.")

(defvar cocolog--depth-cut nil
  "Set while a query runs when a branch was cut for being too deep.
A cut branch fails, and a failure that is really \"I stopped looking\"
has to say so: without this the answer would be a plain no.")

(defvar cocolog--var-counter 0)

(cl-defstruct (cocolog-var (:constructor cocolog--var-make (&optional name))
                           (:copier nil))
  (name nil)
  (id (cl-incf cocolog--var-counter))
  (val cocolog--unbound))

(defconst cocolog-nil (intern "[]") "The Prolog atom [].")
(defconst cocolog-dot (intern ".") "The Prolog list functor.")
(defconst cocolog-curly (intern "{}") "The Prolog atom {}.")
(defconst cocolog-comma (intern ",") "The Prolog conjunction functor.")

(defsubst cocolog-compound-p (x) (consp x))
(defsubst cocolog-atom-p (x) (symbolp x))
(defsubst cocolog-functor (x) (car x))
(defsubst cocolog-args (x) (cdr x))
(defsubst cocolog-arity (x) (length (cdr x)))

(defun cocolog-mk (functor &rest args)
  "Build the term FUNCTOR(ARGS...); with no ARGS return the atom FUNCTOR."
  (if args (cons functor args) functor))

(defun cocolog-deref (x)
  "Follow variable bindings of X until an unbound var or a non-var."
  (while (and (cocolog-var-p x)
              (not (eq (cocolog-var-val x) cocolog--unbound)))
    (setq x (cocolog-var-val x)))
  x)

(defun cocolog-list (elements &optional tail)
  "Build a Prolog list of ELEMENTS ending with TAIL (default [])."
  (let ((res (or tail cocolog-nil)))
    (dolist (e (reverse elements) res)
      (setq res (list cocolog-dot e res)))))

(defun cocolog-list-to-lisp (term)
  "Convert the Prolog list TERM to a Lisp list, or return `:not-a-list'."
  (let ((res '()) (x (cocolog-deref term)) (done nil) (ok t))
    (while (not done)
      (cond
       ((eq x cocolog-nil) (setq done t))
       ((and (cocolog-compound-p x) (eq (cocolog-functor x) cocolog-dot)
             (= (cocolog-arity x) 2))
        (push (cocolog-deref (nth 1 x)) res)
        (setq x (cocolog-deref (nth 2 x))))
       (t (setq done t ok nil))))
    (if ok (nreverse res) :not-a-list)))

(defun cocolog-term-vars (term &optional acc)
  "Return the free variables of TERM, in first-occurrence order.
ACC is an accumulator used by recursive calls."
  (let ((x (cocolog-deref term)))
    (cond
     ((cocolog-var-p x) (if (memq x acc) acc (cons x acc)))
     ((cocolog-compound-p x)
      (dolist (a (cocolog-args x) acc) (setq acc (cocolog-term-vars a acc))))
     (t acc))))

(defun cocolog-copy-term (term &optional map)
  "Return a copy of TERM with fresh variables.
MAP, when given, must be a hash table reused across calls."
  (let ((map (or map (make-hash-table :test 'eq))))
    (cocolog--copy-1 term map)))

(defun cocolog--copy-1 (term map)
  (let ((x (cocolog-deref term)))
    (cond
     ((cocolog-var-p x)
      (or (gethash x map)
          (puthash x (cocolog--var-make (cocolog-var-name x)) map)))
     ((cocolog-compound-p x)
      (cons (cocolog-functor x)
            (mapcar (lambda (a) (cocolog--copy-1 a map)) (cocolog-args x))))
     (t x))))

;;;; ------------------------------------------------------------------
;;;; Trail and unification
;;;; ------------------------------------------------------------------

(defvar cocolog--trail nil "List of variables bound since the start of the query.")

(defsubst cocolog--mark () cocolog--trail)

(defun cocolog--undo-to (mark)
  "Undo every binding made after MARK."
  (while (not (eq cocolog--trail mark))
    (setf (cocolog-var-val (car cocolog--trail)) cocolog--unbound)
    (setq cocolog--trail (cdr cocolog--trail))))

(defsubst cocolog--bind (var val)
  (setf (cocolog-var-val var) val)
  (push var cocolog--trail))

(defun cocolog-unify (a b)
  "Unify terms A and B, binding variables destructively.
 Return non-nil on success."
  (let ((a (cocolog-deref a)) (b (cocolog-deref b)))
    (cond
     ((eq a b) t)
     ((cocolog-var-p a) (cocolog--bind a b) t)
     ((cocolog-var-p b) (cocolog--bind b a) t)
     ((and (numberp a) (numberp b)) (and (= a b) (eq (floatp a) (floatp b))))
     ((and (cocolog-compound-p a) (cocolog-compound-p b))
      (and (eq (cocolog-functor a) (cocolog-functor b))
           (= (cocolog-arity a) (cocolog-arity b))
           (let ((xs (cocolog-args a)) (ys (cocolog-args b)) (ok t))
             (while (and ok xs)
               (setq ok (cocolog-unify (car xs) (car ys))
                     xs (cdr xs) ys (cdr ys)))
             ok)))
     (t (equal a b)))))

;;;; ------------------------------------------------------------------
;;;; Standard order of terms
;;;; ------------------------------------------------------------------

(defun cocolog--type-rank (x)
  (cond ((cocolog-var-p x) 0)
        ((numberp x) 1)
        ((cocolog-atom-p x) 3)
        (t 4)))

(defun cocolog-compare (a b)
  "Compare A and B in the standard order of terms; return -1, 0 or 1."
  (let* ((a (cocolog-deref a)) (b (cocolog-deref b))
         (ra (cocolog--type-rank a)) (rb (cocolog--type-rank b)))
    (cond
     ((/= ra rb) (if (< ra rb) -1 1))
     ((cocolog-var-p a)
      (let ((ia (cocolog-var-id a)) (ib (cocolog-var-id b)))
        (cond ((= ia ib) 0) ((< ia ib) -1) (t 1))))
     ((numberp a) (cond ((= a b) 0) ((< a b) -1) (t 1)))
     ((cocolog-atom-p a)
      (let ((sa (symbol-name a)) (sb (symbol-name b)))
        (cond ((string= sa sb) 0) ((string< sa sb) -1) (t 1))))
     (t
      (let ((na (cocolog-arity a)) (nb (cocolog-arity b)))
        (cond
         ((/= na nb) (if (< na nb) -1 1))
         (t (let ((c (cocolog-compare (cocolog-functor a) (cocolog-functor b))))
              (if (/= c 0) c
                (let ((xs (cocolog-args a)) (ys (cocolog-args b)) (r 0))
                  (while (and (= r 0) xs)
                    (setq r (cocolog-compare (car xs) (car ys))
                          xs (cdr xs) ys (cdr ys)))
                  r))))))))))

;;;; ------------------------------------------------------------------
;;;; Operator table
;;;; ------------------------------------------------------------------

(defconst cocolog-operators
  '((":-"   (1200 xfx) (1200 fx))
    ("-->"  (1200 xfx))
    ("?-"   (1200 fx))
    ("dynamic" (1150 fx)) ("discontiguous" (1150 fx)) ("initialization" (1150 fx))
    (";"    (1100 xfy))
    ("|"    (1100 xfy))
    ("->"   (1050 xfy))
    ("*->"  (1050 xfy))
    (","    (1000 xfy))
    ("\\+"  (900 fy))
    ("="    (700 xfx)) ("\\="  (700 xfx))
    ("=="   (700 xfx)) ("\\==" (700 xfx))
    ("@<"   (700 xfx)) ("@>"   (700 xfx)) ("@=<" (700 xfx)) ("@>=" (700 xfx))
    ("=.."  (700 xfx)) ("is"   (700 xfx))
    ("=:="  (700 xfx)) ("=\\=" (700 xfx))
    ("<"    (700 xfx)) (">"    (700 xfx)) ("=<" (700 xfx)) (">=" (700 xfx))
    (":"    (600 xfy))
    ("+"    (500 yfx) (200 fy)) ("-" (500 yfx) (200 fy))
    ("/\\"  (500 yfx)) ("\\/"  (500 yfx)) ("xor" (500 yfx))
    ("*"    (400 yfx)) ("/"    (400 yfx)) ("//"  (400 yfx))
    ("rem"  (400 yfx)) ("mod"  (400 yfx)) ("div" (400 yfx))
    ("<<"   (400 yfx)) (">>"   (400 yfx))
    ("**"   (200 xfx)) ("^"    (200 xfy))
    ("\\"   (200 fy))
    ("$"    (1 fx)))
  "Operator table: (NAME (PRIORITY TYPE) ...).")

(defun cocolog--op (name kind)
  "Return (PRIORITY TYPE) for operator NAME of KIND `prefix', `infix' or `postfix'."
  (let ((entry (assoc name cocolog-operators)) (res nil))
    (dolist (spec (cdr entry) res)
      (let ((type (nth 1 spec)))
        (when (eq kind (cond ((memq type '(fx fy)) 'prefix)
                             ((memq type '(xf yf)) 'postfix)
                             (t 'infix)))
          (setq res spec))))))

;;;; ------------------------------------------------------------------
;;;; Tokenizer
;;;; ------------------------------------------------------------------

(defconst cocolog--symbol-chars "+-*/\\^<>=~:.?@#&$"
  "Characters that make up symbolic atoms.")

(defvar cocolog--src "")
(defvar cocolog--pos 0)
(defvar cocolog--len 0)
(defvar cocolog--tok nil "Current token: (TYPE VALUE LAYOUT-BEFORE START).")
(defvar cocolog--varmap nil "Alist of NAME -> variable for the term being read.")
(defvar cocolog--var-order nil "Variable names in order of first appearance.")

(defsubst cocolog--peek-char (&optional n)
  (let ((i (+ cocolog--pos (or n 0))))
    (and (< i cocolog--len) (aref cocolog--src i))))

(defun cocolog--syntax-error (fmt &rest args)
  (signal 'cocolog-syntax-error
          (list (format "%s (at character %d)" (apply #'format fmt args) cocolog--pos))))

(defun cocolog--skip-layout ()
  "Skip whitespace and comments.  Return non-nil if anything was skipped."
  (let ((start cocolog--pos) (go t))
    (while go
      (setq go nil)
      (while (and (< cocolog--pos cocolog--len)
                  (memq (aref cocolog--src cocolog--pos) '(?\s ?\t ?\n ?\r ?\f)))
        (cl-incf cocolog--pos) (setq go t))
      (when (eq (cocolog--peek-char) ?%)
        (while (and (< cocolog--pos cocolog--len)
                    (/= (aref cocolog--src cocolog--pos) ?\n))
          (cl-incf cocolog--pos))
        (setq go t))
      (when (and (eq (cocolog--peek-char) ?/) (eq (cocolog--peek-char 1) ?*))
        (cl-incf cocolog--pos 2)
        (while (and (< cocolog--pos cocolog--len)
                    (not (and (eq (cocolog--peek-char) ?*) (eq (cocolog--peek-char 1) ?/))))
          (cl-incf cocolog--pos))
        (if (< cocolog--pos cocolog--len)
            (cl-incf cocolog--pos 2)
          (cocolog--syntax-error "unterminated block comment"))
        (setq go t)))
    (/= start cocolog--pos)))

(defun cocolog--read-escape ()
  "Read one escape sequence body (after the backslash).  Return a character or nil."
  (let ((c (cocolog--peek-char)))
    (cl-incf cocolog--pos)
    (pcase c
      (?n ?\n) (?t ?\t) (?r ?\r) (?a 7) (?b 8) (?f 12) (?v 11) (?0 0)
      (?e 27) (?s ?\s) (?\\ ?\\) (?' ?') (?\" ?\") (?` ?`)
      (?\n nil)                         ; line continuation
      (?x (let ((s cocolog--pos))
            (while (and (cocolog--peek-char)
                        (string-match-p "[0-9a-fA-F]" (string (cocolog--peek-char))))
              (cl-incf cocolog--pos))
            (prog1 (string-to-number (substring cocolog--src s cocolog--pos) 16)
              (when (eq (cocolog--peek-char) ?\\) (cl-incf cocolog--pos)))))
      (_ (if (and c (<= ?0 c ?7))
             (let ((s (1- cocolog--pos)))
               (while (and (cocolog--peek-char) (<= ?0 (cocolog--peek-char) ?7))
                 (cl-incf cocolog--pos))
               (prog1 (string-to-number (substring cocolog--src s cocolog--pos) 8)
                 (when (eq (cocolog--peek-char) ?\\) (cl-incf cocolog--pos))))
           c)))))

(defun cocolog--read-quoted (quote-char)
  "Read the body of a quoted item terminated by QUOTE-CHAR.  Return a string."
  (let ((out '()) (done nil))
    (while (not done)
      (let ((c (cocolog--peek-char)))
        (cond
         ((null c) (cocolog--syntax-error "unterminated quoted item"))
         ((eq c quote-char)
          (cl-incf cocolog--pos)
          (if (eq (cocolog--peek-char) quote-char)
              (progn (push quote-char out) (cl-incf cocolog--pos))
            (setq done t)))
         ((eq c ?\\)
          (cl-incf cocolog--pos)
          (let ((e (cocolog--read-escape))) (when e (push e out))))
         (t (push c out) (cl-incf cocolog--pos)))))
    (concat (nreverse out))))

(defun cocolog--next-token ()
  "Read the next token into `cocolog--tok'."
  (let* ((layout (cocolog--skip-layout))
         (start cocolog--pos)
         (c (cocolog--peek-char)))
    (setq cocolog--tok
          (cond
           ((null c) (list 'eof nil layout start))
           ;; end of clause: '.' followed by layout or EOF or '%'
           ((and (eq c ?.)
                 (let ((n (cocolog--peek-char 1)))
                   (or (null n) (memq n '(?\s ?\t ?\n ?\r ?\f ?%)))))
            (cl-incf cocolog--pos)
            (list 'end nil layout start))
           ((memq c '(?\( ?\) ?\[ ?\] ?{ ?} ?, ?|))
            (cl-incf cocolog--pos)
            (if (and (eq c ?|) (eq (cocolog--peek-char) ?|))
                (progn (cl-incf cocolog--pos) (list 'atom "||" layout start))
              (list 'punct (string c) layout start)))
           ((memq c '(?! ?\;))
            (cl-incf cocolog--pos)
            (list 'atom (string c) layout start))
           ((eq c ?')
            (cl-incf cocolog--pos)
            (list 'atom (cocolog--read-quoted ?') layout start))
           ((eq c ?\")
            (cl-incf cocolog--pos)
            (list 'str (cocolog--read-quoted ?\") layout start))
           ((eq c ?`)
            (cl-incf cocolog--pos)
            (list 'backq (cocolog--read-quoted ?`) layout start))
           ((and (<= ?0 c ?9)) (cocolog--read-number layout start))
           ((or (and (<= ?A c ?Z)) (eq c ?_))
            (while (and (cocolog--peek-char)
                        (string-match-p "[A-Za-z0-9_]" (string (cocolog--peek-char))))
              (cl-incf cocolog--pos))
            (list 'var (substring cocolog--src start cocolog--pos) layout start))
           ((and (<= ?a c ?z))
            (while (and (cocolog--peek-char)
                        (string-match-p "[A-Za-z0-9_]" (string (cocolog--peek-char))))
              (cl-incf cocolog--pos))
            (list 'atom (substring cocolog--src start cocolog--pos) layout start))
           ((cl-find c cocolog--symbol-chars)
            (while (and (cocolog--peek-char)
                        (cl-find (cocolog--peek-char) cocolog--symbol-chars))
              (cl-incf cocolog--pos))
            (list 'atom (substring cocolog--src start cocolog--pos) layout start))
           (t (cocolog--syntax-error "unexpected character `%c'" c))))))

(defun cocolog--read-number (layout start)
  (cond
   ;; 0'c  character code
   ((and (eq (cocolog--peek-char) ?0) (eq (cocolog--peek-char 1) ?'))
    (cl-incf cocolog--pos 2)
    (let ((c (cocolog--peek-char)))
      (cond
       ((eq c ?\\) (cl-incf cocolog--pos)
        (list 'num (or (cocolog--read-escape) 0) layout start))
       ((and (eq c ?') (eq (cocolog--peek-char 1) ?'))
        (cl-incf cocolog--pos 2) (list 'num ?' layout start))
       (t (cl-incf cocolog--pos) (list 'num c layout start)))))
   ((and (eq (cocolog--peek-char) ?0) (memq (cocolog--peek-char 1) '(?x ?o ?b)))
    (let* ((base (pcase (cocolog--peek-char 1) (?x 16) (?o 8) (_ 2)))
           (re (pcase base (16 "[0-9a-fA-F]") (8 "[0-7]") (_ "[01]"))))
      (cl-incf cocolog--pos 2)
      (let ((s cocolog--pos))
        (while (and (cocolog--peek-char)
                    (string-match-p re (string (cocolog--peek-char))))
          (cl-incf cocolog--pos))
        (list 'num (string-to-number (substring cocolog--src s cocolog--pos) base)
              layout start))))
   (t
    (while (and (cocolog--peek-char) (<= ?0 (cocolog--peek-char) ?9))
      (cl-incf cocolog--pos))
    (let ((float nil))
      (when (and (eq (cocolog--peek-char) ?.)
                 (cocolog--peek-char 1) (<= ?0 (cocolog--peek-char 1) ?9))
        (setq float t)
        (cl-incf cocolog--pos)
        (while (and (cocolog--peek-char) (<= ?0 (cocolog--peek-char) ?9))
          (cl-incf cocolog--pos)))
      (when (and (memq (cocolog--peek-char) '(?e ?E))
                 (let ((n (cocolog--peek-char 1)))
                   (or (and n (<= ?0 n ?9))
                       (and (memq n '(?+ ?-)) (cocolog--peek-char 2)
                            (<= ?0 (cocolog--peek-char 2) ?9)))))
        (setq float t)
        (cl-incf cocolog--pos 2)
        (while (and (cocolog--peek-char) (<= ?0 (cocolog--peek-char) ?9))
          (cl-incf cocolog--pos)))
      (let ((text (substring cocolog--src start cocolog--pos)))
        (list 'num (if float (string-to-number text)
                     (truncate (string-to-number text)))
              layout start))))))

;;;; ------------------------------------------------------------------
;;;; Parser
;;;; ------------------------------------------------------------------

(defsubst cocolog--tok-type () (nth 0 cocolog--tok))
(defsubst cocolog--tok-value () (nth 1 cocolog--tok))
(defsubst cocolog--tok-layout () (nth 2 cocolog--tok))

(defun cocolog--intern-var (name)
  (if (string= name "_")
      (cocolog--var-make "_")
    (or (cdr (assoc name cocolog--varmap))
        (let ((v (cocolog--var-make name)))
          (push (cons name v) cocolog--varmap)
          (push name cocolog--var-order)
          v))))

(defun cocolog--term-start-p ()
  "Non-nil when the current token can begin a term."
  (pcase (cocolog--tok-type)
    ((or 'num 'var 'str 'backq) t)
    ('atom t)
    ('punct (member (cocolog--tok-value) '("(" "[" "{")))
    (_ nil)))

(defun cocolog--expect-punct (s)
  (unless (and (eq (cocolog--tok-type) 'punct) (equal (cocolog--tok-value) s))
    (cocolog--syntax-error "expected `%s'" s))
  (cocolog--next-token))

(defun cocolog--parse-arglist ()
  "Parse a comma separated argument list; the current token is the first argument."
  (let ((args (list (car (cocolog--parse 999)))))
    (while (and (eq (cocolog--tok-type) 'punct) (equal (cocolog--tok-value) ","))
      (cocolog--next-token)
      (push (car (cocolog--parse 999)) args))
    (nreverse args)))

(defun cocolog--parse-list ()
  "Parse a list, the current token being the one after `['."
  (if (and (eq (cocolog--tok-type) 'punct) (equal (cocolog--tok-value) "]"))
      (progn (cocolog--next-token) cocolog-nil)
    (let ((items (cocolog--parse-arglist)) (tail cocolog-nil))
      (when (and (eq (cocolog--tok-type) 'punct) (equal (cocolog--tok-value) "|"))
        (cocolog--next-token)
        (setq tail (car (cocolog--parse 999))))
      (cocolog--expect-punct "]")
      (cocolog-list items tail))))

(defun cocolog--parse-primary (maxp)
  "Parse a primary term with maximum priority MAXP.  Return (TERM . PRIORITY)."
  (pcase (cocolog--tok-type)
    ('num (let ((v (cocolog--tok-value))) (cocolog--next-token) (cons v 0)))
    ('var (let ((v (cocolog--intern-var (cocolog--tok-value))))
            (cocolog--next-token) (cons v 0)))
    ('str (let ((s (cocolog--tok-value)))
            (cocolog--next-token)
            (cons (cocolog-list (append s nil)) 0)))
    ('backq (let ((s (cocolog--tok-value)))
              (cocolog--next-token)
              (cons (cocolog-list (append s nil)) 0)))
    ('punct
     (let ((v (cocolog--tok-value)))
       (cond
        ((equal v "(")
         (cocolog--next-token)
         (let ((term (car (cocolog--parse 1200))))
           (cocolog--expect-punct ")")
           (cons term 0)))
        ((equal v "[") (cocolog--next-token) (cons (cocolog--parse-list) 0))
        ((equal v "{")
         (cocolog--next-token)
         (if (and (eq (cocolog--tok-type) 'punct) (equal (cocolog--tok-value) "}"))
             (progn (cocolog--next-token) (cons cocolog-curly 0))
           (let ((term (car (cocolog--parse 1200))))
             (cocolog--expect-punct "}")
             (cons (list cocolog-curly term) 0))))
        (t (cocolog--syntax-error "unexpected `%s'" v)))))
    ('atom
     (let ((name (cocolog--tok-value)))
       (cocolog--next-token)
       (cond
        ;; functional notation: name( with no intervening layout
        ((and (eq (cocolog--tok-type) 'punct)
              (equal (cocolog--tok-value) "(")
              (not (cocolog--tok-layout)))
         (cocolog--next-token)
         (let ((args (cocolog--parse-arglist)))
           (cocolog--expect-punct ")")
           (cons (cons (intern name) args) 0)))
        ;; negative number literal
        ((and (equal name "-") (eq (cocolog--tok-type) 'num)
              (not (cocolog--tok-layout)))
         (let ((n (cocolog--tok-value)))
           (cocolog--next-token)
           (cons (- n) 0)))
        (t
         (let ((pre (cocolog--op name 'prefix)))
           (if (and pre (<= (car pre) maxp) (cocolog--term-start-p)
                    (not (and (eq (cocolog--tok-type) 'atom)
                              (cocolog--op (cocolog--tok-value) 'infix)
                              (not (cocolog--op (cocolog--tok-value) 'prefix)))))
               (let* ((p (car pre))
                      (argmax (if (eq (nth 1 pre) 'fy) p (1- p)))
                      (arg (car (cocolog--parse argmax))))
                 (cons (list (intern name) arg) p))
             (cons (intern name)
                   (if (assoc name cocolog-operators) 1201 0))))))))
    ('end (cocolog--syntax-error "unexpected end of clause"))
    ('eof (cocolog--syntax-error "unexpected end of input"))
    (_ (cocolog--syntax-error "unexpected token"))))

(defun cocolog--parse (maxp)
  "Parse a term with maximum priority MAXP.  Return (TERM . PRIORITY)."
  (let* ((prim (cocolog--parse-primary maxp))
         (left (car prim))
         (leftp (cdr prim))
         (go t))
    (while go
      (let* ((type (cocolog--tok-type))
             (name (cond ((eq type 'atom) (cocolog--tok-value))
                         ((and (eq type 'punct)
                               (member (cocolog--tok-value) '("," "|")))
                          (cocolog--tok-value))
                         (t nil)))
             (inf (and name (cocolog--op name 'infix))))
        (if (not (and inf (<= (car inf) maxp)))
            (setq go nil)
          (let* ((p (car inf)) (type2 (nth 1 inf))
                 (lmax (if (eq type2 'yfx) p (1- p)))
                 (rmax (if (eq type2 'xfy) p (1- p))))
            (if (> leftp lmax)
                (setq go nil)
              (cocolog--next-token)
              (let ((right (car (cocolog--parse rmax))))
                (setq left (list (intern (if (equal name "|") ";" name)) left right)
                      leftp p)))))))
    (cons left leftp)))

(cl-defstruct (cocolog-clause (:constructor cocolog--clause-make))
  head body start end text dcg)

(defun cocolog-read-term (source &optional pos)
  "Read one term from SOURCE starting at POS.
Return a plist (:term T :vars ALIST :order NAMES :start S :end E) or nil at EOF."
  (let ((cocolog--src source)
        (cocolog--pos (or pos 0))
        (cocolog--len (length source))
        (cocolog--varmap nil)
        (cocolog--var-order nil)
        (cocolog--tok nil))
    (cocolog--next-token)
    (if (eq (cocolog--tok-type) 'eof)
        nil
      (let ((start (nth 3 cocolog--tok))
            (term (car (cocolog--parse 1200))))
        (unless (eq (cocolog--tok-type) 'end)
          (cocolog--syntax-error "operator expected before `%s'"
                                 (or (cocolog--tok-value) (cocolog--tok-type))))
        (list :term term
              :vars (reverse cocolog--varmap)
              :order (reverse cocolog--var-order)
              :start start
              :end cocolog--pos)))))

(defun cocolog-read-program (source)
  "Read every clause in SOURCE.
Return a list of plists, as `cocolog-read-term' does."
  (let ((pos 0) (res '()) (go t))
    (while go
      (let ((r (cocolog-read-term source pos)))
        (if (null r)
            (setq go nil)
          (push r res)
          (setq pos (plist-get r :end)))))
    (nreverse res)))

;;;; ------------------------------------------------------------------
;;;; Writer
;;;; ------------------------------------------------------------------

(defun cocolog--atom-needs-quotes-p (name)
  (not (or (string-match-p "\\`[a-z][A-Za-z0-9_]*\\'" name)
           (and (> (length name) 0)
                (cl-every (lambda (c) (cl-find c cocolog--symbol-chars)) name))
           (member name '("[]" "{}" "!" ";" "," "|")))))

(defun cocolog--quote-atom (name)
  (if (cocolog--atom-needs-quotes-p name)
      (concat "'" (replace-regexp-in-string
                   "\n" "\\\\n"
                   (replace-regexp-in-string "\\(['\\\\]\\)" "\\\\\\1" name))
              "'")
    name))

(defvar cocolog-write-quoted t
  "When non-nil, quote atoms that need it while writing terms.")

(defun cocolog-term-to-string (term &optional maxp)
  "Render TERM as Prolog source text.  MAXP is the surrounding priority."
  (cocolog--write term (or maxp 1200)))

(defun cocolog--var-print-name (v)
  "Print name of the variable V.
Named variables keep their name, anonymous ones stay anonymous, and
variables created by the engine get a generated name."
  (let ((n (cocolog-var-name v)))
    (cond ((null n) (format "_G%d" (cocolog-var-id v)))
          ((string= n "_") "_")
          (t n))))

(defun cocolog--write (term maxp)
  (let ((x (cocolog-deref term)))
    (cond
     ((cocolog-var-p x) (cocolog--var-print-name x))
     ((integerp x) (number-to-string x))
     ((numberp x) (let ((s (number-to-string x)))
                    (if (string-match-p "[.e]" s) s (concat s ".0"))))
     ((cocolog-atom-p x)
      (let* ((name (symbol-name x))
             (s (if cocolog-write-quoted (cocolog--quote-atom name) name)))
        (if (and (assoc name cocolog-operators) (< maxp 1201)
                 (not (member name '("[]" "{}" "!"))))
            (concat "(" s ")")
          s)))
     ((and (eq (cocolog-functor x) cocolog-dot) (= (cocolog-arity x) 2))
      (cocolog--write-list x))
     ((and (eq (cocolog-functor x) cocolog-curly) (= (cocolog-arity x) 1))
      (concat "{" (cocolog--write (nth 1 x) 1200) "}"))
     (t
      (let* ((name (symbol-name (cocolog-functor x)))
             (args (cocolog-args x))
             (n (length args)))
        (cond
         ((and (= n 2) (cocolog--op name 'infix))
          (let* ((spec (cocolog--op name 'infix))
                 (p (car spec)) (type (nth 1 spec))
                 (lmax (if (eq type 'yfx) p (1- p)))
                 (rmax (if (eq type 'xfy) p (1- p)))
                 (sep (if (string-match-p "\\`[a-z]" name) " "
                        (if (equal name ",") "" " ")))
                 (body (concat (cocolog--write (nth 0 args) lmax)
                               sep (if cocolog-write-quoted
                                       (cocolog--quote-atom name) name)
                               (if (equal name ",") " " sep)
                               (cocolog--write (nth 1 args) rmax))))
            (if (> p maxp) (concat "(" body ")") body)))
         ((and (= n 1) (cocolog--op name 'prefix)
               (not (member name '("-" "+"))))
          (let* ((spec (cocolog--op name 'prefix))
                 (p (car spec))
                 (amax (if (eq (nth 1 spec) 'fy) p (1- p)))
                 (body (concat name
                               (if (string-match-p "\\`[a-z\\\\]" name) " " "")
                               (cocolog--write (nth 0 args) amax))))
            (if (> p maxp) (concat "(" body ")") body)))
         ((and (= n 1) (member name '("-" "+")))
          (let* ((inner (cocolog-deref (nth 0 args)))
                 (body (concat name
                               (if (numberp inner) " " "")
                               (cocolog--write inner 200))))
            (if (> 200 maxp) (concat "(" body ")") body)))
         (t
          (concat (if cocolog-write-quoted (cocolog--quote-atom name) name)
                  "("
                  (mapconcat (lambda (a) (cocolog--write a 999)) args ", ")
                  ")"))))))))

(defun cocolog--write-list (x)
  (let ((parts '()) (cur x) (go t) (tail nil))
    (while go
      (setq cur (cocolog-deref cur))
      (cond
       ((and (cocolog-compound-p cur) (eq (cocolog-functor cur) cocolog-dot)
             (= (cocolog-arity cur) 2))
        (push (cocolog--write (nth 1 cur) 999) parts)
        (setq cur (nth 2 cur)))
       ((eq cur cocolog-nil) (setq go nil))
       (t (setq tail (cocolog--write cur 999) go nil))))
    (concat "[" (mapconcat #'identity (nreverse parts) ", ")
            (if tail (concat "|" tail) "") "]")))


;;;; ------------------------------------------------------------------
;;;; Database
;;;; ------------------------------------------------------------------

(cl-defstruct (cocolog-db (:constructor cocolog--db-make))
  (preds (make-hash-table :test 'equal))   ; "name/arity" -> list of clause records
  (order '())                              ; clause records, in source order
  (errors '()))                            ; list of (POSITION . MESSAGE)

(defun cocolog--indicator (term)
  "Return the predicate indicator \"name/arity\" of goal TERM."
  (let ((x (cocolog-deref term)))
    (cond
     ((cocolog-compound-p x)
      (format "%s/%d" (symbol-name (cocolog-functor x)) (cocolog-arity x)))
     ((cocolog-atom-p x) (format "%s/0" (symbol-name x)))
     (t nil))))

(defun cocolog-db-add-clause (db term &optional start end text)
  "Add the clause TERM to DB.  START, END and TEXT locate it in the source.
A grammar rule, written with `-->\=', is translated into the ordinary
clause that Prolog resolves, so the graph shows the difference lists the
rule really threads through."
  (let* ((dcg (and (cocolog-compound-p term)
                   (eq (cocolog-functor term) (intern "-->"))
                   (= (cocolog-arity term) 2)))
         (term (cocolog-dcg-translate term))
         head body)
    (if (and (cocolog-compound-p term)
             (eq (cocolog-functor term) (intern ":-"))
             (= (cocolog-arity term) 2))
        (setq head (cocolog-deref (nth 1 term)) body (nth 2 term))
      (setq head term body 'true))
    (when (or (cocolog-var-p head) (numberp head))
      (signal 'cocolog-error (list "invalid clause head")))
    (let* ((key (cocolog--indicator head))
           (rec (cocolog--clause-make :head head :body body :dcg dcg
                                      :start start :end end :text text)))
      (puthash key (append (gethash key (cocolog-db-preds db)) (list rec))
               (cocolog-db-preds db))
      (push rec (cocolog-db-order db))
      rec)))

(defun cocolog-db-clauses (db goal)
  (gethash (cocolog--indicator goal) (cocolog-db-preds db)))

(defun cocolog-db-defined-p (db goal)
  (and (gethash (cocolog--indicator goal) (cocolog-db-preds db)) t))

(defconst cocolog-library-source "
append([], L, L).
append([H|T], L, [H|R]) :- append(T, L, R).
member(X, [X|_]).
member(X, [_|T]) :- member(X, T).
memberchk(X, L) :- member(X, L), !.
reverse(L, R) :- reverse_(L, [], R).
reverse_([], A, A).
reverse_([H|T], A, R) :- reverse_(T, [H|A], R).
last([X], X) :- !.
last([_|T], X) :- last(T, X).
nth0(I, L, E) :- nth_(L, 0, I, E).
nth1(I, L, E) :- nth_(L, 1, I, E).
nth_([H|_], N, N, H).
nth_([_|T], N0, N, E) :- N1 is N0 + 1, nth_(T, N1, N, E).
select(X, [X|T], T).
select(X, [H|T], [H|R]) :- select(X, T, R).
permutation([], []).
permutation(L, [H|T]) :- select(H, L, R), permutation(R, T).
maplist(_, []).
maplist(G, [X|Xs]) :- call(G, X), maplist(G, Xs).
maplist(_, [], []).
maplist(G, [X|Xs], [Y|Ys]) :- call(G, X, Y), maplist(G, Xs, Ys).
maplist(_, [], [], []).
maplist(G, [X|Xs], [Y|Ys], [Z|Zs]) :- call(G, X, Y, Z), maplist(G, Xs, Ys, Zs).
sum_list([], 0).
sum_list([H|T], S) :- sum_list(T, S0), S is S0 + H.
max_list([X], X).
max_list([H|T], M) :- max_list(T, M0), M is max(H, M0).
min_list([X], X).
min_list([H|T], M) :- min_list(T, M0), M is min(H, M0).
numlist(L, H, []) :- L > H, !.
numlist(L, H, [L|T]) :- L1 is L + 1, numlist(L1, H, T).
exclude(_, [], []).
exclude(G, [H|T], R) :- ( call(G, H) -> R = R1 ; R = [H|R1] ), exclude(G, T, R1).
include(_, [], []).
include(G, [H|T], R) :- ( call(G, H) -> R = [H|R1] ; R = R1 ), include(G, T, R1).
append([], []).
append([L|Ls], R) :- append(L, R0, R), append(Ls, R0).

%% The grammar rules of library(dcg/basics), as far as they are needed to
%% read ordinary text: written in Prolog so that they show up in graphs
%% like any other rule.
eos([], []).
remainder(R, R, []).

digit(C) --> [C], { C >= 48, C =< 57 }.
digits([D|T]) --> digit(D), !, digits(T).
digits([]) --> [].

integer(I) --> int_codes(Cs), { atom_codes(A, Cs), atom_number(A, I) }.
int_codes([45,D|Ds]) --> [45], !, digit(D), digits(Ds).
int_codes([43,D|Ds]) --> [43], !, digit(D), digits(Ds).
int_codes([D|Ds]) --> digit(D), digits(Ds).

number(N) --> int_codes(I), number_rest(R),
              { append(I, R, Cs), atom_codes(A, Cs), atom_number(A, N) }.
number_rest(Cs) --> fraction(F), exponent(E), { append(F, E, Cs) }.
fraction([46,D|Ds]) --> [46], digit(D), !, digits(Ds).
fraction([]) --> [].
exponent([C|Cs]) --> exp_char(C), !, int_codes(Cs).
exponent([]) --> [].
exp_char(101) --> [101].
exp_char(101) --> [69].

float(F) --> number(F), { float(F) }.

blank --> [C], { C =< 32 }.
blanks --> blank, !, blanks.
blanks --> [].
white --> [C], { C =:= 32 ; C =:= 9 }.
whites --> white, !, whites.
whites --> [].
nonblank(C) --> [C], { C > 32 }.
nonblanks([C|T]) --> [C], { C > 32 }, !, nonblanks(T).
nonblanks([]) --> [].
blanks_to_nl --> whites, eol.
blanks_to_nl --> whites, eos.
eol --> [10].
eol --> [13, 10].

string([]) --> [].
string([C|T]) --> [C], string(T).
string_without(End, [C|T]) --> [C], { \\+ memberchk(C, End) }, !, string_without(End, T).
string_without(_, []) --> [].

csym(Name, Head, Tail) :- nonvar(Name), !, atom_codes(Name, Cs), append(Cs, Tail, Head).
csym(Name) --> [F], { csymf_code(F) }, csyms(Rest), { atom_codes(Name, [F|Rest]) }.
csyms([C|T]) --> [C], { csym_code(C) }, !, csyms(T).
csyms([]) --> [].
csymf_code(C) :- C >= 97, C =< 122.
csymf_code(C) :- C >= 65, C =< 90.
csymf_code(95).
csym_code(C) :- csymf_code(C).
csym_code(C) :- C >= 48, C =< 57.

xdigit(D) --> [C], { xdigit_code(C, D) }.
xdigit_code(C, D) :- C >= 48, C =< 57, !, D is C - 48.
xdigit_code(C, D) :- C >= 97, C =< 102, !, D is C - 87.
xdigit_code(C, D) :- C >= 65, C =< 70, D is C - 55.
xdigits([D|T]) --> xdigit(D), !, xdigits(T).
xdigits([]) --> [].
xinteger(V) --> [45], !, xdigit(D), xdigits(Ds), { mkval([D|Ds], 16, V0), V is -V0 }.
xinteger(V) --> [43], !, xdigit(D), xdigits(Ds), { mkval([D|Ds], 16, V) }.
xinteger(V) --> xdigit(D), xdigits(Ds), { mkval([D|Ds], 16, V) }.
mkval(Ds, Base, V) :- mkval(Ds, Base, 0, V).
mkval([], _, V, V).
mkval([D|T], B, V0, V) :- V1 is V0 * B + D, mkval(T, B, V1, V).

atom(A, Head, Tail) :- atom_codes(A, Cs), append(Cs, Tail, Head).

alpha_to_lower(L) --> [C], { C >= 65, C =< 90, !, L is C + 32 }.
alpha_to_lower(C) --> [C], { C >= 97, C =< 122 }.
"
  "Library predicates that are written in Prolog so they show up in traces.")

(defvar cocolog--library-db nil)

(defun cocolog-library-db ()
  "Return (and cache) the database holding `cocolog-library-source'."
  (or cocolog--library-db
      (setq cocolog--library-db (cocolog-consult-string cocolog-library-source))))

(defun cocolog-consult-string (source &optional db offset)
  "Read SOURCE and add every clause to DB (a fresh one if nil).
OFFSET is added to the recorded source positions.  Syntax errors are
collected in the `errors' slot instead of being signalled."
  (let ((db (or db (cocolog--db-make)))
        (pos 0) (len (length source)) (go t) (offset (or offset 0)))
    (while go
      (condition-case err
          (let ((r (cocolog-read-term source pos)))
            (if (null r)
                (setq go nil)
              (setq pos (plist-get r :end))
              (let ((term (plist-get r :term)))
                (if (and (cocolog-compound-p term)
                         (memq (cocolog-functor term) (list (intern ":-") (intern "?-")))
                         (= (cocolog-arity term) 1))
                    nil                 ; a directive: ignored
                  (condition-case err2
                      (cocolog-db-add-clause
                       db term
                       (+ offset (plist-get r :start))
                       (+ offset (plist-get r :end))
                       (substring source (plist-get r :start) (plist-get r :end)))
                    (cocolog-error
                     (push (cons (+ offset (plist-get r :start))
                                 (cadr err2))
                           (cocolog-db-errors db))))))))
        (cocolog-syntax-error
         (push (cons (+ offset pos) (cadr err)) (cocolog-db-errors db))
         ;; Skip to the next clause terminator and carry on.
         (let ((next (string-match "\\.[ \t\r\n]" source (min len (1+ pos)))))
           (if next (setq pos (+ next 2)) (setq go nil))))))
    (setf (cocolog-db-errors db) (nreverse (cocolog-db-errors db)))
    (setf (cocolog-db-order db) (nreverse (cocolog-db-order db)))
    db))

;;;; ------------------------------------------------------------------
;;;; Grammar rules
;;;; ------------------------------------------------------------------

;; A rule `H --> B\=' describes a list.  It is translated into a clause
;; with two extra arguments, S0 and S: the list before the rule has read
;; anything and the list left over afterwards.  Everything the rule
;; matches is the difference between the two.

(defun cocolog--dcg-extend (term s0 s)
  "Return the goal TERM with the two grammar arguments S0 and S added."
  (let ((x (cocolog-deref term)))
    (cond
     ((cocolog-compound-p x) (cons (cocolog-functor x)
                                   (append (cocolog-args x) (list s0 s))))
     ((cocolog-atom-p x) (list x s0 s))
     (t (signal 'cocolog-error
                (list (format "%s is not a nonterminal"
                              (cocolog-term-to-string x 999))))))))

(defun cocolog--dcg-terminals (items s0 s)
  "Return the goal that reads the terminals ITEMS out of S0, leaving S."
  (list (intern "=") s0 (cocolog-list items s)))

(defun cocolog--dcg-passthrough-p (body)
  "Non-nil when the grammar body BODY reads nothing off the list.
Such an element can share its neighbour\='s list variable, which keeps
the plain `S0 = S\=' goals out of the translated clause and out of the
graph."
  (let ((b (cocolog-deref body)))
    (cond
     ((eq b cocolog-nil) t)
     ((eq b 'true) t)
     ((eq b (intern "!")) t)
     ((cocolog-var-p b) nil)
     ((not (cocolog-compound-p b)) nil)
     ((and (= (cocolog-arity b) 1)
           (memq (cocolog-functor b) (list cocolog-curly (intern "\\+")
                                           (intern "not"))))
      t)
     ((and (= (cocolog-arity b) 2)
           (memq (cocolog-functor b) (list cocolog-comma (intern ";")
                                           (intern "->") (intern "*->"))))
      (and (cocolog--dcg-passthrough-p (nth 1 b))
           (cocolog--dcg-passthrough-p (nth 2 b))))
     (t nil))))

(defun cocolog--dcg-and (goal s0 s)
  "Return GOAL, followed by S0 = S unless the two are already the same."
  (if (eq s0 s) goal (list (intern ",") goal (list (intern "=") s0 s))))

(defun cocolog--dcg-body (body s0 s)
  "Translate the grammar rule body BODY into a goal from S0 to S."
  (let ((b (cocolog-deref body)))
    (cond
     ;; a variable stands for a grammar body only known at run time
     ((cocolog-var-p b) (list (intern "phrase") b s0 s))
     ((eq b cocolog-nil) (if (eq s0 s) 'true (list (intern "=") s0 s)))
     ((eq b 'true) (cocolog--dcg-and 'true s0 s))
     ((eq b (intern "!")) (cocolog--dcg-and (intern "!") s0 s))
     ((and (cocolog-compound-p b) (= (cocolog-arity b) 2)
           (memq (cocolog-functor b) (list cocolog-comma (intern ";")
                                           (intern "->") (intern "*->"))))
      (let ((op (cocolog-functor b)))
        (if (eq op cocolog-comma)
            ;; an element that reads nothing shares its neighbour's variable
            (let ((mid (cond
                        ((cocolog--dcg-passthrough-p (nth 1 b)) s0)
                        ((cocolog--dcg-passthrough-p (nth 2 b)) s)
                        (t (cocolog--var-make)))))
              (list op
                    (cocolog--dcg-body (nth 1 b) s0 mid)
                    (cocolog--dcg-body (nth 2 b) mid s)))
          (if (eq op (intern ";"))
              (list op
                    (cocolog--dcg-body (nth 1 b) s0 s)
                    (cocolog--dcg-body (nth 2 b) s0 s))
            ;; -> and *-> thread the list through both sides
            (let ((mid (cocolog--var-make)))
              (list op
                    (cocolog--dcg-body (nth 1 b) s0 mid)
                    (cocolog--dcg-body (nth 2 b) mid s)))))))
     ((and (cocolog-compound-p b) (= (cocolog-arity b) 1)
           (memq (cocolog-functor b) (list (intern "\\+") (intern "not"))))
      (cocolog--dcg-and
       (list (cocolog-functor b)
             (cocolog--dcg-body (nth 1 b) s0 (cocolog--var-make)))
       s0 s))
     ;; {Goal} is a plain Prolog goal: it reads nothing
     ((and (cocolog-compound-p b) (eq (cocolog-functor b) cocolog-curly)
           (= (cocolog-arity b) 1))
      (cocolog--dcg-and (nth 1 b) s0 s))
     ;; a list, or a string, is a run of terminals
     ((and (cocolog-compound-p b) (eq (cocolog-functor b) cocolog-dot)
           (= (cocolog-arity b) 2))
      (let ((items (cocolog-list-to-lisp b)))
        (if (eq items :not-a-list)
            (signal 'cocolog-error (list "a partial list cannot be a grammar body"))
          (cocolog--dcg-terminals items s0 s))))
     (t (cocolog--dcg-extend b s0 s)))))

(defun cocolog-dcg-translate (term)
  "Translate TERM into a clause if it is a grammar rule, else return it."
  (let ((x (cocolog-deref term)))
    (if (not (and (cocolog-compound-p x)
                  (eq (cocolog-functor x) (intern "-->"))
                  (= (cocolog-arity x) 2)))
        x
      (let* ((head (cocolog-deref (nth 1 x)))
             (body (nth 2 x))
             (s0 (cocolog--var-make "S0"))
             (s (cocolog--var-make "S"))
             pushback)
        ;; H, PB --> B  puts PB back on the list after H has read its part
        (when (and (cocolog-compound-p head) (eq (cocolog-functor head) cocolog-comma)
                   (= (cocolog-arity head) 2))
          (setq pushback (nth 2 head) head (cocolog-deref (nth 1 head))))
        (if (null pushback)
            (list (intern ":-") (cocolog--dcg-extend head s0 s)
                  (cocolog--dcg-body body s0 s))
          (let ((mid (cocolog--var-make)))
            (list (intern ":-") (cocolog--dcg-extend head s0 s)
                  (list (intern ",")
                        (cocolog--dcg-body body s0 mid)
                        (cocolog--dcg-body pushback s mid)))))))))

;;;; ------------------------------------------------------------------
;;;; Trace nodes
;;;; ------------------------------------------------------------------

(cl-defstruct (cocolog-node (:constructor cocolog--node-create))
  (kept nil)    ; nil when the graph had no room for it: nothing will be shown
  kind          ; call | clause | builtin | control | note | root
  label         ; string shown in the graph
  detail        ; extra string (clause source, exit instantiation, ...)
  depth
  (children '())
  (exits '())   ; list of strings, one per successful exit
  status        ; success | fail | error | limit
  finished)     ; non-nil once children/exits are in source order

(defvar cocolog--trace-root nil)
(defvar cocolog--trace-count 0)
(defvar cocolog--trace-truncated nil)
(defvar cocolog--inferences 0)

(defcustom cocolog-trace-max-nodes 500
  "Stop recording graph nodes after this many; solving continues."
  :type 'integer :group 'cocolog)

(defcustom cocolog-max-exits 10
  "How many times one goal in the graph shows what it came back with.
A goal inside a loop can succeed thousands of times, and writing the
term out each time costs more the bigger the term has grown -- which is
how a runaway program used to take the editor with it."
  :type 'integer :group 'cocolog)

(defun cocolog--node (kind label depth parent &optional detail)
  "Create a node and attach it to PARENT (unless the node budget is spent).

LABEL may be a function returning the label instead of the label itself.
Writing a goal out costs time in proportion to the size of the term, and
a goal whose term keeps growing -- a list being built as a program
recurses -- makes that the most expensive thing in the room.  A node the
graph has no room for is never shown, so its label is never asked for."
  (let* ((keep (and parent (< cocolog--trace-count cocolog-trace-max-nodes)))
         (n (cocolog--node-create
             :kind kind
             :label (if (and keep (functionp label)) (funcall label)
                      (and (not (functionp label)) label))
             :detail detail :depth depth :kept (and keep t))))
    (if keep
        (progn (cl-incf cocolog--trace-count)
               (push n (cocolog-node-children parent)))
      (when parent (setq cocolog--trace-truncated t)))
    n))

(defun cocolog--record-exit (node text)
  "Remember TEXT as one of the ways NODE came back, if anyone will see it.
A node the graph has no room for shows nothing, and a goal that succeeds
over and over needs only its first few: writing a term out costs time in
proportion to its size, so a goal whose term keeps growing must not be
written out once per success."
  (when (and (cocolog-node-kept node)
             (< (length (cocolog-node-exits node)) cocolog-max-exits))
    (push (if (functionp text) (funcall text) text) (cocolog-node-exits node))))

(defun cocolog--node-finish (node)
  "Put the children and exits of NODE back into chronological order."
  (unless (cocolog-node-finished node)
    (setf (cocolog-node-children node) (nreverse (cocolog-node-children node)))
    (setf (cocolog-node-exits node) (nreverse (cocolog-node-exits node)))
    (setf (cocolog-node-finished node) t))
  node)

;;;; ------------------------------------------------------------------
;;;; Arithmetic
;;;; ------------------------------------------------------------------

(defun cocolog--arith-error (fmt &rest args)
  (signal 'cocolog-error (list (apply #'format fmt args))))

(defun cocolog-eval (expr)
  "Evaluate the arithmetic expression EXPR and return an Emacs Lisp number."
  (let ((x (cocolog-deref expr)))
    (cond
     ((numberp x) x)
     ((cocolog-var-p x) (cocolog--arith-error "arguments are not sufficiently instantiated"))
     ((cocolog-atom-p x)
      (pcase (symbol-name x)
        ("pi" float-pi) ("e" float-e) ("inf" 1.0e+INF) ("nan" 0.0e+NaN)
        ("max_tagged_integer" most-positive-fixnum) ("epsilon" 2.220446049250313e-16)
        ("random" (/ (float (random 1000000)) 1000000.0))
        (name (cocolog--arith-error "unknown arithmetic constant `%s'" name))))
     ((= (cocolog-arity x) 1)
      (let ((a (cocolog-eval (nth 1 x))))
        (pcase (symbol-name (cocolog-functor x))
          ("-" (- a)) ("+" a) ("abs" (abs a)) ("sign" (if (floatp a) (float (cl-signum a)) (cl-signum a)))
          ("min" a) ("max" a)
          ("sqrt" (sqrt (float a))) ("sin" (sin a)) ("cos" (cos a)) ("tan" (tan a))
          ("asin" (asin a)) ("acos" (acos a)) ("atan" (atan a))
          ("exp" (exp a)) ("log" (if (<= a 0) (cocolog--arith-error "log of non-positive number") (log a)))
          ("float" (float a)) ("integer" (round a))
          ("float_integer_part" (ftruncate (float a)))
          ("float_fractional_part" (- (float a) (ftruncate (float a))))
          ("truncate" (truncate a)) ("round" (round a))
          ("ceiling" (ceiling a)) ("floor" (floor a))
          ("\\" (lognot (cocolog--int a)))
          ("msb" (let ((n (cocolog--int a)) (i -1)) (while (> n 0) (setq n (ash n -1)) (cl-incf i)) i))
          ("succ" (1+ (cocolog--int a)))
          ("random" (random (cocolog--int a)))
          ("random_float" (/ (float (random 1000000)) 1000000.0))
          (name (cocolog--arith-error "unknown arithmetic function `%s'/1" name)))))
     ((= (cocolog-arity x) 2)
      (let ((a (cocolog-eval (nth 1 x))) (b (cocolog-eval (nth 2 x))))
        (pcase (symbol-name (cocolog-functor x))
          ("+" (+ a b)) ("-" (- a b)) ("*" (* a b))
          ("/" (cond ((and (zerop b)) (cocolog--arith-error "zero divisor"))
                     ((and (integerp a) (integerp b) (zerop (% a b))) (/ a b))
                     (t (/ (float a) b))))
          ("//" (if (zerop b) (cocolog--arith-error "zero divisor")
                  (truncate (cocolog--int a) (cocolog--int b))))
          ("div" (if (zerop b) (cocolog--arith-error "zero divisor")
                   (floor (cocolog--int a) (cocolog--int b))))
          ("mod" (if (zerop b) (cocolog--arith-error "zero divisor")
                   (mod (cocolog--int a) (cocolog--int b))))
          ("rem" (if (zerop b) (cocolog--arith-error "zero divisor")
                   (- (cocolog--int a) (* (truncate (cocolog--int a) (cocolog--int b))
                                          (cocolog--int b)))))
          ("min" (if (<= (cocolog--num-cmp a b) 0) a b))
          ("max" (if (>= (cocolog--num-cmp a b) 0) a b))
          ("**" (let ((r (expt (float a) (float b))))
                  (if (and (integerp a) (integerp b) (>= b 0)) (expt a b) r)))
          ("^" (if (and (integerp a) (integerp b))
                   (if (< b 0) (cocolog--arith-error "negative integer exponent")
                     (expt a b))
                 (expt (float a) (float b))))
          ("atan2" (atan a b)) ("atan" (atan a b))
          ("gcd" (cl-gcd (cocolog--int a) (cocolog--int b)))
          (">>" (ash (cocolog--int a) (- (cocolog--int b))))
          ("<<" (ash (cocolog--int a) (cocolog--int b)))
          ("/\\" (logand (cocolog--int a) (cocolog--int b)))
          ("\\/" (logior (cocolog--int a) (cocolog--int b)))
          ("xor" (logxor (cocolog--int a) (cocolog--int b)))
          ("copysign" (if (< b 0) (- (abs a)) (abs a)))
          ("truncate" (truncate a))
          (name (cocolog--arith-error "unknown arithmetic function `%s'/2" name)))))
     (t (cocolog--arith-error "unknown arithmetic function `%s'/%d"
                              (symbol-name (cocolog-functor x)) (cocolog-arity x))))))

(defun cocolog--int (x)
  (if (integerp x) x (cocolog--arith-error "integer expected, got %s" x)))

(defun cocolog--num-cmp (a b) (cond ((= a b) 0) ((< a b) -1) (t 1)))

;;;; ------------------------------------------------------------------
;;;; Solver
;;;; ------------------------------------------------------------------

(defvar cocolog--builtins nil
  "Alist of \"name/arity\" -> function (ARGS DEPTH PARENT K GOAL).")

(eval-and-compile
  (defun cocolog--mangle (name)
    "Turn the predicate indicator NAME into a symbol-safe string."
    (mapconcat (lambda (c)
                 (if (or (<= ?a c ?z) (<= ?A c ?Z) (<= ?0 c ?9))
                     (string c)
                   (format "x%d" c)))
               name "")))

(defvar cocolog--db nil "The database used by the current query.")
(defvar cocolog--lib nil "The library database used by the current query.")

(defvar cocolog--in-library nil
  "Non-nil while a clause of the library is being resolved.
The library has no module system to hide behind, so this stands in for
one: a library predicate calling another finds the library's, not a
predicate of the same name in the file being edited.  Without it,
defining `digits//1\=' of your own would quietly change what
`number//1\=' means.")
(defvar cocolog--out nil "Buffer collecting output of write/1 and friends.")

(defsubst cocolog--fmt (term)
  (let ((s (cocolog-term-to-string term 999)))
    s))

(defvar cocolog--deadline nil
  "When the query running now has to be given up on, or nil.")

(defun cocolog--tick ()
  (when (> (cl-incf cocolog--inferences) cocolog-max-inferences)
    (signal 'cocolog-limit
            (list (format "inference limit (%d) reached" cocolog-max-inferences))))
  ;; asking the clock is not free, and a step is short: every few hundred
  ;; steps is often enough to keep the promise and rare enough to be free
  (when (and cocolog--deadline (zerop (mod cocolog--inferences 256))
             (time-less-p cocolog--deadline (current-time)))
    (signal 'cocolog-limit
            (list (format "gave up after %s seconds (cocolog-max-seconds)"
                          cocolog-max-seconds)))))

(defun cocolog-solve (goal depth cut parent k)
  "Prove GOAL, calling K once per solution.
DEPTH is the current resolution depth, CUT the catch tag of the
enclosing clause and PARENT the graph node the goal belongs to.
Returns normally when GOAL has no (more) solutions; the trail is
restored to its entry state before returning."
  (let ((mark (cocolog--mark)))
    (cocolog--solve-1 goal depth cut parent k)
    (cocolog--undo-to mark)
    nil))

(defun cocolog--solve-1 (goal depth cut parent k)
  (cocolog--tick)
  (let* ((g (cocolog-deref goal))
         (name (cond ((cocolog-atom-p g) (symbol-name g))
                     ((cocolog-compound-p g) (symbol-name (cocolog-functor g)))
                     ((cocolog-var-p g)
                      (signal 'cocolog-error (list "arguments are not sufficiently instantiated")))
                     (t (signal 'cocolog-error
                                (list (format "%s is not callable" (cocolog--fmt g)))))))
         (arity (if (cocolog-compound-p g) (cocolog-arity g) 0))
         (args (if (cocolog-compound-p g) (cocolog-args g) nil)))
    (pcase (cons name arity)
      (`("," . 2)
       ;; both goals belong to the same clause, so the second is solved in
       ;; the same world as the first, whatever the first wandered into
       (let ((home cocolog--in-library))
         (cocolog--solve-1 (nth 0 args) depth cut parent
                           (lambda ()
                             (let ((cocolog--in-library home))
                               (cocolog-solve (nth 1 args) depth cut parent k))))))
      (`(";" . 2)
       (let ((lhs (cocolog-deref (nth 0 args))))
         (cond
          ((and (cocolog-compound-p lhs) (eq (cocolog-functor lhs) (intern "->"))
                (= (cocolog-arity lhs) 2))
           (cocolog--if-then-else (nth 1 lhs) (nth 2 lhs) (nth 1 args) depth cut parent k))
          ((and (cocolog-compound-p lhs) (eq (cocolog-functor lhs) (intern "*->"))
                (= (cocolog-arity lhs) 2))
           (cocolog--soft-cut (nth 1 lhs) (nth 2 lhs) (nth 1 args) depth cut parent k))
          (t
           (cocolog-solve lhs depth cut parent k)
           (cocolog-solve (nth 1 args) depth cut parent k)))))
      (`("->" . 2)
       (cocolog--if-then-else (nth 0 args) (nth 1 args) 'fail depth cut parent k))
      (`("*->" . 2)
       (cocolog--soft-cut (nth 0 args) (nth 1 args) 'fail depth cut parent k))
      (`("!" . 0)
       (cocolog--node 'control "!" depth parent)
       (funcall k)
       (when cut (throw cut nil)))
      (`("\\+" . 1) (cocolog--negation (nth 0 args) depth parent k))
      (`("not" . 1) (cocolog--negation (nth 0 args) depth parent k))
      (`("true" . 0) (funcall k))
      (`("fail" . 0) nil)
      (`("false" . 0) nil)
      ((and `("call" . ,n) (guard (>= n 1)))
       (let* ((g0 (cocolog-deref (nth 0 args)))
              (extra (cdr args))
              (goal2 (cond
                      ((null extra) g0)
                      ((cocolog-compound-p g0)
                       (cons (cocolog-functor g0) (append (cocolog-args g0) extra)))
                      ((cocolog-atom-p g0) (cons g0 extra))
                      (t (signal 'cocolog-error (list "call/N: not callable"))))))
         (let ((tag (make-symbol "cocolog-call")))
           (catch tag (cocolog-solve goal2 depth tag parent k)))))
      ((and `(">>" . ,n) (guard (>= n 2)))
       (cocolog--call-lambda (nth 0 args) (nth 1 args) (cddr args) depth parent k))
      (_
       (let ((bi (assoc (format "%s/%d" name arity) cocolog--builtins)))
         (if bi
             (funcall (cdr bi) args depth parent k g)
           (cocolog--solve-user g depth parent k)))))))

(defun cocolog--call-lambda (params body extra depth parent k)
  "Call the yall lambda PARAMS>>BODY with the EXTRA arguments.
Variables are renamed apart, except those in the optional Free/Params
prefix, exactly as library(yall) does."
  (let* ((p (cocolog-deref params))
         (free (when (and (cocolog-compound-p p) (eq (cocolog-functor p) (intern "/"))
                          (= (cocolog-arity p) 2))
                 (prog1 (nth 1 p) (setq p (cocolog-deref (nth 2 p))))))
         (map (make-hash-table :test 'eq)))
    (dolist (v (cocolog-term-vars free)) (puthash v v map))
    (let* ((copy (cocolog--copy-1 (list (intern ">>") p body) map))
           (plist (cocolog-list-to-lisp (nth 1 copy)))
           (cbody (nth 2 copy))
           (tag (make-symbol "cocolog-lambda")))
      (when (eq plist :not-a-list)
        (signal 'cocolog-error (list "yall: parameter list expected")))
      (let ((rest extra) (ok t))
        (dolist (pv plist)
          (if rest
              (progn (unless (cocolog-unify pv (car rest)) (setq ok nil))
                     (setq rest (cdr rest)))
            (setq ok nil)))
        (when ok
          (let ((goal2 (if rest
                           (let ((b (cocolog-deref cbody)))
                             (if (cocolog-compound-p b)
                                 (cons (cocolog-functor b) (append (cocolog-args b) rest))
                               (cons b rest)))
                         cbody)))
            (catch tag (cocolog-solve goal2 depth tag parent k))))))))

(defun cocolog--if-then-else (cond-goal then else depth cut parent k)
  (let ((mark (cocolog--mark))
        (tag (make-symbol "cocolog-ite"))
        (found nil)
        (node (cocolog--node 'control
                             (lambda () (concat "if " (cocolog--fmt cond-goal)))
                             depth parent)))
    (catch tag
      (cocolog-solve cond-goal (1+ depth) tag node
                     (lambda () (setq found t) (throw tag nil))))
    ;; NOTE: bindings made by the condition are kept on purpose.
    (setf (cocolog-node-status node) (if found 'success 'fail))
    (if found
        (cocolog-solve then depth cut parent k)
      (cocolog--undo-to mark)
      (cocolog-solve else depth cut parent k))))

(defun cocolog--soft-cut (cond-goal then else depth cut parent k)
  (let ((mark (cocolog--mark))
        (tag (make-symbol "cocolog-softcut"))
        (found nil))
    (catch tag
      (cocolog-solve cond-goal (1+ depth) tag parent
                     (lambda () (setq found t) (cocolog-solve then depth cut parent k))))
    (unless found
      (cocolog--undo-to mark)
      (cocolog-solve else depth cut parent k))))

(defun cocolog--negation (goal depth parent k)
  (let* ((node (cocolog--node 'control (lambda () (concat "\\+ " (cocolog--fmt goal)))
                              depth parent))
         (mark (cocolog--mark))
         (tag (make-symbol "cocolog-naf"))
         (found nil))
    (catch tag
      (cocolog-solve goal (1+ depth) tag node
                     (lambda () (setq found t) (throw tag nil))))
    (cocolog--undo-to mark)
    (cocolog--node-finish node)
    (setf (cocolog-node-status node) (if found 'fail 'success))
    (unless found (funcall k))))

(defun cocolog--strip-comments (text)
  "Return TEXT without its comments.
A `%\=' inside a quoted item is a character of that item, not the start
of a comment: a rule that reads a remark says so with \"%\", and cutting
its body off there would show the rule as something it is not."
  (let ((out (make-string 0 ?\s))
        (quote nil) (i 0) (n (length text)))
    (while (< i n)
      (let ((c (aref text i)))
        (cond
         (quote
          (setq out (concat out (string c)))
          (cond
           ((and (eq c ?\\) (< (1+ i) n))      ; an escaped character, whatever it is
            (setq out (concat out (string (aref text (1+ i)))))
            (cl-incf i))
           ((eq c quote) (setq quote nil))))
         ;; 0'c is the code of a character, not the start of a quoted item
         ((and (eq c ?\') (> i 0) (eq (aref text (1- i)) ?0))
          (setq out (concat out (string c)))
          (when (< (1+ i) n)
            (setq out (concat out (string (aref text (1+ i)))))
            (cl-incf i)
            (when (and (eq (aref text i) ?\\) (< (1+ i) n))
              (setq out (concat out (string (aref text (1+ i)))))
              (cl-incf i))))
         ((memq c '(?\" ?\' ?`))
          (setq quote c out (concat out (string c))))
         ((eq c ?%)                            ; a comment: to the end of the line
          (while (and (< i n) (not (eq (aref text i) ?\n))) (cl-incf i))
          (setq i (1- i)))
         (t (setq out (concat out (string c))))))
      (cl-incf i))
    out))

(defun cocolog--squeeze (text)
  "Return TEXT with its comments dropped and its whitespace squeezed."
  (string-trim
   (replace-regexp-in-string
    "[ \t\n\r]+" " "
    (cocolog--strip-comments text))))

(defun cocolog--clause-label (rec)
  "Return the source line the graph shows for the clause REC.
A grammar rule is shown as it was written, arrow and all; the goals in
the graph still show the two list arguments it was translated into."
  (if (and (cocolog-clause-dcg rec) (cocolog-clause-text rec))
      (cocolog--squeeze (cocolog-clause-text rec))
    (let ((head (cocolog-term-to-string (cocolog-clause-head rec) 1199))
          (body (cocolog-clause-body rec)))
      (if (eq (cocolog-deref body) 'true)
          (concat head ".")
        (concat head " :- " (cocolog-term-to-string body 1199) ".")))))

(defun cocolog--solve-user (goal depth parent k)
  "Resolve the user-defined GOAL against the database."
  (let* ((node (cocolog--node 'call (lambda () (cocolog--fmt goal)) depth parent))
         (own (cocolog-db-clauses cocolog--db goal))
         (lib (and cocolog--lib (cocolog-db-clauses cocolog--lib goal)))
         (clauses (if cocolog--in-library (or lib own) (or own lib)))
         (from-library (and clauses lib (eq clauses lib)))
         (caller cocolog--in-library)
         (mark (cocolog--mark)))
    (cond
     ((null clauses)
      (setf (cocolog-node-status node) 'error)
      (setf (cocolog-node-detail node)
            (format "unknown predicate %s" (cocolog--indicator goal)))
      (cocolog--node-finish node)
      (signal 'cocolog-error
              (list (format "unknown procedure %s" (cocolog--indicator goal)))))
     ((> depth cocolog-max-depth)
      (setq cocolog--depth-cut t)
      (setf (cocolog-node-status node) 'limit)
      (setf (cocolog-node-detail node) "depth limit reached")
      (cocolog--node-finish node)
      nil)
     (t
      (let ((tag (make-symbol "cocolog-cut"))
            (index 0))
        (catch tag
          (dolist (rec clauses)
            (cl-incf index)
            (cocolog--tick)
            (let* ((copy (cocolog-copy-term
                          (cons (intern ":-") (list (cocolog-clause-head rec)
                                                    (cocolog-clause-body rec)))))
                   (head (nth 1 copy))
                   (body (nth 2 copy))
                   (cnode (cocolog--node 'clause
                                         (format "clause %d" index) depth node
                                         (cocolog--clause-label rec))))
              (if (not (cocolog-unify goal head))
                  (progn (setf (cocolog-node-status cnode) 'fail)
                         (cocolog--node-finish cnode)
                         (cocolog--undo-to mark))
                (unwind-protect
                    (let ((cocolog--in-library from-library))
                      (cocolog-solve
                       body (1+ depth) tag cnode
                       (lambda ()
                         (setf (cocolog-node-status node) 'success)
                         (setf (cocolog-node-status cnode) 'success)
                         (cocolog--record-exit node (lambda () (cocolog--fmt goal)))
                         ;; the continuation is the caller's, so it runs in
                         ;; the caller's world, not in the one this clause
                         ;; happens to have been found in
                         (let ((cocolog--in-library caller))
                           (funcall k)))))
                  (cocolog--node-finish cnode))
                (unless (cocolog-node-status cnode)
                  (setf (cocolog-node-status cnode) 'fail))
                (cocolog--undo-to mark)))))
        (cocolog--undo-to mark)
        (cocolog--node-finish node)
        (unless (cocolog-node-status node)
          (setf (cocolog-node-status node) 'fail))
        nil)))))

;;;; ------------------------------------------------------------------
;;;; Builtins
;;;; ------------------------------------------------------------------


(defmacro cocolog-defbuiltin (indicator arglist &rest body)
  "Define the builtin INDICATOR.
ARGLIST is bound to the goal arguments; the macro also binds `depth',
`parent', `k' and `goal'.  BODY should call K for every solution."
  (declare (indent 2))
  (let ((fname (intern (concat "cocolog--bi-" (cocolog--mangle indicator)))))
    `(progn
       (defun ,fname (cocolog--args depth parent k goal)
         (ignore depth parent k goal)
         (cl-destructuring-bind ,arglist cocolog--args ,@body))
       (setq cocolog--builtins
             (cons (cons ,indicator #',fname)
                   (assoc-delete-all ,indicator cocolog--builtins))))))

(defun cocolog--det (goal parent depth ok &optional detail)
  "Record a deterministic builtin node for GOAL with result OK."
  (let ((n (cocolog--node 'builtin (lambda () (cocolog--fmt goal)) depth parent detail)))
    (setf (cocolog-node-status n) (if ok 'success 'fail))
    (when ok (cocolog--record-exit n (lambda () (cocolog--fmt goal))))
    ok))

(defmacro cocolog--deterministic (&rest body)
  "Run BODY, which returns non-nil on success, as a deterministic builtin."
  `(let ((ok (progn ,@body)))
     (cocolog--det goal parent depth ok)
     (when ok (funcall k))))

(cocolog-defbuiltin "=/2" (a b)
  (cocolog--deterministic (cocolog-unify a b)))

(cocolog-defbuiltin "\\=/2" (a b)
  (cocolog--deterministic
   (let ((mark (cocolog--mark)))
     (prog1 (not (cocolog-unify a b)) (cocolog--undo-to mark)))))

(cocolog-defbuiltin "==/2" (a b)
  (cocolog--deterministic (= 0 (cocolog-compare a b))))
(cocolog-defbuiltin "\\==/2" (a b)
  (cocolog--deterministic (/= 0 (cocolog-compare a b))))
(cocolog-defbuiltin "@</2" (a b)
  (cocolog--deterministic (< (cocolog-compare a b) 0)))
(cocolog-defbuiltin "@>/2" (a b)
  (cocolog--deterministic (> (cocolog-compare a b) 0)))
(cocolog-defbuiltin "@=</2" (a b)
  (cocolog--deterministic (<= (cocolog-compare a b) 0)))
(cocolog-defbuiltin "@>=/2" (a b)
  (cocolog--deterministic (>= (cocolog-compare a b) 0)))
(cocolog-defbuiltin "compare/3" (o a b)
  (cocolog--deterministic
   (cocolog-unify o (intern (pcase (cocolog-compare a b) (-1 "<") (0 "=") (_ ">"))))))

(cocolog-defbuiltin "is/2" (r e)
  (cocolog--deterministic (cocolog-unify r (cocolog-eval e))))

(dolist (pair '(("=:=/2" . =) ("=\\=/2" . /=) ("</2" . <) (">/2" . >)
                ("=</2" . <=) (">=/2" . >=)))
  (let ((op (cdr pair)))
    (setq cocolog--builtins
          (cons (cons (car pair)
                      (lambda (args depth parent k goal)
                        (let ((ok (funcall op (cocolog-eval (nth 0 args))
                                           (cocolog-eval (nth 1 args)))))
                          (cocolog--det goal parent depth ok)
                          (when ok (funcall k)))))
                cocolog--builtins))))

(cocolog-defbuiltin "var/1" (x)
  (cocolog--deterministic (cocolog-var-p (cocolog-deref x))))
(cocolog-defbuiltin "nonvar/1" (x)
  (cocolog--deterministic (not (cocolog-var-p (cocolog-deref x)))))
(cocolog-defbuiltin "atom/1" (x)
  (cocolog--deterministic (cocolog-atom-p (cocolog-deref x))))
(cocolog-defbuiltin "number/1" (x)
  (cocolog--deterministic (numberp (cocolog-deref x))))
(cocolog-defbuiltin "integer/1" (x)
  (cocolog--deterministic (integerp (cocolog-deref x))))
(cocolog-defbuiltin "float/1" (x)
  (cocolog--deterministic (floatp (cocolog-deref x))))
(cocolog-defbuiltin "atomic/1" (x)
  (cocolog--deterministic (let ((v (cocolog-deref x)))
                            (or (numberp v) (cocolog-atom-p v)))))
(cocolog-defbuiltin "compound/1" (x)
  (cocolog--deterministic (cocolog-compound-p (cocolog-deref x))))
(cocolog-defbuiltin "callable/1" (x)
  (cocolog--deterministic (let ((v (cocolog-deref x)))
                            (or (cocolog-atom-p v) (cocolog-compound-p v)))))
(cocolog-defbuiltin "is_list/1" (x)
  (cocolog--deterministic (not (eq :not-a-list (cocolog-list-to-lisp x)))))
(cocolog-defbuiltin "ground/1" (x)
  (cocolog--deterministic (null (cocolog-term-vars x))))

(cocolog-defbuiltin "functor/3" (term name arity)
  (cocolog--deterministic
   (let ((x (cocolog-deref term)))
     (if (cocolog-var-p x)
         (let ((n (cocolog-deref name)) (a (cocolog-deref arity)))
           (unless (integerp a) (signal 'cocolog-error (list "functor/3: bad arity")))
           (cocolog-unify x (if (zerop a) n
                              (cons n (cl-loop repeat a collect (cocolog--var-make))))))
       (if (cocolog-compound-p x)
           (and (cocolog-unify name (cocolog-functor x))
                (cocolog-unify arity (cocolog-arity x)))
         (and (cocolog-unify name x) (cocolog-unify arity 0)))))))

(cocolog-defbuiltin "arg/3" (n term arg)
  (let ((x (cocolog-deref term)) (i (cocolog-deref n)))
    (unless (cocolog-compound-p x) (signal 'cocolog-error (list "arg/3: not compound")))
    (if (integerp i)
        (cocolog--deterministic
         (and (<= 1 i (cocolog-arity x)) (cocolog-unify arg (nth i x))))
      (let ((node (cocolog--node 'builtin (lambda () (cocolog--fmt goal)) depth parent))
            (idx 0) (mark (cocolog--mark)))
        (dolist (a (cocolog-args x))
          (cl-incf idx)
          (when (and (cocolog-unify n idx) (cocolog-unify arg a))
            (setf (cocolog-node-status node) 'success)
            (funcall k))
          (cocolog--undo-to mark))
        (unless (cocolog-node-status node) (setf (cocolog-node-status node) 'fail))))))

(cocolog-defbuiltin "=../2" (term lst)
  (cocolog--deterministic
   (let ((x (cocolog-deref term)))
     (if (cocolog-var-p x)
         (let ((l (cocolog-list-to-lisp lst)))
           (when (eq l :not-a-list) (signal 'cocolog-error (list "=../2: bad list")))
           (cocolog-unify x (if (cdr l) (cons (car l) (cdr l)) (car l))))
       (cocolog-unify lst (cocolog-list
                           (if (cocolog-compound-p x)
                               (cons (cocolog-functor x) (cocolog-args x))
                             (list x))))))))

(cocolog-defbuiltin "copy_term/2" (a b)
  (cocolog--deterministic (cocolog-unify b (cocolog-copy-term a))))

(cocolog-defbuiltin "between/3" (low high x)
  (let* ((l (cocolog-eval low)) (h (cocolog-eval high))
         (v (cocolog-deref x))
         (node (cocolog--node 'builtin (lambda () (cocolog--fmt goal)) depth parent)))
    (if (integerp v)
        (let ((ok (and (<= l v) (<= v h))))
          (setf (cocolog-node-status node) (if ok 'success 'fail))
          (when ok (funcall k)))
      (let ((i l) (mark (cocolog--mark)))
        (while (<= i h)
          (when (cocolog-unify x i)
            (setf (cocolog-node-status node) 'success)
            (cocolog--record-exit node (lambda () (format "%s = %d" (cocolog--fmt v) i)))
            (funcall k))
          (cocolog--undo-to mark)
          (cl-incf i))
        (unless (cocolog-node-status node) (setf (cocolog-node-status node) 'fail))))))

(cocolog-defbuiltin "succ/2" (a b)
  (cocolog--deterministic
   (let ((x (cocolog-deref a)) (y (cocolog-deref b)))
     (cond ((integerp x) (cocolog-unify b (1+ x)))
           ((integerp y) (and (> y 0) (cocolog-unify a (1- y))))
           (t (signal 'cocolog-error (list "succ/2: not sufficiently instantiated")))))))

(cocolog-defbuiltin "length/2" (lst len)
  (let ((l (cocolog-list-to-lisp lst)) (n (cocolog-deref len)))
    (if (not (eq l :not-a-list))
        (cocolog--deterministic (cocolog-unify len (length l)))
      (if (integerp n)
          (cocolog--deterministic
           (cocolog-unify lst (cocolog-list (cl-loop repeat n collect (cocolog--var-make)))))
        (let ((node (cocolog--node 'builtin (lambda () (cocolog--fmt goal)) depth parent))
              (i 0) (mark (cocolog--mark)))
          (while (<= i 512)
            (when (and (cocolog-unify len i)
                       (cocolog-unify lst (cocolog-list
                                           (cl-loop repeat i collect (cocolog--var-make)))))
              (setf (cocolog-node-status node) 'success)
              (funcall k))
            (cocolog--undo-to mark)
            (cl-incf i)))))))

(cocolog-defbuiltin "findall/3" (template goal-term bag)
  (let* ((node (cocolog--node 'control (lambda () (concat "findall " (cocolog--fmt goal-term)))
                              depth parent))
         (results '())
         (mark (cocolog--mark))
         (tag (make-symbol "cocolog-findall")))
    (catch tag
      (cocolog-solve goal-term (1+ depth) tag node
                     (lambda () (push (cocolog-copy-term template) results))))
    (cocolog--undo-to mark)
    (cocolog--node-finish node)
    (setf (cocolog-node-status node) 'success)
    (setf (cocolog-node-detail node) (format "%d solution(s)" (length results)))
    (let ((ok (cocolog-unify bag (cocolog-list (nreverse results)))))
      (when ok (funcall k)))))

(cocolog-defbuiltin "forall/2" (c a)
  (let* ((node (cocolog--node 'control (lambda () (cocolog--fmt goal)) depth parent))
         (mark (cocolog--mark))
         (tag (make-symbol "cocolog-forall"))
         (ok t))
    (catch tag
      (cocolog-solve c (1+ depth) tag node
                     (lambda ()
                       (let ((m2 (cocolog--mark)) (found nil)
                             (tag2 (make-symbol "cocolog-forall2")))
                         (catch tag2
                           (cocolog-solve a (1+ depth) tag2 node
                                          (lambda () (setq found t) (throw tag2 nil))))
                         (cocolog--undo-to m2)
                         (unless found (setq ok nil) (throw tag nil))))))
    (cocolog--undo-to mark)
    (cocolog--node-finish node)
    (setf (cocolog-node-status node) (if ok 'success 'fail))
    (when ok (funcall k))))

(cocolog-defbuiltin "aggregate_all/3" (spec goal-term result)
  (let* ((s (cocolog-deref spec))
         (kind (if (cocolog-compound-p s) (symbol-name (cocolog-functor s))
                 (symbol-name s)))
         (template (if (cocolog-compound-p s) (nth 1 s) 0))
         (results '())
         (mark (cocolog--mark))
         (tag (make-symbol "cocolog-agg"))
         (node (cocolog--node 'control (lambda () (cocolog--fmt goal)) depth parent)))
    (catch tag
      (cocolog-solve goal-term (1+ depth) tag node
                     (lambda () (push (cocolog-copy-term template) results))))
    (cocolog--undo-to mark)
    (cocolog--node-finish node)
    (setq results (nreverse results))
    (setf (cocolog-node-status node) 'success)
    (let ((val (pcase kind
                 ("count" (length results))
                 ("sum" (apply #'+ (mapcar #'cocolog-eval results)))
                 ("max" (if results (apply #'max (mapcar #'cocolog-eval results))
                          (signal 'cocolog-error (list "aggregate_all(max, ...) empty"))))
                 ("min" (if results (apply #'min (mapcar #'cocolog-eval results))
                          (signal 'cocolog-error (list "aggregate_all(min, ...) empty"))))
                 ("bag" (cocolog-list results))
                 ("set" (cocolog-list (cocolog--sort-unique results)))
                 (_ (signal 'cocolog-error (list (format "aggregate_all: bad spec %s" kind)))))))
      (when (cocolog-unify result val) (funcall k)))))

(defun cocolog--sort-unique (terms)
  (let ((sorted (sort (copy-sequence terms)
                      (lambda (a b) (< (cocolog-compare a b) 0))))
        (out '()))
    (dolist (x sorted (nreverse out))
      (unless (and out (= 0 (cocolog-compare (car out) x)))
        (push x out)))))

(cocolog-defbuiltin "msort/2" (a b)
  (cocolog--deterministic
   (let ((l (cocolog-list-to-lisp a)))
     (when (eq l :not-a-list) (signal 'cocolog-error (list "msort/2: bad list")))
     (cocolog-unify b (cocolog-list
                       (sort (copy-sequence l)
                             (lambda (x y) (< (cocolog-compare x y) 0))))))))

(cocolog-defbuiltin "sort/2" (a b)
  (cocolog--deterministic
   (let ((l (cocolog-list-to-lisp a)))
     (when (eq l :not-a-list) (signal 'cocolog-error (list "sort/2: bad list")))
     (cocolog-unify b (cocolog-list (cocolog--sort-unique l))))))

(cocolog-defbuiltin "atom_codes/2" (a codes)
  (cocolog--deterministic
   (let ((x (cocolog-deref a)))
     (if (cocolog-var-p x)
         (let ((l (cocolog-list-to-lisp codes)))
           (cocolog-unify a (intern (concat (mapcar #'identity l)))))
       (cocolog-unify codes
                      (cocolog-list (append (cocolog--text-of x) nil)))))))

(cocolog-defbuiltin "atom_length/2" (a len)
  (cocolog--deterministic
   (cocolog-unify len (length (cocolog--text-of (cocolog-deref a))))))

(cocolog-defbuiltin "atom_number/2" (a n)
  (cocolog--deterministic
   (let ((x (cocolog-deref a)))
     (if (cocolog-var-p x)
         (cocolog-unify a (intern (cocolog--text-of (cocolog-deref n))))
       (let ((s (cocolog--text-of x)))
         (and (string-match-p
               "\\`[-+]?[0-9]+\\(\\.[0-9]+\\)?\\([eE][-+]?[0-9]+\\)?\\'" s)
              (cocolog-unify n (if (string-match-p "[.eE]" s)
                                   (string-to-number s)
                                 (truncate (string-to-number s))))))))))

(cocolog-defbuiltin "atom_concat/3" (a b c)
  (cocolog--deterministic
   (let ((x (cocolog-deref a)) (y (cocolog-deref b)))
     (if (or (cocolog-var-p x) (cocolog-var-p y))
         (signal 'cocolog-error (list "atom_concat/3: not sufficiently instantiated"))
       (cocolog-unify c (intern (concat (cocolog--text-of x) (cocolog--text-of y))))))))

(defun cocolog--text-of (x)
  (let ((v (cocolog-deref x)))
    (cond ((cocolog-atom-p v) (symbol-name v))
          ((integerp v) (number-to-string v))
          ((numberp v) (number-to-string v))
          (t (let ((l (cocolog-list-to-lisp v)))
               (if (and (listp l) (cl-every #'integerp l))
                   (concat l)
                 (cocolog--fmt v)))))))

(cocolog-defbuiltin "write/1" (x)
  (cocolog--deterministic
   (let ((cocolog-write-quoted nil))
     (setq cocolog--out (concat cocolog--out (cocolog-term-to-string x))) t)))
(cocolog-defbuiltin "print/1" (x)
  (cocolog--deterministic
   (setq cocolog--out (concat cocolog--out (cocolog-term-to-string x))) t))
(cocolog-defbuiltin "writeln/1" (x)
  (cocolog--deterministic
   (let ((cocolog-write-quoted nil))
     (setq cocolog--out (concat cocolog--out (cocolog-term-to-string x) "\n")) t)))
(cocolog-defbuiltin "nl/0" ()
  (cocolog--deterministic (setq cocolog--out (concat cocolog--out "\n")) t))
(cocolog-defbuiltin "tab/1" (n)
  (cocolog--deterministic
   (setq cocolog--out (concat cocolog--out (make-string (cocolog-eval n) ?\s))) t))

(cocolog-defbuiltin "phrase/2" (body list)
  (cocolog--phrase body list cocolog-nil depth parent k))

(cocolog-defbuiltin "phrase/3" (body list rest)
  (cocolog--phrase body list rest depth parent k))

(defun cocolog--phrase (body list rest depth parent k)
  "Prove that BODY describes the difference between LIST and REST."
  (let ((goal (cocolog--dcg-body body list rest))
        (tag (make-symbol "cocolog-phrase")))
    (catch tag (cocolog-solve goal depth tag parent k))))

(cocolog-defbuiltin "throw/1" (ball)
  (signal 'cocolog-error (list (format "uncaught exception: %s" (cocolog--fmt ball)))))

(cocolog-defbuiltin "halt/0" ()
  (signal 'cocolog-error (list "halt")))

;;;; ------------------------------------------------------------------
;;;; Running a query
;;;; ------------------------------------------------------------------

(cl-defstruct (cocolog-result (:constructor cocolog--result-make))
  goal          ; the query term, as written
  vars          ; alist NAME -> var
  solutions     ; list of alists NAME -> string
  root          ; root trace node
  status        ; done | limit | error
  message       ; error text, if any
  inferences
  truncated
  depth-cut     ; t when a branch was given up on for being too deep
  output)       ; text written by write/1 etc.

(defun cocolog-run-query (db query-string &optional max-solutions)
  "Run QUERY-STRING against DB and return a `cocolog-result'.
QUERY-STRING may include the leading `?-' and the trailing period."
  (let* ((text (string-trim query-string))
         (text (if (string-prefix-p "?-" text) (substring text 2) text))
         (text (string-trim text))
         (text (if (string-suffix-p "." text) text (concat text ".")))
         (parsed (cocolog-read-term text))
         (goal (plist-get parsed :term))
         (vars (cl-remove-if (lambda (c) (string-prefix-p "_" (car c)))
                             (plist-get parsed :vars)))
         (root (cocolog--node-create :kind 'root :label text :depth 0))
         (cocolog--db db)
         (cocolog--lib (cocolog-library-db))
         (cocolog--trail nil)
         (cocolog--inferences 0)
         (cocolog--trace-count 0)
         (cocolog--trace-truncated nil)
         (cocolog--depth-cut nil)
         (cocolog--deadline (and cocolog-max-seconds
                                 (time-add (current-time) cocolog-max-seconds)))
         (cocolog--out nil)
         (max-lisp-eval-depth (max max-lisp-eval-depth 20000))
         (solutions '())
         (status 'done)
         (message nil)
         (limit (or max-solutions cocolog-max-solutions))
         (tag (make-symbol "cocolog-query")))
    (unless parsed (signal 'cocolog-error (list "empty query")))
    (condition-case err
        (catch tag
          (cocolog-solve
           goal 1 tag root
           (lambda ()
             (push (mapcar (lambda (c)
                             (cons (car c) (cocolog-term-to-string (cdr c) 999)))
                           vars)
                   solutions)
             (when (>= (length solutions) limit)
               (setq status 'more)
               (throw tag nil)))))
      (cocolog-limit (setq status 'limit message (cadr err)))
      (cocolog-error (setq status 'error message (cadr err)))
      (error (setq status 'error message (error-message-string err))))
    (cocolog--node-finish root)
    (cocolog--result-make
     :goal goal :vars vars
     :solutions (nreverse solutions)
     :root root :status status :message message
     :inferences cocolog--inferences
     :truncated cocolog--trace-truncated
     :depth-cut cocolog--depth-cut
     :output cocolog--out)))

(provide 'cocolog-engine)

;;; cocolog-engine.el ends here
