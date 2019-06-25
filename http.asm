; Some parts taken from ZiFi sources  

; Performs HTTP-get request
; First packet will be in var 'output_buffer'
; received packet size in var 'bytes_avail'
;
; HL - url includes http:// header
httpGet	ld de,cmd_conn2site_adr
pu1		ld a,(hl)	; http://
		inc hl
		cp "/"
		jr nz,pu1
		inc hl ; /
		ld bc,"//"
		ld (host_url+1),hl
		call find_copy_char
		inc hl
		ld (file_url+1),hl
		
create_link1	ld hl,create_link_suffix
		ld bc,7
		ldir
		ld hl,modem_command

		ld (hl),"G"
		inc hl
		ld (hl),"E"
		inc hl
		ld (hl),"T"
		inc hl
		ld (hl)," "
		inc hl
		ld (hl),"/"
		inc hl

		ex hl,de
file_url	ld hl,0
		ld bc,#0d0a
		call find_copy_char
		ld hl,http_part1
		ld bc,http_part2-http_part1
		ldir
host_url	ld hl,0
		ld bc,"//"
		call find_copy_char
		ld a,13
		ld (de),a
		inc de
		ld a,10
		ld (de),a
		inc de
		ld hl,http_part2
		ld bc,http_part3-http_part2
		ldir
		ex de,hl
		ld de,modem_command
		or a
		sbc hl,de
		ld de,url_len
		ld bc,-1000
		call Num1
		cp "0"
		jr z,1f
		ld (de),a
		inc de
1		ld bc,-100
		call Num1
		ld (de),a
		inc de
1		ld c,-10
		call Num1
		ld (de),a
		inc de
1		ld c,-1
		call Num1
		ld (de),a
		inc de
		ld a,#0d
		ld (de),a
		inc de
		ld a,#0a
		ld (de),a
		inc de
		xor a
		ld (de),a
		jr firstPacket

Num1:		ld	a,'0'-1
Num2:		inc	a
		add	hl,bc
		jr	c,Num2
		sbc	hl,bc
		ret
		
find_copy_char	ld a,(hl)
		cp c
		ret z
		cp b
		ret z
		ld (de),a
		inc hl
		inc de
		jr find_copy_char

firstPacket:
	call performRequest

skipHeaders:
	ld de, output_buffer
	ld bc, 0
shLp:
	ld a, (de)
	push de
	push bc
	call pushRing
	ld hl, headers_end
	call searchRing
	pop bc
	pop de
	inc de
	inc bc
	cp 1
	jr nz, shLp
    ld hl, (bytes_avail)
    sbc hl, bc
    ld (bytes_avail), hl
    push hl
    pop bc
    push de
    ld de, output_buffer
    pop hl
    ldir
	ret


performRequest: 
    ld hl, cmd_conn2site
    call okErrCmd
    cp 1
    jr z, zg_ok
    ld hl, cmd_close
    call okErrCmd
    jr performRequest
zg_ok:
    ld hl, cmd_cipsend
    call okErrCmd
guLp:
    call uartReadBlocking
    call pushRing
    ld hl, send_prompt
    call searchRing
    cp 1
    jr nz, guLp
    ld hl, modem_command
    call okErrCmd
	jp getPacket

create_link_suffix
		db    #22,",80",13,10,0
	display $
modem_command		ds 256+128
	display $
http_part1	db  " HTTP/1.0",13,10 ;size=123
			db 	  "Host: "
http_part2	db    "User-Agent: ZX Uno(Z80 CPU)",13,10    ; show off ;)
			db    "Accept: */*",13,10
			db    "Connection: close",13,10,13,10
http_part3

cmd_conn2site		defb    "AT+CIPSTART=", 0x22,"TCP",0x22,",",0x22		
cmd_conn2site_adr	ds #40	

headers_end		defb 13,10,13,10,0
cmd_cipsend		defb    "AT+CIPSEND="
url_len			defs 6
    			defb 0
