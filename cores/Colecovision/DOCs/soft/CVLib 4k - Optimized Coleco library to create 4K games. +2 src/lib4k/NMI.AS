                psect   text

                global  _disable_nmi
                ; disable_nmi (void)
_disable_nmi:   ld      a,(73c4h)
                and     0dfh
1:              ld      c,a
                ld      b,1
                jp      1fd9h

                global  _enable_nmi
                ; enable_nmi (void)
_enable_nmi:    ld      a,(73c4h)
                or      020h
                call    1b
                jp      1fdch

