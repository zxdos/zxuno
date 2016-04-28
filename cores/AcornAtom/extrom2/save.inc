;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; STARSAVE
;
; Parses filename then resumes execution of the BIOS' save routine.
;

STARSAVE:
   jsr  read_filename       ; copy filename into $140
   jsr  LF844               ; set $c9\a = $140, set x = $c9
   jsr  LFABE               ; scan parameters and jmp through SAVVEC

; Fall through

;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; SAVVEC
;
; 0,x = file parameter block
;
; 0,x = file name string address
; 2,x = data reload address
; 4,x = data execution address
; 6,x = data start address
; 8,x = data end address + 1
;
ossavecode:
;   jsr  $f84f               ; copy data block at $00,x to COS workspace at $c9

   jsr  CHKNAME
   jsr	open_file_write     ; returns with any error in A

   and   #$3f
   beq   @continue

   cmp   #$08              ; FILE EXISTS
   beq   @askover   

   jmp   expect64orless    ; other kind of error

@askover:
   jsr   overwrite

   pha
   jsr   OSCRLF
   pla
   cmp   #'Y'
   beq   @preparetocont

   rts

@preparetocont:
   jsr	delete_file

   jsr	open_file_write     
   jsr   expect64orless

@continue:
   lda   SLOAD           ; tag the file info onto the end of the filename data
   sta   $150
   lda   SLOAD+1
   sta   $151
   lda   SEXEC
   sta   $152
   lda   SEXEC+1
   sta   $153
   sec
   lda   SEND+1
   sbc   SSTART+1
   sta   $155
   lda   SEND
   sbc   SSTART
   sta   $154

   ldx   #$ff          ; zero out any data after the name at $140

@mungename:
   inx
   lda   NAME,x
   cmp   #$0d
   bne   @mungename

   lda   #0

@munge2:
   sta   NAME,x
   inx
   cpx   #16
   bne   @munge2

   jsr   write_info         ; write the ATM header

   jsr   write_file         ; save the main body of data

; Don't need to call CLOSE_FILE here as write_file calls it.
;   CLOSE_FILE

;   bit   MONFLAG             ; 0 = mon, ff = nomon
;   bmi   @noprint

;   ldx   #5
   
;@cpydata:
;   lda   $150,x
;   sta   LLOAD,x
;   dex
;   bpl   @cpydata
   
;   jsr   print_fileinfo

;@noprint:

	rts
   jmp   OSCRLF





overwrite:
   jsr   STROUT
   .byte "OVERWRITE (Y):"
   nop

   jsr   OSRDCH
   jmp   OSWRCH

;----------------------------------------------------------------
; Atom kernal routines rewritten for BBCMMC *SAVE
;----------------------------------------------------------------

LFABE:
	ldx #SLOAD
	jsr LFA65	; Interpret start address

	ldx #SEND
	jsr LFA65	; Interpret end address

	ldx #SEXEC
	jsr LF893	; Interpret run address

	php
	lda SLOAD
	ldx SLOAD+1
	plp
	bne LFAD9
	sta SEXEC
	stx SEXEC+1
LFAD9:
	sta SSTART
	stx SSTART+1
	jsr LFA76
	ldx #SFNPTR
LFADA:
	rts

; Convert ASCII address into binary and store as parameter

LFA65:
	jsr LF893	; Read address
	bne LFADA	; Return if ok
	jmp LFA77	; Generate error
