#ifndef MENU_H
#define MENU_H

enum menu_entry_type {
	MENU_ENTRY_NULL,
	MENU_ENTRY_TOGGLE,
	MENU_ENTRY_CALLBACK,
	MENU_ENTRY_CYCLE,
	MENU_ENTRY_SUBMENU,
	MENU_ENTRY_SLIDER
};

#define ROW_LINEUP -1
#define ROW_LINEDOWN -2
#define ROW_PAGEUP -3
#define ROW_PAGEDOWN -4

typedef int menu_action;
#define MENU_ACTION(x) ((int)(x))
#define MENU_ACTION_TOGGLE(x) x
#define MENU_ACTION_CYCLE(x) x
#define MENU_ACTION_SLIDER(x) x
#define MENU_ACTION_CALLBACK(x) ((void (*)(int row))x)
#define MENU_ACTION_SUBMENU(x) ((struct menu_entry *)(x))

#define MENU_CYCLE_VALUE(x) (*(char *)(&(x)->action))
#define MENU_CYCLE_COUNT(x) (*((char *)(&(x)->action)+3))

#define MENU_SLIDER_VALUE(x) (*(char *)(&(x)->action))
#define MENU_SLIDER_MAX(x) (*((char *)(&(x)->action)+3))

struct menu_entry
{
	enum menu_entry_type type;
	char *label;
	menu_action action;	
};

struct hotkey
{
	int key;
	void (*callback)(int row);
};


void Menu_Show();
void Menu_Hide();
void Menu_Draw();
void Menu_Set(struct menu_entry *head);
void Menu_SetHotKeys(struct hotkey *head);
int Menu_Run(); // Returns the menu's visibility
struct menu_entry *Menu_Get();

extern int menu_toggle_bits;
#define MENU_TOGGLE_VALUES menu_toggle_bits

extern int joya,joyb;

#endif
