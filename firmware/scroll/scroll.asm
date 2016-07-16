        output  scroll.bin
        org     $5e6d
  display $6d35+string-music
string  include string.asm
music   ld      (vari+2), ix
        incbin  music.bin
fuente  incbin  fuente6x8.bin
start   ld      hl, $c000
        ld      de, $c001
        ld      bc, $017f
        ld      (hl), l
        ldir
        ld      hl, fuente
        ld      b, 3
        ldir
        ld      hl, fondo
        ld      b, $40          ; filtro RCS inverso
start0  ld      a, b
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
        jr      nz, start0
        ld      b, 3
        ldir
        out     ($fe), a
        inc     a
        ex      af, af'
;        ld      de, $401f
;rever   ld      hl, $ffe1
;        add     hl, de
;        ld      c, (hl)
;        ld      a, $80
;revl1   rl      c
;        rra
;        jr      nc, revl1
;        ld      (de), a
;        inc     hl
;        dec     de
;        ld      c, (hl)
;        ld      a, $80
;revl2   rl      c
;        rra
;        jr      nc, revl2
;        ld      (de), a
;        inc     hl
;        dec     de
;        ld      c, (hl)
;        ld      a, $80
;revl3   rl      c
;        rra
;        jr      nc, revl3
;        ld      (de), a
;        inc     hl
;        dec     de
;        ld      c, (hl)
;        ld      a, $80
;revl4   rl      c
;        rra
;        jr      nc, revl4
;        ld      (de), a
;        ld      hl, $23
;        add     hl, de
;        ex      de, hl
;        ld      a, d
;        cp      $58
;        jr      nz, rever

        ld      hl, $c000
        ld      de, $c400
start1  ld      b, $08
start2  ld      a, (hl)
        rrca
        ld      (de), a
        inc     de
        cpi
        jp      pe, start2
        jr      nc, start1
        ld      a, $c9
        ld      ($c006), a
        ld      hl, $716f
        call    music+7
start3  call    $6e77
        ei
        halt
        di
        ld      bc, 5
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
vari    ld      ix, string
        ld      hl, start3
        push    hl
        ld      hl, music
        push    hl
        ex      af, af'
        rrca
        jr      c, start5
        ex      af, af'
        ret
start5  ex      af, af'
        linea   3, 1, 0,    3, 0, 0
        linea   3, 2, 0,    3, 1, 0
        linea   3, 3, 0,    3, 2, 0
        linea   3, 4, 0,    3, 3, 0
        linea   3, 5, 0,    3, 4, 0
        linea   3, 6, 0,    3, 5, 0
        linea   3, 7, 0,    3, 6, 0
        linea   3, 0, 1,    3, 7, 0
        linea   3, 1, 1,    3, 0, 1
        linea   3, 2, 1,    3, 1, 1
        linea   3, 3, 1,    3, 2, 1
        linea   3, 4, 1,    3, 3, 1
        linea   3, 5, 1,    3, 4, 1
        linea   3, 6, 1,    3, 5, 1
        linea   3, 7, 1,    3, 6, 1
        linea   3, 0, 2,    3, 7, 1
        linea   3, 1, 2,    3, 0, 2
        linea   3, 2, 2,    3, 1, 2
        linea   3, 3, 2,    3, 2, 2
        linea   3, 4, 2,    3, 3, 2
        linea   3, 5, 2,    3, 4, 2
        linea   3, 6, 2,    3, 5, 2
        ld      sp, $fffc
        ld      b, (ix)
        djnz    start6
        ld      ix, string
start6  inc     ix
        ld      hl, $5ac5
        ld      (hl), b
        ld      de, $5ac6
        ld      bc, 21
        ldir
        xor     a
        push    ix
        pop     hl
        ld      bc, $172b
        cpir
        srl     c
        ld      a, c
        jr      c, prn2
        and     %11111100
        ld      d, a
        xor     c
        ld      c, a
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
        ld      a, b
        and     %00011000
        or      %01000000
        ld      d, a
        ld      a, b
        and     %00000111
        rrca
        rrca
        rrca
        add     a, e
        ld      e, a
        rr      c
        jr      c, pos26
        jr      nz, pos4
pos0    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $c0 >> 2
        call    simple
pos2    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $d8 >> 2
        ld      bc, $04fc
        call    doble
pos4    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $d0 >> 2
        ld      bc, $04f0
        call    doble
pos6    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $c8 >> 2
        call    simple
        inc     de
        jr      pos0
pos26   rr      c
        jr      c, pos6
        jr      pos2
prn2    and     %11111100
        ld      d, a
        xor     c
        ld      c, a
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
        ld      a, b
        and     %00011000
        or      %01000000
        ld      d, a
        ld      a, b
        and     %00000111
        rrca
        rrca
        rrca
        add     a, e
        ld      e, a
        rr      c
        jr      c, pos37
        jr      nz, pos5
pos1    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $cc >> 2
        ld      bc, $04e0
        call    doble
pos3    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $c4 >> 2
        call    simple
pos5    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $dc >> 2
        ld      bc, $04fe
        call    doble
pos7    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $d4 >> 2
        ld      bc, $04f8
        call    doble
        jr      pos1
pos37   rr      c
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
fondo   incbin  fondo.rcs
