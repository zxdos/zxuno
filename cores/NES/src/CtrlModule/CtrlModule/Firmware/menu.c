#include "osd.h"
#include "menu.h"
#include "keyboard.h"


int joya;
int joyb;

static struct menu_entry *menu;
static int menu_visible=0;
int menu_toggle_bits=0;
static int menurows;
static int currentrow;
static struct hotkey *hotkeys;

struct menu_entry *Menu_Get()
{
	return(menu);
}

void Menu_Show()
{
	OSD_Show(menu_visible=1);
}

void Menu_Hide()
{
	// Wait for key releases before hiding the menu, to avoid stray keyup messages reaching the host core.
	while(TestKey(KEY_ESC) || TestKey(KEY_ENTER))
		HandlePS2RawCodes();
	OSD_Show(menu_visible=0);
}


static void DrawSlider(struct menu_entry *m)
{
	int i;
	for(i=0;i<=MENU_SLIDER_MAX(m);++i) // One extra character to leave a space before the label
	{
		OSD_Putchar(i<MENU_SLIDER_VALUE(m) ? 0x07 : 0x20);
	}
}


void Menu_Draw()
{
	struct menu_entry *m=menu;
	OSD_Clear();
	menurows=0;
	while(m->type!=MENU_ENTRY_NULL)
	{
		int i;
		char **labels;
		OSD_SetX(2);
		OSD_SetY(menurows);
		switch(m->type)
		{
			case MENU_ENTRY_CYCLE:
				i=MENU_CYCLE_VALUE(m);	// Access the first byte
				labels=(char**)m->label;
				OSD_Puts("\x16 ");
				OSD_Puts(labels[i]);
				break;
			case MENU_ENTRY_SLIDER:
				DrawSlider(m);
				OSD_Puts(m->label);
				break;
			case MENU_ENTRY_TOGGLE:
				if((menu_toggle_bits>>MENU_ACTION_TOGGLE(m->action))&1)
					OSD_Puts("\x14 ");
				else
					OSD_Puts("\x15 ");
				// Fall through
			default:
				OSD_Puts(m->label);
				break;
		}
		++menurows;
		m++;
	}
}


void Menu_Set(struct menu_entry *head)
{
	menu=head;
	Menu_Draw();
	currentrow=menurows-1;
}


void Menu_SetHotKeys(struct hotkey *head)
{
	hotkeys=head;
}

int Menu_Run()
{
	int i;
	struct menu_entry *m=menu;
	struct hotkey *hk=hotkeys;

	if(TestKey(KEY_ESC)&2)
	{
		while(TestKey(KEY_ESC))
			HandlePS2RawCodes(); // Wait for KeyUp message before opening OSD, since this disables the keyboard for the MSX core.
		OSD_Show(menu_visible^=1);
	}

	joya=0;
	joyb=0;

	if(!menu_visible)	// Swallow any keystrokes that occur while the OSD is hidden...
	{
		if(TestKey(KEY_ENTER))
			joya|=0x80;
		if(TestKey(KEY_RSHIFT))
			joya|=0x40;
		if(TestKey(KEY_RCTRL))
			joya|=0x10;
		if(TestKey(KEY_ALTGR))
			joya|=0x20;
		if(TestKey(KEY_UPARROW))
			joya|=0x01;
		if(TestKey(KEY_DOWNARROW))
			joya|=0x02;
		if(TestKey(KEY_LEFTARROW))
			joya|=0x04;
		if(TestKey(KEY_RIGHTARROW))
			joya|=0x08;

		if(TestKey(KEY_CAPSLOCK))
			joyb|=0x80;
		if(TestKey(KEY_LSHIFT))
			joyb|=0x40;
		if(TestKey(KEY_LCTRL))
			joyb|=0x10;
		if(TestKey(KEY_ALT))
			joyb|=0x20;
		if(TestKey(KEY_W))
			joyb|=0x01;
		if(TestKey(KEY_S))
			joyb|=0x02;
		if(TestKey(KEY_A))
			joyb|=0x04;
		if(TestKey(KEY_D))
			joyb|=0x08;

		//q
		if(TestKey(KEY_1))
			Start();

		if(TestKey(KEY_2))
			Select();
		// master reset
		if ((TestKey(KEY_LCTRL) || TestKey(KEY_RCTRL)) && (TestKey(KEY_ALT) || TestKey(KEY_ALTGR)) && TestKey(KEY_BACKSP) ) 
		{
			masterReset();
		}
		//q

		TestKey(KEY_PAGEUP);
		TestKey(KEY_PAGEDOWN);

		return;
	}

	// master reset
	if ((TestKey(KEY_LCTRL) || TestKey(KEY_RCTRL)) && (TestKey(KEY_ALT) || TestKey(KEY_ALTGR)) && TestKey(KEY_BACKSP) ) 
	{
		masterReset();
	}

	if(TestKey(KEY_UPARROW)&2)
	{
		if(currentrow)
			--currentrow;
		else if((m+menurows)->action)
			MENU_ACTION_CALLBACK((m+menurows)->action)(ROW_LINEUP);
	}
	if(TestKey(KEY_DOWNARROW)&2)
	{
		if(currentrow<(menurows-1))
			++currentrow;
		else if((m+menurows)->action)
			MENU_ACTION_CALLBACK((m+menurows)->action)(ROW_LINEDOWN);
	}

	if(TestKey(KEY_PAGEUP)&2)
	{
		if(currentrow)
			currentrow=0;
		else if((m+menurows)->action)
			MENU_ACTION_CALLBACK((m+menurows)->action)(ROW_PAGEUP);
	}

	if(TestKey(KEY_PAGEDOWN)&2)
	{
		if(currentrow<(menurows-1))
			currentrow=menurows-1;
		else if((m+menurows)->action)
			MENU_ACTION_CALLBACK((m+menurows)->action)(ROW_PAGEDOWN);
	}

	// Find the currently highlighted menu item
	i=currentrow;
	while(i)
	{
		++m;
		--i;
	}

	OSD_SetX(2);
	OSD_SetY(currentrow);

	if(TestKey(KEY_LEFTARROW)&2) // Decrease slider value
	{
		switch(m->type)
		{
			case MENU_ENTRY_SLIDER:
				if((--MENU_SLIDER_VALUE(m))&0x80) // <0?
					MENU_SLIDER_VALUE(m)=0;
				DrawSlider(m);
				break;
			default:
				break;
		}
	}

	if(TestKey(KEY_RIGHTARROW)&2) // Increase slider value
	{
		switch(m->type)
		{
			case MENU_ENTRY_SLIDER:
				if((++MENU_SLIDER_VALUE(m))>MENU_SLIDER_MAX(m))
					MENU_SLIDER_VALUE(m)=MENU_SLIDER_MAX(m);
				DrawSlider(m);
				break;
			default:
				break;
		}
	}


	if(TestKey(KEY_ENTER)&2)
	{
		struct menu_entry *m=menu;
		i=currentrow;
		while(i)
		{
			++m;
			--i;
		}
		switch(m->type)
		{
			case MENU_ENTRY_SUBMENU:
				Menu_Set(MENU_ACTION_SUBMENU(m->action));
				break;
			case MENU_ENTRY_CALLBACK:
				MENU_ACTION_CALLBACK(m->action)(currentrow);
				break;
			case MENU_ENTRY_TOGGLE:
				i=1<<MENU_ACTION_TOGGLE(m->action);
				menu_toggle_bits^=i;
				Menu_Draw();
				break;
			case MENU_ENTRY_CYCLE:
				i=MENU_CYCLE_VALUE(m)+1;
				if(i>=MENU_CYCLE_COUNT(m))
					i=0;
				MENU_CYCLE_VALUE(m)=i;
				Menu_Draw();
				break;
			default:
				break;

		}
	}

	while(hk && hk->key)
	{
		if(TestKey(hk->key)&1)	// Currently pressed?
			hk->callback(currentrow);
		++hk;
	}

	for(i=0;i<OSD_ROWS-1;++i)
	{
		OSD_SetX(0);
		OSD_SetY(i);
		OSD_Putchar(i==currentrow ? (i==menurows-1 ? 17 : 16) : 32);
	}

	return(menu_visible);
}

