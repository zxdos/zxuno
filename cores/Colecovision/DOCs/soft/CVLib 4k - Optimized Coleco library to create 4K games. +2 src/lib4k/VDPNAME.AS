                psect   text

                global  _set_default_name_table
                ; set_default_name_table (unsigned offset)
_set_default_name_table:
                pop     hl
                pop     de
                push    de
                push    hl
                ld      c,0bfh
                di
                out     (c),e
                set     6,d
                out     (c),d
                ei
                ld      c,0beh
                ld      d,3
1:              xor     a
2:              out     (c),a
                nop
                inc     a
                jp      nz,2b
                dec     d
                jp      nz,1b
                ret
