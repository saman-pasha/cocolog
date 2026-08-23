;;; cocolog-markdown.el --- Read cocolog docs in Emacs the way a browser shows them -*- lexical-binding: t; -*-

;;; Commentary:

;; README.md shows its coloured examples as SVG pictures wrapped in
;; <picture> so that a browser can pick a light or a dark one.
;; `markdown-mode' displays Markdown images (![alt](file)) but not HTML
;; ones, so in Emacs those examples stay raw tags.
;;
;; `cocolog-markdown-images-mode' displays them: it understands both
;; <img src="..."> and <picture> with a
;; media="(prefers-color-scheme: dark)" source, and picks the variant
;; that matches the theme you are using -- exactly what the browser
;; does.  It follows theme changes, so it also does the right thing
;; with something like `auto-dark'.
;;
;; Together with `cocolog-swatch-mode', which paints the Cxxxxxx names
;; in the fenced code blocks, this makes README.md look in Emacs the way
;; it looks on GitHub.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'image)
(require 'cocolog-mode)

(defgroup cocolog-markdown nil
  "Reading cocolog documentation inside Emacs."
  :group 'cocolog :prefix "cocolog-markdown-")

(defcustom cocolog-markdown-image-width 0.95
  "Width of an inline picture, as a fraction of the window body width.
A whole number is taken as a width in pixels instead."
  :type 'number :group 'cocolog-markdown)

(defcustom cocolog-markdown-image-margin 8
  "Blank pixels drawn around an inline picture."
  :type 'integer :group 'cocolog-markdown)

(defconst cocolog-markdown--picture-re
  "<picture>\\(?:.\\|\n\\)*?</picture>"
  "Regexp matching a whole HTML <picture> element.")

(defconst cocolog-markdown--img-re
  "<img\\(?:[ \t\n][^>]*\\)?>"
  "Regexp matching an HTML <img> element.")

(defun cocolog-markdown--attribute (name text)
  "Return the value of the NAME=\"...\" attribute in TEXT, or nil."
  (when (string-match (concat "\\_<" (regexp-quote name) "[ \t]*=[ \t]*\"\\([^\"]*\\)\"")
                      text)
    (match-string 1 text)))

(defun cocolog-markdown--dark-p ()
  "Non-nil when the current frame has a dark background."
  (eq (frame-parameter nil 'background-mode) 'dark))

(defun cocolog-markdown--pick-source (text)
  "Return the image file TEXT refers to, honouring the colour scheme.
TEXT is a <picture> or <img> element."
  (let* ((dark (cocolog-markdown--dark-p))
         (chosen nil))
    ;; <source media="(prefers-color-scheme: dark)" srcset="...">
    (when dark
      (let ((pos 0))
        (while (and (not chosen)
                    (string-match "<source\\([^>]*\\)>" text pos))
          (let ((attrs (match-string 1 text)))
            (setq pos (match-end 0))
            (when (and (cocolog-markdown--attribute "media" attrs)
                       (string-match-p
                        "dark" (cocolog-markdown--attribute "media" attrs)))
              (setq chosen (cocolog-markdown--attribute "srcset" attrs)))))))
    (or chosen
        (when (string-match cocolog-markdown--img-re text)
          (cocolog-markdown--attribute "src" (match-string 0 text)))
        (cocolog-markdown--attribute "src" text))))

(defun cocolog-markdown--alt (text)
  (or (when (string-match cocolog-markdown--img-re text)
        (cocolog-markdown--attribute "alt" (match-string 0 text)))
      "picture"))

(defun cocolog-markdown--max-width ()
  (let ((w cocolog-markdown-image-width))
    (if (and (numberp w) (<= w 1))
        (max 200 (round (* w (window-body-width nil t))))
      (round w))))

(defun cocolog-markdown--make-image (file)
  "Create an image for FILE, scaled to the window, or nil."
  (let ((type (ignore-errors (image-type file nil nil))))
    (when (and type (image-type-available-p type))
      (create-image file type nil
                    :scale 1
                    :max-width (cocolog-markdown--max-width)
                    :margin cocolog-markdown-image-margin
                    :ascent 'center))))

(defun cocolog-markdown--code-at-p (pos)
  "Non-nil when POS is inside code rather than in the page itself.
A page about HTML writes `<img ...>\=' in a code span or a fenced block
to talk about it; that is text to read, not a picture to show."
  (or (and (fboundp 'markdown-code-block-at-pos)
           (markdown-code-block-at-pos pos)
           t)
      (and (fboundp 'markdown-inline-code-at-pos)
           (markdown-inline-code-at-pos pos)
           t)))

(defun cocolog-markdown-remove-images ()
  "Remove the inline pictures put up by `cocolog-markdown-display-images'."
  (interactive)
  (remove-overlays (point-min) (point-max) 'cocolog-markdown-image t))

(defun cocolog-markdown-display-images ()
  "Display every HTML <img> and <picture> of the buffer as a picture.
Files are looked up relative to the file the buffer visits."
  (interactive)
  (cocolog-markdown-remove-images)
  (let ((count 0)
        (dir (if buffer-file-name
                 (file-name-directory buffer-file-name)
               default-directory)))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (concat cocolog-markdown--picture-re "\\|" cocolog-markdown--img-re)
              nil t)
        (let* ((beg (match-beginning 0))
               (end (match-end 0))
               (text (match-string 0))
               (src (and (not (cocolog-markdown--code-at-p beg))
                         (cocolog-markdown--pick-source text)))
               (file (and src (expand-file-name src dir))))
          (when (and file (file-readable-p file))
            (let ((image (cocolog-markdown--make-image file)))
              (when image
                (let ((overlay (make-overlay beg end)))
                  (overlay-put overlay 'cocolog-markdown-image t)
                  (overlay-put overlay 'display image)
                  (overlay-put overlay 'evaporate t)
                  (overlay-put overlay 'help-echo
                               (format "%s -- %s" (file-relative-name file dir)
                                       (cocolog-markdown--alt text)))
                  (cl-incf count))))))))
    (when (called-interactively-p 'interactive)
      (message "%d picture%s displayed" count (if (= count 1) "" "s")))
    count))

(defun cocolog-markdown--refresh (&rest _)
  (when (bound-and-true-p cocolog-markdown-images-mode)
    (cocolog-markdown-display-images)))

(defvar cocolog-markdown-images-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-x C-p") #'cocolog-markdown-images-mode)
    map)
  "Keymap of `cocolog-markdown-images-mode'.")

(defconst cocolog-markdown-menu-spec
  '("Coco"
    ["Show the pictures" cocolog-markdown-display-images
     :help "Display every <img> and <picture> of this buffer inline"]
    ["Hide the pictures" cocolog-markdown-remove-images
     :help "Show the HTML tags again"]
    ["Pictures shown" cocolog-markdown-images-mode
     :style toggle :selected (bound-and-true-p cocolog-markdown-images-mode)
     :help "Show the pictures of this buffer, or the tags they are written as"]
    "---"
    ["Colour swatches" cocolog-swatch-mode
     :style toggle :selected (bound-and-true-p cocolog-swatch-mode)
     :help "Paint the Cxxxxxx names of this buffer in their own colour"]
    ("Show colour variables as"
     ["Swatch" (cocolog-markdown--set-style 'block)
      :style radio :selected (eq cocolog-swatch-style 'block)
      :help "A block of the colour, with no name in it"]
     ["Colour name" (cocolog-markdown--set-style 'name)
      :style radio :selected (eq cocolog-swatch-style 'name)
      :help "The name of the variable, on a ground of its colour"]
     ["Coloured text" (cocolog-markdown--set-style 'text)
      :style radio :selected (eq cocolog-swatch-style 'text)
      :help "The text as it stands, written in the colour"])
    "---"
    ["Show both" cocolog-markdown-setup
     :help "Turn on the swatches and the pictures at once"]
    ["Customize..." (customize-group 'cocolog-markdown)
     :help "Every setting of the Markdown side of the mode"])
  "The Coco menu of a Markdown buffer.")

(defun cocolog-markdown--set-style (style)
  "Show colour variables as STYLE in this buffer only."
  (setq-local cocolog-swatch-style style)
  (with-silent-modifications
    (remove-text-properties (point-min) (point-max) '(display nil)))
  (font-lock-flush)
  (font-lock-ensure)
  (cocolog--menu-changed))

(easy-menu-define cocolog-markdown-menu cocolog-markdown-images-mode-map
  "The Coco menu of `cocolog-markdown-images-mode'."
  cocolog-markdown-menu-spec)

;;;###autoload
(define-minor-mode cocolog-markdown-images-mode
  "Show the HTML pictures of a Markdown buffer inline.

`markdown-mode' can display Markdown images itself, but not the HTML
<img> and <picture> elements a README needs in order to offer a light
and a dark version of a picture.  This mode displays those, choosing
the variant that suits the current theme and following theme changes."
  :lighter " Cimg"
  :keymap cocolog-markdown-images-mode-map
  :group 'cocolog-markdown
  (if cocolog-markdown-images-mode
      (progn
        (cocolog-markdown-display-images)
        (when (boundp 'enable-theme-functions)
          (add-hook 'enable-theme-functions #'cocolog-markdown--refresh nil t))
        (when (boundp 'disable-theme-functions)
          (add-hook 'disable-theme-functions #'cocolog-markdown--refresh nil t))
        (add-hook 'after-save-hook #'cocolog-markdown--refresh nil t))
    (when (boundp 'enable-theme-functions)
      (remove-hook 'enable-theme-functions #'cocolog-markdown--refresh t))
    (when (boundp 'disable-theme-functions)
      (remove-hook 'disable-theme-functions #'cocolog-markdown--refresh t))
    (remove-hook 'after-save-hook #'cocolog-markdown--refresh t)
    (cocolog-markdown-remove-images))
  (cocolog--menu-changed))

;;;###autoload
(defun cocolog-markdown-setup ()
  "Turn on everything that makes cocolog documentation readable here.
Meant for `markdown-mode-hook\=' and `gfm-mode-hook\=', and offered in
the Coco menu of a Markdown buffer, which is why it is a command."
  (interactive)
  ;; The colours of a code block are worked out from the whole block, and
  ;; the mode of the moment is told where a block begins and ends by the
  ;; text properties Markdown lays down.  Those are laid down lazily, so
  ;; ask for them all now: fontifying a block whose end is not known yet
  ;; would colour its first lines from one set of variables and the rest
  ;; from another.
  (syntax-propertize (point-max))
  (cocolog-swatch-mode 1)
  (cocolog-markdown-images-mode 1))

(provide 'cocolog-markdown)

;;; cocolog-markdown.el ends here
