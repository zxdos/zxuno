; zxunocfg.asm - configure/print ZX-Uno options.
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
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.
;
; SPDX-FileCopyrightText: Copyright (C) 2016-2021 Antonio Villena
;
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

                include zxuno.def

        define  PROGRAM "zxunocfg"
        define  PROGRAMUC "ZXUNOCFG"    ; uppercase
        define  VERSION "1.0.1"
        define  CORE_ID_STR_LEN 32

                org     $2000      ; entry point of ESXDOS program

 ; small optimization
 macro lda value
  if value = 0
                xor     a               ; 1 byte
  else
                ld      a, value        ; 2 bytes
  endif
 endm

;------------------------------------------------------
; Subroutine
; In: HL = pointer to arguments or 0 to print configuration

Main
                ld      a, h
                or      l
                jr      z, .Print
                call    CollectParam
                call    ParseParam
                jr      nc, .Ok
                cp      255
                ret     z
                ret     c
.Ok             call    ZXUno_WriteScanDblCtrl
.Print          call    PrintCurrentMode
                or      a
                ret

;------------------------------------------------------
; Subroutine

PrintCurrentMode
                ld      a, (QuietMode)
                or      a
                ret     nz

                ld      hl, aCoreID
                call    ZXUno_ReadCoreID
                ld      hl, aCore
                call    Print

                call    ZXUno_ReadScanDblCtrl

                ld      hl, aTiming
                call    Print
                ld      a, (ConfValue)
                ld      hl, aTiming_Pentagon
                bit     6, a
                jr      nz, .PrintTiming
                ld      hl, aTiming_128K
                bit     4, a
                jr      nz, .PrintTiming
                ld      hl, aTiming_48K
.PrintTiming    call    Print

                ld      hl, aContention
                call    Print
                ld      a, (ConfValue)
                ld      hl, aEnabled
                bit     5, a
                jr      z, .PrintContention
                ld      hl, aDisabled
.PrintContention
                call    Print

                ld      hl, aKeyboard
                call    Print
                ld      a, (ConfValue)
                cpl
                and     %00001000       ;
 .3             rrca                    ; A = "2" or "3" depending upon the bit at 3
                add     a, "2"          ;
                rst     $10
                ld      a, 13
                rst     $10

                call    ZXUno_InitMouse
                ld      hl, aMouse
                call    Print

                ld      hl, aSpeed
                call    Print
                ld      a, (ScanDblCtrl)
                and     %11000000
;               cp      %00000000
                ld      hl, aSpeed_0
                jr      z, .PrintSpeed
                cp      %01000000
                ld      hl, aSpeed_1
                jr      z, .PrintSpeed
                cp      %10000000
                ld      hl, aSpeed_2
                jr      z, .PrintSpeed
                ld      hl, aSpeed_3
.PrintSpeed     call    Print

                ld      hl, aVideo
                call    Print
                ld      a, (ScanDblCtrl)
                ld      hl, aVideo_Composite
                bit     0, a
                jr      z, .PrintVideo
                ld      hl, aVideo_VGANoScans
                and     %00000011
                cp      1
                jr      z, .PrintVideo
                ld      hl, aVideo_VGAScans
.PrintVideo     call    Print

                ld      hl, aVFreq
                call    Print
                ld      a, (ScanDblCtrl)
                and     %00011100
                rrca            ; A = (ScanDblCtrl & 0b00011100 >> 2) * 2
                ld      e, a
                ld      d, 0
                ld      hl, tabVFreqStr
                add     hl, de
                ld      a, (hl)
                inc     hl
                ld      h, (hl)
                ld      l, a
                jp      Print

;------------------------------------------------------
; Subroutine
; In: HL = pointer to arguments

CollectParam
                ld      de, BufferParam
.Loop           ld      a, (hl)
                or      a
                jr      z, .End
                cp      ":"
                jr      z, .End
                cp      13
                jr      z, .End
                ldi
                jr      .Loop
.End            ld      a, " "
                ld      (de), a
                inc     de
                xor     a
                ld      (de), a
                ret

;------------------------------------------------------
; Subroutine

ParseParam
                call    ZXUno_ReadScanDblCtrl

                ld      hl, BufferParam
.NextChar       ld      a, (hl)
                inc     hl
                or      a
                ret     z
                cp      " "
                jr      z, .NextChar
                cp      "-"
                jp      nz, .BadOption
                ld      a, (hl)
                inc     hl
                cp      "h"
                jr      z, .OptHelp
                cp      "q"
                jr      z, .OptQuiet
                cp      "t"
                jr      z, .OptTiming
                cp      "c"
                jp      z, .OptContention
                cp      "k"
                jp      z, .OptKeyboard
                cp      "s"
                jp      z, .OptSpeed
                cp      "v"
                jp      z, .OptVideo
                cp      "f"
                jp      z, .OptVFreq
                jp      .BadOption

.SaveConfValue
                ld      (ConfValue), a
                jr      .NextChar

.SaveScanDblCtrl
                ld      (ScanDblCtrl), a
                jr      .NextChar

.OptHelp
                call    CheckOptionTail
                ld      hl, aUsage
                call    Print
                ld      a, 255
                scf
                ret

.OptQuiet
                call    CheckOptionTail
                ld      a, 1
                ld      (QuietMode), a
                jp      .NextChar

.OptTiming
                ld      a, (hl)
                inc     hl
                cp      "1"
                jr      z, .OptTiming_128K
                cp      "p"
                jr      z, .OptTiming_Pentagon
                cp      "4"
                jp      nz, .BadOption

.OptTiming_48K
                ld      a, (hl)
                inc     hl
                cp      "8"
                jp      nz, .BadOption
                call    CheckOptionTail
                ld      a, (ConfValue)
                and     %10101111       ; clear bit 4 and 6
                jp      .SaveConfValue

.OptTiming_128K
                ld      a, (hl)
                inc     hl
                cp      "2"
                jp      nz, .BadOption
                ld      a, (hl)
                inc     hl
                cp      "8"
                jp      nz, .BadOption
                call    CheckOptionTail
                ld      a, (ConfValue)
                and     %10101111       ; clear bit 4 and 6
                or      %00010000       ; set bit 4
                jp      .SaveConfValue

.OptTiming_Pentagon
                ld      a, (hl)
                inc     hl
                cp      "e"
                jp      nz, .BadOption
                ld      a, (hl)
                inc     hl
                cp      "n"
                jp      nz, .BadOption
                call    CheckOptionTail
                ld      a, (ConfValue)
                and     %10101111       ; clear bit 4 and 6
                or      %01000000       ; set bit 6
                jp      .SaveConfValue

.OptContention
                ld      a, (hl)
                inc     hl
                cp      "y"
                jp      nz, .OptContention_Disable

.OptContention_Enable
                call    CheckOptionTail
                ld      a, (ConfValue)
                and     %11011111
;               or      %00000000
                jp      .SaveConfValue

.OptContention_Disable
                cp      "n"
                jp      nz, .BadOption
                call    CheckOptionTail
                ld      a, (ConfValue)
;               and     %11011111
                or      %00100000
                jp      .SaveConfValue

.OptKeyboard
                ld      a, (hl)
                inc     hl
                cp      "2"
                jr      nz, .OptKeyboard_Issue3

.OptKeyboard_Issue2
                call    CheckOptionTail
                ld      a, (ConfValue)
;               and     %11110111
                or      %00001000
                jp      .SaveConfValue

.OptKeyboard_Issue3
                cp      "3"
                jp      nz, .BadOption
                call    CheckOptionTail
                ld      a, (ConfValue)
                and     %11110111
;               or      %00000000
                jp      .SaveConfValue

.OptSpeed
                ld      a, (hl)
                inc     hl
                cp      "0"
                jp      c, .BadOption
                cp      "4"
                jp      nc, .BadOption
                ld      b, a
                call    CheckOptionTail
                ld      a, b
                and     %00000011       ; CY = 0
 .2             rrca                    ; CY = A7
                ld      b, a
                ld      a, (ScanDblCtrl)
                and     %00111111       ; CY = 0
                or      b
                jp      .SaveScanDblCtrl

.OptVideo
                ld      a, (hl)
                inc     hl
                cp      "1"
                jr      z, .OptVideo_VGANoScans
                cp      "2"
                jr      z, .OptVideo_VGAScans
                cp      "0"
                jp      nz, .BadOption

.OptVideo_Composite
                call    CheckOptionTail
                ld      a, (ScanDblCtrl)
                and     %11111100
;               or      %00000000
                jp      .SaveScanDblCtrl

.OptVideo_VGANoScans
                call    CheckOptionTail
                ld      a, (ScanDblCtrl)
                and     %11111100
                or      %00000001
                jp      .SaveScanDblCtrl

.OptVideo_VGAScans
                call    CheckOptionTail
                ld      a, (ScanDblCtrl)
;               and     %11111100
                or      %00000011
                jp      .SaveScanDblCtrl

.OptVFreq
                ld      a, (hl)
                inc     hl
                cp      "0"
                jr      c, .BadOption
                cp      "8"
                jr      nc, .BadOption
                sub     "0"
                ld      b, a
                call    CheckOptionTail
                ld      a, b
 .2             add     a, a
                ld      b, a
                ld      a, (ScanDblCtrl)
                and     %11100011
                or      b
                jp      .SaveScanDblCtrl

.BadOption
                lda     0
                ld      hl, aBadOption
                scf
                ret

;------------------------------------------------------
; Subroutine
; In:  HL = pointer to arguments
; Out: HL += 1

CheckOptionTail
                ld      a, (hl)
                inc     hl
                cp      " "
                ret     z
                pop     hl      ; not used
                jr      ParseParam.BadOption

;------------------------------------------------------
; Subroutine
; In: HL = pointer to ASCIZ string

Print
                ld      a, (hl)
                or      a
                ret     z
                rst     $10
                inc     hl
                jr      Print

;------------------------------------------------------
; Subroutine

ZXUno_ReadScanDblCtrl
                lda     master_conf
                ld      bc, zxuno_port
                out     (c), a
                inc     b       ; BC = zxuno_data
                in      a, (c)
                ld      (ConfValue), a
                lda     scandbl_ctrl
                dec     b       ; BC = zxuno_port
                out     (c), a
                inc     b       ; BC = zxuno_data
                in      a, (c)
                ld      (ScanDblCtrl), a
                ret

;------------------------------------------------------
; Subroutine

ZXUno_WriteScanDblCtrl
                lda     master_conf
                ld      bc, zxuno_port
                out     (c), a
                ld      a, (ConfValue)
                inc     b       ; BC = zxuno_data
                out     (c), a
                lda     scandbl_ctrl
                dec     b       ; BC = zxuno_port
                out     (c), a
                ld      a, (ScanDblCtrl)
                inc     b       ; BC = zxuno_data
                out     (c), a
                ret

;------------------------------------------------------
; Subroutine
; In: HL = pointer to string buffer, (CORE_ID_STR_LEN + 1) bytes long

ZXUno_ReadCoreID
                lda     core_id
                ld      bc, zxuno_port
                out     (c), a
                inc     b       ; BC = zxuno_data
                ld      d, CORE_ID_STR_LEN
.Loop           in      a, (c)
                or      a
                jr      z, .End0
                cp      128
                jr      nc, .End
                ld      (hl), a
                inc     hl
                dec     d
                jr      nz, .Loop
.End            xor     a
.End0           ld      (hl), a
                ret

;------------------------------------------------------
; Subroutine

ZXUno_InitMouse
                lda     mouse_data
                ld      bc, zxuno_port
                out     (c), a
                lda     $f4
                inc     b       ; BC = zxuno_data
                out     (c), a
                ret

;------------------------------------------------------

;                        01234567890123456789012345678901
aUsage          db      PROGRAMUC, " v", VERSION, 13
                db      "Configure/print ZX-UNO options", 13
                db      13
                db      "Usage: ", PROGRAM, " [switches]", 13
                db      " No switches: print config", 13
                db      " -h : show this help and exit", 13
                db      " -q : silent operation", 13
                db      " -tN: choose ULA timings", 13
                db      "      N=48:   48K timings", 13
                db      "      N=128: 128K timings", 13
                db      "      N=pen: Pentagon timings", 13
                db      " -cS: en/dis contention", 13
                db      "      S=y: enable contention", 13
                db      "      S=n: disable contention", 13
                db      " -kN: choose keyboard mode", 13
                db      "      N=2: issue 2 keyboard", 13
                db      "      N=3: issue 3 keyboard", 13
                db      " -sN: choose CPU speed", 13
                db      "      N=0: std. speed (3.5 Mhz)", 13
                db      "      N=1, 2 or 3: turbo speed", 13
                db      "             (7, 14 or 28 MHz)", 13
                db      " -vN: choose video output", 13
                db      "      N=0: composite/RGB 15kHz", 13
                db      "      N=1: VGA no scanlines", 13
                db      "      N=2: VGA with scanlines", 13
                db      " -fN: choose master frequency", 13
                db      "      N=0-7: master freq option", 13
                db      13
                db      "Example: ", PROGRAM, " -tpen -cn -k3", 13
                db      "  (provides Pentagon 128 compati", 13
                db      "   ble mode)", 13
                db      0

;                        01234567890123456789012345678901
aCore           db      "ZX-Uno current configuration:", 13
                db      "       Core: "
aCoreID         dz      "NOT AVAILABLE"
                block   CORE_ID_STR_LEN + 1 - ($ - aCoreID), 0
aTiming         db      13
                dz      "     Timing: "
aTiming_48K     dz      "48K", 13
aTiming_128K    dz      "128K", 13
aTiming_Pentagon
                dz      "Pentagon", 13
aContention     dz      " Contention: "
aEnabled        dz      "ENABLED", 13
aDisabled       dz      "DISABLED", 13
aKeyboard       dz      "   Keyboard: ISSUE "
aMouse          dz      "      Mouse: INITIALIZED", 13
aSpeed          dz      "      Speed: "
aSpeed_0        dz      "3.5 MHz", 13
aSpeed_1        dz      "7 MHz", 13
aSpeed_2        dz      "14 MHz", 13
aSpeed_3        dz      "28 MHz", 13
aVideo          dz      "      Video: "
aVideo_Composite
                dz      "CVBS/RGB 15 kHz", 13
aVideo_VGANoScans
                dz      "VGA", 13
aVideo_VGAScans dz      "VGA w/scanlines", 13
aVFreq          dz      "  VFreq opt: "
aVFreq_0        dz      "50 Hz (0)", 13
aVFreq_1        dz      "51 Hz (1)", 13
aVFreq_2        dz      "53.50 Hz (2)", 13
aVFreq_3        dz      "55.80 Hz (3)", 13
aVFreq_4        dz      "57.39 Hz (4)", 13
aVFreq_5        dz      "59.52 Hz (5)", 13
aVFreq_6        dz      "61.80 Hz (6)", 13
aVFreq_7        dz      "63.77 Hz (7)", 13
tabVFreqStr     dw      aVFreq_0, aVFreq_1, aVFreq_2, aVFreq_3, aVFreq_4, aVFreq_5, aVFreq_6, aVFreq_7

aBadOption      db      "Bad option. Use: ", PROGRAM
                dc      " -h"

ConfValue       db      0       ; current config value
ScanDblCtrl     db      0
QuietMode       db      0

BufferParam     equ     $       ; rest of RAM for filename
