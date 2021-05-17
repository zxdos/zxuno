; firmware.asm
;
; Copyright (C) 2016-2021 Antonio Villena
; Contributors:
;   2015 Einar Saukas (ZX7 Backwards)
;   2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, version 3.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.
;
; SPDX-FileCopyrightText: Copyright (C) 2016-2021 Antonio Villena
;
; SPDX-FileContributor: 2015 Einar Saukas (ZX7 Backwards)
; SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>
;   SJAsmPlus by aprisobal, <https://github.com/z00m128/sjasmplus/>

        output  bootloader.rom

        include zxuno.def

      macro wreg  dir, dato
        rst     $28
        defb    dir, dato
      endm

        di
        ld      sp, $bfff-ini+6
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 0
        ld      de, $c771       ; tras el out (c), h de bffc se ejecuta
        push    de              ; un rst 0 para iniciar la nueva ROM
        ld      de, $ed80       ; en $bffc para evitar que el cambio de ROM
        push    de              ; colisione con la siguiente instruccion
        ld      bc, $bffc-ini+6
        push    bc
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 6    ; envío write enable
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, $c5  ; envío wrear
        out     (c), 0
        jp      cont
        nop

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

        block   $0066 - $

nmi66   jp      $c003
        retn

cont    wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    joy_conf, %00010000
        wreg    master_mapper, 8  ; paginamos la ROM en $c000
lee     in      a, ($1f)
        djnz    lee
        wreg    scandbl_ctrl, $c0 ; lo pongo a 28MHz
        cp      %00011000       ; arriba y disparo a la vez
        jr      z, recov
        cp      %00010100       ; arriba y disparo a la vez
        jr      z, recov
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
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

        block   $0100 - $
        include scroll/define.asm
        ld      sp, 0
        ld      de, filestart+filesize-1
        ld      hl, scroll-1
        call    dzx7b
        jp      start

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
