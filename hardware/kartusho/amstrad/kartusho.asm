        OUTPUT  KARTUSHO.ROM
        ORG     $0
        di
        im      1
        ld      sp, $c000
        ld      hl, initData60Hz
        ld      d, h            ; D=H=0
        ld      bc, $f782
        out     (c), c          ; PIO Control-Register
        dec     b
        out     (c), h          ; Port C
        dec     b
        in      a, (c)          ; Read from port B 
        dec     b
        jr      cont
initData60Hz:
        defb    $3f, $28, $2e, $8e, $1f, $06, $19, $1b
        defb    $00, $07, $00, $00, $30, $00, $c0, $00
initData50Hz:
        defb    $3f, $28, $2e, $8e, $26, $00, $19, $1e
        defb    $00, $07, $00, $00, $30, $00, $c0, $00

rst38   ei
        ret

cont    out     (c), h          ; Port A
        ld      bc, $ef7f
        out     (c), c
        and     $10
        ld      e, a
        add     hl, de
crctlo  ld      b, $bc          ; inicializo registros CRCT
        out     (c), d
        ld      b, $be
        outi
        inc     d
        bit     4, d
        jr      z, crctlo
        ld      bc, $7f98
        out     (c), c

  ld a, $40                     ; poner borde gris
  call border

        ld      bc, $3ffc
        ld      l, h            ; HL= 0
        ld      de, $8000
        ldir

  ld a, $42                     ; poner borde verde
  call border+$8000

        jp      toram+$8000

toram   
        halt

        xor     a
        inc     a
        call    chslot+$8000    ; cargo ROM del 464 en 0000

  ld a, $43                     ; poner borde amarillo
  call border+$8000

        call    $0044           ; initialise LOW KERNEL and HIGH KERNEL jumpblocks
        call    $0888           ; JUMP RESTORE

  ld a, $44                     ; poner borde azul
  call border+$8000

        xor     a
        call    chslot+$8000    ; cargo ROM del juego en 0000
        ld      hl, data
        ld      de, $51f0
        call    sauk            ; descomprimo

        ld      a, 1
        scf                     ; bloqueo después
        call    chslot+$8000    ; cargo ROM del 464


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
