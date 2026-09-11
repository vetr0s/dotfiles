;;; pre-init.el --- Package manifest -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; init.el loads this file before post-init.el asks Straight to make the
;; declared packages available. Installation happens only through the separate
;; bootstrap script; normal startup runs Straight without filesystem writes.
;;
;; Org is deliberately absent: Emacs ships a current one, and pulling a second
;; copy from ELPA only invites a version mismatch against the built-in that
;; loads first.

;;; Code:

(defconst rc-straight-packages
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
        (paredit :type git :host github :repo "emacsmirror/paredit")
        enhanced-evil-paredit
        helpful
        highlight-defined

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
        magit)
  "Packages loaded from Git checkouts managed by Straight.")

;;; pre-init.el ends here
