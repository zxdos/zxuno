; playzxm - a command for ESXDOS 0.8.5 that allows to play videos in ZXM
; format in Black&White and Color.
;
; Copyright (C) 2016-2021 Antonio Villena
; Contributors:
;   2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, version 3.
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
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

 define PROGRAM         "playzxm"
 define VERSION         "0.1"
 define DESCRIPTION     "Plays a video file encoded in", 13, "ZXM (colour/BW) format."
 define COPYRIGHT       127, " 2016-2021 Antonio Villena"
 define LICENSE         "License: GNU GPL 3.0"

 include "zxuno.def"
 include "esxdos.def"
 include "regs.mac"
 include "filezxm.def"

BORDERCLR:      equ     23624
PAPERCOLOR:     equ     23693
BANKM:          equ     $7ffd
STACK_TOP:      equ     $3dea           ; Value suggested by Miguel Ângelo to
                                        ; put the stack in the command area
ScreenAddr:     equ     $4000
FileBuffer:     equ     $8000

                org     $2000           ; entry point of ESXDOS program

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to the command line arguments string (ASCIIZ)

Main:
                ld      a,h
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
                ret     z
                rst     $10
                inc     hl
                jr      Print

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to the command line arguments string (ASCIIZ)

Init:
                ld      de, FileName
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
.End:           xor a
                ld      (de),a
;               ret             ; skipped

; continue Init()
                inc     de      ; DE remains pointing to the buffer that is
                                ; needed in OPEN, I don't know what for
                di
                ld      (BackupSP), sp
                ld      sp, STACK_TOP
                ei

                call    PlayFile
                push    af
                call    Cls
                pop     af
                ld      sp, (BackupSP)
                ret

;-----------------------------------------------------------------------------
; Subroutine

PlayFile:       ld_a    0
                esxdos  M_GETSETDRV     ; A = current drive
                ld      b, FA_READ      ; B = file open mode
                ld      hl, FileName    ; HL = pointer to file name (ASCIIZ)
                esxdos  F_OPEN
                ret     c               ; Return on error
                ld      (FileHandle), a

                call    SetupVideoMemory

                call    ReadHeader
                jr      c, .Stop        ; Stop on error

.Loop:          ld      hl, (StartScreen)
                ld      bc, (FrameLength)
                ld      a, (FileHandle)
                esxdos  F_READ
                jr      c, .Stop        ; Stop on error
                ld      a, b
                or      c
                jr      z, .Stop        ; Stop on end of data

                call    SwitchScreens
                ld      bc, $7ffe
                in      a, (c)          ; Detect if SPACE pressed
                and     %00000001
                jr      nz, .Loop

.Stop:          ld      a, (FileHandle)
                esxdos  F_CLOSE

                call    RestoreVideoMemory

                or      a               ; Return to ESXDOS without errors (CY=0)
                ret

;-----------------------------------------------------------------------------
; Subroutine

ReadHeader:     ld      a, (FileHandle)
                ld      bc, file_zxm_header_t
                ld      hl, FileBuffer
                esxdos  F_READ
                ret     c               ; Return on error

                ld      hl, FileBuffer + file_zxm_header_t.a_magic
                ld      a, 'Z'
                cpi
                jr      nz, BadFormat
                ld      a, 'X'
                cpi
                jr      nz, BadFormat
                ld      a, 'M'
                cpi
                jr      nz, BadFormat
                assume_hl FileBuffer + file_zxm_header_t.a_reserved_0

                chg_hl  FileBuffer + file_zxm_header_t.b_sectors_per_frame
                ld      a, (hl)
                add     a, a            ; BC = b_sectors_per_frame * 512
                ld      b, a            ;
                undef_b                 ;
                ld_c    0               ;
                ld      (FrameLength), bc

                chg_bc  $c000           ; Screen buffer for BW
                ld      (StartScreen), bc
                ld      a, (hl)         ; A = b_sectors_per_frame
                cp      12              ; B/W ?
                jr      z, ReadOK

                chg_bc  $c000 - 256     ; Screen buffer for color
                ld      (StartScreen), bc

ReadOK:         or      a               ; Success
                ret

BadFormat:      scf                     ; Error
                ret

;-----------------------------------------------------------------------------
; Subroutine

SetupVideoMemory:
                di
                ld_bc   BANKM
                ld_a    %00010111       ; Bank 7, normal display, ROM 3
                ld      (Bank), a
                out     (c), a

                ld      hl, $c000 + 6144
                ld      de, ScreenAddr + 6144
                chg_bc  768
.Loop:          ld      a, 64+56
                ld      (hl), a
                ld      (de), a
                inc     hl
                inc     de
                dec     bc
                ld      a, b
                or      c
                jr      nz, .Loop
                assume_a 0
                assume_bc 0

                chg_bc  zxuno_port
                chg_a   0
                out     (c), a
                chg_bc  zxuno_data
                in      a, (c)
                undef_a
                ld      (BackupConfig), a
                or      %00100000
                out     (c), a

                chg_a   0
                out     (254), a

                ei
                ret

;-----------------------------------------------------------------------------
; Subroutine

RestoreVideoMemory:
                di
                ld_bc   zxuno_port
                ld_a    0
                out     (c), a
                chg_bc  zxuno_data
                ld      a, (BackupConfig)
                undef_a
                out     (c), a
                chg_bc  BANKM
                chg_a   %00010000       ; Bank 0, normal display, ROM 3
                out     (c), a
                ei
                ret

;-----------------------------------------------------------------------------
; Subroutine

SwitchScreens:
                halt
                ld      a, (Bank)
                xor     %00001010       ; Switch from the normal screen to the
                ld      (Bank), a       ; shadow screen and from 7 to 5
                ld_bc   BANKM
                out     (c), a
                ret

;-----------------------------------------------------------------------------
; Subroutine

Cls:            ld      a,(BORDERCLR)
 .3             sra     a
                and     %00000111
                out     (254), a
                ld      hl, ScreenAddr  ; L = 0
                ld      de, ScreenAddr+1
                ld      bc, 6144-1
                ld      (hl), l
                ldir
                assume_bc 0
                inc     hl
                inc     de
                chg_bc  768-1
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
                db      "  .", PROGRAM, " moviefile.zxm", 13, 0

FileHandle:     db      0
Bank:           db      0
BackupSP:       dw      0
BackupConfig:   db      0
StartScreen:    dw      0
FrameLength:    dw      0
FileName:                               ; Rest of RAM for filename
