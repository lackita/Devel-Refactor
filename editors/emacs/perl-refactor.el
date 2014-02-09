(require 'ediff)
(require 'ediff-ptch)

(defun perl-refactor-extract-method (method-name start end)
  (interactive "MName: \nr")
  (basic-save-buffer)
  (call-process "refactor.pl" nil '(nil "*error*") nil
				buffer-file-name
				"extract_method"
				method-name
				(number-to-string (- start 1))
				(number-to-string (- end start)))
  (let ((source-file (buffer-file-name)))
	(with-temp-buffer
	  (insert-file-contents-literally "refactor.patch")
	  (let ((patch-dir (current-buffer)))
		(ediff-map-patch-buffer (current-buffer))
		(ediff-dispatch-file-patching-job (current-buffer) source-file)))))

(provide 'perl-refactor)
