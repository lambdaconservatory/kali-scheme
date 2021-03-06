; -*- Mode: Scheme; Syntax: Scheme; Package: Scheme; -*-
; Copyright (c) 1993, 1994 by Richard Kelsey and Jonathan Rees.
; Copyright (c) 1996 by NEC Research Institute, Inc.    See file COPYING.

; Somewhat redundant with vm/istruct.scm.  Fix this some day.

; Templates
;  Templates are made only by the compiler.

;(define make-template make-vector)

;(define (template? obj)
;  (and (vector? obj)
;       (>= (vector-length obj) template-overhead)
;       (code-vector? (template-code obj))
;       ))

;(define template-length vector-length)
;(define template-ref vector-ref)
;(define template-set! vector-set!)

(define template-overhead 3)		; Kali modification

(define (template-code     tem) (template-ref tem 0))
(define (template-info     tem) (template-ref tem 1))
(define (template-id       tem) (template-ref tem 2))		      ; Kali code
(define (set-template-code!     tem cv)   (template-set! tem 0 cv))
(define (set-template-info!     tem info) (template-set! tem 1 info))
(define (set-template-id!       tem id)   (template-set! tem 2 id))   ; Kali code

