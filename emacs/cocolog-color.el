;;; cocolog-color.el --- Colour variables and the visual palette -*- lexical-binding: t; -*-

;;; Commentary:

;; In cocolog a variable can be *a colour* instead of a name.  On disk a
;; colour variable is an ordinary Prolog variable whose name encodes the
;; colour, `C' followed by six hexadecimal digits:
;;
;;     ancestor(Cff0000, C1f77b4) :- parent(Cff0000, C1f77b4).
;;
;; so a cocolog file is still plain Prolog and any other tool can read
;; it.  `cocolog-mode' displays those names as coloured swatches, and
;; this file provides the colour arithmetic plus the palette the
;; developer picks from.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'facemenu)   ; `color-name-rgb-alist', which does not depend on the display

(defconst cocolog-color-var-regexp
  "\\_<C\\([0-9a-fA-F]\\{6\\}\\)\\(?:_\\([A-Za-z][A-Za-z0-9_]*\\)\\)?\\_>"
  "Regexp matching a colour variable.
Group 1 is the RRGGBB part and group 2 the name the developer gave it,
which is absent when the variable is called after its own colour.")

(defcustom cocolog-palette
  '(("crimson"   . "#e6194b") ("red"       . "#d62728") ("tomato"  . "#ff6347")
    ("coral"     . "#ff7f50") ("orange"    . "#f58231") ("amber"   . "#ffa500")
    ("gold"      . "#ffd700") ("yellow"    . "#ffe119")
    ("olive"     . "#808000") ("lime"      . "#bfef45") ("green"   . "#3cb44b")
    ("forest"    . "#228b22") ("mint"      . "#aaffc3") ("teal"    . "#469990")
    ("cyan"      . "#42d4f4") ("sky"       . "#87ceeb")
    ("blue"      . "#4363d8") ("navy"      . "#00308f") ("indigo"  . "#4b0082")
    ("violet"    . "#911eb4") ("purple"    . "#9370db") ("orchid"  . "#dda0dd")
    ("magenta"   . "#f032e6") ("pink"      . "#fabed4")
    ("rose"      . "#ff69b4") ("maroon"    . "#800000") ("brown"   . "#9a6324")
    ("sienna"    . "#a0522d") ("tan"       . "#d2b48c") ("beige"   . "#fffac8")
    ("khaki"     . "#f0e68c") ("apricot"   . "#ffd8b1")
    ("salmon"    . "#fa8072") ("lavender"  . "#dcbeff") ("plum"    . "#8e4585")
    ("slate"     . "#708090") ("steel"     . "#4682b4") ("denim"   . "#1560bd")
    ("aqua"      . "#00ced1") ("seafoam"   . "#66cdaa")
    ("moss"      . "#6b8e23") ("sage"      . "#b2ac88") ("rust"    . "#b7410e")
    ("copper"    . "#b87333") ("charcoal"  . "#36454f") ("gray"    . "#a9a9a9")
    ("silver"    . "#c0c0c0") ("chalk"     . "#f0f0f0"))
  "Colours offered by the visual picker, as (NAME . HEX) pairs.
The grid is filled row by row; see `cocolog-palette-columns'."
  :type '(alist :key-type string :value-type string)
  :group 'cocolog)

(defcustom cocolog-palette-columns 8
  "Number of colours per row in the palette."
  :type 'integer :group 'cocolog)

;;;; ------------------------------------------------------------------
;;;; Colour arithmetic
;;;; ------------------------------------------------------------------

(defun cocolog-normalize-hex (hex)
  "Return HEX as a lowercase \"#rrggbb\" string, or nil if it is not a colour."
  (let ((s (downcase (string-trim (or hex "")))))
    (cond
     ((string-match "\\`#?\\([0-9a-f]\\{6\\}\\)\\'" s)
      (concat "#" (match-string 1 s)))
     ((string-match "\\`#?\\([0-9a-f]\\)\\([0-9a-f]\\)\\([0-9a-f]\\)\\'" s)
      (apply #'concat "#" (mapcar (lambda (i) (let ((c (match-string i s))) (concat c c)))
                                  '(1 2 3))))
     ((assoc-string s color-name-rgb-alist t)
      (apply #'format "#%02x%02x%02x"
             (mapcar (lambda (v) (/ v 256))
                     (cdr (assoc-string s color-name-rgb-alist t)))))
     ((and (color-defined-p s) (color-values s))
      ;; last resort: ask the display, which may only approximate
      (apply #'format "#%02x%02x%02x"
             (mapcar (lambda (v) (/ v 256)) (color-values s))))
     (t nil))))

(defvar cocolog--rgb-cache (make-hash-table :test 'equal)
  "Cached (R G B) triples, keyed by the colour as it was written.")

(defun cocolog-hex-rgb (hex)
  "Return the (R G B) components of HEX as integers 0..255.
The answer is kept: measuring one colour against another is done
thousands of times when a clause is coloured, and taking a string apart
each time was the slowest thing in the mode."
  (or (gethash hex cocolog--rgb-cache)
      (puthash hex
               (let ((h (cocolog-normalize-hex hex)))
                 (list (string-to-number (substring h 1 3) 16)
                       (string-to-number (substring h 3 5) 16)
                       (string-to-number (substring h 5 7) 16)))
               cocolog--rgb-cache)))

(defun cocolog-luminance (hex)
  "Relative luminance of HEX, from 0.0 to 1.0."
  (cl-destructuring-bind (r g b) (cocolog-hex-rgb hex)
    (/ (+ (* 0.2126 r) (* 0.7152 g) (* 0.0722 b)) 255.0)))

(defcustom cocolog-swatch-outline 'auto
  "Whether a swatch is drawn with a thin outline.
`auto\=' outlines only a swatch whose colour is close to the colour of
the frame, which would otherwise melt into the background -- pale ones
on a light theme, dark ones on a dark theme.  `t\=' always outlines and
nil never does.

The outline is a box on a graphical frame and an underline on a
terminal, which has no boxes.  It is worked out again whenever the
theme changes."
  :type '(choice (const :tag "Only when needed" auto)
                 (const :tag "Always" t)
                 (const :tag "Never" nil))
  :group 'cocolog)

(defvar cocolog--background-luminance nil
  "Cached result of `cocolog-background-luminance'.")

(defvar cocolog--swatch-face-cache (make-hash-table :test 'equal)
  "Cached faces, keyed by colour and by what the frame looks like.")

(defun cocolog-forget-faces ()
  "Forget the cached swatch faces; the frame or the theme has changed."
  (setq cocolog--background-luminance nil)
  (clrhash cocolog--swatch-face-cache))

(defun cocolog-background-luminance ()
  "Relative luminance of the frame background, from 0.0 to 1.0.
A terminal that does not say what its background colour is only tells
Emacs whether it is dark or light, which is enough.  The answer is kept:
it is wanted once per swatch drawn, and it only changes with the theme."
  (or cocolog--background-luminance
      (setq cocolog--background-luminance
            (let ((color (frame-parameter nil 'background-color)))
              (if (and (stringp color) (color-defined-p color))
                  (cocolog-luminance (cocolog-normalize-hex color))
                (if (eq (frame-parameter nil 'background-mode) 'dark) 0.08 0.95))))))

(defun cocolog-swatch-needs-outline-p (hex)
  "Non-nil when a swatch of HEX would melt into the frame background."
  (pcase cocolog-swatch-outline
    ('nil nil)
    ('auto (< (abs (- (cocolog-luminance (cocolog-normalize-hex hex))
                      (cocolog-background-luminance)))
              0.15))
    (_ t)))

(defun cocolog-blend-colors (a b fraction)
  "Return the colour FRACTION of the way from A to B."
  (cl-destructuring-bind (r1 g1 b1) (cocolog-hex-rgb (cocolog-normalize-hex a))
    (cl-destructuring-bind (r2 g2 b2) (cocolog-hex-rgb (cocolog-normalize-hex b))
      (format "#%02x%02x%02x"
              (round (+ r1 (* fraction (- r2 r1))))
              (round (+ g1 (* fraction (- g2 g1))))
              (round (+ b1 (* fraction (- b2 b1))))))))

(defun cocolog-swatch-face (hex)
  "Return the face a swatch of the colour HEX is drawn with.
The text on it is black or white, whichever the colour itself calls
for, so it never depends on the theme; the outline does, and comes back
whenever the theme changes."
  (let ((key (list hex cocolog-swatch-outline (display-graphic-p)
                   (cocolog-background-luminance))))
    (or (gethash key cocolog--swatch-face-cache)
        (puthash key (cocolog--swatch-face-1 hex) cocolog--swatch-face-cache))))

(defun cocolog--swatch-face-1 (hex)
  "Work out the face for a swatch of HEX.  See `cocolog-swatch-face'."
  (let* ((hex (cocolog-normalize-hex hex))
         (fg (cocolog-contrast-color hex))
         (face (list :background hex :foreground fg)))
    (if (cocolog-swatch-needs-outline-p hex)
        ;; an edge, not a highlight: a line in the contrast colour itself
        ;; would draw more attention than the swatch it is meant to save
        (let ((edge (cocolog-blend-colors hex fg 0.45)))
          (append face (if (display-graphic-p)
                           (list :box (list :line-width -1 :color edge))
                         (list :underline edge))))
      face)))

(defvar cocolog--distance-cache (make-hash-table :test 'equal)
  "Cached distances, keyed by the pair of colours.")

(defun cocolog-color-distance (a b)
  "How far apart the colours A and B look, from 0 to about 765.
This is the \"redmean\" approximation: cheap, and much closer to what
the eye does than measuring the distance between two RGB triples.  The
answers are kept, since the same pairs come up again and again."
  (let ((key (if (string-lessp a b) (cons a b) (cons b a))))
    (or (gethash key cocolog--distance-cache)
        (puthash key (cocolog--color-distance-1 a b) cocolog--distance-cache))))

(defun cocolog--color-distance-1 (a b)
  "Work out the distance between A and B.  See `cocolog-color-distance'."
  (cl-destructuring-bind (r1 g1 b1) (cocolog-hex-rgb a)
    (cl-destructuring-bind (r2 g2 b2) (cocolog-hex-rgb b)
      (let* ((rmean (/ (+ r1 r2) 2.0))
             (dr (- r1 r2)) (dg (- g1 g2)) (db (- b1 b2)))
        (sqrt (+ (* (+ 2 (/ rmean 256.0)) dr dr)
                 (* 4 dg dg)
                 (* (+ 2 (/ (- 255 rmean) 256.0)) db db)))))))

(defcustom cocolog-color-min-distance 250
  "How far apart the colours of one clause should be.
A variable takes the colour its name asks for when that colour is at
least this far from the ones its clause already uses; otherwise the
clause is given the furthest colour that is free, so that no two
variables of a rule are easy to mistake for each other.  Zero turns the
whole idea off and hands out colours by name alone."
  :type 'integer :group 'cocolog)

(defun cocolog-distinct-color (name taken &optional seed shun)
  "Return a colour for NAME that is not, and does not look like, one of TAKEN.
The colour a name asks for follows from the name and from SEED, so a
variable keeps its colour while you edit; it is only passed over when it
would be too close to a colour the clause already uses.  SHUN, when
given, is a predicate naming colours to avoid if there is any choice --
that is how a colour close to the background of the frame is left for
someone who asks for it by name rather than dealt out."
  (let* ((palette (mapcar (lambda (c) (downcase (cdr c))) cocolog-palette))
         (n (length palette))
         (start (mod (+ (sxhash-equal name) (or seed 0)) n))
         (free '()))
    (dotimes (i n)
      (let ((hex (nth (mod (+ start i) n) palette)))
        (unless (member hex taken) (push hex free))))
    (setq free (nreverse free))
    (when shun
      (let ((wanted (cl-remove-if shun free)))
        (when wanted (setq free wanted))))
    (cond
     ((null free) (nth start palette))
     ((null taken) (car free))
     (t
      ;; each candidate is measured against what is taken exactly once,
      ;; and the answer carried along: doing it inside a sort predicate
      ;; measured the same pair over and over
      (let* ((scored (mapcar (lambda (hex)
                               (cons (apply #'min
                                            (mapcar (lambda (other)
                                                      (cocolog-color-distance hex other))
                                                    taken))
                                     hex))
                             free))
             (far (cl-find-if (lambda (pair)
                                (>= (car pair) cocolog-color-min-distance))
                              scored)))
        (cdr (or far
                 ;; nothing is far enough: take whatever is furthest
                 (car (sort scored (lambda (x y) (> (car x) (car y))))))))))))

(defun cocolog-contrast-color (hex)
  "Return black or white, whichever is readable on HEX."
  (if (> (cocolog-luminance hex) 0.55) "#000000" "#ffffff"))

(defun cocolog-color-display-name (hex)
  "Return the name of HEX to show when a variable has no name of its own.
Palette colours are called by their name, anything else by its hex."
  (let ((h (cocolog-normalize-hex hex)))
    (or (car (rassoc h cocolog-palette)) h)))

(defun cocolog-color-name (hex)
  "Return the palette name of HEX, or the nearest name plus a tilde."
  (let* ((h (cocolog-normalize-hex hex))
         (exact (car (rassoc h cocolog-palette))))
    (or exact
        (let ((best nil) (best-d most-positive-fixnum))
          (dolist (c cocolog-palette)
            (let ((d (cocolog-color-distance h (cdr c))))
              (when (< d best-d) (setq best-d d best (car c)))))
          (concat "~" best)))))

;;;; ------------------------------------------------------------------
;;;; Colour variables
;;;; ------------------------------------------------------------------

(defun cocolog-color-to-var (hex &optional label)
  "Return the Prolog variable that stands for the colour HEX.
With LABEL, the developer\='s own name for that variable is appended, so
the variable carries both a colour and a name.  A LABEL equal to the
name of the colour is dropped again: that is the default anyway."
  (let ((hex (cocolog-normalize-hex hex)))
    (concat "C" (substring hex 1)
            (if (and label
                     (not (string= label (cocolog-color-display-name hex))))
                (concat "_" label)
              ""))))

(defun cocolog-var-label (name)
  "Return the name the developer gave the colour variable NAME, or nil."
  (let ((case-fold-search nil))
    (when (and name
               (string-match (concat "\\`" cocolog-color-var-regexp "\\'") name))
      (match-string 2 name))))

(defun cocolog-var-display-name (name)
  "Return what a colour variable NAME is called.
That is the name the developer gave it, or else the name of its colour."
  (or (cocolog-var-label name)
      (let ((hex (cocolog-var-to-color name)))
        (and hex (cocolog-color-display-name hex)))))

(defun cocolog-valid-label-p (label)
  "Non-nil when LABEL may be used as the name of a colour variable."
  (let ((case-fold-search nil))
    (and (stringp label)
         (string-match-p "\\`[A-Za-z][A-Za-z0-9_]*\\'" label))))

(defun cocolog-var-to-color (name)
  "Return the colour of the variable NAME, or nil if NAME is not one."
  (let ((case-fold-search nil))
    (when (and name
               (string-match (concat "\\`" cocolog-color-var-regexp "\\'") name))
      (concat "#" (downcase (match-string 1 name))))))

(defun cocolog-color-var-p (name)
  "Non-nil when NAME is a colour variable."
  (and (cocolog-var-to-color name) t))

;;;; ------------------------------------------------------------------
;;;; The palette picker
;;;; ------------------------------------------------------------------

(defun cocolog-picked-color (picked)
  "Return the colour of PICKED, as returned by `cocolog-read-color'."
  (if (consp picked) (car picked) picked))

(defun cocolog-picked-label (picked)
  "Return the name in PICKED, as returned by `cocolog-read-color', or nil."
  (and (consp picked) (cdr picked)))

(defvar cocolog--palette-entries nil
  "The (NAME . HEX) list the picker is showing; nil means the whole palette.")

(defvar cocolog--palette-restricted nil
  "Non-nil while the picker is showing a set of colours already chosen.
The keys that reach outside that set -- a random colour, the next unused
one, a hex typed by hand -- are then not offered.")

(defcustom cocolog-palette-used-first t
  "When non-nil, the palette leads with the colours of the clause at hand.
Picking one of those means reusing that variable, which is the commonest
reason to open the palette at all, so they are put where the cursor
starts rather than scattered through the grid.  Set this to nil to keep
the grid in the same order every time."
  :type 'boolean :group 'cocolog)

(defun cocolog-palette-used-first (used)
  "Return the palette with the colours in USED, an alist, brought to the front.
They keep the order they have in USED, which is the order they appear in
the clause; the rest of the palette follows unchanged."
  (let* ((order (mapcar (lambda (c) (downcase (car c))) used))
         (hit (cl-remove-if-not
               (lambda (c) (member (downcase (cdr c)) order)) cocolog-palette))
         (rest (cl-remove-if
                (lambda (c) (member (downcase (cdr c)) order)) cocolog-palette)))
    (append (sort hit (lambda (a b)
                        (< (or (cl-position (downcase (cdr a)) order :test #'equal) 0)
                           (or (cl-position (downcase (cdr b)) order :test #'equal) 0))))
            rest)))

(defun cocolog-palette-entries ()
  "The (NAME . HEX) list the picker is showing."
  (or cocolog--palette-entries cocolog-palette))

(defvar cocolog--palette-index 0)
(defvar cocolog--palette-used nil)
(defvar cocolog--palette-prompt "Pick a colour")

(defconst cocolog--palette-cell-width 5
  "Columns one palette cell takes up, the gap after it included.")

(defconst cocolog--palette-left-margin 2
  "Column the first cell of a palette row starts at.")

(defun cocolog--palette-cell (hex selected used col)
  "Render the palette cell for HEX, starting at column COL.

The cell ends with two stretches of space rather than plain ones: a
marker glyph is not always exactly one column wide in the frame's font,
and without them one such glyph would push the rest of the row a couple
of pixels to the right.  A stretch is drawn to an absolute column, so
every cell of the grid starts and ends where it should whatever is
inside it."
  (let* ((face (cocolog-swatch-face hex))
         (mark (if used (cocolog-glyph "•" "*") " "))
         (text (concat (if selected "[" " ") mark (if selected "]" " ")))
         (props (list 'cocolog-color hex
                      'mouse-face 'highlight
                      'help-echo (format "%s  %s" (cocolog-color-name hex) hex))))
    (concat
     (apply #'propertize text 'face face props)
     ;; fill the colour out to exactly four columns
     (apply #'propertize " " 'face face
            'display (list 'space :align-to (+ col 4))
            props)
     ;; and leave exactly one column of gap before the next cell
     (propertize " " 'display
                 (list 'space :align-to (+ col cocolog--palette-cell-width))))))

(defun cocolog-glyph (uni ascii)
  "Return UNI when the display can show it, ASCII otherwise."
  (if (and (boundp 'cocolog-graph-unicode) (not (symbol-value 'cocolog-graph-unicode)))
      ascii
    (if (char-displayable-p (aref uni 0)) uni ascii)))

(defun cocolog--palette-render (buffer)
  "Draw the palette into BUFFER."
  (with-current-buffer buffer
    (let* ((inhibit-read-only t)
           (entries (cocolog-palette-entries))
           (cols (min cocolog-palette-columns (max 1 (length entries))))
           (n (length entries))
           (i 0))
      (erase-buffer)
      (let* ((cur (nth cocolog--palette-index entries))
             (hex (cdr cur))
             (uses (cdr (assoc (downcase hex) cocolog--palette-used))))
        (insert (propertize (concat " " cocolog--palette-prompt ":  ") 'face 'bold)
                (propertize (format " %s " (car cur)) 'face (cocolog-swatch-face hex))
                (propertize (format "  %s" hex) 'face 'shadow)
                (if uses
                    (propertize (format "   already used %d× in this clause" uses)
                                'face 'warning)
                  "")
                "\n\n"))
      (while (< i n)
        (insert (make-string cocolog--palette-left-margin ?\s))
        (dotimes (c cols)
          (let ((idx (+ i c)))
            (when (< idx n)
              (insert (cocolog--palette-cell
                       (cdr (nth idx entries))
                       (= idx cocolog--palette-index)
                       (assoc (downcase (cdr (nth idx entries)))
                              cocolog--palette-used)
                       (+ cocolog--palette-left-margin
                          (* c cocolog--palette-cell-width)))))))
        (insert "\n")
        (setq i (+ i cols)))
      (insert "\n"
              (propertize
               (if cocolog--palette-restricted
                   "  arrows/hjkl move   RET pick   q cancel"
                 (concat "  arrows/hjkl move   RET pick   n pick and name it   "
                         "# type a hex colour   r random unused   "
                         "TAB next unused   q cancel"))
               'face 'shadow))
      ;; line numbers would shift the grid away from the columns the
      ;; stretches are drawn to
      (setq-local display-line-numbers nil)
      (goto-char (point-min))
      (set-buffer-modified-p nil))))

(defun cocolog--palette-index-of (hex)
  (let ((h (cocolog-normalize-hex hex)))
    (cl-position-if (lambda (c) (equal (downcase (cdr c)) h))
                    (cocolog-palette-entries))))

(defun cocolog-read-color (&optional prompt used initial)
  "Let the user pick a colour visually.
Return \"#rrggbb\", or a cons (\"#rrggbb\" . NAME) when the user asked
to name the variable as well, or nil when they gave up.  Read the two
apart with `cocolog-picked-color\=' and `cocolog-picked-label\='.

PROMPT is shown in the header.  USED is an alist of (HEX . COUNT) for
the colours already used nearby; they are marked in the grid.  INITIAL
is the colour to start on."
  (let ((cocolog--palette-entries
         (or cocolog--palette-entries
             (and cocolog-palette-used-first used
                  (cocolog-palette-used-first used)))))
   (if (or noninteractive (not (display-color-p)))
      (let* ((entries (cocolog-palette-entries))
             (name (completing-read (format "%s (name or #rrggbb): "
                                            (or prompt "Colour"))
                                    (mapcar #'car entries) nil
                                    cocolog--palette-restricted)))
        (or (cdr (assoc name entries)) (cocolog-normalize-hex name)))
    (let* ((buffer (get-buffer-create "*cocolog palette*"))
           (cocolog--palette-used
            (mapcar (lambda (c) (cons (downcase (car c)) (cdr c))) used))
           (cocolog--palette-prompt (or prompt "Pick a colour"))
           (cocolog--palette-index (or (and initial (cocolog--palette-index-of initial)) 0))
           (entries (cocolog-palette-entries))
           (rows (ceiling (length entries)
                          (min cocolog-palette-columns (max 1 (length entries)))))
           (window nil)
           (result nil)
           (done nil))
      (unwind-protect
          (progn
            (with-current-buffer buffer
              (setq buffer-read-only t cursor-type nil)
              (setq-local mode-line-format nil))
            (setq window (display-buffer-at-bottom
                          buffer `((window-height . ,(+ rows 6)))))
            (while (not done)
              (cocolog--palette-render buffer)
              (let* ((n (length entries))
                     (cols (min cocolog-palette-columns (max 1 n)))
                     (event (read-key
                             (format "%s  [%s]" cocolog--palette-prompt
                                     (car (nth cocolog--palette-index entries))))))
                (pcase event
                  ((or 'left ?h ?b) (setq cocolog--palette-index
                                          (mod (1- cocolog--palette-index) n)))
                  ((or 'right ?l ?f) (setq cocolog--palette-index
                                           (mod (1+ cocolog--palette-index) n)))
                  ((or 'up ?k ?\C-p) (setq cocolog--palette-index
                                            (mod (- cocolog--palette-index cols) n)))
                  ((or 'down ?j ?\C-n) (setq cocolog--palette-index
                                              (mod (+ cocolog--palette-index cols) n)))
                  ('home (setq cocolog--palette-index 0))
                  ('end (setq cocolog--palette-index (1- n)))
                  ((and ?\t (guard (not cocolog--palette-restricted)))
                   (let ((i (cl-position-if
                             (lambda (c) (not (assoc (downcase (cdr c))
                                                     cocolog--palette-used)))
                             entries :start (min (1+ cocolog--palette-index) n))))
                     (setq cocolog--palette-index
                           (or i (cl-position-if
                                  (lambda (c) (not (assoc (downcase (cdr c))
                                                          cocolog--palette-used)))
                                  entries)
                               cocolog--palette-index))))
                  ((and ?r (guard (not cocolog--palette-restricted)))
                   (let ((free (cl-remove-if (lambda (c) (assoc (downcase (cdr c))
                                                                cocolog--palette-used))
                                             entries)))
                     (when free
                       (setq cocolog--palette-index
                             (cocolog--palette-index-of
                              (cdr (nth (random (length free)) free)))))))
                  ((and ?# (guard (not cocolog--palette-restricted)))
                   (let ((h (cocolog-normalize-hex
                             (read-string "Colour (#rrggbb or a colour name): "))))
                     (if h (setq result h done t)
                       (message "Not a colour"))))
                  ((or ?\r ?\s)
                   (setq result (cdr (nth cocolog--palette-index entries))
                         done t))
                  ((and ?n (guard (not cocolog--palette-restricted)))
                   (let* ((hex (cdr (nth cocolog--palette-index entries)))
                          (label (string-trim
                                  (read-string
                                   (format "Name for this %s variable: "
                                           (cocolog-color-display-name hex))
                                   nil nil (cocolog-color-display-name hex)))))
                     (cond
                      ((string-empty-p label) (setq result hex done t))
                      ((cocolog-valid-label-p label)
                       (setq result (cons hex label) done t))
                      (t (message "`%s\' cannot be the name of a variable" label)))))
                  ((or ?q ?\e ?\C-g) (setq done t))
                  ((pred consp)
                   (let* ((pos (event-start event))
                          (p (posn-point pos)))
                     (when (and p (eq (window-buffer (posn-window pos)) buffer))
                       (let ((hex (get-text-property p 'cocolog-color buffer)))
                         (when hex
                           (if (memq (car event) '(mouse-1 down-mouse-1))
                               (setq cocolog--palette-index (cocolog--palette-index-of hex))
                             nil))
                         (when (and hex (eq (car event) 'mouse-1))
                           (setq result hex done t))))))
                  (_ nil))))
            (cond
             ((consp result) (cons (cocolog-normalize-hex (car result)) (cdr result)))
             (result (cocolog-normalize-hex result))))
        (when (window-live-p window) (quit-window nil window))
        (kill-buffer buffer))))))

(provide 'cocolog-color)

;;; cocolog-color.el ends here
