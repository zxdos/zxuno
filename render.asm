showPage:
    xor a
    ld (show_offset), a
    ld a, 1
    ld (cursor_pos), a
    call renderScreen
    call showCursor
showLp:
    call controls
    dup 5
    halt
    edup
    jr showLp

controls:
    call inkey
    
    cp 0
    ret z 

    cp 'q'
    jr z, pageCursorUp

    cp 'a'
    jr z, pageCursorDown

    cp 13
    jp z, selectItem 

    cp 'b'
    jr z, historyBack

    cp 'o'
    jp z, openURI
    ret

historyBack:
    ld hl, server
    ld de, path
    ld bc, port
    call openPage
    jp showPage

pageCursorUp:
    ld a, (cursor_pos)
    dec a 
    cp 0
    jp z, pageScrollUp

    push af
    call hideCursor
    pop af
    ld (cursor_pos), a
    call showCursor
    ret

pageCursorDown:
    ld a, (cursor_pos)
    inc a
    cp 21
    jp z, pageScrollDn

    push af
    call hideCursor
    pop af
    ld (cursor_pos), a
    call showCursor
    ret

pageScrollDn:
    ld hl, (show_offset)
    ld de, 20
    add hl, de
    ld (show_offset), hl
    ld a, 1
    ld (cursor_pos), a
    call renderScreen
    call showCursor
    ret 

pageScrollUp:
    ld a, (show_offset)
    and a
    ret z

    ld hl, (show_offset)
    ld de, 20
    sub hl, de
    ld (show_offset), hl

    ld a, 20
    ld (cursor_pos), a
    call renderScreen
    call showCursor
    ret

selectItem:
    ld a, (cursor_pos)
    dec a
    ld b, a
    ld a, (show_offset)
    add b 
    ld b, a
    call findLine
    ld a, h
    cp l
    ret z
    ld a, (hl)

    cp '1'
    jr z, downPg

    cp '0'
    jr z, downPg

    cp '9'
    jp z, downFl

    ret  

downPg:
    push af
    call extractInfo

    ld hl, hist
    ld de, path
    ld bc, 147
    ldir

    ld hl, server_buffer
    ld de, file_buffer
    ld bc, port_buffer
    call openPage
    pop af

    cp '1'
    jp z,showPage

    cp '0'
    jp z, showText

    ret

downFl:
    call extractInfo

    call cleanIBuff
    ld hl, file_buffer
    call findFnme
    ld de, iBuff
    ld bc, 65
    ldir
    call input
    ld hl, server_buffer
    ld de, file_buffer
    ld bc, port_buffer
    call makeRequest
    
    ld hl, iBuff
    call downloadData
    call showCursor
    ret

findFnme:
    push hl
    pop de
ffnmlp:
    ld a, (hl)
    
    cp 0
    jr z, ffnmend

    cp '/'
    jr z, fslsh

    inc hl
    jp ffnmlp
fslsh:
    inc hl
    push hl
    pop de
    jp ffnmlp
ffnmend:
    push de
    pop hl
    ret

showType:
    ld a, (cursor_pos)
    dec a
    ld b, a
    ld a, (show_offset)
    add b 
    ld b, a
    call findLine
    ld a, h
    cp l
    jr z, showTypeUnknown

    ld a, (hl)
    
    cp 'i'
    jr z, showTypeInfo

    cp '9'
    jr z, showTypeDown

    cp '1'
    jr z, showTypePage

    cp '0'
    jr z, showTypeText

    jr showTypeUnknown

showTypeText:
    ld hl, type_text
    call showTypePrint
    call showURI
    ret

showTypeInfo:
    ld hl, type_info
    jp showTypePrint

showTypePage:
    ld hl, type_page
    call showTypePrint
    call showURI
    ret

showTypeDown:
    ld hl, type_down
    call showTypePrint
    call showURI
    ret

showURI:
    call extractInfo
    ld hl, server_buffer
    call printZ64
    
    ld hl, file_buffer
    call printZ64
    ret
showTypeUnknown:
    ld hl, type_unkn
    jp showTypePrint

showTypePrint:
    push hl
    
    ld b, 21
    ld c, 0
    call gotoXY
    ld hl, cleanLine
    call printZ64
    
    ld b, 21
    ld c, 0
    call gotoXY
    ld a, 3
    ld (attr_screen), a
    pop hl
    call printZ64
    ld a, #7
    ld (attr_screen), a
    ret

showCursor:
    ld a, (cursor_pos)
    ld c, 0
    ld b, a
    call bc_to_attr
    ld (hl), #C
    ld de, hl
    inc de
    ld bc, 31
    ldir
    call showType
    ret

hideCursor:
    ld a, (cursor_pos)
    ld b, a
    ld c, 0
    call bc_to_attr
    ld (hl), #07
    ld de, hl
    inc de
    ld bc, 31
    ldir
    ret

renderHeader:
    call clearScreen
    ld a, #0F
    ld (attr_screen), a
    ld bc, 0
    call gotoXY
    ld hl, head
    call printZ64
    
    ld a, #07
    ld (attr_screen), a
    ret

renderScreen:
    call renderHeader
    ld b, 20
renderLp:
    push bc
    ld a, 20
    sub b
    ld b, a
    ld a, (show_offset)
    add b
    ld b, a 
    call renderLine
    pop bc
    djnz renderLp
    ret

; b - line number
renderLine:
    call findLine
    
    ld a, h
    or l 
    ret z 

    ld a, (hl)
    and a
    ret z 
    inc hl
    call printT64
    call mvCR
    ret

; B - line number
; HL - pointer to line(or zero if doesn't find it)
findLine:
    ld hl, page_buffer
fndLnLp:
    ld a, b
    and a
    ret z 

    ld a, (hl)
    
    and a           ; Buffer ends?
    jr z, fndEnd
    
    cp 10           ; New line?
    jr z, fndLnNL
    inc hl
    jp fndLnLp

fndLnNL:
    dec b
    inc hl
    jp fndLnLp
fndEnd:
    ld hl, 0
    ret

extractInfo:
    ld a, (cursor_pos)
    dec a
    ld b, a
    ld a, (show_offset)
    add b 
    ld b, a
    call findLine
    ld a, h
    cp l
    ret z

    call findNextBlock
    inc hl
    ld de, file_buffer
    call extractCol
    inc hl
    ld de, server_buffer
    call extractCol
    inc hl
    ld de, port_buffer
    call extractCol
    ret

extractCol:
    ld a, (hl)

    cp 0
    jr z, endExtract

    cp 09
    jr z, endExtract

    cp 13
    jr z, endExtract

    ld (de), a
    inc de
    inc hl
    jr extractCol

endExtract:
    xor a
    ld (de), a
    ret

findNextBlock:
    ld a, (hl)

    cp 09   ; TAB
    ret z
    
    cp 13   ; New line
    ret z

    cp 0    ; End buffer
    ret z

    inc hl
    jp findNextBlock

show_offset     db  0
    display $
cursor_pos      db  1

head      db "  UGophy - ZX-UNO Gopher client v. 0.1 (c) Alexander Sharikhin  ",0

cleanLine db "                                                                ",0

type_text db "Text file: ", 0
type_info db "Information ", 0
type_page db "Page: ", 0
type_down db "File to download: ", 0
type_unkn db "Unknown type ", 0 

    display $

file_buffer defs 70     ; URI path
server_buffer defs 70   ; Host name
port_buffer defs 7      ; Port

end_inf_buff equ $


        