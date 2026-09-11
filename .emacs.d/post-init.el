;;; post-init.el -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; The last file minimal-emacs.d loads. It activates the packages that the
;; bootstrap command installed and then requires the modules in configs/.
;;
;; Order matters only at the top: rc-defaults repairs PATH, which anything
;; shelling out depends on, and rc-ui applies the theme.

;;; Code:

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(require 'rc-packages)
(rc-straight-load-packages)

;; early-init.el points `custom-file' here but never loads it, so anything set
;; through customize was written and ignored. Before the modules, so they win.
;;
(when (file-exists-p custom-file)
  (load custom-file nil :nomessage))

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
