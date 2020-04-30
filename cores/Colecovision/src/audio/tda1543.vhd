--
-- TDA1543 - I2S Sound
--

library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tda1543 is
	generic (
		chipSMD_g	: boolean := TRUE
	);
	port (
		clock_i			: in    std_logic;
		left_audio_i	: in    std_logic_vector(15 downto 0);
		right_audio_i	: in    std_logic_vector(15 downto 0);

		tda_bck_o		: out   std_logic;
		tda_ws_o			: out   std_logic;
		tda_data_o		: out   std_logic
	);
end entity;

architecture behavior of tda1543 is

	signal offset_s	: integer := 0;	-- 0 = DIP, 7 = SMD

begin

smd: if chipSMD_g generate
	offset_s	<= 7;
end generate;

dip: if not chipSMD_g generate
	offset_s	<= 0;
end generate;

	process (clock_i)
		variable outLeft_v       : unsigned(15 downto 0) := x"0000";
		variable outRight_v      : unsigned(15 downto 0) := x"0000";
		variable outData_v       : unsigned(47 downto 0) := x"000000000000";

		variable leftDataTemp_v  : unsigned(19 downto 0) := x"00000";
		variable rightDataTemp_v : unsigned(19 downto 0) := x"00000";

		variable tdaCounter_v    : unsigned(7 downto 0) := "00000000";
		variable skipCounter_v   : unsigned(7 downto 0) := x"00";
		
	begin
		if rising_edge(clock_i) then

			if tdaCounter_v = 48 * 2 then
				tdaCounter_v := x"00";

				outRight_v := rightDataTemp_v( 19 downto 4 );
				rightDataTemp_v := x"00000";

				outLeft_v := leftDataTemp_v( 19 downto 4 );
				leftDataTemp_v := x"00000";

				outRight_v(15) := not outRight_v(15);
				outLeft_v(15) := not outLeft_v(15);

				outData_v := unsigned( x"00" & std_logic_vector(outRight_v( 15 downto 0 )) & x"00" & std_logic_vector(outLeft_v( 15 downto 0 )) );

			end if;
			
			if tdaCounter_v(0) = '0' then
    			
				tda_data_o <= outData_v( 47 );
				outData_v := outData_v( 46 downto 0 ) & "0";

				-- para TDA1543 (DIP) usar offset 0, para TDA1543T (SMD) usar offset 7
				if tdaCounter_v( 7 downto 1 ) = 0 + offset_s then
					tda_ws_o <= '1';
				elsif tdaCounter_v( 7 downto 1 ) = 24 + offset_s then
					tda_ws_o <= '0';
				end if;

				if skipCounter_v >= 2 then
							
					rightDataTemp_v := rightDataTemp_v + unsigned( right_audio_i );
					leftDataTemp_v  := leftDataTemp_v  + unsigned( left_audio_i );
					skipCounter_v   := x"00";					
					
				else
				
					skipCounter_v := skipCounter_v + 1;
					
				end if;
			
			end if;
		
			tda_bck_o 		<= tdaCounter_v(0);
			tdaCounter_v	:= tdaCounter_v + 1;
			
		end if;
	end process;

end architecture;