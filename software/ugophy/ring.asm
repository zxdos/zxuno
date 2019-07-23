; Pushes A to ring buffer
pushRing
    push af
    ld b, 32
    ld hl, ring_buffer + 1
    ld de, ring_buffer 
ringL
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    djnz ringL
    pop af
    ld hl, ring_buffer + 31
    ld (hl), a
    ret

; HL - Compare string(null terminated)
; A - 0 NOT Found 
;     1 Found
searchRing:
    ld b, 0
    push hl
serlp: 
    ld a, (hl)
    inc hl
    inc b
    and a
    jp nz, serlp
    dec b
    pop hl
    push bc
    push hl
SRWork:
    pop hl
    ld de, ring_buffer + 32
srcLp   
    dec de
    djnz srcLp
    pop bc
ringCmpLp    
    push bc
    push af
    ld a, (de)
    ld b, a
    pop af
    ld a, (hl)
    cp b
    pop bc
    ld a, 0
    ret nz  
    inc de
    inc hl
    djnz ringCmpLp
    ld a, 1
    ret
    
ring_buffer dup 33
            defb 0
            edup