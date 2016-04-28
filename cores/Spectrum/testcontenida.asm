                org 0
                di
                ld sp,32768
                ld hl,Codigo
                ld de,16384
                ld bc,LCodigo
Espera1:        in a,(255)
                cp 255
                jr nz,Espera1
Espera2:        in a,(255)
                cp 255
                jr z,Espera2
                ldir
Otra:           call 16384
                jp Otra

Codigo:         in a,(255)
                cp 255
                jr z,Codigo
                out (254),a
                out (254),a
                nop
                out (254),a
                out (254),a
                nop
                ld bc,40feh
                out (c),a
                out (c),a
                out (c),a
                out (c),a
                out (c),a
                out (c),a
                dec c
                out (c),a
                out (c),a
                out (c),a
                out (c),a
                out (c),a
                out (c),a
                ret
LCodigo         equ $-Codigo

                end
