;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CRC [START] [LENGTH]
;
;  Example: *CRC 2900 400
;
;  Prints the CRC16 for the specified memory range
;
STARCRC:
    ldx  #SSTART              ; interpret parameters
    jsr  $fa65

    ldx  #SEND
    jsr  $fa65

    ldy  #$ff
    sty  CRC
    sty  CRC+1

    iny                     ; y=0
    beq  @pagetest       ; branch always

@fullpageloop:
    lda  #0                  ; whole page
    jsr  calcblock

    inc  SSTART+1
    dec  SEND+1

@pagetest:
    lda  SEND+1              ; any full pages left?
    bne  @fullpageloop

    lda  SEND                ; stragglers?
    beq  @showresult

    jsr  calcblock

@showresult:
    ldx #CRC
    jsr $f7f1
    jmp OSCRLF





calcblock:
    sta  CRC+2       ; bytes to calc, 0 = 256

@calc:
    lda  (SSTART),y
    sty  CRC+3
    
    eor  CRC+1       ; a contained the data
    sta  CRC+1       ; xor it into high byte
    lsr  a            ; right shift a 4 bits
    lsr  a            ; to make top of x^12 term
    lsr  a            ; ($1...)
    lsr  a
    tax             ; save it
    asl  a            ; then make top of x^5 term
    eor  CRC       ; and xor that with low byte
    sta  CRC       ; and save
    txa             ; restore partial term
    eor  CRC+1       ; and update high byte
    sta  CRC+1       ; and save
    asl  a            ; left shift three
    asl  a            ; the rest of the terms
    asl  a            ; have feedback from x^12
    tax             ; save bottom of x^12
    asl  a            ; left shift two more
    asl  a            ; watch the carry flag
    eor  CRC+1       ; bottom of x^5 ($..2.)
    tay             ; save high byte
    txa             ; fetch temp value
    rol  a            ; bottom of x^12, middle of x^5!
    eor  CRC       ; finally update low byte
    sta  CRC+1       ; then swap high and low bytes
    sty  CRC

    ldy  CRC+3
    iny
    dec  CRC+2
    bne  @calc
    rts


