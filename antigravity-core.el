;;; antigravity-core.el --- Core logic for Antigravity -*- lexical-binding: t; -*-

;; Author: Ariel Serranoni
;; Keywords: ai, tools, convenience

;;; Commentary:
;; Core logic for Antigravity: Agent Registry, Detection, Spawning, and Notifications.

;;; Code:

(require 'project)
(require 'cl-lib)

;; Optional dependencies
(require 'gptel nil t)
(require 'aidermacs nil t)
(require 'eat nil t)
(require 'projectile nil t)

(defgroup antigravity nil
  "Antigravity AI Agent Manager."
  :group 'tools)

(defcustom antigravity-notify-on-response t
  "When non-nil, send desktop notification when an agent completes a response."
  :type 'boolean
  :group 'antigravity)

;;; Agent Registry

(defvar antigravity--agents (make-hash-table :test 'equal)
  "Registry of active AI agents. Key is buffer name.")

(defun antigravity--make-agent (buffer package &optional model project title)
  (let ((type (cond 
               ((eq package 'gptel) :chat)
               ((eq package 'aidermacs) :agent)
               ((eq package 'claude-code) :agent)
               ((memq package '(gemini llama-cpp)) :cli)
               (t :chat))))
    (list :buffer buffer
          :package package
          :type type
          :model (or model "unknown")
          :project (or project (antigravity--detect-project buffer))
          :title (or title (buffer-name buffer))
          :status 'active)))

(defun antigravity--detect-project (buffer)
  "Detect project root for BUFFER using Projectile or project.el."
  (with-current-buffer buffer
    (cond
     ((and (featurep 'projectile) (bound-and-true-p projectile-mode))
      (projectile-project-root))
     ((project-current)
      (project-root (project-current)))
     (t nil))))

;; Agent Detection Functions

(defun antigravity--list-gptel-buffers ()
  (seq-filter (lambda (b) (with-current-buffer b (bound-and-true-p gptel-mode))) (buffer-list)))

(defun antigravity--list-aider-sessions ()
  (seq-filter (lambda (b) (string-match-p "^\\*aidermacs" (buffer-name b))) (buffer-list)))

(defun antigravity--list-claude-code-buffers ()
  (when (featurep 'claude-code)
    (seq-filter (lambda (b) (string-match-p "^\\*claude-code" (buffer-name b))) (buffer-list))))

(defun antigravity--list-cli-agent-buffers ()
  "List active CLI agent buffers spawned by Antigravity."
  (seq-filter (lambda (b) (with-current-buffer b (bound-and-true-p antigravity-cli-agent-p)))
              (buffer-list)))

(defun antigravity--get-gptel-model (buffer)
  (with-current-buffer buffer
    (if (boundp 'gptel-model) (format "%s" gptel-model) "unknown")))

(defun antigravity--get-aider-model (buffer)
  (with-current-buffer buffer
    (or (bound-and-true-p aidermacs--current-model)
        (bound-and-true-p aidermacs-default-model)
        "aider-default")))

(defun antigravity--get-aider-project (buffer)
  (let ((name (buffer-name buffer)))
    (if (string-match "\\*aidermacs:\\(.+\\)\\*" name)
        (match-string 1 name)
      (antigravity--detect-project buffer))))

(defun antigravity--register-agent (buffer package model project)
  (puthash (buffer-name buffer)
           (antigravity--make-agent buffer package model project)
           antigravity--agents))

(defun antigravity--unregister-agent (buffer)
  (remhash (buffer-name buffer) antigravity--agents))

(defun antigravity--register-gptel-buffer ()
  "Register current buffer as a gptel agent."
  (when (bound-and-true-p gptel-mode)
    (antigravity--register-agent (current-buffer)
                                 'gptel
                                 (antigravity--get-gptel-model (current-buffer))
                                 (antigravity--detect-project (current-buffer)))))

(defun antigravity--sync-agents ()
  (maphash (lambda (name agent)
             (unless (buffer-live-p (plist-get agent :buffer))
               (remhash name antigravity--agents)))
           antigravity--agents)
  (dolist (buf (antigravity--list-gptel-buffers))
    (unless (gethash (buffer-name buf) antigravity--agents)
      (with-current-buffer buf (antigravity--register-gptel-buffer))))
  (dolist (buf (antigravity--list-aider-sessions))
    (unless (gethash (buffer-name buf) antigravity--agents)
      (antigravity--register-agent buf 'aidermacs 
                                   (antigravity--get-aider-model buf)
                                   (antigravity--get-aider-project buf))))
  (dolist (buf (antigravity--list-claude-code-buffers))
    (unless (gethash (buffer-name buf) antigravity--agents)
      (antigravity--register-agent buf 'claude-code "claude" nil)))
  (dolist (buf (antigravity--list-cli-agent-buffers))
    (unless (gethash (buffer-name buf) antigravity--agents)
      (with-current-buffer buf
        (antigravity--register-agent buf
                                     (or (bound-and-true-p antigravity-cli-package) 'cli)
                                     (or (bound-and-true-p antigravity-cli-model) "unknown")
                                     (antigravity--detect-project buf))))))

(with-eval-after-load 'gptel
  (add-hook 'gptel-mode-hook #'antigravity--register-gptel-buffer))

;;; Notifications

(defun antigravity--notify (title message)
  (cond
   ((and (eq system-type 'darwin) (executable-find "terminal-notifier"))
    (call-process "terminal-notifier" nil nil nil "-title" title "-message" message "-sound" "default"))
   ((and (eq system-type 'darwin) (executable-find "osascript"))
    (call-process "osascript" nil nil nil "-e" (format "display notification \"%s\" with title \"%s\"" message title)))
   ((fboundp 'notifications-notify)
    (notifications-notify :title title :body message))
   (t (message "[%s] %s" title message))))

(defun antigravity--gptel-response-handler (_beg _end)
  (when antigravity-notify-on-response
    (antigravity--notify "Antigravity" (format "Response in %s" (buffer-name)))))

(with-eval-after-load 'gptel
  (add-hook 'gptel-post-response-functions #'antigravity--gptel-response-handler))

;;; Spawning

(defun antigravity--select-project ()
  (cond
   ((and (featurep 'projectile) (bound-and-true-p projectile-mode))
    (if (projectile-project-p)
        (projectile-project-root)
      (projectile-completing-read "Select project for Agent: " projectile-known-projects)))
   ((fboundp 'project-root)
    (let ((pr (project-current t)))
      (if pr (project-root pr) (read-directory-name "Project Root: "))))
   (t (read-directory-name "Project Root: "))))

;;;###autoload
(defun antigravity-spawn-aider ()
  "Spawn Aidermacs Agent with Project selection."
  (interactive)
  (let ((default-directory (antigravity--select-project)))
    (cond
     ((fboundp 'aidermacs-run-in-current-dir)
      (aidermacs-run-in-current-dir))
     ((fboundp 'aidermacs-run)
      (aidermacs-run))
     (t (message "Aidermacs not loaded")))))

;;;###autoload
(defun antigravity-spawn-gptel ()
  "Spawn GPTel Chat."
  (interactive)
  (call-interactively 'gptel))

;;;###autoload
(defun antigravity-spawn-gemini-cli ()
  "Spawn Gemini CLI."
  (interactive)
  (let ((buf-name "*Antigravity: Gemini CLI*"))
    (eat "gemini chat" t buf-name)
    (with-current-buffer buf-name
      (setq-local antigravity-cli-agent-p t)
      (setq-local antigravity-cli-package 'gemini)
      (setq-local antigravity-cli-model "gemini-cli")
      (antigravity--register-agent (current-buffer) 'gemini "gemini-cli" nil))))

;;;###autoload
(defun antigravity-spawn-llama-chat ()
  "Spawn GPTel using a local Llama.cpp server on port 9000."
  (interactive)
  (let* ((default-directory (antigravity--select-project))
         (project-name (file-name-nondirectory (directory-file-name default-directory)))
         (buf-name (format "*Antigravity: Llama Chat (%s)*" project-name))
         (llama-backend (gptel-make-openai "LlamaCPP"
                          :stream t
                          :protocol "http"
                          :host "localhost:9000"
                          :endpoint "/v1/chat/completions"
                          :models '("default"))))
    (gptel buf-name)
    (with-current-buffer buf-name
      (setq-local gptel-backend llama-backend)
      (setq-local gptel-model "default"))))

;;;###autoload
(defun antigravity-spawn-llama-coder ()
  "Spawn Aidermacs using a local Llama.cpp server on port 9000."
  (interactive)
  (let ((default-directory (antigravity--select-project)))
    (dlet ((aidermacs-args '("--openai-api-base" "http://localhost:9000/v1" "--model" "openai/default"))
           (aidermacs-default-model "openai/default"))
      (cond
       ((fboundp 'aidermacs-run-in-current-dir)
        (aidermacs-run-in-current-dir))
       ((fboundp 'aidermacs-run)
        (aidermacs-run))
       (t (message "Aidermacs not loaded"))))))

;;; Auth Utils

(defun antigravity-get-google-token ()
  "Fetch Google Cloud access token via CLI."
  (let ((gcloud-cmd (or (executable-find "gcloud")
                        (expand-file-name "~/google-cloud-sdk/bin/gcloud"))))
    (if (and gcloud-cmd (file-executable-p gcloud-cmd))
        (string-trim (shell-command-to-string (format "%s auth print-access-token" gcloud-cmd)))
      (error "Antigravity: gcloud not found!"))))

;;; Doctor

;;;###autoload
(defun antigravity-doctor ()
  "Check Antigravity dependencies."
  (interactive)
  (let ((errors '()))
    (unless (executable-find "aider")
      (push "Aider (aider-chat) is not installed." errors))
    (unless (executable-find "curl")
      (push "Curl is required for GPTel." errors))
    (unless (or (executable-find "gemini") (executable-find "gcloud") (getenv "GEMINI_API_KEY"))
      (push "No Google Auth method found (gemini-cli, gcloud, or GEMINI_API_KEY)." errors))
    
    (if errors
        (message "Antigravity Doctor: Issues found:\n%s" (mapconcat #'identity errors "\n"))
      (message "Antigravity Doctor: All systems operational."))))

(provide 'antigravity-core)
;;; antigravity-core.el ends here
