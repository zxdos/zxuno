ZXUNOADDR             equ 0FC3Bh
ZXUNODATA             equ 0FD3Bh
MAPPER128K            equ 7FFDh
MAPPERPLUS3           equ 1FFDh
DIVIDECTRL            equ 0E3h
MASTERCONF            equ 0
MASTERMAPPER          equ 1
SCANDBLCTRL           equ 0Bh

CHECK128              equ 74h

                      org 0
                      di
                      ;Comprobar si la ROM de 128K está presente en la pantalla principal

                      xor a   ;paso 1. Conmutar a 28 MHz
                      out (254),a
                      
                      ld bc,ZXUNOADDR
                      ld a,SCANDBLCTRL
                      out (c),a
                      inc b
                      in a,(c)
                      or 0c0h     ;28 MHz para ir rapidito
                      out (c),a

                      ld hl,4000h
                      ld b,0
                      xor a
BucleChecksum         add a,(hl)
                      inc hl
                      djnz BucleChecksum
                      cp CHECK128
                      jp nz,NoArranqueInicial

                      ld a,1  ;paso 2. Copia de ROMs a su sitio
                      out (254),a

                      ld bc,ZXUNOADDR
                      ld a,MASTERMAPPER
                      out (c),a
                      inc b
                      ld a,8   ;banco ROM 0
                      out (c),a
                      ld hl,4000h
                      ld de,0c000h
                      ld bc,4000h
                      ldir

                      ld bc,ZXUNODATA
                      ld a,10  ;banco ROM 2
                      out (c),a
                      ld hl,4000h
                      ld de,0c000h
                      ld bc,4000h
                      ldir

                      ld bc,ZXUNODATA
                      ld a,7   ;shadow screen
                      out (c),a
                      ld hl,0c000h
                      ld de,4000h   ;copiamos a un sitio fuera del ultimo banco de 16KB, para permitir paginación
                      ld bc,4000h
                      ldir

                      ld bc,ZXUNODATA
                      ld a,9   ;banco ROM 1
                      out (c),a
                      ld hl,4000h
                      ld de,0c000h
                      ld bc,4000h
                      ldir

                      ld bc,ZXUNODATA
                      ld a,11  ;banco ROM 3
                      out (c),a
                      ld hl,4000h
                      ld de,0c000h
                      ld bc,4000h
                      ldir

                      ld bc,ZXUNODATA
                      ld a,12  ;banco ESXDOS
                      out (c),a
                      ld hl,ESXDOSRom
                      ld de,0c000h
                      ld bc,2000h
                      ldir


NoArranqueInicial     ld a,2   ;paso 3. Preparar la fase en RAM
                      out (254),a

                      ld hl,UltimaFaseEnRAM
                      ld de,8000h
                      ld bc,LongUltimaFase
                      ldir

                      jp 8000h

UltimaFaseEnRAM       ld a,3   ;paso 4. Configuramos máquina
                      out (254),a

                      ld bc,ZXUNOADDR
                      ld a,MASTERCONF
                      out (c),a
                      inc b
                      ld a,10010010b  ;Modo 128K, con DivMMC y ESXDOS, configuración bloqueada y no boot
                      out (c),a
                      ld bc,MAPPER128K
                      ld a,00010000b
                      out (c),a
                      ld bc,MAPPERPLUS3
                      ld a,00000100b
                      out (c),a

                      ld a,4   ;paso 5. Borrado de la ROM del DivMMC para forzar reinicio
                      out (254),a

                      ld a,80h    ;16 páginas de 8KB cada una + CONMEM
BucleEraseDivMMC      out (DIVIDECTRL),a
                      ld hl,2000h
                      ld de,2001h
                      ld bc,1FFFh
                      ld (hl),l
                      ldir
                      inc a
                      cp 90h
                      jr nz,BucleEraseDivMMC
                      xor a
                      out (DIVIDECTRL),a

                      ld a,5   ;paso 6. Volvemos a 3.5 MHz y arrancamos ROM normal de 128K (con DivMMC)
                      out (254),a

                      ld bc,ZXUNOADDR
                      ld a,SCANDBLCTRL
                      out (c),a
                      inc b
                      in a,(c)
                      and 3Fh     ;echamos el freno y volvemos a los 3.5 MHz
                      out (c),a

                      jp 0
LongUltimaFase        equ $-UltimaFaseEnRAM

                      org 512
ESXDOSRom             equ $

                      end
