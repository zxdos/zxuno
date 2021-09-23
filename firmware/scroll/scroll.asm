; scroll.asm - an easter egg showing the list of people who participated
; in the crowdfunding of the ZX-Uno project through Verkami:
;     https://www.verkami.com/projects/14074-zx-uno
;
; We put the nick that they agreed. Some of them decided to put their
; complete names.
;
; Copyright (C) 2016, 2017, 2020, 2021 Antonio Villena
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
; SPDX-FileType: SOURCE
; SPDX-FileCopyrightText: Copyright (C) 2016, 2017, 2020, 2021 Antonio Villena
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

;       output  scroll.bin

        include rcs.mac
        include memcpy.mac

        org     $5e6d

        export  filestart
        export  start

SCREEN: equ $4000
ATTRS: equ $5800
XA: equ 5       ; X attributes offset
YA: equ 22      ; Y attributes offset
LS: equ 22      ; line size (bytes)

; copy LS bytes from (x0, y0) to (x1, y1)
 macro copy_screen_line x1, y1, x0, y0
        memcpy_22 SCREEN+2048*(y1/64)+256*(y1&7)+32*((y1/8)&7)+x1, SCREEN+2048*(y0/64)+256*(y0&7)+32*((y0/8)&7)+x0
 endm

; copy LS bytes from (x0, y0) to (x1, y1)
 macro copy_attrs_line x1, y1, x0, y0
        memcpy_22 ATTRS+y1*32+x1, ATTRS+y0*32+x0
 endm

filestart
string  include string.asm

music   ld      (vari), ix
        jp      PlaySTC.Play

        define  PLAYSTC_AY_FREQUENCY ay_freq_Spectrum
        define  PLAYSTC_USER_DEFINED_FILE 0
        include playstc.inc

track   incbin  music.stc

fuente  incbin  fuente6x8.bin

start   ld      hl, $c000
        ld      de, $c000+1
        ld      bc, $180-1
        ld      (hl), l
        ldir
        ld      hl, fuente
        ld      b, 3            ; BC = 768, DE = $c000+$180
        ldir
        ld      hl, fondo
        ld      b, high SCREEN  ; BC = SCREEN
        drcs_screen
        ld      b, high (32*24) ; A = 0, BC = 32*24, DE = ATTRS, HL = fondo+32*192
        ldir                    ; copy attributes
        out     ($fe), a
        inc     a
        ex      af, af'
;        ld      de, $401f
;rever   ld      hl, $ffe1
;        add     hl, de
;        ld      c, (hl)
;        ld      a, $80
;revl1   rl      c
;        rra
;        jr      nc, revl1
;        ld      (de), a
;        inc     hl
;        dec     de
;        ld      c, (hl)
;        ld      a, $80
;revl2   rl      c
;        rra
;        jr      nc, revl2
;        ld      (de), a
;        inc     hl
;        dec     de
;        ld      c, (hl)
;        ld      a, $80
;revl3   rl      c
;        rra
;        jr      nc, revl3
;        ld      (de), a
;        inc     hl
;        dec     de
;        ld      c, (hl)
;        ld      a, $80
;revl4   rl      c
;        rra
;        jr      nc, revl4
;        ld      (de), a
;        ld      hl, $23
;        add     hl, de
;        ex      de, hl
;        ld      a, d
;        cp      $58
;        jr      nz, rever

        ld      hl, $c000
        ld      de, $c000+$400
start1  ld      b, $08
start2  ld      a, (hl)
        rrca
        ld      (de), a
        inc     de
        cpi
        jp      pe, start2
        jr      nc, start1
        ld      a, $c9
        ld      ($c000+6), a
        ld      hl, track
        call    PlaySTC.Init
start3  call    PlaySTC.Play
        ei
        halt
        di
        ld      bc, 5
start4  djnz    start4
        dec     c
        jr      nz, start4
y=0
 dup 192-1
        copy_screen_line XA, y, XA, (y+1)
y=y+1
 edup
        ld      sp, ATTRS-32+XA+LS      ; clear bottom line (LS bytes)
        sbc     hl, hl
 dup LS/2
        push    hl
 edup
        ld      sp, hl                  ; SP = 0
        ld      ix, string
vari: equ $-2
        ld      hl, start3
        push    hl                      ; ($fffe) = start3
        ld      hl, music
        push    hl                      ; ($fffc) = music
        ex      af, af'
        rrca
        jr      c, start5
        ex      af, af'
        ret
start5  ex      af, af'
y=0
 dup YA
        copy_attrs_line XA, y, XA, (y+1)
y=y+1
 edup
        ld      sp, $fffc
        ld      b, (ix)
        djnz    start6
        ld      ix, string
start6  inc     ix
        ld      hl, ATTRS+32*YA+XA      ; fill attributes in buffer (LS bytes)
        ld      (hl), b
        ld      de, ATTRS+32*YA+XA+1
        ld      bc, LS-1
        ldir
        xor     a
        push    ix
        pop     hl
        ld      bc, $172b
        cpir
        srl     c
        ld      a, c
        jr      c, prn2
        and     %11111100
        ld      d, a
        xor     c
        ld      c, a
        ld      e, a
        jr      z, prn1
        dec     e
prn1    ld      a, d
        rrca
        ld      d, a
        rrca
        add     a, d
        add     a, e
        ld      e, a
        ld      a, b
        and     %00011000
        or      %01000000
        ld      d, a
        ld      a, b
        and     %00000111
        rrca
        rrca
        rrca
        add     a, e
        ld      e, a
        rr      c
        jr      c, pos26
        jr      nz, pos4
pos0    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $c0 >> 2
        call    simple
pos2    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $d8 >> 2
        ld      bc, $04fc
        call    doble
pos4    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $d0 >> 2
        ld      bc, $04f0
        call    doble
pos6    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $c8 >> 2
        call    simple
        inc     de
        jr      pos0
pos26   rr      c
        jr      c, pos6
        jr      pos2
prn2    and     %11111100
        ld      d, a
        xor     c
        ld      c, a
        cp      2
        adc     a, -1
        ld      e, a
        ld      a, d
        rrca
        ld      d, a
        rrca
        add     a, d
        add     a, e
        ld      e, a
        ld      a, b
        and     %00011000
        or      %01000000
        ld      d, a
        ld      a, b
        and     %00000111
        rrca
        rrca
        rrca
        add     a, e
        ld      e, a
        rr      c
        jr      c, pos37
        jr      nz, pos5
pos1    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $cc >> 2
        ld      bc, $04e0
        call    doble
pos3    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $c4 >> 2
        call    simple
pos5    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $dc >> 2
        ld      bc, $04fe
        call    doble
pos7    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $d4 >> 2
        ld      bc, $04f8
        call    doble
        jr      pos1
pos37   rr      c
        jr      c, pos7
        jr      pos3

simple  ld      b, 4
        ld      l, a
        add     hl, hl
        add     hl, hl
simple2 ld      a, (de)
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        ld      a, (de)
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        djnz    simple2
        ld      hl, $f800
        add     hl, de
        ex      de, hl
        ret

doble   ld      l, a
        add     hl, hl
        add     hl, hl
doble2  ld      a, (de)
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
fondo   incbin  fondo.rcs
