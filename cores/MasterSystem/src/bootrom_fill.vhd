library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use std.textio.all;

entity boot_rom0 is
  generic (
        ADDR_WIDTH       : integer := 14;
        DATA_WIDTH       : integer := 8
    );
  port (
    clk        : in    std_logic;
    RD_n       : in    std_logic;
    A        	: in    std_logic_vector(13 downto 0);
    D_out      : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of boot_rom0 is

   constant MEM_DEPTH : integer := 2**ADDR_WIDTH;

    type mem_type is array (0 to MEM_DEPTH-1) of signed(DATA_WIDTH-1 downto 0);

    impure function init_mem(mif_file_name : in string) return mem_type is
        file mif_file : text open read_mode is mif_file_name;
        variable mif_line : line;
        variable temp_bv : bit_vector(DATA_WIDTH-1 downto 0);
        variable temp_mem : mem_type;
    begin
        for i in mem_type'range loop
            readline(mif_file, mif_line);
            read(mif_line, temp_bv);
            temp_mem(i) := signed(to_stdlogicvector(temp_bv));
        end loop;
        return temp_mem;
    end function;

    shared variable mem : mem_type := init_mem("boot.mif");
  
 begin
 

  p_rom : process
  begin
    wait until rising_edge(clk);
    if (RD_n = '0') then --1
       D_out <= std_logic_vector(mem(to_integer(unsigned(A))));
    end if;
  end process;
end RTL;
