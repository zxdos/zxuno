; playstc.inc - play Sound Tracker .STC music file on AY-3-891x sound chip.
;
; Contributor of a binary file:
;   2016 Michal B. (a.k.a. Yerzmyey)
;
; Reverse-engineer:
;   2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; This is free and unencumbered software released into the public domain.
; For more information, please refer to <http://unlicense.org>.
;
; SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
;
; SPDX-FileContributor: 2016 Michal B. (a.k.a. Yerzmyey) (binary file)
;
; SPDX-License-Identifier: Unlicense

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

        module  PlaySTC

        include filestc.def
        include ay.def

 if PLAYSTC_USER_DEFINED_FILE != 1

; Clear all values for better compression of the final compiled binary file

STCDelay:               equ     0
STCDelayCtr:            equ     0
STCSamplesCnt:          equ     0
STCPositionsCnt:        equ     0
STCHeader:              equ     0
STCPositions:           equ     0 - ST_Positions.rPositions
STCOrnaments:           equ     0
STCPatterns:            equ     0
STCSamples:             equ     0
STCChannelA:            equ     0
STCChannelB:            equ     0
STCChannelC:            equ     0

; internal values
_STCOrnamentData:       equ     0
_STCRepeatLen:          equ     0

 else   ; PLAYSTC_USER_DEFINED_FILE == 1

; internal values
_STCOrnamentData:       equ     STCOrnaments + ST_Ornament.rData
_STCRepeatLen:          equ     -1

 endif  ; PLAYSTC_USER_DEFINED_FILE == 1

; Constants

NOTE_FREQ = 55  ; A note (440 Hz down 3 octaves)

 ; Here "numerator" is 1000 * 2 ^ (halftone / 12)
 macro _PutPeriod numerator, octave
        dw      ((((PLAYSTC_AY_FREQUENCY / 16 * numerator + 1000 / 2) / 1000 + NOTE_FREQ / 2) / NOTE_FREQ) >> octave) - 1
 endm

NotePeriods:
i = 0
 while i < 8
; Original, but hardcoded and inaccurate:
;       dw      3832>>i, 3600>>i, 3424>>i, 3200>>i, 3032>>i, 2856>>i, 2696>>i, 2544>>i, 2400>>i, 2272>>i, 2136>>i, 2016>>i
;       _PutPeriod 2000, i      ; A
        _PutPeriod 1888, i      ; A#
        _PutPeriod 1782, i      ; B
        _PutPeriod 1682, i      ; C
        _PutPeriod 1587, i      ; C#
        _PutPeriod 1498, i      ; D
        _PutPeriod 1414, i      ; D#
        _PutPeriod 1335, i      ; E
        _PutPeriod 1260, i      ; F
        _PutPeriod 1189, i      ; F#
        _PutPeriod 1122, i      ; G
        _PutPeriod 1059, i      ; G#
        _PutPeriod 1000, i      ; A
;       _PutPeriod 944, i       ; A#
;       _PutPeriod 891, i       ; B

i = i + 1
 endw

; Variables

p_rPositions:   dw      STCPositions + ST_Positions.rPositions
p_Ornaments:    dw      STCOrnaments
p_Patterns:     dw      STCPatterns
p_Samples:      dw      STCSamples
b_Delay:        db      STCDelay
b_DelayCtr:     db      1       ; 1 = last tick
b_PositionsCnt: db      STCPositionsCnt
p_ChannelA:     dw      STCChannelA
p_ChannelB:     dw      STCChannelB
p_ChannelC:     dw      STCChannelC
b_EmptyChannel: db      $FF     ; $FF = pattern end mark

        struct  _ST_r0
bSampleFlag     db      0       ; 0=ornament, 1=envelope, 2=?
bNoteDelay      db      0
        ends

        struct  _ST_r1
bSamplePos      db      0
bNote           db      0
bDelayCtr       db      0
pSampleData     dw      0
pOrnamentData   dw      _STCOrnamentData
bRepeatLen      db      _STCRepeatLen   ; =-1 if no loop
        ends

        struct  _ST_Chn
r0              _ST_r0
r1              _ST_r1
        ends

_PlayState: equ $
r_ChnA:         _ST_Chn
r_ChnB:         _ST_Chn
r_ChnC:         _ST_Chn
b_CurPos:       db      0       ; 0-31
; AY-3-891x registers
w_AYPitchA:     dw      0       ; R0: Channel A fine pitch (0-255), R1: Channel A coarse pitch (0-15) - 0-4095
w_AYPitchB:     dw      0       ; R2: Channel B fine pitch (0-255), R3: Channel B coarse pitch (0-15) - 0-4095
w_AYPitchC:     dw      0       ; R4: Channel C fine pitch (0-255), R5: Channel C coarse pitch (0-15) - 0-4095
b_AYNoisePitch: db      0       ; R6: Noise pitch (0-31)
b_AYMixer:      db      0       ; R7: Mixer [ - - N N N T T T ]
b_AYVolumeA:    db      0       ; R8: Channel A volume (0-15) and mode flag (bit 4)
b_AYVolumeB:    db      0       ; R9: Channel B volume (0-15) and mode flag (bit 4)
b_AYVolumeC:    db      0       ; R10: Channel C volume (0-15) and mode flag (bit 4)
w_AYEnvPeriod:  dw      0       ; R11: Envelope fine duration (0-255), R12: Envelope coarse duration (0-255)
b_AYEnvShape:   db      0       ; R13: Envelope shape (0-15)
_PlayStateLen: equ $ - _PlayState

;-----------------------------------------------------------------------------
; Subroutine
; In: HL = pointer to STC file data
Init:
        di                      ; HL = Header
        ld      (p_Header), hl
        ld      a, (hl)         ; A  = Header->bDelay
        ld      (b_Delay), a
        inc     hl              ; HL = & Header->wPositionsOff
        call    ReadPtr         ; HL = & Header->wOrnamentsOff
                                ; DE = Positions
        ld      a, (de)         ; A  = Positions->bCount
        inc     de              ; DE = & Positions->rPositions
        inc     a               ; A  = Positions->bCount + 1
        ld      (b_PositionsCnt), a
        ld      (p_rPositions), de
        call    ReadPtr         ; HL = & Header->wPatternsOff
                                ; DE = Ornaments
        ld      (p_Ornaments), de
        push    de              ; push Ornaments
        call    ReadPtr         ; HL = & Header->sIdentifier
                                ; DE = Patterns
        ld      (p_Patterns), de
        ld      hl, ST_Header.rSamples
        call    GetDataPtr
        ex      de, hl          ; HL = & Header->rSamples
                                ; DE = Patterns
        ld      (p_Samples), hl
        ld      hl, b_EmptyChannel
        ld      (p_ChannelA), hl
        ld      hl, _PlayState
        ld      de, _PlayState + 1
        ld      bc, _PlayStateLen - 1   ; B  = 0
        ld      (hl), b
        ldir                    ; clear variables in _PlayState area
        pop     hl              ; HL = Ornaments
        ld      bc, ST_Ornament
        xor     a               ; A  = 0
        call    FindItem        ; HL = & Ornaments[.bNumber==0].bNumber
        dec     a               ; A  = -1
        ld      (r_ChnA.r1.bRepeatLen), a
        ld      (r_ChnB.r1.bRepeatLen), a
        ld      (r_ChnC.r1.bRepeatLen), a
        ld      a, 1            ; 1 = last tick
        ld      (b_DelayCtr), a
        inc     hl              ; HL = & Ornaments[.bNumber==0].rData
        ld      (r_ChnA.r1.pOrnamentData), hl
        ld      (r_ChnB.r1.pOrnamentData), hl
        ld      (r_ChnC.r1.pOrnamentData), hl
        call    WriteToAY       ; Reset AY
        ei
        ret

;-----------------------------------------------------------------------------
; Subroutine
; In:  A  = number
;      HL = pointer to a byte
;      BC = pointer's increment
; Out: HL = found pointer
FindItem:
        cp      (hl)
        ret     z
        add     hl, bc
        jp      FindItem

;-----------------------------------------------------------------------------
; Subroutine
; In:  HL = pointer to a 16-bit offset in file
; Out: HL = initial HL + 2
;      DE = pointer to data
ReadPtr:
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        ex      de, hl          ; HL = (HL)
                                ; DE = initial HL + 2
;       jp      GetDataPtr      ; no need, it follows

;-----------------------------------------------------------------------------
; Subroutine
; In:  HL = relative offset in ST file
; Out: HL = initial DE value
;      DE = pointer to data
GetDataPtr:
        ld      bc, STCHeader
p_Header: equ $ - 2
        add     hl, bc
        ex      de, hl
        ret

;-----------------------------------------------------------------------------
; Subroutine
; In:  A  = position in sample (0-31)
;      IX = pointer to sample's data
; Out: B  = $02 * NoToneFlag
;      C  = $10 * NoNoiseFlag
;      H  = noise value (0-31)
;      L  = volume value (0-15)
;      DE = tone shift value (0-$FFF) + $1000 * DoToneShiftDownFlag
ReadSample:
        ld      d, 0            ; D  = 0
        ld      e, a            ; DE = A = a
        add     a, a            ; A  = a*2
        add     a, e            ; A  = a*3 (0-93)
        ld      e, a            ; DE = a*3
        add     ix, de          ; IX = & Sample->rData[a]
        ; Byte 0: bits 7-4: Tone shift value (bits 11-8)
        ;         bits 3-0: Volume (0-15)
        ; Byte 1: bit 7: Noise mask (0=noise on, 1=noise off)
        ;         bit 6: Tone mask (0=tone on, 1=tone off)
        ;         bit 5: Tone shift direction (0=minus to freq., 1=plus to freq.)
        ;         bits 4-0: Noise value (0-31)
        ; Byte 2: Tone shift (LSB)
        ld      a, (ix + 1)     ; A  = Byte_1
        bit     7, a            ; Noise mask (0=noise on, 1=noise off)
        ld      c, $10          ; C  = $10 (no noise flag)
        jp      nz, .LNoNoise
        ld      c, d            ; C  = 0 (noise enabled)
.LNoNoise:
        bit     6, a            ; Tone mask (0=tone on, 1=tone off)
        ld      b, $02          ; B  = $02 (no tone flag)
        jp      nz, .LNoTone
        ld      b, d            ; B  = 0 (tone enabled)
.LNoTone:
        and     %00011111       ; Noise value (0-31)
        ld      h, a
        ld      e, (ix + 2)     ; E  = Tone shift (LSB)
        ld      a, (ix + 0)     ; A  = Byte_0
        push    af
        and     %11110000       ; A  = Byte_0 & $F0
 .4     rrca                    ; A  = Tone shift value (MSB)
        ld      d, a            ; DE = Tone shift value
        pop     af
        and     %00001111       ; A  = Volume (0-15)
        ld      l, a            ; L  = Volume (0-15)
        bit     5, (ix + 1)     ; Tone shift direction (0=minus to freq., 1=plus to freq.)
        ret     z
        set     4, d            ; DE |= $1000 (Tone shift direction)
        ret

;-----------------------------------------------------------------------------
; Subroutine
NextPattern:
        ld      a, (b_CurPos)
        ld      c, a            ; C  = b_CurPos
        ld      hl, b_PositionsCnt
        cp      (hl)
        jp      c, .LOk         ; if (b_CurPos >= b_PositionsCnt) restart
        xor     a               ; position is not available, restart
        ld      c, a            ; C  = 0
.LOk:   inc     a
        ld      (b_CurPos), a
        ld      l, c
        ld      h, 0
        add     hl, hl          ; HL = bOldPosition * ST_PositionRec
        ld      de, (p_rPositions)
        add     hl, de          ; HL = p_rPositions[bOldPosition]
        ld      c, (hl)         ; C  = p_rPositions[bOldPosition].bPNum
        inc     hl
        ld      a, (hl)         ; A  = p_rPositions[bOldPosition].bTransposition
        ld      (CalcPitch.bTransposition), a
        ld      a, c            ; A  = p_rPositions[bOldPosition].bPNum
        ld      hl, (p_Patterns)
        ld      bc, ST_Pattern
        call    FindItem
        inc     hl              ; HL = & p_Patterns[A].wChannelAOff
        call    ReadPtr
        ld      (p_ChannelA), de
        call    ReadPtr
        ld      (p_ChannelB), de
        call    ReadPtr
        ld      (p_ChannelC), de
        ret

;-----------------------------------------------------------------------------
; Subroutine
; In:  IX = pointer to _ST_Chn.r1 structure
; Out: Flag S=1 if counter was restarted
NextTick:
        dec     (ix + _ST_r1.bDelayCtr)
        ret     p
        ld      a, (ix - _ST_r0 + _ST_r0.bNoteDelay)
        ld      (ix + _ST_r1.bDelayCtr), a
        ret

;-----------------------------------------------------------------------------
; Subroutine
Play:
        ld      a, (b_DelayCtr)
        dec     a
        ld      (b_DelayCtr), a
        jp      nz, PlayChannels
        ld      a, (b_Delay)
        ld      (b_DelayCtr), a
        ld      ix, r_ChnA.r1
        call    NextTick
        jp      p, .LContinueB
        ld      hl, (p_ChannelA)
        ld      a, (hl)         ; A  = event
        inc     a
        call    z, NextPattern  ; next pattern if pattern end mark $FF found
        ld      hl, (p_ChannelA)
        call    NextRow
        ld      (p_ChannelA), hl
.LContinueB:
        ld      ix, r_ChnB.r1
        call    NextTick
        jp      p, .LContinueC
        ld      hl, (p_ChannelB)
        call    NextRow
        ld      (p_ChannelB), hl
.LContinueC:
        ld      ix, r_ChnC.r1
        call    NextTick
        jp      p, PlayChannels
        ld      hl, (p_ChannelC)
        call    NextRow
        ld      (p_ChannelC), hl
        jp      PlayChannels

;-----------------------------------------------------------------------------
; Subroutine
; In:  HL = pointer to pattern data
;      IX = pointer to _ST_Chn.r1 structure
NextRow:
        ld      a, (hl)         ; read event
        cp      $60
        jp      c, .LNote       ; $00-$5F: Note number (0-95), end position
        cp      $70
        jp      c, .LSample     ; $60-$6F: Sample number (0-15)
        cp      $80
        jp      c, .LOrnament   ; $70-$7F: Ornament number (0-15)
        jp      z, .LPause      ; $80: Pause, end position, channel off
        cp      $81
        jp      z, .LEmptyNote  ; $81: Empty note, end position
        cp      $82
        jp      z, .LNoEnvAndOrn; $82: Disable envelope and ornament
        cp      $8F
        jp      c, .LEnvelope   ; $83-$8E: Envelope number (3-14), read envelope's period LSB, disable ornament
                                ; $8F-$A1: Nothing, never used in pattern
        sub     $A1             ; $A2-$FE: Delay (1-93)
        ld      (ix + _ST_r1.bDelayCtr), a
        ld      (ix - _ST_r0 + _ST_r0.bNoteDelay), a
        inc     hl
        jp      NextRow

.LNote:
        ; $00-$5F: Note number (0-95), end position
        ld      (ix + _ST_r1.bNote), a
        ld      (ix + _ST_r1.bSamplePos), 0
        ld      (ix + _ST_r1.bRepeatLen), ST_SampleLength
.LEmptyNote:
        ; $81: Empty note, end position
        inc     hl
        ret

.LSample:
        ; $60-$6F: Sample number (0-15)
        sub     $60
        push    hl
        ld      bc, ST_Sample
        ld      hl, (p_Samples)
        call    FindItem
                                        ; HL = Samples[A]
        inc     hl                      ; HL = & Samples[A].rData
        ld      (ix + _ST_r1.pSampleData), l
        ld      (ix + _ST_r1.pSampleData + 1), h
        pop     hl
        inc     hl
        jp      NextRow

.LPause:
        ; $80: Pause, end position, channel off
        inc     hl
.LClrRepLen:
        ld      (ix + _ST_r1.bRepeatLen), -1
        ret

.LNoEnvAndOrn:
        ; $82: Disable envelope and ornament
        xor     a
        jr      .LSet

.LOrnament:
        ; $70-$7F: Ornament number (0-15)
        sub     $70
.LSet:  push    hl
        ld      bc, ST_Ornament
        ld      hl, (p_Ornaments)
        call    FindItem
        inc     hl
        ld      (ix + _ST_r1.pOrnamentData), l
        ld      (ix + _ST_r1.pOrnamentData + 1), h
        ld      (ix - _ST_r0 + _ST_r0.bSampleFlag), 0
        pop     hl
        inc     hl
        jp      NextRow

.LEnvelope:
        ; $83-$8E: Envelope number (3-14), read envelope's period LSB, disable ornament
        sub     $80
        ld      (b_AYEnvShape), a
        inc     hl
        ld      a, (hl)         ; A = envelope's period LSB
        inc     hl
        ld      (w_AYEnvPeriod), a
        ld      (ix - _ST_r0 + _ST_r0.bSampleFlag), 1
        push    hl
        xor     a
        ld      bc, ST_Ornament
        ld      hl, (p_Ornaments)
        call    FindItem
        inc     hl
        ld      (ix + _ST_r1.pOrnamentData), l
        ld      (ix + _ST_r1.pOrnamentData + 1), h
        pop     hl
        jp      NextRow

;-----------------------------------------------------------------------------
; Subroutine
; In:  IX = pointer to _ST_Chn.r1 structure
; Out: C  = sample position
SetupSample:
        ld      a, (ix + _ST_r1.bRepeatLen)
        inc     a
        ret     z               ; if (r1->bRepeatLen == -1) return
 .2     dec     a               ; A  = r1->bRepeatLen - 1
        ld      (ix + _ST_r1.bRepeatLen), a
                                ; r1->bRepeatLen = r1->bRepeatLen - 1
        push    af
        ld      a, (ix + _ST_r1.bSamplePos)
        ld      c, a            ; C  = r1->bSamplePos
        inc     a
        and     ST_SamplePosMask
        ld      (ix + _ST_r1.bSamplePos), a
                                ; r1->bSamplePos = (r1->bSamplePos + 1) & ST_SamplePosMask
        pop     af              ; A  = r1->bRepeatLen - 1
        ret     nz              ; if (r1->bRepeatLen != 1) return
        ld      e, (ix + _ST_r1.pSampleData)
        ld      d, (ix + _ST_r1.pSampleData + 1)
        ld      hl, ST_Sample.bRepeatPosition - ST_Sample.rData
        add     hl, de          ; HL = & Sample->bRepeatPosition
        ld      a, (hl)
        dec     a               ; A  = Sample->bRepeatPosition - 1
        jp      m, NextRow.LClrRepLen   ; if (Sample->bRepeatPosition <= 0) reset
        ld      c, a            ; C  = Sample->bRepeatPosition - 1
        inc     a
        and     ST_SamplePosMask
        ld      (ix + _ST_r1.bSamplePos), a
                                ; r1->bSamplePos = Sample->bRepeatPosition & ST_SamplePosMask
        inc     hl              ; HL = & Sample->bRepeatLength
        ld      a, (hl)
        inc     a
        ld      (ix + _ST_r1.bRepeatLen), a
                                ; r1->bRepeatLen = Sample->bRepeatLength + 1
        ret

;-----------------------------------------------------------------------------
; Subroutine
; In:  C  = 0 for noise (no noise otherwise)
;      H  = noise pitch (0-31)
SetupNoise:
        ld      a, c
        or      a
        ret     nz
        ld      a, h
        ld      (b_AYNoisePitch), a
        ret

;-----------------------------------------------------------------------------
; Subroutine
; In:  IX = pointer to _ST_Chn.r1 structure
;      HL = pointer to AY channel volume register's data (R8/R9/R10)
SetupEnvShape:
        ld      a, (ix + _ST_r1.bRepeatLen)
        inc     a
        ret     z               ; if (r1->bRepeatLen == -1) return
        ld      a, (ix - _ST_r0 + _ST_r0.bSampleFlag)
        or      a
        ret     z               ; if (r0->bSampleFlag == 0) return
        cp      2
        jp      z, .LReset      ; if (r0->bSampleFlag == 2) b_AYEnvShape = 0
        ld      (ix - _ST_r0 + _ST_r0.bSampleFlag), 2
        jp      .L2             ; if (r0->bSampleFlag == 1) r0->bSampleFlag = 2
.LReset:xor     a
        ld      (b_AYEnvShape), a
.L2:    set     4, (hl)         ; volume |= $10 (do not use volume: use envelope)
        ret

;-----------------------------------------------------------------------------
; Subroutine
; In:  IX = pointer to _ST_Chn.r1 structure
;      L  = volume value (0-15)
;      DE = tone shift value (0-$FFF) + $1000 * DoToneShiftDownFlag
; Out: A  = volume (0-15)
;      HL = pitch
CalcPitch:
        ld      a, l
        push    af
        push    de
        ld      l, (ix + _ST_r1.pOrnamentData)
        ld      h, (ix + _ST_r1.pOrnamentData + 1)
        ld      de, 0
.wCurPos: equ $ - 2
        add     hl, de          ; HL = & OrnamentData[wCurPos]
        ld      a, (ix + _ST_r1.bNote)
        add     a, (hl)
        add     a, 0            ; A  = r1->bNote + OrnamentData[wCurPos] + bTransposition
.bTransposition: equ $ - 1
        add     a, a            ; A  = (r1->bNote + OrnamentData[wCurPos] + bTransposition) * 2
        ld      e, a
        ld      d, 0
        ld      hl, NotePeriods
        add     hl, de          ; HL = & NotePeriods[r1->bNote + OrnamentData[wCurPos] + bTransposition]
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl          ; HL = NotePeriods[r1->bNote + OrnamentData[wCurPos] + bTransposition]
        pop     de              ; DE = tone shift value (0-$FFF) + $1000 * DoToneShiftDownFlag
        pop     af              ; A  = volume value (0-15)
        bit     4, d
        jr      z, .LShiftUp
        res     4, d
        add     hl, de
        ret
.LShiftUp:
        and     a
        sbc     hl, de
        ret

;-----------------------------------------------------------------------------
; Subroutine
PlayChannels:
; Play channel A
        ld      ix, r_ChnA.r1
        call    SetupSample
        ld      a, c
        ld      (CalcPitch.wCurPos), a
        ld      ix, (r_ChnA.r1.pSampleData)
        call    ReadSample
        ld      a, c
        or      b
        rrca                    ; A  = $08 * NoNoiseFlag | $01 * NoToneFlag
        ld      (b_AYMixer), a
        ld      ix, r_ChnA.r1
        ld      a, (ix + _ST_r1.bRepeatLen)
        inc     a
        jp      z, .L1          ; if (r1->bRepeatLen == -1) skip
        call    SetupNoise
        call    CalcPitch
        ld      (w_AYPitchA), hl
.L1:    ld      hl, b_AYVolumeA
        ld      (hl), a
        call    SetupEnvShape
; Play channel B
        ld      ix, r_ChnB.r1
        call    SetupSample
        ld      a, (ix + _ST_r1.bRepeatLen)
        inc     a
        jp      z, .L2          ; if (r1->bRepeatLen == -1) skip
        ld      a, c
        ld      (CalcPitch.wCurPos), a
        ld      ix, (r_ChnB.r1.pSampleData)
        call    ReadSample
        ld      a, (b_AYMixer)
        or      c
        or      b               ; A  |= $10 * NoNoiseFlag | $02 * NoToneFlag
        ld      (b_AYMixer), a
        call    SetupNoise
        ld      ix, r_ChnB.r1
        call    CalcPitch
        ld      (w_AYPitchB), hl
.L2:    ld      hl, b_AYVolumeB
        ld      (hl), a
        call    SetupEnvShape
; Play channel C
        ld      ix, r_ChnC.r1
        call    SetupSample
        ld      a, (ix + _ST_r1.bRepeatLen)
        inc     a
        jp      z, .L3          ; if (r1->bRepeatLen == -1) skip
        ld      a, c
        ld      (CalcPitch.wCurPos), a
        ld      ix, (r_ChnC.r1.pSampleData)
        call    ReadSample
        ld      a, (b_AYMixer)
        rlc     c
        rlc     b
        or      b
        or      c               ; A  |= $20 * NoNoiseFlag | $04 * NoToneFlag
        ld      (b_AYMixer), a
        call    SetupNoise
        ld      ix, r_ChnC.r1
        call    CalcPitch
        ld      (w_AYPitchC), hl
.L3:    ld      hl, b_AYVolumeC
        ld      (hl), a
        call    SetupEnvShape
; Output sound
;       jp      WriteToAY       ; no need, it follows

;-----------------------------------------------------------------------------
; Subroutine
WriteToAY:
        ld      hl, b_AYEnvShape; start from register 13
        xor     a
        or      (hl)
        ld      a, 13           ; register number
        jr      nz, .LNot0      ; value == 0 ?
        sub     3               ; skip values and start from register 10
 .3     dec     hl
.LNot0: ld      c, ay_ctrl_port & $FF
.LLoop: ld      b, ay_ctrl_port >> 8
        out     (c), a
        ld      b, ay_data_port >> 8    ; LSB address is the same
        outd
        dec     a
        jp      p, .LLoop
        ret

        endmodule
