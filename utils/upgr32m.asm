                define  zxdos 1

              IF zxdos=1
                output  UPGRZX2
              ELSE
                output  UPGRZXD
              ENDIF

                include zxuno.inc

                org     $2000           ; comienzo de la ejecución de los comandos ESXDOS

                call    wrear0
                dec     b
                out     (c), 0
                inc     b
                in      f, (c)
                jp      p, Nonlock
                call    Print
                dz      'ROM not rooted'
                ret
Nonlock         wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $9f  ; jedec id
                in      a, (c)
                in      a, (c)
                in      a, (c)
                in      a, (c)
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                sub     $19
                jr      z, Goodflsh
                call    Print
                dz      'Incorrect flash IC'
                ret
Goodflsh        ld      a, scandbl_ctrl
                dec     b
                out     (c), a
                inc     b
                in      a, (c)
                and     $3f
                ld      (normal+1), a
                or      $c0
                out     (c), a
                call    init
                ld      bc, zxuno_port
                ld      a, scandbl_ctrl
                out     (c), a
                inc     b
normal          ld      a, 0
                out     (c), a
                ret
init            xor     a
                esxdos  M_GETSETDRV     ; A = unidad actual
                jr      nc, SDCard
                call    Print
                dz      'SD card not inserted'
                ret
SDCard          ld      b, FA_READ      ; B = modo de apertura
                ld      hl, FileName    ; HL = Puntero al nombre del fichero (ASCIIZ)
                esxdos  F_OPEN
                ld      (handle+1), a
                jr      nc, FileFound
                call    Print
              IF zxdos=1
                dz      'Can\'t open FLASH.ZX2'
              ELSE
                dz      'Can\'t open FLASH.ZXD'
              ENDIF
                ret
FileFound       call    Print
              IF zxdos=1
                dz      'Upgrading FLASH.ZX2 from SD', 13
              ELSE
                dz      'Upgrading FLASH.ZXD from SD', 13
              ENDIF
                call    read16m
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $c5  ; envío wrear
                ld      l, 1
                out     (c), l
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                call    read16m
                ld      a, (handle+1)
                esxdos  F_CLOSE
                call    Print
                dz      13, 'Upgrade complete'
wrear0          wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $c5  ; envío wrear
                out     (c), 0
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                ret

read16m         ld      ix, $0400
                ld      de, $0000
                exx
Bucle           ld      a, ixl
                inc     a
                and     $3f
                jr      nz, punto
                ld      a, 'o'
                exx
                push    de
                rst     $10
                pop     de
                exx
punto           ld      hl, $8000
                ld      bc, $4000
handle          ld      a, 0
                esxdos  F_READ
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
                dec     ixh
                jr      nz, Bucle
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
                xor     a
wrfls1          wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $20  ; envío sector erase
                out     (c), d
                out     (c), e
                out     (c), a
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
wrfls2          call    waits5
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 6    ; envío write enable
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                wreg    flash_cs, 0     ; activamos spi, enviando un 0
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
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
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
waits5          wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, 5    ; envío read status
                in      a, (c)
waits6          in      a, (c)
                and     1
                jr      nz, waits6
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                ret
        
rst28           ld      bc, zxuno_port + $100
                pop     hl
                outi
                ld      b, (zxuno_port >> 8)+2
                outi
                jp      (hl)

              IF zxdos=1
FileName        dz      'FLASH.ZX2'
              ELSE
FileName        dz      'FLASH.ZXD'
              ENDIF
