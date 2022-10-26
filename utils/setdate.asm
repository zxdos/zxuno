; setdate.asm - set date and time using pcf8563
; .setdate YYYYMMDDHHMMSS
;
; Copyright (C) 2022 Antonio Villena/McLeod_ideafix
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, version 3.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.
;
; Compatible compilers:
;   SjAsmPlus, <https://github.com/z00m128/sjasmplus>

;               output  SETDATE

        define  SCL0SDA0    00b
        define  SCL0SDA1    01b
        define  SCL1SDA0    10b
        define  SCL1SDA1    11b
        define  I2CADDR_R   $a3
        define  I2CADDR_W   $a2

                include zxuno.def
                include esxdos.def

                org     $2000           ; comienzo de la ejecución de los comandos ESXDOS
NoPrint         ld      (Command+1), hl
                ld      a, h
                or      l
                jp      nz, Init
                call    Print
                db      13, 'Usage:', 13
                db      ' .SETDATE YYYYMMDDHHMMSS', 13
                db      'Example:', 13
                dz      ' .SETDATE 20151021072800', 13
                ret

Params          db 02h  ; VL_seconds register . Indico que quiero empezar a leer desde aquí (que es lo típico para leer toda la fecha y hora)
                db 0,40h,16h,24h,01h,10h,22h,0  ;La hora a la que quieres poner el reloj. En lectura, estos datos se machacan con la hora leída del RTC
                ;  S  M   H   D   W  Mo   Y

Wrong           call    Print
                dz      'Wrong format entered', 13
                ret
Init            ld      b, 15
Repite          ld      a, (hl)
                cp      13
                jr      z, Fincad
                inc     hl
                dec     b
                sub     $30
                cp      10
                jr      c, Repite
Fincad          djnz    Wrong
Command         ld      hl, 0
                ld      de, Params+8
                call    ReadBCD
                cp      $20
                jr      nz, Centone
                ld      b, $80
Centone         inc     de
                call    ReadBCD
                call    ReadBCD
                xor     b
                call    ReadBCD
                dec     de
                call    ReadBCD
                call    ReadBCD
                call    ReadBCD
                ld      (de), a
                ld      hl, Params
                ld      e, 8
                ld      bc, ZXUNOADDR
                ld      a, i2creg
                out     (c), a          ; selecciono el registro I2C.
                inc     b
                ld      a, SCL1SDA1     ;Bus en modo idle.
                out     (c), a          ;Envío condición de START al bus (SDA a 0 mientras mantengo SCL a 1)
                dec     a               ;ld a,SCL1SDA0
                out     (c), a
                ld      a, I2CADDR_W    ;Envío la dirección I2C de escritura del RTC
                call    SendByte
LoopSendMess    ld      a, (hl)         ;y en un bucle, me pongo a enviar uno tras otro, los E bytes a los que apunta HL
                inc     hl
                call    SendByte
                dec     e
                jr      nz, LoopSendMess
                call    Send0                   ;después de enviar el ultimo byte, envío la condición de STOP al bus (envío un 0, con lo que se queda SDA a 0 y SCL a 1, y a continuación pongo SDA a 1)
                inc     d               ;ld      d, SCL1SDA1
                out     (c), d
                or      a
                ret

SendByte        ;Enviar un byte por I2C. Byte en A. BC=puerto de datos del ZXUNO ya apuntando a I2CREG. Usa y modifica: A, D, flags
                scf
TransBit        adc     a, a   ;A otro bit
                jr      z, Endbyte
                call    c, Send1
                call    nc, Send0
                and     a
                jr      TransBit
Endbyte         ; Wait for ACK
Send1           ld      d, SCL0SDA1
                out     (c), d
                ld      d, SCL1SDA1
                out     (c), d          ;Transmito un bit 1 para dejar SDA en modo de alta impedancia y que el receptor puedo ponerlo a 0
                ret                     ; S flag 0 = ACK received, S flag 1 = ACK not received

Send0           ld      d, SCL0SDA0
                out     (c), d
                ld      d, SCL1SDA0
                out     (c), d
                ret

ReadBCD         ld      (de), a
                dec     de
                ld      a, (hl)
                inc     hl
                sub     $30
                rlca
                rlca
                rlca
                rlca
                ld      c, a
                ld      a, (hl)
                inc     hl
                sub     $30
                or      c
                ret

                include Print.inc
