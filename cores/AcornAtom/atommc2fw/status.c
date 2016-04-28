/*
	Status.c
	
	Functions for logging program status to the serial port, to
	be used for debugging pruposes etc.
	
	2008-03-21, P.Harvey-Smith.
	
*/

#include <avr/interrupt.h>
#include <stdio.h>
#include <ctype.h>
#include "terminalcodes.h"
#include "status.h"

#ifdef SERIAL_STATUS

static int StdioSerial_TxByte0(char DataByte, FILE *Stream);
static int StdioSerial_TxByte1(char DataByte, FILE *Stream);

FILE ser0stream = FDEV_SETUP_STREAM(StdioSerial_TxByte0,NULL,_FDEV_SETUP_WRITE);
FILE ser1stream = FDEV_SETUP_STREAM(StdioSerial_TxByte1,NULL,_FDEV_SETUP_WRITE);

void StdioSerial_TxByte(char DataByte, uint8_t	Port)
{
	#ifdef COOKED_SERIAL	
		if((DataByte=='\r') || (DataByte=='\n'))
		{
			if(Port==1)
			{
				Serial_TxByte1('\r');
				Serial_TxByte1('\n');
			}
			else
			{
				Serial_TxByte0('\r');
				Serial_TxByte0('\n');
			}
		}
		else
	#endif
	
	if(Port==1)
		Serial_TxByte1(DataByte);
	else
		Serial_TxByte0(DataByte);
	
}

int StdioSerial_TxByte0(char DataByte, FILE *Stream)
{
	StdioSerial_TxByte(DataByte,0);
	return 0;
}

int StdioSerial_TxByte1(char DataByte, FILE *Stream)
{
	StdioSerial_TxByte(DataByte,1);
	return 0;
}

void cls(uint8_t	Port)
{
	if(Port==1)
	{
		log1(ESC_ERASE_DISPLAY);
		log1(ESC_CURSOR_POS(0,0));
	}
	else
	{
		log0(ESC_ERASE_DISPLAY);
		log0(ESC_CURSOR_POS(0,0));
	}
}


void USART_Init0(const uint32_t BaudRate)
{
#ifdef UCSR0A
	UCSR0A = 0;
	UCSR0B = ((1 << RXEN0) | (1 << TXEN0));
	UCSR0C = ((1 << UCSZ01) | (1 << UCSZ00));
	
	UBRR0  = SERIAL_UBBRVAL(BaudRate);
#else
	UCR = ((1 << RXEN)  | (1 << TXEN));
	
	UBRR  	= SERIAL_UBBRVAL(BaudRate);
#endif
}


void USART_Init1(const uint32_t BaudRate)
{
#ifdef UCSR1A
	UCSR1A = 0;
	UCSR1B = ((1 << RXEN1) | (1 << TXEN1));
	UCSR1C = ((1 << UCSZ11) | (1 << UCSZ10));
	
	UBRR1  = SERIAL_UBBRVAL(BaudRate);
#endif
}

/** Transmits a given byte through the USART.
 *
 *  \param DataByte  Byte to transmit through the USART
 */
void Serial_TxByte0(const char DataByte)
{
#ifdef UCSR0A
	while ( !( UCSR0A & (1<<UDRE0)) )		;
	UDR0=DataByte;
#else
	while ( !( USR & (1<<UDRE)) )		;
	UDR=DataByte;
#endif
}

void Serial_TxByte1(const char DataByte)
{
#ifdef UCSR1A
	while ( !( UCSR1A & (1<<UDRE1)) )		;
	UDR1=DataByte;
#endif
}


/** Receives a byte from the USART.
 *
 *  \return Byte received from the USART
 */
char Serial_RxByte0(void)
{
#ifdef UCSR0A
	while (!(USR & (1 << RXC0)))	;
	return UDR0;
#else 
	while (!(USR & (1<<RXC)))	;
	return UDR;
#endif
}

char Serial_RxByte1(void)
{
#ifdef UCSR1A
	while (!(UCSR1A & (1 << RXC1)))	;
	return UDR1;
#else
	return 0;
#endif
}

uint8_t Serial_ByteRecieved0(void)
{
#ifdef UCSR0A
	return (UCSR0A & (1 << RXC0));
#else
	return (USR & (1<<RXC));
#endif
}

uint8_t Serial_ByteRecieved1(void)
{
#ifdef UCSR1A
	return (UCSR1A & (1 << RXC1));
#else
	return 0;
#endif
}

void Serial_Init(const uint32_t BaudRate0,
				 const uint32_t BaudRate1)
{
	if (BaudRate0<=0)
		USART_Init0(DefaultBaudRate);
	else
		USART_Init0(BaudRate0);

	if (BaudRate1<=0)
		USART_Init1(DefaultBaudRate);
	else
		USART_Init1(BaudRate1);
		
	cls(0);
	cls(1);
	
	log0("stdio initialised\n");
	log0("compiled at %s on %s\n",__TIME__,__DATE__);
	
	log0("SerialPort0\n");
	log1("SerialPort1\n");
}

#ifdef USE_HEXDUMP
void HexDump(const uint8_t 	*Buff, 
				   uint16_t Length,
				   uint8_t	Port)
{
	char		LineBuff[80];
	char		*LineBuffPos;
	uint16_t	LineOffset;
	uint16_t	CharOffset;
	const uint8_t		*BuffPtr;
	
	BuffPtr=Buff;
	
	for(LineOffset=0;LineOffset<Length;LineOffset+=16, BuffPtr+=16)
	{
		LineBuffPos=LineBuff;
		LineBuffPos+=sprintf(LineBuffPos,"%4.4X ",LineOffset);
		
		for(CharOffset=0;CharOffset<16;CharOffset++)
		{
			if((LineOffset+CharOffset)<Length)
				LineBuffPos+=sprintf(LineBuffPos,"%2.2X ",BuffPtr[CharOffset]);
			else
			    LineBuffPos+=sprintf(LineBuffPos,"   ");
		}
		
		for(CharOffset=0;CharOffset<16;CharOffset++)
		{
			if((LineOffset+CharOffset)<Length)
			{
				if(isprint(BuffPtr[CharOffset]))
					LineBuffPos+=sprintf(LineBuffPos,"%c",BuffPtr[CharOffset]);
				else
					LineBuffPos+=sprintf(LineBuffPos," ");
			}
			else
				LineBuffPos+=sprintf(LineBuffPos,".");
		}
		switch (Port)
		{
			case 0 : log0("%s\n",LineBuff); break;
			case 1 : log1("%s\n",LineBuff); break;
		}
	}
}

void HexDumpHead(const uint8_t 	*Buff, 
				       uint16_t Length,
				       uint8_t	Port) 
{
	FILE	*File;

	File=&ser0stream;
	
	switch (Port)
	{
		case 0 : File=&ser0stream; break;
		case 1 : File=&ser1stream; break;
	}
	
	fprintf_P(File,PSTR("%d\n"),Buff);

	fprintf_P(File,PSTR("Addr 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F ASCII\n"));
	fprintf_P(File,PSTR("----------------------------------------------------------\n"));

	HexDump(Buff,Length,Port);
};
#else
void HexDump(const uint8_t 	*Buff, 
				   uint16_t Length,
				   uint8_t	Port) {};
void HexDumpHead(const uint8_t 	*Buff, 
				       uint16_t Length,
				       uint8_t	Port) {};
#endif 

#else

void USART_Init0(const uint32_t BaudRate) {};
void Serial_TxByte0(const char DataByte) {};
char Serial_RxByte0(void) {};
uint8_t Serial_ByteRecieved0(void) {};

void USART_Init1(const uint32_t BaudRate) {};
void Serial_TxByte1(const char DataByte) {};
char Serial_RxByte1(void) {};
uint8_t Serial_ByteRecieved1(void) {};

void Serial_Init(const uint32_t BaudRate0,
				 const uint32_t BaudRate1) {};

void cls(uint8_t	Port) {};

void HexDump(const uint8_t 	*Buff, 
				   uint16_t Length,
				   uint8_t	Port) {};
void HexDumpHead(const uint8_t 	*Buff, 
				       uint16_t Length,
				       uint8_t	Port) {};

#endif
