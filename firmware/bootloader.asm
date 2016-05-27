      macro wreg  dir, dato
        rst     $28
        defb    dir, dato
      endm

        output  bootloader.rom
        define  zxuno_port      $fc3b
        define  master_conf     0
        define  master_mapper   1
        define  flash_spi       2
        define  flash_cs        3
        define  joyconf         6
        define  scandbl_ctrl    11

        di
        ld      sp, $bfff-67
        ld      de, $c761       ; tras el out (c), h de bffc se ejecuta
        push    de              ; un rst 0 para iniciar la nueva ROM
        ld      de, $ed80       ; en $bffc para evitar que el cambio de ROM
        wreg    joyconf, %00010000
        jr      lspi

ldedg2  rst     $18             ; call routine ld-edge-1 below.
        jr      nz, ldedg1
        ret

lspi    in      a, ($1f)
        jr      lspi2

ldedg1  ld      a, $16          ; a delay value of twenty two.
ldelay  dec     a               ; decrement counter
        jr      nz, ldelay      ; loop back to ld-delay 22 times.
lsampl  inc     b               ; increment the time-out counter.
        ret     z               ; return with failure when $ff passed.
        in      a, ($fe)        ; row $7ffe. bit 6 is ear, bit 0 is space key.
        xor     c               ; compare with initial long-term state.
        and     $40             ; isolate bit 5
        jr      z, lsampl       ; back to ld-sample if no edge.
        jr      lcont

rst28   ld      bc, zxuno_port + $100
        pop     hl
        outi
        ld      b, (zxuno_port >> 8)+2
        outi
        jp      (hl)

lspi2   wreg    scandbl_ctrl, $c0 ; lo pongo a 28MHz
        push    de              ; colisione con la siguiente instruccion
        defb    $fe

rst38   jp      $c006

lspi3   wreg    flash_cs, 1     ; desactivamos spi, enviando un 0
        wreg    master_mapper, 8  ; paginamos la ROM en $c000
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 3    ; envio flash_spi un 3, orden de lectura
        and     c
        out     (c), h          ; envia direccion 008000, a=00,e=80,a=00
        out     (c), e
        out     (c), h
        add     hl, sp
boot    ini
        inc     b
        cp      h               ; compruebo si la direccion es 0000 (final)
        jr      c, boot         ; repito si no lo es
        wreg    scandbl_ctrl, 0 ; lo pongo a 3.5MHz
        dec     b
        out     (c), h          ; a master_conf quiero enviar un 0 para pasar
        inc     b
        cp      %00011000       ; arriba y disparo a la vez
        ld      de, $bffc-67
        push    de
        ld      ixh, e
        jr      nbreak

nmi66   jp      $c003
        retn

lcont   ld      a, c            ; fetch comparison value.
        xor     $47             ; switch the bits
        ld      c, a            ; and put back in c for long-term.
        out     ($fe), a        ; send to port to effect the change of colour. 
        ret                     ; return.

nbreak  ret     nz
        ld      de, $0051+2
        call    lbytes
        ld      ix, $c000
        ld      de, $4000+2
lbytes  ld      a, $0f          ; make the border white and mic off.
        out     ($fe), a        ; output to port.
        ld      c, 10
lstart  rst     $18             ; routine ld-edge-1
        jr      z, lstart       ; back to ld-break with time out and no edge present on tape
        xor     a               ; set up 8-bit outer loop counter for approx 0.45 second delay
ldwait  add     hl, hl
        djnz    ldwait          ; self loop to ld-wait (for 256 times)
        dec     a               ; decrease outer loop counter.
        jr      nz, ldwait      ; back to ld-wait, if not zero, with zero in b.
        rst     $10             ; routine ld-edge-2
        jr      z, lstart       ; back to ld-break if no edges at all.
leader  ld      b, $9c          ; two edges must be spaced apart.
        rst     $10             ; routine ld-edge-2
        jr      z, lstart       ; back to ld-break if time-out
        ld      a, $c6          ; two edges must be spaced apart.
        cp      b               ; compare
        jr      nc, lstart      ; back to ld-start if too close together for a lead-in.
        inc     h               ; proceed to test 256 edged sample.
        jr      nz, leader      ; back to ld-leader while more to do.
ldsync  ld      b, $c9          ; two edges must be spaced apart.
        rst     $18             ; routine ld-edge-1
        jr      z, lstart       ; back to ld-break with time-out.
        ld      a, b            ; fetch augmented timing value from b.
        cp      $d4             ; compare 
        jr      nc, ldsync      ; back to ld-sync if gap too big, that is, a normal lead-in edge gap
        rst     $18             ; routine ld-edge-1
        jr      z, binf
        xor     3
        ld      c, a
ldloop  ld      (ix-2), l       ; place loaded byte at memory location.
        inc     ix              ; increment byte pointer.
        dec     de              ; decrement length.
        ld      l, $01          ; initialize as %00000001
l8bits  ld      b, $b2          ; timing.
        rst     $10             ; routine ld-edge-2 increments b relative to gap between 2 edges
binf    jr      z, binf         ; return with time-out.
        ld      a, $cb          ; the comparison byte.
        cp      b               ; compare to incremented value of b.
        rl      l               ; rotate the carry bit into l.
        jr      nc, l8bits      ; jump back to ld-8-bits
        ld      a, h            ; fetch the running parity byte.
        xor     l               ; include the new byte.
        ld      h, a            ; and store back in parity register.
        ld      a, d            ; check length of
        or      e               ; expected bytes.
        jr      nz, ldloop      ; back to ld-loop while there are more.
        or      h
bin2    jr      nz, bin2
        ld      bc, zxuno_port + $100
        ret                     ; return
