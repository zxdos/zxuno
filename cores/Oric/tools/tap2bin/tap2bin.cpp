// written by byrtolet@parallel.bas.bg
// this program converst files in oric .tap format to
// files swittable to be written with dos33 program from
// http://www.deater.net/weave/vmwprod/apple/dos33fs.html
// to write binary file do
// dos33 image.dsk B file_binary.bam DOS_FILENAME
// To write basic file do:
// dos33 image.dsk A file_basic.bam DOS_FILENAME



#include <iostream>
#include <fstream>

void writetwobyte(std::ofstream&of, int a)
{
	char ch = a & 0xff;
	of.write(&ch, 1);
	ch = (a >>8) &0xff;
	of.write(&ch, 1);
}

int main(int argc, char **argv)
{
	try{
		if (argc<3)
		{
			std::cerr << "Usage " << argv[0] << " file.tap output_name_base" << std::endl;
			return 1;
		}
		std::string tap_file = argv[1];
		std::string filename_base  = argv[2];

		int filenum = 0;
		std::ifstream file;
		file.exceptions(std::ios::failbit | std::ios::badbit |std::ios::eofbit);
		file.open(tap_file.c_str(), std::ios::binary | std::ios::in);

		while (true) // if more than one tape record
		{
			// 16
			// 16
			//...
			// 16
			// 24
			// 0
			// 0
			// type 0 basic 80 assembler
			// autorun 0 - no  80 basic  c7 assm
			// end addr high
			// end addr lo
			// start addr high
			// start addr lo
			// 0
			// filename up to 16 chars
			// 0
			// data

			char ch;

			// skip sync
			do
			{
				file.read(&ch, 1);
			} while (0x24 != ch);
			file.read(&ch, 1); // first zero
			file.read(&ch, 1); // second zero
			file.read(&ch, 1); // type
			bool basic = ch == 0;
			file.read(&ch, 1); // autostart
			int start_addr = 0;
			int end_addr   = 0;
			file.read(&ch, 1); // autostart
			end_addr = (end_addr << 8) + (unsigned char)ch;
			file.read(&ch, 1); // autostart
			end_addr = (end_addr << 8) + (unsigned char)ch;
			file.read(&ch, 1); // autostart
			start_addr = (start_addr << 8) + (unsigned char)ch;
			file.read(&ch, 1); // autostart
			start_addr = (start_addr << 8) + (unsigned char)ch;
			file.read(&ch, 1); // skip zero

			std::string filename;
			do
			{
				file.read(&ch, 1); // skip zero
				if (ch)
					filename += ch;
			} while (ch);
			int size = end_addr - start_addr + 1;

			filename = filename_base;
			filename += basic ? "_basic" : "_binary";
			filename += std::to_string(filenum);
			filename += ".bam";
			std::cout << "writing " << filename << " " << std::flush;
			std::ofstream of(filename, std::ios::binary |std::ios::out);
			if (!basic)
			{
				writetwobyte(of, start_addr);
				writetwobyte(of, size);
			}else
				writetwobyte(of, size);
				
			for (; size--;)
			{
				file.read(&ch, 1); // skip zero
				of.write(&ch, 1);
			}

			filenum++;
			std::cout << " done." << std::endl;
		}
	} catch (std::exception& e)
	{
		// let's hope it's just endo of file
	}
	return 0;
}
