#include "interrupts.h"

extern void (*_inthandler_fptr)();

void SetIntHandler(void(*handler)())
{
	_inthandler_fptr=handler;
}


int GetInterrupts()
{
	return(HW_INTERRUPT(REG_INTERRUPT_CTRL));
}


void EnableInterrupts()
{
	HW_INTERRUPT(REG_INTERRUPT_CTRL)=1;
}


void DisableInterrupts()
{
	HW_INTERRUPT(REG_INTERRUPT_CTRL)=0;
}

