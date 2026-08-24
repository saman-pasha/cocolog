;;; conformance.el --- Answer the queries `make coco' compares -*- lexical-binding: t; -*-

;;; Commentary:

;; Prints, one per line, what the engine of the mode answers for every
;; test case in the example files and every query in
;; test/conformance-queries.txt:
;;
;;     FILE <TAB> QUERY <TAB> SOLUTIONS
;;
;; tools/coco-diff.sh asks cocolog the same questions and compares.

;;; Code:

(require 'cocolog-mode)

(defun conformance--answer (db query)
  "Return what the engine answers for QUERY against DB, as one line."
  (let* ((result (cocolog-run-query db query 10))
         (sols (cocolog-result-solutions result)))
    (cond
     ((cocolog-result-message result)
      (concat "ERROR: " (cocolog-result-message result)))
     ((null sols) "no solutions")
     ((cl-every #'null sols) "true")
     (t (mapconcat (lambda (s)
                     (mapconcat (lambda (b) (format "%s=%s" (car b) (cdr b))) s ","))
                   sols " ; ")))))

(defun conformance--report (file query)
  (princ (format "%s\t%s\t%s\n" file (string-trim query)
                 (conformance--answer (conformance--db file) query))))

(defvar conformance--dbs (make-hash-table :test 'equal))
(defun conformance--db (file)
  (or (gethash file conformance--dbs)
      (puthash file
               (with-temp-buffer
                 (insert-file-contents (expand-file-name file))
                 (cocolog-consult-string (buffer-string)))
               conformance--dbs)))

;; the test cases of the examples
(dolist (file (sort (directory-files "examples" nil "\\.colog\\'") #'string<))
  (let ((path (concat "examples/" file))
        (seen '()))
    (with-temp-buffer
      (insert-file-contents path)
      (cocolog-mode)
      (let ((db (cocolog-buffer-db)))
        (dolist (rec (cocolog-db-order db))
          (dolist (query (cocolog--clause-own-queries rec))
            (unless (member query seen)
              (push query seen)
              (princ (format "%s\t%s\t%s\n" path (string-trim query)
                             (conformance--answer db query))))))))))

;; and the queries written for this comparison
(let ((program "test/conformance.pl"))
  (with-temp-buffer
    (insert-file-contents "test/conformance-queries.txt")
    (dolist (query (split-string (buffer-string) "\n" t))
      (unless (string-prefix-p "#" query)
        (conformance--report program query)))))

;; and every example the snippet pickers show.  What the picker offers is
;; a promise that the piece runs, and the piece must run under cocolog,
;; not only under the engine -- so each example travels with the program
;; its piece brings along (itself, when it is a whole rule), in a fourth
;; column with its newlines written as \n.
(defun conformance--escape (text)
  (replace-regexp-in-string
   "\n" "\\\\n" (replace-regexp-in-string "\\\\" "\\\\\\\\" text)))

(dolist (table (list cocolog-builtin-snippets cocolog-dcg-snippets))
  (dolist (row (cocolog--pick-rows table))
    (let* ((query (nth 3 row))
           (program (let ((plain (replace-regexp-in-string
                                  cocolog--placeholder-regexp "\\1" (nth 0 row))))
                      (if (string-match-p "-->\\|:-" plain) plain "")))
           (db (cocolog-consult-string program)))
      (princ (format "%s\t%s\t%s\t%s\n"
                     (format "snippet: %s" (cocolog--pick-oneline (nth 0 row)))
                     (string-trim query)
                     (conformance--answer db query)
                     (conformance--escape program))))))

;;; conformance.el ends here
