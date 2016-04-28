#include "keyboard.h"
#include "ps2.h"

// We maintain a keytable which records which keys are currently pressed
// and which keys have been pressed and possibly released since the last test.
// For this we need 2 bits per key in the keytable.
// We'll use 32-bit ints to store the key statuses
// since that's more convienent for the ZPU.
// index(keycode) = Keycode>>4    (keycode range: 0-255)
// Each 2 bit tuple is shifted by (keycode & 15)*2.

unsigned int keytable[16]={0};

int HandlePS2RawCodes()
{
	int result=0;
	static int keyup=0;
	static int extkey=0;
	int updateleds=0;
	int key;

	while((key=PS2KeyboardRead())>-1)
	{
		if(key==KEY_KEYUP)
			keyup=1;
		else if(key==KEY_EXT)
			extkey=1;
		else
		{
			int keyidx=extkey ? 128+key : key;
			if(keyup)
				keytable[keyidx>>4]&=~(1<<((keyidx&15)*2));  // Mask off the "currently pressed" bit.
			else
				keytable[keyidx>>4]|=3<<((keyidx&15)*2);	// Currently pressed and pressed since last test.
			extkey=0;
			keyup=0;
		}
	}
	return(result);
}


void ClearKeyboard()
{
	int i;
	for(i=0;i<16;++i)
		keytable[i]=0;
}

int TestKey(int rawcode)
{
	int result;
	DisableInterrupts();	// Make sure a new character doesn't arrive halfway through the read
	result=3&(keytable[rawcode>>4]>>((rawcode&15)*2));
	keytable[rawcode>>4]&=~(2<<((rawcode&15)*2));	// Mask off the "pressed since last test" bit.
	EnableInterrupts();
	return(result);
}

