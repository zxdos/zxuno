                psect   text

                global  _memcpyb
                ; void memcpyb (void *dest,void *src,int n);
_memcpyb:       pop     bc
                exx
                pop     de
                pop     hl
                pop     bc
                push    bc
                push    hl
                push    de
                exx
                push    bc
                exx
                ldir
                ret
