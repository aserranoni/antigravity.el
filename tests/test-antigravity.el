;;; test-antigravity.el --- Tests for antigravity.el -*- lexical-binding: t; -*-

(require 'ert)
(require 'antigravity)

(ert-deftest antigravity-load-test ()
  "Ensure antigravity feature is provided."
  (should (featurep 'antigravity)))

(ert-deftest antigravity-functions-exist-test ()
  "Ensure main functions are defined."
  (should (fboundp 'antigravity-manager-menu))
  (should (fboundp 'antigravity-spawn-architect))
  (should (fboundp 'antigravity-spawn-gemini-cli))
  (should (fboundp 'antigravity-doctor)))

(provide 'test-antigravity)
;;; test-antigravity.el ends here
