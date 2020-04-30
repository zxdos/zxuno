library ieee, work;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.ddr_sdr_conf_pkg.all;

entity z80ddr_if is
   port (
		clk_i : in std_logic;
		rst_i : in std_logic;
	
	-- for host
		maddr   : in std_logic_vector(15 downto 0):= x"ffff";
		mdata_i : in std_logic_vector( 7 downto 0); 
		mdata_o : out std_logic_vector(7 downto 0);	
		mwe	  : in std_logic; 
		mrd     : in std_logic;
	-- from ddr
		busy 			: in std_logic;
	   data_valid 	: in std_logic;
		data_req 	: in std_logic;
		
	-- for sdram controller
		addr_i : out std_logic_vector(27 downto 0);
		dat_i  : out std_logic_vector(31 downto 0);
		dat_o  : in std_logic_vector(31 downto 0);  --output from ddr controller 
		cmd    : out std_logic_vector(1 downto 0);   -- rd,we to ddr controller
		count_led  : out std_logic_vector(7 downto 0);
      cmd_valid : out std_logic		
	 );
end;

architecture behave of z80ddr_if is

   --type MYSTATE_TYPE is (idle, start_write, write, wait_write_ack, start_read, read, wait_read_ack, init, init_read, init_ack, done);
	type MYSTATE_TYPE is (idle, write, wait_write_ack, read, wait_read_ack, done);
   signal mystate         : MYSTATE_TYPE;
   
--	type CMD_TYPE is (NOP_CMD, RD_CMD, WR_CMD);
 --  signal cmd_r         : CMD_TYPE;

 
  signal addr_i_r	: std_logic_vector(27 downto 0); 
  signal dat_i_r  : std_logic_vector(31 downto 0);
  signal cmd_r	: std_logic_vector(1 downto 0);
  signal cmd_valid_r : std_logic;
  
  signal mdata_o_r : std_logic_vector(31 downto 0);
  signal busy_r : std_logic;
  
  signal initial : std_logic :='0';
 -- signal count_led : std_logic_vector(7 downto 0);
  signal count : std_logic_vector(7 downto 0) :="00000000";

begin
		
	mdata_o <= mdata_o_r(7 downto 0);   	
	dat_i   <= dat_i_r;
	addr_i  <= addr_i_r;
	cmd     <= cmd_r;
   cmd_valid <= cmd_valid_r;
		
		
	process (clk_i, rst_i) is	
		begin
		if (clk_i'event and clk_i='1') then
			if rst_i='1' then
				mystate <= idle;
				addr_i_r <= (others => '1');
				cmd_r <= "00"; --NOP_CMD;
				cmd_valid_r <='0';
				count <= "00000000";
			end if;
			
			case mystate is
			
--				when idle =>                    
--					if (mrd='1' and initial='1') then
--						mystate <= read; --start_read;
--					 else if (mwe='1' and initial='1') then
--						mystate <= write; --start_write;
--						else if initial='1' and mrd='0' and mwe='0' then
--						mystate <= idle;
--						else
--						mystate <= init;
--					  end if;
--						end if;
--					end if ;

				when idle =>      				
					if (mrd='1') then
					   count <= count + 1;
						mystate <= read; --start_read;
					 else if (mwe='1') then
					  -- count_led <= count_led+1;
						mystate <= write; --start_write;
						else 
						mystate <= idle;
						count <= "00000000";
						end if;
					  end if ;				
				
--				when start_write =>
--				   cmd_valid_r <='0';
--					addr_i_r <=  "00000000" & maddr(15 downto 9) & "000" & maddr(8 downto 0) & '0'; --MT46V32M16
--					mystate <= write;
--					
				when write  =>
				   addr_i_r <=  "00000000" & maddr(15 downto 9) & "000" & maddr(8 downto 0) & '0'; --MT46V32M16
               mystate <= wait_write_ack;     
					cmd_r <= "10"; --WR_CMD;
					cmd_valid_r <= '1';
					dat_i_r <= x"00" & mdata_i & x"00" & mdata_i;	

				when wait_write_ack =>
					if data_req = '1' then --busy?
						mystate <= done;
					else
						mystate <= wait_write_ack;
					end if;	
							
--				when start_read =>
--					cmd_valid_r <='0';
--					addr_i_r <=  "00000000" & maddr(15 downto 9) & "000" & maddr(8 downto 0) & '0'; --MT46V32M16
--					mystate <= read;
					
				when read =>
				   addr_i_r <=  "00000000" & maddr(15 downto 9) & "000" & maddr(8 downto 0) & '0'; --MT46V32M16
					cmd_r <= "01"; -- RD_CMD;
					cmd_valid_r <= '1';
					count <= count + 1;
					mystate <= wait_read_ack ;

				when wait_read_ack =>
				   count <= count + 1;
					if data_valid='1' then --busy ?
						mdata_o_r <= dat_o;
						mystate <= done;
					else
						mystate <= wait_read_ack;
					end if;
--------------------------------------------------------------
--- Do 1 read to initialise the ddr controller----------------
--				when init =>
--					cmd_valid_r <='0';
--					addr_i_r <= x"f000000"  ;  --any ddr addr (28 bit)
--					mystate <= init_read;
--					
--				when init_read =>
--					cmd_r <= "01"; -- RD_CMD;
--					cmd_valid_r <= '1';
--					mystate <= init_ack ;
--			   
--				when init_ack =>
--					if data_valid='1' then --busy ?
--						--mdata_o_r <= dat_o; -- discard the data
--						mystate <= done;
--						initial <= '1';
--					else
--						mystate <= init_ack;
--					end if;
					
----------------------------------------------------------------------					
				when done =>
				   count_led <= count+1;
					mystate <= idle;
					cmd_valid_r <='0';
				when others =>
					mystate <= idle;
			end case;
		end if;
	end process;
  end;
