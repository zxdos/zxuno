
library ieee;
use ieee.std_logic_1164.all;

entity genesispad is
	generic (
		clocks_per_1us_g	: integer		:= 2	-- number of clock_i periods during 1us
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		-- Gamepad interface
		pad_p1_i			: in  std_logic;
		pad_p2_i			: in  std_logic;
		pad_p3_i			: in  std_logic;
		pad_p4_i			: in  std_logic;
		pad_p6_i			: in  std_logic;
		pad_p7_o			: out std_logic;
		pad_p9_i			: in  std_logic;
		-- Buttons
		but_up_o			: out std_logic;
		but_down_o		: out std_logic;
		but_left_o		: out std_logic;
		but_right_o		: out std_logic;
		but_a_o			: out std_logic;
		but_b_o			: out std_logic;
		but_c_o			: out std_logic;
		but_x_o			: out std_logic;
		but_y_o			: out std_logic;
		but_z_o			: out std_logic;
		but_start_o		: out std_logic;
		but_mode_o		: out std_logic
	);
end entity;

architecture Behavior of genesispad is

	type state_t is (RESET, IDLE, PULSE1L, PULSE1H, PULSE2L, PULSE2H, PULSE3L, PULSE3H, PULSE4L);
	signal state_q, state_s : state_t;

	signal pass_14u_s		: std_logic;
	signal cnt_14u_q		: integer range 0 to clocks_per_1us_g*14;
	signal cnt_idle_q		: integer range 0 to 720;
	signal but_up_s		: std_logic;
	signal but_down_s		: std_logic;
	signal but_left_s		: std_logic;
	signal but_right_s	: std_logic;
	signal but_a_s			: std_logic;
	signal but_b_s			: std_logic;
	signal but_c_s			: std_logic;
	signal but_x_s			: std_logic;
	signal but_y_s			: std_logic;
	signal but_z_s			: std_logic;
	signal but_start_s	: std_logic;
	signal but_mode_s		: std_logic;

begin

	-- pragma translate_off
	-----------------------------------------------------------------------------
	-- Check generics
	-----------------------------------------------------------------------------
	assert clocks_per_1us_g > 0
		report "clocks_per_1us_g must be at least 1!"
		severity failure;
	-- pragma translate_on

	-- counters
	process (reset_i, clock_i)
	begin
		if reset_i = '1' then
			cnt_14u_q <= 0;
		elsif rising_edge(clock_i) then
			if cnt_14u_q = clocks_per_1us_g*14 then
				cnt_14u_q <= 0;
			else
				cnt_14u_q <= cnt_14u_q + 1;
			end if;
		end if;
	end process;

	pass_14u_s <= '1' when cnt_14u_q = clocks_per_1us_g*14		else '0';

	--
	process (reset_i, clock_i)
	begin
		if reset_i = '1' then
			state_q <= RESET;
			cnt_idle_q <= 0;
		elsif rising_edge(clock_i) then
			if pass_14u_s = '1' then
				state_q <= state_s;
			end if;
			if state_q = IDLE then
				if pass_14u_s = '1' then
					if cnt_idle_q = 720 then
						cnt_idle_q <= 0;
					else
						cnt_idle_q <= cnt_idle_q + 1;
					end if;
				end if;
			else
				cnt_idle_q <= 0;
			end if;
		end if;
	end process;

	process (state_q, cnt_idle_q, pad_p1_i, pad_p2_i, pad_p3_i,
	         pad_p4_i, pad_p6_i, pad_p9_i, but_up_s, but_down_s,
	         but_left_s, but_right_s, but_a_s, but_b_s, but_c_s,
	         but_x_s, but_y_s, but_z_s, but_start_s, but_mode_s)
	begin
		state_s	<= IDLE;
		case state_q is
			when RESET =>
				state_s <= IDLE;
				but_up_s		<= '1';
				but_down_s	<= '1';
				but_left_s	<= '1';
				but_right_s	<= '1';
				but_a_s		<= '1';
				but_b_s		<= '1';
				but_c_s		<= '1';
				but_x_s		<= '1';
				but_y_s		<= '1';
				but_z_s		<= '1';
				but_start_s	<= '1';
				but_mode_s	<= '1';
			when IDLE =>
				pad_p7_o	<= '1';
				if cnt_idle_q = 719 then
					state_s <= PULSE1L;
				end if;
				but_up_o		<= but_up_s;
				but_down_o		<= but_down_s;
				but_left_o		<= but_left_s;
				but_right_o		<= but_right_s;
				but_a_o			<= not but_a_s;
				but_b_o			<= not but_b_s;
				but_c_o			<= not but_c_s;
				but_x_o			<= not but_x_s;
				but_y_o			<= not but_y_s;
				but_z_o			<= not but_z_s;
				but_start_o		<= not but_start_s;
				but_mode_o		<= not but_mode_s;
			when PULSE1L =>
				pad_p7_o	<= '0';
				state_s <= PULSE1H;
			when PULSE1H =>
				pad_p7_o	<= '1';
				state_s <= PULSE2L;
				but_up_s		<= pad_p1_i;
				but_down_s	<= pad_p2_i;
				but_left_s	<= pad_p3_i;
				but_right_s	<= pad_p4_i;
				but_b_s		<= pad_p6_i;
				but_c_s		<= pad_p9_i;
			when PULSE2L =>
				pad_p7_o	<= '0';
				state_s <= PULSE2H;
				but_a_s		<= pad_p6_i;
				but_start_s	<= pad_p9_i;
			when PULSE2H =>
				pad_p7_o	<= '1';
				state_s <= PULSE3L;
			when PULSE3L =>
				pad_p7_o	<= '0';
				state_s <= PULSE3H;
			when PULSE3H =>
				pad_p7_o	<= '1';
				state_s <= PULSE4L;
				but_z_s		<= pad_p1_i;
				but_y_s		<= pad_p2_i;
				but_x_s		<= pad_p3_i;
				but_mode_s	<= pad_p4_i;
			when PULSE4L =>
				pad_p7_o	<= '0';
				state_s <= IDLE;
		end case;
	end process;

end architecture;