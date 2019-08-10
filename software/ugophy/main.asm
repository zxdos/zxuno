    DEVICE ZXSPECTRUM128
    org 24100
Start: 
    di

    call checkHighMem : jp nz, noMem
    
    xor a : out (#fe), a : call changeBank

    ld sp, #5aff

    ld de, #4000 : ld bc, eop - player : ld hl, player : ldir

    ei

    call renderHeader
    ld hl, connecting_wifi : call printZ64
    call initWifi
    
    call wSec

    ld de, path : ld hl, server : ld bc, port : call openPage

    jp showPage

noMem:
    ld hl, no128k
nmLp:
    push hl
    ld a, (hl)
    and a : jr z, $
    rst #10
    pop hl
    inc hl
    jp nmLp


wSec: ld b, 50
wsLp  halt : djnz wsLp

    include "tscreen.asm"
    include "keyboard.asm"
    include "utils.asm"
    include "wifi.asm"
    include "gopher.asm"
    include "render.asm"
    include "textrender.asm"
    include "uart.asm"
    include "ring.asm"
    include "esxdos.asm"


connecting_wifi db 13, 'Connecting to WiFi', 13, 0
open_lbl db 'Opening connection to ', 0

path    db '/ncmenu'
        defs 248              
server  db 'nihirash.net'
        defs 58    
port    db '70'
        defs 5
        db 0
page_buffer equ $
    display "PAGE buffer:", $
no128k  db 13, "You're started in 48k mode!", 13
        db     "Current version require full", 13 
        db     "128K memory access", 13
        db     "System halted!", 0
player 
    DISPLAY "Player starts:" , $       
    include "vtpl.asm"
    DISPLAY "Player ends: ", $
    ENT
eop equ $
    SAVEBIN "ugoph.bin", Start, $ - Start
    SAVETAP "ugoph.tap", Start