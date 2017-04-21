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
	LDX #$FF		;; Fyll register X med 0xFF.
	TXS			;; Sätt stackpekaren till värdet i X.

;;	Nollställ resten av minnet:
	LDA #0
ClearMem:
	STA 0, X		;; Skriv det som är i register A till minnesplats 0 + X
	DEX			;; (kom ihåg att vi satte X till FF förut)
	BNE ClearMem


;;	Okej. Kul. Nu kan vi prova att göra lite mer grafiska operationer.
;;	Sätt bakgrunden till färgen 0x00 (svart)

	LDA #$00		;; Ladda in färgen i A
	STA COLUBK		;; Skriv värdet i A till bakgrundsfärgregistret


;;	Samma med spelare 0 men färg 33
	LDA #33
	STA COLUP0

Main:
