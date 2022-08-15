;;; break-line.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Tommy Alford
;;
;; Author: Tommy Alford <tdalford1@gmail.com>
;; Maintainer: Tommy Alford <tdalford1@gmail.com>
;; Created: August 15, 2022
;; Modified: August 15, 2022
;; Version: 0.0.1
;; Keywords: convenience python julia
;; Homepage: https://github.com/tommyalford/break-line
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;  Provides a convenient way to break lines which use pythonic style functions
;;  args and calls.
;;
;;; Code:


(defvar break-line-open-delim-regex "[({\[]"
  "A regex to search for when finding an opening delimiter.
\(i.e. paren, backet, etc)")

(defvar break-line-arg-sep-regex "[,;]"
  "A regex to search for when finding function args.
\(i.e. the language's function arg separators")

(defun break-line-opening-delimiter ()
  "Breaks a pythonic line into multiple via opening delimiter.
Searches for the closest opening delimiter and then newline/indents
there. Conforms to https://peps.python.org/pep-0008/#indentation"
  (interactive)
  ;; #1: align with opening delimiter
  ;; start at col (fill-column), go until we hit a forward delimiter,
  ;; then create newline
  (move-to-column fill-column)
  (re-search-backward break-line-open-delim-regex)
  (forward-char)
  (newline-and-indent))

(defun break-line-arg-sep ()
  "Breaks a pythonic line into multiple via function args.
Searches for the closest function arg and then newline/indents
there. Conforms to https://peps.python.org/pep-0008/#indentation"
  (interactive)
  ;; type 2: start at col, go to closest arg sep, then create newline
  (move-to-column fill-column)
  ;; look for the first comma which seps a var
  (re-search-backward break-line-arg-sep-regex)
  (forward-char)
  (newline-and-indent))

;; need a function to check if an opening delim is on our line
;; use (save-excursion)
;;

;; algorithm:
;;
;; total alg: try type 1, check if there's a forward delim. If there's none try
;; type 2, continue if next line is longer than 80 chars
;;
;; other bind: keep using type 2 while there is a comma on the line (otherwise
;; try type 1?)
;;
;; see: evil-snipe--seek-re in evil-snipe for similar checks!
;; we can actually re-search forward with a bound (return nil if not found)

(defun break-line--re-search-backward-current-line (regexp)
  "Search for REGEXP only until the start of the current line."
  ;; get the start of the current line and search until this
  (re-search-backward regexp (line-beginning-position) t))

(defun break-line--curr-line-length ()
  "Get the length of the current line."
  ;; Go to the end and find the current column.
    (goto-char (line-end-position))
    (current-column))

(defun break-line--check-line-and-search (regexp)
  "Search for REGEXP and check that line is longer than the fill column."
  (save-excursion
  (move-to-column fill-column)
  (and (break-line--re-search-backward-current-line regexp)
       (> (break-line--curr-line-length) fill-column))))

(defun break-line-1 ()
  "Break the line once via opening delim and from then on via arg seps."
  (interactive)
  ;; one trial of finding an opening delim
  (if (break-line--check-line-and-search break-line-open-delim-regex)
    (break-line-opening-delimiter))

  ;; then check the prev arg
  (while (break-line--check-line-and-search break-line-arg-sep-regex)
    (break-line-arg-sep)))

(defun break-line-2 ()
  "Break the line only via arg seps."
  (interactive)
  (while (break-line--check-line-and-search break-line-arg-sep-regex)
    (break-line-arg-sep)))

(defun break-line-3 ()
  "Break the line first trying via opening delim, then via arg seps."
  (interactive)
  ;; keep trying to check for opening delim
  (while (break-line--check-line-and-search break-line-open-delim-regex)
    (break-line-opening-delimiter))

  ;; then keep trying to check for prev args
  (while (break-line--check-line-and-search break-line-arg-sep-regex)
    (break-line-arg-sep)))

(defvar break-line-functions
  '(#'break-line-1 #'break-line-2 #'break-line-3)
  "Contains various line breaking functions which can be called.
Calls to break-line-cycle will call the function at a given index.")

(defun break-line-cycle (func-index)
  "Break line using FUNC-INDEX indexed function in break-line-functions.
If FUNC-INDEX is not provided, choose the first option, otherwise
index according to the value of FUNC-INDEX."
  (interactive "P")
  (save-excursion
  (eval (cdr (nth (or func-index 0) break-line-functions)))))

(provide 'break-line)
;;; break-line.el ends here
