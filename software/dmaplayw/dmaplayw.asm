; dmaplayw.asm - play an audio file using the SpecDrum and DMA at 15.625 kHz.
;
; Copyright (C) 2017 AZXUNO association
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
; SPDX-FileCopyrightText: Copyright (C) 2017 AZXUNO association
;
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; SPDX-License-Identifier: GPL-3.0-or-later

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

;               output  DMAPLAYW

 define PROGRAM "dmaplayw"
 define VERSION "0.1"

 include "zxuno.def"
 include "esxdos.def"

 define CPU_FREQ        3500000
 define SPECDRUM_FREQ   15625

 ; Prescaler for timed DMA. The count goes from 0 to 223, that is, 224 cycles
 define DMA_PRESCALER   CPU_FREQ / SPECDRUM_FREQ - 1

                org     $2000   ; entry point of ESXDOS program

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to the command line arguments string (ASCIIZ)

Main            ld      a, h
                or      l
                jp      nz, Init
                ld      hl, aUsage
.PrintLoop      ld      a, (hl)
                or      a
                ret     z       ; Return on string end
                rst     $10
                inc     hl
                jr      .PrintLoop

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to the command line arguments (filename)

GetFileName     ld      de, BufferFileName
.CheckCharacter ld      a, (hl)
                or      a
                jr      z, .End
                cp      " "
                jr      z, .End
                cp      ":"
                jr      z, .End
                cp      13
                jr      z, .End
                ldi
                jr      .CheckCharacter
.End            xor     a
                ld      (de), a
                inc     de      ; DE remains pointing to the buffer that is needed in OPEN, I don't know what for
                ret

;                        01234567890123456789012345678901
aUsage          db      " .", PROGRAM, " audiofile.wav", 13
                db      13
                db      "Plays an audio file using the", 13
                db      "SpecDrum and DMA at 15.625 kHz", 13, 0

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to the command line arguments string (ASCIIZ)

Init            call    GetFileName     ; results DE = buffer for OPEN
                xor     a
                esxdos  M_GETSETDRV     ; A = current unit
                ld      b, FA_READ      ; B = opening mode
                ld      hl, BufferFileName      ; HL = pointer to file name (ASCIIZ)
                esxdos  F_OPEN
                ret     c               ; Return on error
                ld      (FHandle), a
                ld      l, SEEK_START
                ld      bc, 0
                ld      de, 44          ; Skip 44 bytes from start (WAV header)
                esxdos  F_SEEK
                ret     c               ; Return on error
                ld      hl, ScreenAddr
                ld      de, ScreenAddr+1
                ld      bc, 31
                ld      (hl), 255
                ldir                    ; This line will be deleted on the first wave plot

                ld      hl, DMABuffer
                ld      de, DMABuffer+1
                ld      bc, DMABuffer_Len-1
                ld      (hl), 0
                ldir                    ; Clear DMA buffer

                ; Prepare to play
                di
                ld      hl, DMABuffer
                ld      bc, zxuno_port
                ld      a, dma_src
                out     (c), a
                inc     b               ; BC = zxuno_data
                out     (c), l
                out     (c), h
                dec     b               ; BC = zxuno_port
                ld      a, dma_dst
                out     (c), a
                inc     b               ; BC = zxuno_data
                ld      hl, specdrum_port
                out     (c), l
                out     (c), h
                dec     b               ; BC = zxuno_port
                ld      a, dma_pre
                out     (c), a
                inc     b               ; BC = zxuno_data
                ld      hl, DMA_PRESCALER
                out     (c), l
                out     (c), h
                dec     b               ; BC = zxuno_port
                ld      a, dma_len
                out     (c), a
                inc     b               ; BC = zxuno_data
                ld      hl, DMABuffer_Len
                out     (c), l
                out     (c), h
                dec     b               ; BC = zxuno_port
                ld      a, dma_prob
                out     (c), a
                inc     b               ; BC = zxuno_data
                ld      hl, DMABuffer
                out     (c), l
                out     (c), h
                dec     b               ; BC = zxuno_port
                ld      a, dma_ctrl
                out     (c), a
                inc     b               ; BC = zxuno_data
                ld      a, %00000111    ; Mem to I/O, redisparable, timed, source address is checked
                out     (c), a
                dec     b               ; BC = zxuno_port
.PlayLoop       ld      bc, $7ffe       ; SPACE halfrow
                in      a, (c)
                and     %00000001
                jp      z, .ExitPlay
                ld      bc, zxuno_port
                ld      a, dma_stat
                out     (c), a
                inc     b               ; BC = zxuno_data
.StillInSecondHalf
                in      a, (c)
                bit     7, a
                jr      z, .StillInSecondHalf
                dec     b               ; BC = zxuno_port
                ld      a, dma_prob
                out     (c), a
                inc     b               ; BC = zxuno_data
                ld      hl, DMABuffer + DMABuffer_Len/2
                out     (c), l
                out     (c), h
                dec     b               ; BC = zxuno_port
                ld      a, dma_stat
                out     (c), a
                inc     b               ; BC = zxuno_data
                in      a, (c)

                ; Fill second half of buffer with audio data
                ld      hl, DMABuffer + DMABuffer_Len/2
                ld      bc, DMABuffer_Len/2
                ld      a, (FHandle)
                esxdos  F_READ
                jp      c, .ExitPlay    ; End read on error
                ld      a, b
                or      c
                jp      z, .ExitPlay    ; End read on end of data

                ld      hl, DMABuffer + DMABuffer_Len/2
                call    PlotWave

                ld      bc, zxuno_port
                ld      a, dma_stat
                out     (c), a
                inc     b               ; BC = zxuno_data
.StillInFirstHalf
                in      a, (c)
                bit     7, a
                jr      z, .StillInFirstHalf

                dec     b               ; BC = zxuno_port
                ld      a, dma_prob
                out     (c), a
                inc     b               ; BC = zxuno_data
                ld      hl, DMABuffer
                out     (c), l
                out     (c), h
                dec     b               ; BC = zxuno_port
                ld      a, dma_stat
                out     (c), a
                inc     b               ; BC = zxuno_data
                in      a, (c)

                ; Fill first half of buffer with audio data
                ld      hl, DMABuffer
                ld      bc, DMABuffer_Len/2
                ld      a, (FHandle)
                esxdos  F_READ
                jp      c, .ExitPlay    ; End read on error
                ld      a, b
                or      c
                jp      z, .ExitPlay    ; End read on end of data

                ld      hl, DMABuffer
                call    PlotWave

                jp      .PlayLoop

.ExitPlay       ld      bc, zxuno_port
                ld      a, dma_ctrl
                out     (c), a
                inc     b               ; BC = zxuno_data
                xor     a
                out     (c), a
                dec     b               ; BC = zxuno_port

                ld      a, (FHandle)
                esxdos  F_CLOSE

                or      a       ; Clear carry flag
                ei
                ret

FHandle         db      0

;-----------------------------------------------------------------------------
; Subroutine

PlotWave        ld      de, BufferCleared
                ld      c, 0
.Loop           ld      a, (de)
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

Plot            push    bc
                push    de
                push    hl
                ld      e, b
                ld      d, 0            ; DE = y
                sla     e
                rl      d               ; DE = DE*2
                ld      hl, DirScan
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
                ld      de, DirBits
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

DirBits
i = %10000000
 while i > 0
                db       i
i = i / 2
 endw

DirScan
y = 0
 while y < 192
                dw	ScreenAddr + (256 * (y & 7)) + (32 * ((y / 8) & 7)) + (64 * 32 * (y / 64))
y = y + 1
 endw

BufferCleared   ds      256

BufferFileName: equ     $       ; Rest of RAM for filename

ScreenAddr:     equ     $4000

DMABuffer:      equ     $8000   ; DMA buffer start address (circular play buffer)
DMABuffer_Len:  equ     2048    ; DMA buffer length
