;;; antigravity.el --- AI pair programming agent manager -*- lexical-binding: t; -*-

;; Author: Ariel Serranoni
;; Version: 0.2.0
;; Package-Requires: ((emacs "26.1") (gptel "0.1") (aidermacs "0.1") (projectile "2.0") (transient "0.3"))
;; Keywords: ai, tools, convenience

;;; Commentary:
;; Antigravity provides an agentic AI experience inside Emacs.
;; Features a Mission Control dashboard to manage Chat (GPTel) and Coding Agents (Aidermacs/Claude).

;;; Code:

(require 'antigravity-core)
(require 'antigravity-ui)

(provide 'antigravity)
;;; antigravity.el ends here
