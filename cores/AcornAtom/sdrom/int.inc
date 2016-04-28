;=================================================================
; INT.INC
; v01.07 !!!!!!!!!!! FINAL VERSION FOR SDROM v1 !!!!!!!!!!!!!!!!!!
; v02.00 !!!!!!!!!!! FINAL VERSION FOR SDROM v2 !!!!!!!!!!!!!!!!!!
; v02.10 !!!!!!!!!!! FINAL VERSION FOR SDROM v2.1 !!!!!!!!!!!!!!!!
; v02.20 !!!!!!!!!!! FINAL VERSION FOR SDROM v2.2 !!!!!!!!!!!!!!!! 
; v02.30 !!!!!!!!!!! #Exxx VERSION FOR SDROM v2.3 !!!!!!!!!!!!!!!! 
;=================================================================

;=================================================================
; VARIABLE DECLARATION
;=================================================================

debug           equ 0

stackpointer    equ $4                 ; Standard Atom address
stack1          equ $16
stack2          equ $25
stack3          equ $34
stack4          equ $43

qual            equ $AC
backup_qual     equ $AD
tmp_ptr3        equ $D5
tmp_ptr5        equ $D6
tmp_ptr6        equ $D7
cur_drive       equ $EE
mon_flag        equ $EF
workspace       equ $F0
cur_status      equ workspace+8
RWPTR           equ workspace+9
RWLEN           equ workspace+11
RWTMP           equ workspace+13

data            equ $80
drivenr         equ data
disknr          equ data+2
sector          equ data+4
pointer         equ data+7
tmp_sector      equ data+9
work            equ $90

columnwidth     equ $321               ; @ var

catbuf          equ $2000
sectbuf         equ $2300

next_param      equ $C231              ; OS calls
no_com_found    equ $C546
no_com          equ $C558
prtdec          equ $C589
read_param      equ $C8BC
dos_init        equ $E000
prttxt          equ $F7D1
prtspc          equ $F7FD
prthex          equ $F802
prtdigit        equ $F80B
skip_space      equ $F876
read_opt_addr   equ $F893
command_error   equ $F926
read_addr       equ $FA65
cos_post_test   equ $FA76
wait_key        equ $FE94
prtchr          equ $FFF4
newline         equ $FFED

RDCVEC          equ $20a
FKIDX		equ $3CA

;=================================================================
; BOOT ROUTINE
;=================================================================

   ; test ctrl - if pressed, don't initialise
   ;
   bit $b001
   bvs initialise

   ; don't initialise the firmware
   ; the E000 build 
   jmp   $c2b2             ; set #2900 text space and enter command handler

initialise:
   tya
   pha
   txa
   pha

   ldx   #0
   stx   FKIDX            ; fake key index for OSRDCH patch, just piggybacking

   lda   #43              ;'+'
   sta   $800b

shorttitle:
   lda   version,x
   and   #$bf
   sta   $800d,x
   inx
   cmp   #$20
   bne   shorttitle

   jsr   sddos

   bit $b001
   bmi unpatched

patchosrdch:		; Shift key pressed, start *MENU
   lda   #<osrdchcode
   sta   RDCVEC
   lda   #>osrdchcode
   sta   RDCVEC+1

unpatched:
   pla
   tax
   pla
   tay

   jmp   $c2b2             ; set #2900 text space and enter command handler

; patched os input function
;
; streams fake keypresses to the system
; re-registers the bios' function when
; a> fake keys have all been sent or
; b> when no shift-key is detected
;
osrdchcode:
   php
   cld
   stx   $e4
   sty   $e5
	
   ldx   FKIDX
   lda   fakekeys,x
   cmp	#$0d
   beq   unpatch

   inx
   stx   FKIDX

   ldx   $e4
   ldy   $e5
   plp
   rts

unpatch:
   ; restore OSRDCH, continue on to read a char

osrdchcode_unhook:
   lda   #$94
   sta   RDCVEC
   lda   #$fe
   sta   RDCVEC+1
   
   lda 	#$0d
   pha
   jmp 	$fe5c

fakekeys:
   .byte "*MENU"
   .byte $0d,0

;=================================================================
; COMMAND INTERPRETER
;=================================================================

;comint          LDX #$FF               ; Set up pointers
;comint1         LDY $5E
;                DEY
;comint2         INX
;                INY
;
;comint3         LDA com_tab,X          ; Lookup command
;                BMI comint5
;                CMP ($05),Y
;                BEQ comint2
;comint4         INX
;                LDA com_tab-1,X
;                BPL comint4
;                LDA  ($05),Y
;                CMP #'.'
;                BNE comint1
;                INY
;                DEX
;                BCS comint3
;
;comint5         STY $3                 ; Store addresspointer
;                STA $53
;                LDA com_tab+1,X
;                STA $52
;                LDX #0
;                STX $4
;                JSR comint6            ; Execute command
;                LDX #0
;                STX $4
;                JMP no_com
;
comint6         JMP ($0052)

;=================================================================
; STAR-COMMAND INTERPRETER
;=================================================================

star_com        LDX #$FF                ; Set up pointers
                CLD
star_com1       LDY #0
                JSR skip_space
                DEY
star_com2       INY
                INX

star_com3       LDA com_tab,X          ; Look up star-command
                BMI star_com5
                CMP $100,Y
                BEQ star_com2
                DEX
star_com4       INX
                LDA com_tab,X
                BPL star_com4
                INX
                LDA $100,Y
                CMP #'.'
                BNE star_com1
                INY
                DEX
                BCS star_com3

star_com5       STY $9A

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

com_tab
;                .db 'SDDOS'
;                .db >sddos,<sddos
;                .db >no_com_found,<no_com_found    ; End of command table

; *DOS commands
                .db 'CAT'
                .db >cat,<cat
                .db 'DELETE'
                .db >delete,<delete
                .db 'DIR'
                .db >dir,<dir
                .db 'DRIVE'
                .db >drive,<drive
                .db 'INFO'
                .db >info,<info
                .db 'INFALL'
                .db >infall,<infall
                .db 'LOAD'
                .db >load,<load
                .db 'LOCK'
                .db >lock,<lock
                .db 'MON'
                .db >mon,<mon
                .db 'NOMON'
                .db >nomon,<nomon
                .db 'RUN'
                .db >run,<run
                .db 'SAVE'
                .db >save,<save
                .db 'SET'
                .db >set,<set
                .db 'TITLE'
                .db >title,<title
                .db 'UNLOCK'
                .db >unlock,<unlock
                .db 'USE'
                .db >use,<use

; *SDDOS commands
sddos_tab
;                .db 'COS'
;                .db >cos,<cos
;                .db 'DOS'
;                .db >dos,<dos
                .db 'DIN'
                .db >din,<din
                .db 'DCAT'
                .db >dcat,<dcat
                .db 'DDISKS'
                .db >ddisks,<ddisks
                .db 'DPROT'
                .db >dprot,<dprot
                .db 'DUNPROT'
                .db >dunprot,<dunprot
                .db 'DFREE'
                .db >dfree,<dfree
                .db 'DKILL'
                .db >dkill,<dkill
                .db 'DRESTORE'
                .db >drestore,<drestore
                .db 'DNEW'
                .db >dnew,<dnew
                .db 'DFORM'
                .db >dform,<dform
                .db 'DONBOOT'
                .db >donboot,<donboot
                .db 'DHELP'
                .db >dhelp,<dhelp

                .db >exec_file,<exec_file ; Check for file

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
;     *FORMAT <dsknr>
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

cat             JSR dir                ; Read catalog

cat1            ldx #$00               ; Print title
                stx $B6
cat2            lda $2000,X
                cpx #$08
                bcc cat3
                lda $20F8,X
cat3            jsr $FFF4
                inx
                cpx #$0D
                bne cat2

                jsr prttxt             ; Print 'DR:'
                .byte ' DR:'
                nop

                lda cur_drive          ; Print drivenr
                jsr $F80B

                jsr prttxt             ; Print 'Q:'
                .byte ' Q:'
                nop

                lda qual               ; Print qual
                jsr $FFF4

                jsr prttxt             ; Print 'DSK:'
                .byte ' DSK:'
                nop

                LDA cur_drive          ; Print disknr
                ASL A
                TAY
                LDX workspace,Y
                LDA workspace+1,Y
                TAY
                jsr prt16dec

cat4            ldy #$00
                jsr cat7 
                bcc cat14
cat5            jsr LE109              ; Y=Y-8
                lda $2008,Y
                and #$7F
                sta $2008,Y
                tya
                bne cat5
                jmp newline            ; Jump to next line

cat6            jsr LE100              ; Y=Y+8

cat7            cpy $2105              ; Check all files print?
                bcs cat8
                lda $2008,Y
                bmi cat6

cat8            rts                    ; End of routine

cat9            ldy $B8                ; A4 B8
                beq cat10              ; F0 05
                jsr newline            ; 20 ED FF
                ldy #$FF               ; A0 FF
cat10:          iny                    ; C8
                sty $B8                ; 84 B8
                jsr LE0F1              ; 20 F1 E0
cat11:          lda #'#'               ; A9 23
                ldy $B7                ; A4 B7
                ldx $200F,Y            ; BE 0F 20
                bmi cat12              ; 30 02
                lda #' '
cat12:          jsr prtchr             ; Print space or #
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

                jsr newline            ; 20 ED FF

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

delete          JSR chk_name           ; Check legal name

                LDA catbuf+$F,Y        ; Check file locked?
                BMI delete1

                JSR file_info          ; Print file info

                JSR chk_disk_wp        ; Check disk protected

                LDY $9A     
                JSR file_del           ; Delete file from catalog

                JSR catalog_w          ; Save catalog from $2000
                JMP lodvec2

delete1         JSR prttxt             ; Error, file was protected
                .db 'PROT?'
                NOP
                BRK

;-----------------------------------------------------------------
; *DIR <drvno>
;
;  Read catalog in buffer $2000-$21FF
;
;  Zeropage usage: -
;-----------------------------------------------------------------

dir             JSR drive              ; Check if <drvno> given
                JMP catalog_r          ; If changed, read catalog
  
;-----------------------------------------------------------------
; *DRIVE <drvno>
;
;  Set drivenr
;
;  Zeropage usage: $EE = drive
;-----------------------------------------------------------------

drive           JSR skip_space         ; Skip spaces until #0D
                CMP #$0D               ; Check if <drvno> given
                BEQ drive1             ; If not, return

                JSR get_drivenr        ; Read drivenr
                EOR cur_drive          ; Check drivechange
                CMP #$80
                BEQ drive1
                EOR cur_drive
                STA cur_drive          ; Set new drivenr

drive1          RTS

;-----------------------------------------------------------------
; *INFO <filename>
;
;  Info on filename
;
;  Zeropage usage: $9A
;-----------------------------------------------------------------

info            JSR chk_name            ; Check legal name
                JMP file_info1          ; Print file info

;-----------------------------------------------------------------
; *INFALL
;
;  Info about all files on disk
;
;  Zeropage usage: $9A
;-----------------------------------------------------------------

infall          JSR catalog_r          ; Read catalog into $2000
                LDY #0
                STY $9A
                
infall1         JSR file_info1          ; Print file info
                LDY $9A
                JSR LE100              ; Pointer to next file
                STY $9A
                CPY catbuf+$105        ; Check last file?
                BNE infall1

                RTS

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

load            JSR read_filename      ; Copy filename into $140

                LDX #$9C               ; Read loadaddress at $9C
                JSR read_opt_addr      
                BEQ load1              ; If no loadaddress, jump
                LDA #$FF               ; Mark loadaddress given
                STA $9E

load1           LDX #$9A               ; Fileinfo pointer at $9A
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

LODVEC          JSR chk_name1           ; Check legal name

                LDX #0
                LDA $9E
                BPL lodvec1            ; Check if loadaddress given
                LDX #2
                INY
                INY

lodvec1         LDA catbuf+$108,Y      ; Copy fileinfo to $9C
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

lodvec2         LDA backup_qual        ; Restore qual
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

loadfile        JSR calc_startsector   ; Calculate start of file
                
                BIT RWTMP              ; Check if startsec is odd
                BMI loadfile1
                JMP loadfile2

loadfile1       JSR read_start         ; Skip 256 bytes
                JSR skip_256bytes
                LDX #1
                JMP loadfile4

loadfile2       JSR read_start         ; Start read sector
loadfile3       LDX #2

loadfile4       LDY #0                 ; Read 256 bytes
loadfile5       JSR OSXFERFF
                STA (RWPTR),Y

                LDA RWLEN              ; Decrement filelen
                BNE loadfile6
                DEC RWLEN+1
loadfile6       DEC RWLEN

                LDA RWLEN              ; Check if filelen=0
                ORA RWLEN+1
                BEQ loadfile8

                INY
                BNE loadfile5

                INC RWPTR+1            ; Mempointer + 256 

                DEX                    ; Check if 512 bytes read
                BNE loadfile4

                JSR read_end           ; End reading sector

                INC sector             ; Increment sector
                BNE loadfile7
                INC sector+1
                BNE loadfile7
                INC sector+2
loadfile7       JMP loadfile2          ; Start reading

loadfile8       CPY #0                 ; Finish reading 256bytes
                BEQ loadfile9
                JSR skip_bytes
                DEX

loadfile9       CPX #0                 ; Check to skip s56 bytes
                BEQ loadfile10
                JSR skip_256bytes

loadfile10      JMP read_end           ; End reading sector

skip_256bytes   LDY #0                 ; Skip 256 bytes

skip_bytes      JSR OSXFERFF           ; Skip bytes until Y=256
                INY
                BNE skip_bytes
                RTS

;-----------------------------------------------------------------
; *LOCK <filename>
;
;  Lock a file on disk
;
;  Zeropage usage: -
;-----------------------------------------------------------------

lock            SEC                    ; Set lockflag
                JMP unlock1

;-----------------------------------------------------------------
; *MON
;
;  Put monitor on.
;
;  Zeropage usage: $EF = mon_flag
;-----------------------------------------------------------------

mon             LDX #0                 ; Monitorflag=true
mon2            
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

nomon           LDX #$FF               ; Monitorflag=false
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

save            JSR read_filename      ; Copy filename into $140

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

save1           STA $A0                ; Copy loadaddress
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
SAVVEC          JSR name_check         ; Check legal name

                JSR catalog_r          ; Read catalog into $2000
                JSR chk_disk_wp        ; Check disk protected
                JSR lookup1            ; Find name in catalog
                BCC savvec1            
                JSR file_del           ; Delete file from catalog

savvec1         LDA $A0                ; Save startadres
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
                .db 'FULL'
                NOP
                BRK

savvec12        JSR savvec11           ; Calculate space between files
                JMP savvec3            ; Check space

savvec2         JSR LE109              ; Previous file
                JSR savvec10

savvec3         TYA
                BEQ savvec4            ; Last file checked

                BCC savvec2            ; No room found

savvec4         BCS savvec5            ; Room found

                JSR prttxt             ; Error, NO ROOM
                .db 'NO ROOM'
                NOP
                BRK

savvec5         STY $EA                ; Move up files
                LDY catbuf+$105
savvec6         CPY $EA
                BEQ savvec7
                LDA catbuf+7,Y
                STA catbuf+$F,Y
                LDA catbuf+$107,Y
                STA catbuf+$10F,Y
                DEY
                BCS savvec6

savvec7         LDX #0                 ; Save filename
savvec8         LDA $A5,X
                STA catbuf+8,Y
                INY
                INX
                CPX #8
                BNE savvec8
 
savvec9         LDA $9B,X              ; Save addresses
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

                LDA $A1                ; FileLen at $A0/$A1
                STA RWLEN
                LDA $A0
                BEQ savvec13
                INC RWLEN

savvec13        JSR savefile           ; Save file

                JMP lodvec2            ; Restore qual

savvec10        LDA catbuf+$10E,Y      ; Calculate space
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

savvec11        SEC
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
;  Input: SECTOR = SD-sector to start writing
;         RWPTR  = Startaddress memory
;         RWLEN  = Number of Atom sectors to save
;         RWTMP  = Bit7 set will save first 256 bytes of SD-sector
;
;-----------------------------------------------------------------

savefile        JSR calc_startsector   ; Calculate startsector

                BIT RWTMP              ; Check if startsec is odd
                BMI savefile1
                JMP savefile2

savefile1       JSR savefile8          ; Read sector in $2300-$24FF

                DEC RWPTR+1            ; RWPTR=$2300
                JSR write_start        ; Write $2300-$23FF
                JSR write_256bytes
                JSR savefile9

                LDX #1                 ; Blockcounter=1
                JMP savefile4

savefile2       LDA RWLEN              ; Check if end is odd
                CMP #1
                BNE savefile3
 
                JSR savefile8          ; Read sector in $2300-$24FF
                JSR savefile9

savefile3       JSR write_start        ; Start writing to SD
                LDX #2                 ; Blockcounter=2

savefile4       JSR write_256bytes     ; Write RWPTR(256)

                INC RWPTR+1            ; RWPTR=RWPTR+$100

                DEC RWLEN              ; Check if file is written
                BEQ savefile6

                DEX                    ; Check if 2 blocks are written
                BNE savefile4

                JSR write_end          ; End writing to SD

                INC sector             ; sector=sector+1
                BNE savefile5
                INC sector+1
                BNE savefile5
                INC sector+2                
savefile5       JMP savefile2

savefile6       CPX #2                 ; Check if end is odd
                BNE savefile7

                JSR set_bufaddress     ; RWPTR=$2400
                INC RWPTR+1
                JSR write_256bytes

savefile7       JMP write_end          ; End writing to SD

savefile8       TXA
                PHA

                LDA RWPTR              ; Save RWPTR
                STA RWTMP+1 
                LDA RWPTR+1
                STA RWTMP+2

                JSR set_bufaddress     ; RWPTR=$2300
                JSR sd_sector_r        ; Read sector

                PLA
                TAX
                RTS
                
savefile9       LDA RWTMP+2            ; Restore RWPTR
                STA RWPTR+1
                LDA RWTMP+1
                STA RWPTR
                RTS

write_256bytes  LDY #0                 ; Write 256 bytes from RWPTR
write_bytes     LDA (RWPTR),Y
                JSR OSXFER
                INY
                BNE write_bytes
                RTS

;-----------------------------------------------------------------
; *SET<qual>
;
;  Set Qual
;
;  Zeropage usage: $AC = qual
;                  $AD = backup_qual
;-----------------------------------------------------------------

set             LDY $3                 ; Load commandpointer
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

title           JSR read_filename      ; Copy filename into $140
                JSR catalog_r          ; Read catalog into $2000
               
                LDX #$FF               ; Check string length<=13
title1          INX
                LDA $140,X
                CMP #$0D
                BNE title1
                CPX #$0E
                BCS title2
                JMP title3

title2          JSR prttxt             ; Error, NAME
                .db 'NAME?'
                NOP
                BRK
 
title3          LDA cur_drive          ; Get current disknr
                JSR drive2disk
    
title4          JSR status_disk_r      ; Read status into $2300
                JSR chk_disk_wp        ; Check disk protected

                LDY #0
title5          LDA $140,Y
                CMP #$0D
                BEQ title6
                STA (pointer),Y        ; Copy title in statussector

                CPY #8
                BCS title8
                STA catbuf,Y           ; Copy title in catalog part1
                JMP title9
title8          STA catbuf+248,Y       ; Copy title in catalog part2
title9          INY
                JMP title5

title6          CPY #$0D               ; Add spaces if needed
                BEQ title7
                LDA #' '
                STA (pointer),Y        ; Copy title in statussector

                CPY #8
                BCS title10
                STA catbuf,Y           ; Copy title in catalog part1
                JMP title11
title10         STA catbuf+248,Y       ; Copy title in catalog part2
title11         INY
                JMP title6

title7          JSR status_disk_w     ; Write status from $2300
                JSR catalog_w          ; Save catalog from $2000
                JMP diskchange         ; Set diskchangeflag

;-----------------------------------------------------------------
; *UNLOCK <filename>
;
;  Unlock a file on disk
;
;  Zeropage usage: -
;-----------------------------------------------------------------

unlock          CLC                    ; Reset lockflag

unlock1         PHP
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

use             LDA qual               ; Save qual
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

exec_file       JSR read_filename      ; Copy filename into $140
                JSR name_check
                JSR copy_parm          ; Copy param to $100

                JSR lookup1
                BCS exec_file1

                JMP command_error

exec_file1      LDA cur_drive          ; Save drive + qual
                STA $C7
                LDA qual
                STA $C8
                LDA #' '
                STA qual
                LDA #0
                STA cur_drive
		sta $9e

                JSR load1              ; Load file

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

copy_parm       JSR skip_space         ; Skip spaces

                LDX #0                 ; Copy param to $100
copy_parm1      LDA $100,Y
                STA $100,X
                INX
                INY
                CMP #$0D                ; Copy until #0D
                BNE copy_parm1
                RTS

;-----------------------------------------------------------------
; Check if current disk not write protect
;-----------------------------------------------------------------

chk_disk_wp     LDA cur_status         ; Load current diskstatus
                JMP chk_wp             ; Check if not write protect

;-----------------------------------------------------------------
; Check if disk is valid and not write protect
;
; Input: pointer = points to disk in statussector
;-----------------------------------------------------------------

chk_disk_valid  LDY #$F                ; Load disk status
                LDA (pointer),Y

chk_valid       CMP #$FF               ; Check if valid
                BNE chk_wp1
                JSR prttxt
                .db 'NOT VALID'
                NOP
                BRK

chk_wp          CMP #$00               ; Check if not write protect
                BNE chk_wp1
                JSR prttxt
                .db 'DISK PROT'
                NOP
                BRK

chk_wp1         RTS

;-----------------------------------------------------------------
; Copy disk info to $9A
; Copy name from $140 to $A5 and add spaces if needed
;
; Input: X = fileinfo pointer
;-----------------------------------------------------------------

name_check      LDY #0                 ; Copy disk info to $9A
name_check1     LDA $0,X
                STA $9A,Y
                INX
                INY
                CPY #$0A
                BCC name_check1

                LDA #' '               ; Fill filename with space
                LDY #6
name_check2     STA $A5,Y
                DEY
                BPL name_check2

name_check3     INY                    ; Copy filename to $A5
                LDA ($9A),Y
                CMP #$0D
                BEQ name_check4
                CPY #7
                BCS name_check5
                STA $A5,Y
                BNE name_check3

name_check4     RTS

name_check5     JMP title2             ; Error, NAME?

;-----------------------------------------------------------------
; Lookup name at $A5 in catalog
;
; Output: Carry set   = file found
;         Carry clear = file not found
;-----------------------------------------------------------------

name_lookup     JSR lookup1            ; Find filename in catalog
                BCS name_check4
                
                JSR prttxt
                .db 'FILE?'
                NOP
                BRK

lookup1         JSR catalog_r          ; Read catalog into $2000
                LDY #$F8
lookup2         JSR LE100              ; INY 8x
                CPY catbuf+$105        ; Check last name
                BCS lookup5
                LDA catbuf+$F,Y
                AND #$7F
                CMP qual
                BNE lookup2
                JSR LE101              ; INY 7x
                LDX #$06
lookup3         LDA catbuf+7,Y
                CMP $A5,X
                BNE lookup4
                DEY
                DEX
                BPL lookup3
                RTS

lookup4         DEY
                DEX
                BPL lookup4
                BMI lookup2

lookup5         CLC
                RTS

;-----------------------------------------------------------------
; Print file info
;
; Input: Y = Filepointer catalog
;-----------------------------------------------------------------

file_info       LDA mon_flag           ; Skip if monflag not set
                BNE file_info5

file_info1      LDA catbuf+$F,Y        ; Load Qual
                AND #$7F               ; Mask ASCII char
                JSR prtchr             ; Print Qual

                JSR prtspc             ; Print space

                LDX catbuf+$F,Y        ; Load lock bit
                BPL file_info2         ; Not locked, print ' '
                LDA #'#'               ; Locked, print #

file_info2      JSR prtchr             ; Print char

                LDX #$07               ; Print filename
file_info3      LDA catbuf+8,Y
                JSR prtchr
                INY
                DEX
                BNE file_info3

file_info4      JSR prtspc             ; Print space

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
                JSR newline

file_info5      RTS

;-----------------------------------------------------------------
; Read filename from $100 to $140
;
; Input:  $9A = pointer just after command
;
; Output: $140 contains filename
;         $9a/$9B = $140
;-----------------------------------------------------------------

read_filename   LDX #0
                LDY $9A

read_filename1  JSR skip_space
                CMP #$22
                BEQ read_filename5

read_filename2  CMP #$0D
                BEQ read_filename3
                STA $140,X
                INX
                INY
                LDA $100,Y
                CMP #$20
                BNE read_filename2

read_filename3  LDA #$0D
                STA $140,X

                LDA #$40
                STA $9A
                LDA #$01
                STA $9B
                LDX #$9A
read_filename4  RTS

read_filename5  INY
                LDA $100,Y
                CMP #$0D
                BEQ read_filename6
                STA $140,X
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

read_filename6  JMP title2

;-----------------------------------------------------------------
; Delete filename from catalog
;
; Input: Y = Filepointer catalog
;-----------------------------------------------------------------

file_del        LDA catbuf+$F,Y
                BMI file_del2
file_del1       LDA catbuf+$10,Y
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

file_del2       JMP delete1

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
;     *DIN <drvnr>,<dsknr>  , Link disk image <dsknr> to drive <drvnr>
;     *DCAT <from>,<to>     , List formatted disk images from to               
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
;   Init SD Disk Operating System and reset SD-card
;-----------------------------------------------------------------

sddos_stamp     .db 'SDDOS   '

sddos           JSR sd_init            ; Hardware init SD card

                JSR bootsector_r       ; Read bootsector in sectbuf
                
                LDY #7                 ; Check format SD-card
sddos1          LDA sectbuf+8,Y
                CMP sddos_stamp,Y
                BEQ sddos2
                JSR prttxt             ; No SDDOS format
                .db 'SD FORMAT?'
                NOP
                BRK

sddos2          DEY
                BPL sddos1

                LDY #7                 ; Copy disktable->ws
sddos3          LDA sectbuf,Y
                STA workspace,Y
                DEY
                BPL sddos3

                LDA #<star_com         ; Redirect *COM vector
                STA $206
                LDA #>star_com
                STA $207

                LDX #3
sddos4          LDA vectors,X
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

vectors         .db <LODVEC,>LODVEC,<SAVVEC,>SAVVEC

;-----------------------------------------------------------------
; COS
;
;   Init Cassette Operating System
;-----------------------------------------------------------------
;
;cos             JSR chk_end_command
;                LDX #$F
;cos1            LDA $FFA2,X
;                STA $20C,X
;                DEX
;                BPL cos1
;                LDA $FF9C
;                STA $206
;                LDA $FF9D
;                STA $207
;                RTS

;-----------------------------------------------------------------
; DOS
;
;   Init Disk Operating System
;-----------------------------------------------------------------
;
;dos             JSR chk_end_command
;                JMP dos_init

;-----------------------------------------------------------------
; DIN <drv>,<dno>
;
;   Link SD-diskimage <dno> to drive <drv>
;   When the diskimage is already linked to a drive, the already
;   linked drive will get the code $FFFF (NO DISK) and the drive
;   <drv> will be linked to diskimage <dno>
;
;    <drv> 0-3
;    <dno> 0-1022
;-----------------------------------------------------------------

disk0           equ workspace
disk1           equ workspace+2
disk2           equ workspace+4
disk3           equ workspace+6

din             JSR get_drivenr                 ; Read drivenr
                JSR get_disknr                  ; Read disknr
                JSR chk_end_command
                
din1            LDX #$FF                        ; NODISK if disk in use
                _BNE16 disknr,disk0,din2        ; Disk in drive0?
                STX disk0
                STX disk0+1
                JMP din5
din2            _BNE16 disknr,disk1,din3        ; Disk in drive1?
                STX disk1
                STX disk1+1
                JMP din5
din3            _BNE16 disknr,disk2,din4        ; Disk in drive2?
                STX disk2
                STX disk2+1
                JMP din5
din4            _BNE16 disknr,disk3,din5        ; Disk in drive3?
                STX disk3
                STX disk3+1

din5            LDA drivenr                     ; Write disknr in disktable

                ASL A                           ; Write disk in workspace
                TAX
                LDA disknr
                STA workspace,X
                LDA disknr+1
                STA workspace+1,X

                JMP diskchange                  ; Set diskchangeflag

;-----------------------------------------------------------------
; DCAT <from_dno>,<to_dno>,(<adsp>)
;
;   List formatted SD-diskimages from <from_dno> to <to_dno>
;   Display list with filter <adsp>
;
;    <from_dno>  0-1022
;    <to_dnodno> 0-1022
;    <adsp>      filter
;                eg R (list SD-diskimage titles starting with R)
;-----------------------------------------------------------------

disk_count      equ work
disk_from       equ work+2
disk_to         equ work+4
filter          equ work+6

dcat            JSR get_disknr                  ; Read disk_from
                LDA disknr
                STA disk_from
                LDA disknr+1
                STA disk_from+1

                JSR get_disknr                  ; Read disk_to
                LDA disknr
                STA disk_to
                LDA disknr+1
                STA disk_to+1

                JSR skip_space                  ; Test if filter given
                CMP #$0D
                BEQ dcat1

                LDY $3                          ; Check and store filter
                LDA (5),Y
                CMP #$0D
                BEQ dcat1
                STA filter
                INY
                LDA (5),Y
                CMP #$0D
                BNE dcat7
                STY $3
                JSR next_param
                JMP dcat2

dcat1           LDX #0                          ; No filter given
                STX filter

dcat2           JSR newline

                LDA #0                          ; Reset disk counter
                STA disk_count
                STA disk_count+1

dcat3           LDX disk_from                   ; Load statussector
                LDY disk_from+1
                JSR statussector_r      ; read status into $2300

                LDY #$F                         ; Check disk status
                LDA (pointer),Y
                BMI dcat5

                LDA filter
                BEQ dcat4

                LDY #0 
                LDA (pointer),Y
                CMP filter
                BNE dcat5

dcat4           LDX disk_from                   ; Print disknr+name
                LDY disk_from+1
                JSR print_line
                JSR newline

                INC disk_count                  ; Increment disk counter
                BNE dcat5
                INC disk_count+1  

dcat5           INC disk_from                   ; Next disk
                BNE dcat6
                INC disk_from+1

dcat6           _BLE16 disk_from,disk_to,dcat3  ; Check end

                JSR newline
                JSR prttxt                      ; Print disk counter
                .db 'DISKS FOUND:'
                NOP
                LDX disk_count
                LDY disk_count+1
                JSR prt16dec
                JMP newline

dcat7           JSR prttxt                      ; Error in filterdef
                .db 'FILTER?'
                NOP
                BRK
;-----------------------------------------------------------------
; DDISKS
;
;   List drives with installed diskimages
;-----------------------------------------------------------------

ddisks          JSR chk_end_command

                LDX #0                         ; Set drivenr
                STX drivenr

ddisks1         LDA drivenr                    ; Print drivenr
                PHA
                JSR prtdigit
                LDA #':'                       ; Print ':'
                JSR prtchr

                PLA                            ; Check for NODISK
                JSR drive2disk
                BMI ddisks2

                JSR status_disk_r       ; Read status into $2300

                LDY #$F                        ; Check if disk is valid
                LDA (pointer),Y
                CMP #$FF
                BEQ ddisks2

                LDX disknr                     ; Print diskname + protect
                LDY disknr+1
                JSR print_line
                JSR newline
                JMP ddisks3

ddisks2         JSR prttxt
                .db '   -'                     ; Print '-' = NODISK
                NOP
                JSR newline
       
ddisks3         INC drivenr                    ; Next drive
                LDA drivenr
                CMP #4
                BNE ddisks1

                JMP newline

;-----------------------------------------------------------------
; DPROT <dno>
;
;   Mark SD-diskimage <dno> as Read only
;
;    <dno> 0-1022
;-----------------------------------------------------------------

dprot           JSR get_disknr                  ; Read disknr
                JSR chk_end_command
                
                JSR status_disk_r               ; Read status into $2300
                JSR chk_disk_valid

                LDY #$F                         ; Protect disk
                LDA #$0
                STA (pointer),Y

                JSR status_disk_w              ; Write status from $2300
                JMP diskchange                  ; Set diskchangeflag

;-----------------------------------------------------------------
; DUNPROT <dno>
;
;   Mark SD-diskimage <dno> as Read/Write
;
;    <dno> 0-1022
;-----------------------------------------------------------------

dunprot         JSR get_disknr                  ; Read disknr
                JSR chk_end_command
                
                JSR status_disk_r               ; Read status into $2300
                JSR chk_disk_valid

                LDY #$F                         ; Unprotect disk
                LDA #$0F
                STA (pointer),Y

                JSR status_disk_w               ; Write status from $2300
                JMP diskchange                  ; Set diskchangeflag

;-----------------------------------------------------------------
; DFREE
;
;   Display number of unformatted SD-diskimages
;-----------------------------------------------------------------

free_total      equ work
free_unformat   equ work+2
free_disk       equ work+4

dfree           JSR chk_end_command
                LDA #0                          ; Reset disk counter
                STA free_total
                STA free_total+1
                STA free_unformat
                STA free_unformat+1
                STA free_disk
                STA free_disk+1

dfree1          LDX free_disk                   ; Load statussector
                LDY free_disk+1
                JSR statussector_r              ; read status into $2300

                LDY #$F                         ; Check disk status
                LDA (pointer),Y
                CMP #$FF
                BEQ dfree3

                INC free_total
                BNE dfree2
                INC free_total+1


dfree2          AND #$F0
                BEQ dfree3

                INC free_unformat
                BNE dfree3
                INC free_unformat+1

dfree3          INC free_disk                   ; Next disk
                BNE dfree4
                INC free_disk+1

dfree4          _BLE16I free_disk,1022,dfree1   ; Check end

                LDX free_unformat               ; Number of unformatted disks
                LDY free_unformat+1
                JSR prt16dec

                JSR prttxt
                .db ' OF '
                NOP

                LDX free_total                  ; Number of total disks
                LDY free_total+1
                JSR prt16dec

                JSR prttxt                      ; Print disk counter
                .db ' DISKS FREE'
                NOP

                JMP newline

;-----------------------------------------------------------------
; DKILL <dno>
;
;   Mark SD-diskimage <dno> as unformatted
;
;    <dno> 0-1022
;-----------------------------------------------------------------

dkill           JSR get_disknr                  ; Read disknr
                JSR chk_end_command
                
                JSR status_disk_r               ; Read status into $2300
                JSR chk_disk_valid
                JSR chk_wp

                JSR prttxt
                .db 'KILL DISK:'
                NOP
                JSR prt16disk
                JSR ask_yes_no
                PHA
                JSR prtchr
                PLA
                CMP #'Y'              
                BEQ dkill1
                JMP newline

dkill1          JSR newline
                LDY #$F                         ; Unformat disk
                LDA #$F0
                STA (pointer),Y

                JSR status_disk_w               ; Write status from $2300
                JMP diskchange                  ; Set diskchangeflag

;-----------------------------------------------------------------
; DRESTORE <dno>
;
;
;   Mark SD-diskimage <dno> as formatted without erasing the 
;   diskcatalog
;
;    <dno> 0-1022
;-----------------------------------------------------------------

drestore        JSR get_disknr                  ; Read disk_from
                JSR chk_end_command
                
drestore1       JSR status_disk_r               ; Read status into $2300

                LDY #$F                         ; Protect disk
                LDA #$F
                STA (pointer),Y

                JSR status_disk_w               ; Write status from $2300
                JMP diskchange                  ; Set diskchangeflag

;-----------------------------------------------------------------
; DNEW (<drv>)
;
; 
;   Finds the first unformatted SD-diskimage and install it in
;   drive <drv>
;
;    <drv> 0-3
;-----------------------------------------------------------------

dsk_count       equ work

dnew            JSR drive                       ; Check for drivenr
                JSR chk_end_command
                
                LDA #0                          ; Reset disk counter
                STA dsk_count
                STA dsk_count+1

dnew1           LDX dsk_count                   ; Load statussector
                LDY dsk_count+1
                JSR statussector_r      ; read status into $2300

                LDY #$F                         ; Check disk status
                LDA (pointer),Y
                CMP #$F0
                BEQ dnew3

                INC dsk_count                   ; Next disk
                BNE dnew2
                INC dsk_count+1

dnew2           _BLE16I dsk_count,1022,dnew1    ; Check end

                JSR prttxt                      ; Print disk counter
                .db 'NO DISK FOUND'
                NOP
                JMP dnew4

dnew3           LDA dsk_count                   ; Check if disk in use
                STA disknr
                LDA dsk_count+1
                STA disknr+1
                LDA cur_drive
                STA drivenr
                LDA #0
                JSR din1

                JSR prttxt                      ; Print disk counter
                .db 'DISK '
                NOP

                JSR prt16disk

                JSR prttxt                      ; Print disk counter
                .db ' IN DRIVE '
                NOP

                LDA cur_drive
                JSR prtdigit

dnew4           JMP newline

;-----------------------------------------------------------------
; DFORM <dno>
;
;   Marks SD-diskimage <dno> as formatted and clears the catalog
;   + title in statussector
;
;    <dno> 0-1023
;-----------------------------------------------------------------

dform           JSR get_disknr                  ; Read disknumber
                JSR chk_end_command
                
                JSR status_disk_r               ; Read status into $2300
                JSR chk_disk_valid
                JSR chk_wp

                JSR prttxt
                .db 'FORMAT DISK:'
                NOP
                JSR prt16disk
                JSR ask_yes_no
                PHA
                JSR prtchr
                PLA
                CMP #'Y'              
                BEQ dform2
                JMP newline

dform2          JSR drestore1                   ; Mark disk as formatted
                JSR newline

                LDA #' '                        ; Clear title
                LDX #0
dform1          STA catbuf,X
                STA catbuf+$100,X
                INX
                BNE dform1

                LDA #0                          ; Reset filecounter
                STA catbuf+$105

                LDA #>400                       ; Set free sectors
                STA catbuf+$106
                LDA #<400
                STA catbuf+$107

                JSR catalog_w                   ; Save catalog from $2000

                LDY #0
                LDX #0
dform3          LDA catbuf,X                    ; Clear statustitle
                STA (pointer),Y
                INY
                INX
                CPX #8
                BNE dform3

dform4          LDA catbuf-8+$100,X
                STA (pointer),y
                INY
                INX
                CPX #13
                BNE dform4

                JSR status_disk_w               ; Write status from $2300
   
                JMP diskchange                  ; Set diskchangeflag

;-----------------------------------------------------------------
; DONBOOT <drv>,<dno>
;
;   Specify which SD-diskimage <dno> is in drive <drv> at init
;
;    <drv> 0-3
;    <dno> 0-1022
;-----------------------------------------------------------------

donboot         JSR get_drivenr                 ; Read drivenr
                JSR get_disknr                  ; Read disknr
                JSR chk_end_command
                
                JSR bootsector_r                ; Read disktable

                LDA drivenr                     ; Set drivenr
                ASL A
                TAY
                LDA disknr
                STA sectbuf,Y
                LDA disknr+1
                STA sectbuf+1,Y

                JMP bootsector_w                ; Save disktable
 
;-----------------------------------------------------------------
; DHELP
;
; List all changed DOS DOS and SDDOS commands with there entry
;-----------------------------------------------------------------

dhelp
           JSR chk_end_command
                JSR newline
                JSR prttxt                      ; Print header
version
                .db 'SDDOS V2.3E'
                NOP
                JSR newline
                JSR newline

                LDY #0                          ; Pointer after SDDOS
dhelp1          LDX #15
dhelp2          LDA sddos_tab,Y                 ; Print command
                BMI dhelp3
                JSR prtchr
                INY
                DEX
                JMP dhelp2

dhelp3          CPX #4                          ; Align column
                BEQ dhelp4
                LDA #' '
                JSR prtchr
                DEX
                BNE dhelp3

dhelp4          LDA sddos_tab,Y                 ; Print linkadres
                JSR prthex
                LDA sddos_tab+1,Y
                JSR prthex

                LDA #' '                        ; Print space
                JSR prtchr

                INY
                INY
                LDA sddos_tab,Y                 ; Check end of commandtable
                CMP #>exec_file
                BNE dhelp5
                LDA sddos_tab+1,Y
                CMP #<exec_file
                BEQ dhelp6
dhelp5          JMP dhelp1

dhelp6          JMP newline

;=================================================================

;=================================================================
; DISK ROUTINES
;=================================================================
;
;   Statusbyte: $00 'READ ONY'
;               $0F 'READ/WRITE'
;               $F0 'UNFORMATTED'
;               $FF 'NO VALID DISKNUMBER'
;
;   Disknr    : $FFFF 'NO DISK'
;
;=================================================================

changebit       equ $80

;-----------------------------------------------------------------
diskchange      LDA cur_drive                   ; Set diskchangeflag
                AND #3
                STA cur_drive
                RTS
;-----------------------------------------------------------------
set_bootsector  LDA #0                          ; Sector=0
                STA sector
                STA sector+1
                STA sector+2

set_bufaddress  LDA #<$2300                     ; Load sector at $2300
                STA RWPTR
                LDA #>$2300
                STA RWPTR+1
                RTS

set_dosaddress  LDA #<$2000                     ; Load sector at $2000
                STA RWPTR
                LDA #>$2000
                STA RWPTR+1
                RTS

;-----------------------------------------------------------------
; sector = 0
; RWPTR  = $2300
;
bootsector_r    JSR set_bootsector
                JMP sd_sector_r                 ; Read disktable

;-----------------------------------------------------------------
; sector = 0
; RWPTR  = $2300
;
bootsector_w    JSR set_bootsector
                JMP sd_sector_w                 ; Write disktable

;-----------------------------------------------------------------
; RWPTR  = $2300
;
statussector_r  JSR calc_statsector
                JSR set_bufaddress              ; Read diskheader
                JMP sd_sector_r

status_disk_r   LDX disknr                      ; Convert diskno->sector
                LDY disknr+1
                JMP statussector_r              ; read status into $2300
 
;-----------------------------------------------------------------
; RWPTR  = $2300
;
statussector_w  JSR calc_statsector
                JSR set_bufaddress              ; Write diskheader <dno>
                JMP sd_sector_w

status_disk_w   LDX disknr                      ; Convert diskno->sector
                LDY disknr+1
                JMP statussector_w              ; read status into $2300
 
;-----------------------------------------------------------------
; RWPTR  = $2000
;
catalog_r       LDA cur_drive                   ; Check if disk changed
                AND #changebit
                BEQ catalog_r1
                JMP catalog_r6

catalog_r1      LDA cur_drive                   ; Check if disk in drive
                JSR drive2disk
                BPL catalog_r3

catalog_r2      JSR prttxt
                .db 'NO DISK'
                NOP
                BRK

catalog_r3      JSR status_disk_r       ; Read status into $2300

                LDY #$F                         ; Load disk status
                LDA (pointer),Y
		STA cur_status

                CMP #$F0                        ; Check disk format
                BNE catalog_r4
                JSR prttxt
                .db 'UNFORMATTED'
                NOP
                BRK

catalog_r4      JSR chk_valid

catalog_r5      JSR calc_catsector              ; Calculate startsector cat
                JSR set_dosaddress
                JSR sd_sector_r

                LDA cur_drive                   ; Clear diskchangeflag
                ORA #changebit 
                STA cur_drive

catalog_r6      LDA cur_status
                RTS

;-----------------------------------------------------------------
; RWPTR  = $2000
;
catalog_w       JSR calc_catsector              ; Calculate startsector cat
                JSR set_dosaddress
                JSR sd_sector_w

                LDA cur_drive                   ; Clear diskchangeflag
                ORA #changebit 
                STA cur_drive

                RTS

;=================================================================
; CALCULATIONS
;=================================================================

;-----------------------------------------------------------------
; calc_startsector
;
;   Calculate startsector 
;    = Startsector SD-diskimage + 0,5 x Startsector File AtomDOS
;   Bit 7 of RWTMP is set if Startsector File AtomDOS is odd
;-----------------------------------------------------------------

calc_startsector
                LDA cur_drive          ; Check if disk in drive
                JSR drive2disk

                JSR calc_catsector

                LDA $A3
                LSR A
                ROR RWTMP              ; Set bit7 to skip first 256 bytes

                CLC
                ADC sector
                STA sector

                LDA $A2
                AND #$F
                BEQ calc1
                ADC #$80
                STA sector
calc1           LDA sector+1
                ADC #0
                STA sector+1
                LDA sector+2
                ADC #0
                STA sector+2
                RTS

;-----------------------------------------------------------------
; calc_statsector
;
;   Calculate sector and pointer of position diskno in statustable
;   sector  = ((disknr + 1) * 16) / 512
;   pointer = ((disknr + 1) * 16) % 512
;
;   Input : X       = diskno_lb
;           Y       = diskno_hb
;   Output: sector  = sector with diskheader
;           pointer = pointer pointer to diskheader
;-----------------------------------------------------------------

calc_statsector INX                             ; Increment disknr
                STX sector
                BNE calc_stat1
                INY
calc_stat1      STY sector+1

                LDA #0                          ; Reset Pointer
                STA sector+2                    ; DMB 2/5/14 - Clear MS byte
                STA pointer
                STA pointer+1

                LDX #4                          ; Multiply with 16
calc_stat2      LSR sector+1
                ROR sector
                ROR pointer
                DEX
                BNE calc_stat2

                LSR sector+1                    ; Divide by 512
                ROR sector
                ROL pointer+1

                CLC                             ; Remainder by 512
                LDA pointer
                ADC #<sectbuf
                STA pointer
                LDA pointer+1
                ADC #>sectbuf
                STA pointer+1 
                RTS

;-----------------------------------------------------------------
; calc_catsector
;
;   Calculate startsector of catalog from disknr
;   sector = 200 x disknr + 32
;
;   Input : disknr
;   Output: sector  = startsector catalog
;-----------------------------------------------------------------

calc_catsector  LDA #0                          ; Sector=0
		STA sector
		STA sector+1
		STA sector+2

                STA tmp_sector+2                ; tmp_sector=disknr
                LDA disknr+1
                STA tmp_sector+1
                LDA disknr
                STA tmp_sector

		JSR mul8_tmp_sector             ; sector = 200 * tmp_sector
		JSR add_cur_sector
		JSR mul8_tmp_sector
		JSR add_cur_sector
		JSR mul2_tmp_sector
		JSR add_cur_sector

		CLC                             ; sector = sector + 32
		LDA #32
		ADC sector
		STA sector
		LDA #0
		ADC sector+1
		STA sector+1
		LDA #0
		ADC sector+2
		STA sector+2

mul8_tmp_sector	LDX #3                         ; tmp_sector = tmp_sector * 8
mul8_loop	JSR mul2_tmp_sector
		DEX
		BNE mul8_loop
		RTS

mul2_tmp_sector	ASL tmp_sector                 ; tmp_sector = tmp_sector * 2
		ROL tmp_sector+1
		ROL tmp_sector+2
		RTS

add_cur_sector	CLC                            ; sector = sector + tmp_sector
		LDA tmp_sector
		ADC sector
		STA sector
		LDA tmp_sector+1
		ADC sector+1
		STA sector+1
		LDA tmp_sector+2
		ADC sector+2
		STA sector+2
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

get_drivenr     JSR read_num                    ; Read parameter
                STA drivenr                     ; Error if drivenr>3
                CMP #4       
                BCS get_drivenr1
                LDA drivenr
                RTS

get_drivenr1    JSR prttxt                      ; Print error
                .db 'DRIVE?'
                NOP
                BRK

;-----------------------------------------------------------------
; GET_DISKNR
;
;   Input : -
;   Output: drivenr 0-1022 or DISK? error
;-----------------------------------------------------------------

get_disknr      JSR read_num                    ; Read parameter
                STA disknr                      ; Error if disknr>1022
                STX disknr+1
                _BGT16I disknr,1022,get_disknr1
                RTS

get_disknr1     JSR prttxt                      ; Print error
                .db 'DISK?'
                NOP
                BRK

;-----------------------------------------------------------------
; Read numeric parameter or calculate expression
;
;   Input : -
;   Output: A=byte0, X=byte1, Y=byte2
;-----------------------------------------------------------------

read_num        JSR read_param                  ; Read expression on stack
                JSR next_param                  ; Next param

                LDY #0                          ; Reset stackpointer
                STY stackpointer
                LDA stack1                      ; Put byte0 in A
                LDX stack2                      ; Put byte1 in X
                LDY stack3                      ; Put byte2 in Y
                RTS

;-----------------------------------------------------------------
; PRT16DEC
;
;   Input : X = number_lb
;           Y = number_hb
;   Output: print 16bit number decimal
;-----------------------------------------------------------------

prt16dec        LDA columnwidth                 ; Save @
                PHA
                LDA #5                          ; Set @=5
                STA columnwidth

                STX stack1                      ; Print decimal number
                STY stack2
                LDA #0
                STA stack3
                STA stack4
                JSR prtdec

                PLA                             ; Restore @
                STA columnwidth
                RTS

prt16disk       ldx disknr
                ldy disknr+1
                jmp prt16dec
                

;-----------------------------------------------------------------
; DRIVE2DISK, Read disknr in drive A
;
;   Input : A      , drive nr (0-3)
;   Output: disknr , disknr (0-1022)
;-----------------------------------------------------------------

drive2disk      ASL A
                TAY
                LDA workspace,y
                STA disknr
                LDA workspace+1,Y
                STA disknr+1
                RTS

;-----------------------------------------------------------------
; PRINT_LINE
;
;   Input : X      = diskno_lb
;           Y      = diskno_hb
;   Output: print disknr + ' ' + diskname + ' ' + protect
;-----------------------------------------------------------------

print_line      JSR prt16dec                    ; Print disknr
                
                LDA #' '                        ; Print ' '
                JSR prtchr

                LDY #0                          ; Print diskname
print_line1     LDA (pointer),Y
                CMP #32
                BPL print_line2
                LDA #' '
print_line2     JSR prtchr
                INY
                CPY #13
                BNE print_line1      

                LDA #' '                        ; Print ' '
                JSR prtchr

                LDY #$0F                        ; If locked print 'P'
                LDA (pointer),Y                 ; else print ' '
                AND #$0F
                BNE print_line3
                LDA #'P'
                JSR prtchr

print_line3     RTS

;=================================================================
; SPACE SAVING ROUTINES
;=================================================================

chk_name        JSR read_filename      ; Read filename
chk_name1       JSR name_check         ; Check legal name
                JSR name_lookup        ; Find name in catalog
                STY $9A                ; Store filepointer
                RTS

;-----------------------------------------------------------------
; Check for end of command, #0D 
;-----------------------------------------------------------------

chk_end_command LDY $3
                JMP cos_post_test

;-----------------------------------------------------------------
; Print 'Y/N' and scan key
;-----------------------------------------------------------------

ask_yes_no      JSR prttxt
                .db ' :(Y/N)'
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

LE100           INY
LE101           INY
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

LE109           DEY
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
