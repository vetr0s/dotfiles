;;; rc-org.el --- Org and document viewing -*- lexical-binding: t; -*-

;;; Commentary:

;; Org and PDF viewing. This is the Org that ships with Emacs; pre-init.el
;; deliberately leaves it out of the package manifest so a second copy from
;; ELPA cannot race the built-in for load order.
;;
;; One rule shapes the capture templates: capturing never asks where a thing
;; belongs. Anything needing a decision lands in inbox.org and is refiled at
;; review, and anything needing none is written straight to its home file.
;; Deciding at capture time is what killed the previous setup.
;;
;; Work is a second agenda directory rather than a file under ~/source/org,
;; because that repo pushes to a remote no employer has agreed to.
;;
;; Settings are grouped by the file that defines them, not by topic. Org splits
;; its defcustoms across org.el, org-refile.el, org-capture.el and
;; org-agenda.el, and setting one before its own file loads assigns to a free
;; variable and skips any setter.

;;; Code:

;;; Org

(keymap-global-set "C-c a" #'org-agenda)
(keymap-global-set "C-c c" #'org-capture)

(setopt org-directory "~/source/org")

(setopt org-hide-leading-stars t)
(setopt org-startup-indented t)
(setopt org-adapt-indentation nil)
(setopt org-edit-src-content-indentation 0)

(setopt org-log-done 'time)
(setopt org-log-into-drawer t)

;; Relative, so each agenda directory archives into its own archive/.
(setopt org-archive-location "archive/%s_archive::")

(defun rc-org-stalled-project-p ()
  "Return non-nil when the subtree at point contains no NEXT child."
  (let ((end (save-excursion (org-end-of-subtree t))))
    (save-excursion
      (forward-line 1)
      ;; Guarded: a childless headline leaves point past END, and
      ;; `re-search-forward' errors on a bound behind point.
      (not (and (<= (point) end)
                (re-search-forward "^\\*+ NEXT " end t))))))

(defun rc-org-skip-unless-stalled ()
  "Skip the subtree at point unless it is a project with no NEXT child."
  (unless (rc-org-stalled-project-p)
    (save-excursion (org-end-of-subtree t))))

(with-eval-after-load 'org
  ;; Filtered, so a missing directory does not break the agenda. Directory
  ;; entries expand non-recursively, which is what keeps archive/ out.
  (setq org-agenda-files
        (seq-filter #'file-directory-p '("~/source/org" "~/source/work-org")))

  ;; The first sequence is for tasks, the second for project subtree roots.
  ;; WAIT prompts for a note because "waiting on what" is the question you
  ;; will have about it in a week.
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCELLED(c@)")
          (sequence "IDEA(i)" "ACTIVE(a)" "PAUSED(p@)" "|" "SHIPPED(s!)" "DROPPED(x@)")))

  ;; Inherited faces keep the keywords aligned with the active Doom theme.
  (setq org-todo-keyword-faces
        '(("TODO" . (:inherit error :weight bold))
          ("NEXT" . (:inherit warning :weight bold))
          ("WAIT" . (:inherit shadow :weight bold))
          ("DONE" . (:inherit success :weight bold))
          ("CANCELLED" . (:inherit shadow :weight bold))
          ("IDEA" . (:inherit shadow :weight bold))
          ("ACTIVE" . (:inherit warning :weight bold))
          ("PAUSED" . (:inherit shadow :weight bold))
          ("SHIPPED" . (:inherit success :weight bold))
          ("DROPPED" . (:inherit shadow :weight bold))))

  ;; Declared, so completion offers them and a typo cannot mint a new tag.
  ;; The context group is mutually exclusive.
  (setq org-tag-alist
        '((:startgroup)
          ("@home" . ?h)
          ("@errand" . ?e)
          ("@computer" . ?c)
          ("@phone" . ?p)
          (:endgroup)
          ("health" . ?H)
          ("finance" . ?f)
          ("admin" . ?a)
          ("social" . ?s))))

;;; Refile

(with-eval-after-load 'org-refile
  (setq org-refile-targets '((org-agenda-files :maxlevel . 3)))
  ;; Whole outline paths, completed in one step so vertico matches against the
  ;; full path rather than one level at a time.
  (setq org-refile-use-outline-path 'file)
  (setq org-outline-path-complete-in-steps nil))

;;; Capture

(with-eval-after-load 'org-capture
  ;; No date prompt on a task. Deciding when belongs to review, where the
  ;; whole week is visible.
  (setq org-capture-templates
        '(("t" "Task" entry (file "inbox.org")
           "* TODO %?")
          ("p" "Project idea" entry (file "inbox.org")
           "* IDEA %?")
          ("n" "Note" entry (file+headline "notes.org" "Unfiled")
           "* %?")
          ("j" "Journal entry" entry (file+olp+datetree "journal.org")
           "* %<%H:%M> %?")
          ("r" "Recipe" entry (file+headline "food.org" "Recipes")
           "* %?"))))

;;; Agenda

(with-eval-after-load 'org-agenda
  ;; Two views. The third block of the review is the one that catches a
  ;; project that has quietly stopped moving.
  (setq org-agenda-custom-commands
        '(("d" "Day"
           ((agenda "" ((org-agenda-span 'day)))
            (todo "NEXT" ((org-agenda-overriding-header "Next")))))
          ("r" "Review"
           ((alltodo "" ((org-agenda-files
                          (list (expand-file-name "inbox.org" org-directory)))
                         (org-agenda-overriding-header "Inbox")))
            (todo "WAIT" ((org-agenda-overriding-header "Waiting on")))
            (todo "ACTIVE" ((org-agenda-skip-function #'rc-org-skip-unless-stalled)
                            (org-agenda-overriding-header "Stalled projects"))))))))

;;; PDF

(add-to-list 'auto-mode-alist '("\\.pdf\\'" . pdf-view-mode))

;; Builds epdfinfo on first use if it is missing.
(with-eval-after-load 'pdf-tools
  (pdf-tools-install :no-query))

(provide 'rc-org)
;;; rc-org.el ends here
