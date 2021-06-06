; API de ESXDOS.
include "esxdos.inc"
include "errors.inc"

; PLAYRMOV : un comando para ESXDOS 0.8.5 que permite reproducir videos en formato
; Radastaniano (ficheros .RDM) usando DIVMMC en el ZX-Uno.

; Video: secuencia lineal de frames.
; Cada frame: 6144 bytes con el bitmap en el formato radastaniano +
;             16 bytes para la paleta (entradas 0-15)

; Version 0.2 : arreglado el problema del stack. Gracias a Miguel Ângelo Guerreiro
;               Se borra la pantalla al terminar la reproducción
; Version 0.1 : necesita que el stack esté por debajo de 49152
;              (ej. CLEAR 49151 antes de ejecutar el comando)

;Para ensamblar con PASMO como archivo binario (no TAP)

BORDERCLR           equ 23624
PAPERCOLOR          equ 23693
ULAPLUSADDR         equ 0bf3bh
ULAPLUSDATA         equ 0ff3bh
ZXUNOADDR           equ 0fc3bh
ZXUNODATA           equ 0fd3bh
RADASCTRL           equ 40h
BANKM               equ 7ffdh
PILA                equ 3deah   ;valor sugerido por Miguel Ângelo para poner la pila en el área de comando

                    org 2000h  ;comienzo de la ejecución de los comandos ESXDOS.

Main                proc
                    ld a,h
                    or l
                    jr z,PrintUso  ;si no se ha especificado nombre de fichero, imprimir uso
                    call RecogerNFile

                    di
                    ld (BackupSP),sp
                    ld sp,PILA
                    ei
                    call PlayFichero
                    call Cls

                    ld sp,(BackupSP)
                    ret

PrintUso            ld hl,Uso
BucPrintMsg         ld a,(hl)
                    or a
                    ret z
                    rst 10h
                    inc hl
                    jr BucPrintMsg
                    endp


RecogerNFile        proc   ;HL apunta a los argumentos (nombre del fichero)
                    ld de,BufferNFich
CheckCaracter       ld a,(hl)
                    or a
                    jr z,FinRecoger
                    cp " "
                    jr z,FinRecoger
                    cp ":"
                    jr z,FinRecoger
                    cp 13
                    jr z,FinRecoger
                    ldi
                    jr CheckCaracter
FinRecoger          xor a
                    ld (de),a
                    inc de   ;DE queda apuntando al buffer este que se necesita en OPEN, no sé pa qué.
                    ret
                    endp


PlayFichero         proc
                    xor a
                    rst 08h
                    db M_GETSETDRV  ;A = unidad actual
                    ld b,FA_READ    ;B = modo de apertura
                    ld hl,BufferNFich   ;HL = Puntero al nombre del fichero (ASCIIZ)
                    rst 08h
                    db F_OPEN
                    ret c   ;Volver si hay error
                    ld (FHandle),a

                    call SetupVideoMemory

BucPlayVideo        ld hl,0c000h
                    ld bc,6144+16   ;Bitmap + paleta
                    ld a,(FHandle)
                    rst 08h
                    db F_READ
                    jr c,FinPlay  ;si error, fin de lectura
                    ld a,b
                    or c
                    jr z,FinPlay  ;si no hay más que leer, fin de lectura

                    call SwitchScreens
                    ld bc,7ffeh
                    in a,(c)   ;Detectar si se ha pulsado SPACE
                    and 1
                    jr z,FinPlay

                    jr BucPlayVideo

FinPlay             ld a,(FHandle)
                    rst 08h
                    db F_CLOSE

                    call RestoreVideoMemory

                    or a   ;Volver sin errores a ESXDOS
                    ret
                    endp


SetupVideoMemory    proc
                    di

                    ld bc,ZXUNOADDR
                    ld a,RADASCTRL
                    out (c),a
                    ld bc,ZXUNODATA
                    ld a,3   ;modo radastaniano
                    out (c),a

                    ld bc,BANKM
                    ld a,00010111b   ;banco 7, pantalla normal, ROM 3
                    ld (Banco),a
                    out (c),a
                    ei
                    ret
                    endp


RestoreVideoMemory  proc
                    di
                    ld bc,BANKM
                    ld a,00010000b   ;banco 0, pantalla normal, ROM 3
                    out (c),a

                    ld bc,ZXUNOADDR
                    ld a,RADASCTRL
                    out (c),a
                    ld bc,ZXUNODATA
                    ld a,0   ;modo ULA normal
                    out (c),a

                    ei
                    ret
                    endp


SwitchScreens       proc
                    halt

                    ld ix,0c000h + 6144   ;apuntamos a donde está la paleta
                    ld d,0      ;D es el indice a la paleta que se está escribiendo
                    ld h,0ffh   ;H contiene el color más oscuro, para poner en el borde después
                    ld l,0      ;L contiene el índice al color más oscuro
BucUpdPaleta        ld bc,ULAPLUSADDR
                    out (c),d
                    ld b,0ffh
                    ld a,(ix)
                    out (c),a
                    ld a,d
                    cp 8    ;Solo hacemos el test para los indices 0-7
                    jr nc,NoTestColorOscuro
                    ld a,(ix)
                    cp h
                    jr nc,NoTestColorOscuro
                    ld h,a
                    ld l,d
NoTestColorOscuro   inc ix
                    inc d
                    ld a,16
                    cp d
                    jr nz,BucUpdPaleta

                    ld a,l
                    out (254),a     ;El borde lo más oscuro posible

                    ld a,(Banco)
                    xor 00001010b   ;conmutamos de la pantalla normal a la shadow y de la 7 a la 5
                    ld (Banco),a
                    ld bc,BANKM
                    out (c),a
                    ret
                    endp


Cls                 proc
                    ld a,(BORDERCLR)
                    sra a
                    sra a
                    sra a
                    and 7
                    out (254),a
                    ld hl,16384
                    ld de,16385
                    ld bc,6143
                    ld (hl),l
                    ldir
                    inc hl
                    inc de
                    ld bc,767
                    ld a,(PAPERCOLOR)
                    ld (hl),a
                    ldir
                    ret
                    endp


                    ;   01234567890123456789012345678901
Uso                 db " playrmov moviefile.rdm",13,13
                    db "Plays a video file encoded for",13
                    db "the ",34,"Radastan",34," video mode.",13,0

FHandle             db 0
Banco               db 0
BackupSP            dw 0

BufferNFich         equ $   ;resto de la RAM para el nombre del fichero