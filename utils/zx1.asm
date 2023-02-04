; mc.asm - multicore load any .ZX1 core on slot 9 or 45.
; File must exists in current directory.  It must be run while using a "root" mode ROM.
;
; Copyright (C) 2022 Antonio Villena
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, version 3.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.
;
; Compatible compilers:
;   SjAsmPlus, <https://github.com/z00m128/sjasmplus>
;
; SPDX-FileType: SOURCE
; SPDX-FileCopyrightText: 2022 Antonio Villena
; SPDX-License-Identifier: GPL-3.0-only

;               output  ZX1

        define  romtbl  $d000
        define  indexe  $e000
        define  active  $e040

        define  bitstr  active+1
        define  quietb  bitstr+1
        define  checkc  quietb+1
        define  keyiss  checkc+1
        define  timing  keyiss+1
        define  conten  timing+1
        define  divmap  conten+1
        define  nmidiv  divmap+1
        define  grapmo  nmidiv+1
        define  layout  grapmo+1
        define  joykey  layout+1
        define  joydb9  joykey+1
        define  split   joydb9+1
        define  outvid  split+1
        define  scanli  outvid+1
        define  freque  scanli+1
        define  cpuspd  freque+1
        define  copt    cpuspd+1
        define  cburst  copt+1

        define  cmbpnt  $e100
        define  cmbcor  $e1d0   ;lo: Y coord          hi: X coord
        define  items   $e1d2   ;lo: totales          hi: en pantalla
        define  offsel  $e1d4   ;lo: offset visible   hi: seleccionado
        define  empstr  $e1d6
        define  tmpbuf  $e200

                include zxuno.def
                include esxdos.def

                org     $8000
                jr      NoPrint
                db      'BP', 0, 0, 0, 0, 'ZX1 plugin - antoniovillena', 0
NoPrint         ld      (FileName+1), hl
                ld      bc, zxuno_port
                out     (c), 0
                inc     b
                in      f, (c)
                jp      p, Nonlock
                call    Print
                dz      'ROM not rooted'
                ret
Nonlock         wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $9f  ; jedec id
                in      a, (c)
                in      a, (c)
                in      a, (c)
                in      a, (c)
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                sub     $18
                jr      z, Goodflsh
                ld      hl, $2f80
                ld      (Slot+1), hl
                inc     a
                inc     a
                jr      z, Goodflsh
                call    Print
                dz      'Incorrect flash IC'
                ret
Goodflsh        ld      a, scandbl_ctrl
                dec     b
                out     (c), a
                inc     b
                in      a, (c)
                and     $3f
                ld      (Normal+1), a
                or      $c0
                out     (c), a
                call    Init
                ld      bc, zxuno_port
                ld      a, scandbl_ctrl
                out     (c), a
                inc     b
Normal          ld      a, 0
                out     (c), a
                ld      a, 7            ;PLUGIN_OK|PLUGIN_RESTORE_SCREEN|PLUGIN_RESTORE_BUFFERS
                ret
Init            wreg    flash_cs, 1
                ld      de, indexe
                ld      hl, $0070
                ld      a, 1
                call    rdflsh
                xor     a
                esxdos  M_GETSETDRV     ; A = unidad actual
                jr      nc, SDCard
                call    Print
                dz      'SD card not inserted'
                ret
SDCard          ld      (Drive+1), a
                ld      b, FA_READ      ; B = modo de apertura
FileName        ld      hl, 0
                esxdos  F_OPEN
                ld      (Handle+1), a
                jr      nc, FileFound
                call    Print
                dz      'File not found'
                ret
FileFound       ld      hl, Stat
                esxdos  F_FSTAT
                ld      hl, (Stat+7)
                ld      bc, $1041
                sbc     hl, bc
                jp      z, Roms
                call    Print
                db      13, 'Writing SPI flash', 13
                dz      '[', 6, '      ]', 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
                ld      ixl, $15
Slot            ld      de, $f7c0
                exx
Bucle           ld      a, 'o'
                exx
                push    de
                rst     $10
                pop     de
                exx
                ld      hl, $c000
                ld      bc, $4000
Handle          ld      a, 0
                esxdos  F_READ
                jr      nc, ReadOK
                call    Print
                dz      'Read Error'
                ret
ReadOK          ld      a, $40
                ld      hl, $c000
                exx
                call    wrflsh
                inc     de
                exx
                dec     ixl
                jr      nz, Bucle
                ld      bc, zxuno_port
                ld      hl, (Slot+1)
                ld      a, core_addr
                out     (c), a
                inc     a
                inc     b
                out     (c), h
                out     (c), l
                out     (c), 0
                dec     b
                out     (c), a
                inc     b
                out     (c), a
                include Print.inc
                include rdflsh.inc
                include wrflsh.inc
                include rst28.inc

Roms            ld      a, (Handle+1)
                ld      hl, romtbl
                esxdos  F_READ
                ld      hl, chrBegin
                ld      de, $c400-Stat+chrBegin
                ld      bc, Stat-chrBegin
                ldir
                ld      hl, $c000
Roms1           ld      b, $04
Roms2           ld      a, (hl)
                rrca
                rrca
                ld      (de), a
                inc     de
                cpi
                jp      pe, Roms2
                jr      nc, Roms1
                push    ix

;++++++++++++++++++++++++++++++++++
;++++++++     Boot list    ++++++++
;++++++++++++++++++++++++++++++++++
blst            ld      hl, indexe
numen1          ld      a, (hl)         ; calculo en L el número de entradas
                inc     l
                inc     a
                jr      nz, numen1
                ld      a, l
                cp      13
                jr      c, blst1
                ld      a, 13
blst1           ld      h, a
                ld      (items), hl
                add     a, -25
                cpl
                rra
                ld      l, a
                ld      a, h
                add     a, 2
                ld      e, a
                ld      a, %01001111    ; fondo azul tinta blanca
                ld      h, $01          ; coordenada X
                ld      d, $1c          ; anchura de ventana
                push    hl
                call    window
                ld      ix, cad1
                pop     bc
                inc     b
                call    prnstr
                push    bc
                ld      iy, (items)
blst2           ld      ix, cad2
                call    prnstr             ; |                |
                dec     iyh
                jr      nz, blst2
                ld      ix, cad3
                call    prnstr
                ld      iy, indexe
                ld      ix, cmbpnt
                ld      de, tmpbuf
                ld      b, e
blst3           ld      l, (iy)
                inc     l
                call    calcu
addbls          ld      (ix+0), e
                ld      (ix+1), d
                push    hl
                ld      c, $21
                push    hl
str2t1          dec     hl
                dec     c
                ld      a, (hl)
                cp      $20
                jr      z, str2t1
                pop     hl
                ld      a, l
                sub     $20
                ld      l, a
                jr      nc, str2t2
                dec     h
str2t2          ldir
                xor     a
                ld      (de), a
                inc     de
                pop     hl
addbl1          inc     iyl
                inc     ixl
                inc     ixl
                ld      a, (items)
                sub     2
                sub     iyl
                jr      nc, blst3
bls37           ld      (ix+1), a
                ld      a, (items+1)
                ld      e, a
                ld      d, 32
                ld      a, (active)
bls38           pop     hl
                ld      h, 4
blst4           ei

combol          push    hl
                push    de
                ex      af, af'
                ld      (cmbcor), hl
                ld      hl, cmbpnt+1
combo1          ld      a, (hl)
                inc     l
                inc     l
                inc     a
                jr      nz, combo1
                srl     l
                dec     l
                ld      c, l
                ld      h, e
                ld      b, d
                ld      (items), hl
                ld      hl, empstr
combo2          ld      (hl), $20
                inc     l
                djnz    combo2
                ld      (hl), a
                ex      af, af'
                ld      (offsel+1), a
                sub     e
                jr      nc, combo3
                sbc     a, a
combo3          inc     a
combo4          ld      (offsel), a
                ld      iy, (items)
                ld      iyl, iyh
                ld      bc, (cmbcor)
                ld      a, iyl
                or      a
                jr      z, combo7
combo5          ld      ix, empstr
                call    prnstr
                dec     iyl
                jr      nz, combo5
                ld      a, (offsel)
                ld      bc, (cmbcor)
                add     a, a
                ld      h, cmbpnt>>8
                ld      l, a
combo6          ld      a, (hl)
                ld      ixl, a
                inc     l
                ld      a, (hl)
                inc     l
                ld      ixh, a
                push    hl
                call    prnstr
                pop     hl
                dec     iyh
                jr      nz, combo6
combo7          ld      de, $1a02
                ld      hl, (cmbcor)
                ld      h, e
                ld      a, (items+1)
                ld      e, a
                ld      a, %01001111
                call    window
                ld      de, $1a02
                ld      hl, (offsel)
                ld      a, (cmbcor)
                add     a, h
                sub     l
                ld      l, a
                ld      h, e
                ld      e, 1
                ld      a, %01000111
                call    window
waitky          in      a, ($fe)
                or      %11100000
                inc     a
                jr      z, waitky
                ld      bc, (items)
                ld      hl, (offsel)
                ld      a, $ef      ;67
                in      a, ($fe)
                bit     3, a
                jr      nz, combo9
                call    halt8
                dec     h
                jp      m, combo7
                ld      a, h
                cp      l
                ld      (offsel), hl
                jr      nc, combo7
                ld      a, l
                dec     a
combo8          jp      combo4
combo9          bit     4, a
                jr      nz, comboa
                call    halt8
                inc     h
                ld      a, h
                cp      c
                jr      z, combo7
                sub     l
                cp      b
                ld      (offsel), hl
                jr      nz, combo7
                ld      a, l
                inc     a
                jr      combo8
comboa          ld      a, $bf      ;enter
                in      a, ($fe)
                rrca
                jr      nc, execut
salir           pop     de
                pop     hl
                pop     ix
halt8           halt
                halt
                halt
                halt
                halt
                halt
                halt
                halt
                halt
                halt
                halt
                halt
                ret

execut  ld      l, h

ccon0   ld      h, active>>8
        ld      l, (hl)
        call    calcu
        ld      de, Stat
        ld      a, (hl)
        push    de
        pop     ix
        ld      bc, 5
        ldir
        ld      l, a
        ld      a, (ix+1)
        ld      iyh, a
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      d, l
        ld      e, 0
        ld      c, h
        ld      b, e
        ld      a, (Handle+1)
        ld      l, SEEK_CUR
        esxdos  F_SEEK
        ld      iyl, 28

        call    Bootoogle
cont66  ld      bc, zxuno_port
        ld      a, master_mapper
        out     (c), a
        inc     b
        ld      a, iyl
        inc     iyl
        out     (c), a
        call    Bootoogle
        ld      hl, $a000
        ld      bc, $2000
        ld      a, (Handle+1)
        esxdos  F_READ
        call    Bootoogle
        ld      hl, $a000
        ld      bc, $2000
        ld      de, $c000
        ldir

        call    Bootoogle
        ld      hl, $a000
        ld      bc, $2000
        ld      a, (Handle+1)
        esxdos  F_READ
        call    Bootoogle
        ld      hl, $a000
        ld      bc, $2000
        ld      de, $e000
        ldir
        dec     iyh
        jr      nz, cont66

        call    Bootoogle
        ld      a, (Handle+1)
        esxdos  F_CLOSE

Drive           ld      a, 0                
                ld      b, FA_WRITE | FA_OPEN_AL ; B = modo de apertura
                ld      hl, Groms
                esxdos  F_OPEN
                ld      (Handle+1), a
                jr      nc, FileFo
                call    Print
                dz      'Cannot open GROMS.ZX1'
                ret
FileFo

        ld      iyl, 28
cont67  call    Bootoogle
        ld      bc, zxuno_port
        ld      a, master_mapper
        out     (c), a
        inc     b
        ld      a, iyl
        inc     iyl
        out     (c), a
        ld      hl, $c000
        ld      bc, $2000
        ld      de, $a000
        ldir
        call    Bootoogle
        ld      hl, $a000
        ld      bc, $2000
        ld      a, (Handle+1)
        esxdos  F_WRITE

        call    Bootoogle
        ld      hl, $e000
        ld      bc, $2000
        ld      de, $a000
        ldir
        call    Bootoogle
        ld      hl, $a000
        ld      bc, $2000
        ld      a, (Handle+1)
        esxdos  F_WRITE
        dec     (ix+1)
        jr      nz, cont67

        ld      a, (Handle+1)
        esxdos  F_CLOSE


        ld a, 2
        out ($fe), a
oooo  jr oooo



        ld      d, (ix+2)
        ld      hl, timing
        ld      a, (outvid)
        rrca
        ld      a, 3
        ld      b, a
        jr      c, ccon1
        cp      (hl)            ; timing
        ld      b, (hl)
        jr      nz, ccon1
        ld      b, d
ccon1   and     b               ; 0 0 0 0 0 0 MODE1 MODE0
        rrca                    ; MODE0 0 0 0 0 0 0 MODE1
        inc     l
        srl     (hl)            ; conten
        jr      z, ccon2
        bit     4, d
        jr      z, ccon2
        ccf
ccon2   adc     a, a            ; 0 0 0 0 0 0 MODE1 /DISCONT
        ld      l, keyiss & $ff
        rr      b
        adc     a, a            ; 0 0 0 0 0 MODE1 /DISCONT MODE0
        srl     (hl)            ; keyiss
        jr      z, ccon3
        bit     5, d
        jr      z, ccon3
        ccf
ccon3   adc     a, a            ; 0 0 0 0 MODE1 /DISCONT MODE0 /I2KB
        ld      l, nmidiv & $ff
        srl     (hl)            ; nmidiv
        jr      z, conti1
        bit     2, d
        jr      z, conti1
        ccf
conti1  adc     a, a            ; 0 0 0 MODE1 /DISCONT MODE0 /I2KB /DISNMI
        dec     l
        srl     (hl)            ; divmap
        jr      z, conti2
        bit     3, d
        jr      z, conti2
        ccf
conti2  adc     a, a            ; 0 0 MODE1 /DISCONT MODE0 /I2KB /DISNMI DIVEN
        add     a, a            ; 0 MODE1 /DISCONT MODE0 /I2KB /DISNMI DIVEN 0
        xor     d
        and     %01111111
        xor     d
        xor     %10101100       ; LOCK MODE1 DISCONT MODE0 I2KB DISNMI DIVEN 0
        ld      (conti9+1), a

micont  ld      iyl, 28
        ld      a, (ix+1)
        ld      iyh, a

  IF 0
conti5  wreg    master_conf, 1
        ld      a, master_mapper
        dec     b
        out     (c), a
        inc     b
        ld      a, iyl
        inc     iyl
        out     (c), a
        wreg    master_conf, 2
        ld      hl, $6000
        ld      bc, $1000
        ld      a, (Handle+1)
        esxdos  F_READ
        wreg    master_conf, 1
        ld      hl, $6000
        ld      bc, $1000
        ld      de, $c000
        ldir
        wreg    master_conf, 2
        ld      hl, $6000
        ld      bc, $1000
        ld      a, (Handle+1)
        esxdos  F_READ
        wreg    master_conf, 1
        ld      hl, $6000
        ld      bc, $1000
        ld      de, $d000
        ldir
        wreg    master_conf, 2
        ld      hl, $6000
        ld      bc, $1000
        ld      a, (Handle+1)
        esxdos  F_READ
        wreg    master_conf, 1
        ld      hl, $6000
        ld      bc, $1000
        ld      de, $e000
        ldir
        wreg    master_conf, 2
        ld      hl, $6000
        ld      bc, $1000
        ld      a, (Handle+1)
        esxdos  F_READ
        wreg    master_conf, 1
        ld      hl, $6000
        ld      bc, $1000
        ld      de, $f000
        ldir
        dec     iyh
        jp      nz, conti5
   ENDIF

;        wreg    master_conf, 2

cont55  wreg    master_conf, 1
        ld      a, master_mapper
        dec     b
        out     (c), a
        inc     b
        ld      a, iyl
        inc     iyl
        out     (c), a
        ld      hl, $c000
        ld      bc, $2000
        ld      de, $a000
        ldir
        wreg    master_conf, 2
        ld      hl, $a000
        ld      bc, $2000
handle2 ld      a, 0
        esxdos  F_WRITE
        wreg    master_conf, 1
        ld      hl, $e000
        ld      bc, $2000
        ld      de, $a000
        ldir
        wreg    master_conf, 2
        ld      hl, $a000
        ld      bc, $2000
        ld      a, (handle2+1)
        esxdos  F_WRITE
        dec     (ix+1)
        jr      nz, cont55

        ld      a, (handle2+1)
        esxdos  F_CLOSE

        ld a, 1
        out ($fe), a
        di
        halt

;        jp      conti9

;        ei

        wreg    master_conf, 1
        ld      iyl, 28
conti6  ld      a, master_mapper
        dec     b
        out     (c), a
        inc     b
        ld      a, iyl
        out     (c), a
        ld      hl, $c000
        ld      bc, $2000
        ld      de, $a000
        ldir
        ld      a, master_mapper
        dec     b
        out     (c), a
        inc     b
        ld      a, iyl
        sub     20
        out     (c), a
        ld      hl, $a000
        ld      bc, $2000
        ld      de, $c000
        ldir
        ld      a, master_mapper
        dec     b
        out     (c), a
        inc     b
        ld      a, iyl
        out     (c), a
        ld      hl, $e000
        ld      bc, $2000
        ld      de, $a000
        ldir
        ld      a, master_mapper
        dec     b
        out     (c), a
        inc     b
        ld      a, iyl
        sub     20
        out     (c), a
        ld      hl, $a000
        ld      bc, $2000
        ld      de, $e000
        ldir
        inc     iyl
        dec     iyh
        jr      nz, conti6

;        ld a, 1
;        out ($fe), a
;        halt

conti9  ld      a, 0
        dec     b
        out     (c), 0
        inc     b
        out     (c), a
        dec     b
        ld      a, dev_control
        out     (c), a
        inc     b
        ld      a, (ix+3)
        out     (c), a
        dec     b
        ld      a, dev_control2
        out     (c), a
        inc     b
        in      a, (c)
        and     %11111000
        ld      l, a
        ld      a, (grapmo)
        srl     a
        jr      c, contib
        ld      a, 7            ; Resv Resv Resv Resv Resv DIRADAS DITIMEX DIULAPLUS
        jr      z, contib
        ld      a, (ix+4)
contib  or      l
        out     (c), a
        rst     0

; -------------------------------------
; Draw a window in the attribute area
; Parameters:
;    A: attribute color
;   HL: X coordinate (H) and Y coordinate (L)
;   DE: window width (D) and window height (E)
; -------------------------------------
window          push    hl
                push    de
                ld      c, h
                add     hl, hl
                add     hl, hl
                add     hl, hl
                ld      h, $16
                add     hl, hl
                add     hl, hl
                ld      b, 0
                add     hl, bc
windo1          ld      b, d
windo2          ld      (hl), a
                inc     hl
                djnz    windo2
                ld      c, d
                sbc     hl, bc
                ld      c, $20
                add     hl, bc
                dec     e
                jr      nz, windo1
                pop     de
                pop     hl
                ret

; -------------------------------------
; Calculate ROM entry address
; Parameters:
;    L: input slot
; Returns:
;   HL: destination address
; -------------------------------------
calcu           add     hl, hl
                add     hl, hl
                ld      h, romtbl >> 12
                add     hl, hl
                add     hl, hl
                add     hl, hl
                add     hl, hl
                ret

; -----------------------------------------------------------------------------
; Print string routine
; Parameters:
;  BC: X coord (B) and Y coord (C)
;  IX: null terminated string
; -----------------------------------------------------------------------------
prnstr          push    bc
                call    prnstr1
                pop     bc
                inc     c
                ret
prnstr1         ld      a, b
                and     %11111100
                ld      d, a
                xor     b
                ld      b, a
                ld      e, a
                jr      z, prnch1
                dec     e
prnch1          ld      a, d
                rrca
                ld      d, a
                rrca
                add     a, d
                add     a, e
                ld      e, a
                ld      a, c
                and     %00011000
                or      %01000000
                ld      d, a
                ld      a, c
                and     %00000111
                rrca
                rrca
                rrca
                add     a, e
                ld      e, a
                rr      b
                jr      c, pos26
                jr      nz, pos4
pos0            ld      a, (ix)
                inc     ix
                add     a, a
                ret     z
                ld      h, $c0 >> 2
                ld      b, 8
                ld      l, a
                add     hl, hl
                add     hl, hl
pos01           ld      a, (hl)
                ld      (de), a
                inc     d
                inc     l
                djnz    pos01
                ld      hl, $f800
                add     hl, de
                ex      de, hl
pos2            ld      a, (ix)
                inc     ix
                add     a, a
                ret     z
                ld      h, $cc >> 2
                ld      bc, $04fc
                call    doble
pos4            ld      a, (ix)
                inc     ix
                add     a, a
                ret     z
                ld      h, $c8 >> 2
                ld      bc, $04f0
                call    doble
pos6            ld      a, (ix)
                inc     ix
                add     a, a
                ret     z
                ld      h, $c4 >> 2
                ld      b, 8
                ld      l, a
                add     hl, hl
                add     hl, hl
pos61           ld      a, (de)
                xor     (hl)
                ld      (de), a
                inc     d
                inc     l
                djnz    pos61
                ld      hl, $f801
                add     hl, de
                ex      de, hl
                jr      pos0
pos26           rr      b
                jr      c, pos6
                jr      pos2

doble           ld      l, a
                add     hl, hl
                add     hl, hl
doble2          ld      a, (de)
                xor     (hl)
                and     c
                xor     (hl)
                ld      (de), a
                inc     e
                ld      a, (hl)
                and     c
                ld      (de), a
                inc     d
                inc     l
                ld      a, (hl)
                and     c
                ld      (de), a
                dec     e
                ld      a, (de)
                xor     (hl)
                and     c
                xor     (hl)
                ld      (de), a
                inc     d
                inc     l
                djnz    doble2
                ld      hl, $f801
                add     hl, de
                ex      de, hl
                ret

Bootoogle       ld      bc, zxuno_port
                out     (c), 0
                inc     b
                in      a, (c)
                xor     %00000001
                out     (c), a
                ret

Groms           dz      "GROMS.ZX1"

cad1            defb    $12, $11, $11, $11, $11, $11, $11, $11, $11
                defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
                defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
                defb    $11, $11, $11, $11, $11, $11, $11, $11, $13, 0
cad2            defb    $10, '                                  ', $10, 0
cad3            defb    $14, $11, $11, $11, $11, $11, $11, $11, $11
                defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
                defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
                defb    $11, $11, $11, $11, $11, $11, $11, $11, $15, 0

chrBegin        incbin  fuente6x8.bin

Stat
