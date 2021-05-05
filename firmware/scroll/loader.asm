; SPDX-FileCopyrightText: Copyright (C) 2016, 2017, 2020, 2021 Antonio Villena
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

        include define.asm
        output  loader.bin
        org     $5ccb
        ld      de, $8000
        di
        defb    $de, $c0, $37, $0e, $8f, $39, $96 ; Basic de Paolo Ferraris
        ld      hl, finload-1
        ld      de, $baff
        call    dzx7b
        inc     hl
        inc     hl
        ld      bc, $4000       ; filtro RCS inverso (jamorski)
        ld      a, b
init    xor     c
        and     $f8
        xor     c
        ld      d, a
        xor     b
        xor     c
        rlca
        rlca
        ld      e, a
init2   inc     bc
        ldi
        inc     bc
        ld      a, b
        cp      $58
        jr      c, init
        sub     $5b
        jr      nz, init2
        ld      hl, $5e6d-2
        ld      de, compsize
        call    $07f4
        di
        ld      de, $5e6d+rawsize-1
        ld      hl, $5e6d-2+compsize-1
        call    dzx7b
        jp      $7be4

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
getbit  ld      a, (hl)
        dec     hl
        adc     a, a
        ret

loadscr incbin  loadscr.rcs.zx7b
finload
