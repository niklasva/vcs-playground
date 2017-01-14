;;;
;;; EXAMPLE KERNEL
;;; ORIGINAL CODE PROVIDED BY http://www.randomterrain.com/atari-2600-memories-tutorial-andrew-davie-09.html
;;; Additional annotations and modifications by me
;;;

	processor 6502

	include "vcs.h"
	include "macro.h"

	SEG
	ORG $F000

Reset
StartOfFrame

	; Start of vertical blank processing
	lda #0
	sta VBLANK

	lda #2
	sta VSYNC

	; 3 scanlines of VSYNCH signal...

	sta WSYNC	; wait for horizontal blank
	sta WSYNC
	sta WSYNC

	lda #0
	sta VSYNC

	; 37 scanlines of vertical blank...
	REPEAT 37
		sta WSYNC
	REPEND

	; 192 scanlines of picture...
	ldx #0
	REPEAT 192
		inx			; Increase the value (previously set to 0) in register x
		stx COLUBK	; ...to change the color of the current horizontal line
		sta WSYNC
	REPEND

	lda #%01000010

	sta VBLANK             	; end of screen - enter blanking

	; 30 scanlines of overscan...
	REPEAT 30
		sta WSYNC
	REPEND

	jmp StartOfFrame

	ORG $FFFA

	.word Reset          ; NMI
	.word Reset          ; RESET
	.word Reset          ; IRQ

END
