;=================================================================
; SD-CARD:
;=================================================================
; The format of the SD-card is:
;
;       Sector        Description
;------------------------------------------------------
;      0 -     31    DISKTABLE + DISK INFORMATION TABLE
;     32 -    231    DISK IMAGE 0000
;    232 -    463    DISK IMAGE 0001
;   ..        ..           ..
;   ..        ..           ..
; 104432 - 204631    DISK IMAGE 1022   
;
;------------------------------------------------------
; DISKTABLE (16 bytes)
;------------------------------------------------------
;  0,1 - Current diskette number in drive 0
;  2,3 - Current diskette number in drive 1
;  4,5 - Current diskette number in drive 2
;  6,7 - Current diskette number in drive 3
;  8-F - Unused
;------------------------------------------------------
;
;------------------------------------------------------
; DISKINFO TABLE (1023 * 16 bytes)
;------------------------------------------------------
; 0-C - Diskname
; D,E - Unused
; F   - Diskette Status  00 = Read Only
;                        0F = R/W
;                        F0 = Unformatted
;                        FF = No valid diskno.
;------------------------------------------------------
;
;------------------------------------------------------
; SD-CARD CAPACITY
;------------------------------------------------------
; DISKTABLE      :                           16 bytes
; DISKINFO TABLE : 1023 *      16 =      16.368 bytes
; DISK IMAGES    : 1023 * 102.400 = 104.755.200 bytes
;------------------------------------------------------
; Total data     :                  104.771.584 bytes
; Total sectors  :                      204.632 sect
; Total mB       :                          100 mB
;-----------------------------------------------------------------

sdbase                  equ $3000

read_start              RTS
read_end                RTS
write_start             RTS
write_end               RTS

;-----------------------------------------------------------------
; SDINIT
;
;  Init SD-card
;-----------------------------------------------------------------

sd_init                 RTS

;-----------------------------------------------------------------
; SD_SECTOR_R
;
;   Read 1 sector (512 bytes) from SD-card into buffer
;
;   Input : A = Byte0 sector
;           X = Byte1 sector
;           Y = Byte2 sector
;   Output: -
;-----------------------------------------------------------------

dum_lo                  equ data+9
dum_mid                 equ data+10
dum_hi                  equ data+11
adres_lo                equ data+12
adres_hi                equ data+13

sd_sector_r             LDA sector
                        STA dum_lo
                        LDA sector+1
                        STA dum_mid
                        LDA sector+2
                        STA dum_hi

.IF debug 
                        STA stack1
                        STX stack2
                        STY stack3
                        LDA #0
                        STA stack4
                        LDA #'r'
                        JSR prtchr
                        JSR prtdec
                        JSR newline
.ENDIF
        ;=================================================================
        ; For testing load sectors 0-31 in Atom memory at $3000 - $6FFF
        ; sector>32 then read $7000 - $71FF (copy of catalog)
        ;
        ; The code for reading an SD-sector must be placed here
        ;-----------------------------------------------------------------

                        LDA dum_hi       ; If sector>32 read $7000-$71FF
                        BNE read_cat
                        LDA dum_mid
                        BNE read_cat
                        LDA dum_lo
                        CMP #32
                        BCS read_cat

read_dir                ASL dum_lo       ; adres = $3000 + sect * 512

                        CLC        
                        LDA dum_lo
                        ADC #>sdbase
                        STA adres_hi
                        LDA #0
                        STA adres_lo

                        LDY #0           ; copy sector->buffer
rd1_loop                LDA (adres_lo),Y
                        STA sectbuf,Y
                        INY
                        BNE rd1_loop
                        INC adres_hi
rd2_loop                LDA (adres_lo),Y
                        STA sectbuf+$100,Y
                        INY
                        BNE rd2_loop
                        RTS

read_cat                LDY #0
readcat1                LDA $7000,Y
                        STA catbuf,Y
                        INY
                        BNE readcat1
readcat2                LDA $7100,Y
                        STA catbuf+$100,Y
                        INY
                        BNE readcat2

                        LDA cur_drive
                        JSR drive2disk

                        LDX disknr                      ; Load statussector
                        LDY disknr+1
                        JSR statussector_r

                        LDY #0                          ; Fill in name in cat
copy_header1            LDA (pointer),Y
                        STA catbuf,Y
                        INY
                        CPY #8
                        BNE copy_header1

copy_header2            LDA (pointer),Y
                        STA catbuf+$100-8,Y
                        INY
                        CPY #13
                        BNE copy_header2

                        RTS

;-----------------------------------------------------------------
; SD_SECTOR_W
;
;   Write 1 sector (512 bytes) from buffer to SD-card
;
;   Input : A = Byte0 sector
;           X = Byte1 sector
;           Y = Byte2 sector
;   Output: -
;-----------------------------------------------------------------

sd_sector_w             LDA sector
                        STA dum_lo
                        LDA sector+1
                        STA dum_mid
                        LDA sector+2
                        STA dum_hi

.IF debug 
                        STA stack1
                        STX stack2
                        STY stack3
                        LDA #0
                        STA stack4
                        LDA #'w'
                        JSR prtchr
                        JSR prtdec
                        JSR newline
.ENDIF
;=================================================================
; For testing load sectors 0-31 in Atom memory at $3000 - $6FFF
; The code for writing an SD-sector must be placed here
;-----------------------------------------------------------------

                        LDA dum_hi       ; If sector>32 read $7000-$71FF
                        BNE wr3_loop
                        LDA dum_mid
                        BNE wr3_loop
                        LDA dum_lo
                        CMP #32
                        BCS wr3_loop

                        ASL dum_lo       ; adres = $3000 + sect * 512

                        CLC        
                        LDA dum_lo
                        ADC #>sdbase
                        STA adres_hi
                        LDA #0
                        STA adres_lo

                        LDY #0           ; copy buffer->sectors
wr1_loop                LDA sectbuf,Y
                        STA (adres_lo),Y
                        INY
                        BNE wr1_loop
                        INC adres_hi
wr2_loop                LDA sectbuf+$100,Y
                        STA (adres_lo),Y
                        INY
                        BNE wr2_loop
;=================================================================

wr3_loop                RTS

OSXFER                  LDA #$FF
                        RTS

OSXFERFF                RTS
