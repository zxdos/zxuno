STARHELP:
	jsr print		; Print text
;	       01234567890123456789012345678901
	.byte 13,"BBCMMC ROM V1.0",13
	.byte "  CAT (<FILTER>)",13
	.byte "  DELETE <NAME>",13
	.byte "  DIR <PATH>",13
;	.byte "  EXEC <NAME>",13
	.byte "  HELP",13
	.byte "  INFO <NAME>",13
	.byte "  LOAD <NAME> (<LOAD>)",13
	.byte "  RUN <NAME>",13
	.byte "  SAVE <NAME><ST><EN>(<EX>)",13
	.byte 13,"OS 1.20",13
	NOP
	RTS
