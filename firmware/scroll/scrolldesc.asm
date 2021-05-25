; scrolldesc.asm - loader of packed "scroll" demo.
;
; SPDX-FileCopyrightText: Copyright (C) 2016, 2017, 2020, 2021 Antonio Villena
;
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

;       output  scrolldesc.bin

        include define.asm
        include dzx7b.mac

        org     $5ccb

        ld      de, filestart+filesize-1
        di
        defb    $de, $c0, $37, $0e, $8f, $39, $96

        ld      hl, scroll_end-1

dzx7b   dzx7b_body getbit

        jp      start

getbit  dzx7b_getbit

        incbin  scroll.bin.zx7b
scroll_end
