unsigned int SwapBBBB(unsigned int i)
{
	unsigned int result=(i>>24)&0xff;
	result|=(i>>8)&0xff00;
	result|=(i<<8)&0xff0000;
	result|=(i<<24)&0xff00000;
	return(result);
}

unsigned int SwapBB(unsigned int i)
{
	unsigned short result=(i>>8)&0xff;
	result|=(i<<8)&0xff00;
	return(result);
}

unsigned long SwapWW(unsigned long i)
{
	unsigned int result=(i>>16)&0xffff;
	result|=(i<<16)&0xffff0000;
	return(result);
}
