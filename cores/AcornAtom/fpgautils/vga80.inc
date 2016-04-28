        GODIL = $BDE0

        ModeExtension = GODIL + 0
        CursorCol = GODIL + 2
        CursorRow = GODIL + 3
        VgaCtrl = GODIL + 4


vga80:
        LDA    #<wrch80
        STA     wrcvec
        LDA    #>wrch80
        STA     wrcvec+1
        LDA    #<rdch80
        STA     rdcvec
        LDA    #>rdch80
        STA     rdcvec+1

        LDA     #$80
        STA     ModeExtension
        LDA     #$B2
        STA     VgaCtrl
        LDA     #12
        JMP     $FFF4


;    Send ASCII Character to Screen subroutine
;    -----------------------------------------
;
;  - Prints non-control codes (#20 to #FF) at the current cursor position on
;    the screen.
;  - Executes the following control codes:
;
;    <NUL><ACK><BEL><BS><HT><LF><VT><FF><CR><SO><SI><NAK><ESC>
;      0    6    7   8   9   #A  #B  #C  #D  #E  #F  #15  #1B

        ; TEST FOR CONTROL CODES

LFCEA:  cmp     #$06            ; Is it <ACK> ?
        beq     LFD0B           ; ..yes, reset the 6847 VDG to alphanumeric
                                ; mode and clear the NAK flag
        cmp     #$15            ; Is it <NAK> ?
        beq     LFD11           ; ..yes, set the NAK flag
        ldy     $E0             ; Get cursor postion - is the NAK flag bit 7 set ?
        bmi     LFD19           ; ..yes, printing not allowed - return
        cmp     #$1B            ; Is it <ESC> ?
        beq     LFD0B           ; ..yes, reset VDG to alphanumeric mode and clear NAK
        cmp     #$07            ; Is it <BEL> ?
        beq     LFD1A           ; ..yes, sound a bleep
        jsr     LFD44           ; Invert char at current cursor position
        ldx     #$0A            ; Point to the control code table at #FED5
        jsr     LFEC5           ; Test character for executable control code
        bne     LFD29           ; ..it's not an executable control code
                                ; so print it if >#1F, otherwise return
        jmp     LFEB7           ; ..executable control code - get the code's
                                ; execution address and jump to it

;    Handle <ESC> subroutine
;    -----------------------
;
;  - Resets the 6847 VDG to alphanumeric mode.
;  - Clears the NAK flag (bit 7 of #E0).


LFD0B:  jmp $fd0b

;    Handle <ACK> or <NAK> subroutine
;    --------------------------------
;
;  - Entry: Carry clear to perform <NAK>
;           Carry  set  to perform <ACK>
;  - Returns with Accumulator and Y registers preserved, and with X=2.
;
LFD11:  jmp     $fd11

LFD19:  rts

;    Handle <BEL> subroutine
;    -----------------------
;
;  - Returns with X=0, Y=128, and the sign flag set.

LFD1A:  jmp     $fd1a

;    Print an ASCII Character on the Screen subroutine
;    -------------------------------------------------
;
;  - Control characters (codes less than #20) are ignored.
;  - Increments current cursor position, incrementing the print line and/or
;    scrolling the screen as necessary.
;  - Entry: Accumulator contains ASCII code of character to be printed
;           Y register contains current cursor position ?#E0.
;  - Accumulator preserved.

LFD29:  cmp     #$20            ; Is the character a control code ?
        bcc     LFD44           ; ..yes, so don't print it

;        adc     #$1F           ; )
;        bmi     LFD33          ; )
;        eor     #$60           ; ) Convert to screen character

         cmp     #$40
         bcc     LFD33
         sbc     #$20
         and     #$5f

LFD33:  sta     ($DE),y         ; Store character at current print position
LFD38:  iny                     ; Increment cursor position
        cpy     #NUMCOLS        ; Reached end of the current print line ?
        bcc     LFD42           ; ..no, update cursor position and invert
                                ; the cursor at this position
        jsr     LFDEC           ; ..yes, do <CR><LF> first

;    Reset Cursor to Start of Current Line Without Deletion subroutine
;    -----------------------------------------------------------------

LFD40:  ldy     #$00            ; Point to start of current line
LFD42:  sty     $E0             ; Update current cursor position register

;    Invert Character at Current Cursor Position subroutine
;    ------------------------------------------------------
;
;  - EORs the character at the current cursor position with the cursor mask
;    ?#E1.
;  - A, X, Y registers preserved.

LFD44:
        pha                     ; Save character in accumulator
        lda ($DE),Y             ; Get character at current print position
        eor $E1                 ; Mask it
        sta ($DE),Y             ; ..and return it to the screen
        pla                     ; Restore character to accumulator
        rts

;    Handle <DEL> subroutine
;    -----------------------

LFD50:  jsr     LFE35           ; Move cursor back one position if possible, otherwise
                                ; invert character at current cursor position and return
        lda     #$20            ; Get <SPC>
        sta     ($DE),y         ; Blank character at previous cursor pos'n
        bpl     LFD42           ; Update cursor position and invert cursor

;    Handle <BS> subroutine
;    ----------------------
;
;  - Enter with Y containing the current cursor position ?#E1.

LFD5C:  jsr     LFE35           ; Move cursor back one position if possible, otherwise
                                ; invert character at current cursor position and return
        jmp     LFD42           ; Update cursor position and invert cursor

;    Handle <LF> subroutine
;    ----------------------

LFD62:  jsr     LFDEC           ; Do <LF>, scrolling if necessary

        lda     VgaCtrl        ; disable the cursor
        and     #$bf
        sta     VgaCtrl

LFD65:  ldy     $E0             ; Get origional cursor position, which has not changed
                                ; although the line start address may have
        bpl     LFD42           ; Update cursor position and invert cursor

;    Handle <FF> subroutine
;    ----------------------
;
;  - Resets the 8647 VDG to the alphanumeric mode and clears the screen.
;  - Sets the cursor to the top left position.

LFD69:  ldy     #$80            ;
        sty     $E1             ; Set the cursor mask to default
        ldy     #$00            ; Clear screen memory index
        sty     $B000           ; Set 6847 VDG to alphanumeric mode
        lda     #$20            ; Get <SPC>
LFD74:  sta     SCREEN,y        ; Clear byte of upper page of screen
        sta     SCREEN+$100,y   ; Clear byte of lower page of screen
        jsr     CLEARMORE
        iny                     ; Point to the next byte
        bne     LFD74           ; ..and clear both complete pages

;    Handle <RS> subroutine
;    ----------------------
;
;  - Sets cursor to top left position.

LFD7D:  jmp     $fd7d

;    Handle <VT> subroutine
;    ----------------------
;
;  - Enter with Y containing the current cursor position ?#E1.

LFD87:  jsr     LFE3A           ; Move the cursor position up a line
        jmp     LFD42           ; Update cursor position and invert cursor

;    Handle <SO> subroutine
;    ----------------------
;
;  - Turns page mode on, and sets the number of lines left to 16.

LFD8D:  clc                     ;
        lda     #NUMROWS        ; Get number of lines in page = 16
        sta     $E6             ; Indicate page mode by setting count

;    Handle <SI> subroutine
;    ----------------------
;
;  - Turns page mode off.
;  - Enter with Carry set.

LFD92:  jmp     $fd92

;    Handle Cursor Keys from Keyboard subroutine
;    -------------------------------------------
;
;  - Sends the cursor control code to screen and then fetches another key.

LFDA2:  tax

        bit     VgaCtrl        ; test hardware cursor
        bvs     cursor_enabled

        lda     $e0
        sta     CursorCol
        lda     #$ff
        sta     CursorRow
        lda     $de             ; use de/df as tmp workspace
        pha
        lda     $df
        pha
address_loop:
        inc     CursorRow
        lda     $de
        sec
        sbc     #80
        sta     $de
        lda     $df
        sbc     #0
        sta     $df
        bmi     address_loop
        pla                     ; restore de/df
        sta     $df
        pla
        sta     $de

        lda     VgaCtrl        ; enable the cursor
        ora     #$40
        sta     VgaCtrl

cursor_enabled:


        lda     #>(LFE9A-1)     ; stack ..and fetch another key
        pha
        lda     #<(LFE9A-1)
        pha

        txa
        and     #$05            ;
        rol     $B001           ;
        rol     a               ;

        cmp     #$08            ; cursor left
        beq     cursor_l
        cmp     #$09            ; cursor right
        beq     cursor_r
        cmp     #$0A            ; cursor down
        beq     cursor_d
        cmp     #$0B            ; cursor up
        beq     cursor_u
                                ; should never get here....
        rts

cursor_l:
        ldy     CursorCol
        dey
        bmi     cursor_l_wrap
        sty     CursorCol
        rts
cursor_l_wrap:
        ldy     #79
        sty     CursorCol

cursor_u:
        ldy     CursorRow
        dey
        bpl     cursor_u_nowrap
        ldy     #39
cursor_u_nowrap:
        sty     CursorRow
        rts

cursor_r:
        ldy     CursorCol
        iny
        cpy     #80
        bcs     cursor_r_wrap
        sty     CursorCol
        rts
cursor_r_wrap:
        ldy     #0
        sty     CursorCol

cursor_d:
        ldy     CursorRow
        iny
        cpy     #40
        bcc     cursor_d_nowrap
        ldy     #0
cursor_d_nowrap:
        sty     CursorRow
        rts

copy:
        lda     $de
        pha
        lda     $df
        pha
        lda     CursorCol
        sta     $de
        lda     #$80
        sta     $df
        ldy     CursorRow
copy_loop:
        dey
        bmi     copy_grab
        clc
        lda     $de
        adc     #80
        sta     $de
        bcc     copy_loop
        inc     $df
        bne     copy_loop
copy_grab:
        iny
        lda     ($de), Y
        ;                 ADC#$20
        ; Screen 00-1F -> 20-3F -> ASCII 40-5F
        ; Screen 20-3F -> 40-5F -> ASCII 20-3F
        ; Screen 40-5F -> 60-7F -> ASCII 60-7F
        clc
        adc     #$20
        cmp     #$60
        bcs     copy_done
        eor     #$60
copy_done:
        tax                    ; remember the ascii value
        jsr     cursor_r       ; copy also moves the cursor right
        pla
        sta     $df
        pla
        sta     $de
        txa                    ; get the ascii value back again
        jmp     $FDE9          ; Restore A,X,Y regs & status & return

;    Handle <LF>, Scrolling if Necessary subroutine
;    ----------------------------------------------
;
;  - If in page mode, decrements page counter, and at the end of the page
;    waits for a keypress before scrolling.

LFDEC:  lda     $DE             ; Get LSB start of line
        ldy     $DF             ; Get MSB start of line
        cpy     #>SCREENEND     ; In lower screen page ?
        bcc     LFE2C           ; ..no, do <LF> - scrolling not required
        cmp     #<SCREENEND     ; In last page..but is it the last line ?
        bcc     LFE2C           ; ..no, do <LF> - scrolling not required

        ; SCROLLING REQUIRED - CHECK IN PAGE MODE

        ldy     $E6             ; Get page mode flag
        bmi     LFE08           ; ..not in page mode - scroll the screen
        dey                     ;
        bne     LFE06           ;

        ;  IN PAGE MODE - GET KEYPRESS

LFDFF:  jsr     LFE71           ; Scan keyboard
        bcs     LFDFF           ; ..keep scanning until key pressed
        ldy     #NUMROWS        ;
LFE06:  sty     $E6             ; Reset page counter to 16 lines

;    Scroll the Screen subroutine
;    ----------------------------

LFE08:  ldy     #NUMCOLS        ; Shift screen up 32 characters = 1 line

;    Scroll Y lines of the Screen subroutine
;    ---------------------------------------
;
;  - For every #20 in Y a top line of the screen is not scrolled.

LFE0D:  lda     SCREEN,y        ; Get byte from upper text page
        sta     SCREEN-NUMCOLS,y                ; ..and store it a line higher
        iny                     ; Point to next screen byte
        bne     LFE0D           ; ..and shift up all the upper text page
LFE19:  lda     SCREEN+$100,y           ; Get byte from lower text page
        sta     SCREEN+$100-NUMCOLS,y           ; ..and store it a line higher
        iny                     ; Point to next screen byte
        bne     LFE19           ; ..and shift up all the lower text page
        JSR     SCROLLMORE

;    Delete Current Line subroutine
;    ------------------------------
;
;  - CLears the 32 character line based at (#DE) to black (<SPACE>).

        ldy     #NUMCOLS-1      ; Set character pointer to end of line
        lda     #$20            ; Get <SPACE>
LFE26:  sta     ($DE),y         ; Clear the character to black
        dey                     ; Point to the next character
        bpl     LFE26           ; ..and clear the entire print line
        rts                     ;

;    Add One Line to the Cursor Position subroutine
;    ----------------------------------------------
;
;  - Enter with the accumulator containing the LSB current cursor
;    Delete Current Line subroutine
;    ------------------------------
;
;  - CLears the 32 character line based at (#DE) to black (<SPACE>).
;  address
;    #DE and Carry clear.

LFE2C:  adc     #NUMCOLS        ; Add 32 characters = 1 print line
        sta     $DE             ; ..and update LSB cursor  Add 32 characters = 1 print lineaddress
        bcc     LFE34           ;
        inc     $DF             ; Increment MSB cursor address if overflow
LFE34:  rts                     ;

;    Move the Cursor Back One Position subroutine
;    --------------------------------------------
;
;  - Decrements the current cursor position, dealing with line underflow.
;  - If the cursor is at the top left of the screen, the character at this
;    position is inverted before premature return.
;  - Used by the <BS> and <DEL> subroutines.
;  - Enter with Y register holding the current cursor position ?#31.

LFE35:  dey                     ; Point to the previous cursor position
        bpl     LFE51           ; ..still on current line, return

        ; DEAL WITH LINE UNDERFLOW

        ldy     #NUMCOLS-1      ; Set cursor position to last char on line
LFE3A:  lda     $DE             ; Get LSB current line address
        bne     LFE49           ; ..not at top of screen, so can move line
                                ; address up a line
        ldx     $DF             ; Get MSB current line address
        cpx     #>SCREEN        ; Is it upper page ?
        bne     LFE49           ; ..no, move line address up a line

        ; ALREADY AT TOP OF SCREEN - RETURN

        pla                     ; )
        pla                     ; ) Remove return address from stack
        jmp     LFD65           ; Invert char at current cursor position

        ; MOVE CURRENT START ADDRESS UP A LINE

LFE49:  sbc     #NUMCOLS        ; Move LSB current line back 32 characters
        sta     $DE             ; ..and update LSB line addres
        bcs     LFE51           ;
        dec     $DF             ; Decrement MSB line address if overflow
LFE51:  rts                     ;

;    Send Character to VIA and Screen subroutine
;    -------------------------------------------
;
;  - Preserves all registers.

wrch80: jsr     LFEFB           ; Send character in accumulator to the VIA

;    Send Character to Screen subroutine
;    -----------------------------------
;
;  - Preserves all registers.

        php                     ; Save flags
        pha                     ; Save accumulator
        cld                     ;
        sty     $E5             ; Save Y register
        stx     $E4             ; Save X register
        jsr     LFCEA           ; Send character in accumulator to screen
        pla                     ; Restore accumulator
LFE60:  ldx     $E4             ; Restore X register
        ldy     $E5             ; Restore Y register
        plp                     ; Restore flags
        rts                     ;


;    OSRDCH Get Key subroutine
;    -------------------------
;
;  - Waits for a key to be pressed and returns with its ASCII value in the
;    accumulator.
;  - Executes control characters before return.
;  - If <LOCK> or cursor control keys is pressed, the code is executed
;    and another keypress fetched before return.
;  - Preserves X,Y registers and flags.

rdch80: php                     ; Save flags
        cld                     ;
        stx     $E4             ; Save X register
        sty     $E5             ; Save Y register

        ; WAIT FOR KEYBOARD TO BE RELEASED

LFE9A:  bit     $B002           ; Is <REPT> key pressed ?
        bvc     LFEA4           ; ..yes, no need to wait for keyboard to be released
        jsr     LFE71           ; Scan keyboard
        bcc     LFE9A           ; ..wait for key to be released

        ; GET KEYPRESS

LFEA4:  jsr     LFB8A           ; Wait 0.1 second for debounce
LFEA7:  jsr     LFE71           ; Scan keyboard
        bcs     LFEA7           ; ..keep scanning until key pressed
        jsr     LFE71           ; Scan keyboard again - still pressed ?
        bcs     LFEA7           ; ..no, noise ? - try again
        tya                     ; Acc = ASCII value of key - #20
        ldx     #$17            ; Pointer to control code table at #FEE2

        ; GET EXECUTION ADDRESS AND JUMP TO IT

        jsr     LFEC5           ; Test for control code or otherwise
LFEB7:  lda     tablelo, x      ; Get LSB execution  Test for control code or otherwiseaddress
        sta     $E2             ; ..into w/s
        lda     tablehi, x      ; Get MSB execution  ..into w/saddress
        sta     $E3             ; ..into w/s
        tya                     ; Acc = ASCII value of key - #20
        jmp     ($E2)           ; Jump to deal with char or control code

;    Decode Control Character subroutine
;    -----------------------------------
;
;  - Enter at #FEC5.
;  - Enter with X pointing to control code table:
;      X=#A  for the WRCHAR table at #FED5
;      X=#17 for the RDCHAR table at #FEE2.
;  - Returns with Carry set, and X pointing to matched code or last code.
;  - Returns with Z flag set if control code matched.

LFEC4:  dex                     ; Point to next control code in table
LFEC5:  cmp     LFECB, x        ; Is it this control code ?
        bcc     LFEC4           ; ..no, table value too large - try the next code
        rts                     ;

;    WRCHAR Control Code Data Lookup Table
;    -------------------------------------

LFECB:  .byte $00, $08, $09, $0A, $0B, $0C, $0D, $0E,$0F, $1E, $7F

;    RDCHAR Control Code Data Lookup Table
;    -------------------------------------

        .byte $00, $01, $05, $06, $08, $0E, $0F, $10, $11, $1C, $20, $21, $3B

;    WRCHAR Control Code Address Lookup Table
;    Note that this is just the LSB.
;    ----------------------------------------

tablelo:
        .byte <LFD44            ; invert char at cursor position
        .byte <LFD5C            ; handle <BS>
        .byte <LFD38            ; handle <HT>
        .byte <LFD62            ; handle <LF>
        .byte <LFD87            ; handle <VT>
        .byte <LFD69            ; handle <FF>
        .byte <LFD40            ; handle <CR>
        .byte <LFD8D            ; handle <SO>
        .byte <LFD92            ; handle <SI>
        .byte <LFD7D            ; handle <RS>
        .byte <LFD50            ; handle <DEL>

;    RDCHAR Control Code Address Lookup Table
;    Note that this is just the LSB.
;    ----------------------------------------

        .byte <LFDDF            ;
        .byte <LFDD2            ;
        .byte <LFD9A            ; handle LOCK
        .byte <LFDA2            ; handle cursor keys
        .byte <LFDE2            ;
        .byte <copy             ; handle COPY
        .byte <LFDC0            ; handle DEL
        .byte <LFDDF            ;
        .byte <LFDD8            ;
        .byte <LFDD6            ;
        .byte <LFDC8            ;
        .byte <LFDC6            ;
        .byte <LFDC2            ;

;    WRCHAR Control Code Address Lookup Table
;    Note that this is just the MSB.
;    ----------------------------------------

tablehi:
        .byte >LFD44            ; invert char at cursor position
        .byte >LFD5C            ; handle <BS>
        .byte >LFD38            ; handle <HT>
        .byte >LFD62            ; handle <LF>
        .byte >LFD87            ; handle <VT>
        .byte >LFD69            ; handle <FF>
        .byte >LFD40            ; handle <CR>
        .byte >LFD8D            ; handle <SO>
        .byte >LFD92            ; handle <SI>
        .byte >LFD7D            ; handle <RS>
        .byte >LFD50            ; handle <DEL>

;    RDCHAR Control Code Address Lookup Table
;    Note that this is just the MSB.
;    ----------------------------------------

        .byte >LFDDF            ;
        .byte >LFDD2            ;
        .byte >LFD9A            ; handle LOCK
        .byte >LFDA2            ; handle cursor keys
        .byte >LFDE2            ;
        .byte >copy             ; handle COPY
        .byte >LFDC0            ; handle DEL
        .byte >LFDDF            ;
        .byte >LFDD8            ;
        .byte >LFDD6            ;
        .byte >LFDC8            ;
        .byte >LFDC6            ;
        .byte >LFDC2            ;


CLEARMORE:
        sta     SCREEN+$200,Y
        sta     SCREEN+$300,Y
        sta     SCREEN+$400,Y
        sta     SCREEN+$500,Y
        sta     SCREEN+$600,Y
        sta     SCREEN+$700,Y
        sta     SCREEN+$800,Y
        sta     SCREEN+$900,Y
        sta     SCREEN+$a00,Y
        sta     SCREEN+$b00,Y
        sta     SCREEN+$c00,Y
        rts


SCROLLMORE:

LFDF2A:
        LDA     SCREEN+$200,Y
        STA     SCREEN+$200-NUMCOLS,Y
        INY
        BNE     LFDF2A
LFDF2B:
        LDA     SCREEN+$300,Y
        STA     SCREEN+$300-NUMCOLS,Y
        INY
        BNE     LFDF2B
LFDF2C:
        LDA     SCREEN+$400,Y
        STA     SCREEN+$400-NUMCOLS,Y
        INY
        BNE     LFDF2C
LFDF2D:
        LDA     SCREEN+$500,Y
        STA     SCREEN+$500-NUMCOLS,Y
        INY
        BNE     LFDF2D
LFDF2E:
        LDA     SCREEN+$600,Y
        STA     SCREEN+$600-NUMCOLS,Y
        INY
        BNE     LFDF2E
LFDF2F:
        LDA     SCREEN+$700,Y
        STA     SCREEN+$700-NUMCOLS,Y
        INY
        BNE     LFDF2F
LFDF2G:
        LDA     SCREEN+$800,Y
        STA     SCREEN+$800-NUMCOLS,Y
        INY
        BNE     LFDF2G
LFDF2H:
        LDA     SCREEN+$900,Y
        STA     SCREEN+$900-NUMCOLS,Y
        INY
        BNE     LFDF2H
LFDF2I:
        LDA     SCREEN+$a00,Y
        STA     SCREEN+$a00-NUMCOLS,Y
        INY
        BNE     LFDF2I
LFDF2J:
        LDA     SCREEN+$b00,Y
        STA     SCREEN+$b00-NUMCOLS,Y
        INY
        BNE     LFDF2J
LFDF2K:
        LDA     SCREEN+$c00,Y
        STA     SCREEN+$c00-NUMCOLS,Y
        INY
        BNE     LFDF2K

        RTS
