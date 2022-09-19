; romsupgr.asm - load from a RomPack file named ROMS.ZX1, in the root
; directory of the SD card, all ZX Spectrum core ROMS into SPI flash
; memory.
;
; It must be run while using a "root" mode ROM.
;
; Copyright (C) 2019, 2021 Antonio Villena
; Contributors:
;   2021 Ivan Tatarinov <ivan-tat@ya.ru>
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

;               output  ROMSUPGR

                include zxuno.def
                include esxdos.def

        define  VERSION "0.1"
        define  ROMS_FILE "ROMS.ZX1"

                org     $2000           ; comienzo de la ejecución de los comandos ESXDOS

                call    wrear0
                dec     b
                out     (c), 0
                inc     b
                in      f, (c)
                jp      p, Nonlock
                call    Print
                dz      'ROM not rooted'
                ret
Nonlock         ld      a, scandbl_ctrl
                dec     b
                out     (c), a
                inc     b
                in      a, (c)
                and     $3f
                ld      (normal+1), a
                or      $c0
                out     (c), a
                call    init
                ld      bc, zxuno_port
                ld      a, scandbl_ctrl
                out     (c), a
                inc     b
normal          ld      a, 0
                out     (c), a
                ret
init            xor     a
                esxdos  M_GETSETDRV     ; A = unidad actual
                jr      nc, SDCard
                call    Print
                dz      'SD card not inserted'
                ret
SDCard          ld      b, FA_READ      ; B = modo de apertura
                ld      hl, FileName    ; HL = Puntero al nombre del fichero (ASCIIZ)
                esxdos  F_OPEN
                ld      (handle+1), a
                jr      nc, FileFound
                call    Print
                dz      'File ', ROMS_FILE, ' not found'
                ret
FileFound       wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $9f  ; jedec id
                in      a, (c)
                in      a, (c)
                in      a, (c)
                in      a, (c)
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                sub     $19
                jp      nz, ZX1
                ld      de, $8000
                ld      hl, $0980
                ld      a, 1
                call    rdflsh
                ld      a, ($8000)
                inc     a
                jr      nz, ZX2P
                call    Print
                db      'Upgrading ', ROMS_FILE, ' from SD', 13
                dz      '[           ]', 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
                jr      ZX2PC
ZX2P            call    Print
                db      'Upgrading ', ROMS_FILE, ' from SD', 13
                dz      '[', 6, ' ]', 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
ZX2PC           ld      a, ($8000)
                inc     a
                ld      ix, $0a2c
                ld      iy, $0000
                jr      z, ZX2cont
                ld      ix, $1840
                jr      ZX2cont
ZX1             call    Print
                db      'Upgrading ', ROMS_FILE, ' from SD', 13
                dz      '[', 6, ' ]', 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
                ld      ix, $2e40
                ld      iy, $34c0
ZX2cont         ld      de, $8000
                ld      hl, $0060
                ld      a, $20
                call    rdflsh
                ld      de, $0060
                exx
                ld      hl, $8000
                ld      bc, $1041
handle          ld      a, 0
                esxdos  F_READ
                jr      c, tError
                ld      a, $20
                ld      hl, $8000
                exx
                call    wrflsh
                ld      e, $c0
                exx
Bucle           ld      a, ixl
                dec     a
                and     $03
                jr      nz, punto
                ld      a, 'o'
                exx
                push    de
                rst     $10
                pop     de
                exx
punto           ld      hl, $8000
                ld      bc, $4000
                ld      a, (handle+1)
                esxdos  F_READ
                jr      nc, ReadOK
tError          call    Print
                dz      'Read Error'
                ret
ReadOK          ld      a, $40
                ld      hl, $8000
                exx
                call    wrflsh
                inc     de
                ld      a, ixl
                cp      ixh
                jr      nz, o10roms
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $c5  ; envío wrear
                ld      l, 1
                out     (c), l
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                push    iy
                pop     de
o10roms         exx
                dec     ixl
                jr      nz, Bucle
                ld      a, (handle+1)
                esxdos  F_CLOSE
                call    Print
                dz      13, 'Upgrade complete', 13
                ld      iy, $5c3a
wrear0          wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $c5  ; envío wrear
                out     (c), 0
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                ret

                include Print.inc
                include rdflsh.inc
                include wrflsh.inc
                include rst28.inc

FileName        dz      ROMS_FILE
