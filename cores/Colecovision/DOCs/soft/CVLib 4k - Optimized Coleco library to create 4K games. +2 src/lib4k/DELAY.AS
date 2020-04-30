                psect   bss
                global  _nmi_flag

                psect   text

                global  _delay
                ; delay (unsigned intcount)
_delay:         pop     hl
                pop     de
                push    de
                push    hl
                ld      a,(73c4h)       ; check if NMI enabled
                and     020h
                jr      z,3f
1:              ld      a,e             ; NMI enabled, check _nmi_flag
                or      d
                ret     z
                xor     a
                ld      (_nmi_flag),a
2:              ld      a,(_nmi_flag)
                or      a
                jr      z,2b
                dec     de
                jr      1b
3:              call    1fdch           ; NMI disabled, check VDP status
4:              ld      a,e
                or      d
                ret     z
5:              call    1fdch
                rlca
                jr      nc,5b
                dec     de
                jr      4b
