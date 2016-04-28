
;=================================================================
; SD.INC
; v01.00 !!!!!!!!!!! FINAL VERSION FOR SDROM v1 !!!!!!!!!!!!!!!!!!
; v02.00 !!!!!!!!!!! FINAL VERSION FOR SDROM v2 !!!!!!!!!!!!!!!!!!
; v02.10 !!!!!!!!!!! FINAL VERSION FOR SDROM v2.1 !!!!!!!!!!!!!!!!
; v02.20 !!!!!!!!!!! FINAL VERSION FOR SDROM v2.2 !!!!!!!!!!!!!!!!
; v03.00 !!!!!!!!!!! AtoMMC2 interface version !!!!!!!!!!!!!!!!!!!
; v03.10 !!!!!!!!!!! SD_servicecall !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; v03.20 !!!!!!!!!!! *RUN file and *file problem solved !!!!!!!!!!
; v03.21 !!!!!!!!!!! *RUN file and *file problem now solved !!!!!!
;=================================================================

;=================================================================
; SD-CARD:
;=================================================================
; The diskimage files are on SD card.
; They have to be mounted by the *DIN command.
; After mounting, relative sectors (256 bytes) can be read/written
; BOOTDRV.CFG contains ONBOOT information of drives. 
;
;  Structure of BOOTDRV.CFG (4 x 18 bytes):
;
;   Drive 0: baseSector(4), filename(12), 0, attribs(1) (tot. 18)
;   Drive 1: baseSector(4), filename(12), 0, attribs(1) (tot. 18)
;   Drive 2: baseSector(4), filename(12), 0, attribs(1) (tot. 18)
;   Drive 3: baseSector(4), filename(12), 0, attribs(1) (tot. 18)
;
;-----------------------------------------------------------------

;===========================================================================
;INIT VARIABLES AND MACROS
;===========================================================================


;-----------------------------------------------------------------
; sd_init
;
;  Initialise SD-interface.
;  If BOOTDRV.CFG exists on the SD-card it will be read and the
;  Atom drives will be mounted.
;  All drives are validated after mounting.
;
;-----------------------------------------------------------------

sd_init:
.IF debug
           rts
.ELSE
;           lda #$3                   ; Initialise SD-interface
;           sta $b40a
;           jsr awaitresult
           SLOWCMDI	CMD_VALID_IMG_NAMES   ; Validate SDDOS imagefiles
           rts
.ENDIF

;-----------------------------------------------------------------
; sd_sector_r
;
;   Read sector (256 bytes) sector from SD-card into address RWPTR
;
;   Input : cur_drive = read from drive
;           sector    = 4 bytes with sector nr
;           RWPTR     = loadaddress
;   Output: -
;
;-----------------------------------------------------------------
; sd_sectorpart_r
;
;   Read part of sector from SD-card into address RWPTR
;
;   Input : cur_drive = read from drive
;           sector    = 4 bytes with sector nr
;           RWPTR     = loadaddress
;           X         = nr of bytes to be read
;   Output: -
;-----------------------------------------------------------------

sd_sector_r:
           jsr read_start            ; Set SDDOS drive + sector 

           ldy #0                    ; Copy globalbuffer to Atom memory
rx1:       readport AREAD_DATA_REG
.IF debug
.ELSE
           sta (RWPTR),y
.ENDIF
           iny
           bne rx1
           rts

sd_sectorpart_r:
           jsr read_start            ; Set SDDOS drive + sector 

           ldy #0                    ; Read X bytes into memory
rx2:       readport AREAD_DATA_REG
.IF debug
.ELSE
           sta (RWPTR),y
.ENDIF
           dex
           beq rx3
           iny
           bne rx2
rx3:
           rts

read_start:
           jsr PREPPUTTOB407         ; Reset globalbufferpointer

           lda cur_drive             ; Send drivenr
           and #3
           writeport AWRITE_DATA_REG             
           lda sector                ; Send sectornr LB
           writeport AWRITE_DATA_REG
           lda sector+1              ; Send sectornr
           writeport AWRITE_DATA_REG
           lda sector+2              ; Send sectornr
           writeport AWRITE_DATA_REG
           lda sector+3              ; Send sectornr HB
           writeport AWRITE_DATA_REG
           nop                       ; Wait, until command finished!!!

           FASTCMDI CMD_LOAD_PARAM   ; Command = load SDDOS parameters
           SLOWCMDI CMD_READ_IMG_SEC ; Command = read SDDOS sector
           
           jsr PREPGETFRB406         ; Reset datapointer
           rts
          
;-----------------------------------------------------------------
; sd_sector_w
;
;   Write sector (256 bytes) from address RWPTR to SD-card sector 
;
;   Input : cur_drive = write to from drive
;           sector    = 4 bytes with sector nr
;           RWPTR     = saveaddress
;   Output: -
;-----------------------------------------------------------------

sd_sector_w:      
           jsr write_start           ; Set SDDOS drive + sector

           ldy #0                    ; Copy data into globalbuffer
tx1:       lda (RWPTR),y
           writeport AWRITE_DATA_REG
           iny
           bne tx1

           SLOWCMDI	CMD_WRITE_IMG_SEC    ; Command = write SDDOS sector
           rts
 
sd_sectorpart_w:
           jsr write_start           ; Set SDDOS drive + sector

           ldy #0                    ; Copy data into globalbuffer
tx2:       lda (RWPTR),y
           dex
           beq tx3
           writeport AWRITE_DATA_REG
           iny
           bne tx2
tx3:
           SLOWCMDI CMD_WRITE_IMG_SEC    ; Command = write SDDOS sector
           rts

write_start:
           jsr PREPPUTTOB407         ; Reset globalbufferpointer

           lda cur_drive             ; Send drivenr
           and #3
           writeport AWRITE_DATA_REG             
           lda sector                ; Send sectornr LB
           writeport AWRITE_DATA_REG
           lda sector+1              ; Send sectornr
           writeport AWRITE_DATA_REG
           lda sector+2              ; Send sectornr
           writeport AWRITE_DATA_REG
           lda sector+3              ; Send sectornr HB
           writeport AWRITE_DATA_REG
           nop                       ; Wait, until command finished!!!

           FASTCMDI CMD_LOAD_PARAM       ; Command = load sddos parameters
           
           jsr PREPPUTTOB407         ; Reset globalbufferpointer
           rts

;-----------------------------------------------------------------
; sd_mount
;
;   Mount filename at $140 to drive cur_drive 
;
;   Input : A         = drive to mount
;           $140      = filename
;   Output: filestatus
;-----------------------------------------------------------------

sd_mount:
           pha                       ; Save drivenr
           jsr PREPPUTTOB407         ; Reset globalbufferpointer
           pla                       ; Restore drivenr

           ldx #0                    ; Globalbuffer(0)=drivenr
loop_m:
           writeport AWRITE_DATA_REG ; Globalbuffer(1..)=filename
           lda $140,x
           inx
           cmp #$0d
           bne loop_m

           lda #0                    ; Globalbuffer(x)=stringterminator
           writeport AWRITE_DATA_REG
           jsr interwritedelay

           SLOWCMDI	CMD_FILE_OPEN_IMG    ; Command = SDDOS mount
           rts

;-----------------------------------------------------------------
; sd_unmount
;
;   Unmount drive cur_drive 
;
;   Input : A = drive to unmount
;   Output: -
;-----------------------------------------------------------------

sd_unmount:
           and #3
           writeport ALATCH_REG       ; Send drivenr

           SLOWCMDI	CMD_IMG_UNMOUNT        ; Command = SDDOS unmount
           rts

;-----------------------------------------------------------------
; sd_drivestatus_r
;
;   Get drivestatus cur_drive
;
;   Input : A = drive to check
;   Output: drivestatus
;-----------------------------------------------------------------

sd_drivestatus_r:
           and #3
           writeport ALATCH_REG      ; Send drivenr
	   FASTCMDI CMD_GET_IMG_STATUS ; Command = SDDOS get file attribute
.IF debug
           lda #0
.ENDIF
           rts

;-----------------------------------------------------------------
; sd_dir_reset
;
;   Reset directory pointer
;
;   Input : -
;   Output: errornumber
;-----------------------------------------------------------------

sd_dir_reset:
			FASTCMDI	CMD_INIT_WRITE 	; Make sure no filter on  PIC
			
			lda		#0
			writeport AWRITE_DATA_REG
			
           SLOWCMDI	CMD_DIR_OPEN        ;  get first directory item
           cmp  #65
           bcs  reportDiskFailure
           rts

reportDiskFailure:
           jsr prttxt                ; Error in filterdef
           .byte "FILTER?"
           nop
           brk

;-----------------------------------------------------------------
; sd_dir_reset
;
;   Reset directory pointer
;
;   Input : -
;   Output: errornumber
;-----------------------------------------------------------------

sd_dir_next:
           SLOWCMDI CMD_DIR_READ      	; get directory item
           cmp  #65
           bcs  reportDiskFailure
           rts

;-----------------------------------------------------------------
; sd_servicecall
;
;   Execute servicecall and return code
;
;   Input : servicnr
;   Output: data
;-----------------------------------------------------------------

sd_servicecall:
.ifndef AVR
           writeport ACMD_REG
           readport ACMD_REG
           rts
.endif
sd_servicecall_slow:
			SLOWCMD 
           lda ACMD_REG
           rts
			

;-----------------------------------------------------------------------------------
; Routines for AtoMMC2 interfacing
;-----------------------------------------------------------------------------------

PREPGETFRB406:
          lda 		#CMD_INIT_READ
          writeport ACMD_REG
          jsr 		interwritedelay
          rts
;-----------------------------------------------------------------------------------
PREPPUTTOB407:
          lda 		#CMD_INIT_WRITE
          writeport ACMD_REG

;-----------------------------------------------------------------------------------
interwritedelay:
.ifndef AVR
           lda  #4
           sec
intloop:
           sbc  #1
           bne  intloop
.endif
           rts
;-----------------------------------------------------------------------------------
;awaitresult:
;.IF debug
;           rts
;.ENDIF
;.ifndef AVR
;           lda ACMD_REG
;           bmi awaitresult
;.else
;			jsr	WaitUntilWritten
;.endif
;		   cmp #STATUS_COMPLETE
;           bcs readerror
;           rts

readerror:
           pha
           cmp #$4A
           bne chk2
           jsr prttxt
           .byte "ALREADY MOUNTED"
           nop
           pla
           brk
chk2:
           CMP #$49
           bne chk3
           jsr prttxt
           .byte "NO DISK"
           nop
           pla
           brk
chk3:
           jsr prttxt
           .byte "SD ERROR "
           nop
           pla
           jsr prthex
           brk


SLOWCMD_SUB:
	writeport		ACMD_REG
.ifndef AVR
SlowLoop:

	lda 			#0
	sec 
SLOWCMD_DELAY_LOOP:
	sbc 			#1
	bne 			SLOWCMD_DELAY_LOOP

	lda 			ACMD_REG
	bmi 			SlowLoop
.else
	jsr				WaitWhileBusy	; Keep waiting until not busy
	lda				ACMD_REG		; get status for client
.endif
	cmp 			#STATUS_COMPLETE+1
	bcs 			readerror

	rts