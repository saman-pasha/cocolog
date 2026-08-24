;;; cocolog-svg.el --- Render a fontified cocolog buffer to SVG -*- lexical-binding: t; -*-

;;; Commentary:

;; Documentation helper, not part of the mode.  It takes a buffer that
;; `cocolog-mode' has fontified and writes an SVG picture of it, colour
;; swatches included, so README.md can show what Emacs actually shows.
;;
;; Syntax colours come from the theme tables below rather than from the
;; running Emacs, so the pictures are reproducible and can be generated
;; for a light and a dark reader.  The colours of the colour variables
;; are the real ones: they are read from the text properties that
;; `cocolog-mode' put there.
;;
;;   make doc

;;; Code:

(require 'cl-lib)
(require 'cocolog-mode)

(defconst cocolog-svg-char-width 8.0)
(defconst cocolog-svg-line-height 19.0)
(defconst cocolog-svg-font-size 13.5)
(defconst cocolog-svg-padding 14.0)
(defconst cocolog-svg-font
  "ui-monospace, SFMono-Regular, Menlo, Consolas, 'DejaVu Sans Mono', monospace")

(defconst cocolog-svg-light
  '((:background . "#ffffff")
    (:foreground . "#24292f")
    (:border     . "#d0d7de")
    (font-lock-comment-face      :foreground "#6e7781")
    (font-lock-function-name-face :foreground "#8250df" :weight bold)
    (font-lock-keyword-face      :foreground "#cf222e")
    (font-lock-preprocessor-face :foreground "#cf222e")
    (font-lock-builtin-face      :foreground "#0550ae")
    (font-lock-constant-face     :foreground "#0550ae")
    (font-lock-variable-name-face :foreground "#953800")
    (font-lock-string-face       :foreground "#0a3069")
    (font-lock-warning-face      :foreground "#cf222e" :weight bold)
    (cocolog-cut-face            :foreground "#cf222e" :weight bold)
    (cocolog-test-face           :foreground "#1a7f37" :weight bold)
    (cocolog-trace-face          :foreground "#8c959f")
    (shadow                      :foreground "#8c959f")
    (warning                     :foreground "#9a6700")
    (bold                        :weight bold))
  "Colours used when rendering for a light background.")

(defconst cocolog-svg-dark
  '((:background . "#0d1117")
    (:foreground . "#e6edf3")
    (:border     . "#30363d")
    (font-lock-comment-face      :foreground "#8b949e")
    (font-lock-function-name-face :foreground "#d2a8ff" :weight bold)
    (font-lock-keyword-face      :foreground "#ff7b72")
    (font-lock-preprocessor-face :foreground "#ff7b72")
    (font-lock-builtin-face      :foreground "#79c0ff")
    (font-lock-constant-face     :foreground "#79c0ff")
    (font-lock-variable-name-face :foreground "#ffa657")
    (font-lock-string-face       :foreground "#a5d6ff")
    (font-lock-warning-face      :foreground "#ff7b72" :weight bold)
    (cocolog-cut-face            :foreground "#ff7b72" :weight bold)
    (cocolog-test-face           :foreground "#7ee787" :weight bold)
    (cocolog-trace-face          :foreground "#6e7681")
    (shadow                      :foreground "#6e7681")
    (warning                     :foreground "#d29922")
    (bold                        :weight bold))
  "Colours used when rendering for a dark background.")

(defun cocolog-svg--escape (s)
  "Escape S for XML.  The ampersand goes first, or the others are undone."
  (replace-regexp-in-string
   ">" "&gt;"
   (replace-regexp-in-string
    "<" "&lt;"
    (replace-regexp-in-string "&" "&amp;" s))))

(defun cocolog-svg--merge (face theme)
  "Resolve FACE against THEME into a (FG BG WEIGHT SLANT) list.
FACE is whatever a `face' text property may hold: nil, a face symbol,
an attribute plist, or a list of those, earlier entries winning."
  (let ((fg nil) (bg nil) (weight nil) (slant nil) (box nil))
    (cl-labels
        ((take (plist)
           (unless fg (setq fg (plist-get plist :foreground)))
           (unless bg (setq bg (plist-get plist :background)))
           (unless weight (setq weight (plist-get plist :weight)))
           (unless slant (setq slant (plist-get plist :slant)))
           (unless box
             (let ((spec (plist-get plist :box)))
               (setq box (cond ((consp spec) (plist-get spec :color))
                               (spec fg)
                               (t nil))))))
         (walk (f)
           (cond
            ((null f) nil)
            ((symbolp f) (let ((entry (assq f theme))) (when entry (take (cdr entry)))))
            ((and (consp f) (keywordp (car f))) (take f))
            ((consp f) (mapc #'walk f)))))
      (walk face))
    (list (or fg (cdr (assq :foreground theme))) bg weight slant box)))

(defun cocolog-svg--runs (beg end)
  "Split the region BEG..END into lines of display runs.
Each run is (TEXT FACE); a `display' string replaces the text it hides,
which is how colour swatches make it into the picture."
  (let ((lines '()))
    (save-excursion
      (goto-char beg)
      (while (< (point) end)
        (let* ((eol (min end (line-end-position)))
               (pos (point))
               (runs '()))
          (while (< pos eol)
            (let* ((next (or (next-property-change pos nil eol) eol))
                   (disp (get-text-property pos 'display)))
              (if (stringp disp)
                  (push (list disp (or (get-text-property 0 'face disp)
                                       (get-text-property pos 'face)))
                        runs)
                (push (list (buffer-substring-no-properties pos next)
                            (get-text-property pos 'face))
                      runs))
              (setq pos next)))
          (push (nreverse runs) lines)
          (goto-char (1+ eol)))))
    (nreverse lines)))

(defun cocolog-svg-render (beg end &optional theme title)
  "Return an SVG picture of the region BEG..END of the current buffer.
THEME defaults to `cocolog-svg-light'.  TITLE becomes the <title>."
  (cocolog-svg-render-lines (cocolog-svg--runs beg end) theme title))

(defun cocolog-svg-render-lines (lines &optional theme title)
  "Return an SVG picture of LINES, as collected by `cocolog-svg--runs'.
Several buffers can be rendered into one picture by appending their
lines, which is how the swatch style comparison is made."
  (let* ((theme (or theme cocolog-svg-light))
         (cw cocolog-svg-char-width)
         (lh cocolog-svg-line-height)
         (pad cocolog-svg-padding)
         (cols (apply #'max 1 (mapcar (lambda (l)
                                        (apply #'+ 0 (mapcar (lambda (r)
                                                               (length (car r)))
                                                             l)))
                                      lines)))
         (width (+ (* cols cw) (* 2 pad)))
         (height (+ (* (length lines) lh) (* 2 pad)))
         (body '())
         (row 0))
    (dolist (line lines)
      (let ((col 0)
            (y (+ pad (* row lh))))
        (dolist (run line)
          (cl-destructuring-bind (text face) run
            (let* ((attrs (cocolog-svg--merge face theme))
                   (fg (nth 0 attrs)) (bg (nth 1 attrs))
                   (weight (nth 2 attrs)) (slant (nth 3 attrs))
                   (box (nth 4 attrs))
                   (n (length text))
                   (x (+ pad (* col cw))))
              (when bg
                (push (if box
                          ;; a swatch whose colour is close to the background
                          ;; is outlined, the way the mode outlines it
                          (format (concat "<rect x=\"%.1f\" y=\"%.1f\" width=\"%.1f\""
                                          " height=\"%.1f\" fill=\"%s\" stroke=\"%s\""
                                          " stroke-width=\"1\" stroke-opacity=\"0.55\"/>")
                                  (+ x 0.5) (+ y 0.5) (1- (* n cw)) (1- lh) bg box)
                        (format
                         "<rect x=\"%.1f\" y=\"%.1f\" width=\"%.1f\" height=\"%.1f\" fill=\"%s\"/>"
                         x y (* n cw) lh bg))
                      body))
              (unless (string-blank-p text)
                (push (format
                       (concat "<text x=\"%.1f\" y=\"%.1f\" fill=\"%s\" textLength=\"%.1f\""
                               " lengthAdjust=\"spacing\" xml:space=\"preserve\"%s%s>%s</text>")
                       x (+ y (* lh 0.74)) fg (* n cw)
                       (if (memq weight '(bold semi-bold ultra-bold)) " font-weight=\"600\"" "")
                       (if (memq slant '(italic oblique)) " font-style=\"italic\"" "")
                       (cocolog-svg--escape text))
                      body))
              (setq col (+ col n)))))
        (setq row (1+ row))))
    (concat
     "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
     (format (concat "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%.0f\" height=\"%.0f\""
                     " viewBox=\"0 0 %.0f %.0f\" font-family=\"%s\" font-size=\"%.1f\">\n")
             width height width height cocolog-svg-font cocolog-svg-font-size)
     (if title (format "<title>%s</title>\n" (cocolog-svg--escape title)) "")
     (format (concat "<rect x=\"0.5\" y=\"0.5\" width=\"%.0f\" height=\"%.0f\" rx=\"6\""
                     " fill=\"%s\" stroke=\"%s\"/>\n")
             (1- width) (1- height)
             (cdr (assq :background theme)) (cdr (assq :border theme)))
     (mapconcat #'identity (nreverse body) "\n")
     "\n</svg>\n")))

(defun cocolog-svg-write (outfile lines &optional title)
  "Write light and dark SVG pictures of LINES to OUTFILE.
OUTFILE gets the light picture; the dark one is written next to it with
a `-dark' suffix.  Returns the list of files written."
  (let* ((light (cocolog-svg-render-lines lines cocolog-svg-light title))
         (dark (cocolog-svg-render-lines lines cocolog-svg-dark title))
         (darkfile (concat (file-name-sans-extension outfile) "-dark.svg")))
    (with-temp-file outfile (insert light))
    (with-temp-file darkfile (insert dark))
    (list outfile darkfile)))

(defun cocolog-svg-region-of (from to)
  "Return (BEG . END) covering the whole lines from regexp FROM to regexp TO."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward from)
    (let ((beg (line-beginning-position)))
      (re-search-forward to)
      (cons beg (line-end-position)))))

(provide 'cocolog-svg)

;;; cocolog-svg.el ends here
