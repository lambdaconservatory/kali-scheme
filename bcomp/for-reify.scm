; Copyright (c) 1993, 1994 Richard Kelsey and Jonathan Rees.  See file COPYING.

; Things used by the expression returned by REIFY-STRUCTURES.
; Cf. link/reify.scm.

(define (operator name type-exp)
  (get-operator name (sexp->type type-exp #t)))

(define (simple-interface names types)
  (make-simple-interface #f
			 (map (lambda (name type)
				(list name (sexp->type type #t)))
			      (vector->list names)
			      (vector->list types))))

(define (package names locs get-location uid)
  (let ((end (vector-length names))
	(p (make-package list list ;(lambda () '())
			 #f #f "" '()
			 uid #f)))
    (set-package-loaded?! p #t)
    (do ((i 0 (+ i 1)))
	((= i end))
      (let* ((name (vector-ref names i))
	     (probe (package-lookup p name)))
	(if (not (binding? probe))
	    (package-define! p
			     name
			     usual-variable-type  ;May get clobbered later
			     (get-location (vector-ref locs i))))))
    (make-table-immutable! (package-definitions p))
    p))

(define (transform names+proc env type-exp source name)
  (make-transform names+proc env (sexp->type type-exp #t) source name))
