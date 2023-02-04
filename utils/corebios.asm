; corebios.asm - update simultaneously ZX Spectrum core and BIOS.
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
; SPDX-FileContributor: 2021, 2023 Ivan Tatarinov
; SPDX-License-Identifier: GPL-3.0-only

;               output  COREBIOS

                include zxuno.def
                include esxdos.def

        define  VERSION "0.1"
        define  CORE_FILE "SPECTRUM.ZX1"
        define  BIOS_FILE "FIRMWARE.ZX1"

                org     $2000           ; comienzo de la ejecución de los comandos ESXDOS

Main            ld      bc, zxuno_port
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
                ld      (normal+1), a
                or      $80
                out     (c), a
                xor     a
                esxdos  M_GETSETDRV     ; A = unidad actual
                jr      nc, SDCard
                call    Print
                dz      'SD card not inserted'
                ret
SDCard          ld      (drive+1), a
                ld      b, FA_READ      ; B = modo de apertura
                ld      hl, FileCore    ; HL = Puntero al nombre del fichero (ASCIIZ)
                esxdos  F_OPEN
                jr      nc, FileFound
                call    Print
                dz      'File ', CORE_FILE, ' not found'
                ret
FileFound       ld      (handle2+1), a
drive:          ld      a, 0
                ld      b, FA_READ      ; B = modo de apertura
                ld      hl, FileBios    ; HL = Puntero al nombre del fichero (ASCIIZ)
                esxdos  F_OPEN
                jr      nc, FileFound2
                call    Print
                dz      'File ', BIOS_FILE, ' not found'
                ret
FileFound2      ld      (handle+1), a
                call    Print
                db      'Upgrading Core and Bios', 13
                dz      '[           ]', 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
                ld      ixl, 21
                ld      hl, $8000
                ld      bc, $4000
handle          ld      a, 0
                esxdos  F_READ
                jr      nc, GoodRead
                call    Print
                dz      'Error reading ', BIOS_FILE
                ret
GoodRead        ld      a, (handle+1)
                esxdos  F_CLOSE
                ld      a, $40
                ld      hl, $8000
                exx
                ld      de, $0080
                call    wrflsh
                ld      de, $0580
                exx
Bucle           ld      a, ixl
                dec     a
                and     $01
                jr      nz, punto
                ld      a, 'o'
                exx
                push    de
                rst     $10
                pop     de
                exx
punto           ld      hl, $8000
                ld      bc, $4000
handle2:        ld      a, 0
                esxdos  F_READ
                jr      nc, GoodRead2
                call    Print
                dz      'Error reading ', CORE_FILE
                ret
GoodRead2       ld      a, $40
                ld      hl, $8000
                exx
                call    wrflsh
                inc     de
                exx
                dec     ixl
                jr      nz, Bucle
                ld      a, (handle2+1)
                esxdos  F_CLOSE
                call    Print
                dz      13, 'Upgrade complete', 13
                ld      bc, zxuno_port
                ld      a, scandbl_ctrl
                out     (c), a
                inc     b
normal          ld      a, 0
                out     (c), a
                ret

                include Print.inc
                include rdflsh.inc
                include wrflsh.inc
                include rst28.inc

FileCore        dz      CORE_FILE
FileBios        dz      BIOS_FILE
