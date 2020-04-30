                psect   text

                global  _get_random
                ; byte get_random (void);
_get_random:    call    1ffdh
               ; ld      hl,(73c8h)
                ld      a,r
                xor     l
                ld      l,a
                ret
