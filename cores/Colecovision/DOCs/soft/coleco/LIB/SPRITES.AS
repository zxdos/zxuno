                psect   bss
                global  _sprites
sprite_count:   defs    1
_sprites:       defs    256

                psect   text
                global  _update_sprites
                ; update_sprites (byte numsprites,unsigned sprtab);
_update_sprites:
                pop     hl
                pop     bc
                pop     de
                push    de
                push    bc
                push    hl
                ld      b,c
                ld      a,(1d43h)
                ld      c,a
                di
                out     (c),e
                set     6,d
                out     (c),d
                ei
                ld      a,(1d47h)
                ld      c,a
                ld      a,b
                ex      af,af'
                ld      b,64
                ld      a,(sprite_count)
                ld      e,a
                ld      d,0
sprites_loop:   ld      hl,_sprites
                add     hl,de
                ld      a,(hl)
                cp      -16
                jr      nc,1f
                cp      192
                jp      nc,3f
1:              ld      a,(hl)
                inc     hl
                out     (c),a
                ld      a,(hl)
                inc     hl
                out     (c),a
                ld      a,(hl)
                inc     hl
                out     (c),a
                ld      a,(hl)
                and     8fh                     ; mask off unused bits so
                inc     hl                      ;  they can be used by the
                out     (c),a                   ;  program itself
                ex      af,af'
                dec     a
                jp      m,9f
                cp      23
                jr      nz,2f
                ex      af,af'
                ld      a,e
                ld      (sprite_count),a
                ex      af,af'
2:              ex      af,af'
3:              ld      a,e
                add     a,4
                ld      e,a
                dec     b
                jp      nz,sprites_loop
                ld      a,208
                out     (c),a
9:              ret

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
