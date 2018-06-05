---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY pia IS
PORT 
( 
	CLK : IN STD_LOGIC;
	ADDR : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
	CPU_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	EN : IN STD_LOGIC;
	WR_EN : IN STD_LOGIC;
	
	RESET_N : IN STD_LOGIC;
	
	CA1 : IN STD_LOGIC;
	CB1 : IN STD_LOGIC;	
	
	CA2_DIR_OUT : OUT std_logic;
	CA2_OUT : OUT std_logic;
	CA2_IN : IN STD_LOGIC;

	CB2_DIR_OUT : OUT std_logic;
	CB2_OUT : OUT std_logic;
	CB2_IN : IN STD_LOGIC;
	
	-- remember these two are different if connecting to gpio (push pull vs pull up - check 6520 data sheet...)
	PORTA_DIR_OUT : OUT STD_LOGIC_VECTOR(7 downto 0); -- pull up - i.e. 0 driven only
	PORTA_OUT : OUT STD_LOGIC_VECTOR(7 downto 0); -- set bit to 1 to enable output mode
	PORTA_IN : IN STD_LOGIC_VECTOR(7 downto 0);
	
	PORTB_DIR_OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	PORTB_OUT : OUT STD_LOGIC_VECTOR(7 downto 0); -- push pull
	PORTB_IN : IN STD_LOGIC_VECTOR(7 downto 0); -- push pull
	
	-- CPU interface
	DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		
	IRQA_N : OUT STD_LOGIC;
	IRQB_N : OUT STD_LOGIC
);
END pia;

ARCHITECTURE vhdl OF pia IS
	COMPONENT complete_address_decoder IS
	generic (width : natural := 1);
	PORT 
	( 
		addr_in : in std_logic_vector(width-1 downto 0);			
		addr_decoded : out std_logic_vector((2**width)-1 downto 0)
	);
	END component;
	
	signal addr_decoded : std_logic_vector(3 downto 0);
	
	signal porta_output_next : std_logic_vector(7 downto 0);
	signal porta_output_reg : std_logic_vector(7 downto 0);
	signal porta_input_reg : std_logic_vector(7 downto 0);
	signal porta_input_next : std_logic_vector(7 downto 0);

	signal porta_direction_next : std_logic_vector(7 downto 0);
	signal porta_direction_reg : std_logic_vector(7 downto 0);
	
	signal porta_control_next : std_logic_vector(5 downto 0);
	signal porta_control_reg : std_logic_vector(5 downto 0);
	
	signal portb_output_next : std_logic_vector(7 downto 0);
	signal portb_output_reg : std_logic_vector(7 downto 0);
	signal portb_input_reg : std_logic_vector(7 downto 0);
	signal portb_input_next : std_logic_vector(7 downto 0);	

	signal portb_direction_next : std_logic_vector(7 downto 0);
	signal portb_direction_reg : std_logic_vector(7 downto 0);
	
	signal portb_control_next : std_logic_vector(5 downto 0);
	signal portb_control_reg : std_logic_vector(5 downto 0);
	
	signal irqa_next : std_logic_vector(1 downto 0);
	signal irqa_reg : std_logic_vector(1 downto 0);
	signal irqb_next : std_logic_vector(1 downto 0);
	signal irqb_reg : std_logic_vector(1 downto 0);
	
	signal CA1_reg : std_logic;
	signal CA2_reg : std_logic;
	signal CB1_reg : std_logic;
	signal CB2_reg : std_logic;

	signal CA2_output_next : std_logic;
	signal CA2_output_reg : std_logic;
	signal CB2_output_next : std_logic;
	signal CB2_output_reg : std_logic;
	
	signal read_ora : std_logic;
	signal read_orb : std_logic;
	
	signal write_ora : std_logic;
	signal write_orb : std_logic;

	signal ca1_edge_next : std_logic;
	signal ca1_edge_reg : std_logic;	
	signal ca2_edge_next : std_logic;
	signal ca2_edge_reg : std_logic;
	
	signal cb1_edge_next : std_logic;
	signal cb1_edge_reg : std_logic;	
	signal cb2_edge_next : std_logic;
	signal cb2_edge_reg : std_logic;
	
begin
	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			porta_output_reg <= (others=>'0');
			porta_input_reg <= (others=>'0');
			porta_direction_reg <= (others=>'0'); -- default to input
			porta_control_reg <= (others=>'0');
			
			portb_output_reg <= X"FF"; -- all high to ensure we have OS Rom enabled
			portb_input_reg <= (others=>'0');
			portb_direction_reg <= (others=>'1'); -- default to ouput
			portb_control_reg <= (others=>'0');
			
			irqa_reg <= (others=>'0');
			irqb_reg <= (others=>'0');
			
			CA1_reg	<= '0';
			CA2_reg	<= '0';
			CB1_reg	<= '0';
			CB2_reg	<= '0';
			
			CA2_output_reg <= '0';
			CB2_output_reg <= '0';
			
			ca1_edge_reg <= '0';
			ca2_edge_reg <= '0';
			
			cb1_edge_reg <= '0';
			cb2_edge_reg <= '0';
			
		elsif (clk'event and clk='1') then						
			porta_output_reg <= porta_output_next;
			porta_input_reg <= porta_input_next;
			porta_direction_reg <= porta_direction_next;
			porta_control_reg <= porta_control_next;
			
			portb_output_reg <= portb_output_next;
			portb_input_reg <= PORTB_input_next;
			portb_direction_reg <= portb_direction_next;
			portb_control_reg <= portb_control_next;	
	
			irqa_reg <= irqa_next;
			irqb_reg <= irqb_next;
	
			CA1_reg	<= CA1;
			CA2_reg	<= CA2_in;
			CB1_reg	<= CB1;
			CB2_reg	<= CB2_in;
			
			CA2_output_reg <= CA2_output_next;
			CB2_output_reg <= CB2_output_next;

			ca1_edge_reg <= ca1_edge_next;			
			ca2_edge_reg <= ca2_edge_next;
			
			cb1_edge_reg <= cb1_edge_next;			
			cb2_edge_reg <= cb2_edge_next;			
		end if;
	end process;

	-- decode address
	decode_addr1 : complete_address_decoder
		generic map(width=>2)
		port map (addr_in=>addr, addr_decoded=>addr_decoded);
				
	-- Writes to registers
	process(cpu_data_in,wr_en,addr_decoded, porta_output_reg, portb_output_reg, porta_direction_reg, portb_direction_reg, porta_control_reg, portb_control_reg)
	begin
		porta_output_next <= porta_output_reg;
		portb_output_next <= portb_output_reg;
		porta_direction_next <= porta_direction_reg;
		portb_direction_next <= portb_direction_reg;
		porta_control_next(5 downto 0) <= porta_control_reg(5 downto 0);
		portb_control_next(5 downto 0) <= portb_control_reg(5 downto 0);
		
		write_ora <= '0';
		write_orb <= '0';
		
		if (wr_en = '1') then
			if(addr_decoded(0) = '1') then
				if (porta_control_reg(2) = '1') then
					porta_output_next <= cpu_data_in;
					write_ora <= '1';
				else
					porta_direction_next <= cpu_data_in;
				end if;
			end if;	

			if(addr_decoded(1) = '1') then				
				if (portb_control_reg(2) = '1') then
					portb_output_next <= cpu_data_in;
					write_orb <= '1';
				else
					portb_direction_next <= cpu_data_in;
				end if;			
			end if;						

			if(addr_decoded(2) = '1') then	
				porta_control_next(5 downto 0) <= cpu_data_in(5 downto 0);
			end if;						
			
			if(addr_decoded(3) = '1') then		
				portb_control_next(5 downto 0) <= cpu_data_in(5 downto 0);
			end if;															

		end if;
	end process;
	
	-- Read from registers
	process(addr_decoded, en, porta_input_reg, portb_input_reg, porta_direction_reg, portb_direction_reg, porta_control_reg, portb_control_reg, irqa_reg, irqb_reg)
	begin
		data_out <= X"FF";
		read_ora <= '0';
		read_orb <= '0';

		if (EN = '1') then -- since reads have an effect here...
			if (addr_decoded(0) = '1') then
				if (porta_control_reg(2) = '1') then
					data_out <= porta_input_reg;
					read_ora <= '1';
				else
					data_out <= porta_direction_reg; -- can this be read?
				end if;
			end if;

			if (addr_decoded(1) = '1') then
				if (portb_control_reg(2) = '1') then
					data_out <= portb_input_reg;
					read_orb <= '1';
				else
					data_out <= portb_direction_reg; -- can this be read?
				end if;
			end if;

			if (addr_decoded(2) = '1') then			
				data_out <= irqa_reg(1)&(irqa_reg(0)and not(porta_control_reg(5)))&porta_control_reg;
			end if;

			if (addr_decoded(3) = '1') then			
				data_out <= irqb_reg(1)&(irqb_reg(0)and not(portb_control_reg(5)))&portb_control_reg;
			end if;
		end if;
		
	end process;
	
	-- irq handing
	-- TODO REVIEW, this stuff is complicated! I think Atari does not need it anyway...
	process (irqa_reg, porta_control_next, porta_control_reg, read_ora, write_ora, ca2_output_reg, CA1, CA1_reg, ca2_in, ca2_reg, ca1_edge_reg, ca2_edge_reg)
	begin
		irqa_next(1) <= irqa_reg(1) and not(read_ora);
		irqa_next(0) <= irqa_reg(0) and not(read_ora);
				
		ca2_output_next <= ca2_output_reg;

		if (CA1 = '1' and CA1_reg = '0') then
			irqa_next(1) <= ca1_edge_reg;
		end if;
		if (CA1 = '0' and CA1_reg = '1') then
			irqa_next(1) <= not(ca1_edge_reg);
		end if;
		
		if (CA2_in = '1' and CA2_reg = '0') then
			irqa_next(0) <= ca2_edge_reg;
		end if;
		
		if (CA2_in = '0' and CA2_reg = '1') then
			irqa_next(0) <= not(ca2_edge_reg);
		end if;	
		
		ca1_edge_next <= porta_control_next(0); -- delay 1 cycle, so I am still set to detect falling edge on the rising edge
		ca2_edge_next <= porta_control_next(4); -- delay 1 cycle, so I am still set to detect falling edge on the rising edge
		
		if (porta_control_next(5) = '0') then -- CA2 is an input					
		else -- CA2 is an output
			--irqa_next(0) <= '0';
			
			case porta_control_next(4 downto 3) is
				when "10" =>
					ca2_output_next <= '0'; -- direct control
				when "11" =>
					ca2_output_next <= '1'; -- direct control
				when "01" =>
					if (read_ora = '1') then
						ca2_output_next <= '0';
					else						
						-- clock restore
						ca2_output_next <= '1';
					end if;
				when "00" =>
					if (read_ora = '1') then
						ca2_output_next <= '0';
					elsif (irqa_reg(1) = '1') then
						-- ca1 restore
						ca2_output_next <= '1';	
					end if;				
				when others =>
					-- nop
			end case;					
		end if;

	end process;

	process (irqb_reg, portb_control_next, portb_control_reg, read_orb, write_orb, cb2_output_reg, CB1, CB1_reg, cb2_in, cb2_reg, cb1_edge_reg, cb2_edge_reg)
	begin
		irqb_next(1) <= irqb_reg(1) and not(read_orb);
		irqb_next(0) <= irqb_reg(0) and not(read_orb);
				
		cb2_output_next <= cb2_output_reg;

		if (CB1 = '1' and CB1_reg = '0') then
			irqb_next(1) <= cb1_edge_reg;
		end if;
		if (CB1 = '0' and CB1_reg = '1') then
			irqb_next(1) <= not(cb1_edge_reg);
		end if;
		
		if (CB2_in = '1' and CB2_reg = '0') then
			irqb_next(0) <= cb2_edge_reg;
		end if;
		
		if (CB2_in = '0' and CB2_reg = '1') then
			irqb_next(0) <= not(cb2_edge_reg);
		end if;	
		
		cb1_edge_next <= portb_control_next(0); -- delay 1 cycle, so I am still set to detect falling edge on the rising edge
		cb2_edge_next <= portb_control_next(4); -- delay 1 cycle, so I am still set to detect falling edge on the rising edge
		
		if (portb_control_next(5) = '0') then -- CB2 is an input					
		else -- CB2 is an output
			--irqb_next(0) <= '0';
			
			case portb_control_next(4 downto 3) is
				when "10" =>
					cb2_output_next <= '0'; -- direct control
				when "11" =>
					cb2_output_next <= '1'; -- direct control
				when "01" =>
					if (write_orb = '1') then
						cb2_output_next <= '0';
					else						
						-- clock restore
						cb2_output_next <= '1';
					end if;
				when "00" =>
					if (write_orb = '1') then
						cb2_output_next <= '0';
					elsif (irqb_reg(1) = '1') then
						-- cb1 restore
						cb2_output_next <= '1';	
					end if;				
				when others =>
					--nop
			end case;					
		end if;

	end process;
	
	-- output
		-- TODO - review if ca2 and cb2 are push pull or pull up...
	--ca2 <= CA2_output_reg when porta_control_reg(5) = '1' else 'Z';
	--cb2 <= CB2_output_reg when portb_control_reg(5) = '1' else 'Z';
	ca2_out <= CA2_output_reg;
	ca2_dir_out <= porta_control_reg(5);
	cb2_out <= CB2_output_reg;
	cb2_dir_out <= portb_control_reg(5);
	
	porta_out <= porta_output_reg;
	porta_dir_out <= porta_direction_reg;
	porta_input_next <= porta_in;

	--portb_out <= portb_output_reg;
	-- forced to 1 when in input mode - star raiders relies on this
	portb_out(0) <= portb_output_reg(0) when portb_direction_reg(0)='1' else '1';
	portb_out(1) <= portb_output_reg(1) when portb_direction_reg(1)='1' else '1';
	portb_out(2) <= portb_output_reg(2) when portb_direction_reg(2)='1' else '1';
	portb_out(3) <= portb_output_reg(3) when portb_direction_reg(3)='1' else '1';	
	portb_out(4) <= portb_output_reg(4) when portb_direction_reg(4)='1' else '1';
	portb_out(5) <= portb_output_reg(5) when portb_direction_reg(5)='1' else '1';
	portb_out(6) <= portb_output_reg(6) when portb_direction_reg(6)='1' else '1';
	portb_out(7) <= portb_output_reg(7) when portb_direction_reg(7)='1' else '1';		
	portb_dir_out <= portb_direction_reg;
	portb_input_next <= portb_in;
	
	irqa_n <= not(((irqa_reg(1) and porta_control_reg(0)) or (irqa_reg(0) and porta_control_reg(3))) and not(porta_control_reg(5)));
	irqb_n <= not(((irqb_reg(1) and portb_control_reg(0)) or (irqb_reg(0) and portb_control_reg(3))) and not(portb_control_reg(5)));
	
end vhdl;


