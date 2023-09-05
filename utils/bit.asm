; multicore load any .BIT core with rp2040 board
; File must exists in current directory
;
; Copyright (C) 2023 Antonio Villena and MicroJack
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

;               output  BIT

                include zxuno.def
                include esxdos.def

                org     $8000
                jr      NoPrint
                db      'BP', 0, 0, 0, 0, 'BIT plugin - AV & MicroJack', 0
                ; hl points to filename?
NoPrint         di
                push    hl              ; save pointer to filename
                xor     a               ; set a to zero - current drive
                rst     $08
                db      M_GETSETDRV
                ld      hl,sysex+4      ; point to end of sysex
                rst     $08
                db      F_GETCWD        ; get current working directory
                ld      bc, $064a       ; $47 xor $0d - b = 5 (size of sysex + 1)
                ld      de, sysex+4     ; end of sysex
                ld      a, (de)         ; get char
ChksumLoop      inc     de
                inc     b
                xor     c               ; char ^ c -> c
                ld      c, a
                ld      a, (de)         ; get char
                or      a               ; compare
                jr      nz, ChksumLoop
                pop     hl              ; retrieve filename
                ld      a, (hl)         ; get first char of filename
Bucle           inc     hl              ; increment pointer to filename
                inc     b               ; increment b = 6
                ld      (de), a         ; BUG? Should store a to de?  store a to filename and file pos + 1 ?
                inc     de              ; first time de is at sysex end
                xor     c               ; calculate checksum => a
                ld      c, a            ; move back to c
                ld      a, (hl)         ; get next byte
                or      a               ; force compare
                jr      nz, Bucle       ; jump if byte is not zero
                ld      a, c            ; move checksum to a
                ld      (de), a         ; store to next byte
                inc     de              ; increment de
                ld      a, $f7          ; end of sysex message
                ld      (de), a         ; store it
                ld      hl, sysex       ; BUG - should be sysex? point to beginning of sysex - 1
                ld      ixl, b          ; move length to ixl
                ld      bc, $fffd       ; bc = port of soundchip
                ld      e, 14           ; register 14
                out     (c), e          ; select register 14 - i/o port.
                ld      b, $bf
Sendbyte        ld      e, $fa          ; set rs232 'rxd' transmit line to 0. (keep keypad 'cts' output line low to prevent the keypad resetting)
                ld      d, 9            ; there are 8 bits to send (+start bit)
                ld      a, (hl)
                jr      Startbit
Sendbit         dec     e               ; (4)
                jp      nz, Sendbit     ; (10)
                rra                     ; (4) rotate the next bit to send into the carry.
                ld      e, $df          ; (7) 11011111
                rl      e               ; (8) 1011111x
                rlc     e               ; (8) 011111x1
                rlc     e               ; (8) 11111x10
Startbit        out     (c), e          ; (12)
                ld      e, 3            ; (7) introduce delays such that the next data bit is output 112 t-states from now.
                dec     d               ; (4) decrement the bit counter.
                jr      nz, Sendbit     ; (12/7) jump back if there are further bits to send.
                ld      e, 4            ; (7) introduce delays such that the next data bit is output 112 t-states from now.
Delay           dec     e               ; (4)
                jr      nz, Delay       ; (12/7)
                dec     e               ; (4)
                dec     e               ; (4) set rs232 'rxd' transmit line to 1. (keep keypad 'cts' output line low to prevent the keypad resetting)
                nop                     ; (4) delay
                nop                     ; (4) delay
                out     (c), e          ; (12) send out the stop bit.
                ld      e, 6            ; (7) delay for 101 t-states (28.5us).
Delay2          dec     e               ; (4)
                jr      nz, Delay2      ; (12/7)
                inc     hl
                dec     ixl
                jr      nz, Sendbyte

                halt

sysex           db      $00, $f0, $14, $0d
