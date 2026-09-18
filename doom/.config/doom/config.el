;;; config.el -*- lexical-binding: t; -*-

(setq user-full-name "Nathan Tebbs"
      user-mail-address "nate@vetr0s.dev"
      doom-font (font-spec :family "Iosevka Term" :size 17)
      doom-theme 'doom-tokyo-night
      org-directory "~/source/org/"
      org-hide-leading-stars t
      org-startup-indented t
      org-adapt-indentation nil
      org-edit-src-content-indentation 0
      org-log-done 'time
      org-log-into-drawer t
      org-archive-location "archive/%s_archive::")

(map! "C-c a" #'org-agenda
      "C-c c" #'org-capture
      "C-c t" #'ghostel
      "C-x g" #'magit-status)

(defun my-ghostel-new ()
  "Open a new Ghostel buffer."
  (interactive)
  (ghostel '(4)))

(map! "C-c T" #'my-ghostel-new)

(defun my-org-stalled-project-p ()
  "Return non-nil when the current subtree has no NEXT child."
  (let ((end (save-excursion (org-end-of-subtree t))))
    (save-excursion
      (forward-line 1)
      (not (and (<= (point) end)
                (re-search-forward "^\\*+ NEXT " end t))))))

(defun my-org-skip-unless-stalled ()
  "Skip the current subtree unless it is stalled."
  (unless (my-org-stalled-project-p)
    (save-excursion (org-end-of-subtree t))))

(after! org
  (setq org-agenda-files
        (seq-filter #'file-directory-p '("~/source/org" "~/source/work-org"))
        org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCELLED(c@)")
          (sequence "IDEA(i)" "ACTIVE(a)" "PAUSED(p@)" "|" "SHIPPED(s!)" "DROPPED(x@)"))
        org-todo-keyword-faces
        '(("TODO" . (:inherit error :weight bold))
          ("NEXT" . (:inherit warning :weight bold))
          ("WAIT" . (:inherit shadow :weight bold))
          ("DONE" . (:inherit success :weight bold))
          ("CANCELLED" . (:inherit shadow :weight bold))
          ("IDEA" . (:inherit shadow :weight bold))
          ("ACTIVE" . (:inherit warning :weight bold))
          ("PAUSED" . (:inherit shadow :weight bold))
          ("SHIPPED" . (:inherit success :weight bold))
          ("DROPPED" . (:inherit shadow :weight bold)))
        org-tag-alist
        '((:startgroup)
          ("@home" . ?h) ("@errand" . ?e) ("@computer" . ?c) ("@phone" . ?p)
          (:endgroup)
          ("health" . ?H) ("finance" . ?f) ("admin" . ?a) ("social" . ?s))
        org-refile-targets '((org-agenda-files :maxlevel . 3))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil
        org-capture-templates
        '(("t" "Task" entry (file "inbox.org") "* TODO %?")
          ("p" "Project idea" entry (file "inbox.org") "* IDEA %?")
          ("n" "Note" entry (file+headline "notes.org" "Unfiled") "* %?")
          ("j" "Journal entry" entry (file+olp+datetree "journal.org") "* %<%H:%M> %?")
          ("r" "Recipe" entry (file+headline "food.org" "Recipes") "* %?"))
        org-agenda-custom-commands
        '(("d" "Day"
           ((agenda "" ((org-agenda-span 'day)))
            (todo "NEXT" ((org-agenda-overriding-header "Next")))))
          ("r" "Review"
           ((alltodo "" ((org-agenda-files
                          (list (expand-file-name "inbox.org" org-directory)))
                         (org-agenda-overriding-header "Inbox")))
            (todo "WAIT" ((org-agenda-overriding-header "Waiting on")))
            (todo "ACTIVE" ((org-agenda-skip-function #'my-org-skip-unless-stalled)
                            (org-agenda-overriding-header "Stalled projects"))))))))

(defun my-use-project-tags ()
  (when-let* ((root (locate-dominating-file default-directory ".tags")))
    (setq-local tags-table-list (list (expand-file-name ".tags" root)))))

(add-hook 'prog-mode-hook #'my-use-project-tags)
(setq tags-revert-without-query t)

(load (expand-file-name "~/source/blog/publish.el") 'noerror 'nomessage)
