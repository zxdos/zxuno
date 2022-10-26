; rtc.asm - return date for esxdos call on $2700
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
;
;-------------------------------------------------------------------------------

;               output  RTC.SYS

        define  SCL0SDA0    00b
        define  SCL0SDA1    01b
        define  SCL1SDA0    10b
        define  SCL1SDA1    11b
        define  I2CADDR_R   $a3
        define  I2CADDR_W   $a2

                include zxuno.def
                include esxdos.def

                org     $2700

                ld      bc, ZXUNOADDR
                ld      a, i2creg
                out     (c), a          ; selecciono el registro I2C.
                inc     b

ReadDateTime    ld      hl, Params
                ;ld      e, 1
                ;call    SendW           ;Envío en modo escritura el número de registro desde donde quiero empezar a leer

SendW           ;Transmite E bytes apuntados por HL al bus I2C (escritura)
                ld      a, SCL1SDA1     ;Bus en modo idle.
                out     (c), a          ;Envío condición de START al bus (SDA a 0 mientras mantengo SCL a 1)
                dec     a               ;ld a,SCL1SDA0
                out     (c), a
                ld      a, I2CADDR_W    ;Envío la dirección I2C de escritura del RTC
                call    SendByte

LoopSendMess    ;ld      a, (hl)         ;y en un bucle, me pongo a enviar uno tras otro, los E bytes a los que apunta HL
                ld      a, 2             ;y en un bucle, me pongo a enviar uno tras otro, los E bytes a los que apunta HL
;                inc     hl
                call    SendByte
;                dec     e
;                jr      nz, LoopSendMess
                call    Send0                   ;después de enviar el ultimo byte, envío la condición de STOP al bus (envío un 0, con lo que se queda SDA a 0 y SCL a 1, y a continuación pongo SDA a 1)
                inc     d               ;ld      d, SCL1SDA1
                out     (c), d
;                ret

                ld      e, 7

;                call    SendR           ;Y a continuación espero recibir 7 bytes (segundos, minutos, horas, día del mes, día de la semana (que no uso), mes, y dos últimos dígitos del año

SendR           ;Recibo E bytes que se guardarán a partir de donde indique HL
                ld      a, SCL1SDA1     ;Bus en modo idle.
                out     (c), a
                ;Envío la condición de START al bus I2C
                dec     a               ;ld a,SCL1SDA0
                out     (c), a

                ld      a, I2CADDR_R    ;Envío la dirección I2C de lectura del RTC
                call    SendByte

LoopSendR       call    nz, Send0       ;enviar un ACK es enviar un 0
                call    RcvByte         ;y en un bucle, me pongo a recibir un byte detrás de otro. Tras cada byte, menos el último, envío ACK
                ld      (hl), a
                inc     hl
                dec     e
                jr      nz, LoopSendR

SendNACKandP    call    Send1           ;aquí llego si acabo de recibir el último byte. Envío un NACK (un 1)
                call    Send0           ;y a continuación envío la condición de STOP al bus I2C
                inc     d               ;ld      d, SCL1SDA1
                out     (c), d
;                ret

                ld      hl, Params
                ld      b, %01111110    ;Segundos
                call    BCDtobin
                rrca                    ;Segundos / 2
                ld      e, a            ;Guarda en E
                ld      b, %01111111    ;Minutos
                call    BCDtobin
                rrca
                rrca
                rrca
                ld      d, a
                and     %11100000
                or      e
                ld      e, a
                ld      b, %00111111    ;Horas
                call    BCDtobin
                rlca
                rlca
                rlca
                xor     d
                and     %11111000
                xor     d
                ld      d, a
                push    de
                ld      b, %00111111    ;Días
                call    BCDtobin
                ld      e, a
                inc     hl
                ld      b, %00011111    ;Siglo/Mes
                ld      c, (hl)
                call    BCDtobin
                rrca
                rrca
                rrca
                ld      d, a
                and     %11100000
                or      e
                ld      e, a
                dec     b
                call    BCDtobin
                bit     7, c
                jr      z, Milnov
                add     100
Milnov          sub     80
                rr      d
                adc     a, a
                ld      b, a
                ld      c, e
                pop     de
                ret

BCDtobin        ld      a, (hl)
                inc     hl
                and     b
                ld      b, 0
Repite          inc     b
                sub     $10
                jr      nc, Repite
Suma10          add     a, 10
                djnz    Suma10
                add     a, 6
                ret

Params             ;db 02h  ; VL_seconds register . Indico que quiero empezar a leer desde aquí (que es lo típico para leer toda la fecha y hora)
                   db 0,40h,16h,24h,01h,10h,22h  ;La hora a la que quieres poner el reloj. En lectura, estos datos se machacan con la hora leída del RTC
                   ;  S  M   H   D   W  Mo   Y   (en BCD) OJO cuidao porque el dígito de las decenas no usa todos los bits (excepto en el año)
                   ;                                      así que hay que enmascararlo antes de hacer algo con él (yo lo hago justo antes de imprirmilo)

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

RcvByte         ;byte a recibir en A. BC=puerto de datos del ZXUNO ya apuntando a I2CREG. Usa y modifica: A, D, flags
                ld      a, 1
RcvBit          call    Send1           ;envío un pulso de reloj con SDA a alta impedancia
                in      d, (c)          ;el RTC pone aquí el dato (1 o 0) y lo leo (está en bit 7 de D)
                sll     d               ;bit 7 a carry
                adc     a, a            ;carry a bit 0 de A, y desplazo a la izquierda
                jr      nc, RcvBit
                ret

Send0           ld      d, SCL0SDA0
                out     (c), d
                ld      d, SCL1SDA0
                out     (c), d
                ret
