;;; init.el -*- lexical-binding: t; -*-

(doom! :completion
       (corfu +icons +orderless +dabbrev)
       vertico

       :ui
       dashboard
       doom
       modeline
       ophints
       (popup +defaults)
       vc-gutter

       :editor
       (evil +everywhere)
       file-templates
       fold
       (format +onsave)
       snippets

       :emacs
       dired
       electric
       undo
       vc

       :term
       ghostel

       :checkers
       (spell +aspell)
       syntax

       :tools
       lookup
       magit

       :lang
       cc
       emacs-lisp
       go
       markdown
       (org +pretty)
       python
       sh
       zig

       :config
       (default +bindings +smartparens))
