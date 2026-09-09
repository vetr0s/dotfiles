;;; rc-cc.el --- C and C++ support -*- lexical-binding: t; -*-

;;; Commentary:

;; Tree-sitter modes, clang-format-driven indentation, and CMake. There is no
;; language server: navigation is xref and tags, and diagnostics come from
;; `compile'.
;;
;; The target is a CMake project. `rc-cc-cmake-configure' configures the build
;; tree and `compile' builds it.
;;
;; CMake lives here rather than in rc-programming because in this setup it
;; exists to build C++, and splitting the build system from the language it
;; builds only means reading two files to answer one question.
;;
;; Formatting is deliberately absent: apheleia runs clang-format from
;; `prog-mode-hook' in rc-editing, which already resolves a project's own
;; .clang-format.
;;
;;; Code:

(require 'treesit)
(require 'subr-x)

;; Loaded by the hooks below rather than at startup: `project-current' is
;; autoloaded and pulls in the rest of project.el on first use.
(declare-function project-current "project")
(declare-function project-root "project")

(defgroup rc-cc nil
  "C and C++ support."
  :group 'languages)

;;; Tree-sitter

;; The modes register their own pinned grammar sources when they load, so
;; requiring them is what makes these installable and why no source is
;; repeated here.
(defun rc-cc-install-grammars ()
  "Compile and install the C, C++, Doxygen and CMake tree-sitter grammars."
  (interactive)
  (require 'c-ts-mode)
  (require 'cmake-ts-mode)
  (dolist (lang '(c cpp doxygen cmake))
    (treesit-install-language-grammar lang)))

;; c-ts-mode's autoloads only register the function names; nothing puts them
;; in `major-mode-remap-alist' until we do, per the mode's own docstring.
;;
;; Guarded on both grammars: without them a fresh clone is better off in
;; cc-mode, with font lock and indentation, until `rc-cc-install-grammars'
;; has run.
(when (and (treesit-ready-p 'c t) (treesit-ready-p 'cpp t))
  (dolist (entry '((c-mode . c-ts-mode)
                    (c++-mode . c++-ts-mode)
                    (c-or-c++-mode . c-or-c++-ts-mode)))
    (add-to-list 'major-mode-remap-alist entry)))

;; Fontifies @param and @return inside /** */, and is off by default.
(setopt c-ts-mode-enable-doxygen (treesit-ready-p 'doxygen t))

;;; Indentation

;; Only reached on a machine with no clang-format: where there is one,
;; `rc-cc-follow-clang-format' below resolves the real style per file and
;; overrides all three of these. Set to mirror ~/.clang-format, which is Allman
;; at four columns with no tabs, so the fallback is not a surprise.
(setopt c-ts-mode-indent-style 'bsd)
(setopt c-ts-indent-offset 4)

(defun rc-cc-set-cc-mode-style ()
  "Set the Allman style and a four column offset for the current C buffer.
The cc-mode half of the defaults above, which cc-mode does not read."
  (c-set-style "bsd")
  (setq c-basic-offset 4
        indent-tabs-mode nil))

;; cc-mode's own hooks, not `c-mode-common-hook', which also fires for
;; java-mode and awk-mode, where a C style and a CMake build do not belong.
(defconst rc-cc--hooks
  '(c-mode-hook c++-mode-hook objc-mode-hook c-ts-base-mode-hook)
  "Every mode hook this file configures, cc-mode's and tree-sitter's alike.")

(dolist (hook '(c-mode-hook c++-mode-hook objc-mode-hook))
  (add-hook hook #'rc-cc-set-cc-mode-style))

;; A project with its own .clang-format is reformatted to that file's rules on
;; every save, so typing to a different width means each save moves the line
;; that was just written. clang-format resolves the whole cascade, BasedOnStyle
;; and nested directories included, so ask it rather than parsing the YAML.
(defun rc-cc--dump-config (file)
  "Return clang-format's resolved configuration for FILE, or nil."
  (when (executable-find "clang-format")
    (with-temp-buffer
      (and (eq 0 (call-process "clang-format" nil t nil "--dump-config"
                               (concat "-assume-filename=" file)))
           (buffer-string)))))

(defun rc-cc--config-value (config key)
  "Return the value KEY takes in CONFIG, or nil if it is absent."
  (and (string-match (format "^%s: +\\(.+?\\) *$" (regexp-quote key)) config)
       (match-string 1 config)))

;; Only inside a function body does this land where clang-format does. Every
;; c-ts-mode style cascades the indent of a brace that opens a namespace or a
;; class on its own line, so those two come out wrong whatever is chosen here.
(defun rc-cc--brace-style (breaking)
  "Return the c-ts-mode indent style matching a BreakBeforeBraces of BREAKING."
  (pcase breaking
    ("Allman" 'bsd)
    ("GNU" 'gnu)
    ;; No Whitesmiths or Stroustrup here, and the attaching styles all land on
    ;; K&R anyway.
    (_ 'k&r)))

(defun rc-cc--config-for (file)
  "Return clang-format's current resolved configuration for FILE."
  (or (rc-cc--dump-config file) ""))

(defun rc-cc-follow-clang-format ()
  "Indent this buffer the way clang-format will reformat it on save."
  (when buffer-file-name
    (let ((config (rc-cc--config-for buffer-file-name)))
      (when-let* ((width (rc-cc--config-value config "IndentWidth")))
        (setq-local c-ts-indent-offset (string-to-number width))
        (setq-local c-basic-offset (string-to-number width)))
      (when-let* ((tabs (rc-cc--config-value config "UseTab")))
        (setq-local indent-tabs-mode (not (equal tabs "Never"))))
      (when-let* (((derived-mode-p 'c-ts-mode 'c++-ts-mode))
                  (braces (rc-cc--config-value config "BreakBeforeBraces")))
        ;; Buffer-local, and rebuilds the indent rules from the new style.
        (c-ts-mode-set-style (rc-cc--brace-style braces))))))

(dolist (hook rc-cc--hooks)
  ;; Depth, so the defaults above are in place before this overrides them.
  (add-hook hook #'rc-cc-follow-clang-format 90))

;;; Preprocessor indentation

;; tree-sitter-c parses the whole body of a multi-line macro as one opaque
;; preproc_arg token, so c-ts-mode indents it with `no-indent': existing lines
;; keep whatever column they had, and a newly typed one lands a single level in
;; however deep it actually sits. clang-format then moves it on save.
;;
;; The tree is no help here, but the syntax table is. `parse-partial-sexp'
;; counts unclosed braces and parens between the directive and this line while
;; skipping strings and comments, which is the nesting depth clang-format
;; indents to. The body sits one level inside the directive, hence the 1+.

(defun rc-cc--macro-start ()
  "Return the start of the directive this line continues, or nil.
Nil on the directive's own first line, which needs no help."
  (save-excursion
    (beginning-of-line)
    (let ((here (point))
          (start (point)))
      (while (and (> (point) (point-min))
                  (save-excursion
                    (forward-line -1)
                    (looking-at ".*\\\\[ \t]*$")))
        (forward-line -1)
        (setq start (point)))
      (and (/= start here)
           (save-excursion (goto-char start) (looking-at "[ \t]*#"))
           start))))

(defun rc-cc--macro-anchor (&rest _)
  "Anchor a macro body line to the column of its directive."
  (rc-cc--macro-start))

(defun rc-cc--macro-offset (&rest _)
  "Return the column a macro body line sits at, relative to its directive."
  (let* ((start (rc-cc--macro-start))
         (here (line-beginning-position))
         (depth (car (parse-partial-sexp start here)))
         (closer (save-excursion
                   (goto-char here)
                   (skip-chars-forward " \t")
                   (looking-at "[])}]"))))
    (* (max 0 (+ 1 depth (if closer -1 0))) c-ts-indent-offset)))

;; Matching on the node type is not precise enough: inside an include guard
;; every line has a preproc ancestor, and a rule keyed on that indents the whole
;; header one level in. The backslash is the thing that actually marks a body.
(defun rc-cc--in-macro-body-p (&rest _)
  "Match a line continuing a multi-line preprocessor directive."
  (and (rc-cc--macro-start) t))

(defconst rc-cc--macro-indent-rule
  '(rc-cc--in-macro-body-p rc-cc--macro-anchor rc-cc--macro-offset)
  "Indent rule placed ahead of the `no-indent' one c-ts-mode uses.")

;; c-ts-mode sends a top-level form under a directive to column 0 with the rule
;; (n-p-gp nil "preproc" "translation_unit"), which only reaches one level deep.
;; A header with an include guard around an #ifdef nests two, so everything in
;; the inner block was picking up an indent level clang-format does not add.
(defun rc-cc--top-level-in-preproc-p (_node parent &rest _)
  "Match a node whose ancestors are all preprocessor conditionals."
  (and parent
       (string-prefix-p "preproc" (treesit-node-type parent))
       (let ((node parent))
         (while (and node (string-prefix-p "preproc" (treesit-node-type node)))
           (setq node (treesit-node-parent node)))
         (equal (treesit-node-type node) "translation_unit"))))

(defconst rc-cc--preproc-indent-rule
  '(rc-cc--top-level-in-preproc-p column-0 0)
  "Indent rule for a form nested more than one directive deep.")

(defun rc-cc-indent-preprocessor ()
  "Add the preprocessor indent rules to this buffer, ahead of c-ts-mode's."
  (when-let* (((derived-mode-p 'c-ts-mode 'c++-ts-mode))
              (lang (if (derived-mode-p 'c++-ts-mode) 'cpp 'c)))
    (setq treesit-simple-indent-rules
          (cons (cons lang (append (list rc-cc--macro-indent-rule
                                         rc-cc--preproc-indent-rule)
                                   (alist-get lang treesit-simple-indent-rules)))
                (assq-delete-all lang treesit-simple-indent-rules)))))

;; Depth, so this lands after `rc-cc-follow-clang-format' has rebuilt the rules
;; through `c-ts-mode-set-style', which would otherwise drop this one.
(dolist (hook rc-cc--hooks)
  (add-hook hook #'rc-cc-indent-preprocessor 91))

;;; Indenting a region

;; Per-line indentation stays with tree-sitter: it survives the half-written
;; buffer that typing produces, where clang-format has no braces to balance and
;; guesses badly. Over a region the buffer is usually whole, and there
;; clang-format is exact by construction, which the indent rules are not: C
;; matches it closely, but a C++ namespace or class body under Allman braces
;; drifts, and closing that with rules means a special case per declaration
;; form.
;;
;; Only the leading whitespace of clang-format's answer is used. It would also
;; rewrap to ColumnLimit and append a comment to a namespace's closing brace,
;; and neither belongs in something bound to TAB.

;; clang-format has no indent-only mode, and left to itself it would also
;; rewrap to ColumnLimit. That changes how many lines come back, which would
;; put every column after the first rewrap on the wrong line. Dumping the
;; resolved style with the limit lifted keeps the line breaks exactly as they
;; are and leaves indentation the only thing that moves.
(defun rc-cc--indent-only-style (file)
  "Return FILE's resolved style with line wrapping disabled."
  (let ((config (rc-cc--config-for file)))
    (unless (string-empty-p config)
      (setq config
            (replace-regexp-in-string
             "^\\(?:---\\|\\.\\.\\.\\) *\n" "" config))
      (replace-regexp-in-string "^ColumnLimit: .*$" "ColumnLimit: 0" config))))

(defun rc-cc--line-indent ()
  "Return the leading whitespace of the current line, verbatim."
  (buffer-substring-no-properties
   (line-beginning-position)
   (save-excursion (back-to-indentation) (point))))

(defun rc-cc--clang-format-indents (first last)
  "Return the leading whitespace clang-format gives lines FIRST to LAST.
Nil when clang-format fails, or when it returned a different number of
lines, which would put these on the wrong ones. The whitespace is taken
verbatim rather than as a column, so tabs land exactly where clang-format
put them instead of being re-derived from `indent-tabs-mode'."
  (when-let* ((style (rc-cc--indent-only-style
                      (or buffer-file-name default-directory)))
              (source (buffer-string))
              (name (or buffer-file-name (buffer-name)))
              (lines (line-number-at-pos (point-max))))
    (let ((style-file (make-temp-file "rc-cc-style" nil ".yaml")))
      (unwind-protect
          (progn
            (write-region style nil style-file nil :silent)
            (with-temp-buffer
              (insert source)
              (when (and (eq 0 (call-process-region
                                (point-min) (point-max) "clang-format" t t nil
                                (format "--lines=%d:%d" first last)
                                (concat "--style=file:" style-file)
                                (concat "-assume-filename=" name)))
                         (= lines (line-number-at-pos (point-max))))
                (goto-char (point-min))
                (forward-line (1- first))
                (let ((indents nil))
                  (dotimes (_ (1+ (- last first)))
                    (push (rc-cc--line-indent) indents)
                    (forward-line 1))
                  (nreverse indents)))))
        (delete-file style-file)))))

(defun rc-cc-indent-region (beg end)
  "Indent BEG to END to the columns clang-format would use.
Falls back to the mode\='s own indentation when clang-format cannot say."
  (let* ((first (line-number-at-pos beg))
         (last (line-number-at-pos (if (and (> end beg) (eq (char-before end) ?\n))
                                       (1- end)
                                     end)))
         (indents (rc-cc--clang-format-indents first last)))
    (if (not indents)
        (treesit-indent-region beg end)
      (save-excursion
        (goto-char beg)
        (forward-line 0)
        (dolist (indent indents)
          ;; Leaves a line that is already right untouched, so this does not
          ;; churn the undo history or move markers on it.
          (unless (equal indent (rc-cc--line-indent))
            (delete-region (line-beginning-position)
                           (save-excursion (back-to-indentation) (point)))
            (insert indent))
          (forward-line 1))))))

(defun rc-cc-use-clang-format-for-regions ()
  "Indent regions in this buffer through clang-format."
  (when (and (executable-find "clang-format")
             (derived-mode-p 'c-ts-mode 'c++-ts-mode))
    (setq-local indent-region-function #'rc-cc-indent-region)))

(dolist (hook rc-cc--hooks)
  (add-hook hook #'rc-cc-use-clang-format-for-regions 92))

;;; CMake

(defcustom rc-cc-cmake-build-directory "build"
  "Directory, relative to the project root, holding the CMake build tree."
  :type 'string
  :group 'rc-cc)

(defun rc-cc--cmake-root ()
  "Return the project root, if it holds a CMakeLists.txt."
  (when-let* ((project (project-current))
              (root (project-root project)))
    (and (file-exists-p (expand-file-name "CMakeLists.txt" root)) root)))

(defun rc-cc-cmake-configure ()
  "Configure the CMake build tree so that it exports a compilation database."
  (interactive)
  (let* ((root (or (rc-cc--cmake-root)
                   (user-error "No CMakeLists.txt at the project root")))
         (default-directory root))
    (compile (format "cmake -S . -B %s -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
                     (shell-quote-argument rc-cc-cmake-build-directory)))))

;; Absolute, so `compile' builds the project from whichever directory the
;; buffer happens to sit in.
(defun rc-cc-set-compile-command ()
  "Point `compile' at the CMake build tree, when the project has one."
  (when-let* ((root (rc-cc--cmake-root)))
    (setq-local compile-command
                (format "cmake --build %s"
                        (shell-quote-argument
                         (expand-file-name rc-cc-cmake-build-directory root))))))

(dolist (hook rc-cc--hooks)
  (add-hook hook #'rc-cc-set-compile-command))

;;; Source and header

(with-eval-after-load 'cc-mode
  (keymap-set c-mode-base-map "C-c o" #'ff-find-other-file))

(with-eval-after-load 'c-ts-mode
  (keymap-set c-ts-base-mode-map "C-c o" #'ff-find-other-file))

(provide 'rc-cc)
;;; rc-cc.el ends here
