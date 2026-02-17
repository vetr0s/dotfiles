;;; post-init.el -*- no-byte-compile: t; lexical-binding: t; -*-

;; Native compilation enhances Emacs performance by converting Elisp code into
;; native machine code, resulting in faster execution and improved
;; responsiveness.
;;
;; Ensure adding the following compile-angel code at the very beginning
;; of your `~/.emacs.d/post-init.el` file, before all other packages.
(use-package compile-angel
  :demand t
  :ensure t
  :custom
  ;; Set `compile-angel-verbose` to nil to suppress output from compile-angel.
  ;; Drawback: The minibuffer will not display compile-angel's actions.
  (compile-angel-verbose t)

  :config
  ;; The following directive prevents compile-angel from compiling your init
  ;; files. If you choose to remove this push to `compile-angel-excluded-files'
  ;; and compile your pre/post-init files, ensure you understand the
  ;; implications and thoroughly test your code. For example, if you're using
  ;; the `use-package' macro, you'll need to explicitly add:
  ;; (eval-when-compile (require 'use-package))
  ;; at the top of your init file.
  (push "/init.el" compile-angel-excluded-files)
  (push "/early-init.el" compile-angel-excluded-files)
  (push "/pre-init.el" compile-angel-excluded-files)
  (push "/post-init.el" compile-angel-excluded-files)
  (push "/pre-early-init.el" compile-angel-excluded-files)
  (push "/post-early-init.el" compile-angel-excluded-files)

  ;; A local mode that compiles .el files whenever the user saves them.
  (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)

  ;; A global mode that compiles .el files prior to loading them via `load' or
  ;; `require'. Additionally, it compiles all packages that were loaded before
  ;; the mode `compile-angel-on-load-mode' was activated.
  (compile-angel-on-load-mode 1))

;; Set the default font to Zenbones Brainy with specific size and weight
(set-face-attribute 'default nil
                    :height 130 :weight 'normal :family "Zenbones Brainy")

;; Theme
(use-package gruber-darker-theme
  :ensure t
  :config
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme 'gruber-darker t))

;; Basic UI Improvements

;; Transparency
(set-frame-parameter nil 'alpha-background 92) ;; For Emacs 29+

;; Display line numbers in programming modes
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)

;; Highlight the current line
(add-hook 'prog-mode-hook #'hl-line-mode)

;; Show column number in mode line
(column-number-mode 1)

;; Delete trailing whitespace on save
(add-hook 'before-save-hook #'delete-trailing-whitespace)

;; Electric pair mode - auto-close brackets
(electric-pair-mode 1)

;; Show matching parentheses
(show-paren-mode 1)

;; Other Keybindings
(global-set-key (kbd "C-c c") #'compile)

;; Better scrolling behavior
(setq mouse-wheel-scroll-amount '(2 ((shift) . 1)))
(setq mouse-wheel-progressive-speed nil)

;; Remember window configurations (C-c left/right to undo/redo)
(winner-mode 1)

;; Make sure GUI Emacs gets PATH (macOS)
(use-package exec-path-from-shell
  :ensure t
  :config
  (exec-path-from-shell-initialize))

;; Auto-revert in Emacs is a feature that automatically updates the
;; contents of a buffer to reflect changes made to the underlying file
;; on disk.
(use-package autorevert
  :ensure nil
  :commands (auto-revert-mode global-auto-revert-mode)
  :hook
  (after-init . global-auto-revert-mode)
  :custom
  (auto-revert-interval 3)
  (auto-revert-remote-files nil)
  (auto-revert-use-notify t)
  (auto-revert-avoid-polling nil)
  (auto-revert-verbose t))

;; Recentf is an Emacs package that maintains a list of recently
;; accessed files, making it easier to reopen files you have worked on
;; recently.
(use-package recentf
  :ensure nil
  :commands (recentf-mode recentf-cleanup)
  :hook
  (after-init . recentf-mode)

  :custom
  (recentf-auto-cleanup (if (daemonp) 300 'never))
  (recentf-exclude
   (list "\\.tar$" "\\.tbz2$" "\\.tbz$" "\\.tgz$" "\\.bz2$"
         "\\.bz$" "\\.gz$" "\\.gzip$" "\\.xz$" "\\.zip$"
         "\\.7z$" "\\.rar$"
         "COMMIT_EDITMSG\\'"
         "\\.\\(?:gz\\|gif\\|svg\\|png\\|jpe?g\\|bmp\\|xpm\\)$"
         "-autoloads\\.el$" "autoload\\.el$"))

  :config
  ;; A cleanup depth of -90 ensures that `recentf-cleanup' runs before
  ;; `recentf-save-list', allowing stale entries to be removed before the list
  ;; is saved by `recentf-save-list', which is automatically added to
  ;; `kill-emacs-hook' by `recentf-mode'.
  (add-hook 'kill-emacs-hook #'recentf-cleanup -90))

;; savehist is an Emacs feature that preserves the minibuffer history between
;; sessions. It saves the history of inputs in the minibuffer, such as commands,
;; search strings, and other prompts, to a file. This allows users to retain
;; their minibuffer history across Emacs restarts.
(use-package savehist
  :ensure nil
  :commands (savehist-mode savehist-save)
  :hook
  (after-init . savehist-mode)
  :custom
  (savehist-autosave-interval 600)
  (savehist-additional-variables
   '(kill-ring                        ; clipboard
     register-alist                   ; macros
     mark-ring global-mark-ring       ; marks
     search-ring regexp-search-ring)))

;; save-place-mode enables Emacs to remember the last location within a file
;; upon reopening. This feature is particularly beneficial for resuming work at
;; the precise point where you previously left off.
(use-package saveplace
  :ensure nil
  :commands (save-place-mode save-place-local-mode)
  :hook
  (after-init . save-place-mode)
  :custom
  (save-place-limit 400))

(use-package dired
  :ensure nil
  :commands dired
  :config
  (require 'dired-x)
  (setq dired-omit-files (concat dired-omit-files "\\|^\\..+$"))
  (setq-default dired-dwim-target t)
  (setq dired-listing-switches "-alh"))

;; Enable `auto-save-mode' to prevent data loss. Use `recover-file' or
;; `recover-session' to restore unsaved changes.
(setq auto-save-default t)

(setq auto-save-interval 300)
(setq auto-save-timeout 30)

;; When auto-save-visited-mode is enabled, Emacs will auto-save file-visiting
;; buffers after a certain amount of idle time if the user forgets to save it
;; with save-buffer or C-x s for example.
;;
;; This is different from auto-save-mode: auto-save-mode periodically saves
;; all modified buffers, creating backup files, including those not associated
;; with a file, while auto-save-visited-mode only saves file-visiting buffers
;; after a period of idle time, directly saving to the file itself without
;; creating backup files.
(setq auto-save-visited-interval 5)   ; Save after 5 seconds if inactivity
(auto-save-visited-mode 1)

;; Corfu enhances in-buffer completion by displaying a compact popup with
;; current candidates, positioned either below or above the point. Candidates
;; can be selected by navigating up or down.
(use-package corfu
  :ensure t
  :commands (corfu-mode global-corfu-mode)

  :hook ((prog-mode . corfu-mode)
         (shell-mode . corfu-mode)
         (eshell-mode . corfu-mode))

  :custom
  ;; Hide commands in M-x which do not apply to the current mode.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Disable Ispell completion function. As an alternative try `cape-dict'.
  (text-mode-ispell-word-completion nil)
  (tab-always-indent 'complete)

  (corfu-auto t)
  (corfu-auto-delay 0.15)
  (corfu-auto-prefix 1)
  (corfu-cycle t)

  ;; Enable Corfu
  :config
  (global-corfu-mode))

;; Cape, or Completion At Point Extensions, extends the capabilities of
;; in-buffer completion. It integrates with Corfu or the default completion UI,
;; by providing additional backends through completion-at-point-functions.
(use-package cape
  :ensure t
  :commands (cape-dabbrev cape-file cape-elisp-block)
  :bind ("C-c p" . cape-prefix-map)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block))

;; ;; Vertico provides a vertical completion interface, making it easier to
;; ;; navigate and select from completion candidates (e.g., when `M-x` is pressed).
;; (use-package vertico
;;   ;; (Note: It is recommended to also enable the savehist package.)
;;   :ensure t
;;   :config
;;   (vertico-mode))

;; ;; Vertico leverages Orderless' flexible matching capabilities, allowing users
;; ;; to input multiple patterns separated by spaces, which Orderless then
;; ;; matches in any order against the candidates.
;; (use-package orderless
;;   :ensure t
;;   :custom
;;   (completion-styles '(orderless basic))
;;   (completion-category-defaults nil)
;;   (completion-category-overrides '((file (styles partial-completion)))))

;; ;; Marginalia allows Embark to offer you preconfigured actions in more contexts.
;; ;; In addition to that, Marginalia also enhances Vertico by adding rich
;; ;; annotations to the completion candidates displayed in Vertico's interface.
;; (use-package marginalia
;;   :ensure t
;;   :commands (marginalia-mode marginalia-cycle)
;;   :hook (after-init . marginalia-mode))

;; ;; Embark integrates with Consult and Vertico to provide context-sensitive
;; ;; actions and quick access to commands based on the current selection, further
;; ;; improving user efficiency and workflow within Emacs. Together, they create a
;; ;; cohesive and powerful environment for managing completions and interactions.
;; (use-package embark
;;   ;; Embark is an Emacs package that acts like a context menu, allowing
;;   ;; users to perform context-sensitive actions on selected items
;;   ;; directly from the completion interface.
;;   :ensure t
;;   :commands (embark-act
;;              embark-dwim
;;              embark-export
;;              embark-collect
;;              embark-bindings
;;              embark-prefix-help-command)
;;   :bind
;;   (("C-." . embark-act)         ;; pick some comfortable binding
;;    ("C-;" . embark-dwim)        ;; good alternative: M-.
;;    ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'
;;
;;   :init
;;   (setq prefix-help-command #'embark-prefix-help-command)
;;
;;   :config
;;   ;; Hide the mode line of the Embark live/completions buffers
;;   (add-to-list 'display-buffer-alist
;;                '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
;;                  nil
;;                  (window-parameters (mode-line-format . none)))))

;; (use-package embark-consult
;;   :ensure t
;;   :hook
;;   (embark-collect-mode . consult-preview-at-point-mode))

;; ;; Consult offers a suite of commands for efficient searching, previewing, and
;; ;; interacting with buffers, file contents, and more, improving various tasks.
;; (use-package consult
;;   :ensure t
;;   :bind (;; C-c bindings in `mode-specific-map'
;;          ("C-c M-x" . consult-mode-command)
;;          ("C-c h" . consult-history)
;;          ("C-c k" . consult-kmacro)
;;          ("C-c m" . consult-man)
;;          ("C-c i" . consult-info)
;;          ([remap Info-search] . consult-info)
;;          ;; C-x bindings in `ctl-x-map'
;;          ("C-x M-:" . consult-complex-command)
;;          ("C-x b" . consult-buffer)
;;          ("C-x 4 b" . consult-buffer-other-window)
;;          ("C-x 5 b" . consult-buffer-other-frame)
;;          ("C-x t b" . consult-buffer-other-tab)
;;          ("C-x r b" . consult-bookmark)
;;          ("C-x p b" . consult-project-buffer)
;;          ;; Custom M-# bindings for fast register access
;;          ("M-#" . consult-register-load)
;;          ("M-'" . consult-register-store)
;;          ("C-M-#" . consult-register)
;;          ;; Other custom bindings
;;          ("M-y" . consult-yank-pop)
;;          ;; M-g bindings in `goto-map'
;;          ("M-g e" . consult-compile-error)
;;          ("M-g f" . consult-flymake)
;;          ("M-g g" . consult-goto-line)
;;          ("M-g M-g" . consult-goto-line)
;;          ("M-g o" . consult-outline)
;;          ("M-g m" . consult-mark)
;;          ("M-g k" . consult-global-mark)
;;          ("M-g i" . consult-imenu)
;;          ("M-g I" . consult-imenu-multi)
;;          ;; M-s bindings in `search-map'
;;          ("M-s d" . consult-find)
;;          ("M-s c" . consult-locate)
;;          ("M-s g" . consult-grep)
;;          ("M-s G" . consult-git-grep)
;;          ("M-s r" . consult-ripgrep)
;;          ("M-s l" . consult-line)
;;          ("M-s L" . consult-line-multi)
;;          ("M-s k" . consult-keep-lines)
;;          ("M-s u" . consult-focus-lines)
;;          ;; Isearch integration
;;          ("M-s e" . consult-isearch-history)
;;          :map isearch-mode-map
;;          ("M-e" . consult-isearch-history)
;;          ("M-s e" . consult-isearch-history)
;;          ("M-s l" . consult-line)
;;          ("M-s L" . consult-line-multi)
;;          ;; Minibuffer history
;;          :map minibuffer-local-map
;;          ("M-s" . consult-history)
;;          ("M-r" . consult-history))
;;
;;   ;; Enable automatic preview at point in the *Completions* buffer.
;;   :hook (completion-list-mode . consult-preview-at-point-mode)
;;
;;   :init
;;   ;; Optionally configure the register formatting. This improves the register
;;   (setq register-preview-delay 0.5
;;         register-preview-function #'consult-register-format)
;;
;;   ;; Optionally tweak the register preview window.
;;   (advice-add #'register-preview :override #'consult-register-window)
;;
;;   ;; Use Consult to select xref locations with preview
;;   (setq xref-show-xrefs-function #'consult-xref
;;         xref-show-definitions-function #'consult-xref)
;;
;;   ;; Aggressive asynchronous that yield instantaneous results. (suitable for
;;   ;; high-performance systems.) Note: Minad, the author of Consult, does not
;;   ;; recommend aggressive values.
;;   ;; Read: https://github.com/minad/consult/discussions/951
;;   ;;
;;   ;; However, the author of minimal-emacs.d uses these parameters to achieve
;;   ;; immediate feedback from Consult.
;;   ;; (setq consult-async-input-debounce 0.02
;;   ;;       consult-async-input-throttle 0.05
;;   ;;       consult-async-refresh-delay 0.02)
;;
;;   :config
;;   (consult-customize
;;    consult-theme :preview-key '(:debounce 0.2 any)
;;    consult-ripgrep consult-git-grep consult-grep
;;    consult-bookmark consult-recent-file consult-xref
;;    ;; consult--source-bookmark consult--source-file-register
;;    ;; consult--source-recent-file consult--source-project-recent-file
;;    ;; :preview-key "M-."
;;    :preview-key '(:debounce 0.4 any))
;;   (setq consult-narrow-key "<"))

(use-package helm
  :ensure t
  :demand t
  :bind (("M-x"     . helm-M-x)
         ("C-x C-f" . helm-find-files)
         ("C-x b"   . helm-mini)
         ("C-x r b" . helm-filtered-bookmarks)
         ("M-y"     . helm-show-kill-ring)
         ("M-g i"   . helm-imenu)
         ("M-g I"   . helm-imenu-in-all-buffers)
         ("M-s g"   . helm-do-grep-ag)
         ("M-s r"   . helm-do-grep-ag)
         ("C-c h"   . helm-command-prefix)
         :map helm-map
         ("<tab>"   . helm-execute-persistent-action)
         ("C-z"     . helm-select-action))
  :custom
  (helm-split-window-in-side-p t)
  (helm-move-to-line-cycle-in-source t)
  (helm-autoresize-max-height 40)
  (helm-autoresize-min-height 20)
  :config
  (helm-mode 1)
  (helm-autoresize-mode 1))

;; The built-in outline-minor-mode provides structured code folding in modes
;; such as Emacs Lisp and Python, allowing users to collapse and expand sections
;; based on headings or indentation levels. This feature enhances navigation and
;; improves the management of large files with hierarchical structures.
(use-package outline
  :ensure nil
  :commands outline-minor-mode
  :hook
  ((emacs-lisp-mode . outline-minor-mode)
   ;; Use " ▼" instead of the default ellipsis "..." for folded text to make
   ;; folds more visually distinctive and readable.
   (outline-minor-mode
    .
    (lambda()
      (let* ((display-table (or buffer-display-table (make-display-table)))
             (face-offset (* (face-id 'shadow) (ash 1 22)))
             (value (vconcat (mapcar (lambda (c) (+ face-offset c)) " ▼"))))
        (set-display-table-slot display-table 'selective-display value)
        (setq buffer-display-table display-table))))))

;; The outline-indent Emacs package provides a minor mode that enables code
;; folding based on indentation levels.
;;
;; In addition to code folding, *outline-indent* allows:
;; - Moving indented blocks up and down
;; - Indenting/unindenting to adjust indentation levels
;; - Inserting a new line with the same indentation level as the current line
;; - Move backward/forward to the indentation level of the current line
;; - and other features.
(use-package outline-indent
  :ensure t
  :commands outline-indent-minor-mode

  :custom
  (outline-indent-ellipsis " ▼")

  :init
  ;; The minor mode can also be automatically activated for a certain modes.
  (add-hook 'python-mode-hook #'outline-indent-minor-mode)
  (add-hook 'python-ts-mode-hook #'outline-indent-minor-mode)

  (add-hook 'yaml-mode-hook #'outline-indent-minor-mode)
  (add-hook 'yaml-ts-mode-hook #'outline-indent-minor-mode))

;; The stripspace Emacs package provides stripspace-local-mode, a minor mode
;; that automatically removes trailing whitespace and blank lines at the end of
;; the buffer when saving.
(use-package stripspace
  :ensure t
  :commands stripspace-local-mode

  ;; Enable for prog-mode-hook, text-mode-hook, conf-mode-hook
  :hook ((prog-mode . stripspace-local-mode)
         (text-mode . stripspace-local-mode)
         (conf-mode . stripspace-local-mode))

  :custom
  ;; The `stripspace-only-if-initially-clean' option:
  ;; - nil to always delete trailing whitespace.
  ;; - Non-nil to only delete whitespace when the buffer is clean initially.
  ;; (The initial cleanliness check is performed when `stripspace-local-mode'
  ;; is enabled.)
  (stripspace-only-if-initially-clean nil)

  ;; Enabling `stripspace-restore-column' preserves the cursor's column position
  ;; even after stripping spaces. This is useful in scenarios where you add
  ;; extra spaces and then save the file. Although the spaces are removed in the
  ;; saved file, the cursor remains in the same position, ensuring a consistent
  ;; editing experience without affecting cursor placement.
  (stripspace-restore-column t))

;; The undo-fu package is a lightweight wrapper around Emacs' built-in undo
;; system, providing more convenient undo/redo functionality.
(use-package undo-fu
  :ensure t
  :commands (undo-fu-only-undo
             undo-fu-only-redo
             undo-fu-only-redo-all
             undo-fu-disable-checkpoint)
  :config
  (global-unset-key (kbd "C-z"))
  (global-set-key (kbd "C-z") 'undo-fu-only-undo)
  (global-set-key (kbd "C-S-z") 'undo-fu-only-redo))

;; The undo-fu-session package complements undo-fu by enabling the saving
;; and restoration of undo history across Emacs sessions, even after restarting.
(use-package undo-fu-session
  :ensure t
  :commands undo-fu-session-global-mode
  :hook (after-init . undo-fu-session-global-mode))

;; Uncomment the following if you are using undo-fu
(setq evil-undo-system 'undo-fu)

;; Vim emulation
(defvar evil-mode-buffers nil)
(use-package evil
  :ensure t
  :demand t  ; Load immediately to avoid post-command-hook errors

  :init
  ;; It has to be defined before evil
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)

  :custom
  ;; Make :s in visual mode operate only on the actual visual selection
  ;; (character or block), instead of the full lines covered by the selection
  (evil-ex-visual-char-range t)
  ;; Use Vim-style regular expressions in search and substitute commands,
  ;; allowing features like \v (very magic), \zs, and \ze for precise matches
  (evil-ex-search-vim-style-regexp t)
  ;; Enable automatic horizontal split below
  (evil-split-window-below t)
  ;; Enable automatic vertical split to the right
  (evil-vsplit-window-right t)
  ;; Disable echoing Evil state to avoid replacing eldoc
  (evil-echo-state nil)
  ;; Do not move cursor back when exiting insert state
  (evil-move-cursor-back nil)
  ;; Make `v$` exclude the final newline
  (evil-v$-excludes-newline t)
  ;; Allow C-h to delete in insert state
  (evil-want-C-h-delete t)
  ;; Enable C-u to delete back to indentation in insert state
  (evil-want-C-u-delete t)
  ;; Enable fine-grained undo behavior
  (evil-want-fine-undo t)
  ;; Allow moving cursor beyond end-of-line in visual block mode
  (evil-move-beyond-eol t)
  ;; Disable wrapping of search around buffer
  (evil-search-wrap nil)
  ;; Whether Y yanks to the end of the line
  (evil-want-Y-yank-to-eol t)

  :config
  (require 'evil)
  (evil-mode 1)

  ;; C-u to scroll up (half page) in normal/visual/motion states
  (define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-visual-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-motion-state-map (kbd "C-u") 'evil-scroll-up)

  ;; C-g always escapes to normal mode
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-visual-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-replace-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-operator-state-map (kbd "C-g") 'evil-normal-state))

(use-package evil-collection
  :after evil
  :ensure t
  :demand t
  :init
  ;; It has to be defined before evil-collection
  (setq evil-collection-setup-minibuffer t)
  :config
  (evil-collection-init))

(use-package evil-mc
  :ensure t
  :after evil
  :commands (evil-mc-make-all-cursors
             evil-mc-undo-all-cursors
             evil-mc-make-and-goto-next-match
             evil-mc-skip-and-goto-next-match)
  :config
  (global-evil-mc-mode 1))

(use-package move-text
  :ensure t
  :commands (move-text-up move-text-down)
  :config
  (global-set-key (kbd "M-p") 'move-text-up)
  (global-set-key (kbd "M-n") 'move-text-down))

;; The evil-surround package simplifies handling surrounding characters, such as
;; parentheses, brackets, quotes, etc. It provides key bindings to easily add,
;; change, or delete these surrounding characters in pairs. For instance, you
;; can surround the currently selected text with double quotes in visual state
;; using S" or gS".
(use-package evil-surround
  :after evil
  :ensure t
  :commands global-evil-surround-mode
  :custom
  (evil-surround-pairs-alist
   '((?\( . ("(" . ")"))
     (?\[ . ("[" . "]"))
     (?\{ . ("{" . "}"))

     (?\) . ("(" . ")"))
     (?\] . ("[" . "]"))
     (?\} . ("{" . "}"))

     (?< . ("<" . ">"))
     (?> . ("<" . ">"))))
  :hook (after-init . global-evil-surround-mode))
;; The following code enables commenting and uncommenting by pressing gcc in
;; normal mode and gc in visual mode.
(with-eval-after-load "evil"
  (evil-define-operator my-evil-comment-or-uncomment (beg end)
    "Toggle comment for the region between BEG and END."
    (interactive "<r>")
    (comment-or-uncomment-region beg end))
  (evil-define-key 'normal 'global (kbd "gc") 'my-evil-comment-or-uncomment))


;; ---------------------------------------------------------------------------
;; LSP (disabled)
;; ---------------------------------------------------------------------------
;; Set up the Language Server Protocol (LSP) servers using Eglot.
;; (use-package eglot
;;   :ensure nil
;;   :commands (eglot-ensure
;;              eglot-rename
;;              eglot-format-buffer)
;;   :hook
;;   (java-mode . eglot-ensure)
;;   (java-ts-mode . eglot-ensure)
;;   (ruby-mode . eglot-ensure)
;;   (ruby-ts-mode . eglot-ensure)
;;   (haskell-mode . eglot-ensure)
;;   (haskell-literate-mode . eglot-ensure)
;;   :config
;;   (dolist (entry '((java-mode    . ("jdtls"))
;;                    (java-ts-mode . ("jdtls"))
;;                    (ruby-mode    . ("solargraph" "stdio"))
;;                    (ruby-ts-mode . ("solargraph" "stdio"))
;;                    (haskell-mode . ("haskell-language-server-wrapper" "--lsp"))
;;                    (haskell-literate-mode . ("haskell-language-server-wrapper" "--lsp"))))
;;     (add-to-list 'eglot-server-programs entry))
;;   (setq eglot-autoshutdown t))

;; Haskell Support
(use-package haskell-mode
  :ensure t)

;; Ormolu auto-formatting (optional)
(use-package ormolu
  :ensure t
  :hook (haskell-mode . ormolu-format-on-save-mode))

;; Python venv support
(use-package pyvenv
  :ensure t
  :config
  (pyvenv-mode 1))

;; Zig Support
(use-package zig-mode
  :ensure t)

;; Odin Support
(use-package odin-mode
  :ensure (odin-mode
           :host github
           :repo "mattt-b/odin-mode")
  :bind (:map odin-mode-map
              ("C-c C-r" . 'odin-run-project)
              ("C-c C-c" . 'odin-build-project)
              ("C-c C-t" . 'odin-test-project)))

;; K&R style auto-formatting for C/C++ (astyle)
(defun astyle-buffer (&optional justify)
  (interactive)
  (let ((saved-line-number (line-number-at-pos)))
    (shell-command-on-region
     (point-min)
     (point-max)
     "astyle --style=kr"
     nil
     t)
    (goto-line saved-line-number)))

(with-eval-after-load "cc-mode"
  (define-key c-mode-map (kbd "C-c C-f") 'astyle-buffer)
  (define-key c++-mode-map (kbd "C-c C-f") 'astyle-buffer))

;; Org mode is a major mode designed for organizing notes, planning, task
;; management, and authoring documents using plain text with a simple and
;; expressive markup syntax. It supports hierarchical outlines, TODO lists,
;; scheduling, deadlines, time tracking, and exporting to multiple formats
;; including HTML, LaTeX, PDF, and Markdown.
(use-package org
  :ensure t
  :commands (org-mode org-version)
  :mode
  ("\\.org\\'" . org-mode)
  :bind (("C-c a"   . org-agenda))
  :custom
  (org-hide-leading-stars t)
  (org-startup-indented t)
  (org-adapt-indentation nil)
  (org-edit-src-content-indentation 0)
  :config
  (setq org-agenda-files '("~/dev/ua/Agenda"))
  (setq org-todo-keywords '((sequence "TODO" "IN-PROGRESS" "WAITING" "DONE")))
  (setq org-todo-keyword-faces
        '(("TODO" . (:foreground "red" :weight bold)) ("IN-PROGRESS" . (:foreground "yellow" :weight bold))
          ("WAITING" . (:foreground "blue" :weight bold)) ("DONE" . (:foreground "green" :weight bold)))))

;; PDF Stuff
(use-package pdf-tools
  :ensure t)

;; The markdown-mode package provides a major mode for Emacs for syntax
;; highlighting, editing commands, and preview support for Markdown documents.
;; It supports core Markdown syntax as well as extensions like GitHub Flavored
;; Markdown (GFM).
(use-package markdown-mode
  :commands (gfm-mode
             gfm-view-mode
             markdown-mode
             markdown-view-mode)
  :mode (("\\.markdown\\'" . markdown-mode)
         ("\\.md\\'" . markdown-mode)
         ("README\\.md\\'" . gfm-mode))
  :bind
  (:map markdown-mode-map
        ("C-c C-e" . markdown-do)))

;; Automatically generate a table of contents when editing Markdown files
(use-package markdown-toc
  :ensure t
  :commands (markdown-toc-generate-toc
             markdown-toc-generate-or-refresh-toc
             markdown-toc-delete-toc
             markdown-toc--toc-already-present-p)
  :custom
  (markdown-toc-header-toc-title "**Table of Contents**"))

;; ;; Tree-sitter in Emacs is an incremental parsing system introduced in Emacs 29
;; ;; that provides precise, high-performance syntax highlighting. It supports a
;; ;; broad set of programming languages, including Bash, C, C++, C#, CMake, CSS,
;; ;; Dockerfile, Go, Java, JavaScript, JSON, Python, Rust, TOML, TypeScript, YAML,
;; ;; Elisp, Lua, Markdown, and many others.
;; (use-package treesit-auto
;;   :ensure t
;;   :custom
;;   (treesit-auto-install 'prompt)
;;   :config
;;   (treesit-auto-add-to-auto-mode-alist 'all)
;;   (global-treesit-auto-mode))

;; This automates the process of updating installed packages
(use-package auto-package-update
  :ensure t
  :custom
  ;; Set the number of days between automatic updates.
  ;; Here, packages will only be updated if at least 7 days have passed
  ;; since the last successful update.
  (auto-package-update-interval 7)

  ;; Suppress display of the *auto-package-update results* buffer after updates.
  ;; This keeps the user interface clean and avoids unnecessary interruptions.
  (auto-package-update-hide-results t)

  ;; Automatically delete old package versions after updates to reduce disk
  ;; usage and keep the package directory clean. This prevents the accumulation
  ;; of outdated files in Emacs’s package directory, which consume
  ;; unnecessary disk space over time.
  (auto-package-update-delete-old-versions t)

  ;; Uncomment the following line to enable a confirmation prompt
  ;; before applying updates. This can be useful if you want manual control.
  ;; (auto-package-update-prompt-before-update t)

  :config
  ;; Run package updates automatically at startup, but only if the configured
  ;; interval has elapsed.
  (auto-package-update-maybe)

  ;; Schedule a background update attempt daily at 10:00 AM.
  ;; This uses Emacs' internal timer system. If Emacs is running at that time,
  ;; the update will be triggered. Otherwise, the update is skipped for that
  ;; day. Note that this scheduled update is independent of
  ;; `auto-package-update-maybe` and can be used as a complementary or
  ;; alternative mechanism.
  (auto-package-update-at-time "10:00"))

(use-package buffer-terminator
  :ensure t
  :custom
  ;; Enable/Disable verbose mode to log buffer cleanup events
  (buffer-terminator-verbose nil)

  ;; Set the inactivity timeout (in seconds) after which buffers are considered
  ;; inactive (default is 30 minutes):
  (buffer-terminator-inactivity-timeout (* 30 60)) ; 30 minutes

  ;; Define how frequently the cleanup process should run (default is every 10
  ;; minutes):
  (buffer-terminator-interval (* 10 60)) ; 10 minutes

  :config
  (buffer-terminator-mode 1))

;; The flyspell package is a built-in Emacs minor mode that provides
;; on-the-fly spell checking. It highlights misspelled words as you type,
;; offering interactive corrections. In text modes, it checks the entire buffer,
;; while in programming modes, it typically checks only comments and strings. It
;; integrates with external spell checkers like aspell, hunspell, or
;; ispell to provide suggestions and corrections.
;;
;; NOTE: flyspell-mode can become slow when using Aspell, especially with large
;; buffers or aggressive suggestion settings like --sug-mode=ultra. This
;; slowdown occurs because Flyspell checks words dynamically as you type or
;; navigate text, requiring frequent communication between Emacs and the
;; external Aspell process. Each check involves sending words to Aspell and
;; receiving results, which introduces overhead from process invocation and
;; inter-process communication.
(use-package ispell
  :ensure nil
  :commands (ispell ispell-minor-mode)
  :custom
  ;; Set the ispell program name to aspell
  (ispell-program-name "aspell")

  ;; Define the "en_US" spell-check dictionary locally, telling Emacs to use
  ;; UTF-8 encoding, match words using alphabetic characters, allow apostrophes
  ;; inside words, treat non-alphabetic characters as word boundaries, and pass
  ;; -d en_US to the underlying spell-check program.
  (ispell-local-dictionary-alist
   '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8)))

  ;; Configures Aspell's suggestion mode to "ultra", which provides more
  ;; aggressive and detailed suggestions for misspelled words. The language
  ;; is set to "en_US" for US English, which can be replaced with your desired
  ;; language code (e.g., "en_GB" for British English, "de_DE" for German).
  (ispell-extra-args '(; "--sug-mode=ultra"
                       "--lang=en_US")))

;; The flyspell package is a built-in Emacs minor mode that provides
;; on-the-fly spell checking. It highlights misspelled words as you type,
;; offering interactive corrections.
(use-package flyspell
  :ensure nil
  :commands flyspell-mode
  :config
  ;; Remove strings from Flyspell
  (setq flyspell-prog-text-faces (delq 'font-lock-string-face
                                       flyspell-prog-text-faces))

  ;; Remove doc from Flyspell
  (setq flyspell-prog-text-faces (delq 'font-lock-doc-face
                                       flyspell-prog-text-faces)))

;; Apheleia is an Emacs package designed to run code formatters (e.g., Shfmt,
;; Black and Prettier) asynchronously without disrupting the cursor position.
(use-package apheleia
  :ensure t
  :commands (apheleia-mode
             apheleia-global-mode)
  :hook ((prog-mode . apheleia-mode)))

;; The official collection of snippets for yasnippet.
(use-package yasnippet-snippets
  :ensure t
  :after yasnippet)

;; YASnippet is a template system designed that enhances text editing by
;; enabling users to define and use snippets. When a user types a short
;; abbreviation, YASnippet automatically expands it into a full template, which
;; can include placeholders, fields, and dynamic content.
(use-package yasnippet
  :ensure t
  :commands (yas-minor-mode
             yas-global-mode)

  :hook
  (after-init . yas-global-mode)

  :custom
  (yas-also-auto-indent-first-line t)  ; Indent first line of snippet
  (yas-also-indent-empty-lines t)
  (yas-snippet-revival nil)  ; Setting this to t causes issues with undo
  (yas-wrap-around-region nil) ; Do not wrap region when expanding snippets
  ;; (yas-triggers-in-field nil)  ; Disable nested snippet expansion
  ;; (yas-indent-line 'fixed) ; Do not auto-indent snippet content
  ;; (yas-prompt-functions '(yas-no-prompt))  ; No prompt for snippet choices

  :init
  ;; Suppress verbose messages
  (setq yas-verbosity 0))

;; Helpful is an alternative to the built-in Emacs help that provides much more
;; contextual information.
(use-package helpful
  :ensure t
  :commands (helpful-callable
             helpful-variable
             helpful-key
             helpful-command
             helpful-at-point
             helpful-function)
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-function] . helpful-callable)
  ([remap describe-key] . helpful-key)
  ([remap describe-symbol] . helpful-symbol)
  ([remap describe-variable] . helpful-variable)
  :custom
  (helpful-max-buffers 7))

;; Enables automatic indentation of code while typing
(use-package aggressive-indent
  :ensure t
  :commands aggressive-indent-mode
  :hook
  (emacs-lisp-mode . aggressive-indent-mode))

;; Highlights function and variable definitions in Emacs Lisp mode
(use-package highlight-defined
  :ensure t
  :commands highlight-defined-mode
  :hook
  (emacs-lisp-mode . highlight-defined-mode))

;; Prevent thesis imbalance
(use-package paredit
  :ensure t
  :commands paredit-mode
  :hook
  (emacs-lisp-mode . paredit-mode)
  :config
  (define-key paredit-mode-map (kbd "RET") nil))

;; For paredit+Evil mode users: enhances paredit with Evil mode compatibility
;; --------------------------------------------------------------------------
(use-package enhanced-evil-paredit
  :ensure t
  :commands enhanced-evil-paredit-mode
  :hook
  (paredit-mode . enhanced-evil-paredit-mode))

;; Displays visible indicators for page breaks
(use-package page-break-lines
  :ensure t
  :commands (page-break-lines-mode
             global-page-break-lines-mode)
  :hook
  (emacs-lisp-mode . page-break-lines-mode))

;; Provides functions to find references to functions, macros, variables,
;; special forms, and symbols in Emacs Lisp
(use-package elisp-refs
  :ensure t
  :commands (elisp-refs-function
             elisp-refs-macro
             elisp-refs-variable
             elisp-refs-special
             elisp-refs-symbol))

;; Trying to make the modeline look pretty and also cut down on the amount of
;; modes being displayed on the modeline.
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

;; Magit Dependency: transient
(use-package transient :ensure t)
;; Magit is like lazyvim but within emacs so you can do most git/github
;; actions without having to leave emacs.
(use-package magit :ensure t)

;; The easysession Emacs package is a session manager for Emacs that can persist
;; and restore file editing buffers, indirect buffers/clones, Dired buffers,
;; windows/splits, the built-in tab-bar (including tabs, their buffers, and
;; windows), and Emacs frames. It offers a convenient and effortless way to
;; manage Emacs editing sessions and utilizes built-in Emacs functions to
;; persist and restore frames.
(use-package easysession
  :ensure t
  :commands (easysession-switch-to
             easysession-save-as
             easysession-save-mode
             easysession-load-including-geometry)

  :custom
  (easysession-mode-line-misc-info t)  ; Display the session in the modeline
  (easysession-save-interval (* 10 60))  ; Save every 10 minutes

  :init
  ;; Key mappings:
  ;; C-c l for switching sessions
  ;; and C-c s for saving the current session
  (global-set-key (kbd "C-c l") 'easysession-switch-to)
  (global-set-key (kbd "C-c s") 'easysession-save-as)
  (global-set-key (kbd "C-c r") 'easysession-reset)

  ;; The depth 102 and 103 have been added to to `add-hook' to ensure that the
  ;; session is loaded after all other packages. (Using 103/102 is particularly
  ;; useful for those using minimal-emacs.d, where some optimizations restore
  ;; `file-name-handler-alist` at depth 101 during `emacs-startup-hook`.)
  (add-hook 'emacs-startup-hook #'easysession-load-including-geometry 102)
  (add-hook 'emacs-startup-hook #'easysession-save-mode 103))

;; Reveal.js slide export for Org
(use-package ox-reveal
  :ensure t
  :after org
  :commands (org-reveal-export-to-html org-reveal-export-as-html)
  :init
  ;; Pick ONE of these:

  ;; ;; Option A: Local reveal.js (recommended)
  ;; ;; 1) git clone https://github.com/hakimel/reveal.js ~/.emacs.d/reveal.js
  ;; ;; 2) set the path:
  ;; (setq org-reveal-root (concat "file://" (expand-file-name "~/.emacs.d/reveal.js")))

  ;; Option B: CDN (easy, but depends on network)
  (setq org-reveal-root "https://cdn.jsdelivr.net/npm/reveal.js")

  :config
  ;; Handy keybinds
  (global-set-key (kbd "C-c e r") #'org-reveal-export-to-html)
  (global-set-key (kbd "C-c e R") #'org-reveal-export-as-html))

;; EMAIL: Mu4e
(use-package mu4e
  :ensure nil
  :config
  (setq mu4e-maildir "~/.mail/gmail")

  ;; Sync mail
  (setq mu4e-get-mail-command "mbsync gmail"
        mu4e-update-interval 300)

  ;; Identity
  (setq user-mail-address "vetr0s.dev@gmail.com"
        user-full-name "Nathan Tebbs")

  ;; Sent/Drafts/Trash folders (Gmail format)
  (setq mu4e-sent-folder   "/[Gmail]/Sent Mail"
        mu4e-drafts-folder "/[Gmail]/Drafts"
        mu4e-trash-folder  "/[Gmail]/Trash")

  ;; SMTP (sending mail)
  (setq message-send-mail-function 'smtpmail-send-it
        smtpmail-smtp-server "smtp.gmail.com"
        smtpmail-smtp-service 587
        smtpmail-stream-type 'starttls))
