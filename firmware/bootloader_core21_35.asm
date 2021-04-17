
        include version.asm
      macro wreg  dir, dato
        rst     $28
        defb    dir, dato
      endm

        output  bootloader.rom
        define  zxuno_port      $fc3b
        define  flash_spi       2
        define  flash_cs        3
        define  core_addr       $fc
        define  core_boot       $fd

        di
        ld      sp, 0
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 0
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 6    ; envío write enable
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, $c5  ; envío wrear
        out     (c), 0
      IF  version=2
        wreg    core_addr, $09
        ld      a, $80
      ELSE
        wreg    core_addr, $0b
        xor     a
      ENDIF
        out     (c), a
        out     (c), 0
        wreg    core_boot, 1

        block   $28 - $
rst28   ld      bc, zxuno_port + $100
        pop     hl
        outi
        ld      b, (zxuno_port >> 8)+2
        outi
        jp      (hl)

