;=================================================================
; macro definitions for AtoMMC
; Collected macros from all files into a single file
;=================================================================
;
; 2013-10-09 converted some of the macro calls to jsr calls where
; appropriate. -- PHS
;

.macro FNADDR addr
   .byte >addr, <addr
.endmacro

.macro readportFAST port
.ifdef AVR
	jsr	WaitUntilWritten
.endif
	lda	port
.endmacro

.macro writeportFAST port
    sta port
.ifdef AVR
	jsr WaitUntilRead
.endif
.endmacro

.macro REPERROR addr
   lda #<addr
   sta $d5
   lda #>addr
   sta $d6
   jmp reportFailure
.endmacro

; Note SLOWCMD used to take a port number, but since ALL calls used APORT_CMD
; it is more code size efficient to convert it to a subroutine call, that always
; uses ACMD_PORT.
.macro SLOWCMD
	jsr	SLOWCMD_SUB
.endmacro

.macro SLOWCMDI command
	lda	#command
	SLOWCMD
.endmacro

; Fast command, command port write followed by interwrite delay on PIC,
; Simply an alias for SLOWCMD on AVR.
.macro FASTCMD
.ifndef AVR
	writeportFAST	ACMD_REG
	jsr				interwritedelay
	lda				ACMD_REG
.else
	SLOWCMD
.endif
.endmacro

; Immediate version of fastcmd
.macro FASTCMDI	command
	lda				#command
	FASTCMD
.endmacro


;.macro PREPPUTTOB407
;   jsr	PREPPUTTOB407_SUB
;.endmacro

.macro SETRWPTR addr
   lda #<addr
   sta RWPTR
   lda #>addr
   sta RWPTR+1
.endmacro


; Subroutines for macros in util.asm
	