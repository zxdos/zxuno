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

ENTITY sdram_statemachine IS
generic
(
	ADDRESS_WIDTH : natural := 22;
	ROW_WIDTH : natural := 12;
	AP_BIT : natural := 10;
	COLUMN_WIDTH : natural := 8
);
PORT 
( 
	CLK_SYSTEM : IN STD_LOGIC;
	CLK_SDRAM : IN STD_LOGIC; -- this is a exact multiple of system clock
	RESET_N : in STD_LOGIC;
	
	-- interface as though SRAM - this module can take care of caching/write combining etc etc. For first cut... nothing. TODO: What extra info would help me here?
	DATA_IN : in std_logic_vector(31 downto 0);
	ADDRESS_IN : in std_logic_vector(ADDRESS_WIDTH downto 0); -- 1 extra bit for byte alignment
	READ_EN : in std_logic; -- if no reads pending may be a good time to do a refresh
	WRITE_EN : in std_logic;
	REQUEST : in std_logic; -- set true to request
	BYTE_ACCESS : in std_logic; -- ldqm/udqm set based on a(0) - if 0=0111, if 1=1011. Data fields valid:7 downto 0.
	WORD_ACCESS : in std_logic; -- ldqm/udqm set based on a(0) - if 0=0011, if 1=1001. Data fields valid:15 downto 0.
	LONGWORD_ACCESS : in std_logic; -- a(0) ignored. lqdm/udqm mask is 0000
	REFRESH : in std_logic;

	COMPLETE : out std_logic;
	DATA_OUT : out std_logic_vector(31 downto 0);

	-- sdram itself
	SDRAM_ADDR : out std_logic_vector(ROW_WIDTH-1 downto 0);
	SDRAM_DQ : inout std_logic_vector(15 downto 0);
	SDRAM_BA0 : out std_logic;
	SDRAM_BA1 : out std_logic;
	
	SDRAM_CKE : out std_logic;
	SDRAM_CS_N : out std_logic;
	SDRAM_RAS_N : out std_logic;
	SDRAM_CAS_N : out std_logic;
	SDRAM_WE_N : out std_logic;
	
	SDRAM_ldqm : out std_logic; -- low enable, high disable - for byte addressing - NB, cas latency applies to reads
	SDRAM_udqm : out std_logic;
	
	reset_client_n : out std_logic
);
END sdram_statemachine;

ARCHITECTURE vhdl OF sdram_statemachine IS
	function repeat(N: natural; B: std_logic) 
	return std_logic_vector
	is
	variable result: std_logic_vector(1 to N);
	begin
	for i in 1 to N loop
	result(i) := B;
	end loop;
	return result;
	end;

	-- bits are: CS_n, RAS_n, CAS_n,WE_n
	constant sdram_command_inhibit                  : std_logic_vector(3 downto 0) := "1000";
	constant sdram_command_no_operation             : std_logic_vector(3 downto 0) := "0111";
	constant sdram_command_device_burst_stop        : std_logic_vector(3 downto 0) := "0110";
	constant sdram_command_read                     : std_logic_vector(3 downto 0) := "0101";
	constant sdram_command_write                    : std_logic_vector(3 downto 0) := "0100";
	constant sdram_command_bank_activate            : std_logic_vector(3 downto 0) := "0011"; -- activate copies cells to buffer for reading/writing
	constant sdram_command_precharge                : std_logic_vector(3 downto 0) := "0010"; -- precharge copies cells from buffer back to dram
	constant sdram_command_mode_register            : std_logic_vector(3 downto 0) := "0000"; -- e.g. burst length etc
	constant sdram_command_refresh                  : std_logic_vector(3 downto 0) := "0001"; -- must be in idle state - call 4096 times in 64ms
	
	signal command_next : std_logic_vector(3 downto 0);
	
--	constant bank_state_idle                 : std_logic_vector(3 downto 0) := "0000";
--	constant bank_state_row_active           : std_logic_vector(3 downto 0) := "0001";
--	constant bank_state_read                 : std_logic_vector(3 downto 0) := "0010";
--	constant bank_state_write                : std_logic_vector(3 downto 0) := "0011";
--	constant bank_state_read_pre             : std_logic_vector(3 downto 0) := "0100";
--	constant bank_state_write_pre            : std_logic_vector(3 downto 0) := "0101";
--	constant bank_state_precharging          : std_logic_vector(3 downto 0) := "0111";
--	constant bank_state_row_activating       : std_logic_vector(3 downto 0) := "1000";
--	constant bank_state_write_recovering     : std_logic_vector(3 downto 0) := "1001";
--	constant bank_state_write_recovering_pre : std_logic_vector(3 downto 0) := "1010";
--	constant bank_state_refresh              : std_logic_vector(3 downto 0) := "1011";
--	constant bank_state_mode_access          : std_logic_vector(3 downto 0) := "1100"; 
--	constant bank_state_init                 : std_logic_vector(3 downto 0) := "1101"; 
-- Banks each have their own state, but since read/write lines are shared they are not truly independent
-- Also for auto-refresh all banks must be in idle state

	constant sdram_state_powerup        : std_logic_vector(2 downto 0) := "000"; -- requires standard init
	constant sdram_state_init           : std_logic_vector(2 downto 0) := "001"; -- requires standard init
	constant sdram_state_idle           : std_logic_vector(2 downto 0) := "010"; -- ready to start a new request
	constant sdram_state_refresh        : std_logic_vector(2 downto 0) := "011"; -- processing a refresh
	constant sdram_state_read           : std_logic_vector(2 downto 0) := "100"; -- processing a read request
	constant sdram_state_write          : std_logic_vector(2 downto 0) := "101"; -- processing a write request
	constant sdram_state_init_precharge : std_logic_vector(2 downto 0) := "110";
	
	signal sdram_state_next : std_logic_vector(2 downto 0);
	signal sdram_state_reg : std_logic_vector(2 downto 0);
	
	signal delay_next : std_logic_vector(13 downto 0);
	signal delay_reg : std_logic_vector(13 downto 0);
	
	signal cycles_since_refresh_next : std_logic_vector(10 downto 0);
	signal cycles_since_refresh_reg : std_logic_vector(10 downto 0); -- we expect a refresh about every 2000 cycles (approx 8ns each) - if this overflows we store the pending refresh below
	
	signal refresh_pending_next : std_logic_vector(11 downto 0);
	signal refresh_pending_reg : std_logic_vector(11 downto 0); -- valid to do all 4096 once per 64ms
	
	signal suggest_refresh : std_logic; -- i.e. do we have any pending?
	signal force_refresh : std_logic; -- i.e. do we NEED to refresh - up to 64ms...
	signal require_refresh : std_logic; -- i.e. we NEED to refresh or we have some pending and the client says it is a good time	
	signal refreshing_now : std_logic;
	
	signal idle_priority : std_logic_vector(3 downto 0);

	signal data_out_next : std_logic_vector(31 downto 0);
	signal data_out_reg : std_logic_vector(31 downto 0);
	
	signal reply_next : std_logic;
	signal reply_reg : std_logic;
	
	-- track the active bank
	-- Since we're often processing the same 512 bytes can keep the bank active and just read/write within it?
	-- CAS,NOP,NOP,DATA
	-- Perhaps if we're smart this can be access in one system clk cycle (4x slower than our one)
	--signal bank_row_next : array( downto 0) of std_logic_vector(ROW_WIDTH-1 downto 0);
	--signal bank_row_reg : array( downto 0) of std_logic_vector(ROW_WIDTH-1 downto 0);
	
	-- capture inputs
	signal DATA_IN_snext      : std_logic_vector(31 downto 0);
	signal DATA_IN_sreg       : std_logic_vector(31 downto 0);
	signal ADDRESS_IN_snext   : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
	signal ADDRESS_IN_sreg    : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
	signal READ_EN_snext      : std_logic; -- if no reads pending may be a good time to do a refresh
	signal READ_EN_sreg       : std_logic; -- if no reads pending may be a good time to do a refresh
	signal WRITE_EN_snext     : std_logic;
	signal WRITE_EN_sreg      : std_logic;	
	signal dqm_mask_snext     : std_logic_vector(3 downto 0);
	signal dqm_mask_sreg      : std_logic_vector(3 downto 0);
	signal request_snext      : std_logic;
	signal request_sreg       : std_logic;
	signal refresh_snext      : std_logic;
	signal refresh_sreg       : std_logic;
	
	-- slow clock output regs
	signal DATA_OUT_snext     : std_logic_vector(31 downto 0);
	signal DATA_OUT_sreg      : std_logic_vector(31 downto 0);
	
	signal reply_snext : std_logic;
	signal reply_sreg  : std_logic;
	
	-- sdram output registers 
	signal addr_next : std_logic_vector(ROW_WIDTH-1 downto 0);
	signal dq_out_next : std_logic_vector(15 downto 0);
	signal dq_output_next : std_logic;
	signal dq_in_next  : std_logic_vector(15 downto 0);	
	signal ba_next : std_logic_vector(1 downto 0);
	signal cs_n_next : std_logic;
	signal ras_n_next : std_logic;
	signal cas_n_next : std_logic;
	signal we_n_next : std_logic;
	signal ldqm_next : std_logic;
	signal udqm_next : std_logic;
	signal cke_next : std_logic;
	
	signal addr_reg : std_logic_vector(ROW_WIDTH-1 downto 0);
	signal dq_out_reg : std_logic_vector(15 downto 0);
	signal dq_output_reg : std_logic;
	signal ba_reg : std_logic_vector(1 downto 0);
	signal cs_n_reg : std_logic;
	signal ras_n_reg : std_logic;
	signal cas_n_reg : std_logic;
	signal we_n_reg : std_logic;
	signal ldqm_reg : std_logic;
	signal udqm_reg : std_logic;
	signal cke_reg : std_logic;
	
	signal sdram_request_reg : std_logic;
	signal sdram_request_next : std_logic;
	
	signal reset_client_n_reg : std_logic;
	signal reset_client_n_next : std_logic;
	
BEGIN
	-- register
	process(CLK_SDRAM,reset_n)
	begin
		if (reset_N = '0') then
			sdram_state_reg <= sdram_state_init;
			delay_reg <= (others=>'0');
			refresh_pending_reg <= (others=>'0');
			cycles_since_refresh_reg <= (others=>'0');
			data_out_reg <= (others=>'0');
			reply_reg <= '0';
			
			addr_reg <= (others => '0');
			dq_out_reg <= (others=> '0');
			dq_output_reg <= '0';
			ba_reg <= (others=>'0');
			cs_n_reg <= '0';
			ras_n_reg <= '0';
			cas_n_reg <= '0';
			we_n_reg <= '0';
			ldqm_reg <= '0';
			udqm_reg <= '0';
			cke_reg <= '0';
			
			--bank_row_reg <= (others=>(others=>'0'));
		elsif (CLK_SDRAM'event and CLK_SDRAM='1') then
			sdram_state_reg <= sdram_state_next;
			delay_reg <= delay_next;
			refresh_pending_reg <= refresh_pending_next;
			cycles_since_refresh_reg <= cycles_since_refresh_next;
			data_out_reg <= data_out_next;
			reply_reg <= reply_next;
			
			addr_reg <= addr_next;
			dq_out_reg <= dq_out_next;
			dq_output_reg <= dq_output_next;
			ba_reg <= ba_next;
			cs_n_reg <= cs_n_next;
			ras_n_reg <= ras_n_next;
			cas_n_reg <= cas_n_next;
			we_n_reg <= we_n_next;
			ldqm_reg <=ldqm_next;
			udqm_reg <= udqm_next;
			cke_reg <= cke_next;
			
			--bank_row_reg <= bank_row_next;
		end if;
	end process;

	-- register request	
	process(CLK_SYSTEM,reset_n)
	begin
		if (reset_N = '0') then
			data_in_sreg <= (others=>'0');
			address_in_sreg <= (others=>'0');
			read_en_sreg <= '0';
			write_en_sreg <= '0';
			request_sreg <= '0';
			dqm_mask_sreg <= (others=>'1');
			refresh_sreg <= '0';
			
			data_out_sreg <= (others=>'0');
			reply_sreg <= '0';
			
			sdram_request_reg <= '0';
			
			reset_client_n_reg <= '0';
			
		elsif (CLK_SYSTEM'event and CLK_SYSTEM='1') then
			data_in_sreg <= data_in_snext;
			address_in_sreg <= address_in_snext;
			read_en_sreg <= read_en_snext;
			write_en_sreg <= write_en_snext;
			request_sreg <= request_snext;
			dqm_mask_sreg <= dqm_mask_snext;
			refresh_sreg <= refresh_snext;
			
			data_out_sreg <= data_out_snext;
			reply_sreg <= reply_snext;
			
			sdram_request_reg <= sdram_request_next;
			
			reset_client_n_reg <= reset_client_n_next;
		end if;
	end process;

	-- Inputs - NB, clocked at a smaller multiple
	process(data_in_sreg, address_in_sreg, read_en_sreg, write_en_sreg, request_sreg, dqm_mask_sreg, refresh_sreg, data_in, address_in, read_en, write_en, sdram_request_next, byte_access, word_access, longword_access, refresh)
	begin
		data_in_snext <= data_in_sreg;
		address_in_snext <= address_in_sreg;
		read_en_snext <= read_en_sreg;
		write_en_snext <= write_en_sreg;
		request_snext <= request_sreg;
		dqm_mask_snext <= dqm_mask_sreg;
		
		refresh_snext <= refresh; -- independent of memory requests
	
		-- only snap inputs on new request
		-- in theory I could keep the requests in a fifo so I can handle several without waiting - processed in order
		if ((sdram_request_next xor request_sreg) = '1') then
			data_in_snext <= data_in;
			address_in_snext <= address_in(ADDRESS_WIDTH downto 1);
			read_en_snext <= read_en;
			write_en_snext <= write_en;
			request_snext <= sdram_request_next;
			
			dqm_mask_snext(0) <= (byte_access or word_access) and address_in(0); -- masked on misaligned byte or word
			dqm_mask_snext(1) <= (byte_access) and not(address_in(0)); -- masked on aligned byte only
			dqm_mask_snext(2) <= byte_access or (word_access and not(address_in(0))); -- masked on aligned word or byte
			dqm_mask_snext(3) <= not(longword_access); -- masked for everything except long word access
		end if;
	end process;
	
	-- refresh counters
	process(cycles_since_refresh_reg, refresh_pending_reg, refresh_sreg, refreshing_now, force_refresh, suggest_refresh)
	begin
		cycles_since_refresh_next <= std_logic_vector(unsigned(cycles_since_refresh_reg)+1);
		refresh_pending_next <= refresh_pending_reg;
		suggest_refresh <= '0';
		force_refresh <= '0';
		
		if (refresh_pending_reg > X"000") then -- refresh_pending updates before refresh completes
			suggest_refresh <= '1';
		end if;
		
		if (refresh_pending_reg = X"FFF") then
			force_refresh <= '1';
		end if;
		
		require_refresh <= force_refresh or (suggest_refresh and refresh_sreg);
		
		if (refreshing_now = '1') then
			-- refreshing right now
			cycles_since_refresh_next <= (others=>'0');
			
			-- This is one of our pending refreshes (if we have any)			
			if (suggest_refresh = '1') then
				refresh_pending_next <= std_logic_vector(unsigned(refresh_pending_reg) -1);
			end if;
		else
			if (cycles_since_refresh_reg = "11111111111") then
				refresh_pending_next <= std_logic_vector(unsigned(refresh_pending_reg) +1);
				cycles_since_refresh_next <= (others=>'0');
			end if;
		end if;

	end process;
	
	--
	process(reset_client_n_reg,sdram_state_reg,delay_reg, idle_priority, data_out_reg, read_en_sreg, write_en_sreg, address_in_sreg, data_in_sreg, reply_reg, require_refresh, dq_in_next, dqm_mask_sreg, request_sreg)
	begin
		idle_priority <= (others=>'0');
		refreshing_now <= '0';
	
		reset_client_n_next <= reset_client_n_reg;
	
		sdram_state_next <= sdram_state_reg;
		
		command_next <= sdram_command_no_operation;
		
		delay_next <= std_logic_vector(unsigned(delay_reg) + 1);
		
		data_out_next <= data_out_reg;
		reply_next <= reply_reg;
		
		-- Set some default for when we're sending NOP
		dq_out_next <= (others=>'0');
		dq_output_next <= '0';
		cke_next <= '1';
		ldqm_next <= '1';
		udqm_next <= '1';
		ba_next <= (others=>'0');
		addr_next <= (others=>'1');

		-- TODO - use bank states!!
		-- TODO - MUCH MORE SMART STUFF!
		-- Lets do them once we have Hello World running...
		case sdram_state_reg is
		when sdram_state_powerup =>			
			-- wait 100us (min)
			if (delay_reg(13) = '1') then
				sdram_state_next <= sdram_state_init_precharge;
				delay_next <= (others=>'0');
			end if;			
		when sdram_state_init =>			
			case delay_reg(5 downto 3)&delay_reg(0) is
			when "0001" =>
				command_next <= sdram_command_precharge;
				addr_next(AP_BIT) <= '1'; --all banks
			when "0010" =>
				command_next <= sdram_command_refresh;				
				-- cke still high, so auto refresh
			when "0100" =>
				command_next <= sdram_command_refresh;
				-- cke still high, so auto refresh
			when "1000" =>
				command_next <= sdram_command_mode_register;
				--addr_next(2 downto 0) <= (others=>'0'); -- burst single cycle for now
				addr_next(2 downto 0) <= "001"; -- two cycle burst to fetch word-aligned 32-bit, misaligned 16-bit, misaligned 8-bit
				addr_next(3) <= '0'; -- sequential
				addr_next(6 downto 4) <= "011"; -- cas latency 3 cycles
				addr_next(8 downto 7) <= "00"; -- standard operation
				addr_next(9) <= '0'; -- programmed burst access - of single cycle!
				addr_next(11 downto 10) <= "00"; -- reserved
			when "1010" =>
				sdram_state_next <= sdram_state_idle;
				delay_next <= (others=>'0');
			when others =>
				-- nop
			end case;
		when sdram_state_idle =>
			reset_client_n_next <= '1';		
			delay_next <= (others=>'0');						
			
			idle_priority <= (request_sreg xor reply_reg)&require_refresh&write_en_sreg&read_en_sreg;
			case idle_priority is -- priority encoder...
			when "0100"|"0101"|"0110"|"0111"|"1100"|"1101"|"1110"|"1111" =>
				sdram_state_next <= sdram_state_refresh;
			when "1010"|"1011" =>				
				sdram_state_next <= sdram_state_write;
			when "1001" =>
				sdram_state_next <= sdram_state_read;
			when others =>
				-- stay here
			end case;
		when sdram_state_read =>
			-- TODO - if same bank we can save some time... ?
			-- Only do precharge on switching bank?
				
			case delay_reg(3 downto 0) is
			when X"0" =>
				command_next <= sdram_command_bank_activate;
				ba_next <= address_in_sreg(ADDRESS_WIDTH-1 downto ADDRESS_WIDTH-2);
				addr_next <= address_in_sreg(ADDRESS_WIDTH-3 downto ADDRESS_WIDTH-3-ROW_WIDTH+1);
			when X"3" => -- after t_rcd (18ns issi, 21ns psc) i.e. 3 cycles - beware of t_ras (6 cycles before auto-precharge)
				command_next <= sdram_command_read;
				ba_next <= address_in_sreg(ADDRESS_WIDTH-1 downto ADDRESS_WIDTH-2);
				addr_next(COLUMN_WIDTH-1 downto 0) <= address_in_sreg(ADDRESS_WIDTH-3-ROW_WIDTH downto 0);
				addr_next(AP_BIT) <= '1'; -- auto-precharge
				
			when X"4" =>  -- command actually sent now
				ldqm_next <= dqm_mask_sreg(0);  -- for first read
				udqm_next <= dqm_mask_sreg(1);
			
			when X"5" =>  -- dqm for 1st read is sent
				ldqm_next <= dqm_mask_sreg(2); -- for 2nd read
				udqm_next <= dqm_mask_sreg(3);				
			when X"7" => 
				data_out_next(7 downto 0) <= (dq_in_next(7 downto 0) and not(repeat(8,dqm_mask_sreg(0)))) or (dq_in_next(15 downto 8) and repeat(8,dqm_mask_sreg(0)));
				data_out_next(15 downto 8) <= dq_in_next(15 downto 8);				
			when X"8" => -- auto-precharge starts here after cas cycles (at this speed issi can do 2, psc can do 3 -> use slowest)
				data_out_next(15 downto 8) <= (dq_in_next(7 downto 0) and repeat(8,dqm_mask_sreg(0))) or (data_out_reg(15 downto 8) and not(repeat(8,dqm_mask_sreg(0))));
				data_out_next(31 downto 16) <= dq_in_next(15 downto 0);
				
				reply_next <= request_sreg;
				sdram_state_next <= sdram_state_idle;
				-- after 3 cycles we can do the next ACT (21 ns psc)
				-- TODO - directly switch to next action so as not to waste a cycle
			when others =>
			end case;				
		when sdram_state_write =>
			case delay_reg(3 downto 0) is
			when X"0" =>
				command_next <= sdram_command_bank_activate;
				ba_next <= address_in_sreg(ADDRESS_WIDTH-1 downto ADDRESS_WIDTH-2);
				addr_next <= address_in_sreg(ADDRESS_WIDTH-3 downto ADDRESS_WIDTH-3-ROW_WIDTH+1);
			when X"3" => -- after t_rcd (18ns issi, 21ns psc) i.e. 3 cycles - before of t_ras (6 cycles before auto-precharge)
				command_next <= sdram_command_write; 
				ba_next <= address_in_sreg(ADDRESS_WIDTH-1 downto ADDRESS_WIDTH-2);
				addr_next(COLUMN_WIDTH-1 downto 0) <= address_in_sreg(ADDRESS_WIDTH-3-ROW_WIDTH downto 0);
				addr_next(AP_BIT) <= '1'; -- auto-precharge
				
				dq_output_next <= '1';
				dq_out_next(7 downto 0) <= data_in_sreg(7 downto 0);
				dq_out_next(15 downto 8) <= (data_in_sreg(15 downto 8) and not(repeat(8,dqm_mask_sreg(0)))) or (data_in_sreg(7 downto 0) and repeat(8,dqm_mask_sreg(0)));
				ldqm_next <= dqm_mask_sreg(0);
				udqm_next <= dqm_mask_sreg(1);
			when X"4" =>
				dq_output_next <= '1';
				dq_out_next(7 downto 0) <= (data_in_sreg(23 downto 16) and not(repeat(8,dqm_mask_sreg(0)))) or (data_in_sreg(15 downto 8) and repeat(8,dqm_mask_sreg(0)));
				dq_out_next(15 downto 8) <= data_in_sreg(31 downto 24);
				ldqm_next <= dqm_mask_sreg(2);
				udqm_next <= dqm_mask_sreg(3);

				reply_next <= request_sreg;				
			when X"6" => -- after 3 cycles we can do the next ACT (21 ns psc)
				sdram_state_next <= sdram_state_idle;		
				-- TODO - directly switch to next action to match read
			when others =>
			end case;				
		when sdram_state_refresh =>
			case delay_reg(3 downto 0) is
			when X"0" =>
				command_next <= sdram_command_refresh;
				-- cke still high, so auto refresh
				refreshing_now <= '1';
			when X"8" =>
				sdram_state_next <= sdram_state_idle;
			when others =>
			end case;
		when others =>
			sdram_state_next <= sdram_state_init;			
		end case;
	end process;
	
	-- command_next directly translates to lines to send
	-- NB command_next is send ON NEXT CLOCK - so we get a clean clk->q with no combinational logic
	process(command_next)
	begin
		cs_n_next <= command_next(3);
		ras_n_next <= command_next(2);
		cas_n_next <= command_next(1);
		we_n_next <= command_next(0);
	end process;
	
	-- outputs to SDRAM - because timing is tight these SHOULD ALL BE DIRECT FROM REGISTERS
	SDRAM_ADDR <= addr_reg;
	SDRAM_DQ <= dq_out_reg when dq_output_reg='1' else (others=>'Z');
	SDRAM_BA0 <= ba_reg(0);
	SDRAM_BA1 <= ba_reg(1);
	SDRAM_CS_N <= cs_n_reg;
	SDRAM_RAS_N <= ras_n_reg;
	SDRAM_CAS_N <= cas_n_reg;
	SDRAM_WE_N <= we_n_reg;
	SDRAM_ldqm <= ldqm_reg;
	SDRAM_udqm <= udqm_reg;
	SDRAM_CKE <= cke_reg;
	
	-- inputs from SDRAM
	dq_in_next <= SDRAM_DQ;
	
	-- back to slower clock
	reply_snext <= reply_reg;
	data_out_snext <= data_out_reg;
	
	-- outputs to rest of system
	--REPLY <= reply_sreg;
	DATA_OUT <= DATA_OUT_sreg;

	-- a little sdram glue - move to sdram wrapper?
	COMPLETE <= (reply_sreg xnor sdram_request_reg) and not(request);
	sdram_request_next <= sdram_request_reg xor request;
	
	reset_client_n <= reset_client_n_reg;
	
END vhdl;
