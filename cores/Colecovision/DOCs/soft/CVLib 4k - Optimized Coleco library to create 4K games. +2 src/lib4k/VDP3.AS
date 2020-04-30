                psect   text

                global  _get_vram
                ; get_vram (offset,ptr,count)
_get_vram:      exx
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
                jp	z,1fe2h
                inc	b
                ; - End Patch -
                jp	1fe2h

