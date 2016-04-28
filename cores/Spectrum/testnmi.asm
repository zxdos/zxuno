                    org 28000
Main                di
                    ld bc,7ffdh
                    ld a,16+6   ;pagina 6 de RAM
                    out (c),a
                    ld hl,Rom
                    ld de,0c000h    ;Copiar ROM NMI a esta dirección
                    ld bc,LRom
                    ldir
                    ld bc,7ffdh
                    ld a,16     ;Restablecemos página 0 de RAM
                    out (c),a
                    ei
                    ret

Rom                 ;Esto se ejecuta a partir de C000h.
                    ;Guardar puntero de pila, establecer pila privada y guardar registros
                    ld (OldSP-Rom+0c000h),sp
                    ld sp,Stack-Rom+0c000h
                    push af
                    push bc
                    push de
                    push hl

                    ;Salvaguarda zona de atributos
                    ld hl,22528
                    ld de,Buffer-Rom+0c000h
                    ld bc,768
                    ldir

                    ;Pon el banner de PAUSE
                    ld hl,Banner-Rom+0c000h
                    ld de,22528+32*8+1
                    ld b,7
BucBanner           push bc
                    ld bc,29
                    ldir
                    inc de
                    inc de
                    inc de
                    pop bc
                    djnz BucBanner

                    ;Espera una tecla para terminar pausa
BucWaitKey          xor a
                    in a,(254)
                    and 31
                    cp 31
                    jr z,BucWaitKey

                    ;Restaura zona de atributos
                    ld hl,Buffer-Rom+0c000h
                    ld de,22528
                    ld bc,768
                    ldir

                    ;Restablecer registros y puntero de pila anterior
                    pop hl
                    pop de
                    pop bc
                    pop af
                    ld sp,(OldSP-Rom+0c000h)

                    ;Saltar a direccion de fin de NMI
                    jp 0069h

Banner              db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000
                    db 000,255,255,255,000,000,000,255,255,255,000,000,255,000,000,000,255,000,000,255,255,255,000,000,255,255,255,255,000
                    db 000,255,000,000,255,000,255,000,000,000,255,000,255,000,000,000,255,000,255,000,000,000,000,000,255,000,000,000,000
                    db 000,255,255,255,000,000,255,255,255,255,255,000,255,000,000,000,255,000,000,255,255,255,000,000,255,255,255,255,000
                    db 000,255,000,000,000,000,255,000,000,000,255,000,255,000,000,000,255,000,000,000,000,000,255,000,255,000,000,000,000
                    db 000,255,000,000,000,000,255,000,000,000,255,000,000,255,255,255,000,000,000,255,255,255,000,000,255,255,255,255,000
                    db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000

OldSP               dw 0

                    ds 16   ;16 bytes de pila
Stack               equ $

Buffer              equ $

LRom                equ $-Rom
                    end Main

