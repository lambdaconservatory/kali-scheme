; Copyright (c) 1993-2001 by Richard Kelsey and Jonathan Rees. See file COPYING.

(define-interface posix-files-interface
  (export directory-stream?
	  open-directory-stream		; name -> directory
	  read-directory-stream		; directory -> name or #f
	  close-directory-stream	; directory -> ()
	  list-directory		; name -> list of names

	  working-directory
	  set-working-directory!

	  open-file

	  (file-options :syntax)
	  file-options-on?

	  make-directory
	  make-fifo

	  link
	  unlink
	  remove-directory
	  rename

	  get-file-info get-file/link-info get-port-info

	  file-info?
	  file-info-name
	  file-info-type
	  file-info-device
	  file-info-inode
	  file-info-mode
	  file-info-link-count
	  file-info-owner
	  file-info-group
	  file-info-size
	  file-info-last-access
	  file-info-last-modification
	  file-info-last-status-change
	  
	  file-type? file-type-name
	  (file-type :syntax)

	  set-file-creation-mask!

	  file-mode?
	  (file-mode :syntax)
	  file-mode+ file-mode-
	  file-mode=? file-mode<=? file-mode>=?
	  file-mode->integer integer->file-mode

	  accessible?
	  (access-mode :syntax)
	  ))

(define-interface posix-time-interface
  (export make-time time? time-seconds
	  time=? time<? time<=? time>? time>=?
	  time->string
	  current-time
	  ))

(define-interface posix-users-interface
  (export user-id?
	  user-id->integer integer->user-id
	  user-id=?

	  user-info?
	  user-info-name user-info-id user-info-group
	  user-info-home-directory user-info-shell
	  user-id->user-info
	  name->user-info

	  group-id?
	  group-id->integer integer->group-id
	  group-id=?

	  group-info?
	  group-info-name group-info-id group-info-members
	  group-id->group-info
	  name->group-info
	  ))

(define-structures ((posix-files posix-files-interface)
		    (posix-time  posix-time-interface)
		    (posix-users posix-users-interface))
  (open scheme define-record-types finite-types
	external-calls
	external-util
	bitwise			;for manipulating protection masks
	signals			;call-error
	posix-file-options
	channel-i/o
	channel-ports)
  (for-syntax (open scheme bitwise))
  (files dir))

(define-structure posix-file-options (export ((file-option file-options)
					        :syntax)
					     file-options?
					     file-options-on?)
  (open scheme define-record-types finite-types
	external-calls
	bitwise)
  (files file-options))

(define-interface posix-process-data-interface
  (export get-process-id get-parent-process-id
	  
	  ; I am not happy with these names.  They don't mention the process.
	  get-user-id get-effective-user-id set-user-id!
	  get-group-id get-effective-group-id set-group-id!

	  get-groups
	  get-login-name

	  lookup-environment-variable
	  environment-alist
	  ))

(define-interface posix-platform-names-interface
  (export os-name os-node-name os-release-name os-version-name
	  machine-name))

(define-structures ((posix-process-data posix-process-data-interface)
		    (posix-platform-names posix-platform-names-interface))
  (open scheme define-record-types external-calls
	interrupts
	posix-processes posix-users posix-time) ; we need these to be loaded
  (files proc-env))

(define-interface posix-processes-interface
  (export process-id?
	  process-id=?

	  process-id->integer
	  integer->process-id

	  process-id-exit-status
	  process-id-terminating-signal

	  fork
	  fork-and-forget
	  
	  exec
	  exec-with-environment
	  exec-file
	  exec-file-with-environment
	  exec-with-alias

	  exit

	  wait-for-child-process

	  signal-process
	  
	  (signal :syntax)
	  signal-name
	  signal-os-number
	  integer->signal
	  name->signal

	  make-signal-queue
	  dequeue-signal!
	  maybe-dequeue-signal!
	  signal-queue-signals
	  add-signal-queue-signal!
	  remove-signal-queue-signal!
	  ))

(define-structure posix-processes posix-processes-interface
  (open scheme define-record-types finite-types external-calls
	interrupts
	placeholders
	weak
	value-pipes
	debug-messages
	session-data
	signals			;call-error
	root-scheduler		;scheme-exit-now
	channel-ports		;force-channel-output-ports!
	interrupts		;set-interrupt-handler!
	architecture)		;interrupts enum
  (files proc
	 signal))

(define-interface posix-i/o-interface
  (export open-pipe

	  dup
	  dup-switching-mode
	  dup2
	  remap-file-descriptors!
	  close-all-but
	  
	  close-on-exec?
	  set-close-on-exec?!

	  i/o-flags
	  set-i/o-flags!

	  fd-port?
	  port->fd

	  port-is-a-terminal?
	  port-terminal-name
	  ))

(define-structure posix-i/o posix-i/o-interface
  (open scheme
	external-calls
	i/o			;read-block
	channels
	channel-i/o
	channel-ports
	signals			;call-error
	util
	posix-file-options
	ports			;port?
	architecture
	enum-case)
  (files io))

(define-interface posix-regexps-interface
  (export make-regexp
	  (regexp-option :syntax)
	  regexp?
	  regexp-match

	  match?
	  match-start
	  match-end
	  match-submatches
	  ))

(define-structures ((posix-regexps posix-regexps-interface)
		    (posix-regexps-internal (export make-match)))
  (open scheme define-record-types finite-types external-calls
	signals
	external-util)
  (files regexp))

(define-interface regexps-interface
  (export set
	  range ranges
	  ascii-range ascii-ranges

	  negate intersection union subtract

	  lower-case upper-case alphabetic
	  numeric hexdigit
	  alphanumeric
	  punctuation whitespace
	  graphic printing
	  control

	  sequence one-of text repeat

	  ignore-case use-case

	  submatch no-submatches

	  any-match? exact-match?
	  match 

	  match?
	  match-start match-end match-submatches))

(define-structure regexps regexps-interface
  (open scheme define-record-types mvlet ascii signals
	bitwise bigbit
	reduce
	(modify posix-regexps (rename (make-regexp make-posix-regexp)))
	posix-regexps-internal
	util)			;every
  (optimize auto-integrate)
  (files func-regexp))

; All in one chunk.

(define-structure posix (compound-interface
			  (interface-of posix-processes)
			  (interface-of posix-process-data)
			  (interface-of posix-platform-names)
			  (interface-of posix-files)
			  (interface-of posix-i/o)
			  (interface-of posix-time)
			  (interface-of posix-users)
			  (interface-of posix-regexps))
  (open posix-processes
	posix-process-data
	posix-platform-names
	posix-files
	posix-i/o
	posix-time
	posix-users
	posix-regexps))

(define-structure external-util (export immutable-copy-string)
  (open scheme
	primitives	;copy-bytes!
	features)	;immutable? make-immutable!
  (begin
    (define (immutable-copy-string string)
      (if (immutable? string)
	  string
	  (let ((copy (copy-string string)))
	    (make-immutable! copy)
	    copy)))

    ; Why isn't this available elsewhere?

    (define (copy-string string)
      (let* ((length (string-length string))
	     (new (make-string length #\?)))
	(copy-bytes! string 0 new 0 length)
	new))))