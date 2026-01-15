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
         :desc "Mission Control" "m" #'antigravity-manager-menu
         :desc "Antigravity (Aider)" "a" #'aidermacs-transient-menu
         :desc "Antigravity Chat" "c" #'gptel
         :desc "Gemini CLI" "C" #'antigravity-spawn-gemini-cli)))
```
