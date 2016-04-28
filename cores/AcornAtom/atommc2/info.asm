
;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *INFO [filename]
;
; Shows metadata associated with the specified file.
;
STARINFO:
    lda  #0                   ; load address is not set
    sta  LEXEC

    jsr  read_filename
	jsr		open_file_read
    jsr  read_info
    jsr  print_filename
    jsr  print_fileinfo
    jmp  OSCRLF
