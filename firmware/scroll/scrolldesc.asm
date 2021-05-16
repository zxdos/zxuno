; scrolldesc.asm
;
; SPDX-FileCopyrightText: Copyright (C) 2016, 2017, 2020, 2021 Antonio Villena
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

        include define.asm
        output  scrolldesc.bin
        org     $5ccb
        ld      de, filestart+filesize-1
        di
        defb    $de, $c0, $37, $0e, $8f, $39, $96
        jr      aqui
getbit  ld      a, (hl)
        dec     hl
        adc     a, a
        ret
aqui    ld      hl, fin-1

; -----------------------------------------------------------------------------
; ZX7 Backwards by Einar Saukas, Antonio Villena
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------
dzx7b   ld      bc, $8000
        ld      a, b
copyby  inc     c
        ldd
mainlo  add     a, a
        call    z, getbit
        jr      nc, copyby
        push    de
        ld      d, c
        defb    $30
lenval  add     a, a
        call    z, getbit
        rl      c
        rl      b
        add     a, a
        call    z, getbit
        jr      nc, lenval
        inc     c
        jr      z, exitdz
        ld      e, (hl)
        dec     hl
        sll     e
        jr      nc, offend
        ld      d, $10
nexbit  add     a, a
        call    z, getbit
        rl      d
        jr      nc, nexbit
        inc     d
        srl     d
offend  rr      e
        ex      (sp), hl
        ex      de, hl
        adc     hl, de
        lddr
exitdz  pop     hl
        jr      nc, mainlo
        jp      start
        incbin  scroll.bin.zx7b
fin
