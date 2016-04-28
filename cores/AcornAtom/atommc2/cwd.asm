;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CWD [path]
;
; Sets the current working directory
;
; 2011-05-29, Now uses CMD_REG -- PHS

STARCWD:
   jsr   SKIPSPC
   bne   @setcwd

   jmp   COSSYN

@setcwd:
   jsr   read_filename        ; copy filename into $140

set_cwd:
   jsr   $f844                ; set $c9\a = $140, set x = $c9

   jsr   COSPOST              ; Do COS interpreter post test
   ldx   #$c9                 ; File data starts at #C9

   jsr   CHKNAME
   jsr   send_name            ; put string at $140 to interface

   SLOWCMDI	CMD_DIR_CWD			; set CWD 
   jmp   expect64orless

   rts