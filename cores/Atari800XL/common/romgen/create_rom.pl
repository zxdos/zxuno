#!/usr/bin/perl -w
use strict;
use POSIX;

my $length = shift @ARGV;
my $data_max = ($length*8) - 1;
my $filename= shift @ARGV;
my $name = shift @ARGV;
my $fixedsize = shift @ARGV;

#Based on file size
my $filesize = -s $filename;
#print STDERR "$filename is $filesize\n";
my $addr_max = ceil((log($filesize/$length)/log(2)))-1;
if (defined $fixedsize)
{
	$addr_max = $fixedsize-1;
}

my $size_max = 2**($addr_max+1)-1;

my $data = "";
   open(my $FILE, "$filename") or die $!;
   binmode($FILE);

   my $needed = 2**($addr_max+1);
   my $bytes = "";
   while (read($FILE, my $byte, 1)) {
        $bytes .= $byte;
	if ($length == length $bytes)
	{
		$data.= "X\"".unpack('H*', $bytes)."\",\n";
		$bytes = "";
		$needed = $needed-1;
	}
   }

   my $content = "00"x$length;
   for (1..$needed)
   {
       $data.="X\"$content\",\n";
   }
   $data=~s/(.*).$/$1/;

   

   close $FILE;

#X"0200A",X"00300",X"08101",X"04000",X"08601",X"0233A", X"00300",X"08602",X"02310",X"0203B",X"08300",X"04002", X"08201",X"00500",X"04001",X"02500",X"00340",X"00241", X"04002",X"08300",X"08201",X"00500",X"08101",X"00602", X"04003",X"0241E",X"00301",X"00102",X"02122",X"02021", X"00301",X"00102",X"02222",X"04001",X"00342",X"0232B", X"00900",X"00302",X"00102",X"04002",X"00900",X"08201", X"02023",X"00303",X"02433",X"00301",X"04004",X"00301", X"00102",X"02137",X"02036",X"00301",X"00102",X"02237", X"04004",X"00304",X"04040",X"02500",X"02500",X"02500", X"0030D",X"02341",X"08201",X"0400D"

print <<END

--
--ROMsUsingBlockRAMResources.
--VHDLcodeforaROMwithregisteredoutput(template2)
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity $name is
port(
        clock:in std_logic;
        address:in std_logic_vector($addr_max downto 0);
        q:out std_logic_vector($data_max downto 0)
);
end $name;

architecture syn of $name is
        type rom_type is array(0 to $size_max) of std_logic_vector($data_max downto 0);
        signal ROM:rom_type:=
(
	$data
);
        signal rdata:std_logic_vector($data_max downto 0);
begin
        rdata<=ROM(conv_integer(address));

        process(clock)
        begin
                if(clock'event and clock='1')then
                	q<=rdata;
                end if;
        end process;
end syn;
END

