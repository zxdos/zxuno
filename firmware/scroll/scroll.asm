
        output  scroll.bin
        org     $5ccb
        defb    0, 0, 0, 0
        defb    $de, $c0, $37, $0e, $8f, $39, $ac ;OVER USR 7 ($5cd6)

      macro linea   src1, src2, src3, dst1, dst2, dst3
        ld      sp, $4005+$800*src1+$100*src3+$20*src2
        pop     hl
        pop     de
        pop     bc
        pop     af
        exx
        pop     hl
        pop     de
        pop     bc
        ld      sp, $4013+$800*dst1+$100*dst3+$20*dst2
        push    bc
        push    de
        push    hl
        exx
        push    af
        push    bc
        push    de
        push    hl
        ld      sp, $4013+$800*src1+$100*src3+$20*src2
        pop     hl
        pop     de
        pop     bc
        pop     af
        ld      sp, $401b+$800*dst1+$100*dst3+$20*dst2
        push    af
        push    bc
        push    de
        push    hl
      endm

bucle   ;ld      hl, 0
        ;ld      de, $4000
        ;ld      bc, $1800
        ;ldir
        ld      a, 1
        ex      af, af'


        ld      hl, chr
        ld      de, $b400-chrend+chr
        ld      bc, chrend-chr
        ldir
        ld      hl, $b000
;        ld      de, $b400
start1  ld      b, $04
start2  ld      a, (hl)
        rrca
        rrca
        ld      (de), a
        inc     de
        cpi
        jp      pe, start2
        jr      nc, start1


bucl2   halt
        di
        ld      c, 4
bucl3   djnz    bucl3
        dec     c
        jr      nz, bucl3
        linea   0, 0, 1,    0, 0, 0
        linea   0, 0, 2,    0, 0, 1
        linea   0, 0, 3,    0, 0, 2
        linea   0, 0, 4,    0, 0, 3
        linea   0, 0, 5,    0, 0, 4
        linea   0, 0, 6,    0, 0, 5
        linea   0, 0, 7,    0, 0, 6
        linea   0, 1, 0,    0, 0, 7
        linea   0, 1, 1,    0, 1, 0
        linea   0, 1, 2,    0, 1, 1
        linea   0, 1, 3,    0, 1, 2
        linea   0, 1, 4,    0, 1, 3
        linea   0, 1, 5,    0, 1, 4
        linea   0, 1, 6,    0, 1, 5
        linea   0, 1, 7,    0, 1, 6
        linea   0, 2, 0,    0, 1, 7
        linea   0, 2, 1,    0, 2, 0
        linea   0, 2, 2,    0, 2, 1
        linea   0, 2, 3,    0, 2, 2
        linea   0, 2, 4,    0, 2, 3
        linea   0, 2, 5,    0, 2, 4
        linea   0, 2, 6,    0, 2, 5
        linea   0, 2, 7,    0, 2, 6
        linea   0, 3, 0,    0, 2, 7
        linea   0, 3, 1,    0, 3, 0
        linea   0, 3, 2,    0, 3, 1
        linea   0, 3, 3,    0, 3, 2
        linea   0, 3, 4,    0, 3, 3
        linea   0, 3, 5,    0, 3, 4
        linea   0, 3, 6,    0, 3, 5
        linea   0, 3, 7,    0, 3, 6
        linea   0, 4, 0,    0, 3, 7
        linea   0, 4, 1,    0, 4, 0
        linea   0, 4, 2,    0, 4, 1
        linea   0, 4, 3,    0, 4, 2
        linea   0, 4, 4,    0, 4, 3
        linea   0, 4, 5,    0, 4, 4
        linea   0, 4, 6,    0, 4, 5
        linea   0, 4, 7,    0, 4, 6
        linea   0, 5, 0,    0, 4, 7
        linea   0, 5, 1,    0, 5, 0
        linea   0, 5, 2,    0, 5, 1
        linea   0, 5, 3,    0, 5, 2
        linea   0, 5, 4,    0, 5, 3
        linea   0, 5, 5,    0, 5, 4
        linea   0, 5, 6,    0, 5, 5
        linea   0, 5, 7,    0, 5, 6
        linea   0, 6, 0,    0, 5, 7
        linea   0, 6, 1,    0, 6, 0
        linea   0, 6, 2,    0, 6, 1
        linea   0, 6, 3,    0, 6, 2
        linea   0, 6, 4,    0, 6, 3
        linea   0, 6, 5,    0, 6, 4
        linea   0, 6, 6,    0, 6, 5
        linea   0, 6, 7,    0, 6, 6
        linea   0, 7, 0,    0, 6, 7
        linea   0, 7, 1,    0, 7, 0
        linea   0, 7, 2,    0, 7, 1
        linea   0, 7, 3,    0, 7, 2
        linea   0, 7, 4,    0, 7, 3
        linea   0, 7, 5,    0, 7, 4
        linea   0, 7, 6,    0, 7, 5
        linea   0, 7, 7,    0, 7, 6
        linea   1, 0, 0,    0, 7, 7
        linea   1, 0, 1,    1, 0, 0
        linea   1, 0, 2,    1, 0, 1
        linea   1, 0, 3,    1, 0, 2
        linea   1, 0, 4,    1, 0, 3
        linea   1, 0, 5,    1, 0, 4
        linea   1, 0, 6,    1, 0, 5
        linea   1, 0, 7,    1, 0, 6
        linea   1, 1, 0,    1, 0, 7
        linea   1, 1, 1,    1, 1, 0
        linea   1, 1, 2,    1, 1, 1
        linea   1, 1, 3,    1, 1, 2
        linea   1, 1, 4,    1, 1, 3
        linea   1, 1, 5,    1, 1, 4
        linea   1, 1, 6,    1, 1, 5
        linea   1, 1, 7,    1, 1, 6
        linea   1, 2, 0,    1, 1, 7
        linea   1, 2, 1,    1, 2, 0
        linea   1, 2, 2,    1, 2, 1
        linea   1, 2, 3,    1, 2, 2
        linea   1, 2, 4,    1, 2, 3
        linea   1, 2, 5,    1, 2, 4
        linea   1, 2, 6,    1, 2, 5
        linea   1, 2, 7,    1, 2, 6
        linea   1, 3, 0,    1, 2, 7
        linea   1, 3, 1,    1, 3, 0
        linea   1, 3, 2,    1, 3, 1
        linea   1, 3, 3,    1, 3, 2
        linea   1, 3, 4,    1, 3, 3
        linea   1, 3, 5,    1, 3, 4
        linea   1, 3, 6,    1, 3, 5
        linea   1, 3, 7,    1, 3, 6
        linea   1, 4, 0,    1, 3, 7
        linea   1, 4, 1,    1, 4, 0
        linea   1, 4, 2,    1, 4, 1
        linea   1, 4, 3,    1, 4, 2
        linea   1, 4, 4,    1, 4, 3
        linea   1, 4, 5,    1, 4, 4
        linea   1, 4, 6,    1, 4, 5
        linea   1, 4, 7,    1, 4, 6
        linea   1, 5, 0,    1, 4, 7
        linea   1, 5, 1,    1, 5, 0
        linea   1, 5, 2,    1, 5, 1
        linea   1, 5, 3,    1, 5, 2
        linea   1, 5, 4,    1, 5, 3
        linea   1, 5, 5,    1, 5, 4
        linea   1, 5, 6,    1, 5, 5
        linea   1, 5, 7,    1, 5, 6
        linea   1, 6, 0,    1, 5, 7
        linea   1, 6, 1,    1, 6, 0
        linea   1, 6, 2,    1, 6, 1
        linea   1, 6, 3,    1, 6, 2
        linea   1, 6, 4,    1, 6, 3
        linea   1, 6, 5,    1, 6, 4
        linea   1, 6, 6,    1, 6, 5
        linea   1, 6, 7,    1, 6, 6
        linea   1, 7, 0,    1, 6, 7
        linea   1, 7, 1,    1, 7, 0
        linea   1, 7, 2,    1, 7, 1
        linea   1, 7, 3,    1, 7, 2
        linea   1, 7, 4,    1, 7, 3
        linea   1, 7, 5,    1, 7, 4
        linea   1, 7, 6,    1, 7, 5
        linea   1, 7, 7,    1, 7, 6
        linea   2, 0, 0,    1, 7, 7
        linea   2, 0, 1,    2, 0, 0
        linea   2, 0, 2,    2, 0, 1
        linea   2, 0, 3,    2, 0, 2
        linea   2, 0, 4,    2, 0, 3
        linea   2, 0, 5,    2, 0, 4
        linea   2, 0, 6,    2, 0, 5
        linea   2, 0, 7,    2, 0, 6
        linea   2, 1, 0,    2, 0, 7
        linea   2, 1, 1,    2, 1, 0
        linea   2, 1, 2,    2, 1, 1
        linea   2, 1, 3,    2, 1, 2
        linea   2, 1, 4,    2, 1, 3
        linea   2, 1, 5,    2, 1, 4
        linea   2, 1, 6,    2, 1, 5
        linea   2, 1, 7,    2, 1, 6
        linea   2, 2, 0,    2, 1, 7
        linea   2, 2, 1,    2, 2, 0
        linea   2, 2, 2,    2, 2, 1
        linea   2, 2, 3,    2, 2, 2
        linea   2, 2, 4,    2, 2, 3
        linea   2, 2, 5,    2, 2, 4
        linea   2, 2, 6,    2, 2, 5
        linea   2, 2, 7,    2, 2, 6
        linea   2, 3, 0,    2, 2, 7
        linea   2, 3, 1,    2, 3, 0
        linea   2, 3, 2,    2, 3, 1
        linea   2, 3, 3,    2, 3, 2
        linea   2, 3, 4,    2, 3, 3
        linea   2, 3, 5,    2, 3, 4
        linea   2, 3, 6,    2, 3, 5
        linea   2, 3, 7,    2, 3, 6
        linea   2, 4, 0,    2, 3, 7
        linea   2, 4, 1,    2, 4, 0
        linea   2, 4, 2,    2, 4, 1
        linea   2, 4, 3,    2, 4, 2
        linea   2, 4, 4,    2, 4, 3
        linea   2, 4, 5,    2, 4, 4
        linea   2, 4, 6,    2, 4, 5
        linea   2, 4, 7,    2, 4, 6
        linea   2, 5, 0,    2, 4, 7
        linea   2, 5, 1,    2, 5, 0
        linea   2, 5, 2,    2, 5, 1
        linea   2, 5, 3,    2, 5, 2
        linea   2, 5, 4,    2, 5, 3
        linea   2, 5, 5,    2, 5, 4
        linea   2, 5, 6,    2, 5, 5
        linea   2, 5, 7,    2, 5, 6
        linea   2, 6, 0,    2, 5, 7
        linea   2, 6, 1,    2, 6, 0
        linea   2, 6, 2,    2, 6, 1
        linea   2, 6, 3,    2, 6, 2
        linea   2, 6, 4,    2, 6, 3
        linea   2, 6, 5,    2, 6, 4
        linea   2, 6, 6,    2, 6, 5
        linea   2, 6, 7,    2, 6, 6
        linea   2, 7, 0,    2, 6, 7
        linea   2, 7, 1,    2, 7, 0
        linea   2, 7, 2,    2, 7, 1
        linea   2, 7, 3,    2, 7, 2
        linea   2, 7, 4,    2, 7, 3
        linea   2, 7, 5,    2, 7, 4
        linea   2, 7, 6,    2, 7, 5
        linea   2, 7, 7,    2, 7, 6
        ld      sp, 0
        
        ex      af, af'
        rlca
        jr      c, nprn
        ex      af, af'

;        ld      hl, 
        ld      ix, string
        ld      bc, $0014
        call    prnstr
        ld      ix, string
        ld      bc, $8015
        call    prnstr
        ld      ix, string
        ld      bc, $0116
        call    prnstr
        ld      ix, string
        ld      bc, $8117
        call    prnstr
 jr $
        ex      af, af'

nprn    ex      af, af'
        ei
        halt
        halt
        jp      bucl2

; 01234567 01234567 01234567 01234567
; abcdef
;       ab cdef
;              abcd ef
;                     abcdef          0642
;    abcde f
;           abcdef
;                 a bcdef
;                        abc def      3175

        block   256 - ($ & $ff)

prntab  defb    pos0 & $ff
        defb    pos1 & $ff
        defb    pos2 & $ff
        defb    pos3 & $ff

; -----------------------------------------------------------------------------
; Print string routine
; Parameters:
;  BC: X coord (B) and Y coord (C)
;  IX: null terminated string
; -----------------------------------------------------------------------------

prnstr  push    bc
        ld      a, b
        and     %11111100
        ld      d, a
        res     7, d
        xor     b
        ld      e, a
        jr      z, prnch1
        dec     e
prnch1  rl      b
        jr      nc, prnch2
        add     a, 3
prnch2  and     %00000011
        ld      l, a
        ld      h, prnstr>>8
        ld      l, (hl)
        push    hl
        ld      a, d
        rrca
        ld      d, a
        rrca
        add     a, d
        add     a, e
        ld      e, a
        ld      a, c
        and     %00011000
        or      %01000000
        ld      d, a
        ld      a, c
        and     %00000111
        rrca
        rrca
        rrca
        add     a, e
        ld      e, a
        defb    $3e             ; salta la siguiente instruccion
posf    pop     bc
        inc     c
        ret

pos0    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      l, a
        ld      h, $2c
        add     hl, hl
        add     hl, hl
        ld      b, 4
pos00   ld      a, (hl)
        ld      (de), a
        inc     l
        inc     d
        ld      a, (hl)
        ld      (de), a
        inc     l
        inc     d
        djnz    pos00
        ld      hl, $f800
        add     hl, de
        ex      de, hl
pos1    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      l, a
        ld      h, $2f
        add     hl, hl
        add     hl, hl
        ld      bc, $04fc
pos10   ld      a, (de)
        xor     (hl)
        and     c
        xor     (hl)
        ld      (de), a
        inc     e
        ld      a, (hl)
        and     c
        ld      (de), a
        inc     d
        inc     l
        ld      a, (hl)
        and     c
        ld      (de), a
        dec     e
        ld      a, (de)
        xor     (hl)
        and     c
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        djnz    pos10
        ld      hl, $f801
        add     hl, de
        ex      de, hl
pos2    ld      a, (ix)
        inc     ix
        add     a, a
tposf   jr      z, posf
        ld      l, a
        ld      h, $2e
        add     hl, hl
        add     hl, hl
        ld      bc, $04f0
pos20   ld      a, (de)
        xor     (hl)
        and     c
        xor     (hl)
        ld      (de), a
        inc     e
        ld      a, (hl)
        and     c
        ld      (de), a
        inc     d
        inc     l
        ld      a, (hl)
        and     c
        ld      (de), a
        dec     e
        ld      a, (de)
        xor     (hl)
        and     c
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        djnz    pos20
        ld      hl, $f801
        add     hl, de
        ex      de, hl
pos3    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, tposf
        ld      l, a
        ld      h, $2d
        add     hl, hl
        add     hl, hl
        ld      b, 4
pos30   ld      a, (de)
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        ld      a, (de)
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        djnz    pos30
        ld      hl, $f801
        add     hl, de
        ex      de, hl
        jp      pos0


string  include string.asm
chr     incbin  fuente6x8.bin
chrend
