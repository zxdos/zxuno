                psect   text

                global  _rle2ram
                ; void *rle2ram (void *rledata,void *ptr)
_rle2ram:       pop     bc
                pop     hl
                pop     de
                push    de
                push    hl
                push    bc
0:              ld      a,(hl)
                inc     hl
                cp      0ffh
                ret     z
                bit     7,a
                jr      z,2f
                and     127
                inc     a
                ld      b,a
                ld      a,(hl)
                inc     hl
1:              ld      (de),a
                inc     de
                djnz    1b
                jr      0b
2:              inc     a
                ld      b,a
                ldir
                jr      0b
