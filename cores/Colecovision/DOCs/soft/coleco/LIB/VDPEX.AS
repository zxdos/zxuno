                psect   text

                global  _put_vram_ex
                ; put_vram_ex (offset,ptr,count,byte and,byte xor)
_put_vram_ex:   pop     hl
                exx
                pop     de
                ld      a,(1d43h)
                di
                ld      c,a
                out     (c),e
                set     6,d
                out     (c),d
                ei
                pop     hl
                pop     bc
                pop     de
                ld      a,e
                pop     de
                ld      d,a
                push    de
                push    de
                push    bc
                push    hl
                push    de
                exx
                push    hl
                exx
1:              push    bc
                ld      b,c
                ld      a,(1d47h)
                ld      c,a
2:              ld      a,(hl)
                inc     hl
                and     d
                xor     e
                out     (c),a
                djnz    2b
                pop     bc
                ld      c,0
                dec     b
                ret     z
                jp      p,1b
                ret

                global  _put_vram_pattern
                ; put_vram_pattern (unsigned offset,void *pattern,
                ;                   byte psize,unsigned count);
_put_vram_pattern:
                pop     hl
                pop     de
                ld      a,(1d43h)
                ld      c,a
                di
                out     (c),e
                set     6,d
                out     (c),d
                ei
                exx
                pop     hl
                pop     bc
                pop     de
                push    de
                push    bc
                push    hl
                exx
                push    de
                push    hl
                exx
                ld      b,c
                ld      a,(1d47h)
                ld      c,a
1:              push    bc
                push    hl
2:              outi
                nop
                nop
                jp      nz,2b
                pop     hl
                pop     bc
                dec     de
                ld      a,e
                or      d
                jr      nz,1b
                ret

                global  _set_default_name_table
                ; set_default_name_table (unsigned offset)
_set_default_name_table:
                pop     hl
                pop     de
                ld      a,(1d43h)
                ld      c,a
                di
                out     (c),e
                set     6,d
                out     (c),d
                ei
                push    de
                push    hl
                ld      a,(1d47h)
                ld      c,a
                ld      d,3
1:              xor     a
2:              out     (c),a
                nop
                inc     a
                jp      nz,2b
                dec     d
                jp      nz,1b
                ret
