--
-- (C) Alvaro Lopes <alvieboy@alvie.com> All Rights Reserved
--
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity sid_filters is
port (
	clk         : in  std_logic; -- At least 12Mhz
	rst         : in  std_logic;
	-- SID registers.
	Fc_lo       : in  std_logic_vector(7 downto 0);
	Fc_hi       : in  std_logic_vector(7 downto 0);
	Res_Filt    : in  std_logic_vector(7 downto 0);
	Mode_Vol    : in  std_logic_vector(7 downto 0);
	-- Voices - resampled to 13 bit
	voice1      : in  signed(12 downto 0);
	voice2      : in  signed(12 downto 0);
	voice3      : in  signed(12 downto 0);
	--
	input_valid : in  std_logic;
	ext_in      : in  signed(12 downto 0);

	sound       : out signed(18 downto 0);
	valid       : out std_logic
);
end entity;

architecture beh of sid_filters is

	alias filt        : std_logic_vector(3 downto 0) is Res_Filt(3 downto 0);
	alias res         : std_logic_vector(3 downto 0) is Res_Filt(7 downto 4);
	alias volume      : std_logic_vector(3 downto 0) is Mode_Vol(3 downto 0);
	alias hp_bp_lp    : std_logic_vector(2 downto 0) is Mode_Vol(6 downto 4);
	alias voice3off   : std_logic is Mode_Vol(7);

	constant mixer_DC : integer := -475; -- NOTE to self: this might be wrong.

	type regs_type is record
		Vhp   : signed(17 downto 0);
		Vbp   : signed(17 downto 0);
		dVbp  : signed(17 downto 0);
		Vlp   : signed(17 downto 0);
		dVlp  : signed(17 downto 0);
		Vi    : signed(17 downto 0);
		Vnf   : signed(17 downto 0);
		Vf    : signed(17 downto 0);
		w0    : signed(17 downto 0);
		q     : signed(17 downto 0);
		vout  : signed(18 downto 0);
		state : integer;
		done  : std_logic;
	end record;

	signal addr : integer range 0 to 2047;
	signal val  : std_logic_vector(15 downto 0);

	type divmul_t is array(0 to 15) of integer;
	constant divmul: divmul_t := (
		1448, 1323, 1218, 1128, 1051, 984, 925, 872, 825, 783, 745, 710, 679, 650, 624, 599
	);

	signal r : regs_type;

	signal mula  : signed(17 downto 0);
	signal mulb  : signed(17 downto 0);
	signal mulr  : signed(35 downto 0);
	signal mulen : std_logic;

	function s13_to_18(a: in signed(12 downto 0)) return signed is
	begin
		return a(12)&a(12)&a(12)&a(12)&a(12)&a;
	end function;

	signal fc : std_logic_vector(10 downto 0);

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if mulen='1' then
				mulr <= mula * mulb;
			end if;
		end if;
	end process;

	fc <= Fc_hi & Fc_lo(2 downto 0);

	c: entity work.sid_coeffs
	port map (
		clk   => clk,
		addr  => addr,
		val   => val
	);

	addr <= to_integer(unsigned(fc));

	process(clk, rst, r, input_valid, val, filt, voice1, voice2, voice3, voice3off, mulr, ext_in, hp_bp_lp, Mode_Vol)
		variable w: regs_type;
	begin
		w:=r;
		mula <= (others => 'X');
		mulb <= (others => 'X');
		mulen <= '0';

		case r.state is
			when 0 =>
				w.done := '0';
				if input_valid = '1' then
					w.state := 1;
					-- Reset Vin, Vnf
					w.vi := (others => '0');
					w.vnf := (others => '0');
				end if;

			when 1 =>
				w.state := 2;
				-- already have W0 ready. Always positive
				w.w0 := "00" & signed(val);
				-- 1st accumulation
				if filt(0)='1' then
					w.vi := r.vi + s13_to_18(voice1);
				else
					w.vnf := r.vnf + s13_to_18(voice1);
				end if;

			when 2 =>
				w.state := 3;
				-- 2nd accumulation
				if filt(1)='1' then
					w.vi := r.vi + s13_to_18(voice2);
				else
					w.vnf := r.vnf + s13_to_18(voice2);
				end if;
				-- Mult
				mula <= r.w0;
				mulb <= r.vhp;
				mulen <= '1';

			when 3 =>
				w.state := 4;
				-- 3rd accumulation
				if filt(2)='1' then
					w.vi := r.vi + s13_to_18(voice3);
				else
					if voice3off='0' then
						w.vnf := r.vnf + s13_to_18(voice3);
					end if;
				end if;
				-- Mult
				mula <= r.w0;
				mulb <= r.vbp;
				mulen <= '1';
				w.dVbp := mulr(35) & mulr(35 downto 19);

			when 4 =>
				w.state := 5;
				-- 4th accumulation
				if filt(3)='1' then
					w.vi := r.vi + s13_to_18(ext_in);
				else
					w.vnf := r.vnf + s13_to_18(ext_in);
				end if;
				w.dVlp := mulr(35) & mulr(35 downto 19);
				w.Vbp := r.Vbp - r.dVbp;
				-- Get Q, synchronous.
				w.q := to_signed(divmul(to_integer(unsigned(res))), 18);

			when 5 =>
				w.state := 6;
				-- Ok, we have all summed. We performed multiplications for dVbp and dVlp.
				-- new Vbp already computed.
				mulen <= '1';
				mula <= r.q;
				mulb <= r.Vbp;
				w.vlp := r.Vlp - r.dVlp;
				-- Start computing output;
				if hp_bp_lp(1)='1' then
					w.Vf := r.Vbp;
				else
					w.Vf := (others => '0');
				end if;

			when 6 =>
				w.state := 7;
				-- Adjust Vbp*Q, shift by 10
				w.Vhp := (mulr(35)&mulr(26 downto 10)) - r.vlp;
				if hp_bp_lp(0)='1' then
					w.Vf := r.Vf + r.Vlp;
				end if;

			when 7 =>
				w.state := 8;
				w.Vhp := r.Vhp - r.Vi;

			when 8 =>
				w.state := 9;
				if hp_bp_lp(2)='1' then
					w.Vf := r.Vf + r.Vhp;
				end if;

			when 9 =>
				w.state := 10;
				w.Vf := r.Vf + r.Vnf;

			when 10 =>
				w.state := 11;
				-- Add mixer DC
				w.Vf := r.Vf + to_signed(mixer_DC, r.Vf'LENGTH);

			when 11 =>
				w.state := 12;
				-- Process volume
				mulen <= '1';
				mula <= r.Vf;
				mulb <= (others => '0');
				mulb(3 downto 0) <= signed(volume);

			when 12 =>
				w.state := 0;
				w.done := '1';
				w.vout(18) := mulr(35);
				w.vout(17 downto 0) := mulr(17 downto 0);

			when others => null;
		end case;

		if rst='1' then
			w.done := '0';
			w.state := 0;
			w.Vlp := (others => '0');
			w.Vbp := (others => '0');
			w.Vhp := (others => '0');
		end if;

		if rising_edge(clk) then
			r<=w;
		end if;
	end process;

	sound <= r.vout;
	valid <= r.done;

end beh;
