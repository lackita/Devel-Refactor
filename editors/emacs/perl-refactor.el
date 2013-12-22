(defun perl-refactor-extract-method (method-name start end)
  (interactive "MName: \nr")
  (basic-save-buffer)
  (call-process "/Users/cwilliams/bin/refactor.pl" nil '(nil "*error*") nil
				buffer-file-name
				"extract_method"
				method-name
				(number-to-string (- start 1))
				(number-to-string (- end start)))
  (revert-buffer nil t))

(provide 'perl-refactor)
