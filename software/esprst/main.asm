    DEVICE ZXSPECTRUM48
    org #2000
Start:
    ld hl, init_txt
    call putS

    call uartBegin

    ld hl, cmd_mode
    call uartWriteStringZ
    
    call wait

    ld hl, cmd_rst
    call uartWriteStringZ
    
    call wait
    call wait

    ld hl, cmd_at
    call uartWriteStringZ
wtlp:
    call uartReadBlocking
    call pushRing

    ld hl,response_ok
    call searchRing
    cp 1
    jr nz, wtlp

    ld hl, fin
    call putS

    ret

wait:
    ld b, 50
wlp:
    halt
    djnz wlp
    ret

    include "uart.asm"
    include "ring.asm"

putS:
    ld a, (hl)
    or 0
    ret z
    push hl
    rst #10
    pop hl
    inc hl 
    jr putS

init_txt    defb ".EspRst v.0.1 (c) Nihirash",13,"This tool resets esp-chip",13,0

fin         defb "WiFi module ready to work", 13, 0

cmd_mode    defb "+++", 0
cmd_rst     defb "AT+RST", 13, 10, 0
cmd_at      defb "AT", 13, 10, 0

response_ok defb "OK", 13, 10, 0

    SAVEBIN "esprst", Start, $ - Start