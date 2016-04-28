ZXUNOREGADDR            equ 0fc3bh
ZXUNOREGDATA            equ 0fd3bh
MASTERCONF              equ 0
MASTERMAPPER            equ 1
FLASHSPI                equ 2
FLASHCS                 equ 3

; Selecciona un registro ZXUno de forma que los siguientes IN/OUTs a (C)
; se hagan en el registro deseado
select                  macro dir
                        ld bc,ZXUNOREGADDR
                        ld a,dir
                        out (c),a
                        inc b
                        endm

; Escribe "dato" en el registro ZXUno de direccion "dir"
wreg                    macro dir,dato
                        ld bc,ZXUNOREGADDR
                        ld a,dir
                        out (c),a
                        inc b
                        ld a,dato
                        out (c),a
                        endm

; Lee un byte desde el registro ZXUno cuya dirección es "dir" y lo almacena en "dest" (un registro de 8 bits)
rreg                    macro dir,dest
                        ld bc,ZXUNOREGADDR
                        ld a,dir
                        out (c),a
                        inc b
                        in dest,(c)
                        endm

;--------------------------------------------------------------------------

                        org 32768
Main                    di
                        ld sp,49151   ;stack fuera de la pagina de memoria que tocaremos

                        ; Borramos la pantalla shadow, ya que Open SE IV parece que no la borra
                        wreg MASTERMAPPER,7   ;paginamos la pantalla shadow
                        call BorraBloque

                        ; Elige uno, para probar
                        ;-------------------------------------------------  ROM de 48K con DIVMMC (se copia la interna)
                         wreg MASTERMAPPER,11    ;Donde estaría la ROM 3
                         ld hl,0
                         ld de,49152
                         ld bc,16384
                         ldir
                         ld bc,1ffdh
                         ld a,2
                         out (c),a
                         ld b,7fh
                         ld a,10h
                         out (c),a
                         call CopiaESXDOS
                         wreg MASTERCONF,010b   ;Fin del modo boot. La nueva ROM está en su sitio y activada. DIVMMC está activado.
                         jp 0                ;Vamonos a ella.
                        ;------------------------------------------------- ROM del +3 con DIVMMC
;                        call CopiaPlus3
;                        call CopiaESXDOS
;                        wreg MASTERCONF,2   ;Fin del modo boot. La nueva ROM está en su sitio y activada. DIVMMC está activado
;                        jp 0                ;Vamonos a ella.
                        ;------------------------------------------------- ROM SE IV con DIVMMC, sin NMI en DIVMMC
;                         call CopiaOpenSE
;                         ld bc,1ffdh
;                         ld a,2
;                         out (c),a
;                         ld b,7fh
;                         ld a,10h
;                         out (c),a
;                         call CopiaESXDOS
;                         wreg MASTERCONF,110b   ;Fin del modo boot. La nueva ROM está en su sitio y activada. DIVMMC está activado pero sin NMI
;                         jp 0                ;Vamonos a ella.
                        ;-------------------------------------------------

CopiaESXDOS             wreg MASTERMAPPER,16   ;Borramos los 128KB de la RAM del DIVMMC (bancos 16 a 23)
                        call BorraBloque
                        wreg MASTERMAPPER,17
                        call BorraBloque
                        wreg MASTERMAPPER,18
                        call BorraBloque
                        wreg MASTERMAPPER,19
                        call BorraBloque
                        wreg MASTERMAPPER,20
                        call BorraBloque
                        wreg MASTERMAPPER,21
                        call BorraBloque
                        wreg MASTERMAPPER,22
                        call BorraBloque
                        wreg MASTERMAPPER,23
                        call BorraBloque

                        wreg MASTERMAPPER,12  ;En los primeros 8KB del bloque 12 está la ROM del DIVMMC (ESXDOS)

                        wreg FLASHCS,0        ;linea CS de la flash a nivel bajo. Necesario antes de emitir comandos SPI
                        wreg FLASHSPI,3       ;comando de lectura de la flash
                        ld a,04h   ;
                        out (c),a  ; Dirección donde se encuentra
                        ld a,80h   ; la ROM del ESXDOS en la flash: 048000h
                        out (c),a  ;
                        ld a,00h   ;
                        out (c),a  ; A partir de aqui leemos secuencialmente

                        in a,(c)   ; Primera lectura que se descarta...
                        ld hl,49152
                        ld de,8192 ; son solo 8K a copiar
                        call BucCopia

                        wreg FLASHCS,1
                        ret

CopiaPlus3              wreg MASTERMAPPER,8   ;primera página de RAM que se convertirá en ROM (la 8)
                        wreg FLASHCS,0        ;linea CS de la flash a nivel bajo. Necesario antes de emitir comandos SPI
                        wreg FLASHSPI,3       ;comando de lectura de la flash
                        ld a,03h   ;
                        out (c),a  ; Dirección donde se encuentra
                        ld a,00h   ; la ROM en la flash: 030000h
                        out (c),a  ;
                        ld a,00h   ;
                        out (c),a  ; A partir de aqui leemos secuencialmente

                        in a,(c)   ; Primera lectura que se descarta...

                        call CopiaBloque   ;copia 16K de la flash a la página 8

                        wreg MASTERMAPPER,9
                        select FLASHSPI

                        call CopiaBloque   ;copia 16K de la flash a la página 9

                        wreg MASTERMAPPER,10
                        select FLASHSPI

                        call CopiaBloque   ;etc...

                        wreg MASTERMAPPER,11
                        select FLASHSPI

                        call CopiaBloque

                        wreg FLASHCS,1    ;Deseleccionar flash
                        ret


CopiaOpenSE             wreg MASTERMAPPER,11   ;Solo copiamos la ROM 1 de la SE Basic, como ROM 3.
                        wreg FLASHCS,0         ;linea CS de la flash a nivel bajo
                        wreg FLASHSPI,3        ;comando de lectura de la flash
                        ld a,04h   ;
                        out (c),a  ; Dirección donde se encuentra
                        ld a,40h   ; la ROM en la flash: 044000h
                        out (c),a  ;
                        ld a,00h   ;
                        out (c),a  ; A partir de aqui leemos secuencialmente

                        in a,(c)   ; Primera lectura que se descarta...

                        call CopiaBloque

                        wreg FLASHCS,1    ;Deseleccionar flash
                        ret

CopiaBloque             ld hl,49152
                        ld de,16384
BucCopia                in a,(c)        ;leemos de la flash...
                        ld (hl),a       ;...a memoria
                        inc hl
                        dec de
                        ld a,d
                        or e
                        jr nz,BucCopia
                        ret


BorraBloque             ld hl,49152
                        ld de,49153
                        ld bc,16383
                        ld (hl),l
                        ldir
                        ret

                        end Main
