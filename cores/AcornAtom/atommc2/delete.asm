;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *DELETE [filename] ([Y])
;
; Deletes the specified file after a prompt, unless Y specified on command line
;
STARDELETE:
   jsr  read_filename
   jsr	open_file_read

   jsr   confirm

   pha
   jsr   OSCRLF
   pla
   cmp   #'Y'
   beq   @continue

   rts

@continue:
   jsr	delete_file
   rts



confirm:
   jsr   STROUT
   .byte "CONFIRM (Y):"
   nop

   jsr   OSRDCH
   jmp   OSWRCH
