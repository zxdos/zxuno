; b1 [f0..87] nolit= 148 bytes
        ld      iy, 23408
        ld      a, 128
        ld      b, 52
        push    de
        cp      a
exinit: ld      c, 16
        jr      nz, exget4
        ld      de, 1
        ld      ixl, c
exget4: add     a, a
        call    z, exgetb
        rl      c
        jr      nc, exget4
        ld      (iy-112), c
        push    hl
        ld      hl, 1
        defb    210
exsetb: add     hl, hl
        dec     c
        jr      nz, exsetb
        ld      (iy-60), e
        ld      (iy-8), d
        add     hl, de
        ex      de, hl
        inc     iyl
        pop     hl
        dec     ixl
        djnz    exinit
        pop     de
exlit:  ldd
exloop: add     a, a
        call    z, exgetb
        jr      c, exlit
        ld      c, 111
exgeti: add     a, a
        call    z, exgetb
exgbic: inc     c
        jr      c, exgeti
        ret     m
        push    de
        ld      iyl, c
        call    expair
        push    de
        ld      bc, 672
        dec     e
        jr      z, exgoit
        dec     e
        ld      bc, 1168
        jr      z, exgoit
        ld      c, 128
exgoit: call    exgbts
        ld      iyl, c
        add     iy, de
        call    expair
        pop     bc
        ex      (sp), hl
        ex      de, hl
        add     hl, de
        lddr
        pop     hl
        jr      exloop
expair: ld      b, (iy-112)
        call    exgbts
        ex      de, hl
        ld      c, (iy-60)
        ld      b, (iy-8)
        add     hl, bc
        ex      de, hl
        ret
exgbts: ld      de, 0
excont: dec     b
        ret     m
        add     a, a
        call    z, exgetb
        rl      e
        rl      d
        jr      excont
exgetb: ld      a, (hl)
        dec     hl
        adc     a, a
        ret
