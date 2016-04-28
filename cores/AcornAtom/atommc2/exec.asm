;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *EXEC [filename]
;
; Feed bytes from a file to the system as if they were typed.
; Highly experimental :)
;
STAREXEC:
   jsr   read_filename

   jsr	open_file_read

   SETRWPTR NAME     ; get the FAT file size - text files won't have ATM headers

   SLOWCMDI CMD_FILE_GETINFO	

   ldx   #13
   jsr   read_data_buffer

   lda   NAME
   sta   RDCLEN
   lda   NAME+1
   sta   RDCLEN+1

   lda   #0         ; indicate there are no bytes in the pipe
   sta   RDCCNT

   lda   #<execrdch     ; point OSRDCH at our routine
   sta   RDCVEC
   lda   #>execrdch
   sta   RDCVEC+1
   rts


;
; pull characters from the file and return these to the OS
; until none left at which point unhook ourselves
;
; ---== no X or Y reg used ) ==---
;
execrdch:
   php
   cld

sinkchar:
   lda   RDCCNT         ; exhausted our little pool?
   bne   plentyleft

   lda   RDCLEN+1       ; are there pages left in the file?
   bne   @nextread16
   
   lda   RDCLEN         ; less than 16 left in the file?
   cmp   #17
   bcc   @fillpool

@nextread16:
   lda   #16           ; 16 or more left in the file

@fillpool:
   sta   RDCCNT         ; pool count

   lda   RDCLEN         ; file length remaining -= pool count
   sec
   sbc   RDCCNT
   sta   RDCLEN
   bcs   @refillpool

   dec   RDCLEN+1

@refillpool:
   lda   			RDCCNT         		; recover count
   writeportFAST	ALATCH_REG			; set ammount to read
   jsr				interwritedelay

   SLOWCMDI 		CMD_READ_BYTES		; set command	
   cmp   			#STATUS_COMPLETE
   beq   			@allok

   ; error! bail!

   jmp   osrdchcode_unhook    ; eek

@allok:
   jsr	prepare_read_data				; get data from pic

plentyleft:
   dec   RDCCNT         ; one less in the pool
   bne   @finally


   lda   RDCLEN        ; all done completely?
   ora   RDCLEN+1
   bne   @finally


   lda   #$94          ; unhook and avoid trailing 'A' gotcha
   sta   RDCVEC
   lda   #$fe
   sta   RDCVEC+1

	readportFAST   AREAD_DATA_REG	; get char from PIC/AVR
   plp
   rts


@finally:
	readportFAST   AREAD_DATA_REG	; get char from PIC/AVR

   cmp   #$0a            ; lose LFs - god this is so ghetto i can't believe i've done it
   beq   sinkchar     	; this will fubar if the last char in a file is A. which is likely. BEWARE!

   plp
   rts
