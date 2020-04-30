                psect   text

                global  indir

                global  _upload_ascii
                ; upload_ascii (byte first,byte count,
                ;               unsigned offset,byte flags);
                ; flags are as follows:
                ; bit
                ; 0 - italic
                ; 1 - bold
_upload_ascii:  pop     hl
                pop     de
                pop     bc
                exx
                pop     de
                ld      a,(1d43h)
                ld      c,a
                di
                out     (c),e
                set     6,d
                out     (c),d
                ei
                pop     bc
                ld      a,c
                exx
                push    bc
                push    bc
                push    bc
                push    de
                push    hl
                ld      l,e
                ld      h,0
                add     hl,hl
                add     hl,hl
                add     hl,hl
                ld      de,(006ah)
                add     hl,de
                ld      de,-65*8
                add     hl,de
                exx
                ld      hl,upload_procs
                and     3
                add     a,a
                add     a,l
                ld      l,a
                ld      a,0
                adc     a,h
                ld      h,a
                ld      a,(hl)
                inc     hl
                ld      h,(hl)
                ld      l,a
                exx
                ld      a,c
                exx
                ld      b,a
                exx
                ld      a,(1d47h)
                ld      c,a
                exx
1:              call    indir
                djnz    1b
                ret

normal:         exx
                ld      b,8
1:              outi
                nop
                nop
                jp      nz,1b
                exx
                ret

italic:         exx
                ld      b,4
1:              ld      a,(hl)
                inc     hl
                rrca
                and     7fh
                out     (c),a
                djnz    1b
                ld      b,4
2:              outi
                nop
                nop
                jp      nz,2b
                exx
                ret

bold:           exx
                ld      b,8
1:              ld      a,(hl)
                inc     hl
                ld      d,a
                rrca
                and     7fh
                or      d
                out     (c),a
                djnz    1b
                exx
                ret

bold_italic:    exx
                ld      b,4
1:              ld      a,(hl)
                inc     hl
                ld      d,a
                rrca
                and     7fh
                or      d
                rrca
                and     7fh
                out     (c),a
                djnz    1b
                ld      b,4
2:              ld      a,(hl)
                inc     hl
                ld      d,a
                rrca
                and     7fh
                or      d
                out     (c),a
                djnz    2b
                exx
                ret

                psect   data
upload_procs:   defw    normal
                defw    italic
                defw    bold
                defw    bold_italic

