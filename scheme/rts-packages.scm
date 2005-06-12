; Copyright (c) 1993-2004 by Richard Kelsey and Jonathan Rees. See file COPYING.


(define-structures ((scheme-level-1 scheme-level-1-interface)
		    (util util-interface))
  (open scheme-level-0 ascii signals
	code-quote)			; needed by SYNTAX-RULES
  (usual-transforms case quasiquote syntax-rules)
  (files (rts base)
	 (rts util)
	 (rts number)
	 (rts lize))	  ; Rationalize
  (optimize auto-integrate))


; "Level 2"

(define-structures ((record-types record-types-interface)
		    (records-internal records-internal-interface))
  (open scheme-level-1 records signals
	primitives)
  (files (rts record))
  (optimize auto-integrate))

; The external code needs this to check the types of records.

(define-structure export-the-record-type (export)
  (open scheme-level-1 records-internal shared-bindings)
  (begin
    (define-exported-binding "s48-the-record-type" :record-type)))

(define-structures ((define-record-types define-record-types-interface)
		    (define-sync-record-types
		      (export (define-synchronized-record-type :syntax))))
  (open scheme-level-1
	records record-types records-internal
	loopholes
	low-proposals	;provisional-checked-record-{ref|set!}
	primitives)	;unspecific
  (files (rts jar-defrecord)))

(define-structures ((methods methods-interface)
		    (meta-methods meta-methods-interface))
  (open scheme-level-1
	define-record-types
	records record-types records-internal
	bitwise util primitives
	signals)
  (files (rts method))
  (optimize auto-integrate))

(define-structure number-i/o number-i/o-interface
  (open scheme-level-1 methods signals ascii)
  (files (rts numio)))

(define-structures ((fluids fluids-interface)
		    (fluids-internal fluids-internal-interface))
  (open scheme-level-1 define-record-types primitives cells)
  (files (rts fluid))
  (optimize auto-integrate))

(define-structure wind wind-interface
  (open scheme-level-1 signals define-record-types
	fluids fluids-internal
	low-proposals
	escapes)
  (files (rts wind))
  (optimize auto-integrate))

(define-structure session-data (export make-session-data-slot!
				       initialize-session-data!
				       session-data-ref
				       session-data-set!)
  (open scheme-level-1
	primitives)
  (files (rts session))
  (optimize auto-integrate))

(define-structures ((i/o i/o-interface)
		    (i/o-internal i/o-internal-interface))
  (open scheme-level-1 signals fluids
	architecture
	primitives
	ports byte-vectors bitwise
	define-record-types ascii
	proposals
	session-data
	debug-messages	; for error messages
	methods         ; &disclose :input-port :output-port
	number-i/o      ; number->string for debugging
	handle		; report-errors-as-warnings
	exceptions)     ; wrong-number-of-args stuff
  (files (rts port)
	 (rts port-buffer)
	 (rts current-port))
  (optimize auto-integrate))

(define-structure channel-i/o channel-i/o-interface
  (open scheme-level-1 byte-vectors cells
	channels
	i/o i/o-internal
	conditions
	(subset threads-internal (maybe-commit-no-interrupts))
	proposals
	condvars condvars-internal
	interrupts
	architecture
	session-data
	debug-messages)	; for error messages
  (files (rts channel)))

(define-structure channel-ports channel-ports-interface
  (open scheme-level-1 byte-vectors define-record-types ascii
	ports
	i/o i/o-internal
	channels channel-i/o
	proposals
	condvars
	signals conditions
	architecture		; channel-opening options
	debug-messages		; for error messages
	(subset util		(unspecific))
	(subset primitives	(add-finalizer!)))
  (files (rts channel-port)))

(define-structure conditions conditions-interface
  (open scheme-level-1 signals
	(subset primitives (os-error-message)))
  (files (rts condition)))

(define-structure keywords keywords-interface
  (open scheme-level-1 define-record-types tables)
  (files (rts keywords)))

(define-structure writing writing-interface
  (open scheme-level-1
	number-i/o
        keywords
	i/o				;output-port-option, write-string
	methods				;disclose
	(subset i/o-internal	(open-output-port?))
	(subset signals		(call-error))
	(subset channels	(channel? channel-id))
	(subset code-vectors	(code-vector?)))
  (files (rts write)))

(define-structure reading reading-interface
  (open scheme-level-1
	number-i/o
        keywords
	i/o		;input-port-option
	ascii		;for dispatch table
	signals		;warn, signal-condition, make-condition
	conditions	;define-condition-type
	primitives	;make-immutable!
	silly)		;reverse-list->string
  (files (rts read))
  (optimize auto-integrate))

(define-structure scheme-level-2 scheme-level-2-interface
  (open scheme-level-1
	number-i/o
	writing
	reading
        keywords
	wind
	i/o
	channel-ports))

(define-structure features features-interface
  (open primitives i/o))

; Hairier stuff now.

(define-structure templates templates-interface
  (open scheme-level-1 primitives methods)
  (files (rts template))
  (optimize auto-integrate))

(define-structure continuations continuations-interface
  (open scheme-level-1 primitives
	architecture code-vectors
	templates closures all-operators
	methods)
  (files (rts continuation))
  (optimize auto-integrate))

(define-structure more-types (export :closure :code-vector :location :double
				     :template :channel :port :weak-pointer
				     :shared-binding :cell
                                     :proxy :proxy-data :address-space) ; Kali code
  (open scheme-level-1 methods
        proxy-internals address-space-internals			; Kali code
 	records	fluids-internal					; Kali code
	closures code-vectors locations cells templates channels ports
	primitives shared-bindings)
  (begin (define-simple-type :closure     (:value) closure?)
	 (define-simple-type :code-vector (:value) code-vector?)
	 (define-simple-type :location    (:value) location?)
	 (define-simple-type :cell        (:value) cell?)
	 (define-simple-type :template    (:value) template?)
	 (define-simple-type :channel     (:value) channel?)
	 (define-simple-type :port        (:value) port?)
	 (define-simple-type :double      (:rational) double?)
	 (define-simple-type :weak-pointer (:value) weak-pointer?)
	 (define-method &disclose ((obj :weak-pointer)) (list 'weak-pointer))
	 (define-simple-type :shared-binding (:value) shared-binding?)
; Begin Kali code
	 (define-simple-type :proxy	  (:value) proxy?)
	 (define-method &disclose ((obj :proxy))
	   (cond ((not (proxy-has-local-value? obj))
		  (list 'proxy (proxy-data-uid (proxy-data obj))))
		 ((or (record-type? obj)
		      (fluid? (proxy-local-ref obj)))
		  (disclose (proxy-local-ref obj)))
		 (else
		  (list 'proxy (proxy-data-uid (proxy-data obj))))))
	 (define-simple-type :address-space (:value) address-space?)
	 (define-simple-type :proxy-data (:value) proxy-data?)
; End Kali code	 
	 (define-method &disclose ((obj :shared-binding))
	   (list (if (shared-binding-is-import? obj)
		     'imported-binding
		     'exported-binding)
		 (shared-binding-name obj)))))

(define-structure enumerated enumerated-interface
  (open scheme-level-1 signals)
  (files (rts defenum scm)))

(define-structure architecture vm-architecture-interface
  (open scheme-level-1 signals enumerated)
  (files (vm/interp arch)))

(define-structure vm-data vm-data-interface
  (open scheme-level-1 enumerated bitwise ascii
        architecture
        (subset signals (error)))
  (begin
    ; Scheme/Pre-Scheme differences
    (define (arithmetic-shift-right n k)
      (arithmetic-shift n (- k)))
    (define shift-left arithmetic-shift)
    
    ; From vm/vm-utilities.scm
    (define (adjoin-bits high low k)
      (+ (arithmetic-shift high k) low))
    
    (define (low-bits n k)
      (bitwise-and n (- (arithmetic-shift 1 k) 1)))
    
    (define high-bits arithmetic-shift-right)
    
    (define unsigned-high-bits high-bits)
    
    (define-syntax assert
      (syntax-rules ()
        ((assert foo) #t)))
    
    ; We just know this.
    (define useful-bits-per-word 32))
  (files (vm/data data)))

(define-structures ((exceptions exceptions-interface)
		    (handle handle-interface))
  (open scheme-level-1
	signals fluids cells
	conditions	  ;make-exception, etc.
	primitives	  ;set-exception-handlers!, etc.
	wind		  ;CWCC
	methods
	meta-methods
	more-types
	architecture
	enumerated
	debug-messages	  ; for printing from last-resort-condition handler
	vm-exposure	  ;primitive-catch
	templates	  ;template-code, template-info
	continuations	  ;continuation-pc, etc.
	locations	  ;location?, location-id
	closures	  ;closure-template
	number-i/o)       ; number->string, for backtrace
  (files (rts exception)))  ; Needs generic, arch

(define-structure interrupts interrupts-interface
  (open scheme-level-1
	signals fluids conditions
	bitwise
	escapes
	session-data
	primitives
	architecture)
  (files (rts interrupt))
  (optimize auto-integrate)) ;mostly for threads package...

(define-structures ((threads threads-interface)
		    (threads-internal threads-internal-interface))
  (open scheme-level-1 enumerated queues cells
	(subset proposals            (define-synchronized-record-type))
	define-record-types
	interrupts
        wind
        fluids
	fluids-internal         ;get-dynamic-env
	proposals		;maybe-commit
        escapes                 ;primitive-cwcc
        conditions              ;error?
        handle                  ;with-handler
        signals                 ;signal, warn, call-error
	loopholes               ;for converting #f to a continuation
	architecture            ;time-option
	session-data
	debug-messages
	(subset primitives	(find-all-records
				 current-thread set-current-thread!
				 unspecific
				 collect
				 time)))
  (optimize auto-integrate)
  (files (rts thread)
	 (rts sleep)))

(define-structure proposals proposals-interface
  (open scheme-level-1 low-proposals
	define-record-types define-sync-record-types
	primitives)		 ;unspecific
  (files (rts proposal)))

(define-structure scheduler scheduler-interface
  (open scheme-level-1 threads threads-internal enumerated enum-case queues
	debug-messages
	signals)       		;error
  (files (rts scheduler)))

(define-structure root-scheduler (export root-scheduler
					 spawn-on-root
					 scheme-exit-now
					 call-when-deadlocked!)
  (open scheme-level-1 threads threads-internal scheduler queues
	session-data
	conditions		;warning?, error?
	writing			;display
	debug-messages		;for debugging
	(subset i/o		(current-error-port newline))
	(subset signals		(error))
	(subset handle		(with-handler))
	(subset i/o-internal	(output-port-forcers output-forcer-id))
	(subset fluids-internal (get-dynamic-env))
	(subset interrupts      (with-interrupts-inhibited
				 all-interrupts
				 set-enabled-interrupts!))
	(subset wind            (call-with-current-continuation))
	(subset channel-i/o	(waiting-for-i/o?
				 initialize-channel-i/o!
				 abort-unwanted-reads!))
	(modify primitives      (rename (wait primitive-wait))
		                (expose wait unspecific)))
  (files (rts root-scheduler)))

(define-structure enum-case (export (enum-case :syntax))
  (open scheme-level-1 enumerated util)
  (begin
    (define-syntax enum-case
      (syntax-rules (else)
	((enum-case enumeration (x ...) clause ...)
	 (let ((temp (x ...)))
	   (enum-case enumeration temp clause ...)))
	((enum-case enumeration value ((name ...) body ...) rest ...)
	 (if (or (= value (enum enumeration name)) ...)
	     (begin body ...)
	     (enum-case enumeration value rest ...)))
	((enum-case enumeration value (else body ...))
	 (begin body ...))
	((enum-case enumeration value)
	 (unspecific))))))

(define-structure queues queues-interface
  (open scheme-level-1 proposals signals)
  (files (big queue))
  (optimize auto-integrate))

; No longer used
;(define-structure linked-queues (compound-interface 
;                                 queues-interface
;                                 (export delete-queue-entry!
;                                         queue-head))
;  (open scheme-level-1 define-record-types signals primitives)
;  (files (big linked-queue))
;  (optimize auto-integrate))

(define-structures ((condvars condvars-interface)
		    (condvars-internal (export condvar-has-waiters?)))
  (open scheme-level-1 queues
	proposals
	threads threads-internal)
  (optimize auto-integrate)
  (files (rts condvar)))

(define-structure usual-resumer (export usual-resumer)
  (open scheme-level-1
	i/o		 ;initialize-i/o, etc.
	channel-i/o      ;initialize-channel-i/o
	channel-ports    ;{in,out}put-channel->port
	session-data     ;initialize-session-data!
	fluids-internal	 ;initialize-dynamic-state!
	exceptions	 ;initialize-exceptions!
	interrupts	 ;initialize-interrupts!
	records-internal ;initialize-records!
	threads-internal ;start threads
	root-scheduler)  ;start a scheduler
  (files (rts init)))

; Weak pointers & populations

(define-structure weak weak-interface
  (open scheme-level-1 signals
	primitives)	;Open primitives instead of loading (alt weak)
  (files ;;(alt weak)   ;Only needed if VM's weak pointers are buggy
	 (rts population)))

; Utility for displaying error messages

(define-structure display-conditions display-conditions-interface
  (open scheme-level-2
	writing
	methods
	handle)			;ignore-errors
  (files (env dispcond)))
