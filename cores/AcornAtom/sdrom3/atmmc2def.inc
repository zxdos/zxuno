; /*
; atmmmc2def.h Symbolic defines for AtoMMC2

; 2011-05-25, Phill Harvey-Smith.

; // Register definitions, these are offsets from 0xB400 on the Atom side.

CMD_REG                         equ $00
LATCH_REG                       equ $01
READ_DATA_REG                   equ $02
WRITE_DATA_REG                  equ $03

; // DIR_CMD_REG commands
CMD_DIR_OPEN                    equ $00
CMD_DIR_READ                    equ $01
CMD_DIR_CWD                     equ $02

; // CMD_REG_COMMANDS
CMD_FILE_CLOSE                  equ $10
CMD_FILE_OPEN_READ              equ $11
CMD_FILE_OPEN_IMG               equ $12
CMD_FILE_OPEN_WRITE             equ $13
CMD_FILE_DELETE                 equ $14
CMD_FILE_GETINFO                equ $15

CMD_INIT_READ                   equ $20
CMD_INIT_WRITE                  equ $21
CMD_READ_BYTES                  equ $22
CMD_WRITE_BYTES                 equ $23

; // READ_DATA_REG "commands"

; // EXEC_PACKET_REG "commands"
CMD_EXEC_PACKET                 equ $3F

; // SDOS_LBA_REG commands
CMD_LOAD_PARAM                  equ $40
CMD_GET_IMG_STATUS              equ $41
CMD_GET_IMG_NAME                equ $42
CMD_READ_IMG_SEC                equ $43
CMD_WRITE_IMG_SEC               equ $44
CMD_SER_IMG_INFO                equ $45
CMD_VALID_IMG_NAMES             equ $46
CMD_IMG_UNMOUNT                 equ $47

; // UTIL_CMD_REG commands
CMD_GET_CARD_TYPE               equ $80
CMD_GET_PORT_DDR                equ $A0
CMD_SET_PORT_DDR                equ $A1
CMD_READ_PORT                   equ $A2
CMD_WRITE_PORT                  equ $A3
CMD_GET_FW_VER                  equ $E0
CMD_GET_BL_VER                  equ $E1
CMD_GET_CFG_BYTE                equ $F0
CMD_SET_CFG_BYTE                equ $F1
CMD_READ_AUX                    equ $FD
CMD_GET_HEARTBEAT               equ $FE


; // Status codes
STATUS_OK                       equ $3F
STATUS_COMPLETE                 equ $40
STATUS_BUSY                     equ $80

ERROR_MASK                      equ $3F

; // To be or'd with STATUS_COMPLETE
ERROR_NO_DATA                   equ $08
ERROR_INVALID_DRIVE             equ $09
ERROR_READ_ONLY                 equ $0A
ERROR_ALREADY_MOUNT             equ $0A















