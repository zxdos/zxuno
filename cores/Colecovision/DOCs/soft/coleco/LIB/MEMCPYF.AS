                psect   text

                global  _memcpyf
                ; void memcpyf (void *dest,void *src,int n);
_memcpyf:       pop     bc
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
                add     hl,bc
                dec     hl
                ex      de,hl
                add     hl,bc
                dec     hl
                ex      de,hl
                lddr
                ret
