UART_DATA_REG = #c6
UART_STAT_REG = #c7
UART_BYTE_RECIVED = #80
UART_BYTE_SENDING = #40

; Enable UART
; Cleaning all flags by reading UART regs
; Wastes AF and BC
uartBegin:
    ld bc, ZXUNO_ADDR : ld a, UART_STAT_REG : out (c), a
    ld bc, ZXUNO_REG : in A, (c)
    ld bc, ZXUNO_ADDR : ld a, UART_DATA_REG : out (c), a
    ld bc, ZXUNO_REG : in A, (c)
    ret

; Blocking read one byte
uartReadBlocking:
    call uartRead
    push af : ld a, 1 : cp b : jr z, urb : pop af
    jp uartReadBlocking
urb: 
    pop af
    ret

; Write single byte to UART
; A - byte to write
; BC will be wasted
uartWriteByte:
    push af
    ld bc, ZXUNO_ADDR : ld a, UART_STAT_REG : out (c), a
waitWriteReady:
    ld bc, ZXUNO_REG : in A, (c) : and UART_BYTE_RECIVED
    jr nz,  is_recvF
checkSent:
    ld bc, ZXUNO_REG : in A, (c) : and UART_BYTE_SENDING
    jr nz, checkSent

    ld bc, ZXUNO_ADDR : ld a, UART_DATA_REG : out (c), a

    ld bc, ZXUNO_REG : pop af : out (c), a
    ret
is_recvF:
    push af : push hl
    
    ld hl, is_recv : ld a, 1 : ld (hl), a 
    
    pop hl : pop af
    jr checkSent

; Is data avail in UART
; NZ - Data Presents
; Z - Data absent
uartAvail:
    ld a, (is_recv) : and 1 : ret nz
    ld a, (poked_byte) : and 1 : ret nz

    call uartRead

    push af : ld a, b : and 1 : jr z, noneData : pop af

    push af
    ld hl, byte_buff : ld (hl), a : ld hl, poked_byte : ld a, 1 : ld (hl), a
    pop af

    ld b, a : ld a, 1 : or a : ld a, b
    ret
noneData:
    pop bc : xor a
    ret

; Read byte from UART
; A: byte
; B:
;     1 - Was read
;     0 - Nothing to read
uartRead:
    ld a, (poked_byte) : and 1 : jr nz, retBuff

    ld a, (is_recv) : and 1 : jr nz, recvRet

    ld bc, ZXUNO_ADDR : ld a, UART_STAT_REG : out (c), a
    ld bc, ZXUNO_REG : in a, (c) : and UART_BYTE_RECIVED
    jr nz, retReadByte

    ld b, 0
    ret

retReadByte:
    xor a : ld (poked_byte), a : ld (is_recv), a

    ld bc, ZXUNO_ADDR : ld a, UART_DATA_REG : out (c), a
    ld bc, ZXUNO_REG : in a, (c)

    ld b, 1
    ret

recvRet:
    ld bc, ZXUNO_ADDR : ld a,  UART_DATA_REG : out (c),a

    ld bc, ZXUNO_REG : in a, (c)
    ld hl, is_recv : ld (hl), 0
    ld hl, poked_byte : ld (hl), 0
    
    ld b, 1
    ret

retBuff
    ld a, 0 : ld (poked_byte), a : ld a, (byte_buff)
    ld b, 1
    ret

poked_byte defb 0
byte_buff defb 0
is_recv defb 0