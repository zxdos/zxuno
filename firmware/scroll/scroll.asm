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
        include ay.def
        include prn6x8f.mac

        org     $5e6d

        export  filestart
        export  start

SCREEN: equ $4000
ATTRS: equ $5800
FONT: equ $c000         ; only bits 10-15 are used
FA: equ 80              ; font characters available for printing
FC: equ 128             ; font capacity (total characters used by subroutines)
XMAX: equ (256-6)/3     ; maximal horizontal position to print string
XA: equ 5               ; X attributes offset
YA: equ 23              ; Y attributes offset
LS: equ 22              ; line size (bytes)

PLAYSTC_AY_FREQUENCY: equ ay_freq_Spectrum
PLAYSTC_USER_DEFINED_FILE: equ 0

; copy LS bytes from (x0, y0) to (x1, y1)
 macro copy_screen_line x1, y1, x0, y0
        memcpy_22 SCREEN+2048*(y1/64)+256*(y1&7)+32*((y1/8)&7)+x1, SCREEN+2048*(y0/64)+256*(y0&7)+32*((y0/8)&7)+x0
 endm

; copy LS bytes from (x0, y0) to (x1, y1)
 macro copy_attrs_line x1, y1, x0, y0
        memcpy_22 ATTRS+y1*32+x1, ATTRS+y0*32+x0
 endm

filestart

start   ld      hl, FONT                ; L = 0
        ld      de, FONT+1
        ld      bc, 8*(FC-FA)-1
        ld      (hl), l
        ldir                            ; clear unused characters
        ld      hl, font
        ld      bc, 8*FA
        ldir                            ; copy font
        ; HL = picture
        ld      b, high SCREEN          ; BC = SCREEN
        drcs_screen                     ; show picture
        ; A = 0, BC = 32*192, DE = ATTRS, HL = picture+32*192
        ld      b, high (32*24)         ; BC = 32*24
        ldir                            ; show attributes
        out     ($fe), a                ; set border to black
        inc     a                       ; A = flag variable to print new text
        ex      af, af'                 ; hide flag variable
        ld      hl, FONT
        ld      de, FONT+8*FC
        ld      b, high (8*FC*7)        ; BC = size of 7 copies of font
setfont ld      a, (hl)                 ; A = (HL)
        rrca                            ; A = [A0 A7 A6 A5 A4 A3 A2 A1]
        ld      (de), a                 ; (DE) = A
        inc     de                      ; DE++
        cpi                             ; HL++, BC--, PV = (BC!=0)
        jp      pe, setfont             ; if (BC) goto setfont
        ld      hl, track
        call    PlaySTC.Init
;       jp      main_loop               ; no need, it follows

main_loop
        call    PlaySTC.Play
        ei
        halt                            ; wait for new video frame
        di
        ; wait to avoid refresh artifacts on the screen
        ld      bc, 5                   ; B = 0, C = 5
pause   djnz    pause                   ; wait: inner loop (256 iterations)
        dec     c                       ; B = 0, C--
        jr      nz, pause               ; wait: outer loop (5 iterations)
y=0     ; scroll credits
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
        ld      ix, credits
credits_pos: equ $-2
        ld      hl, main_loop
        push    hl                      ; ($fffe) = main_loop
        ld      hl, music
        push    hl                      ; ($fffc) = music
        ex      af, af'                 ; show flag variable
        rrca                            ; next screen line, CY = new text
        jr      c, new_text
        ex      af, af'                 ; hide flag variable
        ret                             ; jump to "music"

new_text
        ex      af, af'                 ; hide flag variable
y=0
      dup YA-1
        copy_attrs_line XA, y, XA, (y+1)
y=y+1
      edup
        ld      sp, $fffc
getattr ld      b, (ix)                 ; B = attribute or end mark
        djnz    goahead                 ; if (--B) goto goahead
        ld      ix, credits             ; IX = credits
        jr      getattr                 ; B = attribute
goahead inc     ix                      ; IX = pointer to ASCIIZ string
        ld      hl, ATTRS+32*(YA-1)+XA
        ld      (hl), b
        ld      de, ATTRS+32*(YA-1)+XA+1
        ld      bc, LS-1
        ldir                            ; fill attributes (LS bytes)
        xor     a                       ; A = 0
        push    ix                      ; IX = pointer to ASCIIZ string
        pop     hl                      ; HL = IX
        ld      bc, (YA<<8)+(XMAX+1)/2+1; B = YA, C = (XMAX+1)/2+1
        cpir                            ; C = (XMAX+1)/2-strlen(HL)
;       jp      print                   ; no need, it follows
print   print6x8_84_fast FONT           ; inline

music   ld      (credits_pos), ix
        jp      PlaySTC.Play

        include playstc.inc

track   incbin  music.stc

credits include string.asm

; Sequence must match with no gaps: font, picture

font    incbin  fuente6x8.bin

picture incbin  fondo.rcs
