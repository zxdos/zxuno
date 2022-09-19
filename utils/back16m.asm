; back16m.asm - dumps to a file, in the root directory of the microSD
; card, the contents of a 16 Meg SPI Flash memory.
;
; It must be run while using a "root" mode ROM. After finishing, it is
; necessary to execute the command .ls so that the cache is written to
; the card.
;
; Copyright (C) 2019, 2021 Antonio Villena
; Contributors:
;   2021 kounch
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

;               output  BACK16M

                include zxuno.def
                include esxdos.def

        define  VERSION "0.1"
        define  FLASH_FILE "FLASH.ZX1"

                org     $2000           ; comienzo de la ejecución de los comandos ESXDOS

Main            ld      bc, zxuno_port
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
SDCard          ld      b, FA_WRITE | FA_OPEN_AL ; B = modo de apertura
                ld      hl, FileName    ; HL = Puntero al nombre del fichero (ASCIIZ)
                esxdos  F_OPEN
                ld      (handle+1), a
                jr      nc, FileFound
                call    Print
                dz      'Cannot open ', FLASH_FILE
                ret
FileFound       call    Print
                db      'Backing up ', FLASH_FILE, ' to SD', 13
                dz      '[', 6, ' ]', 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
                ld      hl, $0000
Bucle           push    hl
                ld      de, $8000
                ld      a, $40
                call    rdflsh
                add     hl, hl
                add     hl, hl
                ld      a, h
                and     $3f
                jr      nz, punto
                ld      a, 'o'
                rst     $10
punto           ld      hl, $8000
                ld      bc, $4000
handle          ld      a, 0
                esxdos  F_WRITE
                pop     hl
                jr      nc, WriteOK
                call    Print
                dz      'Write Error'
                ret
WriteOK         ld      de, $0040
                adc     hl, de
                jr      nc, Bucle
                esxdos  F_CLOSE
                call    Print
                dz      13, 'Backup complete'
                ret

                include Print.inc
                include rdflsh.inc
                include rst28.inc

FileName        dz      FLASH_FILE
