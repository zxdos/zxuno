;==============================================================================
; Project: NMI.zdsp
; File: NMI.inc
; Date: 29/07/2017 10:58:43
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; DEFINITIONS
;==============================================================================

M_VERSION       MACRO
                db      'v0.0.13'
                ENDM

; -----------------------------------------------------------------------------
; Colors and attributes
; -----------------------------------------------------------------------------
BLACK           equ     0
BLUE            equ     1
RED             equ     2
MAGENTA         equ     3
GREEN           equ     4
CYAN            equ     5
YELLOW          equ     6
WHITE           equ     7

BRIGHT          equ     $40
FLASH           equ     $80

; -----------------------------------------------------------------------------
; Key table
; -----------------------------------------------------------------------------
K_EDIT          equ     $07
K_LEFT          equ     $08
K_RIGHT         equ     $09
K_DOWN          equ     $0a
K_UP            equ     $0b
K_DELETE        equ     $0c
K_ENTER         equ     $0d

K_AT            equ     $ac     ; SS+I
K_TO            equ     $cc     ; SS+F

; no mapping on speccy BASIC

K_BREAK         equ     $1c

K_SS_ENTER      equ     $1d

; -----------------------------------------------------------------------------
; Colors used in GUI
; -----------------------------------------------------------------------------
COL_MID         equ     BLACK*8+WHITE           ; black paper, white ink
COL_TOP         equ     WHITE*8+BLACK           ; white paper, black ink
COL_BOT         equ     WHITE*8+BLACK           ; white paper, black ink
COL_CUR         equ     BRIGHT+BLUE*8+WHITE     ; blue paper, bright white ink
COL_ERR         equ     BRIGHT+RED*8+WHITE      ; red paper, bright white ink

; -----------------------------------------------------------------------------
; Overlay system
; -----------------------------------------------------------------------------
SIZ_OVR         equ     768                     ; size of overlay buffer
