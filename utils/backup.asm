; backup.asm
;
; Copyright (C) 2019, 2021 Antonio Villena
; Contributors:
;   2021 Ivan Tatarinov <ivan-tat@ya.ru>
;   2021 kounch
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
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
; SPDX-FileContributor: 2021 kounch
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

                output  BACKUP

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
                and     $0f
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
                add     hl, de
                bit     6, h
                jr      z, Bucle
                esxdos  F_CLOSE
                call    Print
                dz      13, 'Backup complete'
                ret

                include Print.inc
                include rdflsh.inc
                include rst28.inc

FileName        dz      FLASH_FILE
