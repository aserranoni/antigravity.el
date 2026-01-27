;;; test-antigravity.el --- Tests for antigravity.el -*- lexical-binding: t; -*-

(require 'ert)
(require 'antigravity)

(ert-deftest antigravity-load-test ()
  "Ensure antigravity feature is provided."
  (should (featurep 'antigravity)))

(ert-deftest antigravity-functions-exist-test ()
  "Ensure main functions are defined."
  (should (fboundp 'antigravity-mission-control))
  (should (fboundp 'antigravity-refresh-dashboard))
  (should (fboundp 'antigravity-spawn-architect))
  (should (fboundp 'antigravity-spawn-aider))
  (should (fboundp 'antigravity-spawn-gptel))
  (should (fboundp 'antigravity-doctor)))

(ert-deftest antigravity-aliases-test ()
  "Ensure legacy aliases work."
  (should (fboundp 'antigravity-manager-menu)))

(ert-deftest antigravity-dashboard-mode-test ()
  "Test dashboard mode definition."
  (with-temp-buffer
    (antigravity-dashboard-mode)
    (should (eq major-mode 'antigravity-dashboard-mode))
    (should (equal mode-name "Antigravity Mission Control"))))

(ert-deftest antigravity-agent-registry-test ()
  "Test agent registry data structure."
  (should (hash-table-p antigravity--agents))
  (should (fboundp 'antigravity--make-agent))
  (should (fboundp 'antigravity--register-agent)))

(ert-deftest antigravity-make-agent-test ()
  "Test agent plist creation and type inference."
  (let ((buf (get-buffer-create "*test-chat*")))
    (unwind-protect
        (let ((agent (antigravity--make-agent buf 'gptel)))
          (should (eq (plist-get agent :type) :chat)))
      (kill-buffer buf)))
  (let ((buf (get-buffer-create "*test-agent*")))
    (unwind-protect
        (let ((agent (antigravity--make-agent buf 'aidermacs)))
          (should (eq (plist-get agent :type) :agent)))
      (kill-buffer buf))))

(provide 'test-antigravity)
;;; test-antigravity.el ends here
