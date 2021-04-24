; SPDX-FileCopyrightText: Copyright (C) 2019, 2021 Antonio Villena
;
; SPDX-License-Identifier: GPL-3.0-only

; Compatible compilers:
;   SJAsmPlus, <https://github.com/sjasmplus/sjasmplus/>

Print           pop     hl
                db      $3e             ; ld a,$nn
Print1          rst     $10             ; db $d7
                ld      a, (hl)
                inc     hl
                or      a
                jr      nz, Print1
                jp      (hl)
