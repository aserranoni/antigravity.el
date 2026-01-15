;;; antigravity.el --- AI pair programming agent manager -*- lexical-binding: t; -*-

;; Author: Ariel Serranoni
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1") (gptel "0.1") (aidermacs "0.1") (transient "0.3"))
;; Keywords: ai, tools, convenience

;;; Commentary:
;; Antigravity provides an agentic AI experience inside Emacs, integrating
;; Aidermacs (for coding) and GPTel (for chat) into a unified "Mission Control" interface.

;;; Code:

(require 'gptel)
(require 'aidermacs)
(require 'transient)
(require 'eat)

(defgroup antigravity nil
  "Antigravity AI Agent Manager."
  :group 'tools)

;;; Agent Manager

(defun antigravity--list-gptel-buffers ()
  "Return a list of active GPTel chat buffers."
  (seq-filter (lambda (b)
                (with-current-buffer b
                  (eq major-mode 'gptel-mode)))
              (buffer-list)))

(defun antigravity--list-aider-sessions ()
  "Return a list of active Aidermacs session buffers."
  (seq-filter (lambda (b)
                (string-match-p "^\\*aidermacs" (buffer-name b)))
              (buffer-list)))

(defun antigravity-kill-agent (buffer)
  "Kill the agent associated with BUFFER."
  (interactive (list (current-buffer)))
  (when (buffer-live-p buffer)
    (kill-buffer buffer)
    (message "Agent killed: %s" (buffer-name buffer))))

(defun antigravity-spawn-architect ()
  "Spawn a new Architect agent (High reasoning model)."
  (interactive)
  (let ((gptel-model 'gemini-pro)) ;; Uses default or configured model
    (gptel "*Antigravity: Architect*")
    (with-current-buffer "*Antigravity: Architect*"
      (goto-char (point-max))
      (insert "\n\n**System**: You are the Architect. Analyze the problem and provide a high-level solution.\n\n"))))

(defun antigravity-spawn-gemini-cli ()
  "Spawn Gemini CLI in a terminal buffer."
  (interactive)
  (eat "gemini chat" t))

(defun antigravity--format-agent-list ()
  "Format the list of agents for the dashboard."
  (let ((chats (antigravity--list-gptel-buffers))
        (coders (antigravity--list-aider-sessions)))
    (concat 
     (propertize "  Chat Agents:\n" 'face 'bold)
     (if chats 
         (mapconcat (lambda (b) (format "    - %s" (buffer-name b))) chats "\n")
       "    (none)\n")
     (propertize "\n  Coding Agents:\n" 'face 'bold)
     (if coders
         (mapconcat (lambda (b) (format "    - %s" (buffer-name b))) coders "\n")
       "    (none)"))))

(define-transient-command antigravity-manager-menu ()
  "Antigravity Agent Manager Mission Control."
  ["Antigravity Mission Control"
   ["Active Agents"
    (antigravity--format-agent-list)]
   ["Actions"
    ("s" "Spawn Chat Agent" gptel)
    ("c" "Spawn Chat (Gemini CLI)" antigravity-spawn-gemini-cli)
    ("a" "Spawn Aider (Coder)" aidermacs-transient-menu)
    ("A" "Spawn Architect" antigravity-spawn-architect)
    ("k" "Kill Agent" antigravity-kill-agent-menu)]])

(define-transient-command antigravity-kill-agent-menu ()
  "Select an agent to kill."
  :setup-children (lambda (_)
                    (let ((buffers (append (antigravity--list-gptel-buffers)
                                           (antigravity--list-aider-sessions))))
                      (transient-parse-suffixes 
                       'antigravity-kill-agent-menu
                       (mapcar (lambda (b)
                                 (list (buffer-name b)
                                       (buffer-name b)
                                       `(lambda () (interactive) (antigravity-kill-agent ,b))))
                               buffers)))))

;;; Auth Utils

(defun antigravity-get-google-token ()
  "Fetch Google Cloud access token via CLI."
  (let ((gcloud-cmd (or (executable-find "gcloud")
                        (expand-file-name "~/google-cloud-sdk/bin/gcloud"))))
    (if (and gcloud-cmd (file-executable-p gcloud-cmd))
        (string-trim (shell-command-to-string (format "%s auth print-access-token" gcloud-cmd)))
      (error "Antigravity: gcloud not found!"))))

;;; Doctor

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

(provide 'antigravity)
;;; antigravity.el ends here
