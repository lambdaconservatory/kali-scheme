; Copyright (c) 1993, 1994 by Richard Kelsey and Jonathan Rees.
; Copyright (c) 1996 by NEC Research Institute, Inc.    See file COPYING.
; This file contains the type declarations for the VM's interface to
; unbuffered i/o.  Unbuffered ports are called channels in the VM
; and FD's in the OS.  The external names are unixoid, but the interface
; itself is intended to be portable.

(define current-input-channel
  (external "STDIN_FD" (=> () integer)))

(define current-output-channel
  (external "STDOUT_FD" (=> () integer)))

(define current-error-channel
  (external "STDERR_FD" (=> () integer)))

; Converting between ports and channels.

(define input-port->channel
  (external "fileno" (=> (input-port) integer)))

(define output-port->channel
  (external "fileno" (=> (output-port) integer)))

(define input-channel->port
  (external "PS_INPUT_FDOPEN" (=> (integer) input-port integer)))

(define output-channel->port
  (external "PS_OUTPUT_FDOPEN" (=> (integer) output-port integer)))

; Opening and closing channels

(define open-file-channel
  (external "ps_open_fd" (=> ((^ char) boolean) integer integer)))

(define (open-input-file-channel name)
  (open-file-channel name #t))

(define (open-output-file-channel name)
  (open-file-channel name #f))

(define close-channel
  (external "ps_close_fd" (=> (integer) integer)))

(define close-input-channel close-channel)
(define close-output-channel close-channel)

; Read and writing blocks of data
;
; (channel-read-block channel buffer count wait?)
;       -> char-count eof? pending? status
;
; (channel-write-block channel buffer count)
;       -> char-count eof? pending? status
;
; CHAR-COUNT - the number of characters read/written
; EOF? - char-count is ignored if this is true
; PENDING? - true if the operation cannot complete immediately
; STATUS - from an enumeration defined as part of Pre-Scheme
;
; Pending i/o operations produce i/o-completion events when they're done.

(define channel-read-block
  (external "ps_read_fd"
	    (=> (integer address integer boolean) integer boolean boolean integer)))

(define channel-write-block
  (external "ps_write_fd"
	    (=> (integer address integer) integer boolean integer)))

(define channel-abort
  (external "ps_abort_fd_op" (=> (integer) integer)))

;----------------------------------------------------------------
; Asynchronous external events

; The different kinds of events

(define-external-enumeration events
  (keyboard-interrupt-event     ; user interrupt
   io-completion-event          ; a pending i/o operation completed
   alarm-event                  ; scheduled interrupt
   error-event                  ; OS error occurred
   no-event                     ; no more pending events
   ))

; Initialize the event system

(define initialize-events
  (external "interrupt_init" (=> () integer)))

; True if an event is pending

(define pending-event?
  (external "pending_eventp" (=> () boolean)))

; Returns the next event.  The second return value is the FD for i/o-completion
; events and the third is the status for i/o-completion and error events.
; (currently this is always zero for i/o-completions).

(define get-next-event
  (external "get_next_event" (=> () integer integer integer)))

; Wait for the next event.  The two arguments are maximum time to wait and
; whether that time is in minutes (#T) or milliseconds (#F).

(define wait-for-event
  (external "wait_for_event" (=> (integer boolean) unit)))


