# Antigravity for Emacs

Antigravity is an agentic AI coding environment for Emacs. It integrates:
- **Aidermacs**: For heavy-lifting coding tasks and git operations.
- **GPTel**: For versatile chat interactions.
- **Gemini CLI**: For direct subscription access.

## Installation

Add this to your `packages.el`:

```elisp
(package! antigravity :recipe (:local-repo "~/dev/antigravity"))
;; Dependencies (if not already managed)
(package! aidermacs :recipe (:host github :repo "MatthewZMD/aidermacs"))
(package! gptel)
```

Add this to your `config.el`:

```elisp
(use-package! antigravity
  :config
  (map! :leader
        (:prefix ("a" . "antigravity")
         :desc "Antigravity Menu" "m" #'antigravity-manager-menu
         :desc "Mission Control"  "M" #'antigravity-mission-control
         :desc "Spawn Agent"      "a" #'antigravity-spawn-aider
         :desc "Spawn Architect"  "A" #'antigravity-spawn-architect
         :desc "Spawn Chat"       "c" #'antigravity-spawn-gptel)))
```
