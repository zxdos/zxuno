                psect   text

                global  _memset
                ; void *memset (void *p,int c,int n);
                ; in the library version, c and n are reversed
_memset:        pop     hl
                exx
                pop     hl
                pop     de
                pop     bc
                push    bc
                push    de
                push    hl
                exx
                push    hl
                exx
                push    hl
1:              ld      a,b
                or      c
                jr      z,2f
                ld      (hl),e
                inc     hl
                dec     bc
                jr      1b
2:              pop     hl
                ret
