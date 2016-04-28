;***********************************************************************
;*    B B C   M O S   E X T E N S I O N   R O M  2                     *
;*---------------------------------------------------------------------*
;*    remark         : Extension rom 2 for Atom BBC MOSROM v3          *
;*---------------------------------------------------------------------*
;*    filename       : extrom2.asm                                     *
;*    auteur         : Kees van Oss                                    *
;*    date           : june 2014                                       *
;*    laatste update :                                                 *
;*---------------------------------------------------------------------*
;*    assemble       : MAKE extrom2                                    *
;*---------------------------------------------------------------------*
;*    init           : Automaticly at $7xxx at boot BBC mode           *
;*---------------------------------------------------------------------*
;*    extrom2 format : $7000 = $AA, ID byte                            *
;*                     $7001 = Jump to initialisation routine MOS-EXT2 *
;***********************************************************************


;***********************************************************************
;* Definition variables and consants
;***********************************************************************

cli_vec		= $0208		; OSCLI vector
file_vec	= $0212		; OSFILE vector

extrom1_id	= $6000		; EXTROM1 ID byte

osbyte		= $fff4		; OSBYTE
oswrch          = $ffee		; OSWRCH, print character in A
osascii		= $ffe3		; OSACII, print character in A and LF
oscli		= $fff7		; OSCLI, execute *command

;***********************************************************************
;* Initialisation MOS EXT ROM 2
;***********************************************************************

extrom2_init:
	.byte $AA		; ID byte BBC MOS v3

	JSR print		; Report ROM on screen
extrom2_msgtxt:
	.byte "BBCMMC 1.00",13,10
	NOP

	LDA #<OSCLI_entry	; Reset OSCLI vector
	STA cli_vec
	LDA #>OSCLI_entry
	STA cli_vec+1

	LDA #<OSFILE_entry	; Reset OSFILE vector
	STA file_vec
	LDA #>OSFILE_entry
	STA file_vec+1

;*********************
; SHIFT-BREAK option
;*********************
	bit $b001
	bmi no_boot

	ldx #<boot_command
	ldy #>boot_command
	jsr oscli

;*********************

no_boot:
	RTS

boot_command:
	.byte "R.!BOOT",13

;***********************************************************************
; OSCLI entry, new vector $0208/209
; New *-command interpreter, copied from MOS ROM v3
;***********************************************************************

L00C6	= $00c6			; Temp A
L00C7	= $00c7			; Temp X
L00C8	= $00c8			; Temp Y

L00C9	= $00c9			; Jump command address
L00CA	= $00ca

L0100	= $0100			; CLI buffer

OSCLI_entry:
	STA L00C6		; Save A,X,Y
	STX L00C7
	STY L00C8

	LDY #$00
	LDX #$FF
	LDA (L00C7),Y		; Load character CLI buffer
	CMP #'*'		; Check if *-command
	BNE LF77D		; Skip if not
LF77C:
	INY
LF77D:
	INX			; Copy command to $100
	LDA (L00C7),Y
	STA L0100,X
	CMP #$0D
	BNE LF77C

	JSR LF8C3		; Check if command in table

	LDY L00C8		; Restore A,X,Y
	LDX L00C7
	LDA L00C6
LF790:
	RTS

; Check if command in table

LF8C3:
	LDX #$FF
	CLD
LF8C6:
	LDY #$00
	JSR LF863		; Skip spaces

	DEY
LF8CE:
	INY
	INX
LF8D0:
	LDA LF5E9,X		; Get character from star command table
	BMI LF8ED		; Check if address

	CMP L0100,Y		; Compare with CLI buffer
	BEQ LF8CE		; Repeat for next char

	DEX
LF8DB:
	INX
	LDA LF5E9,X		; Skip table command 
	BPL LF8DB

	INX
	LDA L0100,Y		; Check if abreviation
	CMP #'.'
	BNE LF8C6

	INY
	DEX
	BCS LF8D0
LF8ED:
	AND #$7F		; Strip bit7 from hb-address
	STA L00CA
	LDA LF5E9 + 1,X		; Get lb-address
	STA L00C9
	CLC
	LDX #$00
	JMP (L00C9)		; Jump command

; *-Command table, high byte address MUST be added by $80 to make negative!

LF5E9:
	.byte "CAT"
	.byte >STARCAT+$80
	.byte <STARCAT

	.byte "DELETE"
	.byte >STARDELETE+$80
	.byte <STARDELETE

	.byte "DIR"
	.byte >STARDIR+$80
	.byte <STARDIR

	.byte "INFO"
	.byte >STARINFO+$80
	.byte <STARINFO

	.byte "LOAD"
	.byte >STARLOAD+$80
	.byte <STARLOAD

	.byte "SAVE"
	.byte >STARSAVE+$80
	.byte <STARSAVE

	.byte "RUN"
	.byte >STARRUN+$80
	.byte <STARRUN

	.byte "HELP"
	.byte >STARHELP+$80
	.byte <STARHELP

	.byte >STARARBITRARY+$80
	.byte <STARARBITRARY

;	.byte >LF8B6+$80	; Command not found, ERROR
;	.byte <LF8B6

; Command not found, report BAD COMMAND and generate error

LF8B6:
	BRK
	.byte $FE
	.byte "BAD COMMAND"
	.byte $00,$00

; Skip spaces, entry at F863

LF862:
	INY
LF863:
	LDA     L0100,Y
	CMP     #' '		; Skip space
	BEQ     LF862

	RTS

;------------------------------------------------------------------------
; Commands 
;------------------------------------------------------------------------

	.include "cat.inc"
	.include "delete.inc"
	.include "cwd.inc"
	.include "info.inc"
	.include "load.inc"
	.include "save.inc"
	.include "run.inc"
	.include "help.inc"

;***********************************************************************
; OSFILE entry, new vector $0212/213
; Entry for LOAD and SAVE command
; (0,x) points to 1st character filename
; A = &00 -> SAVE
;     &FF -> LOAD
;     
;***********************************************************************

CHKNAME		= $f84b		; Check if len filename<14

OSFILE_entry:
	STA L00C6		; Save A,X,Y
	STX L00C7
	STY L00C8

	LDA 0,X			; Set pointer to filename
	STA $c9
	LDA 1,X
	STA $ca


	ldy #$ff		; Copy filename to $140
read_loop:
	iny
	lda (L00C9),y
	sta NAME,y
	cmp #$0d
	bne read_loop

; Check OSFILE action

	LDA L00C6		; Get Action byte
	BEQ action_0		; A=0   -> save
	CMP #$FF
	BEQ action_ff		; A=$FF -> load
	JMP OSFILE_return

action_0:			; Action=0 -> SAVE file
	JSR ossavecode
	JMP OSFILE_return

action_ff:			; Action=$ff -> LOAD file
	JSR osloadcode

OSFILE_return:
        LDY     L00C8		; Restore A,X,Y
        LDX     L00C7
        LDA     L00C6
        RTS


;************************************************************************
;* Common subroutines                                                   *
;************************************************************************

; Print string until negative byte

print:
	pla			; Get address from stack
	sta $E8			; Set print pointer
	pla
	sta $E9
print1:
	ldy #$00		; Reset indexregister
	inc $E8			; Increment pointer
	bne print2		; Jump if no pagecross
	inc $E9
print2:
	lda ($E8),y		; Read character
	bmi print3		; Jump if end of string
	jsr osascii		; Print character
	jmp print1		; Read next character
print3:
	jmp ($E8)		; End of routine



