;;	Assemblerinstruktioner.
;;	Först och främst måste vi berätta för assemblern 
;;	att vi programmerar mot 6502 och att vi vill hämta
;;	definitioner ang. Atari VCS-specifika minnesfunktioner:
	
	processor 6502
	include vcs.h
	
	ORG $F000		;; Startadress

;;	Bra jobbat. Nu börjar koden som körs på processorn.
Start:
	SEI			;; Set interrupt disable
	CLD			;; Clear decimal mode

;;	Nollställ stackpekaren:
	LDX #$FF		;; Fyll register X med FF.
	TXS			;; Sätt stackpekaren till värdet i X.

;;	Nollställ resten av minnet:
	LDA #0
ClearMem:
	STA 0, X
	DEX
	BNE ClearMem

Main: