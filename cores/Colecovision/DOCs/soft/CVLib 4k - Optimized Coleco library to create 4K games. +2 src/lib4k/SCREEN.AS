                psect   text

                global  _screen_off
                ; screen_off (void)
_screen_off:    ld      a,(73c4h)
                and     0bfh
                ld      c,a
                ld      b,1
                jp      1fd9h

                global  _screen_on
                ; screen_on (void)
_screen_on:     ld      a,(73c4h)
                or      40h
                ld      c,a
                ld      b,1
                jp      1fd9h
