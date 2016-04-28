/* Cut-down, read-only PS/2 handler for OSD code. */

#include "ps2.h"
#include "interrupts.h"
#include "keyboard.h"
#include "host.h"


// We use a simple ring buffer as a PS/2 event queue.

void ps2_ringbuffer_init(struct ps2_ringbuffer *r)
{
	r->in_hw=0;
	r->in_cpu=0;
}


int ps2_ringbuffer_read(struct ps2_ringbuffer *r)
{
	unsigned char result;
	if(r->in_hw==r->in_cpu)
		return(-1);	// No characters ready
	DisableInterrupts();
	result=r->inbuf[r->in_cpu];
	r->in_cpu=(r->in_cpu+1) & (PS2_RINGBUFFER_SIZE-1);
	EnableInterrupts();
	return(result);
}


int ps2_ringbuffer_count(struct ps2_ringbuffer *r)
{
	if(r->in_hw>=r->in_cpu)
		return(r->in_hw-r->in_cpu);
	return(r->in_hw+PS2_RINGBUFFER_SIZE-r->in_cpu);
}

struct ps2_ringbuffer kbbuffer;

static volatile int intflag;


// Interrupt routine.  Any interrupt will trigger this routine, not just PS/2 interrupts
// A side effect of this is that the PS2Wait() function doubles as a WaitVBlank() function
// when there's no keyboard activity.

void PS2Handler()
{
	int kbd;
	int mouse;

	DisableInterrupts();
	
	kbd=HW_PS2(REG_PS2_KEYBOARD);

	if(kbd & (1<<BIT_PS2_RECV))
	{
		kbbuffer.inbuf[kbbuffer.in_hw]=kbd&0xff;
		kbbuffer.in_hw=(kbbuffer.in_hw+1) & (PS2_RINGBUFFER_SIZE-1);
	}

	intflag=0;
	GetInterrupts();	// Clear interrupt bit
	EnableInterrupts();
}


void PS2Wait()
{
	DisableInterrupts();
	intflag=1;
	EnableInterrupts();
	while(intflag)
		;
}


void PS2Init()
{
	ps2_ringbuffer_init(&kbbuffer);
	ClearKeyboard();
	SetIntHandler(&PS2Handler);
}

