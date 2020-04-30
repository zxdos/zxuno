                psect   text

                global  _put_vram_pattern
                ; put_vram_pattern (unsigned offset,void *pattern,
                ;                   byte psize,unsigned count);
_put_vram_pattern:
                pop     hl
                pop     de
                ld      c,0bfh
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
                ld      c,0beh
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
