; zxuno.inc
;
; SPDX-FileCopyrightText: Copyright (C) 2019, 2021 Antonio Villena
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

        define  zxuno_port      $fc3b
        define  master_conf     0
        define  master_mapper   1
        define  flash_spi       2
        define  flash_cs        3
        define  scan_code       4
        define  key_stat        5
        define  joy_conf        6
        define  key_map         7
        define  nmi_event       8
        define  mouse_data      9
        define  mouse_status    10
        define  scandbl_ctrl    11
        define  raster_line     12
        define  raster_ctrl     13
        define  dev_control     14
        define  core_addr       $fc
        define  core_boot       $fd
        define  cold_boot       $fe
        define  core_id         $ff

        define  SPI_PORT        $eb
        define  OUT_PORT        $e7
        define  MMC_0           $fe ; D0 LOW = SLOT0 active
        define  CMD0            $40
        define  CMD1            $41
        define  CMD8            $48
        define  SET_BLOCKLEN    $50
        define  READ_SINGLE     $51
        define  CMD41           $69
        define  CMD55           $77
        define  CMD58           $7a

        define  FA_READ         0x01
        define  FA_WRITE        0x02
        define  FA_OPEN_AL      0x08
        define  M_GETSETDRV     0x89
        define  F_OPEN          0x9a
        define  F_CLOSE         0x9b
        define  F_READ          0x9d
        define  F_WRITE         0x9e
        define  F_FSTAT         0xa1

              macro wreg  dir, dato
                call    rst28
                defb    dir, dato
              endm

              macro esxdos  dato
                rst     $08
                defb    dato
              endm
