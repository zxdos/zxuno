                psect   text

                global  _put_vram
                ; put_vram (offset,ptr,count)
_put_vram:      exx
                pop     hl
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
                ; - Patch to fix a curious bug -
                ld      a,c
                or	a
                jp	z,1fdfh
                inc	b
                ; - End Patch -
                jp	1fdfh

