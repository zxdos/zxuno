; playrmov - a command for ESXDOS 0.8.5 and above that allows playing videos
; in Radastan format  (.RDM files) using DivMMC on the ZX-Uno.
;
; Copyright (C) 2016-2021 Antonio Villena
; Contributors:
;   Miguel Ângelo Guerreiro (fixed the stack problem)
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
; SPDX-FileCopyrightText: Copyright (C) 2016-2021 Antonio Villena
;
; SPDX-FileContributor: Miguel Ângelo Guerreiro
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; SPDX-License-Identifier: GPL-3.0-only

; Video: linear sequence of frames.
; Frame: 6144 bytes with the bitmap in Radastan format +
;        16 bytes for the palette (inputs 0-15)

;         output    PLAYRMOV

 define PROGRAM         "playrmov"
 define VERSION         "0.2"
 define DESCRIPTION     "Plays a video file encoded for", 13, "the ", 34, "Radastan", 34, " video mode."
 define COPYRIGHT       127, " 2016-2021 Antonio Villena"
 define LICENSE         "License: GNU GPL 3.0"

 include zxuno.def
 include esxdos.def
 include regs.mac

BORDERCLR:      equ     23624
PAPERCOLOR:     equ     23693
ULAPLUSADDR:    equ     $bf3b
ULAPLUSDATA:    equ     $ff3b
BANKM:          equ     $7ffd
PILA:           equ     $3dea           ; value suggested by Miguel Ângelo to
                                        ; put the stack in the command area

                org     $2000           ; entry point of ESXDOS program

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to the command line arguments string (ASCIIZ)

Main:           ld      a, h
                or      l
                jr      nz, Init        ; If no filename specified, show usage
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
                di
                ld      (BackupSP), sp
                ld      sp, PILA
                ei

                call    PlayFile
                call    Cls

                ld      sp, (BackupSP)
                ret

;-----------------------------------------------------------------------------
; Subroutine

PlayFile:       xor     a
                esxdos  M_GETSETDRV     ; A = current drive
                ld      b, FA_READ      ; B = file open mode
                ld      hl, FileName    ; HL = pointer to file name (ASCIIZ)
                esxdos  F_OPEN
                ret     c               ; Return on error
                ld      (FileHandle), a

                call    SetupVideoMemory

.Loop:          ld      hl, $c000
                ld      bc, 6144 + 16   ; Bitmap + palette
                ld      a, (FileHandle)
                esxdos  F_READ
                jr      c, .Stop        ; Stop on error
                ld      a,b
                or      c
                jr      z, .Stop        ; Stop on end of data
                call    SwitchScreens
                ld      bc, $7ffe
                in      a, (c)          ; Detect if SPACE has been pressed
                and     %00000001
                jr      nz, .Loop
.Stop:          ld      a, (FileHandle)
                esxdos  F_CLOSE

                call    RestoreVideoMemory

                or      a               ; Return to ESXDOS without errors (CY=0)
                ret

;-----------------------------------------------------------------------------
; Subroutine

SetupVideoMemory:
                di
                ld_bc   ZXUNOADDR
                ld_a    RADASCTRL
                out     (c), a
                chg_bc  ZXUNODATA
                chg_a   3               ; "Radastan" mode
                out     (c), a
                chg_bc  BANKM
                chg_a   %00010111       ; Bank 7, normal display, ROM 3
                ld      (Bank), a
                out     (c), a
                ei
                ret

;-----------------------------------------------------------------------------
; Subroutine

RestoreVideoMemory:
                di
                ld_bc   BANKM
                ld_a    %00010000       ; Bank 0, normal display, ROM 3
                out     (c), a
                chg_bc  ZXUNOADDR
                chg_a   RADASCTRL
                out     (c), a
                chg_bc  ZXUNODATA
                chg_a   0               ; Normal ULA mode
                out     (c),a
                ei
                ret

;-----------------------------------------------------------------------------
; Subroutine

SwitchScreens:  halt

                ld      ix, $c000 + 6144 ; IX = pointer to palette
                ld      d, 0             ; D = index to the palette that is being written
                ld      h, $ff           ; H = darkest color, to put on the edge afterwards
                ld      l, 0             ; L = index to the darkest color
PaletteUpdate:
                ld_bc   ULAPLUSADDR
                out     (c), d
                chg_bc  ULAPLUSDATA
                ld      a, (ix)
                out     (c), a
                ld      a, d
                cp      8                ; Only do the test for indices 0-7
                jr      nc, .NoDarkColor
                ld      a, (ix)
                cp      h
                jr      nc, .NoDarkColor
                ld      h, a
                ld      l, d
.NoDarkColor:   inc     ix
                inc     d
                ld      a, 16
                cp      d
                jr      nz, PaletteUpdate

                ld      a, l            ; The edge is as dark as possible
                out     (254), a        ;

                ld      a, (Bank)       ; Switch from the normal screen to
                xor     %00001010       ; the shadow screen and from 7 to 5
                ld      (Bank), a       ;
                ld      bc, BANKM       ;
                out     (c), a          ;
                ret

;-----------------------------------------------------------------------------
; Subroutine

Cls:            ld      a, (BORDERCLR)
 .3             sra     a
                and     %00000111
                out     (254), a
                ld      hl, ScreenAddr  ; L = 0
                ld      de, ScreenAddr+1
                ld      bc, 6144-1
                ld      (hl), l
                ldir
                inc     hl
                inc     de
                ld      bc, 768-1
                ld      a, (PAPERCOLOR)
                ld      (hl), a
                ldir
                ret

;                        01234567890123456789012345678901
aUsage:         db      PROGRAM, " version ", VERSION, 13
                db      DESCRIPTION, 13
                db      COPYRIGHT, 13
                db      LICENSE, 13
                db      13
                db      "Usage:", 13
                db      "  .", PROGRAM, " moviefile.rdm", 13, 0

FileHandle      db      0
Bank            db      0
BackupSP        dw      0
FileName:                               ; Rest of RAM for filename
ScreenAddr:     equ     $4000
