        define  debug   0

inirea  push    hl
        push    bc
reinit  call    mmcinit
        pop     bc
        pop     hl
        ret     nz
;        defb    $32
readat0 ld      e, 0
readata push    hl
        push    bc
        ld      a, READ_SINGLE  ; Command code for multiple block read
        call    cs_low          ; set cs high
        ld      bc, READ_SINGLE<<8 | SPI_PORT
        out     (c), b
        ld      a, (sdhc)
        or      a
        jr      z, mul2
        out     (c), 0
        out     (c), e
        out     (c), h
        out     (c), l
        call    send0z
        jr      mul3
mul2    ld      a, e
        add     hl, hl
        adc     a, a
        out     (c), a
        out     (c), h
        out     (c), l
        call    send1z
mul3    or      a
        jr      nz, reinit
waitl   call    waitr
        sub     $fe             ; waits for the MMC to reply $FE (DATA TOKEN)
        jr      z, waitm
        djnz    waitl
waitm   push    ix
        pop     hl              ; INI usa HL come puntatore
        ld      b, a
        inir
        inir
        pop     bc
        pop     hl
        ret

mmcinit xor     a
        ld      (sdhc), a
        ld      iyl, a
        dec     a
        call    cs_high         ; set cs high
        ld      bc, $09<<8 | SPI_PORT
l_init  out     (c), a
        djnz    l_init
        call    cs_low          ; set cs low
        ld      hl, $95<<8 | CMD0 
        call    send5
        dec     a               ; MMC should respond 01 to this command
        ret     nz              ; fail to reset
        ld      l, CMD8
        out     (c), l          ; sends the command
        out     (c), 0
        out     (c), 0
        inc     a
        out     (c), a
        ld      hl, $87aa
        out     (c), l
        call    send0z
        dec     a
        jr      z, sdv2
        ld      h, 0
        call    acmd41
        cp      2
        jr      nc, mmc
      IF debug=1
        ld      a, 1
        out     ($fe), a
      ENDIF
sdv1    call    acmd41
        call    count
        jr      z, count
        and     a
        jr      nz, sdv1
mmc1    and     a
        ret     z
mmc     ld      l, CMD1
        call    send5
        call    count
        jr      nz, mmc1
count   dec     b
        ret     nz
        dec     iyl
        ret
sdv2    ld      h, $40
        call    sdv1
        ld      l, CMD58
        call    send5
        in      a, (c)
        cp      $c0
        jr      nz, sig2
        ld      (sdhc), a
sig2    in      a, (c)
        in      a, (c)
        in      a, (c)

cs_low  push    af
        ld      a, MMC_0
        jr      cs_hig1
  
acmd41  ld      l, CMD55
        call    send5
        ld      l, CMD41
        out     (c), l
        out     (c), h
        jr      send3z

cs_high push    af
        ld      a, $ff
cs_hig1 out     (OUT_PORT), a
        pop     af
        ret

send5   out     (c), l          ; sends the command
        out     (c), 0          ; then sends four "00" bytes (parameters = NULL)
send3z  out     (c), 0
        out     (c), 0
send1z  out     (c), 0
send0z  out     (c), h          ; then this byte is ignored.
waitr   push    bc
        ld      c, 50           ; retry counter
resp    in      a, (SPI_PORT)   ; reads a byte from MMC
        cp      $ff             ; $FF = no card data line activity
        jr      nz, resp_ok
        djnz    resp
        dec     c
        jr      nz, resp
resp_ok pop     bc
        ret
