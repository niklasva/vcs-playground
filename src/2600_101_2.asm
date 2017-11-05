; Assemblerinstruktioner.
; Först och främst måste vi berätta för assemblern att vi programmerar mot
; 6502 och att vi vill hämta definitioner ang. Atari VCS-specifika
; minnesfunktioner.

    processor 6502
    include "vcs.h"

    ORG $F000	; Startadress

; Bra jobbat. Nu börjar koden som körs på processorn.


;; ---- VARIABLER ---- ;;
ypos = $80;					; Punktens vertikala position räknat från botten
missile_height = $81		; av skärmen.


Start:
    SEI         	; Set interrupt disable
    CLD         	; Clear decimal mode

; Nollställ stackpekaren:

    LDX #$FF    	; Fyll register X med 0xFF.
    TXS         	; Sätt stackpekaren till värdet i X.

; Nollställ resten av minnet:

    LDA #0

ClearMem:
    STA 0,X    		; Skriv det som är i register A till minnesplats 0 + X
    DEX				; (kom ihåg att vi satte X till FF förut)
    BNE ClearMem

; Okej. Kul. Nu kan vi prova att göra lite mer grafiska operationer.
; Sätt bakgrunden till färgen 0x00 (svart)

    LDA #$00		; Ladda in färgen i A
    STA COLUBK		; Skriv värdet i A till bakgrundsfärgregistret

; Samma med spelare 0 men färg 33

    LDA #33
    STA COLUP0

Init:
	LDA #80
	STA ypos		; Sätt 80 som Y:s ursprungsvärde.

	LDA #$20		; Sätt missile0:s bredd till 4x
	STA NUSIZ0		;

Main:

; För att kicka igång VSYNC-processen sätter man bit D1
; (andra biten från höger) till 1.
; 0010 (2) -> VSYNC.

    LDA #2
    STA VSYNC   	;; --- BEGIN VSYNC --- ;;

    STA WSYNC   	; VSYNC är 3 scanlines lång. Vänta på 3 HBLANK.
    STA WSYNC   	; Det här är egentligen slöseri med tid --
    STA WSYNC   	; man kan fylla på med logik här.


    LDA #43
    STA TIM64T

    LDA #0
    STA VSYNC   	;; ---- END VSYNC ---- ;;

	LDA #%000100000 ; Säg åt missil 0 att rära sig långsamt åt höger
	STA HMM0		;

Vblank:
; Vi måste vänta på att vblank ritats färdigt innan vi kan börja
; jobba mot skärmen.

	LDA INTIM		; Läs från timern
	BNE Vblank		; Vänta till timern är 0.

	LDY #191		; Vi sätter register Y till 191. Planen är att räkna
					; ner den här efter varje scanline, för att hålla reda
					; på hur många scanlines som är kvar att rita på.

	STA WSYNC
	STA VBLANK		; Skriv 0 till VBLANK (A har värdet 0 eftersom BNE inte
					; hade skickat hit oss om A inte har fått det värdet.

	LDA #$F0		; HMM0 är missile0:s horizontal movement register.
	STA HMM0		; Vi vill sätta de vänstra fyra bitarna till -1,
					; vilket enligt 2-komplement blir $F.

	STA WSYNC		; Låt en hel linje ritas färdigt
	STA HMOVE		; Sen sätter vi missile0 i rörelse.

Scanline:
;
; Här sker renderingslogiken för varje pixelrad på skärmen
;
	STA WSYNC				; Vänta in att förra raden är klar

CheckActivateMissile:		; Väntar till Y-registret, som håller reda på
	CPY ypos				; vilken rad som renderas, kommer till missilens
	BNE SkipActivateMissile	; y-position.

	LDA #16					; Sen säger vi hur lång missile 0 ska vara i y-led
	STA missile_height		; genom att spara värdet i visiblemisline variabeln.

SkipActivateMissile:
	LDA #0
	STA ENAM0				; Se till att missile 0 är osynlig.

	LDA missile_height		; Om height fortfarande är noll
	BEQ FinishMissile		; struntar vi i renderingen.

IsMissileOn:				; Annars renderar vi missile 0
	LDA #2
	STA ENAM0
	DEC missile_height		; Hela missilens y-höjd

FinishMissile:

	DEY				; Räkna ner "radräknaren"
	BNE Scanline	; Gör TIA output osynlig under overscantiden.
					; (och vidare genom vsync och vblank)


; Allt som visas på skärmen har renderats klart. Nu väntar vi på 30
; overscanrader.
	LDX #30			; Ladda in #30 i X (antalet overscanrader)
Overscan:
	STA WSYNC		; Vänta på att strålen har passerat hela raden
	DEX				; Räkna ner vilken overscanrad vi är på
	BNE Overscan

	JMP Main		; Hoppa till början igen.

	org $FFFC
	.word Start
	.word Start
