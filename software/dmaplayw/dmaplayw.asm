; dmaplayw.asm - play an audio file using the SpecDrum and DMA at 15.625 kHz.
;
; Copyright (C) 2017-2021 AZXUNO association
; Contributors:
;   2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;
; SPDX-FileCopyrightText: Copyright (C) 2017-2021 AZXUNO association
;
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; SPDX-License-Identifier: GPL-3.0-or-later

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

;               output  DMAPLAYW

 define PROGRAM         "dmaplayw"
 define VERSION         "0.1"
 define DESCRIPTION     "Plays an audio file using the", 13, "SpecDrum and DMA at 15.625 kHz"
 define COPYRIGHT       127, " 2017-2021 AZXUNO association"
 define LICENSE         "License: GNU GPL 3.0 or above"

 include "zxuno.def"
 include "esxdos.def"
 include "regs.mac"

 define CPU_FREQ        3500000
 define SPECDRUM_FREQ   15625

 ; Prescaler for timed DMA. The count goes from 0 to 223, that is, 224 cycles
 define DMA_PRESCALER   CPU_FREQ / SPECDRUM_FREQ - 1

 define DMA_BUFSIZE      2048           ; DMA buffer size

ScreenAddr:     equ     $4000
DMABuffer:      equ     $8000   ; DMA buffer start address (circular play buffer)

                org     $2000           ; entry point of ESXDOS program

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to the command line arguments string (ASCIIZ)

Main:           ld      a, h
                or      l
                jr      nz, Init
;               jr      ShowUsage       ; No need, it follows

;-----------------------------------------------------------------------------
; Subroutine

ShowUsage:      ld      hl, aUsage
;               jr      Print           ; No need, it follows

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to an ASCIIZ string

Print:          ld      a, (hl)
                or      a
                ret     z               ; Return on string end
                rst     $10
                inc     hl
                jr      Print

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to the command line arguments string (ASCIIZ)

Init:           ld      de, FileName
;               call    GetFileName     ; inline

;-----------------------------------------------------------------------------
; Subroutine
; In:  HL = pointer to the command line arguments (filename)
;      DE = pointer to the output ASCIIZ string (filename)
; Out: DE = pointer to terminating 0 character of output string

.GetFileName:   ld      a, (hl)
                or      a
                jr      z, .End
                cp      " "
                jr      z, .End
                cp      ":"
                jr      z, .End
                cp      13
                jr      z, .End
                ldi
                jr      .GetFileName
.End:           xor     a
                ld      (de), a
;               ret                     ; skipped

; continue Init()
                inc     de      ; DE remains pointing to the buffer that is
                                ; needed in OPEN, I don't know what for
                xor     a
                esxdos  M_GETSETDRV     ; A = current drive
                ld      b, FA_READ      ; B = file open mode
                ld      hl, FileName    ; HL = pointer to filename (ASCIIZ)
                esxdos  F_OPEN
                ret     c               ; Return on error
                ld      (FileHandle), a
                ld      l, SEEK_START
                ld      bc, 0
                ld      de, 44          ; Skip 44 bytes from start (WAV header)
                esxdos  F_SEEK
                ret     c               ; Return on error
                ld      hl, ScreenAddr
                ld      de, ScreenAddr+1
                ld      bc, 32-1
                ld      (hl), 255
                ldir                    ; This line will be deleted on the first wave plot

                ld      hl, ScreenLines ; Fill ScreenLines
                ld      de, ScreenAddr  ; with screen lines addresses
                ld      b, (192-1)+1    ; 191 repeats
.LineDownLoop:  ld      (hl), e
                inc     hl
                ld      (hl), d
                inc     hl
                ; Calculate next line (down one line)
                inc     d               ; D = (D + 1) & 255
                ld      a, d            ; A = D
                and     %00000111       ; A = D & 7, CY = 0
                jr      nz, .SamePart   ; if (D & 7) goto SamePart
                ld      a, e            ; A = E
                sub     a, -32          ; A = (E + 32) & 255, CY = !A
                ld      e, a            ; E = (E + 32) & 255, CY = !E
                sbc     a, a            ; A = -CY
                and     %11111000       ; A = -8 * CY
                add     a, d            ; A = (D - 8 * CY) & 255
                ld      d, a            ; D = (D - 8 * CY) & 255
.SamePart:      djnz    .LineDownLoop

;               ld      hl, WaveBuffer  ; HL already points to WaveBuffer
                ld      de, WaveBuffer+1
                ld      bc, 256-1       ; B = 0
                ld      (hl), b
                ldir                    ; Clear WaveBuffer

                ld      hl, DMABuffer
                ld      de, DMABuffer+1
                ld      bc, DMA_BUFSIZE-1
                ld      (hl), 0
                ldir                    ; Clear DMA buffer

                ; Prepare to play
                di
                ld_hl   DMABuffer
                ld_bc   zxuno_port
                ld_a    dma_src
                out     (c), a
                chg_bc  zxuno_data
                out     (c), l
                out     (c), h
                chg_bc  zxuno_port
                chg_a   dma_dst
                out     (c), a
                chg_bc  zxuno_data
                chg_hl  specdrum_port
                out     (c), l
                out     (c), h
                chg_bc  zxuno_port
                chg_a   dma_pre
                out     (c), a
                chg_bc  zxuno_data
                chg_hl  DMA_PRESCALER
                out     (c), l
                out     (c), h
                chg_bc  zxuno_port
                chg_a   dma_len
                out     (c), a
                chg_bc  zxuno_data
                chg_hl  DMA_BUFSIZE
                out     (c), l
                out     (c), h
                chg_bc  zxuno_port
                chg_a   dma_prob
                out     (c), a
                chg_bc  zxuno_data
                chg_hl  DMABuffer       ; hl
                out     (c), l
                out     (c), h
                chg_bc  zxuno_port
                chg_a   dma_ctrl
                out     (c), a
                chg_bc  zxuno_data
                chg_a   %00000111       ; Mem to I/O, redisparable, timed, source address is checked
                out     (c), a
PlayLoop:       ld_bc   $7ffe           ; SPACE halfrow
                in      a, (c)
                and     %00000001
                jp      z, .ExitPlay
                chg_bc  zxuno_port
                ld      a, dma_stat
                out     (c), a
                chg_bc  zxuno_data
.StillInSecondHalf:
                in      a, (c)
                bit     7, a
                jr      z, .StillInSecondHalf
                chg_bc  zxuno_port
                ld_a    dma_prob
                out     (c), a
                chg_bc  zxuno_data
                chg_hl  DMABuffer + DMA_BUFSIZE/2
                out     (c), l
                out     (c), h
                chg_bc  zxuno_port
                chg_a   dma_stat
                out     (c), a
                chg_bc  zxuno_data
                in      a, (c)

                ; Fill second half of buffer with audio data
                chg_hl  DMABuffer + DMA_BUFSIZE/2
                chg_bc  DMA_BUFSIZE/2
                ld      a, (FileHandle)
                esxdos  F_READ
                jp      c, .ExitPlay    ; End read on error
                ld      a, b
                or      c
                jp      z, .ExitPlay    ; End read on end of data

                ld      hl, DMABuffer + DMA_BUFSIZE/2
                call    PlotWave

                ld_bc   zxuno_port
                ld      a, dma_stat
                out     (c), a
                chg_bc  zxuno_data
.StillInFirstHalf:
                in      a, (c)
                bit     7, a
                jr      z, .StillInFirstHalf

                chg_bc  zxuno_port
                ld_a    dma_prob
                out     (c), a
                chg_bc  zxuno_data
                ld_hl   DMABuffer
                out     (c), l
                out     (c), h
                chg_bc  zxuno_port
                chg_a   dma_stat
                out     (c), a
                chg_bc  zxuno_data
                in      a, (c)

                ; Fill first half of buffer with audio data
                chg_hl  DMABuffer
                chg_bc  DMA_BUFSIZE/2
                ld      a, (FileHandle)
                esxdos  F_READ
                jp      c, .ExitPlay    ; End read on error
                ld      a, b
                or      c
                jp      z, .ExitPlay    ; End read on end of data

                ld      hl, DMABuffer
                call    PlotWave

                jp      PlayLoop

.ExitPlay:      ld_bc   zxuno_port
                ld_a    dma_ctrl
                out     (c), a
                chg_bc  zxuno_data
                chg_a   0
                out     (c), a
                chg_bc  zxuno_port

                ld      a, (FileHandle)
                esxdos  F_CLOSE

                or      a               ; Return to ESXDOS without errors (CY=0)
                ei
                ret

;-----------------------------------------------------------------------------
; Subroutine

PlotWave:       ld      de, WaveBuffer
                ld      c, 0
.Loop:          ld      a, (de)
                ld      b, a
                call    Plot
                ld      a, (hl)
                srl     a
                add     a, 24
                ld      b, a
                call    Plot
                ld      a, b
                ld      (de), a
                inc     hl
                inc     de
                inc     c
                jp      nz, .Loop
                ret

;-----------------------------------------------------------------------------
; Subroutine
; In: B = y
;     C = x

Plot:           push    bc
                push    de
                push    hl
                ld      e, b
                ld      d, 0            ; DE = y
                sla     e
                rl      d               ; DE = DE*2
                ld      hl, ScreenLines
                add     hl, de          ; HL = pointer to the address of the first pixel of Y
                ld      e, (hl)
                inc     hl
                ld      d, (hl)
                ex      de, hl          ; HL = dir first pixel row Y
                ld      d, c            ; save X coordinate in D
                ld      a, c
 .3             srl     a
                ld      c, a
                ld      b, 0
                add     hl, bc          ; HL contains the address to paint the pixel
                ld      a, d            ; restore X coordinate
                and     %00000111
                ld      de, PixelMask
                add     a, e
                ld      e, a
                ld      a, d
                adc     a, 0
                ld      d, a
                ld      a, (de)
                xor     (hl)
                ld      (hl), a
                pop     hl
                pop     de
                pop     bc
                ret

;                        01234567890123456789012345678901
aUsage:         db      PROGRAM, " version ", VERSION, 13
                db      DESCRIPTION, 13
                db      COPYRIGHT, 13
                db      LICENSE, 13
                db      13
                db      "Usage:", 13
                db      "  .", PROGRAM, " audiofile.wav", 13, 0

FileHandle:     db      0

i = %10000000
PixelMask:      dup     8
                db      i
i = i / 2
                edup

ScreenLines:    org     $+192*2

WaveBuffer:     org     $+256

FileName:                       ; Rest of RAM for filename
