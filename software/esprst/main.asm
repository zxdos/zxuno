; SPDX-FileCopyrightText: Copyright (C) 2019 Alexander Sharikhin
;
; SPDX-License-Identifier: GPL-3.0-or-later

    DEVICE ZXSPECTRUM48
    org #2000
Start:
    ld hl, init_txt
    call putS

    call uartBegin

    ld hl, ent : call putS
    ld hl, cmd_mode : call uartWriteStringZ
    call wait : call wait

    ld hl, configuring : call putS
    ld hl, cmd_uart : call uartWriteStringZ
    ld b, 255
rdWt:
    push bc : call uartRead : halt : pop bc : djnz rdWt

    ld hl, reseting : call putS
    ld hl, cmd_rst : call uartWriteStringZ
wrlp:
    call uartReadBlocking : call pushRing
    ld hl, response_er : call searchRing : cp 1 : jr nz, wrlp

    ld hl, setting_m : call putS
    ld hl, cmd_cwmode : call uartWriteStringZ
wtlp:
    call uartReadBlocking : call pushRing

    ld hl,response_ok : call searchRing
    cp 1 : jr nz, wtlp

    ld hl, receiv_info : call putS
    ld hl, cmd_info : call uartWriteStringZ
infoLp:
    call uartReadBlocking: push af : call putC : pop af : call pushRing
    ld hl, response_ok : call searchRing
    cp 1 : jr nz, infoLp

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
    call putC
    pop hl
    inc hl 
    jr putS

putC:
    cp 13
    ret s
    rst #10
    ret

init_txt    defb ".EspRst v.0.2 (c) Nihirash",13,"This tool resets esp-chip",13,0
fin         defb 13, "WiFi module ready to work!", 13, 0
ent         defb "Entering command mode", 13, 0
configuring defb "Configuring UART mode", 13, 0
reseting    defb "Reseting ESP-chip", 13, 0
setting_m   defb "WiFi chip to client mode", 13, 0
receiv_info defb "Getting ESP-chip version", 13, 0

cmd_mode    defb "+++", 0
cmd_uart    defb "AT+UART_DEF=115200,8,1,0,2", 13, 10, 0
cmd_rst     defb "AT+RST", 13, 10, 0
cmd_echo    defb "ATE0", 13, 10, 0
cmd_cwmode  defb "AT+CWMODE=1", 13, 10, 0
cmd_info    defb "AT+GMR", 13, 10, 0

response_ok defb "OK", 13, 10, 0
response_er defb "ready", 0

    SAVEBIN "esprst", Start, $ - Start
