
        output  OS6128.ROM

; Disassembly of the CPC6128 operating system ROM

;; START OF LOW KERNEL JUMPBLOCK AND ROM START
;;
;; firmware register assignments:
;; B' = 0x07f - Gate Array I/O port address (upper 8 bits)
;; C': upper/lower rom enabled state and current mode. Bit 7 = 1, Bit 6 = 0.

;----------------------------------------------------------------
; RST 0 - LOW: RESET ENTRY
L0000:  ld      bc,$7f89     ; select mode 1, disable upper rom, enable lower rom        
L0003:  out     (c),c        ; select mode and rom configuration
L0005:  jp      L0591
;-------------------------------------------------------
L0008:  jp      $b98a            ; RST 1 - LOW: LOW JUMP
;-------------------------------------------------------
L000b:  jp      $b984            ; LOW: KL LOW PCHL
;-------------------------------------------------------
L000e:  push    bc               ; LOW: PCBC INSTRUCTION
L000f:  ret     
;-------------------------------------------------------
L0010:  jp      $ba1d            ; RST 2 - LOW: SIDE CALL
;-------------------------------------------------------
L0013:  jp      $ba17            ; LOW: KL SIDE PCHL
;-------------------------------------------------------
L0016:  push    de               ; LOW: PCDE INSTRUCTION
L0017:  ret     
;-------------------------------------------------------
L0018:  jp      $b9c7            ; RST 3 - LOW: FAR CALL
;-------------------------------------------------------
L001b:  jp      $b9b9            ; LOW: KL FAR PCHL
;-------------------------------------------------------
L001e:  jp      (hl)             ; LOW: PCHL INSTRUCTION
;-------------------------------------------------------
L001f:  nop     
;-------------------------------------------------------
L0020:  jp      $bac6            ; RST 4 - LOW: RAM LAM
;-------------------------------------------------------
L0023:  jp      $b9c1            ; LOW: KL FAR ICALL
;-------------------------------------------------------
L0026:  nop     
L0027:  nop     
;-------------------------------------------------------
L0028:  jp      $ba35            ; RST 5 - LOW: FIRM JUMP
L002b:  nop     
L002c:  out     (c),c
L002e:  exx     
L002f:  ei      
;-------------------------------------------------------
L0030:  di                       ; RST 6 - LOW: USER RESTART
L0031:  exx     
L0032:  ld      hl,$002b
L0035:  ld      (hl),c
L0036:  jr      L0040            
;-------------------------------------------------------
L0038:  jp      $b941            ; RST 7 - LOW: INTERRUPT ENTRY
;-------------------------------------------------------
;; Th default handler in the ROM. The user can patch the RAM version of this
;; ha
L003b:  ret                      ; LOW: EXT INTERRUPT

;-------------------------------------------------------

L003c:  nop     
L003d:  nop     
L003e:  nop     
L003f:  nop     
;; ENKERNEL JUMPBLOCK
;;-------------------------------------------------------------------------------

L0040:  set     2,c
L0042:  jr      L002c            ; (-$18)

;;-------------------------------------------------------------------------------
;; SeERNEL jumpblock

;; Coo RAM
L0044:  ld      hl,$0040         ; copy first $40 bytes of this rom to $0000
                               ; in RAM, and therefore initialise low kernel jumpblock
L0047:  dec     l
L0048:  ld      a,(hl)           ; get byte from rom
L0049:  ld      (hl),a           ; write byte to ram
L004a:  jr      nz,L0047         ; 

;; inUSER RESTART in LOW KERNEL jumpblcok
L004c:  ld      a,$c7
L004e:  ld      ($0030),a

;; SeKERNEL jumpblock

L0051:  ld      hl,$03a6         ; copy high kernel jumpblock
L0054:  ld      de,$b900
L0057:  ld      bc,$01e4
L005a:  ldir    

;;=================================================================
;; KLF

L005c:  di      
L005d:  ld      a,($b8d9)
L0060:  ld      de,($b8d7)
L0064:  ld      b,$cd
L0066:  ld      hl,$b82d
L0069:  ld      (hl),$00
L006b:  inc     hl
L006c:  djnz    $0069            ; (-$05)
L006e:  ld      b,a
L006f:  ld      c,$ff
L0071:  xor     c
L0072:  ret     nz
L0073:  ld      b,a
L0074:  ld      e,a
L0075:  ld      d,a
L0076:  ret     

;;=================================================================
;; thled at the very end just before BASIC is started 
;;
;; HLs to start
;; C ect 
;;
;; ifen BASIC is started.

L0077:  ld      a,h
L0078:  or      l
L0079:  ld      a,c
L007a:  jr      nz,L0080          ; HL=0?

;; ye
L007c:  ld      a,l              ; A = 0 (BASIC)
L007d:  ld      hl,$c006         ; execution address for BASIC

;; A ect 
;; HLs to start
L0080:  ld      ($b8d6),a
;; inthree byte far address
L0083:  ld      ($b8d9),a        ; rom select byte
L0086:  ld      ($b8d7),hl       ; address

L0089:  ld      hl,$abff
L008c:  ld      de,$0040
L008f:  ld      bc,$b0ff
L0092:  ld      sp,$c000
L0095:  rst     $18              ; RST 3 - LOW: FAR CALL

        defw $b8d7
L0098:  rst     $00              ; RST 0 - LOW: RESET ENTRY
 
;;=== =============================================================
;; KL SE
 
L0099:  di      
L009a:  ld      de,($b8b6)
L009e:  ld      hl,($b8b4)
L00a1:  ei      
L00a2:  ret     
 
;;=== =============================================================
;; KL 
 
L00a3:  di      
L00a4:  xor     a
L00a5:  ld      ($b8b8),a
L00a8:  ld      ($b8b6),de
L00ac:  ld      ($b8b4),hl
L00af:  ei      
L00b0:  ret     
 
;;=== =============================================================
 
;; up 
L00b1:  ld      hl,$b8b4
L00b4:  inc     (hl)
L00b5:  inc     hl
L00b6:  jr      z,L00b4          ; (-$04)
 
;; te tate
L00b8:  ld      b,$f5
L00ba:  in      a,(c)
L00bc:  rra     
L00bd:  jr      nc,L00c7         
 
;; VS 
L00bf:  ld      hl,($b8b9)       ;; FRAME FLY events
L00c2:  ld      a,h
L00c3:  or      a
L00c4:  call    nz,L0153
 
L00c7:  ld      hl,($b8bb)       ;; FAST TICKER events
L00ca:  ld      a,h
L00cb:  or      a
L00cc:  call    nz,L0153
 
L00cf:  call    L20d7            ;; process sound
 
L00d2:  ld      hl,$b8bf         ;; keyboard scan interrupt counter
L00d5:  dec     (hl)
L00d6:  ret     nz
 
L00d7:  ld      (hl),$06         ;; reset keyboard scan interrupt counter
 
L00d9:  call    $bdf4            ; IND: KM SCAN KEYS
 
L00dc:  ld      hl,($b8bd)       ; ticker list
L00df:  ld      a,h
L00e0:  or      a
L00e1:  ret     z
 
L00e2:  ld      hl,$b831         ; indicate there are some ticker events to process?
L00e5:  set     0,(hl)
L00e7:  ret     
 
;;--- -----------------------------------------------------------------
;; th e for queuing up normal Asynchronous events to be processed after all others
 
;; no  
L00e8:  dec     hl
L00e9:  ld      (hl),$00
L00eb:  dec     hl
;; ha n setup?
L00ec:  ld      a,($b82e)
L00ef:  or      a
L00f0:  jr      nz,L00fe         ; (+$0c)
;; ad  of list
L00f2:  ld      ($b82d),hl
L00f5:  ld      ($b82f),hl
;; si l event list setup
L00f8:  ld      hl,$b831
L00fb:  set     6,(hl)
L00fd:  ret     
 
;; ad event to 
L00fe:  ld      de,($b82f)
L0102:  ld      ($b82f),hl
L0105:  ex      de,hl
L0106:  ld      (hl),e
L0107:  inc     hl
L0108:  ld      (hl),d
L0109:  ret     
 
;;--- --------------------------------------
;; sy ?
L010a:  ld      ($b832),sp
L010e:  ld      sp,$b8b4
L0111:  push    hl
L0112:  push    de
L0113:  push    bc
;; no  has been setup?
L0114:  ld      hl,$b831
L0117:  bit     6,(hl)
L0119:  jr      z,L0139          ; (+$1e)
 
L011b:  set     7,(hl)
L011d:  ld      hl,($b82d)
L0120:  ld      a,h
L0121:  or      a
L0122:  jr      z,L0132          ; (+$0e)
L0124:  ld      e,(hl)
L0125:  inc     hl
L0126:  ld      d,(hl)
L0127:  ld      ($b82d),de
L012b:  inc     hl
L012c:  call    L0209            ; execute event function
L012f:  di      
L0130:  jr      L011d            ; (-$15)
 
;;--- --------------------------------------
L0132:  ld      hl,$b831
L0135:  bit     0,(hl)
L0137:  jr      z,L0149          ; (+$10)
L0139:  ld      (hl),$00
L013b:  scf     
L013c:  ex      af,af'
L013d:  call    L0189            ;; execute ticker
L0140:  or      a
L0141:  ex      af,af'
L0142:  ld      hl,$b831
L0145:  ld      a,(hl)
L0146:  or      a
L0147:  jr      nz,L011b         ; (-$2e)
L0149:  ld      (hl),$00
L014b:  pop     bc
L014c:  pop     de
L014d:  pop     hl
L014e:  ld      sp,($b832)
L0152:  ret     
 
;;--- --------------------------------------------------------
;; lo ents
;; 
;; HL  of event list
L0153:  ld      e,(hl)           
L0154:  inc     hl
L0155:  ld      a,(hl)           
L0156:  inc     hl
L0157:  or      a
L0158:  jp      z,L01e2          ; KL EVENT
 
L015b:  ld      d,a
L015c:  push    de
L015d:  call    L01e2            ; KL EVENT
L0160:  pop     hl
L0161:  jr      L0153            ; (-$10)
 
;;=== =============================================================
;; KL  FLY
 
L0163:  push    hl
L0164:  inc     hl
L0165:  inc     hl
L0166:  call    L01d2            ; KL INIT EVENT
L0169:  pop     hl
 
;;=== =============================================================
;; KL  FLY
 
L016a:  ld      de,$b8b9
L016d:  jp      L0379 ;; add event to list
 
;;=== =============================================================
;; KL  FLY
 
L0170:  ld      de,$b8b9
L0173:  jp      L0388 ; remove event from list
 
;;=== =============================================================
;; KL TICKER
 
L0176:  push    hl
L0177:  inc     hl
L0178:  inc     hl
L0179:  call    L01d2            ; KL INIT EVENT
L017c:  pop     hl
 
;;=== =============================================================
;; KL TICKER
 
;; HL  of event block
L017d:  ld      de,$b8bb
L0180:  jp      L0379 ;; add event to list
 
;;=== =============================================================
;; KL TICKER
 
;; HL  of event block
L0183:  ld      de,$b8bb
L0186:  jp      L0388 ; remove event from list
 
;;=== =============================================================
 
L0189:  ld      hl,($b8bd)           ; ticker list
L018c:  ld      a,h
L018d:  or      a
L018e:  ret     z
 
L018f:  ld      e,(hl)
L0190:  inc     hl
L0191:  ld      d,(hl)
L0192:  inc     hl
L0193:  ld      c,(hl)
L0194:  inc     hl
L0195:  ld      b,(hl)
L0196:  ld      a,b
L0197:  or      c
L0198:  jr      z,L01b0          ; (+$16)
L019a:  dec     bc
L019b:  ld      a,b
L019c:  or      c
L019d:  jr      nz,L01ad         ; (+$0e)
L019f:  push    de
L01a0:  inc     hl
L01a1:  inc     hl
L01a2:  push    hl
L01a3:  inc     hl
L01a4:  call    L01e2            ; KL EVENT
L01a7:  pop     hl
L01a8:  ld      b,(hl)
L01a9:  dec     hl
L01aa:  ld      c,(hl)
L01ab:  dec     hl
L01ac:  pop     de
L01ad:  ld      (hl),b
L01ae:  dec     hl
L01af:  ld      (hl),c
L01b0:  ex      de,hl
L01b1:  jr      L018c            ; (-$27)
 
;;=== =============================================================
;; KL R
;; HL  lock
;; DE  value for counter
;; BC ount
 
L01b3:  push    hl
L01b4:  inc     hl
L01b5:  inc     hl
L01b6:  di      
L01b7:  ld      (hl),e           ;; initial counter
L01b8:  inc     hl
L01b9:  ld      (hl),d
L01ba:  inc     hl
L01bb:  ld      (hl),c           ;; reset count
L01bc:  inc     hl
L01bd:  ld      (hl),b
L01be:  pop     hl
L01bf:  ld      de,$b8bd         ;; ticker list
L01c2:  jp      L0379 ;; add event to list
 
;;=== =============================================================
;; KL R
 
L01c5:  ld      de,$b8bd
L01c8:  call    L0388 ; remove event from list
L01cb:  ret     nc
 
L01cc:  ex      de,hl
L01cd:  inc     hl
L01ce:  ld      e,(hl)
L01cf:  inc     hl
L01d0:  ld      d,(hl)
L01d1:  ret     
 
;;=== =============================================================
;; KL T
 
L01d2:  di      
L01d3:  inc     hl
L01d4:  inc     hl
L01d5:  ld      (hl),$00     ;; tick count
L01d7:  inc     hl
L01d8:  ld      (hl),b       ;; class
L01d9:  inc     hl
L01da:  ld      (hl),e       ;; routine
L01db:  inc     hl
L01dc:  ld      (hl),d
L01dd:  inc     hl
L01de:  ld      (hl),c       ;; rom
L01df:  inc     hl
L01e0:  ei      
L01e1:  ret     
 
;;=== =============================================================
;; KL 
;; 
;; pe t
;; DE  of next in chain
;; HL  of current event
 
L01e2:  inc     hl
L01e3:  inc     hl
L01e4:  di      
L01e5:  ld      a,(hl)           ;; count
L01e6:  inc     (hl)
L01e7:  jp      m,L0201          ;; update count 
 
L01ea:  or      a
L01eb:  jr      nz,L0202         ; (+$15)
 
L01ed:  inc     hl
L01ee:  ld      a,(hl)           ; class
L01ef:  dec     hl
L01f0:  or      a
L01f1:  jp      p,L022e          ; -ve (bit = 1) = Asynchronous, +ve (bit = 0) = synchronous
 
;; As 
L01f4:  ex      af,af'
L01f5:  jr      nc,L0208         
L01f7:  ex      af,af'
 
L01f8:  add     a,a              ; express = -ve (bit = 1), normal = +ve (bit = 0)
L01f9:  jp      p,L00e8          ; add to normal list
 
;; As  Express
L01fc:  dec     (hl)             ; indicate it needs processing
L01fd:  inc     hl
L01fe:  inc     hl
                               ; HL = routine address
L01ff:  jr      L0222            ; execute event
 
;; up  
L0201:  dec     (hl)
 
;; do ing
 
L0202:  ex      af,af'
L0203:  jr      c,L0206          ; (+$01)
L0205:  ei      
L0206:  ex      af,af'
L0207:  ret     
 
L0208:  ex      af,af'
 
;;--- -------------
;; ex t func
L0209:  ei                       ; enable ints
L020a:  ld      a,(hl)
L020b:  dec     a
L020c:  ret     m
 
L020d:  push    hl
L020e:  call    L021b                ; part of KL DO SYNC
L0211:  pop     hl
L0212:  dec     (hl)
L0213:  ret     z
 
L0214:  jp      p,L020d
L0217:  inc     (hl)
L0218:  ret     
 
;;=== =============================================================
;; KL 
 
;; HL lock
;; DE  of event
L0219:  inc     hl
L021a:  inc     hl
L021b:  inc     hl
 
;; ne address?
L021c:  ld      a,(hl)
L021d:  inc     hl
L021e:  rra     
L021f:  jp      nc,$b9c1         ;    LOW: KL FAR ICALL
 
;; ev ear address
;; ex 
;; no wer rom is enabled at this point so the function can't sit under the lower rom
L0222:  ld      e,(hl)
L0223:  inc     hl
L0224:  ld      d,(hl)
L0225:  ex      de,hl
L0226:  jp      (hl)
 
;;=== =============================================================
;; KL T
 
L0227:  ld      hl,$0000
L022a:  ld      ($b8c1),hl
L022d:  ret     
 
;;--- --------------------------------------------------------------
 
;; Sy Event
L022e:  push    hl
L022f:  ld      b,a
L0230:  ld      de,$b8c3
L0233:  ex      de,hl
 
L0234:  dec     hl
L0235:  dec     hl
L0236:  ld      d,(hl)
L0237:  dec     hl
L0238:  ld      e,(hl)
L0239:  ld      a,d
L023a:  or      a
L023b:  jr      z,L0244          ; (+$07)
 
L023d:  inc     de               ; count
L023e:  inc     de               ; class
L023f:  inc     de
L0240:  ld      a,(de)
L0241:  cp      b
L0242:  jr      nc,L0233         ; (-$11)
 
L0244:  pop     de
L0245:  dec     de
L0246:  inc     hl
L0247:  ld      a,(hl)
L0248:  ld      (de),a
L0249:  dec     de
L024a:  ld      (hl),d
L024b:  dec     hl
L024c:  ld      a,(hl)
L024d:  ld      (de),a
L024e:  ld      (hl),e
L024f:  ex      af,af'
L0250:  jr      c,L0253          ; (+$01)
 
L0252:  ei      
L0253:  ex      af,af'
L0254:  ret     
 
;;=== =============================================================
;; KL 
 
L0255:  di      
L0256:  ld      hl,($b8c0)           ; synchronous event list
L0259:  ld      a,h
L025a:  or      a
L025b:  jr      z,L0274          ; (+$17)
L025d:  push    hl
L025e:  ld      e,(hl)
L025f:  inc     hl
L0260:  ld      d,(hl)
L0261:  inc     hl
L0262:  inc     hl
L0263:  ld      a,($b8c2)
L0266:  cp      (hl)
L0267:  jr      nc,L0273         ; (+$0a)
L0269:  push    af
L026a:  ld      a,(hl)
L026b:  ld      ($b8c2),a
L026e:  ld      ($b8c0),de           ; synchronous event list
L0272:  pop     af
L0273:  pop     hl
L0274:  ei      
L0275:  ret     
 
;;=== =============================================================
;; KL 
 
L0276:  ld      ($b8c2),a
L0279:  inc     hl
L027a:  inc     hl
L027b:  dec     (hl)
L027c:  ret     z
 
L027d:  di      
L027e:  jp      p,L022e              ;; Synchronous event
L0281:  inc     (hl)
L0282:  ei      
L0283:  ret     
 
;;=== =============================================================
;; KL RONOUS
 
L0284:  call    L028d            ; KL DISARM EVENT
L0287:  ld      de,$b8c0         ; synchronouse event list
L028a:  jp      L0388 ; remove event from list
 
;;=== =============================================================
;; KL ENT
 
L028d:  inc     hl
L028e:  inc     hl
L028f:  ld      (hl),$c0
L0291:  dec     hl
L0292:  dec     hl
L0293:  ret     
 
;;=== =============================================================
;; KL ABLE
 
L0294:  ld      hl,$b8c2
L0297:  set     5,(hl)
L0299:  ret     
 
;;=== =============================================================
;; KL BLE
 
L029a:  ld      hl,$b8c2
L029d:  res     5,(hl)
L029f:  ret     
 
;;=== =============================================================
;; KL 
;; 
;; BC the address of the RSX's command table
;; HL the address of four bytes exclusively for use by the firmware 
;;  
;; NO recent command is added to the start of the list. The next oldest
;; is so on until we get to the command that was registered first and the 
;; en ist.
;;  
;; HL in the range $0000-$3fff because the OS rom will be active in this range. 
;; Se ge is $4000-$c000. ($c000-$ffff is normally where upper ROM is located, so it
;; is  locate it here if you want to access the command from BASIC because BASIC
;; wi ve in this range)
L02a0:  push    hl
L02a1:  ld      de,($b8d3)   ;; get head of the list
L02a5:  ld      ($b8d3),hl   ;; set new head of the list
L02a8:  ld      (hl),e       ;; previous | command registered with KL LOG EXT or 0 if end of list
L02a9:  inc     hl
L02aa:  ld      (hl),d
L02ab:  inc     hl
L02ac:  ld      (hl),c       ;; address of RSX's command table
L02ad:  inc     hl
L02ae:  ld      (hl),b
L02af:  pop     hl
L02b0:  ret     
 
;;=== =============================================================
;; KL AND
;; HL  of command name to be found.
 
;; NO 
;; -  must have bit 7 set to indicate the end of the string.
;; -  haracters is compared. Name can be any length but first 16 characters must be unique.
 
L02b1:  ld      de,$b8c3 ;; destination
L02b4:  ld      bc,$0010 ;; length
L02b7:  call    $baa1            ;; HI: KL LDIR (disable upper and lower roms and perform LDIR)
 
;; en character has bit 7 set (indicates end of string, where length of name is longer
;; th acters). If name is less than 16 characters the last char will have bit 7 set anyway.
L02ba:  ex      de,hl
L02bb:  dec     hl
L02bc:  set     7,(hl)
 
L02be:  ld      hl,($b8d3)   ; points to commands registered with KL LOG EXT
L02c1:  ld      a,l          ; preload lower byte of address into A for comparison
L02c2:  jr      L02d4           
 
;; se ore | commands registered with KL LOG EXT
L02c4:  push    hl
L02c5:  inc     hl         ; skip pointer to next registered RSX
L02c6:  inc     hl
L02c7:  ld      c,(hl)     ; fetch address of RSX table
L02c8:  inc     hl
L02c9:  ld      b,(hl)
L02ca:  call    L02f1      ; search for command
L02cd:  pop     de
L02ce:  ret     c
 
L02cf:  ex      de,hl
L02d0:  ld      a,(hl)     ; get address of next registered RSX
L02d1:  inc     hl
L02d2:  ld      h,(hl)
L02d3:  ld      l,a
 
L02d4:  or      h              ; if HL is zero, then this is the end of the list.
L02d5:  jr      nz,L02c4       ; loop if we didn't get to the end of the list
 
 
L02d7:  ld      c,$ff
L02d9:  inc     c
;; C  ct address of ROM to probe
L02da:  call    $ba7e            ;; HI: KL PROBE ROM
;; A  ass.
;; 0  nd
;; 1  nd
;; 2  n foreground ROM
L02dd:  push    af
L02de:  and     $03
L02e0:  ld      b,a
L02e1:  call    z,L02f1    ; search for command
 
L02e4:  call    c,L061c          ; MC START PROGRAM
L02e7:  pop     af
L02e8:  add     a,a
L02e9:  jr      nc,L02d9         ; (-$12)
L02eb:  ld      a,c
L02ec:  cp      $10          ; maximum rom selection scanned by firmware
L02ee:  jr      c,L02d9          ; (-$17)
L02f0:  ret     
 
;;--- ------------------------------------------------------------------------------------------------
;; pe ch of RSX in command-table.
;; EI n RAM or RSX in ROM.
 
;; HL  of command-table in ROM
L02f1:  ld      hl,$c004
 
;;B=0 n ROM, B!=0 for RSX in RAM
;; Th ans that ROM class must be foreground.
L02f4:  ld      a,b
L02f5:  or      a
L02f6:  jr      z,L02fc          
 
;; HL  of RSX table
L02f8:  ld      h,b
L02f9:  ld      l,c
;; "R  for RAM 
L02fa:  ld      c,$ff
 
;; C  ct address
L02fc:  call    $ba79            ;; HI: KL ROM SELECT
;; C  he ROM select address of the previously selected ROM.
;; B  he previous ROM state
;; pr vious rom selection and rom state
L02ff:  push    bc
 
;; ge of strings from table.
L0300:  ld      e,(hl)
L0301:  inc     hl
L0302:  ld      d,(hl)
L0303:  inc     hl
;; DE ck for RSX commands
L0304:  ex      de,hl
L0305:  jr      L031e            ; (+$17)
 
;; B8 ommand to look for stored in RAM
L0307:  ld      bc,$b8c3
L030a:  ld      a,(bc)
L030b:  cp      (hl)
L030c:  jr      nz,L0316         ; (+$08)
L030e:  inc     hl
L030f:  inc     bc
L0310:  add     a,a
L0311:  jr      nc,L030a         ; (-$09)
;; if  here, then we found the name
L0313:  ex      de,hl
L0314:  jr      L0322            ; (+$0c)
 
;; ch match in name
;; lo  of string, it has bit 7 set
L0316:  ld      a,(hl)
L0317:  inc     hl
;; tr  7 into carry flag
L0318:  add     a,a
L0319:  jr      nc,L0316         ; (-$05)
 
;; up lock pointer
L031b:  inc     de
L031c:  inc     de
L031d:  inc     de
 
;; 0  end of list.
L031e:  ld      a,(hl)
L031f:  or      a
L0320:  jr      nz,L0307         ; (-$1b)
 
;; we e end of the RSX command-table and we didn't find the command
 
L0322:  pop     bc
;; re ious rom selection
L0323:  jp      $ba87            ;; HI: KL ROM DESELECT
 
;;=== =============================================================
;; KL 
 
L0326:  ld      c,$0f      ;; maximum number of roms that firmware supports -1
L0328:  call    L0330            ; KL INIT BACK
L032b:  dec     c
L032c:  jp      p,L0328
L032f:  ret     
 
;;=== =============================================================
;; KL 
 
L0330:  ld      a,($b8d9)
L0333:  cp      c
L0334:  ret     z
 
L0335:  ld      a,c
L0336:  cp      $10        ;; maximum rom selection supported by firmware
L0338:  ret     nc
 
L0339:  call    $ba79        ;; HI: KL ROM SELECT
L033c:  ld      a,($c000)
L033f:  and     $03
L0341:  dec     a
L0342:  jr      nz,L0366         ; (+$22)
L0344:  push    bc
L0345:  scf     
L0346:  call    $c006
L0349:  jr      nc,L0365         ; (+$1a)
L034b:  push    de
L034c:  inc     hl
L034d:  ex      de,hl
L034e:  ld      hl,$b8da
L0351:  ld      bc,($b8d6)
L0355:  ld      b,$00
L0357:  add     hl,bc
L0358:  add     hl,bc
L0359:  ld      (hl),e
L035a:  inc     hl
L035b:  ld      (hl),d
L035c:  ld      hl,$fffc
L035f:  add     hl,de
L0360:  call    L02a0            ; KL LOG EXT
L0363:  dec     hl
L0364:  pop     de
L0365:  pop     bc
L0366:  jp      $ba87            ;; HI: KL ROM DESELECT
 
;;=== =======================================================
;; DE  of event block
;; HL  of event list
 
;; fi n list
L0369:  ld      a,(hl)
L036a:  cp      e
L036b:  inc     hl
L036c:  ld      a,(hl)
L036d:  dec     hl
L036e:  jr      nz,L0373         ; (+$03)
L0370:  cp      d
L0371:  scf     
L0372:  ret     z
 
L0373:  or      a
L0374:  ret     z
 
L0375:  ld      l,(hl)
L0376:  ld      h,a
L0377:  jr      L0369 ;; find event in list            ; (-$10)
 
;;=== =======================================================
;; ad  an event list
;; HL  of event block
;; DE  of event list
L0379:  ex      de,hl
L037a:  di      
L037b:  call    L0369 ;; find event in list
L037e:  jr      c,L0386          ; event found
;; ad of list
L0380:  ld      (hl),e
L0381:  inc     hl
L0382:  ld      (hl),d
L0383:  inc     de
L0384:  xor     a
L0385:  ld      (de),a
 
L0386:  ei      
L0387:  ret     
 
;;=== =======================================================
;; de  from list
;; HL  of event block
;; DE  of event list
L0388:  ex      de,hl
L0389:  di      
L038a:  call    L0369 ;; find event in list
L038d:  jr      nc,L0395         ; (+$06)
L038f:  ld      a,(de)
L0390:  ld      (hl),a
L0391:  inc     de
L0392:  inc     hl
L0393:  ld      a,(de)
L0394:  ld      (hl),a
L0395:  ei      
L0396:  ret     
 
;;=== =======================================================
;; KL CH 
;; 
;; A  iguration (0-31)
;; 
;; Al onfiguration to be used, so compatible with ALL Dk'Tronics RAM sizes.
 
L0397:  di      
L0398:  exx     
L0399:  ld      hl,$b8d5   ; current bank selection
L039c:  ld      d,(hl)     ; get previous
L039d:  ld      (hl),a     ; set new
L039e:  or      $c0        ; bit 7 = 1, bit 6 = 1, selection in lower bits.
L03a0:  out     (c),a
L03a2:  ld      a,d        ; previous bank selection
L03a3:  exx     
L03a4:  ei      
L03a5:  ret     
 
;;--- -------------------------------------------------------
;; HI JUMPBLOCK
L03a6:  jp      $ba5f        ;; HI: KL U ROM ENABLE
L03a9:  jp      $ba66        ;; HI: KL U ROM DISABLE
L03ac:  jp      $ba51        ;; HI: KL L ROM ENABLE
L03af:  jp      $ba58        ;; HI: KL L ROM DISABLE
L03b2:  jp      $ba70        ;; HI: KL L ROM RESTORE
L03b5:  jp      $ba79        ;; HI: KL ROM SELECT
L03b8:  jp      $ba9d        ;; HI: KL CURR SELECTION
L03bb:  jp      $ba7e        ;; HI: KL PROBE ROM
L03be:  jp      $ba87        ;; HI: KL ROM DESELECT
L03c1:  jp      $baa1        ;; HI: KL LDIR
L03c4:  jp      $baa7        ;; HI: KL LDDR
 
;;--- -------------------------------------------------------
L03c7:  ld      a,($b8c1)    ;; HI: KL POLL SYNCRONOUS
L03ca:  or      a
L03cb:  ret     z
 
L03cc:  push    hl
L03cd:  di      
L03ce:  jr      L03d6            ; (+$06)
 
L03d0:  ld      hl,$b8bf     ;; HI: KL SCAN NEEDED
L03d3:  ld      (hl),$01
L03d5:  ret     
 
L03d6:  ld      hl,($b8c0)       ; synchronouse event list
L03d9:  ld      a,h
L03da:  or      a
L03db:  jr      z,L03e4          ; (+$07)
L03dd:  inc     hl
L03de:  inc     hl
L03df:  inc     hl
L03e0:  ld      a,($b8c2)
L03e3:  cp      (hl)
L03e4:  pop     hl
L03e5:  ei      
L03e6:  ret     
 
;;=== ===============================================================================
; RST INTERRUPT ENTRY handler
 
L03e7:  di      
L03e8:  ex      af,af'
L03e9:  jr      c,L041e          ; detect external interrupt
L03eb:  exx     
L03ec:  ld      a,c
L03ed:  scf     
L03ee:  ei      
L03ef:  ex      af,af'           ; allow interrupt function to be re-entered. This will happen if there is an external interrupt
                               ; source that continues to assert INT. Internal raster interrupts are acknowledged automatically and cleared.
L03f0:  di      
L03f1:  push    af
L03f2:  res     2,c              ; ensure lower rom is active in range $0000-$3fff
L03f4:  out     (c),c
L03f6:  call    L00b1            ; update time, execute FRAME FLY, FAST TICKER and SOUND events
                               ; also scan keyboard
L03f9:  or      a
L03fa:  ex      af,af'
L03fb:  ld      c,a
L03fc:  ld      b,$7f
 
L03fe:  ld      a,($b831)
L0401:  or      a
L0402:  jr      z,L0418          ; quit...
L0404:  jp      m,$b972          ; quit... (same as 0418, but in RAM)
 
L0407:  ld      a,c
L0408:  and     $0c              ; %00001100
L040a:  push    af
L040b:  res     2,c              ; ensure lower rom is active in range $0000-$3fff
L040d:  exx     
L040e:  call    L010a
L0411:  exx     
L0412:  pop     hl
L0413:  ld      a,c
L0414:  and     $f3              ; %11110011
L0416:  or      h
L0417:  ld      c,a
 
;; 
L0418:  out     (c),c            ; set rom config/mode etc
L041a:  exx     
L041b:  pop     af
L041c:  ei      
L041d:  ret     
 
;; ha nal interrupt
L041e:  ex      af,af'
L041f:  pop     hl
L0420:  push    af
L0421:  set     2,c              ; disable lower rom 
L0423:  out     (c),c            ; set rom config/mode etc
L0425:  call    L003b            ; LOW: EXT INTERRUPT. Patchable by the user
L0428:  jr      L03f9            ; return to interrupt processing.
 
;;=== ===============================================================================
; LOW CHL
L042a:  di      
L042b:  push    hl               ; store HL onto stack
L042c:  exx     
L042d:  pop     de               ; get it back from stack
L042e:  jr      L0436            ; 
 
;;=== ===============================================================================
; RST LOW JUMP
 
L0430:  di      
L0431:  exx     
L0432:  pop     hl               ; get return address from stack
L0433:  ld      e,(hl)           ; DE = address to call
L0434:  inc     hl
L0435:  ld      d,(hl)
 
;;--- -------------------------------------------------------------------------------
L0436:  ex      af,af'
L0437:  ld      a,d
L0438:  res     7,d
L043a:  res     6,d
L043c:  rlca    
L043d:  rlca    
 
;;--- --------------------------------------------------------------------------------
L043e:  rlca    
L043f:  rlca    
L0440:  xor     c
L0441:  and     $0c
L0443:  xor     c
L0444:  push    bc
L0445:  call    $b9b0
L0448:  di      
L0449:  exx     
L044a:  ex      af,af'
L044b:  ld      a,c
L044c:  pop     bc
L044d:  and     $03
L044f:  res     1,c
L0451:  res     0,c
L0453:  or      c
L0454:  jr      L0457            ; (+$01)
 
;;=== ===============================================================================
;; co 9b0 in RAM
 
L0456:  push    de
L0457:  ld      c,a
L0458:  out     (c),c
L045a:  or      a
L045b:  ex      af,af'
L045c:  exx     
L045d:  ei      
L045e:  ret     
 
;;=== ===============================================================================
; LOW CHL
L045f:  di      
L0460:  ex      af,af'
L0461:  ld      a,c
L0462:  push    hl
L0463:  exx     
L0464:  pop     de
L0465:  jr      L047c            ; (+$15)
 
;;=== ===============================================================================
; LOW CALL
L0467:  di      
L0468:  push    hl
L0469:  exx     
L046a:  pop     hl
L046b:  jr      L0476            ; (+$09)
 
;;=== ===============================================================================
;; RS  FAR CALL
;; 
;; fa its rom select to 251. So firmware can call functions in ROMs up to 251.
;; If to access ROMs above this use KL ROM SELECT.
;; 
L046d:  di      
L046e:  exx     
L046f:  pop     hl
L0470:  ld      e,(hl)
L0471:  inc     hl
L0472:  ld      d,(hl)
L0473:  inc     hl
L0474:  push    hl
L0475:  ex      de,hl
L0476:  ld      e,(hl)
L0477:  inc     hl
L0478:  ld      d,(hl)
L0479:  inc     hl
L047a:  ex      af,af'
L047b:  ld      a,(hl)
;; $f nge to rom select, enable upper and lower roms
;; $f nge to rom select, enable upper disable lower
;; $f nge to rom select, disable upper and enable lower
;; $f nge to rom select, disable upper and lower roms
L047c:  cp      $fc
L047e:  jr      nc,L043e 
 
;; al lect to change
L0480:  ld      b,$df            ; ROM select I/O port
L0482:  out     (c),a            ; select upper rom
 
L0484:  ld      hl,$b8d6
L0487:  ld      b,(hl)
L0488:  ld      (hl),a
L0489:  push    bc
L048a:  push    iy
 
;; ro elow 16 (max for firmware 1.1)?
L048c:  cp      $10         
L048e:  jr      nc,L049f   
 
;; 16  at $b8da
L0490:  add     a,a
L0491:  add     a,$da
L0493:  ld      l,a
L0494:  adc     a,$b8
L0496:  sub     l
L0497:  ld      h,a
 
;; ge alue from this address
L0498:  ld      a,(hl)
L0499:  inc     hl
L049a:  ld      h,(hl)
L049b:  ld      l,a
L049c:  push    hl
L049d:  pop     iy
 
L049f:  ld      b,$7f
L04a1:  ld      a,c
L04a2:  set     2,a          
L04a4:  res     3,a          
L04a6:  call    $b9b0
L04a9:  pop     iy
L04ab:  di      
L04ac:  exx     
L04ad:  ex      af,af'
L04ae:  ld      e,c
L04af:  pop     bc
L04b0:  ld      a,b
;; re select
L04b1:  ld      b,$df            ; ROM select I/O port
L04b3:  out     (c),a            ; restore upper rom selection
 
L04b5:  ld      ($b8d6),a
L04b8:  ld      b,$7f
L04ba:  ld      a,e
L04bb:  jr      L044d            ; (-$70)
 
;;=== ===============================================================================
; LOW PCHL
L04bd:  di      
L04be:  push    hl
L04bf:  exx     
L04c0:  pop     de
L04c1:  jr      L04cb            ; (+$08)
 
;;=== ===============================================================================
;; RS  SIDE CALL
 
L04c3:  di      
L04c4:  exx     
L04c5:  pop     hl
L04c6:  ld      e,(hl)
L04c7:  inc     hl
L04c8:  ld      d,(hl)
L04c9:  inc     hl
L04ca:  push    hl
L04cb:  ex      af,af'
L04cc:  ld      a,d
L04cd:  set     7,d
L04cf:  set     6,d
L04d1:  and     $c0
L04d3:  rlca    
L04d4:  rlca    
L04d5:  ld      hl,$b8d9
L04d8:  add     a,(hl)
L04d9:  jr      L0480            ; (-$5b)
 
;;=== ===============================================================================
; RST FIRM JUMP
L04db:  di      
L04dc:  exx     
L04dd:  pop     hl
L04de:  ld      e,(hl)
L04df:  inc     hl
L04e0:  ld      d,(hl)
L04e1:  res     2,c              ; enable lower rom
L04e3:  out     (c),c
L04e5:  ld      ($ba46),de
L04e9:  exx     
L04ea:  ei      
L04eb:  call    $ba45
L04ee:  di      
L04ef:  exx     
L04f0:  set     2,c              ; disable lower rom
L04f2:  out     (c),c
L04f4:  exx     
L04f5:  ei      
L04f6:  ret     
 
;;=== ===============================================================================
;; HI  ENABLE
L04f7:  di      
L04f8:  exx     
L04f9:  ld      a,c        ; current mode/rom state
L04fa:  res     2,c              ; enable lower rom
L04fc:  jr      L0511            ; enable/disable rom common code
 
;;=== ===============================================================================
;; HI  DISABLE
L04fe:  di      
L04ff:  exx     
L0500:  ld      a,c        ; current mode/rom state
L0501:  set     2,c              ; disable upper rom
L0503:  jr      L0511            ; enable/disable rom common code
 
;;=== ===============================================================================
;; HI  ENABLE
L0505:  di      
L0506:  exx     
L0507:  ld      a,c        ; current mode/rom state
L0508:  res     3,c              ; enable upper rom
L050a:  jr      L0511            ; enable/disable rom common code
 
;;=== ===============================================================================
;; HI  DISABLE
L050c:  di      
L050d:  exx     
L050e:  ld      a,c        ; current mode/rom state
L050f:  set     3,c              ; disable upper rom
 
;;--- -------------------------------------------------------------------------------
;; en le rom common code
L0511:  out     (c),c
L0513:  exx     
L0514:  ei      
L0515:  ret     
 
;;=== ===============================================================================
;; HI  RESTORE
L0516:  di      
L0517:  exx     
L0518:  xor     c
L0519:  and     $0c              ; %1100
L051b:  xor     c
L051c:  ld      c,a
L051d:  jr      L0511             ; enable/disable rom common code
 
;;=== ===============================================================================
;; HI ELECT
;; An n be used from 0-255.
 
L051f:  call    $ba5f            ;; HI: KL U ROM ENABLE
L0522:  jr      L0533      ;; common upper rom selection code      
 
;;=== ===============================================================================
;; HI  ROM
L0524:  call    $ba79            ;; HI: KL ROM SELECT
 
;; re sion etc
L0527:  ld      a,($c000)            
L052a:  ld      hl,($c001)
;; dr  to HI: KL ROM DESELECT
;;=== ===============================================================================
;; HI ESELECT
L052d:  push    af
L052e:  ld      a,b
L052f:  call    $ba70            ;; HI: KL L ROM RESTORE
L0532:  pop     af
 
;;--- -------------------------------------------------------------------------------
;; co  rom selection code
L0533:  push    hl
L0534:  di      
L0535:  ld      b,$df            ;; ROM select I/O port
L0537:  out     (c),c            ;; select upper rom
L0539:  ld      hl,$b8d6   ;; previous upper rom selection
L053c:  ld      b,(hl)     ;; get previous upper rom selection
L053d:  ld      (hl),c     ;; store new rom selection
L053e:  ld      c,b        ;; C = previous rom select
L053f:  ld      b,a        ;; B = previous rom state
L0540:  ei      
L0541:  pop     hl
L0542:  ret     
 
;;=== ===============================================================================
;; HI SELECTION
L0543:  ld      a,($b8d6)
L0546:  ret     
 
;;=== ===============================================================================
;; HI 
L0547:  call    $baad            ;; disable upper/lower rom.. execute code below and then restore rom state
 
;; ca baad
L054a:  ldir    
;; re  to code after call in $baad   
L054c:  ret     
 
;;=== ===============================================================================
;; HI 
L054d:  call    $baad            ;; disable upper/lower rom.. execute code below and then restore rom state
 
;; ca baad
L0550:  lddr 
;; re  to code after call in $baad   
L0552:  ret     
;;=== ===============================================================================
;; us KL LDIR and HI: KL LDDR
;; co aad in RAM
;; 
;; -  pper and lower rom
;; -  execution from function that called it allowing it to return back
;; -  pper and lower rom state
 
L0553:  di      
L0554:  exx     
L0555:  pop     hl                   ; return address
L0556:  push    bc                   ; store rom state
L0557:  set     2,c                  ; disable lower rom
L0559:  set     3,c                  ; disable upper rom
L055b:  out     (c),c                ; set rom state
 
;; ju tion on the stack, allow it to return back here
L055d:  call    $bac2                ; jump to function in HL
 
 
L0560:  di      
L0561:  exx     
L0562:  pop     bc                   ; get previous rom state
L0563:  out     (c),c                ; restore previous rom state
L0565:  exx     
L0566:  ei      
L0567:  ret     
 
;;=== ===============================================================================
;; co ac2 into RAM
L0568:  push    hl
L0569:  exx     
L056a:  ei      
L056b:  ret     
 
;;=== ===============================================================================
; RST RAM LAM
;; HL  to read
L056c:  di      
L056d:  exx     
L056e:  ld      e,c              ;; E = current rom configuration
L056f:  set     2,e              ;; disable lower rom
L0571:  set     3,e              ;; disable upper rom
L0573:  out     (c),e            ;; set rom configuration
L0575:  exx     
L0576:  ld      a,(hl)           ;; read byte from RAM
L0577:  exx     
L0578:  out     (c),c            ;; restore rom configuration
L057a:  exx     
L057b:  ei      
L057c:  ret     
 
;;=== ===============================================================================
;; re om address pointed to IX with roms disabled
;; 
;; (u sette functions to read/write to RAM)
;; 
;; IX  of byte to read
;; C'  rom selection and mode
 
L057d:  exx                      ;; switch to alternative register set
 
L057e:  ld      a,c              ;; get rom configuration
L057f:  or      $0c              ;; %00001100 (disable upper and lower rom)
L0581:  out     (c),a            ;; set the new rom configuration
 
L0583:  ld      a,(ix+$00)       ;; read byte from RAM
 
L0586:  out     (c),c            ;; restore original rom configuration
L0588:  exx                      ;; switch back from alternative register set
L0589:  ret     
 
;;=== ===============================================================================
 
L058a:  ld      h,$c7
L058c:  rst     $00
L058d:  rst     $00
L058e:  rst     $00
L058f:  rst     $00
L0590:  rst     $00
 
;;=== ===============================================================================
L0591:  di      
L0592:  ld      bc,$f782
L0595:  out     (c),c
 
L0597:  ld      bc,$f400         ;; initialise PPI port A data
L059a:  out     (c),c
 
L059c:  ld      bc,$f600         ;; initialise PPI port C data 
                               ;; - select keyboard line 0
                               ;; - PSG control inactive
                               ;; - cassette motor off
                               ;; - cassette write data "0"
L059f:  out     (c),c            ;; set PPI port C data
 
L05a1:  ld      bc,$ef7f
L05a4:  out     (c),c
 
L05a6:  ld      b,$f5            ;; PPI port B inputs
L05a8:  in      a,(c)
L05aa:  and     $10              
L05ac:  ld      hl,$05d5         ;; end of CRTC data for 50Hz display
L05af:  jr      nz,L05b4         
L05b1:  ld      hl,$05e5         ;; end of CRTC data for 60Hz display
 
;; in isplay
;; st h register 15, then down to 0
L05b4:  ld      bc,$bc0f
L05b7:  out     (c),c            ; select CRTC register
L05b9:  dec     hl
L05ba:  ld      a,(hl)           ; get data from table 
L05bb:  inc     b
L05bc:  out     (c),a            ; write data to selected CRTC register
L05be:  dec     b
L05bf:  dec     c
L05c0:  jp      p,L05b7
 
;; co h setup...
L05c3:  jr      L05e5            ; (+$20)

;; CRTC data for 50Hz display
L05c5:  defb $3f, $28, $2e, $8e, $26, $00, $19, $1e, $00, $07, $00,$00,$30,$00,$c0,$00
;; CRTC data for 60Hz display
L05d5:  defb $3f, $28, $2e, $8e, $1f, $06, $19, $1b, $00, $07, $00,$00,$30,$00,$c0,$00

;;========================================================
;; continue with setup...

L05e5:  ld      de,$0677         ; this is executed by execution address
L05e8:  ld      hl,$0000         ; this will force MC START PROGRAM to start BASIC
L05eb:  jr      L061f            ; mc start program

;;===============================================
;; MCGRAM
;; 
;; HLe address

L05ed:  ld      sp,$c000
L05f0:  push    hl
L05f1:  call    L1fe9            ;; SOUND RESET
L05f4:  di      

L05f5:  ld      bc,$f8ff         ;; reset all peripherals
L05f8:  out     (c),c

L05fa:  call    L005c            ;; KL CHOKE OFF
L05fd:  pop     hl
L05fe:  push    de
L05ff:  push    bc
L0600:  push    hl
L0601:  call    L1b98            ;; KM RESET
L0604:  call    L1084            ;; TXT RESET
L0607:  call    L0ad0            ;; SCR RESET
L060a:  call    $ba5f            ;; HI: KL U ROM ENABLE
L060d:  pop     hl
L060e:  call    L001e            ;; LOW: PCHL INSTRUCTION
L0611:  pop     bc
L0612:  pop     de
L0613:  jr      c,L061c          ; MC START PROGRAM


;; digram load failed message
L0615:  ex      de,hl
L0616:  ld      c,b
L0617:  ld      de,$06f9         ; program load failed
L061a:  jr      L061f            ; 

;;================================================
;; MCOGRAM
;; HLaddress
;; C ect 

L061c:  ld      de,$0737         ; RET (no message)
                               ; this is executed by: LOW: PCHL INSTRUCTION

;;------------------------------------------------

L061f:  di                       ; disable interrupts
L0620:  im      1                ; Z80 interrupt mode 1
L0622:  exx     

L0623:  ld      bc,$df00         ; select upper ROM 0
L0626:  out     (c),c

L0628:  ld      bc,$f8ff         ; reset all peripherals
L062b:  out     (c),c

L062d:  ld      bc,$7fc0         ; select ram configuration 0
L0630:  out     (c),c

L0632:  ld      bc,$fa7e         ; stop disc motor
L0635:  xor     a
L0636:  out     (c),a

L0638:  ld      hl,$b100         ; clear memory block which will hold 
L063b:  ld      de,$b101         ; firmware jumpblock
L063e:  ld      bc,$07f9
L0641:  ld      (hl),a
L0642:  ldir    

L0644:  ld      bc,$7f89         ; select mode 1, lower rom on, upper rom off
L0647:  out     (c),c

L0649:  exx     
L064a:  xor     a
L064b:  ex      af,af'
L064c:  ld      sp,$c000             ;; initial stack location
L064f:  push    hl
L0650:  push    bc
L0651:  push    de

L0652:  call    L0044                ;; initialise LOW KERNEL and HIGH KERNEL jumpblocks
L0655:  call    L08bd                ;; JUMP RESTORE
L0658:  call    L1b5c                ;; KM INITIALISE
L065b:  call    L1fe9                ;; SOUND RESET
L065e:  call    L0abf                ;; SCR INITIALISE
L0661:  call    L1074                ;; TXT INITIALISE
L0664:  call    L15a8                ;; GRA INITIALISE
L0667:  call    L24bc                ;; CAS INITIALISE
L066a:  call    L07e0                ;; MC RESET PRINTER
L066d:  ei      
L066e:  pop     hl
L066f:  call    L001e                ;; LOW: PCHL INSTRUCTION
L0672:  pop     bc
L0673:  pop     hl
L0674:  jp      L0077                ;; start BASIC or program

;;=============================================================

L0677:  ld      hl,$0202
L067a:  call    L1170            ; TXT SET CURSOR

L067d:  call    L0723            ; get pointer to machine name (based on LK1-LK3 on PCB)

L0680:  call    L06fc            ; display message

L0683:  ld      hl,$0688         ; "128K Microcomputer.." message
L0686:  jr      L06fc            ; 

L0688:  defb " 128K Microcomputer  (v3)"
        defb $1f,$02,$04
        defb "Copyright"
        defb $1f,$02,$04
        defb $a4                                ;; copyright symbol
        defb "1985 Amstrad Consumer Electronics plc"
        defb $1f,$0c,$05
        defb "and Locomotive Software Ltd."
        defb $1f,$01,$07
        defb 0

;;-----------------------------------------------------------------------
L06f9:  ld      hl,$0705         ; "*** PROGRAM LOAD FAILED ***" message

;;--------------------------------------------------------------
;; diull terminated string
L06fc:  ld      a,(hl)           ; get message character
L06fd:  inc     hl
L06fe:  or      a
L06ff:  ret     z

L0700:  call    L13fe            ; TXT OUTPUT
L0703:  jr      L06fc            

L0705:  defb "*** PROGRAM LOAD FAILED ***",13,10,0
;;-----------------------------------------------------------------------
;; get a pointer to the machine name
;; HL = machine name
L0723:  ld      b,$f5            ;; PPI port B input
L0725:  in      a,(c)
L0727:  cpl     
L0728:  and     $0e              ;; isolate LK1-LK3 (defines machine name on startup)
L072a:  rrca    
;; A  name number
L072b:  ld      hl,$0738         ; table of names
L072e:  inc     a
L072f:  ld      b,a

;; B f string wanted

;; keg bytes until end of string marker (0) is found
;; detring count and continue until we have got string
;; wa
L0730:  ld      a,(hl)           ; get byte
L0731:  inc     hl
L0732:  or      a                ; end of string?
L0733:  jr      nz,L0730         ; 

L0735:  djnz    $0730            ; (-$07)
L0737:  ret     

;; start-up names
L0738:  defb "Arnold",0                         ;; this name can't be chosen
        defb "Amstrad",0
        defb "Orion",0
        defb "Schneider",0
        defb "Awa",0
        defb "Solavox",0
        defb "Saisho",0
        defb "Triumph",0
        defb "Isp",0


;;====================================================================
;; MC SET MODE
;; 
;; A = mode index
;;
;; C' = Gate Array rom and mode configuration register

;; test mode index is in range
L0776:  cp      $03
L0778:  ret     nc

;; mois in range: A = 0,1 or 2.

L0779:  di      
L077a:  exx     
L077b:  res     1,c              ;; clear mode bits (bit 1 and bit 0)
L077d:  res     0,c

L077f:  or      c                ;; set mode bits to new mode value
L0780:  ld      c,a
L0781:  out     (c),c            ;; set mode
L0783:  ei      
L0784:  exx     
L0785:  ret     

;;===========================================================
;; MCKS

L0786:  push    hl
L0787:  ld      hl,$0000
L078a:  jr      L0790            

;;===========================================================
;; MC

L078c:  push    hl
L078d:  ld      hl,$0001

;;-----------------------------------------------------------
;; HLclear, 1 for set
L0790:  push    de
L0791:  push    bc
L0792:  ex      de,hl

L0793:  ld      bc,$7f10         ; set border colour
L0796:  call    L07aa            ; set colour for PEN/border direct to hardware
L0799:  inc     hl
L079a:  ld      c,$00

L079c:  call    L07aa            ; set colour for PEN/border direct to hardware
L079f:  add     hl,de
L07a0:  inc     c
L07a1:  ld      a,c
L07a2:  cp      $10        ; maximum number of colours (mode 0 has 16 colours)
L07a4:  jr      nz,L079c         ; (-$0a)

L07a6:  pop     bc
L07a7:  pop     de
L07a8:  pop     hl
L07a9:  ret     

;;===========================================================
;; sefor a pen
;;
;; HLs of colour for pen
;; C ex

L07aa:  out     (c),c            ; select pen 
L07ac:  ld      a,(hl)
L07ad:  and     $1f
L07af:  or      $40
L07b1:  out     (c),a            ; set colour for pen
L07b3:  ret     


;;===========================================================
;; MCBACK

L07b4:  push    af
L07b5:  push    bc

L07b6:  ld      b,$f5            ; PPI port B I/O address
L07b8:  in      a,(c)            ; read PPI port B input
L07ba:  rra                      ; transfer bit 0 (VSYNC signal from CRTC) into carry flag
L07bb:  jr      nc,L07b8         ; wait until VSYNC=1

L07bd:  pop     bc
L07be:  pop     af
L07bf:  ret     

;;===========================================================
;; MCFFSET
;;
;; HL
;; A 

L07c0:  push    bc
L07c1:  rrca    
L07c2:  rrca    
L07c3:  and     $30
L07c5:  ld      c,a
L07c6:  ld      a,h
L07c7:  rra     
L07c8:  and     $03
L07ca:  or      c

;; CRer 12 and 13 define screen base and offset

L07cb:  ld      bc,$bc0c         
L07ce:  out     (c),c            ; select CRTC register 12
L07d0:  inc     b                ; BC = bd0c
L07d1:  out     (c),a            ; set CRTC register 12 data
L07d3:  dec     b                ; BC = bc0c
L07d4:  inc     c                ; BC = bc0d
L07d5:  out     (c),c            ; select CRTC register 13
L07d7:  inc     b                ; BC = bd0d

L07d8:  ld      a,h
L07d9:  rra     
L07da:  ld      a,l
L07db:  rra     

L07dc:  out     (c),a            ; set CRTC register 13 data
L07de:  pop     bc
L07df:  ret     


;;===========================================================
;; MCINTER

L07e0:  ld      hl,$07f7
L07e3:  ld      de,$b804
L07e6:  ld      bc,$0015
L07e9:  ldir    

L07eb:  ld      hl,$07f1             ;; table used to initialise printer indirections
L07ee:  jp      L0ab4                ;; initialise printer indirections

L07f1:  defb $03
        defw $bdf1                                  
        jp      L0835                               ;; IND: MC WAIT PRINTER

L07f7:  ld      a,(bc)
L07f8:  and     b
L07f9:  ld      e,(hl)
L07fa:  and     c
L07fb:  ld      e,h
L07fc:  and     d
L07fd:  ld      a,e
L07fe:  and     e
L07ff:  inc     hl
L0800:  and     (hl)
L0801:  ld      b,b
L0802:  xor     e
L0803:  ld      a,h
L0804:  xor     h
L0805:  ld      a,l
L0806:  xor     l
L0807:  ld      a,(hl)
L0808:  xor     (hl)
L0809:  ld      e,l
L080a:  xor     a
L080b:  ld      e,e

;;==================================================================
;; MCANSLATION

L080c:  rst     $20              ; RST 4 - LOW: RAM LAM
L080d:  add     a,a
L080e:  inc     a
L080f:  ld      c,a
L0810:  ld      b,$00
L0812:  ld      de,$b804
L0815:  cp      $2a
L0817:  call    c,$baa1          ;; HI: KL LDIR
L081a:  ret     

;;==================================================================
;; MCAR

L081b:  push    bc
L081c:  push    hl
L081d:  ld      hl,$b804
L0820:  ld      b,(hl)
L0821:  inc     b
L0822:  dec     b
L0823:  jr      z,L082f          ; (+$0a)
L0825:  inc     hl
L0826:  cp      (hl)
L0827:  inc     hl
L0828:  jr      nz,L0822         ; (-$08)
L082a:  ld      a,(hl)
L082b:  cp      $ff
L082d:  jr      z,L0832          ; (+$03)
L082f:  call    $bdf1            ; IND: MC WAIT PRINTER
L0832:  pop     hl
L0833:  pop     bc
L0834:  ret     

;;===========================================================
;; INT PRINTER

L0835:  ld      bc,$0032
L0838:  call    L0858            ; MC BUSY PRINTER
L083b:  jr      nc,L0844         ; MC SEND PRINTER
L083d:  djnz    $0838            
L083f:  dec     c
L0840:  jr      nz,L0838         
L0842:  or      a
L0843:  ret     

;;===========================================================
;; MCNTER
;; 
;; NO
;; -  of A contain the data
;; - data is /STROBE signal
;; - ignal is inverted by hardware; therefore 0->1 and 1->0
;; - ritten with /STROBE pulsed low 
L0844:  push    bc
L0845:  ld      b,$ef            ; printer I/O address
L0847:  and     $7f              ; clear bit 7 (/STROBE)
L0849:  out     (c),a            ; write data with /STROBE=1
L084b:  or      $80              ; set bit 7 (/STROBE)
L084d:  di                       
L084e:  out     (c),a            ; write data with /STROBE=0
L0850:  and     $7f              ; clear bit 7 (/STROBE)
L0852:  ei                       
L0853:  out     (c),a            ; write data with /STROBE=1
L0855:  pop     bc
L0856:  scf     
L0857:  ret     

;;===========================================================
;; MCNTER
;; 
;; ex
;; cate of BUSY input from printer

L0858:  push    bc
L0859:  ld      c,a
L085a:  ld      b,$f5            ; PPI port B I/O address
L085c:  in      a,(c)            ; read PPI port B input
L085e:  rla                      ; transfer bit 6 into carry (BUSY input from printer)                       
L085f:  rla
L0860:  ld      a,c
L0861:  pop     bc
L0862:  ret     

;;===========================================================
;; MCGISTER
;; 
;; en
;; A r index
;; C r data
;; 

L0863:  di      

L0864:  ld      b,$f4            ; PPI port A I/O address
L0866:  out     (c),a            ; write register index

L0868:  ld      b,$f6            ; PPI port C I/O address
L086a:  in      a,(c)            ; get current outputs of PPI port C I/O port
L086c:  or      $c0              ; bit 7,6: PSG register select
L086e:  out     (c),a            ; write control to PSG. PSG will select register
                               ; referenced by data at PPI port A output
L0870:  and     $3f              ; bit 7,6: PSG inactive
L0872:  out     (c),a            ; write control to PSG.

L0874:  ld      b,$f4            ; PPI port A I/O address
L0876:  out     (c),c            ; write register data

L0878:  ld      b,$f6            ; PPI port C I/O address
L087a:  ld      c,a
L087b:  or      $80              ; bit 7,6: PSG write data to selected register
L087d:  out     (c),a            ; write control to PSG. PSG will write the data
                               ; at PPI port A into the currently selected register
; bit inactive
L087f:  out     (c),c            ; write control to PSG
L0881:  ei      
L0882:  ret     

;;-----------------------------------------------------
;; scrd

;;------------------------------------------------------------------------
;; seport A register
L0883:  ld      bc,$f40e         ; B = I/O address for PPI port A
                               ; C = 14 (index of PSG I/O port A register)
L0886:  out     (c),c            ; write PSG register index to PPI port A

L0888:  ld      b,$f6            ; B = I/O address for PPI port C
L088a:  in      a,(c)            ; get current port C data
L088c:  and     $30
L088e:  ld      c,a

L088f:  or      $c0              ; PSG operation: select register
L0891:  out     (c),a            ; write to PPI port C 
                               ; PSG will use data from PPI port A
                               ; to select a register
L0893:  out     (c),c            

;;------------------------------------------------------------------------
;; set A to input
L0895:  inc     b                ; B = $f7 (I/O address for PPI control)
L0896:  ld      a,$92            ; PPI port A: input
                               ; PPI port B: input
                               ; PPI port C (upper and lower): output
L0898:  out     (c),a            ; write to PPI control register

;;------------------------------------------------------------------------

L089a:  push    bc
L089b:  set     6,c              ; PSG: operation: read data from selected register


L089d:  ld      b,$f6            ; B = I/O address for PPI port C
L089f:  out     (c),c
L08a1:  ld      b,$f4            ; B = I/O address for PPI port A
L08a3:  in      a,(c)            ; read selected keyboard line
                               ; (keyboard data->PSG port A->PPI port A)

L08a5:  ld      b,(hl)           ; get previous keyboard line state
                               ; "0" indicates a pressed key
                               ; "1" indicates a released key
L08a6:  ld      (hl),a           ; store new keyboard line state

L08a7:  and     b                ; a bit will be 1 where a key was not pressed
                               ; in the previous keyboard scan and the current keyboard scan.
                               ; a bit will be 0 where a key has been:
                               ; - pressed in previous keyboard scan, released in this keyboard scan
                               ; - not pressed in previous keyboard scan, pressed in this keyboard scan
                               ; - key has been held for previous and this keyboard scan.
L08a8:  cpl                      ; change so a '1' now indicates held/pressed key
                               ; '0' indicates a key that has not been pressed/held
L08a9:  ld      (de),a           ; store keybaord line data

L08aa:  inc     hl
L08ab:  inc     de
L08ac:  inc     c

L08ad:  ld      a,c
L08ae:  and     $0f              ; current keyboard line
L08b0:  cp      $0a              ; 10 keyboard lines
L08b2:  jr      nz,L089d         

L08b4:  pop     bc
;; B ress of PPI control register
L08b5:  ld      a,$82            ; PPI port A: output
                               ; PPI port B: input
                               ; PPI port C (upper and lower): output
L08b7:  out     (c),a
;; B ress of PPI port C lower

L08b9:  dec     b
L08ba:  out     (c),c
L08bc:  ret     

;;-----------------------------------------------------
;; JUE
;;
;; (rl the firmware jump routines)

;; mare jumpblock
L08bd:  ld      hl,$08de         ; table of addressess for firmware functions
L08c0:  ld      de,$bb00         ; start of firmware jumpblock
L08c3:  ld      bc,$cbcf         ; B = 203 entries, C = 0x0cf -> RST 1 -> LOW: LOW JUMP
L08c6:  call    L08cc

L08c9:  ld      bc,$20ef         ; B = number of entries: 32 entries
                               ; C=  0x0ef -> RST 5 -> LOW: FIRM JUMP
;;----------------------------------------------------------------------------
; C = RST 1 -> LOW: LOW JUMP
; OR
; C=  RST 5 -> LOW: FIRM JUMP

L08cc:  ld      a,c              ; write RST instruction             
L08cd:  ld      (de),a
L08ce:  inc     de
L08cf:  ldi                      ; write low byte of address in ROM
L08d1:  inc     bc
L08d2:  cpl     
L08d3:  rlca    
L08d4:  rlca    
L08d5:  and     $80
L08d7:  or      (hl)
L08d8:  ld      (de),a           ; write high byte of address in ROM
L08d9:  inc     de
L08da:  inc     hl
L08db:  djnz    $08cc            
L08dd:  ret     

;; each entry is an address (within this ROM) which will perform
;; the associated firmware function
L08de:  defw $1b5c      ;; 0 firmware function: KM INITIALISE
        defw $1b98      ;; 1 firmware function: KM RESET 
        defw $1bbf      ;; 2 firmware function: KM WAIT CHAR
        defw $1bc5      ;; 3 firmware function: KM READ CHAR 
        defw $1bfa      ;; 4 firmware function: KM CHAR RETURN
        defw $1c46      ;; 5 firmware function: KM SET EXPAND
        defw $1cb3      ;; 6 firmware function: KM GET EXPAND
        defw $1c04      ;; 7 firmware function: KM EXP BUFFER
        defw $1cdb      ;; 8 firmware function: KM WAIT KEY
        defw $1ce1      ;; 9 firmware function: KM READ KEY
        defw $1e45      ;; 10 firmware function: KM TEST KEY
        defw $1d38      ;; 11 firmware function: KM GET STATE
        defw $1de5      ;; 12 firmware function: KM GET JOYSTICK
        defw $1ed8      ;; 13 firmware function: KM SET TRANSLATE
        defw $1ec4      ;; 14 firmware function: KM GET TRANSLATE
        defw $1edd      ;; 15 firmware function: KM SET SHIFT
        defw $1ec9      ;; 16 firmware function: KM GET SHIFT
        defw $1ee2      ;; 17 firmware function: KM SET CONTROL 
        defw $1ece      ;; 18 firmware function: KM GET CONTROL 
        defw $1e34      ;; 19 firmware function: KM SET REPEAT
        defw $1e2f      ;; 20 firmware function: KM GET REPEAT
        defw $1df6      ;; 21 firmware function: KM SET DELAY
        defw $1df2      ;; 22 firmware function: KM GET DELAY
        defw $1dfa      ;; 23 firmware function: KM ARM BREAK
        defw $1e0b      ;; 24 firmware function: KM DISARM BREAK
        defw $1e19      ;; 25 firmware function: KM BREAK EVENT 
        defw $1074      ;; 26 firmware function: TXT INITIALISE
        defw $1084      ;; 27 firmware function: TXT RESET
        defw $1459      ;; 28 firmware function: TXT VDU ENABLE
        defw $1452      ;; 29 firmware function: TXT VDU DISABLE
        defw $13fe      ;; 30 firmware function: TXT OUTPUT
        defw $1335      ;; 31 firmware function: TXT WR CHAR
        defw $13ac      ;; 32 firmware function: TXT RD CHAR
        defw $13a8      ;; 33 firmware function: TXT SET GRAPHIC
        defw $1208      ;; 34 firmware function: TXT WIN ENABLE
        defw $1252      ;; 35 firmware function: TXT GET WINDOW
        defw $154f      ;; 36 firmware function: TXT CLEAR WINDOW
        defw $115a      ;; 37 firmware function: TXT SET COLUMN
        defw $1165      ;; 38 firmware function: TXT SET ROW
        defw $1170      ;; 39 firmware function: TXT SET CURSOR
        defw $117c      ;; 40 firmware function: TXT GET CURSOR
        defw $1286      ;; 41 firmware function: TXT CUR ENABLE
        defw $1297      ;; 42 firmware function: TXT CUR DISABLE
        defw $1276      ;; 43 firmware function: TXT CUR ON
        defw $127e      ;; 44 firmware function: TXT CUR OFF
        defw $11ca      ;; 45 firmware function: TXT VALIDATE
        defw $1265      ;; 46 firmware function: TXT PLACE CURSOR
        defw $1265      ;; 47 firmware function: TXT REMOVE CURSOR
        defw $12a6      ;; 48 firmware function: TXT SET PEN 
        defw $12ba      ;; 49 firmware function: TXT GET PEN
        defw $12ab      ;; 50 firmware function: TXT SET PAPER
        defw $12c0      ;; 51 firmware function: TXT GET PAPER
        defw $12c6      ;; 52 firmware function: TXT INVERSE
        defw $137b      ;; 53 firmware function: TXT SET BACK
        defw $1388      ;; 54 firmware function: TXT GET BACK
        defw $12d4      ;; 55 firmware function: TXT GET MATRIX
        defw $12f2      ;; 56 firmware function: TXT SET MATRIX
        defw $12fe      ;; 57 firmware function: TXT SET M TABLE
        defw $132b      ;; 58 firmware function: TXT GET M TABLE
        defw $14d4      ;; 59 firmware function: TXT GET CONTROLS
        defw $10e4      ;; 60 firmware function: TXT STR SELECT
        defw $1103      ;; 61 firmware function: TXT SWAP STREAMS
        defw $15a8      ;; 62 firmware function: GRA INITIALISE
        defw $15d7      ;; 63 firmware function: GRA RESET
        defw $15fe      ;; 64 firmware function: GRA MOVE ABSOLUTE
        defw $15fb      ;; 65 firmware function: GRA MOVE RELATIVE
        defw $1606      ;; 66 firmware function: GRA ASK CURSOR
        defw $160e      ;; 67 firmware function: GRA SET ORIGIN
        defw $161c      ;; 68 firmware function: GRA GET ORIGIN
        defw $16a5      ;; 69 firmware function: GRA WIN WIDTH
        defw $16ea      ;; 70 firmware function: GRA WIN HEIGHT
        defw $1717      ;; 71 firmware function: GRA GET W WIDTH
        defw $172d      ;; 72 firmware function: GRA GET W HEIGHT
        defw $1736      ;; 73 firmware function: GRA CLEAR WINDOW
        defw $1767      ;; 74 firmware function: GRA SET PEN
        defw $1775      ;; 75 firmware function: GRA GET PEN
        defw $176e      ;; 76 firmware function: GRA SET PAPER
        defw $177a      ;; 77 firmware function: GRA GET PAPER
        defw $1783      ;; 78 firmware function: GRA PLOT ABSOLUTE
        defw $1780      ;; 79 firmware function: GRA PLOT RELATIVE
        defw $1797      ;; 80 firmware function: GRA TEST ABSOLUTE
        defw $1794      ;; 81 firmware function: GRA TEST RELATIVE
        defw $17a9      ;; 82 firmware function: GRA LINE ABSOLUTE
        defw $17a6      ;; 83 firmware function: GRA LINE RELATIVE
        defw $1940      ;; 84 firmware function: GRA WR CHAR
        defw $0abf      ;; 85 firmware function: SCR INITIALIZE
        defw $0ad0      ;; 86 firmware function: SCR RESET
        defw $0b37      ;; 87 firmware function: SCR OFFSET
        defw $0b3c      ;; 88 firmware function: SCR SET BASE
        defw $0b56      ;; 89 firmware function: SCR GET LOCATION
        defw $0ae9      ;; 90 firmware function: SCR SET MODE
        defw $0b0c      ;; 91 firmware function: SCR GET MODE
        defw $0b17      ;; 92 firmware function: SCR CLEAR
        defw $0b5d      ;; 93 firmware function: SCR CHAR LIMITS
        defw $0b6a      ;; 94 firmware function: SCR CHAR POSITION
        defw $0baf      ;; 95 firmware function: SCR DOT POSITION
        defw $0c05      ;; 96 firmware function: SCR NEXT BYTE
        defw $0c11      ;; 97 firmware function: SCR PREV BYTE
        defw $0c1f      ;; 98 firmware function: SCR NEXT LINE
        defw $0c39      ;; 99 firmware function: SCR PREV LINE
        defw $0c8e      ;; 100 firmware function: SCR INK ENCODE
        defw $0ca7      ;; 101 firmware function: SCR INK DECODE
        defw $0cf2      ;; 102 firmware function: SCR SET INK
        defw $0d1a      ;; 103 firmware function: SCR GET INK
        defw $0cf7      ;; 104 firmware function: SCR SET BORDER
        defw $0d1f      ;; 105 firmware function: SCR GET BORDER
        defw $0cea      ;; 106 firmware function: SCR SET FLASHING
        defw $0cee      ;; 107 firmware function: SCR GET FLASHING
        defw $0db9      ;; 108 firmware function: SCR FILL BOX
        defw $0dbd      ;; 109 firmware function: SCR FLOOD BOX
        defw $0de5      ;; 110 firmware function: SCR CHAR INVERT
        defw $0e00      ;; 111 firmware function: SCR HW ROLL
        defw $0e44      ;; 112 firmware function: SCR SW ROLL
        defw $0ef9      ;; 113 firmware function: SCR UNPACK
        defw $0f2a      ;; 114 firmware function: SCR REPACK
        defw $0c55      ;; 115 firmware function: SCR ACCESS
        defw $0c74      ;; 116 firmware function: SCR PIXELS
        defw $0f93      ;; 117 firmware function: SCR HORIZONTAL
        defw $0f9b      ;; 118 firmware function: SCR VERTICAL
        defw $24bc      ;; 119 firmware function: CAS INITIALISE
        defw $24ce      ;; 120 firmware function: CAS SET SPEED
        defw $24e1      ;; 121 firmware function: CAS NOISY
        defw $2bbb      ;; 122 firmware function: CAS START MOTOR
        defw $2bbf      ;; 123 firmware function: CAS STOP MOTOR
        defw $2bc1      ;; 124 firmware function: CAS RESTORE MOTOR
        defw $24e5      ;; 125 firmware function: CAS IN OPEN
        defw $2550      ;; 126 firmware function: CAS IN CLOSE
        defw $2557      ;; 127 firmware function: CAS IN ABANDON
        defw $25a0      ;; 128 firmware function: CAS IN CHAR
        defw $2618      ;; 129 firmware function: CAS IN DIRECT
        defw $2607      ;; 130 firmware function: CAS RETURN
        defw $2603      ;; 131 firmware function: CAS TEST EOF
        defw $24fe      ;; 132 firmware function: CAS OUT OPEN
        defw $257f      ;; 133 firmware function: CAS OUT CLOSE
        defw $2599      ;; 134 firmware function: CAS OUT ABANDON
        defw $25c6      ;; 135 firmware function: CAS OUT CHAR
        defw $2653      ;; 136 firmware function: CAS OUT DIRECT
        defw $2692      ;; 137 firmware function: CAS CATALOG
        defw $29af      ;; 138 firmware function: CAS WRITE
        defw $29a6      ;; 139 firmware function: CAS READ
        defw $29c1      ;; 140 firmware function: CAS CHECK
        defw $1fe9      ;; 141 firmware function: SOUND RESET
        defw $2114      ;; 142 firmware function: SOUND QUEUE
        defw $21ce      ;; 143 firmware function: SOUND CHECK
        defw $21eb      ;; 144 firmware function: SOUND ARM EVENT
        defw $21ac      ;; 145 firmware function: SOUND RELEASE
        defw $2050      ;; 146 firmware function: SOUND HOLD
        defw $206b      ;; 147 firmware function: SOUND CONTINUE
        defw $2495      ;; 148 firmware function: SOUND AMPL ENVELOPE
        defw $249a      ;; 149 firmware function: SOUND TONE ENVELOPE
        defw $24a6      ;; 150 firmware function: SOUND A ADDRESS
        defw $24ab      ;; 151 firmware function: SOUND T ADDRESS
        defw $005c      ;; 152 firmware function: KL CHOKE OFF
        defw $0326      ;; 153 firmware function: KL ROM WALK
        defw $0330      ;; 154 firmware function: KL INIT BACK
        defw $02a0      ;; 155 firmware function: KL LOG EXT
        defw $02b1      ;; 156 firmware function: KL FIND COMMAND
        defw $0163      ;; 157 firmware function: KL NEW FRAME FLY
        defw $016a      ;; 158 firmware function: KL ADD FRAME FLY
        defw $0170      ;; 159 firmware function: KL DEL FRAME FLY
        defw $0176      ;; 160 firmware function: KL NEW FAST TICKER
        defw $017d      ;; 161 firmware function: KL ADD FAST TICKER
        defw $0183      ;; 162 firmware function: KL DEL FAST TICKER
        defw $01b3      ;; 163 firmware function: KL ADD TICKER
        defw $01c5      ;; 164 firmware function: KL DEL TICKER
        defw $01d2      ;; 165 firmware function: KL INIT EVENT
        defw $01e2      ;; 166 firmware function: KL EVENT
        defw $0227      ;; 167 firmware function: KL SYNC RESET
        defw $0284      ;; 168 firmware function: KL DEL SYNCHRONOUS
        defw $0255      ;; 169 firmware function: KL NEXT SYNC
        defw $0219      ;; 170 firmware function: KL DO SYNC
        defw $0276      ;; 171 firmware function: KL DONE SYNC
        defw $0294      ;; 172 firmware function: KL EVENT DISABLE
        defw $029a      ;; 173 firmware function: KL EVENT ENABLE
        defw $028d      ;; 174 firmware function: KL DISARM EVENT
        defw $0099      ;; 175 firmware function: KL TIME PLEASE
        defw $00a3      ;; 176 firmware function: KL TIME SET
        defw $05ed      ;; 177 firmware function: MC BOOT PROGRAM
        defw $061c      ;; 178 firmware function: MC START PROGRAM
        defw $07b4      ;; 179 firmware function: MC WAIT FLYBACK
        defw $0776      ;; 180 firmware function: MC SET MODE 
        defw $07c0      ;; 181 firmware function: MC SCREEN OFFSET
        defw $0786      ;; 182 firmware function: MC CLEAR INKS
        defw $078c      ;; 183 firmware function: MC SET INKS
        defw $07e0      ;; 184 firmware function: MC RESET PRINTER
        defw $081b      ;; 185 firmware function: MC PRINT CHAR
        defw $0858      ;; 186 firmware function: MC BUSY PRINTER
        defw $0844      ;; 187 firmware function: MC SEND PRINTER
        defw $0863      ;; 188 firmware function: MC SOUND REGISTER
        defw $08bd      ;; 189 firmware function: JUMP RESTORE
        defw $1d3c      ;; 190 firmware function: KM SET LOCKS
        defw $1bfe      ;; 191 firmware function: KM FLUSH
        defw $1460      ;; 192 firmware function: TXT ASK STATE
        defw $15ec      ;; 193 firmware function: GRA DEFAULT
        defw $19d5      ;; 194 firmware function: GRA SET BACK
        defw $17b0      ;; 195 firmware function: GRA SET FIRST
        defw $17ac      ;; 196 firmware function: GRA SET LINE MASK
        defw $162a      ;; 197 firmware function: GRA FROM USER
        defw $19d9      ;; 198 firmware function: GRA FILL
        defw $0b45      ;; 199 firmware function: SCR SET POSITION
        defw $080c      ;; 200 firmware function: MC PRINT TRANSLATION
        defw $0397      ;; 201 firmware function: KL BANK SWITCH
        defw $2c02      ;; 202 BD5E
        defw $2f91      ;; 0 BD61
        defw $2f9f      ;; 1 BD64
        defw $2fc8      ;; 2 BD67
        defw $2fd9      ;; 3 BD6A
        defw $3001      ;; 4 BD6D
        defw $3014      ;; 5 BD70
        defw $3055      ;; 6 BD73
        defw $305f      ;; 7 BD76
        defw $30c6      ;; 8 BD79
        defw $34a2      ;; 9 BD7C
        defw $3159      ;; 10 BD7F
        defw $349e      ;; 11 BD82
        defw $3577      ;; 12 BD85
        defw $3604      ;; 13 BD88
        defw $3188      ;; 14 BD8B
        defw $36df      ;; 15 BD8E
        defw $3731      ;; 16 BD91
        defw $3727      ;; 17 BD94
        defw $3345      ;; 18 BD97
        defw $2f73      ;; 19 BD9A
        defw $32ac      ;; 20 BD9D
        defw $32af      ;; 21 BDA0
        defw $31b6      ;; 22 BDA3
        defw $31b1      ;; 23 BDA6
        defw $322f      ;; 24 BDA9
        defw $3353      ;; 25 BDAC
        defw $3349      ;; 26 BDAF
        defw $33c8      ;; 27 BDB2
        defw $33d8      ;; 28 BDB5
        defw $2fd1      ;; 29 BDB8
        defw $3136      ;; 30 BDBB
        defw $3143      ;; 31 BDBE

;;==========================================================================
;; used to initialise the firmware indirections
;; this routine is called by each of the firmware "units"
;; i.e. screen pack, graphics pack etc.

;; HL = pointer to start of a table

;; table format:
;;
;; 0 = length of data 
;; 1,2 = destination to copy data
;; 3.. = data

L0ab4:  ld      c,(hl)
L0ab5:  ld      b,$00
L0ab7:  inc     hl
L0ab8:  ld      e,(hl)
L0ab9:  inc     hl
L0aba:  ld      d,(hl)
L0abb:  inc     hl
L0abc:  ldir    
L0abe:  ret     

;;==================================================================
;; SCISE

L0abf:  ld      de,$1052         ;; default colour palette
L0ac2:  call    L0786            ;; MC CLEAR INKS
L0ac5:  ld      a,$c0
L0ac7:  ld      ($b7c6),a
L0aca:  call    L0ad0            ;; SCR RESET
L0acd:  jp      L0b12

;;==================================================================
;; SC

L0ad0:  xor     a
L0ad1:  call    L0c55            ;; SCR ACCESS
L0ad4:  ld      hl,$0add         ;; table used to initialise screen indirections
L0ad7:  call    L0ab4            ;; initialise screen pack indirections
L0ada:  jp      L0cd8            ;; restore colours and set default flashing

L0add:  defb $09
        defw $bde5
L0ae0:  jp      L0c8a            ;; IND: SCR READ
L0ae3:  jp      L0c71            ;; IND: SCR WRITE
L0ae6:  jp      L0b17            ;; IND: SCR MODE CLEAR

;;==================================================================
;; SCE

L0ae9:  and     $03
L0aeb:  cp      $03
L0aed:  ret     nc

L0aee:  push    af
L0aef:  call    L0d55
L0af2:  pop     de
L0af3:  call    L10b3
L0af6:  push    af
L0af7:  call    L15ce
L0afa:  push    hl
L0afb:  ld      a,d
L0afc:  call    L0b31
L0aff:  call    $bdeb            ; IND: SCR MODE CLEAR
L0b02:  pop     hl
L0b03:  call    L15ae
L0b06:  pop     af
L0b07:  call    L10d1
L0b0a:  jr      L0b2e            ; (+$22)

;;==================================================================
;; SCE

L0b0c:  ld      a,($b7c3)
L0b0f:  cp      $01
L0b11:  ret     

L0b12:  ld      a,$01
L0b14:  call    L0b31

;;==================================================================
;; INDE CLEAR

L0b17:  call    L0d55
L0b1a:  ld      hl,$0000
L0b1d:  call    L0b37            ;; SCR OFFSET
L0b20:  ld      hl,($b7c5)
L0b23:  ld      l,$00
L0b25:  ld      d,h
L0b26:  ld      e,$01
L0b28:  ld      bc,$3fff
L0b2b:  ld      (hl),l
L0b2c:  ldir    
L0b2e:  jp      L0d42

;;==================================================================
L0b31:  ld      ($b7c3),a
L0b34:  jp      L0776            ; MC SET MODE

;;==================================================================
;; SC

L0b37:  ld      a,($b7c6)
L0b3a:  jr      L0b3f            ; (+$03)

;;==================================================================
;; SCE

L0b3c:  ld      hl,($b7c4)
L0b3f:  call    L0b45            ; SCR SET POSITION
L0b42:  jp      L07c0            ; MC SCREEN OFFSET

;;==================================================================
;; SCITION

L0b45:  and     $c0
L0b47:  ld      ($b7c6),a
L0b4a:  push    af
L0b4b:  ld      a,h
L0b4c:  and     $07
L0b4e:  ld      h,a
L0b4f:  res     0,l
L0b51:  ld      ($b7c4),hl
L0b54:  pop     af
L0b55:  ret     

;;==================================================================
;; SCATION

L0b56:  ld      hl,($b7c4)
L0b59:  ld      a,($b7c6)
L0b5c:  ret     

;;=============================================================================
;; SCMITS
L0b5d:  call    L0b0c            ;; SCR GET MODE
L0b60:  ld      bc,$1318         ;; B = 19, C = 24
L0b63:  ret     c

L0b64:  ld      b,$27            ;; 39
L0b66:  ret     z

L0b67:  ld      b,$4f            ;; 79
;; B -1
;; C -1
L0b69:  ret     

;;=============================================================================
;; SCSITION

L0b6a:  push    de
L0b6b:  call    L0b0c            ;; SCR GET MODE
L0b6e:  ld      b,$04
L0b70:  jr      c,L0b77          ; (+$05)
L0b72:  ld      b,$02
L0b74:  jr      z,L0b77          ; (+$01)
L0b76:  dec     b
L0b77:  push    bc
L0b78:  ld      e,h
L0b79:  ld      d,$00
L0b7b:  ld      h,d
L0b7c:  push    de
L0b7d:  ld      d,h
L0b7e:  ld      e,l
L0b7f:  add     hl,hl
L0b80:  add     hl,hl
L0b81:  add     hl,de
L0b82:  add     hl,hl
L0b83:  add     hl,hl
L0b84:  add     hl,hl
L0b85:  add     hl,hl
L0b86:  pop     de
L0b87:  add     hl,de
L0b88:  djnz    $0b87            ; (-$03)
L0b8a:  ld      de,($b7c4)
L0b8e:  add     hl,de
L0b8f:  ld      a,h
L0b90:  and     $07
L0b92:  ld      h,a
L0b93:  ld      a,($b7c6)
L0b96:  add     a,h
L0b97:  ld      h,a
L0b98:  pop     bc
L0b99:  pop     de
L0b9a:  ret     

L0b9b:  ld      a,e
L0b9c:  sub     l
L0b9d:  inc     a
L0b9e:  add     a,a
L0b9f:  add     a,a
L0ba0:  add     a,a
L0ba1:  ld      e,a
L0ba2:  ld      a,d
L0ba3:  sub     h
L0ba4:  inc     a
L0ba5:  ld      d,a
L0ba6:  call    L0b6a            ; SCR CHAR POSITION
L0ba9:  xor     a
L0baa:  add     a,d
L0bab:  djnz    $0baa            ; (-$03)
L0bad:  ld      d,a
L0bae:  ret     

;;=============================================================================
;; SCITION

L0baf:  push    de
L0bb0:  ex      de,hl
L0bb1:  ld      hl,$00c7
L0bb4:  or      a
L0bb5:  sbc     hl,de
L0bb7:  ld      a,l
L0bb8:  and     $07
L0bba:  add     a,a
L0bbb:  add     a,a
L0bbc:  add     a,a
L0bbd:  ld      c,a
L0bbe:  ld      a,l
L0bbf:  and     $f8
L0bc1:  ld      l,a
L0bc2:  ld      d,h
L0bc3:  ld      e,l
L0bc4:  add     hl,hl
L0bc5:  add     hl,hl
L0bc6:  add     hl,de
L0bc7:  add     hl,hl
L0bc8:  pop     de
L0bc9:  push    bc
L0bca:  call    L0bf6
L0bcd:  ld      a,b
L0bce:  and     e
L0bcf:  jr      z,L0bd6          ; (+$05)
L0bd1:  rrc     c
L0bd3:  dec     a
L0bd4:  jr      nz,L0bd1         ; (-$05)
L0bd6:  ex      (sp),hl
L0bd7:  ld      h,c
L0bd8:  ld      c,l
L0bd9:  ex      (sp),hl
L0bda:  ld      a,b
L0bdb:  rrca    
L0bdc:  srl     d
L0bde:  rr      e
L0be0:  rrca    
L0be1:  jr      c,L0bdc          ; (-$07)
L0be3:  add     hl,de
L0be4:  ld      de,($b7c4)
L0be8:  add     hl,de
L0be9:  ld      a,h
L0bea:  and     $07
L0bec:  ld      h,a
L0bed:  ld      a,($b7c6)
L0bf0:  add     a,h
L0bf1:  add     a,c
L0bf2:  ld      h,a
L0bf3:  pop     de
L0bf4:  ld      c,d
L0bf5:  ret     

;;------------------------------------------------------------
L0bf6:  call    L0b0c            ;; SCR GET MODE
L0bf9:  ld      bc,$01aa
L0bfc:  ret     c

L0bfd:  ld      bc,$0388 ; remove event from list
L0c00:  ret     z

L0c01:  ld      bc,$0780
L0c04:  ret     


;;------------------------------------------------------------
;; finction: SCR NEXT BYTE
;;
;; Entions:
;; HL address
;; Exions:
;; HLd screen address
;; AF
;;
;; As
;; - n

L0c05:  inc     l
L0c06:  ret     nz

L0c07:  inc     h
L0c08:  ld      a,h
L0c09:  and     $07
L0c0b:  ret     nz

;; atnt the address has incremented over a 2048
;; byry.
;;
;; Atnt, the next byte on screen is *not* previous byte plus 1.
;;
;; Thng is true:
;; 07
;; 0F
;; 17
;; 1F
;; 27
;; 2F
;; 37
;; 3F
;;
;; Thng code adjusts for this case.

L0c0c:  ld      a,h
L0c0d:  sub     $08
L0c0f:  ld      h,a
L0c10:  ret     

;;------------------------------------------------------------
;; finction: SCR PREV BYTE
;;
;; Entions:
;; HL address
;; Exions:
;; HLd screen address
;; AF
;;
;; As
;; - n

L0c11:  ld      a,l
L0c12:  dec     l
L0c13:  or      a
L0c14:  ret     nz

L0c15:  ld      a,h
L0c16:  dec     h
L0c17:  and     $07
L0c19:  ret     nz

L0c1a:  ld      a,h
L0c1b:  add     a,$08
L0c1d:  ld      h,a
L0c1e:  ret     

;;------------------------------------------------------------
;; finction: SCR NEXT LINE
;;
;; Entions:
;; HL address
;; Exions:
;; HLd screen address
;; AF
;;
;; As
;; - n
;; - per line (40 CRTC characters per line)

L0c1f:  ld      a,h
L0c20:  add     a,$08
L0c22:  ld      h,a


L0c23:  and     $38
L0c25:  ret     nz

;; 

L0c26:  ld      a,h
L0c27:  sub     $40
L0c29:  ld      h,a
L0c2a:  ld      a,l
L0c2b:  add     a,$50            ;; number of bytes per line
L0c2d:  ld      l,a
L0c2e:  ret     nc

L0c2f:  inc     h
L0c30:  ld      a,h
L0c31:  and     $07
L0c33:  ret     nz

L0c34:  ld      a,h
L0c35:  sub     $08
L0c37:  ld      h,a
L0c38:  ret     

;;------------------------------------------------------------
;; finction: SCR PREV LINE
;;
;; Entions:
;; HL address
;; Exions:
;; HLd screen address
;; AF
;;
;; As
;; - n
;; - per line (40 CRTC characters per line)

L0c39:  ld      a,h
L0c3a:  sub     $08
L0c3c:  ld      h,a
L0c3d:  and     $38
L0c3f:  cp      $38
L0c41:  ret     nz

L0c42:  ld      a,h
L0c43:  add     a,$40
L0c45:  ld      h,a

L0c46:  ld      a,l
L0c47:  sub     $50              ;; number of bytes per line
L0c49:  ld      l,a
L0c4a:  ret     nc

L0c4b:  ld      a,h
L0c4c:  dec     h
L0c4d:  and     $07
L0c4f:  ret     nz

L0c50:  ld      a,h
L0c51:  add     a,$08
L0c53:  ld      h,a
L0c54:  ret     


;;===================================================================
;; SC
;;
;; A ode:
;; 0 
;; 1 
;; 2 
;; 3 
L0c55:  and     $03
L0c57:  ld      hl,$0c74         ; SCR PIXELS
L0c5a:  jr      z,L0c68          ; (+$0c)
L0c5c:  cp      $02
L0c5e:  ld      l,$7a
L0c60:  jr      c,L0c68          ; (+$06)
L0c62:  ld      l,$7f
L0c64:  jr      z,L0c68          ; (+$02)
L0c66:  ld      l,$85
;; HLs of screen write function 
;; injump for IND: SCR WRITE
L0c68:  ld      a,$c3
L0c6a:  ld      ($b7c7),a
L0c6d:  ld      ($b7c8),hl
L0c70:  ret     

;;=========================================================================
;; INITE

;; julised by SCR ACCESS
L0c71:  jp      $b7c7


;;===================================================================
;; SC
;; (w fill)
L0c74:  ld      a,b
L0c75:  xor     (hl)
L0c76:  and     c
L0c77:  xor     (hl)
L0c78:  ld      (hl),a
L0c79:  ret     

;;-------------------------------------------------------------------
;; sce access mode

;; (w XOR)
L0c7a:  ld      a,b
L0c7b:  and     c
L0c7c:  xor     (hl)
L0c7d:  ld      (hl),a
L0c7e:  ret     

;;-------------------------------------------------------------------
;; sce access mode
;;
;; (w AND)
L0c7f:  ld      a,c
L0c80:  cpl     
L0c81:  or      b
L0c82:  and     (hl)
L0c83:  ld      (hl),a
L0c84:  ret     

;;-------------------------------------------------------------------
;; sce access mode
;;
;; (w OR)
L0c85:  ld      a,b
L0c86:  and     c
L0c87:  or      (hl)
L0c88:  ld      (hl),a
L0c89:  ret     

;;=========================================================================
;; INAD
L0c8a:  ld      a,(hl)
L0c8b:  jp      L0cb2

;;=========================================================================
;; SCODE
L0c8e:  push    bc
L0c8f:  push    de
L0c90:  call    L0cc8
L0c93:  ld      e,a
L0c94:  call    L0bf6
L0c97:  ld      b,$08
L0c99:  rrc     e
L0c9b:  rla     
L0c9c:  rrc     c
L0c9e:  jr      c,L0ca2          ; (+$02)
L0ca0:  rlc     e
L0ca2:  djnz    $0c99            ; (-$0b)
L0ca4:  pop     de
L0ca5:  pop     bc
L0ca6:  ret     

;;===================================================================
;; SCODE

L0ca7:  push    bc
L0ca8:  push    af
L0ca9:  call    L0bf6
L0cac:  pop     af
L0cad:  call    L0cb2
L0cb0:  pop     bc
L0cb1:  ret     

;;--------------------------------------------------------------------

L0cb2:  push    de
L0cb3:  ld      de,$0008
L0cb6:  rrca    
L0cb7:  rl      d
L0cb9:  rrc     c
L0cbb:  jr      c,L0cbf          ; (+$02)
L0cbd:  rr      d
L0cbf:  dec     e
L0cc0:  jr      nz,L0cb6         ; (-$0c)
L0cc2:  ld      a,d
L0cc3:  call    L0cc8
L0cc6:  pop     de
L0cc7:  ret     

;;--------------------------------------------------------------------
L0cc8:  ld      d,a
L0cc9:  call    L0b0c            ;; SCR GET MODE
L0ccc:  ld      a,d
L0ccd:  ret     nc
L0cce:  rrca    
L0ccf:  rrca    
L0cd0:  adc     a,$00
L0cd2:  rrca    
L0cd3:  sbc     a,a
L0cd4:  and     $06
L0cd6:  xor     d
L0cd7:  ret     

;;--------------------------------------------------------------------

;; reours and set default flashing
L0cd8:  ld      hl,$1052                 ;; default colour palette
L0cdb:  ld      de,$b7d4
L0cde:  ld      bc,$0022
L0ce1:  ldir    
L0ce3:  xor     a
L0ce4:  ld      ($b7f6),a
L0ce7:  ld      hl,$0a0a

;;===================================================================
;; SCSHING

L0cea:  ld      ($b7d2),hl
L0ced:  ret     


;;===================================================================
;; SCSHING

L0cee:  ld      hl,($b7d2)
L0cf1:  ret     

;;===================================================================
;; SC
L0cf2:  and     $0f              ; keep pen within 0-15 range
L0cf4:  inc     a                
L0cf5:  jr      L0cf8

;;===================================================================
;; SCDER
L0cf7:  xor     a
;;-------------------------------------------------------------------
;; SC/SCR SET BORDER
;;
;; A l pen number
;; B firmware colour number)
;; C firmware colour number)
;; 0 
;; 1 0
;; 2 1
;; ..
;; 16 15
L0cf8:  ld      e,a

L0cf9:  ld      a,b
L0cfa:  call    L0d10        ; lookup address of hardware colour number in conversion
                           ; table using software colour number
                           
L0cfd:  ld      b,(hl)       ; get hardware colour number for ink 1

L0cfe:  ld      a,c
L0cff:  call    L0d10        ; lookup address of hardware colour number in conversion
                           ; table using software colour number
                           
L0d02:  ld      c,(hl)       ; get hardware colour number for ink 2

L0d03:  ld      a,e
L0d04:  call    L0d35        ; get address of pen in both palette's in RAM

L0d07:  ld      (hl),c       ; write ink 2
L0d08:  ex      de,hl
L0d09:  ld      (hl),b       ; write ink 1

L0d0a:  ld      a,$ff
L0d0c:  ld      ($b7f7),a
L0d0f:  ret     

;;===================================================================
;; in
;; A e colour number
;; ou
;; HLs of element in table. Element is corresponding hardware colour number.
L0d10:  and     $1f
L0d12:  add     a,$99
L0d14:  ld      l,a
L0d15:  adc     a,$0d
L0d17:  sub     l
L0d18:  ld      h,a
L0d19:  ret     

;;===================================================================
;; SC
L0d1a:  and     $0f            ; keep pen within range 0-15.
L0d1c:  inc     a
L0d1d:  jr      L0d20           

;;===================================================================
;; SCDER

L0d1f:  xor     a
;;-------------------------------------------------------------------
;; SC/SCR GET BORDER
;; en
;; A l pen number
;; 0 
;; 1 0
;; 2 1
;; ..
;; 16 15
;; ex
;; B software colour number)
;; C software colour number)
L0d20:  call    L0d35            ; get address of pen in both palette's in RAM
L0d23:  ld      a,(de)           ; ink 2

L0d24:  ld      e,(hl)           ; ink 1

L0d25:  call    L0d2a            ; lookup hardware colour number for ink 2
L0d28:  ld      b,c

;; loware colour number for ink 1
L0d29:  ld      a,e

;;-------------------------------------------------------------------
;; loware colour number which corresponds to the hardware colour number

;; en
;; A e colour number
;; ex
;; C n table (same as software colour number)
L0d2a:  ld      c,$00
L0d2c:  ld      hl,$0d99         ; table to convert from software colour
                               ; number to hardware colour number
;;---
L0d2f:  cp      (hl)             ; same as this entry in the table?
L0d30:  ret     z                ; zero set if entry is the same, zero clear if entry is different
L0d31:  inc     hl
L0d32:  inc     c
L0d33:  jr      L0d2f

;;===================================================================
;;
;; The stores two palette's in RAM, this allows a pen to have a flashing ink.
;;
;; ge of palette entry for corresponding ink for both palettes in RAM.
;;
;; en
;; A ber
;; 0 
;; 1 0
;; 2 1
;; ..
;; 16 15
;; 
;; ex
;; HLs of element in palette 2
;; DEs of element in palette 1
L0d35:  ld      e,a
L0d36:  ld      d,$00
L0d38:  ld      hl,$b7e5         ; palette 2 start
L0d3b:  add     hl,de
L0d3c:  ex      de,hl
L0d3d:  ld      hl,$ffef         ; palette 1 start (B7D4)
L0d40:  add     hl,de
L0d41:  ret     
;;===================================================================

L0d42:  ld      hl,$b7f9
L0d45:  push    hl
L0d46:  call    L0170            ; KL DEL FRAME FLY
L0d49:  call    L0d73
L0d4c:  ld      de,$0d61
L0d4f:  ld      b,$81
L0d51:  pop     hl
L0d52:  jp      L0163            ; KL NEW FRAME FLY

;;=========================================================================
L0d55:  ld      hl,$b7f9
L0d58:  call    L0170            ; KL DEL FRAME FLY
L0d5b:  call    L0d87
L0d5e:  jp      L0786            ; MC CLEAR INKS

;;------------------------------------------------
;; frck routine for changing colours
L0d61:  ld      hl,$b7f8
L0d64:  dec     (hl)
L0d65:  jr      z,L0d73          ; (+$0c)
L0d67:  dec     hl
L0d68:  ld      a,(hl)
L0d69:  or      a
L0d6a:  ret     z

L0d6b:  call    L0d87
L0d6e:  call    L078c            ; MC SET INKS
L0d71:  jr      L0d82            ; (+$0f)
;;=========================================================================

L0d73:  call    L0d87
L0d76:  ld      ($b7f8),a
L0d79:  call    L078c            ; MC SET INKS
L0d7c:  ld      hl,$b7f6
L0d7f:  ld      a,(hl)
L0d80:  cpl     
L0d81:  ld      (hl),a
L0d82:  xor     a
L0d83:  ld      ($b7f7),a
L0d86:  ret     

;;==================================================================

L0d87:  ld      de,$b7e5
L0d8a:  ld      a,($b7f6)
L0d8d:  or      a
L0d8e:  ld      a,($b7d3)
L0d91:  ret     z

;;==================================================================

L0d92:  ld      de,$b7d4
L0d95:  ld      a,($b7d2)
L0d98:  ret     

;;---------------------------------------------------------------------------
;; table to convert from software colour number to hardware colour number
L0d99:  defb $14,$04,$15,$1c,$18,$1d,$0c,$05,$0d,$16,$06,$17,$1e,$00,$1f,$0e,$07,$0f
        defb $12,$02,$13,$1a,$19,$1b,$0a,$03,$0b,$01,$08,$09,$10,$11

;;============================================================================
;; SCR FILL BOX

L0db9:  ld      c,a
L0dba:  call    L0b9b


;;===================================================================
;; SCOX

L0dbd:  push    hl
L0dbe:  ld      a,d
L0dbf:  call    L0eee
L0dc2:  jr      nc,L0dcd         ; (+$09)
L0dc4:  ld      b,d
L0dc5:  ld      (hl),c
L0dc6:  call    L0c05            ; SCR NEXT BYTE
L0dc9:  djnz    $0dc5            ; (-$06)
L0dcb:  jr      L0ddd            ; (+$10)
L0dcd:  push    bc
L0dce:  push    de
L0dcf:  ld      (hl),c
L0dd0:  dec     d
L0dd1:  jr      z,L0ddb          ; (+$08)
L0dd3:  ld      c,d
L0dd4:  ld      b,$00
L0dd6:  ld      d,h
L0dd7:  ld      e,l
L0dd8:  inc     de
L0dd9:  ldir    
L0ddb:  pop     de
L0ddc:  pop     bc
L0ddd:  pop     hl
L0dde:  call    L0c1f            ; SCR NEXT LINE
L0de1:  dec     e
L0de2:  jr      nz,L0dbd         ; (-$27)
L0de4:  ret     


;;===================================================================
;; SCVERT

L0de5:  ld      a,b
L0de6:  xor     c
L0de7:  ld      c,a
L0de8:  call    L0b6a            ; SCR CHAR POSITION
L0deb:  ld      d,$08
L0ded:  push    hl
L0dee:  push    bc
L0def:  ld      a,(hl)
L0df0:  xor     c
L0df1:  ld      (hl),a
L0df2:  call    L0c05            ; SCR NEXT BYTE
L0df5:  djnz    $0def            ; (-$08)
L0df7:  pop     bc
L0df8:  pop     hl
L0df9:  call    L0c1f            ; SCR NEXT LINE
L0dfc:  dec     d
L0dfd:  jr      nz,L0ded         ; (-$12)
L0dff:  ret     


;;===================================================================
;; SC
L0e00:  ld      c,a
L0e01:  push    bc
L0e02:  ld      de,$ffd0
L0e05:  ld      b,$30
L0e07:  call    L0e2a
L0e0a:  pop     bc
L0e0b:  call    L07b4            ; MC WAIT FLYBACK
L0e0e:  ld      a,b
L0e0f:  or      a
L0e10:  jr      nz,L0e1f         ; (+$0d)
L0e12:  ld      de,$ffb0
L0e15:  call    L0e3d
L0e18:  ld      de,$0000
L0e1b:  ld      b,$20
L0e1d:  jr      L0e2a            ; (+$0b)
L0e1f:  ld      de,$0050
L0e22:  call    L0e3d
L0e25:  ld      de,$ffb0
L0e28:  ld      b,$20
L0e2a:  ld      hl,($b7c4)
L0e2d:  add     hl,de
L0e2e:  ld      a,h
L0e2f:  and     $07
L0e31:  ld      h,a
L0e32:  ld      a,($b7c6)
L0e35:  add     a,h
L0e36:  ld      h,a
L0e37:  ld      d,b
L0e38:  ld      e,$08
L0e3a:  jp      L0dbd            ;; SCR FLOOD BOX
L0e3d:  ld      hl,($b7c4)
L0e40:  add     hl,de
L0e41:  jp      L0b37            ;; SCR OFFSET


;;===================================================================
;; SC

L0e44:  push    af
L0e45:  ld      a,b
L0e46:  or      a
L0e47:  jr      z,L0e79          ; (+$30)
L0e49:  push    hl
L0e4a:  call    L0b9b
L0e4d:  ex      (sp),hl
L0e4e:  inc     l
L0e4f:  call    L0b6a            ; SCR CHAR POSITION
L0e52:  ld      c,d
L0e53:  ld      a,e
L0e54:  sub     $08
L0e56:  ld      b,a
L0e57:  jr      z,L0e70          ; (+$17)
L0e59:  pop     de
L0e5a:  call    L07b4            ; MC WAIT FLYBACK
L0e5d:  push    bc
L0e5e:  push    hl
L0e5f:  push    de
L0e60:  call    L0eaa
L0e63:  pop     hl
L0e64:  call    L0c1f            ; SCR NEXT LINE
L0e67:  ex      de,hl
L0e68:  pop     hl
L0e69:  call    L0c1f            ; SCR NEXT LINE
L0e6c:  pop     bc
L0e6d:  djnz    $0e5d            ; (-$12)
L0e6f:  push    de
L0e70:  pop     hl
L0e71:  ld      d,c
L0e72:  ld      e,$08
L0e74:  pop     af
L0e75:  ld      c,a
L0e76:  jp      L0dbd            ;; SCR FLOOD BOX
L0e79:  push    hl
L0e7a:  push    de
L0e7b:  call    L0b9b
L0e7e:  ld      c,d
L0e7f:  ld      a,e
L0e80:  sub     $08
L0e82:  ld      b,a
L0e83:  pop     de
L0e84:  ex      (sp),hl
L0e85:  jr      z,L0e70          ; (-$17)
L0e87:  push    bc
L0e88:  ld      l,e
L0e89:  ld      d,h
L0e8a:  inc     e
L0e8b:  call    L0b6a            ; SCR CHAR POSITION
L0e8e:  ex      de,hl
L0e8f:  call    L0b6a            ; SCR CHAR POSITION
L0e92:  pop     bc
L0e93:  call    L07b4            ; MC WAIT FLYBACK
L0e96:  call    L0c39            ; SCR PREV LINE
L0e99:  push    hl
L0e9a:  ex      de,hl
L0e9b:  call    L0c39            ; SCR PREV LINE
L0e9e:  push    hl
L0e9f:  push    bc
L0ea0:  call    L0eaa
L0ea3:  pop     bc
L0ea4:  pop     de
L0ea5:  pop     hl
L0ea6:  djnz    $0e96            ; (-$12)
L0ea8:  jr      L0e70            ; (-$3a)
L0eaa:  ld      b,$00
L0eac:  call    L0eec
L0eaf:  jr      c,L0ec7          ; (+$16)
L0eb1:  call    L0eec
L0eb4:  jr      nc,L0edb         ; (+$25)
L0eb6:  push    bc
L0eb7:  xor     a
L0eb8:  sub     l
L0eb9:  ld      c,a
L0eba:  ldir    
L0ebc:  pop     bc
L0ebd:  cpl     
L0ebe:  inc     a
L0ebf:  add     a,c
L0ec0:  ld      c,a
L0ec1:  ld      a,h
L0ec2:  sub     $08
L0ec4:  ld      h,a
L0ec5:  jr      L0edb            ; (+$14)
L0ec7:  call    L0eec
L0eca:  jr      c,L0ede          ; (+$12)
L0ecc:  push    bc
L0ecd:  xor     a
L0ece:  sub     e
L0ecf:  ld      c,a
L0ed0:  ldir    
L0ed2:  pop     bc
L0ed3:  cpl     
L0ed4:  inc     a
L0ed5:  add     a,c
L0ed6:  ld      c,a
L0ed7:  ld      a,d
L0ed8:  sub     $08
L0eda:  ld      d,a
L0edb:  ldir    
L0edd:  ret     

L0ede:  ld      b,c
L0edf:  ld      a,(hl)
L0ee0:  ld      (de),a
L0ee1:  call    L0c05            ; SCR NEXT BYTE
L0ee4:  ex      de,hl
L0ee5:  call    L0c05            ; SCR NEXT BYTE
L0ee8:  ex      de,hl
L0ee9:  djnz    $0edf            
L0eeb:  ret     

;;===================================================================
L0eec:  ld      a,c
L0eed:  ex      de,hl
L0eee:  dec     a
L0eef:  add     a,l
L0ef0:  ret     nc

L0ef1:  ld      a,h
L0ef2:  and     $07
L0ef4:  xor     $07
L0ef6:  ret     nz

L0ef7:  scf     
L0ef8:  ret     


;;===================================================================
;; SC

L0ef9:  call    L0b0c            ;; SCR GET MODE 
L0efc:  jr      c,L0f0b          ; mode 0
L0efe:  jr      z,L0f06          ; mode 1
L0f00:  ld      bc,$0008
L0f03:  ldir    
L0f05:  ret     

;;--------------------------------------------------------------------
;; SC mode 1
L0f06:  ld      bc,$0288
L0f09:  jr      L0f0e            ; 0x088 is the pixel mask

;;--------------------------------------------------------------------
;; SC mode 0
L0f0b:  ld      bc,$04aa         ;; 0x0aa is the pixel mask

;;--------------------------------------------------------------------
;; rod by mode 0 and mode 1 for SCR UNPACK
L0f0e:  ld      a,$08
L0f10:  push    af
L0f11:  push    hl
L0f12:  ld      l,(hl)
L0f13:  ld      h,b
L0f14:  xor     a
L0f15:  rlc     l
L0f17:  jr      nc,L0f1a         ; (+$01)
L0f19:  or      c
L0f1a:  rrc     c
L0f1c:  jr      nc,L0f15         ; (-$09)
L0f1e:  ld      (de),a
L0f1f:  inc     de
L0f20:  djnz    $0f14            ; (-$0e)
L0f22:  ld      b,h
L0f23:  pop     hl
L0f24:  inc     hl
L0f25:  pop     af
L0f26:  dec     a
L0f27:  jr      nz,L0f10         ; (-$19)
L0f29:  ret     


;;===================================================================
;; SC

L0f2a:  ld      c,a
L0f2b:  call    L0b6a            ; SCR CHAR POSITION
L0f2e:  call    L0b0c            ; SCR GET MODE
L0f31:  ld      b,$08
L0f33:  jr      c,L0f6b          ; mode 0
L0f35:  jr      z,L0f42          ; mode 1

;;-------------------------------------------------------------------------------
;; SC mode 2
L0f37:  ld      a,(hl)
L0f38:  xor     c
L0f39:  cpl     
L0f3a:  ld      (de),a
L0f3b:  inc     de
L0f3c:  call    L0c1f            ; SCR NEXT LINE
L0f3f:  djnz    $0f37            
L0f41:  ret     

;;-------------------------------------------------------------------------------
;; SC mode 1
L0f42:  push    bc
L0f43:  push    hl
L0f44:  push    de
L0f45:  call    L0f5a      ; mode 1
L0f48:  call    L0c05            ; SCR NEXT BYTE
L0f4b:  call    L0f5a      ; mode 1
L0f4e:  ld      a,e
L0f4f:  pop     de
L0f50:  ld      (de),a
L0f51:  inc     de
L0f52:  pop     hl
L0f53:  call    L0c1f            ; SCR NEXT LINE
L0f56:  pop     bc
L0f57:  djnz    $0f42            
L0f59:  ret     

;;-------------------------------------------------------------------------------
;; SC mode 1 (part)
L0f5a:  ld      d,$88        ; pixel mask
L0f5c:  ld      b,$04
L0f5e:  ld      a,(hl)
L0f5f:  xor     c
L0f60:  and     d
L0f61:  jr      nz,L0f64         ; (+$01)
L0f63:  scf     
L0f64:  rl      e
L0f66:  rrc     d
L0f68:  djnz    $0f5e            
L0f6a:  ret     

;;-------------------------------------------------------------------------------
;; SC mode 0
L0f6b:  push    bc
L0f6c:  push    hl
L0f6d:  push    de

L0f6e:  ld      b,$04
L0f70:  ld      a,(hl)
L0f71:  xor     c
L0f72:  and     $aa            ; left pixel mask
L0f74:  jr      nz,L0f77        
L0f76:  scf     
L0f77:  rl      e
L0f79:  ld      a,(hl)
L0f7a:  xor     c
L0f7b:  and     $55            ; right pixel mask
L0f7d:  jr      nz,L0f80        
L0f7f:  scf     
L0f80:  rl      e
L0f82:  call    L0c05            ; SCR NEXT BYTE
L0f85:  djnz    $0f70            

L0f87:  ld      a,e
L0f88:  pop     de
L0f89:  ld      (de),a
L0f8a:  inc     de
L0f8b:  pop     hl
L0f8c:  call    L0c1f            ; SCR NEXT LINE
L0f8f:  pop     bc
L0f90:  djnz    $0f6b           
L0f92:  ret     


;;===================================================================
;; SOVENT
L0f93:  call    L0fad
L0f96:  call    L0fc2
L0f99:  jr      L0fa1            ; (+$06)


;;===================================================================
;; SCL

L0f9b:  call    L0fad
L0f9e:  call    L1016
L0fa1:  ld      hl,($b802)
L0fa4:  ld      a,l
L0fa5:  ld      ($b6a3),a        ; graphics pen
L0fa8:  ld      a,h
L0fa9:  ld      ($b6b3),a        ; graphics line mask
L0fac:  ret     

;;===================================================================

L0fad:  push    hl
L0fae:  ld      hl,($b6a3)       ; L = graphics pen, H = graphics paper
L0fb1:  ld      ($b6a3),a        ; graphics pen
L0fb4:  ld      a,($b6b3)        ; graphics line mask
L0fb7:  ld      h,a
L0fb8:  ld      a,$ff
L0fba:  ld      ($b6b3),a        ; graphics line mask
L0fbd:  ld      ($b802),hl
L0fc0:  pop     hl
L0fc1:  ret     

L0fc2:  scf     
L0fc3:  call    L103b
L0fc6:  rlc     b
L0fc8:  ld      a,c
L0fc9:  jr      nc,L0fde         ; (+$13)
L0fcb:  dec     e
L0fcc:  jr      nz,L0fd1         ; (+$03)
L0fce:  dec     d
L0fcf:  jr      z,L0ffd          ; (+$2c)
L0fd1:  rrc     c
L0fd3:  jr      c,L0ffd          ; (+$28)
L0fd5:  bit     7,b
L0fd7:  jr      z,L0ffd          ; (+$24)
L0fd9:  or      c
L0fda:  rlc     b
L0fdc:  jr      L0fcb            ; (-$13)
L0fde:  dec     e
L0fdf:  jr      nz,L0fe4         ; (+$03)
L0fe1:  dec     d
L0fe2:  jr      z,L0ff1          ; (+$0d)
L0fe4:  rrc     c
L0fe6:  jr      c,L0ff1          ; (+$09)
L0fe8:  bit     7,b
L0fea:  jr      nz,L0ff1         ; (+$05)
L0fec:  or      c
L0fed:  rlc     b
L0fef:  jr      L0fde            ; (-$13)
L0ff1:  push    bc
L0ff2:  ld      c,a
L0ff3:  ld      a,($b6a4)        ; graphics paper
L0ff6:  ld      b,a
L0ff7:  ld      a,($b6b4)
L0ffa:  or      a
L0ffb:  jr      L1004            ; (+$07)
L0ffd:  push    bc
L0ffe:  ld      c,a
L0fff:  ld      a,($b6a3)        ; graphics pen
L1002:  ld      b,a
L1003:  xor     a
L1004:  call    z,$bde8          ; IND: SCR WRITE
L1007:  pop     bc
L1008:  bit     7,c
L100a:  call    nz,L0c05         ; SCR NEXT BYTE
L100d:  ld      a,d
L100e:  or      e
L100f:  jr      nz,L0fc6         ; (-$4b)
L1011:  ld      a,b
L1012:  ld      ($b6b3),a        ; graphics line mask
L1015:  ret     

L1016:  or      a
L1017:  call    L103b
L101a:  rlc     b
L101c:  ld      a,($b6a3)        ; graphics pen
L101f:  jr      c,L102a          ; (+$09)
L1021:  ld      a,($b6b4)
L1024:  or      a
L1025:  jr      nz,L1030         ; (+$09)
L1027:  ld      a,($b6a4)        ; graphics paper
L102a:  push    bc
L102b:  ld      b,a
L102c:  call    $bde8            ; IND: SCR WRITE
L102f:  pop     bc
L1030:  call    L0c39            ; SCR PREV LINE
L1033:  dec     e
L1034:  jr      nz,L101a         ; (-$1c)
L1036:  dec     d
L1037:  jr      nz,L101a         ; (-$1f)
L1039:  jr      L1011            ; (-$2a)
L103b:  push    hl
L103c:  jr      nc,L1040         ; (+$02)
L103e:  ld      h,d
L103f:  ld      l,e
L1040:  or      a
L1041:  sbc     hl,bc
L1043:  call    L1939            ; HL = -HL
L1046:  inc     h
L1047:  inc     l
L1048:  ex      (sp),hl
L1049:  call    L0baf            ; SCR DOT POSITION
L104c:  ld      a,($b6b3)        ; graphics line mask
L104f:  ld      b,a
L1050:  pop     de
L1051:  ret     

;;---------------------------------------------------------------------------
;; default colour palette
;; uses hardware colour numbers
;; 
;; There are two palettes here; so that flashing colours can be defined.
L1052:  defb $04,$04,$0a,$13,$0c,$0b,$14,$15,$0d,$06,$1e,$1f,$07,$12,$19,$04,$17
        defb $04,$04,$0a,$13,$0c,$0b,$14,$15,$0d,$06,$1e,$1f,$07,$12,$19,$0a,$07

;;===========================================================================
;; TXT INITIALISE

L1074:  call    L1084            ;; TXT RESET
L1077:  xor     a
L1078:  ld      ($b735),a
L107b:  ld      hl,$0001
L107e:  call    L1139
L1081:  jp      L109f

;;==================================================================
;; TX

L1084:  ld      hl,$108d         ;; table used to initialise text vdu indirections
L1087:  call    L0ab4            ;; initialise text vdu indirections
L108a:  jp      L1464            ;; initialise control code handler functions

L108d:  defb $f
        defw $bdcd
        jp      L125f                           ;; IND: TXT DRAW CURSOR
        jp      L125f                           ;; IND: TXT UNDRAW CURSOR
        jp      L134b                           ;; IND: TXT WRITE CHAR
        jp      L13be                           ;; IND: TXT UNWRITE
        jp      L140a                           ;; IND: TXT OUT ACTION


;;==================================================================

L109f:  ld      a,$08
L10a1:  ld      de,$b6b6
L10a4:  ld      hl,$b726
L10a7:  ld      bc,$000e
L10aa:  ldir    
L10ac:  dec     a
L10ad:  jr      nz,L10a4         ; (-$0b)
L10af:  ld      ($b6b5),a
L10b2:  ret     
;;=========================================================================

L10b3:  ld      a,($b6b5)
L10b6:  ld      c,a
L10b7:  ld      b,$08

L10b9:  ld      a,b
L10ba:  dec     a
L10bb:  call    L10e4            ; TXT STR SELECT
L10be:  call    $bdd0            ; IND: TXT UNDRAW CURSOR
L10c1:  call    L12c0            ; TXT GET PAPER
L10c4:  ld      ($b730),a
L10c7:  call    L12ba            ; TXT GET PEN
L10ca:  ld      ($b72f),a
L10cd:  djnz    $10b9            ; (-$16)
L10cf:  ld      a,c
L10d0:  ret     

;;=========================================================================
L10d1:  ld      c,a
L10d2:  ld      b,$08
L10d4:  ld      a,b
L10d5:  dec     a
L10d6:  call    L10e4            ; TXT STR SELECT
L10d9:  push    bc
L10da:  ld      hl,($b72f)
L10dd:  call    L1139
L10e0:  pop     bc
L10e1:  djnz    $10d4            ; (-$0f)
L10e3:  ld      a,c

;;=========================================================================
;; TXECT
L10e4:  and     $07
L10e6:  ld      hl,$b6b5
L10e9:  cp      (hl)
L10ea:  ret     z

L10eb:  push    bc
L10ec:  push    de
L10ed:  ld      c,(hl)
L10ee:  ld      (hl),a
L10ef:  ld      b,a
L10f0:  ld      a,c
L10f1:  call    L1126
L10f4:  call    L111e
L10f7:  ld      a,b
L10f8:  call    L1126
L10fb:  ex      de,hl
L10fc:  call    L111e
L10ff:  ld      a,c
L1100:  pop     de
L1101:  pop     bc
L1102:  ret     

;;==================================================================
;; TXREAMS
L1103:  ld      a,($b6b5)
L1106:  push    af
L1107:  ld      a,c
L1108:  call    L10e4
L110b:  ld      a,b
L110c:  ld      ($b6b5),a
L110f:  call    L1126
L1112:  push    de
L1113:  ld      a,c
L1114:  call    L1126
L1117:  pop     hl
L1118:  call    L111e
L111b:  pop     af
L111c:  jr      L10e4            ; (-$3a)
;;==================================================================
L111e:  push    bc
L111f:  ld      bc,$000e
L1122:  ldir    
L1124:  pop     bc
L1125:  ret     

;;==================================================================
L1126:  and     $07
L1128:  ld      e,a
L1129:  add     a,a
L112a:  add     a,e
L112b:  add     a,a
L112c:  add     a,e
L112d:  add     a,a
L112e:  add     a,$b6
L1130:  ld      e,a
L1131:  adc     a,$b6
L1133:  sub     e
L1134:  ld      d,a
L1135:  ld      hl,$b726
L1138:  ret     

;;==================================================================
L1139:  ex      de,hl
L113a:  ld      a,$83
L113c:  ld      ($b72e),a
L113f:  ld      a,d
L1140:  call    L12ab            ; TXT SET PAPER
L1143:  ld      a,e
L1144:  call    L12a6            ; TXT SET PEN
L1147:  xor     a
L1148:  call    L13a8            ; TXT SET GRAPHIC
L114b:  call    L137b            ; TXT SET BACK
L114e:  ld      hl,$0000
L1151:  ld      de,$7f7f
L1154:  call    L1208            ; TXT WIN ENABLE
L1157:  jp      L1459            ; TXT VDU ENABLE

;;==================================================================
;; TXUMN

L115a:  dec     a
L115b:  ld      hl,$b72a
L115e:  add     a,(hl)
L115f:  ld      hl,($b726)
L1162:  ld      h,a
L1163:  jr      L1173            ;; undraw cursor, set cursor position and draw it

;;==================================================================
;; TX

L1165:  dec     a
L1166:  ld      hl,$b729
L1169:  add     a,(hl)
L116a:  ld      hl,($b726)
L116d:  ld      l,a
L116e:  jr      L1173            ;; undraw cursor, set cursor position and draw it

;;==================================================================
;; TXSOR

L1170:  call    L1186

;; unor, set cursor position and draw it
L1173:  call    $bdd0            ; IND: TXT UNDRAW CURSOR

;; seposition and draw it
L1176:  ld      ($b726),hl
L1179:  jp      $bdcd            ; IND: TXT DRAW CURSOR

;;==================================================================
;; TXSOR

L117c:  ld      hl,($b726)
L117f:  call    L1193
L1182:  ld      a,($b72d)
L1185:  ret     

;;==================================================================
L1186:  ld      a,($b729)
L1189:  dec     a
L118a:  add     a,l
L118b:  ld      l,a
L118c:  ld      a,($b72a)
L118f:  dec     a
L1190:  add     a,h
L1191:  ld      h,a
L1192:  ret     

;;===========================================================
L1193:  ld      a,($b729)
L1196:  sub     l
L1197:  cpl     
L1198:  inc     a
L1199:  inc     a
L119a:  ld      l,a
L119b:  ld      a,($b72a)
L119e:  sub     h
L119f:  cpl     
L11a0:  inc     a
L11a1:  inc     a
L11a2:  ld      h,a
L11a3:  ret     

;;===========================================================
L11a4:  call    $bdd0                ;; IND: TXT UNDRAW CURSOR

;;-----------------------------------------------------------
L11a7:  ld      hl,($b726)
L11aa:  call    L11d6
L11ad:  ld      ($b726),hl
L11b0:  ret     c

L11b1:  push    hl
L11b2:  ld      hl,$b72d
L11b5:  ld      a,b
L11b6:  add     a,a
L11b7:  inc     a
L11b8:  add     a,(hl)
L11b9:  ld      (hl),a
L11ba:  call    L1252                ;; TXT GET WINDOW
L11bd:  ld      a,($b730)
L11c0:  push    af
L11c1:  call    c,L0e44              ;; SCR SW ROLL
L11c4:  pop     af
L11c5:  call    nc,L0e00             ;; SCR HW ROLL
L11c8:  pop     hl
L11c9:  ret     


;;==================================================================
;; TXE

L11ca:  call    L1186
L11cd:  call    L11d6
L11d0:  push    af
L11d1:  call    L1193
L11d4:  pop     af
L11d5:  ret     
;;==================================================================
L11d6:  ld      a,($b72c)
L11d9:  cp      h
L11da:  jp      p,L11e2
L11dd:  ld      a,($b72a)
L11e0:  ld      h,a
L11e1:  inc     l
L11e2:  ld      a,($b72a)
L11e5:  dec     a
L11e6:  cp      h
L11e7:  jp      m,L11ef
L11ea:  ld      a,($b72c)
L11ed:  ld      h,a
L11ee:  dec     l
L11ef:  ld      a,($b729)
L11f2:  dec     a
L11f3:  cp      l
L11f4:  jp      p,L1202
L11f7:  ld      a,($b72b)
L11fa:  cp      l
L11fb:  scf     
L11fc:  ret     p

L11fd:  ld      l,a
L11fe:  ld      b,$ff
L1200:  or      a
L1201:  ret     

;;==================================================================
L1202:  inc     a
L1203:  ld      l,a
L1204:  ld      b,$00
L1206:  or      a
L1207:  ret     

;;==================================================================
;; TXBLE

L1208:  call    L0b5d            ;; SCR CHAR LIMITS
L120b:  ld      a,h
L120c:  call    L1240
L120f:  ld      h,a
L1210:  ld      a,d
L1211:  call    L1240
L1214:  ld      d,a
L1215:  cp      h
L1216:  jr      nc,L121a         ; (+$02)
L1218:  ld      d,h
L1219:  ld      h,a
L121a:  ld      a,l
L121b:  call    L1249
L121e:  ld      l,a
L121f:  ld      a,e
L1220:  call    L1249
L1223:  ld      e,a
L1224:  cp      l
L1225:  jr      nc,L1229         ; (+$02)
L1227:  ld      e,l
L1228:  ld      l,a
L1229:  ld      ($b729),hl
L122c:  ld      ($b72b),de
L1230:  ld      a,h
L1231:  or      l
L1232:  jr      nz,L123a         ; (+$06)
L1234:  ld      a,d
L1235:  xor     b
L1236:  jr      nz,L123a         ; (+$02)
L1238:  ld      a,e
L1239:  xor     c
L123a:  ld      ($b728),a
L123d:  jp      L1173            ;; undraw cursor, set cursor position and draw it

;;==================================================================
L1240:  or      a
L1241:  jp      p,L1245
L1244:  xor     a
L1245:  cp      b
L1246:  ret     c

L1247:  ld      a,b
L1248:  ret     

L1249:  or      a
L124a:  jp      p,L124e
L124d:  xor     a
L124e:  cp      c
L124f:  ret     c

L1250:  ld      a,c
L1251:  ret     

;;==================================================================
;; TXDOW

L1252:  ld      hl,($b729)
L1255:  ld      de,($b72b)
L1259:  ld      a,($b728)
L125c:  add     a,$ff
L125e:  ret     

;;==================================================================
;; INDRAW CURSOR
L125f:  ld      a,($b72e)
L1262:  and     $03
L1264:  ret     nz

;;==================================================================
;; TXURSOR
;; TXCURSOR

L1265:  push    bc
L1266:  push    de
L1267:  push    hl
L1268:  call    L11a7
L126b:  ld      bc,($b72f)
L126f:  call    L0de5                ;; SCR CHAR INVERT
L1272:  pop     hl
L1273:  pop     de
L1274:  pop     bc
L1275:  ret     

;;==================================================================
;; TX

L1276:  push    af
L1277:  ld      a,$fd
L1279:  call    L1288
L127c:  pop     af
L127d:  ret     

;;==================================================================
;; TX

L127e:  push    af
L127f:  ld      a,$02
L1281:  call    L1299
L1284:  pop     af
L1285:  ret     

;;==================================================================
;; TXBLE

L1286:  ld      a,$fe
;;------------------------------------------------------------------
L1288:  push    af
L1289:  call    $bdd0                ;; IND: TXT UNDRAW CURSOR
L128c:  pop     af
L128d:  push    hl
L128e:  ld      hl,$b72e
L1291:  and     (hl)
L1292:  ld      (hl),a
L1293:  pop     hl
L1294:  jp      $bdcd                ;; IND: TXT DRAW CURSOR

;;==================================================================
;; TXABLE

L1297:  ld      a,$01
;;------------------------------------------------------------------
L1299:  push    af
L129a:  call    $bdd0                ;; IND: TXT UNDRAW CURSOR
L129d:  pop     af
L129e:  push    hl
L129f:  ld      hl,$b72e
L12a2:  or      (hl)
L12a3:  ld      (hl),a
L12a4:  pop     hl
L12a5:  ret     

;;==================================================================
;; TX 
L12a6:  ld      hl,$b72f
L12a9:  jr      L12ae            ; (+$03)

;;==================================================================
;; TXER
L12ab:  ld      hl,$b730
;;------------------------------------------------------------------
L12ae:  push    af
L12af:  call    $bdd0                ;; IND: TXT UNDRAW CURSOR
L12b2:  pop     af
L12b3:  call    L0c8e                ;; SCR INK ENCODE
L12b6:  ld      (hl),a
L12b7:  jp      $bdcd                ;; IND: TXT DRAW CURSOR

;;==================================================================
;; TX
L12ba:  ld      a,($b72f)
L12bd:  jp      L0ca7            ; SCR INK DECODE

;;==================================================================
;; TXER
L12c0:  ld      a,($b730)
L12c3:  jp      L0ca7            ; SCR INK DECODE

;;==================================================================
;; TX
L12c6:  call    $bdd0                ;; IND: TXT UNDRAW CURSOR
L12c9:  ld      hl,($b72f)
L12cc:  ld      a,h
L12cd:  ld      h,l
L12ce:  ld      l,a
L12cf:  ld      ($b72f),hl
L12d2:  jr      L12b7            ; (-$1d)

;;==================================================================
;; TXRIX
L12d4:  push    de
L12d5:  ld      e,a
L12d6:  call    L132b            ; TXT GET M TABLE
L12d9:  jr      nc,L12e4         ; get pointer to character graphics
L12db:  ld      d,a
L12dc:  ld      a,e
L12dd:  sub     d
L12de:  ccf     
L12df:  jr      nc,L12e4         ; get pointer to character graphics
L12e1:  ld      e,a
L12e2:  jr      L12e7            ; (+$03)

;;----------------------------------------------------------
;; ge to graphics for character in font
;;
;; Entions:
;; A er code
;; Exions:
;; HLr to graphics for character

L12e4:  ld      hl,$3800         ; font graphics
L12e7:  push    af
L12e8:  ld      d,$00
L12ea:  ex      de,hl
L12eb:  add     hl,hl            ; x2
L12ec:  add     hl,hl            ; x4
L12ed:  add     hl,hl            ; x8
L12ee:  add     hl,de
L12ef:  pop     af
L12f0:  pop     de
L12f1:  ret     

;;==================================================================
;; TXRIX
L12f2:  ex      de,hl
L12f3:  call    L12d4            ; TXT GET MATRIX
L12f6:  ret     nc

L12f7:  ex      de,hl

;;------------------------------------------------------------------
L12f8:  ld      bc,$0008
L12fb:  ldir    
L12fd:  ret     

;;==================================================================
;; TXABLE
L12fe:  push    hl
L12ff:  ld      a,d
L1300:  or      a
L1301:  ld      d,$00
L1303:  jr      nz,L131e         ; (+$19)
L1305:  dec     d
L1306:  push    de
L1307:  ld      c,e
L1308:  ex      de,hl
L1309:  ld      a,c
L130a:  call    L12d4            ; TXT GET MATRIX
L130d:  ld      a,h
L130e:  xor     d
L130f:  jr      nz,L1315         ; (+$04)
L1311:  ld      a,l
L1312:  xor     e
L1313:  jr      z,L131d          ; (+$08)
L1315:  push    bc
L1316:  call    L12f8
L1319:  pop     bc
L131a:  inc     c
L131b:  jr      nz,L1309         ; (-$14)
L131d:  pop     de
L131e:  call    L132b            ; TXT GET M TABLE
L1321:  ld      ($b734),de
L1325:  pop     de
L1326:  ld      ($b736),de
L132a:  ret     

;;==================================================================
;; TXABLE
L132b:  ld      hl,($b734)
L132e:  ld      a,h
L132f:  rrca    
L1330:  ld      a,l
L1331:  ld      hl,($b736)
L1334:  ret     

;;==================================================================
;; TX

L1335:  ld      b,a
L1336:  ld      a,($b72e)
L1339:  rlca    
L133a:  ret     c

L133b:  push    bc
L133c:  call    L11a4
L133f:  inc     h
L1340:  ld      ($b726),hl
L1343:  dec     h
L1344:  pop     af
L1345:  call    $bdd3                ;; IND: TXT WRITE CURSOR
L1348:  jp      $bdcd                ;; IND: TXT DRAW CURSOR

;;==================================================================
;; INITE CHAR
L134b:  push    hl
L134c:  call    L12d4            ; TXT GET MATRIX
L134f:  ld      de,$b738
L1352:  push    de
L1353:  call    L0ef9            ; SCR UNPACK
L1356:  pop     de
L1357:  pop     hl
L1358:  call    L0b6a            ; SCR CHAR POSITION
L135b:  ld      c,$08
L135d:  push    bc
L135e:  push    hl
L135f:  push    bc
L1360:  push    de
L1361:  ex      de,hl
L1362:  ld      c,(hl)
L1363:  call    L1377
L1366:  call    L0c05            ; SCR NEXT BYTE
L1369:  pop     de
L136a:  inc     de
L136b:  pop     bc
L136c:  djnz    $135f            ; (-$0f)
L136e:  pop     hl
L136f:  call    L0c1f            ; SCR NEXT LINE
L1372:  pop     bc
L1373:  dec     c
L1374:  jr      nz,L135d         ; (-$19)
L1376:  ret     

;;==================================================================
L1377:  ld      hl,($b731)
L137a:  jp      (hl)
;;==================================================================
;; TXK
L137b:  ld      hl,$1392
L137e:  or      a
L137f:  jr      z,L1384          ; (+$03)
L1381:  ld      hl,$13a0
L1384:  ld      ($b731),hl
L1387:  ret     

;;==================================================================
;; TXK
L1388:  ld      hl,($b731)
L138b:  ld      de,$ec6e
L138e:  add     hl,de
L138f:  ld      a,h
L1390:  or      l
L1391:  ret     
;;==================================================================

L1392:  ld      hl,($b72f)
L1395:  ld      a,c
L1396:  cpl     
L1397:  and     h
L1398:  ld      b,a
L1399:  ld      a,c
L139a:  and     l
L139b:  or      b
L139c:  ld      c,$ff
L139e:  jr      L13a3            ; (+$03)

;;==================================================================
L13a0:  ld      a,($b72f)
;;------------------------------------------------------------------
L13a3:  ld      b,a
L13a4:  ex      de,hl
L13a5:  jp      L0c74            ; SCR PIXELS

;;==================================================================
;; TXPHIC

L13a8:  ld      ($b733),a
L13ab:  ret     

;;==================================================================
;; TX

L13ac:  push    hl
L13ad:  push    de
L13ae:  push    bc
L13af:  call    L11a4
L13b2:  call    $bdd6            ; IND: TXT UNWRITE
L13b5:  push    af
L13b6:  call    $bdcd            ; IND: TXT DRAW CURSOR
L13b9:  pop     af
L13ba:  pop     bc
L13bb:  pop     de
L13bc:  pop     hl
L13bd:  ret     

;;==================================================================
;; INWRITE

L13be:  ld      a,($b730)
L13c1:  ld      de,$b738
L13c4:  push    hl
L13c5:  push    de
L13c6:  call    L0f2a            ; SCR REPACK
L13c9:  pop     de
L13ca:  push    de
L13cb:  ld      b,$08
L13cd:  ld      a,(de)
L13ce:  cpl     
L13cf:  ld      (de),a
L13d0:  inc     de
L13d1:  djnz    $13cd            ; (-$06)
L13d3:  call    L13e1
L13d6:  pop     de
L13d7:  pop     hl
L13d8:  jr      nc,L13db         ; (+$01)
L13da:  ret     nz

L13db:  ld      a,($b72f)
L13de:  call    L0f2a            ; SCR REPACK
L13e1:  ld      c,$00
L13e3:  ld      a,c
L13e4:  call    L12d4            ; TXT GET MATRIX
L13e7:  ld      de,$b738
L13ea:  ld      b,$08
L13ec:  ld      a,(de)
L13ed:  cp      (hl)
L13ee:  jr      nz,L13f9         ; (+$09)
L13f0:  inc     hl
L13f1:  inc     de
L13f2:  djnz    $13ec            ; (-$08)
L13f4:  ld      a,c
L13f5:  cp      $8f
L13f7:  scf     
L13f8:  ret     

L13f9:  inc     c
L13fa:  jr      nz,L13e3         ; (-$19)
L13fc:  xor     a
L13fd:  ret     

;;==================================================================
;; TX

L13fe:  push    af
L13ff:  push    bc
L1400:  push    de
L1401:  push    hl
L1402:  call    $bdd9            ; IND: TXT OUT ACTION
L1405:  pop     hl
L1406:  pop     de
L1407:  pop     bc
L1408:  pop     af
L1409:  ret     

;;==================================================================
;; INT ACTION

L140a:  ld      c,a
L140b:  ld      a,($b733)
L140e:  or      a
L140f:  ld      a,c
L1410:  jp      nz,L1940         ; GRA WR CHAR

L1413:  ld      hl,$b758
L1416:  ld      b,(hl)
L1417:  ld      a,b
L1418:  cp      $0a
L141a:  jr      nc,L144d         ; (+$31)
L141c:  or      a
L141d:  jr      nz,L1425         ; (+$06)
L141f:  ld      a,c
L1420:  cp      $20
L1422:  jp      nc,L1335         ; TXT WR CHAR
L1425:  inc     b
L1426:  ld      (hl),b
L1427:  ld      e,b
L1428:  ld      d,$00
L142a:  add     hl,de
L142b:  ld      (hl),c


;; b7rol code character
L142c:  ld      a,($b759)
L142f:  ld      e,a

;; stntrol code table in RAM
;; eais 3 bytes
L1430:  ld      hl,$b763
;; thively multiplies E by 3
;; an onto the base address of the table

L1433:  add     hl,de
L1434:  add     hl,de
L1435:  add     hl,de        ;; 3 bytes per entry

L1436:  ld      a,(hl)
L1437:  and     $0f
L1439:  cp      b
L143a:  ret     nc

L143b:  ld      a,($b72e)
L143e:  and     (hl)
L143f:  rlca    
L1440:  jr      c,L144d          ; (+$0b)

L1442:  inc     hl
L1443:  ld      e,(hl)           ;; function to execute
L1444:  inc     hl
L1445:  ld      d,(hl)
L1446:  ld      hl,$b759
L1449:  ld      a,c
L144a:  call    L0016            ; LOW: PCDE INSTRUCTION
L144d:  xor     a
L144e:  ld      ($b758),a
L1451:  ret     

;;==================================================================
;; TXABLE

L1452:  ld      a,$81
L1454:  call    L1299
L1457:  jr      L144d            ; (-$0c)

;;==================================================================
;; TXBLE

L1459:  ld      a,$7e
L145b:  call    L1288
L145e:  jr      L144d            ; (-$13)

;;==================================================================
;; TXTE

L1460:  ld      a,($b72e)
L1463:  ret     

;;==================================================================
;; incontrol code functions
L1464:  xor     a
L1465:  ld      ($b758),a

L1468:  ld      hl,$1474
L146b:  ld      de,$b763
L146e:  ld      bc,$0060
L1471:  ldir    
L1473:  ret     
;;==================================================================

;; coe handler functions
;; (s8 for a description of the control character operations)

;; bys 3..0: number of parameters expected
;; byandler function

L1474:  defb $80
        defw $1513              ;; NUL:
        defb $81
        defw $1335              ;; SOH: firmware function: TXT WR CHAR
        defb $80
        defw $1297              ;; STX: firmware function: TXT CUR DISABLE
        defb $80
        defw $1286              ;; ETX: firmware function: TXT CUR ENABLE
        defb $81
        defw $0ae9              ;; EOT: firmware function: SCR SET MODE
        defb $81
        defw $1940              ;; ENQ: firmware function: GRA WR CHAR
        defb $00
        defw $1459              ;; ACK: firmware function: TXT VDU ENABLE
        defb $80
        defw $14e1              ;; BEL:
        defb $80
        defw $1519              ;; BS:
        defb $80
        defw $151e              ;; TAB:
        defb $80
        defw $1523              ;; LF:
        defb $80
        defw $1528              ;; VT:
        defb $80
        defw $154f              ;; FF: firmware function: TXT CLEAR WINDOW
        defb $80
        defw $153f              ;; CR:
        defb $81
        defw $12ab              ;; SO: firmware function: TXT SET PAPER
        defb $81
        defw $12a6              ;; SI: firmware function: TXT SET PEN
        defb $80
        defw $155e              ;; DLE:
        defb $80
        defw $1599              ;; DC1:
        defb $80
        defw $158f              ;; DC2:
        defb $80
        defw $1578              ;; DC3:
        defb $80
        defw $1565              ;; DC4:
        defb $80
        defw $1452              ;; NAK: firmware function: TXT VDU DISABLE
        defb $81
        defw $14ec              ;; SYN:
        defb $81
        defw $0c55              ;; ETB: firmware function: SCR ACCESS
        defb $80
        defw $12c6              ;; CAN: firmware function: TXT INVERSE
        defb $89
        defw $150d              ;; EM:
        defb $84
        defw $1501              ;; SUB:
        defb $00
        defw $14eb              ;; ESC
        defb $83
        defw $14f1              ;; FS:
        defb $82
        defw $14fa              ;; GS:
        defb $80
        defw $1539              ;; RS:
        defb $82
        defw $1547              ;; US:

;; ====================================================================
;; TXTROLS
L14d4:  ld      hl,$b763
L14d7:  ret     

;; ====================================================================
;; dantrol character 'BEL' sound
L14d8:  defb $87 ;; channel status byte
        defb $00 ;; volume envelope to use
        defb $00 ;; tone envelope to use
        defb $5a ;; tone period low
        defb $00 ;; tone period high
        defb $00 ;; noise period
        defb $0b ;; start volume
        defb $14 ;; envelope repeat count low
        defb $00 ;; envelope repeat count high

;; ====================================================================
;; pentrol character 'BEL' function
L14e1:  push    ix
L14e3:  ld      hl,$14d8         ; 
L14e6:  call    L2114            ; SOUND QUEUE
L14e9:  pop     ix

;; pentrol character 'ESC' function
L14eb:  ret     
;; ====================================================================
;; pentrol character 'SYN' function
L14ec:  rrca    
L14ed:  sbc     a,a
L14ee:  jp      L137b            ; TXT SET BACK
;; ====================================================================
;; pentrol character 'FS' function
L14f1:  inc     hl
L14f2:  ld      a,(hl)           ; pen number
L14f3:  inc     hl
L14f4:  ld      b,(hl)           ; ink 1
L14f5:  inc     hl
L14f6:  ld      c,(hl)           ; ink 2
L14f7:  jp      L0cf2            ; SCR SET INK
;;===========================================================
;; pentrol character 'GS' instruction
L14fa:  inc     hl
L14fb:  ld      b,(hl)           ; ink 1
L14fc:  inc     hl
L14fd:  ld      c,(hl)           ; ink 2
L14fe:  jp      L0cf7            ; SCR SET BORDER
;;===========================================================
;; pentrol character 'SUB' function
L1501:  inc     hl
L1502:  ld      d,(hl)           ; left column
L1503:  inc     hl
L1504:  ld      a,(hl)           ; right column
L1505:  inc     hl
L1506:  ld      e,(hl)           ; top row
L1507:  inc     hl
L1508:  ld      l,(hl)           ; bottom row
L1509:  ld      h,a
L150a:  jp      L1208            ; TXT WIN ENABLE
;;===========================================================
;; pentrol character 'EM' function
L150d:  inc     hl
L150e:  ld      a,(hl)           ; character index
L150f:  inc     hl
L1510:  jp      L12f2            ; TXT SET MATRIX
;;===========================================================
;; pentrol character 'NUL' function
L1513:  call    L11a4
L1516:  jp      $bdcd            ; IND: TXT DRAW CURSOR
;;===========================================================
;; pentrol character 'BS' function
L1519:  ld      de,$ff00
L151c:  jr      L152b            ; (+$0d)
;;===========================================================
;; pentrol character 'TAB' function
L151e:  ld      de,$0100
L1521:  jr      L152b            ; (+$08)
;;===========================================================
;; pentrol character 'LF' function
L1523:  ld      de,$0001
L1526:  jr      L152b            ; (+$03)
;;===========================================================
;; pentrol character 'VT' function
L1528:  ld      de,$00ff
;;-----------------------------------------------------------
;; D adjustment
;; E ustment
L152b:  push    de
L152c:  call    L11a4
L152f:  pop     de

;; ad
L1530:  ld      a,l
L1531:  add     a,e
L1532:  ld      l,a

;; admn
L1533:  ld      a,h
L1534:  add     a,d
L1535:  ld      h,a

L1536:  jp      L1176            ; set cursor position and draw it
;;===========================================================
;; pentrol character 'RS' function
L1539:  ld      hl,($b729)
L153c:  jp      L1173            ;; undraw cursor, set cursor position and draw it
;;==================================================================
;; pentrol character 'CR' function
L153f:  call    L11a4
L1542:  ld      a,($b72a)
L1545:  jr      L1535            ; (-$12)

;;==================================================================
;; pentrol character 'US' function
L1547:  inc     hl
L1548:  ld      d,(hl)           ; column
L1549:  inc     hl
L154a:  ld      e,(hl)           ; row
L154b:  ex      de,hl
L154c:  jp      L1170            ; TXT SET CURSOR

;;==================================================================
;; TXINDOW

L154f:  call    $bdd0            ; IND: TXT UNDRAW CURSOR
L1552:  ld      hl,($b729)
L1555:  ld      ($b726),hl
L1558:  ld      de,($b72b)
L155c:  jr      L15a2            ; (+$44)

;;==================================================================
;; pentrol character 'DLE' function
L155e:  call    L11a4
L1561:  ld      d,h
L1562:  ld      e,l
L1563:  jr      L15a2            ; (+$3d)

;;==================================================================
;; pentrol character 'DC4' function
L1565:  call    L158f            ; control character 'DC2'
L1568:  ld      hl,($b729)
L156b:  ld      de,($b72b)
L156f:  ld      a,($b726)
L1572:  ld      l,a
L1573:  inc     l
L1574:  cp      e
L1575:  ret     nc

L1576:  jr      L1589            ; (+$11)

;;==================================================================
;; pentrol character 'DC3' function
L1578:  call    L1599            ; control character 'DC1' function
L157b:  ld      hl,($b729)
L157e:  ld      a,($b72c)
L1581:  ld      d,a
L1582:  ld      a,($b726)
L1585:  dec     a
L1586:  ld      e,a
L1587:  cp      l
L1588:  ret     c

L1589:  ld      a,($b730)
L158c:  jp      L0db9            ; SCR FILL BOX

;;==================================================================
;; pentrol character 'DC2' function
L158f:  call    L11a4
L1592:  ld      e,l
L1593:  ld      a,($b72c)
L1596:  ld      d,a
L1597:  jr      L15a2            ; (+$09)

;;==================================================================
;; pentrol character 'DC1' function
L1599:  call    L11a4
L159c:  ex      de,hl
L159d:  ld      l,e
L159e:  ld      a,($b72a)
L15a1:  ld      h,a

;;------------------------------------------------------------------
L15a2:  call    L1589
L15a5:  jp      $bdcd            ; IND: TXT DRAW CURSOR

;;==================================================================
;; GRISE
L15a8:  call    L15d7            ; GRA RESET
L15ab:  ld      hl,$0001
L15ae:  ld      a,h
L15af:  call    L176e            ; GRA SET PAPER
L15b2:  ld      a,l
L15b3:  call    L1767            ; GRA SET PEN
L15b6:  ld      hl,$0000
L15b9:  ld      d,h
L15ba:  ld      e,l
L15bb:  call    L160e            ; GRA SET ORIGIN
L15be:  ld      de,$8000
L15c1:  ld      hl,$7fff
L15c4:  push    hl
L15c5:  push    de
L15c6:  call    L16a5            ; GRA WIN WIDTH
L15c9:  pop     hl
L15ca:  pop     de
L15cb:  jp      L16ea            ; GRA WIN HEIGHT
;;==================================================================

L15ce:  call    L177a            ; GRA GET PAPER
L15d1:  ld      h,a
L15d2:  call    L1775            ; GRA GET PEN
L15d5:  ld      l,a
L15d6:  ret     

;;==================================================================
;; GR
L15d7:  call    L15f0            
L15da:  ld      hl,$15e0         ;; table used to initialise graphics pack indirections
L15dd:  jp      L0ab4            ;; initialise graphics pack indirections

L15e0:  defb $09
        defw $bddc
        jp      L1786                           ;; IND: GRA PLOT
        jp      L179a                           ;; IND: GRA TEXT
        jp      L17b4                           ;; IND: GRA LINE

;;==================================================================
;; GR

L15ec:  xor     a
L15ed:  call    L0c55            ; SCR ACCESS

L15f0:  xor     a
L15f1:  call    L19d5            ; GRA SET BACK
L15f4:  cpl     
L15f5:  call    L17b0            ; GRA SET FIRST
L15f8:  jp      L17ac            ; GRA SET LINE MASK

;;==================================================================
;; GRLATIVE
L15fb:  call    L165d            ; convert relative graphics coordinate to
                               ; absolute graphics coordinate


;;------------------------------------------------------------------
;; GRSOLUTE
L15fe:  ld      ($b697),de       ; absolute x
L1602:  ld      ($b699),hl       ; absolute y
L1605:  ret     

;;==================================================================
;; GRSOR
L1606:  ld      de,($b697)       ; absolute x
L160a:  ld      hl,($b699)       ; absolute y
L160d:  ret     

;;==================================================================
;; GRGIN
L160e:  ld      ($b693),de       ; origin x
L1612:  ld      ($b695),hl       ; origin y


;;==================================================================
;; see position to origin
L1615:  ld      de,$0000         ; x = 0
L1618:  ld      h,d
L1619:  ld      l,e              ; y = 0
L161a:  jr      L15fe            ; GRA MOVE ABSOLUTE

;;==================================================================
;; GRGIN
L161c:  ld      de,($b693)       ; origin x  
L1620:  ld      hl,($b695)       ; origin y
L1623:  ret     

;;==================================================================
;; geabsolute user coordinate
L1624:  call    L1606            ; GRA ASK CURSOR

;;-------------------------------------------------------------------
;; gee user coordinate
L1627:  call    L15fe            ; GRA MOVE ABSOLUTE

;;==================================================================
;; GRER
;; DE coordinate
;; HL coordinate
;; ou
;; DE coordinate
;; HL coordinate
L162a:  push    hl
L162b:  call    L0b0c            ; SCR GET MODE
L162e:  neg     
L1630:  sbc     a,$fd
L1632:  ld      h,$00
L1634:  ld      l,a
L1635:  bit     7,d
L1637:  jr      z,L163c          ; (+$03)
L1639:  ex      de,hl
L163a:  add     hl,de
L163b:  ex      de,hl
L163c:  cpl     
L163d:  and     e
L163e:  ld      e,a
L163f:  ld      a,l
L1640:  ld      hl,($b693)       ; origin x
L1643:  add     hl,de
L1644:  rrca    
L1645:  call    c,L16e5          ; HL = HL/2
L1648:  rrca    
L1649:  call    c,L16e5          ; HL = HL/2
L164c:  pop     de
L164d:  push    hl
L164e:  ld      a,d
L164f:  rlca    
L1650:  jr      nc,L1653         
L1652:  inc     de
L1653:  res     0,e
L1655:  ld      hl,($b695)       ; origin y
L1658:  add     hl,de
L1659:  pop     de
L165a:  jp      L16e5            ; HL = HL/2

;;=========================================================================
;; coative graphics coordinate to absolute graphics coordinate
;; DEve X
;; HLve Y
L165d:  push    hl
L165e:  ld      hl,($b697)       ; absolute x        
L1661:  add     hl,de
L1662:  pop     de
L1663:  push    hl
L1664:  ld      hl,($b699)       ; absolute y
L1667:  add     hl,de
L1668:  pop     de
L1669:  ret     

;;=========================================================================
;; X coordinate within window

;; DEdinate
L166a:  ld      hl,($b69b)       ; graphics window left edge
L166d:  scf     
L166e:  sbc     hl,de
L1670:  jp      p,L167e

L1673:  ld      hl,($b69d)       ; graphics window right edge
L1676:  or      a
L1677:  sbc     hl,de
L1679:  scf     
L167a:  ret     p

L167b:  or      $ff
L167d:  ret     

L167e:  xor     a
L167f:  ret     

;;=========================================================================
;; y coordinate within window
;; DEdinate
L1680:  ld      hl,($b69f)       ; graphics window top edge
L1683:  or      a
L1684:  sbc     hl,de
L1686:  jp      m,L167b
L1689:  ld      hl,($b6a1)       ; graphics window bottom edge
L168c:  scf     
L168d:  sbc     hl,de
L168f:  jp      p,L167e
L1692:  scf     
L1693:  ret     

;;=========================================================================

;; cunt within graphics window
L1694:  call    L1627            ; get absolute user coordinate

;; poaphics window?
;; HLdinate
;; DEdinate
L1697:  push    hl
L1698:  call    L166a            ; X graphics coordinate within window
L169b:  pop     hl
L169c:  ret     nc

L169d:  push    de
L169e:  ex      de,hl
L169f:  call    L1680            ; Y graphics coordinate within window
L16a2:  ex      de,hl
L16a3:  pop     de
L16a4:  ret     

;;=========================================================================
;; GRTH
;; DEdge
;; HLedge
L16a5:  push    hl
L16a6:  call    L16d1            ;; Make X coordinate within range 0-639
L16a9:  pop     de
L16aa:  push    hl
L16ab:  call    L16d1            ;; Make X coordinate within range 0-639
L16ae:  pop     de
L16af:  ld      a,e
L16b0:  sub     l
L16b1:  ld      a,d
L16b2:  sbc     a,h
L16b3:  jr      c,L16b6         

L16b5:  ex      de,hl
L16b6:  ld      a,e
L16b7:  and     $f8
L16b9:  ld      e,a
L16ba:  ld      a,l
L16bb:  or      $07
L16bd:  ld      l,a
L16be:  call    L0b0c            ; SCR GET MODE
L16c1:  dec     a
L16c2:  call    m,$16e1          ; DE = DE/2 and HL = HL/2
L16c5:  dec     a
L16c6:  call    m,$16e1          ; DE = DE/2 and HL = HL/2
L16c9:  ld      ($b69b),de       ; graphics window left edge
L16cd:  ld      ($b69d),hl       ; graphics window right edge
L16d0:  ret     

;;=========================================================================
;; Madinate within range 0-639
L16d1:  ld      a,d
L16d2:  or      a
L16d3:  ld      hl,$0000
L16d6:  ret     m

L16d7:  ld      hl,$027f         ; 639
L16da:  ld      a,e
L16db:  sub     l
L16dc:  ld      a,d
L16dd:  sbc     a,h
L16de:  ret     nc

L16df:  ex      de,hl
L16e0:  ret     

;;=========================================================================
;; DE
;; HL
L16e1:  sra     d
L16e3:  rr      e

;;-------------------------------------------------------------------------
;; HL
L16e5:  sra     h
L16e7:  rr      l
L16e9:  ret     

;;=========================================================================
;; GRGHT
L16ea:  push    hl
L16eb:  call    L1703            ;; make Y coordinate in range 0-199
L16ee:  pop     de
L16ef:  push    hl
L16f0:  call    L1703            ;; make Y coordinate in range 0-199
L16f3:  pop     de
L16f4:  ld      a,l
L16f5:  sub     e
L16f6:  ld      a,h
L16f7:  sbc     a,d
L16f8:  jr      c,L16fb          ; (+$01)
L16fa:  ex      de,hl
L16fb:  ld      ($b69f),de       ; graphics window top edge
L16ff:  ld      ($b6a1),hl       ; graphics window bottom edge
L1702:  ret     

;;=========================================================================
;; madinate in range 0-199

L1703:  ld      a,d
L1704:  or      a
L1705:  ld      hl,$0000
L1708:  ret     m

L1709:  srl     d
L170b:  rr      e
L170d:  ld      hl,$00c7     ; 199
L1710:  ld      a,e
L1711:  sub     l
L1712:  ld      a,d
L1713:  sbc     a,h
L1714:  ret     nc

L1715:  ex      de,hl
L1716:  ret     

;;=========================================================================
;; GRIDTH
L1717:  ld      de,($b69b)       ; graphics window left edge
L171b:  ld      hl,($b69d)       ; graphics window right edge
L171e:  call    L0b0c            ; SCR GET MODE
L1721:  dec     a
L1722:  call    m,$1727
L1725:  dec     a
L1726:  ret     p

;; HL+1
L1727:  add     hl,hl            
L1728:  inc     hl               

;; DE
L1729:  ex      de,hl
L172a:  add     hl,hl
L172b:  ex      de,hl            

L172c:  ret     
;;=========================================================================
;; GREIGHT
L172d:  ld      de,($b69f)       ; graphics window top edge
L1731:  ld      hl,($b6a1)       ; graphics window bottom edge
L1734:  jr      L1727
;;=========================================================================
;; GRINDOW
L1736:  call    L1717            ; GRA GET W WIDTH
L1739:  or      a
L173a:  sbc     hl,de
L173c:  inc     hl
L173d:  call    L16e5            ; HL = HL/2
L1740:  call    L16e5            ; HL = HL/2
L1743:  srl     l
L1745:  ld      b,l
L1746:  ld      de,($b6a1)       ; graphics window bottom edge
L174a:  ld      hl,($b69f)       ; graphics window top edge
L174d:  push    hl
L174e:  or      a
L174f:  sbc     hl,de
L1751:  inc     hl
L1752:  ld      c,l
L1753:  ld      de,($b69b)       ; graphics window left edge
L1757:  pop     hl
L1758:  push    bc
L1759:  call    L0baf            ;; SCR DOT POSITION
L175c:  pop     de
L175d:  ld      a,($b6a4)        ; graphics paper
L1760:  ld      c,a
L1761:  call    L0dbd            ;; SCR FLOOD BOX
L1764:  jp      L1615            ;; set absolute position to origin

;;=========================================================================
;; GR
L1767:  call    L0c8e                ;; SCR INK ENCODE
L176a:  ld      ($b6a3),a        ; graphics pen
L176d:  ret     

;;=========================================================================
;; GRER
L176e:  call    L0c8e                ;; SCR INK ENCODE
L1771:  ld      ($b6a4),a        ; graphics paper
L1774:  ret     
;;=========================================================================
;; GR
L1775:  ld      a,($b6a3)        ; graphics pen
L1778:  jr      L177d            ; do SCR INK ENCODE
;;=========================================================================
;; GRER
L177a:  ld      a,($b6a4)        ; graphics paper
L177d:  jp      L0ca7            ;; SCR INK DECODE

;;=========================================================================
;; GRLATIVE
L1780:  call    L165d            ; convert relative graphics coordinate to
                               ; absolute graphics coordinate

;;-------------------------------------------------------------------------
;; GRSOLUTE
L1783:  jp      $bddc            ; IND: GRA PLOT

;;===================================================================
;; INOT
L1786:  call    L1694            ; test if current coordinate within graphics window
L1789:  ret     nc

L178a:  call    L0baf            ;; SCR DOT POSITION
L178d:  ld      a,($b6a3)        ; graphics pen
L1790:  ld      b,a
L1791:  jp      $bde8            ; IND: SCR WRITE

;;==================================================================
;; GRLATIVE
L1794:  call    L165d            ; convert relative graphics coordinate to
                               ; absolute graphics coordinate

;;------------------------------------------------------------------
;; GRSOLUTE
L1797:  jp      $bddf            ; IND: GRA TEST

;;==================================================================
;; INXT
L179a:  call    L1694            ; test if current coordinate within graphics window
L179d:  jp      nc,L177a         ; GRA GET PAPER
L17a0:  call    L0baf            ; SCR DOT POSITION
L17a3:  jp      $bde5            ; IND: SCR READ

;;==================================================================
;; GRLATIVE
L17a6:  call    L165d            ; convert relative graphics coordinate to
                               ; absolute graphics coordinate

;;------------------------------------------------------------------
;; GRSOLUTE
L17a9:  jp      $bde2            ; IND: GRA LINE

;;==================================================================
;; GRE MASK

L17ac:  ld      ($b6b3),a        ; gra line mask
L17af:  ret     

;;==================================================================
;; GRST

L17b0:  ld      ($b6b2),a
L17b3:  ret     

;;==================================================================
;; INNE
L17b4:  push    hl
L17b5:  call    L188b            ; get cursor absolute position
L17b8:  pop     hl
L17b9:  call    L1627            ; get absolute user coordinate

;; recoordinate
L17bc:  push    hl

;; DEdinate

;;----------------------------------

;; cax
L17bd:  ld      hl,($b6a5)       ; absolute user X coordinate
L17c0:  or      a
L17c1:  sbc     hl,de

;; thecord the fact of dx is +ve or negative
L17c3:  ld      a,h
L17c4:  ld      ($b6ad),a

;; ifgative, make it positive
L17c7:  call    m,$1939          ; HL = -HL

;; HL)

;;----------------------------------

;; cay
L17ca:  pop     de
;; DEdinate
L17cb:  push    hl
L17cc:  ld      hl,($b6a7)       ; absolute user Y coordinate
L17cf:  or      a
L17d0:  sbc     hl,de

;; th the fact of dy is +ve or negative
L17d2:  ld      a,h
L17d3:  ld      ($b6ae),a

;; ifgative, make it positive
L17d6:  call    m,$1939          ; HL = -HL

;; HL)


L17d9:  pop     de
;; DE)
;; HL)

;;----------------------------------

;; is largest?
L17da:  or      a
L17db:  sbc     hl,de            ; dy-dx
L17dd:  add     hl,de            ; and return it back to their original values

L17de:  sbc     a,a
L17df:  ld      ($b6af),a        ; remembers which of dy/dx was largest

L17e2:  ld      a,($b6ae)        ; dy is negative
L17e5:  jr      z,L17eb          ; depends on result of dy-dx

;; ifn swap dx/dy
L17e7:  ex      de,hl
;; DE)
;; HL)

L17e8:  ld      a,($b6ad)        ; dx is negative

;;----------------------------------

L17eb:  push    af
L17ec:  ld      ($b6ab),de
L17f0:  ld      b,h
L17f1:  ld      c,l
L17f2:  ld      a,($b6b2)
L17f5:  or      a
L17f6:  jr      z,L17f9          ; (+$01)
L17f8:  inc     bc
L17f9:  ld      ($b6b0),bc
L17fd:  call    L1939            ; HL = -HL
L1800:  push    hl
L1801:  add     hl,de
L1802:  ld      ($b6a9),hl
L1805:  pop     hl
L1806:  sra     h                ;; /2 for y coordinate (0-400 GRA coordinates, 0-200 actual number of lines)
L1808:  rr      l
L180a:  pop     af
L180b:  rlca    
L180c:  jr      c,L1820          ; (+$12)
L180e:  push    hl
L180f:  call    L188b            ; get cursor absolute position
L1812:  ld      hl,($b6ad)
L1815:  ld      a,h
L1816:  cpl     
L1817:  ld      h,a
L1818:  ld      a,l
L1819:  cpl     
L181a:  ld      l,a
L181b:  ld      ($b6ad),hl
L181e:  jr      L1832            ; (+$12)


L1820:  ld      a,($b6b2)
L1823:  or      a
L1824:  jr      nz,L1833         ; (+$0d)
L1826:  add     hl,de
L1827:  push    hl

L1828:  ld      a,($b6af)        ; dy or dx was biggest?
L182b:  rlca    
L182c:  call    c,L18da          ; plot a pixel moving up
L182f:  call    nc,L1928         ; plot a pixel moving right

L1832:  pop     hl
L1833:  ld      a,d
L1834:  or      e
L1835:  jp      z,L1898
L1838:  push    ix
L183a:  ld      bc,$0000
L183d:  push    bc
L183e:  pop     ix
L1840:  push    ix
L1842:  pop     de
L1843:  or      a
L1844:  adc     hl,de
L1846:  ld      de,($b6ab)
L184a:  jp      p,L1853
L184d:  inc     bc
L184e:  add     ix,de
L1850:  add     hl,de
L1851:  jr      nc,L184d         ; (-$06)

; DE 
L1853:  xor     a
L1854:  sub     e
L1855:  ld      e,a
L1856:  sbc     a,a
L1857:  sub     d
L1858:  ld      d,a

L1859:  add     hl,de
L185a:  jr      nc,L1861         ; (+$05)
L185c:  add     ix,de
L185e:  dec     bc
L185f:  jr      L1859            ; (-$08)


L1861:  ld      de,($b6a9)
L1865:  add     hl,de
L1866:  push    bc
L1867:  push    hl
L1868:  ld      hl,($b6b0)
L186b:  or      a
L186c:  sbc     hl,bc
L186e:  jr      nc,L1876         ; (+$06)

L1870:  add     hl,bc
L1871:  ld      b,h
L1872:  ld      c,l
L1873:  ld      hl,$0000

L1876:  ld      ($b6b0),hl
L1879:  call    L1898            ; plot with clip
L187c:  pop     hl
L187d:  pop     bc
L187e:  jr      nc,L1888         ; (+$08)
L1880:  ld      de,($b6b0)
L1884:  ld      a,d
L1885:  or      e
L1886:  jr      nz,L1840         ; (-$48)
L1888:  pop     ix
L188a:  ret     
;;=========================================================================

L188b:  push    de
L188c:  call    L1624            ;; get cursor absolute user coordinate
L188f:  ld      ($b6a5),de       
L1893:  ld      ($b6a7),hl
L1896:  pop     de
L1897:  ret     
;;=========================================================================

L1898:  ld      a,($b6af)
L189b:  rlca    
L189c:  jr      c,L18eb          ; (+$4d)
L189e:  ld      a,b
L189f:  or      c
L18a0:  jr      z,L18da          ; (+$38)
L18a2:  ld      hl,($b6a7)
L18a5:  add     hl,bc
L18a6:  dec     hl
L18a7:  ld      b,h
L18a8:  ld      c,l
L18a9:  ex      de,hl
L18aa:  call    L1680            ; Y graphics coordinate within window
L18ad:  ld      hl,($b6a7)
L18b0:  ex      de,hl
L18b1:  inc     hl
L18b2:  ld      ($b6a7),hl
L18b5:  jr      c,L18bd          ; 
L18b7:  jr      z,L18da          ; 
L18b9:  ld      bc,($b69f)       ; graphics window top edge
L18bd:  call    L1680            ; Y graphics coordinate within window
L18c0:  jr      c,L18c7          ; (+$05)
L18c2:  ret     nz

L18c3:  ld      de,($b6a1)       ; graphics window bottom edge
L18c7:  push    de
L18c8:  ld      de,($b6a5)       
L18cc:  call    L166a            ; graphics x coordinate within window
L18cf:  pop     hl
L18d0:  jr      c,L18d7          ; (+$05)
L18d2:  ld      hl,$b6ad
L18d5:  xor     (hl)
L18d6:  ret     p

L18d7:  call    c,L1016          ; plot a pixel, going up a line


L18da:  ld      hl,($b6a5)
L18dd:  ld      a,($b6ad)
L18e0:  rlca    
L18e1:  inc     hl
L18e2:  jr      c,L18e6          ; (+$02)
L18e4:  dec     hl
L18e5:  dec     hl
L18e6:  ld      ($b6a5),hl
L18e9:  scf     
L18ea:  ret     

;; weh coordinates...

;; thms the clipping to find if the coordinates are within rnage

L18eb:  ld      a,b
L18ec:  or      c
L18ed:  jr      z,L1928          ; (+$39)
L18ef:  ld      hl,($b6a5)
L18f2:  add     hl,bc
L18f3:  dec     hl
L18f4:  ld      b,h
L18f5:  ld      c,l
L18f6:  ex      de,hl
L18f7:  call    L166a            ; x graphics coordinate within window
L18fa:  ld      hl,($b6a5)
L18fd:  ex      de,hl
L18fe:  inc     hl
L18ff:  ld      ($b6a5),hl
L1902:  jr      c,L190a          
L1904:  jr      z,L1928          
L1906:  ld      bc,($b69d)       ; graphics window right edge
L190a:  call    L166a            ; x graphics coordinate within window
L190d:  jr      c,L1914          
L190f:  ret     nz

L1910:  ld      de,($b69b)       ; graphics window left edge
L1914:  push    de
L1915:  ld      de,($b6a7)
L1919:  call    L1680            ; Y graphics coordinate within window
L191c:  pop     hl
L191d:  jr      c,L1924          ; (+$05)

L191f:  ld      hl,$b6ae
L1922:  xor     (hl)
L1923:  ret     p

L1924:  ex      de,hl
L1925:  call    c,L0fc2          ; plot a pixel moving right

L1928:  ld      hl,($b6a7)
L192b:  ld      a,($b6ae)
L192e:  rlca    
L192f:  inc     hl
L1930:  jr      c,L1934          ; (+$02)
L1932:  dec     hl
L1933:  dec     hl
L1934:  ld      ($b6a7),hl
L1937:  scf     
L1938:  ret     

;;=========================================================================
; HL 
L1939:  xor     a
L193a:  sub     l
L193b:  ld      l,a
L193c:  sbc     a,a
L193d:  sub     h
L193e:  ld      h,a
L193f:  ret     

;;==================================================================
;; GR

L1940:  push    ix
L1942:  call    L12d4            ; TXT GET MATRIX
L1945:  push    hl
L1946:  pop     ix
L1948:  call    L1624            ;; get cursor absolute user coordinate
L194b:  call    L1697            ;; point in graphics window
L194e:  jr      nc,L199b         ; (+$4b)
L1950:  push    hl
L1951:  push    de
L1952:  ld      bc,$0007
L1955:  ex      de,hl
L1956:  add     hl,bc
L1957:  ex      de,hl
L1958:  or      a
L1959:  sbc     hl,bc
L195b:  call    L1697            ;; point in graphics window
L195e:  pop     de
L195f:  pop     hl
L1960:  jr      nc,L199b         ; (+$39)
L1962:  call    L0baf            ;; SCR DOT POSITION
L1965:  ld      d,$08
L1967:  push    hl
L1968:  ld      e,(ix+$00)
L196b:  scf     
L196c:  rl      e
L196e:  call    L19c4
L1971:  rrc     c
L1973:  call    c,L0c05          ; SCR NEXT BYTE
L1976:  sla     e
L1978:  jr      nz,L196e         ; (-$0c)
L197a:  pop     hl
L197b:  call    L0c1f            ; SCR NEXT LINE
L197e:  inc     ix
L1980:  dec     d
L1981:  jr      nz,L1967         ; (-$1c)
L1983:  pop     ix
L1985:  call    L1606            ; GRA ASK CURSOR
L1988:  ex      de,hl
L1989:  call    L0b0c            ; SCR GET MODE
L198c:  ld      bc,$0008
L198f:  jr      z,L1995          ; (+$04)
L1991:  jr      nc,L1996         ; (+$03)
L1993:  add     hl,bc
L1994:  add     hl,bc
L1995:  add     hl,bc
L1996:  add     hl,bc
L1997:  ex      de,hl
L1998:  jp      L15fe            ; GRA MOVE ABSOLUTE

;;=========================================================================
L199b:  ld      b,$08
L199d:  push    bc
L199e:  push    de
L199f:  ld      a,(ix+$00)
L19a2:  scf     
L19a3:  adc     a,a
L19a4:  push    hl
L19a5:  push    de
L19a6:  push    af
L19a7:  call    L1697            ;; point in graphics window
L19aa:  jr      nc,L19b4         ; (+$08)
L19ac:  call    L0baf            ;; SCR DOT POSITION
L19af:  pop     af
L19b0:  push    af
L19b1:  call    L19c4
L19b4:  pop     af
L19b5:  pop     de
L19b6:  pop     hl
L19b7:  inc     de
L19b8:  add     a,a
L19b9:  jr      nz,L19a4         ; (-$17)
L19bb:  pop     de
L19bc:  dec     hl
L19bd:  inc     ix
L19bf:  pop     bc
L19c0:  djnz    $199d            ; (-$25)
L19c2:  jr      L1983            ; (-$41)

;;=========================================================================

L19c4:  ld      a,($b6a3)        ; graphics pen
L19c7:  jr      c,L19d1          ; (+$08)
L19c9:  ld      a,($b6b4)
L19cc:  or      a
L19cd:  ret     nz

L19ce:  ld      a,($b6a4)        ; graphics paper
L19d1:  ld      b,a
L19d2:  jp      $bde8            ; IND: SCR WRITE

;;==================================================================
;; GRK

L19d5:  ld      ($b6b4),a
L19d8:  ret     

;;==================================================================
;; GR
;; HL
;; A fill
;; DE of buffer

L19d9:  ld      ($b6a5),hl
L19dc:  ld      (hl),$01
L19de:  dec     de
L19df:  ld      ($b6a7),de
L19e3:  call    L0c8e                ;; SCR INK ENCODE
L19e6:  ld      ($b6aa),a
L19e9:  call    L1624            ;; get cursor absolute user coordinate
L19ec:  call    L1697            ;; point in graphics window
L19ef:  call    c,L1b42
L19f2:  ret     nc

L19f3:  push    hl
L19f4:  call    L1ae7
L19f7:  ex      (sp),hl
L19f8:  call    L1b15
L19fb:  pop     bc
L19fc:  ld      a,$ff
L19fe:  ld      ($b6a9),a
L1a01:  push    hl
L1a02:  push    de
L1a03:  push    bc
L1a04:  call    L1a0b
L1a07:  pop     bc
L1a08:  pop     de
L1a09:  pop     hl
L1a0a:  xor     a
L1a0b:  ld      ($b6ab),a
L1a0e:  call    L1ade
L1a11:  call    L1697            ;; point in graphics window
L1a14:  call    c,L1a50
L1a17:  jr      c,L1a0e          ; (-$0b)
L1a19:  ld      hl,($b6a5)       ; graphics fill buffer
L1a1c:  rst     $20              ; RST 4 - LOW: RAM LAM
L1a1d:  cp      $01
L1a1f:  jr      z,L1a4b          ; (+$2a)
L1a21:  ld      ($b6ab),a
L1a24:  ex      de,hl
L1a25:  ld      hl,($b6a7)
L1a28:  ld      bc,$0007
L1a2b:  add     hl,bc
L1a2c:  ld      ($b6a7),hl
L1a2f:  ex      de,hl
L1a30:  dec     hl
L1a31:  rst     $20              ; RST 4 - LOW: RAM LAM
L1a32:  ld      b,a
L1a33:  dec     hl
L1a34:  rst     $20              ; RST 4 - LOW: RAM LAM
L1a35:  ld      c,a
L1a36:  dec     hl
L1a37:  rst     $20              ; RST 4 - LOW: RAM LAM
L1a38:  ld      d,a
L1a39:  dec     hl
L1a3a:  rst     $20              ; RST 4 - LOW: RAM LAM
L1a3b:  ld      e,a
L1a3c:  push    de
L1a3d:  dec     hl
L1a3e:  rst     $20              ; RST 4 - LOW: RAM LAM
L1a3f:  ld      d,a
L1a40:  dec     hl
L1a41:  rst     $20              ; RST 4 - LOW: RAM LAM
L1a42:  ld      e,a
L1a43:  dec     hl
L1a44:  ld      ($b6a5),hl       ; graphics fill buffer
L1a47:  ex      de,hl
L1a48:  pop     de
L1a49:  jr      L1a11            ; (-$3a)
L1a4b:  ld      a,($b6a9)
L1a4e:  rrca    
L1a4f:  ret     

;;=========================================================================

L1a50:  ld      ($b6ac),bc
L1a54:  call    L1b42
L1a57:  jr      c,L1a62          ; (+$09)
L1a59:  call    L1af1
L1a5c:  ret     nc

L1a5d:  ld      ($b6ae),hl
L1a60:  jr      L1a73            ; (+$11)
L1a62:  push    hl
L1a63:  call    L1b15
L1a66:  ld      ($b6ae),hl
L1a69:  pop     bc
L1a6a:  ld      a,l
L1a6b:  sub     c
L1a6c:  ld      a,h
L1a6d:  sbc     a,b
L1a6e:  call    c,L1acb
L1a71:  ld      h,b
L1a72:  ld      l,c
L1a73:  call    L1ae7
L1a76:  ld      ($b6b0),hl
L1a79:  ld      bc,($b6ac)
L1a7d:  or      a
L1a7e:  sbc     hl,bc
L1a80:  add     hl,bc
L1a81:  jr      z,L1a94          ; (+$11)
L1a83:  jr      nc,L1a8d         ; (+$08)
L1a85:  call    L1af1
L1a88:  call    c,L1a9d
L1a8b:  jr      L1a94            ; (+$07)
L1a8d:  push    hl
L1a8e:  ld      h,b
L1a8f:  ld      l,c
L1a90:  pop     bc
L1a91:  call    L1acb
L1a94:  ld      hl,($b6ae)
L1a97:  ld      bc,($b6b0)
L1a9b:  scf     
L1a9c:  ret     

L1a9d:  push    de
L1a9e:  push    hl
L1a9f:  ld      hl,($b6a7)
L1aa2:  ld      de,$fff9
L1aa5:  add     hl,de
L1aa6:  pop     de
L1aa7:  jr      nc,L1ac5         ; (+$1c)
L1aa9:  ld      ($b6a7),hl
L1aac:  ld      hl,($b6a5)       ; graphics fill buffer
L1aaf:  inc     hl
L1ab0:  ld      (hl),e
L1ab1:  inc     hl
L1ab2:  ld      (hl),d
L1ab3:  inc     hl
L1ab4:  pop     de
L1ab5:  ld      (hl),e
L1ab6:  inc     hl
L1ab7:  ld      (hl),d
L1ab8:  inc     hl
L1ab9:  ld      (hl),c
L1aba:  inc     hl
L1abb:  ld      (hl),b
L1abc:  inc     hl
L1abd:  ld      a,($b6ab)
L1ac0:  ld      (hl),a
L1ac1:  ld      ($b6a5),hl               ; graphics fill buffer
L1ac4:  ret     

L1ac5:  xor     a
L1ac6:  ld      ($b6a9),a
L1ac9:  pop     de
L1aca:  ret     

L1acb:  call    L1ad7
L1ace:  call    L1b42
L1ad1:  call    nc,L1af1
L1ad4:  call    c,L1a9d
L1ad7:  ld      a,($b6ab)
L1ada:  cpl     
L1adb:  ld      ($b6ab),a
L1ade:  dec     de
L1adf:  ld      a,($b6ab)
L1ae2:  or      a
L1ae3:  ret     z

L1ae4:  inc     de
L1ae5:  inc     de
L1ae6:  ret     

L1ae7:  xor     a
L1ae8:  ld      bc,($b69f)       ; graphics window top edge
L1aec:  call    L1af3
L1aef:  dec     hl
L1af0:  ret     

;;=========================================================================

L1af1:  ld      a,$ff
L1af3:  push    bc
L1af4:  push    de
L1af5:  push    hl
L1af6:  push    af
L1af7:  call    L1b4f
L1afa:  pop     af
L1afb:  ld      b,a
L1afc:  call    L1b34
L1aff:  inc     b
L1b00:  djnz    $1b06            ; (+$04)
L1b02:  jr      nc,L1b4b         ; (+$47)
L1b04:  xor     (hl)
L1b05:  ld      (hl),a
L1b06:  jr      c,L1b4b          ; (+$43)
L1b08:  ex      (sp),hl
L1b09:  inc     hl
L1b0a:  ex      (sp),hl
L1b0b:  sbc     hl,de
L1b0d:  jr      z,L1b4b          ; (+$3c)
L1b0f:  add     hl,de
L1b10:  call    L0c39            ; SCR PREV LINE
L1b13:  jr      L1afc            ; (-$19)
L1b15:  push    bc
L1b16:  push    de
L1b17:  push    hl
L1b18:  ld      bc,($b6a1)       ; graphics window bottom edge
L1b1c:  call    L1b4f
L1b1f:  or      a
L1b20:  sbc     hl,de
L1b22:  jr      z,L1b4b          ; (+$27)
L1b24:  add     hl,de
L1b25:  call    L0c1f            ; SCR NEXT LINE
L1b28:  call    L1b34
L1b2b:  jr      z,L1b4b          ; (+$1e)
L1b2d:  xor     (hl)
L1b2e:  ld      (hl),a
L1b2f:  ex      (sp),hl
L1b30:  dec     hl
L1b31:  ex      (sp),hl
L1b32:  jr      L1b1f            ; (-$15)

;;=========================================================================

L1b34:  ld      a,($b6a3)        ; graphics pen
L1b37:  xor     (hl)
L1b38:  and     c
L1b39:  ret     z

L1b3a:  ld      a,($b6aa)
L1b3d:  xor     (hl)
L1b3e:  and     c
L1b3f:  ret     z

L1b40:  scf     
L1b41:  ret     

;;=========================================================================

L1b42:  push    bc
L1b43:  push    de
L1b44:  push    hl
L1b45:  call    L0baf            ;; SCR DOT POSITION
L1b48:  call    L1b34
L1b4b:  pop     hl
L1b4c:  pop     de
L1b4d:  pop     bc
L1b4e:  ret     

;;=========================================================================

L1b4f:  push    bc
L1b50:  push    de
L1b51:  call    L0baf            ;; SCR DOT POSITION
L1b54:  pop     de
L1b55:  ex      (sp),hl
L1b56:  call    L0baf            ;; SCR DOT POSITION
L1b59:  ex      de,hl
L1b5a:  pop     hl
L1b5b:  ret     

;;==================================================================
;; KMSE

L1b5c:  ld      hl,$1e02
L1b5f:  call    L1df6            ; KM SET DELAY
L1b62:  xor     a
L1b63:  ld      ($b655),a
L1b66:  ld      h,a
L1b67:  ld      l,a
L1b68:  ld      ($b631),hl
L1b6b:  ld      bc,$ffb0
L1b6e:  ld      de,$b5d6
L1b71:  ld      hl,$b692
L1b74:  ld      a,$04
L1b76:  ex      de,hl
L1b77:  add     hl,bc
L1b78:  ex      de,hl
L1b79:  ld      (hl),d
L1b7a:  dec     hl
L1b7b:  ld      (hl),e
L1b7c:  dec     hl
L1b7d:  dec     a
L1b7e:  jr      nz,L1b76         ; (-$0a)

;;----------------------------------
;; cord translation table
L1b80:  ld      hl,$1eef
L1b83:  ld      bc,$00fa
L1b86:  ldir    

;;----------------------------------
L1b88:  ld      b,$0a
L1b8a:  ld      de,$b635
L1b8d:  ld      hl,$b63f
L1b90:  xor     a
L1b91:  ld      (de),a
L1b92:  inc     de
L1b93:  ld      (hl),$ff
L1b95:  inc     hl
L1b96:  djnz    $1b91            ; (-$07)
;;----------------------------------

;;==================================================================
;; KM

L1b98:  call    L1e75
L1b9b:  call    L1bf8            ; reset returned key (KM CHAR RETURN)
L1b9e:  ld      de,$b590
L1ba1:  ld      hl,$0098
L1ba4:  call    L1c0a

L1ba7:  ld      hl,$1bb3         ; table used to initialise keyboard manager indirections
L1baa:  call    L0ab4            ; initialise keyboard manager indirections (KM TEST BREAK)
L1bad:  call    L0ab4            ; initialise keyboard manager indirections (KM SCAN KEYS)
L1bb0:  jp      L1e0b            ; KM DISARM BREAK

L1bb3:: defb $3
        defw $bdee                              ; IND: KM TEST BREAK
        jp      L1db8
        defb $3
        defw $bdf4                              ; IND: KM SCAN KEYS
        jp      L1d40

;;==================================================================
;; KMR

L1bbf:  call    L1bc5            ; KM READ CHAR
L1bc2:  jr      nc,L1bbf         
L1bc4:  ret     

;;==================================================================
;; KMR

L1bc5:  push    hl
L1bc6:  ld      hl,$b62a         ; returned char
L1bc9:  ld      a,(hl)           ; get char
L1bca:  ld      (hl),$ff         ; reset state
L1bcc:  cp      (hl)             ; was a char returned?
L1bcd:  jr      c,L1bf6          ; a key was put back into buffer, return without expanding it

;; arnding?
L1bcf:  ld      hl,($b628)
L1bd2:  ld      a,h
L1bd3:  or      a
L1bd4:  jr      nz,L1be7         ; continue expansion

L1bd6:  call    L1ce1            ; KM READ KEY
L1bd9:  jr      nc,L1bf6         ; (+$1b)
L1bdb:  cp      $80
L1bdd:  jr      c,L1bf6          ; (+$17)
L1bdf:  cp      $a0
L1be1:  ccf     
L1be2:  jr      c,L1bf6          ; (+$12)

;; besion
L1be4:  ld      h,a
L1be5:  ld      l,$00

;; copansion
L1be7:  push    de
L1be8:  call    L1cb3            ; KM GET EXPAND
L1beb:  jr      c,L1bef          

;; wrsion pointer
L1bed:  ld      h,$00
L1bef:  inc     l
L1bf0:  ld      ($b628),hl
L1bf3:  pop     de
L1bf4:  jr      nc,L1bd6         
L1bf6:  pop     hl
L1bf7:  ret     

;==================================================================
;; rened key
L1bf8:  ld      a,$ff

;;==================================================================
;; KMURN

L1bfa:  ld      ($b62a),a
L1bfd:  ret     

;;==================================================================
;; KM

L1bfe:  call    L1bc5            ; KM READ CHAR
L1c01:  jr      c,L1bfe          
L1c03:  ret     

;;==================================================================
;; KMER

L1c04:  call    L1c0a
L1c07:  ccf     
L1c08:  ei      
L1c09:  ret     

;;==================================================================

L1c0a:  di      
L1c0b:  ld      a,l
L1c0c:  sub     $31
L1c0e:  ld      a,h
L1c0f:  sbc     a,$00
L1c11:  ret     c

L1c12:  add     hl,de
L1c13:  ld      ($b62d),hl
L1c16:  ex      de,hl
L1c17:  ld      ($b62b),hl
L1c1a:  ld      bc,$0a30
L1c1d:  ld      (hl),$01
L1c1f:  inc     hl
L1c20:  ld      (hl),c
L1c21:  inc     hl
L1c22:  inc     c
L1c23:  djnz    $1c1d            ; (-$08)
L1c25:  ex      de,hl

L1c26:  ld      hl,$1c3c                 ;; default expansion values
L1c29:  ld      c,$0a
L1c2b:  ldir    

L1c2d:  ex      de,hl
L1c2e:  ld      b,$13
L1c30:  xor     a
L1c31:  ld      (hl),a
L1c32:  inc     hl
L1c33:  djnz    $1c31            ; (-$04)
L1c35:  ld      ($b62f),hl
L1c38:  ld      ($b629),a
L1c3b:  ret     

L1c3c:  defb $01
        defb "."
        defb $01
        defb 13
        defb $5
        defb "RUN\"",13

;;==================================================================
;; KMND
L1c46:  ld       a,b
L1c47:  call    L1cc3
L1c4a:  ret     nc

L1c4b:  push    bc
L1c4c:  push    de
L1c4d:  push    hl
L1c4e:  call    L1c6a
L1c51:  ccf     
L1c52:  pop     hl
L1c53:  pop     de
L1c54:  pop     bc
L1c55:  ret     nc

L1c56:  dec     de
L1c57:  ld      a,c
L1c58:  inc     c
L1c59:  ld      (de),a
L1c5a:  inc     de
L1c5b:  rst     $20              ; RST 4 - LOW: RAM LAM
L1c5c:  inc     hl
L1c5d:  dec     c
L1c5e:  jr      nz,L1c59         ; (-$07)
L1c60:  ld      hl,$b629
L1c63:  ld      a,b
L1c64:  xor     (hl)
L1c65:  jr      nz,L1c68         ; (+$01)
L1c67:  ld      (hl),a
L1c68:  scf     
L1c69:  ret     

;;==================================================================
L1c6a:  ld      b,$00
L1c6c:  ld      h,b
L1c6d:  ld      l,a
L1c6e:  ld      a,c
L1c6f:  sub     l
L1c70:  ret     z

L1c71:  jr      nc,L1c82         ; (+$0f)
L1c73:  ld      a,l
L1c74:  ld      l,c
L1c75:  ld      c,a
L1c76:  add     hl,de
L1c77:  ex      de,hl
L1c78:  add     hl,bc
L1c79:  call    L1ca7                        
L1c7c:  jr      z,L1ca1          ; (+$23)
L1c7e:  ldir    
L1c80:  jr      L1ca1            ; (+$1f)
L1c82:  ld      c,a
L1c83:  add     hl,de
L1c84:  push    hl
L1c85:  ld      hl,($b62f)
L1c88:  add     hl,bc
L1c89:  ex      de,hl
L1c8a:  ld      hl,($b62d)
L1c8d:  ld      a,l
L1c8e:  sub     e
L1c8f:  ld      a,h
L1c90:  sbc     a,d
L1c91:  pop     hl
L1c92:  ret     c

L1c93:  call    L1ca7            
L1c96:  ld      hl,($b62f)
L1c99:  jr      z,L1ca1          ; (+$06)
L1c9b:  push    de
L1c9c:  dec     de
L1c9d:  dec     hl
L1c9e:  lddr    
L1ca0:  pop     de
L1ca1:  ld      ($b62f),de
L1ca5:  or      a
L1ca6:  ret     

;;==================================================================

L1ca7:  ld      a,($b62f)
L1caa:  sub     l
L1cab:  ld      c,a
L1cac:  ld      a,($b630)
L1caf:  sbc     a,h
L1cb0:  ld      b,a
L1cb1:  or      c
L1cb2:  ret     

;;==================================================================
;; KMND

L1cb3:  call    L1cc3
L1cb6:  ret     nc

L1cb7:  cp      l
L1cb8:  ret     z

L1cb9:  ccf     
L1cba:  ret     nc

L1cbb:  push    hl
L1cbc:  ld      h,$00
L1cbe:  add     hl,de
L1cbf:  ld      a,(hl)
L1cc0:  pop     hl
L1cc1:  scf     
L1cc2:  ret     

;;==================================================================

;; keve $7f not defineable?
L1cc3:  and     $7f
;; ken $20-$7f are not defineable?
L1cc5:  cp      $20
L1cc7:  ret     nc

L1cc8:  push    hl
L1cc9:  ld      hl,($b62b)
L1ccc:  ld      de,$0000
L1ccf:  inc     a
L1cd0:  add     hl,de
L1cd1:  ld      e,(hl)
L1cd2:  inc     hl
L1cd3:  dec     a
L1cd4:  jr      nz,L1cd0         ; (-$06)
L1cd6:  ld      a,e
L1cd7:  ex      de,hl
L1cd8:  pop     hl
L1cd9:  scf     
L1cda:  ret     

;;==================================================================
;; KM

L1cdb:  call    L1ce1            ; KM READ KEY
L1cde:  jr      nc,L1cdb         
L1ce0:  ret     

;;==================================================================
;; KM

L1ce1:  push    hl
L1ce2:  push    bc
L1ce3:  call    L1e9d
L1ce6:  jr      nc,L1d22         ; (+$3a)
L1ce8:  ld      a,c
L1ce9:  cp      $ef
L1ceb:  jr      z,L1d21          ; (+$34)
L1ced:  and     $0f
L1cef:  add     a,a
L1cf0:  add     a,a
L1cf1:  add     a,a
L1cf2:  dec     a
L1cf3:  inc     a
L1cf4:  rrc     b
L1cf6:  jr      nc,L1cf3         ; (-$05)
L1cf8:  call    L1d25
L1cfb:  ld      hl,$b632
L1cfe:  bit     7,(hl)
L1d00:  jr      z,L1d0c          ; (+$0a)
L1d02:  cp      $61
L1d04:  jr      c,L1d0c          ; (+$06)
L1d06:  cp      $7b
L1d08:  jr      nc,L1d0c         ; (+$02)
L1d0a:  add     a,$e0
L1d0c:  cp      $ff
L1d0e:  jr      z,L1ce3          ; (-$2d)
L1d10:  cp      $fe
L1d12:  ld      hl,$b631
L1d15:  jr      z,L1d1c          ; (+$05)
L1d17:  cp      $fd
L1d19:  inc     hl
L1d1a:  jr      nz,L1d21         ; (+$05)
L1d1c:  ld      a,(hl)
L1d1d:  cpl     
L1d1e:  ld      (hl),a
L1d1f:  jr      L1ce3            ; (-$3e)
L1d21:  scf     
L1d22:  pop     bc
L1d23:  pop     hl
L1d24:  ret     

;;==================================================================

L1d25:  rl      c
L1d27:  jp      c,L1ece          ; KM GET CONTROL
L1d2a:  ld      b,a
L1d2b:  ld      a,($b631)
L1d2e:  or      c
L1d2f:  and     $40
L1d31:  ld      a,b
L1d32:  jp      nz,L1ec9         ; KM GET SHIFT
L1d35:  jp      L1ec4            ; KM GET TRANSLATE

;;==================================================================
;; KME

L1d38:  ld      hl,($b631)
L1d3b:  ret     

;;==================================================================
;; KMS

L1d3c:  ld      ($b631),hl
L1d3f:  ret     

;;==================================================================
;; INN KEYS

L1d40:  ld      de,$b649         ; buffer for keys that have changed
L1d43:  ld      hl,$b63f         ; buffer for current state of key matrix
                               ; if a bit is '0' then key is pressed,
                               ; if a bit is '1' then key is released.
L1d46:  call    L0883            ; scan keyboard

;;b63
;;b63
;;b64eyboard line 0-10 inclusive)

L1d49:  ld      a,($b64b)        ; keyboard line 2
L1d4c:  and     $a0              ; isolate change state of CTRL and SHIFT keys
L1d4e:  ld      c,a

L1d4f:  ld      hl,$b637
L1d52:  or      (hl)
L1d53:  ld      (hl),a

;;-------------------------------------------------------------
L1d54:  ld      hl,$b649
L1d57:  ld      de,$b635
L1d5a:  ld      b,$00

L1d5c:  ld      a,(de)
L1d5d:  xor     (hl)
L1d5e:  and     (hl)
L1d5f:  call    nz,L1dd1
L1d62:  ld      a,(hl)
L1d63:  ld      (de),a
L1d64:  inc     hl
L1d65:  inc     de
L1d66:  inc     c
L1d67:  ld      a,c
L1d68:  and     $0f
L1d6a:  cp      $0a
L1d6c:  jr      nz,L1d5c         ; (-$12)

;;------------------------------------------------------------

L1d6e:  ld      a,c
L1d6f:  and     $a0
L1d71:  bit     6,c
L1d73:  ld      c,a
L1d74:  call    nz,$bdee         ; IND: KM TEST BREAK
L1d77:  ld      a,b
L1d78:  or      a
L1d79:  ret     nz

L1d7a:  ld      hl,$b653
L1d7d:  dec     (hl)
L1d7e:  ret     nz

L1d7f:  ld      hl,($b654)
L1d82:  ex      de,hl
L1d83:  ld      b,d
L1d84:  ld      d,$00
L1d86:  ld      hl,$b635
L1d89:  add     hl,de
L1d8a:  ld      a,(hl)
L1d8b:  ld      hl,($b691)
L1d8e:  add     hl,de
L1d8f:  and     (hl)
L1d90:  and     b
L1d91:  ret     z

L1d92:  ld      hl,$b653
L1d95:  inc     (hl)
L1d96:  ld      a,($b68a)
L1d99:  or      a
L1d9a:  ret     nz

L1d9b:  ld      a,c
L1d9c:  or      e
L1d9d:  ld      c,a
L1d9e:  ld      a,($b633)

L1da1:  ld      ($b653),a
L1da4:  call    L1e86
L1da7:  ld      a,c
L1da8:  and     $0f
L1daa:  ld      l,a
L1dab:  ld      h,b
L1dac:  ld      ($b654),hl

L1daf:  cp      $08
L1db1:  ret     nz

L1db2:  bit     4,b
L1db4:  ret     nz

L1db5:  set     6,c
L1db7:  ret     

;;============================================================================
;; INT BREAK

L1db8:  ld      hl,$b63d
L1dbb:  bit     2,(hl)
L1dbd:  ret     z

L1dbe:  ld      a,c
L1dbf:  xor     $a0
L1dc1:  jr      nz,L1e19         ; KM BREAK EVENT
L1dc3:  push    bc
L1dc4:  inc     hl
L1dc5:  ld      b,$0a
L1dc7:  adc     a,(hl)
L1dc8:  dec     hl
L1dc9:  djnz    $1dc7            ; (-$04)
L1dcb:  pop     bc
L1dcc:  cp      $a4
L1dce:  jr      nz,L1e19         ; KM BREAK EVENT

;; do
L1dd0:  rst     $00

;;===========================================================

L1dd1:  push    hl
L1dd2:  push    de
L1dd3:  ld      e,a
L1dd4:  cpl     
L1dd5:  inc     a
L1dd6:  and     e
L1dd7:  ld      b,a
L1dd8:  ld      a,($b634)
L1ddb:  call    L1da1
L1dde:  ld      a,b
L1ddf:  xor     e
L1de0:  jr      nz,L1dd3         ; (-$0f)
L1de2:  pop     de
L1de3:  pop     hl
L1de4:  ret     

;;==================================================================
;; KMTICK

L1de5:  ld      a,($b63b)
L1de8:  and     $7f
L1dea:  ld      l,a
L1deb:  ld      a,($b63e)
L1dee:  and     $7f
L1df0:  ld      h,a
L1df1:  ret     

;;==================================================================
;; KMY

L1df2:  ld      hl,($b633)
L1df5:  ret     

;;==================================================================
;; KMY

L1df6:  ld      ($b633),hl
L1df9:  ret     

;;==================================================================
;; KMK

L1dfa:  call    L1e0b            ; KM DISARM BREAK
L1dfd:  ld      hl,$b657
L1e00:  ld      b,$40
L1e02:  call    L01d2            ; KL INIT EVENT
L1e05:  ld      a,$ff
L1e07:  ld      ($b656),a
L1e0a:  ret     

;;==================================================================
;; KMREAK

L1e0b:  push    bc
L1e0c:  push    de
L1e0d:  ld      hl,$b656
L1e10:  ld      (hl),$00
L1e12:  inc     hl
L1e13:  call    L0284            ; KL DEL SYNCHRONOUS
L1e16:  pop     de
L1e17:  pop     bc
L1e18:  ret     

;;==================================================================
;; KMENT

L1e19:  ld      hl,$b656
L1e1c:  ld      a,(hl)
L1e1d:  ld      (hl),$00
L1e1f:  cp      (hl)
L1e20:  ret     z

L1e21:  push    bc
L1e22:  push    de
L1e23:  inc     hl
L1e24:  call    L01e2            ; KL EVENT
L1e27:  ld      c,$ef
L1e29:  call    L1e86
L1e2c:  pop     de
L1e2d:  pop     bc
L1e2e:  ret     

;;==================================================================
;; KMAT

L1e2f:  ld      hl,($b691)
L1e32:  jr      L1e50            ; (+$1c)

;;==================================================================
;; KMAT

L1e34:  cp      $50
L1e36:  ret     nc

L1e37:  ld      hl,($b691)
L1e3a:  call    L1e55
L1e3d:  cpl     
L1e3e:  ld      c,a
L1e3f:  ld      a,(hl)
L1e40:  xor     b
L1e41:  and     c
L1e42:  xor     b
L1e43:  ld      (hl),a
L1e44:  ret     

;;==================================================================
;; KM

L1e45:  push    af
L1e46:  ld      a,($b637)
L1e49:  and     $a0
L1e4b:  ld      c,a
L1e4c:  pop     af
L1e4d:  ld      hl,$b635
L1e50:  call    L1e55
L1e53:  and     (hl)
L1e54:  ret     

;;==================================================================

L1e55:  push    de
L1e56:  push    af
L1e57:  and     $f8
L1e59:  rrca    
L1e5a:  rrca    
L1e5b:  rrca    
L1e5c:  ld      e,a
L1e5d:  ld      d,$00
L1e5f:  add     hl,de
L1e60:  pop     af

L1e61:  push    hl
L1e62:  ld      hl,$1e6d
L1e65:  and     $07
L1e67:  ld      e,a
L1e68:  add     hl,de
L1e69:  ld      a,(hl)
L1e6a:  pop     hl
L1e6b:  pop     de
L1e6c:  ret     

;;==================================================================
;; tanvert from bit index (0-7) to bit OR mask (1<<bit index)
L1e6d:  defb $01,$02,$04,$08,$10,$20,$40,$80
;;==================================================================

L1e75:  di      
L1e76:  ld      hl,$b686
L1e79:  ld      (hl),$15
L1e7b:  inc     hl
L1e7c:  xor     a
L1e7d:  ld      (hl),a
L1e7e:  inc     hl
L1e7f:  ld      (hl),$01
L1e81:  inc     hl
L1e82:  ld      (hl),a
L1e83:  inc     hl
L1e84:  ld      (hl),a
L1e85:  ret     

;;==================================================================

L1e86:  ld      hl,$b686
L1e89:  or      a
L1e8a:  dec     (hl)
L1e8b:  jr      z,L1e9b          ; (+$0e)
L1e8d:  call    L1eb4
L1e90:  ld      (hl),c
L1e91:  inc     hl
L1e92:  ld      (hl),b
L1e93:  ld      hl,$b68a
L1e96:  inc     (hl)
L1e97:  ld      hl,$b688
L1e9a:  scf     
L1e9b:  inc     (hl)
L1e9c:  ret     

;;==================================================================
L1e9d:  ld      hl,$b688
L1ea0:  or      a
L1ea1:  dec     (hl)
L1ea2:  jr      z,L1eb2          ; (+$0e)
L1ea4:  call    L1eb4
L1ea7:  ld      c,(hl)
L1ea8:  inc     hl
L1ea9:  ld      b,(hl)
L1eaa:  ld      hl,$b68a
L1ead:  dec     (hl)
L1eae:  ld      hl,$b686
L1eb1:  scf     
L1eb2:  inc     (hl)
L1eb3:  ret     

;;==================================================================
L1eb4:  inc     hl
L1eb5:  inc     (hl)
L1eb6:  ld      a,(hl)
L1eb7:  cp      $14
L1eb9:  jr      nz,L1ebd         ; (+$02)

L1ebb:  xor     a
L1ebc:  ld      (hl),a

L1ebd:  add     a,a
L1ebe:  add     a,$5e
L1ec0:  ld      l,a
L1ec1:  ld      h,$b6
L1ec3:  ret     

;;==================================================================
;; KMSLATE

L1ec4:  ld      hl,($b68b)
L1ec7:  jr      L1ed1            ; (+$08)

;;==================================================================
;; KMT

L1ec9:  ld      hl,($b68d)
L1ecc:  jr      L1ed1            ; (+$03)

;;==================================================================
;; KMROL 

L1ece:  ld      hl,($b68f)

L1ed1:  add     a,l
L1ed2:  ld      l,a
L1ed3:  adc     a,h
L1ed4:  sub     l
L1ed5:  ld      h,a
L1ed6:  ld      a,(hl)
L1ed7:  ret     

;;==================================================================
;; KMSLATE

L1ed8:  ld      hl,($b68b)
L1edb:  jr      L1ee5            ; (+$08)

;;==================================================================
;; KMT

L1edd:  ld      hl,($b68d)
L1ee0:  jr      L1ee5            ; (+$03)

;;==================================================================
;; KMROL

L1ee2:  ld      hl,($b68f)
L1ee5:  cp      $50
L1ee7:  ret     nc

L1ee8:  add     a,l
L1ee9:  ld      l,a
L1eea:  adc     a,h
L1eeb:  sub     l
L1eec:  ld      h,a
L1eed:  ld      (hl),b
L1eee:  ret     

;;---------------------------------------------
;; keanslation table
        defb    $F0, $F3, $F1, $89, $86, $83, $8B, $8A
        defb    $F2, $E0, $87, $88, $85, $81, $82, $80
        defb    $10, $5B, $0D, $5D, $84, $FF, $5C, $FF
        defb    $5E, $2D, $40, $70, $3B, $3A, $2F, $2E
        defb    $30, $39, $6F, $69, $6C, $6B, $6D, $2C
        defb    $38, $37, $75, $79, $68, $6A, $6E, $20
        defb    $36, $35, $72, $74, $67, $66, $62, $76
        defb    $34, $33, $65, $77, $73, $64, $63, $78
        defb    $31, $32, $FC, $71, $09, $61, $FD, $7A
        defb    $0B, $0A, $08, $09, $58, $5A, $FF, $7F
        defb    $F4, $F7, $F5, $89, $86, $83, $8B, $8A
        defb    $F6, $E0, $87, $88, $85, $81, $82, $80
        defb    $10, $7B, $0D, $7D, $84, $FF, $60, $FF
        defb    $A3, $3D, $7C, $50, $2B, $2A, $3F, $3E
        defb    $5F, $29, $4F, $49, $4C, $4B, $4D, $3C
        defb    $28, $27, $55, $59, $48, $4A, $4E, $20
        defb    $26, $25, $52, $54, $47, $46, $42, $56
        defb    $24, $23, $45, $57, $53, $44, $43, $58
        defb    $21, $22, $FC, $51, $09, $41, $FD, $5A
        defb    $0B, $0A, $08, $09, $58, $5A, $FF, $7F
        defb    $F8, $FB, $F9, $89, $86, $83, $8C, $8A
        defb    $FA, $E0, $87, $88, $85, $81, $82, $80
        defb    $10, $1B, $0D, $1D, $84, $FF, $1C, $FF
        defb    $1E, $FF, $00, $10, $FF, $FF, $FF, $FF
        defb    $1F, $FF, $0F, $09, $0C, $0B, $0D, $FF
        defb    $FF, $FF, $15, $19, $08, $0A, $0E, $FF
        defb    $FF, $FF, $12, $14, $07, $06, $02, $16
        defb    $FF, $FF, $05, $17, $13, $04, $03, $18
        defb    $FF, $7E, $FC, $11, $E1, $01, $FE, $1A
        defb    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7F
        defb    $07, $03, $4B, $FF, $FF, $FF, $FF, $FF
        defb    $AB, $8F

;;===================================================================
;; SO

;; foannel:
;; $0el number (0,1,2)
;; $0 value for tone (also used for active mask)
;; $0 value for noise
;; $0s
;; st0=rendezvous channel A
;; st1=rendezvous channel B
;; st2=rendezvous channel C
;; st3=hold

;; $0 = tone envelope active
;; $0 = volume envelope active

;; $0uration of sound or envelope repeat count
;; $0olume envelope pointer reload
;; $0e envelope step down count
;; $0urrent volume envelope pointer
;; $0nt volume for channel (bit 7 set if has noise)
;; $1e envelope current step down count

;; $1one envelope pointer reload
;; $1r of sections in tone remaining
;; $1urrent tone pointer
;; $1yte tone for channel
;; $1byte tone for channel
;; $1envelope current step down count

;; $1position in queue
;; $1r of items in the queue
;; $1 position in queue
;; $1r of items free in queue
;; $1yte event 
;; $1byte event (set to 0 to disarm event)



L1fe9:  ld      hl,$b1ed         ; channels active at SOUND HOLD

;; cl
;; b1nels active at SOUND HOLD
;; b1d channels active
;; b1d timer?
;; b1
L1fec:  ld      b,$04
L1fee:  ld      (hl),$00     
L1ff0:  inc     hl
L1ff1:  djnz    $1fee            

;; HL block (b1f1)
L1ff3:  ld      de,$208b         ;; sound event function
L1ff6:  ld      b,$81            ;; asynchronous event, near address
                               ;; C = rom select, but unused because it's a near address
L1ff8:  call    L01d2            ; KL INIT EVENT

L1ffb:  ld      a,$3f            ; default mixer value (noise/tone off + I/O)
L1ffd:  ld      ($b2b5),a

L2000:  ld      hl,$b1f8         ;; data for channel A
L2003:  ld      bc,$003d         ;; size of data for each channel
L2006:  ld      de,$0108         ;; D = mixer value for tone (channel A)
                               ;; E = mixer value for noise (channel A)

;; inchannel data
L2009:  xor     a

L200a:  ld      (hl),a           ;; channel number
L200b:  inc     hl
L200c:  ld      (hl),d           ;; mixer tone for channel
L200d:  inc     hl
L200e:  ld      (hl),e           ;; mixer noise for channel
L200f:  add     hl,bc            ;; update channel data pointer

L2010:  inc     a                ;; increment channel number

L2011:  ex      de,hl            ;; update tone/noise mixer for next channel shifting it left once
L2012:  add     hl,hl
L2013:  ex      de,hl

L2014:  cp      $03              ;; setup all channels?
L2016:  jr      nz,L200a         

L2018:  ld      c,$07            ; all channels active
L201a:  push    ix
L201c:  push    hl
L201d:  ld      hl,$b1f0
L2020:  inc     (hl)
L2021:  push    hl
L2022:  ld      ix,$b1b9
L2026:  ld      a,c              ; channels active

L2027:  call    L2209            ;; get next active channel
L202a:  push    af
L202b:  push    bc
L202c:  call    L2286            ;; update channels that are active
L202f:  call    L23e7            ;; disable channel
L2032:  push    ix
L2034:  pop     de
L2035:  inc     de
L2036:  inc     de
L2037:  inc     de
L2038:  ld      l,e
L2039:  ld      h,d
L203a:  inc     de
L203b:  ld      bc,$003b
L203e:  ld      (hl),$00
L2040:  ldir    
L2042:  ld      (ix+$1c),$04     ;; number of spaces in queue
L2046:  pop     bc
L2047:  pop     af
L2048:  jr      nz,L2027         ; (-$23)


L204a:  pop     hl
L204b:  dec     (hl)
L204c:  pop     hl
L204d:  pop     ix
L204f:  ret     

;;=================================================================
;; SO
;;
;; - ware handling sound
;; - all volume registers
;;
;; ca - already stopped
;; ca- sound has been held
L2050:  ld      hl,$b1ee             ;; sound channels active
L2053:  di      
L2054:  ld      a,(hl)               ;; get channels that were active
L2055:  ld      (hl),$00             ;; no channels active
L2057:  ei      
L2058:  or      a                    ;; already stopped?
L2059:  ret     z

L205a:  dec     hl                   
L205b:  ld      (hl),a               ;; channels held

;; sevolume registers to zero to silence sound
L205c:  ld      l,$03
L205e:  ld      c,$00            ; set zero volume

L2060:  ld      a,$07            ; AY Mixer register
L2062:  add     a,l              ; add on value to get volume register
                               ; A = AY volume register (10,9,8)
L2063:  call    L0863            ; MC SOUND REGISTER
L2066:  dec     l
L2067:  jr      nz,L2060         
 
L2069:  scf     
L206a:  ret     


;;=================================================================
;; SONUE

L206b:  ld      de,$b1ed ;; channels active at SOUND HELD
L206e:  ld      a,(de)
L206f:  or      a
L2070:  ret     z

;; ate channel was held

L2071:  push    de
L2072:  ld      ix,$b1b9
L2076:  call    L2209            ; get next active channel
L2079:  push    af
L207a:  ld      a,(ix+$0f)       ; volume for channel
L207d:  call    c,L23de          ; set channel volume
L2080:  pop     af
L2081:  jr      nz,L2076         ;repeat next held channel

L2083:  ex      (sp),hl
L2084:  ld      a,(hl)
L2085:  ld      (hl),$00
L2087:  inc     hl
L2088:  ld      (hl),a
L2089:  pop     hl
L208a:  ret     

;;======================================================================
;; sossing function

L208b:  push    ix
L208d:  ld      a,($b1ee)        ; sound channels active
L2090:  or      a
L2091:  jr      z,L20d0          

;; A  to process
L2093:  push    af
L2094:  ld      ix,$b1b9
L2098:  ld      bc,$003f
L209b:  add     ix,bc
L209d:  srl     a
L209f:  jr      nc,L209b         

L20a1:  push    af
L20a2:  ld      a,(ix+$04)
L20a5:  rra     
L20a6:  call    c,L241f          ; update tone envelope

L20a9:  ld      a,(ix+$07)
L20ac:  rra     
L20ad:  call    c,L231f          ; update volume envelope

L20b0:  call    c,L2213          ; process queue
L20b3:  pop     af
L20b4:  jr      nz,L2098         ;; process next..?

L20b6:  pop     bc
L20b7:  ld      a,($b1ee)        ; sound channels active
L20ba:  cpl     
L20bb:  and     b
L20bc:  jr      z,L20d0          ; (+$12)

L20be:  ld      ix,$b1b9
L20c2:  ld      de,$003f
L20c5:  add     ix,de
L20c7:  srl     a
L20c9:  push    af
L20ca:  call    c,L23e7          ; mixer
L20cd:  pop     af
L20ce:  jr      nz,L20c5         ; (-$0b)

;; ??
L20d0:  xor     a
L20d1:  ld      ($b1f0),a
L20d4:  pop     ix
L20d6:  ret     

;;---------------------------------------------------------
;; prnd

L20d7:  ld      hl,$b1ee     ;; sound active flag?
L20da:  ld      a,(hl)
L20db:  or      a
L20dc:  ret     z
;; sotive

L20dd:  inc     hl           ;; sound timer?
L20de:  dec     (hl)
L20df:  ret     nz

L20e0:  ld      b,a
L20e1:  inc     (hl)
L20e2:  inc     hl

L20e3:  ld      a,(hl)       ;; b1f0
L20e4:  or      a
L20e5:  ret     nz

L20e6:  dec     hl
L20e7:  ld      (hl),$03

L20e9:  ld      hl,$b1be
L20ec:  ld      de,$003f
L20ef:  xor     a
L20f0:  add     hl,de
L20f1:  srl     b
L20f3:  jr      nc,L20f0         ; (-$05)

L20f5:  dec     (hl)
L20f6:  jr      nz,L20fd         ; (+$05)
L20f8:  dec     hl
L20f9:  rlc     (hl)
L20fb:  adc     a,d
L20fc:  inc     hl
L20fd:  inc     hl
L20fe:  dec     (hl)
L20ff:  jr      nz,L2106         ; (+$05)
L2101:  inc     hl
L2102:  rlc     (hl)
L2104:  adc     a,d
L2105:  dec     hl
L2106:  dec     hl
L2107:  inc     b
L2108:  djnz    $20f0            ; (-$1a)
L210a:  or      a
L210b:  ret     z

L210c:  ld      hl,$b1f0
L210f:  ld      (hl),a
L2110:  inc     hl
;; HLblock
;; kient
L2111:  jp      L01e2            ; KL EVENT


;;===================================================================
;; SO
;; HLdata
;;bytnnel status byte 
;; bid sound to channel A
;; bid sound to channel B
;; bid sound to channel C
;; bidezvous with channel A
;; bidezvous with channel B
;; bidezvous with channel C
;; bid sound channel
;; bish sound channel

;;bytume envelope to use 
;;byte envelope to use 
;;byttone period (0 = no tone)
;;bytse period (0 = no noise)
;;bytrt volume 
;;bytduration of the sound, or envelope repeat count 


L2114:  call    L206b            ; SOUND CONTINUE
L2117:  ld      a,(hl)           ; channel status byte
L2118:  and     $07
L211a:  scf     
L211b:  ret     z

L211c:  ld      c,a
L211d:  or      (hl)
L211e:  call    m,$201a
L2121:  ld      b,c
L2122:  ld      ix,$b1b9
;; ge address
L2126:  ld      de,$003f
L2129:  xor     a

L212a:  add     ix,de
L212c:  srl     b
L212e:  jr      nc,L212a         ; (-$06)

L2130:  ld      (ix+$1e),d       ;; disarm event
L2133:  cp      (ix+$1c)         ;; number of spaces in queue
L2136:  ccf     
L2137:  sbc     a,a
L2138:  inc     b
L2139:  djnz    $212a            

L213b:  or      a
L213c:  ret     nz

L213d:  ld      b,c
L213e:  ld      a,(hl)           ;; channel status
L213f:  rra     
L2140:  rra     
L2141:  rra     
L2142:  or      b
L2143:  and     $0f
L2145:  ld      c,a
L2146:  push    hl
L2147:  ld      hl,$b1f0
L214a:  inc     (hl)
L214b:  ex      (sp),hl
L214c:  inc     hl
L214d:  ld      ix,$b1b9

L2151:  ld      de,$003f
L2154:  add     ix,de
L2156:  srl     b
L2158:  jr      nc,L2154         ; (-$06)

L215a:  push    hl
L215b:  push    bc
L215c:  ld      a,(ix+$1b)       ; write pointer in queue
L215f:  inc     (ix+$1b)         ; increment for next item
L2162:  dec     (ix+$1c)         ;; number of spaces in queue
L2165:  ex      de,hl
L2166:  call    L219c        ;; get sound queue slot
L2169:  push    hl
L216a:  ex      de,hl
L216b:  ld      a,(ix+$01)       ;; channel's active flag
L216e:  cpl     
L216f:  and     c
L2170:  ld      (de),a
L2171:  inc     de
L2172:  ld      a,(hl)
L2173:  inc     hl
L2174:  add     a,a
L2175:  add     a,a
L2176:  add     a,a
L2177:  add     a,a
L2178:  ld      b,a
L2179:  ld      a,(hl)
L217a:  inc     hl
L217b:  and     $0f
L217d:  or      b
L217e:  ld      (de),a
L217f:  inc     de
L2180:  ld      bc,$0006
L2183:  ldir    
L2185:  pop     hl
L2186:  ld      a,(ix+$1a)       ;; number of items in the queue
L2189:  inc     (ix+$1a)         
L218c:  or      (ix+$03)         ;; status
L218f:  call    z,L221f
L2192:  pop     bc
L2193:  pop     hl
L2194:  inc     b
L2195:  djnz    $2151            

L2197:  ex      (sp),hl
L2198:  dec     (hl)
L2199:  pop     hl
L219a:  scf     
L219b:  ret     

;; A n queue
L219c:  and     $03
L219e:  add     a,a      
L219f:  add     a,a
L21a0:  add     a,a
L21a1:  add     a,$1f
L21a3:  push    ix
L21a5:  pop     hl
L21a6:  add     a,l
L21a7:  ld      l,a
L21a8:  adc     a,h
L21a9:  sub     l
L21aa:  ld      h,a
L21ab:  ret     

;;=================================================================
;; SOSE

L21ac:  ld      l,a
L21ad:  call    L206b            ; SOUND CONTINUE
L21b0:  ld      a,l
L21b1:  and     $07
L21b3:  ret     z

L21b4:  ld      hl,$b1f0
L21b7:  inc     (hl)
L21b8:  push    hl
L21b9:  ld      ix,$b1b9
L21bd:  call    L2209            ; get next active channel
L21c0:  push    af
L21c1:  bit     3,(ix+$03)        ; held?
L21c5:  call    nz,L2219          ; process queue item
L21c8:  pop     af
L21c9:  jr      nz,L21bd         ; (-$0e)
L21cb:  pop     hl
L21cc:  dec     (hl)
L21cd:  ret     


;;===================================================================
;; SO
;; in
;; binnel 0
;; binnel 1
;; binnel 2
;;
;; re
;; xxnot allowed
;; xx0
;; xx1
;; xx0
;; xx2
;; xx0
;; xx1
;; xx2
;; ou
;;bit- the number of free spaces in the sound queue 
;;bitng to rendezvous with channel A 
;;bitng to rendezvous with channel B 
;;bitng to rendezvous with channel C 
;;biting the channel 
;;bitucing a sound 

L21ce:  and     $07
L21d0:  ret     z

L21d1:  ld      hl,$b1bc         ;; sound data - 63
L21d4:  ld      de,$003f         ;; 63

L21d7:  add     hl,de
L21d8:  rra     
L21d9:  jr      nc,L21d7        ;; bit a zero?

L21db:  di      
L21dc:  ld      a,(hl)
L21dd:  add     a,a      ;; x2
L21de:  add     a,a      ;; x4
L21df:  add     a,a      ;; x8
L21e0:  ld      de,$0019
L21e3:  add     hl,de
L21e4:  or      (hl)
L21e5:  inc     hl
L21e6:  inc     hl
L21e7:  ld      (hl),$00
L21e9:  ei      
L21ea:  ret     

;;===================================================================
;; SOVENT
;; 
;; Seevent which will be activated when a space occurs in a sound queue.
;; if space the event is kicked immediately.
;;
;;
;; A:
;; binnel 0
;; binnel 1
;; binnel 2
;; 
;; re
;; xxnot allowed
;; xx0
;; xx1
;; xx0
;; xx2
;; xx0
;; xx1
;; xx2
;;
;; HLfunction
L21eb:  and     $07
L21ed:  ret     z

L21ee:  ex      de,hl            ;; DE = event function

;; ge of data
L21ef:  ld      hl,$b1d5
L21f2:  ld      bc,$003f
L21f5:  add     hl,bc
L21f6:  rra     
L21f7:  jr      nc,L21f5         

L21f9:  xor     a                ;; 0=no space in queue. !=0  space in the queue
L21fa:  di                       ;; stop event processing changing the value (this is a data fence)
L21fb:  cp      (hl)             ;; +$1c -> number of events remaining in queue
L21fc:  jr      nz,L21ff         ;; if it has space, disarm and call

;; no the queue, arm the event
L21fe:  ld      a,d

;; wrion
L21ff:  inc     hl
L2200:  ld      (hl),e           ;; +$1d
L2201:  inc     hl
L2202:  ld      (hl),a           ;; +$1e if zero means event is disarmed
L2203:  ei      
L2204:  ret     z                ;; queue is full
;; qupace
L2205:  ex      de,hl             
L2206:  jp      L01e2            ; KL EVENT

;;=========================================================================
;; getive channel
;; A  mask (updated)
;; IXl pointer
L2209:  ld      de,$003f         ; 63
L220c:  add     ix,de
L220e:  srl     a
L2210:  ret     c
L2211:  jr      L220c            ; (-$07)

;;=========================================================================

L2213:  ld      a,(ix+$1a)       ; has items in the queue
L2216:  or      a
L2217:  jr      z,L2286          

;; prue item
L2219:  ld      a,(ix+$19)       ; read pointer in queue
L221c:  call    L219c            ; get sound queue slot

;;-------------------
L221f:  ld      a,(hl)           ; channel status byte
;; bizvous channel A
;; bizvous channel B
;; bizvous channel C
;; bi
L2220:  or      a
L2221:  jr      z,L2230          

L2223:  bit     3,a              ; hold channel?
L2225:  jr      nz,L2280         ; 

L2227:  push    hl
L2228:  ld      (hl),$00
L222a:  call    L2290            ; process rendezvous
L222d:  pop     hl
L222e:  jr      nc,L2286         

L2230:  ld      (ix+$03),$10     ; playing

L2234:  inc     hl
L2235:  ld      a,(hl)           ;   
L2236:  and     $f0
L2238:  push    af
L2239:  xor     (hl)
L223a:  ld      e,a              ; tone envelope number
L223b:  inc     hl
L223c:  ld      c,(hl)           ; tone low
L223d:  inc     hl
L223e:  ld      d,(hl)           ; tone period high
L223f:  inc     hl

L2240:  or      d                ; tone period set?
L2241:  or      c
L2242:  jr      z,L224c          
;; 
L2244:  push    hl
L2245:  call    L2408            ; set tone and tone envelope    
L2248:  ld      d,(ix+$01)       ; tone mixer value
L224b:  pop     hl

L224c:  ld      c,(hl)           ; noise
L224d:  inc     hl
L224e:  ld      e,(hl)           ; start volume
L224f:  inc     hl
L2250:  ld      a,(hl)           ; duration of sound or envelope repeat count
L2251:  inc     hl
L2252:  ld      h,(hl)
L2253:  ld      l,a
L2254:  pop     af
L2255:  call    L22de            ;; set noise

L2258:  ld      hl,$b1ee         ;; channel active flag
L225b:  ld      b,(ix+$01)       ;; channels' active flag
L225e:  ld      a,(hl)
L225f:  or      b
L2260:  ld      (hl),a
L2261:  xor     b
L2262:  jr      nz,L2267         ; (+$03)

L2264:  inc     hl
L2265:  ld      (hl),$03

L2267:  inc     (ix+$19)         ;; increment read position in queue
L226a:  dec     (ix+$1a)         ;; number of items in the queue
;; 
L226d:  inc     (ix+$1c)         ;; increase space in the queue

;; thspace in the queue...
L2270:  ld      a,(ix+$1e)       ;; high byte of event (0=disarmed)
L2273:  ld      (ix+$1e),$00     ;; disarm event
L2277:  or      a
L2278:  ret     z

;; evmed, kick it off.
L2279:  ld      h,a
L227a:  ld      l,(ix+$1d)
L227d:  jp      L01e2            ; KL EVENT

;;====================================================================

;; ?
L2280:  res     3,(hl)
L2282:  ld      (ix+$03),$08     ;; held

;; st
L2286:  ld      hl,$b1ee         ;; sound channels active flag
L2289:  ld      a,(ix+$01)       ;; channels' active flag
L228c:  cpl     
L228d:  and     (hl)
L228e:  ld      (hl),a
L228f:  ret     

;;=====================================================
;; prdezvous
L2290:  push    ix
L2292:  ld      b,a
L2293:  ld      c,(ix+$01)       ;; channels' active flag
L2296:  ld      ix,$b1f8         ;; channel A's data
L229a:  bit     0,a
L229c:  jr      nz,L22aa         

L229e:  ld      ix,$b237         ;; channel B's data
L22a2:  bit     1,a
L22a4:  jr      nz,L22aa        
L22a6:  ld      ix,$b276         ;; channel C's data

L22aa:  ld      a,(ix+$03)       ; channels' rendezvous flags
L22ad:  and     c                ; ignore rendezvous with self.
L22ae:  jr      z,L22d7
     
L22b0:  ld      a,b
L22b1:  cp      (ix+$01)         ; channels' active flag
L22b4:  jr      z,L22cf          ; ignore rendezvous with self (process own queue)

L22b6:  push    ix
L22b8:  ld      ix,$b276         ; channel C's data
L22bc:  bit     2,a              ; rendezvous channel C
L22be:  jr      nz,L22c4         
L22c0:  ld      ix,$b237         ; channel B's data

L22c4:  ld      a,(ix+$03)       ; channels' rendezvous flags
L22c7:  and     c                ; ignore rendezvous with self.
L22c8:  jr      z,L22d6          
;; prother

L22ca:  call    L2219            ; process queue item
L22cd:  pop     ix
L22cf:  call    L2219            ; process queue item
L22d2:  pop     ix
L22d4:  scf     
L22d5:  ret     

L22d6:  pop     hl
L22d7:  pop     ix
L22d9:  ld      (ix+$03),b       ; status
L22dc:  or      a
L22dd:  ret     


;;========================================================================

;; se values
;; C alue
;; E  volume
;; HLon of sound or envelope repeat count
L22de:  set     7,e
L22e0:  ld      (ix+$0f),e       ;; volume for channel?
L22e3:  ld      e,a

;; du sound or envelope repeat count
L22e4:  ld      a,l
L22e5:  or      h
L22e6:  jr      nz,L22e9        

L22e8:  dec     hl
L22e9:  ld      (ix+$08),l       ; duration of sound or envelope repeat count
L22ec:  ld      (ix+$09),h

L22ef:  ld      a,c              ; if zero do not set noise
L22f0:  or      a
L22f1:  jr      z,L22fb          

L22f3:  ld      a,$06            ; PSG noise register
L22f5:  call    L0863            ; MC SOUND REGISTER
L22f8:  ld      a,(ix+$02)

L22fb:  or      d
L22fc:  call    L23e8            ; mixer for channel
L22ff:  ld      a,e
L2300:  or      a
L2301:  jr      z,L230d          

L2303:  ld      hl,$b2a6
L2306:  ld      d,$00
L2308:  add     hl,de
L2309:  ld      a,(hl)           
L230a:  or      a
L230b:  jr      nz,L2310         

L230d:  ld      hl,$231b         ; default volume envelope   
L2310:  ld      (ix+$0a),l
L2313:  ld      (ix+$0b),h
L2316:  call    L23cd            ; set volume envelope?
L2319:  jr      L2328            ; (+$0d)

;;========================================================================
;; deume envelope
L231b:  defb 1 ;; step count
        defb 1 ;; step size
        defb 0 ;; pause time

;; un
        defb $c8

;;========================================================================
;; upme envelope
L231f:  ld      l,(ix+$0d)       ; volume envelope pointer
L2322:  ld      h,(ix+$0e)
L2325:  ld      e,(ix+$10)       ; step count    

L2328:  ld      a,e
L2329:  cp      $ff
L232b:  jr      z,L23a2          ; no tone/volume envelopes active


L232d:  add     a,a              
L232e:  ld      a,(hl)           ; reload envelope shape/step count
L232f:  inc     hl
L2330:  jr      c,L237b          ; set hardware envelope (HL) = hardware envelope value
L2332:  jr      z,L2340          ; set volume

L2334:  dec     e                ; decrease step count

L2335:  ld      c,(ix+$0f)       ;; 
L2338:  or      a
L2339:  jr      nz,L233f         ;

L233b:  bit     7,c              ; has noise
L233d:  jr      z,L2345          ;       

;; 
L233f:  add     a,c


L2340:  and     $0f
L2342:  call    L23db            ; write volume for channel and store

L2345:  ld      c,(hl)
L2346:  ld      a,(ix+$09)
L2349:  ld      b,a
L234a:  add     a,a
L234b:  jr      c,L2368          ; (+$1b)
L234d:  xor     a
L234e:  sub     c
L234f:  add     a,(ix+$08)
L2352:  jr      c,L2360          ; (+$0c)
L2354:  dec     b
L2355:  jp      p,L235d
L2358:  ld      c,(ix+$08)
L235b:  xor     a
L235c:  ld      b,a
L235d:  ld      (ix+$09),b
L2360:  ld      (ix+$08),a
L2363:  or      b
L2364:  jr      nz,L2368         ; (+$02)
L2366:  ld      e,$ff
L2368:  ld      a,e
L2369:  or      a
L236a:  call    z,L23ae
L236d:  ld      (ix+$10),e
L2370:  di      
L2371:  ld      (ix+$06),c
L2374:  ld      (ix+$07),$80     ; has tone envelope
L2378:  ei      
L2379:  or      a
L237a:  ret     

;; E e envelope shape
;; D e envelope period low
;; (Hware envelope period high

;; DEre envelope period
L237b:  ld      d,a
L237c:  ld      c,e
L237d:  ld      a,$0d            ; PSG hardware volume shape register
L237f:  call    L0863            ; MC SOUND REGISTER
L2382:  ld      c,d
L2383:  ld      a,$0b            ; PSG hardware volume period low
L2385:  call    L0863            ; MC SOUND REGISTER
L2388:  ld      c,(hl)
L2389:  ld      a,$0c            ; PSG hardware volume period high
L238b:  call    L0863            ; MC SOUND REGISTER
L238e:  ld      a,$10            ; use hardware envelope
L2390:  call    L23db            ; write volume for channel and store

L2393:  call    L23ae
L2396:  ld      a,e
L2397:  inc     a
L2398:  jr      nz,L2328         

L239a:  ld      hl,$231b         ; default volume envelope
L239d:  call    L23cd            ; set volume envelope
L23a0:  jr      L2328            ;

;;==============================================================

L23a2:  xor     a
L23a3:  ld      (ix+$03),a       ; no rendezvous/hold and not playing
L23a6:  ld      (ix+$07),a       ; no tone envelope active
L23a9:  ld      (ix+$04),a       ; no volume envelope active
L23ac:  scf     
L23ad:  ret     

;;==============================================================

L23ae:  dec     (ix+$0c)
L23b1:  jr      nz,L23d1         ; (+$1e)

L23b3:  ld      a,(ix+$09)
L23b6:  add     a,a
L23b7:  ld      hl,$231b         ; 
L23ba:  jr      nc,L23cd         ; set volume envelope

L23bc:  inc     (ix+$08)
L23bf:  jr      nz,L23c7         ; (+$06)
L23c1:  inc     (ix+$09)
L23c4:  ld      e,$ff
L23c6:  ret     z

;; re
L23c7:  ld      l,(ix+$0a)
L23ca:  ld      h,(ix+$0b)

;; seenvelope
L23cd:  ld      a,(hl)
L23ce:  ld      (ix+$0c),a       ;; step count
L23d1:  inc     hl
L23d2:  ld      e,(hl)           ;; step size
L23d3:  inc     hl
L23d4:  ld      (ix+$0d),l       ;; current volume envelope pointer
L23d7:  ld      (ix+$0e),h
L23da:  ret     

;;-------------------

;; wre 0 = channel, 15 = value
L23db:  ld      (ix+$0f),a

;;-------------------
;; sefor channel
;; IXr to channel data
;;
;; A 
L23de:  ld      c,a
L23df:  ld      a,(ix+$00)
L23e2:  add     a,$08            ; PSG volume register for channel A
L23e4:  jp      L0863            ; MC SOUND REGISTER

;;-------------------
;; dinnel
L23e7:  xor     a

;;----------------
;; upr for channel
L23e8:  ld      b,a
L23e9:  ld      a,(ix+$01)       ; tone mixer value
L23ec:  or      (ix+$02)         ; noise mixer value

L23ef:  ld      hl,$b2b5          ; mixer value
L23f2:  di      
L23f3:  or      (hl)              ; combine with current
L23f4:  xor     b
L23f5:  cp      (hl)
L23f6:  ld      (hl),a
L23f7:  ei      
L23f8:  jr      nz,L23fd         ; this means tone and noise disabled

L23fa:  ld      a,b
L23fb:  or      a
L23fc:  ret     nz

L23fd:  xor     a                ; silence sound
L23fe:  call    L23de            ; set channel volume
L2401:  di      
L2402:  ld      c,(hl)
L2403:  ld      a,$07            ; PSG mixer register
L2405:  jp      L0863            ; MC SOUND REGISTER

;;---------------------------------------------------------------

;; sed get tone envelope
;; E velope number
L2408:  call    L2481            ; write tone to psg registers
L240b:  ld      a,e
L240c:  call    L24ab            ; SOUND T ADDRESS
L240f:  ret     nc

L2410:  ld      a,(hl)           ; number of sections in tone
L2411:  and     $7f              
L2413:  ret     z

L2414:  ld      (ix+$11),l       ; set tone envelope pointer reload
L2417:  ld      (ix+$12),h
L241a:  call    L2470
L241d:  jr      L2428            ; initial update tone envelope            

;;===========================================================================

L241f:  ld      l,(ix+$14)           ; current tone pointer?
L2422:  ld      h,(ix+$15)

L2425:  ld      e,(ix+$18)           ; step count

;; up envelope
L2428:  ld      c,(hl)               ; step size
L2429:  inc     hl
L242a:  ld      a,e
L242b:  sub     $f0
L242d:  jr      c,L2433          ; increase/decrease tone

L242f:  ld      e,$00
L2431:  jr      L2441             

;;----------------------------

L2433:  dec     e                ; decrease step count
L2434:  ld      a,c
L2435:  add     a,a
L2436:  sbc     a,a
L2437:  ld      d,a
L2438:  ld      a,(ix+$16)       ;; low byte tone
L243b:  add     a,c
L243c:  ld      c,a
L243d:  ld      a,(ix+$17)       ;; high byte tone
L2440:  adc     a,d

L2441:  ld      d,a
L2442:  call    L2481            ; write tone to psg registers
L2445:  ld      c,(hl)           ; pause time
L2446:  ld      a,e
L2447:  or      a
L2448:  jr      nz,L2463         ; (+$19)

;; stdone..

L244a:  ld      a,(ix+$13)       ; number of tone sections remaining..
L244d:  dec     a
L244e:  jr      nz,L2460         

;; re
L2450:  ld      l,(ix+$11)
L2453:  ld      h,(ix+$12)

L2456:  ld      a,(hl)           ; number of sections.
L2457:  add     a,$80
L2459:  jr      c,L2460          

L245b:  ld      (ix+$04),$00     ; no volume envelope
L245f:  ret     

;;===========================================

L2460:  call    L2470
L2463:  ld      (ix+$18),e
L2466:  di      
L2467:  ld      (ix+$05),c           ; pause
L246a:  ld      (ix+$04),$80         ; has volume envelope
L246e:  ei      
L246f:  ret     

;;============================================================

L2470:  ld      (ix+$13),a   ;; number of sections remaining in envelope
L2473:  inc     hl
L2474:  ld      e,(hl)       ;; step count
L2475:  inc     hl
L2476:  ld      (ix+$14),l
L2479:  ld      (ix+$15),h
L247c:  ld      a,e
L247d:  or      a
L247e:  ret     nz

L247f:  inc     e
L2480:  ret     

;;==================================================================
;; wrto PSG
;; C w byte
;; D gh byte
L2481:  ld      a,(ix+$00)       ;; sound channel 0 = A, 1 = B, 2 =C 
L2484:  add     a,a              
                               ;; A = 0/2/4
L2485:  push    af
L2486:  ld      (ix+$16),c
L2489:  call    L0863            ; MC SOUND REGISTER
L248c:  pop     af
L248d:  inc     a                
                               ;; A = 1/3/5
L248e:  ld      c,d
L248f:  ld      (ix+$17),c
L2492:  jp      L0863            ; MC SOUND REGISTER


;;=================================================================
;; SOENVELOPE
;; seolume envelope
;; A e 1-15
L2495:  ld      de,$b2a6
L2498:  jr      L249d            ; (+$03)


;;=================================================================
;; SOENVELOPE
;; seone envelope
;; A e 1-15

L249a:  ld      de,$b396
L249d:  ex      de,hl
L249e:  call    L24ae            ;; get envelope
L24a1:  ex      de,hl
L24a2:  ret     nc

;; +0 of sections in the envelope 
;; +1st section of the envelope 
;; +4ond section of the envelope 
;; +7rd section of the envelope 
;; +1ourth section of the envelope 
;; +1ifth section of the envelope 
;;
;; Ean of the envelope has three bytes set out as follows 

;; noe envelope:
;;bytp count (with bit 7 set) 
;;bytp size 
;;bytse time 
;; havelope:
;;bytelope shape (with bit 7 not set)
;;byt2 - envelope period 
L24a3:  ldir    
L24a5:  ret     

;;=================================================================
;; SORESS
;; Gedress of the data block associated with the amplitude/volume envelope
;; A e number (1-15)

L24a6:  ld      hl,$b2a6         ; first amplitude envelope - $10
L24a9:  jr      L24ae            ; get envelope

;;=================================================================
;; SORESS
;; Gedress of the data block associated with the tone envelope
;; A e number (1-15)
 
L24ab:  ld      hl,$b396     ;; first tone envelope - $10

;; gee
L24ae:  or      a            ;; 0 = invalid envelope number
L24af:  ret     z

L24b0:  cp      $10          ;; >=16 invalid envelope number
L24b2:  ret     nc

L24b3:  ld      bc,$0010     ;; 16 bytes per envelope (5 sections + count)
L24b6:  add     hl,bc
L24b7:  dec     a
L24b8:  jr      nz,L24b6         ; (-$04)
L24ba:  scf     
L24bb:  ret     

;;===================================================================
;; CAISE

L24bc:  call    L2557            ; CAS IN ABANDON
L24bf:  call    L2599            ; CAS OUT ABANDON

;; enette messages
L24c2:  xor     a
L24c3:  call    L24e1            ; CAS NOISY

;; stte motor
L24c6:  call    L2bbf            ; CAS STOP MOTOR

;; se speed for writing
L24c9:  ld      hl,$014d
L24cc:  ld      a,$19

;;===================================================================
;; CAED

L24ce:  add     hl,hl            ; x2
L24cf:  add     hl,hl            ; x4
L24d0:  add     hl,hl            ; x8
L24d1:  add     hl,hl            ; x32
L24d2:  add     hl,hl            ; x64
L24d3:  add     hl,hl            ; x128
L24d4:  rrca    
L24d5:  rrca    
L24d6:  and     $3f
L24d8:  ld      l,a
L24d9:  ld      ($b1e9),hl
L24dc:  ld      a,($b1e7)
L24df:  scf     
L24e0:  ret     

;;===================================================================
;; CA

L24e1:  ld      ($b118),a
L24e4:  ret     

;;===================================================================
;; CA
;; 
;; B of filename
;; HLme
;; DEs of 2K buffer
;;
;; NO
;; - ck of file *must* be 2K long

L24e5:  ld      ix,$b11a         ;; input header

L24e9:  call    L2502            ;; initialise header
L24ec:  push    hl
L24ed:  call    c,L26ac          ;; read a block
L24f0:  pop     hl
L24f1:  ret     nc

L24f2:  ld      de,($b134)       ;; load address
L24f6:  ld      bc,($b137)       ;; execution address
L24fa:  ld      a,($b131)        ;; file type from header
L24fd:  ret     

;;===================================================================
;; CAN

L24fe:  ld      ix,$b15f

;;-------------------------------------------------------------------
;; DEs of 2k buffer
;; HLs of filename
;; B of filename

L2502:  ld      a,(ix+$00)
L2505:  or      a
L2506:  ld      a,$0e
L2508:  ret     nz

L2509:  push    ix
L250b:  ex      (sp),hl          
L250c:  inc     (hl)
L250d:  inc     hl
L250e:  ld      (hl),e
L250f:  inc     hl
L2510:  ld      (hl),d
L2511:  inc     hl
L2512:  ld      (hl),e
L2513:  inc     hl
L2514:  ld      (hl),d
L2515:  inc     hl
L2516:  ex      de,hl
L2517:  pop     hl
L2518:  push    de

;; leeader
L2519:  ld      c,$40

;; clr
L251b:  xor     a
L251c:  ld      (de),a
L251d:  inc     de
L251e:  dec     c
L251f:  jr      nz,L251c         ; (-$05)

;; wrame
L2521:  pop     de
L2522:  push    de

;;--------------------------------------------
;; come into buffer

L2523:  ld      a,b
L2524:  cp      $10
L2526:  jr      c,L252a          ; (+$02)

L2528:  ld      b,$10            

L252a:  inc     b
L252b:  ld      c,b
L252c:  jr      L2535            ; (+$07)

;; reter from RAM
L252e:  rst     $20              ; RST 4 - LOW: RAM LAM
L252f:  inc     hl
L2530:  call    L2926            ; convert character to upper case
L2533:  ld      (de),a           ; store character
L2534:  inc     de
L2535:  djnz    $252e            

;; paaces
L2537:  dec     c
L2538:  jr      z,L2543          ; (+$09)
L253a:  dec     de
L253b:  ld      a,(de)
L253c:  xor     $20
L253e:  jr      nz,L2543         ; 

L2540:  ld      (de),a           ; write character
L2541:  jr      L2537            ; 

;;---------------------------------------------

L2543:  pop     hl
L2544:  inc     (ix+$15)         ; set block index
L2547:  ld      (ix+$17),$16     ; set initial file type
L254b:  dec     (ix+$1c)         ; set first block flag
L254e:  scf     
L254f:  ret     

;;===================================================================
;; CAE

L2550:  ld      a,($b11a)        ; get current read function
L2553:  or      a
L2554:  ld      a,$0e
L2556:  ret     z

;;===================================================================
;; CADON

L2557:  ld      hl,$b11a         ; get current read function
L255a:  ld      b,$01
L255c:  ld      a,(hl)
L255d:  ld      (hl),$00         ; clear function allowing other functions to proceed
L255f:  push    bc
L2560:  call    L256d        
L2563:  pop     af

L2564:  ld      hl,$b1e4
L2567:  xor     (hl)
L2568:  scf     
L2569:  ret     nz
L256a:  ld      (hl),a
L256b:  sbc     a,a
L256c:  ret     

;;===================================================================
;; A n code
;; HL
L256d:  cp      $04              
L256f:  ret     c

;; cl
L2570:  inc     hl
L2571:  ld      e,(hl)
L2572:  inc     hl
L2573:  ld      d,(hl)
L2574:  ld      l,e
L2575:  ld      h,d
L2576:  inc     de
L2577:  ld      (hl),$00
L2579:  ld      bc,$07ff
L257c:  jp      $baa1                ;; HI: KL LDIR          

;;===================================================================
;; CASE

L257f:  ld      a,($b15f)
L2582:  cp      $03
L2584:  jr      z,L2599          ; (+$13)
L2586:  add     a,$ff
L2588:  ld      a,$0e
L258a:  ret     nc

L258b:  ld      hl,$b175
L258e:  dec     (hl)
L258f:  inc     hl
L2590:  inc     hl
L2591:  ld      a,(hl)
L2592:  inc     hl
L2593:  or      (hl)
L2594:  scf     
L2595:  call    nz,L2786         ;; write a block
L2598:  ret     nc

;;===================================================================
;; CANDON

L2599:  ld      hl,$b15f
L259c:  ld      b,$02
L259e:  jr      L255c            ; (-$44)

;;===================================================================
;; CA

L25a0:  push    hl
L25a1:  push    de
L25a2:  push    bc
L25a3:  ld      b,$05
L25a5:  call    L25f6            ;; set cassette input function
L25a8:  jr      nz,L25c4         ; (+$1a)
L25aa:  ld      hl,($b132)
L25ad:  ld      a,h
L25ae:  or      l
L25af:  scf     
L25b0:  call    z,L26ac          ;; read a block
L25b3:  jr      nc,L25c4         ; (+$0f)
L25b5:  ld      hl,($b132)
L25b8:  dec     hl
L25b9:  ld      ($b132),hl
L25bc:  ld      hl,($b11d)
L25bf:  rst     $20              ; RST 4 - LOW: RAM LAM
L25c0:  inc     hl
L25c1:  ld      ($b11d),hl
L25c4:  jr      L25f2            ; (+$2c)

;;===================================================================
;; CAR

L25c6:  push    hl
L25c7:  push    de
L25c8:  push    bc
L25c9:  ld      c,a
L25ca:  ld      hl,$b15f
L25cd:  ld      b,$05
L25cf:  call    L25f9
L25d2:  jr      nz,L25f2         ; (+$1e)
L25d4:  ld      hl,($b177)
L25d7:  ld      de,$0800
L25da:  sbc     hl,de
L25dc:  push    bc
L25dd:  call    nc,L2786         ;; write a block
L25e0:  pop     bc
L25e1:  jr      nc,L25f2         ; (+$0f)
L25e3:  ld      hl,($b177)
L25e6:  inc     hl
L25e7:  ld      ($b177),hl
L25ea:  ld      hl,($b162)
L25ed:  ld      (hl),c
L25ee:  inc     hl
L25ef:  ld      ($b162),hl
L25f2:  pop     bc
L25f3:  pop     de
L25f4:  pop     hl
L25f5:  ret     


;;===================================================================
;; atset cassette input function

;; en
;; B n code
;;
;; 0 tion active
;; 1 using CAS IN OPEN or CAS OUT OPEN
;; 2  with CAS IN DIRECT
;; 3 into with ESC
;; 4 
;; 5  with CAS IN CHAR
;;
;; ex
;; zeno error. function has been set or function is already set
;; ze= error. A = error code
;;
L25f6:  ld      hl,$b11a         

L25f9:  ld      a,(hl)           ;; get current function code
L25fa:  cp      b                ;; same as existing code?
L25fb:  ret     z
;; fudes are different
L25fc:  xor     $01              ;; just opened?
L25fe:  ld      a,$0e
L2600:  ret     nz
;; mut opened for this to succeed
;;
;; section

L2601:  ld      (hl),b
L2602:  ret     

;;===================================================================
;; CAF

L2603:  call    L25a0
L2606:  ret     nc

;;===================================================================
;; CA

L2607:  push    hl
L2608:  ld      hl,($b132)
L260b:  inc     hl
L260c:  ld      ($b132),hl
L260f:  ld      hl,($b11d)
L2612:  dec     hl
L2613:  ld      ($b11d),hl
L2616:  pop     hl
L2617:  ret     

;;===================================================================
;; CACT
;; 
;; HLddress
;;
;; No
;; -  be contiguous;
;; - ess of first block is important, load address of subsequent blocks 
;;   d and can be any value
;; - ck of file must be 2k long; subsequent blocks can be any length
;; -  address is taken from header of last block
;; - of each block must be the same
;; - bers are consecutive and increment
;; - ck number is *not* important; it can be any value!

L2618:  ex      de,hl
L2619:  ld      b,$02            ;; IN direct
L261b:  call    L25f6            ;; set cassette input function
L261e:  ret     nz

;; se load address
L261f:  ld      ($b134),de

;; trrst block to destination
L2623:  call    L263c            ;; transfer loaded block to destination location


;; up address
L2626:  ld      hl,($b134)       ;; load address from in memory header
L2629:  ld      de,($b132)       ;; length from loaded header
L262d:  add     hl,de
L262e:  ld      ($b134),hl

L2631:  call    L26ac            ;; read a block
L2634:  jr      c,L2626          ; (-$10)

L2636:  ret     z
L2637:  ld      hl,($b1be)       ;; execution address
L263a:  scf     
L263b:  ret     

;;===================================================================
;; traded block to destination location

L263c:  ld      hl,($b11b)
L263f:  ld      bc,($b132)
L2643:  ld      a,e
L2644:  sub     l
L2645:  ld      a,d
L2646:  sbc     a,h
L2647:  jp      c,$baa1              ;; HI: KL LDIR
L264a:  add     hl,bc
L264b:  dec     hl
L264c:  ex      de,hl
L264d:  add     hl,bc
L264e:  dec     hl
L264f:  ex      de,hl
L2650:  jp      $baa7                ;; HI: KL LDDR

;;===================================================================
;; CAECT
;; 
;; HLddress
;; DE
;; BCion address
;; A pe

L2653:  push    hl
L2654:  push    bc
L2655:  ld      c,a
L2656:  ld      hl,$b15f
L2659:  ld      b,$02
L265b:  call    L25f9
L265e:  jr      nz,L268d         ; (+$2d)

L2660:  ld      a,c
L2661:  pop     bc
L2662:  pop     hl

;; ser
L2663:  ld      ($b176),a        
L2666:  ld      ($b17c),de       ; length
L266a:  ld      ($b17e),bc       ; execution address

L266e:  ld      ($b160),hl       ; load address
L2671:  ld      ($b177),de       ; length
L2675:  ld      hl,$f7ff         ; $f7ff = -$800
L2678:  add     hl,de
L2679:  ccf     
L267a:  ret     c

L267b:  ld      hl,$0800
L267e:  ld      ($b177),hl       ; length of this block

L2681:  ex      de,hl
L2682:  sbc     hl,de
L2684:  push    hl
L2685:  ld      hl,($b160)
L2688:  add     hl,de
L2689:  push    hl
L268a:  call    L2786            ; write block
    
L268d:  pop     hl
L268e:  pop     de
L268f:  ret     nc

L2690:  jr      L266e            ; (-$24)

;;===================================================================
;; CA
;;
;; DEs of 2k buffer

L2692:  ld      hl,$b11a
L2695:  ld      a,(hl)
L2696:  or      a
L2697:  ld      a,$0e
L2699:  ret     nz

L269a:  ld      (hl),$04         ; set catalog function

L269c:  ld      ($b11b),de       ; buffer to load blocks to
L26a0:  xor     a
L26a1:  call    L24e1            ;; CAS NOISY
L26a4:  call    L26b3            ; read block
L26a7:  jr      c,L26a4          ; loop if cassette not pressed

L26a9:  jp      L2557            ;; CAS IN ABANDON


;;========================================================================
;; rek
;; 
;; 
;; no
;;

L26ac:  ld      a,($b130)        ; last block flag
L26af:  or      a
L26b0:  ld      a,$0f            ; "hard end of file"
L26b2:  ret     nz

L26b3:  ld      bc,$8301         ; Press PLAY then any key
L26b6:  call    L27e5            ; display message if required
L26b9:  jr      nc,L271a         

L26bb:  ld      hl,$b1a4         ; location to load header
L26be:  ld      de,$0040         ; header length
L26c1:  ld      a,$2c            ; header marker byte
L26c3:  call    L29a6            ; cas read: read header
L26c6:  jr      nc,L271a         

L26c8:  ld      b,$8b            ; no message
L26ca:  call    L292f            ; catalog?
L26cd:  jr      z,L26d6          

;; no, so compare filenames
L26cf:  call    L2737            ; compare filenames
L26d2:  jr      nz,L2727         ; if nz, display "Found xxx block x"

L26d4:  ld      b,$89            ; "Loading"
L26d6:  call    L2804            ; display "Loading xxx block x"

L26d9:  ld      de,($b1b7)       ; length from loaded header
L26dd:  ld      hl,($b134)       ; location from in-memory header

L26e0:  ld      a,($b11a)        ; 
L26e3:  cp      $02              ; in direct?
L26e5:  jr      z,L26f5          ; 

;; noct, so is:
;; 1.
;; 2.file for read
;; 3.file char by char
;;
;; chlock is no longer than $800 bytes
;; ifport a "read error d"
L26e7:  ld      hl,$f7ff         ; $f7ff = -$800
L26ea:  add     hl,de            ; add length from header

L26eb:  ld      a,$04            ; code for 'read error d'
L26ed:  jr      c,L271a          ; (+$2b)

L26ef:  ld      hl,($b11b)       ; 2k buffer
L26f2:  ld      ($b11d),hl

L26f5:  ld      a,$16            ; data marker
L26f7:  call    L29a6            ; cas read: read data

L26fa:  jr      nc,L271a         ;

;; inlock number in internal header
L26fc:  ld      hl,$b12f         ; block number
L26ff:  inc     (hl)             ; increment block number

;; geock flag from loaded header and store into
;; inader
L2700:  ld      a,($b1b5)        
L2703:  inc     hl
L2704:  ld      (hl),a           

;; cl block flag
L2705:  xor     a                
L2706:  ld      ($b136),a

L2709:  ld      hl,($b1b7)       ; get length from loaded header
L270c:  ld      ($b132),hl       ; store in internal header

L270f:  call    L292f            ; catalog?

;; ifdisplay OK message
L2712:  ld      a,$8c            ; "OK"
L2714:  call    z,L287e          ; display message

;; 
L2717:  scf     
L2718:  jr      L277f            ; (+$65)

;;==================================================================
;; A =0: no error; A<>0: error)

L271a:  or      a
L271b:  ld      hl,$b11a
L271e:  jr      z,L2778          ; 

;; A ode
L2720:  ld      b,$85            ; "Read error"
L2722:  call    L2885            ; display message with code
;; ..
L2725:  jr      L26bb            

;;==================================================================

L2727:  push    af
L2728:  ld      b,$88            ; "Found "
L272a:  call    L2804            ; "Found xxx block x"
L272d:  pop     af
L272e:  jr      nc,L26bb         ; (-$75)

L2730:  ld      b,$87            ; "Rewind tape"
L2732:  call    L2883
L2735:  jr      L26bb            ; (-$7c)

;;===============================================================
;; coenames
;;
;; ift block:
;; coes
;; ifock:
;; - ilenames if a filename was specified
;; - ed header into ram

L2737:  ld      a,($b136)        ; first block flag in internal header?
L273a:  or      a
L273b:  jr      z,L2758          

L273d:  ld      a,($b1bb)        ; first block flag in loaded header?
L2740:  cpl     
L2741:  or      a
L2742:  ret     nz

;; ifcified a filename, compare it against the filename in the loaded
;; heerwise accept the file

L2743:  ld      a,($b11f)        ; did user specify a filename?
                               ; e.g. LOAD"bob
L2746:  or      a

L2747:  call    nz,L2760         ; compare filenames and block number
L274a:  ret     nz               ; if filenames do not match, quit

;; gef:

;; 1.ename was specified by user and filename matches with 
;; fi loaded header
;;
;; 2.ame was specified by user

;; co header to in-memory header
L274b:  ld      hl,$b1a4
L274e:  ld      de,$b11f
L2751:  ld      bc,$0040
L2754:  ldir    

L2756:  xor     a
L2757:  ret     

;;================================================================
;; coe and block number

L2758:  call    L2760            ; compare filenames
L275b:  ret     nz

;; cock number
L275c:  ex      de,hl
L275d:  ld      a,(de)
L275e:  cp      (hl)
L275f:  ret     

;;===================================================================
;; co filenames; one filename is in the loaded header
;; thfilename is in the in-memory header
;;
;; nzmes are different
;; z es are identical

L2760:  ld      hl,$b11f         ; in-memory header
L2763:  ld      de,$b1a4         ; loaded header

;; coenames
L2766:  ld      b,$10            ; 16 characters

L2768:  ld      a,(de)           ; get character from loaded header
L2769:  call    L2926            ; convert character to upper case
L276c:  ld      c,a
L276d:  ld      a,(hl)           ; get character from in-memory header
L276e:  call    L2926            ; convert character to upper case

L2771:  xor     c                ; result will be 0 if the characters are identical.
                               ; will be <>0 if the characters are different

L2772:  ret     nz               ; quit if characters are not the same

L2773:  inc     hl               ; increment pointer
L2774:  inc     de               ; increment pointer
L2775:  djnz    $2768            

;; ifgets to here, then the filenames are identical
L2777:  ret     
;;===================================================================

L2778:  ld      a,(hl)
L2779:  ld      (hl),$03         ; 
L277b:  call    L256d        
L277e:  or      a

;;-------------------------------------------------------------------
;; qug block
L277f:  sbc     a,a
L2780:  push    af
L2781:  call    L2bbf            ; CAS STOP MOTOR
L2784:  pop     af
L2785:  ret     

;;===================================================================
;; wrck

L2786:  ld      bc,$8402         ; press rec
L2789:  call    L27e5            ;  display message if required
L278c:  jr      nc,L27d8         ; (+$4a)
L278e:  ld      b,$8a
L2790:  ld      de,$b164
L2793:  call    L2807
L2796:  ld      hl,$b17b
L2799:  call    L27fa
L279c:  jr      nc,L27d8         ; (+$3a)
L279e:  ld      hl,($b160)
L27a1:  ld      ($b162),hl
L27a4:  ld      ($b179),hl
L27a7:  push    hl

;; wrr for this block
L27a8:  ld      hl,$b164
L27ab:  ld      de,$0040
L27ae:  ld      a,$2c            ; header marker
L27b0:  call    L29af            ; cas write: write header

L27b3:  pop     hl
L27b4:  jr      nc,L27d8         ; (+$22)

;; wrfor this block
L27b6:  ld      de,($b177)
L27ba:  ld      a,$16            ; data marker
L27bc:  call    L29af            ; cas write: write data block
L27bf:  ld      hl,$b175
L27c2:  call    c,L27fa
L27c5:  jr      nc,L27d8         ; (+$11)
L27c7:  ld      hl,$0000
L27ca:  ld      ($b177),hl
L27cd:  ld      hl,$b174
L27d0:  inc     (hl)
L27d1:  xor     a
L27d2:  ld      ($b17b),a
L27d5:  scf     
L27d6:  jr      L277f            ; (-$59)

;;==============================================================
;; A =0: no error; A<>0: error)
L27d8:  or      a
L27d9:  ld      hl,$b15f
L27dc:  jr      z,L2778          ; (-$66)

;; a 
L27de:  ld      b,$86            ; "Write error"
L27e0:  call    L2885            ; display message with code
L27e3:  jr      L279e            ; (-$47)

;;===============================================================
;; C  code
;; ex
;; A rror
;; A r

L27e5:  ld      hl,$b1e4
L27e8:  ld      a,c
L27e9:  cp      (hl)
L27ea:  ld      (hl),c
L27eb:  scf     

L27ec:  push    hl
L27ed:  push    bc
L27ee:  call    nz,L28d2         ; Press play then any key
L27f1:  pop     bc
L27f2:  pop     hl

L27f3:  sbc     a,a
L27f4:  ret     nc

L27f5:  call    L2bbb            ; CAS START MOTOR
L27f8:  sbc     a,a
L27f9:  ret     

;;===============================================================

L27fa:  ld      a,(hl)
L27fb:  or      a
L27fc:  scf     
L27fd:  ret     z

L27fe:  ld      bc,$012c         ; delay in 1/100ths of a second
L2801:  jp      L2be2            ; delay for 3 seconds

;;==========================================================================

L2804:  ld      de,$b1a4

L2807:  ld      a,($b118)        ; cassette messages enabled?
L280a:  or      a
L280b:  ret     nz

L280c:  ld      ($b119),a
L280f:  call    L28f3

L2812:  call    L2898            ; display message

L2815:  ld      a,(de)           ; is first character of filename = 0?
L2816:  or      a
L2817:  jr      nz,L2823         ; 

;; une

L2819:  ld      a,$8e            ; "Unnamed file"
L281b:  call    L2899            ; display message

L281e:  ld      bc,$0010
L2821:  jr      L2851            ; (+$2e)

;;--------------------
;; na
L2823:  call    L292f

L2826:  ld      bc,$1000
L2829:  jr      z,L2838          ; (+$0d)
L282b:  ld      l,e
L282c:  ld      h,d
L282d:  ld      a,(hl)
L282e:  or      a
L282f:  jr      z,L2835          ; (+$04)
L2831:  inc     c
L2832:  inc     hl
L2833:  djnz    $282d            ; (-$08)
L2835:  ld      a,b
L2836:  ld      b,c
L2837:  ld      c,a

L2838:  call    L28fd            ; insert new-line if word
                               ; can't fit onto current-line

L283b:  ld      a,(de)           ; get character from filename
L283c:  call    L2926            ; convert character to upper case

L283f:  or      a                ; zero?
L2840:  jr      nz,L2844         

;; dipace if a zero is found

L2842:  ld      a,$20            ; display a space

L2844:  push    bc
L2845:  push    de
L2846:  call    L1335            ; TXT WR CHAR
L2849:  pop     de
L284a:  pop     bc
L284b:  inc     de
L284c:  djnz    $283b            ; (-$13)

L284e:  call    L28ce            ; display space

L2851:  ex      de,hl
L2852:  add     hl,bc
L2853:  ex      de,hl

L2854:  ld      a,$8d            ; "block "
L2856:  call    L2899            ; display message

L2859:  ld      b,$02            ; length of word
L285b:  call    L28fd            ; insert new-line if word
                               ; can't fit onto current-line

L285e:  ld      a,(de)
L285f:  call    L2914            ; display decimal number

L2862:  call    L28ce            ; display space

L2865:  inc     de
L2866:  call    L292f
L2869:  jr      nz,L2876         ; (+$0b)
L286b:  inc     de
L286c:  ld      a,(de)
L286d:  and     $0f
L286f:  add     a,$24
L2871:  call    L28f0

L2874:  jr      L28ce            ; display space

;;================================================================

L2876:  ld      a,(de)
L2877:  ld      hl,$b119
L287a:  or      (hl)
L287b:  ret     z
L287c:  jr      L28eb            ; (+$6d)

;;================================================================
;; A  code

L287e:  call    L2899            ; display message
L2881:  jr      L28eb            ; (+$68)

;;================================================================

L2883:  ld      a,$ff

;; disage with code on end (e.g. "Read error x" or "Write error x"
;; A ,2,3)
L2885:  push    af
L2886:  call    L2891            
L2889:  pop     af
L288a:  add     a,$60            ; 'a'-1
L288c:  call    nc,L28f0         ; display character
L288f:  jr      L28eb            

;;================================================================

L2891:  call    L117c            ; TXT GET CURSOR
L2894:  dec     h
L2895:  call    nz,L28eb

L2898:  ld      a,b

;;================================================================
;; disage
;;
;; - s displayed using word-wrap
;;
;; a  number ($80-$FF)
L2899:  push    hl

L289a:  and     $7f              ; get message index (0-127)
L289c:  ld      b,a

L289d:  ld      hl,$2935         ; start of message list (points to first message)

;; fige in list? (message 0?)
L28a0:  jr      z,L28a9          

;; no
;; 
;; - age is terminated by a zero byte
;; - hing bytes until a zero is found.
;; -  is found, decrement count. If count reaches zero, then 
;; thyte following the zero, is the start of the message we want

L28a2:  ld      a,(hl)           ; get byte
L28a3:  inc     hl               ; increment pointer

L28a4:  or      a                ; is it zero (0) ?
L28a5:  jr      nz,L28a2         ; if zero, it is the end of this string

;; gobyte, so at end of the current string

L28a7:  djnz    $28a2            ; decrement message count

;; HLof message to display

;; ths looped; message may contain multiple strings

;; enage?
L28a9:  ld      a,(hl)
L28aa:  or      a
L28ab:  jr      z,L28b2          ; (+$05)

;; disage
L28ad:  call    L28b5            ; display message with word-wrap

;; atnt there might be a end of string marker (0), the start
;; ofstring (next byte will have bit 7=0) or a continuation string
;; (nwill have bit 7=1)
L28b0:  jr      L28a9           ; continue displaying string 

;; fisplaying complete string , or displayed part of string sequence
L28b2:  pop     hl

L28b3:  inc     hl               ; if part of a complete message, go to next sub-string or word
L28b4:  ret     

;;================================================================
;; disage with word wrap

;; HLs of message
;; A haracter in message

;; ifn bit 7 is set. Bit 6..0 define the ID of the message to display
;; ifn this is the first character in the message
L28b5:  jp      m,L2899          


;;----------------------------
;; cor of letters in word

L28b8:  push    hl           ;; store start of word

;; cor of letters in world
L28b9:  ld      b,$00
L28bb:  inc     b

L28bc:  ld      a,(hl)       ;; get character
L28bd:  inc     hl           ;; increment pointer
L28be:  rlca                 ;; if bit 7 is set, then this is the last character of the current word
L28bf:  jr      nc,L28bb        

;; B of letters

;; ifl not fit onto end of current line, insert
;; a k, and display on next line
L28c1:  call    L28fd

L28c4:  pop     hl           ;; restore start of word 

;;---------------------------
;; did

;; HLon of characters
;; B of characters 
L28c5:  ld      a,(hl)           ; get byte
L28c6:  inc     hl               ; increment counter
L28c7:  and     $7f              ; isolate byte
L28c9:  call    L28f0            ; display char (txt output?)
L28cc:  djnz    $28c5            

;; dice
L28ce:  ld      a,$20            ; " " (space) character
L28d0:  jr      L28f0            ; display character

;;================================================================

L28d2:  ld      a,($b118)        ; cassette messages enabled?
L28d5:  or      a
L28d6:  scf     
L28d7:  ret     nz

L28d8:  call    L2891            ; display message

L28db:  call    L1bfe            ; KM FLUSH
L28de:  call    L1276            ; TXT CUR ON
L28e1:  call    L1cdb            ; KM WAIT KEY
L28e4:  call    L127e            ; TXT CUR OFF
L28e7:  cp      $fc
L28e9:  ret     z

L28ea:  scf     

;;--------------------------------------------------------------

L28eb:  call    L28f3

;; di
L28ee:  ld      a,$0a
L28f0:  jp      L13fe            ; TXT OUTPUT

;;=================================================================

L28f3:  push    af
L28f4:  push    hl
L28f5:  ld      a,$01
L28f7:  call    L115a            ; TXT SET COLUMN
L28fa:  pop     hl
L28fb:  pop     af
L28fc:  ret     

;;=================================================================
;; def word can be displayed on this line
L28fd:  push    de
L28fe:  call    L1252            ; TXT GET WINDOW
L2901:  ld      e,h
L2902:  call    L117c            ; TXT GET CURSOR
L2905:  ld      a,h
L2906:  dec     a
L2907:  add     a,e
L2908:  add     a,b
L2909:  dec     a
L290a:  cp      d
L290b:  pop     de
L290c:  ret     c

L290d:  ld      a,$ff
L290f:  ld      ($b119),a
L2912:  jr      L28eb            ; (-$29)


;;===================================================================

;; di0
L2914:  ld      b,$ff
L2916:  inc     b
L2917:  sub     $0a              
L2919:  jr      nc,L2916         ; (-$05)
;; B of division by 10
;; A 

L291b:  add     a,$3a            ; convert to ASCII digit
     
L291d:  push    af
L291e:  ld      a,b
L291f:  or      a
L2920:  call    nz,L2914         ; continue with division

L2923:  pop     af
L2924:  jr      L28f0            ; display character

;;===================================================================
;; coracter to upper case
L2926:  cp      $61              ; "a"
L2928:  ret     c

L2929:  cp      $7b              ; "z"
L292b:  ret     nc

L292c:  add     a,$e0
L292e:  ret     

;;===================================================================
;; ted function is CATALOG
;;
;; zecatalog
;; ze= not catalog
L292f:  ld      a,($b11a)        ; get current read function
L2932:  cp      $04              ; catalog function?
L2934:  ret     

;;===================================================================
;; cassages
;; - ) byte indicates end of complete message
;; - th bit 7 set indicates:
;;   word, the id of another continuing string
;; 0:
;; 1:en any key:"
;; 2:
;; 3:LAY then any key:"
;; 4:EC and PLAY then any key:"
;; 5:ror"
;; 6:rror"
;; 7:tape"
;; 8:"
;; 9:"
;; 10"
;; 11
;; 12
;; 13
;; 14d file"

        defb "Pres",'s'+$80,0
        defb "PLA",'Y'+$80,"the",'n'+$80,"an",'y'+$80,"key",':'+$80,0
        defb "erro",'r'+$80,0
        defb 0+$80,1+$80,0
        defb $80,"RE",'C'+$80,"an",'d'+$80,$81,0
        defb "Rea",'d'+$80,$82,0
        defb "Writ",'e'+$80,$82,0
        defb "Rewin",'d'+$80,"tap",'e'+$80,0
        defb "Found ",' '+$80,0
        defb "Loadin",'g'+$80,0
        defb "Savin",'g'+$80,0
        defb 0
        defb "O",'k'+$80,0
        defb "bloc",'k'+$80,0
        defb "Unname", 'd'+$80,"file   ",' '+$80,0


;;================================================================
;; CA

;; A te
;; HLon of data
;; DE of data

L29a6:  call    L29e3            ; enable key checking and start the cassette motor
L29a9:  push    af
L29aa:  ld      hl,$2a28         ; read block of data
L29ad:  jr      L29c8            ; do read

;;================================================================
;; CA

;; A te
;; HLation location for data
;; DE of data

L29af:  call    L29e3            ; enable key checking and start the cassette motor
L29b2:  push    af
L29b3:  call    L2ad4            ;; write start of block (pilot and syncs)
L29b6:  ld      hl,$2a67         ;; write block of data
L29b9:  call    c,L2a0d          ;; read/write 256 byte blocks
L29bc:  call    c,L2ae9          ;; write trailer
L29bf:  jr      L29d0            ;; 

;;================================================================
;; CA

L29c1:  call    L29e3            ; enable key checking and start the cassette motor
L29c4:  push    af
L29c5:  ld      hl,$2a37         ;; check stored block with block in memory

;;---------------------------------------------
;; do
;; car cas read
L29c8:  push    hl
L29c9:  call    L2a89            ;; read pilot and sync
L29cc:  pop     hl
L29cd:  call    c,L2a0d          ;; read/write 256 byte blocks


;;-------------------------------------------------------
;; cacas read or cas write
L29d0:  pop     de
L29d1:  push    af

L29d2:  ld      bc,$f782         ;; set PPI port A to output
L29d5:  out     (c),c

L29d7:  ld      bc,$f610         ;; cassette motor on
L29da:  out     (c),c

;; if motor is stopped, then it will stop immediatly
;; if motor is running, then there will not be any pause.

L29dc:  ei                       ;; enable interrupts

L29dd:  ld      a,d
L29de:  call    L2bc1            ;; CAS RESTORE MOTOR
L29e1:  pop     af
L29e2:  ret     

;;================================================================
;; enchecking and start the cassette motor

;; str
L29e3:  ld      ($b1e5),a

L29e6:  dec     de
L29e7:  inc     e

L29e8:  push    hl
L29e9:  push    de
L29ea:  call    L1fe9            ; SOUND RESET
L29ed:  pop     de
L29ee:  pop     ix

L29f0:  call    L2bbb            ; CAS START MOTOR


L29f3:  di                   ;; disable interrupts

;; seregister 14 (PSG port A)
;; (kata is connected to PSG port A)
L29f4:  ld      bc,$f40e     ;; select keyboard line 14
L29f7:  out     (c),c

L29f9:  ld      bc,$f6d0     ;; cassette motor on + PSG select register operation
L29fc:  out     (c),c

L29fe:  ld      c,$10
L2a00:  out     (c),c        ;; cassette motor on + PSG inactive operation

L2a02:  ld      bc,$f792     ;; set PPI port A to input
L2a05:  out     (c),c        
                           ;; PSG port A data can be read through PPI port A now

L2a07:  ld      bc,$f658     ;; cassette motor on + PSG read data operation + select keyboard line 8
L2a0a:  out     (c),c
L2a0c:  ret     

;;===============================================================================
;; reblocks

;; DE of bytes to read/write

;; D of 256 blocks to read/write 
;; ifhen there is a single block to write, which has E bytes
;; in
;; ifen there is more than one block to write, write 256 bytes
;; foock except the last. Then write final block with remaining
;; by

L2a0d:  ld      a,d
L2a0e:  or      a
L2a0f:  jr      z,L2a1e          ; (+$0d)

;; doplete 256 byte block
L2a11:  push    hl
L2a12:  push    de
L2a13:  ld      e,$00            ; number of bytes
L2a15:  call    L2a1e            ; read/write block
L2a18:  pop     de
L2a19:  pop     hl
L2a1a:  ret     nc

L2a1b:  dec     d
L2a1c:  jr      nz,L2a11         ; (-$0d)

;; E of bytes in last block to write

;;---------------------------
;; incrc
L2a1e:  ld      bc,$ffff
L2a21:  ld      ($b1eb),bc       ; crc 

;; do
L2a25:  ld      d,$01
L2a27:  jp      (hl)

;;===============================================================================
;; IXs to load data to 
;; re
;; in
;; D ize
;; E data size
;; ou
;; D emaining in block (block size - actual data size)

L2a28:  call    L2b20            ; read byte from cassette
L2a2b:  ret     nc

L2a2c:  ld      (ix+$00),a       ; store byte
L2a2f:  inc     ix               ; increment pointer

L2a31:  dec     d                ; decrement block count

L2a32:  dec     e
L2a33:  jr      nz,L2a28         ; decrement actual data count

;; D of bytes remaining in block

;; reing bytes in block; but ignore
L2a35:  jr      L2a49            ; (+$12)

;;===============================================================================
;; chd block with block in memory
L2a37:  call    L2b20            ; read byte from cassette
L2a3a:  ret     nc

L2a3b:  ld      b,a
L2a3c:  call    $bad7            ; get byte from IX with roms disabled
L2a3f:  xor     b                


L2a40:  ld      a,$03            ; 
L2a42:  ret     nz

L2a43:  inc     ix
L2a45:  dec     d
L2a46:  dec     e
L2a47:  jr      nz,L2a37         ; (-$12)

;; antes remaining in block??
L2a49:  dec     d
L2a4a:  jr      z,L2a52          ; 

;; byning
;; remaining bytes but ignore

L2a4c:  call    L2b20            ; read byte from cassette   
L2a4f:  ret     nc

L2a50:  jr      L2a49            ; 

;;--------------------------------------------

L2a52:  call    L2b16            ; get 1's complemented crc

L2a55:  call    L2b20            ; read crc byte1 from cassette
L2a58:  ret     nc

L2a59:  xor     d
L2a5a:  jr      nz,L2a63         ;

L2a5c:  call    L2b20            ; read crc byte2 from cassette
L2a5f:  ret     nc

L2a60:  xor     e
L2a61:  scf     
L2a62:  ret     z

L2a63:  ld      a,$02
L2a65:  or      a
L2a66:  ret     

;;===============================================================================
;; wr of data (pad with 0's if less than block size)
;; IXs of data
;; E byte count
;; D ize count
 
L2a67:  call    $bad7            ; get byte from IX with roms disabled
L2a6a:  call    L2b68            ; write data byte
L2a6d:  ret     nc

L2a6e:  inc     ix               ; increment pointer

L2a70:  dec     d                ; decrement block size count
L2a71:  dec     e                ; decrement actual count
L2a72:  jr      nz,L2a67         ; (-$0d)

;; ac count = block size count?
L2a74:  dec     d
L2a75:  jr      z,L2a7e          

;; nobyte count was less than block size
;; palock size with zeros

L2a77:  xor     a
L2a78:  call    L2b68            ; write data byte
L2a7b:  ret     nc

L2a7c:  jr      L2a74            ; (-$0a)


;; geplemented crc
L2a7e:  call    L2b16

;; wr
L2a81:  call    L2b68            ; write data byte
L2a84:  ret     nc

;; wr
L2a85:  ld      a,e
L2a86:  jp      L2b68            ; write data byte

;;===============================================================================
;; reand sync

L2a89:  push    de
L2a8a:  call    L2a93            ; read pilot and sync
L2a8d:  pop     de

L2a8e:  ret     c            

L2a8f:  or      a
L2a90:  ret     z

L2a91:  jr      L2a89            ; (-$0a)

;;=================================================================
;; reand sync

;;------------------------
;; waart of leader/pilot

L2a93:  ld      l,$55            ; %01010101
                               ; this is used to generate the cassette input data comparison 
                               ; used in the edge detection

L2a95:  call    L2b3d            ; sample edge
L2a98:  ret     nc

;;---------------------------------
;; geses of leader/pilot
L2a99:  ld      de,$0000         ; initial total

L2a9c:  ld      h,d

L2a9d:  call    L2b3d            ; sample edge
L2aa0:  ret     nc

L2aa1:  ex      de,hl
;; C d time
;; add time to total
L2aa2:  ld      b,$00
L2aa4:  add     hl,bc
L2aa5:  ex      de,hl

L2aa6:  dec     h
L2aa7:  jr      nz,L2a9d         ; (-$0c)


;; C n of last pulse read

;; lonc bit
;; anthe average for every non-sync

;; DE 256 edges
;; D: 8.8 fixed point number
;; D  part of number (integer average of 256 pulses)
;; E nal part of number

L2aa9:  ld      h,c              ; time of last pulse

L2aaa:  ld      a,c
L2aab:  sub     d                ; subtract initial average 
L2aac:  ld      c,a
L2aad:  sbc     a,a
L2aae:  ld      b,a

;; if BC is +ve; BC = +ve delta
;; if BC is -ve; BC = -ve delta

;; adage
L2aaf:  ex      de,hl
L2ab0:  add     hl,bc            ; DE = DE + BC
L2ab1:  ex      de,hl

L2ab2:  call    L2b3d            ; sample edge
L2ab5:  ret     nc

; A =
L2ab6:  ld      a,d              ; average so far            
L2ab7:  srl     a                ; /2
L2ab9:  srl     a                ; /4
                               ; A = D * 1/4
L2abb:  adc     a,d              ; A = D + (D*1/4)

;; sywill have a duration which is half that of a pulse in a 1 bit
;; avvious 


L2abc:  sub     h                ; time of last pulse
L2abd:  jr      c,L2aa9          ; carry set if H>A

;; avevious (possibly read first pulse of sync or second of sync)

L2abf:  sub     c                ; time of current pulse
L2ac0:  jr      c,L2aa9          ; carry set if C>(A-H)

;; to average>=(previous*2)
;; anans we have just read the second pulse of the sync bit


;; cait 1 timing
L2ac2:  ld      a,d              ; average
L2ac3:  rra                      ; /2
                               ; A = D/2
L2ac4:  adc     a,d              ; A = D + (D/2)
                               ; A = D * (3/2)
L2ac5:  ld      h,a
                               ; this is the middle time
                               ; to calculate difference between 0 and 1 bit

;; ifasured is > this time, then we have a 1 bit
;; ifasured is < this time, then we have a 0 bit

;; H constant
;; L  cassette data input state
L2ac6:  ld      ($b1e6),hl

;; re
L2ac9:  call    L2b20            ; read data-byte
L2acc:  ret     nc

L2acd:  ld      hl,$b1e5         ; marker
L2ad0:  xor     (hl)
L2ad1:  ret     nz

L2ad2:  scf     
L2ad3:  ret     

;;===============================================================================
;; wr of block
L2ad4:  call    L2bf9        ;; 1/100th of a second delay

;; wrr
L2ad7:  ld      hl,$0801     ;; 2049
L2ada:  call    L2aec        ;; write leader (2049 1 bits; 4096 pulses)
L2add:  ret     nc

;; wrbit
L2ade:  or      a
L2adf:  call    L2b78        ;; write data-bit
L2ae2:  ret     nc

;; wrr
L2ae3:  ld      a,($b1e5)
L2ae6:  jp      L2b68        ;; write data byte

;;====================================================================
;; wrer = 33 "1" bits
;;
;; ca trailer written successfully
;; zeescape was pressed

L2ae9:  ld      hl,$0021     ;; 33

;; chscape
L2aec:  ld      b,$f4        ;; PPI port A
L2aee:  in      a,(c)        ;; read keyboard data through PPI port A (connected to PSG port A)
L2af0:  and     $04          ;; escape key pressed?
                           ;; bit 2 is 0 if escape key pressed
L2af2:  ret     z            

;; wrer bit
L2af3:  push    hl
L2af4:  scf                  ;; a "1" bit   
L2af5:  call    L2b78        ;; write data-bit
L2af8:  pop     hl
L2af9:  dec     hl           ;; decrement trailer bit count

L2afa:  ld      a,h
L2afb:  or      l
L2afc:  jr      nz,L2aec     ;;

L2afe:  scf     
L2aff:  ret     
;;====================================================================

;; up
L2b00:  ld      hl,($b1eb)       ;; get crc
L2b03:  xor     h
L2b04:  jp      p,L2b10

L2b07:  ld      a,h
L2b08:  xor     $08
L2b0a:  ld      h,a
L2b0b:  ld      a,l
L2b0c:  xor     $10
L2b0e:  ld      l,a
L2b0f:  scf     

L2b10:  adc     hl,hl
L2b12:  ld      ($b1eb),hl       ;; store crc
L2b15:  ret     

;;===============================================================================
;; gedata crc and 1's complement it
;; inready to write to cassette or to compare against crc from cassette

L2b16:  ld      hl,($b1eb)       ;; block crc

;; 1'ent crc
L2b19:  ld      a,l
L2b1a:  cpl     
L2b1b:  ld      e,a
L2b1c:  ld      a,h
L2b1d:  cpl     
L2b1e:  ld      d,a
L2b1f:  ret     

;;===============================================================================
;; reyte

L2b20:  push    de
L2b21:  ld      e,$08            ;; number of data-bits

L2b23:  ld      hl,($b1e6)   
;; H constant
;; L  cassette data input state

L2b26:  call    L2b44            ;; get edge

L2b29:  call    c,L2b4d          ;; get edge
L2b2c:  jr      nc,L2b3b         

L2b2e:  ld      a,h              ;; ideal time
L2b2f:  sub     c                ;; subtract measured time
                               ;; -ve (1 pulse) or +ve (0 pulse)
L2b30:  sbc     a,a              
                               ;; if -ve, set carry
                               ;; if +ve, clear carry

;; ca= bit state: carry set = 1 bit, carry clear = 0 bit

L2b31:  rl      d                ;; shift carry state into bit 0
                               ;; updating data-byte
                               
L2b33:  call    L2b00            ;; update crc
L2b36:  dec     e
L2b37:  jr      nz,L2b23         ; 

L2b39:  ld      a,d
L2b3a:  scf     
L2b3b:  pop     de
L2b3c:  ret     

;;===============================================================================
;; sa and check for escape
;; L uence which is shifted after each edge detected
;; sts $55 (%01010101)

;; chscape
L2b3d:  ld      b,$f4        ;; PPI port A
L2b3f:  in      a,(c)        ;; read keyboard data through PPI port A (connected to PSG port A)
L2b41:  and     $04          ;; escape key pressed?
                           ;; bit 2 is 0 if escape key pressed
L2b43:  ret     z            


;; prtion?
L2b44:  ld      a,r

;; ro divisible by 4
;; i.
;; 0-
;; 1-
;; 2-
;; 3-
;; 4-
;; 5-
;; et

L2b46:  add     a,$03
L2b48:  rrca                 ;; /2
L2b49:  rrca                 ;; /4

L2b4a:  and     $1f          ;; 

L2b4c:  ld      c,a

L2b4d:  ld      b,$f5        ; PPI port B input (includes cassette data input)

;; --------------------------------------------
;; lont time between edges
;; C  17us units (68T states)
;; ca edge arrived within time
;; ca = edge arrived too late

L2b4f:  ld      a,c      ; [1] update edge timer
L2b50:  add     a,$02        ; [2]
L2b52:  ld      c,a      ; [1]
L2b53:  jr      c,L2b63          ; [3] overflow?

L2b55:  in      a,(c)        ; [4] read cassette input data
L2b57:  xor     l        ; [1]
L2b58:  and     $80      ; [2] isolate cassette input in bit 7
L2b5a:  jr      nz,L2b4f         ; [3] has bit 7 (cassette data input) changed state?

;; pussfully read

L2b5c:  xor     a
L2b5d:  ld      r,a

L2b5f:  rrc     l        ; toggles between 0 and 1 

L2b61:  scf     
L2b62:  ret     

;; ti
L2b63:  xor     a
L2b64:  ld      r,a
L2b66:  inc     a            ; "read error a"
L2b67:  ret     

;;===============================================================================
;; wrbyte to cassette
;; A te
L2b68:  push    de
L2b69:  ld      e,$08            ;; number of bits
L2b6b:  ld      d,a

L2b6c:  rlc     d                ;; shift bit state into carry
L2b6e:  call    L2b78            ;; write bit to cassette
L2b71:  jr      nc,L2b76         

L2b73:  dec     e
L2b74:  jr      nz,L2b6c         ;; loop for next bit

L2b76:  pop     de
L2b77:  ret     

;;===============================================================================
;; wro cassette
;;
;; ca= state of bit
;; ca 1 data bit
;; ca = 0 data bit

L2b78:  ld      bc,($b1e8)
L2b7c:  ld      hl,($b1ea)
L2b7f:  sbc     a,a
L2b80:  ld      h,a
L2b81:  jr      z,L2b8a          ; (+$07)
L2b83:  ld      a,l
L2b84:  add     a,a
L2b85:  add     a,b
L2b86:  ld      l,a
L2b87:  ld      a,c
L2b88:  sub     b
L2b89:  ld      c,a
L2b8a:  ld      a,l
L2b8b:  ld      ($b1e8),a

;; wr level
L2b8e:  ld      l,$0a            ; %00001010 = clear bit 5 (cassette write data)
L2b90:  call    L2ba7

L2b93:  jr      c,L2b9b          ; (+$06)
L2b95:  sub     c
L2b96:  jr      nc,L2ba4         ; (+$0c)
L2b98:  cpl     
L2b99:  inc     a
L2b9a:  ld      c,a
L2b9b:  ld      a,h
L2b9c:  call    L2b00            ; update crc

;; wrh level
L2b9f:  ld      l,$0b            ; %00001011 = set bit 5 (cassette write data)
L2ba1:  call    L2ba7

L2ba4:  ld      a,$01            
L2ba6:  ret     


;;============================================================
;; wr to cassette
;; usntrol bit set/clear function
;; L trol byte 
;;   
;;    = bit index
;;   bit set, 0=bit clear

L2ba7:  ld      a,r
L2ba9:  srl     a
L2bab:  sub     c
L2bac:  jr      nc,L2bb1         ; 

;; des (16T-state) units
;; to = ((A-1)*4) + 3

L2bae:  inc     a                ; [1]
L2baf:  jr      nz,L2bae         ; [3] 

;; seh level
L2bb1:  ld      b,$f7            ; PPI control 
L2bb3:  out     (c),l            ; set control

L2bb5:  push    af
L2bb6:  xor     a
L2bb7:  ld      r,a
L2bb9:  pop     af
L2bba:  ret     

;;============================================================
;; CAOTOR
;;
;; sttte motor (if cassette motor was previously off
;; al achieve full rotational speed)
L2bbb:  ld      a,$10            ; start cassette motor
L2bbd:  jr      L2bc1            ; CAS RESTORE MOTOR 

;;============================================================
;; CATOR

L2bbf:  ld      a,$ef            ; stop cassette motor

;;============================================================
;; CA MOTOR
;;
;; - was switched from off->on, delay for a time to allow
;; cator to achieve full rotational speed
;; - was switched from on->off, do nothing

;; bigister A = cassette motor state
L2bc1:  push    bc

L2bc2:  ld      b,$f6        ; B = I/O address for PPI port C 
L2bc4:  in      c,(c)        ; read current inputs (includes cassette input data)
L2bc6:  inc     b            ; B = I/O address for PPI control       

L2bc7:  and     $10          ; isolate cassette motor state from requested
                           ; cassette motor status
                           
L2bc9:  ld      a,$08        ; %00001000 = cassette motor off
L2bcb:  jr      z,L2bce

L2bcd:  inc     a            ; %00001001 = cassette motor on

L2bce:  out     (c),a        ; set the requested motor state
                           ; (uses PPI Control bit set/reset feature)

L2bd0:  scf     
L2bd1:  jr      z,L2bdf          

L2bd3:  ld      a,c
L2bd4:  and     $10          ; previous state

L2bd6:  push    bc
L2bd7:  ld      bc,$00c8     ; delay in 1/100ths of a second
L2bda:  scf     
L2bdb:  call    z,L2be2      ; delay for 2 seconds
L2bde:  pop     bc

L2bdf:  ld      a,c
L2be0:  pop     bc
L2be1:  ret     

;;========================================================
;; deck for escape; allows cassette motor to achieve full
;; rospeed

;; entions:
;; B actor in 1/100ths of a second

;; exions:
;; c ompleted and escape was not pressed
;; nc was pressed

L2be2:  push    bc
L2be3:  push    hl
L2be4:  call    L2bf9        ;; 1/100th of a second delay

L2be7:  ld      a,$42        ;; keycode for escape key 
L2be9:  call    L1e45        ;; check for escape pressed (km test key)
                           ;; if non-zero then escape key has been pressed
                           ;; if zero, then escape key is not pressed
L2bec:  pop     hl
L2bed:  pop     bc
L2bee:  jr      nz,L2bf7     ;; escape key pressed?

;; colay
L2bf0:  dec     bc
L2bf1:  ld      a,b
L2bf2:  or      c
L2bf3:  jr      nz,L2be2 

;; deeted successfully and escape was not pressed
L2bf5:  scf     
L2bf6:  ret     

;; espressed
L2bf7:  xor     a
L2bf8:  ret     

;;===============================================================================
;; 1/ second delay

L2bf9:  ld      bc,$0682         ; [3]

;; to is ((BC-1)*(2+1+1+3)) + (2+1+1+2) + 3 + 3 = 11667 microseconds
;; th000000 microseconds in a second
;; thelay is 11667/1000000 = 0.01 seconds or 1/100th of a second

L2bfc:  dec     bc               ; [2]
L2bfd:  ld      a,b              ; [1]
L2bfe:  or      c                ; [1]
L2bff:  jr      nz,L2bfc         ; [3]

L2c01:  ret                      ; [3]     
;;===============================================================================
;; ED
;; HLs of buffer

L2c02:  push    bc
L2c03:  push    de
L2c04:  push    hl
L2c05:  call    L2df2            ; reset relative cursor pos
L2c08:  ld      bc,$00ff         
; B = in edit buffer
; C =f characters remaining in buffer

;; if a number at the start of the line then skip it
L2c0b:  ld      a,(hl)
L2c0c:  cp      $30              ; '0'
L2c0e:  jr      c,L2c17          ; (+$07)
L2c10:  cp      $3a              ; '9'+1
L2c12:  call    c,L2c42
L2c15:  jr      c,L2c0b          

;;-----------------------------------------------------------
;; alharacters
L2c17:  ld      a,b
L2c18:  or      a
;; zeet if start of buffer, zero flag clear if not start of buffer

L2c19:  ld      a,(hl)
L2c1a:  call    nz,L2c42

L2c1d:  push    hl
L2c1e:  inc     c
L2c1f:  ld      a,(hl)
L2c20:  inc     hl
L2c21:  or      a
L2c22:  jr      nz,L2c1e         ; (-$06)

L2c24:  ld      ($b115),a        ; insert/overwrite mode
L2c27:  pop     hl
L2c28:  call    L2ee4


L2c2b:  push    bc
L2c2c:  push    hl
L2c2d:  call    L2f56
L2c30:  pop     hl
L2c31:  pop     bc
L2c32:  call    L2c48            ; process key
L2c35:  jr      nc,L2c2b         ; (-$0c)

L2c37:  push    af
L2c38:  call    L2e4f
L2c3b:  pop     af
L2c3c:  pop     hl
L2c3d:  pop     de
L2c3e:  pop     bc
L2c3f:  cp      $fc
L2c41:  ret     

;;-----------------------------------------------------------
;; usp characters in input buffer

L2c42:  inc     c
L2c43:  inc     b        ; increment pos
L2c44:  inc     hl       ; increment position in buffer
L2c45:  jp      L2f25

;;-----------------------------------------------------------

L2c48:  push    hl
L2c49:  ld      hl,$2c72
L2c4c:  ld      e,a
L2c4d:  ld      a,b
L2c4e:  or      c
L2c4f:  ld      a,e
L2c50:  jr      nz,L2c5d         ; (+$0b)

L2c52:  cp      $f0              ;
L2c54:  jr      c,L2c5d          ; (+$07)
L2c56:  cp      $f4
L2c58:  jr      nc,L2c5d         ; (+$03)

;; cu
L2c5a:  ld      hl,$2cae

;;-----------------------------------------------------------
L2c5d:  ld      d,(hl)
L2c5e:  inc     hl
L2c5f:  push    hl
L2c60:  inc     hl
L2c61:  inc     hl
L2c62:  cp      (hl)
L2c63:  inc     hl
L2c64:  jr      z,L2c6a          ; (+$04)
L2c66:  dec     d
L2c67:  jr      nz,L2c60         ; (-$09)
L2c69:  ex      (sp),hl
L2c6a:  pop     af
L2c6b:  ld      a,(hl)
L2c6c:  inc     hl
L2c6d:  ld      h,(hl)
L2c6e:  ld      l,a
L2c6f:  ld      a,e
L2c70:  ex      (sp),hl
L2c71:  ret     

;; keiting an existing line
L2c72:  defb $13
        defw $2d8a
        defb $fc                                ; ESC key
        defw $2cd0                              
        defb $ef
        defw $2cce
        defb $0d                                ; RETURN key
        defw $2cf2
        defb $f0                                ; up cursor key
        defw $2d3c
        defb $f1                                ; down cursor key
        defw $2d0a
        defb $f2                                ; left cursor key
        defw $2d34
        defb $f3                                ; right cursor key
        defw $2d02
        defb $f8                                ; CTRL key + up cursor key
        defw $2d4f
        defb $f9                                ; CTRL key + down cursor key
        defw $2d1d
        defb $fa                                ; CTRL key + left cursor key
        defw $2d45
        defb $fb                                ; CTRL key + right cursor key
        defw $2d14
        defb $f4                                ; SHIFT key + up cursor key
        defw $2e21
        defb $f5                                ; SHIFT key + down cursor key
        defw $2e26
        defb $f6                                ; SHIFT key + left cursor key
        defw $2e1c
        defb $f7                                ; SHIFT key + right cursor key
        defw $2e17                              
        defb $e0                                ; COPY key
        defw $2e65
        defb $7f                                ; ESC key
        defw $2dc3
        defb $10                                ; CLR key
        defw $2dcd
        defb $e1                                ; CTRL key+TAB key (toggle insert/overwrite)
        defw $2d81

;;-----------------------------------------------------------

;; ke
L2cae:: defb $04
        defw $2cfe                              ; Sound bleeper
        defb $f0                                ; up cursor key
        defw $2cbd                              ; Move cursor up a line
        defb $f1                                ; down cursor key
        defw $2cc1                              ; Move cursor down a line
        defb $f2                                ; left cursor key
        defw $2cc9                              ; Move cursor back one character
        defb $f3                                ; right cursor key
        defw $2cc5                              ; Move cursor forward one character

;;-----------------------------------------------------------
;; upey pressed
L2cbd:  ld      a,$0b            ; VT (Move cursor up a line)
L2cbf:  jr      L2ccb            ; 

;;-----------------------------------------------------------
;; do key pressed
L2cc1:  ld      a,$0a            ; LF (Move cursor down a line)
L2cc3:  jr      L2ccb           

;;-----------------------------------------------------------
;; rir key pressed
L2cc5:  ld      a,$09            ; TAB (Move cursor forward one character)
L2cc7:  jr      L2ccb            ; 

;;-----------------------------------------------------------
;; le key pressed
L2cc9:  ld      a,$08            ; BS (Move character back one character)

;;-----------------------------------------------------------

L2ccb:  call    L13fe            ; TXT OUTPUT

;;-----------------------------------------------------------
L2cce:  or      a
L2ccf:  ret     

;;-----------------------------------------------------------

L2cd0:  call    L2cf2            ; display message
L2cd3:  push    af
L2cd4:  ld      hl,$2cea         ; "*Break*"
L2cd7:  call    L2cf2            ; display message

L2cda:  call    L117c            ; TXT GET CURSOR
L2cdd:  dec     h
L2cde:  jr      z,L2ce8          

;; goline
L2ce0:  ld      a,$0d            ; CR (Move cursor to left edge of window on current line)
L2ce2:  call    L13fe            ; TXT OUTPUT
L2ce5:  call    L2cc1            ; Move cursor down a line

L2ce8:  pop     af
L2ce9:  ret     

;;-----------------------------------------------------------
L2cea:  defb "*Break*",0

;;-----------------------------------------------------------
;; dierminated string

L2cf2:  push af
L2cf3:  ld      a,(hl)           ; get character
L2cf4:  inc     hl
L2cf5:  or      a                ; end of string marker?
L2cf6:  call    nz,L2f25         ; display character
L2cf9:  jr      nz,L2cf3         ; loop for next character
L2cfb:  pop     af
L2cfc:  scf     
L2cfd:  ret     

;;==================================================================
L2cfe:  ld      a,$07            ; BEL (Sound bleeper)
L2d00:  jr      L2ccb

;;==================================================================
;; rir key pressed
L2d02:  ld      d,$01
L2d04:  call    L2d1e
L2d07:  jr      z,L2cfe          ; (-$0b)
L2d09:  ret     

;;==================================================================
;; do key pressed

L2d0a:  call    L2d73
L2d0d:  ld      a,c
L2d0e:  sub     b
L2d0f:  cp      d
L2d10:  jr      c,L2cfe          ; (-$14)
L2d12:  jr      L2d1e            ; (+$0a)

;;-----------------------------------------------------------
;; CTright cursor key pressed
;; 
;; gof current line
L2d14:  call    L2d73
L2d17:  ld      a,d
L2d18:  sub     e
L2d19:  ret     z

L2d1a:  ld      d,a
L2d1b:  jr      L2d1e            ; (+$01)

;;-----------------------------------------------------------
;; CTdown cursor key pressed
;;
;; gof text 

L2d1d:  ld      d,c

;;-----------------------------------------------------------

L2d1e:  ld      a,b
L2d1f:  cp      c
L2d20:  ret     z

L2d21:  push    de
L2d22:  call    L2ecd
L2d25:  ld      a,(hl)
L2d26:  call    nc,L2f25
L2d29:  inc     b
L2d2a:  inc     hl
L2d2b:  call    nc,L2ee4
L2d2e:  pop     de
L2d2f:  dec     d
L2d30:  jr      nz,L2d1e         ; (-$14)
L2d32:  jr      L2d70            ; (+$3c)

;;==================================================================
;; le key pressed
L2d34:  ld      d,$01
L2d36:  call    L2d50
L2d39:  jr      z,L2cfe          ; (-$3d)
L2d3b:  ret     


;;==================================================================
;; upey pressed
L2d3c:  call    L2d73
L2d3f:  ld      a,b
L2d40:  cp      d
L2d41:  jr      c,L2cfe          ; (-$45)
L2d43:  jr      L2d50            ; (+$0b)


;;==================================================================
;; CTleft cursor key pressed
;;
;; go of current line

L2d45:  call    L2d73
L2d48:  ld      a,e
L2d49:  sub     $01
L2d4b:  ret     z

L2d4c:  ld      d,a
L2d4d:  jr      L2d50            ; (+$01)

;;==================================================================
;; CTup cursor key pressed

;; go of text

L2d4f:  ld      d,c

L2d50:  ld      a,b
L2d51:  or      a
L2d52:  ret     z

L2d53:  call    L2ec7
L2d56:  jr      nc,L2d5f         ; (+$07)
L2d58:  dec     b
L2d59:  dec     hl
L2d5a:  dec     d
L2d5b:  jr      nz,L2d50         ; (-$0d)
L2d5d:  jr      L2d70            ; (+$11)

;;==================================================================
L2d5f:  ld      a,b
L2d60:  or      a
L2d61:  jr      z,L2d6d          ; (+$0a)
L2d63:  dec     b
L2d64:  dec     hl
L2d65:  push    de
L2d66:  call    L2ea2
L2d69:  pop     de
L2d6a:  dec     d
L2d6b:  jr      nz,L2d5f         ; (-$0e)
L2d6d:  call    L2ee4
L2d70:  or      $ff
L2d72:  ret     

;;-----------------------------------------------------------
L2d73:  push    hl
L2d74:  call    L1252            ; TXT GET WINDOW
L2d77:  ld      a,d
L2d78:  sub     h
L2d79:  inc     a
L2d7a:  ld      d,a
L2d7b:  call    L117c            ; TXT GET CURSOR
L2d7e:  ld      e,h
L2d7f:  pop     hl
L2d80:  ret     
;;-----------------------------------------------------------
;; CTTAB key
;; 
;; tort/overwrite mode
L2d81:  ld      a,($b115)        ; insert/overwrite mode
L2d84:  cpl     
L2d85:  ld      ($b115),a
L2d88:  or      a
L2d89:  ret     

;;-----------------------------------------------------------
L2d8a:  or      a
L2d8b:  ret     z

L2d8c:  ld      e,a
L2d8d:  ld      a,($b115)        ; insert/overwrite mode
L2d90:  or      a
L2d91:  ld      a,c
L2d92:  jr      z,L2d9f          ; (+$0b)
L2d94:  cp      b
L2d95:  jr      z,L2d9f          ; (+$08)
L2d97:  ld      (hl),e
L2d98:  inc     hl
L2d99:  inc     b
L2d9a:  or      a
L2d9b:  ld      a,e
L2d9c:  jp      L2f25

L2d9f:  cp      $ff
L2da1:  jp      z,L2cfe
L2da4:  xor     a
L2da5:  ld      ($b114),a
L2da8:  call    L2d9b
L2dab:  inc     c
L2dac:  push    hl
L2dad:  ld      a,(hl)
L2dae:  ld      (hl),e
L2daf:  ld      e,a
L2db0:  inc     hl
L2db1:  or      a
L2db2:  jr      nz,L2dad         ; (-$07)
L2db4:  ld      (hl),a
L2db5:  pop     hl
L2db6:  inc     b
L2db7:  inc     hl
L2db8:  call    L2ee4
L2dbb:  ld      a,($b114)
L2dbe:  or      a
L2dbf:  call    nz,L2ea2
L2dc2:  ret     

;; ESssed
L2dc3:  ld      a,b
L2dc4:  or      a
L2dc5:  call    nz,L2ec7
L2dc8:  jp      nc,L2cfe
L2dcb:  dec     b
L2dcc:  dec     hl

;; CLssed
L2dcd:  ld      a,b
L2dce:  cp      c
L2dcf:  jp      z,L2cfe
L2dd2:  push    hl
L2dd3:  inc     hl
L2dd4:  ld      a,(hl)
L2dd5:  dec     hl
L2dd6:  ld      (hl),a
L2dd7:  inc     hl
L2dd8:  or      a
L2dd9:  jr      nz,L2dd3         ; (-$08)
L2ddb:  dec     hl
L2ddc:  ld      (hl),$20
L2dde:  ld      ($b114),a
L2de1:  ex      (sp),hl
L2de2:  call    L2ee4
L2de5:  ex      (sp),hl
L2de6:  ld      (hl),$00
L2de8:  pop     hl
L2de9:  dec     c
L2dea:  ld      a,($b114)
L2ded:  or      a
L2dee:  call    nz,L2ea6
L2df1:  ret     


;;-----------------------------------------------------------
;; inrelative copy cursor position to origin
L2df2:  xor     a
L2df3:  ld      ($b116),a
L2df6:  ld      ($b117),a
L2df9:  ret     

;;-----------------------------------------------------------
;; coy cursor relative position
;; HL position
L2dfa:  ld      de,($b116)
L2dfe:  ld      a,h
L2dff:  xor     d
L2e00:  ret     nz
L2e01:  ld      a,l
L2e02:  xor     e
L2e03:  ret     nz
L2e04:  scf     
L2e05:  ret     
;;-----------------------------------------------------------

L2e06:  ld      c,a
L2e07:  call    L2ec1            ; get copy cursor position
L2e0a:  ret     z                ; quit if not active

;; adsition
L2e0b:  ld      a,l
L2e0c:  add     a,c
L2e0d:  ld      l,a

;; vaw position
L2e0e:  call    L11ca            ; TXT VALIDATE
L2e11:  jr      nc,L2df2         ; reset relative cursor pos

;; seposition
L2e13:  ld      ($b116),hl
L2e16:  ret     

;;-----------------------------------------------------------
;; SH left cursor key
;; 
;; moursor left
L2e17:  ld      de,$0100
L2e1a:  jr      L2e29            ; (+$0d)
;;-----------------------------------------------------------
;; SH right cursor pressed
;; 
;; moursor right
L2e1c:  ld      de,$ff00
L2e1f:  jr      L2e29            ; (+$08)
;;-----------------------------------------------------------
;; SH up cursor pressed
;;
;; moursor up
L2e21:  ld      de,$00ff
L2e24:  jr      L2e29            ; (+$03)
;;-----------------------------------------------------------
;; SH left cursor pressed
;;
;; moursor down
L2e26:  ld      de,$0001

;;-----------------------------------------------------------
;; D increment
;; E rement
L2e29:  push    bc
L2e2a:  push    hl
L2e2b:  call    L2ec1            ; get copy cursor position

;; geposition
L2e2e:  call    z,L117c          ; TXT GET CURSOR

;; ador position

;; admn
L2e31:  ld      a,h
L2e32:  add     a,d
L2e33:  ld      h,a

;; ad
L2e34:  ld      a,l
L2e35:  add     a,e
L2e36:  ld      l,a
;; vae position
L2e37:  call    L11ca            ; TXT VALIDATE
L2e3a:  jr      nc,L2e47         ; position invalid?

;; po valid

L2e3c:  push    hl
L2e3d:  call    L2e4f
L2e40:  pop     hl

;; stosition
L2e41:  ld      ($b116),hl

L2e44:  call    L2e4a

;;-------

L2e47:  pop     hl
L2e48:  pop     bc
L2e49:  ret     

;;-----------------------------------------------------------

L2e4a:  ld      de,$1265         ; TXT PLACE CURSOR/TXT REMOVE CURSOR
L2e4d:  jr      L2e52            

;;-----------------------------------------------------------
L2e4f:  ld      de,$1265         ; TXT PLACE CURSOR/TXT REMOVE CURSOR

;;-----------------------------------------------------------
L2e52:  call    L2ec1            ; get copy cursor position
L2e55:  ret     z

L2e56:  push    hl
L2e57:  call    L117c            ; TXT GET CURSOR
L2e5a:  ex      (sp),hl
L2e5b:  call    L1170            ; TXT SET CURSOR
L2e5e:  call    L0016            ; LOW: PCDE INSTRUCTION
L2e61:  pop     hl
L2e62:  jp      L1170            ; TXT SET CURSOR
;;-----------------------------------------------------------
;; COessed
L2e65:  push    bc
L2e66:  push    hl
L2e67:  call    L117c            ; TXT GET CURSOR
L2e6a:  ex      de,hl
L2e6b:  call    L2ec1
L2e6e:  jr      nz,L2e7c         ; perform copy
L2e70:  ld      a,b
L2e71:  or      c
L2e72:  jr      nz,L2e9a         ; (+$26)
L2e74:  call    L117c            ; TXT GET CURSOR
L2e77:  ld      ($b116),hl
L2e7a:  jr      L2e82            ; (+$06)

;;-----------------------------------------------------------

L2e7c:  call    L1170            ; TXT SET CURSOR
L2e7f:  call    L1265            ; TXT PLACE CURSOR/TXT REMOVE CURSOR

L2e82:  call    L13ac            ; TXT RD CHAR
L2e85:  push    af
L2e86:  ex      de,hl
L2e87:  call    L1170            ; TXT SET CURSOR
L2e8a:  ld      hl,($b116)
L2e8d:  inc     h
L2e8e:  call    L11ca            ; TXT VALIDATE
L2e91:  jr      nc,L2e96         ; (+$03)
L2e93:  ld      ($b116),hl
L2e96:  call    L2e4a
L2e99:  pop     af
L2e9a:  pop     hl
L2e9b:  pop     bc
L2e9c:  jp      c,L2d8a
L2e9f:  jp      L2cfe

;;-----------------------------------------------------------

L2ea2:  ld      d,$01
L2ea4:  jr      L2ea8            ; (+$02)

;;-----------------------------------------------------------

L2ea6:  ld      d,$ff
;;-----------------------------------------------------------
L2ea8:  push    bc
L2ea9:  push    hl
L2eaa:  push    de
L2eab:  call    L2e4f
L2eae:  pop     de
L2eaf:  call    L2ec1
L2eb2:  jr      z,L2ebd          ; (+$09)
L2eb4:  ld      a,h
L2eb5:  add     a,d
L2eb6:  ld      h,a
L2eb7:  call    L2e0e
L2eba:  call    L2e4a
L2ebd:  pop     hl
L2ebe:  pop     bc
L2ebf:  or      a
L2ec0:  ret     

;;-----------------------------------------------------------
;; gersor position
;; thative to the actual cursor pos
;;
;; zeet if cursor is not active
L2ec1:  ld      hl,($b116)
L2ec4:  ld      a,h
L2ec5:  or      l
L2ec6:  ret     
;;-----------------------------------------------------------
;; tr cursor left?
L2ec7:  push    de
L2ec8:  ld      de,$ff08
L2ecb:  jr      L2ed1            ; (+$04)

;;-----------------------------------------------------------
;; tr cursor right?
L2ecd:  push    de
L2ece:  ld      de,$0109
;;-----------------------------------------------------------
;; D increment
;; E er to plot
L2ed1:  push    bc
L2ed2:  push    hl

;; ge cursor position
L2ed3:  call    L117c            ; TXT GET CURSOR

;; ador position
L2ed6:  ld      a,d              ; column increment
L2ed7:  add     a,h              ; add on column
L2ed8:  ld      h,a              ; final column

;; vais new position
L2ed9:  call    L11ca            ; TXT VALIDATE

;; ifen output character, otherwise report error
L2edc:  ld      a,e
L2edd:  call    c,L13fe          ; TXT OUTPUT

L2ee0:  pop     hl
L2ee1:  pop     bc
L2ee2:  pop     de
L2ee3:  ret     

;;-----------------------------------------------------------
L2ee4:  push    bc
L2ee5:  push    hl
L2ee6:  ex      de,hl
L2ee7:  call    L117c            ; TXT GET CURSOR
L2eea:  ld      c,a
L2eeb:  ex      de,hl
L2eec:  ld      a,(hl)
L2eed:  inc     hl
L2eee:  or      a
L2eef:  call    nz,L2f02
L2ef2:  jr      nz,L2eec         ; (-$08)
L2ef4:  call    L117c            ; TXT GET CURSOR
L2ef7:  sub     c
L2ef8:  ex      de,hl
L2ef9:  add     a,l
L2efa:  ld      l,a
L2efb:  call    L1170            ; TXT SET CURSOR
L2efe:  pop     hl
L2eff:  pop     bc
L2f00:  or      a
L2f01:  ret     

L2f02:  push    af
L2f03:  push    bc
L2f04:  push    de
L2f05:  push    hl
L2f06:  ld      b,a
L2f07:  call    L117c            ; TXT GET CURSOR
L2f0a:  sub     c
L2f0b:  add     a,e
L2f0c:  ld      e,a
L2f0d:  ld      c,b
L2f0e:  call    L11ca            ; TXT VALIDATE
L2f11:  jr      c,L2f18          ; (+$05)
L2f13:  ld      a,b
L2f14:  add     a,a
L2f15:  inc     a
L2f16:  add     a,e
L2f17:  ld      e,a
L2f18:  ex      de,hl
L2f19:  call    L11ca            ; TXT VALIDATE
L2f1c:  ld      a,c
L2f1d:  call    c,L2f25
L2f20:  pop     hl
L2f21:  pop     de
L2f22:  pop     bc
L2f23:  pop     af
L2f24:  ret     

L2f25:  push    af
L2f26:  push    bc
L2f27:  push    de
L2f28:  push    hl
L2f29:  ld      b,a
L2f2a:  call    L117c            ; TXT GET CURSOR
L2f2d:  ld      c,a
L2f2e:  push    bc
L2f2f:  call    L11ca            ; TXT VALIDATE
L2f32:  pop     bc
L2f33:  call    c,L2dfa
L2f36:  push    af
L2f37:  call    c,L2e4f
L2f3a:  ld      a,b
L2f3b:  push    bc
L2f3c:  call    L1335            ; TXT WR CHAR
L2f3f:  pop     bc
L2f40:  call    L117c            ; TXT GET CURSOR
L2f43:  sub     c
L2f44:  call    nz,L2e06
L2f47:  pop     af
L2f48:  jr      nc,L2f51         ; (+$07)
L2f4a:  sbc     a,a
L2f4b:  ld      ($b114),a
L2f4e:  call    L2e4a
L2f51:  pop     hl
L2f52:  pop     de
L2f53:  pop     bc
L2f54:  pop     af
L2f55:  ret     

L2f56:  call    L117c            ; TXT GET CURSOR
L2f59:  ld      c,a
L2f5a:  call    L11ca            ; TXT VALIDATE
L2f5d:  call    L2dfa
L2f60:  jp      c,L1bbf          ; KM WAIT CHAR
L2f63:  call    L1276            ; TXT CUR ON
L2f66:  call    L117c            ; TXT GET CURSOR
L2f69:  sub     c
L2f6a:  call    nz,L2e06
L2f6d:  call    L1bbf            ; KM WAIT CHAR
L2f70:  jp      L127e            ; TXT CUR OFF

;;==================================================================================
;; MAIONS

;; RE
L2f73:  ld      de,$2f78
L2f76:  jr      L2f91           

L2f78:  defb $a2,$da,$0f,$49,$82                ;; PI in floating point format

;;==================================================================================
;; RE
L2f7d:  ld      de,$2f82
L2f80:  jr      L2f91            ; (+$0f)

L2f82:  defb $00,$00,$00,$00,$81            ;; 1 in floating point format

;;==================================================================================
L2f87:  ex      de,hl
L2f88:  ld      hl,$b10e
L2f8b:  jr      L2f91            ; (+$04)

;;==================================================================================
L2f8d:  ld      de,$b104
L2f90:  ex      de,hl

;; RE
;; HL to address to write floating point number to
;; DE to address of a floating point number

L2f91:  push    hl
L2f92:  push    de
L2f93:  push    bc
L2f94:  ex      de,hl
L2f95:  ld      bc,$0005
L2f98:  ldir    
L2f9a:  pop     bc
L2f9b:  pop     de
L2f9c:  pop     hl
L2f9d:  scf     
L2f9e:  ret     

;; IN
L2f9f:  push    de
L2fa0:  push    bc
L2fa1:  or      $7f
L2fa3:  ld      b,a
L2fa4:  xor     a
L2fa5:  ld      (de),a
L2fa6:  inc     de
L2fa7:  ld      (de),a
L2fa8:  inc     de
L2fa9:  ld      c,$90
L2fab:  or      h
L2fac:  jr      nz,L2fbb         ; (+$0d)
L2fae:  ld      c,a
L2faf:  or      l
L2fb0:  jr      z,L2fbf          ; (+$0d)
L2fb2:  ld      l,h
L2fb3:  ld      c,$88
L2fb5:  jr      L2fbb            ; (+$04)
L2fb7:  dec     c
L2fb8:  sla     l
L2fba:  adc     a,a
L2fbb:  jp      p,L2fb7
L2fbe:  and     b
L2fbf:  ex      de,hl
L2fc0:  ld      (hl),e
L2fc1:  inc     hl
L2fc2:  ld      (hl),a
L2fc3:  inc     hl
L2fc4:  ld      (hl),c
L2fc5:  pop     bc
L2fc6:  pop     hl
L2fc7:  ret     

;; BI
L2fc8:  push    bc
L2fc9:  ld      bc,$a000
L2fcc:  call    L2fd3
L2fcf:  pop     bc
L2fd0:  ret     

L2fd1:  ld      b,$a8
L2fd3:  push    de
L2fd4:  call    L379c
L2fd7:  pop     de
L2fd8:  ret     

;; RE
L2fd9:  push    hl
L2fda:  pop     ix
L2fdc:  xor     a
L2fdd:  sub     (ix+$04)
L2fe0:  jr      z,L2ffd          ; (+$1b)
L2fe2:  add     a,$90
L2fe4:  ret     nc

L2fe5:  push    de
L2fe6:  push    bc
L2fe7:  add     a,$10
L2fe9:  call    L373d
L2fec:  sla     c
L2fee:  adc     hl,de
L2ff0:  jr      z,L2ffa          ; (+$08)
L2ff2:  ld      a,(ix+$03)
L2ff5:  or      a
L2ff6:  ccf     
L2ff7:  pop     bc
L2ff8:  pop     de
L2ff9:  ret     

L2ffa:  sbc     a,a
L2ffb:  jr      L2ff6            ; (-$07)
L2ffd:  ld      l,a
L2ffe:  ld      h,a
L2fff:  scf     
L3000:  ret     

;; RE
L3001:  call    L3014
L3004:  ret     nc

L3005:  ret     p

L3006:  push    hl
L3007:  ld      a,c
L3008:  inc     (hl)
L3009:  jr      nz,L3011         ; (+$06)
L300b:  inc     hl
L300c:  dec     a
L300d:  jr      nz,L3008         ; (-$07)
L300f:  inc     (hl)
L3010:  inc     c
L3011:  pop     hl
L3012:  scf     
L3013:  ret     

;; RE

L3014:  push    hl
L3015:  push    de
L3016:  push    hl
L3017:  pop     ix
L3019:  xor     a
L301a:  sub     (ix+$04)
L301d:  jr      nz,L3029         ; (+$0a)
L301f:  ld      b,$04
L3021:  ld      (hl),a
L3022:  inc     hl
L3023:  djnz    $3021            ; (-$04)
L3025:  ld      c,$01
L3027:  jr      L3051            ; (+$28)

L3029:  add     a,$a0
L302b:  jr      nc,L3052         ; (+$25)
L302d:  push    hl
L302e:  call    L373d
L3031:  xor     a
L3032:  cp      b
L3033:  adc     a,a
L3034:  or      c
L3035:  ld      c,l
L3036:  ld      b,h
L3037:  pop     hl
L3038:  ld      (hl),c
L3039:  inc     hl
L303a:  ld      (hl),b
L303b:  inc     hl
L303c:  ld      (hl),e
L303d:  inc     hl
L303e:  ld      e,a
L303f:  ld      a,(hl)
L3040:  ld      (hl),d
L3041:  and     $80
L3043:  ld      b,a
L3044:  ld      c,$04
L3046:  xor     a
L3047:  or      (hl)
L3048:  jr      nz,L304f         ; (+$05)
L304a:  dec     hl
L304b:  dec     c
L304c:  jr      nz,L3047         ; (-$07)
L304e:  inc     c
L304f:  ld      a,e
L3050:  or      a
L3051:  scf     
L3052:  pop     de
L3053:  pop     hl
L3054:  ret     

;; RE

L3055:  call    L3014
L3058:  ret     nc

L3059:  ret     z

L305a:  bit     7,b
L305c:  ret     z

L305d:  jr      L3006            ; (-$59)
L305f:  call    L3727
L3062:  ld      b,a
L3063:  jr      z,L30b7          ; (+$52)
L3065:  call    m,$3734
L3068:  push    hl
L3069:  ld      a,(ix+$04)
L306c:  sub     $80
L306e:  ld      e,a
L306f:  sbc     a,a
L3070:  ld      d,a
L3071:  ld      l,e
L3072:  ld      h,d
L3073:  add     hl,hl
L3074:  add     hl,hl
L3075:  add     hl,hl
L3076:  add     hl,de
L3077:  add     hl,hl
L3078:  add     hl,de
L3079:  add     hl,hl
L307a:  add     hl,hl
L307b:  add     hl,de
L307c:  ld      a,h
L307d:  sub     $09
L307f:  ld      c,a
L3080:  pop     hl
L3081:  push    bc
L3082:  call    nz,L30c8
L3085:  ld      de,$30bc
L3088:  call    L36e2
L308b:  jr      nc,L3098         ; (+$0b)
L308d:  ld      de,$30f5         ; start of power's of ten
L3090:  call    L3577
L3093:  pop     de
L3094:  dec     e
L3095:  push    de
L3096:  jr      L3085            ; (-$13)
L3098:  ld      de,$30c1
L309b:  call    L36e2
L309e:  jr      c,L30ab          ; (+$0b)
L30a0:  ld      de,$30f5         ; start of power's of ten
L30a3:  call    L3604
L30a6:  pop     de
L30a7:  inc     e
L30a8:  push    de
L30a9:  jr      L3098            ; (-$13)
L30ab:  call    L3001
L30ae:  ld      a,c
L30af:  pop     de
L30b0:  ld      b,d
L30b1:  dec     a
L30b2:  add     a,l
L30b3:  ld      l,a
L30b4:  ret     nc

L30b5:  inc     h
L30b6:  ret     

L30b7:  ld      e,a
L30b8:  ld      (hl),a
L30b9:  ld      c,$01
L30bb:  ret     

L30bc:  defb $f0,$1f,$bc,$3e,$96

L30c1:  defb $fe,$27,$6b,$6e,$9e

;; RE
L30c6:  cpl     
L30c7:  inc     a
L30c8:  or      a
L30c9:  scf     
L30ca:  ret     z

L30cb:  ld      c,a
L30cc:  jp      p,L30d1
L30cf:  cpl     
L30d0:  inc     a
L30d1:  ld      de,$3131
L30d4:  sub     $0d
L30d6:  jr      z,L30ed          ; (+$15)
L30d8:  jr      c,L30e3          ; (+$09)
L30da:  push    bc
L30db:  push    af
L30dc:  call    L30ed
L30df:  pop     af
L30e0:  pop     bc
L30e1:  jr      L30d1            ; (-$12)
L30e3:  ld      b,a
L30e4:  add     a,a
L30e5:  add     a,a
L30e6:  add     a,b
L30e7:  add     a,e
L30e8:  ld      e,a
L30e9:  ld      a,$ff
L30eb:  adc     a,d
L30ec:  ld      d,a
L30ed:  ld      a,c
L30ee:  or      a
L30ef:  jp      p,L3604
L30f2:  jp      L3577

;;==================================================================================
;; po10 in internal floating point representation
;;
L30f5:  defb $00,$00,$00,$20,$84            ;; 10 (10^1)
        defb $00,$00,$00,$48,$87            ;; 100 (10^2)
        defb $00,$00,$00,$7A,$8A            ;; 1000 (10^3)
        defb $00,$00,$40,$1c,$8e            ;; 10000 (10^4) (1E+4)
        defb $00,$00,$50,$43,$91            ;; 100000 (10^5) (1E+5)
        defb $00,$00,$24,$74,$94            ;; 1000000 (10^6) (1E+6)
        defb $00,$80,$96,$18,$98            ;; 10000000 (10^7) (1E+7)
        defb $00,$20,$bc,$3e,$9b            ;; 100000000 (10^8) (1E+8)
        defb $00,$28,$6b,$6e,$9e            ;; 1000000000 (10^9) (1E+9)
        defb $00,$f9,$02,$15,$a2            ;; 10000000000 (10^10) (1E+10)
        defb $40,$b7,$43,$3a,$a5            ;; 100000000000 (10^11) (1E+11)
        defb $10,$a5,$d4,$68,$a8            ;; 1000000000000 (10^12) (1E+12)
        defb $2a,$e7,$84,$11,$ac            ;; 10000000000000 (10^13) (1E+13)
;;==================================================================================

L3136:  ld      hl,$8965
L3139:  ld      ($b102),hl
L313c:  ld      hl,$6c07
L313f:  ld      ($b100),hl
L3142:  ret     

;; RANDOMIZE seed
L3143:  ex      de,hl
L3144:  call    L3136
L3147:  ex      de,hl
L3148:  call    L3727
L314b:  ret     z

L314c:  ld      de,$b100
L314f:  ld      b,$04
L3151:  ld      a,(de)
L3152:  xor     (hl)
L3153:  ld      (de),a
L3154:  inc     de
L3155:  inc     hl
L3156:  djnz    $3151            ; (-$07)
L3158:  ret     

;; REAL rnd
L3159:  push    hl
L315a:  ld      hl,($b102)
L315d:  ld      bc,$6c07
L3160:  call    L319c
L3163:  push    hl
L3164:  ld      hl,($b100)
L3167:  ld      bc,$8965
L316a:  call    L319c
L316d:  push    de
L316e:  push    hl
L316f:  ld      hl,($b102)
L3172:  call    L319c
L3175:  ex      (sp),hl
L3176:  add     hl,bc
L3177:  ld      ($b100),hl
L317a:  pop     hl
L317b:  ld      bc,$6c07
L317e:  adc     hl,bc
L3180:  pop     bc
L3181:  add     hl,bc
L3182:  pop     bc
L3183:  add     hl,bc
L3184:  ld      ($b102),hl
L3187:  pop     hl

;; REAL rnd0
L3188:  push    hl
L3189:  pop     ix
L318b:  ld      hl,($b100)
L318e:  ld      de,($b102)
L3192:  ld      bc,$0000
L3195:  ld      (ix+$04),$80
L3199:  jp      L37ac
L319c:  ex      de,hl
L319d:  ld      hl,$0000
L31a0:  ld      a,$11
L31a2:  dec     a
L31a3:  ret     z

L31a4:  add     hl,hl
L31a5:  rl      e
L31a7:  rl      d
L31a9:  jr      nc,L31a2         ; (-$09)
L31ab:  add     hl,bc
L31ac:  jr      nc,L31a2         ; (-$0c)
L31ae:  inc     de
L31af:  jr      L31a2            ; (-$0f)

;; REAL log10
L31b1:  ld      de,$322a
L31b4:  jr      L31b9            ; (+$03)

;; REAL log
L31b6:  ld      de,$3225
L31b9:  call    L3727
L31bc:  dec     a
L31bd:  cp      $01
L31bf:  ret     nc

L31c0:  push    de
L31c1:  call    L36d3
L31c4:  push    af
L31c5:  ld      (ix+$04),$80
L31c9:  ld      de,$3220
L31cc:  call    L36df
L31cf:  jr      nc,L31d7         ; (+$06)
L31d1:  inc     (ix+$04)
L31d4:  pop     af
L31d5:  dec     a
L31d6:  push    af
L31d7:  call    L2f87
L31da:  push    de
L31db:  ld      de,$2f82
L31de:  push    de
L31df:  call    L34a2
L31e2:  pop     de
L31e3:  ex      (sp),hl
L31e4:  call    L349a
L31e7:  pop     de
L31e8:  call    L3604
L31eb:  call    L3440 
        defb    $04
        defb    $4C, $4B, $57, $5E, $7F
        defb    $0D, $08, $9B, $13, $80
        defb    $23, $93, $38, $76, $80
        defb    $20, $3B, $AA, $38, $82

L3203:  push    de
L3204:  call    L3577
L3207:  pop     de
L3208:  ex      (sp),hl
L3209:  ld      a,h
L320a:  or      a
L320b:  jp      p,L3210
L320e:  cpl     
L320f:  inc     a
L3210:  ld      l,a
L3211:  ld      a,h
L3212:  ld      h,$00
L3214:  call    L2f9f
L3217:  ex      de,hl
L3218:  pop     hl
L3219:  call    L34a2
L321c:  pop     de
L321d:  jp      L3577

L3220:  defb $34,$f3,$04,$35,$80            ;; 0.707106781
        defb $f8,$17,$72,$31,$80            ;; 0.693147181
        defb $85,$9a,$20,$1a,$7f            ;; 0.301029996

;; RE
L322f:  ld      b,$e1
L3231:  call    L3492
L3234:  jp      nc,L2f7d
L3237:  ld      de,$32a2
L323a:  call    L36df
L323d:  jp      p,L37e8
L3240:  ld      de,$32a7
L3243:  call    L36df
L3246:  jp      m,L37e2
L3249:  ld      de,$329d
L324c:  call    L3469
L324f:  ld      a,e
L3250:  jp      p,L3255
L3253:  neg     
L3255:  push    af
L3256:  call    L3570
L3259:  call    L2f8d
L325c:  push    de
L325d:  call    L3443
L3260:  inc     bc
L3261:  call    p,$eb32
L3264:  rrca    
L3265:  ld      (hl),e
L3266:  ex      af,af'
L3267:  cp      b
L3268:  push    de
L3269:  ld      d,d
L326a:  ld      a,e
L326b:  nop     
L326c:  nop     
L326d:  nop     
L326e:  nop     
L326f:  add     a,b
L3270:  ex      (sp),hl
L3271:  call    L3443
L3274:  ld      (bc),a
L3275:  add     hl,bc
L3276:  ld      h,b
L3277:  sbc     a,$01
L3279:  ld      a,b
L327a:  ret     m

L327b:  rla     
L327c:  ld      (hl),d
L327d:  ld      sp,$cd7e
L3280:  ld      (hl),a
L3281:  dec     (hl)
L3282:  pop     de
L3283:  push    hl
L3284:  ex      de,hl
L3285:  call    L349a
L3288:  ex      de,hl
L3289:  pop     hl
L328a:  call    L3604
L328d:  ld      de,$326b
L3290:  call    L34a2
L3293:  pop     af
L3294:  scf     
L3295:  adc     a,(ix+$04)
L3298:  ld      (ix+$04),a
L329b:  scf     
L329c:  ret     

        defb    $29, $3B, $AA, $38, $81
        defb    $C7, $33, $0F, $30, $87
        defb    $F8, $17, $72, $B1, $87

;; REAL sqr
L32ac:  ld      de,$326b

;; REAL power
L32af:  ex      de,hl
L32b0:  call    L3727
L32b3:  ex      de,hl
L32b4:  jp      z,L2f7d
L32b7:  push    af
L32b8:  call    L3727
L32bb:  jr      z,L32e2          ; (+$25)
L32bd:  ld      b,a
L32be:  call    m,$3734
L32c1:  push    hl
L32c2:  call    L3324
L32c5:  pop     hl
L32c6:  jr      c,L32ed          ; (+$25)
L32c8:  ex      (sp),hl
L32c9:  pop     hl
L32ca:  jp      m,L32ea
L32cd:  push    bc
L32ce:  push    de
L32cf:  call    L31b6
L32d2:  pop     de
L32d3:  call    c,L3577
L32d6:  call    c,L322f
L32d9:  pop     bc
L32da:  ret     nc

L32db:  ld      a,b
L32dc:  or      a
L32dd:  call    m,$3731
L32e0:  scf     
L32e1:  ret     

L32e2:  pop     af
L32e3:  scf     
L32e4:  ret     p

L32e5:  call    L37e8
L32e8:  xor     a
L32e9:  ret     

L32ea:  xor     a
L32eb:  inc     a
L32ec:  ret     

L32ed:  ld      c,a
L32ee:  pop     af
L32ef:  push    bc
L32f0:  push    af
L32f1:  ld      a,c
L32f2:  scf     
L32f3:  adc     a,a
L32f4:  jr      nc,L32f3         ; (-$03)
L32f6:  ld      b,a
L32f7:  call    L2f8d
L32fa:  ex      de,hl
L32fb:  ld      a,b
L32fc:  add     a,a
L32fd:  jr      z,L3314          ; (+$15)
L32ff:  push    af
L3300:  call    L3570
L3303:  jr      nc,L331b         ; (+$16)
L3305:  pop     af
L3306:  jr      nc,L32fc         ; (-$0c)
L3308:  push    af
L3309:  ld      de,$b104
L330c:  call    L3577
L330f:  jr      nc,L331b         ; (+$0a)
L3311:  pop     af
L3312:  jr      L32fc            ; (-$18)
L3314:  pop     af
L3315:  scf     
L3316:  call    m,$35fb
L3319:  jr      L32d9            ; (-$42)
L331b:  pop     af
L331c:  pop     af
L331d:  pop     bc
L331e:  jp      m,L37e2
L3321:  jp      L37ea
L3324:  push    bc
L3325:  call    L2f88
L3328:  call    L3014
L332b:  ld      a,c
L332c:  pop     bc
L332d:  jr      nc,L3331         ; (+$02)
L332f:  jr      z,L3334          ; (+$03)
L3331:  ld      a,b
L3332:  or      a
L3333:  ret     

L3334:  ld      c,a
L3335:  ld      a,(hl)
L3336:  rra     
L3337:  sbc     a,a
L3338:  and     b
L3339:  ld      b,a
L333a:  ld      a,c
L333b:  cp      $02
L333d:  sbc     a,a
L333e:  ret     nc

L333f:  ld      a,(hl)
L3340:  cp      $27
L3342:  ret     c

L3343:  xor     a
L3344:  ret     

L3345:  ld      ($b113),a
L3348:  ret     

;; RE
L3349:  call    L3727
L334c:  call    m,$3734
L334f:  or      $01
L3351:  jr      L3354            ; (+$01)

;; REAL sin
L3353:  xor     a
L3354:  push    af
L3355:  ld      de,$33b4
L3358:  ld      b,$f0
L335a:  ld      a,($b113)
L335d:  or      a
L335e:  jr      z,L3365          ; (+$05)
L3360:  ld      de,$33b9
L3363:  ld      b,$f6
L3365:  call    L3492
L3368:  jr      nc,L33a4         ; (+$3a)
L336a:  pop     af
L336b:  call    L346a
L336e:  ret     nc

L336f:  ld      a,e
L3370:  rra     
L3371:  call    c,L3734
L3374:  ld      b,$e8
L3376:  call    L3492
L3379:  jp      nc,L37e2
L337c:  inc     (ix+$04)
L337f:  call    L3440
        defb    $06
        defb    $1B, $2D, $1A, $E6, $6E
        defb    $F8, $FB, $07, $28, $74
        defb    $01, $89, $68, $99, $79
        defb    $E1, $DF, $35, $23, $7D
        defb    $28, $E7, $5D, $A5, $80
        defb    $A2, $DA, $0F, $49, $81
L33a1:  jp      L3577
L33a4:  pop     af
L33a5:  jp      nz,L2f7d
L33a8:  ld      a,($b113)
L33ab:  cp      $01
L33ad:  ret     c

L33ae:  ld      de,$33be
L33b1:  jp      L3577
L33b4:  ld      l,(hl)
L33b5:  add     a,e
L33b6:  ld      sp,hl
L33b7:  ld      ($b67f),hl
L33ba:  ld      h,b
L33bb:  dec     bc
L33bc:  ld      (hl),$79
L33be:  inc     de
L33bf:  dec     (hl)
L33c0:  jp      m,$7b0e
L33c3:  out     ($e0),a
L33c5:  ld      l,$65
L33c7:  add     a,(hl)

;; RE
L33c8:  call    L2f8d
L33cb:  push    de
L33cc:  call    L3349
L33cf:  ex      (sp),hl
L33d0:  call    c,L3353
L33d3:  pop     de
L33d4:  jp      c,L3604
L33d7:  ret     

;; RE
L33d8:  call    L3727
L33db:  push    af
L33dc:  call    m,$3734
L33df:  ld      b,$f0
L33e1:  call    L3492
L33e4:  jr      nc,L3430         ; (+$4a)
L33e6:  dec     a
L33e7:  push    af
L33e8:  call    p,$35fb
L33eb:  call    L3440
L33ee:  dec     bc
L33ef:  rst     $38
L33f0:  pop     bc
L33f1:  inc     bc
L33f2:  rrca    
L33f3:  ld      (hl),a
L33f4:  add     a,e
L33f5:  call    m,$ebe8
L33f8:  ld      a,c
L33f9:  ld      l,a
L33fa:  jp      z,L3678
L33fd:  ld      a,e
L33fe:  push    de
L33ff:  ld      a,$b0
L3401:  or      l
L3402:  ld      a,h
L3403:  or      b
L3404:  pop     bc
L3405:  adc     a,e
L3406:  add     hl,bc
L3407:  ld      a,l
L3408:  xor     a
L3409:  ret     pe

L340a:  ld      ($7db4),a
L340d:  ld      (hl),h
L340e:  ld      l,h
L340f:  ld      h,l
L3410:  ld      h,d
L3411:  ld      a,l
L3412:  pop     de
L3413:  push    af
L3414:  scf     
L3415:  sub     d
L3416:  ld      a,(hl)
L3417:  ld      a,d
L3418:  jp      $4ccb
L341b:  ld      a,(hl)
L341c:  add     a,e
L341d:  and     a
L341e:  xor     d
L341f:  xor     d
L3420:  ld      a,a
L3421:  cp      $ff
L3423:  rst     $38
L3424:  ld      a,a
L3425:  add     a,b
L3426:  call    L3577
L3429:  pop     af
L342a:  ld      de,$339c
L342d:  call    p,$349e
L3430:  ld      a,($b113)
L3433:  or      a
L3434:  ld      de,$33c3
L3437:  call    nz,L3577
L343a:  pop     af
L343b:  call    m,$3734
L343e:  scf     
L343f:  ret     

L3440:  call    L3570
L3443:  call    L2f87
L3446:  pop     hl
L3447:  ld      b,(hl)
L3448:  inc     hl
L3449:  call    L2f90
L344c:  inc     de
L344d:  inc     de
L344e:  inc     de
L344f:  inc     de
L3450:  inc     de
L3451:  push    de
L3452:  ld      de,$b109
L3455:  dec     b
L3456:  ret     z

L3457:  push    bc
L3458:  ld      de,$b10e
L345b:  call    L3577
L345e:  pop     bc
L345f:  pop     de
L3460:  push    de
L3461:  push    bc
L3462:  call    L34a2
L3465:  pop     bc
L3466:  pop     de
L3467:  jr      L344c            ; (-$1d)
L3469:  xor     a
L346a:  push    af
L346b:  call    L3577
L346e:  pop     af
L346f:  ld      de,$326b
L3472:  call    nz,L34a2
L3475:  push    hl
L3476:  call    L2fd9
L3479:  jr      nc,L348e         ; (+$13)
L347b:  pop     de
L347c:  push    hl
L347d:  push    af
L347e:  push    de
L347f:  ld      de,$b109
L3482:  call    L2f9f
L3485:  ex      de,hl
L3486:  pop     hl
L3487:  call    L349a
L348a:  pop     af
L348b:  pop     de
L348c:  scf     
L348d:  ret     

L348e:  pop     hl
L348f:  xor     a
L3490:  inc     a
L3491:  ret     

L3492:  call    L36d3
L3495:  ret     p

L3496:  cp      b
L3497:  ret     z

L3498:  ccf     
L3499:  ret     

L349a:  ld      a,$01
L349c:  jr      L34a3            ; (+$05)

;; REe subtract
L349e:  ld      a,$80
L34a0:  jr      L34a3            ; (+$01)

;; REon
L34a2:  xor     a
L34a3:  push    hl
L34a4:  pop     ix
L34a6:  push    de
L34a7:  pop     iy
L34a9:  ld      b,(ix+$03)
L34ac:  ld      c,(iy+$03)
L34af:  or      a
L34b0:  jr      z,L34bc          ; (+$0a)
L34b2:  jp      m,L34ba
L34b5:  rrca    
L34b6:  xor     c
L34b7:  ld      c,a
L34b8:  jr      L34bc            ; (+$02)
L34ba:  xor     b
L34bb:  ld      b,a
L34bc:  ld      a,(ix+$04)
L34bf:  cp      (iy+$04)
L34c2:  jr      nc,L34d8         ; (+$14)
L34c4:  ld      d,b
L34c5:  ld      b,c
L34c6:  ld      c,d
L34c7:  or      a
L34c8:  ld      d,a
L34c9:  ld      a,(iy+$04)
L34cc:  ld      (ix+$04),a
L34cf:  jr      z,L3525          ; (+$54)
L34d1:  sub     d
L34d2:  cp      $21
L34d4:  jr      nc,L3525         ; (+$4f)
L34d6:  jr      L34e9            ; (+$11)
L34d8:  xor     a
L34d9:  sub     (iy+$04)
L34dc:  jr      z,L3537          ; (+$59)
L34de:  add     a,(ix+$04)
L34e1:  cp      $21
L34e3:  jr      nc,L3537         ; (+$52)
L34e5:  push    hl
L34e6:  pop     iy
L34e8:  ex      de,hl
L34e9:  ld      e,a
L34ea:  ld      a,b
L34eb:  xor     c
L34ec:  push    af
L34ed:  push    bc
L34ee:  ld      a,e
L34ef:  call    L3743
L34f2:  ld      a,c
L34f3:  pop     bc
L34f4:  ld      c,a
L34f5:  pop     af
L34f6:  jp      m,L353c
L34f9:  ld      a,(iy+$00)
L34fc:  add     a,l
L34fd:  ld      l,a
L34fe:  ld      a,(iy+$01)
L3501:  adc     a,h
L3502:  ld      h,a
L3503:  ld      a,(iy+$02)
L3506:  adc     a,e
L3507:  ld      e,a
L3508:  ld      a,(iy+$03)
L350b:  set     7,a
L350d:  adc     a,d
L350e:  ld      d,a
L350f:  jp      nc,L37b7
L3512:  rr      d
L3514:  rr      e
L3516:  rr      h
L3518:  rr      l
L351a:  rr      c
L351c:  inc     (ix+$04)
L351f:  jp      nz,L37b7
L3522:  jp      L37ea
L3525:  ld      a,(iy+$02)
L3528:  ld      (ix+$02),a
L352b:  ld      a,(iy+$01)
L352e:  ld      (ix+$01),a
L3531:  ld      a,(iy+$00)
L3534:  ld      (ix+$00),a
L3537:  ld      (ix+$03),b
L353a:  scf     
L353b:  ret     

L353c:  xor     a
L353d:  sub     c
L353e:  ld      c,a
L353f:  ld      a,(iy+$00)
L3542:  sbc     a,l
L3543:  ld      l,a
L3544:  ld      a,(iy+$01)
L3547:  sbc     a,h
L3548:  ld      h,a
L3549:  ld      a,(iy+$02)
L354c:  sbc     a,e
L354d:  ld      e,a
L354e:  ld      a,(iy+$03)
L3551:  set     7,a
L3553:  sbc     a,d
L3554:  ld      d,a
L3555:  jr      nc,L356d         ; (+$16)
L3557:  ld      a,b
L3558:  cpl     
L3559:  ld      b,a
L355a:  xor     a
L355b:  sub     c
L355c:  ld      c,a
L355d:  ld      a,$00
L355f:  sbc     a,l
L3560:  ld      l,a
L3561:  ld      a,$00
L3563:  sbc     a,h
L3564:  ld      h,a
L3565:  ld      a,$00
L3567:  sbc     a,e
L3568:  ld      e,a
L3569:  ld      a,$00
L356b:  sbc     a,d
L356c:  ld      d,a
L356d:  jp      L37ac
L3570:  ld      de,$b109
L3573:  call    L2f90
L3576:  ex      de,hl

;; RElication
L3577:  push    de
L3578:  pop     iy
L357a:  push    hl
L357b:  pop     ix
L357d:  ld      a,(iy+$04)
L3580:  or      a
L3581:  jr      z,L35ad          ; (+$2a)
L3583:  dec     a
L3584:  call    L36af
L3587:  jr      z,L35ad          ; (+$24)
L3589:  jr      nc,L35aa         ; (+$1f)
L358b:  push    af
L358c:  push    bc
L358d:  call    L35b0
L3590:  ld      a,c
L3591:  pop     bc
L3592:  ld      c,a
L3593:  pop     af
L3594:  bit     7,d
L3596:  jr      nz,L35a3         ; (+$0b)
L3598:  dec     a
L3599:  jr      z,L35ad          ; (+$12)
L359b:  sla     c
L359d:  adc     hl,hl
L359f:  rl      e
L35a1:  rl      d
L35a3:  ld      (ix+$04),a
L35a6:  or      a
L35a7:  jp      nz,L37b7
L35aa:  jp      L37ea
L35ad:  jp      L37e2
L35b0:  ld      hl,$0000
L35b3:  ld      e,l
L35b4:  ld      d,h
L35b5:  ld      a,(iy+$00)
L35b8:  call    L35f3
L35bb:  ld      a,(iy+$01)
L35be:  call    L35f3
L35c1:  ld      a,(iy+$02)
L35c4:  call    L35f3
L35c7:  ld      a,(iy+$03)
L35ca:  or      $80
L35cc:  ld      b,$08
L35ce:  rra     
L35cf:  ld      c,a
L35d0:  jr      nc,L35e6         ; (+$14)
L35d2:  ld      a,l
L35d3:  add     a,(ix+$00)
L35d6:  ld      l,a
L35d7:  ld      a,h
L35d8:  adc     a,(ix+$01)
L35db:  ld      h,a
L35dc:  ld      a,e
L35dd:  adc     a,(ix+$02)
L35e0:  ld      e,a
L35e1:  ld      a,d
L35e2:  adc     a,(ix+$03)
L35e5:  ld      d,a
L35e6:  rr      d
L35e8:  rr      e
L35ea:  rr      h
L35ec:  rr      l
L35ee:  rr      c
L35f0:  djnz    $35d0            ; (-$22)
L35f2:  ret     

L35f3:  or      a
L35f4:  jr      nz,L35cc         ; (-$2a)
L35f6:  ld      l,h
L35f7:  ld      h,e
L35f8:  ld      e,d
L35f9:  ld      d,a
L35fa:  ret     

L35fb:  call    L2f87
L35fe:  ex      de,hl
L35ff:  push    de
L3600:  call    L2f7d
L3603:  pop     de
L3604:  push    de
L3605:  pop     iy
L3607:  push    hl
L3608:  pop     ix
L360a:  xor     a
L360b:  sub     (iy+$04)
L360e:  jr      z,L366a          ; (+$5a)
L3610:  call    L36af
L3613:  jp      z,L37e2
L3616:  jr      nc,L3667         ; (+$4f)
L3618:  push    bc
L3619:  ld      c,a
L361a:  ld      e,(hl)
L361b:  inc     hl
L361c:  ld      d,(hl)
L361d:  inc     hl
L361e:  ld      a,(hl)
L361f:  inc     hl
L3620:  ld      h,(hl)
L3621:  ld      l,a
L3622:  ex      de,hl
L3623:  ld      b,(iy+$03)
L3626:  set     7,b
L3628:  call    L369d
L362b:  jr      c,L3633          ; (+$06)
L362d:  ld      a,c
L362e:  or      a
L362f:  jr      nz,L3639         ; (+$08)
L3631:  jr      L3666            ; (+$33)
L3633:  dec     c
L3634:  add     hl,hl
L3635:  rl      e
L3637:  rl      d
L3639:  ld      (ix+$04),c
L363c:  call    L3672
L363f:  ld      (ix+$03),c
L3642:  call    L3672
L3645:  ld      (ix+$02),c
L3648:  call    L3672
L364b:  ld      (ix+$01),c
L364e:  call    L3672
L3651:  ccf     
L3652:  call    c,L369d
L3655:  ccf     
L3656:  sbc     a,a
L3657:  ld      l,c
L3658:  ld      h,(ix+$01)
L365b:  ld      e,(ix+$02)
L365e:  ld      d,(ix+$03)
L3661:  pop     bc
L3662:  ld      c,a
L3663:  jp      L37b7
L3666:  pop     bc
L3667:  jp      L37ea
L366a:  ld      b,(ix+$03)
L366d:  call    L37ea
L3670:  xor     a
L3671:  ret     

L3672:  ld      c,$01
L3674:  jr      c,L367e          ; (+$08)
L3676:  ld      a,d
L3677:  cp      b
L3678:  call    z,L36a0
L367b:  ccf     
L367c:  jr      nc,L3691         ; (+$13)
L367e:  ld      a,l
L367f:  sub     (iy+$00)
L3682:  ld      l,a
L3683:  ld      a,h
L3684:  sbc     a,(iy+$01)
L3687:  ld      h,a
L3688:  ld      a,e
L3689:  sbc     a,(iy+$02)
L368c:  ld      e,a
L368d:  ld      a,d
L368e:  sbc     a,b
L368f:  ld      d,a
L3690:  scf     
L3691:  rl      c
L3693:  sbc     a,a
L3694:  add     hl,hl
L3695:  rl      e
L3697:  rl      d
L3699:  inc     a
L369a:  jr      nz,L3674         ; (-$28)
L369c:  ret     

L369d:  ld      a,d
L369e:  cp      b
L369f:  ret     nz

L36a0:  ld      a,e
L36a1:  cp      (iy+$02)
L36a4:  ret     nz

L36a5:  ld      a,h
L36a6:  cp      (iy+$01)
L36a9:  ret     nz

L36aa:  ld      a,l
L36ab:  cp      (iy+$00)
L36ae:  ret     

L36af:  ld      c,a
L36b0:  ld      a,(ix+$03)
L36b3:  xor     (iy+$03)
L36b6:  ld      b,a
L36b7:  ld      a,(ix+$04)
L36ba:  or      a
L36bb:  ret     z

L36bc:  add     a,c
L36bd:  ld      c,a
L36be:  rra     
L36bf:  xor     c
L36c0:  ld      a,c
L36c1:  jp      p,L36cf
L36c4:  set     7,(ix+$03)
L36c8:  sub     $7f
L36ca:  scf     
L36cb:  ret     nz

L36cc:  cp      $01
L36ce:  ret     

L36cf:  or      a
L36d0:  ret     m

L36d1:  xor     a
L36d2:  ret     

L36d3:  push    hl
L36d4:  pop     ix
L36d6:  ld      a,(ix+$04)
L36d9:  or      a
L36da:  ret     z

L36db:  sub     $80
L36dd:  scf     
L36de:  ret     

L36df:  push    hl
L36e0:  pop     ix
L36e2:  push    de
L36e3:  pop     iy
L36e5:  ld      a,(ix+$04)
L36e8:  cp      (iy+$04)
L36eb:  jr      c,L3719          ; (+$2c)
L36ed:  jr      nz,L3722         ; (+$33)
L36ef:  or      a
L36f0:  ret     z

L36f1:  ld      a,(ix+$03)
L36f4:  xor     (iy+$03)
L36f7:  jp      m,L3722
L36fa:  ld      a,(ix+$03)
L36fd:  sub     (iy+$03)
L3700:  jr      nz,L3719         ; (+$17)
L3702:  ld      a,(ix+$02)
L3705:  sub     (iy+$02)
L3708:  jr      nz,L3719         ; (+$0f)
L370a:  ld      a,(ix+$01)
L370d:  sub     (iy+$01)
L3710:  jr      nz,L3719         ; (+$07)
L3712:  ld      a,(ix+$00)
L3715:  sub     (iy+$00)
L3718:  ret     z

L3719:  sbc     a,a
L371a:  xor     (iy+$03)
L371d:  add     a,a
L371e:  sbc     a,a
L371f:  ret     c

L3720:  inc     a
L3721:  ret     

L3722:  ld      a,(ix+$03)
L3725:  jr      L371d            ; (-$0a)
L3727:  push    hl
L3728:  pop     ix
L372a:  ld      a,(ix+$04)
L372d:  or      a
L372e:  ret     z

L372f:  jr      L3722            ; (-$0f)
L3731:  push    hl
L3732:  pop     ix
L3734:  ld      a,(ix+$03)
L3737:  xor     $80
L3739:  ld      (ix+$03),a
L373c:  ret     

L373d:  cp      $21
L373f:  jr      c,L3743          ; (+$02)
L3741:  ld      a,$21
L3743:  ld      e,(hl)
L3744:  inc     hl
L3745:  ld      d,(hl)
L3746:  inc     hl
L3747:  ld      c,(hl)
L3748:  inc     hl
L3749:  ld      h,(hl)
L374a:  ld      l,c
L374b:  ex      de,hl
L374c:  set     7,d
L374e:  ld      bc,$0000
L3751:  jr      L375e            ; (+$0b)
L3753:  ld      c,a
L3754:  ld      a,b
L3755:  or      l
L3756:  ld      b,a
L3757:  ld      a,c
L3758:  ld      c,l
L3759:  ld      l,h
L375a:  ld      h,e
L375b:  ld      e,d
L375c:  ld      d,$00
L375e:  sub     $08
L3760:  jr      nc,L3753         ; (-$0f)
L3762:  add     a,$08
L3764:  ret     z

L3765:  srl     d
L3767:  rr      e
L3769:  rr      h
L376b:  rr      l
L376d:  rr      c
L376f:  dec     a
L3770:  jr      nz,L3765         ; (-$0d)
L3772:  ret     

L3773:  jr      nz,L378c         ; (+$17)
L3775:  ld      d,a
L3776:  ld      a,e
L3777:  or      h
L3778:  or      l
L3779:  or      c
L377a:  ret     z

L377b:  ld      a,d
L377c:  sub     $08
L377e:  jr      c,L379a          ; (+$1a)
L3780:  ret     z

L3781:  ld      d,e
L3782:  ld      e,h
L3783:  ld      h,l
L3784:  ld      l,c
L3785:  ld      c,$00
L3787:  inc     d
L3788:  dec     d
L3789:  jr      z,L377c          ; (-$0f)
L378b:  ret     m

L378c:  dec     a
L378d:  ret     z

L378e:  sla     c
L3790:  adc     hl,hl
L3792:  rl      e
L3794:  rl      d
L3796:  jp      p,L378c
L3799:  ret     

L379a:  xor     a
L379b:  ret     

L379c:  push    hl
L379d:  pop     ix
L379f:  ld      (ix+$04),b
L37a2:  ld      b,a
L37a3:  ld      e,(hl)
L37a4:  inc     hl
L37a5:  ld      d,(hl)
L37a6:  inc     hl
L37a7:  ld      a,(hl)
L37a8:  inc     hl
L37a9:  ld      h,(hl)
L37aa:  ld      l,a
L37ab:  ex      de,hl
L37ac:  ld      a,(ix+$04)
L37af:  dec     d
L37b0:  inc     d
L37b1:  call    p,$3773
L37b4:  ld      (ix+$04),a
L37b7:  sla     c
L37b9:  jr      nc,L37cd         ; (+$12)
L37bb:  inc     l
L37bc:  jr      nz,L37cd         ; (+$0f)
L37be:  inc     h
L37bf:  jr      nz,L37cd         ; (+$0c)
L37c1:  inc     de
L37c2:  ld      a,d
L37c3:  or      e
L37c4:  jr      nz,L37cd         ; (+$07)
L37c6:  inc     (ix+$04)
L37c9:  jr      z,L37ea          ; (+$1f)
L37cb:  ld      d,$80
L37cd:  ld      a,b
L37ce:  or      $7f
L37d0:  and     d
L37d1:  ld      (ix+$03),a
L37d4:  ld      (ix+$02),e
L37d7:  ld      (ix+$01),h
L37da:  ld      (ix+$00),l
L37dd:  push    ix
L37df:  pop     hl
L37e0:  scf     
L37e1:  ret     

L37e2:  xor     a
L37e3:  ld      (ix+$04),a
L37e6:  jr      L37dd            ; (-$0b)
L37e8:  ld      b,$00
L37ea:  push    ix
L37ec:  pop     hl
L37ed:  ld      a,b
L37ee:  or      $7f
L37f0:  ld      (ix+$03),a
L37f3:  or      $ff
L37f5:  ld      (ix+$04),a
L37f8:  ld      (hl),a
L37f9:  ld      (ix+$01),a
L37fc:  ld      (ix+$02),a
L37ff:  ret     

;; focs
L3800:  defb %11111111
        defb %11000011
        defb %11000011
        defb %11000011
        defb %11000011
        defb %11000011
        defb %11000011
        defb %11111111

        ;; character 1
        ;;
        defb %11111111
        defb %11000000
        defb %11000000
        defb %11000000
        defb %11000000
        defb %11000000
        defb %11000000
        defb %11000000

        ;; character 2
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %11111111

        ;; character 3
        ;;
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000011
        defb %11111111

        ;; character 4
        ;;
        defb %00001100
        defb %00011000
        defb %00110000
        defb %01111110
        defb %00001100
        defb %00011000
        defb %00110000
        defb %00000000

        ;; character 5
        ;;
        defb %11111111
        defb %11000011
        defb %11100111
        defb %11011011
        defb %11011011
        defb %11100111
        defb %11000011
        defb %11111111

        ;; character 6
        ;;
        defb %00000000
        defb %00000001
        defb %00000011
        defb %00000110
        defb %11001100
        defb %01111000
        defb %00110000
        defb %00000000

        ;; character 7
        ;;
        defb %00111100
        defb %01100110
        defb %11000011
        defb %11000011
        defb %11111111
        defb %00100100
        defb %11100111
        defb %00000000

        ;; character 8
        ;;
        defb %00000000
        defb %00000000
        defb %00110000
        defb %01100000
        defb %11111111
        defb %01100000
        defb %00110000
        defb %00000000

        ;; character 9
        ;;
        defb %00000000
        defb %00000000
        defb %00001100
        defb %00000110
        defb %11111111
        defb %00000110
        defb %00001100
        defb %00000000

        ;; character 10
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %11011011
        defb %01111110
        defb %00111100
        defb %00011000

        ;; character 11
        ;;
        defb %00011000
        defb %00111100
        defb %01111110
        defb %11011011
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 12
        ;;
        defb %00011000
        defb %01011010
        defb %00111100
        defb %10011001
        defb %11011011
        defb %01111110
        defb %00111100
        defb %00011000

        ;; character 13
        ;;
        defb %00000000
        defb %00000011
        defb %00110011
        defb %01100011
        defb %11111110
        defb %01100000
        defb %00110000
        defb %00000000

        ;; character 14
        ;;
        defb %00111100
        defb %01100110
        defb %11111111
        defb %11011011
        defb %11011011
        defb %11111111
        defb %01100110
        defb %00111100

        ;; character 15
        ;;
        defb %00111100
        defb %01100110
        defb %11000011
        defb %11011011
        defb %11011011
        defb %11000011
        defb %01100110
        defb %00111100

        ;; character 16
        ;;
        defb %11111111
        defb %11000011
        defb %11000011
        defb %11111111
        defb %11000011
        defb %11000011
        defb %11000011
        defb %11111111

        ;; character 17
        ;;
        defb %00111100
        defb %01111110
        defb %11011011
        defb %11011011
        defb %11011111
        defb %11000011
        defb %01100110
        defb %00111100

        ;; character 18
        ;;
        defb %00111100
        defb %01100110
        defb %11000011
        defb %11011111
        defb %11011011
        defb %11011011
        defb %01111110
        defb %00111100

        ;; character 19
        ;;
        defb %00111100
        defb %01100110
        defb %11000011
        defb %11111011
        defb %11011011
        defb %11011011
        defb %01111110
        defb %00111100

        ;; character 20
        ;;
        defb %00111100
        defb %01111110
        defb %11011011
        defb %11011011
        defb %11111011
        defb %11000011
        defb %01100110
        defb %00111100

        ;; character 21
        ;;
        defb %00000000
        defb %00000001
        defb %00110011
        defb %00011110
        defb %11001110
        defb %01111011
        defb %00110001
        defb %00000000

        ;; character 22
        ;;
        defb %01111110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %11100111

        ;; character 23
        ;;
        defb %00000011
        defb %00000011
        defb %00000011
        defb %11111111
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000000

        ;; character 24
        ;;
        defb %11111111
        defb %01100110
        defb %00111100
        defb %00011000
        defb %00011000
        defb %00111100
        defb %01100110
        defb %11111111

        ;; character 25
        ;;
        defb %00011000
        defb %00011000
        defb %00111100
        defb %00111100
        defb %00111100
        defb %00111100
        defb %00011000
        defb %00011000

        ;; character 26
        ;;
        defb %00111100
        defb %01100110
        defb %01100110
        defb %00110000
        defb %00011000
        defb %00000000
        defb %00011000
        defb %00000000

        ;; character 27
        ;;
        defb %00111100
        defb %01100110
        defb %11000011
        defb %11111111
        defb %11000011
        defb %11000011
        defb %01100110
        defb %00111100

        ;; character 28
        ;;
        defb %11111111
        defb %11011011
        defb %11011011
        defb %11011011
        defb %11111011
        defb %11000011
        defb %11000011
        defb %11111111

        ;; character 29
        ;;
        defb %11111111
        defb %11000011
        defb %11000011
        defb %11111011
        defb %11011011
        defb %11011011
        defb %11011011
        defb %11111111

        ;; character 30
        ;;
        defb %11111111
        defb %11000011
        defb %11000011
        defb %11011111
        defb %11011011
        defb %11011011
        defb %11011011
        defb %11111111

        ;; character 31
        ;;
        defb %11111111
        defb %11011011
        defb %11011011
        defb %11011011
        defb %11011111
        defb %11000011
        defb %11000011
        defb %11111111

        ;; character 32
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 33
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00000000
        defb %00011000
        defb %00000000

        ;; character 34
        ;;
        defb %01101100
        defb %01101100
        defb %01101100
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 35
        ;;
        defb %01101100
        defb %01101100
        defb %11111110
        defb %01101100
        defb %11111110
        defb %01101100
        defb %01101100
        defb %00000000

        ;; character 36
        ;;
        defb %00011000
        defb %00111110
        defb %01011000
        defb %00111100
        defb %00011010
        defb %01111100
        defb %00011000
        defb %00000000

        ;; character 37
        ;;
        defb %00000000
        defb %11000110
        defb %11001100
        defb %00011000
        defb %00110000
        defb %01100110
        defb %11000110
        defb %00000000

        ;; character 38
        ;;
        defb %00111000
        defb %01101100
        defb %00111000
        defb %01110110
        defb %11011100
        defb %11001100
        defb %01110110
        defb %00000000

        ;; character 39
        ;;
        defb %00011000
        defb %00011000
        defb %00110000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 40
        ;;
        defb %00001100
        defb %00011000
        defb %00110000
        defb %00110000
        defb %00110000
        defb %00011000
        defb %00001100
        defb %00000000

        ;; character 41
        ;;
        defb %00110000
        defb %00011000
        defb %00001100
        defb %00001100
        defb %00001100
        defb %00011000
        defb %00110000
        defb %00000000

        ;; character 42
        ;;
        defb %00000000
        defb %01100110
        defb %00111100
        defb %11111111
        defb %00111100
        defb %01100110
        defb %00000000
        defb %00000000

        ;; character 43
        ;;
        defb %00000000
        defb %00011000
        defb %00011000
        defb %01111110
        defb %00011000
        defb %00011000
        defb %00000000
        defb %00000000

        ;; character 44
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00110000

        ;; character 45
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %01111110
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 46
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00000000

        ;; character 47
        ;;
        defb %00000110
        defb %00001100
        defb %00011000
        defb %00110000
        defb %01100000
        defb %11000000
        defb %10000000
        defb %00000000

        ;; character 48
        ;;
        defb %01111100
        defb %11000110
        defb %11001110
        defb %11010110
        defb %11100110
        defb %11000110
        defb %01111100
        defb %00000000

        ;; character 49
        ;;
        defb %00011000
        defb %00111000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %01111110
        defb %00000000

        ;; character 50
        ;;
        defb %00111100
        defb %01100110
        defb %00000110
        defb %00111100
        defb %01100000
        defb %01100110
        defb %01111110
        defb %00000000

        ;; character 51
        ;;
        defb %00111100
        defb %01100110
        defb %00000110
        defb %00011100
        defb %00000110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 52
        ;;
        defb %00011100
        defb %00111100
        defb %01101100
        defb %11001100
        defb %11111110
        defb %00001100
        defb %00011110
        defb %00000000

        ;; character 53
        ;;
        defb %01111110
        defb %01100010
        defb %01100000
        defb %01111100
        defb %00000110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 54
        ;;
        defb %00111100
        defb %01100110
        defb %01100000
        defb %01111100
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 55
        ;;
        defb %01111110
        defb %01100110
        defb %00000110
        defb %00001100
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00000000

        ;; character 56
        ;;
        defb %00111100
        defb %01100110
        defb %01100110
        defb %00111100
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 57
        ;;
        defb %00111100
        defb %01100110
        defb %01100110
        defb %00111110
        defb %00000110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 58
        ;;
        defb %00000000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00000000

        ;; character 59
        ;;
        defb %00000000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00110000

        ;; character 60
        ;;
        defb %00001100
        defb %00011000
        defb %00110000
        defb %01100000
        defb %00110000
        defb %00011000
        defb %00001100
        defb %00000000

        ;; character 61
        ;;
        defb %00000000
        defb %00000000
        defb %01111110
        defb %00000000
        defb %00000000
        defb %01111110
        defb %00000000
        defb %00000000

        ;; character 62
        ;;
        defb %01100000
        defb %00110000
        defb %00011000
        defb %00001100
        defb %00011000
        defb %00110000
        defb %01100000
        defb %00000000

        ;; character 63
        ;;
        defb %00111100
        defb %01100110
        defb %01100110
        defb %00001100
        defb %00011000
        defb %00000000
        defb %00011000
        defb %00000000

        ;; character 64
        ;;
        defb %01111100
        defb %11000110
        defb %11011110
        defb %11011110
        defb %11011110
        defb %11000000
        defb %01111100
        defb %00000000

        ;; character 65
        ;;
        defb %00011000
        defb %00111100
        defb %01100110
        defb %01100110
        defb %01111110
        defb %01100110
        defb %01100110
        defb %00000000

        ;; character 66
        ;;
        defb %11111100
        defb %01100110
        defb %01100110
        defb %01111100
        defb %01100110
        defb %01100110
        defb %11111100
        defb %00000000

        ;; character 67
        ;;
        defb %00111100
        defb %01100110
        defb %11000000
        defb %11000000
        defb %11000000
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 68
        ;;
        defb %11111000
        defb %01101100
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01101100
        defb %11111000
        defb %00000000

        ;; character 69
        ;;
        defb %11111110
        defb %01100010
        defb %01101000
        defb %01111000
        defb %01101000
        defb %01100010
        defb %11111110
        defb %00000000

        ;; character 70
        ;;
        defb %11111110
        defb %01100010
        defb %01101000
        defb %01111000
        defb %01101000
        defb %01100000
        defb %11110000
        defb %00000000

        ;; character 71
        ;;
        defb %00111100
        defb %01100110
        defb %11000000
        defb %11000000
        defb %11001110
        defb %01100110
        defb %00111110
        defb %00000000

        ;; character 72
        ;;
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01111110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00000000

        ;; character 73
        ;;
        defb %01111110
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %01111110
        defb %00000000

        ;; character 74
        ;;
        defb %00011110
        defb %00001100
        defb %00001100
        defb %00001100
        defb %11001100
        defb %11001100
        defb %01111000
        defb %00000000

        ;; character 75
        ;;
        defb %11100110
        defb %01100110
        defb %01101100
        defb %01111000
        defb %01101100
        defb %01100110
        defb %11100110
        defb %00000000

        ;; character 76
        ;;
        defb %11110000
        defb %01100000
        defb %01100000
        defb %01100000
        defb %01100010
        defb %01100110
        defb %11111110
        defb %00000000

        ;; character 77
        ;;
        defb %11000110
        defb %11101110
        defb %11111110
        defb %11111110
        defb %11010110
        defb %11000110
        defb %11000110
        defb %00000000

        ;; character 78
        ;;
        defb %11000110
        defb %11100110
        defb %11110110
        defb %11011110
        defb %11001110
        defb %11000110
        defb %11000110
        defb %00000000

        ;; character 79
        ;;
        defb %00111000
        defb %01101100
        defb %11000110
        defb %11000110
        defb %11000110
        defb %01101100
        defb %00111000
        defb %00000000

        ;; character 80
        ;;
        defb %11111100
        defb %01100110
        defb %01100110
        defb %01111100
        defb %01100000
        defb %01100000
        defb %11110000
        defb %00000000

        ;; character 81
        ;;
        defb %00111000
        defb %01101100
        defb %11000110
        defb %11000110
        defb %11011010
        defb %11001100
        defb %01110110
        defb %00000000

        ;; character 82
        ;;
        defb %11111100
        defb %01100110
        defb %01100110
        defb %01111100
        defb %01101100
        defb %01100110
        defb %11100110
        defb %00000000

        ;; character 83
        ;;
        defb %00111100
        defb %01100110
        defb %01100000
        defb %00111100
        defb %00000110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 84
        ;;
        defb %01111110
        defb %01011010
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00111100
        defb %00000000

        ;; character 85
        ;;
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 86
        ;;
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00011000
        defb %00000000

        ;; character 87
        ;;
        defb %11000110
        defb %11000110
        defb %11000110
        defb %11010110
        defb %11111110
        defb %11101110
        defb %11000110
        defb %00000000

        ;; character 88
        ;;
        defb %11000110
        defb %01101100
        defb %00111000
        defb %00111000
        defb %01101100
        defb %11000110
        defb %11000110
        defb %00000000

        ;; character 89
        ;;
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00011000
        defb %00011000
        defb %00111100
        defb %00000000

        ;; character 90
        ;;
        defb %11111110
        defb %11000110
        defb %10001100
        defb %00011000
        defb %00110010
        defb %01100110
        defb %11111110
        defb %00000000

        ;; character 91
        ;;
        defb %00111100
        defb %00110000
        defb %00110000
        defb %00110000
        defb %00110000
        defb %00110000
        defb %00111100
        defb %00000000

        ;; character 92
        ;;
        defb %11000000
        defb %01100000
        defb %00110000
        defb %00011000
        defb %00001100
        defb %00000110
        defb %00000010
        defb %00000000

        ;; character 93
        ;;
        defb %00111100
        defb %00001100
        defb %00001100
        defb %00001100
        defb %00001100
        defb %00001100
        defb %00111100
        defb %00000000

        ;; character 94
        ;;
        defb %00011000
        defb %00111100
        defb %01111110
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00000000

        ;; character 95
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11111111

        ;; character 96
        ;;
        defb %00110000
        defb %00011000
        defb %00001100
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 97
        ;;
        defb %00000000
        defb %00000000
        defb %01111000
        defb %00001100
        defb %01111100
        defb %11001100
        defb %01110110
        defb %00000000

        ;; character 98
        ;;
        defb %11100000
        defb %01100000
        defb %01111100
        defb %01100110
        defb %01100110
        defb %01100110
        defb %11011100
        defb %00000000

        ;; character 99
        ;;
        defb %00000000
        defb %00000000
        defb %00111100
        defb %01100110
        defb %01100000
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 100
        ;;
        defb %00011100
        defb %00001100
        defb %01111100
        defb %11001100
        defb %11001100
        defb %11001100
        defb %01110110
        defb %00000000

        ;; character 101
        ;;
        defb %00000000
        defb %00000000
        defb %00111100
        defb %01100110
        defb %01111110
        defb %01100000
        defb %00111100
        defb %00000000

        ;; character 102
        ;;
        defb %00011100
        defb %00110110
        defb %00110000
        defb %01111000
        defb %00110000
        defb %00110000
        defb %01111000
        defb %00000000

        ;; character 103
        ;;
        defb %00000000
        defb %00000000
        defb %00111110
        defb %01100110
        defb %01100110
        defb %00111110
        defb %00000110
        defb %01111100

        ;; character 104
        ;;
        defb %11100000
        defb %01100000
        defb %01101100
        defb %01110110
        defb %01100110
        defb %01100110
        defb %11100110
        defb %00000000

        ;; character 105
        ;;
        defb %00011000
        defb %00000000
        defb %00111000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00111100
        defb %00000000

        ;; character 106
        ;;
        defb %00000110
        defb %00000000
        defb %00001110
        defb %00000110
        defb %00000110
        defb %01100110
        defb %01100110
        defb %00111100

        ;; character 107
        ;;
        defb %11100000
        defb %01100000
        defb %01100110
        defb %01101100
        defb %01111000
        defb %01101100
        defb %11100110
        defb %00000000

        ;; character 108
        ;;
        defb %00111000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00111100
        defb %00000000

        ;; character 109
        ;;
        defb %00000000
        defb %00000000
        defb %01101100
        defb %11111110
        defb %11010110
        defb %11010110
        defb %11000110
        defb %00000000

        ;; character 110
        ;;
        defb %00000000
        defb %00000000
        defb %11011100
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00000000

        ;; character 111
        ;;
        defb %00000000
        defb %00000000
        defb %00111100
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 112
        ;;
        defb %00000000
        defb %00000000
        defb %11011100
        defb %01100110
        defb %01100110
        defb %01111100
        defb %01100000
        defb %11110000

        ;; character 113
        ;;
        defb %00000000
        defb %00000000
        defb %01110110
        defb %11001100
        defb %11001100
        defb %01111100
        defb %00001100
        defb %00011110

        ;; character 114
        ;;
        defb %00000000
        defb %00000000
        defb %11011100
        defb %01110110
        defb %01100000
        defb %01100000
        defb %11110000
        defb %00000000

        ;; character 115
        ;;
        defb %00000000
        defb %00000000
        defb %00111100
        defb %01100000
        defb %00111100
        defb %00000110
        defb %01111100
        defb %00000000

        ;; character 116
        ;;
        defb %00110000
        defb %00110000
        defb %01111100
        defb %00110000
        defb %00110000
        defb %00110110
        defb %00011100
        defb %00000000

        ;; character 117
        ;;
        defb %00000000
        defb %00000000
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00111110
        defb %00000000

        ;; character 118
        ;;
        defb %00000000
        defb %00000000
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00011000
        defb %00000000

        ;; character 119
        ;;
        defb %00000000
        defb %00000000
        defb %11000110
        defb %11010110
        defb %11010110
        defb %11111110
        defb %01101100
        defb %00000000

        ;; character 120
        ;;
        defb %00000000
        defb %00000000
        defb %11000110
        defb %01101100
        defb %00111000
        defb %01101100
        defb %11000110
        defb %00000000

        ;; character 121
        ;;
        defb %00000000
        defb %00000000
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00111110
        defb %00000110
        defb %01111100

        ;; character 122
        ;;
        defb %00000000
        defb %00000000
        defb %01111110
        defb %01001100
        defb %00011000
        defb %00110010
        defb %01111110
        defb %00000000

        ;; character 123
        ;;
        defb %00001110
        defb %00011000
        defb %00011000
        defb %01110000
        defb %00011000
        defb %00011000
        defb %00001110
        defb %00000000

        ;; character 124
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00000000

        ;; character 125
        ;;
        defb %01110000
        defb %00011000
        defb %00011000
        defb %00001110
        defb %00011000
        defb %00011000
        defb %01110000
        defb %00000000

        ;; character 126
        ;;
        defb %01110110
        defb %11011100
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 127
        ;;
        defb %11001100
        defb %00110011
        defb %11001100
        defb %00110011
        defb %11001100
        defb %00110011
        defb %11001100
        defb %00110011

        ;; character 128
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 129
        ;;
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 130
        ;;
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 131
        ;;
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 132
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000

        ;; character 133
        ;;
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000

        ;; character 134
        ;;
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000

        ;; character 135
        ;;
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000

        ;; character 136
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111

        ;; character 137
        ;;
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111

        ;; character 138
        ;;
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111

        ;; character 139
        ;;
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111

        ;; character 140
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111

        ;; character 141
        ;;
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11110000
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111

        ;; character 142
        ;;
        defb %00001111
        defb %00001111
        defb %00001111
        defb %00001111
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111

        ;; character 143
        ;;
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111
        defb %11111111

        ;; character 144
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 145
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 146
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00011111
        defb %00011111
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 147
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011111
        defb %00001111
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 148
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 149
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 150
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00001111
        defb %00011111
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 151
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011111
        defb %00011111
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 152
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11111000
        defb %11111000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 153
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %11111000
        defb %11110000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 154
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11111111
        defb %11111111
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 155
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %11111111
        defb %11111111
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 156
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11110000
        defb %11111000
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 157
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %11111000
        defb %11111000
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 158
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11111111
        defb %11111111
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 159
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %11111111
        defb %11111111
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 160
        ;;
        defb %00010000
        defb %00111000
        defb %01101100
        defb %11000110
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 161
        ;;
        defb %00001100
        defb %00011000
        defb %00110000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 162
        ;;
        defb %01100110
        defb %01100110
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 163
        ;;
        defb %00111100
        defb %01100110
        defb %01100000
        defb %11111000
        defb %01100000
        defb %01100110
        defb %11111110
        defb %00000000

        ;; character 164
        ;;
        defb %00111000
        defb %01000100
        defb %10111010
        defb %10100010
        defb %10111010
        defb %01000100
        defb %00111000
        defb %00000000

        ;; character 165
        ;;
        defb %01111110
        defb %11110100
        defb %11110100
        defb %01110100
        defb %00110100
        defb %00110100
        defb %00110100
        defb %00000000

        ;; character 166
        ;;
        defb %00011110
        defb %00110000
        defb %00111000
        defb %01101100
        defb %00111000
        defb %00011000
        defb %11110000
        defb %00000000

        ;; character 167
        ;;
        defb %00011000
        defb %00011000
        defb %00001100
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 168
        ;;
        defb %01000000
        defb %11000000
        defb %01000100
        defb %01001100
        defb %01010100
        defb %00011110
        defb %00000100
        defb %00000000

        ;; character 169
        ;;
        defb %01000000
        defb %11000000
        defb %01001100
        defb %01010010
        defb %01000100
        defb %00001000
        defb %00011110
        defb %00000000

        ;; character 170
        ;;
        defb %11100000
        defb %00010000
        defb %01100010
        defb %00010110
        defb %11101010
        defb %00001111
        defb %00000010
        defb %00000000

        ;; character 171
        ;;
        defb %00000000
        defb %00011000
        defb %00011000
        defb %01111110
        defb %00011000
        defb %00011000
        defb %01111110
        defb %00000000

        ;; character 172
        ;;
        defb %00011000
        defb %00011000
        defb %00000000
        defb %01111110
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00000000

        ;; character 173
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %01111110
        defb %00000110
        defb %00000110
        defb %00000000
        defb %00000000

        ;; character 174
        ;;
        defb %00011000
        defb %00000000
        defb %00011000
        defb %00110000
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 175
        ;;
        defb %00011000
        defb %00000000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00000000

        ;; character 176
        ;;
        defb %00000000
        defb %00000000
        defb %01110011
        defb %11011110
        defb %11001100
        defb %11011110
        defb %01110011
        defb %00000000

        ;; character 177
        ;;
        defb %01111100
        defb %11000110
        defb %11000110
        defb %11111100
        defb %11000110
        defb %11000110
        defb %11111000
        defb %11000000

        ;; character 178
        ;;
        defb %00000000
        defb %01100110
        defb %01100110
        defb %00111100
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 179
        ;;
        defb %00111100
        defb %01100000
        defb %01100000
        defb %00111100
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 180
        ;;
        defb %00000000
        defb %00000000
        defb %00011110
        defb %00110000
        defb %01111100
        defb %00110000
        defb %00011110
        defb %00000000

        ;; character 181
        ;;
        defb %00111000
        defb %01101100
        defb %11000110
        defb %11111110
        defb %11000110
        defb %01101100
        defb %00111000
        defb %00000000

        ;; character 182
        ;;
        defb %00000000
        defb %11000000
        defb %01100000
        defb %00110000
        defb %00111000
        defb %01101100
        defb %11000110
        defb %00000000

        ;; character 183
        ;;
        defb %00000000
        defb %00000000
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01111100
        defb %01100000
        defb %01100000

        ;; character 184
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11111110
        defb %01101100
        defb %01101100
        defb %01101100
        defb %00000000

        ;; character 185
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %01111110
        defb %11011000
        defb %11011000
        defb %01110000
        defb %00000000

        ;; character 186
        ;;
        defb %00000011
        defb %00000110
        defb %00001100
        defb %00111100
        defb %01100110
        defb %00111100
        defb %01100000
        defb %11000000

        ;; character 187
        ;;
        defb %00000011
        defb %00000110
        defb %00001100
        defb %01100110
        defb %01100110
        defb %00111100
        defb %01100000
        defb %11000000

        ;; character 188
        ;;
        defb %00000000
        defb %11100110
        defb %00111100
        defb %00011000
        defb %00111000
        defb %01101100
        defb %11000111
        defb %00000000

        ;; character 189
        ;;
        defb %00000000
        defb %00000000
        defb %01100110
        defb %11000011
        defb %11011011
        defb %11011011
        defb %01111110
        defb %00000000

        ;; character 190
        ;;
        defb %11111110
        defb %11000110
        defb %01100000
        defb %00110000
        defb %01100000
        defb %11000110
        defb %11111110
        defb %00000000

        ;; character 191
        ;;
        defb %00000000
        defb %01111100
        defb %11000110
        defb %11000110
        defb %11000110
        defb %01101100
        defb %11101110
        defb %00000000

        ;; character 192
        ;;
        defb %00011000
        defb %00110000
        defb %01100000
        defb %11000000
        defb %10000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 193
        ;;
        defb %00011000
        defb %00001100
        defb %00000110
        defb %00000011
        defb %00000001
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 194
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000001
        defb %00000011
        defb %00000110
        defb %00001100
        defb %00011000

        ;; character 195
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %10000000
        defb %11000000
        defb %01100000
        defb %00110000
        defb %00011000

        ;; character 196
        ;;
        defb %00011000
        defb %00111100
        defb %01100110
        defb %11000011
        defb %10000001
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 197
        ;;
        defb %00011000
        defb %00001100
        defb %00000110
        defb %00000011
        defb %00000011
        defb %00000110
        defb %00001100
        defb %00011000

        ;; character 198
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %10000001
        defb %11000011
        defb %01100110
        defb %00111100
        defb %00011000

        ;; character 199
        ;;
        defb %00011000
        defb %00110000
        defb %01100000
        defb %11000000
        defb %11000000
        defb %01100000
        defb %00110000
        defb %00011000

        ;; character 200
        ;;
        defb %00011000
        defb %00110000
        defb %01100000
        defb %11000001
        defb %10000011
        defb %00000110
        defb %00001100
        defb %00011000

        ;; character 201
        ;;
        defb %00011000
        defb %00001100
        defb %00000110
        defb %10000011
        defb %11000001
        defb %01100000
        defb %00110000
        defb %00011000

        ;; character 202
        ;;
        defb %00011000
        defb %00111100
        defb %01100110
        defb %11000011
        defb %11000011
        defb %01100110
        defb %00111100
        defb %00011000

        ;; character 203
        ;;
        defb %11000011
        defb %11100111
        defb %01111110
        defb %00111100
        defb %00111100
        defb %01111110
        defb %11100111
        defb %11000011

        ;; character 204
        ;;
        defb %00000011
        defb %00000111
        defb %00001110
        defb %00011100
        defb %00111000
        defb %01110000
        defb %11100000
        defb %11000000

        ;; character 205
        ;;
        defb %11000000
        defb %11100000
        defb %01110000
        defb %00111000
        defb %00011100
        defb %00001110
        defb %00000111
        defb %00000011

        ;; character 206
        ;;
        defb %11001100
        defb %11001100
        defb %00110011
        defb %00110011
        defb %11001100
        defb %11001100
        defb %00110011
        defb %00110011

        ;; character 207
        ;;
        defb %10101010
        defb %01010101
        defb %10101010
        defb %01010101
        defb %10101010
        defb %01010101
        defb %10101010
        defb %01010101

        ;; character 208
        ;;
        defb %11111111
        defb %11111111
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 209
        ;;
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000011
        defb %00000011

        ;; character 210
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %11111111
        defb %11111111

        ;; character 211
        ;;
        defb %11000000
        defb %11000000
        defb %11000000
        defb %11000000
        defb %11000000
        defb %11000000
        defb %11000000
        defb %11000000

        ;; character 212
        ;;
        defb %11111111
        defb %11111110
        defb %11111100
        defb %11111000
        defb %11110000
        defb %11100000
        defb %11000000
        defb %10000000

        ;; character 213
        ;;
        defb %11111111
        defb %01111111
        defb %00111111
        defb %00011111
        defb %00001111
        defb %00000111
        defb %00000011
        defb %00000001

        ;; character 214
        ;;
        defb %00000001
        defb %00000011
        defb %00000111
        defb %00001111
        defb %00011111
        defb %00111111
        defb %01111111
        defb %11111111

        ;; character 215
        ;;
        defb %10000000
        defb %11000000
        defb %11100000
        defb %11110000
        defb %11111000
        defb %11111100
        defb %11111110
        defb %11111111

        ;; character 216
        ;;
        defb %10101010
        defb %01010101
        defb %10101010
        defb %01010101
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000

        ;; character 217
        ;;
        defb %00001010
        defb %00000101
        defb %00001010
        defb %00000101
        defb %00001010
        defb %00000101
        defb %00001010
        defb %00000101

        ;; character 218
        ;;
        defb %00000000
        defb %00000000
        defb %00000000
        defb %00000000
        defb %10101010
        defb %01010101
        defb %10101010
        defb %01010101

        ;; character 219
        ;;
        defb %10100000
        defb %01010000
        defb %10100000
        defb %01010000
        defb %10100000
        defb %01010000
        defb %10100000
        defb %01010000

        ;; character 220
        ;;
        defb %10101010
        defb %01010100
        defb %10101000
        defb %01010000
        defb %10100000
        defb %01000000
        defb %10000000
        defb %00000000

        ;; character 221
        ;;
        defb %10101010
        defb %01010101
        defb %00101010
        defb %00010101
        defb %00001010
        defb %00000101
        defb %00000010
        defb %00000001

        ;; character 222
        ;;
        defb %00000001
        defb %00000010
        defb %00000101
        defb %00001010
        defb %00010101
        defb %00101010
        defb %01010101
        defb %10101010

        ;; character 223
        ;;
        defb %00000000
        defb %10000000
        defb %01000000
        defb %10100000
        defb %01010000
        defb %10101000
        defb %01010100
        defb %10101010

        ;; character 224
        ;;
        defb %01111110
        defb %11111111
        defb %10011001
        defb %11111111
        defb %10111101
        defb %11000011
        defb %11111111
        defb %01111110

        ;; character 225
        ;;
        defb %01111110
        defb %11111111
        defb %10011001
        defb %11111111
        defb %11000011
        defb %10111101
        defb %11111111
        defb %01111110

        ;; character 226
        ;;
        defb %00111000
        defb %00111000
        defb %11111110
        defb %11111110
        defb %11111110
        defb %00010000
        defb %00111000
        defb %00000000

        ;; character 227
        ;;
        defb %00010000
        defb %00111000
        defb %01111100
        defb %11111110
        defb %01111100
        defb %00111000
        defb %00010000
        defb %00000000

        ;; character 228
        ;;
        defb %01101100
        defb %11111110
        defb %11111110
        defb %11111110
        defb %01111100
        defb %00111000
        defb %00010000
        defb %00000000

        ;; character 229
        ;;
        defb %00010000
        defb %00111000
        defb %01111100
        defb %11111110
        defb %11111110
        defb %00010000
        defb %00111000
        defb %00000000

        ;; character 230
        ;;
        defb %00000000
        defb %00111100
        defb %01100110
        defb %11000011
        defb %11000011
        defb %01100110
        defb %00111100
        defb %00000000

        ;; character 231
        ;;
        defb %00000000
        defb %00111100
        defb %01111110
        defb %11111111
        defb %11111111
        defb %01111110
        defb %00111100
        defb %00000000

        ;; character 232
        ;;
        defb %00000000
        defb %01111110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01100110
        defb %01111110
        defb %00000000

        ;; character 233
        ;;
        defb %00000000
        defb %01111110
        defb %01111110
        defb %01111110
        defb %01111110
        defb %01111110
        defb %01111110
        defb %00000000

        ;; character 234
        ;;
        defb %00001111
        defb %00000111
        defb %00001101
        defb %01111000
        defb %11001100
        defb %11001100
        defb %11001100
        defb %01111000

        ;; character 235
        ;;
        defb %00111100
        defb %01100110
        defb %01100110
        defb %01100110
        defb %00111100
        defb %00011000
        defb %01111110
        defb %00011000

        ;; character 236
        ;;
        defb %00001100
        defb %00001100
        defb %00001100
        defb %00001100
        defb %00001100
        defb %00111100
        defb %01111100
        defb %00111000

        ;; character 237
        ;;
        defb %00011000
        defb %00011100
        defb %00011110
        defb %00011011
        defb %00011000
        defb %01111000
        defb %11111000
        defb %01110000

        ;; character 238
        ;;
        defb %10011001
        defb %01011010
        defb %00100100
        defb %11000011
        defb %11000011
        defb %00100100
        defb %01011010
        defb %10011001

        ;; character 239
        ;;
        defb %00010000
        defb %00111000
        defb %00111000
        defb %00111000
        defb %00111000
        defb %00111000
        defb %01111100
        defb %11010110

        ;; character 240
        ;;
        defb %00011000
        defb %00111100
        defb %01111110
        defb %11111111
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000

        ;; character 241
        ;;
        defb %00011000
        defb %00011000
        defb %00011000
        defb %00011000
        defb %11111111
        defb %01111110
        defb %00111100
        defb %00011000

        ;; character 242
        ;;
        defb %00010000
        defb %00110000
        defb %01110000
        defb %11111111
        defb %11111111
        defb %01110000
        defb %00110000
        defb %00010000

        ;; character 243
        ;;
        defb %00001000
        defb %00001100
        defb %00001110
        defb %11111111
        defb %11111111
        defb %00001110
        defb %00001100
        defb %00001000

        ;; character 244
        ;;
        defb %00000000
        defb %00000000
        defb %00011000
        defb %00111100
        defb %01111110
        defb %11111111
        defb %11111111
        defb %00000000

        ;; character 245
        ;;
        defb %00000000
        defb %00000000
        defb %11111111
        defb %11111111
        defb %01111110
        defb %00111100
        defb %00011000
        defb %00000000

        ;; character 246
        ;;
        defb %10000000
        defb %11100000
        defb %11111000
        defb %11111110
        defb %11111000
        defb %11100000
        defb %10000000
        defb %00000000

        ;; character 247
        ;;
        defb %00000010
        defb %00001110
        defb %00111110
        defb %11111110
        defb %00111110
        defb %00001110
        defb %00000010
        defb %00000000

        ;; character 248
        ;;
        defb %00111000
        defb %00111000
        defb %10010010
        defb %01111100
        defb %00010000
        defb %00101000
        defb %00101000
        defb %00101000

        ;; character 249
        ;;
        defb %00111000
        defb %00111000
        defb %00010000
        defb %11111110
        defb %00010000
        defb %00101000
        defb %01000100
        defb %10000010

        ;; character 250
        ;;
        defb %00111000
        defb %00111000
        defb %00010010
        defb %01111100
        defb %10010000
        defb %00101000
        defb %00100100
        defb %00100010

        ;; character 251
        ;;
        defb %00111000
        defb %00111000
        defb %10010000
        defb %01111100
        defb %00010010
        defb %00101000
        defb %01001000
        defb %10001000

        ;; character 252
        ;;
        defb %00000000
        defb %00111100
        defb %00011000
        defb %00111100
        defb %00111100
        defb %00111100
        defb %00011000
        defb %00000000

        ;; character 253
        ;;
        defb %00111100
        defb %11111111
        defb %11111111
        defb %00011000
        defb %00001100
        defb %00011000
        defb %00110000
        defb %00011000

        ;; character 254
        ;;
        defb %00011000
        defb %00111100
        defb %01111110
        defb %00011000
        defb %00011000
        defb %01111110
        defb %00111100
        defb %00011000

        ;; character 255
        ;;
        defb %00000000
        defb %00100100
        defb %01100110
        defb %11111111
        defb %01100110
        defb %00100100
        defb %00000000
        defb %00000000
