; back32m.asm - creates a file, in the root directory of the microSD
; card, with the contents of a 32 Meg SPI Flash memory.
;
; It must be run while using a "root" mode ROM. After finishing it's
; execution, you must execute the command .ls to finish recording the
; cache on the microSD card. If not, the length of the file will be
; wrongly set to 0.
;
; Copyright (C) 2019, 2021, 2022 Antonio Villena
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
; SPDX-FileCopyrightText: 2019, 2021, 2022 Antonio Villena
; SPDX-FileContributor: 2021 kounch
; SPDX-FileContributor: 2021, 2023 Ivan Tatarinov
; SPDX-License-Identifier: GPL-3.0-only

                ; definition of "zxdos" flag
                include back32m.def

;             IF zxdos=1
;               output  BACKZX2
;             ELSE
;               output  BACKZXD
;             ENDIF

                include zxuno.def
                include esxdos.def

        define  VERSION "0.1.1"
              IF zxdos=1
        define  FLASH_FILE "FLASH_32.ZX2"
              ELSE
        define  FLASH_FILE "FLASH_32.ZXD"
              ENDIF

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
Nonlock         wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $9f  ; jedec id
                in      a, (c)
                in      a, (c)
                in      a, (c)
                in      a, (c)
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                sub     $19
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
                dz      'Backing up ', FLASH_FILE, ' to SD', 13
                call    write16m
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $c5  ; envío wrear
                ld      l, 1
                out     (c), l
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                call    write16m
                esxdos  F_CLOSE
                call    Print
                dz      13, 'Backup complete'
wrear0          wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $c5  ; envío wrear
                out     (c), 0
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                ret

write16m        ld      hl, $0000
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
                ret

                include Print.inc
                include rdflsh.inc
                include rst28.inc

FileName        dz      FLASH_FILE
