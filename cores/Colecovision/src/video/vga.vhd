-------------------------------------------------------------------[13.08.2016]
-- VGA
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library IEEE; 
	use IEEE.std_logic_1164.all; 
	use IEEE.std_logic_unsigned.all;
	use IEEE.numeric_std.all;
	
entity vga is
	port (
		I_CLK			: in  std_logic;
		I_CLK_VGA	: in  std_logic;
		I_COLOR		: in  std_logic_vector(3 downto 0);
		I_HCNT		: in  std_logic_vector(8 downto 0);
		I_VCNT		: in  std_logic_vector(7 downto 0);
		O_HSYNC		: out std_logic;
		O_VSYNC		: out std_logic;
		O_COLOR		: out std_logic_vector(3 downto 0);
		O_BLANK		: out std_logic
	);
end vga;

architecture rtl of vga is
	signal pixel_out		: std_logic_vector( 3 downto 0);
	signal addr_rd			: std_logic_vector(15 downto 0);
	signal addr_wr			: std_logic_vector(15 downto 0);
	signal wren				: std_logic;
	signal picture			: std_logic;
	signal window_hcnt	: std_logic_vector( 9 downto 0) := (others => '0');
	signal window_vcnt	: std_logic_vector( 8 downto 0) := (others => '0');
	signal hcnt				: std_logic_vector( 9 downto 0) := (others => '0');
	signal h					: std_logic_vector( 9 downto 0) := (others => '0');
	signal vcnt				: std_logic_vector( 9 downto 0) := (others => '0');
	signal hsync			: std_logic;
	signal vsync			: std_logic;
	signal blank			: std_logic;

-- ModeLine "640x480@60Hz"  25,175  640  656  752  800 480 490 492 525 -HSync -VSync
	-- Horizontal Timing constants  
	constant h_pixels_across	: integer := 640 - 1;
	constant h_sync_on			: integer := 656 - 1;
	constant h_sync_off			: integer := 752 - 1;
	constant h_end_count			: integer := 800 - 1;
	-- Vertical Timing constants
	constant v_pixels_down		: integer := 480 - 1;
	constant v_sync_on			: integer := 490 - 1;
	constant v_sync_off			: integer := 492 - 1;
	constant v_end_count			: integer := 525 - 1;

	-- In
	constant hc_max				: integer := 280;
	constant vc_max				: integer := 216;

	constant h_start				: integer := 40;
	constant h_end					: integer := h_start + (hc_max * 2);	-- 64 + (280 * 2) => 64 + 560 = 624
	constant v_start				: integer := 22;
	constant v_end					: integer := v_start + (vc_max * 2);
	
begin
	
	frbuff: entity work.dpram
	generic map (
		addr_width_g	=> 16,
		data_width_g	=> 4
	)
	port map(
		clk_a_i		=> I_CLK,
		data_a_i		=> I_COLOR,
		addr_a_i		=> addr_wr,
		we_i			=> wren,
		data_a_o		=> open,
		--
		clk_b_i		=> I_CLK_VGA,
		addr_b_i		=> addr_rd,
		data_b_o		=> pixel_out
	);

	process (I_CLK_VGA)
	begin
		if I_CLK_VGA'event and I_CLK_VGA = '1' then
			if h = h_end_count then
				h <= (others => '0');
			else
				h <= h + 1;
			end if;
		
			if h = 7 then
				hcnt <= (others => '0');
			else
				hcnt <= hcnt + 1;
				if hcnt = (h_start-1) then
					window_hcnt <= (others => '0');
				else
					window_hcnt <= window_hcnt + 1;
				end if;
			end if;
			if hcnt = h_sync_on then
				if vcnt = v_end_count then
					vcnt <= (others => '0');
				else
					vcnt <= vcnt + 1;
					if vcnt = (v_start-1) then
						window_vcnt <= (others => '0');
					else
						window_vcnt <= window_vcnt + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	process (I_HCNT, I_VCNT, window_hcnt, window_vcnt)
		variable wr_result_v : std_logic_vector(16 downto 0);
		variable rd_result_v : std_logic_vector(16 downto 0);
	begin
		wr_result_v := std_logic_vector((unsigned(I_VCNT)                  * to_unsigned(hc_max, 9)) + unsigned(I_HCNT));
		rd_result_v := std_logic_vector((unsigned(window_vcnt(8 downto 1)) * to_unsigned(hc_max, 9)) + unsigned(window_hcnt(9 downto 1)));
		addr_wr	<= wr_result_v(15 downto 0);
		addr_rd	<= rd_result_v(15 downto 0);
	end process;

	wren		<= '1' when (I_HCNT < hc_max) and (I_VCNT < vc_max) else '0';
--	addr_wr	<= I_VCNT(7 downto 0) & I_HCNT(7 downto 0);
--	addr_rd	<= window_vcnt(8 downto 1) & window_hcnt(8 downto 1);
	blank		<= '1' when (hcnt > h_pixels_across) or (vcnt > v_pixels_down) else '0';
	picture	<= '1' when (blank = '0') and (hcnt > h_start and hcnt < h_end) and (vcnt > v_start and vcnt < v_end) else '0';

	O_HSYNC	<= '1' when (hcnt <= h_sync_on) or (hcnt > h_sync_off) else '0';
	O_VSYNC	<= '1' when (vcnt <= v_sync_on) or (vcnt > v_sync_off) else '0';
	O_COLOR	<= pixel_out when picture = '1' else (others => '0');
	O_BLANK	<= blank;

end rtl;
