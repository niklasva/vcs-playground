; '2600 for Newbies
; Sessions 17 & 18
; Excercise in creating asymmetrical playfields

     processor 6502
     include "vcs.h"
     include "macro.h"

                SEG
                ORG $F000

Reset
   ; Clear RAM and all TIA registers
                ldx #0
                lda #0

Clear           sta 0,x
                inx
                bne Clear

       ;------------------------------------------------
       ; Once-only initialization...
			 lda #$45
			 sta COLUPF             ; set the playfield color

			 lda #%00000001
			 sta CTRLPF             ; reflect playfield
       ;------------------------------------------------


StartOfFrame

   ; Start of new frame
   ; Start of vertical blank processing
                lda #0
                sta VBLANK

                lda #2
                sta VSYNC

                sta WSYNC
                sta WSYNC
                sta WSYNC               ; 3 scanlines of VSYNC signal

                lda #0
                sta VSYNC
       ;------------------------------------------------
       ; 37 scanlines of vertical blank...
                ldx #0
VerticalBlank   sta WSYNC
			 inx
			 cpx #37
			 bne VerticalBlank


			 ldx #192
Picture         stx COLUPF
                sleep 5
                lda #%00000000
                sta PF0
                sleep 10
                lda #%11110111
                sta PF1
                sleep 10
                lda #%00011111
                sta PF2
                sleep 5
                lda #%00010000
                sta PF0
                lda #%11001100
                sta PF1
                sta PF2
                dex
                sta WSYNC
                bne Picture

   ; 30 scanlines of overscan...
                ldx #0
Overscan        sta WSYNC
                inx
                cpx #30
                bne Overscan


                jmp StartOfFrame
;------------------------------------------------------------------------------

            	 ORG $FFFA

InterruptVectors
     		 .word Reset          ; NMI
     		 .word Reset          ; RESET
     		 .word Reset          ; IRQ

END
