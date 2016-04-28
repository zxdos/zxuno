; /*
; atmmmc2def.h Symbolic defines for AtoMMC2

; 2011-05-25, Phill Harvey-Smith.

; // Register definitions, these are offsets from 0xB400 on the Atom side.

CMD_REG                         =   $00
LATCH_REG                       =   $01
READ_DATA_REG                   =   $02
WRITE_DATA_REG                  =   $03
STATUS_REG                      =   $04

; // DIR_CMD_REG commands
CMD_DIR_OPEN                    =   $00
CMD_DIR_READ                    =   $01
CMD_DIR_CWD                     =   $02
CMD_DIR_GETCWD                  =   $03
CMD_DIR_MKDIR                   =   $04
CMD_DIR_RMDIR                   =   $05

; // CMD_REG_COMMANDS
CMD_FILE_CLOSE                  =   $10
CMD_FILE_OPEN_READ              =   $11
CMD_FILE_OPEN_IMG               =   $12
CMD_FILE_OPEN_WRITE             =   $13
CMD_FILE_DELETE                 =   $14
CMD_FILE_GETINFO                =   $15

CMD_INIT_READ                   =   $20
CMD_INIT_WRITE                  =   $21
CMD_READ_BYTES                  =   $22
CMD_WRITE_BYTES                 =   $23

; // READ_DATA_REG "commands"

; // EXEC_PACKET_REG "commands"
CMD_EXEC_PACKET                 =   $3F

; // SDOS_LBA_REG commands
CMD_LOAD_PARAM                  =   $40
CMD_GET_IMG_STATUS              =   $41
CMD_GET_IMG_NAME                =   $42
CMD_READ_IMG_SEC                =   $43
CMD_WRITE_IMG_SEC               =   $44
CMD_SER_IMG_INFO                =   $45
CMD_VALID_IMG_NAMES             =   $46
CMD_IMG_UNMOUNT                 =   $47

; // UTIL_CMD_REG commands
CMD_GET_CARD_TYPE               =   $80
CMD_GET_PORT_DDR                =   $A0
CMD_SET_PORT_DDR                =   $A1
CMD_READ_PORT                   =   $A2
CMD_WRITE_PORT                  =   $A3
CMD_GET_FW_VER                  =   $E0
CMD_GET_BL_VER                  =   $E1
CMD_GET_CFG_BYTE                =   $F0
CMD_SET_CFG_BYTE                =   $F1
CMD_READ_AUX                    =   $FD
CMD_GET_HEARTBEAT               =   $FE


; // Status codes
STATUS_OK                       =   $3F
STATUS_COMPLETE                 =   $40
STATUS_BUSY                     =   $80

ERROR_MASK                      =   $3F

; // To be or'd with STATUS_COMPLETE
ERROR_NO_DATA                   =   $08
ERROR_INVALID_DRIVE             =   $09
ERROR_READ_ONLY                 =   $0A
ERROR_ALREADY_MOUNT             =   $0A

; // STATUS_REG bit masks
; //
; // MMC_MCU_BUSY set by a write to CMD_REG by the Atom, cleared by a write by the MCU
; // MMC_MCU_READ set by a write by the Atom (to any reg), cleared by a read by the MCU
; // MCU_MMC_WROTE set by a write by the MCU cleared by a read by the Atom (any reg except status).
; //
MMC_MCU_BUSY                    =   $01
MMC_MCU_READ                    =   $02
MMC_MCU_WROTE                   =   $04














