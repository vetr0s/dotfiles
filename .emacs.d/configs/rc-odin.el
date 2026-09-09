;;; rc-odin.el --- Odin support -*- lexical-binding: t; -*-

;;; Commentary:

;; A tree-sitter major mode for Odin, written here rather than installed. The
;; two published options both fall short: odin-mode is a regex mode that never
;; matches procedure calls or field access, so a call-heavy buffer comes out
;; almost entirely unfontified, and odin-ts-mode ships no releases and warns in
;; its own README that it crashes.
;;
;; The grammar is tree-sitter-grammars/tree-sitter-odin, compiled into
;; ~/.emacs.d/tree-sitter by `rc-odin-install-grammar'. That directory is
;; gitignored, so a fresh machine runs the command once.
;;
;; The queries follow the grammar's own highlights.scm where they translate.
;; Two rules from it are left out on purpose. Its "a capitalised identifier is
;; a type" heuristic needs #not-has-parent?, which Emacs has no equivalent for,
;; and without the guard it repaints procedure names and parameters. Its ERROR
;; rule is dropped because this grammar mis-parses some valid Odin, and a red
;; buffer that blames the code for a grammar bug is worse than no rule at all.

;;; Code:

(require 'treesit)
(require 'c-ts-common)

;; Only for the compilation-error-regexp variables set at the end of the file.
(eval-when-compile (require 'compile))

(defgroup rc-odin nil
  "Odin language support."
  :group 'languages)

(defcustom rc-odin-indent-offset 4
  "Number of columns one Odin indentation level occupies."
  :type 'natnum
  :group 'rc-odin)

(add-to-list 'treesit-language-source-alist
             '(odin "https://github.com/tree-sitter-grammars/tree-sitter-odin"))

(defun rc-odin-install-grammar ()
  "Compile and install the Odin tree-sitter grammar."
  (interactive)
  (treesit-install-language-grammar 'odin))

;;; Word lists

;; Odin has no reserved word for these; they are procedures in package builtin
;; that every file gets without importing anything.
(defconst rc-odin--builtins
  '("abs" "align_of" "append" "append_elem" "append_elems" "append_string"
    "assert" "card" "cap" "clamp" "clear" "clear_dynamic_array" "clear_map"
    "complex" "conj" "copy" "delete" "delete_key" "excl" "excl_bit_set"
    "excl_elem" "excl_elems" "free" "free_all" "imag" "incl" "incl_bit_set"
    "incl_elem" "incl_elems" "jmag" "kmag" "len" "make" "max" "min" "new"
    "new_clone" "offset_of" "ordered_remove" "panic" "pop" "quaternion" "raw_data"
    "real" "reserve" "reserve_dynamic_array" "reserve_map" "resize"
    "resize_dynamic_array" "size_of" "soa_unzip" "soa_zip" "swizzle" "type_info_of"
    "type_of" "typeid_of" "unimplemented" "unordered_remove" "unreachable"))

(defconst rc-odin--type-builtins
  '("any" "b16" "b32" "b64" "b8" "bool" "byte" "complex128" "complex32"
    "complex64" "complex_double" "complex_float" "cstring" "double" "f16"
    "f16be" "f16le" "f32" "f32be" "f32le" "f64" "f64be" "f64le" "float" "i128"
    "i128be" "i128le" "i16" "i16be" "i16le" "i32" "i32be" "i32le" "i64" "i64be"
    "i64le" "i8" "int" "quaternion128" "quaternion256" "quaternion64" "rawptr"
    "rune" "string" "typeid" "u128" "u128be" "u128le" "u16" "u16be" "u16le"
    "u32" "u32be" "u32le" "u64" "u64be" "u64le" "u8" "uint" "uintptr"))

(defconst rc-odin--constant-rx "\\`_*[A-Z][A-Z0-9_]+\\'"
  "Identifiers in SCREAMING_SNAKE_CASE, which Odin uses for constants.
Two characters minimum, so a one-letter polymorphic type parameter is
left to the type rules instead of being claimed as a constant.")

;;; Font lock

;; The blanket (identifier) rule is the base coat and must stay first: every
;; later rule overrides it, so order in this list is what resolves conflicts.
(defvar rc-odin--font-lock-rules
  (treesit-font-lock-rules
   :language 'odin
   :feature 'variable
   :override t
   '((identifier) @font-lock-variable-use-face
     (parameter :anchor (identifier) @font-lock-variable-name-face)
     (default_parameter :anchor (identifier) @font-lock-variable-name-face)
     ((identifier) @font-lock-builtin-face
      (:match "\\`\\(?:context\\|self\\)\\'" @font-lock-builtin-face)))

   :language 'odin
   :feature 'property
   :override t
   '((member_expression "." (identifier) @font-lock-property-use-face)
     ;; No anchor: `x, y: f32' is one field node with two name children, and
     ;; the type is always wrapped in a type node, so it cannot match here.
     (field (identifier) @font-lock-property-name-face)
     (struct_field :anchor (identifier) @font-lock-property-name-face)
     (struct_type "{" (identifier) @font-lock-property-name-face)
     (field_identifier) @font-lock-property-name-face)

   :language 'odin
   :feature 'namespace
   :override t
   '((package_declaration (identifier) @font-lock-constant-face)
     (import_declaration alias: (identifier) @font-lock-constant-face)
     (using_statement (identifier) @font-lock-constant-face)
     (foreign_block (identifier) @font-lock-constant-face)
     (field_type :anchor (identifier) @font-lock-constant-face))

   :language 'odin
   :feature 'constant
   :override t
   `(((identifier) @font-lock-constant-face
      (:match ,rc-odin--constant-rx @font-lock-constant-face))
     ;; An implicit selector such as .Running, where the enum is inferred.
     (member_expression :anchor "." (identifier) @font-lock-constant-face)
     (enum_declaration "{" (identifier) @font-lock-constant-face)
     [(boolean) (nil) (uninitialized)] @font-lock-constant-face)

   :language 'odin
   :feature 'type
   :override t
   `((type (identifier) @font-lock-type-face)
     (type (field_type) @font-lock-type-face)
     (struct :anchor (identifier) @font-lock-type-face)
     (struct_declaration (identifier) @font-lock-type-face "::")
     (enum_declaration (identifier) @font-lock-type-face "::")
     (union_declaration (identifier) @font-lock-type-face "::")
     (bit_field_declaration (identifier) @font-lock-type-face "::")
     (const_declaration (identifier) @font-lock-type-face "::"
                        [(array_type) (bit_set_type) (distinct_type)
                         (map_type) (matrix_type) (pointer_type)
                         (procedure_type) (slice_expression)])
     (bit_set_type (identifier) @font-lock-type-face ";")
     (polymorphic_parameters (identifier) @font-lock-type-face)
     (named_type (identifier) @font-lock-type-face)
     (field_type "." (identifier) @font-lock-type-face)
     ((type (identifier) @font-lock-builtin-face)
      (:match ,(rx-to-string `(seq bos (or ,@rc-odin--type-builtins) eos))
              @font-lock-builtin-face)))

   :language 'odin
   :feature 'function
   :override t
   '((procedure_declaration (identifier) @font-lock-function-name-face)
     (overloaded_procedure_declaration (identifier) @font-lock-function-name-face)
     (call_expression function: (identifier) @font-lock-function-call-face))

   :language 'odin
   :feature 'builtin
   :override t
   `(((call_expression function: (identifier) @font-lock-builtin-face)
      (:match ,(rx-to-string `(seq bos (or ,@rc-odin--builtins) eos))
              @font-lock-builtin-face)))

   :language 'odin
   :feature 'number
   :override t
   '([(number) (float)] @font-lock-number-face
     (character) @font-lock-constant-face)

   :language 'odin
   :feature 'string
   :override t
   '((string) @font-lock-string-face)

   :language 'odin
   :feature 'escape-sequence
   :override t
   '((escape_sequence) @font-lock-escape-face)

   :language 'odin
   :feature 'keyword
   :override t
   '(["auto_cast" "bit_field" "bit_set" "break" "case" "cast" "continue"
      "defer" "distinct" "do" "dynamic" "else" "enum" "for" "foreign" "if"
      "import" "in" "map" "matrix" "not_in" "or_break" "or_continue" "or_else"
      "or_return" "package" "proc" "return" "struct" "switch" "transmute"
      "union" "using" "when" "where"]
     @font-lock-keyword-face
     (fallthrough_statement) @font-lock-keyword-face)

   :language 'odin
   :feature 'preprocessor
   :override t
   '([(build_tag) (calling_convention) (tag)] @font-lock-preprocessor-face)

   :language 'odin
   :feature 'attribute
   :override t
   '((attribute (identifier) @font-lock-preprocessor-face))

   :language 'odin
   :feature 'label
   :override t
   '((label_statement (identifier) @font-lock-constant-face ":"))

   :language 'odin
   :feature 'comment
   :override t
   '([(block_comment) (comment)] @font-lock-comment-face)

   :language 'odin
   :feature 'operator
   :override t
   '(["!" "!=" "%" "%%" "%=" "&" "&&" "&&=" "&=" "&~" "&~=" "*" "*=" "+" "+="
      "-" "-=" "/" "/=" "<" "<<" "<<=" "<=" "=" "==" ">" ">=" ">>" ">>=" ":="
      "?" "^" "^=" "|" "|=" "||" "||=" "~" "~=" ".." "..<" "..=" "..."]
     @font-lock-operator-face)

   :language 'odin
   :feature 'bracket
   :override t
   '(["(" ")" "[" "]" "{" "}"] @font-lock-bracket-face)

   :language 'odin
   :feature 'delimiter
   :override t
   '(["," ":" "::" ";" "." "->"] @font-lock-delimiter-face
     ["$" "@"] @font-lock-misc-punctuation-face)))

(defvar rc-odin--font-lock-feature-list
  '((comment)
    (keyword string type)
    (attribute builtin constant escape-sequence function label namespace
               number preprocessor property)
    (bracket delimiter operator variable)))

;;; Indentation

(defconst rc-odin--comment-rx
  (rx bos (or "block_comment" "comment") eos))

(defvar rc-odin--indent-rules
  `((odin
     ((parent-is "source_file") column-0 0)
     ((node-is "}") standalone-parent 0)
     ((node-is ")") standalone-parent 0)
     ((node-is "]") standalone-parent 0)
     ((node-is "else_clause") parent-bol 0)
     ((node-is "else_if_clause") parent-bol 0)
     ((node-is "else_when_clause") parent-bol 0)
     ((node-is "switch_case") parent-bol 0)
     ;; A continuation line inside /* */ has no node, so the parent is the
     ;; comment. Hand-aligned lines stay put; prev-adaptive-prefix flattens them.
     ((and (parent-is ,rc-odin--comment-rx) c-ts-common-looking-at-star)
      c-ts-common-comment-start-after-first-star -1)
     ((parent-is ,rc-odin--comment-rx) no-indent 0)
     ((parent-is ,(rx bos (or "bit_field_declaration" "block" "call_expression"
                              "enum_declaration" "parameters" "struct"
                              "struct_declaration" "struct_type" "switch_case"
                              "switch_statement" "tuple_type" "union_declaration"
                              "union_type")
                      eos))
      standalone-parent rc-odin-indent-offset)
     (catch-all parent-bol 0))))

;;; Mode

;; Font lock comes from tree-sitter, but movement, electric pairs, filling and
;; anything else that calls `syntax-ppss' still reads this.
(defvar rc-odin--syntax-table
  (let ((table (make-syntax-table)))
    ;; Comments, C style. The n on * is what makes /* */ nest, as Odin's do.
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23n" table)
    (modify-syntax-entry ?\n "> b" table)
    ;; Runes are single quoted and raw strings are backquoted.
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?' "\"" table)
    (modify-syntax-entry ?` "\"" table)
    (modify-syntax-entry ?\\ "\\" table)
    ;; Directives, attributes and polymorphic parameters read as one symbol.
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?# "_" table)
    (modify-syntax-entry ?@ "_" table)
    (modify-syntax-entry ?$ "_" table)
    (dolist (c '(?+ ?- ?% ?& ?| ?^ ?! ?= ?< ?> ?? ?~ ?:))
      (modify-syntax-entry c "." table))
    table))

(defvar rc-odin--imenu-settings
  '(("Procedure" "\\`\\(?:overloaded_\\)?procedure_declaration\\'" nil nil)
    ("Struct" "\\`struct_declaration\\'" nil nil)
    ("Enum" "\\`enum_declaration\\'" nil nil)
    ("Union" "\\`union_declaration\\'" nil nil)
    ("Bit field" "\\`bit_field_declaration\\'" nil nil)))

;; The grammar gives declarations no name field, and an attributed procedure
;; leads with its attributes, so take the first identifier rather than child 0.
(defun rc-odin--defun-name (node)
  "Return the name declared by NODE, or nil if it has none."
  (when-let* ((id (car (treesit-filter-child
                        node
                        (lambda (child)
                          (equal (treesit-node-type child) "identifier"))
                        t))))
    (treesit-node-text id t)))

;;;###autoload
(define-derived-mode odin-ts-mode prog-mode "Odin"
  "Major mode for Odin, backed by tree-sitter."
  :group 'rc-odin
  :syntax-table rc-odin--syntax-table
  (unless (treesit-ready-p 'odin t)
    (error "No Odin tree-sitter grammar; run M-x rc-odin-install-grammar"))

  (treesit-parser-create 'odin)

  (setq-local treesit-font-lock-settings rc-odin--font-lock-rules)
  (setq-local treesit-font-lock-feature-list rc-odin--font-lock-feature-list)
  (setq-local treesit-simple-indent-rules rc-odin--indent-rules)
  (setq-local treesit-simple-imenu-settings rc-odin--imenu-settings)
  (setq-local treesit-defun-type-regexp
              (rx bos (or "procedure_declaration"
                          "overloaded_procedure_declaration"
                          "struct_declaration" "enum_declaration"
                          "union_declaration" "bit_field_declaration")
                  eos))
  (setq-local treesit-defun-name-function #'rc-odin--defun-name)

  ;; Tabs, against the global default: the core library and odinfmt both use
  ;; them. tab-width has to match the offset or a level indents to a tab plus
  ;; padding spaces rather than to one tab.
  (setq-local indent-tabs-mode t)
  (setq-local tab-width rc-odin-indent-offset)

  ;; Odin's comments are C's, down to /* */ nesting, so this sets comment-start
  ;; and the fill and paragraph machinery correctly on its own.
  (c-ts-common-comment-setup)

  (setq-local electric-indent-chars
              (append "{}():;," electric-indent-chars))

  (treesit-major-mode-setup))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.odin\\'" . odin-ts-mode))

;;; Building

(defcustom rc-odin-build-flags "-vet -strict-style -debug"
  "Flags appended to every `odin' subcommand this file runs."
  :type 'string
  :group 'rc-odin)

(defcustom rc-odin-package-directory "src"
  "Directory, relative to the project root, holding the main package.
Used only when it exists and holds Odin source."
  :type 'string
  :group 'rc-odin)

(defconst rc-odin--root-markers '(".git" "ols.json" "odinfmt.json")
  "Files and directories that identify an Odin project root.")

(defun rc-odin--root ()
  "Return the root of the project owning the current buffer, or nil."
  (when-let* ((root
               (locate-dominating-file
                default-directory
                (lambda (directory)
                  (catch 'found
                    (dolist (marker rc-odin--root-markers)
                      (when (file-exists-p (expand-file-name marker directory))
                        (throw 'found t))))))))
    (expand-file-name root)))

(defun rc-odin--package-p (dir)
  "Return DIR when it directly holds Odin source, and nil otherwise."
  (and (file-directory-p dir)
       (directory-files dir nil "\\.odin\\'" t 1)
       dir))

;; A package in Odin is a directory holding .odin files, so a root that holds
;; only subdirectories is not one. `default-directory' always is, which is what
;; makes the fallback safe.
(defun rc-odin--package (root)
  "Return the package directory `odin' should be pointed at under ROOT."
  (or (rc-odin--package-p (expand-file-name rc-odin-package-directory root))
      (rc-odin--package-p root)
      default-directory))

(defun rc-odin--command (subcommand)
  "Return the shell command running odin SUBCOMMAND on this buffer's project."
  (let* ((root (or (rc-odin--root) default-directory))
         (package (rc-odin--package root)))
    (format "cd %s && odin %s %s %s"
            (shell-quote-argument root)
            subcommand
            (shell-quote-argument (file-relative-name package root))
            rc-odin-build-flags)))

;; No build command: `C-c b' is `compile' globally, and the compile-command set
;; below already builds. These three are the subcommands it cannot reach.
(defun rc-odin-run ()
  "Build and run this buffer's Odin package."
  (interactive)
  (compile (rc-odin--command "run")))

(defun rc-odin-check ()
  "Type check this buffer's Odin package without producing a binary."
  (interactive)
  (compile (rc-odin--command "check")))

(defun rc-odin-test ()
  "Run the tests in this buffer's Odin package."
  (interactive)
  (compile (rc-odin--command "test")))

;; A Makefile wins over a constructed command line: it already carries the
;; flags and the -out: path that a bare `odin build' would have to invent.
(defun rc-odin-set-compile-command ()
  "Point `compile' at this buffer's Odin project."
  ;; A loose file outside any project is still a package, so the root is not
  ;; required; a package in Odin is a directory and there is always one.
  (let ((root (or (rc-odin--root) default-directory)))
    (setq-local compile-command
                (if (file-exists-p (expand-file-name "Makefile" root))
                    (format "make -C %s" (shell-quote-argument root))
                  (rc-odin--command "build")))))

(add-hook 'odin-ts-mode-hook #'rc-odin-set-compile-command)

;; Odin reports errors as path(line:column) Error:, which no entry in the
;; default alist matches. The level is optional in the pattern so that a
;; message shape this does not anticipate still yields a jumpable location.
(with-eval-after-load 'compile
  (add-to-list 'compilation-error-regexp-alist-alist
               '(odin "^\\(.+?\\)(\\([0-9]+\\):\\([0-9]+\\))\\(?: \\(Warning\\)\\)?"
                      1 2 3 (4)))
  (add-to-list 'compilation-error-regexp-alist 'odin))

;;; Formatting

;; odinfmt is built from the ols tree and reads the odinfmt.json the project
;; root holds, so both editors format identically. -stdin is the shape apheleia
;; wants: source in, source out, leaving point and the markers alone.
(with-eval-after-load 'apheleia
  (setf (alist-get 'odinfmt apheleia-formatters) '("odinfmt" "-stdin")
        (alist-get 'odin-ts-mode apheleia-mode-alist) 'odinfmt))

;;; Keymap

(keymap-set odin-ts-mode-map "C-c C-r" #'rc-odin-run)
(keymap-set odin-ts-mode-map "C-c C-k" #'rc-odin-check)
(keymap-set odin-ts-mode-map "C-c C-t" #'rc-odin-test)

(provide 'rc-odin)
;;; rc-odin.el ends here
