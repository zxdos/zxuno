; romsback.asm - dumps to a RomPack file named ROMS.ZX1, in the root
; directory of the microSD card, all ZX Spectrum core ROMS which are
; stored in SPI flash memory.
;
; It must be run while using a "root" mode ROM. Only works correctly
; on ZX-Uno and ZXDOS (do not use on ZXDOS+ or gomaDOS+).
;
; Copyright (C) 2019, 2021 Antonio Villena
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
; SPDX-FileCopyrightText: Copyright (C) 2019, 2021 Antonio Villena
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

                output  ROMSBACK

                include zxuno.def
                include esxdos.def

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
SDCard          ld      b, FA_WRITE | FA_OPEN_AL ; B = modo de apertura
                ld      hl, FileName    ; HL = Puntero al nombre del fichero (ASCIIZ)
                esxdos  F_OPEN
                ld      (handle+1), a
                jr      nc, FileFound
                call    Print
                dz      'Cannot open ROMS.ZX1'
                ret
FileFound       call    Print
                db      'Backing up ROMS.ZX1 to SD', 13
                dz      '[', 6, ' ]', 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $9f  ; jedec id
                in      a, (c)
                in      a, (c)
                in      a, (c)
                in      a, (c)
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                sub     $19
                jr      nz, ZX1
                ld      ix, $1d40
                ld      iy, $0000
                jr      ZX2cont
ZX1             ld      ix, $2d40
                ld      iy, $34c0
ZX2cont         ld      de, $8000
                ld      hl, $0060
                ld      a, $11
                call    rdflsh
                ld      hl, $8000
                ld      bc, $1041
handle          ld      a, 0
                esxdos  F_WRITE
                ld      hl, $00c0
                jr      c, tError
Bucle           ld      a, ixl
                dec     a
                and     $03
                jr      nz, punto
                ld      a, 'o'
                rst     $10
punto           ld      a, ixl
                cp      ixh
                jr      nz, o29roms
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $c5  ; envío wrear
                ld      l, 1
                out     (c), l
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                push    iy
                pop     hl
o29roms         ld      de, $8000
                ld      a, $40
                call    rdflsh
                ld      de, $0040
                add     hl, de
                push    hl
                ld      hl, $8000
                ld      bc, $4000
                ld      a, (handle+1)
                esxdos  F_WRITE
                pop     hl
                jr      nc, ReadOK
tError          call    Print
                dz      'Write Error'
                ret
ReadOK          dec     ixl
                jr      nz, Bucle
                ld      a, (handle+1)
                esxdos  F_CLOSE
                call    Print
                dz      13, 'Backup complete', 13
                ld      iy, $5c3a
wrear0          wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $c5  ; envío wrear
                out     (c), 0
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                ret

Print           pop     hl
                db      $3e
Print1          rst     $10
                ld      a, (hl)
                inc     hl
                or      a
                jr      nz, Print1
                jp      (hl)

; ------------------------
; Read from SPI flash
; Parameters:
;   DE: destination address
;   HL: source address without last byte
;    A: number of pages (256 bytes) to read
; ------------------------
rdflsh          ex      af, af'
                xor     a
                push    hl
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 3    ; envio flash_spi un 3, orden de lectura
                pop     hl
                push    hl
                out     (c), h
                out     (c), l
                out     (c), a
                ex      af, af'
                ex      de, hl
                in      f, (c)
rdfls1          ld      e, $20
rdfls2          ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                dec     e
                jr      nz, rdfls2
                dec     a
                jr      nz, rdfls1
                wreg    flash_cs, 1
                pop     hl
                ret

rst28           ld      bc, zxuno_port + $100
                pop     hl
                outi
                ld      b, (zxuno_port >> 8)+2
                outi
                jp      (hl)

FileName        dz      'ROMS.ZX1'
