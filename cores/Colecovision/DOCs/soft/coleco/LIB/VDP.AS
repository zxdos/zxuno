                psect   text

                global  _vdp_out
                ; vdp_out (reg,val)
_vdp_out:       pop     hl
                pop     de
                pop     bc
                push    bc
                push    de
                push    hl
                ld      b,e
                jp      1fd9h

                global  _fill_vram
                ; fill_vram (offset,value,count)
_fill_vram:     pop     hl
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

                global  _put_vram
                ; put_vram (offset,ptr,count)
_put_vram:      pop     hl
                exx
                pop     de
                pop     hl
                pop     bc
                push    bc
                push    hl
                push    de
                exx
                push    hl
                exx
                ld      a,c
                jp      1fdfh

                global  _get_vram
                ; get_vram (offset,ptr,count)
_get_vram:      pop     hl
                exx
                pop     de
                pop     hl
                pop     bc
                push    bc
                push    hl
                push    de
                exx
                push    hl
                exx
                ld      a,c
                jp      1fe2h

