	processor 6502

	include "vcs.h"

	include "macro.h"


;-------------------------------------------------------------
;-                    Start of code here                     -
;-------------------------------------------------------------
	SEG
	ORG $F000

COLOR = $80
POS = $81


Reset
;-------------------------------------------------------------
;-   Clear RAM, TIA registers and Set Stack Pointer to #$FF  -
;-------------------------------------------------------------
	sei
	cld
	ldx #$FF
	txs
	lda #0

Clear_Mem
	sta 0,X
	dex
	bne Clear_Mem

	lda #$80        ; Blue
	sta COLUBK      ; Background Color
	lda #$1E        ; Yellow
	sta COLOR
;-------------------------------------------------------------
;-                    Start to Build Frame                   -
;-------------------------------------------------------------
Start_Frame
	; Start of Vertical Blank
	lda #2
	sta VSYNC
	sta WSYNC
	sta WSYNC
	sta WSYNC        ; 3 scanlines of VSYNC

	lda #0
	sta VSYNC

	; Start of vertical blank
	; 37 scanlines

	lda  #43         ; 2 cycles
	sta  TIM64T      ; 3 cycles

; 2793 cycles free
 	ldx COLOR
	inx
	stx COLUP0
	stx COLOR
; stop

Wait_VBLANK_End

	lda INTIM                ; 3 cycles
	bne Wait_VBLANK_End      ; 3 cycles
	sta WSYNC        		; 3 cycles  total amount = 19 cycles
				  		; 2812-19 = 2793; 2793/64 = 43.64 (TIM64T)

	lda #0
	sta VBLANK      ; Enable TIA Output

	; Display 192 Scanlines with Player 0

	sleep 36         ; Player X = +/- Middle Screen
	sta RESP0        ; Set Player 0 (X)
	ldy #192         ; 192 Scanlines
	ldx #0

Picture
	stx COLUBK
	cpy #110         ; Position Y reached ?
	bpl No_Drawing   ; No = Continue
	cpx #14          ; 14 Lines of sprite Datas Drawn ?
	beq No_Drawing   ; Yes = Stop
	lda Sprite_Data,X
	sta GRP0
	inx

No_Drawing
	sta WSYNC
	dey              ; 192 Scanlines drawn ?
	bne Picture      ; No = Continue


;-------------------------------------------------------------
;-                       Frame Ends Here                     -
;-------------------------------------------------------------
	lda #%00000010
	sta VBLANK       ; Disable TIA Output

	; 30 Scanlines of Overscan
	ldx #30
Overscan
	sta WSYNC
	dex
	bne Overscan
	jmp Start_Frame  ; Build Next Frame

;-------------------------------------------------------------
;-                         Demo Datas                        -
;-------------------------------------------------------------
Sprite_Data
	.byte #%00011000
	.byte #%00111100
	.byte #%01111110
	.byte #%01101110
	.byte #%11111111
	.byte #%11111000
	.byte #%11100000
	.byte #%11111000
	.byte #%11111111
	.byte #%01111110
	.byte #%01111110
	.byte #%00111100
	.byte #%00011000
	.byte #%00000000

;-------------------------------------------------------------
;-                     Set Interrup Vectors                  -
;-------------------------------------------------------------

	ORG $FFFA

Interrupt_Vectors

	.word Reset      ; NMI
	.word Reset      ; RESET
	.word Reset      ; IRQ

END
