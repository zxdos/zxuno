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

;               output  MC

                include zxuno.def
                include esxdos.def

                org     $2000           ; comienzo de la ejecución de los comandos ESXDOS

Main            ld      a, h
                or      l
                jr      nz, NoPrint     ; si no se ha especificado nombre de fichero, imprimir uso
                call    Print
                dz      '.mc corefile.zx1', 13, 13, 'Loads and executes a core'
                ret
NoPrint         ld      de, FileName
NextChar        ld      a, (hl)
                or      a
                jr      z, EndParse
                cp      ' '
                jr      c, EndParse
                ldi
                jr      NextChar
EndParse        xor     a
                ld      (de), a
                ld      bc, zxuno_port
                out     (c), a
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
                dz      'File not found'
                ret
FileFound       call    Print
                db      'Writing SPI flash', 13
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
punto           ld      hl, $8000
                ld      bc, $4000
handle          ld      a, 0
                esxdos  F_READ
                jr      nc, ReadOK
                call    Print
                dz      'Read Error'
                ret
ReadOK          ld      a, $40
                ld      hl, $8000
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
                include wrflsh.inc
                include rst28.inc
FileName
