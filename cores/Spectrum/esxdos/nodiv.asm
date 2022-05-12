ZXUNOADDR             equ 0FC3Bh
ZXUNODATA             equ 0FD3Bh
MAPPER128K            equ 7FFDh
MAPPERPLUS3           equ 1FFDh
MASTERCONF            equ 0

                      org 2000h
                      di
                      ld hl,Programa
                      ld de,8000h
                      ld bc,LongPrograma
                      ldir
                      jp 8000h

Programa              ld bc,ZXUNOADDR
                      ld a,MASTERCONF
                      out (c),a
                      inc b
                      ld a,10010100b
                      out (c),a
                      
                      ld bc,MAPPERPLUS3
                      xor a
                      out (c),a
                      ld bc,MAPPER128K
                      out (c),a
                      
                      jp 0
                      
LongPrograma          equ $-Programa

                      end
                                            
