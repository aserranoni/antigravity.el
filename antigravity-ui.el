;;; antigravity-ui.el --- UI components for Antigravity -*- lexical-binding: t; -*-

;; Author: Ariel Serranoni
;; Keywords: ai, tools, convenience

;;; Commentary:
;; UI components for Antigravity: Mission Control Dashboard and Transient Menu.

;;; Code:

(require 'transient)
(require 'tabulated-list)
(require 'antigravity-core)

;;; Dashboard

(defun antigravity--dashboard-entries ()
  (antigravity--sync-agents)
  (let (entries)
    (maphash (lambda (name agent)
               (let* ((type (plist-get agent :type))
                      (icon (if (eq type :chat) "💬" "🛠️"))
                      (pkg (symbol-name (plist-get agent :package)))
                      (project (or (plist-get agent :project) "-")))
                 (push (list agent 
                             (vector icon
                                     name
                                     (plist-get agent :model)
                                     (if (stringp project) (abbreviate-file-name project) "-")
                                     pkg))
                       entries)))
             antigravity--agents)
    entries))

(define-derived-mode antigravity-dashboard-mode tabulated-list-mode "Antigravity Mission Control"
  "Antigravity Mission Control Dashboard."
  (setq tabulated-list-format [("Type" 6 t)
                               ("Name" 30 t)
                               ("Model" 20 t)
                               ("Project" 40 t)
                               ("Package" 12 t)])
  (setq tabulated-list-padding 2)
  (setq tabulated-list-sort-key '("Type" . nil))
  (use-local-map antigravity-dashboard-mode-map)
  (tabulated-list-init-header))

(defvar antigravity-dashboard-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'antigravity-dashboard-visit)
    (define-key map (kbd "k") 'antigravity-dashboard-kill)
    (define-key map (kbd "g") 'antigravity-refresh-dashboard)
    (define-key map (kbd "s") 'antigravity-spawn-gptel)
    (define-key map (kbd "a") 'antigravity-spawn-aider)
    (define-key map (kbd "c") 'antigravity-spawn-gemini-cli)
    (define-key map (kbd "l") 'antigravity-spawn-llama-chat)
    (define-key map (kbd "L") 'antigravity-spawn-llama-coder)
    (define-key map (kbd "A") 'antigravity-spawn-architect)
    (define-key map (kbd "q") 'quit-window)
    map))

(defun antigravity-dashboard-visit ()
  (interactive)
  (let ((agent (tabulated-list-get-id)))
    (when agent (switch-to-buffer (plist-get agent :buffer)))))

(defun antigravity-dashboard-kill ()
  (interactive)
  (let ((agent (tabulated-list-get-id)))
    (when agent
      (let ((buf (plist-get agent :buffer)))
        (when (buffer-live-p buf)
          (antigravity--unregister-agent buf)
          (kill-buffer buf)
          (antigravity-refresh-dashboard)
          (message "Killed agent: %s" (buffer-name buf)))))))

;;;###autoload
(defun antigravity-refresh-dashboard ()
  "Refresh Mission Control."
  (interactive)
  (with-current-buffer (get-buffer-create "*Antigravity Mission Control*")
    (antigravity-dashboard-mode)
    (setq tabulated-list-entries (antigravity--dashboard-entries))
    (tabulated-list-print t)))

;;;###autoload
(defun antigravity-mission-control ()
  "Open Antigravity Mission Control."
  (interactive)
  (let ((buf (get-buffer-create "*Antigravity Mission Control*")))
    (with-current-buffer buf
      (antigravity-dashboard-mode)
      (antigravity-refresh-dashboard))
    (switch-to-buffer buf)))

;;;###autoload
(transient-define-prefix antigravity-manager-menu ()
  "Antigravity Agent Manager Menu."
  ["Mission Control"
   ("m" "Open Dashboard" antigravity-mission-control)]
  ["Spawn"
   ("c" "Chat (GPTel)" antigravity-spawn-gptel)
   ("a" "Coder (Aider)" antigravity-spawn-aider)
   ("A" "Architect" antigravity-spawn-architect)
   ("l" "Llama Chat" antigravity-spawn-llama-chat)
   ("L" "Llama Coder" antigravity-spawn-llama-coder)
   ("C" "Gemini CLI" antigravity-spawn-gemini-cli)])

(provide 'antigravity-ui)
;;; antigravity-ui.el ends here
