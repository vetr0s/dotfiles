;;; post-init.el -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; The last file minimal-emacs.d loads. It installs whatever pre-init.el
;; declared and then requires the modules in configs/, which is where the
;; actual configuration lives.
;;
;; Order matters only at the top: rc-defaults repairs PATH, which anything
;; shelling out depends on, and rc-ui applies the theme.

;;; Code:

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(require 'rc-packages)

;; Reject changed archive builds before they can replace persistent state.
(rc-package-verify-install-candidates)
(package-install-selected-packages :no-confirm)
(rc-package-verify-lock)

;; early-init.el points `custom-file' here but never loads it, so anything set
;; through customize was written and ignored. Before the modules, so they win.
;;
;; Customize writes `package-selected-packages' too, and that copy would shadow
;; the manifest. pre-init.el is the one source of truth, so it is put back.
(let ((manifest package-selected-packages))
  (when (file-exists-p custom-file)
    (load custom-file nil :nomessage))
  (setq package-selected-packages manifest))

(require 'rc-defaults)
(require 'rc-ui)
(require 'rc-completion)
(require 'rc-evil)
(require 'rc-editing)
(require 'rc-elisp)
(require 'rc-programming)
(require 'rc-cc)
(require 'rc-zig)
(require 'rc-odin)
(require 'rc-org)
(require 'rc-git)
(require 'rc-terminal)

;;; post-init.el ends here
