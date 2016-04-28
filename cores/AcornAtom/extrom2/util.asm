;
; renamed some subs as follows :
; PREPGETFRB406_SUB	to prepare_read_data
; PREPPUTTOB407_SUB to prepare_write_data
;	-- PHS 2013-10-09

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Short delay
;
; Enough to intersperse 2 writes to the FATPIC.
;
interwritedelay:
.ifndef AVR
;   lda  #4
	lda	#8
   sec

@loop:
   sbc  #1
   bne  @loop
.endif
   rts

; subroutines for macros in macro.inc
SLOWCMD_SUB:
   writeportFAST ACMD_REG
.ifndef AVR
SlowLoop:

	lda #0
	sec 
SLOWCMD_DELAY_LOOP:
	sbc #1
	bne SLOWCMD_DELAY_LOOP

   lda ACMD_REG
   bmi SlowLoop
.else
	jsr	WaitWhileBusy	; Keep waiting until not busy
	lda	ACMD_REG		; get status for client
.endif
	rts
	
prepare_read_data:
   lda 				#CMD_INIT_READ
   writeportFAST 	ACMD_REG				
   jmp 				interwritedelay

prepare_write_data: 
   lda 				#CMD_INIT_WRITE
   writeportFAST 	ACMD_REG 			
   jmp 				interwritedelay
 
   
.ifdef AVR		; Extra PHA/PLA added for restoring A
WaitUntilRead:		
	pha
WaitUntilRead1:		
	lda		ASTATUS_REG		; Read status reg
	and		#MMC_MCU_READ		; Been read yet ?
	bne		WaitUntilRead1		; nope keep waiting
	pla
	rts

WaitUntilWritten:
	pha
WaitUntilWritten1:
	lda		ASTATUS_REG		; Read status reg
	and		#MMC_MCU_WROTE		; Been written yet ?
	beq		WaitUntilWritten1	; nope keep waiting
	pla
	rts

WaitWhileBusy:
	pha
WaitWhileBusy1:
	lda		ASTATUS_REG		; Read status reg
	and		#MMC_MCU_BUSY		; MCU still busy ?
	bne		WaitWhileBusy1		; yes keep waiting
	pla
	rts
.endif


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read an asciiz string to name buffer at $140
;
; on exit y = character count not including terminating 0
;
;	bug: this will keep reading until it hits a 0, if there is not one, it will
;		 keep going forever......
getasciizstringto140:
   jsr				prepare_read_data

   ldy  			#$ff

@loop:
   iny
   readportFAST 	AREAD_DATA_REG	; $b406
   sta  			NAME,y
   bne  			@loop

   rts

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read data to memory from the pic's buffer
;
; data may be from another source other than file, ie getfileinfo
; x = number of bytes to read (0 = 256)
; (RWPTR) points to store
;
read_data_buffer:
   jsr	prepare_read_data

   ldy  #0

@loop:
   readportFAST 	AREAD_DATA_REG	; $b406
   sta  (RWPTR),y
   iny
   dex
   bne @loop

   rts







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Perform slow command initialisation and expect a return code <= 64
;
expect64orless:
   cmp  #STATUS_COMPLETE+1
   bcs  reportDiskFailure
   rts







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Disable/Enable interface IRQ
;
ifdi:
   jsr   getcb
   and   #$DF              ; remove bit 6
   jmp   putcb   

ifen:
   jsr   getcb
   ora   #$20              ; set bit 6
   jmp   putcb   




getcb:
	FASTCMDI		CMD_GET_CFG_BYTE      ; retreive config byte
   rts

   
putcb:
   writeportFAST	ALATCH_REG		; $b40e  ; latch the value
   jsr   			interwritedelay

   lda   			#CMD_SET_CFG_BYTE      ; write latched val as config byte. irqs are now off
   writeportFAST	ACMD_REG	
   rts




;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; report a file system error
;
reportDiskFailure:
   and   #ERROR_MASK
   tax                     ; error code into x
   ldy   #$ff                ; string indexer

@findstring:
   iny                     ; do this here because we need the z flag below
   lda   diskerrortab,y
   cmp   #$0d
   bne   @findstring       ; zip along the string till we find a zero

   dex                     ; when this bottoms we've found our error
   bne   @findstring

   iny                     ; store index for basic BRK-alike hander
   tya
   clc
   adc   #<diskerrortab
   sta   $d5
   lda   #>diskerrortab
   adc   #0
   sta   $d6

   ; fall into ...


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Error printer
;
; Enter with $d5,6 -> Error string.
;
reportFailure:
;   lda   #<errorhandler
;   sta   $5
;   lda   #>errorhandler
;   sta   $6

	lda #10
	jsr OSWRCH
	ldy #$ff
failure_loop:
	iny
	lda ($d5),y
	jsr OSWRCH
	cmp #$0d
	bne failure_loop
	brk
	.byte $fe,11,0,0

diskerrortab:
   .byte $0d
   .byte "DISK FAULT",$0d
   .byte "INTERNAL ERROR",$0d
   .byte "NOT READY",$0d
   .byte "FILE NOT FOUND",$0d
   .byte "NO PATH",$0d
   .byte "INVALID NAME",$0d
   .byte "ACCESS DENIED",$0d
   .byte "EXISTS",$0d
   .byte "INVALID OBJECT",$0d
   .byte "WRITE PROTECTED",$0d
   .byte "INVALID DRIVE",$0d
   .byte "NOT ENABLED",$0d
   .byte "NO FILESYSTEM",$0d
   .byte $0d                     ; mkfs error
   .byte "TIMEOUT",$0d
   .byte "EEPROM ERROR",$0d
   .byte "FAILED",$0d
   .byte "NOT NOW",$0d
   .byte "SILLY",$0d

;errorhandler:
;   .byte "@=8;P.$6$7'"
;   .byte SQ
;   .byte "ERROR - "
;   .byte SQ
;   .byte "$!#D5&#FFFF;"
;   .byte "IF?1|?2P."
;   .byte SQ
;   .byte " - LINE "
;   .byte SQ
;   .byte "!1& #FFFF"
;   .byte $0d,0,0
;   .byte "P.';E."
;   .byte $0d

;COSSYN:
;	jsr print
;	.byte "SYNC?"
;	nop
;	brk


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display the filename at $140
;
;   renders 16 chars, pads with spaces
;
print_filename:
   ldx   #0
   beq   @test

@showit:
   jsr   OSWRCH
   inx

@test:
   lda   NAME,x
   cmp   #32              ; end string print if we find char < 32
   bcc   @test2

   cpx   #16              ; or x == 16
   bne   @showit

   rts

@showit2:
   lda   #32
   jsr   OSWRCH
   inx

@test2:
   cpx   #16
   bne   @showit2

   rts







;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Display file info
;
; Shows load, exec, length
;
print_fileinfo:
   lda   LLOAD+1
   jsr   HEXOUT
   lda   LLOAD
   jsr   HEXOUTS

   lda   LEXEC+1
   jsr   HEXOUT
   lda   LEXEC
   jsr   HEXOUTS

   lda   LLENGTH+1
   jsr   HEXOUT
   lda   LLENGTH
   jmp   HEXOUTS

HEXOUT:
	PHA		; Save original A
	LSR A		; Shift right 4 times, padding top 4 bits with 0
	LSR A		; ie. Demoting top 4 bits, or dividing by 16
	LSR A
	LSR A
	JSR convert
	PLA		; Restore A
	AND #15		; Remove upper 
	JSR convert 
	RTS		; Exit. Add an extra PHA/PLA if you want A uncorrupted
convert:
	SED		; Perform in binary coded decimal from now on
	CMP #10
	ADC #48		; Add on ASCii code for the number 0
	CLD		; Work in pure binary again
	JMP OSWRCH	; Using JMP means the OS does the RTS - saves a byte

HEXOUTS:
	jsr HEXOUT
	lda #' '
	jsr OSWRCH



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read filename from (0,X) to $140
;
; Input  X = pointer to filename
;
; Output $140 contains filename
;
read_filename:
   ldx   #0
;   ldy   $9a

@filename1:
   jsr   SKIPSPC
   cmp   #$22
   beq   @filename5

@filename2:
   cmp   #$0d
   beq   @filename3

   sta   NAME,x
   inx
   iny
   lda   $100,y
   cmp   #$20
   bne   @filename2

@filename3:
   lda   #$0d
   sta   NAME,x

   cpx   #0
   beq   @filename6

   rts

@filename5:
   iny
   lda   $100,y
   cmp   #$0d
   beq   @filename6

   sta   NAME,x
   inx
   cmp   #$22
   bne   @filename5

   dex
   iny
   lda   $100,y
   cmp   #$22
   bne   @filename3

   inx
   bcs   @filename5

@filename6:

	rts
;   jmp   COSSYN











;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; getnexthexval
;
; parse a 1 or 2 digit hex value from $100,y leaving result in A and $cb. 
; C set if error
;
getnexthexval:
   jsr   $f876       ; get next non-space char from input buffer
   jsr   $f87e       ; convert to hex nybble
   bcs   @error

   sta   $cb

   iny
   lda   $100,y

   jsr   $f87e       ; convert to hex nybble
   bcs   @nomore

   iny
   asl   $cb
   asl   $cb
   asl   $cb
   asl   $cb
   ora   $cb
   sta   $cb

@nomore:
   lda   $cb
   clc

@error:
   rts





;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; more
;
; prompt for a key, return it in A
;
more:
   jsr   print
   .byte "<PRESS A KEY>"
   nop
   jsr   OSRDCH
   pha

   lda   #0                  ; cheesy x-pos reset
   sta   $e0
   jsr   print
   .byte "             "
   nop
   lda   #0
   sta   $e0

   pla
   rts





;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; tab_space
;
; tabs across until horizontal cursor pos is = to val in x
;
tab_loop:
   lda   #$20
   jsr   OSWRCH

tab_space:
   cpx   $e0
   bcs   tab_loop
   rts

tab_space10:
   ldx   #10
   jmp   tab_space

tab_space16:
   ldx   #16
   jmp   tab_space
