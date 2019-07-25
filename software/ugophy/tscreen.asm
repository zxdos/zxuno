; Timex screen routines

showCursor:
hideCursor:
    call showType
    ld a, (cursor_pos)
    ld d, a
inverseLine: 
	ld e, 0
	ld b, 64
ilp
	push bc
	push de
	call findAddr
    ld a, 7
    call changeBank
	
	ld b, 8
iCLP:	
	ld a, (de)
	xor #ff
	ld (de), a
	inc d
	djnz iCLP
	pop de
	inc e
	pop bc
	djnz ilp

    ;xor a
    ;call changeBank
	
    ret

gotoXY:
    ld (coords), bc
    ret

mvCR:
	ld hl, (coords)
	inc h
	ld l, 0
	ld (coords), hl
	cp 24
	ret c
	ld hl, 0
	ld (coords), hl
	ret	

; A - char
putC:
	cp 13
	jr z, mvCR

	sub 32
    ld b, a
    
    ld de, (coords)
    ld a, e
    cp 64
    ret nc

	push bc

    ld a, 7
    call changeBank

	call findAddr
	pop af
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl
	ld bc, font
	add hl, bc
	ld b, 8
pLp:
	ld a, (HL)
	ld (DE), A
	inc hl
	inc d
	djnz pLp
	ld hl, (coords)
	inc l
	ld (coords), hl
	ret

; D - Y
; E - X
; OUT: de - coords
findAddr:
    ld a, e
    srl a
    ld e, a
    ld hl, #A000
    jr c, fa1
    ld hl, #8000
fa1:		   
    LD A,D
    AND 7
    RRCA
    RRCA
    RRCA
    OR E
    LD E,A
    LD A,D
    AND 24
    OR 64
    LD D,A
    ADD hl, de
    ex hl, de
    ret

clearScreen:

    ld a, 7
    call changeBank

    ld c, #ff
    ld a, #3E
    out (c), a


    di
    ld	hl,0
    ld	d,h
    ld	e,h
    ld	b,h
    ld	c,b
    add	hl,sp
    ld	sp,#c000 + 6144
clgloop
	push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    djnz	clgloop

    ld	b,c
    ld	sp,#e000 + 6144
clgloop2:
    push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    djnz	clgloop2

    ld	sp,hl

    xor a
    call changeBank
    
    ei
    ret


coords dw 0
; Using ZX-Spectrum font - 2K economy
font equ #3D00
