                psect   text

                global  _play_sound
                ; play_sound (byte sound_number);
_play_sound:    pop     bc
                pop     de
                push    de
                push    bc
                push    ix
                push    iy

                ld      b,e
                call	1ff1h

                pop     iy
                pop     ix
                ret

