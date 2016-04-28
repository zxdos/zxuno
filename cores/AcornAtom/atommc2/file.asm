open_file_read:
   lda #CMD_FILE_OPEN_READ
   jsr open_file
   jmp expect64orless

open_file_write:
	lda #CMD_FILE_OPEN_WRITE

; Falls through to

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Open file
;
; $140 = name
; a = read/write $01 = read, $11 = write
;
open_file:
   pha
   
   jsr   send_name
   pla
   SLOWCMD 
   rts

send_name:
   jsr	prepare_write_data

   ldx  #0
   beq  @pumpname

@nextchar:
   writeportFAST  AWRITE_DATA_REG	; $b407
   inx

@pumpname:
   lda  NAME,x              ; write filename to filename buffer
   cmp  #$0d
   bne  @nextchar

   lda  #0                  ; terminate the string
   writeportFAST  	AWRITE_DATA_REG	; $b407
   jmp  			interwritedelay


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Get 1st 22 bytes of file to $140
;
; leave the LOAD address in RAM alone if LEXEC is FF.
;
read_info:
    ; read the file header to $140

    SETRWPTR NAME

    lda  #22
    jsr  read_block

    ldy  #5                  ; index of msb of length
    ldx  #3                  ; set up to copy 4 bytes - exec & length

    bit  LEXEC               ; if bit 7 is set on entry we don't overwrite
    bmi  @copyfileinfo    ; the load address

    ldx  #5                  ; otherwise copy 6 bytes including load

@copyfileinfo:
    lda  $150,y
    sta  LLOAD,y
    dey
    dex
    bpl  @copyfileinfo

    rts






;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
;  Read file
;
; (LLOAD) = memory target
; LLENGTH = bytes to read
;

read_file_read:
    lda  #0
    jsr  read_file_adapter

    inc  LLOAD+1
    dec  LLENGTH+1

read_file:
    lda  LLENGTH+1           ; any pages left?
    bne  read_file_read

    lda  LLENGTH             ; any stragglers?
    beq  @alldone

    jsr  read_file_adapter

    lda  LLOAD               ; final adjustment to write pointer
    clc
    adc  LLENGTH
    sta  LLOAD
    bcc  @zerolen

    inc  LLOAD+1

@zerolen:
    stx  LLENGTH             ; zero out the length

@alldone:
	jmp 	closefile
;   lda   #CMD_FILE_CLOSE       ; close file
;   SLOWCMD 
;    jmp  expect64orless




read_file_adapter:
    ; enter with a = bytes to read (0=256)

    pha

    lda  LLOAD
    sta  RWPTR
    lda  LLOAD+1
    sta  RWPTR+1

    pla

    ; falls through to


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read data to memory
;
; a = number of bytes to read (0 = 256)
; (RWPTR) points to target
;
read_block:
    tax

	; ask PIC for (A) bytes of data (0=256)
	writeportFAST	ALATCH_REG	; set ammount to read
	jsr				interwritedelay
	SLOWCMDI 		CMD_READ_BYTES		; set command
    
    jsr  expect64orless

    jsr	prepare_read_data				; tell pic to release the data we just read

    ldy  #0

@loop:
    readportFAST	AREAD_DATA_REG	; then read it
    sta  (RWPTR),y
    iny
    dex
    bne  @loop

    rts






;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; put 1st 22 bytes of data to open file
;
; file needs to be open at this point
;
write_info:
   SETRWPTR NAME
    lda  #22
    jmp  write_block



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Write data to open file
;
; SSTART = address to write from
; SEND   = final address + 1
;
write_file_fullpageloop:
    lda  #0                  ; 1 page
    jsr  write_file_adapter
   
    inc  SSTART+1

write_file:
    lda  SSTART+1
    cmp  SEND+1
    bne  write_file_fullpageloop

    lda  SEND                ; any stragglers to write?
    cmp  SSTART
    beq  closefile

    sec                      ; calc remaining bytes
    sbc  SSTART
    jsr  write_file_adapter

closefile:
    SLOWCMDI	CMD_FILE_CLOSE     ; close the file 
    jmp  		expect64orless


; adapter - falls through to write_block
;
write_file_adapter:
    ldy  SSTART
    sty  RWPTR
    ldy  SSTART+1
    sty  RWPTR+1

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; write a block of data
;
; a = block length (0=256)
; (RWPTR) = source
;
write_block:
    tax                     ; save away the block size
    pha

    jsr	prepare_write_data	; take it

    ldy  #0

@loop:
    lda  			(RWPTR),y           ; upload data
    writeportFAST	AWRITE_DATA_REG	
    iny
    dex
    bne 			@loop

    pla                     	; write block command
	writeportFAST	ALATCH_REG	; ammount to write
	jsr				interwritedelay
	SLOWCMDI 		CMD_WRITE_BYTES	; give command to write
    jmp  			expect64orless

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; delete a file
;
; file to be deleted must be opened with open_read
;
delete_file:
   SLOWCMDI		CMD_FILE_DELETE
   jmp   		expect64orless
