; -*- Mode: Scheme; Syntax: Scheme; Package: Scheme; -*-
; Copyright (c) 1993-2004 by Richard Kelsey and Jonathan Rees. See file COPYING.

;;;; Data representations

; This implementation of the data representations is particularly
; tuned for byte-addressable machines with 4 bytes per word.
; Good representations for other kinds of machines would necessarily
; look quite different; e.g. on a word-addressed machine you might
; want to put tag bits in the high end of a word, or even go to some
; kind of BIBOP system.

; Fundamental parameters

(define bits-per-byte 8)
(define bytes-per-cell 4)
(define bits-per-cell (* bits-per-byte bytes-per-cell))

(define (bytes->cells bytes)
  ; using shift instead of quotient for speed
  ; (quotient (+ bytes (- bytes-per-cell 1)) bytes-per-cell)
  (arithmetic-shift-right (+ bytes (- bytes-per-cell 1))
			  2))  ; log(bytes-per-cell)

(define (cells->bytes cells)
  (* cells bytes-per-cell))

; Addresses
;
;  An "addressing unit" is the smallest quantum of storage addressed by
;  an address on a particular machine.  On a DEC-20, 3600, or other
;  word-addressed architecture there is one addressing unit per cell.  On
;  the VAX or 68000, though, the addressing unit is the byte, of which there
;  are 4 to a cell.
;
;  Note: by a "byte" is meant enough bits to store either a character or
;  a bytecode.  That probably means either 7, 8, or 9 bits.
;
;  If the addressing unit is smaller than a cell each address will have some
;  number of "unused bits" at its low end.  On a byte-addressable machine with
;  32 bit addresses, there are two.

(define unused-field-width 2)

(define addressing-units-per-cell 4)

(define (cells->a-units cells)
  (adjoin-bits cells 0 unused-field-width))

(define (a-units->cells cells)
  (high-bits cells unused-field-width))

(define (bytes->a-units byte-count)
  (cells->a-units (bytes->cells byte-count)))

; Descriptors
;  A descriptor describes a Scheme object.
;  A descriptor is represented as an integer whose low two bits are
;  tag bits.  The high bits contain information whose format and
;  meaning are dependent on the tag.

(define tag-field-width 2)
(define data-field-width (- bits-per-cell tag-field-width))

(define (make-descriptor tag data)
  (adjoin-bits data tag tag-field-width))

(define (descriptor-tag descriptor)
  (low-bits descriptor tag-field-width))

(define (descriptor-data descriptor)
  (high-bits descriptor tag-field-width))

(define (unsigned-descriptor-data descriptor)
  (unsigned-high-bits descriptor tag-field-width))

(define (set-descriptor-tag proto-descriptor tag)
  (assert (= 0 (descriptor-tag proto-descriptor)))
  (+ proto-descriptor tag))

(define vm-eq? =)

; The four tags are: fixnum, immediate (character, boolean, etc.),
; header (gives the type and size of a stored object), and stored
; (pointer into memory).
; The header and immediate tags could be multiplexed, thus freeing up
; one of the 4 type codes for some other purpose, but the
; implementation is simpler if they're not.

(define-enumeration tag
  (fixnum
   immediate
   header
   stob))

;; (assert (>= (shift-left 1 tag-field-width)
;;             (vector-length tag)))

(define (fixnum? descriptor)
  (= (descriptor-tag descriptor) (enum tag fixnum)))

(define (immediate? descriptor)
  (= (descriptor-tag descriptor) (enum tag immediate)))

(define (header? descriptor)
  (= (descriptor-tag descriptor) (enum tag header)))

(define (stob? descriptor)
  (= (descriptor-tag descriptor) (enum tag stob)))

; Fixnums

(define bits-per-fixnum
  (- (if (< bits-per-cell useful-bits-per-word)
          bits-per-cell
          useful-bits-per-word)
      tag-field-width))

(define    least-fixnum-value (- 0 (shift-left 1 (- bits-per-fixnum 1))))
(define greatest-fixnum-value (-   (shift-left 1 (- bits-per-fixnum 1)) 1))

(define (too-big-for-fixnum? n)
  (> n greatest-fixnum-value))

(define (too-small-for-fixnum? n)
  (< n least-fixnum-value))

(define (enter-fixnum n)
  (assert (not (or (too-big-for-fixnum? n)
		   (too-small-for-fixnum? n))))
  (make-descriptor (enum tag fixnum) n))

(define (extract-fixnum p)
  (assert (fixnum? p))
  (descriptor-data p))

(define (descriptor->fixnum p)
  (enter-fixnum (descriptor-data p)))

(define (fixnum->stob p)
  (make-descriptor (enum tag stob) (extract-fixnum p)))

; These happen to work out, given our representation for fixnums.
(define fixnum= =)
(define fixnum< <)
(define fixnum> >)
(define fixnum<= <=)
(define fixnum>= >=)

(define (fixnum-bitwise-not x)
  (bitwise-not (bitwise-ior x 3)))
(define fixnum-bitwise-and bitwise-and)
(define fixnum-bitwise-ior bitwise-ior)
(define fixnum-bitwise-xor bitwise-xor)

;----------------
; Immediates
;  The number 8 is chosen to streamline 8-bit-byte-oriented implementations.

(define immediate-type-field-width
  (- 8 tag-field-width))

(define (make-immediate type info)
  (make-descriptor (enum tag immediate)
                   (adjoin-bits info type immediate-type-field-width)))

(define (immediate-type imm)
  (assert (immediate? imm))
  (low-bits (descriptor-data imm)
             immediate-type-field-width))

(define (immediate-info imm)
  (assert (immediate? imm))
  (high-bits (descriptor-data imm)
              immediate-type-field-width))

(define (tag&immediate-type descriptor)
  (low-bits descriptor (+ tag-field-width immediate-type-field-width)))

(define (make-tag&immediate-type type)
  (adjoin-bits type (enum tag immediate) tag-field-width))

(define-enumeration imm
  (false      ; #f
   true       ; #t
   char
   unspecific
   undefined
   eof
   null
   unreleased))

;; (assert (>= (shift-left 1 immediate-type-field-width)
;;             (vector-length imm)))

(define (immediate-predicate type)
  (lambda (descriptor)
    ;; Check low 8 bits...
    (= (tag&immediate-type descriptor)
	(make-tag&immediate-type type))))

(define vm-char?   (immediate-predicate (enum imm char)))
(define undefined? (immediate-predicate (enum imm undefined)))

(define true          (make-immediate (enum imm true) 0))
(define false         (make-immediate (enum imm false) 0))
(define eof-object    (make-immediate (enum imm eof)  0))
(define null          (make-immediate (enum imm null) 0))
(define unspecific-value  (make-immediate (enum imm unspecific) 0))
(define quiescent         (make-immediate (enum imm undefined) 0))
(define unbound-marker    (make-immediate (enum imm undefined) 1))
(define unassigned-marker (make-immediate (enum imm undefined) 2))
(define unreleased-value  (make-immediate (enum imm unreleased) 0))

(define (false? x)
  (vm-eq? x false))

(define (enter-boolean b)
  (if b true false))

(define (extract-boolean b)
  (assert (vm-boolean? b))
  (if (false? b) #f #t))

(define (vm-boolean? x)
  (or (vm-eq? x false)
      (vm-eq? x true)))

; Characters

(define (enter-char c)
  (make-immediate (enum imm char) (char->ascii c)))

(define (extract-char d)
  (assert (vm-char? d))
  (ascii->char (immediate-info d)))

; these work given the representations
(define vm-char=? =)
(define vm-char<? <)

; Headers

(define header-type-field-width (- immediate-type-field-width 1))

(define header-size-field-width (- data-field-width immediate-type-field-width))

; Assumes headers sizes are extracted as unsigned.

(define max-stob-contents-size-in-cells
  (bytes->cells (- (shift-left 1 header-size-field-width) 1)))

(define (make-header type length-in-bytes)
  (make-descriptor (enum tag header)
		   (adjoin-bits length-in-bytes
				type
				(+ 1 header-type-field-width))))

(define header-immutable-bit-mask
  (adjoin-bits 1 0 (+ header-type-field-width tag-field-width)))

(define (make-header-immutable header)
  (bitwise-ior header header-immutable-bit-mask))

(define (header-type h)
  (assert (header? h))
  (low-bits (descriptor-data h)
	    header-type-field-width))

(define (immutable-header? h)
  (assert (header? h))
  (not (= 0 (bitwise-and h header-immutable-bit-mask))))

(define (header-length-in-bytes h)
  (assert (header? h))
  (unsigned-high-bits (unsigned-descriptor-data h)
		      (+ 1 header-type-field-width)))

(define (header-length-in-cells header)
  (bytes->cells (header-length-in-bytes header)))

(define (header-length-in-a-units h)
  (cells->a-units (header-length-in-cells h)))

(define (d-vector-header? h)
  (< (header-type h) least-b-vector-type))

(define (b-vector-header? h)
  (and (header? h)
       (>= (header-type h) least-b-vector-type)))

; Stored objects
;  The data field of a descriptor for a stored object contains the
;  cell number of the first cell after the object's header cell.

(define (add-stob-tag address-as-integer)
  (set-descriptor-tag address-as-integer (enum tag stob)))

(define (remove-stob-tag stob)
  (- stob (enum tag stob)))

;----------------
; Kali only code:
; For encode/decode

(define element-type-field-width
  (- 8 tag-field-width))

(define (make-element type info)
  (make-descriptor (enum tag stob)
                   (adjoin-bits info type element-type-field-width)))

(define (element-type element)
  (assert (stob? element))
  (low-bits (descriptor-data element)
	    element-type-field-width))

(define (element-info element)
  (assert (stob? element))
  (high-bits (descriptor-data element)
              element-type-field-width))

; end Kali code
