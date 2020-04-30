                psect   bss
                global  sprite_count
                global  _sprites

                psect   text
                global  _clear_sprites
                ; clear_sprites (byte first,byte count)
_clear_sprites: pop     bc
                pop     hl
                pop     de
                push    de
                push    hl
                push    bc
                ld      h,0
                add     hl,hl
                add     hl,hl
                ld      bc,_sprites
                add     hl,bc
                ld      bc,4
1:              dec     e
                ret     m
                ld      (hl),207
                add     hl,bc
                jr      1b
                ret

