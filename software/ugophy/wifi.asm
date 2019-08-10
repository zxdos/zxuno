; Initialize WiFi chip and connect to WiFi
initWifi:
    call setNoTurboMode : call loadWiFiConfig : call uartBegin
    
    ld hl, cmd_plus : call uartWriteStringZ
    ld b,#ff
wlp:
    push bc : ld b, #ff : djnz $ : pop bc : djnz wlp
    
    ld hl, cmd_rst : call uartWriteStringZ
rstLp:
    call uartReadBlocking : call pushRing

    ld hl, response_rdy : call searchRing : cp 1 : jr nz, rstLp     
; Disable ECHO. BTW Basic UART test


    ld hl, cmd_at : call okErrCmd : and 1 : jr z, errInit
; Lets disconnect from last AP    
    ld hl, cmd_cwqap : call okErrCmd : and 1 : jr z, errInit
; Single connection mode 
    ld hl, cmd_cmux : call okErrCmd : and 1 : jr z, errInit
; FTP enables this info? We doesn't need it :-)
    ld hl, cmd_inf_off : call okErrCmd : and 1 : jr z, errInit

; Access Point connection
    ld hl, cmd_cwjap1 : call uartWriteStringZ : ld hl, ssid : call uartWriteStringZ : ld hl, cmd_cwjap2 : call uartWriteStringZ
    ld hl, pass :call uartWriteStringZ : ld hl, cmd_cwjap3 : call okErrCmd

    and 1 :jr z, errInit
    
    ld hl, log_ok : call putStringZ
    call setTurbo4Mode
    ret
errInit
    ld hl, log_err : call putStringZ
    jr $


; Send AT-command and wait for result. 
; HL - Z-terminated AT-command(with CR/LF)
; A:
;    1 - Success
;    0 - Failed
okErrCmd: 
    call uartWriteStringZ
okErrCmdLp:
    call uartReadBlocking : call pushRing
    
    ld hl, response_ok   : call searchRing : cp 1 : jr z, okErrOk
    ld hl, response_err  : call searchRing : cp 1 : jr z, okErrErr
    ld hl, response_fail : call searchRing : cp 1 : jr z, okErrErr
    
    jp okErrCmdLp
okErrOk
    ld a, 1
    ret
okErrErr
    ld a, 0
    ret

; Gets packet from network
; packet will be in var 'output_buffer'
; received packet size in var 'bytes_avail'
;
; If connection was closed it calls 'closed_callback'
getPacket
	call uartReadBlocking : call pushRing

	ld hl, closed : call searchRing : cp 1 : jp z, closed_callback
	ld hl, ipd : call searchRing : cp 1 : jr nz, getPacket

	call count_ipd_lenght : ld (bytes_avail), hl 
    push hl : pop bc
    
    ld hl, output_buffer
readp:
	push bc : push hl
	call uartReadBlocking
	pop hl
	ld (hl), a 
	pop bc

	dec bc : inc hl 
    
    ld a, b : or c : jr nz, readp
	
    ld hl, (bytes_avail)
	ret

count_ipd_lenght
		ld hl,0			; count lenght
cil1	push hl : call uartReadBlocking : push af : call pushRing : pop af : pop hl
		cp      ':' : ret z
		sub 0x30 : ld c,l : ld b,h : add hl,hl : add hl,hl : add hl,bc : add hl,hl : ld c,a : ld b,0 : add hl,bc
		jr      cil1

; HL - z-string to hostname or ip
; DE - z-string to port
startTcp:
    push de
    push hl
    ld hl, cmd_open1 : call uartWriteStringZ
    pop hl : call uartWriteStringZ 
    ld hl, cmd_open2 : call uartWriteStringZ
    pop de : call uartWriteStringZ 
    ld hl, cmd_open3 : call okErrCmd
    ret

; Returns:
;  A: 1 - Success
;     0 - Failed
sendByte:
    push af 
    ld hl, cmd_send_b : call okErrCmd
    cp 1 : jr nz, sbErr
sbLp
    call uartReadBlocking 
    ld hl, send_prompt : call searchRing : cp 1 : jr nz, sbLp
    pop af

    ld (sbyte_buff), a : call okErrCmd
    ret
sbErr:
    pop af
    ld a, 0 
    ret

loadWiFiConfig:
    ld b, FMODE_READ : ld hl, conf_file : call fopen
    push af : ld hl, ssid : ld bc, 160 : call fread : pop af
    call fclose
    ret
    
cmd_plus    defb "+++", 0
cmd_rst     defb "AT+RST",13, 10, 0
cmd_at      defb "ATE0", 13, 10, 0                  ; Disable echo - less to parse
cmd_mode    defb "AT+CWMODE_DEF=1",13,10,0	        ; Client mode
cmd_cmux    defb "AT+CIPMUX=0",13,10,0              ; Single connection mode
cmd_cwqap   defb "AT+CWQAP",13,10,0		            ; Disconnect from AP
cmd_inf_off defb "AT+CIPDINFO=0",13,10,0            ; doesn't send me info about remote port and ip

cmd_cwjap1  defb  "AT+CWJAP_CUR=", #22,0        ;Connect to AP. Send this -> SSID
cmd_cwjap2  defb #22,',',#22,0                  ; -> This -> Password
cmd_cwjap3  defb #22, 13, 10, 0                 ; -> And this

cmd_open1   defb "AT+CIPSTART=", #22, "TCP", #22, ",", #22, 0
cmd_open2   defb #22, ",", 0
cmd_open3   defb 13, 10, 0
cmd_send    defb "AT+CIPSEND=", 0
cmd_close   defb "AT+CIPCLOSE",13,10,0
cmd_send_b  defb "AT+CIPSEND=1", 13, 10,0
closed			defb 	"CLOSED", 13, 10, 0
ipd			defb 13, 10, "+IPD,", 0
crlf        defb 13,10, 0

response_rdy    defb 'ready', 0
response_ok     defb 'OK', 13, 10, 0      ; Sucessful operation
response_err    defb 13,10,'ERROR',13,10,0      ; Failed operation
response_fail   defb 13,10,'FAIL',13,10,0       ; Failed connection to WiFi. For us same as ERROR

log_err defb 'Failed connect to WiFi!',13, 0
log_ok  defb 'WiFi connected!', 13, 0

ssid        defs 80
pass        defs 80

bytes_avail	  defw 0
sbyte_buff     defb 0, 0 

send_prompt defb ">",0
output_buffer defs 2048 ; buffer for downloading data

; WiFi configuration
conf_file defb "/sys/config/iw.cfg",0
