;;; rc-packages.el --- Package revision lock -*- lexical-binding: t; -*-

;;; Commentary:

;; Verifies the exact package versions and source revisions used by this
;; configuration. Only revisions matching this lock are accepted.

;;; Code:

(require 'package)

(defvar rc-package-lock nil
  "Exact versions and source revisions for the package dependency closure.")

(defconst rc-package-lock-file
  (expand-file-name
   "../package-lock.el"
   (file-name-directory (or load-file-name buffer-file-name)))
  "File holding `rc-package-lock'.")

(load rc-package-lock-file nil :nomessage)

(defun rc-package--installed-descriptor (package)
  "Return the installed descriptor for PACKAGE, or nil."
  (cadr (assq package package-alist)))

(defun rc-package--dependency-closure ()
  "Return installed packages reachable from `package-selected-packages'."
  (let ((todo (copy-sequence package-selected-packages))
        (seen nil))
    (while todo
      (let ((package (pop todo)))
        (unless (memq package seen)
          (push package seen)
          (let ((descriptor (or (rc-package--installed-descriptor package)
                                (error "Package is not installed: %s" package))))
            (dolist (requirement (package-desc-reqs descriptor))
              (unless (package-built-in-p (car requirement) (cadr requirement))
                (push (car requirement) todo)))))))
    (sort seen (lambda (left right)
                 (string< (symbol-name left) (symbol-name right))))))

(defun rc-package--descriptor-lock (package)
  "Return the lock entry for installed PACKAGE."
  (let* ((descriptor (or (rc-package--installed-descriptor package)
                         (error "Package is not installed: %s" package)))
         (version (package-version-join (package-desc-version descriptor)))
         (commit (alist-get :commit (package-desc-extras descriptor))))
    (unless (and (stringp commit)
                 (string-match-p "\\`[0-9a-f]\\{40\\}\\'" commit))
      (error "Package has no immutable source revision: %s" package))
    (list package version commit)))

(defun rc-package-verify-lock ()
  "Verify the installed dependency closure against `rc-package-lock'."
  (dolist (package (rc-package--dependency-closure))
    (let* ((expected (or (assq package rc-package-lock)
                         (error "Package is absent from package-lock.el: %s"
                                package)))
           (actual (rc-package--descriptor-lock package)))
      (unless (equal actual expected)
        (error "Package lock mismatch for %s: expected %S, found %S"
               package (cdr expected) (cdr actual)))))
  t)

(defun rc-package-write-lock ()
  "Write the installed dependency closure to `rc-package-lock-file'."
  (interactive)
  (let ((lock (mapcar #'rc-package--descriptor-lock
                      (rc-package--dependency-closure))))
    (with-temp-file rc-package-lock-file
      (insert ";;; package-lock.el --- Exact package revisions -*- no-byte-compile: t; lexical-binding: t; -*-\n\n")
      (insert ";;; Code:\n\n(setq rc-package-lock\n      '(")
      (while lock
        (prin1 (pop lock) (current-buffer))
        (if lock
            (insert "\n        ")
          (insert "))\n")))
      (insert "\n;;; package-lock.el ends here\n"))
    (message "Wrote %s" rc-package-lock-file)))

(provide 'rc-packages)
;;; rc-packages.el ends here
