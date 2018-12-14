        include version.asm
        define  LX16            $32
        define  recovery        0
        define  recodire        0
        define  zesarux         0
        define  vertical        0
        output  firmware_strings.rom
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
        define  newreg          16
        define  ad724           $fb
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
        define  copt    cpuspd+1

        define  tmpbuf  $7800
        define  tmpbu2  $7880
        define  bnames  $a100
        define  stack   $aab0
        define  alto    $ae00-crctab+

        ld      sp, stack
        ld      a, scan_code
        ld      bc, zxuno_port
        out     (c), a
        inc     b
        in      f, (c)
        push    af
        ld      hl, sdtab
        ld      de, $b400-chrend+sdtab
        ei
        jp      start

rst18   jp      alto prnstr
        nop

jmptbl
      IF  recovery=0
        defw    main
        defw    roms
        defw    upgra
        defw    upgra
        defw    advan
        defw    exit
      ELSE
        defw    upgra
        defw    upgra
        defw    upgra
        defw    upgra
        defw    upgra
        defw    upgra
      ENDIF

rst28   ld      bc, zxuno_port + $100
        pop     hl
        outi
        ld      b, (zxuno_port >> 8)+2
        outi
        jp      (hl)

        nop
        nop
        nop
        nop
        nop

; ----------------------
; THE 'KEYBOARD' ROUTINE
; ----------------------
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
      IF  zesarux=0
        or      a
      ELSE
        xor     a
      ENDIF
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
        defb    $0c                     ; Break

start   ld      bc, chrend-sdtab
        ldir
      IF  recovery=0
        call    alto loadch
        ld      hl, (scanli)
        rrc     l
        add     hl, hl
        ld      a, (copt)
        rrca
        jr      nc, start0
        set     4, h
start0  ld      a, (outvid)
        ld      de, ad724<<8 | scandbl_ctrl
        ld      bc, zxuno_port
        out     (c), d
        inc     b
        out     (c), a
        dec     b
        out     (c), e
        inc     b
        rrca
        rrca
        ld      a, h
        adc     a, a
        or      $c0
        ld      (scnbak), a
        sub     $40             ; lo pongo a 14Mhz
        out     (c), a
        ld      de, fincad-1    ; descomprimo cadenas
        ld      hl, sdtab-1
        call    dzx7b
      ELSE
        wreg    scandbl_ctrl, $c0
      ENDIF
        im      1
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
        jr      nc, start1
        dec     e
      IF  recovery=0
        ld      a, (quietb)
        out     ($fe), a
        dec     a
        jr      nz, start3
        ld      h, l
        ld      d, $20
        call    window
        jr      start8
start3  ld      hl, finlog-1
        ld      d, $7a
        call    dzx7b           ; descomprimir
        call    drcs
        ld      bc, zxuno_port
        out     (c), a          ; a = $ff = core_id
        inc     b
        ld      hl, cad0+6      ; Load address of coreID string
start5  in      a, (c)
        ld      (hl), a         ; copia el caracter leido de CoreID 
        inc     hl
        ld      ix, cad0        ; imprimir cadena
        jr      nz, start5      ; si no recibimos un 0 seguimos pillando caracteres
        call    alto tstmem
        jr      z, star55
        ld      hl, cadmem
        ld      (hl), ' '
        inc     hl
        ld      (hl), ' '
        inc     hl
        dec     e
        jr      nz, star54
        dec     (hl)
star54  inc     hl
        ld      (hl), 'M'
star55  ld      a, (outvid)
        rrca
        jr      nc, star56
        wreg    master_conf, %01010000
star56  
      IF  vertical=0
        ld      bc, $090b
        call_prnstr             ; CoreID
        ld      c, b
        ld      ixl, cad1 & $ff ; imprimir cadenas BOOT screen
        call_prnstr             ; http://zxuno.speccy.org
        ld      bc, $020d
        call_prnstr             ; ZX-Uno BIOS version
        call_prnstr             ; Copyleft
        ld      bc, $0010       ; Copyleft (c) 2016 ZX-Uno Team
        call_prnstr             ; Processor
        call_prnstr             ; Memory
        call_prnstr             ; Graphics
        ld      b, $0b
        call_prnstr             ; hi-res, ULAplus
        push    bc
        ld      b, a
        call_prnstr             ; Booting
        ld      c, $17
        call_prnstr             ; Press <Edit> to Setup
      ELSE
        ld      bc, $040f
        call_prnstr             ; CoreID
        ld      c, $0c
        ld      ixl, cad1 & $ff ; imprimir cadenas BOOT screen
        call_prnstr             ; http://zxuno.speccy.org
        ld      bc, $0211
        call_prnstr             ; ZX-Uno BIOS version
        call_prnstr             ; Copyleft
        ld      bc, $0014       ; Copyleft (c) 2016 ZX-Uno Team
        call_prnstr             ; Processor
        call_prnstr             ; Memory
        call_prnstr             ; Graphics
        ld      b, $0b
        call_prnstr             ; hi-res, ULAplus
        push    bc
        ld      b, a
        call_prnstr             ; Booting
        ld      c, $1b
        call_prnstr             ; Press <Edit> to Setup
        call_prnstr             ; Press <Edit> to Setup
      ENDIF
        ld      hl, bitstr
        add     a, (hl)
        jr      z, start6
        dec     a
        call    cbname
        xor     a
        jr      start7
start6  dec     l
        ld      l, (hl)
        ld      l, (hl)
        call    calcu
        set     5, l
start7  ld      de, tmpbuf
        push    de
        pop     ix
        ld      c, $1f
        ldir
        ld      (de), a
        pop     bc
        call_prnstr             ; Imprime máquina (ROM o core)
      ENDIF
start8  
      IF  version=1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, $9f  ; jedec id
        in      a, (c)
        in      a, (c)
        in      a, (c)
        in      a, (c)
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        sub     $13
        cp      5
        jr      nz, start9
        ld      hl, alto subnn+1
        ld      (hl), 6*4
start9  ld      hl, $0800
star10  add     hl, hl
        dec     a
        jr      nz, star10
        ld      (alto fllen), hl
      ENDIF
    IF  recovery=0
star11  wreg    key_stat, 0
        ld      a, (layout)
        rr      a
        ld      hl, fines-1
        jr      z, star12
        ld      hl, finus-1
        jr      nc, star13
        ld      hl, finav-1
star12  jr      nc, star15
star13  ld      de, $cfff
        call    dzx7b
        wreg    key_map, 0
        ld      hl, $c001
star14  inc     b
        outi
        bit     4, h              ; compruebo si la direccion es D000 (final)
        jr      z, star14         ; repito si no lo es
star15  ld      d, 4
        pop     af
        jr      nz, star16
        ld      d, 16
star16  djnz    star18
        dec     de
        ld      a, d
        or      e
        jr      nz, star18
        wreg    scan_code, $f6  ; $f6 = kb set defaults
        halt
        halt
        wreg    scan_code, $ed  ; $ed + 2 = kb set leds + numlock
        halt
        wreg    scan_code, $02
        halt
        wreg    mouse_data, $f4 ; $f4 = init Kmouse
      IF  vertical=0
        ld      hl, $0017       ; Si se acaba el temporizador borrar
        ld      de, $2001       ; lo de presione Break
      ELSE
        ld      hl, $001b       ; Si se acaba el temporizador borrar
        ld      de, $2002       ; lo de presione Break
      ENDIF
        call    window
star17  ld      hl, (joykey)
        inc     h
        inc     l
        ld      a, h
        rlca
        rlca
        rlca
        rlca
        or      l
        ld      bc, zxuno_port
        ld      de, joy_conf<<8 | scandbl_ctrl
        out     (c), d
        inc     b
        out     (c), a
        ld      a, (cpuspd)
        rrca
        rrca
        or      $3f
        ld      hl, scnbak
        and     (hl)
        dec     b
        out     (c), e
        inc     b
        out     (c), a
        jp      conti

runbit0 ld      a, l
    IF  version=1
        cp      45
    ELSE
      IF  version=2
        cp      69
      ELSE
        cp      31
      ENDIF
    ENDIF
        jr      z, bios
runbit1 ld      (bitstr), a
        jr      star17

star18  ld      a, (codcnt)
star19  sub     $80
        jr      c, star16
        ld      (codcnt), a
        sub     '1'
        cp      9
        jr      c, runbit1
        jp      z, alto easter
        cp      $19-'1'
        jr      z, star20
        sub     $0c-'1'
star20  jp      z, blst
        sub     $1d-$0c
        jp      z, launch
        ld      hl, alto contia+1
        cp      $2f-$1d         ;'/'
        jr      nz, star20a
        out     ($fe), a
        ld      (hl), %01111111
star20a cp      $72-$1d         ; 'r'
        jr      nz, star20b
        out     ($fe), a
        ld      (hl), %11111101
        ld      a, %00000111
        ld      (contib+1), a
star20b cp      $17-$1d         ; 'Edit'
        jr      nz, star19
ELSE
        pop     af
star21  wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 6    ; envío write enable
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 1    ; envío write register status
        ld      hl, $0202
        ld      (menuop), hl
        out     (c), 0
        out     (c), l
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, $35  ; envío write register status
        in      a, (c)
        in      a, (c)
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        and     2
      IF  zesarux=0
        jr      z, star21
      ENDIF
        xor     a
    ENDIF

;++++++++++++++++++++++++++++++++++
;++++++++    Enter Setup   ++++++++
;++++++++++++++++++++++++++++++++++
bios    ld      a, %01001111    ; fondo azul tinta blanca
      IF  vertical=0
        ld      hl, $0017
        ld      de, $2001
        call    window
        ld      a, %00111001    ; fondo blanco tinta azul
        ld      l, h
        ld      e, $17
      ELSE
        ld      hl, $001f
        ld      de, $1801
        call    window
        ld      a, %00111001    ; fondo blanco tinta azul
        ld      l, h
        ld      de, $181f
      ENDIF
        call    window
      IF  recovery=0
        ld      (menuop), hl
      ENDIF
        call    clrscr          ; borro pantalla
        ld      ix, cad7
        call_prnstr             ; menu superior
        call_prnstr             ; borde superior
      IF  vertical=0
        ld      iyl, $14
      ELSE
        ld      iyl, $1c
      ENDIF
bios1   ld      ix, cad8
        call_prnstr             ; |        |     |
        dec     iyl
        jr      nz, bios1
        ld      ix, cad9
        call_prnstr             ; borde inferior
        call_prnstr             ; info
      IF  vertical=0
        ld      hl, %0111111001111110
        ld      ($55fc), hl
        ld      ($55fe), hl
        ld      ($56fc), hl
        ld      ($56fe), hl
        ld      hl, %0100111001001010
        ld      ($5afc), hl
        ld      hl, %0100110101001100
        ld      ($5afe), hl
      ELSE
        ld      hl, $411f
        ld      c, 4
bios2   ld      b, 6
bios25  ld      (hl), %00000110
        inc     h
        djnz    bios25
        ld      de, $fa20
        add     hl, de
        dec     c
        jr      nz, bios2
        ld      a, %01001010
        ld      ($587f), a
        ld      a, %01001110
        ld      ($585f), a
        dec     a
        ld      ($581f), a
        dec     a
        ld      ($583f), a
      ENDIF
bios3   ld      a, $07
        out     ($fe), a
        call    bios4
        jr      bios3
bios4   ld      a, %00111001    ; fondo blanco tinta azul
        ld      hl, $0102
      IF  vertical=0
        ld      de, $1814
        call    window
        ld      a, %01001111    ; fondo azul tinta blanca
        dec     h
        ld      l, h
        ld      de, $2001
        call    window
        di
        ld      c, $14
        ld      hl, $405f
        ld      d, b
        ld      e, b
bios5   ld      b, 8
bios6   ld      sp, hl
        push    de
        push    de
        push    de
        push    de
        push    de
        inc     sp
        push    de
        dec     sp
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        inc     h
        djnz    bios6
        ld      a, l
        add     a, $20
        ld      l, a
        jr      c, bios7
        ld      a, h
        sub     8
        ld      h, a
bios7   dec     c
        jr      nz, bios5
        ei
        ld      sp, stack-2
        ld      ix, cad11
        ld      bc, $1906
        call    prnmul          ; borde medio
        ld      h, a
      ELSE
        ld      de, $1614
        call    window
        ld      a, %01001111    ; fondo azul tinta blanca
        dec     h
        ld      l, h
        ld      de, $1801
        call    window
        di
        ld      bc, $16
        ld      hl, $403e
        ld      d, b
        ld      e, b
bios5   ld      b, 8
bios6   ld      sp, hl
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        push    de
        inc     h
        djnz    bios6
        ld      a, l
        add     a, $20
        ld      l, a
        jr      c, bios7
        ld      a, h
        sub     8
        ld      h, a
bios7   dec     c
        jr      nz, bios5
        ei
        ld      sp, stack-2
;;di borrado ei
        ld      h, 0
      ENDIF
        ld      a, (menuop)
        add     a, a
        add     a, jmptbl&$ff
        ld      l, a
        ld      c, (hl)
        inc     l
        ld      b, (hl)
        call    chcol
        defw    $1201
        defw    %0100011100111001
        ld      hl, (menuop)
        ld      l, 0
        push    bc
        ld      de, $0401
        ld      a, %01111001    ; fondo blanco tinta azul
        ret
  IF  recovery=0
    IF  vertical=0
launch  ld      (tmpbuf+21), a
        call    clrscr          ; borro pantalla
        inc     hl
        inc     de
      IF  version=1
        ld      c, $20
        ld      (hl), %00000111
        ldir
        ld      bc, $2e0
        ld      (hl), %01001111
        ldir
        ld      ix, cad118
        call_prnstr
        ld      ix, cad62   
        call_prnstr
      ELSE
        ld      bc, $300
        ld      (hl), %01001111
        ldir
        ld      hl, $5ae0
        ld      de, $5ae1
        ld      c, 20
        ld      (hl), %00000111
        ldir
        ld      ix, cad62   
        call_prnstr
        ld      c, 23
        ld      ix, cad118+8
        call_prnstr
        ld      c, 1
      ENDIF
        ld      de, bnames
laun1   ex      de, hl
        push    hl
        push    bc
        ld      de, tmpbuf
      IF  version=1
        ld      bc, 21
        ldir
      ELSE
        ld      bc, 14
        ldir
        ld      (de), a
      ENDIF
        ld      ix, tmpbuf
        pop     bc
        call_prnstr
        pop     hl
        ld      de, $0020
        add     hl, de
        ex      de, hl
        ld      hl, $a3c0
        sbc     hl, de
      IF  version=1
        jr      nz, laun2
        ld      bc, $1501
laun2   ld      hl, $a681
      ELSE
        jr      nz, laun2
        ld      bc, $0e00
laun2   ld      hl, $a6a1
        sbc     hl, de
        jr      nz, laun3
        ld      bc, $1c00
laun3   ld      hl, $a981
      ENDIF
        sbc     hl, de
        jr      nz, laun1
        ld      ix, cad6
        call_prnstr

        ld      hl, (active+1)
games   call    SELEC
        call    waitky
        cp      $0d
        jr      z, gamen
        cp      $20
gamen   jp      z, runbit0
        ld      bc, games
        push    bc
        call    SELEC
        ld      a, (codcnt)
        sub     $1c
        jr      z, gamup
        dec     a
        jr      z, gamdw
        dec     a
        jr      z, gamlf
        dec     a
        jr      z, gamrh
        sub    'a'-$1f
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
      IF  version=1
        cp      46
        ret     c
        dec     l
        ret
gamlf   ld      a, l
        ld      l, 0
        sub     23
        ret     c
        ld      l, a
        ret
gamrh   ld      a, l
        cp      23
        jr      c, gamrh1
        ld      a, 22
gamrh1  add     a, 23
        ld      l, a
        ret
SELEC   push    hl
        exx
        pop     hl
        inc     l
        ld      a, l
        cp      24
        ld      de, 0
        ld      b, 16
        jr      c, sel01
        ld      e, -23
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
        xor     %00110110
        ld      (hl), a
        inc     l
        djnz    sel02
        exx
        ld      a, l
        exx
sel03   sub     23
        jr      nc, sel03
        add     a, 24
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
      ELSE
        cp      70
        ret     c
        dec     l
        ret
gamlf   ld      a, l
        ld      l, 0
        sub     23
        ret     c
        ld      l, a
        ret
gamrh   ld      a, l
        cp      47
        jr      c, gamrh1
        ld      a, 46
gamrh1  add     a, 23
        ld      l, a
        ret
SELEC   push    hl
        exx
        pop     hl
        ld      a, l
        cp      23
        ld      de, 0
        ld      b, 11
        jr      c, sel01
        cp      46
        jr      nc, seli
        ld      e, -23
        add     hl, de
        ld      e, b
        dec     b
        jr      sel01
seli    ld      e, -46
        add     hl, de
        ld      e, 21
sel01   add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      h, $16
        add     hl, hl
        add     hl, hl
        add     hl, de
sel02   ld      a, (hl)
        xor     %00110110
        ld      (hl), a
        inc     l
        djnz    sel02
        exx
        ld      a, l
        cp      46
        ret     nc
        exx
sel03   sub     23
        jr      nc, sel03
        add     a, 23
        ld      c, a
        and     %00011000
        or      %01000000
        ld      d, a
        ld      a, c
        and     %00000111
        rrca
        rrca
        rrca
        add     a, $0a
        ld      e, a
        ld      b, 8
sel04   ld      a, (de)
        xor     7
        ld      (de), a
        inc     d
        djnz    sel04
sel05   exx
        ret
      ENDIF

    ELSE
launch  ld      (tmpbuf), a
        ld      hl, finbez-1
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
        inc     a
        ld      (tmpbuf), a
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
        ld      (ix+0), cad6&$ff
        ld      (ix+1), cad6>>8
        ld      (ix+3), a
        ld      a, (items+1)
        ld      e, a
        ld      d, 24
        call    chcol
        defw    $1203
        defw    %0111100001000111
        jp      bls375
    ENDIF
;++++++++++++++++++++++++++++++++++
;++++++++    Start ROM     ++++++++
;++++++++++++++++++++++++++++++++++
conti   di
        xor     a
        ld      hl, (active)
        cp      h
        jr      z, ccon0
runbit  ld      b, h
        call    calbit
        ld      bc, zxuno_port
        ld      e, core_addr
        out     (c), e
        inc     b
        out     (c), h
        out     (c), l
        out     (c), 0
        wreg    core_boot, 1
ccon0   ld      h, active>>8
        ld      l, (hl)
        call    calcu
        push    hl
        pop     ix
        ld      d, (ix+2)
        ld      hl, timing
        ld      a, (outvid)
        rrca
        ld      a, 3
        ld      b, a
        jr      c, ccon1
        cp      (hl)            ; timing
        ld      b, (hl)
        jr      nz, ccon1
        ld      b, d
ccon1   and     b               ; 0 0 0 0 0 0 MODE1 MODE0
        rrca                    ; MODE0 0 0 0 0 0 0 MODE1
        inc     l
        srl     (hl)            ; conten
        jr      z, ccon2
        bit     4, d
        jr      z, ccon2
        ccf
ccon2   adc     a, a            ; 0 0 0 0 0 0 MODE1 /DISCONT
        ld      l, keyiss & $ff
        rr      b
        adc     a, a            ; 0 0 0 0 0 MODE1 /DISCONT MODE0
        srl     (hl)            ; keyiss
        jr      z, ccon3
        bit     5, d
        jr      z, ccon3
        ccf
ccon3   adc     a, a            ; 0 0 0 0 MODE1 /DISCONT MODE0 /I2KB
        ld      l, nmidiv & $ff
        srl     (hl)            ; nmidiv
        jr      z, conti1
        bit     2, d
        jr      z, conti1
        ccf
conti1  adc     a, a            ; 0 0 0 MODE1 /DISCONT MODE0 /I2KB /DISNMI
        dec     l
        srl     (hl)            ; divmap
        jr      z, conti2
        bit     3, d
        jr      z, conti2
        ccf
conti2  adc     a, a            ; 0 0 MODE1 /DISCONT MODE0 /I2KB /DISNMI DIVEN
        add     a, a            ; 0 MODE1 /DISCONT MODE0 /I2KB /DISNMI DIVEN 0
        xor     d
        and     %01111111
        xor     d
        xor     %10101100       ; LOCK MODE1 DISCONT MODE0 I2KB DISNMI DIVEN 0
        ld      (alto conti9+1), a
        jp      alto micont

;****  Main Menu  ****
;*********************
main
      IF  vertical=0
        inc     d
        ld      h, l
        call    help
      ELSE
        ld      h, l
        call    window
      ENDIF
        ld      ix, cad10
        ld      bc, $0202
        call    prnmul          ; Harward tests ...
        ld      iy, quietb
        ld      bc, $0f0b
main1   call    showop
        defw    cad28
        defw    cad29
        defw    $ffff
        ld      a, iyl
        rrca
        jr      c, main1
main2   call    showop
        defw    cad30
        defw    cad31
        defw    cadv2
        defw    $ffff
main3   call    showop
        defw    cadv3
        defw    cadv4
        defw    cadv5
        defw    cadv2
        defw    $ffff
main4   call    showop
        defw    cad28
        defw    cad29
        defw    cadv2
        defw    $ffff
        ld      a, grapmo&$ff
        cp      iyl
        jr      nc, main4
        ld      de, $1201
        call    listas
        defb    $04
        defb    $05
        defb    $06
        defb    $07
        defb    $0b
        defb    $0c
        defb    $0d
        defb    $0e
        defb    $0f
        defb    $10
        defb    $11
        defb    $12
        defb    $ff
        defw    cad14
        defw    cad15
        defw    cad72
        defw    cad16
        defw    cad17
        defw    cad56
        defw    cad20
        defw    cad70
        defw    cad71
        defw    cad18
        defw    cad19
        defw    cad116
        jr      c, main9
        ld      (menuop+1), a
        cp      4
        ld      h, active >> 8
        jr      c, main8        ; c->tests, nc->options
        add     a, bitstr-3&$ff
        ld      l, a
        sub     keyiss&$ff
        jr      z, main5
        jr      nc, main6
        call    popupw          ; quiet or crc (enabled or disabled)
        defw    cad28
        defw    cad29
        defw    $ffff
        ret
main5   call    popupw          ; keyboard issue
        defw    cad30
        defw    cad31
        defw    cadv2
        defw    $ffff
        ret
main6   dec     a
        jr      nz, main7
        call    popupw          ; timming
        defw    cadv3
        defw    cadv4
        defw    cadv5
        defw    cadv2
        defw    $ffff
        ret
main7   call    popupw          ; contended, divmmc, nmidiv
        defw    cad28
        defw    cad29
        defw    cadv2
        defw    $ffff
        ret
main8   and     a
        jp      z, alto ramtst
        dec     a
        jr      nz, main17
        call    bomain
        ld      ix, cad114
        call_prnstr
        ld      a, $08
        ld      bc, $7ffe
main83  xor     $10
        out     ($fe), a
main86  dec     h
        jr      nz, main86      ; self loop to ld-wait (for 256 times)
        in      l, (c)
        bit     0, l
        jr      nz, main83
        ret
main9   cp      $0c
        call    z, roms8
        cp      $16
        call    z, romsa
        ld      hl, (menuop)
        cp      $1e
        jr      nz, main10
        dec     l
        jp      p, main13
main10  cp      $1f
        jr      nz, main11
        res     2, l
        dec     l
        jr      nz, main13
main11  ld      a, iyl
        dec     a
        ld      (menuop+1), a
        ret
main12  call    waitky
main13  ld      hl, (menuop)
        cp      $0c
        call    z, roms8
        cp      $16
        call    z, romsa
        sub     $1e
        jr      nz, main16
        dec     l
        jp      m, main12
main14  ld      a, l
        ld      h, 0
        dec     a
        jr      nz, main15
        ld      a, (active)
        ld      h, a
main15  ld      (menuop), hl
        ret
main16  dec     a
        jr      nz, main12
        inc     l
        ld      a, l
        cp      6
        jr      z, main12
        jr      main14
main17  dec     a
        jp      z, tape
        call    bomain
        ld      c, $12
        ld      ix, cad74
        call_prnstr
        ld      c, $15
        call_prnstr
      IF  vertical=0
        ld      de, $4861
        ld      a, '1'<<1
tkeys1  ld      l, a
        ld      h, $2c
        add     hl, hl
        add     hl, hl
        ld      b, 8
tkeys2  ld      a, (hl)
        ld      (de), a
        inc     l
        inc     d
        djnz    tkeys2
        ld      hl, $f802
        add     hl, de
        ex      de, hl
        ld      a, (ix)
        inc     ix
        add     a, a
        jr      nc, tkeys1
        ex      af, af'
        ld      a, $2c
        add     a, e
        ld      e, a
        jr      nc, tkeys3
        ld      d, $50
tkeys3  ex      af, af'
        jr      nz, tkeys1
tkeys4  add     a, $fe
        ld      de, $004a
        ld      hl, $5a6f-4
tkeys5  sbc     hl, de
        push    af
        in      a, ($fe)
        ld      b, 5
tkeys6  ld      (hl), 7
        rrca
        jr      c, tkeys7
        ld      (hl), $4e
tkeys7  inc     hl
        inc     hl
        djnz    tkeys6
        pop     af
        rlca
        cp      $ef
        jr      nz, tkeys5
        ld      l, $77-4
tkeys8  push    af
        in      a, ($fe)
        ld      b, 5
tkeys9  ld      (hl), 7
        rrca
        jr      c, tkeys10
        ld      (hl), $4e
tkeys10 dec     hl
        dec     hl
        djnz    tkeys9
        add     hl, de
        pop     af
        rlca
        jr      c, tkeys8
        ld      a, ($5a33)
        ld      e, a
        ld      a, ($5a21)
        add     a, e
        ret     m
        ld      l, $6b
        in      a, ($1f)
        cpl
        ld      b, 5
        call    tkeys11
        xor     a
        jr      tkeys4
tkeys11 dec     l
        dec     l
        rrca
tkeys12 ld      (hl), 7
        jr      c, tkeys13
        ld      (hl), $4e
tkeys13 djnz    tkeys11
        ret
      ELSE
        ld      de, $57cb
        ld      a, '1'<<1
tkeys1  ld      l, a
        ld      h, $2c
        add     hl, hl
        add     hl, hl
        ld      b, 6
tkeys2  ld      a, (hl)
        ld      (de), a
        inc     l
        dec     d
        djnz    tkeys2
        ld      hl, $05c0
        add     hl, de
        ld      a, l
        or      %00111111
        inc     a
        jr      nz, tkeys3
        ld      a, h
        sub     $07
        ld      h, a
tkeys3  ex      de, hl
        ld      a, (ix)
        inc     ix
        add     a, a
        jr      nc, tkeys1
        ld      hl, $1082
        add     hl, de
        ex      de, hl
        jr      nz, tkeys1
tkeys4  add     a, $fe
        ld      hl, $5993
tkeys5  ld      de, $013e
        add     hl, de
        push    af
        in      a, ($fe)
        ld      b, 5
tkeys6  ld      (hl), 7
        rrca
        jr      c, tkeys7
        ld      (hl), $4e
tkeys7  ld      de, $ffc0
        add     hl, de
        djnz    tkeys6
        pop     af
        rlca
        cp      $ef
        jr      nz, tkeys5
        ld      hl, $5a09
tkeys8  ld      de, $fe82
        add     hl, de
        push    af
        in      a, ($fe)
        ld      b, 5
tkeys9  ld      (hl), 7
        rrca
        jr      c, tkeys10
        ld      (hl), $4e
tkeys10 ld      de, $0040
        add     hl, de
        djnz    tkeys9
        add     hl, de
        pop     af
        rlca
        jr      c, tkeys8
        ld      a, ($5ad1)
        ld      e, a
        ld      a, ($5891)
        add     a, e
        ret     m
        ld      hl, $5b13
        in      a, ($1f)
        cpl
        ld      b, 5
        call    tkeys11
        xor     a
        jr      tkeys4
tkeys11 ld      de, $ffc0
        add     hl, de
        rrca
tkeys12 ld      (hl), 7
        jr      c, tkeys13
        ld      (hl), $4e
tkeys13 djnz    tkeys11
        ret
      ENDIF

tape    call    bomain
        ld      c, $14
        ld      ix, cad51
        call_prnstr             ; Press any key to continue
      IF  vertical=0
        ld      hl, $4881
      ELSE
        ld      hl, $4882
      ENDIF
        ld      de, $00ee
        ld      c, 8
tape1   ld      b, 18
tape2   ld      (hl), %00001111
        inc     l
        djnz    tape2
        add     hl, de
        dec     c
        jr      nz, tape1
        ld      hl, %0100100000001000
      IF  vertical=0
        ld      ($5968), hl
        ld      hl, %0000100001001000
        ld      ($596a), hl
      ELSE
        ld      ($5969), hl
        ld      hl, %0000100001001000
        ld      ($596b), hl
      ENDIF
tape3   ld      h, b
        ld      l, b
        ld      bc, $7ffe
        ld      de, $1820
tape4   in      a, (c)
        jp      po, tape5
        defb    $e2
tape5   ld      a, d
        inc     hl
        xor     $10
        out     (c), a
        djnz    tape4
        ld      a, (codcnt)
        sub     $80
        ret     nc
        dec     e
        jr      nz, tape4
        ld      a, h
        sub     7
        jr      nc, tape6
        xor     a
tape6   cp      17
        jr      z, tape7
        jr      c, tape8
        ld      a, 17
tape7   srl     l
tape8   
      IF  vertical=0
        add     a, $81
        rl      l
        ld      de, $5991
        ld      hl, $5992
      ELSE
        add     a, $82
        rl      l
        ld      de, $5992
        ld      hl, $5993
      ENDIF
        ld      c, $11
        ld      (hl), %01000000
        lddr
        ld      l, a
        ld      (hl), %01111111
        jr      nc, tape3
        ld      (hl), %01000111
        inc     l
        ld      (hl), %01111000
        jr      tape3

;****  Roms Menu  ****
;*********************
roms    push    hl
      IF  vertical=0
        ld      h, 5
      ELSE
        ld      h, 4
      ENDIF
        call    window
        ld      a, %00111000    ; fondo blanco tinta negra
        ld      hl, $0102
        ld      d, $12
        call    window
        ld      ix, cad12       ; Name Slot
        ld      bc, $0202
        call_prnstr
        call_prnstr
      IF  vertical=0
        ld      bc, $1503
        call_prnstr
        ld      bc, $1b0c
        call_prnstr
        call_prnstr
        ld      c, $10
        call_prnstr
        call_prnstr
        call_prnstr
        ld      c, $0e
        call_prnstr
        call_prnstr
      ENDIF
        ld      iy, indexe
        ld      ix, cmbpnt
        ld      de, tmpbuf
        ld      b, e
roms1   ld      l, (iy)
        inc     l
        jr      z, roms5
        dec     l
        call    calcu
        ld      c, (hl)
        set     5, l
        call    deixl
        ld      a, (active)
        cp      iyl
        ld      a, $1b
        jr      z, roms2
        ld      a, ' '
roms2   ld      (de), a
        inc     e
        inc     iyl
        ld      a, c
        ld      c, $17
        ldir
        ld      h, d
        ld      l, e
        inc     e
        ld      (hl), b
        dec     l
roms3   inc     c
        sub     10
        jr      nc, roms3
        add     a, 10+$30
        ld      (hl), a
        dec     l
        dec     c
        ld      a, $20
        jr      z, roms4
        ld      a, c
        add     a, $30
roms4   ld      (hl), a
        dec     l
        ld      (hl), $20
        jr      roms1
roms5   ld      (ix+1), $ff
        ld      d, $17
        ld      a, iyl
      IF  vertical=0
        cp      $12
        jr      c, roms6
        ld      a, $12
      ELSE
        cp      $1a
        jr      c, roms6
        ld      a, $1a
      ENDIF
roms6   ld      e, a
        pop     af
roms7   ld      hl, $0104
        call    combol
        ld      (menuop+1), a
        ld      a, (codcnt)
        sub     $0d
        jr      nc, roms9
roms8   push    af
        ld      a, 1
        call    exitg
        pop     af
        ret
roms9   jp      z, roms15
        sub     $16-$0d
        jr      nz, romsb
romsa   push    af
        call    exitg
        pop     af
        ret
romsb   sub     $1e-$16
        jp      z, roms27
        dec     a
        jp      z, roms27
        sub     'n'-$1f         ; n= New Entry
        jp      nz, roms144
        call    qloadt
        ld      ix, cad54
        call_prnstr
        dec     c
        ld      a, %01000111    ; fondo blanco tinta azul
        ld      h, $12
        ld      l, c
        ld      de, $0201
        call    window
        ld      c, l
        ld      hl, $0200
        ld      b, $18
        call    inputv
        ld      a, (codcnt)
        rrca
        ret     nc
        call    loadta
        ei
        jp      nc, roms12
        call    atoi
        ld      b, (ix-$3f)
romsb6  ld      e, 0
isbusy  ld      h, indexe>>8
        ld      l, e
        inc     e
        ld      l, (hl)
        inc     l
        jr      z, romsb7
        dec     l
        call    calcu
        inc     l
        ld      c, (hl)
        dec     l
isbus1  cp      (hl)
        jr      z, isbus2
        dec     a
        dec     c
        jr      nz, isbus1
        inc     l
        add     a, (hl)
        jr      isbusy
isbus2
      IF  vertical=0
        ld      bc, $090a
      ELSE
        ld      bc, $0510
      ENDIF
        ld      ix, cad115
        call_prnstr
        call_prnstr
        call_prnstr
        jp      waitky
romsb7  inc     a
        djnz    romsb6
        ld      hl, %00001010
romsc   ld      (offsel), hl
        ld      bc, $7ffd
        out     (c), h
        call    prsta1
        push    bc
        inc     (ix-8)
        ld      ix, $c000
        ld      de, $4000
        call    lbytes
        pop     bc
        dec     c
        jp      nc, roms12
        ld      b, $17
        ld      ix, cad53
        call_prnstr
        ld      hl, (offsel)
        inc     h
        rr      l
        jr      nc, romsd
        inc     h
romsd   dec     iyh
        jr      nz, romsc
        ei
        call    romcyb
        call    newent
        call    atoi
        ld      (items), a
        ld      (hl), a
        inc     l
        ex      de, hl
        ld      hl, tmpbuf
        ld      a, (hl)
        ld      iyh, a
        ld      c, $1f
        ldir
        ld      c, $20
        ld      l, tmpbuf+$31 & $ff
        ldir
        ld      hl, %00001010
roms10  ld      (offsel), hl
        ld      bc, $7ffd
        out     (c), h
        ld      hl, $c000
        exx
        ld      hl, items
        ld      a, (hl)
        inc     (hl)
        call    alto slot2a
        ex      de, hl
        ld      a, $40
        call    wrflsh
        exx
        ld      hl, (offsel)
        inc     h
        rr      l
        jr      nc, roms11
        inc     h
roms11  dec     iyh
        jr      nz, roms10
        ret
  ENDIF
roms12  call    romcyb
        ld      ix, cad50
roms13  call_prnstr
        call    romcyb
toanyk  ei
        ld      ix, cad51
        call_prnstr
        jp      waitky
      IF  recovery=0
roms144 sub     'q'-'n'         ; q= move item up
        jr      nz, nmovup
        ld      a, (menuop+1)
        jr      moveup
nmovup  add     a, 'q'-'a'
        ld      a, (menuop+1)
        jr      z, movedw
        jp      roms7
roms15  ld      hl, tmpbuf
        ld      (hl), 1
roms16  call    popupw
        defw    cad32
        defw    cad33
        defw    cad34
        defw    cad35
        defw    cad36
        defw    $ffff
        ld      a, (codcnt)
        sub     $0e
        jr      nc, roms16
        inc     a
        ret     nz
        ld      a, (menuop+1)
        ld      b, (hl)
        inc     b
        djnz    roms1a
moveup  or      a               ; move up
        ret     z
        ld      hl, active
        ld      b, (hl)
        cp      b
        jr      nz, roms17
        dec     (hl)
roms17  dec     a
        cp      b
        jr      nz, roms18
        inc     (hl)
roms18  ld      (menuop+1), a
roms19  ld      l, a
        ld      a, (hl)
        inc     l
        ld      b, (hl)
        ld      (hl), a
        dec     l
        ld      (hl), b
        ret
roms1a  djnz    roms1b
        ld      (active), a     ; set active
        ret
roms1b  djnz    roms1f
movedw  ld      b, a            ; move down
        call    nument
        sub     2
        cp      b
roms1c  ret     z
        ld      a, b
        ld      l, active & $ff
        ld      b, (hl)
        cp      b
        jr      nz, roms1d
        inc     (hl)
roms1d  inc     a
        cp      b
        jr      nz, roms1e
        dec     (hl)
roms1e  ld      (menuop+1), a
        dec     a
        jr      roms19
roms1f  djnz    roms23
        ld      l, a            ; rename
        ld      h, indexe >> 8
        ld      a, (hl)
        inc     a
        ld      l, a
        call    calcu
        push    hl
        ld      de, empstr
        call    str2tmp
      IF  vertical=0
        ld      hl, $0309
        ld      de, $1b07
      ELSE
        ld      hl, $020d
        ld      de, $1507
      ENDIF
        ld      a, e            ;%00000111 fondo negro tinta blanca
        call    window
        dec     h
        dec     l
        ld      a, %01001111    ; fondo azul tinta blanca
        call    window
      IF  vertical=0
        sub     l               ; fondo negro tinta blanca
        ld      iyl, 2
        ld      hl, $030c
        ld      de, $1801
        call    window
        ld      bc, $0208
      ELSE
        ld      a, %01000111    ; fondo negro tinta blanca
        ld      iyl, 2
        ld      hl, $0310
        ld      de, $1201
        call    window
        ld      bc, $010c
      ENDIF
        call_prnstr
        call_prnstr
        call_prnstr
roms20  push    ix
        call_prnstr
        pop     ix
        dec     iyl
        jr      nz, roms20
        call_prnstr
        call_prnstr
      IF  vertical=0
        ld      bc, $040c
        ld      hl, $20ff
        call    inputs
        ld      hl, $1708
        ld      de, $0708
        ld      a, %00111001    ; fondo blanco tinta azul
        call    window
      ELSE
        xor     a
        ld      (empstr+23), a
        ld      bc, $0410
        ld      hl, $17ff
        call    inputs
        ld      b, 0
      ENDIF
        ld      a, (codcnt)
        cp      $0c
        pop     hl
        jr      z, roms1c
        ld      a, (items)
        or      a
        jr      z, roms1c
        ld      c, a
        sub     32
        jr      z, roms22
        cpl
roms21  dec     hl
        ld      (hl), 32
        dec     a
        jp      p, roms21
roms22  dec     l
        ex      de, hl
        ld      h, empstr>>8
        ld      a, empstr-1&$ff
        add     a, c
        ld      l, a
        lddr
        ret
roms23  ld      hl, active      ; delete
        cp      (hl)
        jr      c, roms24
        ld      l, (hl)
        inc     l
        ld      b, (hl)
        inc     b
        jr      nz, roms25
        dec     l
        ret     z
        ld      l, $20
roms24  dec     (hl)
roms25  ld      l, a
roms26  inc     l
        ld      a, (hl)
        dec     l
        ld      (hl), a
        inc     l
        or      a
        jp      p, roms26
        add     a, l
        ld      hl, menuop+1
        cp      (hl)
        ret     nz
        dec     (hl)
        ret
roms27  ld      hl, $0104
        ld      d, $12
        ld      a, (items+1)
        ld      e, a
        ld      a, %00111001
        call    window
        ld      a, (codcnt)
        jp      main13
      ENDIF

;*** Upgrade Menu ***
;*********************
upgra 
      IF  recovery=1
        ld      ix, cad117
        ex      af, af'
        call    prnhel
upgra0  in      a, ($1f)
        jr      nz, upgra0
        ld      de, $0401
        ld      a, %01111001    ; fondo blanco tinta azul
        ld      l, 0
      ENDIF
        ld      bc, (menuop)
      IF  vertical=0
        ld      h, 16
        dec     c
        dec     c
        jr      nz, upgra1
        ld      h, 9
        ld      d, 7
upgra1  push    af
        call    help
        pop     af
      ELSE
        ld      h, 12
        ld      d, 3
        dec     c
        dec     c
        jr      nz, upgra1
        ld      h, 8
        ld      d, 4
upgra1  push    af
        call    window
        pop     af
      ENDIF
        ld      de, tmpbuf
        ld      ix, cmbpnt
        ld      hl, cad60
        jr      z, upgr17
        ld      l, cad62 & $ff
        ld      a, (bitstr)
        or      a
        jr      nz, upgr17
        call    deixl
        ld      a, $1b
        defb    $ca
upgr15  ld      a, (hl)
        inc     hl
upgr16  ld      (de), a
        inc     de
        or      a
        jr      nz, upgr15
upgr17  call    deixl
        ld      a, cad63 & $ff
        sub     l
        ld      a, ' '
        jr      nz, upgr16
        ld      hl, bnames
        ld      iyl, 1
upgra3  inc     iyl
        ld      a, (menuop)
        dec     a
        dec     a
        jr      z, upgr31
        ld      a, (bitstr)
        inc     a
        cp      iyl
        ld      a, $1b
        jr      z, upgr32
upgr31  ld      a, ' '
upgr32  ld      (de), a
        ld      a, iyl
        inc     de
        ld      bc, 23
        ldir
        ex      de, hl
        ld      (hl), b
        dec     hl
upgr33  inc     c
        sub     10
        jr      nc, upgr33
        add     a, 10+$30
        ld      (hl), a
        dec     hl
        dec     c
        ld      a, ' '
        jr      z, upgr34
        ld      a, c
        add     a, $30
upgr34  ld      (hl), a
        dec     hl
        ld      (hl), ' '
        ld      c, 4
        add     hl, bc
        ex      de, hl
        ld      c, 8
        add     hl, bc
        ld      a, (hl)
        inc     hl
        call    deixl
        or      a
        jr      nz, upgra3
        ld      hl, (menuop)
        dec     l
        dec     l
    IF  recovery=0
        ld      a, (alto fllen+1)
        or      l
        ld      a, ixl
        rra
        jr      nz, upgr35
    IF  version=1
        cp      45+5
    ELSE
      IF  version=2
        cp      69+5
      ELSE
        cp      31+5
      ENDIF
    ENDIF
        jr      z, upgr35
        inc     a
        ld      (ix-4), cad119 & $ff
        ld      (ix-3), cad119 >> 8
        call    deixl1
upgr35  ld      (ix-3), $ff
        dec     a
        dec     a
      IF  vertical=0
        cp      20
        jr      c, upgr38
        ld      a, 20
      ELSE
        cp      $1c
        jr      c, upgr38
        ld      a, $1c
      ENDIF
upgr38  ld      e, a
    ELSE
        ld      (ix-3), $ff
        ld      e, 4
    ENDIF
        dec     l
        ld      a, h
        jr      nz, upgra4
        ld      a, (bitstr)
upgra4  ld      hl, $0102
        ld      d, $18
      IF  recodire=0
        call    combol
      ELSE
        ld      a, 2
      ENDIF
        ld      (menuop+1), a
        inc     a
        ld      iyl, a
      IF  recovery=0
        ld      a, (codcnt)
        cp      $0d
        jp      nz, main9
      ENDIF
        ld      hl, (menuop)
        dec     l
        dec     l
        jr      z, upgra6
        ld      a, h
        ld      (bitstr), a
        ret
upgra6  dec     h
        dec     h
        jp      nz, upgra7

tosd    ld      ix, cad75
      IF  vertical=0
        call    prnhel
      ENDIF
        call    imyesn
        ld      ix, cad445
      IF  recodire=0
        call    yesno
        ret     nz
      ELSE
        ld      c, 8
        call_prnstr
        call_prnstr
      ENDIF
        ld      d, h
        ld      a, %01001111    ; fondo azul tinta blanca
        call    window
        ld      iyl, 6
        call    prstat
        ld      ix, cad76
        inc     c
        inc     c
        call_prnstr
        di
        ;wreg    master_conf, 2        ; enable divmmc
;        ld      hl, SET_BLOCKLEN<<8 | 2
;        call    cs_low
;        out     (c), h
;        out     (c), 0
;        out     (c), 0
;        out     (c), l
;        call    send1z

        call    mmcinit
        jp      nz, errsd

        ;sbc     hl, hl                ; read MBR
        ld   hl, 0
        ld      ix, tmpbu2
        call    readat0

        ld      a, (tmpbu2)           ; read first type
        sub     $e0
        cp      $0b
        jr      z, tosd0
        ld      hl, (tmpbu2+$1c6)     ; read LBA address of 1st partition
        ld      a, (tmpbu2+$1c2)      ; read partition type
tosd0   push    af
        call    readata               ; read boot sector with BPB
        push    hl
        ld      a, (menuop+1)
        ld      b, a
        inc     a
        dec     b
        dec     b
        push    af
        call    calbi1
        pop     af
        ld      (tmpbu2+$1e), hl
        ld      b, a
        ld      hl, alto sdtab-4
        cp      4
        push    af
        jr      c, tosd1
        ld      b, 4
tosd1   cp      b
        ld      a, files&$ff
        jr      z, tosd3
tosd2   add     a, 11
tosd3   inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    tosd2
        ld      de, tmpbu2+$1a
        ld      (de), a
        inc     de
        ld      a, files>>8
        ld      (de), a
        inc     de
        ldi
        ldi
        pop     af
        jr      nc, tosd4
        ldi
        ldi
tosd4   sub     3
        ld      hl, fileco+4
tosd45  inc     b
        sub     10
        jr      nc, tosd45
        add     a, 10+$30
        ld      (hl), a
        inc     l
        ld      (hl), ' '
        djnz    tosd46
        cp      '1'
        jr      nz, tosd5
        dec     (ix+$1c)
        jr      tosd5
tosd46  ld      (hl), a
        dec     l
        ld      a, b
        add     a, $30
        ld      (hl), a
tosd5   ld      bc, SPI_PORT
        pop     de
        pop     af
        cp      $0b
        jr      z, fatxx
        and     $f5
        sub     4
        jr      z, fatxx        ; 04,06,0b,0c,0e -> FAT32
errsd   ld      ix, cad77
ferror  ;wreg    master_conf, 0
      IF  vertical=0
        ld      bc, $090d
      ELSE
        ld      bc, $0510
      ENDIF
        call_prnstr
        ld      a, cad80 & $ff
        cp      ixl
        ei
twaitk  jp      nz, waitky
        ld      a, (menuop+1)
        sub     4
        jr      c, twaitk
        call    cbname
        ld      bc, $0020
        add     hl, bc
        ld      de, empstr
        call    str2tmp
        ld      ix, cad82
      IF  vertical=0
        ld      bc, $090a
        call_prnstr
        ld      a, %00000111    ; fondo negro tinta blanca
        ld      hl, $060b
        ld      de, $1201
        call    window
        ld      bc, $080b
        ld      hl, $20ff
        call    inputs
        ld      a, (items)
        add     a, empstr&$ff
        ld      l, a
        ld      h, empstr>>8
        ld      bc, $20
        ld      (hl), c
      ELSE
        ld      bc, $050d
        call_prnstr
        ld      a, %00000111    ; fondo negro tinta blanca
        ld      hl, $030e
        ld      de, $1201
        call    window
        ld      bc, $040e
        ld      hl, $1aff
        xor     a
        ld      (empstr+$1a), a
        call    inputs
        ld      a, (items)
        add     a, empstr&$ff
        ld      l, a
        ld      h, empstr>>8
        ld      bc, $1a
        ld      (hl), $20
      ENDIF
        ld      l, empstr&$ff
        ld      de, tmpbuf+$31
        ldir
        jp      savena

fatxx   ld      hl, (tmpbu2+$0e)      ; count of reserved logical sectors
        add     hl, de                ; LBA address+reserved
        ld      (items), hl           ; write FAT table address
        ex      de, hl
        ld      hl, (tmpbu2+$16)      ; sectors per FAT
        ld      a, l
        or      h
        jr      z, fat32
fat16   add     hl, hl                ; 2*FAT
        add     hl, de                ; LBA+reserved+2*FAT
        ex      de, hl
        ld      hl, (tmpbu2+$11)      ; max FAT entries in root
        ld      b, 4
div8    rr      h
        rr      l
        djnz    div8
        ld      b, l                  ; B= (max entries in sectors)*2
        add     hl, de                ; LBA+reserved+2*FAT+entries in sectors
        ld      (offsel), hl          ; data= LBA+reserved+2*FAT+entries
        ex      de, hl                ; root= LBA+reserved+2*FAT
        ld      ix, $c000
rotp    call    readat0               ; read 512 bytes of entries (16 entries)
        call    buba                  ; search filename (FLASH) in entries
        jr      z, saba               ; if found ($20) or EOF ($00), exit
        djnz    rotp
erfnf   ld      ix, cad78
terror  jp      ferror
saba
      IF  version=2
        sub     LX16
      ELSE
        sub     $30+version
      ENDIF
        jr      nz, erfnf
        call    testl
        jr      nz, erfnf             ; wrong length
        ld      l, (ix+$1a)           ; first cluster of the file
        ld      h, (ix+$1b)
        ld      ix, $e000
bucop   push    hl                    ; save current cluster
        ld      b, e
        call    calcs                 ; translate cluster to address
        call    trans                 ; copy from data address to SPI flash
        pop     hl                    ; recover current cluster
        push    ix                    ; save buffer position
        ld      ix, tmpbuf+$200       ; small buffer to read FAT
        push    hl
        ld      l, h
        ld      h, 0
        ld      de, (items)           ; fat address
        add     hl, de
        call    readat0
        pop     hl
        ld      h, (tmpbuf+$200)>>9   ; hl= fatad/2  llllllll
        add     hl, hl                ; hl= (fatad)l lllllll0
        ld      a, (hl)
        inc     l
        ld      h, (hl)
        ld      l, a                  ; next cluster in hl
        and     h
        inc     a                     ; cluster==FFFF
        pop     ix
        jr      nz, bucop
enbur   
      IF  vertical=0
        ld      bc, $090a
      ELSE
        ld      bc, $050d
      ENDIF
        ld      ix, cad785
        call_prnstr
        jr      terror
fat32   ld      hl, (tmpbu2+$24)      ; Logical sectors per FAT
        add     hl, hl
        add     hl, de
        ld      (offsel), hl
        ld      hl, (tmpbu2+$2c)
tica    push    hl
        push    bc
        call    calcs
        ld      a, (tmpbu2+$d)
        ld      b, a
        ld      ix, $c000
otve    call    readata
        call    buba
        jr      z, sabe
        djnz    otve
        pop     bc
        pop     hl
        add     hl, hl
        rl      b
        ld      ix, tmpbuf+$200
        push    hl
        ld      l, h
        ld      h, b
        ld      de, (items)
        add     hl, de
        call    readat0
        pop     hl
        ld      h, (tmpbuf+$200)>>9
        add     hl, hl
        ld      e, (hl)
        inc     l
        ld      d, (hl)
        inc     l
        ld      b, (hl)
        ex      de, hl
        ld      a, l
        and     h
        and     b
        inc     a
        jr      nz, tica
erfnf2  jp      erfnf
sabe    pop     bc
        pop     hl
      IF  version=2
        sub     LX16
      ELSE
        sub     $30+version
      ENDIF
        jr      nz, erfnf2
        call    testl
        jr      nz, erfnf2
        ld      b, (ix+$14)
        ld      l, (ix+$1a)
        ld      h, (ix+$1b)
        ld      ix, $e000
bucap   push    hl
        call    calcs
        call    trans
        pop     hl
        push    ix
        ld      ix, tmpbuf+$200
        add     hl, hl
        rl      b
        push    hl
        ld      l, h
        ld      h, b
        ld      de, (items)
        add     hl, de
        call    readat0
        pop     hl
        ld      h, (tmpbuf+$200)>>9
        add     hl, hl
        ld      e, (hl)
        inc     l
        ld      d, (hl)
        inc     l
        ld      b, (hl)
        ex      de, hl
        ld      a, l
        and     h
        and     b
        inc     a
        pop     ix
        jr      nz, bucap
        jp      enbur

testl   or      a, (ix+$1c)           ; third byte of length
        ret     nz
        push    de
        ld      e, (ix+$1d)
        ld      d, (ix+$1e)
        ld      a, e
        or      d
        jr      nz, test1
        dec     (ix+$1f)
        jr      nz, test2
test1   ld      hl, (tmpbu2+$1c)
        sbc     hl, de
        jr      nz, test2
        cp      $3f
        jr      nz, nzxco
        inc     a
        ld      (tmpbu2+$1c), a
nzxco   xor     a
test2   pop     de
        ret

calcs   push    bc
        call    decbhl
        call    decbhl
        ld      a, (tmpbu2+$d)
        jr      calc2
calc1   add     hl, hl
        rl      b
calc2   rrca
        jr      nc, calc1
        ld      de, (offsel)
        add     hl, de
        ld      a, b
        adc     a, 0
        ld      e, a
        pop     bc
        ret


buba    push    bc
        push    de
        push    hl
        ld      hl, $c000
        ld      b, 16
bubi    push    bc
        ld      b, 11
        ld      a, (hl)
        or      a
        jr      z, sali
        ld      de, (tmpbu2+$1a)
        push    hl
buub    ld      a, (de)
        cp      (hl)
        inc     hl
        inc     de
        jr      nz, beeb
        djnz    buub
        pop     ix
sali    pop     bc
        jr      desc
beeb    pop     hl
        pop     bc
        ld      de, $0020
        add     hl, de
        djnz    bubi
        ld      a, d
desc    pop     hl
        inc     hl
        pop     de
        pop     bc
        ret

trans   push    bc
        ld      a, (tmpbu2+$d)
        ld      b, a
        ld      a, (tmpbu2+$1d)
        or      a
        jr      nz, otva
        ld      a, (tmpbu2+$1c)
        rrc     a
        jr      z, otva
        cp      b
        jr      nc, otva
        ld      b, a
otva    call    readata
        inc     ixh
        inc     ixh
        jr      nz, putc0
        push    bc
        push    hl
        push    de
        ld      hl, (tmpbu2+$1c)
        ld      de, $ffe0
        add     hl, de
        ld      (tmpbu2+$1c), hl
        ld      hl, tmpbuf+$59
        ld      a, (tmpbu2+$1f)
otv2    call    alto subnn
        inc     hl
        jr      nc, otv2
        ld      (hl), 'o'
        ld      iyl, 1
        call    prsta1
        ld      de, (tmpbu2+$1e)    ; SPI address, initially 0000
        exx
        ld      a, $20
        ld      hl, $e000
        exx
        call    wrflsh
        inc     de
        ld      (tmpbu2+$1e), de
        exx
        ld      ix, $e000
        pop     de
        pop     hl
        pop     bc
putc0   inc     hl
        djnz    otva
        pop     bc
        ret

        include sd.asm

upgra7  ld      hl, items
      IF  vertical=0
        ld      (hl), b
      ELSE
        ld      (hl), 0
      ENDIF
upgr75  call    popupw
        defw    cad80
        defw    cad81
        defw    $ffff
        ld      a, (codcnt)
        sub     $0e
        jr      nc, upgr75
        inc     a
        ld      a, (hl)
        rrca
        call    chcol
        defw    $1201
        defw    %0100011100111001
        ret     nz
        jp      c, tosd
        call    loadta
        jr      nc, upgra8
        ld      hl, (menuop+1)
        dec     l
        jr      z, upgra9
        jp      p, upgrac

;upgrade ESXDOS
        call    prsta1
        ld      ix, $e000
        ld      de, $2000
        call    lbytes
upgra8  jp      nc, roms12
        ld      bc, $170a
        ld      ix, cad53
        call_prnstr
        ld      hl, $e000
        call    alto check0
        ld      hl, (tmpbuf+7)
        sbc     hl, de
        jr      nz, upgraa
        ld      a, $20
        ld      hl, $e000
        exx
        ld      de, $0040
        call    wrflsh
        call    romcyb
        ld      ix, cad59
        jr      upgrab

;upgrade BIOS
upgra9  cp      $31
upgraa  jp      nz, roms12
        ld      a, (tmpbuf+2)
        cp      $ca
        jr      nz, upgraa
        call    prsta1
        ld      ix, $c000
        ld      de, $4000
        call    lbytes
        jr      nc, upgra8
        ld      bc, $170a
        ld      ix, cad53
        call_prnstr
        call    alto check
        ld      hl, (tmpbuf+7)
        sbc     hl, de
        jr      nz, upgraa
        ld      a, $40
        ld      hl, $c000
        exx
        ld      de, $0080
        call    wrflsh
        call    romcyb
        ld      ix, cad58
upgrab  jp      roms13

prstat  ld      de, tmpbuf+$52
        ld      hl, cad63
        ld      bc, cad64-cad63
        ldir
prsta1  call    romcyb
        ld      ix, tmpbuf+$52
        call_prnstr
        ret

;upgrade machine
upgrac  cp      $43
        jr      c, upgraa
        cp      $46
        jr      nc, upgraa
        ld      b, l
        dec     b
        djnz    upgrae
        ld      a, (tmpbuf+2)
        cp      $cb
upgrad  jr      nz, upgraa
upgrae  call    calbit
        push    hl
        call    prstat
        push    iy
upgrag  ld      a, (tmpbuf+$65 & $ff)*2
        sub     iyh
        rra
        ld      l, a
        ld      h, tmpbuf>>8
        ld      (hl), 'o'
        jr      c, upgrah
        ld      (hl), '-'
upgrah  and     a
        call    shaon
        ld      ix, $4000
        ld      de, $4000
        call    lbytes
        ex      af, af'
        ld      a, 30
        sub     iyh
        call    alto copyme
        jr      nz, upgrad
        call    shaoff
        ex      af, af'
        jp      nc, roms12
        dec     iyl
        call    prsta1
        dec     iyh
        jr      nz, upgrag
        pop     iy
        call    shaon
        pop     de
        exx
upgrai  ld      a, 30
        sub     iyh
        call    alto saveme
        ld      a, $40
        ld      hl, $4000
        exx
        call    wrfls0
        inc     de
        exx
        dec     iyh
        jr      nz, upgrai
        call    savena
        call    shaoff
        call    romcyb
        ld      ix, cad57
        jp      roms13

      IF  recovery=0
;*** Advanced Menu ***
;*********************
advan
      IF  vertical=0
        ld      h, 20
        ld      d, 8
        call    help
      ELSE
        ld      h, 15
        ld      d, 5
        call    window
      ENDIF
        ld      ix, cad83
        ld      bc, $0202
        call    prnmul
        ld      bc, $0f04
        ld      iy, layout
        call    showop          ; Keyb Layout
        defw    cad875
        defw    cad88
        defw    cad89
        defw    cad90
        defw    $ffff
advan1  call    showop          ; Joy Keypad & DB9
        defw    cad91
        defw    cad92
        defw    cad93
        defw    cad94
        defw    cad95
        defw    cad955
        defw    $ffff
        ld      a, iyl
        rrca
        jr      nc, advan1
        ld      c, $0b
        call    showop          ; Output
        defw    cad96
        defw    cad97
        defw    cad98
        defw    $ffff
        call    showop          ; Scanlines
        defw    cad28
        defw    cad29
        defw    $ffff
        call    showop          ; VSync frequency
        defw    cad102
        defw    cad103
        defw    cad104
        defw    cad105
        defw    cad106
        defw    cad107
        defw    cad108
        defw    cad109
        defw    $ffff
        call    showop          ; CPU Speed
        defw    cad110
        defw    cad111
        defw    cad112
        defw    cad113
        defw    $ffff
        call    showop          ; CSync
        defw    cad90
        defw    cad96
        defw    $ffff
        ld      de, $1201
        call    listas
        defb    $04
        defb    $05
        defb    $06
        defb    $0b
        defb    $0c
        defb    $0d
        defb    $0e
        defb    $0f
        defb    $ff
        defw    cad84
        defw    cad85
        defw    cad86
        defw    cad87
        defw    cad99
        defw    cad100
        defw    cad101
        defw    cad10a
        jp      c, main9
        ld      (menuop+1), a
        ld      hl, layout
        ld      e, a
        add     hl, de
        jr      nz, advan2
        call    popupw          ; Keyb Layout
        defw    cad875
        defw    cad88
        defw    cad89
        defw    cad90
        defw    $ffff
        ret
advan2  ld      b, a
        djnz    advan3
        call    popupw          ; Joy Keypad
        defw    cad91
        defw    cad92
        defw    cad93
        defw    cad94
        defw    cad95
        defw    $ffff
        ret
advan3  djnz    advan4
        call    popupw          ; Joy DB9
        defw    cad91
        defw    cad92
        defw    cad93
        defw    cad94
        defw    cad95
        defw    cad955
        defw    $ffff
        ret
advan4  djnz    advan5
        call    popupw          ; Output
        defw    cad96
        defw    cad97
        defw    cad98
        defw    $ffff
        ret
advan5  djnz    advan6
        call    popupw          ; Scanlines
        defw    cad28
        defw    cad29
        defw    $ffff
        ret
advan6  djnz    advan7
        call    popupw          ; VSync frequency
        defw    cad102      
        defw    cad103
        defw    cad104
        defw    cad105
        defw    cad106
        defw    cad107
        defw    cad108
        defw    cad109
        defw    $ffff
        ret
advan7  djnz    advan8
        call    popupw          ; CPU Speed
        defw    cad110
        defw    cad111
        defw    cad112
        defw    cad113
        defw    $ffff
        ret
advan8  call    popupw          ; CSync
        defw    cad90
        defw    cad96
        defw    $ffff
        ret


;****  Exit Menu  ****
;*********************
exit    
      IF  vertical=0
        ld      h, 28
        call    help
      ELSE
        ld      h, 20
        call    window
      ENDIF
        ld      ix, cad37
        ld      bc, $0202
        call_prnstr
        call_prnstr
        call_prnstr
        call_prnstr
        ld      de, $1201
        call    listas
        defb    $02
        defb    $03
        defb    $04
        defb    $05
        defb    $ff
        defw    cad38
        defw    cad39
        defw    cad40
        defw    cad41
        jp      c, main9
        ld      (menuop+1), a
exitg   ld      (colcmb+1), a
        call    imyesn
        ld      a, (colcmb+1)
        ld      b, a
        djnz    exit1
        ld      ix, cad46
exit1   djnz    exit2
        ld      ix, cad47
exit2   djnz    exit3
        ld      ix, cad48
exit3   call    yesno
        ret     nz
        ld      a, (colcmb+1)
        ld      b, a
        djnz    exit4
        call    alto loadch
        jr      exit7
exit4   djnz    exit5
        jp      savech
exit5   djnz    exit6
        jp      alto loadch
exit6   call    savech
exit7   jp      star11

;++++++++++++++++++++++++++++++++++
;++++++++     Boot list    ++++++++
;++++++++++++++++++++++++++++++++++
blst    call    clrscr          ; borro pantalla
        ld      h, bnames-1>>8
        ld      c, $20
        ld      a, c
blst0   add     hl, bc
        inc     e
        cp      (hl)
        jr      z, blst0
        ld      a, (codcnt)
        ld      (tmpbuf), a
        rrca
        inc     e
        ld      a, e
        ld      l, a
        call    nc, nument
      IF  vertical=0
        cp      13
        jr      c, blst1
        ld      a, 13
blst1   ld      h, a
        ld      (items), hl
        add     a, -16
      ELSE
        cp      21
        jr      c, blst1
        ld      a, 21
blst1   ld      h, a
        ld      (items), hl
        add     a, -24
      ENDIF
        cpl
        rra
        ld      l, a
        ld      a, h
        add     a, 7
        ld      e, a
        ld      a, %01001111    ; fondo azul tinta blanca
        ld      h, $01          ; coordenada X
      IF  vertical=0
        ld      d, $1c          ; anchura de ventana
      ELSE
        ld      d, $16          ; anchura de ventana
      ENDIF
        push    hl
        call    window
        ld      ix, cad2
        pop     bc
        inc     b
        call_prnstr
        call_prnstr
        call_prnstr
        push    bc
        ld      iy, (items)
blst2   ld      ix, cad4
        call_prnstr             ; |                |
        dec     iyh
        jr      nz, blst2
        ld      ix, cad3
        call_prnstr             ; |----------------|
        ld      ix, cad5 
        call_prnstr
        call_prnstr
        call_prnstr
        ld      hl, cad62
        ld      (cmbpnt), hl
        ld      iy, indexe
        ld      ix, cmbpnt
        ld      de, tmpbuf
        ld      b, e
        ld      hl, bnames
        ld      a, (de)
        rrca
        jr      c, bls31
blst3   ld      l, (iy)
        inc     l
        call    calcu
        call    addbls
        jr      nc, blst3
        jr      bls37
bls31   call    addbl1
bls33   ld      c, $20
        add     hl, bc
        call    addbls
        jr      nc, bls33
bls37   ld      (ix+0), cad6&$ff
        ld      (ix+1), cad6>>8
        ld      (ix+3), a
        ld      a, (items+1)
        ld      e, a
      IF  vertical=0
        ld      d, 32
        call    chcol
        defw    $1a02
        defw    %0100011101001111
      ELSE
        ld      d, 25
        call    chcol
        defw    $1402
        defw    %0100011101001111
      ENDIF
bls375  ld      a, (cmbpnt+1)
        rlca
        ld      hl, (active)
        ld      a, h
        jr      c, bls38
        ld      a, l
bls38   pop     hl
        ld      h, 4
blst4   call    combol
        ld      b, a
        ld      a, (codcnt)
        sub     $0d
        ld      (bitstr), a
        ld      a, b
;        jr      c, blst5
        jr      nz, blst4
        ld      a, (items)
        dec     a
        cp      b
        ld      a, $17
        jp      z, bios
        ld      a, (cmbpnt+1)
        rlca
        ld      a, b
        ld      (active), a
        jr      nc, blst5
        ld      (bitstr), a
blst5   jp      star17
      ENDIF

imyesn  call    bloq1
        ld      ix, cad42
        call_prnstr
        call_prnstr
        call_prnstr
        call_prnstr
        ret

; ------------------------------------
; Calculate start address of bitstream
;    B: number of bitstream
; Returns:
;   HL: address of bitstream
; ------------------------------------
calbit  inc     b
      IF  version=1
calbi1  ld      a, 9
        cp      b
        ld      hl, $0040
        jr      nc, calbi2
        ld      hl, $0b80
calbi2  ld      de, $0540
      ELSE
calbi1  ld      a, b        ;1-69
        sub     35
        jr      c, calbi2   ;<35 c n
        ld      b, a        ;>=35 nc n-35
calbi2  ccf
        push    bc
        push    af
        adc     a, a
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 6    ; envío write enable
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, $c5  ; envío wrear
        out     (c), a
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        pop     af
        or      a
        pop     bc
        ld      hl, $0240
        ret     z
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

      IF  recovery=0
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
      ENDIF

;first part of loadta
qloadt
      IF  vertical=0
        ld      ix, cad49
        call    prnhel
        call    bloq1
        dec     c
        dec     c
      ELSE
        call    bloq1
        ld      bc, $040c
      ENDIF
        ld      iyl, 5
loadt1  ld      ix, cad42
        call_prnstr
        dec     iyl
        jr      nz, loadt1
      IF  vertical=0
        ld      ixl, cad43 & $ff
        call_prnstr
        ld      ixl, cad44 & $ff
        ld      c, b
      ELSE
        ld      ix, cad43
        call_prnstr
        ld      ixl, cad44 & $ff
        ld      c, $0b
      ENDIF
        call_prnstr

; -------------------------------------
; Prits a blank line in the actual line
; -------------------------------------
romcyb  ld      a, iyl
romcy1  sub     5
        jr      nc, romcy1
      IF  vertical=0
        add     a, 5+9
        ld      c, a
        inc     iyl
        ld      b, 8
      ELSE
        add     a, 5+12
        ld      c, a
        inc     iyl
        ld      b, 4
      ENDIF
        ld      ix, cad42
        call_prnstr
        inc     b
        dec     c
        ret

; -------------------------------------
; Generates a determined box with shadow
; -------------------------------------
      IF  vertical=0
bloq1   ld      hl, $0709
        ld      de, $1207
        ld      a, %00000111     ;%00000111 fondo negro tinta blanca
        call    window
        dec     h
        dec     l
        ld      a, %01001111    ; fondo azul tinta blanca
        call    window
        ld      bc, $080b
      ELSE
bloq1   ld      hl, $040c
        ld      de, $1207
        ld      a, %00000111     ;%00000111 fondo negro tinta blanca
        call    window
        dec     h
        dec     l
        ld      a, %01001111    ; fondo azul tinta blanca
        call    window
        ld      bc, $040e
      ENDIF
        ret

; -------------------------------------
;  Carry: 0 -> from 4000 to C000, shadow on , pre  page
;         1 -> from C000 to 4000, shadow off, post page
; -------------------------------------
shaoff  scf
shao1   ld      bc, $4000
        ld      d, b
        ld      e, c
        ld      hl, $c000
        jr      c, shao2
        ex      de, hl
shao2   ldir
        ret     nc
        ld      a, $07
        defb    $d2
shaon   ld      a, $0f
        ld      bc, $7ffd
        out     (c), a
        jr      nc, shao1
        ret

; -------------------------------------
; Shows the window of Load from Tape
; -------------------------------------
loadta  call    qloadt
        ld      ix, cad45
        call_prnstr
        ld      ix, tmpbuf
        ld      de, $0051
        call    lbytes
        ld      bc, $1109
        ret     nc
        ld      hl, tmpbuf+$3e
        ld      a, (hl)
        push    af
        ld      (hl), 0
        ld      ixl, $31
        call_prnstr
        pop     af
        ld      (tmpbuf+$3e), a
        ld      de, tmpbuf+$52
        ld      hl, cad52
        ld      bc, cad53-cad52
        ldir
        ld      a, (tmpbuf)
        ld      iyh, a
        sub     $d0
        ld      (tmpbuf+$5d), a
        ret

; -------------------------------------
; Yes or not dialog
;    A: if 0 preselected Yes, if 1 preselected No
; Returns:
;    A: 0: yes, 1: no
; -------------------------------------
yesno
      IF  vertical=0
        ld      bc, $0808
        call_prnstr
        call_prnstr
        call_prnstr
yesno0  inc     a
yesno1  ld      ixl, a
yesno2  ld      hl, $0b0d
      ELSE
        ld      bc, $040b
        call_prnstr
        call_prnstr
        call_prnstr
yesno0  inc     a
yesno1  ld      ixl, a
yesno2  ld      hl, $0810
      ENDIF
        ld      de, $0801
        ld      a, %01001111    ; fondo azul tinta blanca
        call    window
        sub     d               ; %01000111 fondo negro tinta blanca
        ld      d, 3
        ld      b, ixl
        djnz    yesno3
      IF  vertical=0
        ld      h, $11
      ELSE
        ld      h, $0e
      ENDIF
        dec     d
yesno3  call    window
        call    waitky
        add     a, $100-$1f
        jr      nz, yesno4
        add     a, ixl
        jr      z, yesno0
yesno4  inc     a
        jr      nz, yesno5
        dec     a
        add     a, ixl
        jr      z, yesno1
yesno5  add     a, $1e-$0c
        cp      2
        jr      nc, yesno2
        ld      a, (codcnt)
        sub     $0d
        ret     nz 
        ld      a, ixl
        and     a
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
; Read number of boot entries
; Returns:
;    A: number of boot entries
; -------------------------------------
nument  ld      hl, indexe
numen1  ld      a, (hl)         ; calculo en L el número de entradas
        inc     l
        inc     a
        jr      nz, numen1
        ld      a, l
        ret

; -------------------------------------
; Input a string by the keyboard
; Parameters:
; empstr: input and output string
;     HL: max length (H) and cursor position (L)
;     BC: X coord (B) and Y coord (C)
; -------------------------------------
inputv  xor     a
        ld      (empstr), a
inputs  ld      (offsel), hl
input1  push    bc
        ld      ix, empstr
        call_prnstr
        push    ix
        pop     hl
        ld      a, l
        sub     empstr+1&$ff
        ld      (items), a
        ld      r, a
        ld      e, a
        add     a, b
        ld      b, a
        ld      a, (offsel)
        inc     a
        jr      nz, input2
        ld      a, e
        ld      (offsel), a
input2  ld      de, (offsel)
        ld      e, ' '
        defb    $32
input3  ld      (hl), e
        inc     l
        ld      a, l
        sub     empstr+2&$ff
        sub     d
        jr      nz, input3
        ld      (hl), a
        dec     c
        call_prnstr
        pop     bc
input4  ld      a, r
        cpl
        ld      r, a
        call    cursor
        ld      h, $80
input5  ld      a, (codcnt)
        sub     $80
        jr      nc, input7
        dec     l
        jr      nz, input5
        dec     h
        jr      nz, input5
input6  jr      input4
input7  ld      (codcnt), a
        cp      $0e
        jr      nc, input8
        ld      a, r
        ret     p
      IF  vertical=0
cursor  ld      a, (offsel)
        add     a, b
        ld      l, a
        and     %11111100
        ld      d, a
        xor     l
        ld      h, $80
        ld      e, a
        jr      z, curso1
        dec     e
curso1  xor     $fc
curso2  rrc     h
        rrc     h
        inc     a
        jr      nz, curso2
        ld      a, d
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
        ld      l, $08
curso3  ld      a, (de)
        xor     h
        ld      (de), a
        inc     d
        dec     l
        jr      nz, curso3
        ret
      ELSE
cursor  ld      a, (offsel)
        add     a, b
        ld      e, a
        add     a, e
        add     a, e
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
curso3  ld      a, (de)
        cpl
        ld      (de), a
        ret
      ENDIF
input8  ld      hl, (offsel)
        cp      $18
        jr      nz, input9
        dec     l
        jp      m, input1
        ld      (offsel), hl
        ld      a, 33
        sub     l
        push    bc
        ld      c, a
        ld      b, 0
        ld      a, l
        add     a, empstr&$ff
        ld      l, a
        ld      h, empstr>>8
        ld      d, h
        ld      e, l
        inc     l
        ldir
        pop     bc
        jr      inputc
input9  sub     $1e
        jr      nz, inputb
        dec     l
        jp      m, input1
inputa  jp      inputs
inputb  dec     a
        ld      a, (items)
        jr      nz, inputd
        cp      l
        jr      nz, inpute
inputc  jp      input1
inputd  cp      h
        jr      z, input6
        ld      a, l
        add     a, empstr&$ff
        ld      l, a
        ld      h, empstr>>8
        ld      a, (codcnt)
        inc     (hl)
        dec     (hl)
        jr      nz, inputf
        ld      (hl), a
        inc     l
        ld      (hl), 0
inpute  ld      hl, (offsel)
        inc     l
        jr      inputa
inputf  ex      af, af'
        ld      a, empstr+33&$ff
        sub     l
        push    bc
        ld      c, a
        ld      b, 0
        ld      l, empstr+32&$ff
        ld      de, empstr+33
        lddr
        inc     l
        ex      af, af'
        ld      (hl), a
        pop     bc
        jr      inpute

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
; Show a normal list only in attribute area width elements
; in not consecutive lines
; Parameters:
;    A: preselected one
;   PC: list of Y positions
;   DE: window width (D) and X position (E)
; Returns:
;    A: item selected
;    Carry on: if no Enter pressed
; -------------------------------------
listas  ld      a, (menuop+1)
        inc     a
        ld      iyl, a
        pop     hl
        push    hl
        xor     a
        defb    $32
lista1  inc     hl
        inc     a
        inc     (hl)
        jr      nz, lista1
        ld      ixl, a
        pop     hl
lista2  ld      iyh, iyl
        ld      ixh, ixl
        push    hl
        push    de
lista3  push    hl
        ld      l, (hl)
        ld      h, e
        ld      e, 1
        ld      a, %00111001    ; fondo blanco tinta azul
        dec     iyh
        jr      nz, lista4
        ld      a, %01000111
lista4  call    window
        pop     hl
        inc     hl
        dec     ixh
        jr      nz, lista3
        ld      a, iyl
        add     a, a
        ld      c, a
        add     hl, bc
        push    ix
      IF  vertical=0
        ld      a, (hl)
        ld      ixh, a
        dec     hl
        ld      a, (hl)
        ld      ixl, a
        call    prnhel
      ELSE
        call    waitky
        ld      a, (codcnt)
        cp      $0d
        jr      z, listaa
        jr      lista55
      ENDIF
        call    waitky
        ld      a, (codcnt)
        cp      $0d
        jr      z, listaa
        ld      ix, lista5
; -------------------------------------
; Deletes the upper right area (help)
; -------------------------------------
delhel  di
        ld      c, $9
        ld      hl, $405f
        ld      de, 0
delhe1  ld      b, 8
delhe2  ld      sp, hl
        push    de
        push    de
        push    de
        push    de
        push    de
        inc     sp
        push    de
        inc     h
        djnz    delhe2
        ld      a, l
        add     a, $20
        ld      l, a
        jr      c, delhe3
        ld      a, h
        sub     8
        ld      h, a
delhe3  dec     c
        jr      nz, delhe1
        ei
        jp      (ix)
lista5  ld      sp, stack-8
lista55 pop     ix
        pop     de
        pop     hl
        ld      a, (codcnt)
        cp      $1c
        jr      nz, lista7
        ld      a, iyl
        dec     a
        jr      z, lista2
lista6  ld      iyl, a
        jr      lista2
lista7  cp      $1d
        jr      nz, lista8
        ld      a, iyl
        cp      ixl
        jp      nc, lista2
        inc     a
        jr      lista6
lista8  push    ix
        pop     de
        add     hl, de
        add     hl, de
        add     hl, de
        inc     hl
lista9  scf
        jp      (hl)
listaa  pop     de
        pop     hl
        pop     hl
        add     hl, de
        add     hl, de
        add     hl, de
        inc     hl
        ld      a, iyl
        dec     a
        jp      (hl)

; restore background color in recovery dialog
resto   ld      a, %01001111    ; fondo azul tinta blanca
        ld      hl, $0208
rest1   ld      de, $1b08
        
        
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
; Prints an option between some strings
; Parameters:
; (iy): option to print
;   PC: list of pointers to options (last is $ffff)
showop  ld      a, (iy)
        inc     a
        pop     hl
        defb    $fe
showo1  dec     a
        push    hl
        call    z, alto prnstr
        pop     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        push    de
        pop     ix
        inc     d
        jr      nz, showo1
        inc     iyl
        jp      (hl)

; -------------------------------------
; Draw a pop up list with options
; Parameters:
;   PC: list of pointers to options (last is $ffff)
;   HL: pointer to variable item
; -------------------------------------
popupw  exx
        pop     hl
        ld      de, cmbpnt
        ldi
popup1  ldi
        ldi
        inc     (hl)
        jr      nz, popup1
        ldi
        push    hl
        srl     e
        ld      a, e
        dec     a
        ld      iyl, a
      IF  vertical=0
        add     a, -24
        cpl
        rra
        ld      l, a
        ld      h, $16
      ELSE
        add     a, -32
        cpl
        rra
        ld      l, a
        ld      h, $13
      ENDIF
        ld      d, 1
        ld      a, %00000111    ; fondo negro tinta blanca
        call    window
        ld      a, e
        inc     e
        ld      h, e
        push    hl
        add     a, l
        ld      l, a
      IF  vertical=0
        ld      h, $0a
      ELSE
        ld      h, $07
      ENDIF
        ld      de, $0d01
        ld      a, %00000111    ; fondo negro tinta blanca
        call    window
        pop     hl
        ld      e, h
        dec     l
      IF  vertical=0
        ld      h, $09
      ELSE
        ld      h, $06
      ENDIF
        push    de
        push    hl
        ld      a, %01001111    ; fondo azul tinta blanca
        call    window
        ld      ix, cad21
      IF  vertical=0
        ld      b, $0c
      ELSE
        ld      b, $08
      ENDIF
        ld      c, l
        call_prnstr
popup2  ld      ix, cad22
        call_prnstr
        dec     iyl
        jr      nz, popup2
        call_prnstr
        call    chcol
      IF  vertical=0
        defw    $0b0a
      ELSE
        defw    $0b07
      ENDIF
        defw    %0100011101001111
        pop     hl
        pop     de
        inc     l
        ld      a, h
      IF  vertical=0
        add     a, 5
      ELSE
        add     a, 4
      ENDIF
        ld      h, a
        dec     e
        dec     e
        exx
        ld      a, (hl)
        exx
        call    combol
        exx
        ld      (hl), a
        ret

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

; ------------------------
; Clear the screen
; ------------------------
clrscr  ld      hl, $4000
        ld      de, $4001
        ld      bc, $17ff
        ld      (hl), l
        ldir
        ret

; -------------------------------
; Prints some lines, end with 0,0
; -------------------------------
prnhel  ld      bc, $1b02
prnmul  call_prnstr
        add     a, (ix)
        jr      nz, prnmul
        inc     ix
        ret

      IF  recovery=0
bomain  ld      ix, cad65
        ld      bc, $0209
        call_prnstr             ; Performing...
        inc     c
        ld      iyh, 8
ramts1  ld      ixl, cad66&$ff
        call_prnstr
        dec     iyh
        jr      nz, ramts1
        ret

; create a new ROM entry
newent  call    nument
        dec     l
        ld      e, l
        ld      a, -1
romst   inc     a
        ld      b, e
        ld      l, 0
romsu   cp      (hl)
        jr      z, romst
        inc     l
        djnz    romsu
        ld      (hl), a
        ld      l, a

; points to the ROM table, input L entry, output HL
calcu   add     hl, hl
        add     hl, hl
        ld      h, 9
        jp      alto slot2c
      ENDIF

savena  ld      a, (menuop+1)
        sub     4
        ret     c
        call    cbname
        ex      de, hl
        ld      hl, tmpbuf+$31
        ld      bc, 32
        ldir

; ------------------------
; Save flash structures from $9000 to $06000 and from $a000 to $07000 
; ------------------------
savech  ld      a, $20
        ld      hl, config
        exx
        ld      de, $0060   ;old $0aa0

; ------------------------
; Write to SPI flash
; Parameters:
;    A: number of pages (256 bytes) to write
;   DE: target address without last byte
;  HL': source address from memory
; ------------------------
wrflsh  
      IF  version=2
        push    af
        adc     a, a
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 6    ; envío write enable
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, $c5  ; envío wrear
        out     (c), a
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        pop     af
      ENDIF
wrfls0  ex      af, af'
wrfls1  wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 6    ; envío write enable
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, $20  ; envío sector erase
        out     (c), d
        out     (c), e
        out     (c), 0
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
wrfls2  call    waits5
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 6    ; envío write enable
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 2    ; page program
        out     (c), d
        out     (c), e
        out     (c), a
        ld      a, $20
        exx
        ld      bc, zxuno_port+$100
wrfls3  inc     b
        outi
        inc     b
        outi
        inc     b
        outi
        inc     b
        outi
        inc     b
        outi
        inc     b
        outi
        inc     b
        outi
        inc     b
        outi
        dec     a
        jr      nz, wrfls3
        exx
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        ex      af, af'
        dec     a
        jr      z, waits5
        ex      af, af'
        inc     e
        ld      a, e
        and     $0f
        jr      nz, wrfls2
        ld      hl, wrfls1
        push    hl
waits5  wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 5    ; envío read status
        in      a, (c)
waits6  in      a, (c)
        and     1
        jr      nz, waits6
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        ret

cbname  ld      h, bnames>>13
        ld      l, a
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        inc     h
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

get16   ld      b, 0
        call    lsampl
        call    lsampl
        cp      12
        adc     hl, hl
        jr      nc, get16
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

; Parameters:
;(empstr): input string
; Returns:
;       A: binary number
      IF  recovery=0
atoi    push    hl
        ld      hl, items
        ld      b, (hl)
        ld      l, empstr & $ff
        xor     a
romse   add     a, a
        ld      c, a
        add     a, a
        add     a, a
        add     a, c
romsf   add     a, (hl)
        inc     l
        sub     $30
        djnz    romse
        pop     hl
        ret
      ENDIF

      IF  0
hhhh    push    af
        push    bc
        push    de
        push    hl
        push    ix
        push    iy
        pop     hl
        push    hl
        ld      de, cad199+44
        call    alto wtohex
        ld      iy, 0
        add     iy, sp
        ld      l, (iy+2)
        ld      h, (iy+3)
        ld      de, cad199+37
        call    alto wtohex
        ld      l, (iy+4)
        ld      h, (iy+5)
        ld      de, cad199+23
        call    alto wtohex
        ld      l, (iy+6)
        ld      h, (iy+7)
        ld      de, cad199+16
        call    alto wtohex
        ld      l, (iy+8)
        ld      h, (iy+9)
        ld      de, cad199+9
        call    alto wtohex
        ld      l, (iy+10)
        ld      h, (iy+11)
        ld      de, cad199+2
        call    alto wtohex
        ld      ix, cad199
        ld      bc, $0030
        call    alto prnstr
        pop     iy
        pop     ix
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret
;binf jr binf        
      ENDIF

  IF  recovery=0
        incbin  es.zx7b
fines   incbin  us.zx7b
finus   incbin  av.zx7b
finav
; -----------------------------------------------------------------------------
; Compressed and RCS filtered logo
; -----------------------------------------------------------------------------
    IF version=1
      IF  vertical=0
        incbin  logo256x192.rcs.zx7b
      ELSE
        incbin  bezel.rcs.zx7b
finbez  incbin  logo192x256.rcs.zx7b
      ENDIF
    ELSE
      IF  vertical=0
        incbin  logo256x192d.rcs.zx7b
      ELSE
        incbin  bezel.rcs.zx7b
finbez  incbin  logo192x256d.rcs.zx7b
      ENDIF
    ENDIF
finlog  incbin  strings.bin.zx7b
  ENDIF

; -----------------------------------------------------------------------------
; Compressed messages
; -----------------------------------------------------------------------------
sdtab   defw    $0020, $0040
        defw    $0040, $0080
fllen   defw    $0000, $0000
      IF  version=1
        defw    $0540
subnn   sub     6
      ELSE
        defw    $0740
subnn   sub     6*4
      ENDIF
        ret
      IF  recovery=0
micont  wreg    master_conf, 1
        and     $02
        jr      z, conti4
        wreg    master_mapper, 12
        ld      hl, $0040
        ld      de, $c000
        ld      a, $20
        call    alto rdflsh
        ld      a, 16
conti3  ld      de, $c000 | master_mapper
        dec     b
        out     (c), e
        inc     b
        push    bc
        out     (c), a
        ld      bc, $3fff
        ld      hl, $c000
        ld      (hl), l
        ldir
        pop     bc
        inc     a
        cp      24
        jr      nz, conti3
conti4  ld      iyl, 8
conti5  ld      a, (ix)
        inc     (ix)
        call    alto slot2a
        ld      a, master_mapper
        dec     b
        out     (c), a
        inc     b
        ld      a, iyl
        inc     iyl
        out     (c), a
        ld      de, $c000
        ld      a, $40
        call    alto rdflsh
        ld      a, (checkc)
        dec     a
        jr      nz, conti8
        push    ix
        push    bc
        call    alto check
        ld      a, (ix+1)
        add     a, a
        add     a, ixl
        ld      ixl, a
        ld      l, (ix+6)
        ld      h, (ix+7)
        sbc     hl, de
        jr      z, conti7
        add     hl, de
        push    de
        ld      de, cad55+33
        call    alto wtohex
        pop     hl
        ld      e, cad55+19&$ff
        call    alto wtohex
        ld      ix, cad55
        ld      bc, $0015
        call    alto prnstr
        call    alto prnstr
        ld      c, $fe
conti6  in      a, (c)
        or      $e0
        inc     a
        jr      z, conti6
conti7  pop     bc
        pop     ix
conti8  dec     (ix+1)
        jr      nz, conti5
conti9  ld      a, 0
contia  and     %11111111
        dec     b
        out     (c), 0;d
        inc     b
        out     (c), a
        dec     b
        ld      a, dev_control
        out     (c), a
        inc     b
        ld      a, (ix+3)
        out     (c), a
        dec     b
        ld      a, dev_control2
contib  or      %00000000
        out     (c), a
        inc     b
        ld      a, (grapmo)
        srl     a
        jr      c, contic
        ld      a, 7            ; Resv Resv Resv Resv Resv DIRADAS DITIMEX DIULAPLUS
        jr      z, contic
        ld      a, (ix+4)
contic  out     (c), a
        rst     0
      ENDIF
; -------------------------------------
; Detect memory size
;      E: 00000000-> 512K
;         00000001-> 1M
;         00000011-> 2M
; -------------------------------------
tstmem  ld      de, newreg<<8 | %00000000
        wreg    master_conf, 1
        wreg    master_mapper, $48
        ld      a, ($c000)
        sub     $31
        jr      z, tstme1
        scf
tstme1  rl      e
        wreg    master_mapper, $28
        ld      a, ($c000)
        sub     $31
        jr      z, tstme2
        scf
tstme2  rl      e
        wreg    master_conf, 0
        dec     b
        out     (c), d
        inc     b
        out     (c), e
        or      e
        ret

; -------------------------------------
; Put page A in mode 1 and copies from 4000 to C000
;      A: page number
; -------------------------------------
copyme  wreg    master_conf, 1
        ld      de, $c000 | master_mapper
        dec     b
        out     (c), e
        inc     b
        out     (c), a
        dec     e
        push    bc
        ld      bc, $4000
        ld      h, b
        ld      l, c
        ldir
        call    alto check
        pop     bc
        wreg    master_conf, 0
        ld      a, iyh
        add     a, a
        add     a, 5
        ld      l, a
        ld      h, tmpbuf>>8
        ld      c, (hl)
        inc     l
        ld      b, (hl)
        ex      de, hl
        sbc     hl, bc
        ret

; -------------------------------------
; Put page A in mode 1 and copies from C000 to 4000
;      A: page number
; -------------------------------------
saveme  wreg    master_conf, 1
        ld      hl, $c000 | master_mapper
        dec     b
        out     (c), l
        inc     b
        out     (c), a
        dec     l
        push    bc
        ld      bc, $4000
        ld      d, b
        ld      e, c
        ldir
        pop     bc
        wreg    master_conf, 0
        ret

easter  di
        ld      a, (scnbak)
        and     %00111111
        call    setvid
        wreg    master_conf, 1
        jp      $0100

      IF  recovery=0
; ------------------------
; Load flash structures from $06000 to $9000  
; ------------------------
loadch  
      IF  version=2
        and     a
      ENDIF
        wreg    flash_cs, 1
        ld      de, config
        ld      hl, $0060   ;old $0aa0
        ld      a, $1a
      ENDIF

; ------------------------
; Read from SPI flash
; Parameters:
;   DE: destination address
;   HL: source address without last byte
;    A: number of pages (256 bytes) to read
; ------------------------
      IF  version=1
rdflsh  push    hl
      ELSE
rdflsh  push    hl
        push    af
        adc     a, a
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 6    ; envío write enable
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, $c5  ; envío wrear
        out     (c), a
        wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
        pop     af
      ENDIF
        wreg    flash_cs, 0     ; activamos spi, enviando un 0
        wreg    flash_spi, 3    ; envio flash_spi un 3, orden de lectura
        pop     hl
        push    hl
        out     (c), h
        out     (c), l
        out     (c), 0
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

; ------------------------
; Print Hexadecimal number
; Parameters:
;   DE: destination address
;   HL: 4 digit number
; ------------------------
      IF  recovery=0
wtohex  ld      b, 4
wtohe1  ld      a, $3
        add     hl, hl
        adc     a, a
        add     hl, hl
        adc     a, a
        add     hl, hl
        adc     a, a
        add     hl, hl
        adc     a, a
        cp      $3a
        jr      c, wtohe2
        add     a, 7
wtohe2  ld      (de), a
        inc     e
        djnz    wtohe1
        ret

; ---------------
; RAM Memory test
; ---------------
ramtst  di
        call    bomain
        wreg    master_conf, 1
        ld      bc, $040b
ramts2  dec     b
        dec     b
ramts3  ld      de, cad69
        push    bc
        ld      bc, zxuno_port
        ld      a, master_mapper
        out     (c), a
        inc     b
        push    iy
        pop     hl
        out     (c), h
        ld      b, 2
        call    alto wtohe1
        pop     bc
        ld      ixl, cad69&$ff
        call    alto prnstr
        dec     c
        inc     b
        inc     b
        ld      ixl, cad67&$ff
        ld      hl, $c000
ramts4  ld      a, (hl)
        xor     l
        ld      (hl), a
        ld      e, a
        ld      a, (hl)
        xor     l
        ld      (hl), a
        xor     l
        xor     e
        jr      z, ramts5
        ld      ixl, cad68&$ff
ramts5  inc     hl
        bit     4, h
        jr      z, ramts4
        call    alto prnstr
        inc     iyh
        ld      a, iyh
        and     $07
        jr      nz, ramts2
        ld      c, $0b
        ld      a, b
        add     a, 4
        ld      b, a
        ld      a, iyh
        cp      32
        jr      nz, ramts3
        wreg    master_conf, 0
        ld      bc, $0214
        jp      toanyk
      ENDIF

; ---------
; CRC check
; ---------
check   ld      hl, $c000
check0  ld      a, $ff
        ld      d, a
check1  xor     (hl)            ;6*4+4*7+10= 62 ciclos/byte
        ld      e, a
        ex      de, hl
        ld      a, h
        ld      h, alto crctab>>8
        xor     (hl)
        inc     h
        ld      h, (hl)
        ex      de, hl
        inc     l
        jp      nz, alto check1
        inc     h
        jr      nz, check1
        ld      e, a
        ret

; Parameters:
;    A: input slot
; Returns:
;   HL: destination address
    IF  recovery=0
slot2a  ld      de, 3
      IF  version=1
        and     $3f
        ld      h, d
        ld      l, a
        cp      19
        jr      c, slot2b
        ld      e, $c0
      ELSE
sloti   ld      l, a
        sub     44              ;-44, -1 -> 0, 43
        jr      nc, sloti
        ld      h, d
        add     a, 9
        jr      nc, slot2b
        ld      hl, $0400
        ld      e, a
      ENDIF
slot2b  add     hl, de          ; $00c0 y 2f80
        add     hl, hl
        add     hl, hl
slot2c  add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ret
    ENDIF

help    call    window
        ld      a, %00111000    ; fondo blanco tinta negra
        ld      hl, $0102
        ld      d, $12
        call    window
        ld      l, 9
        call    window
        ld      ix, cad13
        ld      bc, $1b0c
        call_prnstr             ; Select Screen ...
        call_prnstr
        call_prnstr
        call_prnstr

; -----------------------------------------------------------------------------
; Print string routine
; Parameters:
;  BC: X coord (B) and Y coord (C)
;  IX: null terminated string
; -----------------------------------------------------------------------------
      IF  vertical=0
prnstr  push    bc
        call    alto prnstr1
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
        call    alto doble
pos4    ld      a, (ix)
        inc     ix
        add     a, a
        ret     z
        ld      h, $b8 >> 2
        ld      bc, $04f0
        call    alto doble
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
        call    alto prnstr1
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

; ----------
; CRC Table
; ----------
crctab  incbin  crctable.bin
        defs    $80

; -----------------------------------------------------------------------------
; 6x8 character set (128 characters x 1 rotation)
; -----------------------------------------------------------------------------
      IF  vertical=0
        incbin  fuente6x8.bin
      ELSE
        incbin  fuente8x6.bin
      ENDIF

chrend

      IF  recovery=1
        include strings.asm
      ENDIF

        block   $3bbf-$

l3bbf   inc     h               ;4
        jr      nc, l3bcd       ;7/12     46/48
        xor     b               ;4
        xor     $9c             ;7
        ld      (de), a         ;7
        inc     de              ;6
        ld      a, $dc          ;7
        ex      af, af'         ;4
        in      l, (c)          ;12
        jp      (hl)            ;4
l3bcd   xor     b               ;4
        add     a, a            ;4
        ret     c               ;5
        add     a, a            ;4
        ex      af, af'         ;4
        out     ($fe), a        ;11
        in      l, (c)          ;12
        jp      (hl)            ;4

        block   $3bff-$         ; X bytes

l3bff   in      l, (c)
        jp      (hl)

        block   $3c0d-$         ; 11 bytes

        defb    $ec, $ec, $01   ; 0d
        defb    $ec, $ec, $02   ; 10
        defb    $ec, $ec, $03   ; 13
        defb    $ec, $ec, $04   ; 16
        defb    $ec, $ec, $05   ; 19
        defb    $ec, $ec, $06   ; 1c
        defb    $ec, $ec, $07   ; 1f
        defb    $ec, $ec, $08   ; 22
        defb    $ec, $ec, $09   ; 25
        defb    $ed, $ed, $0a   ; 28
        defb    $ed, $ed, $0b   ; 2b
        defb    $ed, $ed, $0c   ; 2e
        defb    $ed, $ed, $0d   ; 31
        defb    $ed, $ed, $0e   ; 34
        defb    $ed, $ed, $7f   ; 37
        defb    $ed, $ed, $7f   ; 3a
        defb    $ed, $ed, $7f   ; 3d
        defb    $ed, $ed, $7f   ; 40
        defb    $ed, $ee, $7f   ; 43 --
        defb    $ee, $ee, $7f   ; 46 --
        defb    $ee, $ee, $7f   ; 49
        defb    $ee, $ee, $7f   ; 4c
        defb    $ee, $ee, $7f   ; 4f
        defb    $ee, $ee, $7f   ; 52
        defb    $ee, $ee, $0f   ; 55
        defb    $ee, $ee, $10   ; 58
        defb    $ee, $ee, $11   ; 5b
        defb    $ee, $ef, $12   ; 5e
        defb    $ee, $ef, $13   ; 61
        defb    $ef, $ef, $14   ; 64
        defb    $ef, $ef, $15   ; 67
        defb    $ef, $ef, $16   ; 6a
        defb    $ef, $ef, $17   ; 6d
        defb    $ef, $ef, $18   ; 70
        defb    $ef, $ef, $19   ; 73
        defb    $ef, $ef, $1a   ; 76
        defb    $ef, $1b, $1c   ; 79
        defb    $ef, $1d, $1e   ; 7c
        defb    $ef             ; 7f
        defb    $ec, $ec, $1f   ; 80
        defb    $ec, $ec, $20   ; 83
        defb    $ec, $ec, $21   ; 86
        defb    $ec, $ec, $22   ; 89
        defb    $ec, $ec, $23   ; 8c
        defb    $ed, $ed, $7e   ; 8f
        defb    $ed, $ed, $7d   ; 92
        defb    $ed, $ed, $7f   ; 95
        defb    $ed, $ed, $7f   ; 98
        defb    $ed, $ee, $7f   ; 9b --
        defb    $ee, $ee, $7f   ; 9e
        defb    $ee, $ee, $7f   ; a1
        defb    $ee, $ee, $7d   ; a4
        defb    $ee, $ee, $7e   ; a7
        defb    $ee, $ef, $24   ; aa
        defb    $ef, $ef, $25   ; ad
        defb    $ef, $ef, $26   ; b0
        defb    $ef, $ef, $27   ; b3
        defb    $ef, $ef, $28   ; b6
        defb    $ef, $29, $2a   ; b9
        defb    $2b, $2c, $2d   ; bc
l3cbf   in      l, (c)
        jp      (hl)

        block   $3cff-$         ; 61 bytes

l3cff   ld      a, r            ;9        49 (41 sin borde)
        ld      l, a            ;4
        ld      b, (hl)         ;7
l3d03   ld      a, ixl          ;8
        ld      r, a            ;9
        ld      a, b            ;4
        ex      af, af'         ;4
        dec     h               ;4
        in      l, (c)          ;12
        jp      (hl)            ;4

        block   $3dbf-$         ; 178 bytes

l3dbf   in      l, (c)
        jp      (hl)

        block   $3df5-$         ; 51 bytes

l3df5   xor     b
        add     a, a
        ret     c
        add     a, a
        ex      af, af'
        out     ($fe), a
        in      l, (c)
        jp      (hl)
l3dff   inc     h
        jr      nc, l3df5
        xor     b
        xor     $9c
        ld      (de), a
        inc     de
        ld      a, $dc
        ex      af, af'
        in      l, (c)
        jp      (hl)
        defb    $ec, $ec, $01   ; 0d
        defb    $ec, $ec, $02   ; 10
        defb    $ec, $ec, $03   ; 13
        defb    $ec, $ec, $04   ; 16
        defb    $ec, $ec, $05   ; 19
        defb    $ec, $ec, $06   ; 1c
        defb    $ec, $ec, $07   ; 1f
        defb    $ec, $ec, $08   ; 22
        defb    $ec, $ec, $09   ; 25
        defb    $ed, $ed, $0a   ; 28
        defb    $ed, $ed, $0b   ; 2b
        defb    $ed, $ed, $0c   ; 2e
        defb    $ed, $ed, $0d   ; 31
        defb    $ed, $ed, $0e   ; 34
        defb    $ed, $ed, $7f   ; 37
        defb    $ed, $ed, $7f   ; 3a
        defb    $ed, $ed, $7f   ; 3d
        defb    $ed, $ed, $7f   ; 40
        defb    $ed, $ee, $7f   ; 43 --
        defb    $ee, $ee, $7f   ; 46 --
        defb    $ee, $ee, $7f   ; 49
        defb    $ee, $ee, $7f   ; 4c
        defb    $ee, $ee, $7f   ; 4f
        defb    $ee, $ee, $7f   ; 52
        defb    $ee, $ee, $0f   ; 55
        defb    $ee, $ee, $10   ; 58
        defb    $ee, $ee, $11   ; 5b
        defb    $ee, $ef, $12   ; 5e
        defb    $ee, $ef, $13   ; 61
        defb    $ef, $ef, $14   ; 64
        defb    $ef, $ef, $15   ; 67
        defb    $ef, $ef, $16   ; 6a
        defb    $ef, $ef, $17   ; 6d
        defb    $ef, $ef, $18   ; 70
        defb    $ef, $ef, $19   ; 73
        defb    $ef, $ef, $1a   ; 76
        defb    $ef, $1b, $1c   ; 79
        defb    $ef, $1d, $1e   ; 7c
        defb    $ef             ; 7f
        defb    $ec, $ec, $1f   ; 80
        defb    $ec, $ec, $20   ; 83
        defb    $ec, $ec, $21   ; 86
        defb    $ec, $ec, $22   ; 89
        defb    $ec, $ec, $23   ; 8c
        defb    $ed, $ed, $7e   ; 8f
        defb    $ed, $ed, $7d   ; 92
        defb    $ed, $ed, $7f   ; 95
        defb    $ed, $ed, $7f   ; 98
        defb    $ed, $ee, $7f   ; 9b --
        defb    $ee, $ee, $7f   ; 9e
        defb    $ee, $ee, $7f   ; a1
        defb    $ee, $ee, $7d   ; a4
        defb    $ee, $ee, $7e   ; a7
        defb    $ee, $ef, $24   ; aa
        defb    $ef, $ef, $25   ; ad
        defb    $ef, $ef, $26   ; b0
        defb    $ef, $ef, $27   ; b3
        defb    $ef, $ef, $28   ; b6
        defb    $ef, $29, $2a   ; b9
        defb    $2b, $2c, $2d   ; bc
l3ebf   ld      a, r
        ld      l, a
        ld      b, (hl)
l3ec3   ld      a, ixl
        ld      r, a
        ld      a, b
        ex      af, af'
        dec     h
        in      l, (c)
        jp      (hl)

        block   $3ee6-$         ; 25 bytes

lbytes  ld      a, (scnbak)
        and     %00111111
        call    setvid
        call    lbytes2
        ld      a, (scnbak)
setvid  ld      l, scandbl_ctrl
        ld      bc, zxuno_port
        out     (c), l
        inc     b
        out     (c), a
        ret

l3eff   in      l, (c)
        jp      (hl)

lbytes2 di                      ; disable interrupts
        ld      a, $0f          ; make the border white and mic off.
        out     ($fe), a        ; output to port.
        push    ix
        pop     hl              ; pongo la direccion de comienzo en hl
        ld      c, 2
        exx                     ; salvo de, en caso de volver al cargador estandar y para hacer luego el checksum
        ld      c, a
ultr0   defb    $21             ; en 1120 bit bajo de h=1 alto de l=0
ultr1   jr      nz, ultr3       ; return if at any time space is pressed.
ultr2   ld      b, 0
        call    lsampl          ; leo la duracion de un pulso (positivo o negativo)
        jr      nc, ultr1       ; si el pulso es muy largo retorno a bucle
        cp      40              ; si el contador esta entre 24 y 40
        jr      nc, ultr4       ; y se reciben 8 pulsos (me falta inicializar hl a 00ff)
        cp      24
        rl      h
        jr      nz, ultr4
ultr3   exx
lbreak  ret     nz              ; return if at any time space is pressed.
lstart  call    ldedg1          ; routine ld-edge-1
        jr      nc, lbreak      ; back to ld-break with time out and no edge present on tape
        xor     a               ; set up 8-bit outer loop counter for approx 0.45 second delay
ldwait  add     hl, hl
        djnz    ldwait          ; self loop to ld-wait (for 256 times)
        dec     a               ; decrease outer loop counter.
        jr      nz, ldwait      ; back to ld-wait, if not zero, with zero in b.
        call    ldedg2          ; routine ld-edge-2
        jr      nc, lbreak      ; back to ld-break if no edges at all.
leader  ld      b, $9c          ; two edges must be spaced apart.
        call    ldedg2          ; routine ld-edge-2
        jr      nc, lbreak      ; back to ld-break if time-out
        add     a, $3a          ; two edges must be spaced apart.
        jr      nc, lstart      ; back to ld-start if too close together for a lead-in.
        inc     h               ; proceed to test 256 edged sample.
        jr      nz, leader      ; back to ld-leader while more to do.
ldsync  ld      b, $c9          ; two edges must be spaced apart.
        call    ldedg1          ; routine ld-edge-1
        jr      nc, lbreak      ; back to ld-break with time-out.
        cp      $d4             ; compare 
        jr      nc, ldsync      ; back to ld-sync if gap too big, that is, a normal lead-in edge gap
        call    ldedg1          ; routine ld-edge-1
        ret     nc              ; return with time-out.
        ld      a, c            ; fetch long-term mask from c
        xor     $03             ; and make blue/yellow.
        ld      c, a            ; store the new long-term byte.
        jr      marker          ; forward to ld-marker 
ldloop  ex      af, af'         ; restore entry flags and type in a.
        jr      nz, ldflag      ; forward to ld-flag if awaiting initial flag, to be discarded
        ld      (ix), l         ; place loaded byte at memory location.
        inc     ix              ; increment byte pointer.
        dec     de              ; decrement length.
        defb    $c2
ldflag  inc     l               ; compare type in a with first byte in l.
        ret     nz              ; return if no match e.g. code vs. data.
marker  ex      af, af'         ; store the flags.
        ld      l, $01          ; initialize as %00000001
l8bits  ld      b, $b2          ; timing.
        call    ldedg2          ; routine ld-edge-2 increments b relative to gap between 2 edges
        ret     nc              ; return with time-out.
        add     a, $35          ; the comparison byte.
        rl      l               ; rotate the carry bit into l.
        jr      nc, l8bits      ; jump back to ld-8-bits
        ld      a, h            ; fetch the running parity byte.
        xor     l               ; include the new byte.
        ld      h, a            ; and store back in parity register.
        ld      a, d            ; check length of
        or      e               ; expected bytes.
        jr      nz, ldloop      ; back to ld-loop while there are more.
        ld      a, h            ; fetch parity byte.
        cp      1               ; set carry if zero.
        ret                     ; return
ultr4   cp      16              ; si el contador esta entre 10 y 16 es el tono guia
        rr      l               ; de las ultracargas, si los ultimos 8 pulsos
        cp      10              ; son de tono guia h debe valer ff
        jr      nc, ultr2
        inc     l
        inc     l
        jr      nz, ultr0       ; si detecto sincronismo sin 8 pulsos de tono guia retorno a bucle
        ld      h, l
        call    lsampl          ; leo pulso negativo de sincronismo
        inc     l               ; hl vale 0001, marker para leer 16 bits en hl (checksum y byte flag)
        call    get16           ; leo 16 bits, ahora temporizo cada 2 pulsos
        ld      a, l
        inc     l               ; lo comparo con el que me encuentro en la ultracarga
        ret     nz              ; salgo si no coinciden
        xor     h               ; xoreo el checksum con en byte flag, resultado en a
        exx                     ; guardo checksum por duplicado en h' y l'
        push    hl              ; pongo direccion de comienzo en pila
        ld      c, a
        ld      a, $d8          ; a' tiene que valer esto para entrar en raudo
        ex      af, af'
        exx
        ld      h, $01          ; leo 8 bits en hl
        call    get16
        push    hl
        pop     ix
        pop     de              ; recupero en de la direccion de comienzo del bloque
        rr      c               ; pongo en flag z el signo del pulso
        ld      bc, $effe       ; este valor es el que necesita b para entrar en raudo
        jp      nc, ult55
        ld      h, $3e
ultr5   in      f, (c)
        jp      pe, ultr5
        call    l3ec3           ; salto a raudo segun el signo del pulso en flag z
        jr      ultr7
ult55   ld      h, $3c
ultr6   in      f, (c)
        jp      po, ultr6
        call    l3d03           ; salto a raudo
ultr7   sbc     a, a
        exx                     ; ya se ha acabado la ultracarga (raudo)
        dec     de
        ld      b, e
        inc     b
        inc     d
ultr8   xor     (hl)
        inc     hl
        djnz    ultr8
        dec     d
        jp      nz, ultr8
        push    hl              ; ha ido bien
        xor     c
        pop     ix              ; ix debe apuntar al siguiente byte despues del bloque
        ret     nz              ; si no coincide el checksum salgo con carry desactivado
        scf
        ret
ldedg2  call    ldedg1          ; call routine ld-edge-1 below.
        ret     nc              ; return if space pressed or time-out.
ldedg1  ld      a, $16          ; a delay value of twenty two.
ldelay  dec     a               ; decrement counter
        jr      nz, ldelay      ; loop back to ld-delay 22 times.
lsampl  inc     b               ; increment the time-out counter.
        ld      a, b
        ret     z               ; return with failure when $ff passed.
        ld      a, $7f          ; prepare to read keyboard and ear port
        in      a, ($fe)        ; row $7ffe. bit 6 is ear, bit 0 is space key.
        rra                     ; test outer key the space. (bit 6 moves to 5)
        ret     nc              ; return if space pressed.  >>>
        xor     c               ; compare with initial long-term state.
        and     $20             ; isolate bit 5
        jr      z, lsampl       ; back to ld-sample if no edge.
        ld      a, c            ; fetch comparison value.
        xor     $27             ; switch the bits
        ld      c, a            ; and put back in c for long-term.
        out     ($fe), a        ; send to port to effect the change of colour. 
        ld      a, b
        scf                     ; set carry flag signaling edge found within time allowed
        ret                     ; return.

decbhl  dec     hl
        ld      a, l
        and     h
        inc     a
        ret     nz
        dec     b
        ret

;++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++
;++++++++++++               +++++++++++++
;++++++++++++    MESSAGES   +++++++++++++
;++++++++++++               +++++++++++++
;++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++
      IF  recovery=0
        block   $7e00-$
        include strings.asm
      ENDIF
; todo
; * generar tablas CRC por código
; * descomprimir en lugar de copiar codigo alto
