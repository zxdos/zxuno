// zpuromgen.c
//
// Program to turn a binary file into a VHDL lookup table.
//   by Adam Pierce
//   29-Feb-2008
//
// This software is free to use by anyone for any purpose.
//
// Modified by Alastair M. Robinson to output 1-bit data rather than 32

#include <unistd.h>
#include <stdio.h>

typedef unsigned char BYTE;

main(int argc, char **argv)
{
       BYTE    opcode[4];
       int     fd;
       int     addr = 0;
       ssize_t s;

// Check the user has given us an input file.
       if(argc < 2)
       {
               printf("Usage: %s <binary_file>\n\n", argv[0]);
               return 1;
       }

// Open the input file.
       fd = open(argv[1], 0);
       if(fd == -1)
       {
               perror("File Open");
               return 2;
       }

       while(1)
       {
       // Read 32 bits.
//               s = read(fd, opcode, 4);
			int i;
               s = read(fd, opcode, 1);
               if(s == -1)
               {
                       perror("File read");
                       return 3;
               }

               if(s == 0)
                       break; // End of file.

       // Output to STDOUT.
//               printf("%6d => x\"%02x%02x%02x%02x\",\n",
//                      addr++, opcode[0], opcode[1],
//                      opcode[2], opcode[3]);
			for(i=0;i<8;++i)
			{
				printf("%6d => \'%d\',\n",
					addr++, opcode[0]&0x80 ? 1 : 0);
				opcode[0]<<=1;
			}
       }

       close(fd);
       return 0;
}

