;n26a6
waitm   push    bc
        ld      b, 10
n26a9   call    waitr
        cp      $fe
        jr      z, n26b6
        cp      $ff
        jr      nz, n26b6
        djnz    n26a9
n26b6   pop     bc
        ret

readat0 ld      e, 0
;n26b8
readata push    hl
        push    bc
        call    waittok
        call    cslow
        ld      bc, READ_SINGLE<<8 | SPI_PORT
        out     (c), b
        ld      a, (sdhc)
        or      a
        jr      nz, mul2
        out     (c), 0
        out     (c), e
        out     (c), h
        out     (c), l
        jr      mul3
mul2    ld      a, e
        add     hl, hl
        adc     a, a
        out     (c), a
        out     (c), h
        out     (c), l
        out     (c), 0
mul3    out     (c), 0
        call    waitr
        and     a
        jr      nz, n26bd
        scf
n26bd   ld      a, 0
        jr      nc, twait
        call    waitm
        cp      $fe
        jr      z, n26ca
        and     a
        jr      n26bd
n26ca   push    ix
        pop     hl
        ld      bc, SPI_PORT
        inir
        nop
        inir
        pop     bc
        pop     hl
n26d7   in      a, (SPI_PORT)
        nop
        nop
        in      a, (SPI_PORT)
        scf
        jr      waittok
twait   pop     bc
        pop     hl
;n2620
waittok call    cshigh
        push    af
        push    bc
        ld      b, 10
n2625   in      a, (SPI_PORT)
        djnz    n2625
        pop     bc
        pop     af
        ret

;n2628
send0   ld      h, 0
;n262a
send1   ld      l, 0
        ld      d, l
        ld      e, l
;n2630
sendc   push    bc
        ld      b, $ff
        jr      n2638
;n2637
send    push    bc
n2638   ld      c, a
        call    waittok
        call    cslow
        ld      a, c
        out     (SPI_PORT), a
        ld      a, h
        nop
        out     (SPI_PORT), a
        ld      a, l
        nop
        out     (SPI_PORT), a
        ld      a, d
        nop
        out     (SPI_PORT), a
        ld      a, e
        nop
        out     (SPI_PORT), a
        ld      a, b
        nop
        out     (SPI_PORT), a
        call    waitr
        pop     bc
        and     a
        ret     nz
        scf
        ret

;n266d
;readcsd push    bc
;        push    de
;        push    hl
;        push    af
;        call    mmcinit
;        pop     af
;        push    de
;        ld      a, $49    ;CMD9
;        call    send0
;        pop     de
;        pop     hl
;        jr      nc, n2692
;        call    waitm
;        cp      $fe
;        jr      z, n2689
;        and     a
;        jr      n2692
;n2689   ld      b, $12
;        ld      c, SPI_PORT
;n268d   ini
;        jr      nz, n268d
;        scf
;        ld      a, d
;n2692   pop     de
;        pop     bc
;        jr      waittok

;n2695
waitr   push    bc
        ld      bc, 50
n2699   in      a, (SPI_PORT)
        cp      $ff
        jr      nz, n26a4
        djnz    n2699
        dec     c
        jr      nz, n2699
n26a4   pop     bc
        ret

cshigh  push    af
        ld      a, $ff
        jr      n261d
cslow   push    af
        ld      a, $fe
n261d   out     (OUT_PORT), a
        in      a, (SPI_PORT)
        pop     af
        ret

;n278c
mmcinit push    bc
        push    af
;       xor     a
;       ld      (sdhc), a
        call    waittok
        ld      a, $40    ;CMD0
        ld      hl, 0
        ld      d, h
        ld      e, l
        ld      b, $95    ;CRC
        call    send
        dec     a
        jr      nz, n27c0
        ld      bc, $0078
n27a8   pop     af
        push    af
        push    bc
        ld      a, $48    ;CMD8
        ld      hl, 0
        ld      de, $01aa
        ld      b, $87    ;CRC
n27ad   call    send
        pop     bc
        bit     2, a
        ld      h, 0
        jr      nz, n27b8
        dec     a
        jr      nz, n27c2
        in      a, (SPI_PORT)
        ld      h, a
        nop
        in      a, (SPI_PORT)
        ld      l, a
        nop
        in      a, (SPI_PORT)
        and     $0f
        ld      d, a
        in      a, (SPI_PORT)
        cp      e
        jr      nz, n27c2
        dec     d
        jr      nz, n27de
        ld      h, $40    ;SDv2
n27b8   pop     af
        push    af
        push    hl
        ld      a, $77    ;CMD55
        call    send0
        pop     hl
        pop     af
        push    af
        push    hl
        ld      a, $69    ;CMD41
        call    send1
        pop     hl
        bit     2, a
        jr      nz, n27c8
        jr      c, n27d0
        dec     a
        jr      z, n27b8
n27c0   jr      n27de
n27c2   djnz    n27a8 
        dec     c
        jr      nz, n27a8
        jr      n27de
n27c8   pop     af
        push    af
        ld      a, $41    ;CMD1
n27ce   call    send0
        jr      c, n27d1
        djnz    n27c8
        dec     c
        jr      nz, n27c8
        jr      n27de
n27d0   pop     af
        push    af
        call    readocr
        jr      nc, n27de
        ld      d, a
        jr      z, n27db
n27d1   pop     af
        push    af
        ld      a, $50    ;SET_BLOCKLEN
        ld      de, $0200
        ld      h, e
        ld      l, e
        call    sendc
        jr      nc, n27de
n27d9   ld      a, 1      ;/sdhc
n27db   ld      (sdhc), a
        scf
        jr      n27df
n27de   and     a
n27df   pop     bc
        pop     bc
        jp      waittok

;n27e4
readocr ld      a, $7a    ;CMD58
        call    send0
        ret     nc
        ld      d, $c0
        in      a, (SPI_PORT)
        and     d
        ld      h, a
        in      a, (SPI_PORT)
        ld      l, a
        nop
        in      a, (SPI_PORT)
        ld      e, a
        nop
        in      a, (SPI_PORT)
        ld      a, h
        sub     d
        scf
        ret
