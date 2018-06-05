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
        ld      sp, $bfff-ini+6
        ld      de, $c771       ; tras el out (c), h de bffc se ejecuta
        push    de              ; un rst 0 para iniciar la nueva ROM
        ld      de, $ed80       ; en $bffc para evitar que el cambio de ROM
        push    de              ; colisione con la siguiente instruccion
        ld      bc, $bffc-ini+6
        push    bc
        wreg    joyconf, %00010000
        wreg    master_mapper, 8  ; paginamos la ROM en $c000
        wreg    scandbl_ctrl, $c0 ; lo pongo a 28MHz
        in      a, ($1f)
        cp      %00011000       ; arriba y disparo a la vez
        jr      z, recov
        cp      %00010100       ; arriba y disparo a la vez
        jr      z, recov
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 0
        jr      cont

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

rst38   jp      $c006

cont    wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 3    ; envio flash_spi un 3, orden de lectura
ini     out     (c), h          ; envia direccion 008000, a=00,e=80,a=00
        out     (c), e
        out     (c), h
        add     hl, sp
boot    ini
        inc     b
        cp      h               ; compruebo si la direccion es 0000 (final)
        jr      c, boot         ; repito si no lo es
boot1   dec     b
        out     (c), 0          ; a master_conf quiero enviar un 0 para pasar
        inc     b
        ret

recov   ld      hl, firmware-1
        ld      de, $ffff
        push    bc
        call    dzx7b
        pop     bc
        jr      boot1

        defb    'AV2018'

nmi66   jp      $c003
        retn


        block   $0100 - $
        include scroll/define.asm
        ld      sp, 0
        ld      de, $5e6d+filesize-1
        ld      hl, scroll-1
        call    dzx7b
        jp      $7be4

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
offend  rr      e
        ex      (sp), hl
        ex      de, hl
        adc     hl, de
        lddr
exitdz  pop     hl
        jr      nc, mainlo
        ret

        incbin  firmware.rom.zx7b
firmware
        incbin  scroll/scroll.bin.zx7b
scroll
        ;block   $4000 - $
