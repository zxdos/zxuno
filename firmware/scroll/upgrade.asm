; upgrade.asm
;
; Copyright (C) 2016, 2020, 2021 Antonio Villena
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
; SPDX-FileCopyrightText: Copyright (C) 2016, 2020, 2021 Antonio Villena
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

                output  UPGRADE

                define  FA_READ         0x01
                define  M_GETSETDRV     0x89
                define  F_OPEN          0x9a
                define  F_CLOSE         0x9b
                define  F_READ          0x9d
                define  F_SEEK          0x9f

                define  zxuno_port      $fc3b
                define  flash_spi       2
                define  flash_cs        48

              macro wreg  dir, dato
                call    rst28
                defb    dir, dato
              endm

                org     $2000           ; comienzo de la ejecución de los comandos ESXDOS

Main            xor     a
                rst     $08
                db      M_GETSETDRV     ; A = unidad actual
                jr      nc, SDCard
                call    Print
                dz      'SD card not inserted'
                ret
SDCard          ld      b, FA_READ      ; B = modo de apertura
                ld      hl, FileName    ; HL = Puntero al nombre del fichero (ASCIIZ)
                rst     $08
                db      F_OPEN
                ld      (handle+1), a
                jr      nc, FileFound
                call    Print
                dz      'File FLASH not found'
                ret
FileFound       ld      l, 0
                ld      bc, 0
                ld      de, 0
                rst     $08
                db      F_SEEK
                call    Print
                dz      'No '
                ld      a, (puerto+2)
                add     a, $30
                rst     $10
                call    repe
                jr      nz, nfallo
;                call    hex
                call    Print
                dz      'Flash error'
                jr      Next
nfallo          halt
                halt
                ;jr Verify;call    hex
                ld      ixl, 0
                ld      de, $0000
                exx
Bucle           ld      a, ixl
                inc     a
                and     $0f
                jr      nz, punto
                ld      a, '.'
                exx
                push    de
                rst     $10
                pop     de
                exx
punto           ld      hl, $8000
                ld      bc, $4000
handle          ld      a, 0
                rst     $08
                db      F_READ
                jr      nc, ReadOK
                call    Print
                dz      'Read Error'
                ret
ReadOK          ld      a, $40
                ld      hl, $8000
                exx
                call    wrflsh
                inc     de
                exx
                dec     ixl
                jr      nz, Bucle

                halt
                halt

Verify          ld      de, $8000
                ld      hl, $0040
                ld      a, 2
                call    rdflsh
                ld      de, $8000
                ld      hl, 0
Verify1         ex      de, hl
                ld      c, (hl)
                inc     l
                ld      b, (hl)
                inc     hl
                ex      de, hl
                add     hl, bc
                bit     1, d
                jr      z, Verify1
                ld      a, h
                call    hex
                ld      a, l
                call    hex
                halt
                halt
                
;                ld      de, $371a
;                sbc     hl, de
;                jr      z, Next
;                call    Print
;                dz      'CRC Error'
Next            ld      a, 13
                rst     $10
                ld      a, (puerto+2)
                inc     a
                ld      (puerto+2), a
                cp      $10
                ld      a, (handle+1)
                jp      nz, FileFound
                rst     $08
                db      F_CLOSE
                ret

Print           pop     hl
                db      $3e
Print1          rst     $10
                ld      a, (hl)
                inc     hl
                or      a
                jr      nz, Print1
                jp      (hl)

; ------------------------
; Write to SPI flash
; Parameters:
;    A: number of pages (256 bytes) to write
;   DE: target address without last byte
;  BC': zxuno_port+$100 (constant)
;  HL': source address from memory
; ------------------------
wrflsh          ex      af, af'
wrfls1          call    puerto
                wreg    flash_spi, 6    ; envío write enable
                call    flashcs
                call    puerto
                wreg    flash_spi, $20  ; envío sector erase
                out     (c), d
                out     (c), e
                out     (c), a
                call    flashcs
wrfls2          call    waits5
                call    puerto
                wreg    flash_spi, 6    ; envío write enable
                call    flashcs
                call    puerto
                wreg    flash_spi, 2    ; page program
                out     (c), d
                out     (c), e
                out     (c), a
                ld      a, $20
                exx
                ld      bc, zxuno_port+$100
wrfls3          inc     b
                outi
                inc     b
                outi
                inc     b
                outi
                inc     b
                outi
                inc     b
                outi
                inc     b
                outi
                inc     b
                outi
                inc     b
                outi
                dec     a
                jr      nz, wrfls3
                exx
                call    flashcs
                ex      af, af'
                dec     a
                jr      z, waits5
                ex      af, af'
                inc     e
                ld      a, e
                and     $0f
                jr      nz, wrfls2
                ld      hl, wrfls1
                push    hl
waits5          call    puerto
                wreg    flash_spi, 5    ; envío read status
                in      a, (c)
waits6          in      a, (c)
                and     1
                jr      nz, waits6

flashcs         push    af
                ld      a, (puerto+2)
                rrca
                jr      c, flashcs1
                wreg    flash_cs, $ff
                pop     af
                ret
flashcs1        wreg    flash_cs+1, $ff
                pop     af
                ret

puerto          push    af
                ld      a, 0
                srl     a
                push    af
                ld      bc, zxuno_port
                ld      a, flash_cs
                adc     a, 0
                out     (c), a
                pop     bc
                inc     b
                ld      a, $7f
puerto1         rlca
                djnz    puerto1
                ld      bc, zxuno_port + $100
                out     (c), a
                pop     af
                ret

rst28           ld      bc, zxuno_port + $100
                pop     hl
                outi
                ld      b, (zxuno_port >> 8)+2
                outi
                jp      (hl)

repe            ld      e, 0
repe1           call    puerto
                wreg    flash_spi, 6    ; envío write enable
                call    flashcs
                call    puerto
                wreg    flash_spi, 1    ; envío write register status
                out     (c), 0
                ld      a, 2
                out     (c), a
                call    flashcs
                call    puerto
                wreg    flash_spi, $35  ; envío write register status
                in      a, (c)
                in      a, (c)
                call    flashcs
                and     2
                ret     nz
                dec     e
                jr      nz, repe1
                ret

; ------------------------
; Read from SPI flash
; Parameters:
;   DE: destination address
;   HL: source address without last byte
;    A: number of pages (256 bytes) to read
; ------------------------
rdflsh          ex      af, af'
                xor     a
                push    hl
                call    puerto
                wreg    flash_spi, 3    ; envio flash_spi un 3, orden de lectura
                pop     hl
                push    hl
                out     (c), h
                out     (c), l
                out     (c), a
                ex      af, af'
                ex      de, hl
                in      f, (c)
rdfls1          ld      e, $20
rdfls2          ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                ini
                inc     b
                dec     e
                jr      nz, rdfls2
                dec     a
                jr      nz, rdfls1
                call    flashcs
                pop     hl
                ret

hex             push    af
                and     $f0
                rrca
                rrca
                rrca
                rrca
                cp      $0a
                jr      c, mayo
                add     a, 7
mayo            add     a, $30
                rst     $10
                pop     af
                and     $0f
                cp      $0a
                jr      c, maya
                add     a, 7
maya            add     a, $30
                rst     $10
                ret

FileName        dz      'FLASH.ZX1'
