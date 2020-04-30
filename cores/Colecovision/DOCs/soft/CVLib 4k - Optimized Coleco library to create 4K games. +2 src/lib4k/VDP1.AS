                psect   text

                global  _fill_vram
                ; fill_vram (offset,value,count)
_fill_vram:     exx
                pop     hl
                exx
                pop     hl
                pop     bc
                pop     de
                push    de
                push    bc
                push    hl
                exx
                push    hl
                exx
                ld      a,c
                jp      1f82h

