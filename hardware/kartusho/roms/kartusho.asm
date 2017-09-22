        OUTPUT  kartusho.rom
        define  codcnt  $7800
        include version.asm

        di
        im      1
        ld      sp, $8000
        ld      hl, $5800
        ld      de, $5801
        ld      (hl), e
        ld      bc, $0020
        ldir
        ld      (hl), $47
        ld      bc, $03fe
        out     (c), h
        ldir
        ld      hl, manic-1
        push    hl
        ld      d, $77
        call    dzx7b
        inc     l
        inc     hl
        ld      b, $40
start3  ld      a, b
        xor     c
        and     $f8
        xor     c
        ld      d, a
        xor     b
        xor     c
        rlca
        rlca
        ld      e, a
        inc     bc
        ldi
        jr      cont

; ----------------------
; THE 'KEYBOARD' ROUTINE
; ----------------------
rst38   push    af
        push    bc
        push    hl
        ld      hl, keytab-5
        ld      bc, $fefe
keyscn  in      a, (c)
        cpl
        and     $1f
        set     5, a
        dec     hl
keysc1  inc     hl
        rrca
        jr      nc, keysc1
        jr      nz, keysc5
        rlc     b
        jr      c, keyscn
keysc5  ld      a, (hl)
        or      a
keysc6  ld      hl, (codcnt)
        jr      z, keysc8
        res     7, l
        cp      l
        jr      nz, keysc7
        dec     h
        jr      nz, keysc9
        ld      h, 3
        defb    $c2
keysc7  ld      h, 32
        or      $80
keysc8  ld      l, a
keysc9  ld      (codcnt), hl
        ei
        pop     hl
        pop     bc
        pop     af
        ret

cont    inc     bc
        ld      a, b
        cp      $58
        jr      nz, start3
      IF version=1
        ld      d, codcnt-1>>8
        push    de
      ELSE
        ld      hl, game3
        ld      d, (hl)
        push    de
        ld      b, h
        ldir
      ENDIF
        ld      l, c
        ld      bc, $f7fe
        call    direc
        ld      b, $ef
        call    c, inver
        ld      b, $fb
        call    c, direc
        ld      b, $df
        call    c, inver
        ld      b, $fd
        call    c, direc
        ld      b, $bf
        call    c, inver
        ld      b, c
        dec     l
        jr      nc, game1
        in      a, (c)
        rrca
        ld      b, 3
cont1   rrca
        jr      nc, gamen
        inc     l
        djnz    cont1
        ld      l, e
      IF version=1
        inc     d
      ENDIF
        ei

games   call    SELEC
        ld      bc, games
        push    bc
waitky  ld      a, (de)
        sub     $80
        jr      c, waitky
        ld      (de), a
        cp      $0d
        jr      z, gamen
        cp      $20
        jr      z, gamen
        call    SELEC
        ld      a, (de)
        sub     '5'
        jr      z, gamlf
        dec     a
        jr      z, gamdw
        dec     a
        jr      z, gamup
        dec     a
        jr      z, gamrh
        sub    'a'-'8'
        jr      z, gamdw
        sub    'o'-'a'
        jr      z, gamlf
        dec     a
        jr      z, gamrh
        dec     a
        ret     nz
gamup   dec     l
        ret     p
gamdw   inc     l
        ld      a, l
        cp      32
        ret     c
        dec     l
        ret
gamlf   ld      a, l
        ld      l, e
        sub     16
        ret     c
        ld      l, a
        ret
gamrh   ld      a, l
        cp      16
        jr      c, gamrh1
        ld      a, 15
gamrh1  add     a, 16
        ld      l, a
        ret
gamen   pop     af
game1   ld      a, l
      IF version=1
        ld      hl, $c777
        and     $1f
        jr      nz, game2
        inc     h
        inc     h
game2   ld      ($7700), hl
        ld      h, a
        or      $80
      ELSE
        ld      l, $c9
        and     $1f
        jr      nz, game2
        ld      ($770b), hl
game2   rlca
        ld      hl, $3ffc
        rlca
        rlca
        ld      b, 5
      ENDIF
        ret

keytab  defb    $61, $73, $64, $66, $67 ; a       s       d       f       g
        defb    $71, $77, $65, $72, $74 ; q       w       e       r       t
        defb    $31, $32, $33, $34, $35 ; 1       2       3       4       5
        defb    $30, $39, $38, $37, $36 ; 0       9       8       7       6
        defb    $70, $6f, $69, $75, $79 ; p       o       i       u       y
        defb    $0d, $6c, $6b, $6a, $68 ; Enter   l       k       j       h
        defb    $20

inver   in      a, (c)
        ld      b, 5
inver1  nop
        rrca
        rl      e
        djnz    inver1
        ld      a, e
        defb    $da
direc   in      a, (c)
        ld      e, 6
direc2  dec     e
        ret     z
        inc     l
        rrca
        jr      c, direc2
        ret

      IF version=0
game3   ld      (hl), a
        rlca
        res     0, l
        jr      nc, game4
        inc     l
game4   djnz    game3
        set     1, l
        ld      (hl), a
        rst     0
      ENDIF

SELEC   push    hl
        exx
        pop     hl
        inc     l
        ld      a, l
        cp      17
        ld      de, 0
        ld      b, 16
        jr      c, sel01
        ld      e, -16
        add     hl, de
        ld      e, b
sel01   add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      h, $16
        add     hl, hl
        add     hl, hl
        add     hl, de
sel02   ld      a, (hl)
        xor     %00111111
        ld      (hl), a
        inc     l
        djnz    sel02
        exx
        ld      a, l
        exx
sel03   sub     16
        jr      nc, sel03
        add     a, 17
        ld      c, a
        and     %00011000
        or      %01000000
        ld      d, a
        ld      a, c
        and     %00000111
        rrca
        rrca
        rrca
        add     a, $0f
        ld      e, a
        ld      b, 8
sel04   ld      a, (de)
        xor     3
        ld      (de), a
        inc     d
        djnz    sel04
        exx
        ret

        incbin  screen.cut.zx7b

manic   
      IF version=0
        ld      (hl), a
      ENDIF
        ld      de, $ffff
        ld      hl, endman-1
        ld      bc, $8400
        push    bc

dzx7b   include dzx7b_fast.asm
        incbin  manic.cut.zx7b
endman  block   $3d00-$, $ff

; -------------------------------
; THE 'ZX SPECTRUM CHARACTER SET'
; -------------------------------

;; char-set

; $20 - Character: ' '          CHR$(32)

L3D00:  DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000

; $21 - Character: '!'          CHR$(33)

        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00000000

; $22 - Character: '"'          CHR$(34)

        DEFB    %00000000
        DEFB    %00100100
        DEFB    %00100100
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000

; $23 - Character: '#'          CHR$(35)

        DEFB    %00000000
        DEFB    %00100100
        DEFB    %01111110
        DEFB    %00100100
        DEFB    %00100100
        DEFB    %01111110
        DEFB    %00100100
        DEFB    %00000000

; $24 - Character: '$'          CHR$(36)

        DEFB    %00000000
        DEFB    %00001000
        DEFB    %00111110
        DEFB    %00101000
        DEFB    %00111110
        DEFB    %00001010
        DEFB    %00111110
        DEFB    %00001000

; $25 - Character: '%'          CHR$(37)

        DEFB    %00000000
        DEFB    %01100010
        DEFB    %01100100
        DEFB    %00001000
        DEFB    %00010000
        DEFB    %00100110
        DEFB    %01000110
        DEFB    %00000000

; $26 - Character: '&'          CHR$(38)

        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00101000
        DEFB    %00010000
        DEFB    %00101010
        DEFB    %01000100
        DEFB    %00111010
        DEFB    %00000000

; $27 - Character: '''          CHR$(39)

        DEFB    %00000000
        DEFB    %00001000
        DEFB    %00010000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000

; $28 - Character: '('          CHR$(40)

        DEFB    %00000000
        DEFB    %00000100
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00000100
        DEFB    %00000000

; $29 - Character: ')'          CHR$(41)

        DEFB    %00000000
        DEFB    %00100000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00100000
        DEFB    %00000000

; $2A - Character: '*'          CHR$(42)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00010100
        DEFB    %00001000
        DEFB    %00111110
        DEFB    %00001000
        DEFB    %00010100
        DEFB    %00000000

; $2B - Character: '+'          CHR$(43)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00111110
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00000000

; $2C - Character: ','          CHR$(44)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00010000

; $2D - Character: '-'          CHR$(45)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00111110
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000

; $2E - Character: '.'          CHR$(46)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00011000
        DEFB    %00011000
        DEFB    %00000000

; $2F - Character: '/'          CHR$(47)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000010
        DEFB    %00000100
        DEFB    %00001000
        DEFB    %00010000
        DEFB    %00100000
        DEFB    %00000000

; $30 - Character: '0'          CHR$(48)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000110
        DEFB    %01001010
        DEFB    %01010010
        DEFB    %01100010
        DEFB    %00111100
        DEFB    %00000000

; $31 - Character: '1'          CHR$(49)

        DEFB    %00000000
        DEFB    %00011000
        DEFB    %00101000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00111110
        DEFB    %00000000

; $32 - Character: '2'          CHR$(50)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %00000010
        DEFB    %00111100
        DEFB    %01000000
        DEFB    %01111110
        DEFB    %00000000

; $33 - Character: '3'          CHR$(51)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %00001100
        DEFB    %00000010
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $34 - Character: '4'          CHR$(52)

        DEFB    %00000000
        DEFB    %00001000
        DEFB    %00011000
        DEFB    %00101000
        DEFB    %01001000
        DEFB    %01111110
        DEFB    %00001000
        DEFB    %00000000

; $35 - Character: '5'          CHR$(53)

        DEFB    %00000000
        DEFB    %01111110
        DEFB    %01000000
        DEFB    %01111100
        DEFB    %00000010
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $36 - Character: '6'          CHR$(54)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000000
        DEFB    %01111100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $37 - Character: '7'          CHR$(55)

        DEFB    %00000000
        DEFB    %01111110
        DEFB    %00000010
        DEFB    %00000100
        DEFB    %00001000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00000000

; $38 - Character: '8'          CHR$(56)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $39 - Character: '9'          CHR$(57)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00111110
        DEFB    %00000010
        DEFB    %00111100
        DEFB    %00000000

; $3A - Character: ':'          CHR$(58)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00000000

; $3B - Character: ';'          CHR$(59)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00100000

; $3C - Character: '<'          CHR$(60)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000100
        DEFB    %00001000
        DEFB    %00010000
        DEFB    %00001000
        DEFB    %00000100
        DEFB    %00000000

; $3D - Character: '='          CHR$(61)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00111110
        DEFB    %00000000
        DEFB    %00111110
        DEFB    %00000000
        DEFB    %00000000

; $3E - Character: '>'          CHR$(62)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00001000
        DEFB    %00000100
        DEFB    %00001000
        DEFB    %00010000
        DEFB    %00000000

; $3F - Character: '?'          CHR$(63)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %00000100
        DEFB    %00001000
        DEFB    %00000000
        DEFB    %00001000
        DEFB    %00000000

; $40 - Character: '@'          CHR$(64)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01001010
        DEFB    %01010110
        DEFB    %01011110
        DEFB    %01000000
        DEFB    %00111100
        DEFB    %00000000

; $41 - Character: 'A'          CHR$(65)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01111110
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00000000

; $42 - Character: 'B'          CHR$(66)

        DEFB    %00000000
        DEFB    %01111100
        DEFB    %01000010
        DEFB    %01111100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01111100
        DEFB    %00000000

; $43 - Character: 'C'          CHR$(67)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $44 - Character: 'D'          CHR$(68)

        DEFB    %00000000
        DEFB    %01111000
        DEFB    %01000100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000100
        DEFB    %01111000
        DEFB    %00000000

; $45 - Character: 'E'          CHR$(69)

        DEFB    %00000000
        DEFB    %01111110
        DEFB    %01000000
        DEFB    %01111100
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %01111110
        DEFB    %00000000

; $46 - Character: 'F'          CHR$(70)

        DEFB    %00000000
        DEFB    %01111110
        DEFB    %01000000
        DEFB    %01111100
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %00000000

; $47 - Character: 'G'          CHR$(71)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %01000000
        DEFB    %01001110
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $48 - Character: 'H'          CHR$(72)

        DEFB    %00000000
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01111110
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00000000

; $49 - Character: 'I'          CHR$(73)

        DEFB    %00000000
        DEFB    %00111110
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00111110
        DEFB    %00000000

; $4A - Character: 'J'          CHR$(74)

        DEFB    %00000000
        DEFB    %00000010
        DEFB    %00000010
        DEFB    %00000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $4B - Character: 'K'          CHR$(75)

        DEFB    %00000000
        DEFB    %01000100
        DEFB    %01001000
        DEFB    %01110000
        DEFB    %01001000
        DEFB    %01000100
        DEFB    %01000010
        DEFB    %00000000

; $4C - Character: 'L'          CHR$(76)

        DEFB    %00000000
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %01111110
        DEFB    %00000000

; $4D - Character: 'M'          CHR$(77)

        DEFB    %00000000
        DEFB    %01000010
        DEFB    %01100110
        DEFB    %01011010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00000000

; $4E - Character: 'N'          CHR$(78)

        DEFB    %00000000
        DEFB    %01000010
        DEFB    %01100010
        DEFB    %01010010
        DEFB    %01001010
        DEFB    %01000110
        DEFB    %01000010
        DEFB    %00000000

; $4F - Character: 'O'          CHR$(79)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $50 - Character: 'P'          CHR$(80)

        DEFB    %00000000
        DEFB    %01111100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01111100
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %00000000

; $51 - Character: 'Q'          CHR$(81)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01010010
        DEFB    %01001010
        DEFB    %00111100
        DEFB    %00000000

; $52 - Character: 'R'          CHR$(82)

        DEFB    %00000000
        DEFB    %01111100
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01111100
        DEFB    %01000100
        DEFB    %01000010
        DEFB    %00000000

; $53 - Character: 'S'          CHR$(83)

        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000000
        DEFB    %00111100
        DEFB    %00000010
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $54 - Character: 'T'          CHR$(84)

        DEFB    %00000000
        DEFB    %11111110
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00000000

; $55 - Character: 'U'          CHR$(85)

        DEFB    %00000000
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00111100
        DEFB    %00000000

; $56 - Character: 'V'          CHR$(86)

        DEFB    %00000000
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %00100100
        DEFB    %00011000
        DEFB    %00000000

; $57 - Character: 'W'          CHR$(87)

        DEFB    %00000000
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01000010
        DEFB    %01011010
        DEFB    %00100100
        DEFB    %00000000

; $58 - Character: 'X'          CHR$(88)

        DEFB    %00000000
        DEFB    %01000010
        DEFB    %00100100
        DEFB    %00011000
        DEFB    %00011000
        DEFB    %00100100
        DEFB    %01000010
        DEFB    %00000000

; $59 - Character: 'Y'          CHR$(89)

        DEFB    %00000000
        DEFB    %10000010
        DEFB    %01000100
        DEFB    %00101000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00000000

; $5A - Character: 'Z'          CHR$(90)

        DEFB    %00000000
        DEFB    %01111110
        DEFB    %00000100
        DEFB    %00001000
        DEFB    %00010000
        DEFB    %00100000
        DEFB    %01111110
        DEFB    %00000000

; $5B - Character: '['          CHR$(91)

        DEFB    %00000000
        DEFB    %00001110
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001110
        DEFB    %00000000

; $5C - Character: '\'          CHR$(92)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01000000
        DEFB    %00100000
        DEFB    %00010000
        DEFB    %00001000
        DEFB    %00000100
        DEFB    %00000000

; $5D - Character: ']'          CHR$(93)

        DEFB    %00000000
        DEFB    %01110000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %01110000
        DEFB    %00000000

; $5E - Character: '^'          CHR$(94)

        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00111000
        DEFB    %01010100
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00000000

; $5F - Character: '_'          CHR$(95)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %11111111

; $60 - Character: ' £ '        CHR$(96)

        DEFB    %00000000
        DEFB    %00011100
        DEFB    %00100010
        DEFB    %01111000
        DEFB    %00100000
        DEFB    %00100000
        DEFB    %01111110
        DEFB    %00000000

; $61 - Character: 'a'          CHR$(97)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00111000
        DEFB    %00000100
        DEFB    %00111100
        DEFB    %01000100
        DEFB    %00111100
        DEFB    %00000000

; $62 - Character: 'b'          CHR$(98)

        DEFB    %00000000
        DEFB    %00100000
        DEFB    %00100000
        DEFB    %00111100
        DEFB    %00100010
        DEFB    %00100010
        DEFB    %00111100
        DEFB    %00000000

; $63 - Character: 'c'          CHR$(99)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00011100
        DEFB    %00100000
        DEFB    %00100000
        DEFB    %00100000
        DEFB    %00011100
        DEFB    %00000000

; $64 - Character: 'd'          CHR$(100)

        DEFB    %00000000
        DEFB    %00000100
        DEFB    %00000100
        DEFB    %00111100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %00111100
        DEFB    %00000000

; $65 - Character: 'e'          CHR$(101)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00111000
        DEFB    %01000100
        DEFB    %01111000
        DEFB    %01000000
        DEFB    %00111100
        DEFB    %00000000

; $66 - Character: 'f'          CHR$(102)

        DEFB    %00000000
        DEFB    %00001100
        DEFB    %00010000
        DEFB    %00011000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00000000

; $67 - Character: 'g'          CHR$(103)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %00111100
        DEFB    %00000100
        DEFB    %00111000

; $68 - Character: 'h'          CHR$(104)

        DEFB    %00000000
        DEFB    %01000000
        DEFB    %01000000
        DEFB    %01111000
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %00000000

; $69 - Character: 'i'          CHR$(105)

        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00000000
        DEFB    %00110000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00111000
        DEFB    %00000000

; $6A - Character: 'j'          CHR$(106)

        DEFB    %00000000
        DEFB    %00000100
        DEFB    %00000000
        DEFB    %00000100
        DEFB    %00000100
        DEFB    %00000100
        DEFB    %00100100
        DEFB    %00011000

; $6B - Character: 'k'          CHR$(107)

        DEFB    %00000000
        DEFB    %00100000
        DEFB    %00101000
        DEFB    %00110000
        DEFB    %00110000
        DEFB    %00101000
        DEFB    %00100100
        DEFB    %00000000

; $6C - Character: 'l'          CHR$(108)

        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00001100
        DEFB    %00000000

; $6D - Character: 'm'          CHR$(109)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01101000
        DEFB    %01010100
        DEFB    %01010100
        DEFB    %01010100
        DEFB    %01010100
        DEFB    %00000000

; $6E - Character: 'n'          CHR$(110)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01111000
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %00000000

; $6F - Character: 'o'          CHR$(111)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00111000
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %00111000
        DEFB    %00000000

; $70 - Character: 'p'          CHR$(112)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01111000
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %01111000
        DEFB    %01000000
        DEFB    %01000000

; $71 - Character: 'q'          CHR$(113)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00111100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %00111100
        DEFB    %00000100
        DEFB    %00000110

; $72 - Character: 'r'          CHR$(114)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00011100
        DEFB    %00100000
        DEFB    %00100000
        DEFB    %00100000
        DEFB    %00100000
        DEFB    %00000000

; $73 - Character: 's'          CHR$(115)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00111000
        DEFB    %01000000
        DEFB    %00111000
        DEFB    %00000100
        DEFB    %01111000
        DEFB    %00000000

; $74 - Character: 't'          CHR$(116)

        DEFB    %00000000
        DEFB    %00010000
        DEFB    %00111000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %00001100
        DEFB    %00000000

; $75 - Character: 'u'          CHR$(117)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %00111000
        DEFB    %00000000

; $76 - Character: 'v'          CHR$(118)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %00101000
        DEFB    %00101000
        DEFB    %00010000
        DEFB    %00000000

; $77 - Character: 'w'          CHR$(119)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01000100
        DEFB    %01010100
        DEFB    %01010100
        DEFB    %01010100
        DEFB    %00101000
        DEFB    %00000000

; $78 - Character: 'x'          CHR$(120)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01000100
        DEFB    %00101000
        DEFB    %00010000
        DEFB    %00101000
        DEFB    %01000100
        DEFB    %00000000

; $79 - Character: 'y'          CHR$(121)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %01000100
        DEFB    %00111100
        DEFB    %00000100
        DEFB    %00111000

; $7A - Character: 'z'          CHR$(122)

        DEFB    %00000000
        DEFB    %00000000
        DEFB    %01111100
        DEFB    %00001000
        DEFB    %00010000
        DEFB    %00100000
        DEFB    %01111100
        DEFB    %00000000

; $7B - Character: '{'          CHR$(123)

        DEFB    %00000000
        DEFB    %00001110
        DEFB    %00001000
        DEFB    %00110000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001110
        DEFB    %00000000

; $7C - Character: '|'          CHR$(124)

        DEFB    %00000000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00001000
        DEFB    %00000000

; $7D - Character: '}'          CHR$(125)

        DEFB    %00000000
        DEFB    %01110000
        DEFB    %00010000
        DEFB    %00001100
        DEFB    %00010000
        DEFB    %00010000
        DEFB    %01110000
        DEFB    %00000000

; $7E - Character: '~'          CHR$(126)

        DEFB    %00000000
        DEFB    %00010100
        DEFB    %00101000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000
        DEFB    %00000000

; $7F - Character: ' © '        CHR$(127)

        DEFB    %00111100
        DEFB    %01000010
        DEFB    %10011001
        DEFB    %10100001
        DEFB    %10100001
        DEFB    %10011001
        DEFB    %01000010
        DEFB    %00111100
