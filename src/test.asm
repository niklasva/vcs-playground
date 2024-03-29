	processor 6502
        include "vcs.h"
        include "macro.h"
        include "xmacro.h"

        seg.u Variables
	org $80

TrackFrac	.byte	; fractional position along track
Speed		.byte	; speed of car
TimeOfDay	.word	; 16-bit time of day counter
; Variables for preprocessing step
XPos		.word	; 16-bit X position
XVel		.word	; 16-bit X velocity
TPos		.word	; 16-bit track position
TrackLookahead	.byte	; current fractional track increment
; Variables for track generation
Random		.byte	; random counter
GenTarget	.byte	; target of current curve
GenDelta	.byte	; curve increment 
GenCur		.byte	; current curve value

ZOfs		.byte	; counter to draw striped center line
Weather		.byte	; bitmask for weather

NumRoadSegments equ 28

; Preprocessing result: X positions for all track segments 
RoadX0		REPEAT NumRoadSegments
	        .byte
	        REPEND

; Generated track curve data
TrackLen	equ 5
TrackData	REPEAT TrackLen
		.byte
                REPEND

InitialSpeed	equ 10	; starting speed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	seg Code
        org $f000

Start
	CLEAN_START
        lda #1
        sta Random
        lda #InitialSpeed
        sta Speed
        lda #0
        sta TimeOfDay+1
        lda #0
        sta Weather

NextFrame

	VERTICAL_SYNC

; Set up some values for road curve computation,
; since we have some scanline left over.
	lda #0
        sta XVel
        sta XVel+1
        sta XPos
        lda #70		; approx. center of screen
        sta XPos+1
        lda TrackFrac
        sta TPos
        lda #0
        sta TPos+1
        lda #10		; initial lookahead
        sta TrackLookahead

; VSYNC+36+198+24 = 4+258 = 262 lines

	TIMER_SETUP 36

; Initialize array with X road positions
        jsr PreprocessCurve
        
	TIMER_WAIT

; Now draw the main frame
	TIMER_SETUP 198

	jsr DrawSky
        jsr SetupRoadComponents
        jsr DrawRoad	; draw the road
        
        TIMER_WAIT
        
	TIMER_SETUP 24
; Advance position on track
; TrackFrac += Speed
	lda TrackFrac
        clc
        adc Speed
        sta TrackFrac
        bcc .NoGenTrack ; addition overflowed?
        jsr GenTrack	; yes, generate new track segment
.NoGenTrack
; TimeOfDay += 1
        inc TimeOfDay
        bne .NoTODInc
        inc TimeOfDay+1
        lda TimeOfDay+1
; See if it's nighttime yet, and if the stars come out
        clc
        adc #8
        and #$3f
        cmp #$35
        ror
        sta Weather
.NoTODInc

	TIMER_WAIT
        jmp NextFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Compute road curve from bottom of screen to horizon.
PreprocessCurve subroutine
	ldx #NumRoadSegments-1
.CurveLoop
; Modify X position
; XPos += XVel (16 bit add)
	lda XPos
        clc
        adc XVel
        sta XPos
        lda XPos+1
        adc XVel+1
        sta XPos+1
        sta RoadX0,x	; store in RoadX0 array
; Modify X velocity (slope)
; XVel += TrackData[TPos]
        ldy TPos+1
        lda TrackData,y
        clc		; clear carry for ADC
        bmi .CurveLeft	; track slope negative?
        adc XVel
        sta XVel
        lda XVel+1
        adc #0		; carry +1
        jmp .NoCurveLeft
.CurveLeft
        adc XVel
        sta XVel
        lda XVel+1
        sbc #0		; carry -1
        nop ; make the branch timings are the same
.NoCurveLeft
        sta XVel+1
; Advance TPos (TrackData index)
; TPos += TrackLookahead
	lda TPos
        clc
        adc TrackLookahead
        sta TPos
        lda TPos+1
        adc #0
        sta TPos+1
; Go to next segment
	inc TrackLookahead ; see further along track
        dex
        bpl .CurveLoop
        rts

; Set road component X positions and enable registers
SetupRoadComponents subroutine
	lda RoadX0
	sta HMCLR	; clear HMOVE registers
        sec
	sta WSYNC
.DivideLoop
	sbc #15		; subtract 15
	bcs .DivideLoop	; branch while carry still set
        adc #15
        tay
        lda HMoveTable,y	; lookup HMOVE value
        sta HMM0	; set missile 0 fine pos
        sta HMBL	; set ball fine pos
        sta HMM1	; set missile 1 fine pos
        sta RESM0	; set missile 0 position
        sta RESBL	; set ball position
        sta RESM1	; set missile 1 position
        sta WSYNC
        sta HMOVE
; Make road components converge at horizon
; This will require an additional HMOVE
	lda #$90	; right 7 pixels
        ldy #$70	; left 7 pixels
        ldx #$00	; no movement
        SLEEP 14	; wait until safe to set regs
        sta HMM0
        sty HMM1
        stx HMBL
        sta WSYNC
        sta HMOVE
        rts

; Draw the sky, adding clouds and time-of-day colors.
DrawDaytime subroutine
	lda TimeOfDay+1	; offset into sunset color table
        and #$3f
        tay
        lda #16		; initial height of sky segment
.SkyLoop2
        tax		; height -> X
        pha		; push original height
.SkyLoop
        lda SunsetColors,y	; get sunset color
	sta WSYNC		; start scanline
        sta COLUBK		; set background color
        lda SunsetColors+2,y	; get cloud color
        sta COLUPF		; set foreground color
        lda CloudPFData0,x	; load clouds -> playfield
        sta PF0
        lda CloudPFData1,x
        sta PF1
        lda CloudPFData2,x
        sta PF2
        dex
        bne .SkyLoop		; repeat until sky segment done
        iny			; next sky color
        tya
        and #$3f		; keep sky color in range 0-63
        tay			; sky color -> Y
        pla			; restore original segment height 
        sec
        sbc #2			; segment height - 2
        cmp #2			; done with segments?
        bcs .SkyLoop2		; no, repeat
; Draw mountains
; First, load mountain color
	lda TimeOfDay+1
        lsr
        lsr			; divide time-of-day by 4
        and #$f			; keep in range 0-15
        tax			; -> Y
        lda MountainColors,x	; load mountain color
        sta COLUPF		; set foreground
        lda GroundColors,x	; load ground color
        pha			; save it for later
        ldx #0
        stx PF0
        stx PF1			; to avoid artifacts, we have to
        stx PF2			; clear previous clouds
.MtnLoop
        lda SunsetColors,y	; get sunset color
        sta WSYNC		; start scanline
        sta COLUBK		; set background color
        lda MtnPFData0,x	; load mountains -> playfield
        sta PF0
        lda MtnPFData1,x
        sta PF1
        lda MtnPFData2,x
        sta PF2
        iny			; next sky color
        tya
        and #$3f		; keep sky color in range 0-63
        tay			; sky color -> Y
        inx
        cpx #7			; only 7 scanlines for the mountains
        bne .MtnLoop
; Setup colors and enable road components
	pla		; restore ground color
        sta COLUBK	; set background
        lda #0
        sta PF0
        sta PF1
        sta PF2
        rts

DrawSky
	bit Weather
        bmi DrawNight
        jmp DrawDaytime

; Draw the night sky, with stars.
DrawNight subroutine
	lda #6
        sta ENABL
        sta COLUPF
        ldy #0
.MoreStars
	sta RESBL	; strobe the ball to display a star
        adc Start,y	; "randomize" the A register
        bmi .Delay1
.Delay1
	ror
        bcc .Delay2
.Delay2
	ror
        bcs .Delay3
.Delay3
	ror
        bcs .Delay4
.Delay4
        iny
	ldx INTIM
        cpx #$89	; timer says we're done?
        bcs .MoreStars	; nope, make more stars
        lda #0
        sta ENABL	; disable ball
        rts

DrawRoad subroutine
        lda #2
        sta ENAM0
        sta ENAM1	; enable missiles
        sta COLUPF
        sta COLUP0
        sta COLUP1	; set their colors too
; Draw road
	lda TrackFrac
        asl
	sta WSYNC	; WSYNC so scanline starts at same place each time
        asl		; TrackFrac * 4
        sta ZOfs	; -> counter for animated stripe
        ldx #0		; 0 is farthest segment
.RoadLoop
	lda RoadColors,x ; color of sides and center line
        sta COLUP0
        sta COLUP1
        sta COLUPF
	lda RoadX0+1,x	; get next X coordinate
        sec
        sbc RoadX0,x	; subtract this X coordinate
        clc
        adc #7		; add 7
        tay		; -> Y
        lda HMoveTable-3,y	; left side biased left
        sta HMM0
        lda HMoveTable,y	; center line
        sta HMBL
        lda HMoveTable+3,y	; right side biased right
        sta HMM1
        sta WSYNC
        sta HMOVE
        sta WSYNC
; Make dashed road stripe by using a counter
; initialized to the fractional track position,
; then subracting the PIA timer as an approximation
; to Z value.
        lda ZOfs
        sec
        sbc INTIM
        sta ZOfs	; ZOfs -= timer
        rol
        rol
        rol		; shift left by 3
        sta ENABL	; enable ball (bit 2)
        sta WSYNC
	lda RoadWidths,x ; lookup register for missile size
        sta NUSIZ0	; store missile 0 size
        sta NUSIZ1	; store missile 1 size
        sta WSYNC
        inx
        cpx #NumRoadSegments-1
        bne .RoadLoop	; repeat until all segments done
; Clean up road objects
	lda #0
        sta ENAM0
        sta ENAM1
        sta ENABL
        sta COLUBK
        sta NUSIZ0
        sta NUSIZ1
	rts

; Get next random number
NextRandom subroutine
	lda Random
	lsr
	bcc .NoEor
	eor #$d4
.NoEor:
	sta Random
        rts

; Generate next track byte
GenTrack subroutine
; Shift the existing track data one byte up
; (a[i] = a[i+1])
	ldx #0
.ShiftTrackLoop
	lda TrackData+1,x
        sta TrackData,x
        inx
        cpx #TrackLen-1
        bne .ShiftTrackLoop
; Modify our current track value and
; see if it intersects the target value
	lda GenCur
        clc
        adc GenDelta
        cmp GenTarget
        beq .ChangeTarget   ; target == cur?
        bit GenTarget	    ; we need the sign flag 
        bmi .TargetNeg	    ; target<0?
        bcs .ChangeTarget   ; target>=0 && cur>=target?
        bcc .NoChangeTarget ; branch always taken
.TargetNeg
        bcs .NoChangeTarget ; target<0 && cur<target?
; Generate a new target value and increment value,
; and make sure the increment value is positive if
; the target is above the current value, and negative
; otherwise
.ChangeTarget
	jsr NextRandom	; get a random value
        and #$3f	; range 0..63
        sec
        sbc #$1f	; range -31..32
        sta GenTarget	; -> target
        cmp GenCur
        bmi .TargetBelow ; current > target?
        jsr NextRandom	; get a random value
        and #$f		; mask to 0..15
        jmp .TargetAbove
.TargetBelow
	jsr NextRandom
        ora #$f0	; mask to -16..0
.TargetAbove
        ora #1		; to avoid 0 values
        sta GenDelta	; -> delta
        lda GenCur
.NoChangeTarget
; Store the value in GenCur, and also
; at the end of the TrackData array
	sta GenCur
	sta TrackData+TrackLen-1
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; HMOVE table from -7 to +8
HMoveTable
	hex 7060504030201000f0e0d0c0b0a09080

; Sunset table
SunsetColors
	hex 00000000a07060504446383efc0c9f9f
        hex aeaeaeaeaeaeaeaeaeaeaeaeaeaeaeae
        hex 9f9f9f0cfc3e384644506070a0000000
        hex 00000000000000000000000000000000
        hex 0000	; for overflow

MountainColors
	hex 00021012f4f6e6264604020000000000
GroundColors
	hex 00c0c2c4c6c8c8e6e4e2e00000000000

RoadColors
	hex 020202
        hex 040404
        hex 060606
        hex 08080808
        hex 0a0a0a0a0a
        hex 0c0c0c0c0c0c
        hex 0e0e0e0e0e0e0e0e0e

RoadWidths
	hex 000000000000
        hex 10101010
        hex 1010101010
        hex 202020202020
        hex 202020202020202020

; Cloud data
CloudPFData0
        .byte #%10000000
        .byte #%11100000
        .byte #%10000000
        .byte #%00000000
        .byte #%00000000
        .byte #%10000000
        .byte #%11100000
        .byte #%00000000

CloudPFData1
        .byte #%11000000
        .byte #%11110000
        .byte #%11100001
        .byte #%00000011
        .byte #%00000111
        .byte #%11000000
        .byte #%00000000
        .byte #%00011000

CloudPFData2
        .byte #%00000000
        .byte #%00001110
        .byte #%00011111
        .byte #%00000111
        .byte #%01100000
        .byte #%11000000
        .byte #%00000110
        .byte #%00000000

; Mountain data
MtnPFData0
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%10000000
        .byte #%11100000

MtnPFData1
        .byte #%00000000
        .byte #%00010000
        .byte #%00110000
        .byte #%01111000
        .byte #%11111100
        .byte #%11111110
        .byte #%11111110

MtnPFData2
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000100
        .byte #%00101110
        .byte #%01111111
        .byte #%11111111

CarSprite
        .byte 0
        .byte #%10000001;--
        .byte #%10111101;--
        .byte #%11111111;--
        .byte #%10000001;--
        .byte #%10111101;--
        .byte #%01011010;--
        .byte #%01011010;--
        .byte #%01011010;--
        .byte #%00100100;--
        .byte #%11111111;--
        .byte #%10111101;--
        .byte #%00111100;--

; Epilogue
	org $fffc
        .word Start
        .word Start


