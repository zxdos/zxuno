                psect   text

                global  _disable_nmi
                ; disable_nmi (void)
_disable_nmi:   ld      a,(73c4h)
                and     0dfh
                ld      c,a
                ld      b,1
                jp      1fd9h

                global  _enable_nmi
                ; enable_nmi (void)
_enable_nmi:    ld      a,(73c4h)
                or      020h
                ld      c,a
                ld      b,1
                call    1fd9h
                jp      1fdch
