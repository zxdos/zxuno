.macro FNADDR addr
   .byte >addr, <addr
.endmacro

.macro readport 	port
.ifdef AVR
			jsr	WaitUntilWritten
.endif
			lda	port
.endmacro

.macro writeport   	port

.IF debug
            pha
            lda #>port
            jsr $F802
            lda #<port
            jsr $F802
            lda #':'
            jsr $fff4
            pla
            pha
            jsr $F802
            lda #' '
            jsr $fff4
            pla
.ELSE
.ifndef AVR
            sta port
            nop
            nop
            nop
			nop
.else
			sta port
			jsr	WaitUntilRead
.endif
.ENDIF
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

; Fast command, command port write followed by interwrite delay on PIC, or a WaitWhileBusy on the AVR
.macro FASTCMD
	writeport		ACMD_REG
.ifdef AVR
	jsr				WaitWhileBusy	; Keep waiting until not busy
.else
	jsr				interwritedelay
.endif
	lda				ACMD_REG		; get status for client
.endmacro

; Immediate version of fastcmd
.macro FASTCMDI	command
	lda				#command
	FASTCMD
.endmacro
