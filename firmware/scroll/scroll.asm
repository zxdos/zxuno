
        output  scroll.bin
        org     $5ccb
        defb    0, 0, 0, 0
        defb    $de, $c0, $37, $0e, $8f, $39, $ac ;OVER USR 7 ($5cd6)

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
start1  ld      b, $08
start2  ld      a, (hl)
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
        include lineas.asm
        ld      sp, 0
        
        ex      af, af'
        rlca
        jr      c, nprn
        ex      af, af'

        ld      ix, string
        ld      bc, $0010
        call    prnstr
        ld      ix, string
        ld      bc, $0111
        call    prnstr
        ld      ix, string
        ld      bc, $0212
        call    prnstr
        ld      ix, string
        ld      bc, $0313
        call    prnstr
        ld      ix, string
        ld      bc, $0414
        call    prnstr
        ld      ix, string
        ld      bc, $0515
        call    prnstr
        ld      ix, string
        ld      bc, $0616
        call    prnstr
        ld      ix, string
        ld      bc, $0717
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


; -----------------------------------------------------------------------------
; Print string routine
; Parameters:
;  BC: X coord (B) and Y coord (C)
;  IX: null terminated string
; -----------------------------------------------------------------------------

prnstr  push    bc
        rr      b
        ld      a, b
        jr      c, prnimp
        and     %1111100
        ld      d, a
        xor     b
        ld      e, a
        jr      z, prnch1
        dec     e
prnch1  ld      a, d
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
        inc     c
        rr      b
        jr      c, pos26
        jr      nz, pos4
pos0    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      h, $2c
        call    simple
        dec     de
pos2    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      h, $32
        ld      bc, $04fc
        call    doble
pos4    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      h, $30
        ld      bc, $04f0
        call    doble
pos6    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      h, $2e
        call    simple
        jr      pos0
pos26   rr      b
        jr      c, pos6
        jr      pos2

posf    pop     bc
        inc     c
        ret

prnimp  and     %1111100
        ld      d, a
        xor     b
        cp      3
        adc     a, -1
        ld      e, a
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
        inc     c
        rr      b
        jr      c, pos37
        jr      nz, pos5
pos1    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      h, $2f
        ld      bc, $04e0
        call    doble
pos3    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      h, $2d
        call    simple
pos5    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      h, $33
        ld      bc, $0401
        call    doble
        dec     de
pos7    ld      a, (ix)
        inc     ix
        add     a, a
        jr      z, posf
        ld      h, $31
        ld      bc, $04f8
        call    doble
        jr      pos1
pos37   rr      b
        jr      c, pos7
        jr      pos3

simple  ld      b, 4
        ld      l, a
        add     hl, hl
        add     hl, hl
simple2 ld      a, (de)
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        ld      a, (de)
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        djnz    simple2
        ld      hl, $f801
        add     hl, de
        ex      de, hl
        ret

doble   ld      l, a
        add     hl, hl
        add     hl, hl
doble2  ld      a, (de)
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
        djnz    doble2
        ld      hl, $f801
        add     hl, de
        ex      de, hl
        ret

string  include string.asm
chr     incbin  fuente6x8.bin
chrend
