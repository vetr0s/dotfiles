;;; rc-programming.el --- Language support -*- lexical-binding: t; -*-

;;; Commentary:

;; Major modes and per-language settings. Formatting is apheleia's job in
;; rc-editing, so only what a language needs beyond its own package is here.
;;
;; Two languages take a file of their own. Odin is in rc-odin, since its major
;; mode is written rather than installed, and C and C++ are in rc-cc, along
;; with the CMake that builds them.
;;
;; Bindings that live in a mode's own keymap go behind with-eval-after-load,
;; since the map does not exist until the mode's package loads.

;;; Code:

(require 'treesit)

;;; Tags

;; What answers `M-.' now that no language server does. util/scripts/tags.sh
;; writes .tags at the project root in the etags format this reads. The
;; vi-format tags beside it is Neovim's: macOS filesystems are
;; case-insensitive, so the two cannot both be called TAGS.
(defun rc-programming-visit-tags-table ()
  "Point `M-.' at the project's own .tags, when it has one."
  (when-let* ((root (locate-dominating-file default-directory ".tags")))
    (setq-local tags-table-list (list (expand-file-name ".tags" root)))))

(add-hook 'prog-mode-hook #'rc-programming-visit-tags-table)

;; Rerunning the script rewrites the index under a live Emacs, and the prompt
;; asking whether to reread it has only one sensible answer.
(setopt tags-revert-without-query t)

;;; Python

;; Select Python 3 explicitly. Older Emacs versions may still try `python'.
(setopt python-shell-interpreter "python3")
(setopt python-interpreter "python3")

;; python.el registers its own commit-pinned grammar source when it loads, so
;; requiring it is what makes the grammar installable. Stating a source here
;; would only add a second, unpinned entry racing that one.
(defun rc-programming-install-python-grammar ()
  "Compile and install the Python tree-sitter grammar."
  (interactive)
  (require 'python)
  (treesit-install-language-grammar 'python))

;; python.el's autoloads only register the function name; nothing puts it in
;; `major-mode-remap-alist' until we do, per the mode's own docstring.
;;
;; Guarded on the grammar, so a fresh clone falls back to `python-mode' rather
;; than sitting in a python-ts-mode with no font lock.
(when (treesit-ready-p 'python t)
  (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))

;; uv puts the environment at .venv in the project root and does not export
;; anything, so nothing in a GUI Emacs would otherwise know it exists.
;; Keep the changes buffer-local. Two open projects must not replace each
;; other's interpreter or linter.
(defun rc-programming-activate-venv ()
  "Use the current project's .venv for this Python buffer."
  (let* ((root (locate-dominating-file default-directory ".venv"))
         (venv (and root (expand-file-name ".venv" root)))
         (bin (and venv (expand-file-name "bin" venv))))
    (setq-local process-environment (copy-sequence process-environment))
    (setq-local exec-path (copy-sequence exec-path))
    (when (and bin (file-directory-p bin))
      (setq-local exec-path (cons bin (delete bin exec-path)))
      (setenv "PATH" (concat bin path-separator (or (getenv "PATH") "")))
      (setenv "VIRTUAL_ENV" venv)
      (setq-local python-shell-virtualenv-path venv)
      (setq-local python-shell-virtualenv-root venv))
    (let ((linter (cond
                   ((executable-find "ruff")
                    '("ruff" "check" "--output-format=concise"
                      "--stdin-filename" "stdin" "-"))
                   ((executable-find "flake8")
                    '("flake8" "--stdin-display-name" "stdin" "-")))))
      (when linter
        (setq-local python-flymake-command linter)
        (flymake-mode 1)))))

(add-hook 'python-base-mode-hook #'rc-programming-activate-venv 90)

;; Linting runs without a language server. Ruff is preferred and Flake8 is the
;; fallback. The hook above resolves each command inside the buffer's .venv.
;; Both print `stdin:line:col: CODE message', which is already what
;; `python-flymake-command-output-pattern' expects, so only severities follow.
;; First match wins, and the empty pattern matches everything. Without that
;; last clause an unrecognised code defaults to :error, which would make every
;; rule a project turns on shout. Only a file that will not run is an error.
;;
;; ruff reports a parse failure as an uncoded "invalid-syntax:" rather than the
;; E999 flake8 uses, so both spellings are listed. It has to precede the note
;; rule: python.el matches these with `case-fold-search' left at t, so a bare
;; "^[IC]" also matches the i in "invalid-syntax" and files that do not parse
;; end up as notes. The digit anchors close that off as well.
(setopt python-flymake-msg-alist
        '(("^invalid-syntax" . :error)    ; ruff, a file that will not parse
          ("^E9" . :error)                ; flake8, the same
          ("^F82" . :error)               ; undefined name
          ("^[IC][0-9]" . :note)          ; import order, complexity
          ("" . :warning)))               ; style, and anything else opinionated

;; apheleia formats Python with black by default, which uv users do not have.
;; `ruff-isort' sorts imports and `ruff' is `ruff format', so the pair covers
;; what isort and black did.
(with-eval-after-load 'apheleia
  (setf (alist-get 'python-mode apheleia-mode-alist) '(ruff-isort ruff)
        (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff-isort ruff)))

;;; Markdown

;; markdown-mode claims .md and .markdown through its own autoloads. This only
;; redirects README.md, and lands ahead of that entry by being added later.
(add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode))

(with-eval-after-load 'markdown-mode
  (keymap-set markdown-mode-map "C-c C-e" #'markdown-do))

(provide 'rc-programming)
;;; rc-programming.el ends here
