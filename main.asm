    DEVICE ZXSPECTRUM48
    org 24100
Start: 
    jp run
    ds #21d9 
run:
    call renderHeader
    ld hl, connecting_wifi
    call printZ64
    call initWifi
    jp showPage
wSec: ld b, 50
wsLp  halt
      djnz wsLp

    ;include "screen64.asm"
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

path    db '/'
        defs 254              
server  db 'nihirash.net'
        defs 58    
port    db '70'
        defs 5

page_buffer 
    display "Page buffer starts here"
    display $
    incbin "index.pg"
    db 0
eop equ $
    SAVEBIN "ugoph.bin", Start, eop - Start
