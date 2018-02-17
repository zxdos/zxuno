        output  launcher.rom
        include version.asm
        define  vertical        1
      macro wreg  dir, dato
        rst     $28
        defb    dir, dato
      endm
        define  call_prnstr     rst     $18
        define  zxuno_port      $fc3b
        define  master_conf     0
        define  master_mapper   1
        define  flash_spi       2
        define  flash_cs        3
        define  scan_code       4
        define  key_stat        5
        define  joy_conf        6
        define  key_map         7
        define  nmi_event       8
        define  mouse_data      9
        define  mouse_status    10
        define  scandbl_ctrl    11
        define  raster_line     12
        define  raster_ctrl     13
        define  dev_control     14
        define  dev_control2    15
        define  core_addr       $fc
        define  core_boot       $fd
        define  cold_boot       $fe
        define  core_id         $ff

        define  SPI_PORT        $eb
        define  OUT_PORT        $e7
        define  MMC_0           $fe ; D0 LOW = SLOT0 active
        define  CMD0            $40
        define  CMD1            $41
        define  CMD8            $48
        define  SET_BLOCKLEN    $50
        define  READ_SINGLE     $51
        define  CMD41           $69
        define  CMD55           $77
        define  CMD58           $7a

        define  cmbpnt  $8f00
        define  colcmb  $8fc6   ;lo: color de lista   hi: temporal
        define  menuop  $8fc8   ;lo: menu superior    hi: submenu
        define  corwid  $8fca   ;lo: X attr coor      hi: attr width
        define  cmbcor  $8fcc   ;lo: Y coord          hi: X coord
        define  codcnt  $8fce   ;lo: codigo ascii     hi: repdel
        define  items   $8fd0   ;lo: totales          hi: en pantalla
        define  offsel  $8fd2   ;lo: offset visible   hi: seleccionado
                      ; inputs   lo: cursor position  hi: max length
                      ; otro     lo: pagina actual    hi: mascara paginas
        define  sdhc    $8fd4
        define  scnbak  $8fd5
        define  empstr  $8fd6
        define  config  $9000
        define  indexe  $a000
        define  active  $a040
        define  bitstr  active+1
        define  quietb  bitstr+1
        define  checkc  quietb+1
        define  keyiss  checkc+1
        define  timing  keyiss+1
        define  conten  timing+1
        define  divmap  conten+1
        define  nmidiv  divmap+1
        define  grapmo  nmidiv+1

        define  layout  grapmo+1
        define  joykey  layout+1
        define  joydb9  joykey+1
        define  outvid  joydb9+1
        define  scanli  outvid+1
        define  freque  scanli+1
        define  cpuspd  freque+1
        define  roboot  cpuspd+1  ; boot as root

        define  tmpbuf  $7800
        define  tmpbu2  $7880
        define  bnames  $a100
        define  stack   $aab0

        di
        jp      start

        block   $18-$
rst18   jp      prnstr

        block   $28-$
rst28   ld      bc, zxuno_port + $100
        pop     hl
        outi
        ld      b, (zxuno_port >> 8)+2
        outi
        jp      (hl)

; ----------------------
; THE 'KEYBOARD' ROUTINE
; ----------------------
        block   $38-$
rst38   push    af
        ex      af, af'
        push    af
        push    bc
        push    de
        push    hl
        ld      de, keytab-1&$ff
        ld      bc, $fefe
        ld      l, d
keyscn  in      a, (c)
        cpl
        and     $1f
        ld      h, l
        jr      z, keysc5
keysc1  inc     l
        srl     a
        jr      nc, keysc1
        ex      af, af'
        ld      a, l
        cp      $25                     ;symbol, change here
        jr      z, keysc3
        cp      $01                     ;shift, change here
        jr      z, keysc2
        inc     d
        dec     d
        ld      d, l
        jr      z, keysc4
        xor     a
        jr      keysc6
keysc2  ld      e, 39+keytab&$ff
        defb    $c2                     ;JP NZ,xxxx
keysc3  ld      e, 79+keytab&$ff
keysc4  ex      af, af'
        jr      nz, keysc1
keysc5  ld      a, h
        add     a, 5
        ld      l, a
        rlc     b
        jr      c, keyscn
        in      a, ($1f)
        or      a
        jr      z, nokemp
        ld      hl, kemp-1
sikemp  inc     hl
        rrca
        jr      nc, sikemp
        jr      sikem2
nokemp  ld      h, a
        add     a, d
        jr      z, keysc6
        ld      d, h
        ld      l, a
        add     hl, de
sikem2  ld      a, (hl)
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
        pop     de
        pop     bc
        pop     af
        ex      af, af'
        pop     af
        ret                             ; return.
; ---------------
; THE 'KEY TABLE'
; ---------------
keytab  defb    $00, $7a, $78, $63, $76 ; Caps    z       x       c       v
        defb    $61, $73, $64, $66, $67 ; a       s       d       f       g
        defb    $71, $77, $65, $72, $74 ; q       w       e       r       t
        defb    $31, $32, $33, $34, $35 ; 1       2       3       4       5
        defb    $30, $39, $38, $37, $36 ; 0       9       8       7       6
        defb    $70, $6f, $69, $75, $79 ; p       o       i       u       y
        defb    $0d, $6c, $6b, $6a, $68 ; Enter   l       k       j       h
        defb    $20, $00, $6d, $6e, $62 ; Space   Symbol  m       n       b
        defb    $00, $5a, $58, $43, $56 ; Caps    Z       X       C       V
        defb    $41, $53, $44, $46, $47 ; A       S       D       F       G
        defb    $51, $57, $45, $52, $54 ; Q       W       E       R       T
        defb    $17, $19, $1a, $1b, $1e ; Edit    CapsLk  TruVid  InvVid  Left
        defb    $18, $16, $1f, $1c, $1d ; Del     Graph   Right   Up      Down
        defb    $50, $4f, $49, $55, $59 ; P       O       I       U       Y
        defb    $0d, $4c, $4b, $4a, $48 ; Enter   L       K       J       H
        defb    $0c, $00, $4d, $4e, $42 ; Break   Symbol  M       N       B
        defb    $00, $3a, $60, $3f, $2f ; Caps    :       `       ?       /
        defb    $7e, $7c, $5c, $7b, $7d ; ~       |       \       {       }
        defb    $51, $57, $45, $3c, $3e ; Q       W       E       <       >
        defb    $21, $40, $23, $24, $25 ; !       @       #       $       %
        defb    $5f, $29, $28, $27, $26 ; _       )       (       '       &
        defb    $22, $3b, $7f, $5d, $5b ; "       ;      (c)      ]       [
        defb    $0d, $3d, $2b, $2d, $5e ; Enter   =       +       -       ^
        defb    $20, $00, $2e, $2c, $2a ; Space   Symbol  .       ,       *
kemp    defb    $1f, $1e, $1d, $1c, $0d ; Right   Left    Down    Up      Enter

start   ld      sp, stack
        ld      hl, chrstr
        ld      de, $b080
        ld      bc, chrend-chrstr
        ldir
        call    loadch
        ld      hl, $b000
        ld      de, $b400
start1  ld      b, $04
start2  ld      a, (hl)
        rrca
        rrca
        ld      (de), a
        inc     de
        cpi
        jp      pe, start2
        ld      a, h
        cp      a, $bc
        jr      nz, start1
        ei

;++++++++++++++++++++++++++++++++++
;++++++++     Boot list    ++++++++
;++++++++++++++++++++++++++++++++++
blst    ld      hl, finbez-1
        ld      d, $7a
        call    dzx7b           ; descomprimir
        call    drcs
        ld      hl, bnames-1
        ld      bc, $20
        ld      a, c
laun0   add     hl, bc
        inc     e
        cp      (hl)
        jr      z, laun0
        inc     e
        ld      a, e
        ld      l, a
        cp      24
        jr      c, laun1
        ld      a, 24
laun1   ld      h, a
        ld      (items), hl
        ld      hl, $0104          ; coordenada X
        push    hl
        ld      iy, (items)
        ld      hl, cad62
        ld      (cmbpnt), hl
        ld      iy, indexe
        ld      ix, cmbpnt
        ld      de, tmpbuf
        ld      b, e
        ld      hl, bnames
        call    addbl1
laun2   ld      c, $20
        add     hl, bc
        call    addbls
        jr      nc, laun2
        ld      (ix+1), a
        ld      a, (items+1)
        ld      e, a
        ld      d, 24
        call    chcol
        defw    $1203
        defw    %0111100001000111
bls375  ld      hl, 0;(active)
        ld      a, h
        pop     hl
        ld      h, 4
blst4   call    combol
        ld      b, a
        ld      a, (codcnt)
        sub     $0d
        jr      nz, blst4
        call    calbit
        ld      bc, zxuno_port
        ld      e, core_addr
        out     (c), e
        inc     b
        out     (c), h
        out     (c), l
        out     (c), 0
        wreg    core_boot, 1

; ------------------------------------
; Calculate start address of bitstream
;    B: number of bitstream
; Returns:
;   HL: address of bitstream
; ------------------------------------
calbit  inc     b
      IF  version<5
calbi1  ld      a, 9
        cp      b
        ld      hl, $0040
        jr      nc, calbi2
        ld      hl, $0b80
calbi2  ld      de, $0540
      ELSE
calbi1  ld      hl, $0980
        ld      de, $0740
      ENDIF
calbi3  add     hl, de
        djnz    calbi3
        ret

deixl   ld      (ix+0), e
        ld      (ix+1), d
deixl1  inc     ixl
        inc     ixl
        ret

; ----------------------------
; Add an entry to the bootlist
; ----------------------------
addbls  ld      (ix+0), e
        ld      (ix+1), d
        push    hl
      IF  vertical=0
        call    str2tmp
      ELSE
        push    de
        call    str2tmp
        pop     hl
        ld      a, l
        add     a, 25
        ld      l, a
        jr      nc, addbl0
        inc     h
addbl0  ld      (hl), 0
      ENDIF
        pop     hl
addbl1  inc     iyl
        call    deixl1
        ld      a, (items)
        sub     2
        sub     iyl
        ret

; -------------------------------------
; Transforms space finished string to a null terminated one
;   HL: end of origin string
;   DE: start of moved string
; -------------------------------------
str2tmp ld      c, $21
        push    hl
str2t1  dec     hl
        dec     c
        ld      a, (hl)
        cp      $20
        jr      z, str2t1
        pop     hl
        ld      a, l
        sub     $20
        ld      l, a
        jr      nc, str2t2
        dec     h
str2t2  ldir
        xor     a
        ld      (de), a
        inc     de
        ret

; -------------------------------------
; Show a combo list to select one element
; Parameters:
;(corwid)
; cmbpnt: list of pointers (last is $ffff)
;    A: preselected one
;   HL: X coord (H) and Y coord (L) of the first element
;   DE: window width (D) and window height (E)
; Returns:
;    A: item selected
; -------------------------------------
combol  push    hl
        push    de
        ex      af, af'
        ld      (cmbcor), hl
        ld      hl, cmbpnt+1
combo1  ld      a, (hl)
        inc     l
        inc     l
        inc     a
        jr      nz, combo1
        srl     l
        dec     l
        ld      c, l
        ld      h, e
        ld      b, d
        ld      (items), hl
        ld      hl, empstr
combo2  ld      (hl), $20
        inc     l
        djnz    combo2
        ld      (hl), a
        ex      af, af'
        ld      (offsel+1), a
        sub     e
        jr      nc, combo3
        sbc     a, a
combo3  inc     a
combo4  ld      (offsel), a
        ld      iy, (items)
        ld      iyl, iyh
        ld      bc, (cmbcor)
        ld      a, iyl
        or      a
        jr      z, combo7
combo5  ld      ix, empstr
        call_prnstr
        dec     iyl
        jr      nz, combo5
        ld      a, (offsel)
        ld      bc, (cmbcor)
        add     a, a
        ld      h, cmbpnt>>8
        ld      l, a
combo6  ld      a, (hl)
        ld      ixl, a
        inc     l
        ld      a, (hl)
        inc     l
        ld      ixh, a
        push    hl
        call_prnstr
        pop     hl
        dec     iyh
        jr      nz, combo6
combo7  ld      de, (corwid)
        ld      hl, (cmbcor)
        ld      h, e
        ld      a, (items+1)
        ld      e, a
        ld      a, (colcmb)
        call    window
        ld      de, (corwid)
        ld      hl, (offsel)
        ld      a, (cmbcor)
        add     a, h
        sub     l
        ld      l, a
        ld      h, e
        ld      e, 1
        ld      a, (colcmb-1)
        call    window
        call    waitky
        ld      hl, (offsel)
        sub     $0d
        jr      c, comboa
        jr      z, comboa
        ld      bc, (items)
        sub     $1c-$0d
        jr      nz, combo9
        dec     h
        jp      m, combo7
        ld      a, h
        cp      l
        ld      (offsel), hl
        jr      nc, combo7
        ld      a, l
        dec     a
combo8  jr      combo4
combo9  dec     a               ; $1d
        jr      nz, comboa
        inc     h
        ld      a, h
        cp      c
        jr      z, combo7
        sub     l
        cp      b
        ld      (offsel), hl
        jr      nz, combo7
        ld      a, l
        inc     a
        jr      combo8
comboa  ld      a, h
        pop     de
        pop     hl
        ret

; -------------------------------------
; Draw a window in the attribute area
; Parameters:
;    A: attribute color
;   HL: X coordinate (H) and Y coordinate (L)
;   DE: window width (D) and window height (E)
; -------------------------------------
      IF  vertical=0
window  push    hl
        push    de
        ld      c, h
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      h, $16
        add     hl, hl
        add     hl, hl
        ld      b, 0
        add     hl, bc
windo1  ld      b, d
windo2  ld      (hl), a
        inc     hl
        djnz    windo2
        ld      c, d
        sbc     hl, bc
        ld      c, $20
        add     hl, bc
        dec     e
        jr      nz, windo1
        pop     de
        pop     hl
        ret
      ELSE
window  push    hl
        push    de
        ld      c, l;h
        push    af
        ld      a, 23
        sub     h
        ld      l, a
        pop     af
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      h, $16
        add     hl, hl
        add     hl, hl
        ld      b, 0
        add     hl, bc
        ld      c, e
        add     hl, bc

windo1  ld      b, e;d
windo2  dec     hl
        ld      (hl), a
        djnz    windo2
        ld      c, e
        add     hl, bc
        ld      bc, $ffe0
        add     hl, bc
        dec     d;e
        jr      nz, windo1
        pop     de
        pop     hl
        ret
      ENDIF

; -------------------------------------
; Change corwid and colcmb variables
; Parameters: PC
chcol   pop     hl
        ld      a, (hl)
        inc     hl
        ld      (corwid), a
        ld      a, (hl)
        inc     hl
        ld      (corwid+1), a
        ld      a, (hl)
        inc     hl
        ld      (colcmb), a
        ld      a, (hl)
        inc     hl
        ld      (colcmb-1), a
        jp      (hl)

; -------------------------------------
; Wait for a key
; Returns:
;    A: ascii code of the key
; -------------------------------------
waitky  ld      a, (codcnt)
        sub     $80
        jr      c, waitky       ; Espero la pulsación de una tecla
        ld      (codcnt), a
        ret

; -----------------------------------------------------------------------------
; ZX7 Backwards by Einar Saukas, Antonio Villena
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------
dzx7b   ld      bc, $8000
        ld      a, b
copyby  inc     c
        ldd
mainlo  add     a, a
        call    z, getbit
        jr      nc, copyby
        push    de
        ld      d, c
        defb    $30
lenval  add     a, a
        call    z, getbit
        rl      c
        rl      b
        add     a, a
        call    z, getbit
        jr      nc, lenval
        inc     c
        jr      z, exitdz
        ld      e, (hl)
        dec     hl
        sll     e
        jr      nc, offend
        ld      d, $10
nexbit  add     a, a
        call    z, getbit
        rl      d
        jr      nc, nexbit
        inc     d
        srl     d
offend  rr      e
        ex      (sp), hl
        ex      de, hl
        adc     hl, de
        lddr
exitdz  pop     hl
        jr      nc, mainlo
        ret

getbit  ld      a, (hl)
        dec     hl
        adc     a, a
        ret

drcs    inc     hl
        ld      b, $40          ; filtro RCS inverso
start4  ld      a, b
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
        inc     bc
      IF  vertical=0
        bit     3, b
        jr      z, start4
      ELSE
        ld      a, b
        sub     $58
        jr      nz, start4
        dec     a
      ENDIF
        ld      b, $13
        ldir
        ret


      IF  vertical=1
        incbin  bezel.rcs.zx7b
finbez  
      ENDIF


; ------------------------
; Load flash structures from $06000 to $9000  
; ------------------------
loadch  wreg    flash_cs, 1
        ld      de, config
        ld      hl, $0060   ;old $0aa0
        ld      a, $17

; ------------------------
; Read from SPI flash
; Parameters:
;   DE: destination address
;   HL: source address without last byte
;    A: number of pages (256 bytes) to read
; ------------------------
rdflsh  ex      af, af'
        xor     a
        push    hl
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 3    ; envio flash_spi un 3, orden de lectura
        pop     hl
        push    hl
        out     (c), h
        out     (c), l
        out     (c), a
        ex      af, af'
        ex      de, hl
        in      f, (c)
rdfls1  ld      e, $20
rdfls2  ini
        inc     b
        ini
        inc     b
        ini
        inc     b
        ini
        inc     b
        ini
        inc     b
        ini
        inc     b
        ini
        inc     b
        ini
        inc     b
        dec     e
        jr      nz, rdfls2
        dec     a
        jr      nz, rdfls1
        wreg    flash_cs, 1
        pop     hl
        ret

; -----------------------------------------------------------------------------
; Print string routine
; Parameters:
;  BC: X coord (B) and Y coord (C)
;  IX: null terminated string
; -----------------------------------------------------------------------------
      IF  vertical=0
prnstr  push    bc
        call    prnstr1
        pop     bc
        inc     c
        ret
prnstr1 ld      a, b
        and     %11111100
        ld      d, a
        xor     b
        ld      b, a
        ld      e, a
        jr      z, prnch1
        dec     e
prnch1  ld      a, d
        rrca
        ld      d, a
        rrca
        add     a, d
        add     a, e
        ld      e, a
        ld      a, c
        and     %00011000
        or      %01000000
        ld      d, a
        ld      a, c
        and     %00000111
        rrca
        rrca
        rrca
        add     a, e
        ld      e, a
        rr      b
        jr      c, pos26
        jr      nz, pos4
pos0    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $b0 >> 2
        ld      b, 8
        ld      l, a
        add     hl, hl
        add     hl, hl
pos01   ld      a, (hl)
        ld      (de), a
        inc     d
        inc     l
        djnz    pos01
        ld      hl, $f800
        add     hl, de
        ex      de, hl
pos2    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $bc >> 2
        ld      bc, $04fc
        call    doble
pos4    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $b8 >> 2
        ld      bc, $04f0
        call    doble
pos6    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $b4 >> 2
        ld      b, 8
        ld      l, a
        add     hl, hl
        add     hl, hl
pos61   ld      a, (de)
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        djnz    pos61
        ld      hl, $f801
        add     hl, de
        ex      de, hl
        jr      pos0
pos26   rr      b
        jr      c, pos6
        jr      pos2

doble   ld      l, a
        add     hl, hl
        add     hl, hl
doble2  ld      a, (de)
        xor     (hl)
        and     c
        xor     (hl)
        ld      (de), a
        inc     e
        ld      a, (hl)
        and     c
        ld      (de), a
        inc     d
        inc     l
        ld      a, (hl)
        and     c
        ld      (de), a
        dec     e
        ld      a, (de)
        xor     (hl)
        and     c
        xor     (hl)
        ld      (de), a
        inc     d
        inc     l
        djnz    doble2
        ld      hl, $f801
        add     hl, de
        ex      de, hl
        ret
      ELSE
prnstr  push    bc
        call    prnstr1
        pop     bc
        inc     c
        ret
prnstr1 ld      a, b
        add     a, b
        add     a, b
        add     a, a
        cpl
        add     a, 192
        ld      e, a
        rrca
        rrca
        rrca
        and     %00011000
        xor     e
        and     %11111000
        xor     e
        or      %01000000
        ld      d, a
        ld      a, e
        rlca
        rlca
        and     %11100000
        add     a, c
        ld      e, a
prnstr2 ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $b0 >> 2
        ld      b, 6
        ld      l, a
        add     hl, hl
        add     hl, hl
prnstr3 ld      a, (hl)
        ld      (de), a
        ld      a, d
        and     $07
        jr      nz, prnstr4
        ld      a, e
        sub     $20
        ld      e, a
        jr      c, prnstr4
        ld      a, d
        add     a, $08
        ld      d, a
prnstr4 dec     d
        inc     l
        djnz    prnstr3
        jr      prnstr2
      ENDIF


; -----------------------------------------------------------------------------
; 6x8 character set (128 characters x 1 rotation)
; -----------------------------------------------------------------------------
chrstr
      IF  vertical=0
        incbin  fuente6x8.bin
      ELSE
        incbin  fuente8x6.bin
      ENDIF
chrend

cad62   defb    'ZX Spectrum', 0

      IF 0
        block   $3000-$
bnames  defb  'Sam Coupe                       '
        defb  'Jupiter ACE                     '
        defb  'Master System                   '
        defb  'Atari 800 XL                    '
        defb  'BBC Micro                       '
        defb  'VIC-20                          '
        defb  'Acorn Electron                  '
        defb  'Oric Atmos                      '
        defb  'Apple 2 (VGA)                   '
      ENDIF
        block   $4000-$
