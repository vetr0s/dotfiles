;;; editor-tests.el --- Editor regression tests -*- lexical-binding: t; -*-

(require 'ert)
(require 'python)
(require 'rc-cc)
(require 'rc-odin)
(require 'rc-programming)

(defun rc-test--write-file (path contents)
  (make-directory (file-name-directory path) t)
  (write-region contents nil path nil :silent))

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
