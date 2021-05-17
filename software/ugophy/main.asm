;; (c) 2019 Alexander Sharikhin
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;; SPDX-FileCopyrightText: Copyright (C) 2019 Alexander Sharikhin
;;
;; SPDX-License-Identifier: GPL-3.0-or-later


    DEVICE ZXSPECTRUM128
    org 24100
stack_pointer EQU #5aff
Start: 
    di
    res 4, (iy+1)
    call checkHighMem : jp nz, noMem
    
    xor a : out (#fe), a : call changeBank

    ld sp, stack_pointer

    ld de, #4000 : ld bc, eop - player : ld hl, player : ldir

    ei

    call renderHeader
    ld hl, connecting_wifi : call printZ64
    call initWifi
    
    call wSec

    ld de, path : ld hl, server : ld bc, port : call openPage

    jp showPage

noMem:
    ld hl, no128k
nmLp:
    push hl
    ld a, (hl)
    and a : jr z, $
    rst #10
    pop hl
    inc hl
    jp nmLp


wSec: ld b, 50
wsLp  halt : djnz wsLp

    include "tscreen.asm"
    include "keyboard.asm"
    include "utils.asm"
    include "wifi.asm"
    include "gopher.asm"
    include "render.asm"
    include "textrender.asm"
    include "uart.asm"
    include "ring.asm"
    include "esxdos.asm"


connecting_wifi db 13, 'Connecting to WiFi', 13, 0
open_lbl db 'Opening connection to ', 0

path    db '/ncmenu'
        defs 248              
server  db 'nihirash.net'
        defs 58    
port    db '70'
        defs 5
        db 0
page_buffer equ $
    display "PAGE buffer:", $
no128k  db 13, "You're in 48k mode!", 13, 13
        db     "Current version require full", 13 
        db     "128K memory access", 13, 13
        db     "System halted!", 0
player 
    DISPLAY "Player starts:" , $       
    include "vtpl.asm"
    DISPLAY "Player ends: ", $
    ENT
eop equ $
;   SAVEBIN "ugoph.bin", Start, $ - Start
;   SAVETAP "ugoph.tap", Start
