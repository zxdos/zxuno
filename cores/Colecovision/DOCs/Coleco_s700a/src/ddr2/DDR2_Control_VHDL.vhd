---------------------------------------------------------------------
-- File :			DDR2_Control_VHDL.vhd
-- Projekt :		Prj_12_DDR2
-- Zweck :			DDR2-Verwaltung (Init,Read,Write)
-- Datum :        19.08.2011
-- Version :      2.0
-- Plattform :    XILINX Spartan-3A
-- FPGA :         XC3S700A-FGG484
-- Sprache :      VHDL
-- ISE :				ISE-Design-Suite V:13.1
-- Autor :        UB
-- Mail :         Becker_U(at)gmx.de
---------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

	--------------------------------------------
--- Description:
---
--- Which has 512 Mbit DDR2 RAM (64MB) memory
--- Organized in 16-bit words
---
--- There will always read data words of 64 bits
--- Or written (because the burst mode is set to 4)
--- The reason is the data vector for Read / Write
--- 64-bit wide
---
--- The RAM is divided into 4 blocks (each 16Mbyte)
--- Bank "00" to bank "11": 2Bit
---
--- Each block is organized as 8192 rows of 1024 columns
--- ROW - "0000000000000" to "1111111111111": 13Bit
--- COL      "0000000000" to    "1111111111": 10Bit
---
--- The given address to the FIFO component
--- With 25 bit then sits down together so
---
--- Input_adress = ROW & COL & BANK
--- (25Bit) 13Bit 10Bit 2Bit
--- Per address are 16bit data
---
--- In this demo program is only bank = 0
--- COL and ROW = 0 = 0 to 15 using
-----------------------------------------------
---
--- The CONTROL controls the READ and WRITE functions
--- Depending on which button was pressed
---
----------------------------------------------
--- Caution! to address:
--- The burst mode is FIX to "4"
--- It will ALWAYS 4 (16bit) Read cells
--- And described (ie imer 64Bit)
---
--- So if the 64bit word "123456789ABCDEF0" in addr 0
--- Is written, then the memory looks like this:
--- Row 0 Col 0 = "1234"
--- Row 1 Col 0 = "5678"
--- Row 2 Col = 0 "9ABC"
--- Row 0 Col 3 = "DEF0"
---
--- The Col-counter would always be around 4 addresses
--Be incremented / decremented -
---
--- In the demo only the ROW counter is changed
---
	--------------------------------------------

entity DDR2_Control_VHDL is

	--------------------------------------------
	-- Port Deklerationen
	--------------------------------------------
	port (
		reset_in : in std_logic;
		clk_in : in std_logic;
		clk90_in : in std_logic;

		maddr   : in std_logic_vector(15 downto 0);
		mdata_i : in std_logic_vector(7 downto 0);
		data_out : out std_logic_vector(7 downto 0);
		mwe	  : in std_logic;
		mrd    : in std_logic;

		
		init_done : in std_logic;
		command_register : out std_logic_vector(2 downto 0);
		input_adress : out std_logic_vector(24 downto 0);
		input_data : out std_logic_vector(31 downto 0);
		output_data : in std_logic_vector(31 downto 0);
		cmd_ack : in std_logic;
		data_valid : in std_logic;
		burst_done : out std_logic;
		auto_ref_req : in std_logic
	);

end DDR2_Control_VHDL;

architecture Verhalten of DDR2_Control_VHDL is

	--------------------------------------------
	-- Einbinden einer Componente
	-- zum schreiben eines 64Bit Wertes
	--------------------------------------------
	COMPONENT DDR2_Write_VHDL
	PORT (
		reset_in : in std_logic;
		clk_in : in std_logic;
		clk90_in : in std_logic;	
		w_command_register : out std_logic_vector(2 downto 0);
		w_cmd_ack : in std_logic;
		w_burst_done : out std_logic;
		write_en : in std_logic;
		write_busy : out std_logic;
		input_data : out std_logic_vector(31 downto 0);
		write_data : in std_logic_vector(63 downto 0)
	);
	END COMPONENT DDR2_Write_VHDL;
	
	--------------------------------------------
	-- Einbinden einer Componente
	-- zum lesen eines 64Bit Wertes
	--------------------------------------------
	COMPONENT DDR2_Read_VHDL
	PORT (
		reset_in : in std_logic;
		clk_in : in std_logic;
		clk90_in : in std_logic;
		r_command_register : out std_logic_vector(2 downto 0);
		r_cmd_ack : in std_logic;
		r_burst_done : out std_logic;	
		r_data_valid : in std_logic;			
		read_en : in std_logic;
		read_busy : out std_logic;
		output_data : in std_logic_vector(31 downto 0);
		read_data : out std_logic_vector(63 downto 0)
	);
	END COMPONENT DDR2_Read_VHDL;	

	--------------------------------------------
	-- Interne Signale
	--------------------------------------------

	constant INIT_PAUSE : integer := 150000; -- pause 1ms (important!)
	signal v_counter :  natural range 0 to INIT_PAUSE := INIT_PAUSE;	
--	
--	--------------------------------------------
--	-- 16 Konstante Werte erzeugen, die beim INIT
--	-- (Auto-Write) ins RAM geschrieben werden
--	-- ein Wert ist 64Bit = 8 Byte breit
--	--------------------------------------------
--	constant MAX_ADR : integer := 15; -- 0 bis 15 = 16 Werte
--	type RAM_DATA_TYP is array (0 to MAX_ADR) of std_logic_vector(63 downto 0);
--	constant RAM_DATA : RAM_DATA_TYP :=
--	(
--		x"0123456789ABCD69", x"123456789ABCDEF0", x"23456789ABCDEF01", x"3456789ABCDEF012",
--		x"456789ABCDEF0123", x"56789ABCDEF01234", others => (x"639CC6398C7318E7")
--	);
--	signal v_array_pos :  natural range 0 to MAX_ADR+1 := 0;	
	
	--------------------------------------------
	-- Definition der ROW,COL,BANK adressen
	--------------------------------------------
	signal v_ROW : std_logic_vector(12 downto 0):= (others => '0'); -- 13Bit
	signal v_COL : std_logic_vector(9 downto 0):= (others => '0');  -- 10Bit
	signal v_BANK : std_logic_vector(1 downto 0):= (others => '0'); -- 2Bit
	
	-- zwischenspeicher fuer daten
	signal v_write_data : std_logic_vector(63 downto 0):= (others => '0');	
	signal v_read_data : std_logic_vector(63 downto 0):= (others => '0');		
	
	--------------------------------------------
	-- Ein Konstanter Wert, der mit WRITE-Button
	-- ins RAM geschrieben wird
	--------------------------------------------	
--	constant CONST_DATA : std_logic_vector(63 downto 0):= x"31CE629DC43B8877";
	
	--------------------------------------------
	-- State-Machine-Typen
	--------------------------------------------	
	type STATE_M_TYPE is (
		M1_START_UP,
		M2_WAIT_4_DONE,
		M3_AUTO_WRITE_START,
		M4_AUTO_WRITE_INIT,
		M5_AUTO_WRITING,
		M6_AUTO_READ_INIT,
		M7_AUTO_READING,
		M8_NOP,
		M9_WRITE_INIT,
		M10_WRITING,
		M11_READ_INIT,
		M12_READING
	);
	signal STATE_M : STATE_M_TYPE := M1_START_UP;	
		
	--------------------------------------------
	-- sonstige Signale
	--------------------------------------------		
	signal v_write_en : std_logic:='0'; -- '1'=chip-select
	signal v_read_en : std_logic:='0'; -- '1'=chip-select
	signal v_write_busy : std_logic; -- '1'=belegt, '0'=frei
	signal v_read_busy : std_logic; -- '1'=belegt, '0'=frei
	signal v_main_command_register : std_logic_vector(2 downto 0):= (others => '0');
	signal v_write_command_register : std_logic_vector(2 downto 0):= (others => '0');
	signal v_read_command_register : std_logic_vector(2 downto 0):= (others => '0');
	signal v_write_burst_done : std_logic;
	signal v_read_burst_done : std_logic;	
	signal mrd_r : std_logic;	
	signal mwe_r : std_logic;	
	signal m_rd : std_logic;	
	signal m_we : std_logic;	
	
begin

synchro : process (clk_in)
	begin
		mrd_r <= m_rd;
		mwe_r <= m_we;
		m_rd <= mrd;
		m_we <= mwe;
	end process synchro;

	--------------------------------------------------
	-- Instantz einer Componente erzeugen und verbinden
	-- zum schreiben eines 64Bit Wertes
	--------------------------------------------------
	INST_DDR2_Write_VHDL : DDR2_Write_VHDL
	PORT MAP (
		reset_in => reset_in,
		clk_in => clk_in,
		clk90_in => clk90_in,
		w_command_register => v_write_command_register,
		w_cmd_ack => cmd_ack,
		w_burst_done => v_write_burst_done,
		write_en => v_write_en,
		write_busy => v_write_busy,
		input_data => input_data,
		write_data => v_write_data
	);
	
	--------------------------------------------------
	-- Instantz einer Componente erzeugen und verbinden
	-- zum lesen eines 64Bit Wertes
	--------------------------------------------------
	INST_DDR2_Read_VHDL : DDR2_Read_VHDL
	PORT MAP (
		reset_in => reset_in,
		clk_in => clk_in,
		clk90_in => clk90_in,
		r_command_register => v_read_command_register,
		r_cmd_ack => cmd_ack,
		r_burst_done => v_read_burst_done,	
		r_data_valid => data_valid,	
		read_en => v_read_en,
		read_busy => v_read_busy,
		output_data => output_data,
		read_data => v_read_data
	);		

	-----------------------------------------
--- State Machine:
--- 1 waiting 1ms after reset
--- 2 sends the INIT command to the RAM
--- 3 Waiting for the init_done from RAM
--- 4 Write 16 data values ??in RAM
--- 5 Reading Adr0
--- 6 Wait for key press
---
--- 7a. North / South = Change of Address (ROW)
--- 7b. Northeast = read a value
--- 7c. West = write a value
--- 8 Jump to point 6
	-----------------------------------------	
	P_State_Main : process(clk_in,reset_in)
	begin
		if reset_in = '1' then
			-- reset button ist gedrueckt
			STATE_M <= M1_START_UP;
			v_write_en <= '0';
			v_read_en <= '0';
			v_main_command_register <= "000"; -- NOP
			v_counter <= INIT_PAUSE;			
			v_ROW <= (others => '0');	
			v_COL <= (others => '0');
			v_BANK <= (others => '0');
--			v_array_pos	<= 0;
		elsif falling_edge(clk_in) then
			case STATE_M is
			   -----------------------------------------------------
--				- INITIALIZATION from RAM: IMPORTANT! :
--				- After the reset is 1ms and then waited
--				- The INIT command is sent to the RAM
--				- And waited for the Init Done signal from RAM
				-----------------------------------------------------
				when M1_START_UP =>
					-- Wait 1ms after reset ready to RAM
					-- IMPORTANT! this is so in the Data Sheet
					if v_counter = 0 then					
						--Register (for clock) to 1ms INIT command
						STATE_M <= M2_WAIT_4_DONE;
						v_main_command_register <= "010";	-- INIT-CMD	
					else 
						v_main_command_register <= "000"; -- NOP
						v_counter <= v_counter - 1;
					end if;	
				when M2_WAIT_4_DONE =>
					-- Waiting for Init Done signal from RAM
					v_main_command_register <= "000"; -- NOP
					if (init_done = '1') then
						-- The RAM is now ready
						STATE_M <= M8_NOP; -- M3_AUTO_WRITE_START;	
					end if;
			   -----------------------------------------------------
--				- Automatic write of a few values??:
--				- There are 16 fixed data values ??in the addresses 0-15
--				- Written to RAM
				-----------------------------------------------------					
--				when M3_AUTO_WRITE_START =>
--					-- automatisches schreiben von daten ins RAM
--					if v_array_pos > MAX_ADR then
--						-- wenn alle adressen geschrieben sind
--						STATE_M <= M6_AUTO_READ_INIT;
--						v_ROW <= (others => '0');
--					else
--						if v_write_busy = '0' and auto_ref_req = '0' then
--							-- wenn RAM nicht beschäftigt ist, starte das schreiben
--							STATE_M <= M4_AUTO_WRITE_INIT;
--						end if;
--					end if;
--				when M4_AUTO_WRITE_INIT =>					
--					-- warten bis zum schreiben bereit
--					if v_write_busy = '0' and v_write_en='0' then
--						-- daten zum schreiben freigeben
--						v_write_en <= '1';
--					elsif v_write_busy = '1' and v_write_en='1' then
--						-- daten werden geschrieben
--						v_write_en <= '0';
--						STATE_M <= M5_AUTO_WRITING;
--					end if;
--				when M5_AUTO_WRITING =>								
--					-- warte bis schreiben fertig
--					if v_write_busy = '0' then
--						-- naechste adresse beschreiben						
--						v_array_pos <= v_array_pos +1;
--						v_ROW <= v_ROW +1;
--						STATE_M <= M3_AUTO_WRITE_START;
--					end if;	
			   -----------------------------------------------------
--				- Automatic reading of a value:
--				- It is the contents of addr 0 read from RAM
				-----------------------------------------------------					
--				when M6_AUTO_READ_INIT =>
--					-- automatisches lesen vom RAM  (ein wert)
--					-- warten bis zum lesen bereit
--					if v_read_busy = '0' and v_read_en='0' and auto_ref_req = '0' then 
--						-- daten zum lesen freigeben
--						v_read_en <= '1';						
--					elsif v_read_busy = '1' and v_read_en='1' then
--						-- daten werden gelesen
--						v_read_en <= '0';						
--						STATE_M <= M7_AUTO_READING;
--					end if;
--				when M7_AUTO_READING =>
--					-- warte bis lesen fertig
--					if v_read_busy = '0' then						
--						STATE_M <= M8_NOP;
--					end if;					
			   -----------------------------------------------------
--				- Permanent loop: wait for user input:
--				- Here is to wait until one of the four buttons
--					Was pressed -
				-----------------------------------------------------						
				when M8_NOP =>
					-- warte auf Taste fuer READ oder WRITE
					v_write_en <= '0';
					v_read_en <= '0';					
					if mwe_r = '1' and v_write_busy = '0' and auto_ref_req = '0' then
						-- write start (only if not busy and no refresh cycle)
						STATE_M <= M9_WRITE_INIT;
					elsif mrd_r = '1' and v_read_busy = '0' and auto_ref_req = '0' then
						-- read restart (only if not busy and no refresh cycle)
						STATE_M <= M11_READ_INIT;
					end if;					
					-- warte auf Taste fuer Adr-Up oder Adr-Down								
--					if risingedge_in(1)='1' and v_ROW < 255 then
--						-- button = north
--						v_ROW <= v_ROW + 1;
--					elsif risingedge_in(2)='1' and v_ROW > 0 then
--						-- button = south
--						v_ROW <= v_ROW - 1;
--					end if;
			   -----------------------------------------------------
--				- WRITE: Write a value into RAM:
--				- A fixed data value is in the current address
--				- Written to RAM
				-----------------------------------------------------						
				when M9_WRITE_INIT =>					
					-- Wait until ready for writing
					if v_write_busy = '0' and v_write_en='0' then
						-- to write data release
						v_write_en <= '1';
					elsif v_write_busy = '1' and v_write_en='1' then
						-- data to be written
						v_write_en <= '0';
						STATE_M <= M10_WRITING;
					end if;
				when M10_WRITING =>								
					-- wait to finish writing
					if v_write_busy = '0' then
						STATE_M <= M8_NOP;
					end if;
			   -----------------------------------------------------
--				- READ: Read a value from RAM:
--				- The current address is read from RAM
				-----------------------------------------------------						
				when M11_READ_INIT =>					
					-- wait until ready for reading
					if v_read_busy = '0' and v_read_en='0' then 
						-- Share to read data
						v_read_en <= '1';
					elsif v_read_busy = '1' and v_read_en='1' then
						-- data to be read
						v_read_en <= '0';						
						STATE_M <= M12_READING;
					end if;
				when M12_READING =>
					-- wait to finish reading
					if v_read_busy = '0' then						
						STATE_M <= M8_NOP;
					end if;									
				when others =>
					NULL;
			end case;
		end if;
	end process P_State_Main;	
	
	-----------------------------------------
--- Routing of signals
--- Depending on read or write:
	-----------------------------------------	
	P_SIGNAL : process(clk_in)
	begin
		if falling_edge(clk_in) then
--			if STATE_M=M4_AUTO_WRITE_INIT or STATE_M=M5_AUTO_WRITING then
--			   -----------------------------------------------------
--				-- automatic write of a few values
--				-----------------------------------------------------	
--				v_write_data <= RAM_DATA(v_array_pos);							
--				input_adress <= v_ROW & v_COL & v_BANK;
--				command_register <= v_write_command_register;
--				burst_done <= v_write_burst_done;					
--			elsif STATE_M=M6_AUTO_READ_INIT or STATE_M=M7_AUTO_READING then
--			   -----------------------------------------------------
--				-- automatically read from a value
--				-----------------------------------------------------
--				v_write_data <= (others => '0'); 				
--				input_adress <= v_ROW & v_COL & v_BANK;
--				command_register <= v_read_command_register;
--				burst_done <= v_read_burst_done;				
--			elsif STATE_M=M9_WRITE_INIT or STATE_M=M10_WRITING then
			if STATE_M=M9_WRITE_INIT or STATE_M=M10_WRITING then
			   -----------------------------------------------------
				-- WRITE : Write a value to the RAM
				-----------------------------------------------------	
				v_write_data <= x"00000000000000" & mdata_i; -- CONST_DATA;				
				input_adress <=  "00000" & maddr(15 downto 8) & maddr(7 downto 0) & "0000"; --v_ROW & v_COL & v_BANK;
				command_register <= v_write_command_register;
				burst_done <= v_write_burst_done;				
			elsif STATE_M=M11_READ_INIT or STATE_M=M12_READING then
			   -----------------------------------------------------
				-- READ : Read a value from RAM
				-----------------------------------------------------
				v_write_data <= (others => '0'); 				
				input_adress <=  "00000" & maddr(15 downto 8) & maddr(7 downto 0) & "0000";--input_adress <= v_ROW & v_COL & v_BANK;
				command_register <= v_read_command_register;
				burst_done <= v_read_burst_done;				
			else
			   -----------------------------------------------------
				--Permanent loop or INIT oder INIT
				-----------------------------------------------------	
				v_write_data <= (others => '0');				
				input_adress <= (others => '0');				
				command_register <= v_main_command_register;
				burst_done <= '0';				
			end if;
		end if;
	end process P_SIGNAL;
	
	-----------------------------------------
	-- Output of the read data
	-- Depending on the switch position
	-----------------------------------------	
	P_DataOut : process(clk_in,reset_in)
	begin
		if reset_in = '1' then
			-- reset button ist gedrueckt
			data_out <= (others => '0');
		elsif falling_edge(clk_in) and v_read_busy='0' then
		
			data_out <= v_read_data(7 downto 0);
		 
		
--			if debounce_in(7 downto 5)="000" then data_out <= v_read_data(7 downto 0);
--			elsif debounce_in(7 downto 5)="001" then data_out <= v_read_data(15 downto 8);
--			elsif debounce_in(7 downto 5)="010" then data_out <= v_read_data(23 downto 16);
--			elsif debounce_in(7 downto 5)="011" then data_out <= v_read_data(31 downto 24);
--			elsif debounce_in(7 downto 5)="100" then data_out <= v_read_data(39 downto 32);
--			elsif debounce_in(7 downto 5)="101" then data_out <= v_read_data(47 downto 40);
--			elsif debounce_in(7 downto 5)="110" then data_out <= v_read_data(55 downto 48);
--			elsif debounce_in(7 downto 5)="111" then data_out <= v_read_data(63 downto 56);
--			end if;
			-------------------------------------------			
		end if;
	end process P_DataOut;

end Verhalten;

