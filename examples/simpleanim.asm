ORG &8000
;; Clear screen
CALL &BB6C ;; TXT_CLEAR_WINDOW

;; Start coordinates and character
LD B, 39
LD C, 10

LOOP:
;; Draw character
LD D, '@'
CALL DRAW
;; Wait
CALL WAIT
;; Remove Character
LD D, ' '
CALL DRAW
;; Move character
DJNZ LOOP
RET

DRAW:
LD H, B
LD L, C
CALL &BB75  ;; TXT_SET_CURSOR
LD A, D
CALL &BB5A ;; TXT_OUTPUT
RET

WAIT:
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
HALT
RET