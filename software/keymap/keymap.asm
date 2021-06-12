; keymap - utility for loading a keymap into the ZX-Uno. You only need a map
; filename, which must be saved in `/SYS/KEYMAPS' inside the SD card where
; ESXDOS is.
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

;               output  KEYMAP

 define PROGRAM         "keymap"
 define VERSION         "0.1"
 define DESCRIPTION     "Loads the specified keymap from", 13, KEYMAPPATH, " and enables it."
 define COPYRIGHT       127, " 2016-2021 Antonio Villena"
 define LICENSE         "License: GNU GPL 3.0"

 include "zxuno.def"
 include "esxdos.def"

 define KEYMAPPATH      "/SYS/KEYMAP"
 define FNAMESIZE       1024            ; will it be enough?
 define FBUFSIZE        4096            ; 4KB file buffer

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
                ret     z
                rst     $10
                inc     hl
                jr      Print

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to the command line arguments string (ASCIIZ)

Init:           ld      de, FileName
;               call    GetFileName             ; inline

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
                ld      (de),a
;               ret                     ; skipped

; continue Init()
                inc     de      ; DE remains pointing to the buffer that is
                                ; needed in OPEN, I don't know what for
;               jr      ReadMap         ; No need, it follows

;-----------------------------------------------------------------------------
; Subroutine
; In: DE = pointer to the buffer that is needed in OPEN, I don't know what for

ReadMap:        xor     a
                esxdos  M_GETSETDRV     ; A = current drive
                ld      b, FA_READ      ; B = file open mode
                ld      hl, FilePath    ; HL = pointer to a filename (ASCIIZ)
                esxdos  F_OPEN
                ret     c               ; Return on error
                ld      (FileHandle), a

                ld      bc, ZXUNOADDR
                ld      a, key_map      ; Select KEYMAP register
                out     (c), a

                ld      b, 4            ; 4 chunks of FBUFSIZE bytes each to load
.ReadMapFromFileLoop:
                push    bc              ; Save counter

                ld      bc, FBUFSIZE
                ld      hl, FileBuffer
                ld      a, (FileHandle)
                esxdos  F_READ
                jr      c, .Error       ; End reading on error

                ld      hl, FileBuffer
                ld      bc, ZXUNODATA
                ld      de, FBUFSIZE
.WriteMapToFPGALoop:
                ld      a, (hl)
                out     (c), a
                inc     hl
                dec     de
                ld      a, d
                or      e
                jr      nz, .WriteMapToFPGALoop

                pop     bc              ; Restore counter
                djnz    .ReadMapFromFileLoop

                jr      .ReadMapDone

.Error:         pop     bc              ; Restore stack
                push    af              ; Save error status
                ld      a, (FileHandle)
                esxdos  F_CLOSE
                pop     af              ; Restore error status
                ret

.ReadMapDone:   ld      a, (FileHandle)
                esxdos  F_CLOSE
                or      a               ; Return to ESXDOS without errors (CY=0)
                ret

;                        01234567890123456789012345678901
aUsage:         db      PROGRAM, " version ", VERSION, 13
                db      DESCRIPTION, 13
                db      COPYRIGHT, 13
                db      LICENSE, 13
                db      13
                db      "Usage:", 13
                db      "  .", PROGRAM, " file", 13, 0

FileHandle:     db      0

FilePath:       db      KEYMAPPATH, "/"
FileName:                               ; File name buffer
                org     $+FNAMESIZE
FileBuffer:                             ; File data buffer
