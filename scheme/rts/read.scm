; -*- Mode: Scheme; Syntax: Scheme; Package: Scheme; -*-
; Copyright (c) 1993-2005 by Richard Kelsey and Jonathan Rees. See file COPYING.


; A little Scheme reader.

; Nonstandard things used:
;  ASCII stuff: ascii-whitespaces
;    (for dispatch table; portable definition in alt/ascii.scm)
;  Unicode: char->scalar-value, scalar-value->char
;  reverse-list->string  -- ok to define as follows:
;    (define (reverse-list->string l n)
;      (list->string (reverse l)))
;  make-immutable! -- ok to define as follows:
;    (define (make-immutable! x) x)
;  signal (only for use by reading-error; easily excised)


(define (read . port-option)
  (let ((port (input-port-option port-option)))
    (let loop ()
      (let ((form (sub-read port)))
        (cond ((not (reader-token? form))
	       form)
              ((eq? form close-paren)
               ;; Too many right parens.
	       (warn "discarding extraneous right parenthesis" port)
               (loop))
	      (else
	       (reading-error port (cdr form))))))))

(define (sub-read-carefully port)
  (let ((form (sub-read port)))
    (cond ((eof-object? form)
           (reading-error port "unexpected end of file"))
	  ((reader-token? form) (reading-error port (cdr form)))
	  (else form))))

(define reader-token-marker (list 'reader-token))
(define (make-reader-token message) (cons reader-token-marker message))
(define (reader-token? form)
  (and (pair? form) (eq? (car form) reader-token-marker)))

(define close-paren (make-reader-token "unexpected right parenthesis"))
(define dot         (make-reader-token "unexpected \" . \""))


; Main dispatch

(define *dispatch-table-limit* 128)

(define read-dispatch-vector
  (make-vector *dispatch-table-limit*
               (lambda (c port)
                 (reading-error port "illegal character read" c))))

(define read-terminating?-vector
  (make-vector *dispatch-table-limit* #t))

(define (set-standard-syntax! char terminating? reader)
  (vector-set! read-dispatch-vector     (char->scalar-value char) reader)
  (vector-set! read-terminating?-vector (char->scalar-value char) terminating?))

(define (sub-read port)
  (let ((c (read-char port)))
    (if (eof-object? c)
        c
	(let ((scalar-value (char->scalar-value c)))
	  (cond
	   ((< scalar-value *dispatch-table-limit*)
	    ((vector-ref read-dispatch-vector (char->scalar-value c))
	     c port))
	   ((char-alphabetic? c)
	    (sub-read-constituent c port))
	   (else
	    (reading-error port "illegal character read" c)))))))

(let ((sub-read-whitespace
       (lambda (c port)
         c                              ;ignored
         (sub-read port))))
  (for-each (lambda (c)
              (vector-set! read-dispatch-vector c sub-read-whitespace))
            ascii-whitespaces))

(define (sub-read-constituent c port)
  (parse-token (sub-read-token c port) port))

(for-each (lambda (c)
	    (set-standard-syntax! c #f sub-read-constituent))
	  (string->list
	   (string-append "!$%&*+-./0123456789:<=>?@^_~ABCDEFGHIJKLM"
			  "NOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")))

; Usual read macros

(define (set-standard-read-macro! c terminating? proc)
  (set-standard-syntax! c terminating? proc))

(define (sub-read-list c port)
  (let ((form (sub-read port)))
    (if (eq? form dot)
	(reading-error port
		       "missing car -- ( immediately followed by .")
	(let recur ((form form))
	  (cond ((eof-object? form)
		 (reading-error port
				"end of file inside list -- unbalanced parentheses"))
		((eq? form close-paren) '())
		((eq? form dot)
		 (let* ((last-form (sub-read-carefully port))
			(another-form (sub-read port)))
		   (if (eq? another-form close-paren)
		       last-form
		       (reading-error port
				      "randomness after form after dot"
				      another-form))))
		(else
		 (cons form (recur (sub-read port)))))))))

(set-standard-read-macro! #\( #t sub-read-list)

(set-standard-read-macro! #\) #t
  (lambda (c port)
    c port
    close-paren))

(set-standard-read-macro! #\' #t
  (lambda (c port)
    c
    (list 'quote (sub-read-carefully port))))

(set-standard-read-macro! #\` #t
  (lambda (c port)
    c
    (list 'quasiquote (sub-read-carefully port))))

(set-standard-read-macro! #\, #t
  (lambda (c port)
    c
    (let* ((next (peek-char port))
	   ;; DO NOT beta-reduce!
	   (keyword (cond ((eof-object? next)
			   (reading-error port "end of file after ,"))
			  ((char=? next #\@)
			   (read-char port)
			   'unquote-splicing)
			  (else 'unquote))))
      (list keyword
            (sub-read-carefully port)))))

; Don't use non-R5RS char literals to avoid bootstrap circularities

(define *nul* (scalar-value->char 0))
(define *alarm* (scalar-value->char 7))
(define *backspace* (scalar-value->char 8))
(define *tab* (scalar-value->char 9))
(define *linefeed* (scalar-value->char 10))
(define *vtab* (scalar-value->char 11))
(define *page* (scalar-value->char 12))
(define *return* (scalar-value->char 13))
(define *escape* (scalar-value->char 27))
(define *rubout* (scalar-value->char 127))

(set-standard-read-macro! #\" #t
  (lambda (c port)
    c ;ignored
    (let loop ((l '()) (i 0))
      (let ((c (read-char port)))
        (cond ((eof-object? c)
               (reading-error port "end of file within a string"))
              ((char=? c #\\)
	       (loop (cons (decode-escape port) l) (+ i 1)))
              ((char=? c #\")
	       (reverse-list->string l i))
              (else
	       (loop (cons c l) (+ i 1))))))))

(define (decode-escape port)
  (let ((c (read-char port)))
    (if (eof-object? c)
	(reading-error port "end of file within a string"))
    (let ((scalar-value (char->scalar-value c)))
      (cond
       ((or (char=? c #\\) (char=? c #\")
	    (char=? c #\') (char=? c #\newline)) ; proposed for R6RS
	c)
       ;; these are all from Matthew Flatt's proposal for R6RS
       ((char=? c #\a) *alarm*)
       ((char=? c #\b) *backspace*)
       ((char=? c #\t) *tab*)
       ((char=? c #\n) *linefeed*)
       ((char=? c #\v) *vtab*)
       ((char=? c #\f) *page*)
       ((char=? c #\r) *return*)
       ((char=? c #\e) *escape*)
       ((char=? c #\x)
	(let ((digit0 (read-char port))
	      (digit1 (read-char port)))
	  (if (or (eof-object? digit0)
		  (eof-object? digit1))
	      (reading-error port "end of file within a string"))
	  (cond
	   ((string->number (string digit0 digit1) 16)
	    => scalar-value->char)
	   (else
	    (reading-error port
			   "invalid hexadecimal escape sequence within a string")))))

       ((or (char=? c #\u)
	    (char=? c #\U))
	(decode-hex-char-literal c port "string"))

       ((octal-digit? c)
	(if (octal-digit? (peek-char port))
	    (let ((digit1 (read-char port)))
	      (if (octal-digit? (peek-char port))
		  (let* ((digit2 (read-char port))
			 (n (string->number (string c digit1 digit2) 8)))
		    (if (<= n #o377)
			(scalar-value->char n)
			(reading-error port
				       "invalid octal escape sequence within a string (>#o377)")))
		  (scalar-value->char (string->number (string c digit1) 8))))
	    (scalar-value->char (- scalar-value 48))))
       (else
	(reading-error port
		       "invalid escaped character in string"
		       c))))))

(define (octal-digit? c)
  (and (not (eof-object? c))
       (let ((scalar-value (char->scalar-value c)))
	 (and (>= scalar-value 48)	; #\0
	      (<= scalar-value 55)))))	; #\7

; The \u / \U syntax is shared between character and string literals

(define (decode-hex-char-literal c port desc)
  (cond
   ((char=? c #\u)
    (decode-hex-digits port 4 desc))
   ((char=? c #\U)
    (decode-hex-digits port 6 desc))))

(define (decode-hex-digits port max-digit-count desc)
  (let loop ((rev-digits '()) (count 0))

    (define (return)
      (scalar-value->char
       (string->number (list->string (reverse rev-digits)) 16)))

    (if (>= count max-digit-count)
	(return)
	(let ((c (peek-char port)))
	  (cond
	   ((eof-object? c)
	    (if (null? rev-digits)
		(reading-error port
			       (string-append "end of file within a " desc))
		(return)))
	   ((not (char-hex-digit? c))
	    (if (null? rev-digits)
		(reading-error port
			       (string-append "invalid hex digit in a " desc)
			       c)
		(return)))
	   (else
	    (read-char port)
	    (loop (cons c rev-digits) (+ 1 count))))))))

(define (char-hex-digit? c)
  (let ((scalar-value (char->scalar-value c)))
    (or (and (>= scalar-value 48)	; #\0
	     (<= scalar-value 57))	; #\9
	(and (>= scalar-value 65)	; #\A
	     (<= scalar-value 70))	; #\F
	(and (>= scalar-value 97)	; #\a
	     (<= scalar-value 102)))))	; #\f

(set-standard-read-macro! #\; #t
  (lambda (c port)
    c ;ignored
    (gobble-line port)
    (sub-read port)))

(define (gobble-line port)
  (let loop ()
    (let ((c (read-char port)))
      (cond ((eof-object? c) c)
	    ((char=? c #\newline) #f)
	    (else (loop))))))

(define *sharp-macros* '())

(define (define-sharp-macro c proc)
  (set! *sharp-macros* (cons (cons c proc) *sharp-macros*)))

(set-standard-read-macro! #\# #f
  (lambda (c port)
    c ;ignored
    (let* ((c (peek-char port))
	   (c (if (eof-object? c)
		  (reading-error port "end of file after #")
		  (char-downcase c)))
	   (probe (assq c *sharp-macros*)))
      (if probe
	  ((cdr probe) c port)
	  (reading-error port "unknown # syntax" c)))))

(define-sharp-macro #\f
  (lambda (c port) (read-char port) #f))

(define-sharp-macro #\t
  (lambda (c port) (read-char port) #t))

; These are from Matthew Flatt's Unicode proposal for R6RS
; See write.scm.

; Richard will hopefully provide a fancy version of this that provides
; all the names in the Unicode character database.

(define *char-name-table*
  (list
   (cons 'space #\space)
   (cons 'newline #\newline)
   (cons 'nul *nul*)
   (cons 'alarm *alarm*)
   (cons 'backspace *backspace*)
   (cons 'tab *tab*)
   (cons 'linefeed *linefeed*)
   (cons 'vtab *vtab*)
   (cons 'page *page*)
   (cons 'return *return*)
   (cons 'escape *escape*)
   (cons 'rubout *rubout*)))

(define-sharp-macro #\\
  (lambda (c port)
    (read-char port)
    (let ((c (peek-char port)))
      (cond ((eof-object? c)
	     (reading-error port "end of file after #\\"))

	    ((and (or (char=? #\u c) (char=? #\U c)))
	     (read-char port)
	     (if (delimiter? (peek-char port))
		 c
		 (decode-hex-char-literal c port "char literal")))

	    ((octal-digit? c)
	     (read-char port)
	     (if (delimiter? (peek-char port))
		 c
		 (let ((digit1 (read-char port))
		       (digit2 (read-char port)))
		   (if (or (eof-object? digit1)
			   (eof-object? digit2))
		       (reading-error port
				      "unexpected end of file within a octal char literal"))
		   (let ((n (string->number (string c digit1 digit2) 8)))
		     (if (<= n #o377)
			 (scalar-value->char n)
			 (reading-error port
					"invalid octal char literal (>#o377)"))))))

	    ((char-alphabetic? c)
	     (let ((name (sub-read-carefully port)))
	       (cond ((= (string-length (symbol->string name)) 1)
		      c)
		     ((assq name *char-name-table*)
		      => cdr)
		     (else
		      (reading-error port "unknown #\\ name" name)))))

	    (else
	     (read-char port)
	     c)))))

(define-sharp-macro #\(
  (lambda (c port)
    (read-char port)
    (let ((elts (sub-read-list c port)))
      (if (proper-list? elts)
	  (list->vector elts)
	  (reading-error port "dot in #(...)")))))

(define (proper-list? x)
  (cond ((null? x) #t)
	((pair? x) (proper-list? (cdr x)))
	(else #f)))

(let ((number-sharp-macro
       (lambda (c port)
	 (let ((string (sub-read-token #\# port)))
	   (or (string->number string)
	       (reading-error port "unsupported number syntax" string))))))
  (for-each (lambda (c)
	      (define-sharp-macro c number-sharp-macro))
	    '(#\b #\o #\d #\x #\i #\e)))

; Tokens

(define (sub-read-token c port)
  (let loop ((l (list (preferred-case c))) (n 1))
    (let ((c (peek-char port)))
      (cond ((or (eof-object? c)
		  (and (< (char->scalar-value c) *dispatch-table-limit*)
		       (vector-ref read-terminating?-vector (char->scalar-value c))))
             (reverse-list->string l n))
            (else
	     (read-char port)
             (loop (cons (preferred-case c) l)
                   (+ n 1)))))))

(define (parse-token string port)
  (if (let ((c (string-ref string 0)))
	(or (char-numeric? c) (char=? c #\+) (char=? c #\-) (char=? c #\.)))
      (cond ((string->number string))
	    ((member string strange-symbol-names)
	     (string->symbol (make-immutable! string)))
	    ((string=? string ".")
	     dot)
	    (else
	     (reading-error port "unsupported number syntax" string)))
      (string->symbol (make-immutable! string))))

(define strange-symbol-names
  '("+" "-" "..."
	"1+" "-1+"  ;Only for S&ICP support
	"->"	    ;Only for JAR's thesis
	))

(define (delimiter? c)
  (or (char-whitespace? c)
      (char=? c #\))
      (char=? c #\()
      (char=? c #\")
      (char=? c #\;)))

;--- This loses because the compiler won't in-line it.
; and it's in READ's inner loop.

(define preferred-case
  (if (char=? (string-ref (symbol->string 't) 0) #\T)
      char-upcase
      char-downcase))

; For ASCII, we previously had this hand-hacked version,

; (define p-c-v (make-string ascii-limit #\0))
; 
; (let ((p-c (if (char=? (string-ref (symbol->string 't) 0) #\T)
;                char-upcase
;                char-downcase)))
;   (do ((i 0 (+ i 1)))
;       ((>= i ascii-limit))
;     (string-set! p-c-v i (p-c (ascii->char i)))))
; 
; (define (preferred-case c)
;   (string-ref p-c-v (char->ascii c)))

; Reader errors

(define (reading-error port message . irritants)
  (apply signal 'read-error message
	 (append irritants (list port))))
