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


