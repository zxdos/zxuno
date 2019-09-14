showText:
    xor a : ld (show_offset), a 
    call renderTextScreen
showTxLp:
    call txControls
    
    xor a : call changeBank
    
    dup 5
    halt
    edup
    jp showTxLp

txControls:
    call inkey
    
    and a : ret z

    cp 'q' : jp z, txUp
    cp 'o' : jp z, txUp
    cp 'a' : jp z, txDn
    cp 'p' : jp z, txDn
    cp 'b' : jp z, historyBack
    cp 'n' : jp z, openURI

    ret

txUp:
    ld a, (show_offset)
    and a : ret z

    sub 20 : ld (show_offset), a
    call renderTextScreen
    ret

txDn:
    ld a, (show_offset) 
    add 20 : ld (show_offset), a

    call renderTextScreen
    ret

renderTextScreen:
    call renderHeader
    ld b, 20
txRenderLp:
    push bc
    
    ld a, 20 : sub b : ld b, a : ld a, (show_offset) : add b : ld b, a 
    call renderTextLine
    
    pop bc
    djnz txRenderLp
    ret


renderTextLine:
    call findLine
    
    ld a, h : or l : ret z
    ld a, (hl) : and a : ret z

    call printL64
    call mvCR
    ret
