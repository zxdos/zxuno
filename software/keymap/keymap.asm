; API de ESXDOS.
include "esxdos.inc"
include "errors.inc"

; KEYMAP. Una utilidad para cargar un mapa de teclado en el ZX-Uno
; Necesita sólamente un nombre de fichero de mapa, que debe estar
; guardado en /SYS/KEYMAPS dentro de la tarjeta SD donde esté ESXDOS.

;Para ensamblar con PASMO como archivo binario (no TAP)

ZXUNOADDR           equ 0fc3bh
ZXUNODATA           equ 0fd3bh

                    org 2000h  ;comienzo de la ejecución de los comandos ESXDOS.

Main                proc
                    ld a,h
                    or l
                    jr z,PrintUso  ;si no se ha especificado nombre de fichero, imprimir uso
                    call RecogerNFile

                    call ReadMap
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


ReadMap             proc
                    xor a
                    rst 08h
                    db M_GETSETDRV  ;A = unidad actual
                    ld b,FA_READ    ;B = modo de apertura
                    ld hl,MapFile   ;HL = Puntero al nombre del fichero (ASCIIZ)
                    rst 08h
                    db F_OPEN
                    ret c   ;Volver si hay error
                    ld (FHandle),a

                    ld bc,ZXUNOADDR
                    ld a,7
                    out (c),a   ;select KEYMAP register

                    ld b,4      ;4 chunks of 4096 bytes each to load
BucReadMapFromFile  push bc

                    ld bc,4096
                    ld hl,Buffer
                    ld a,(FHandle)
                    rst 08h
                    db F_READ
                    jr c,PrematureEnd  ;si error, fin de lectura

                    ld hl,Buffer
                    ld bc,ZXUNODATA
                    ld de,4096
BucWriteMapToFPGA   ld a,(hl)
                    out (c),a
                    inc hl
                    dec de
                    ld a,d
                    or e
                    jr nz,BucWriteMapToFPGA

                    pop bc
                    djnz BucReadMapFromFile

                    jr FinReadMap

PrematureEnd        pop bc
                    push af
                    ld a,(FHandle)
                    rst 08h
                    db F_CLOSE
                    pop af
                    ret

FinReadMap          ld a,(FHandle)
                    rst 08h
                    db F_CLOSE
                    or a   ;Volver sin errores a ESXDOS
                    ret
                    endp

                    ;   01234567890123456789012345678901
Uso                 db " KEYMAP file",13,13
                    db "Loads the specified keymap from",13
                    db "/SYS/KEYMAPS and enables it.",13,0

FHandle             db 0

Buffer              ds 4096  ;4KB para buffer de lectura
MapFile             db "/SYS/KEYMAPS/"
BufferNFich         equ $   ;resto de la RAM para el nombre del fichero