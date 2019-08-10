;Universal PT2'n'PT3 Turbo Sound player for ZX Spectrum
;(c)2004-2007 S.V.Bulba <vorobey@mail.khstu.ru>
;Specially for AlCo
;http://bulba.untergrund.net/ (http://bulba.at.kz/)

;Release number
Release EQU "0"

;Conditional assembly
;1) Current position counters at (Vars1+0) and (Vars2+0)
CurPosCounter=0
;2) Allow channels allocation bits at (START+10)
ACBBAC=0
;3) Allow loop checking and disabling
LoopChecker=1
;4) Insert official identificator
Id=0
;5) Set IY for correct return to ZX Basic
Basic=1

;Features
;--------
;-Can be compiled at any address (i.e. no need rounding ORG
; address).
;-Variables (VARS) can be located at any address (not only after
; code block).
;-INIT subprogram checks PT3-module version and rightly
; generates both note and volume tables outside of code block
; (in VARS).
;-Two portamento (spc. command 3xxx) algorithms (depending of
; PT3 module version).
;-New 1.XX and 2.XX special command behaviour (only for PT v3.7
; and higher).
;-Any Tempo value are accepted (including Tempo=1 and Tempo=2).
;-TS modes: 2xPT3, 2xPT2 and PT v3.7 TS standard.
;-Fully compatible with Ay_Emul PT3 and PT2 players codes.
;-See also notes at the end of this source code.

;Limitations
;-----------
;-Can run in RAM only (self-modified code is used).
;-PT2 position list must be end by #FF marker only.

;Warning!!! PLAY subprogram can crash if no module are loaded
;into RAM or INIT subprogram was not called before.

;Call MUTE or INIT one more time to mute sound after stopping
;playing 

	DISP #4000

;Test codes (commented)
;	LD A,32 ;SinglePT3(TS if TSPT3.7),ABC,Looped
;	LD (START+10),A
;	LD HL,#8000 ;Mod1
;	LD DE,#A000 ;Mod2 (optional)
;	CALL START+3
;	EI
;_LP	HALT
;	CALL START+5
;	XOR A
;	IN A,(#FE)
;	CPL
;	AND 15
;	JR Z,_LP
;	JR START+8

TonA	EQU 0
TonB	EQU 2
TonC	EQU 4
Noise	EQU 6
Mixer	EQU 7
AmplA	EQU 8
AmplB	EQU 9
AmplC	EQU 10
Env	EQU 11
EnvTp	EQU 13

;Entry and other points
;START initialize playing of modules at MDLADDR (single module)
;START+3 initialization with module address in HL and DE (TS)
;START+5 play one quark
;START+8 mute
;START+10 setup and status flags

START
	LD HL,MDLADDR ;DE - address of 2nd module for TS
	JR INIT
	JP PLAY
	JR MUTE
SETUP	DB 0 ;set bit0, if you want to play without looping
	     ;(optional);
	     ;set bit1 for PT2 and reset for PT3 before
	     ;calling INIT;
	     ;bits2-3: %00-ABC, %01-ACB, %10-BAC (optional);
	     ;bits4-5: %00-no TS, %01-2 modules TS, %10-
	     ;autodetect PT3 TS-format by AlCo (PT 3.7+);
	     ;Remark: old PT3 TS-format by AlCo (PT 3.6) is not
	     ;documented and must be converted to new standard.
	     ;bit6 is set each time, when loop point of 2nd TS
	     ;module is passed (optional).
	     ;bit7 is set each time, when loop point of 1st TS
	     ;or of single module is passed (optional).

;Identifier
	IF Id
	DB "=UniPT2/PT3/TS-Player r.",Release,"="
	ENDIF

	IF LoopChecker
CHECKLP	LD HL,SETUP
	BIT 0,(IY-100+VRS.ModNum)
	JR Z,CHL1
	SET 6,(HL)
	JR CHL2
CHL1	SET 7,(HL)
CHL2	BIT 0,(HL)
	RET Z
	POP HL
	INC (IY-100+VRS.DelyCnt)
	INC (IY-100+VRS.ChanA+CHP.NtSkCn)
	XOR A
	LD (IY-100+VRS.AYREGS+AmplA),A
	LD (IY-100+VRS.AYREGS+AmplB),A
	LD (IY-100+VRS.AYREGS+AmplC),A
	RET
	ENDIF

MUTE	XOR A
	LD H,A
	LD L,A
	LD (VARS1+VRS.AYREGS+AmplA),A
	LD (VARS1+VRS.AYREGS+AmplB),HL
	LD (VARS2+VRS.AYREGS+AmplA),A
	LD (VARS2+VRS.AYREGS+AmplB),HL
	JP ROUT

INIT
;HL - AddressOfModule
;DE - AddresOf2ndModule
	PUSH DE
	PUSH HL
	LD HL,VARS
	LD (HL),0
	LD DE,VARS+1
	LD BC,VAR0END-VARS-1
	LDIR
	INC HL
	LD (VARS1+VRS.AdInPtA),HL ;ptr to zero
	LD (VARS2+VRS.AdInPtA),HL

	POP HL
	LD IY,VARS1+100
	LD A,(START+10)
	AND 2
	JP NZ,I_PT2

	CALL INITPT3
	LD HL,(e_-SamCnv-2)*256+#18
	LD (SamCnv),HL
	LD A,#BA
	LD (OrnCP),A
	LD (SamCP),A
	LD A,#7B
	LD (OrnLD),A
	LD (SamLD),A
	LD A,#87
	LD (SamClc2),A
	POP HL
	;Use version and ton table of 1st module
	LD A,(IX+13-100) ;EXTRACT VERSION NUMBER
	SUB #30
	JR C,L20
	CP 10
	JR C,L21
L20	LD A,6
L21	LD (Version),A
	PUSH AF ;VolTable version
	CP 4
	LD A,(IX+99-100) ;TONE TABLE NUMBER
	RLA
	AND 7
	PUSH AF ;NoteTable number

	LD IY,VARS2+100
	LD A,(START+10)
	AND 48
	JR Z,NOTS
	CP 16
	JR Z,TwoPT3s
	LD A,(Version)
	CP 7
	JR C,NOTS
	LD A,(IX+98-100) ;ALCO TS MARKER
	CP #20
	JR Z,NOTS
	LD HL,VARS1
	LD DE,VARS2
	LD BC,VRS
	LDIR
	SET 1,(IY-100+VRS.ModNum)
	LD C,A
	ADD A,A
	ADD A,C
	SUB 2
	LD (TSSub),A
	JR AlCoTS_
TwoPT3s	CALL INITPT3
AlCoTS_	LD A,1
	LD (is_ts),A
	SET 0,(IY-100+VRS.ModNum)

NOTS	LD BC,PT3PD
	LD HL,0
	LD DE,PT3EMPTYORN
	JR INITCOMMON

I_PT2	CALL INITPT2
	LD HL,#51CB
	LD (SamCnv),HL
	LD A,#BB
	LD (OrnCP),A
	LD (SamCP),A
	LD A,#7A
	LD (OrnLD),A
	LD (SamLD),A
	LD A,#80
	LD (SamClc2),A
	POP HL
	LD A,5
	LD (Version),A
	PUSH AF
	LD A,2
	PUSH AF

	LD A,(START+10)
	AND 48
	JR Z,NOTS2

	LD IY,VARS2+100
	LD A,1
	LD (is_ts),A
	SET 0,(IY-100+VRS.ModNum)
	CALL INITPT2

NOTS2	LD BC,PT2PD
	LD HL,#8687
	LD DE,PT2EMPTYORN

INITCOMMON

	IF Basic
	LD IY,#5C3A
	ENDIF

	LD (PTDEC),BC
	LD (PsCalc),HL
	PUSH DE

;note table data depacker
;(c) Ivan Roshin
	LD DE,T_PACK
	LD BC,T1_+(2*49)-1
TP_0	LD A,(DE)
	INC DE
	CP 15*2
	JR NC,TP_1
	LD H,A
	LD A,(DE)
	LD L,A
	INC DE
	JR TP_2
TP_1	PUSH DE
	LD D,0
	LD E,A
	ADD HL,DE
	ADD HL,DE
	POP DE
TP_2	LD A,H
	LD (BC),A
	DEC BC
	LD A,L
	LD (BC),A
	DEC BC
	SUB #F8*2
	JR NZ,TP_0

	INC A
	LD (VARS1+VRS.DelyCnt),A
	LD (VARS2+VRS.DelyCnt),A
	LD HL,#F001 ;H - CHP.Volume, L - CHP.NtSkCn
	LD (VARS1+VRS.ChanA+CHP.NtSkCn),HL
	LD (VARS1+VRS.ChanB+CHP.NtSkCn),HL
	LD (VARS1+VRS.ChanC+CHP.NtSkCn),HL
	LD (VARS2+VRS.ChanA+CHP.NtSkCn),HL
	LD (VARS2+VRS.ChanB+CHP.NtSkCn),HL
	LD (VARS2+VRS.ChanC+CHP.NtSkCn),HL
	POP HL
	LD (VARS1+VRS.ChanA+CHP.OrnPtr),HL
	LD (VARS1+VRS.ChanB+CHP.OrnPtr),HL
	LD (VARS1+VRS.ChanC+CHP.OrnPtr),HL
	LD (VARS2+VRS.ChanA+CHP.OrnPtr),HL
	LD (VARS2+VRS.ChanB+CHP.OrnPtr),HL
	LD (VARS2+VRS.ChanC+CHP.OrnPtr),HL

	POP AF

;NoteTableCreator (c) Ivan Roshin
;A - NoteTableNumber*2+VersionForNoteTable
;(xx1b - 3.xx..3.4r, xx0b - 3.4x..3.6x..VTII1.0)

	LD HL,NT_DATA
	LD D,0
	ADD A,A
	LD E,A
	ADD HL,DE
	LD E,(HL)
	INC HL
	SRL E
	SBC A,A
	AND #A7 ;#00 (NOP) or #A7 (AND A)
	LD (L3),A
	EX DE,HL
	LD BC,T1_
	ADD HL,BC

	LD A,(DE)
	ADD A,T_
	LD C,A
	ADC A,T_/256
	SUB C
	LD B,A
	PUSH BC
	LD DE,NT_
	PUSH DE

	LD B,12
L1	PUSH BC
	LD C,(HL)
	INC HL
	PUSH HL
	LD B,(HL)

	PUSH DE
	EX DE,HL
	LD DE,23
	LD IXH,8

L2	SRL B
	RR C
L3	DB #19	;AND A or NOP
	LD A,C
	ADC A,D	;=ADC 0
	LD (HL),A
	INC HL
	LD A,B
	ADC A,D
	LD (HL),A
	ADD HL,DE
	DEC IXH
	JR NZ,L2

	POP DE
	INC DE
	INC DE
	POP HL
	INC HL
	POP BC
	DJNZ L1

	POP HL
	POP DE

	LD A,E
	CP TCOLD_1
	JR NZ,CORR_1
	LD A,#FD
	LD (NT_+#2E),A

CORR_1	LD A,(DE)
	AND A
	JR Z,TC_EXIT
	RRA
	PUSH AF
	ADD A,A
	LD C,A
	ADD HL,BC
	POP AF
	JR NC,CORR_2
	DEC (HL)
	DEC (HL)
CORR_2	INC (HL)
	AND A
	SBC HL,BC
	INC DE
	JR CORR_1

TC_EXIT

	POP AF

;VolTableCreator (c) Ivan Roshin
;A - VersionForVolumeTable (0..4 - 3.xx..3.4x;
			   ;5.. - 2.x,3.5x..3.6x..VTII1.0)

	CP 5
	LD HL,#11
	LD D,H
	LD E,H
	LD A,#17
	JR NC,M1
	DEC L
	LD E,L
	XOR A
M1      LD (M2),A

	LD IX,VT_+16

	LD C,#F
INITV2  PUSH HL

	ADD HL,DE
	EX DE,HL
	SBC HL,HL

	LD B,#10
INITV1  LD A,L
M2      DB #7D
	LD A,H
	ADC A,0
	LD (IX),A
	INC IX
	ADD HL,DE
	DJNZ INITV1

	POP HL
	LD A,E
	CP #77
	JR NZ,M3
	INC E
M3      DEC C
	JR NZ,INITV2

	JP ROUT

INITPT3	CALL SETMDAD
	PUSH HL
	LD DE,100
	ADD HL,DE
	LD A,(HL)
	LD (IY-100+VRS.Delay),A
	PUSH HL
	POP IX
	ADD HL,DE
	CALL SETCPPT
	LD E,(IX+102-100)
	INC HL

	IF CurPosCounter
	LD (IY-100+VRS.PosSub),L
	ENDIF

	ADD HL,DE
	CALL SETLPPT
	POP DE
	LD L,(IX+103-100)
	LD H,(IX+104-100)
	ADD HL,DE
	CALL SETPTPT
	LD HL,169
	ADD HL,DE
	CALL SETORPT
	LD HL,105
	ADD HL,DE

SETSMPT LD (IY-100+VRS.SamPtrs),L
	LD (IY-100+VRS.SamPtrs+1),H
	RET

INITPT2	LD A,(HL)
	LD (IY-100+VRS.Delay),A
	PUSH HL
	PUSH HL
	PUSH HL
	INC HL
	INC HL
	LD A,(HL)
	INC HL
	CALL SETSMPT
	LD E,(HL)
	INC HL
	LD D,(HL)
	POP HL
	AND A
	SBC HL,DE
	CALL SETMDAD
	POP HL
	LD DE,67
	ADD HL,DE
	CALL SETORPT
	LD E,32
	ADD HL,DE
	LD C,(HL)
	INC HL
	LD B,(HL)
	LD E,30
	ADD HL,DE
	CALL SETCPPT
	LD E,A
	INC HL

	IF CurPosCounter
	LD (IY-100+VRS.PosSub),L
	ENDIF

	ADD HL,DE
	CALL SETLPPT
	POP HL
	ADD HL,BC

SETPTPT	LD (IY-100+VRS.PatsPtr),L
	LD (IY-100+VRS.PatsPtr+1),H
	RET

SETMDAD	LD (IY-100+VRS.MODADDR),L
	LD (IY-100+VRS.MODADDR+1),H
	RET

SETORPT	LD (IY-100+VRS.OrnPtrs),L
	LD (IY-100+VRS.OrnPtrs+1),H
	RET

SETCPPT	LD (IY-100+VRS.CrPsPtr),L
	LD (IY-100+VRS.CrPsPtr+1),H
	RET

SETLPPT	LD (IY-100+VRS.LPosPtr),L
	LD (IY-100+VRS.LPosPtr+1),H
	RET

SETENBS	LD (IY-100+VRS.EnvBase),L
	LD (IY-100+VRS.EnvBase+1),H
	RET

SETESLD	LD (IY-100+VRS.CurESld),L
	LD (IY-100+VRS.CurESld+1),H
	RET

GETIX	PUSH IY
	POP IX
	ADD IX,DE
	RET

PTDECOD CALL GETIX
PTDEC	EQU $+1
	JP #C3C3

;PT2 pattern decoder
PD2_SAM	CALL SETSAM
	JR PD2_LOOP

PD2_EOff LD (IX-12+CHP.Env_En),A
	JR PD2_LOOP

PD2_ENV	LD (IX-12+CHP.Env_En),16
	LD (IY-100+VRS.AYREGS+EnvTp),A
	LD A,(BC)
	INC BC
	LD L,A
	LD A,(BC)
	INC BC
	LD H,A
	CALL SETENBS
	JR PD2_LOOP

PD2_ORN	CALL SETORN
	JR PD2_LOOP

PD2_SKIP INC A
	LD (IX-12+CHP.NNtSkp),A
	JR PD2_LOOP

PD2_VOL	RRCA
	RRCA
	RRCA
	RRCA
	LD (IX-12+CHP.Volume),A
	JR PD2_LOOP

PD2_DEL	CALL C_DELAY
	JR PD2_LOOP

PD2_GLIS SET 2,(IX-12+CHP.Flags)
	INC A
	LD (IX-12+CHP.TnSlDl),A
	LD (IX-12+CHP.TSlCnt),A
	LD A,(BC)
	INC BC
        LD (IX-12+CHP.TSlStp),A
	ADD A,A
	SBC A,A
        LD (IX-12+CHP.TSlStp+1),A
	SCF
	JR PD2_LP2

PT2PD	AND A

PD2_LP2	EX AF,AF'

PD2_LOOP LD A,(BC)
	INC BC
	ADD A,#20
	JR Z,PD2_REL
	JR C,PD2_SAM
	ADD A,96
	JR C,PD2_NOTE
	INC A
	JR Z,PD2_EOff
	ADD A,15
	JP Z,PD_FIN
	JR C,PD2_ENV
	ADD A,#10
	JR C,PD2_ORN
	ADD A,#40
	JR C,PD2_SKIP
	ADD A,#10
	JR C,PD2_VOL
	INC A
	JR Z,PD2_DEL
	INC A
	JR Z,PD2_GLIS
	INC A
	JR Z,PD2_PORT
	INC A
	JR Z,PD2_STOP
	LD A,(BC)
	INC BC
	LD (IX-12+CHP.CrNsSl),A
	JR PD2_LOOP

PD2_PORT RES 2,(IX-12+CHP.Flags)
	LD A,(BC)
	INC BC
	INC BC ;ignoring precalc delta to right sound
	INC BC
	SCF
	JR PD2_LP2

PD2_STOP LD (IX-12+CHP.TSlCnt),A
	JR PD2_LOOP

PD2_REL	LD (IX-12+CHP.Flags),A
	JR PD2_EXIT

PD2_NOTE LD L,A
	LD A,(IX-12+CHP.Note)
	LD (PrNote+1),A
	LD (IX-12+CHP.Note),L
	XOR A
	LD (IX-12+CHP.TSlCnt),A
	SET 0,(IX-12+CHP.Flags)
	EX AF,AF'
	JR NC,NOGLIS2
	BIT 2,(IX-12+CHP.Flags)
	JR NZ,NOPORT2
	LD (LoStep),A
	ADD A,A
	SBC A,A
	EX AF,AF'
	LD H,A
	LD L,A
	INC A
	CALL SETPORT
NOPORT2	LD (IX-12+CHP.TSlCnt),1
NOGLIS2	XOR A


PD2_EXIT LD (IX-12+CHP.PsInSm),A
	LD (IX-12+CHP.PsInOr),A
	LD (IX-12+CHP.CrTnSl),A
	LD (IX-12+CHP.CrTnSl+1),A
	JP PD_FIN

;PT3 pattern decoder
PD_OrSm	LD (IX-12+CHP.Env_En),0
	CALL SETORN
PD_SAM_	LD A,(BC)
	INC BC
	RRCA

PD_SAM	CALL SETSAM
	JR PD_LOOP

PD_VOL	RRCA
	RRCA
	RRCA
	RRCA
	LD (IX-12+CHP.Volume),A
	JR PD_LP2
	
PD_EOff	LD (IX-12+CHP.Env_En),A
	LD (IX-12+CHP.PsInOr),A
	JR PD_LP2

PD_SorE	DEC A
	JR NZ,PD_ENV
	LD A,(BC)
	INC BC
	LD (IX-12+CHP.NNtSkp),A
	JR PD_LP2

PD_ENV	CALL SETENV
	JR PD_LP2

PD_ORN	CALL SETORN
	JR PD_LOOP

PD_ESAM	LD (IX-12+CHP.Env_En),A
	LD (IX-12+CHP.PsInOr),A
	CALL NZ,SETENV
	JR PD_SAM_

PT3PD	LD A,(IX-12+CHP.Note)
	LD (PrNote+1),A
	LD L,(IX-12+CHP.CrTnSl)
	LD H,(IX-12+CHP.CrTnSl+1)
	LD (PrSlide+1),HL

PD_LOOP	LD DE,#2010
PD_LP2	LD A,(BC)
	INC BC
	ADD A,E
	JR C,PD_OrSm
	ADD A,D
	JR Z,PD_FIN
	JR C,PD_SAM
	ADD A,E
	JR Z,PD_REL
	JR C,PD_VOL
	ADD A,E
	JR Z,PD_EOff
	JR C,PD_SorE
	ADD A,96
	JR C,PD_NOTE
	ADD A,E
	JR C,PD_ORN
	ADD A,D
	JR C,PD_NOIS
	ADD A,E
	JR C,PD_ESAM
	ADD A,A
	LD E,A
	LD HL,SPCCOMS+#FF20-#2000
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	PUSH DE
	JR PD_LOOP

PD_NOIS	LD (IY-100+VRS.Ns_Base),A
	JR PD_LP2

PD_REL	RES 0,(IX-12+CHP.Flags)
	JR PD_RES

PD_NOTE	LD (IX-12+CHP.Note),A
	SET 0,(IX-12+CHP.Flags)
	XOR A

PD_RES	LD (PDSP_+1),SP
	LD SP,IX
	LD H,A
	LD L,A
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
PDSP_	LD SP,#3131

PD_FIN	LD A,(IX-12+CHP.NNtSkp)
	LD (IX-12+CHP.NtSkCn),A
	RET

C_PORTM LD A,(BC)
	INC BC
;SKIP PRECALCULATED TONE DELTA (BECAUSE
;CANNOT BE RIGHT AFTER PT3 COMPILATION)
	INC BC
	INC BC
	EX AF,AF'
	LD A,(BC) ;SIGNED TONE STEP
	INC BC
	LD (LoStep),A
	LD A,(BC)
	INC BC
	AND A
	EX AF,AF'
	LD L,(IX-12+CHP.CrTnSl)
	LD H,(IX-12+CHP.CrTnSl+1)

;Set portamento variables
;A - Delay; A' - Hi(Step); ZF' - (A'=0); HL - CrTnSl

SETPORT	RES 2,(IX-12+CHP.Flags)
	LD (IX-12+CHP.TnSlDl),A
	LD (IX-12+CHP.TSlCnt),A
	PUSH HL
	LD DE,NT_
	LD A,(IX-12+CHP.Note)
	LD (IX-12+CHP.SlToNt),A
	ADD A,A
	LD L,A
	LD H,0
	ADD HL,DE
	LD A,(HL)
	INC HL
	LD H,(HL)
	LD L,A
	PUSH HL
PrNote	LD A,#3E
	LD (IX-12+CHP.Note),A
	ADD A,A
	LD L,A
	LD H,0
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	POP HL
	SBC HL,DE
	LD (IX-12+CHP.TnDelt),L
	LD (IX-12+CHP.TnDelt+1),H
	POP DE
Version EQU $+1
	LD A,#3E
	CP 6
	JR C,OLDPRTM ;Old 3xxx for PT v3.5-
PrSlide	LD DE,#1111
	LD (IX-12+CHP.CrTnSl),E
	LD (IX-12+CHP.CrTnSl+1),D
LoStep	EQU $+1
OLDPRTM	LD A,#3E
	EX AF,AF'
	JR Z,NOSIG
	EX DE,HL
NOSIG	SBC HL,DE
	JP P,SET_STP
	CPL
	EX AF,AF'
	NEG
	EX AF,AF'
SET_STP	LD (IX-12+CHP.TSlStp+1),A
	EX AF,AF'
	LD (IX-12+CHP.TSlStp),A
	LD (IX-12+CHP.COnOff),0
	RET

C_GLISS	SET 2,(IX-12+CHP.Flags)
	LD A,(BC)
	INC BC
	LD (IX-12+CHP.TnSlDl),A
	AND A
	JR NZ,GL36
	LD A,(Version) ;AlCo PT3.7+
	CP 7
	SBC A,A
	INC A
GL36	LD (IX-12+CHP.TSlCnt),A
	LD A,(BC)
	INC BC
	EX AF,AF'
	LD A,(BC)
	INC BC
	JR SET_STP

C_SMPOS	LD A,(BC)
	INC BC
	LD (IX-12+CHP.PsInSm),A
	RET

C_ORPOS	LD A,(BC)
	INC BC
	LD (IX-12+CHP.PsInOr),A
	RET

C_VIBRT	LD A,(BC)
	INC BC
	LD (IX-12+CHP.OnOffD),A
	LD (IX-12+CHP.COnOff),A
	LD A,(BC)
	INC BC
	LD (IX-12+CHP.OffOnD),A
	XOR A
	LD (IX-12+CHP.TSlCnt),A
	LD (IX-12+CHP.CrTnSl),A
	LD (IX-12+CHP.CrTnSl+1),A
	RET

C_ENGLS	LD A,(BC)
	INC BC
	LD (IY-100+VRS.Env_Del),A
	LD (IY-100+VRS.CurEDel),A
	LD A,(BC)
	INC BC
	LD L,A
	LD A,(BC)
	INC BC
	LD H,A
	LD (IY-100+VRS.ESldAdd),L
	LD (IY-100+VRS.ESldAdd+1),H
	RET

C_DELAY	LD A,(BC)
	INC BC
	LD (IY-100+VRS.Delay),A
	LD HL,VARS2+VRS.ModNum ;if AlCo_TS
	BIT 1,(HL)
	RET Z
	LD (VARS1+VRS.Delay),A
	LD (VARS1+VRS.DelyCnt),A
	LD (VARS2+VRS.Delay),A
	RET
	
SETENV	LD (IX-12+CHP.Env_En),E
	LD (IY-100+VRS.AYREGS+EnvTp),A
	LD A,(BC)
	INC BC
	LD H,A
	LD A,(BC)
	INC BC
	LD L,A
	CALL SETENBS
	XOR A
	LD (IX-12+CHP.PsInOr),A
	LD (IY-100+VRS.CurEDel),A
	LD H,A
	LD L,A
	JP SETESLD

SETORN	ADD A,A
	LD E,A
	LD D,0
	LD (IX-12+CHP.PsInOr),D
	LD L,(IY-100+VRS.OrnPtrs)
	LD H,(IY-100+VRS.OrnPtrs+1)
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	LD L,(IY-100+VRS.MODADDR)
	LD H,(IY-100+VRS.MODADDR+1)
	ADD HL,DE
	LD (IX-12+CHP.OrnPtr),L
	LD (IX-12+CHP.OrnPtr+1),H
C_NOP	RET

SETSAM	ADD A,A
	LD E,A
	LD D,0
	LD L,(IY-100+VRS.SamPtrs);
	LD H,(IY-100+VRS.SamPtrs+1);
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	LD L,(IY-100+VRS.MODADDR)
	LD H,(IY-100+VRS.MODADDR+1)
	ADD HL,DE
	LD (IX-12+CHP.SamPtr),L
	LD (IX-12+CHP.SamPtr+1),H
	RET

;ALL 16 ADDRESSES TO PROTECT FROM BROKEN PT3 MODULES
SPCCOMS DW C_NOP
	DW C_GLISS
	DW C_PORTM
	DW C_SMPOS
	DW C_ORPOS
	DW C_VIBRT
	DW C_NOP
	DW C_NOP
	DW C_ENGLS
	DW C_DELAY
	DW C_NOP
	DW C_NOP
	DW C_NOP
	DW C_NOP
	DW C_NOP
	DW C_NOP

CHREGS	CALL GETIX
	XOR A
	LD (Ampl),A
	BIT 0,(IX+CHP.Flags)
	PUSH HL
	JP Z,CH_EXIT
	LD (CSP_+1),SP
	LD L,(IX+CHP.OrnPtr)
	LD H,(IX+CHP.OrnPtr+1)
	LD SP,HL
	POP DE
	LD H,A
	LD A,(IX+CHP.PsInOr)
	LD L,A
	ADD HL,SP
	INC A
		;PT2	PT3
OrnCP	INC A	;CP E	CP D
	JR C,CH_ORPS
OrnLD	DB 1	;LD A,D	LD A,E
CH_ORPS	LD (IX+CHP.PsInOr),A
	LD A,(IX+CHP.Note)
	ADD A,(HL)
	JP P,CH_NTP
	XOR A
CH_NTP	CP 96
	JR C,CH_NOK
	LD A,95
CH_NOK	ADD A,A
	EX AF,AF'
	LD L,(IX+CHP.SamPtr)
	LD H,(IX+CHP.SamPtr+1)
	LD SP,HL
	POP DE
	LD H,0
	LD A,(IX+CHP.PsInSm)
	LD B,A
	ADD A,A
SamClc2	ADD A,A ;or ADD A,B for PT2
	LD L,A
	ADD HL,SP
	LD SP,HL
	LD A,B
	INC A
		;PT2	PT3
SamCP	INC A	;CP E	CP D
	JR C,CH_SMPS
SamLD	DB 1	;LD A,D	LD A,E
CH_SMPS	LD (IX+CHP.PsInSm),A
	POP BC
	POP HL

;Convert PT2 sample to PT3
		;PT2		PT3
SamCnv	POP HL  ;BIT 2,C	JR e_
	POP HL	
	LD H,B
	JR NZ,$+8
	EX DE,HL
	AND A
	SBC HL,HL
	SBC HL,DE
	LD D,C
	RR C
	SBC A,A
	CPL
	AND #3E
	RR C
	RR B
	AND C
	LD C,A
	LD A,B
	RRA
	RRA
	RR D
	RRA
	AND #9F
	LD B,A

e_	LD E,(IX+CHP.TnAcc)
	LD D,(IX+CHP.TnAcc+1)
	ADD HL,DE
	BIT 6,B
	JR Z,CH_NOAC
	LD (IX+CHP.TnAcc),L
	LD (IX+CHP.TnAcc+1),H
CH_NOAC EX DE,HL
	EX AF,AF'
	ADD A,NT_
	LD L,A
	ADC A,NT_/256
	SUB L
	LD H,A
	LD SP,HL
	POP HL
	ADD HL,DE
	LD E,(IX+CHP.CrTnSl)
	LD D,(IX+CHP.CrTnSl+1)
	ADD HL,DE
CSP_	LD SP,#3131
	EX (SP),HL
	XOR A
	OR (IX+CHP.TSlCnt)
	JR Z,CH_AMP
	DEC (IX+CHP.TSlCnt)
	JR NZ,CH_AMP
	LD A,(IX+CHP.TnSlDl)
	LD (IX+CHP.TSlCnt),A
	LD L,(IX+CHP.TSlStp)
	LD H,(IX+CHP.TSlStp+1)
	LD A,H
	ADD HL,DE
	LD (IX+CHP.CrTnSl),L
	LD (IX+CHP.CrTnSl+1),H
	BIT 2,(IX+CHP.Flags)
	JR NZ,CH_AMP
	LD E,(IX+CHP.TnDelt)
	LD D,(IX+CHP.TnDelt+1)
	AND A
	JR Z,CH_STPP
	EX DE,HL
CH_STPP SBC HL,DE
	JP M,CH_AMP
	LD A,(IX+CHP.SlToNt)
	LD (IX+CHP.Note),A
	XOR A
	LD (IX+CHP.TSlCnt),A
	LD (IX+CHP.CrTnSl),A
	LD (IX+CHP.CrTnSl+1),A
CH_AMP	LD A,(IX+CHP.CrAmSl)
	BIT 7,C
	JR Z,CH_NOAM
	BIT 6,C
	JR Z,CH_AMIN
	CP 15
	JR Z,CH_NOAM
	INC A
	JR CH_SVAM
CH_AMIN	CP -15
	JR Z,CH_NOAM
	DEC A
CH_SVAM	LD (IX+CHP.CrAmSl),A
CH_NOAM	LD L,A
	LD A,B
	AND 15
	ADD A,L
	JP P,CH_APOS
	XOR A
CH_APOS	CP 16
	JR C,CH_VOL
	LD A,15
CH_VOL	OR (IX+CHP.Volume)
	ADD A,VT_
	LD L,A
	ADC A,VT_/256
	SUB L
	LD H,A
	LD A,(HL)
CH_ENV	BIT 0,C
	JR NZ,CH_NOEN
	OR (IX+CHP.Env_En)
CH_NOEN	LD (Ampl),A
	BIT 7,B
	LD A,C
	JR Z,NO_ENSL
	RLA
	RLA
	SRA A
	SRA A
	SRA A
	ADD A,(IX+CHP.CrEnSl) ;SEE COMMENT BELOW
	BIT 5,B
	JR Z,NO_ENAC
	LD (IX+CHP.CrEnSl),A
NO_ENAC	ADD A,(IY-100+VRS.AddToEn) ;BUG IN PT3 - NEED WORD HERE
	LD (IY-100+VRS.AddToEn),A
	JR CH_MIX
NO_ENSL RRA
	ADD A,(IX+CHP.CrNsSl)
	LD (IY-100+VRS.AddToNs),A
	BIT 5,B
	JR Z,CH_MIX
	LD (IX+CHP.CrNsSl),A
CH_MIX	LD A,B
	RRA
	AND #48
CH_EXIT	OR (IY-100+VRS.AYREGS+Mixer)
	RRCA
	LD (IY-100+VRS.AYREGS+Mixer),A
	POP HL
	XOR A
	OR (IX+CHP.COnOff)
	RET Z
	DEC (IX+CHP.COnOff)
	RET NZ
	XOR (IX+CHP.Flags)
	LD (IX+CHP.Flags),A
	RRA
	LD A,(IX+CHP.OnOffD)
	JR C,CH_ONDL
	LD A,(IX+CHP.OffOnD)
CH_ONDL	LD (IX+CHP.COnOff),A
	RET

PLAY_	XOR A
	LD (IY-100+VRS.AddToEn),A
	LD (IY-100+VRS.AYREGS+Mixer),A
	DEC A
	LD (IY-100+VRS.AYREGS+EnvTp),A
	DEC (IY-100+VRS.DelyCnt)
	JP NZ,PL2
	DEC (IY-100+VRS.ChanA+CHP.NtSkCn)
	JR NZ,PL1B
	LD C,(IY-100+VRS.AdInPtA)
	LD B,(IY-100+VRS.AdInPtA+1)
	LD A,(BC)
	AND A
	JR NZ,PL1A
	LD D,A
	LD (IY-100+VRS.Ns_Base),A
	LD L,(IY-100+VRS.CrPsPtr)
	LD H,(IY-100+VRS.CrPsPtr+1)
	INC HL
	LD A,(HL)
	INC A
	JR NZ,PLNLP

	IF LoopChecker
	CALL CHECKLP
	ENDIF

	LD L,(IY-100+VRS.LPosPtr)
	LD H,(IY-100+VRS.LPosPtr+1)
	LD A,(HL)
	INC A
PLNLP	CALL SETCPPT
	DEC A
	BIT 1,(IY-100+VRS.ModNum)
	JR Z,NoAlCo
TSSub	EQU $+1
	SUB #D6
	CPL
NoAlCo
		;PT2		PT3
PsCalc	DEC A	;ADD A,A	NOP
	DEC A	;ADD A,(HL)	NOP
	ADD A,A
	LD E,A
	RL D

	IF CurPosCounter
	LD A,L
	SUB (IY-100+VRS.PosSub)
	LD (IY-100+VRS.CurPos),A
	ENDIF

	LD L,(IY-100+VRS.PatsPtr)
	LD H,(IY-100+VRS.PatsPtr+1)
	ADD HL,DE
	LD E,(IY-100+VRS.MODADDR)
	LD D,(IY-100+VRS.MODADDR+1)
	LD (PSP_+1),SP
	LD SP,HL
	POP HL
	ADD HL,DE
	LD B,H
	LD C,L
	POP HL
	ADD HL,DE
	LD (IY-100+VRS.AdInPtB),L
	LD (IY-100+VRS.AdInPtB+1),H
	POP HL
	ADD HL,DE
	LD (IY-100+VRS.AdInPtC),L
	LD (IY-100+VRS.AdInPtC+1),H
PSP_	LD SP,#3131
PL1A	LD DE,VRS.ChanA+12-100
	CALL PTDECOD
	LD (IY-100+VRS.AdInPtA),C
	LD (IY-100+VRS.AdInPtA+1),B

PL1B	DEC (IY-100+VRS.ChanB+CHP.NtSkCn)
	JR NZ,PL1C
	LD DE,VRS.ChanB+12-100
	LD C,(IY-100+VRS.AdInPtB)
	LD B,(IY-100+VRS.AdInPtB+1)
	CALL PTDECOD
	LD (IY-100+VRS.AdInPtB),C
	LD (IY-100+VRS.AdInPtB+1),B

PL1C	DEC (IY-100+VRS.ChanC+CHP.NtSkCn)
	JR NZ,PL1D
	LD DE,VRS.ChanC+12-100
	LD C,(IY-100+VRS.AdInPtC)
	LD B,(IY-100+VRS.AdInPtC+1)
	CALL PTDECOD
	LD (IY-100+VRS.AdInPtC),C
	LD (IY-100+VRS.AdInPtC+1),B

PL1D	LD A,(IY-100+VRS.Delay)
	LD (IY-100+VRS.DelyCnt),A

PL2	LD DE,VRS.ChanA-100
	LD L,(IY-100+VRS.AYREGS+TonA)
	LD H,(IY-100+VRS.AYREGS+TonA+1)
	CALL CHREGS
	LD (IY-100+VRS.AYREGS+TonA),L
	LD (IY-100+VRS.AYREGS+TonA+1),H
Ampl	EQU $+1
	LD A,#3E
	LD (IY-100+VRS.AYREGS+AmplA),A
	LD DE,VRS.ChanB-100
	LD L,(IY-100+VRS.AYREGS+TonB)
	LD H,(IY-100+VRS.AYREGS+TonB+1)
	CALL CHREGS
	LD (IY-100+VRS.AYREGS+TonB),L
	LD (IY-100+VRS.AYREGS+TonB+1),H
	LD A,(Ampl)
	LD (IY-100+VRS.AYREGS+AmplB),A
	LD DE,VRS.ChanC-100
	LD L,(IY-100+VRS.AYREGS+TonC)
	LD H,(IY-100+VRS.AYREGS+TonC+1)
	CALL CHREGS
	LD (IY-100+VRS.AYREGS+TonC),L
	LD (IY-100+VRS.AYREGS+TonC+1),H
	LD A,(Ampl)
	LD (IY-100+VRS.AYREGS+AmplC),A

	LD A,(IY-100+VRS.Ns_Base)
	ADD (IY-100+VRS.AddToNs)
	LD (IY-100+VRS.AYREGS+Noise),A

	LD A,(IY-100+VRS.AddToEn)
	LD E,A
	ADD A,A
	SBC A,A
	LD D,A
	LD L,(IY-100+VRS.EnvBase)
	LD H,(IY-100+VRS.EnvBase+1)
	ADD HL,DE
	LD E,(IY-100+VRS.CurESld)
	LD D,(IY-100+VRS.CurESld+1)
	ADD HL,DE
	LD (IY-100+VRS.AYREGS+Env),L
	LD (IY-100+VRS.AYREGS+Env+1),H

	XOR A
	OR (IY-100+VRS.CurEDel)
	RET Z
	DEC (IY-100+VRS.CurEDel)
	RET NZ
	LD A,(IY-100+VRS.Env_Del)
	LD (IY-100+VRS.CurEDel),A
	LD L,(IY-100+VRS.ESldAdd)
	LD H,(IY-100+VRS.ESldAdd+1)
	ADD HL,DE
	JP SETESLD

PLAY    LD IY,VARS1+100
	CALL PLAY_
	LD A,(is_ts)
	AND A
	JR Z,PL_nts
	LD IY,VARS2+100
	CALL PLAY_
PL_nts
	IF Basic
	LD IY,#5C3A
	ENDIF

ROUT	LD BC,#FFFD
	LD A,(is_ts)
	AND A
	JR Z,r_nts ;keep old standard
	OUT (C),B
r_nts	EX AF,AF'

	IF ACBBAC
	LD IX,VARS1+VRS.AYREGS
	ELSE
	LD HL,VARS1+VRS.AYREGS
	ENDIF

	CALL ROUT_
	EX AF,AF'
	RET Z
	LD B,D
	CPL
	OUT (C),A

	IF ACBBAC
	LD IX,VARS2+VRS.AYREGS
	ELSE
	LD HL,VARS2+VRS.AYREGS
	ENDIF

ROUT_
	IF ACBBAC
	LD A,(SETUP)
	AND 12
	JR Z,ABC
	ADD A,CHTABLE
	LD E,A
	ADC A,CHTABLE/256
	SUB E
	LD D,A
	LD B,0
	PUSH IX
	POP HL
	LD A,(DE)
	INC DE
	LD C,A
	ADD HL,BC
	LD A,(IX+TonB)
	LD C,(HL)
	LD (IX+TonB),C
	LD (HL),A
	INC HL
	LD A,(IX+TonB+1)
	LD C,(HL)
	LD (IX+TonB+1),C
	LD (HL),A
	LD A,(DE)
	INC DE
	LD C,A
	ADD HL,BC
	LD A,(IX+AmplB)
	LD C,(HL)
	LD (IX+AmplB),C
	LD (HL),A
	LD A,(DE)
	INC DE
	LD (RxCA1),A
	XOR 8
	LD (RxCA2),A
	LD A,(DE)
	AND (IX+Mixer)
	LD E,A
	LD A,(IX+Mixer)
RxCA1	DB #E6
	AND %010010
	OR E
	LD E,A
	LD A,(IX+Mixer)
	AND %010010
RxCA2	OR E
	OR E
	LD (IX+Mixer),A
ABC
	ENDIF

	XOR A
	LD DE,#FFBF

	IF ACBBAC
	LD BC,#FFFD
	PUSH IX
	POP HL
	ENDIF

LOUT	OUT (C),A
	LD B,E
	OUTI 
	LD B,D
	INC A
	CP 13
	JR NZ,LOUT
	OUT (C),A
	LD A,(HL)
	AND A
	RET M
	LD B,E
	OUT (C),A
	RET

	IF ACBBAC
CHTABLE	EQU $-4
	DB 4,5,15,%001001,0,7,7,%100100
	ENDIF

NT_DATA	DB (T_NEW_0-T1_)*2
	DB TCNEW_0-T_
	DB (T_OLD_0-T1_)*2+1
	DB TCOLD_0-T_
	DB (T_NEW_1-T1_)*2+1
	DB TCNEW_1-T_
	DB (T_OLD_1-T1_)*2+1
	DB TCOLD_1-T_
	DB (T_NEW_2-T1_)*2
	DB TCNEW_2-T_
	DB (T_OLD_2-T1_)*2
	DB TCOLD_2-T_
	DB (T_NEW_3-T1_)*2
	DB TCNEW_3-T_
	DB (T_OLD_3-T1_)*2
	DB TCOLD_3-T_

T_

TCOLD_0	DB #00+1,#04+1,#08+1,#0A+1,#0C+1,#0E+1,#12+1,#14+1
	DB #18+1,#24+1,#3C+1,0
TCOLD_1	DB #5C+1,0
TCOLD_2	DB #30+1,#36+1,#4C+1,#52+1,#5E+1,#70+1,#82,#8C,#9C
	DB #9E,#A0,#A6,#A8,#AA,#AC,#AE,#AE,0
TCNEW_3	DB #56+1
TCOLD_3	DB #1E+1,#22+1,#24+1,#28+1,#2C+1,#2E+1,#32+1,#BE+1,0
TCNEW_0	DB #1C+1,#20+1,#22+1,#26+1,#2A+1,#2C+1,#30+1,#54+1
	DB #BC+1,#BE+1,0
TCNEW_1 EQU TCOLD_1
TCNEW_2	DB #1A+1,#20+1,#24+1,#28+1,#2A+1,#3A+1,#4C+1,#5E+1
	DB #BA+1,#BC+1,#BE+1,0

PT3EMPTYORN EQU $-1
	DB 1,0

;first 12 values of tone tables (packed)

T_PACK	DB #06EC*2/256,#06EC*2
	DB #0755-#06EC
	DB #07C5-#0755
	DB #083B-#07C5
	DB #08B8-#083B
	DB #093D-#08B8
	DB #09CA-#093D
	DB #0A5F-#09CA
	DB #0AFC-#0A5F
	DB #0BA4-#0AFC
	DB #0C55-#0BA4
	DB #0D10-#0C55
	DB #066D*2/256,#066D*2
	DB #06CF-#066D
	DB #0737-#06CF
	DB #07A4-#0737
	DB #0819-#07A4
	DB #0894-#0819
	DB #0917-#0894
	DB #09A1-#0917
	DB #0A33-#09A1
	DB #0ACF-#0A33
	DB #0B73-#0ACF
	DB #0C22-#0B73
	DB #0CDA-#0C22
	DB #0704*2/256,#0704*2
	DB #076E-#0704
	DB #07E0-#076E
	DB #0858-#07E0
	DB #08D6-#0858
	DB #095C-#08D6
	DB #09EC-#095C
	DB #0A82-#09EC
	DB #0B22-#0A82
	DB #0BCC-#0B22
	DB #0C80-#0BCC
	DB #0D3E-#0C80
	DB #07E0*2/256,#07E0*2
	DB #0858-#07E0
	DB #08E0-#0858
	DB #0960-#08E0
	DB #09F0-#0960
	DB #0A88-#09F0
	DB #0B28-#0A88
	DB #0BD8-#0B28
	DB #0C80-#0BD8
	DB #0D60-#0C80
	DB #0E10-#0D60
	DB #0EF8-#0E10

;vars from here can be stripped
;you can move VARS to any other address

VARS

is_ts	DB 0

;ChannelsVars
	STRUCT	CHP
;reset group
PsInOr	DB 0
PsInSm	DB 0
CrAmSl	DB 0
CrNsSl	DB 0
CrEnSl	DB 0
TSlCnt	DB 0
CrTnSl	DW 0
TnAcc	DW 0
COnOff	DB 0
;reset group

OnOffD	DB 0

;IX for PTDECOD here (+12)
OffOnD	DB 0
OrnPtr	DW 0
SamPtr	DW 0
NNtSkp	DB 0
Note	DB 0
SlToNt	DB 0
Env_En	DB 0
Flags	DB 0
 ;Enabled - 0, SimpleGliss - 2
TnSlDl	DB 0
TSlStp	DW 0
TnDelt	DW 0
NtSkCn	DB 0
Volume	DB 0
	ENDS

	STRUCT	VRS

;IF not works in STRUCT in SjASM :(
;	IF CurPosCounter
CurPos	DB 0
PosSub	DB 0
;	ENDIF

ModNum	DB 0 ;bit0: ChipNum
	     ;bit1: 1-reversed patterns order (AlCo TS)

ChanA	DS CHP
ChanB	DS CHP
ChanC	DS CHP

;GlobalVars
MODADDR	DW 0
OrnPtrs	DW 0
SamPtrs	DW 0
PatsPtr	DW 0
AdInPtA	DW 0
AdInPtB	DW 0
AdInPtC	DW 0
CrPsPtr	DW 0
LPosPtr	DW 0
Delay	DB 0
DelyCnt	DB 0
ESldAdd	DW 0
CurESld	DW 0
Env_Del	DB 0
CurEDel	DB 0
Ns_Base	DB 0
AddToNs	DB 0
AddToEn	DB 0
EnvBase	DW 0
AYREGS	DS 14
	ENDS

VARS1	DS VRS
VARS2	DS VRS

VT_	EQU $-16
	DS 256-16 ;CreatedVolumeTableAddress

T1_	EQU VT_+16 ;Tone tables data depacked here

T_OLD_1	EQU T1_
T_OLD_2	EQU T_OLD_1+24
T_OLD_3	EQU T_OLD_2+24
T_OLD_0	EQU T_OLD_3+2
T_NEW_0	EQU T_OLD_0
T_NEW_1	EQU T_OLD_1
T_NEW_2	EQU T_NEW_0+24
T_NEW_3	EQU T_OLD_3

PT2EMPTYORN EQU VT_+31 ;1,0,0 sequence

NT_	DS 192 ;CreatedNoteTableAddress

VAR0END	EQU VT_+16 ;INIT zeroes from VARS to VAR0END-1

VARSEND EQU $

MDLADDR EQU $

;Release 0 steps:
;04/21/2007
;Works start (PTxPlay adaptation); first beta.
;04/22/2007
;Job finished; beta-testing.
;04/23/2007
;PT v3.7 TS mode corrected (after AlCo remarks).
;04/29/2007
;Added 1.XX and 2.XX special commands interpretation for PT3
;modules of v3.7+.

;Size (minimal build for ZX Spectrum):
;Code block #908 bytes
;Variables #2BF bytes (can be stripped)
;Total size #908+#2BF=#BC7 (3015) bytes
