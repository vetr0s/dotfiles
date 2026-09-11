;;; rc-packages.el --- Reproducible Straight package loading -*- lexical-binding: t; -*-

;;; Commentary:

;; Package installation and network access belong to bootstrap-emacs.sh.
;; Ordinary startup runs Straight in safe mode and only activates the package
;; checkouts and builds already present under rc-emacs-state-directory.

;;; Code:

(defconst rc-straight-bootstrap-file
  (expand-file-name "straight/repos/straight.el/bootstrap.el"
                    rc-emacs-state-directory)
  "Bootstrap file installed by bootstrap-emacs.sh.")

(defconst rc-straight-lock-file
  (expand-file-name "../straight-lock.el"
                    (file-name-directory (or load-file-name buffer-file-name)))
  "Tracked Straight version lockfile.")

(defun rc-straight-load-packages ()
  "Load the configured packages from their pinned Straight checkouts."
  (unless (file-exists-p rc-straight-bootstrap-file)
    (error "Emacs packages are not installed; run util/scripts/bootstrap-emacs.sh"))
  (unless (file-exists-p rc-straight-lock-file)
    (error "Straight lockfile is missing: %s" rc-straight-lock-file))
  (setq straight-base-dir rc-emacs-state-directory
        straight-profiles `((nil . ,rc-straight-lock-file))
        straight-check-for-modifications '(check-on-save find-when-checking)
        straight-safe-mode (not (getenv "RC_EMACS_BOOTSTRAP")))
  (load rc-straight-bootstrap-file nil :nomessage)
  (dolist (package rc-straight-packages)
    (straight-use-package package)))

(provide 'rc-packages)
;;; rc-packages.el ends here
