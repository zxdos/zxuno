CURKEY = 23560

; Returns in A key code or zero if key wans't pressed
inkey:
    ld hl, CURKEY : ld a, (hl)
    push af : xor a : ld (hl), a : pop af
    ret

findZero:
    ld a, (hl) : or a : ret z
    inc hl
    jp findZero

input:
    ld b, 20 : ld c, 0 : call gotoXY

    ld hl, cleanLine : call printZ64
    
    ld hl, iBuff : call findZero
iLp:
    halt
    push hl

    ld b, 20 : ld c, 0: call gotoXY
    ld hl, iBuff : call printZ64
    
    ld a, '_' : call putC : ld a, ' ' : call putC
    
    call inkey

    cp 0 : jr z, iNth
    cp 12 : jr z, iBS
    cp 13 : jr z, iRet

    pop hl : ld (hl), A : push hl
    
    ld de, iBuff + 62 : sub hl, de : ld a, h : or l : jr z, iCr 
    
    pop hl : inc hl
    jr iLp

iBS: pop hl : push hl
     ld de, iBuff : sub hl, de : ld a, h : or l
     pop hl :jr z, iLp
     
     dec hl : ld (hl), 0
     jr iLp

iCr  pop hl  : xor a : ld (hl), a : push hl
iNth pop hl: jr iLp

cleanIBuff:
    ld bc, 64 : ld hl, iBuff : ld de, iBuff + 1 : ld (hl), 0 : ldir
    ret

iRet:
    pop hl
    
    ld b, 20 : ld c, 0 : call gotoXY
    ld hl, cleanLine :call printZ64
    ret

iBuff defs 65