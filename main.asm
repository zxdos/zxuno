    DEVICE ZXSPECTRUM48
    org 24100
Start:
    call renderHeader
    call initWifi
    jp showPage
wSec: ld b, 50
wsLp  halt
      djnz wsLp

    include "screen64.asm"
    include "keyboard.asm"
    include "utils.asm"
    include "wifi.asm"
    include "gopher.asm"
    include "render.asm"
    include "textrender.asm"
    include "uart.asm"
    include "ring.asm"
    include "esxdos.asm"

open_lbl db 'Opening connection to ', 0

path    db '/'
        defs 69              
server  db 'nihirash.net'
        defs 58    
port    db '70'
        defs 5

data_buff   defs 255
page_buffer 
    incbin "index.pg"
    db 0
eop equ $
    SAVEBIN "ugoph.bin", Start, eop-Start
