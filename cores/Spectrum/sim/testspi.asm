ZXUNOADDR           equ 0fc3bh
ZXUNODATA           equ 0fd3bh
SPIPORT             equ 02h
SPICS               equ 03h

                    org 0

Main                proc
                    di
                    ld sp,512
                    ld hl,256

                    call CS0

                    dec b
                    ld a,SPIPORT
                    out (c),a
                    inc b

                    in a,(c)      ;la primera se descarta
                    in a,(c)
                    in d,(c)
                    in e,(c)
                    in b,(c)

                    ld (hl),a
                    inc hl
                    ld (hl),d
                    inc hl
                    ld (hl),e
                    inc hl
                    ld (hl),b
                    
                    call CS1

                    halt
                    endp

CS0                 proc
                    ld bc,ZXUNOADDR
                    ld a,SPICS
                    out (c),a
                    inc b
                    xor a
                    out (c),a
                    ret
                    endp

CS1                 proc
                    ld bc,ZXUNOADDR
                    ld a,SPICS
                    out (c),a
                    inc b
                    ld a,1
                    out (c),a
                    ret
                    endp

                    org 255
                    db 0
