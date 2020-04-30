                psect   text

                global  _rle2vram
                ; void *rle2vram (void *rledata,unsigned offset);
_rle2vram:      pop     bc
                pop     hl
                pop     de
                push    de
                push    hl
                push    bc
                di
;                ld      a,(1d43h)
                ld      c,0bfh
                out     (c),e
                set     6,d
                out     (c),d
                ei
;                ld      a,(1d47h)
                ld      c,0beh
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
1:              out     (c),a
                nop
                nop
                djnz    1b
                jr      0b
2:              inc     a
                ld      b,a
3:              outi
                jr      z,0b
                jp      3b

