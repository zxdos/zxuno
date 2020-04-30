            psect   data

            global  _sprites

            psect   text
            
            global  _got_bulle
            
_got_bulle:
            pop     bc
            pop     hl
            push    hl
            push    bc
            
            ld      h,0
            ld      de,_sprites
            add     hl,hl
            add     hl,hl
            add     hl,de
            ld      d,(hl)
            inc     hl
            ld      e,(hl)
            ld      hl,_sprites+8
            ld      bc,070fh    ; values 7 and 15
            ld      a,(hl)
            add     a,b
            sbc     a,d
            jr      c,1f
            sbc     a,c
            jr      nc,1f
            inc     hl
            ld      a,(hl)
            add     a,b
            sbc     a,e
            jr      c,1f
            sbc     a,c
            jr      nc,1f
            
            ld      hl,0001h
            ret
            
1:          ld      hl,0000h
            ret

; byte got_bulle(byte i)            
; {
;    byte delta_x = 7 + sprites[2].x - sprites[i].x;
;    byte delta_y = 7 + sprites[2].y - sprites[i].y;
;    return (delta_x<15 && delta_y<15);
; }

