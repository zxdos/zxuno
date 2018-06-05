        OUTPUT  KARTUSHO.ROM
        ORG     $0
        di
        im      1
        ld      sp, $c000
        ld      hl, initData60Hz
        ld      d, h            ; D=H=0
        ld      bc, $f782
        out     (c), c          ; PIO Control-Register
        dec     b
        out     (c), h          ; Port C
        dec     b
        in      a, (c)          ; Read from port B 
        dec     b
        jr      cont
initData60Hz:
        defb    $3f, $28, $2e, $8e, $1f, $06, $19, $1b
        defb    $00, $07, $00, $00, $30, $00, $c0, $00
initData50Hz:
        defb    $3f, $28, $2e, $8e, $26, $00, $19, $1e
        defb    $00, $07, $00, $00, $30, $00, $c0, $00

rst38   ei
        ret

cont    out     (c), h          ; Port A
        ld      bc, $ef7f
        out     (c), c
        and     $10
        ld      e, a
        add     hl, de
crctlo  ld      b, $bc          ; inicializo registros CRCT
        out     (c), d
        ld      b, $be
        outi
        inc     d
        bit     4, d
        jr      z, crctlo
        ld      bc, $7f98
        out     (c), c

  ld a, $40                     ; poner borde gris
  call border

        ld      bc, $3ffc
        ld      l, h            ; HL= 0
        ld      de, $4000
        ldir
        jp      toram+$4000

toram   

LEEKB   LD      A, $45          ;kbdline ; from &40 to &49 with bdir/bc1=01
                                ; bit7 6 5 4 3 2 1 0
        LD      D, 0            ;SPACE N J H Y U 7 8
        LD      BC, $F782       ; PPI port A out /C out 
        OUT     (C), C
        LD      BC, $F40E       ; Select Ay reg 14 on ppi port A 
        OUT     (C), C 
        LD      BC, $F6C0       ; This value is an AY index (R14) 
        OUT     (C), C 
        OUT     (C), D          ; Validate!! out (c),0
        LD      BC, $F792       ; PPI port A in/C out 
        OUT     (C), C 
        DEC     B
        OUT     (C), A          ; Send KbdLine on reg 14 AY through ppi port A
        LD      B, $F4          ; Read ppi port A 
        IN      A,(C)           ; e.g. AY R14 (AY port A) 
        LD      BC, $F782       ; PPI port A out / C out 
        OUT     (C), C 
        DEC     B               ; Reset PPI Write 
        OUT     (C), D          ; out (c),0
        CP      $FF             ; no se ha pulsado nada?
        JR      Z, LEEKB
        LD      B, 0            ; B=1->   8     B=5->   H
SIGUI   INC     B               ; B=2->   7     B=6->   J
        RRCA                    ; B=3->   U     B=7->   N
        JR      C, SIGUI        ; B=4->   Y     B=8->   SPACe
        
        ld      a, b
        call    chslot+$4000    ; cargo ROM del 464 en 0000
        rst     0

;input A= color
;      carry= LOCK
border  ld      bc, $7f10
        out     (c), c
        out     (c), a
        ret

;input A= slot number bewteen 0 and 31
;      carry= LOCK
chslot  adc     a, a
        add     a, a
        add     a, a
        ld      hl, $3ffc
        ld      b, 5
chslo1  ld      c, (hl)
        add     a, a
        res     0, l
        jr      nc, chslo2
        inc     l
chslo2  djnz    chslo1
        rlca
        rlca
        add     a, l
        ld      l, a
        ld      c, (hl)
        ret

        BLOCK   1*$4000-$       ; slot 1 verde mar Tecla 8
        ld      a, $42
        ld      bc, $7f10
        out     (c), c
        out     (c), a
        halt

        BLOCK   2*$4000-$       ; slot 2 amarillo Tecla 7
        ld      a, $43
        ld      bc, $7f10
        out     (c), c
        out     (c), a
        halt

        BLOCK   3*$4000-$       ; slot 3 azul Tecla U
        ld      a, $44
        ld      bc, $7f10
        out     (c), c
        out     (c), a
        halt

        BLOCK   4*$4000-$       ; slot 4 rosa oscuro Tecla Y
        ld      a, $45
        ld      bc, $7f10
        out     (c), c
        out     (c), a
        halt

        BLOCK   5*$4000-$       ; slot 5 cyan Tecla H
        ld      a, $46
        ld      bc, $7f10
        out     (c), c
        out     (c), a
        halt

        BLOCK   6*$4000-$       ; slot 6 rosa claro Tecla J
        ld      a, $47
        ld      bc, $7f10
        out     (c), c
        out     (c), a
        halt

        BLOCK   7*$4000-$       ; slot 7 verde brillante Tecla N
        ld      a, $52
        ld      bc, $7f10
        out     (c), c
        out     (c), a
        halt

        BLOCK   8*$4000-$       ; slot 8 cyan brillante Tecla SPACE
        ld      a, $53
        ld      bc, $7f10
        out     (c), c
        out     (c), a
        halt

        BLOCK   $80000-$
