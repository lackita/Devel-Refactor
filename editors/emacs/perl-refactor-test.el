(require 'perl-refactor)

(ert-deftest perl-refactor-extract-method ()
  "Tests integration of the extract method refactoring of Devel::Refactor"
  (let ((file (make-temp-file "perl-refactor-extract-method")))
	(unwind-protect
		(with-temp-buffer
		  (setq buffer-file-name file)
		  (insert "print 'foo';")
		  (goto-char (point-min))
		  (set-mark (point-max))
		  (perl-refactor-extract-method "newSub" (region-beginning) (region-end))
		  (should-not (buffer-modified-p))
		  (should (equal (buffer-string) "newSub ();\n\nsub newSub {\n\tprint 'foo';\n}\n")))
	  (delete-file file))))
