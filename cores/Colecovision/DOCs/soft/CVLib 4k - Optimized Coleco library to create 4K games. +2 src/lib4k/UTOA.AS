                psect   text

count_sub:      xor     a
1:              sbc     hl,bc
                inc     a
                jr      nc,1b
                dec     a
                add     hl,bc
                ret

                global  _utoa
                ; utoa (unsigned value,char *buffer,byte *null_character)
                ; leading zeros _are_ put in buffer
_utoa:          pop     bc
                pop     hl
                pop     de
                exx
                pop     bc
                push    bc
                exx
                push    de
                push    hl
                push    bc
                ld      bc,10000
                call    count_sub
                exx
                add     a,c
                exx
                ld      (de),a
                inc     de
                ld      bc,1000
                call    count_sub
                exx
                add     a,c
                exx
                ld      (de),a
                inc     de
                ld      bc,100
                call    count_sub
                exx
                add     a,c
                exx
                ld      (de),a
                inc     de
                ld      c,10
                call    count_sub
                exx
                add     a,c
                exx
                ld      (de),a
                inc     de
                ld      a,l
                exx
                add     a,c
                exx
                ld      (de),a
                ret
