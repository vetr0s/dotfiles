;;; editor-tests.el --- Editor regression tests -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'python)
(require 'rc-cc)
(require 'rc-odin)
(require 'rc-programming)

(load (expand-file-name ".emacs.d/pre-init.el" default-directory)
      nil :nomessage)

(defvar rc-emacs-state-directory temporary-file-directory)

(defun rc-test--write-file (path contents)
  (make-directory (file-name-directory path) t)
  (write-region contents nil path nil :silent))

(ert-deftest rc-defaults-imports-wayland-shell-environment ()
  (let ((window-system 'pgtk)
        (imported nil))
    (cl-letf (((symbol-function 'daemonp) (lambda () nil))
              ((symbol-function 'exec-path-from-shell-initialize)
               (lambda () (setq imported t))))
      (load "rc-defaults" nil :nomessage)
      (should imported))))

(defun rc-test--straight-lock ()
  "Read the tracked Straight lockfile and return its repository entries."
  (with-temp-buffer
    (insert-file-contents
     (expand-file-name ".emacs.d/straight-lock.el" default-directory))
    (read (current-buffer))))

(ert-deftest rc-straight-lock-pins-every-repository ()
  (let ((lock (rc-test--straight-lock))
        (seen nil))
    (should (> (length lock) 40))
    (dolist (entry lock)
      (should (and (consp entry)
                   (stringp (car entry))
                   (string-match-p "\\`[0-9a-f]\\{40\\}\\'" (cdr entry))))
      (should-not (member (car entry) seen))
      (push (car entry) seen))))

(ert-deftest rc-straight-lock-pins-bootstrap ()
  (should (cdr (assoc "straight.el" (rc-test--straight-lock)))))

(ert-deftest rc-straight-loader-requires-bootstrap-state ()
  (require 'rc-packages)
  (let ((rc-straight-bootstrap-file
         (make-temp-name (expand-file-name "missing-straight-" temporary-file-directory)))
        (rc-straight-lock-file
         (expand-file-name ".emacs.d/straight-lock.el" default-directory)))
    (should-error (rc-straight-load-packages)
                  :type 'error)))

(ert-deftest rc-programming-allows-python-without-a-venv ()
  (let ((root (make-temp-file "rc-python-no-venv" t)))
    (unwind-protect
        (with-temp-buffer
          (setq default-directory (file-name-as-directory root))
          (rc-programming-activate-venv)
          (should (local-variable-p 'process-environment))
          (should (local-variable-p 'exec-path)))
      (delete-directory root t))))

(ert-deftest rc-programming-keeps-venvs-buffer-local ()
  (let ((root-a (make-temp-file "rc-python-a" t))
        (root-b (make-temp-file "rc-python-b" t))
        (buffer-a (generate-new-buffer " rc-python-a"))
        (buffer-b (generate-new-buffer " rc-python-b"))
        (base-environment process-environment)
        (base-exec-path exec-path)
        (old-command (default-value 'python-flymake-command)))
    (unwind-protect
        (progn
          (dolist (root (list root-a root-b))
            (let ((ruff (expand-file-name ".venv/bin/ruff" root)))
              (rc-test--write-file ruff "#!/bin/sh\nexit 0\n")
              (set-file-modes ruff #o755)))
          (setq-default python-flymake-command '("flake8" "-"))
          (with-current-buffer buffer-a
            (setq default-directory (file-name-as-directory root-a))
            (run-hooks 'python-base-mode-hook)
            (should (local-variable-p 'process-environment))
            (should (local-variable-p 'exec-path))
            (should (local-variable-p 'python-flymake-command))
            (should (equal (car python-flymake-command) "ruff")))
          (with-current-buffer buffer-b
            (setq default-directory (file-name-as-directory root-b))
            (run-hooks 'python-base-mode-hook)
            (should (equal (getenv "VIRTUAL_ENV")
                           (expand-file-name ".venv" root-b))))
          (with-current-buffer buffer-a
            (should (equal (getenv "VIRTUAL_ENV")
                           (expand-file-name ".venv" root-a)))
            (should (string-prefix-p
                     (expand-file-name ".venv/bin" root-a)
                     (getenv "PATH"))))
          (should (eq process-environment base-environment))
          (should (eq exec-path base-exec-path)))
      (setq-default python-flymake-command old-command)
      (kill-buffer buffer-a)
      (kill-buffer buffer-b)
      (delete-directory root-a t)
      (delete-directory root-b t))))

(ert-deftest rc-programming-clears-a-previous-project-venv ()
  (let ((root-a (make-temp-file "rc-python-transition-a" t))
        (root-b (make-temp-file "rc-python-transition-b" t))
        (exec-path nil)
        (process-environment '("PATH=")))
    (unwind-protect
        (with-temp-buffer
          (make-directory (expand-file-name ".venv/bin" root-a) t)
          (let ((ruff (expand-file-name ".venv/bin/ruff" root-a)))
            (rc-test--write-file ruff "#!/bin/sh\nexit 0\n")
            (set-file-modes ruff #o755))
          (setq default-directory (file-name-as-directory root-a))
          (rc-programming-activate-venv)
          (should (equal (getenv "VIRTUAL_ENV")
                         (expand-file-name ".venv" root-a)))
          (should (equal (car python-flymake-command) "ruff"))
          (setq default-directory (file-name-as-directory root-b))
          (rc-programming-activate-venv)
          (should-not (getenv "VIRTUAL_ENV"))
          (should-not (member (expand-file-name ".venv/bin" root-a) exec-path))
          (should-not python-shell-virtualenv-path)
          (should-not python-shell-virtualenv-root)
          (should-not (local-variable-p 'python-flymake-command)))
      (delete-directory root-a t)
      (delete-directory root-b t))))

(ert-deftest rc-programming-falls-back-to-global-linter ()
  (let* ((root (make-temp-file "rc-python-global" t))
         (bin (expand-file-name "bin" root))
         (exec-path (list bin))
         (process-environment (list (concat "PATH=" bin))))
    (unwind-protect
        (with-temp-buffer
          (dolist (tool '("bin/flake8" ".venv/bin/ruff"))
            (let ((path (expand-file-name tool root)))
              (rc-test--write-file path "#!/bin/sh\nexit 0\n")
              (set-file-modes path #o755)))
          (setq default-directory (file-name-as-directory root))
          (rc-programming-activate-venv)
          (should (equal (car python-flymake-command) "ruff"))
          (setq default-directory temporary-file-directory)
          (rc-programming-activate-venv)
          (should-not (getenv "VIRTUAL_ENV"))
          (should (equal exec-path (list bin)))
          (should (equal (car python-flymake-command) "flake8")))
      (delete-directory root t))))

(ert-deftest rc-cc-keeps-language-specific-styles-separate ()
  (skip-unless (executable-find "clang-format"))
  (let* ((root (make-temp-file "rc-cc-languages" t))
         (style (expand-file-name ".clang-format" root))
         (c-file (expand-file-name "probe.c" root))
         (cpp-file (expand-file-name "probe.cpp" root)))
    (unwind-protect
        (progn
          (rc-test--write-file
           style
           "---\nLanguage: Cpp\nIndentWidth: 2\n---\nLanguage: C\nIndentWidth: 7\n")
          (should (equal (rc-cc--config-value
                          (rc-cc--config-for c-file) "IndentWidth")
                         "7"))
          (should (equal (rc-cc--config-value
                          (rc-cc--config-for cpp-file) "IndentWidth")
                         "2")))
      (delete-directory root t))))

(ert-deftest rc-cc-reloads-style-for-region-indentation ()
  (skip-unless (executable-find "clang-format"))
  (let* ((root (make-temp-file "rc-cc-reload" t))
         (style (expand-file-name ".clang-format" root))
         (source (expand-file-name "probe.c" root)))
    (unwind-protect
        (with-temp-buffer
          (setq buffer-file-name source)
          (insert "int main(void) {\nif (1) {\nreturn 0;\n}\n}\n")
          (rc-test--write-file style "BasedOnStyle: LLVM\nIndentWidth: 2\n")
          (let ((first (rc-cc--clang-format-indents 1 5)))
            (rc-test--write-file style "BasedOnStyle: LLVM\nIndentWidth: 6\n")
            (set-file-times style (time-add (current-time) 2))
            (let ((second (rc-cc--clang-format-indents 1 5)))
              (should-not (equal first second)))))
      (delete-directory root t))))

(ert-deftest rc-odin-uses-nearest-root-marker ()
  (let* ((root (make-temp-file "rc-odin-root" t))
         (nested (expand-file-name "nested/package" root))
         (default-directory (file-name-as-directory nested)))
    (unwind-protect
        (progn
          (make-directory (expand-file-name ".git" root))
          (rc-test--write-file (expand-file-name "odinfmt.json" nested) "{}\n")
          (should (equal (rc-odin--root) default-directory)))
      (delete-directory root t))))

;;; editor-tests.el ends here
