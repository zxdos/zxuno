#include <stdio.h>
#include <math.h>

#define GAMMA 0.75

int main()
{
	FILE *f;
	int i,v;
	double x;
	
	f = fopen ("compressor_lut.hex", "wt");
	for (i=0;i<256;i++)
	{
		if (i<=186)
		{
			x = i/186.0;
			v = 255*pow(x,GAMMA);
		}
		else
			v = 255;
		printf ("%4d -> %4d\n", i, v);
		fprintf (f, "%.2X\n", v);
	}
	fclose (f);
	return 0;
}
