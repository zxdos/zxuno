;----------------------------------------------
;MOS EXTENSION ROM 2 for BBC
;----------------------------------------------
	.DEFINE asm_code $7000
	.DEFINE header   0		; Header Wouter Ras emulator
	.DEFINE filenaam "EXTROM2"

.org asm_code-22*header

.IF header
;********************************************************************
; ATM Header for Atom emulator Wouter Ras

name_start:
	.byte filenaam			; Filename
name_end:
	.repeat 16-name_end+name_start	; Fill with 0 till 16 chars
	  .byte $0
	.endrep

	.word asm_code			; 2 bytes startaddress
	.word exec			; 2 bytes linkaddress
	.word eind_asm-start_asm	; 2 bytes filelength

;********************************************************************
.ENDIF


exec:
start_asm:
	.include "macros.inc"
	.include "atmmc2def.inc"
	.include "extrom2.inc"

	.include "util.asm"
	.include "file.asm"

;***********************************************************************
;* Fill rom and add EXTMEM vectors
;***********************************************************************

	.repeat (asm_code+$0FFF-*)	; Fill rom with $ff
	  .byte $ff
	.endrep

eind_asm:
