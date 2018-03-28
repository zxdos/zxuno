        OUTPUT  TEST.ROM
        ORG     $0 
        im      1
        ld      sp, $8000

        ;; Reset PPI Values
        ld      bc, $f782
        out     (c), c
        ld      bc, $f400       ;; Port A
        out     (c), c
        ld      bc, $f600       ;; Port C
        out     (c), c

        ld      bc, $ef7f
        out     (c), c
        ;; Read from port B and check if PAL or NTSC
        ld      b, $f5
        in      a, (c)
        and     $10
        ld      hl, initData50Hz + 16
        jr      nz, initCRTCData
        ld      hl, initData60Hz + 16
initCRTCData:
        ld      bc, $bc0f
initCRTCLoop:
        out     (c), c
        dec     hl
        ld      a, (hl)
        inc     b
        out     (c), a
        dec     b
        dec     c
        jp      p, initCRTCLoop

        jr      continue

rst38:  ei
        ret

continue:
        ;; Select mode 0, enable lower ROM, disable upper ROM, enable INT
        ld      bc, $7f98
        out     (c), c
        ei
        halt
        di
        ld      a, $f5
        in      a, ($ff)
        inc     a
        jr      nz, AMSTRAD

SPECTRUM:
        ld      a, 1
        out     ($fe), a
        halt

AMSTRAD:
        ei
        ld      a, $40
        ld      bc, $7f10
bucle:  out     (c), c
        out     (c), a
        halt
        inc     a
        cp      $60
        jr      nz, bucle
        di
;; CRTC registers initialization data
initData50Hz:
        defb    $3f, $28, $2e, $8e, $26, $00, $19, $1e
        defb    $00, $07, $00, $00, $30, $00, $c0, $00

initData60Hz:
        defb    $3f, $28, $2e, $8e, $1f, $06, $19, $1b
        defb    $00, $07, $00, $00, $30, $00, $c0, $00

        BLOCK   $4000-$