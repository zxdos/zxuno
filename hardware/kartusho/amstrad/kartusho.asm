        OUTPUT  KARTUSHO.ROM
        ORG     $0
        di
        ld      sp, $c000
        ld      bc, $3ffc
        ld      hl, $0000
        ld      de, $4000
        ldir
        jp      conti+$4000

conti   im      1
        xor     a
        inc     a
        call    chslot+$4000    ; cargo ROM del 464 en 0000

  ld a, $40                     ; poner borde gris
  call border+$4000

        ld      d, c            ; D=0
        ld      bc, $f782
        out     (c), c          ; PIO Control-Register
        dec     b
        out     (c), d          ; Port C
        dec     b
        in      a, (c)          ; Read from port B 
        dec     b
        out     (c), d          ; Port A
        ld      bc, $ef7f
        out     (c), c
        and     $10
        ld      e, a
        ld      hl, $05c4       ; 60hz
        xor     a
        sbc     hl, de
crctlo  ld      b, $bc          ; inicializo registros CRCT
        out     (c), a
        ld      b, $be
        outi
        inc     a
        cp      $10
        jr      nz, crctlo
        ld      bc, $7f98
        out     (c), c
        call    $0044           ; initialise LOW KERNEL and HIGH KERNEL jumpblocks
        call    $0888           ; JUMP RESTORE

  ld a, $42                     ; poner borde cyan
  call border+$4000

        xor     a
        call    chslot+$4000    ; cargo ROM del juego en 0000
        ld      hl, data
        ld      de, $51f0
        call    sauk            ; descomprimo

  ld a, $43                     ; poner borde amarillo
  call border+$4000

        ld      a, 1
        scf                     ; bloqueo después
        call    chslot+$4000    ; cargo ROM del 464

  ld a, $44                     ; poner borde azul
  call border+$4000

        jp      $6e3f           ; salto a juego

        include d.asm

;input A= color
;      carry= LOCK
border  ld      b, $7f
        out     (c), a
        ret

;input A= slot number bewteen 0 and 31
;      carry= LOCK
chslot  adc     a, a
        add     a, a
        add     a, a
        ld      hl, $3ffc
        ld      b, 5
chslo1  ld      (hl), a
        add     a, a
        res     0, l
        jr      nc, chslo2
        inc     l
chslo2  djnz    chslo1
        rlca
        rlca
        add     a, l
        ld      l, a
        ld      (hl), a
        ret
data    incbin  Manic.bin.skv

        BLOCK   $4000-$
        incbin  OS464.ROM
        BLOCK   $80000-$
