;;; pre-early-init.el --- Configuration and state roots -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; minimal-emacs.d captures its configuration root before loading this file.
;; Runtime data can therefore leave the checkout without changing how the
;; remaining init files load.

;;; Code:

(add-to-list 'load-path
             (expand-file-name "configs/" user-emacs-directory))

(defconst rc-emacs-state-directory
  (file-name-as-directory
   (expand-file-name
    "emacs"
    (or (getenv "XDG_DATA_HOME") (expand-file-name "~/.local/share"))))
  "Directory for persistent Emacs state and installed packages.")

(make-directory rc-emacs-state-directory t)
(setq user-emacs-directory rc-emacs-state-directory
      package-user-dir (expand-file-name "elpa" rc-emacs-state-directory))

(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (expand-file-name
    "emacs/eln-cache/"
    (or (getenv "XDG_CACHE_HOME") (expand-file-name "~/.cache")))))

;; *scratch* comes up in `fundamental-mode' (see `initial-major-mode' in
;; early-init.el), which does no font locking, hence the mode switch.
(defun rc-display-startup-time ()
  "Write startup time and package count as comments atop *scratch*."
  (with-current-buffer (get-buffer-create "*scratch*")
    (unless (derived-mode-p 'lisp-interaction-mode)
      (lisp-interaction-mode))
    (goto-char (point-min))
    (insert (format ";; Startup Time: %.2fs\n;; Packages: %d\n\n"
                    (float-time (time-subtract after-init-time before-init-time))
                    (length package-activated-list)))))

(add-hook 'emacs-startup-hook #'rc-display-startup-time 100)

;;; pre-early-init.el ends here
