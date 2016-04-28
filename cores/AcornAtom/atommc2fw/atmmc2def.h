/*
	atmmmc2def.h Symbolic defines for AtoMMC2
	
	2011-05-25, Phill Harvey-Smith.
*/

// Register definitions, these are offsets from 0xB400 on the Atom side.

#define CMD_REG				0x00
#define LATCH_REG			0x01
#define READ_DATA_REG		0x02
#define WRITE_DATA_REG		0x03
#define STATUS_REG			0x04

// DIR_CMD_REG commands
#define CMD_DIR_OPEN		0x00
#define CMD_DIR_READ		0x01
#define CMD_DIR_CWD			0x02

// CMD_REG_COMMANDS
#define CMD_FILE_CLOSE		0x10
#define CMD_FILE_OPEN_READ	0x11
#define CMD_FILE_OPEN_IMG	0x12
#define CMD_FILE_OPEN_WRITE	0x13
#define CMD_FILE_DELETE		0x14
#define CMD_FILE_GETINFO	0x15
#define CMD_FILE_SEEK		0x16
#define CMD_FILE_OPEN_RAF       0x17

#define CMD_INIT_READ		0x20
#define CMD_INIT_WRITE		0x21
#define CMD_READ_BYTES		0x22
#define CMD_WRITE_BYTES		0x23

// READ_DATA_REG "commands"

// EXEC_PACKET_REG "commands"
#define CMD_EXEC_PACKET		0x3F

// SDOS_LBA_REG commands
#define CMD_LOAD_PARAM		0x40
#define CMD_GET_IMG_STATUS	0x41
#define CMD_GET_IMG_NAME	0x42
#define CMD_READ_IMG_SEC	0x43
#define CMD_WRITE_IMG_SEC	0x44
#define CMD_SER_IMG_INFO	0x45
#define CMD_VALID_IMG_NAMES	0x46
#define CMD_IMG_UNMOUNT		0x47

// UTIL_CMD_REG commands
#define CMD_GET_CARD_TYPE	0x80
#define CMD_GET_PORT_DDR	0xA0
#define CMD_SET_PORT_DDR	0xA1
#define CMD_READ_PORT		0xA2
#define CMD_WRITE_PORT		0xA3
#define CMD_GET_FW_VER		0xE0
#define CMD_GET_BL_VER		0xE1
#define CMD_GET_CFG_BYTE	0xF0
#define CMD_SET_CFG_BYTE	0xF1
#define CMD_READ_AUX		0xFD
#define CMD_GET_HEARTBEAT	0xFE


// Status codes
#define STATUS_OK			0x3F
#define STATUS_COMPLETE		0x40
#define STATUS_EOF		0x60
#define	STATUS_BUSY			0x80

#define ERROR_MASK			0x3F

// To be or'd with STATUS_COMPLETE
#define ERROR_NO_DATA		0x08
#define ERROR_INVALID_DRIVE	0x09
#define ERROR_READ_ONLY		0x0A
#define ERROR_ALREADY_MOUNT	0x0A
#define ERROR_TOO_MANY_OPEN	0x12

// Offset returned file numbers by 0x20, to disambiguate from errors
#define FILENUM_OFFSET		0x20

// STATUS_REG bit masks
//
// MMC_MCU_BUSY set by a write to CMD_REG by the Atom, cleared by a write by the MCU
// MMC_MCU_READ set by a write by the Atom (to any reg), cleared by a read by the MCU
// MCU_MMC_WROTE set by a write by the MCU cleared by a read by the Atom (any reg except status).
//
#define MMC_MCU_BUSY		0x01
#define MMC_MCU_READ		0x02
#define MMC_MCU_WROTE		0x04














