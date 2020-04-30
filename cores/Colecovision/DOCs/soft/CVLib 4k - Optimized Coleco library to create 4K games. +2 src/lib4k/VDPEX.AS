                psect   text

                global  _put_vram_ex
                ; put_vram_ex (offset,ptr,count,byte and,byte xor)
_put_vram_ex:   pop     hl
                exx
                pop     de
                di
                ld      c,0bfh
                out     (c),e
                set     6,d
                out     (c),d
                ei
                pop     hl
                pop     bc
                pop     de
                ld      a,e
                pop     de
                ld      d,a
                push    de
                push    de
                push    bc
                push    hl
                push    de
                exx
                push    hl
                exx
1:              push    bc
                ld      b,c
                ld      c,0beh
2:              ld      a,(hl)
                inc     hl
                and     d
                xor     e
                out     (c),a
                djnz    2b
                pop     bc
                ld      c,0
                dec     b
                ret     z
                jp      p,1b
                ret
