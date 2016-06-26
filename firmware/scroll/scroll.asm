
        output  scroll.bin
        org     $5d27
        ld      hl, fondo
        ld      b, $40          ; filtro RCS inverso
start   ld      a, b
        xor     c
        and     $f8
        xor     c
        ld      d, a
        xor     b
        xor     c
        rlca
        rlca
        ld      e, a
        inc     bc
        ldi
        inc     bc
        ld      a, b
        sub     $58
        jr      nz, start
        ld      b, 3
        ldir
        out     ($fe), a
        inc     a
        ex      af, af'
        ld      hl, chr
        push    hl
        pop     ix
        ld      de, $b400-fondo+chr
        ld      bc, fondo-chr
        ldir
        ld      hl, $b000
start1  ld      b, $08
start2  ld      a, (hl)
        rrca
        ld      (de), a
        inc     de
        cpi
        jp      pe, start2
        jr      nc, start1

start3  ei
        halt
        di
        ld      c, 4
start4  djnz    start4
        dec     c
        jr      nz, start4
        include lineas.asm
        ld      sp, $401b+$800*2+$100*7+$20*7
        sbc     hl, hl
        push    hl
        push    hl
        push    hl
        push    hl
        push    hl
        push    hl
        push    hl
        push    hl
        push    hl
        push    hl
        push    hl
        ld      sp, hl
        ld      hl, start3
        push    hl
        ex      af, af'
        rrca
        jr      c, start5
        ex      af, af'
        ret
start5  ex      af, af'
        xor     a
        cp      (ix)
        jr      nz, start6
        ld      ix, string
start6  push    ix
        pop     hl
        ld      c, $2b
        cpir
        ld      b, c
        ld      c, $17

        push    bc
        srl     b
        ld      a, b
        jr      c, prn2
        and     %11111100
        ld      d, a
        xor     b
        ld      b, a
        ld      e, a
        jr      z, prn1
        dec     e
prn1    ld      a, d
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
        inc     de
        jr      pos0
pos26   rr      b
        jr      c, pos6
        jr      pos2

posf    pop     bc
        inc     c
        ret

prn2    and     %11111100
        ld      d, a
        xor     b
        ld      b, a
        cp      2
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
        ld      bc, $04fe
        call    doble
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
        ld      hl, $f800
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
fondo   incbin  fondo.rcs
fin