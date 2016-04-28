Transfer                macro lbytes,dst1,dst2,dst3,dst4,dst5
                        ld bc,lbytes
                        ldir
                        ld bc,254
                        out (c),a
                        cpl
                        ex af,af'
                        in a,(c)
                        ld b,a
                        ex af,af'
                        ld c,a
                        ld a,b
                        and 00010001b
                        jp z,ChangeROM
                        bit 0,b
                        jp z,dst1
                        bit 1,b
                        jp z,dst2
                        bit 2,b
                        jp z,dst3
                        bit 3,b
                        jp z,dst4
                        bit 4,b
                        jp z,dst5
                        ld a,c
                        endm

Retardo                 macro
                        local BucRetardo
                        ld hl,0
BucRetardo              dec hl
                        inc h
                        dec h
                        jr nz,BucRetardo
                        endm

;------------------------------------------------------------------------------

                        org 0
                        di
                        im 1
                        ld sp,0ffffh

                        ld hl,32768
                        ld de,32769
                        ld bc,32767
                        ld (hl),0
                        ldir

                        jp TestDesdeROM

                        org 38h  ;IM 1
                        inc sp
                        inc sp
                        jp (iy)


TestDesdeROM            xor a
                        Retardo
TestDesdeROM1           ld hl,TestScreen
                        ld de,16384
                        Transfer 6912,TestDesdeRAM,TestDesdeRAMBaja,Graba,Carga,TestRAM
                        jp TestDesdeROM1

TestDesdeRAM            xor a
                        ld hl,TestScreen
                        ld de,32768
                        ld bc,6912
                        ldir
                        Retardo

TestDesdeRAM1           ld hl,32768
                        ld de,16384
                        Transfer 6912,TestDesdeROM,TestDesdeRAMBaja,Graba,Carga,TestRAM
                        jp TestDesdeRAM1

TestDesdeRAMBaja        xor a
                        ld hl,TestScreen
                        ld de,25856
                        ld bc,6912
                        ldir
                        Retardo

TestDesdeRAM1Baja       ld hl,25856
                        ld de,16384
                        Transfer 6912,TestDesdeROM,TestDesdeRAM,Graba,Carga,TestRAM
                        jp TestDesdeRAM1Baja


TestRAM                 ld hl,65535
RellenaRAM              ld (hl),10000000b
                        dec hl
                        ld a,h
                        cp 7fh
                        jp nz,RellenaRAM

                        inc hl
DecrementaRAM           dec (hl)
                        dec (hl)
                        inc hl
                        ld a,h
                        or l
                        jp nz,DecrementaRAM

                        dec hl
CheckRAM                ld a,01111110b
                        cp (hl)
                        jp nz,FalloRAM
                        dec hl
                        ld a,h
                        out (254),a
                        cp 7fh
                        jp nz,CheckRAM
                        ld a,4
                        out (254),a
                        Retardo
                        jp TestDesdeROM

FalloRAM                ;HL contiene la direccion que falló.
                        ld c,1
                        ld b,8
CheckBit1               ld (hl),c
                        ld a,c
                        and (hl)
                        cp c
                        jp nz,Bit1Malo
                        sla c
                        djnz CheckBit1

                        ld c,11111110b
                        ld b,8
CheckBit0               ld (hl),c
                        ld a,c
                        or (hl)
                        cp c
                        jp nz,Bit0Malo
                        sla c
                        djnz CheckBit0

                        ;No encontramos el bit que esta mal... Volvemos a buscar
                        jp TestRAM

Bit0Malo                ld de,0205h
                        jp ShowBitMalo

Bit1Malo                ld de,0007h

ShowBitMalo             ld a,9
                        sub b
                        ld b,a
                        ld c,a
                        exx

                        ld hl,200   ;4 segundos
                        exx

BucleBitMalo            ld iy,DirRetornoIM1
                        ei
                        halt

DirRetornoIM1           di
                        ld hl,600
EsperaLarga             dec hl
                        ld a,h
                        or l
                        jp nz,EsperaLarga

BucleRayas              ld a,d
                        out (254),a
                        ld h,80
Espera1                 dec h
                        jp nz,Espera1

                        ld a,e
                        out (254),a
                        ld h,80
Espera2                 dec h
                        jp nz,Espera2
                        djnz BucleRayas

                        ld b,c
                        exx
                        dec hl
                        ld a,h
                        or l
                        exx
                        jp nz,BucleBitMalo
                        jp TestRAM

ChangeROM               ld hl,Rutina
                        ld de,16384
                        ld bc,LRutina
                        ldir
                        jp 16384
Rutina                  ld a,00010111b
                        ld bc,7ffdh
                        out (c),a
                        jp 0
LRutina                 equ $-Rutina


Graba                   ld ix,Cabecera1
                        ld de,17
                        ld a,0
                        call SaBytes

                        Retardo

                        ld ix,16384
                        ld de,6912
                        ld a,255
                        call SaBytes

                        Retardo

                        ld ix,Cabecera2
                        ld de,17
                        ld a,0
                        call SaBytes

                        Retardo

                        ld ix,32768
                        ld de,32768
                        ld a,255
                        call SaBytes

                        jp TestDesdeROM


Carga                   ld ix,32768
                        ld de,17
                        ld a,0
                        scf
                        call LdBytes
                        jr nc,Carga   ;Esperando cabecera, no datos
                        ld a,(32768)
                        cp 3
                        jr nz,Carga   ;Solo cargo bloque de bytes

                        ld ix,(32781) ;Comienzo de carga
                        ld de,(32779) ;Longitud de la carga
                        ld a,255
                        scf
                        push ix
                        call LdBytes
                        pop hl
                        ld de,TestDesdeROM
                        push de
                        jp (hl)



Cabecera1               db 3,"Pantalla  "
                        dw 6912,16384,32768
Cabecera2               db 3,"RAM       "
                        dw 32768,32768,32768


;; SA-BYTES
SaBytes:
L04C2:  LD      HL,L053F        ; address: SA/LD-RET
        PUSH    HL              ; is pushed as common exit route.
                                ; however there is only one non-terminal exit
                                ; point.

        LD      HL,$1F80        ; a timing constant H=$1F, L=$80
                                ; inner and outer loop counters
                                ; a five second lead-in is used for a header.

        BIT     7,A             ; test one bit of accumulator.
                                ; (AND A ?)
        JR      Z,L04D0         ; skip to SA-FLAG if a header is being saved.

;   else is data bytes and a shorter lead-in is used.

        LD      HL,$0C98        ; another timing value H=$0C, L=$98.
                                ; a two second lead-in is used for the data.


;; SA-FLAG
L04D0:  EX      AF,AF'          ; save flag
        INC     DE              ; increase length by one.
        DEC     IX              ; decrease start.

        LD      A,$02           ; select red for border, microphone bit on.
        LD      B,A             ; also does as an initial slight counter value.

;; SA-LEADER
L04D8:  DJNZ    L04D8           ; self loop to SA-LEADER for delay.
                                ; after initial loop, count is $A4 (or $A3)

        OUT     ($FE),A         ; output byte $02/$0D to tape port.

        XOR     $0F             ; switch from RED (mic on) to CYAN (mic off).

        LD      B,$A4           ; hold count. also timed instruction.

        DEC     L               ; originally $80 or $98.
                                ; but subsequently cycles 256 times.
        JR      NZ,L04D8        ; back to SA-LEADER until L is zero.

;   the outer loop is counted by H

        DEC     B               ; decrement count
        DEC     H               ; originally  twelve or thirty-one.
        JP      P,L04D8         ; back to SA-LEADER until H becomes $FF

;   now send a sync pulse. At this stage mic is off and A holds value
;   for mic on.
;   A sync pulse is much shorter than the steady pulses of the lead-in.

        LD      B,$2F           ; another short timed delay.

;; SA-SYNC-1
L04EA:  DJNZ    L04EA           ; self loop to SA-SYNC-1

        OUT     ($FE),A         ; switch to mic on and red.
        LD      A,$0D           ; prepare mic off - cyan
        LD      B,$37           ; another short timed delay.

;; SA-SYNC-2
L04F2:  DJNZ    L04F2           ; self loop to SA-SYNC-2

        OUT     ($FE),A         ; output mic off, cyan border.
        LD      BC,$3B0E        ; B=$3B time(*), C=$0E, YELLOW, MIC OFF.

; 

        EX      AF,AF'          ; restore saved flag
                                ; which is 1st byte to be saved.

        LD      L,A             ; and transfer to L.
                                ; the initial parity is A, $FF or $00.
        JP      L0507           ; JUMP forward to SA-START     ->
                                ; the mid entry point of loop.

; -------------------------
;   During the save loop a parity byte is maintained in H.
;   the save loop begins by testing if reduced length is zero and if so
;   the final parity byte is saved reducing count to $FFFF.

;; SA-LOOP
L04FE:  LD      A,D             ; fetch high byte
        OR      E               ; test against low byte.
        JR      Z,L050E         ; forward to SA-PARITY if zero.

        LD      L,(IX+$00)      ; load currently addressed byte to L.

;; SA-LOOP-P
L0505:  LD      A,H             ; fetch parity byte.
        XOR     L               ; exclusive or with new byte.

; -> the mid entry point of loop.

;; SA-START
L0507:  LD      H,A             ; put parity byte in H.
        LD      A,$01           ; prepare blue, mic=on.
        SCF                     ; set carry flag ready to rotate in.
        JP      L0525           ; JUMP forward to SA-8-BITS            -8->

; ---

;; SA-PARITY
L050E:  LD      L,H             ; transfer the running parity byte to L and
        JR      L0505           ; back to SA-LOOP-P 
                                ; to output that byte before quitting normally.

; ---

;   The entry point to save yellow part of bit.
;   A bit consists of a period with mic on and blue border followed by 
;   a period of mic off with yellow border. 
;   Note. since the DJNZ instruction does not affect flags, the zero flag is 
;   used to indicate which of the two passes is in effect and the carry 
;   maintains the state of the bit to be saved.

;; SA-BIT-2
L0511:  LD      A,C             ; fetch 'mic on and yellow' which is 
                                ; held permanently in C.
        BIT     7,B             ; set the zero flag. B holds $3E.

;   The entry point to save 1 entire bit. For first bit B holds $3B(*).
;   Carry is set if saved bit is 1. zero is reset NZ on entry.

;; SA-BIT-1
L0514:  DJNZ    L0514           ; self loop for delay to SA-BIT-1

        JR      NC,L051C        ; forward to SA-OUT if bit is 0.

;   but if bit is 1 then the mic state is held for longer.

        LD      B,$42           ; set timed delay. (66 decimal)

;; SA-SET
L051A:  DJNZ    L051A           ; self loop to SA-SET 
                                ; (roughly an extra 66*13 clock cycles)

;; SA-OUT
L051C:  OUT     ($FE),A         ; blue and mic on OR  yellow and mic off.

        LD      B,$3E           ; set up delay
        JR      NZ,L0511        ; back to SA-BIT-2 if zero reset NZ (first pass)

;   proceed when the blue and yellow bands have been output.

        DEC     B               ; change value $3E to $3D.
        XOR     A               ; clear carry flag (ready to rotate in).
        INC     A               ; reset zero flag i.e. NZ.

; -8-> 

;; SA-8-BITS
L0525:  RL      L               ; rotate left through carry
                                ; C<76543210<C
        JP      NZ,L0514        ; JUMP back to SA-BIT-1 
                                ; until all 8 bits done.

;   when the initial set carry is passed out again then a byte is complete.

        DEC     DE              ; decrease length
        INC     IX              ; increase byte pointer
        LD      B,$31           ; set up timing.

        LD      A,$7F           ; test the space key and
        IN      A,($FE)         ; return to common exit (to restore border)
        RRA                     ; if a space is pressed
        RET     NC              ; return to SA/LD-RET.   - - >

;   now test if byte counter has reached $FFFF.

        LD      A,D             ; fetch high byte
        INC     A               ; increment.
        JP      NZ,L04FE        ; JUMP to SA-LOOP if more bytes.

        LD      B,$3B           ; a final delay. 

;; SA-DELAY
L053C:  DJNZ    L053C           ; self loop to SA-DELAY

        RET                     ; return - - >

; ------------------------------
; THE 'SAVE/LOAD RETURN' ROUTINE
; ------------------------------
;   The address of this routine is pushed on the stack prior to any load/save
;   operation and it handles normal completion with the restoration of the
;   border and also abnormal termination when the break key, or to be more
;   precise the space key is pressed during a tape operation.
;
; - - >

;; SA/LD-RET
L053F:  PUSH    AF              ; preserve accumulator throughout.
        LD      A,7
        OUT     ($FE),A         ; change the border colour.
L0554:  POP     AF              ; restore the accumulator.
        RET                     ; return.




; ------------------------------------
; Load header or block of information
; ------------------------------------
;   This routine is used to load bytes and on entry A is set to $00 for a
;   header or to $FF for data.  IX points to the start of receiving location
;   and DE holds the length of bytes to be loaded. If, on entry the carry flag
;   is set then data is loaded, if reset then it is verified.

LdBytes:
;; LD-BYTES
L0556:  INC     D               ; reset the zero flag without disturbing carry.
        EX      AF,AF'          ; preserve entry flags.
        DEC     D               ; restore high byte of length.

        LD      A,$0F           ; make the border white and mic off.
        OUT     ($FE),A         ; output to port.

        LD      HL,L053F        ; Address: SA/LD-RET
        PUSH    HL              ; is saved on stack as terminating routine.

;   the reading of the EAR bit (D6) will always be preceded by a test of the
;   space key (D0), so store the initial post-test state.

        IN      A,($FE)         ; read the ear state - bit 6.
        RRA                     ; rotate to bit 5.
        AND     $20             ; isolate this bit.
        OR      $02             ; combine with red border colour.
        LD      C,A             ; and store initial state long-term in C.
        CP      A               ; set the zero flag.

;

;; LD-BREAK
L056B:  RET     NZ              ; return if at any time space is pressed.

;; LD-START
L056C:  CALL    L05E7           ; routine LD-EDGE-1
        JR      NC,L056B        ; back to LD-BREAK with time out and no
                                ; edge present on tape.

;   but continue when a transition is found on tape.

        LD      HL,$0415        ; set up 16-bit outer loop counter for
                                ; approx 1 second delay.

;; LD-WAIT
L0574:  DJNZ    L0574           ; self loop to LD-WAIT (for 256 times)

        DEC     HL              ; decrease outer loop counter.
        LD      A,H             ; test for
        OR      L               ; zero.
        JR      NZ,L0574        ; back to LD-WAIT, if not zero, with zero in B.

;   continue after delay with H holding zero and B also.
;   sample 256 edges to check that we are in the middle of a lead-in section.

        CALL    L05E3           ; routine LD-EDGE-2
        JR      NC,L056B        ; back to LD-BREAK
                                ; if no edges at all.

;; LD-LEADER
L0580:  LD      B,$9C           ; set timing value.
        CALL    L05E3           ; routine LD-EDGE-2
        JR      NC,L056B        ; back to LD-BREAK if time-out

        LD      A,$C6           ; two edges must be spaced apart.
        CP      B               ; compare
        JR      NC,L056C        ; back to LD-START if too close together for a
                                ; lead-in.

        INC     H               ; proceed to test 256 edged sample.
        JR      NZ,L0580        ; back to LD-LEADER while more to do.

;   sample indicates we are in the middle of a two or five second lead-in.
;   Now test every edge looking for the terminal sync signal.

;; LD-SYNC
L058F:  LD      B,$C9           ; initial timing value in B.
        CALL    L05E7           ; routine LD-EDGE-1
        JR      NC,L056B        ; back to LD-BREAK with time-out.

        LD      A,B             ; fetch augmented timing value from B.
        CP      $D4             ; compare
        JR      NC,L058F        ; back to LD-SYNC if gap too big, that is,
                                ; a normal lead-in edge gap.

;   but a short gap will be the sync pulse.
;   in which case another edge should appear before B rises to $FF

        CALL    L05E7           ; routine LD-EDGE-1
        RET     NC              ; return with time-out.

; proceed when the sync at the end of the lead-in is found.
; We are about to load data so change the border colours.

        LD      A,C             ; fetch long-term mask from C
        XOR     $03             ; and make blue/yellow.

        LD      C,A             ; store the new long-term byte.

        LD      H,$00           ; set up parity byte as zero.
        LD      B,$B0           ; timing.
        JR      L05C8           ; forward to LD-MARKER
                                ; the loop mid entry point with the alternate
                                ; zero flag reset to indicate first byte
                                ; is discarded.

; --------------
;   the loading loop loads each byte and is entered at the mid point.

;; LD-LOOP
L05A9:  EX      AF,AF'          ; restore entry flags and type in A.
        JR      NZ,L05B3        ; forward to LD-FLAG if awaiting initial flag
                                ; which is to be discarded.

        JR      NC,L05BD        ; forward to LD-VERIFY if not to be loaded.

        LD      (IX+$00),L      ; place loaded byte at memory location.
        JR      L05C2           ; forward to LD-NEXT

; ---

;; LD-FLAG
L05B3:  RL      C               ; preserve carry (verify) flag in long-term
                                ; state byte. Bit 7 can be lost.

        XOR     L               ; compare type in A with first byte in L.
        RET     NZ              ; return if no match e.g. CODE vs. DATA.

;   continue when data type matches.

        LD      A,C             ; fetch byte with stored carry
        RRA                     ; rotate it to carry flag again
        LD      C,A             ; restore long-term port state.

        INC     DE              ; increment length ??
        JR      L05C4           ; forward to LD-DEC.
                                ; but why not to location after ?

; ---
;   for verification the byte read from tape is compared with that in memory.

;; LD-VERIFY
L05BD:  LD      A,(IX+$00)      ; fetch byte from memory.
        XOR     L               ; compare with that on tape
        RET     NZ              ; return if not zero.

;; LD-NEXT
L05C2:  INC     IX              ; increment byte pointer.

;; LD-DEC
L05C4:  DEC     DE              ; decrement length.
        EX      AF,AF'          ; store the flags.
        LD      B,$B2           ; timing.

;   when starting to read 8 bits the receiving byte is marked with bit at right.
;   when this is rotated out again then 8 bits have been read.

;; LD-MARKER
L05C8:  LD      L,$01           ; initialize as %00000001

;; LD-8-BITS
L05CA:  CALL    L05E3           ; routine LD-EDGE-2 increments B relative to
                                ; gap between 2 edges.
        RET     NC              ; return with time-out.

        LD      A,$CB           ; the comparison byte.
        CP      B               ; compare to incremented value of B.
                                ; if B is higher then bit on tape was set.
                                ; if <= then bit on tape is reset.

        RL      L               ; rotate the carry bit into L.

        LD      B,$B0           ; reset the B timer byte.
        JP      NC,L05CA        ; JUMP back to LD-8-BITS

;   when carry set then marker bit has been passed out and byte is complete.

        LD      A,H             ; fetch the running parity byte.
        XOR     L               ; include the new byte.
        LD      H,A             ; and store back in parity register.

        LD      A,D             ; check length of
        OR      E               ; expected bytes.
        JR      NZ,L05A9        ; back to LD-LOOP
                                ; while there are more.

;   when all bytes loaded then parity byte should be zero.

        LD      A,H             ; fetch parity byte.
        CP      $01             ; set carry if zero.
        RET                     ; return
                                ; in no carry then error as checksum disagrees.

; -------------------------
; Check signal being loaded
; -------------------------
;   An edge is a transition from one mic state to another.
;   More specifically a change in bit 6 of value input from port $FE.
;   Graphically it is a change of border colour, say, blue to yellow.
;   The first entry point looks for two adjacent edges. The second entry point
;   is used to find a single edge.
;   The B register holds a count, up to 256, within which the edge (or edges)
;   must be found. The gap between two edges will be more for a '1' than a '0'
;   so the value of B denotes the state of the bit (two edges) read from tape.

; ->

;; LD-EDGE-2
L05E3:  CALL    L05E7           ; call routine LD-EDGE-1 below.
        RET     NC              ; return if space pressed or time-out.
                                ; else continue and look for another adjacent 
                                ; edge which together represent a bit on the 
                                ; tape.

; -> 
;   this entry point is used to find a single edge from above but also 
;   when detecting a read-in signal on the tape.

;; LD-EDGE-1
L05E7:  LD      A,$16           ; a delay value of twenty two.

;; LD-DELAY
L05E9:  DEC     A               ; decrement counter
        JR      NZ,L05E9        ; loop back to LD-DELAY 22 times.

        AND      A              ; clear carry.

;; LD-SAMPLE
L05ED:  INC     B               ; increment the time-out counter.
        RET     Z               ; return with failure when $FF passed.

        LD      A,$7F           ; prepare to read keyboard and EAR port
        IN      A,($FE)         ; row $7FFE. bit 6 is EAR, bit 0 is SPACE key.
        RRA                     ; test outer key the space. (bit 6 moves to 5)
        RET     NC              ; return if space pressed.  >>>

        XOR     C               ; compare with initial long-term state.
        AND     $20             ; isolate bit 5
        JR      Z,L05ED         ; back to LD-SAMPLE if no edge.

;   but an edge, a transition of the EAR bit, has been found so switch the
;   long-term comparison byte containing both border colour and EAR bit. 

        LD      A,C             ; fetch comparison value.
        CPL                     ; switch the bits
        LD      C,A             ; and put back in C for long-term.

        AND     $07             ; isolate new colour bits.
        OR      $08             ; set bit 3 - MIC off.
        OUT     ($FE),A         ; send to port to effect the change of colour. 

        SCF                     ; set carry flag signaling edge found within
                                ; time allowed.
        RET                     ; return.



TestScreen
                        incbin "test48kmcleod_screen.scr"

                        org 16383
                        db 0