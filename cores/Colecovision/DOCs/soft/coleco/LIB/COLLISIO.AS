                psect   text

                global  _check_collision
                ; check_collision
                ; (byte *sprite1,                       ix+0
                ;  byte *sprite2,                       ix+2
                ;  unsigned sprite1_size_hor,           ix+4
                ;  unsigned sprite1_size_vert,          ix+6
                ;  unsigned sprite2_size_hor,           ix+8
                ;  unsigned sprite2_size_vert);         ix+10
                ; sizes decode as follows:
                ; lobyte - first pixel set
                ; hibyte - number of pixels set
_check_collision:
                push    ix
                ld      ix,4
                add     ix,sp
                ld      l,(ix+0)
                ld      h,(ix+1)
                ld      a,(hl)
                add     a,32
                add     a,(ix+6)
                ld      e,a
                ld      d,0             ; de=vertical pos. sprite 1 + 32
                ld      l,(ix+2)
                ld      h,(ix+3)
                ld      a,(hl)
                add     a,32
                add     a,(ix+10)
                ld      l,a
                ld      h,0             ; hl=vertical pos. sprite 2 + 32
                ld      b,(ix+11)       ; b=number of pixels, sprite 2
                ex      de,hl
                or      a
                sbc     hl,de
                jr      nc,1f
                ld      b,(ix+7)        ; swap sprites
                add     hl,de
                ex      de,hl
                or      a
                sbc     hl,de
1:              ld      a,l
                cp      b
                jr      nc,9f

                ld      l,(ix+0)
                ld      h,(ix+1)
                inc     hl
                ld      e,(hl)
                inc     hl
                inc     hl
                ld      a,(hl)
                and     128
                rrca
                rrca
                xor     32
                add     a,(ix+4)
                add     a,e
                ld      e,a
                ld      a,0
                adc     a,a
                ld      d,a             ; de=horizontal pos. sprite 1 + 32
                ld      l,(ix+2)
                ld      h,(ix+3)
                inc     hl
                ld      c,(hl)
                inc     hl
                inc     hl
                ld      a,(hl)
                and     128
                rrca
                rrca
                xor     32
                add     a,(ix+8)
                add     a,c
                ld      l,a
                ld      a,0
                adc     a,a
                ld      h,a             ; hl=horizontal pos. sprite 2 + 32
                ld      b,(ix+9)        ; b=number of pixels, sprite 2
                ex      de,hl
                or      a
                sbc     hl,de
                jr      nc,1f
                ld      b,(ix+5)        ; swap sprites
                add     hl,de
                ex      de,hl
                or      a
                sbc     hl,de
1:              ld      a,h
                or      a
                jr      nz,9f
                ld      a,l
                cp      b
9:              ld      hl,0
                adc     hl,hl
                pop     ix
                ret

