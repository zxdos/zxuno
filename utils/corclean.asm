; corclean.asm
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
; SPDX-FileCopyrightText: Copyright (C) 2019, 2021 Antonio Villena
;
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

                output  CORCLEAN

                include zxuno.def

        define  VERSION "0.1"
;        define  ROMS_FILE "ROMS.ZX1"

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
                or      $c0
                out     (c), a
                call    Print
                dz      'Cleaning...', 13
                ld      ixl, 64
                ld      de, $8000
                ld      hl, $0070
                ld      a, $02
                call    rdflsh
                ld      hl, $8200
                ld      de, $8201
                ld      (hl), l
                ld      bc, $0e00
                ldir
                ld      a, $10
                ld      h, $80
                exx
                ld      de, $0070
                call    wrflsh
                call    Print
                dz      13, 'Clean complete', 13
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

;FileName        dz      ROMS_FILE
