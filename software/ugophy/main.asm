    DEVICE ZXSPECTRUM128
    org 24100
Start: 
    xor a
    call changeBank

    ld de, #4000
    ld bc, eop - page_buffer
    ld hl, page_buffer
    ldir

    call renderHeader
    ld hl, connecting_wifi
    call printZ64
    call initWifi
    
    ld de, path
    ld hl, server
    ld bc, port
    call openPage

    jp showPage

wSec: ld b, 50
wsLp  halt
      djnz wsLp

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

connecting_wifi db 13, ' Connecting to WiFi', 13, 0
open_lbl db 'Opening connection to ', 0

path    db '/unomenu'
        defs 247              
server  db 'nihirash.net'
        defs 58    
port    db '70'
        defs 5
        db 0
page_buffer equ $
    INCBIN "player.bin"
eop equ $
    SAVEBIN "ugoph.bin", Start, $ - Start
