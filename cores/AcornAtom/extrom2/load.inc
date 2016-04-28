;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *LOAD [filename] ([address])
;
; Loads specified file to memory. If reload address is specified then this will be
; used in preference to the reload address stored in the file's metadata.
;

STARLOAD:
    jsr  read_filename       ; copy filename into $140
    jsr  LF844               ; set $c9\a = $140, set x = $c9
    jsr  LF95B               ; *LOAD+3

; Fall trough

; LODVEC entry point
;
; 0,x = file parameter block
;
; 0,x = file name string address
; 2,x = data dump start address
; 4,x  if bit 7 is clear, then the file's own start address is to be used
;
osloadcode:
    ; transfer control block to $c9 (LFNPTR) onward and check name
    ;
    jsr  CHKNAME

    jsr	open_file_read
    jsr  read_info

;    bit  MONFLAG             ; 0 = mon, ff = nomon
;    bmi  @noprint

;    jsr  print_fileinfo
;    jsr  OSCRLF

@noprint:
    jmp read_file


;----------------------------------------------------------------
; Atom kernal routines rewritten for BBCMMC *LOAD
;----------------------------------------------------------------

; Set filenamepointer to $140

LF844:
	lda #$40
	sta LFNPTR
	sta L00C9
	lda #$1
	sta LFNPTR+1
	sta L00CA
	rts

; Read loadaddress and load file

LF95B:
	ldx #LLOAD
	jsr LF893	; Read loadaddress
	beq LF966
	lda #$0d
	sta LEXEC
LF966:
	jsr LFA76	; Check end of command
	ldx #LFNPTR
	rts

; Read ASCII load address into parameterblock

LF893:
	lda #0
	sta 0,x
	sta 1,x
	sta 2,x
	jsr LF863	; Skip spaces
LF89E:
	lda $100,y
	jsr LF87E	; Convert ASCII hex digit to binary nibble
	bcs LF8BB
	asl a
	asl a
	asl a
	asl a
	sty 2,x
	ldy #4
LF8AE:
	asl a
	rol 0,x
	rol 1,x
	dey
	bne LF8AE
	ldy 2,x
	iny
	bne LF89E
LF8BB:
	lda 2,x
	rts

; Convert ASCII hex char to binary value

LF87E:
	cmp #$30
	bcc LF891
	cmp #$3a
	bcc LF88E
	sbc #7
	bcc LF891
	cmp #$40
	bcs LF890
LF88E:
	and #$f
LF890:
	rts
LF891:
	sec
LFA1F:
	rts

; Check end of command

LFA76:
	jsr LF863
	cmp #$0d
	beq LFA1F
LFA77:
	brk
	.byte $fe
	.byte "BAD COMMAND"
	.byte 0,0