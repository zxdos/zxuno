library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity saa5050_rom_dual_port is
    generic (
        ADDR_WIDTH       : integer := 12;
        DATA_WIDTH       : integer := 8
    );
    port(
        clock    : in  std_logic;
        addressA : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        QA       : out std_logic_vector(DATA_WIDTH-1 downto 0);
        addressB : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        QB       : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end saa5050_rom_dual_port;

architecture RTL of saa5050_rom_dual_port is

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

    shared variable mem : mem_type := init_mem("saa5050_rom.mif");
  
 begin
 
--    process(clock) is
--    begin
--        if (rising_edge(clock)) then
--            QA <= std_logic_vector(mem(to_integer(unsigned(addressA))));
--        end if;
--    end process;
--
--    process(clock) is
--    begin
--        if (rising_edge(clock)) then    
--            QB <= std_logic_vector(mem(to_integer(unsigned(addressB))));
--        end if;
--    end process;

			QA <= std_logic_vector(mem(to_integer(unsigned(addressA))));
			QB <= std_logic_vector(mem(to_integer(unsigned(addressB))));

end RTL;
