
(define-interface address-space-interface
  (export address-space?
	  address-space<
          socket-id->address-space
	  initialize-local-address-space!
	  local-address-space
	  all-address-spaces
	  initialize-shared-address-space!

	  address-space-ip-address
	  address-space-socket
	  address-space-uid
	  address-space-lock
	  address-space-decode-vector set-address-space-decode-vector!
	  address-space-proxy-vector set-address-space-proxy-vector!
	  address-space-pending-vector set-address-space-pending-vector!
	  address-space-in-channel set-address-space-in-channel!
	  address-space-out-channel set-address-space-out-channel!
	  address-space-placeholder set-address-space-placeholder!
	  ))

(define-structure address-spaces address-space-interface
  (open scheme address-space-internals structure-refs
	define-record-types
	ascii tables
	signals			; error
	architecture		; stob
	templates locations	; set-template-id! set-location-uid!
	interrupts		; with-interrupts-inhibited
	proxy-internals		; set-proxy-uid! set-proxy-owner-uid!
	locks)			; make-lock
  (access primitives)		; vm-extension copy-bytes! find-all-xs encode
  (files aspace))

(define-structure disclose-aspaces (export)
  (open scheme-level-1 methods more-types
	address-spaces)
  (begin
    (define-method &disclose ((obj :address-space))
      (list 'address-space
	    (address-space-ip-address obj)
	    (address-space-socket obj)))))

(define-structure connect (export connection-server
				  send-message send-admin-message)
  (open scheme structure-refs ascii
	code-vectors signals
	address-spaces
	sockets channels
	channel-hacks			; set-tcp-nodelay!
	enumerated enum-case
	message-types
	proxy-count-requests
	placeholders locks
	interrupts			; call-after-gc!
	bitwise				; arithmetic-shift
	conditions handle i/o display-conditions	; dealing with errors
	debug-messages
	threads)			; spawn
  (access primitives			; memory-status encode decode
	  architecture			; memory-status-option
	  disclose-aspaces)		; just to make sure it loads
  (optimize auto-integrate)
  (files connect))

(define-structure message-types (export (message-type :syntax))
  (open scheme enumerated)
  (begin
    (define-enumeration message-type
      (run			; (proc . args)
       apply			; (return-id proc . args)
       results			; (return-id . values)
       uid-request      	; (element-type . uid)*
       uid-reply        	; #(aspace-uid uid element-type contents)
       proxy-counts-request	; proxy-id*
       proxy-counts     	; proxy*
       return-proxy-counts	; (id . counts)*
       drop-proxy-values	; (key . #(aspace-id proxy-id count)*)
       proxy-values-dropped     ; key
       ))))

(define-interface uid-request-interface
  (export wait-for-missing-uids
	  process-uid-replies
	  make-uid-reply))

(define-structure uid-requests uid-request-interface
  (open scheme receiving structure-refs define-record-types signals
	enumerated enum-case architecture
	connect message-types
	closures locations templates
	proxy-internals address-spaces
	;weak
	records			; record?, record-ref (abstraction breaking)
	debug-messages)		; (for debugging)
  (access primitives)
  (optimize auto-integrate)
  (files uid-request))

(define-interface proxy-count-requests-interface
  (export make-proxy-requests
	  make-proxy-rerequests
	  adjust-proxy-counts!
	  proxy-uid->proxy
	  add-proxy-counts!
	  find-dead-proxies))

(define-structure proxy-count-requests proxy-count-requests-interface
  (open scheme define-record-types
	proxy-internals
	address-spaces address-space-internals
	placeholders
	architecture			; max-proxy-count, max-proxy-debit
	weak				; weak-pointer-ref
	signals				; warn
	debug-messages			; for debugging
	interrupts)			; with-interrupts-inhibited
  (optimize auto-integrate)
  (files proxy-count))

(define-structure messages (export remote-run! remote-apply start-server)
  (open scheme
	connect message-types uid-requests
	proxy-count-requests
	signals				; warn
	address-spaces
	enumerated enum-case
	threads	threads-internal
	interrupts			; with-interrupts-inhibited
	proxy-internals			; (for debugging)
	debug-messages			; (for debugging)
	i/o)				; force-output (for debugging)
  (files message))

(define-interface kali-interface
  (export socket-id->address-space
	  address-space?

	  remote-run!
	  remote-apply

	  make-proxy
	  proxy?
	  proxy-owner
	  proxy-local-ref proxy-local-set!
	  proxy-remote-ref proxy-remote-set!
	  any-proxy-value

	  move-to!

	  start-server))

(define-structure kali kali-interface
  (open scheme address-spaces
	messages proxy-internals threads
	fluids-internal)		; current-thread
  (begin
    ; Little proxy utilities.

    (define (proxy-owner proxy)
      (or (proxy-data-owner (proxy-data proxy))
	  (local-address-space)))

    (define (proxy-remote-ref proxy)
      (remote-apply (proxy-owner proxy) proxy-local-ref proxy))

    (define (proxy-remote-set! proxy value)
      (remote-run! (proxy-owner proxy) proxy-local-set! proxy value))

    ; To avoid circular module dependencies we provide PROXY-REMOTE-REF to
    ; the rts low module.
    
    (initialize-any-proxy-value! proxy-remote-ref)
    
    ; Move the current thread to another aspace.
    (define move-to!
      (lambda (aspace)
	(call-with-current-continuation
	  (lambda (k)
	    (remote-run! aspace
			 spawn
			 (lambda ()
			   (k #F))
			 (thread-name (current-thread)))
	    (terminate-current-thread)))))
    ))

; A comrade is a Kali process with no REPL.

(define-structure comrades (export start-comrade)
  (open scheme
	scheduler		; round-robin-event-handler run-threads
	threads-internal	; 	scheduler stuff

	messages		; start-server
	handle			; with-handler
	static-fluid-env	; 	minimize fluid environments
	channels		; open-channel channel-write close-channel
	architecture)		; channel-status-option
   (files comrade))

(define-structure channel-hacks
   (export open-input-channel
	   open-output-channel
	   channel->fd
	   make-channel-non-blocking!
	   fd->input-port
	   fd->output-port
	   set-tcp-nodelay!
	   fd->channels)
   (open scheme
	 architecture
	 channels
	 channel-i/o
	 i/o-internal
	 primitives)
   (optimize auto-integrate)
   (files channel-hacks))

