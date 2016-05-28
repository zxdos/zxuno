        output  firmloader.rom
      macro wreg  dir, dato
        rst     $28
        defb    dir, dato
      endm

        define  zxuno_port      $fc3b
        define  master_conf     0
        define  master_mapper   1

        di
        ld      sp, $bfff
        ld      de, $c771       ; tras el out (c), h de bffc se ejecuta
        push    de              ; un rst 0 para iniciar la nueva ROM
        ld      de, $edff       ; en $bffc para evitar que el cambio de ROM
        push    de              ; colisione con la siguiente instruccion
        wreg    master_mapper, 8  ; paginamos la ROM en $c000
        ld      hl, fin-1
        ld      d, e
        rst     $38
        ld      bc, zxuno_port
        out     (c), 0          ; a master_conf quiero enviar un 0 para pasar
        inc     b
        jp      $bffc

acab    rr      e
        ex      de, hl
        adc     hl, de
        lddr
exitdz  pop     hl
        jr      nc, mainlo
        ret

rst28   ld      bc, zxuno_port + $100
        pop     hl
        outi
        ld      b, (zxuno_port >> 8)+2
        outi
        jp      (hl)
getbit  ld      a, (hl)
        dec     hl
        adc     a, a
        ret
        nop

; -----------------------------------------------------------------------------
; ZX7 Backwards by Einar Saukas, Antonio Villena
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------
dzx7b   ld      bc, $8000
        ld      a, b
copyby  inc     c
        ldd
mainlo  add     a, a
        call    z, getbit
        jr      nc, copyby
        push    de
        ld      d, c
        defb    $30
lenval  add     a, a
        call    z, getbit
        rl      c
        rl      b
        add     a, a
        call    z, getbit
        jr      nc, lenval
        inc     c
        jr      z, exitdz
        ld      e, (hl)
        dec     hl
        sll     e
        jr      nc, offend
        ld      d, $10
nexbit  add     a, a
        call    z, getbit
        rl      d
        jr      nc, nexbit
        inc     d
        srl     d
offend  ex      (sp), hl
        jr      acab

        incbin  firmware.rom.zx7b
fin
