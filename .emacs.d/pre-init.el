;;; pre-init.el --- Package manifest -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; init.el loads this file immediately before it calls `package-initialize',
;; which is the last point at which `package-selected-packages' still decides
;; what gets activated. The archives and their priorities are already set by
;; early-init.el, upstream, in the order GNU > NonGNU > MELPA > MELPA stable.
;;
;; Org is deliberately absent: Emacs ships a current one, and pulling a second
;; copy from ELPA only invites a version mismatch against the built-in that
;; loads first.

;;; Code:

(setq package-selected-packages
      '(;; Completion and navigation
        cape
        consult
        corfu
        embark
        embark-consult
        marginalia
        orderless
        vertico

        ;; Modal editing
        evil
        evil-collection
        evil-mc
        evil-surround
        move-text
        undo-fu
        undo-fu-session

        ;; Editing
        apheleia
        outline-indent
        stripspace
        yasnippet
        yasnippet-snippets

        ;; Emacs Lisp
        aggressive-indent
        enhanced-evil-paredit
        helpful
        highlight-defined
        paredit

        ;; Languages
        markdown-mode
        zig-mode

        ;; Documents
        pdf-tools

        ;; Interface
        doom-themes

        ;; Everything else
        evil-ghostel
        exec-path-from-shell
        ghostel
        magit))

;;; pre-init.el ends here
