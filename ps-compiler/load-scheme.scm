; Load the Scheme front-end

(config)
(load "interfaces.scm")
(load "package-defs.scm")
(load "scheme-to-c/package-defs.scm")
(load-package 'let-nodes)       ; used in FOR-SYNTAX
(load-package 'simp-patterns)   ; used in FOR-SYNTAX
(load-package 'scheme-test)
