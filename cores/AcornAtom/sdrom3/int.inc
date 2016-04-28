;=================================================================
; INT.INC
; v01.07 !!!!!!!!!!! FINAL VERSION FOR SDROM v1 !!!!!!!!!!!!!!!!!!
; v02.00 !!!!!!!!!!! FINAL VERSION FOR SDROM v2 !!!!!!!!!!!!!!!!!!
; v02.10 !!!!!!!!!!! FINAL VERSION FOR SDROM v2.1 !!!!!!!!!!!!!!!!
; v02.20 !!!!!!!!!!! FINAL VERSION FOR SDROM v2.2 !!!!!!!!!!!!!!!! 
; v03.00 !!!!!!!!!!! AtoMMC2 interface version !!!!!!!!!!!!!!!!!!!
; v03.10 !!!!!!!!!!! *DVER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; v03.20 !!!!!!!!!!! *RUN file and *file problem solved !!!!!!!!!!
; v03.21 !!!!!!!!!!! *RUN file and *file problem now solved !!!!!!
; v03.22 !!!!!!!!!!! Corrected stack overflow interpreter !!!!!!!!
; v03.24 !!!!!!!!!!! PHS - Merged in routines for AVR/AtomClone !!
; v03.25 !!!!!!!!!!! *RUN file and *file problem now solved !!!!!!
; v03.26 !!!!!!!!!!! Several problems with AVR build solved !!!!!!
;=================================================================

;=================================================================
; Register definition, generated from PIC firmware headers.
;=================================================================

.ifdef ALTADDR
AREG_BASE			=	$b408
.else
AREG_BASE			=	$b400
.endif

ACMD_REG			=	AREG_BASE+CMD_REG
ALATCH_REG          =	AREG_BASE+LATCH_REG             
AREAD_DATA_REG      =	AREG_BASE+READ_DATA_REG             
AWRITE_DATA_REG     =	AREG_BASE+WRITE_DATA_REG             
ASTATUS_REG			= 	AREG_BASE+STATUS_REG	


;=================================================================
; VARIABLE DECLARATION
;=================================================================

debug           = 0

stackpointer    = $4                 ; Standard Atom address
stack1          = $16
stack2          = $25
stack3          = $34
stack4          = $43

qual            = $AC
backup_qual     = $AD
tmp_ptr3        = $D5
tmp_ptr5        = $D6
tmp_ptr6        = $D7
cur_drive       = $EE
mon_flag        = $EF
 
data            = $80
drivenr         = data
disknr          = data+2
sector          = data+4
cur_status      = data+8
RWPTR           = data+9
RWLEN           = data+11
RWTMP           = data+13

work            = $90

NAME            = $140
catbuf          = $2000

next_param      = $C231              ; OS calls
no_com_found    = $C546
no_com          = $C558
prtdec          = $C589
read_param      = $C8BC
dos_init        = $E000
prttxt          = $F7D1
prtspc          = $F7FD
prthex          = $F802
prtdigit        = $F80B
skip_space      = $F876
read_opt_addr   = $F893
command_error   = $F926
read_addr       = $FA65
cos_post_test   = $FA76
wait_key        = $FE94
OSWRCH          = $FFF4
OSCRLF          = $FFED

;=================================================================
; ROM IDENTIFIER
;=================================================================

romid:         .byte $40,$BF

;=================================================================
; COMMAND INTERPRETER
;=================================================================

comint:         LDX #$FF               ; Set up pointers
comint1:        LDY $5E
                DEY
comint2:        INX
                INY

comint3:		LDA com_tab,X          ; Lookup command
                BMI comint5
                CMP ($05),Y
                BEQ comint2
comint4:        INX
                LDA com_tab-1,X
                BPL comint4
                LDA  ($05),Y
                CMP #'.'
                BNE comint1
                INY
                DEX
                BCS comint3

comint5:         STY $3                 ; Store addresspointer
                STA $53
                LDA com_tab+1,X
                STA $52
                LDX #0
                STX $4
                JSR comint6            ; Execute command
                LDX #0
                STX $4
                JMP no_com

comint6:        JMP ($0052)

;=================================================================
; STAR-COMMAND INTERPRETER
;=================================================================

star_com:       LDX #8                 ; Set up pointers
                CLD
star_com1:      LDY #0
                JSR skip_space
                DEY
star_com2:      INY
                INX

star_com3:      LDA com_tab,X          ; Look up star-command
                BMI star_com5
                CMP $100,Y
                BEQ star_com2
                DEX
star_com4:      INX
                LDA com_tab,X
                BPL star_com4
                INX
                LDA $100,Y
                CMP #'.'
                BNE star_com1
                INY
                DEX
                BCS star_com3

star_com5:      STY $9A

                LDY $3                 ; Save command pointers
                STY tmp_ptr3
                LDY $5
                STY tmp_ptr5
                LDY $6
                STY tmp_ptr6
                LDY #<$100
                STY $5
                LDY #>$100
                STY $6
                LDY $9A
                STY $3

                STA $53                ; Execute star command
                LDA com_tab+1,X
                STA $52
                JSR comint6

                LDY tmp_ptr5           ; Restore command pointers
                STY $5
                LDY tmp_ptr6
                STY $6
                LDY tmp_ptr3
                STY $3

                LDA #$0D
                STA ($5),Y

                RTS 

;=================================================================
; COMMAND TABLE
;=================================================================

com_tab:        .byte 	"SDDOS" 
                FNADDR 	sddos
				FNADDR	no_com_found			; End of command table

; *DOS commands
dos_tab:
                .byte 	"CAT"
                FNADDR	cat
                
				.byte 	"DELETE"
                FNADDR	delete
                
				.byte 	"DIR"
                FNADDR	dir
                
				.byte 	"DRIVE"
                FNADDR	drive
				
                .byte 	"FORMAT"
                FNADDR	format
				
                .byte 	"INFO"
                FNADDR	info
				
                .byte 	"INFALL"
                FNADDR	infall
				
                .byte 	"LOAD"
                FNADDR	load
				
                .byte 	"LOCK"
                FNADDR	lock
				
                .byte 	"MON"
                FNADDR	mon
				
                .byte 	"NOMON"
                FNADDR	nomon
				
                .byte 	"RUN"
                FNADDR	run
				
                .byte 	"SAVE"
                FNADDR	save
				
                .byte 	"SET"
                FNADDR	set
				
                .byte 	"TITLE"
                FNADDR	title
				
                .byte 	"UNLOCK"
                FNADDR	unlock
                
				.byte 	"USE"
                FNADDR	use

; *SDDOS commands
sddos_tab:      .byte 	"COS"
                FNADDR	cos
				
                .byte 	"DOS"
                FNADDR	dos
				
                .byte 	"DIN"
                FNADDR	din
				
                .byte 	"DOUT"
                FNADDR	dout
				
                .byte 	"DCAT"
                FNADDR	dcat
				
                .byte 	"DDISKS"
                FNADDR	ddisks
				
                .byte 	"DHELP"
                FNADDR	dhelp
				
                .byte 	"DVER"
                FNADDR	dversion

				FNADDR	exec_file	; Check for file

;=================================================================
; DOS COMMANDS
;
;   Changed DOS commands to handle disk images stored on SD-card
;   Random Access File handling is not implemented
;   The changed commands are:
;
;     *CAT <drvnr>
;     *DELETE <filename>
;     *DIR <drvnr>
;     *DRIVE <drvnr>
;     *FORMAT <drvnr>
;     *INFALL
;     *INFO <filename>
;     *LOAD <filename> <loadaddress>
;     *LOCK <filename>
;     *MON
;     *NOMON
;     *RUN <filename> <param>
;     *SAVE <filename> <startaddress> <endaddress> <linkaddress>
;     *SET<qual>
;     *TITLE "<txt>"
;     *UNLOCK <filename>
;     *USE<qual>
;     *<filename> <param>
;
;=================================================================

;-----------------------------------------------------------------
; *CAT <drvno>
;
;  Display alphabetical sorted catalog of disk <drvno>
;
;  Zeropage usage: $AC,$AE,$AF,$B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8
;-----------------------------------------------------------------

cat:            JSR dir                ; Read catalog

cat1:           ldx #$00               ; Print title
                stx $B6
cat2:           lda $2000,X
                cpx #$08
                bcc cat3
                lda $20F8,X
cat3:           jsr $FFF4
                inx
                cpx #$0D
                bne cat2

                jsr prttxt             ; Print "DRIVE "
                .byte " DRIVE "
                nop

                lda cur_drive          ; Print drivenr
                jsr $F80B

                jsr prttxt             ; Print "QUAL "
                .byte " QUAL "
                nop

                lda qual               ; Print qual
                jsr $FFF4

cat4:           ldy #$00
                jsr cat7 
                bcc cat14
cat5:           jsr LE109              ; Y=Y-8
                lda $2008,Y
                and #$7F
                sta $2008,Y
                tya
                bne cat5
                jmp OSCRLF             ; Jump to next line

cat6:           jsr LE100              ; Y=Y+8

cat7:           cpy $2105              ; Check all files print?
                bcs cat8
                lda $2008,Y
                bmi cat6

cat8:           rts                    ; End of routine

cat9:           ldy $B8                ; A4 B8
                beq cat10              ; F0 05
                jsr OSCRLF             ; 20 ED FF
                ldy #$FF               ; A0 FF
cat10:          iny                    ; C8
                sty $B8                ; 84 B8
                jsr LE0F1              ; 20 F1 E0
cat11:          lda #'#'               ; A9 23
                ldy $B7                ; A4 B7
                ldx $200F,Y            ; BE 0F 20
                bmi cat12              ; 30 02
                lda #' '
cat12:          jsr OSWRCH             ; Print space or #
                ldx #$00               ; A2 00
cat13:          lda $AE,X              ; B5 AE
                jsr $FFF4              ; 20 F4 FF
                inx                    ; E8
                cpx #$07               ; E0 07
                bne cat13              ; D0 F6
                beq cat4               ; F0 AF

cat14:          sty $B7                ; 84 B7
                ldx #$00               ; A2 00
cat15:          lda $2008,Y            ; B9 08 20
                and #$7F               ; 29 7F
                sta $AE,X              ; 95 AE
                iny                    ; C8
                inx                    ; E8
                cpx #$08               ; E0 08
                bne cat15              ; D0 F3

cat16:          jsr cat7               ; 20 88 E2
                bcs cat18              ; B0 1D
                ldx #$06               ; A2 06
                sec                    ; 38
cat17:          lda $200E,Y            ; B9 0E 20
                sbc $AE,X              ; F5 AE
                dey                    ; 88
                dex                    ; CA
                bpl cat17              ; 10 F7
                jsr LE101              ; 20 01 E1
                lda $200F,Y            ; B9 0F 20
                and #$7F               ; 29 7F
                sbc $B5                ; E5 B5
                bcc cat14              ; 90 D2
                jsr LE100              ; 20 00 E1
                bcs cat16              ; B0 DE
cat18:          ldy $B7                ; A4 B7
                lda $2008,Y            ; B9 08 20
                ora #$80               ; 09 80
                sta $2008,Y            ; 99 08 20
                lda $B5                ; A5 B5
                cmp $B6                ; C5 B6
                beq cat9               ; F0 92
                sta $B6                ; 85 B6

                jsr OSCRLF             ; 20 ED FF

                lda $B5                ; A5 B5
                jsr $FFF4              ; 20 F4 FF

                lda #':'               ; Print ':'
                jsr $FFF4

                ldy #$04               ; Print 4 spaces
                jsr LE0F3

                sty $B8                ; Forced jump
                beq cat11

cat19:          lda $210E,Y            ; B9 0E 21
                jsr LE0FB              ; Multiply with 8
                sta $A2                ; 85 A2
                clc                    ; 18
                lda #$FF               ; A9 FF
                adc $210C,Y            ; 79 0C 21
                lda $210F,Y            ; B9 0F 21
                adc $210D,Y            ; 79 0D 21
                sta $A3                ; 85 A3
                lda $210E,Y            ; B9 0E 21
                and #$0F               ; 29 0F
                adc $A2                ; 65 A2
                sta $A2                ; 85 A2
cat20:          sec                    ; 38
                lda $2107,Y            ; B9 07 21
                sbc $A3                ; E5 A3
                pha                    ; 48
                lda $2106,Y            ; B9 06 21
                and #$0F               ; 29 0F

                sbc $A2                ; E5 A2
                tax                    ; AA
                lda #$00               ; A9 00
                cmp $A0                ; C5 A0
                pla                    ; 68
                sbc $A1                ; E5 A1
                txa                    ; 8A
                sbc #$00               ; E9 00
                rts                    ; 60

;-----------------------------------------------------------------
; *DELETE <filename>
;
;  Deletes a file from the catalog
;
;  Zeropage usage: $9A
;-----------------------------------------------------------------

delete:         JSR chk_name           ; Check legal name
                LDA catbuf+$F,Y        ; Check file locked?
                BMI delete1

                JSR chk_disk_wp        ; Check disk protected
                JSR file_info          ; Print file info

                LDY $9A     
                JSR file_del           ; Delete file from catalog

                JSR catalog_w          ; Save catalog from $2000
                JMP lodvec2

delete1:        JSR prttxt             ; Error, file was protected
                .byte "PROT?"
                NOP
                BRK

;-----------------------------------------------------------------
; *DIR <drvno>
;
;  Read catalog in buffer $2000-$21FF
;
;  Zeropage usage: -
;-----------------------------------------------------------------

dir:            JSR drive              ; Check if <drvno> given
                JMP catalog_r          ; If changed, read catalog
  
;-----------------------------------------------------------------
; *DRIVE <drvno>
;
;  Set drivenr
;
;  Zeropage usage: $EE = drive
;-----------------------------------------------------------------

drive:          JSR skip_space         ; Skip spaces until #0D
                CMP #$0D               ; Check if <drvno> given
                BEQ drive1             ; If not, return

                JSR get_drivenr        ; Read drivenr
                EOR cur_drive          ; Check drivechange
                CMP #$80
                BEQ drive1
                EOR cur_drive
                STA cur_drive          ; Set new drivenr

drive1:         RTS

;-----------------------------------------------------------------
; *INFO <filename>
;
;  Info on filename
;
;  Zeropage usage: $9A
;-----------------------------------------------------------------

info:           JSR chk_name            ; Check legal name
                JMP file_info1          ; Print file info

;-----------------------------------------------------------------
; *INFALL
;
;  Info about all files on disk
;
;  Zeropage usage: $9A
;-----------------------------------------------------------------

infall:         JSR catalog_r          ; Read catalog into $2000
                LDY #0
                STY $9A
                
infall1:        JSR file_info1          ; Print file info
                LDY $9A
                JSR LE100              ; Pointer to next file
                STY $9A
                CPY catbuf+$105        ; Check last file?
                BNE infall1

                RTS

;-----------------------------------------------------------------
; *FORMAT <drv>
;
;   Clear catalog of diskimagefile in drive drv
;
;    <drv> 0-3
;-----------------------------------------------------------------

format:         JSR get_drivenr                 ; Read disknumber
                JSR chk_end_command
               
                JSR status_disk_r               ; Read disk status
                JSR chk_disk

                JSR prttxt
                .byte "FORMAT DRIVE:"
                NOP
                LDA drivenr
                JSR prthex
                JSR ask_yes_no
                PHA
                JSR OSWRCH
                PLA
                CMP #'Y'              
                BEQ form2
                JMP OSCRLF 

form2:          JSR OSCRLF 

                LDA #' '                        ; Clear title
                LDX #0
form1:          STA catbuf,X
                STA catbuf+$100,X
                INX
                BNE form1

                LDA #0                          ; Reset filecounter
                STA catbuf+$105

                LDA #>400                       ; Set free sectors
                STA catbuf+$106
                LDA #<400
                STA catbuf+$107

                JSR catalog_w                   ; Save catalog from $2000
                JMP diskchange                  ; Set diskchangeflag

;-----------------------------------------------------------------
; *LOAD <filename>,<loadaddress>
;
;  Load filename at <loadaddress>
;  $9A/$9B = Pointer to filename (normal $140)
;  $9C/$9D = Loadaddress
;  $9E     = Loadaddress given flag, if given     $9E =  $FF
;                                    if not given $9E <> $FF
;
;  Zeropage usage: $9E
;-----------------------------------------------------------------

load:           JSR read_filename      ; Copy filename into $140

                LDX #$9C               ; Read loadaddress at $9C
                JSR read_opt_addr      
                BEQ load1              ; If no loadaddress, jump
load2:
                LDA #$FF               ; Mark loadaddress given
                STA $9E

load1:          LDX #$9A               ; Fileinfo pointer at $9A
                CLC
                JMP ($20C)             ; Load file

;-----------------------------------------------------------------
; LODVEC, Entry for LOAD and *LOAD commands
;
;  Fileinfo is at $00,X
;  If $9E<>$FF then read loadaddress from catalog to $9C/$9D
;
;  Zeropage usage: $9C/$9D = Load address
;                  $9E/$9F = Execaddress
;                  $A0/$A1 = Filelength
;                  $A2/$A3 = Sector address
;                  $A5-$AB = Filename
;-----------------------------------------------------------------

LODVEC:         JSR chk_name1           ; Check legal name

                LDX #0
                LDA $9E
                BPL lodvec1            ; Check if loadaddress given
                LDX #2
                INY
                INY

lodvec1:        LDA catbuf+$108,Y      ; Copy fileinfo to $9C
                STA $9C,X
                INY
                INX
                CPX #8
                BNE lodvec1

                LDA $9C                ; Set loadaddress
                STA RWPTR
                LDA $9D
                STA RWPTR+1

                LDA $A0                ; Set filelen
                STA RWLEN
                LDA $A1
                STA RWLEN+1

                JSR loadfile           ; Load file

                LDY $9A
                JSR file_info          ; Print file info

lodvec2:        LDA backup_qual        ; Restore qual
                STA qual                
                RTS

;-----------------------------------------------------------------
; Load file, Part of LODVEC routine
;
;  Loads a file into memory
;  Input: SECTOR = SD-sector to start reading
;         RWPTR  = Startaddress memory
;         RWLEN  = Number of bytes to read
;         RWTMP  = Bit7 set will skip first 256 bytes of SD-sector
;
;-----------------------------------------------------------------

loadfile:       LDA $A3
                STA sector
                LDA $A2
                STA sector+1
                LDA #0
                STA sector+2
                LDA #0
                STA sector+3

loadfile1:      LDA RWLEN+1             ; read complete sectors
                BEQ read_part
                JSR sd_sector_r

                INC sector
                BNE loadfile2
                INC sector+1
loadfile2:
                INC RWPTR+1
                DEC RWLEN+1
                BNE loadfile1

read_part:
                LDX RWLEN
                BEQ loadfile8
                JSR sd_sectorpart_r
loadfile8:
                RTS

;-----------------------------------------------------------------
; *LOCK <filename>
;
;  Lock a file on disk
;
;  Zeropage usage: -
;-----------------------------------------------------------------

lock:           SEC                    ; Set lockflag
                JMP unlock1

;-----------------------------------------------------------------
; *MON
;
;  Put monitor on.
;
;  Zeropage usage: $EF = mon_flag
;-----------------------------------------------------------------

mon:            LDX #0                 ; Monitorflag=true
mon2:            
                JSR chk_end_command    ; Check end of command
                STX mon_flag           ; Set Monitorflag

                JMP lodvec2            ; Restore qual

;-----------------------------------------------------------------
; *NOMON
;
;  Put monitor off
;
;  Zeropage usage: $EF = mon_flag
;-----------------------------------------------------------------

nomon:          LDX #$FF               ; Monitorflag=false
                JMP mon2

;-----------------------------------------------------------------
; *RUN <filename> <param>
;
;  Load filename and jump to execaddress
;  If param given, will be copied to $100
;
;  Zeropage usage: -
;-----------------------------------------------------------------

run:            JSR load
                LDY $3
;                JSR read_filename      ; Copy filename into $140
                JSR copy_parm          ; Copy param to $100
;                JSR load1              ; Load file, no loadaddress given
                JMP ($009E)            ; Jump to executionaddress

;-----------------------------------------------------------------
; *SAVE <filename>,<loadaddress>,<endaddress>,<linkaddress>
;
;  Save filename from <loadaddress> to <endaddress>
;  $9A/$9B = Pointer to filename (normal $140)
;  $9C/$9D = Loadaddress
;  $9E/$9F = Execaddress
;  $A0/$A1 = Startaddress
;  $A2/$A3 = Endaddress+1
;  $A5-$AB = Filename
;
;  Zeropage usage: $03,$9E,$9F,$A0,$A1
;-----------------------------------------------------------------

save:           JSR read_filename      ; Copy filename into $140

                LDX #$9C               ; Read loadaddress at $9C
                JSR read_addr

                LDX #$A2               ; Read endaddress at $A2
                JSR read_addr

                LDX #$9E               ; Read Execaddress at $9C
                JSR read_opt_addr

                PHP                    ; Check if execaddress given
                LDA $9C
                LDX $9D
                PLP
                BNE save1

                STA $9E                ; If not exec=loadaddress
                STX $9F

save1:          STA $A0                ; Copy loadaddress
                STX $A1

                STY $3                 ; Check end of command
                JSR cos_post_test

                LDX #$9A               ; Filepointer=$9A
                CLC
                JMP ($20E)             ; Save file

;-----------------------------------------------------------------
; SAVVEC, Entry for SAVE and *SAVE commands
;
;   Fileinfo is at $00,X
;   If filename is in catalog, filelen is checked
;     filelen(new) =< filelen(old) then overwrite entry in cat
;     filelen(new) > filelen(old) then delete entry and add in cat
;
;  Zeropage usage: $9A/$9B = Pointer to filename (normal $140)
;                  $9C/$9D = Loadaddress
;                  $9E/$9F = Execaddress
;                  $A0/$A1 = Startaddress
;                  $A2/$A3 = Endaddress+1
;                  $A5-$AB = Filename
;
;-----------------------------------------------------------------
SAVVEC:         JSR name_check         ; Check legal name

                JSR catalog_r          ; Read catalog into $2000
                JSR chk_disk_wp        ; Check disk protected
                JSR lookup1            ; Find name in catalog
                BCC savvec1            
                JSR file_del           ; Delete file from catalog

savvec1:        LDA $A0                ; Save startadres
                PHA
                LDA $A1
                PHA

                SEC                    ; Filelen into $A0/$A1
                LDA $A2
                SBC $A0
                STA $A0
                LDA $A3
                SBC $A1
                STA $A1

                LDA #0                 ; Set sectorcounter
                STA $A2
                LDA #2
                STA $A3

                LDY catbuf+$105        ; Check disk empty
                BEQ savvec7

                CPY #$F8               ; Check disk full
                BCC savvec12
                JSR prttxt             ; Error, DISK FULL
                .byte "FULL"
                NOP
                BRK

savvec14:       JSR prttxt             ; Error, file was protected
                .byte "PROT?"
                NOP
                BRK

savvec12:       JSR savvec11           ; Calculate space between files
                JMP savvec3            ; Check space

savvec2:        JSR LE109              ; Previous file
                JSR savvec10

savvec3:        TYA
                BEQ savvec4            ; Last file checked

                BCC savvec2            ; No room found

savvec4:        BCS savvec5            ; Room found

                JSR prttxt             ; Error, NO ROOM
                .byte "NO ROOM"
                NOP
                BRK

savvec5:        STY $EA                ; Move up files
                LDY catbuf+$105
savvec6:        CPY $EA
                BEQ savvec7
                LDA catbuf+7,Y
                STA catbuf+$F,Y
                LDA catbuf+$107,Y
                STA catbuf+$10F,Y
                DEY
                BCS savvec6

savvec7:        LDX #0                 ; Save filename
savvec8:        LDA $A5,X
                STA catbuf+8,Y
                INY
                INX
                CPX #8
                BNE savvec8
 
savvec9:        LDA $9B,X              ; Save addresses
                DEY
                STA catbuf+$108,Y
                DEX
                BNE savvec9

                JSR file_info          ; Print file info

                PLA                    ; Restore startaddress
                STA $9D
                PLA
                STA $9C

                LDY catbuf+$105        ; Increment filecounter
                JSR LE100
                STY catbuf+$105
                JSR catalog_w          ; Save catalog from $2000

                LDA $9C                ; Startaddress at $9C/$9D
                STA RWPTR
                LDA $9D
                STA RWPTR+1

                LDA $A0                ; FileLen at $A0/$A1
                STA RWLEN
                LDA $A1
                STA RWLEN+1

savvec13:       JSR savefile           ; Save file

                JMP lodvec2            ; Restore qual

savvec10:       LDA catbuf+$10E,Y      ; Calculate space
                JSR LE0FB
                STA $A2
                CLC
                LDA #$FF
                ADC catbuf+$10C,Y
                LDA catbuf+$10F,Y
                ADC catbuf+$10D,Y
                STA $A3
                LDA catbuf+$10E,Y
                AND #$F
                ADC $A2
                STA $A2

savvec11:       SEC
                LDA catbuf+$107,Y
                SBC $A3
                PHA
                LDA catbuf+$106,Y
                AND #$F
                SBC $A2
                TAX
                LDA #0
                CMP $A0
                PLA
                SBC $A1
                TXA
                SBC #0
                RTS


;-----------------------------------------------------------------
; Save file, Part of SAVVEC routine
;
;  Saves a file from memory to SD-card
;  Input: SECTOR = AtomDOS sector to start writing
;         RWPTR  = Startaddress memory
;         RWLEN  = Filelength to save
;
;-----------------------------------------------------------------

savefile:       LDA $A3
                STA sector
                LDA $A2
                STA sector+1
                LDA #0
                STA sector+2
                LDA #0
                STA sector+3

savefile1:      LDA RWLEN+1             ; write complete sectors
                BEQ write_part
                JSR sd_sector_w

                INC sector
                BNE savefile2
                INC sector+1
savefile2:
                INC RWPTR+1
                DEC RWLEN+1
                BNE savefile1

write_part:
                LDX RWLEN
                BEQ savefile8
                JSR sd_sector_w
savefile8:
                RTS

;-----------------------------------------------------------------
; *SET<qual>
;
;  Set Qual
;
;  Zeropage usage: $AC = qual
;                  $AD = backup_qual
;-----------------------------------------------------------------

set:            LDY $3                 ; Load commandpointer
                INY                    ; Skip 1 char
                JSR cos_post_test      ; Check end of command

                LDA $FF,Y              ; Read qual
                STA qual               ; Set qual
                STA backup_qual
                RTS

;-----------------------------------------------------------------
; *TITLE <txt>
;
;  Set disktitle
;
;  Zeropage usage: -
;-----------------------------------------------------------------

title:          JSR read_filename      ; Copy filename into $140
                JSR catalog_r          ; Read catalog into $2000
               
                LDX #$FF               ; Check string length<=13
title1:         INX
                LDA NAME,X
                CMP #$0D
                BNE title1
                CPX #$0E
                BCS title2
                JMP title3

title2:         JSR prttxt             ; Error, NAME
                .byte "NAME?"
                NOP
                BRK
 
title3:         JSR status_disk_r
                JSR chk_disk_wp        ; Check disk protected

                LDY #0
title5:         LDA NAME,Y
                CMP #$0D
                BEQ title6
                CPY #8
                BCS title8
                STA catbuf,Y           ; Copy title in catalog part1
                JMP title9
title8:         STA catbuf+248,Y       ; Copy title in catalog part2
title9:         INY
                JMP title5

title6:         CPY #$0D               ; Add spaces if needed
                BEQ title7
                LDA #' '
                CPY #8
                BCS title10
                STA catbuf,Y           ; Copy title in catalog part1
                JMP title11
title10:        STA catbuf+248,Y       ; Copy title in catalog part2
title11:        INY
                JMP title6

title7:         JSR status_disk_w     ; Write status from $2300
                JSR catalog_w          ; Save catalog from $2000
                JMP diskchange         ; Set diskchangeflag

;-----------------------------------------------------------------
; *UNLOCK <filename>
;
;  Unlock a file on disk
;
;  Zeropage usage: -
;-----------------------------------------------------------------

unlock:         CLC                    ; Reset lockflag

unlock1:        PHP
                JSR read_filename      ; Copy filename into $140
                JSR name_check         ; Check legal name

                JSR name_lookup        ; Find name in catalog

                JSR chk_disk_wp        ; Check disk protected

                LDA qual
                ROL A
                PLP
                ROR A
                STA catbuf+$F,Y        ; Set lockbit file in catalog

                JSR file_info          ; Print file info

                JSR catalog_w          ; Save catalog from $2000
                JMP lodvec2            ; Restore qual

;-----------------------------------------------------------------
; *USE<qual>
;
;  Set temperarily qual. Qual will be reset by load,save or
;  info command
;
;  Zeropage usage: $AC = qual
;                  $AD = backup_qual
;-----------------------------------------------------------------

use:            LDA qual               ; Save qual
                STA backup_qual

                LDY $3                 ; Load commandpointer
                INY                    ; Skip 1 char
                JSR cos_post_test      ; Check end of command

                LDA $FF,Y              ; Read qual
                STA qual               ; Set qual
                RTS

;-----------------------------------------------------------------
; *<filename> <param>
;
;  Search for filename on drive 0, load it and jump to execaddress.
;  If param given, will be copied to $100
;
;  Zeropage usage: $AC = qual
;                  $EE = cur_drive
;                  $C7 = temp cur_drive
;                  $C8 = temp qual
;-----------------------------------------------------------------

exec_file:
                JSR read_filename      ; Copy filename into $140
                JSR name_check
                JSR copy_parm          ; Copy param to $100

                JSR lookup1
                BCS exec_file1

                JMP command_error

exec_file1:     LDA cur_drive          ; Save drive + qual
                STA $C7
                LDA qual
                STA $C8
                LDA #' '
                STA qual
                LDA #0
                STA cur_drive
	sta $9e

                JSR load1              ; Load file, no loadaddress given

                LDA $C7                ; Restore drive + qual
                STA cur_drive
                LDA $C8
                STA qual

                JMP ($09E)             ; Jump to executionaddress

;=================================================================
; SUBROUTINES
;=================================================================

;-----------------------------------------------------------------
; Copy parameter until #0D after command to $100
; Used by *RUN and *<filename>
;
; Input:  Y = pointer just after command
;
; Output: $100 contains parameter string 
;-----------------------------------------------------------------

copy_parm:      JSR skip_space         ; Skip spaces

                LDX #0                 ; Copy param to $100
copy_parm1:     LDA $100,Y
                STA $100,X
                INX
                INY
                CMP #$0D               ; Copy until #0D
                BNE copy_parm1
                RTS

;-----------------------------------------------------------------
; Check if current disk not write protect
;-----------------------------------------------------------------

chk_disk_wp:    JSR status_disk_r
                JMP chk_wp             ; Check if not write protect

;-----------------------------------------------------------------
; Check if disk is valid and not write protect
;
; Input: pointer = points to disk in statussector
;-----------------------------------------------------------------

chk_disk:       CMP #$FF               ; Check disk mounted
                BNE chk_wp

                JSR prttxt
                .byte "NO DISK"
                NOP
                BRK

chk_wp:         AND #$1               ; Check if not write protect
                BEQ chk_wp1
                JSR prttxt
                .byte "DISK PROT"
                NOP
                BRK

chk_wp1:  
                RTS

;-----------------------------------------------------------------
; Copy disk info to $9A
; Copy name from $140 to $A5 and add spaces if needed
;
; Input: X = fileinfo pointer
;-----------------------------------------------------------------

name_check:     LDY #0                 ; Copy disk info to $9A
name_check1:    LDA $0,X
                STA $9A,Y
                INX
                INY
                CPY #$0A
                BCC name_check1

                LDA #' '               ; Fill filename with space
                LDY #6
name_check2:    STA $A5,Y
                DEY
                BPL name_check2

name_check3:    INY                    ; Copy filename to $A5
                LDA ($9A),Y
                CMP #$0D
                BEQ name_check4
                CPY #7
                BCS name_check5
                STA $A5,Y
                BNE name_check3

name_check4:    RTS

name_check5:    JMP title2             ; Error, NAME?

;-----------------------------------------------------------------
; Lookup name at $A5 in catalog
;
; Output: Carry set   = file found
;         Carry clear = file not found
;-----------------------------------------------------------------

name_lookup:    JSR lookup1            ; Find filename in catalog
                BCS name_check4
                
                JSR prttxt
                .byte "FILE?"
                NOP
                BRK

lookup1:        JSR catalog_r          ; Read catalog into $2000
                LDY #$F8
lookup2:        JSR LE100              ; INY 8x
                CPY catbuf+$105        ; Check last name
                BCS lookup5
                LDA catbuf+$F,Y
                AND #$7F
                CMP qual
                BNE lookup2
                JSR LE101              ; INY 7x
                LDX #$06
lookup3:        LDA catbuf+7,Y
                CMP $A5,X
                BNE lookup4
                DEY
                DEX
                BPL lookup3
                RTS

lookup4:        DEY
                DEX
                BPL lookup4
                BMI lookup2

lookup5:        CLC
                RTS

;-----------------------------------------------------------------
; Print file info
;
; Input: Y = Filepointer catalog
;-----------------------------------------------------------------

file_info:      LDA mon_flag           ; Skip if monflag not set
                BNE file_info5

file_info1:     LDA catbuf+$F,Y        ; Load Qual
                AND #$7F               ; Mask ASCII char
                JSR OSWRCH             ; Print Qual

                JSR prtspc             ; Print space

                LDX catbuf+$F,Y        ; Load lock bit
                BPL file_info2         ; Not locked, print ' '
                LDA #'#'               ; Locked, print #

file_info2:     JSR OSWRCH             ; Print char

                LDX #$07               ; Print filename
file_info3:     LDA catbuf+8,Y
                JSR OSWRCH
                INY
                DEX
                BNE file_info3

file_info4:     JSR prtspc             ; Print space

                LDA catbuf+$102,Y      ; Print adres
                JSR prthex
                LDA catbuf+$101,Y
                JSR prthex

                INY
                INX
                INY
                CPX #$02               ; Repeat 3 times
                BCC file_info4

                JSR prtspc             ; Print space
                JSR prtspc             ; Print space

                LDA catbuf+$103,Y
                JSR LE0FB              ; Divide by 16
                JSR prtdigit           ; Print digit file>64kB
                LDA catbuf+$102,Y
                JSR prthex             ; Print filesize hb
                LDA catbuf+$101,Y
                JSR prthex             ; Print filesize lb

                JSR prtspc             ; Print space

                LDA catbuf+$103,Y
                JSR prtdigit           ; Print sector>255
                LDA catbuf+$104,Y
                JSR prthex             ; Print sector
                JSR OSCRLF 

file_info5:     RTS

;-----------------------------------------------------------------
; Read filename from $100 to $140
;
; Input:  $9A = pointer just after command
;
; Output: $140 contains filename
;         $9A/$9B = $140
;-----------------------------------------------------------------

read_filename:  LDX #0
                LDY $9A

read_filename1: JSR skip_space
                CMP #$22
                BEQ read_filename5

read_filename2: CMP #$0D
                BEQ read_filename3
                STA NAME,X
                INX
                INY
                LDA $100,Y
                CMP #$20
                BNE read_filename2

read_filename3: LDA #$0D
                STA NAME,X

                LDA #$40
                STA $9A
                LDA #$01
                STA $9B
                LDX #$9A
read_filename4: RTS

read_filename5: INY
                LDA $100,Y
                CMP #$0D
                BEQ read_filename6
                STA NAME,X
                INX
                CMP #$22
                BNE read_filename5
                DEX
                INY
                LDA $100,Y
                CMP #$22
                BNE read_filename3
                INX
                BCS read_filename5

read_filename6: JMP title2

;-----------------------------------------------------------------
; Delete filename from catalog
;
; Input: Y = Filepointer catalog
;-----------------------------------------------------------------

file_del:       LDA catbuf+$F,Y
                BMI file_del2
file_del1:      LDA catbuf+$10,Y
                STA catbuf+$8,Y
                LDA catbuf+$110,Y
                STA catbuf+$108,Y
                INY
                CPY catbuf+$105
                BCC file_del1
                TYA
                SBC #8
                STA catbuf+$105
                RTS

file_del2:      JMP delete1

;=================================================================
; SDDOS COMMANDS
;
;   Commands to handle disk images on a SD-card
;   A disk image is a copy of an original 100 kB Atom disk
;   SDDOS can handle 1023 disk images
;   The first 32 sectors of the SD card are reserved for a Disktable
;   Every disk image occupies 200 sectors on the SD-card
;   SDDOS commands are:
;
;     SDDOS                 , Init SDDOS
;     *COS                  , Init COS
;     *DOS                  , Init DOS
;     *DIN <drvnr>,<dsknr>  , Mount disk image <dsknr> to drive <drvnr>
;     *DOUT <drvnr>         , Unmount disk image <dsknr> from drive <drvnr>
;     *DCAT <filter>        , List disk images files starting with letter <filter>               
;     *DDISKS               , List linked drives and disk images
;     *DPROT <dsknr>        , Protect disk <dsknr>
;     *DUNPROT <dsknr>      , Unprotect disk <dsknr>
;     *DFREE                , Displays number of unformatted disk images
;     *DKILL <dsknr>        , Marks a disk image as unformatted
;     *DRESTORE <dsknr>     , Marks an unformatted disk as formatted
;     *DNEW <drvnr>         , Links the first unformatted disk with drive <drvnr>
;     *DFORM                , Formats the SD-card sector 0-31
;     *DHELP                , List SDDOS commands with Execaddresses
;     *DONBOOT <drv>,<dsk>  , Specify disknr in drivenr at init
;
;=================================================================

;-----------------------------------------------------------------
; SDDOS
;
;   Init SD Disk Operating System and initialise SD-card
;-----------------------------------------------------------------

sddos:
                JSR sd_init            ; Init BOOTDRV.CFG on SD card

                LDA #<star_com         ; Redirect *COM vector
                STA $206
                LDA #>star_com
                STA $207

                LDX #3
sddos4:         LDA vectors,X
                STA $20C,X
                DEX
                BPL sddos4

                LDA #$20               ; Reset Qual
                STA qual
                STA backup_qual

                EOR #$20               ; Reset Drive
                STA cur_drive
                STA $C0
                STA $B9
                STA $BA

                LDY #$FF               ; *NOMON
                STY mon_flag

                RTS

vectors:        .byte <LODVEC,>LODVEC,<SAVVEC,>SAVVEC

;-----------------------------------------------------------------
; *COS
;
;   Init Cassette Operating System
;-----------------------------------------------------------------

cos:            JSR chk_end_command
                LDX #$F
cos1:           LDA $FFA2,X
                STA $20C,X
                DEX
                BPL cos1
                LDA $FF9C
                STA $206
                LDA $FF9D
                STA $207
                RTS

;-----------------------------------------------------------------
; *DOS
;
;   Init Disk Operating System
;-----------------------------------------------------------------

dos:            JSR chk_end_command
                JMP dos_init

;-----------------------------------------------------------------
; *DIN <drv>,<filename>
;
;   Mount SD-diskimage <filename> to drive <drv>
;   When the diskimage is already linked to another drive, an error
;   is generated and the drive is cleared
;
;    <drv> 0-3
;    <filename> max 13 chars
;-----------------------------------------------------------------

din:            JSR get_drivenr                 ; Read drivenr
                LDY $3
                STY $9A
                JSR read_filename               ; Read diskimage name into $140
                STY $3
                JSR chk_end_command

                lda drivenr
                jsr sd_mount

                JMP diskchange                  ; Set diskchangeflag

;-----------------------------------------------------------------
; *DOUT <drv>
;
;   Unmount SD-diskimage <filename> from drive <drv>
;
;    <drv> 0-3
;-----------------------------------------------------------------

dout:           JSR get_drivenr                 ; Read drivenr
                JSR chk_end_command

                lda drivenr
                JMP sd_unmount

;-----------------------------------------------------------------
; *DCAT (<filter>)
;
;   List *.DSK files on SD-card
;   Display list with filter <adsp>
;
;    <adsp>      filter
;                eg R (list SD-diskimage titles starting with R)
;-----------------------------------------------------------------

dsk_filter:	
			.byte	"*.DSK",$00				; look for dsk files
dcat:
            JSR read_filename               ; Read diskimage name into $140
                
            jsr PREPPUTTOB407         ; Reset globalbufferpointer
			ldx	#0
			
dcat_loop_m:
           lda $140,x
           inx
           cmp #$0d
		   beq	dcat_send_filter
           writeport AWRITE_DATA_REG ; Globalbuffer(1..)=filename
           jmp dcat_loop_m

dcat_send_filter:
			ldx		#$ff
dcat_send_filter_loop:
			inx
			lda		dsk_filter,x				; pickup byte
			writeport AWRITE_DATA_REG
            cmp		#$00						; end ?
			bne		dcat_send_filter_loop		; nope keep going


			SLOWCMDI 	CMD_DIR_OPEN			;  open directory

GetNextLoop:
			SLOWCMDI	CMD_DIR_READ        	; get directory item
			cmp   		#STATUS_COMPLETE    	; all done
			bne			@printit
			rts
			
@printit:
			jsr   		getasciizstringto140    ; a = 0 on exit

			readport    AREAD_DATA_REG		; $b406 ; get attribute byte
			and   		#2                      ; hidden?
			bne   		pause
			
			ldy			#0
			lda			NAME					; preload first char
@printloop:
			jsr			OSWRCH					; write it to screen
			iny
			lda			NAME,y					; get char
			bne			@printloop

			jsr			OSCRLF					; print eol
			

pause:
                bit  $b002                   ; stick here while REPT/shift/ctrl pressed
                bvc  pause 
                lda  $b001
                rol  a                       ; shift/rept pressed?
                bcc  pause 
                rol   a
                bcc  pause 
                rol  a                       ; esc pressed?
                bcs   GetNextLoop

                jmp  OSCRLF 
				rts
				
;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; Read an asciiz string to name buffer at $140
;
; on exit y = character count not including terminating 0
;
;	bug: this will keep reading until it hits a 0, if there is not one, it will
;		 keep going forever......
getasciizstringto140:
   jsr				PREPGETFRB406

   ldy  			#$ff

@loop:
   iny
   readport      	AREAD_DATA_REG	; $b406
   sta  			NAME,y
   bne  			@loop

   rts


;-----------------------------------------------------------------
; *DDISKS
;
;   List drives with installed diskimages
;-----------------------------------------------------------------

ddisks:         JSR chk_end_command

                SLOWCMDI CMD_GET_IMG_NAME		; Command read imagenames
                
                FASTCMDI CMD_INIT_READ          ; Reset pointer
                
				pha
				
                LDX #0                         ; Set drivenr
                STX drivenr
                JSR OSCRLF 

ddisks1:        LDA drivenr                    ; Print drivenr
                JSR prtdigit
                LDA #':'                       ; Print ':'
                JSR OSWRCH

				LDA drivenr                    ; get drivenr
                cmp #0
				bne	ddisks4						; nope skip
				pla								; retrieve fist character
				jmp	ddisks4a

ddisks4:        readport AREAD_DATA_REG
ddisks4a:       BEQ ddisks3
                JSR OSWRCH
                JMP ddisks4

ddisks2:        JSR prttxt
                .byte "    -"                    ; Print "-" = NODISK
                NOP

ddisks3:        JSR OSCRLF
                INC drivenr                    ; Next drive
                LDA drivenr
                CMP #4
                BNE ddisks1

                JMP OSCRLF 

;-----------------------------------------------------------------
; DHELP
;
; List all changed DOS DOS and SDDOS commands with there entry
;-----------------------------------------------------------------

dhelp:
				JSR chk_end_command
                JSR OSCRLF 
                JSR prttxt                      ; Print header
                .byte 	"SDDOS V3.27 [TURBO]  (C)KC 2015"
.ifdef AVR
				.byte	" AVR"
.endif
				NOP
                JSR OSCRLF 
                JSR OSCRLF 

                LDY #0                          ; Pointer after SDDOS
dhelp1:         LDX #15
dhelp2:         LDA dos_tab,Y                 ; Print command
                BMI dhelp3
                JSR OSWRCH
                INY
                DEX
                JMP dhelp2

dhelp3:         CPX #4                          ; Align column
                BEQ dhelp4
                LDA #' '
                JSR OSWRCH
                DEX
                BNE dhelp3

dhelp4:         LDA dos_tab,Y                 ; Print linkadres
                JSR prthex
                LDA dos_tab+1,Y
                JSR prthex

                LDA #' '                        ; Print space
                JSR OSWRCH

                INY
                INY
                LDA dos_tab,Y                 ; Check end of commandtable
                CMP #>exec_file
                BNE dhelp5
                LDA dos_tab+1,Y
                CMP #<exec_file
                BEQ dhelp6
dhelp5:         JMP dhelp1

dhelp6:         JMP OSCRLF 

;-----------------------------------------------------------------
; *DVERSION
;
; Print SD interface information
;-----------------------------------------------------------------

dversion:
                JSR chk_end_command    ; Check end of command
                JSR OSCRLF
                JSR prttxt
                .byte "CARDTYPE  : ",$ea
                LDA #CMD_GET_CARD_TYPE
                JSR sd_servicecall_slow
                JSR prthex

                JSR OSCRLF
                JSR prttxt
                .byte "FIRMWARE  : ",$ea
                LDA #CMD_GET_FW_VER
                JSR sd_servicecall_slow
                JSR prthex

                JSR OSCRLF
                JSR prttxt
                .byte "BOOTLOADER: ",$ea
                LDA #CMD_GET_BL_VER
                JSR sd_servicecall_slow
                JSR prthex

                JSR OSCRLF
                JMP OSCRLF

;=================================================================

;=================================================================
; DISK ROUTINES
;=================================================================
;
;   Statusbyte: bit 0 = 0 "READ/WRITE"
;                       1 "READ ONY 
;               $FF "NO VALID DISK"
;=================================================================

changebit       = $80

;-----------------------------------------------------------------
diskchange:     LDA cur_drive                   ; Set diskchangeflag
                AND #3
                STA cur_drive
                RTS
;-----------------------------------------------------------------
setcatalog:     LDA #0                          ; Sector=0
                STA sector
                STA sector+1
                STA sector+2
                STA sector+3

                LDA #<$2000                     ; Load sector at $2000
                STA RWPTR
                LDA #>$2000
                STA RWPTR+1
                RTS

;-----------------------------------------------------------------
status_disk_r:  LDA cur_drive
                JMP sd_drivestatus_r            ; Read status of current disk

;-----------------------------------------------------------------
status_disk_w:  RTS                             ; Write status of current disk

;-----------------------------------------------------------------
catalog_r:      LDA cur_drive                   ; Check if disk changed
                AND #changebit
                BEQ catalog_r1
                JMP catalog_r6

catalog_r1:
                JSR status_disk_r
                JSR chk_disk
                JSR setcatalog
                JSR sd_sector_r                    ; Read sector 0
                INC sector
                INC RWPTR+1
                JSR sd_sector_r                    ; Read sector 1

catalog_r6:     RTS
      
;-----------------------------------------------------------------
catalog_w:
                JSR status_disk_r
                JSR chk_disk
                JSR setcatalog
                JSR sd_sector_w                    ; Write sector
                INC sector
                INC RWPTR+1
                JSR sd_sector_w                    ; Write sector

                LDA cur_drive                   ; Clear diskchangeflag
                ORA #changebit 
                STA cur_drive

                RTS

;=================================================================
; GENERAL SUBROUTINES
;=================================================================

;-----------------------------------------------------------------
; GET_DRIVENR
;
;   Input : -
;   Output: drivenr 0-3 or DRIVE? error
;-----------------------------------------------------------------

get_drivenr:    JSR read_num                    ; Read parameter
                STA drivenr                     ; Error if drivenr>3
                CMP #4       
                BCS get_drivenr1
                LDA drivenr
                RTS

get_drivenr1:   JSR prttxt                      ; Print error
                .byte "DRIVE?"
                NOP
                BRK

;-----------------------------------------------------------------
; Read numeric parameter or calculate expression
;
;   Input : -
;   Output: A=byte0, X=byte1, Y=byte2
;-----------------------------------------------------------------

read_num:       JSR read_param                  ; Read expression on stack
                JSR next_param                  ; Next param

                LDY #0                          ; Reset stackpointer
                STY stackpointer
                LDA stack1                      ; Put byte0 in A
                LDX stack2                      ; Put byte1 in X
                LDY stack3                      ; Put byte2 in Y
                RTS

;=================================================================
; SPACE SAVING ROUTINES
;=================================================================

chk_name:       JSR read_filename      ; Read filename
chk_name1:      JSR name_check         ; Check legal name
                JSR name_lookup        ; Find name in catalog
                STY $9A                ; Store filepointer
                RTS

;-----------------------------------------------------------------
; Check for end of command, #0D 
;-----------------------------------------------------------------

chk_end_command: LDY $3
                JMP cos_post_test

;-----------------------------------------------------------------
; Print "Y/N" and scan key
;-----------------------------------------------------------------

ask_yes_no:     JSR prttxt
                .byte " :(Y/N)"
                NOP
                JMP wait_key                    ; Scan key

;-----------------------------------------------------------------
; Print spaces
;
;   Entry LE0F1, prints 6 spaces
;   Entry LE0F3, prints Y spaces
;-----------------------------------------------------------------

LE0F1:          ldy #$06
LE0F3:          jsr $F7FD                       ; Print space
                dey
                bne LE0F3
                rts

;-----------------------------------------------------------------
; INY loop
;
;   Entry LE100 is 8x INY
;   Entry LE101 is 7x INY
;-----------------------------------------------------------------

LE100:          INY
LE101:          INY
                INY
                INY
                INY
                INY
                INY
                INY
                RTS

;-----------------------------------------------------------------
; DEY 8x loop
;-----------------------------------------------------------------

LE109:          DEY
                DEY
                DEY
                DEY
                DEY
                DEY
                DEY
                DEY
                RTS

;-----------------------------------------------------------------
; LSR loop
;
;   Entry LE0FA is divide A by 32
;   Entry LE0FB is divide A by 16
;-----------------------------------------------------------------

LE0FA:          LSR A
LE0FB:          LSR A
                LSR A
                LSR A
                LSR A
                RTS

; Latch routines for AVR
.ifdef AVR
WaitUntilRead:
    pha
WaitUntilRead1:
	lda		ASTATUS_REG			; Read status reg
	and		#MMC_MCU_READ		; Been read yet ?
	bne		WaitUntilRead1		; nope keep waiting
    pla
	rts

WaitUntilWritten:
    pha
WaitUntilWritten1:
	lda		ASTATUS_REG			; Read status reg
	and		#MMC_MCU_WROTE		; Been written yet ?
	beq		WaitUntilWritten1	; nope keep waiting
    pla
	rts

WaitWhileBusy:
    pha
WaitWhileBusy1:
	lda		ASTATUS_REG			; Read status reg
	and		#MMC_MCU_BUSY		; MCU still busy ?
	bne		WaitWhileBusy1		; yes keep waiting
    pla
	rts
.endif
