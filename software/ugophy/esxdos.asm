; API methods
ESX_GETSETDRV = #89
ESX_FOPEN = #9A
ESX_FCLOSE = #9B
ESX_FSYNC = #9C
ESX_FREAD = #9D
ESX_FWRITE = #9E

; File modes
FMODE_READ = #01
FMODE_WRITE = #06
FMODE_CREATE = #0E

; Returns: 
;  A - current drive
getDefaultDrive:
    ld a, 0 : rst #8
    defb ESX_GETSETDRV
    ret

; Opens file on default drive
; B - File mode
; HL - File name
; Returns:
;  A - file stream id
fopen:
    push bc : push hl 
    call getDefaultDrive
    pop ix : pop bc
    rst #8
    defb ESX_FOPEN
    ret

; A - file stream id
fclose:
    rst #8
    defb ESX_FCLOSE
    ret

; A - file stream id
; BC - length
; HL - buffer
; Returns
;  BC - length(how much was actually read) 
fread:
    push hl : pop ix
    rst #8
    defb ESX_FREAD
    ret

; A - file stream id
; BC - length
; HL - buffer
; Returns:
;   BC - actually written bytes
fwrite:
    push hl : pop ix
    rst #8
    defb ESX_FWRITE
    ret
    
; A - file stream id
fsync:
    rst #8
    defb ESX_FSYNC
    ret
