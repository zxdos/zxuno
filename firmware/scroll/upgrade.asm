                output  UPGRADE

                define  FA_READ         0x01
                define  M_GETSETDRV     0x89
                define  F_OPEN          0x9a
                define  F_CLOSE         0x9b
                define  F_READ          0x9d

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
                jr      nc, FileFound
                call    Print
                dz      'File FLASH not found'
                ret
FileFound       ld      ixl, 0
                ld      de, $0000
                exx
Bucle           ld      hl, $8000
                ld      bc, $4000
                push    af
                rst     $08
                db      F_READ
                jr      nc, ReadOK
                call    Print
                dz      'Read Error'
                pop     af
                ret
ReadOK          ld      a, $40
                ld      hl, $8000
                exx
                call    wrflsh
                inc     de
                exx
                pop     af
                dec     ixl
                jr      nz, Bucle
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
wrfls1          call    flashcs
                wreg    flash_spi, 6    ; envío write enable
                call    puerto
                call    flashcs
                wreg    flash_spi, $20  ; envío sector erase
                out     (c), d
                out     (c), e
                out     (c), a
                call    puerto
wrfls2          call    waits5
                call    flashcs
                wreg    flash_spi, 6    ; envío write enable
                call    puerto
                call    flashcs
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
                call    puerto
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
waits5          call    flashcs
                wreg    flash_spi, 5    ; envío read status
                in      a, (c)
waits6          in      a, (c)
                and     1
                jr      nz, waits6

puerto          ld      a, 0
                srl     a
                push    af
                dec     b
                sbc     a, a
                adc     a, flash_cs+1
                out     (c), a
                pop     bc
                inc     b
                ld      a, $80
puerto1         rlca
                djnz    puerto1
                ld      bc, zxuno_port
                out     (c), a
                ret

flashcs         ld      a, (puerto+1)
                rrca
                jr      c, flashcs1
                wreg    flash_cs+1, 0
                ret
flashcs1        wreg    flash_cs, 0
                ret

rst28           ld      bc, zxuno_port + $100
                pop     hl
                outi
                ld      b, (zxuno_port >> 8)+2
                outi
                jp      (hl)

FileName        dz      'FLASH.ZX1'
