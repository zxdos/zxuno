---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY reg_file IS
generic
(
	BYTES : natural := 1;
	WIDTH : natural := 1
);
PORT 
( 
	CLK : IN STD_LOGIC;
	ADDR : IN STD_LOGIC_VECTOR(width-1 DOWNTO 0);
	DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	WR_EN : IN STD_LOGIC;
	
	DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
END reg_file;

ARCHITECTURE vhdl OF reg_file IS
	component complete_address_decoder IS
	generic (width : natural := 1);
	PORT 
	( 
		addr_in : in std_logic_vector(width-1 downto 0);	
		
		addr_decoded : out std_logic_vector((2**width)-1 downto 0)
	);
	END component;

	type reg_file_type is array(bytes-1 downto 0) of std_LOGIC_VECTOR(7 downto 0);

	signal digit_next : reg_file_type;
	signal digit_reg : reg_file_type;
	
	signal addr_decoded : std_logic_vector(2**width-1 downto 0);
BEGIN
	complete_address_decoder1 : complete_address_decoder
		generic map (width => WIDTH)
		port map (addr_in => addr, addr_decoded => addr_decoded);

	-- next state logic
	process(digit_reg,addr_decoded,data_in,WR_EN)
	begin
		digit_next <= digit_reg;
		
		if (WR_EN = '1') then		
			comp_gen:
			for i in 0 to (BYTES-1) loop
				if (addr_decoded(i) = '1') then				
					digit_next(i) <= data_in;
				end if;
			end loop;		
		end if;
	end process;
	
	-- register
	process(clk)
	begin
		if (clk'event and clk='1') then
			digit_reg <= digit_next;
		end if;
	end process;
	
	-- output
	process(addr_decoded,digit_reg)
	begin
		data_out <= X"FF";
		comp_gen:
		for i in 0 to (BYTES-1) loop
			if (addr_decoded(i) = '1') then				
				data_out <= digit_reg(i);
			end if;
		end loop;	
	end process;
		
END vhdl;