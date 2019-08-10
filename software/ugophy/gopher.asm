; hl - server
; de - path
; bc - port
openPage:
    push hl : push de : push bc

    xor a : call changeBank

    ex hl, de : ld de, hist : ld bc, 322 : ldir

    ld hl, page_buffer : xor a : ld (hl), a :  ld de, page_buffer + 1 : ld bc, #ffff - page_buffer - 1 : ldir

    pop bc : pop de : pop hl

    call makeRequest

    xor a : call changeBank

    ld hl, page_buffer : call loadData
    
    xor a : ld (show_offset), a
    inc a : ld (cursor_pos), a
    ret

; HL - domain stringZ
; DE - path stringZ
; BC - port stringZ
makeRequest:
    push de : push bc : push hl

    ld hl, downloading_msg : call showTypePrint

    xor a : call changeBank

; Open TCP connection
    ld hl, cmd_open1 : call uartWriteStringZ
    pop hl : call uartWriteStringZ
    ld hl, cmd_open2 : call uartWriteStringZ
    pop hl : call uartWriteStringZ
    ld hl, cmd_open3 : call okErrCmd

    pop hl : cp 1 : jp nz, reqErr : push hl

; Send request
    ld hl, cmd_send : call uartWriteStringZ
    pop hl : push hl
    call getStringLength 
    push bc : pop hl : inc hl : inc hl :  call B2D16

    ld hl, B2DBUF : call SkipWhitespace : call uartWriteStringZ  
    ld hl, crlf : call okErrCmd  

    pop hl : cp 1 : jp nz, reqErr : push hl
wPrmt:
    call uartReadBlocking : call pushRing
    ld hl, send_prompt : call searchRing : cp 1 : jr nz, wPrmt
    
    pop hl : call uartWriteStringZ
    
    ld hl, crlf : call uartWriteStringZ : ld a, 1 : ld (connectionOpen), a
    ret

reqErr: 
    pop hl  ; Now we won't back to same address
    
    ld hl, connectionError : call showTypePrint : call wSec 
    xor a : ld (connectionOpen), a

    call initWifi ; Trying reset ESP and continue work 
    jp historyBack ; Let's try back home on one URL :)

; Load data to ram via gopher
; HL - data pointer
; In data_recv downloaded volume
loadData:
    ld (data_pointer), hl 
    ld hl, 0 : ld (data_recv), hl
lpLoop:
    call getPacket
    
    ld a, (connectionOpen) : and a : jp z, ldEnd 

    ld bc, (bytes_avail) : ld de, (data_pointer) : ld hl, output_buffer : ldir
    ld hl, (data_pointer) : ld de, (bytes_avail) : push de : add hl, de : ld (data_pointer), hl : pop de
    ld hl, (data_recv) : add hl, de : ld (data_recv), hl

    jp lpLoop

ldEnd 
    xor a : ld (data_pointer), a
    ret

; Download file via gopher
; HL - filename
downloadData:
    ld b, FMODE_CREATE : call fopen : ld (fstream), a
dwnLp:
    call getPacket : ld a, (connectionOpen) : and a : jp z, dwnEnd
    
    ld bc, (bytes_avail) : ld hl, output_buffer : ld a, (fstream) : call fwrite
    
    ld a, (fstream) : call fsync
    jp dwnLp
dwnEnd:
    ld a, (fstream) : call fclose
    ret

openURI:
    call cleanIBuff 
    
    ld b, 19: ld c, 0 :call gotoXY : ld hl, cleanLine : call printZ64
    ld b, 19: ld c, 0 : call gotoXY : ld hl, hostTxt : call printZ64

    call input

    ld a, (iBuff) : or a : jp z, backToPage

    ld b, 19 : ld c, 0 : call gotoXY : ld hl, cleanLine : call printZ64

    ld hl, iBuff : ld de, d_host : ld bc, 65 : ldir

    ld hl, d_host : ld de, d_path : ld bc, d_port : call openPage
    
    jp showPage
    

data_pointer    defw #4000
data_recv       defw 0
fstream         defb 0 

closed_callback
    xor a
    ld (connectionOpen), a
    ret

hostTxt   db 'Enter host: ', 0

d_path    db '/'
          defs 254
d_host    defs 70
d_port    db '70'
          defs 5

hist            ds 322
connectionOpen  db 0
downloading_msg db 'Downloading...', 0

connectionError db "Issue with making request - trying get back", 0
