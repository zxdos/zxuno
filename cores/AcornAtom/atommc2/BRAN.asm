;
; **** Note **** to use this code you need to patch the floating point rom 
;
;=============================
;Floating Point Patch (#Dxxx):
;=============================
;
;Original                     Patch
;-------------------------    -------------------------
;D4AF: Ad 04 E0  LDA #E004    D4AF: AD 20 EB  LDA #EB20
;D4B2: C9 BF     CMP @#BF     D4B2: C9 40     CMP @#40
;D4B4: F0 0A     BEQ #D4C0    D4B4: F0 0A     BEQ #D4C0
;D4B6: AD 00 A0  LDA #A000    D4B6: AD 01 A0  LDA #A001
;D4B9: C9 40     CMP @#40     D4B9: C9 BF     CMP @#BF
;D4BB: D0 83     BNE #D440    D4BB: D0 83     BNE #D440
;D4BD: 4C 01 A0  JMP #A002    D4BD: 4C 02 A0  JMP #A002
;D4C0: 4C 05 E0  JMP #E005    D4C3: 4C 22 EB  JMP #EB22


; *** Options ***

LATCH		= $BFFF
SHADOW 		= $FD			; If $BFFF is write only otherwise SHADOW =$BFFF
MAX		= $8
ZPBASE		= $90
ZPLENGTH	= $10

; *** Workarea ***

BASE		= $400
BRKLOW		= BASE
BRKHIGH		= BRKLOW+1
BRKROM		= BRKHIGH+1
STARTROM	= BRKROM+1
TEMP		= STARTROM+1
VECTOR		= TEMP
DUMP		= TEMP+1
VECT		= MAX*ZPLENGTH
VECTAB		= VECT+DUMP+1 
SUB_ACCU	= VECTAB+1+15*3
SUB_STATUS	= SUB_ACCU+1
SUB_Y		= SUB_STATUS+1
SUB_X		= SUB_Y+1
STACKPOINTER	= SUB_X
SUBVECTOR	= SUB_X+1
INTVECTOR	= SUBVECTOR+2
INT_ACCU	= INTVECTOR+2
INT_STATUS1	= INT_ACCU+1
INT_STATUS2	= INT_STATUS1+1
INT_X		= INT_STATUS2+1
INT_Y		= INT_X+1
OPT_PCHARME	= INT_Y+1
FREE		= OPT_PCHARME+1

; *** Constants ***

BRKVEC		= $202
TEXT		= $F7D1
CR		= $D
LF		= $A
DELIM		= $EA

.SEGMENT "BRAN"

; *** Start of assembly ***

	.BYTE $40,$bf			; ROM entry

; *** Entry in system ***

ENTRY:
	LDA 6				; Test directmode
	CMP #1
	BNE LABEL8

	BIT $B001			; Test SHIFT
	BMI LABEL8

	LDX #0				; Test RETURN
	LDA (5,X)
	CMP #CR
	BNE LABEL8

	JMP UNLOCK+3			; If SHIFT-RETURN, unlock ROMs

LABEL8:
	BIT SHADOW			; ROM locked?
	BVC NOT_LOCKED
	JMP LOCKED

; *** Not locked search ***

NOT_LOCKED:
	LDA SHADOW 			; Save current ROM nr
	STA STARTROM
	JSR UPDATE_VECTORS		; Save current vectors
	JSR SWITCH_CONTEXT_OUT		; Store zeropage

	LDA BRKVEC+1			; Check if breakvector is changed
	CMP #>HANDLER
	BEQ LABEL1			; If not, change it
	STA BRKHIGH
	LDA BRKVEC
	STA BRKLOW

	LDA SHADOW 			; Save lastrom
	STA BRKROM
LABEL1:
	JMP SWITCH

; ***  Try next box ***

NEXT_BOX:
	INC SHADOW			; Switch to next ROM
	LDA SHADOW 
	STA LATCH

	CMP #MAX			; If last reached, switch to ROM 0
	BNE LABEL2
	LDA #0
	STA SHADOW 
	STA LATCH
LABEL2:
	JSR SWITCH_CONTEXT_IN		; Restore zeropage

	LDA SHADOW 			; Check if all ROMs entered
	CMP STARTROM
	BNE SWITCH
	JMP NOT_FOUND			; Command not found in ROMs, try table

; *** Replace break vector and enter ROM ***

SWITCH:
	LDA #>HANDLER			; Replace breakvector
	STA BRKVEC+1
	LDA #<HANDLER
	STA BRKVEC

	LDA $A000			; Check if new ROM is legal
	CMP #$40
	BNE NEXT_BOX
 	LDA $A001
	CMP #$BF
	BNE NEXT_BOX
	JMP $A002			; Is legal, enter ROM

; *** Central break handler ***

HANDLER:
	PLA
	STA TEMP			; Save high byte ERROR
	PLA
	STA 0				; Save low byte ERROR

	BIT SHADOW 			; ROM locked?
	BVC NOT_LOCKED_ERROR
	JMP LOCKED_ERROR

; *** ERROR with ROM not locked ***

NOT_LOCKED_ERROR:
	CMP #94				; ERROR 94?
	BNE NOT_ERROR_94

	LDY $5E				; Check if command is abreviated
	LDA (5),Y
	CMP #'.'
	BNE LABEL99
	JMP NOT_FOUND			; Command not found in ROMs, try table
LABEL99:
	LDX #$FF			; Reset stackpointer
	TXS
	JMP NEXT_BOX			; Check next ROM

; *** Function check ***

NOT_ERROR_94:
	LDA BRKLOW			; Set breakpointer
	STA BRKVEC
	LDA BRKHIGH
	STA BRKVEC+1

	LDA 0				; Get ERROR nr
	CMP #174			; ERROR 174?
	BEQ INSTALL

	CMP #29				; ERROR 29?
	BNE NOT_INSTALL

; *** Install fake caller ***

INSTALL:
	TSX				; Save stackpointer
	STX STACKPOINTER

	LDX #$FF
LB1:
	LDA $100,X
	CPX STACKPOINTER
	BCC NOT_INSTALL
	BEQ NOT_INSTALL

	DEX
	DEX
	AND #$F0
	CMP #$A0
	BEQ LB1

	CPX #$FD			; No A-block?
	BEQ NOT_INSTALL

	TXA
	CLC
	ADC #3
	STA STACKPOINTER
	PHA
	PHA
	PHA
	TSX
LB2:
	LDA $103,X
	STA $100,X
	INX
	CPX STACKPOINTER
	BNE LB2

	LDA STACKPOINTER
	TAX
	DEX
	LDA SHADOW 
	STA $100,X
	DEX
	LDA #>(SWITCH_BACK-1)
	STA $100,X
	LDA #<(SWITCH_BACK-1)
	DEX
	STA $100,X
	
NOT_INSTALL:
	JSR SWITCH_CONTEXT_OUT		; Store zeropage
	JSR UPDATE_VECTORS		; Save vectors

	LDA BRKROM			; Set start ROM nr
	STA SHADOW 
	STA LATCH

	JSR SWITCH_CONTEXT_IN		; Restore zeropage

; *** Terminate search ***

	LDA 0				; Get LB return address
	PHA				; Push on stack
	LDA TEMP			; Get HB return address
	PHA				; Push on stack
	JMP (BRKVEC)			; Return

; *** ERROR with ROM locked ***

LOCKED_ERROR:
	LDA SHADOW			; Set start ROM nr
	STA BRKROM

	LDA 0				; Get ERROR nr
	CMP #94				; ERROR 94?
	BEQ LABEL3
	JMP NOT_ERROR_94

LABEL3:
	LDX #$FF			; Reset stackpointer
	TXS
	JMP NOT_FOUND			; Command not found in ROMs, try table

; *** Store zeropage (always #91-#98) ***

SWITCH_CONTEXT_OUT:
	LDA SHADOW 			; Get ROM nr
	AND #$F				; Filter to 0-15
	TAX
	INX

	LDA #0

LABEL4:
	CLC				; DUMP pointer = ROMnr * ZPLENGTH-1
	ADC #ZPLENGTH
	DEX
	BNE LABEL4

	LDX #(ZPLENGTH-1)		; Set ZPBASE pointer
	TAY
	DEY
	
LABEL5:
	LDA ZPBASE,X			; Save zeropage
	STA DUMP,Y
	DEY
	DEX
	BPL LABEL5
	RTS

; *** Restore zeropage (always #91-#98) ***

SWITCH_CONTEXT_IN:
	LDA SHADOW 			; Get ROM nr
	AND #$F				; Filter to 0-15
	TAX
	INX

	LDA #0
	
LABEL6:
	CLC				; DUMP pointer = ROMnr * ZPLENGTH-1
	ADC #ZPLENGTH
	DEX
	BNE LABEL6

	LDX #(ZPLENGTH-1)		; Set ZPBASE pointer
	TAY
	DEY
	
LABEL7:
	LDA DUMP,Y			; Restore zeropage
	STA ZPBASE,X
	DEY
	DEX
	BPL LABEL7
	RTS

; *** Start search locked ***

LOCKED:
	LDA BRKVEC+1			; Check if break handler switched
	CMP #>HANDLER
	BEQ LABEL21

	STA BRKHIGH			; If not, save break handler
	LDA BRKVEC
	STA BRKLOW

	LDA #>HANDLER			; Replace break handler
	STA BRKVEC+1
	LDA #<HANDLER
	STA BRKVEC

	LDA SHADOW 			; Set start ROM nr
	STA BRKROM
	
LABEL21:
	LDA $A000			; Check if legal rom
	CMP #$40
	BNE TRAP_ERROR
	LDA $A001
	CMP #$BF
	BNE TRAP_ERROR
	JMP $A002			; If legal, enter ROM
	
TRAP_ERROR:
	JMP $C558			; No legal ROM, return

; *** Not found in boxes ***
;     Try own table
;     If not found in table
;     Try by original BRKVEC

NOT_FOUND:
	LDA BRKLOW			; Reset break handler
	STA BRKVEC
	LDA BRKHIGH
	STA BRKVEC+1

	JSR SWITCH_CONTEXT_OUT		; Store zeropage

	LDA BRKROM			; Reset ROM nr
	STA SHADOW 
	STA LATCH

	JSR SWITCH_CONTEXT_IN		; Restore zeropage
	LDX #$FF
	
NEXT_STATEMENT:
	LDY $5E
	LDA (5),Y
	CMP #'.'
	BNE LABEL54
	
TRAP_ERROR_94:
	JMP $C558
	
LABEL54:
	DEY
	
NEXT_CHAR:
	INX
	INY
	
LABEL12:
	LDA TABLE,X
	CMP #$FF
	BEQ TRAP_ERROR_94
	
LABEL15:
	CMP #$FE
	BEQ LABEL14
	CMP (5),Y
	BEQ NEXT_CHAR
	DEX
	LDA (5),Y
	CMP #'.'
	BEQ LABEL100
	
LABEL13:
	INX
	LDA TABLE,X
	CMP #$FE
	BNE LABEL13
	INX
	INX
	JMP NEXT_STATEMENT
	
LABEL100:
	INX
	LDA TABLE,X
	CMP #$FE
	BNE LABEL100
	INY
	
LABEL14:
	LDA TABLE+1,X
	STA $53
	LDA TABLE+2,X
	STA $52
	STY 3
	LDX 4
	JMP ($0052)

; *** Own commands ***

ROM:
	JSR $C4E1
	JSR UPDATE_VECTORS
	LDX 4
	DEX
	STX 4
	LDA $16,X
	AND #$F
	ORA #$40
 	STA SHADOW 
 	STA LATCH

 	LDA $A000
	CMP #$40
	BNE LABEL9
	LDA $A001
	CMP #$BF
	BEQ LABEL20
	
LABEL9:
	JSR TEXT
	.byte "NO ROM AVAILABLE"
	.BYTE CR,LF,DELIM
	
LABEL20:
	LDA BRKROM
	ORA #$40
	CMP SHADOW 
	BEQ LABEL60

	LDA #$D8			; Install original BRK handler
	STA BRKVEC
	LDA #$C9
	STA BRKVEC+1
	
LABEL60:
	JMP $C55B
	
UNLOCK:
	JSR $C4E4
	LDA SHADOW 
	AND #$F
	STA SHADOW 
	STA LATCH
	JMP $C55B

; *** Table of commands ***

TABLE:
	.byte	"ROM",$FE
	.byte	>ROM,<ROM
	.byte	"UNLOCK",$FE
	.byte	>UNLOCK,<UNLOCK

	.BYTE $FF

; *** Check vectors ***
; If vector point to #Axxx, 
; save it with corresponding ROM nr
; and replace vector

UPDATE_VECTORS:
	PHP
	SEI

	LDX #0				; Reset pointers
	LDY #0
	
LABEL30:
	LDA $201,X			; Check if vector points to #Axxx
	AND #$F0
	CMP #$A0
	BNE LABEL31
	CPX #2				; Skip BRK vector
	BEQ LABEL31

	LDA $200,X			; Save vector
	STA VECTAB+1,Y
	LDA $201,X
	STA VECTAB,Y
	LDA SHADOW 			; Save ROM nr
	STA VECTAB+2,Y

	TXA				; Replace vector
	ASL A
	ASL A
	CLC
	ADC #<VECENTRY
	STA $200,X
	LDA #>VECENTRY
	ADC #0
 	STA $201,X
	
LABEL31:
	INX				; Point to next vector
	INX

	INY
	INY
	INY

	CPX #$1C			; Check end of vectors
	BNE LABEL30

	LDA $3FF			; Check if plot vector points at #Axxx (SCREEN ROM)
 	AND #$F0
	CMP #$A0
	BNE LABEL32

	LDA $3FF			; Save plot vector
	STA VECTAB,Y
	LDA $3FE
	STA VECTAB+1,Y
	LDA #>(VECENTRY+14*8)		; Replace plot vector
	STA $3FF
	LDA #<(VECENTRY+14*8)
	STA $3FE

	LDA SHADOW			; Save ROM nr
	STA VECTAB+2,Y
	
LABEL32:
	PLP
	RTS

; *** Entry vector pathways ***

VECENTRY:
	JSR ISAVE			; $200, NMI vector
	LDX #0
	JMP IJOB

	NOP				; $202, BRK vector
	NOP
	NOP
	NOP
	NOP
	JMP $C558

	JSR ISAVE			; $204, IRQ vector
	LDX #6
	JMP IJOB

	JSR SAVE			; $206, *COM vector
	LDX #9
	JMP JOB

	JSR SAVE			; $208, Write vector
	LDX #12
	JMP JOB

	JSR SAVE			; $20A, Read vector
	LDX #15
	JMP JOB

	JSR SAVE			; $20C, Load vector
	LDX #18
	JMP JOB

	JSR SAVE			; $20E, Save vector
	LDX #21
	JMP JOB

	JSR SAVE			; $210,  vector
	LDX #24
	JMP JOB

	JSR SAVE			; $212,  vector
	LDX #27
	JMP JOB

	JSR SAVE			; $214, Get byte vector
	LDX #30
	JMP JOB

	JSR SAVE			; $216, Put byte vector
	LDX #33
	JMP JOB

	JSR SAVE			; $218, Print message vector
	LDX #36
	JMP JOB

	JSR SAVE			; $21A, Shut vector
	LDX #39
	JMP JOB
 
	JSR SAVE			; $3FF, Plot vector
	LDX #42
	JMP JOB

; *** Save normal processor/registers ***

SAVE:
	PHP				; Save processor status
	STA SUB_ACCU			; Save accu
	PLA
	STA SUB_STATUS			; Save status
	STX SUB_X			; Save X-reg
	STY SUB_Y			; Save Y-reg
	RTS

; *** Save interrupt processor/registers ***

ISAVE:
	PHP				; Save processor status
	STA INT_ACCU			; Save accu
	PLA
	STA INT_STATUS1			; Save status
	STX INT_X			; Save X-reg
	STY INT_Y			; Save Y-reg
	RTS

; *** Reset normal processor/registers ***

LOAD:
	LDY SUB_Y			; Reset Y-reg
	LDX SUB_X			; Reset X-reg
	LDA SUB_STATUS			; Reset status
	PHA
	LDA SUB_ACCU			; Reset accu
	PLP				; Reset processor status
	RTS

; *** Reset interrupt processor/registers ***

ILOAD:
	LDX INT_X			; Reset Y-reg
	LDY INT_Y			; Reset X-reg
	LDA INT_STATUS1			; Reset status
	PHA
	LDA INT_ACCU			; Reset accu
	PLP				; Reset processor status
	RTS

; *** Interrupt switching pathway ***

IJOB:
	PLA
	STA INT_ACCU
	PLA
	PHA
	STA INT_STATUS2

	LDA SHADOW			; Save ROM nr
	PHA

	LDA VECTAB+2,X			; Reset ROM nr
	STA SHADOW 
	STA LATCH

	LDA VECTAB,X			; Reset NMI/IRQ vector
	STA INTVECTOR+1
	LDA VECTAB+1,X
	STA INTVECTOR

	LDA #>IENTRY			; Replace NMI/IRQ vector
	PHA
	LDA #<IENTRY
	PHA
	LDA INT_STATUS2
	PHA
	LDA INT_ACCU
	PHA
	JSR ILOAD
	JMP (INTVECTOR)			; Jump interrupt vector


; *** NMI/IRQ entry ***

IENTRY:
	JSR ISAVE			; Save processor/register values
	PLA
	STA SHADOW 
	STA LATCH
	PLP
	LDA INT_STATUS2
	PHA
	JSR ILOAD			; Load processor/register values
	RTI				; Return from interrupt

; *** Non interrupt switching pathway ***

JOB:
	STX VECTOR
	TXA
	PHA

	LDA $60				; Save option PCharm
	STA OPT_PCHARME			;**!!**
	
	LDA VECTAB+2,X
	CMP SHADOW 
	BEQ SHORT_EXECUTION
	CPX #21				; Save file
	BNE LABEL40

	JSR UPDATE_VECTORS		;**!!**
	LDX VECTOR
	
LABEL40:
	CPX #30				; Get byte
	BEQ SHORT_EXECUTION
	CPX #33				; Put byte
	BEQ SHORT_EXECUTION
	JSR SWITCH_CONTEXT_OUT		; Store zeropage
	LDX VECTOR
	LDA SHADOW 
	PHA
	LDA VECTAB+1,X
	STA SUBVECTOR
	LDA VECTAB,X
	STA SUBVECTOR+1
	LDA VECTAB+2,X
	STA SHADOW 
	STA LATCH
	JSR SWITCH_CONTEXT_IN		; Restore zeropage
	JSR LOAD
	JSR LB50
	JMP LB51
	
LB50:
	JMP (SUBVECTOR)
	
LB51:
	JSR SAVE
	JSR SWITCH_CONTEXT_OUT		; Store zeropage
	PLA
	STA SHADOW 
	STA LATCH
	JSR SWITCH_CONTEXT_IN		; Restore zeropage

	LDA OPT_PCHARME			;**!!**
	STA $60

	PLA
	CMP #21				; Save file
	BNE LB10
	LDA VECTAB+13
	CMP #$CE			; ED64 outchar?
	BNE LB10

	LDA #$CE			;**!!**
	STA $208
	LDA #$AC
	STA $209
	
LB10:
	JMP LOAD

; *** No swith pathway ***

SHORT_EXECUTION:
	PLA
	LDX VECTOR
	LDA SHADOW 
	PHA
	LDA VECTAB+2,X
	STA SHADOW 
	STA LATCH
	LDA VECTAB,X
	STA SUBVECTOR+1
	LDA VECTAB+1,X
	STA SUBVECTOR
	JSR LOAD
	JSR LB60
	JMP LB61
	
LB60:
	JMP (SUBVECTOR)
	
LB61:
	JSR SAVE
	PLA
	STA SHADOW 
	STA LATCH

	LDA OPT_PCHARME			;**!!**
	STA $60
	JMP LOAD

; *** Fake expression caller ***

SWITCH_BACK:
	JSR SAVE
	JSR SWITCH_CONTEXT_OUT		; Store zeropage
	PLA
	STA SHADOW 
	STA LATCH
	JSR SWITCH_CONTEXT_IN		; Restore zeropage
	LDA #>HANDLER			; Reinit break handler
	STA BRKVEC+1
	LDA #<HANDLER
	STA BRKVEC
	JMP LOAD

