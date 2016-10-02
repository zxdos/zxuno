library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity ula is
	port
	(
		cpuClock   : in  std_logic;
		iorq       : in  std_logic;
		rd         : in  std_logic;
		wr         : in  std_logic;
		a0         : in  std_logic;
		di         : in  std_logic_vector( 7 downto 0);
		do         : out std_logic_vector( 7 downto 0);
		--
		vramClock  : in  std_logic;
		vramData   : in  std_logic_vector( 7 downto 0);
		vramAddr   : out std_logic_vector(12 downto 0);
		int        : out std_logic;
		v          : out std_logic;
		h          : out std_logic;
		r          : out std_logic;
		g          : out std_logic;
		b          : out std_logic;
		i          : out std_logic;
		--
		ear        : in  std_logic;
		mic        : out std_logic;
		speaker    : out std_logic;
		--
		rows       : in  std_logic_vector(15 downto 8);
		boot       : out std_logic;
		reset      : out std_logic;
		nmi        : out std_logic;
		ps2        : inout std_logic_vector(1 downto 0)
	);
end;

architecture behavioral of ula is

	signal received    : std_logic;
	signal scancode    : std_logic_vector(7 downto 0);
	signal keys        : std_logic_vector(4 downto 0);

	signal border      : std_logic_vector(2 downto 0);

	signal hCount      : std_logic_vector(8 downto 0) := (others => '0');
	signal vCount      : std_logic_vector(8 downto 0) := (others => '0');
	signal fCount      : std_logic_vector(4 downto 0) := (others => '0');

	signal hSync       : std_logic;
	signal vSync       : std_logic;

	signal dataInp     : std_logic_vector(7 downto 0);
	signal dataOut     : std_logic_vector(7 downto 0);

	signal attrInp     : std_logic_vector(7 downto 0);
	signal attrMux     : std_logic_vector(7 downto 3);
	signal attrOut     : std_logic_vector(7 downto 0);

	signal dataEnable  : std_logic;
	signal videoBlank  : std_logic;
	signal videoEnable : std_logic;

	signal dataInpLoad : std_logic;
	signal dataOutLoad : std_logic;

	signal attrInpLoad : std_logic;
	signal attrOutLoad : std_logic;

	signal dataSelect  : std_logic;

begin

	Ups2 : entity work.ps2 port map
	(
		clockPs2 => vramClock, -- 7 MHz
		clock    => ps2(0),
		data     => ps2(1),
		received => received,
		scancode => scancode
	);
	Ukeyboard : entity work.keyboard port map
	(
		received => received,
		scancode => scancode,
		boot     => boot,
		reset    => reset,
		nmi      => nmi,
		cols     => keys,
		rows     => rows
	);

	process(cpuClock)
	begin
		if falling_edge(cpuClock)
		then
			do <= attrOut;

			if iorq = '0' and a0 = '0'
			then
				if wr = '0'
				then
					border  <= di(2 downto 0);
					mic     <= di(3);
					speaker <= di(4);
				elsif rd = '0'
				then
					do <= '0'&ear&'0'&keys;
				end if;
			end if;
		end if;
	end process;

	process(vramClock)
	begin
		if falling_edge(vramClock)
		then
			if hCount < 447
			then
				hCount <= hCount+1;
			else
				hCount <= (others => '0');

				if vCount < 311
				then
					vCount <= vCount+1;
				else
					vCount <= (others => '0');
					fCount <= fCount+1;
				end if;
			end if;

			if hCount >= 344 and hCount <= 375 then hSync <= '0'; else hSync <= '1'; end if;
			if vCount >= 248 and vCount <= 251 then vSync <= '0'; else vSync <= '1'; end if;

			if vCount = 248 and hCount >= 2 and hCount <= 65 then int <= '0'; else int <= '1'; end if;
		end if;
	end process;

	process(vramClock)
	begin
		if falling_edge(vramClock)
		then
			dataInpLoad <= hCount(0) and not hCount(1) and hCount(3) and videoEnable;
			dataOutLoad <= not hCount(0) and not hCount(1) and hCount(2) and videoEnable;

			attrInpLoad <= hCount(0) and hCount(1) and hCount(3) and videoEnable;
			attrOutLoad <= hCount(0) and not hCount(1) and hCount(2);

			dataSelect <= dataOut(7) xor (fCount(4) and attrOut(7));

			if hCount(3) = '1' then videoEnable <= dataEnable; end if;
			if hCount < 256 and vCount < 192 then dataEnable <= '1'; else dataEnable <= '0'; end if;
			if (hCount >= 320 and hCount <= 415) or (vCount >= 248 and vCount <= 255) then videoBlank <= '1'; else videoBlank <= '0'; end if;

			if dataInpLoad = '1' then dataInp <= vramData; end if;
			if dataOutLoad = '1' then dataOut <= dataInp; else dataOut <= dataOut(6 downto 0)&'0'; end if;

			if attrInpLoad = '1' then attrInp <= vramData; end if;
			if attrOutLoad = '1' then attrOut <= attrMux&attrInp(2 downto 0); end if;

			if videoEnable = '1' then attrMux(7 downto 3) <= attrInp(7 downto 3); else attrMux(7 downto 3) <= "00"&border; end if;

			vramAddr( 7 downto 0) <= vCount(5 downto 3)&hCount(7 downto 4)&hCount(2);
			if hCount(1) = '0' then vramAddr(12 downto 8) <= vCount(7 downto 6)&vCount(2 downto 0); else vramAddr(12 downto 8) <= "110"&vCount(7 downto 6); end if;

		end if;
	end process;

	v <= vSync;
	h <= hSync;
	r <= '0' when videoBlank = '1' else attrOut(1) when dataSelect = '1' else attrOut(4);
	g <= '0' when videoBlank = '1' else attrOut(2) when dataSelect = '1' else attrOut(5);
	b <= '0' when videoBlank = '1' else attrOut(0) when dataSelect = '1' else attrOut(3);
	i <= '0' when videoBlank = '1' else attrOut(6);

end;
