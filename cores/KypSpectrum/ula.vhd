library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity ula is
	port
	(
		cpuClock   : in  std_logic;
		mreq       : in  std_logic;
		iorq       : in  std_logic;
		rd         : in  std_logic;
		wr         : in  std_logic;
		a0         : in  std_logic;
		aP         : in  std_logic;
		di         : in  std_logic_vector( 7 downto 0);
		do         : out std_logic_vector( 7 downto 0);
		cpuEnable  : out std_logic;
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
    sw         : in std_logic_vector(7 downto 0);
    col        : inout std_logic_vector(4 downto 0);
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
	signal attrMux     : std_logic_vector(7 downto 0);
	signal attrOut     : std_logic_vector(7 downto 0);

	signal dataEnable  : std_logic;
	signal videoBlank  : std_logic;
	signal videoEnable : std_logic;

	signal dataInpLoad : std_logic;
	signal dataOutLoad : std_logic;

	signal attrInpLoad : std_logic;
	signal attrOutLoad : std_logic;

	signal dataSelect  : std_logic;

	signal cancelContention : std_logic := '1';
	signal causeContention  : std_logic;
	signal mayContend       : std_logic;
	signal iorequla         : std_logic;

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
    sw       => sw,
    col      => col,
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
			if iorq = '0' and a0 = '0' and  wr = '0'
			then
				border  <= di(2 downto 0);
				mic     <= di(3);
				speaker <= di(4);
			end if;
		end if;
	end process;

	do <= '1'&(not ear)&'1'&keys when iorq = '0' and rd = '0' and a0 = '0'
		else vramData when iorq = '0' and rd = '0' and (dataInpLoad = '1' or attrInpLoad = '1')
		else x"FF";

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
          case vCount(8 downto 6) is
            when "000" =>
              col <= "11110";
            when "001" =>
              col <= "11101";
            when "010" =>
              col <= "11011";
            when "011" =>
              col <= "10111";
            when others =>
              col <= "01111";
          end case;
				else
					vCount <= (others => '0');
					fCount <= fCount+1;
				end if;
			end if;

			if dataInpLoad = '1' then dataInp <= vramData; end if;
			if attrInpLoad = '1' then attrInp <= vramData; end if;

			if dataOutLoad = '1' then dataOut <= dataInp; else dataOut <= dataOut(6 downto 0)&'0'; end if;
			if attrOutLoad = '1' then attrOut <= attrMux; end if;

			if hCount(3) = '1' then videoEnable <= dataEnable; end if;

			if vCount = 248 and hCount >= 2 and hCount <= 65 then int <= '0'; else int <= '1'; end if;
		end if;
	end process;

	hSync <= '0' when hCount >= 344 and hCount <= 375 else '1';
	vSync <= '0' when vCount >= 248 and vCount <= 251 else '1';

	dataInpLoad <= '1' when videoEnable = '1' and (hCount(3 downto 0) =  9 or hCount(3 downto 0) = 13) else '0';
	attrInpLoad <= '1' when videoEnable = '1' and (hCount(3 downto 0) = 11 or hCount(3 downto 0) = 15) else '0';

	dataOutLoad <= '1' when videoEnable = '1' and hCount(2 downto 0) = 4 else '0';
	attrOutLoad <= '1' when hCount(2 downto 0) = 4 else '0';

	dataSelect <= dataOut(7) xor (fCount(4) and attrOut(7));
	attrMux <= attrInp when videoEnable = '1' else "00"&border&"000";

	dataEnable <= '1' when hCount < 256 and vCount < 192 else '0';
	videoBlank <= '1' when (hCount >= 320 and hCount <= 415) or (vCount >= 248 and vCount <= 255) else '0';

	vramAddr( 7 downto 0) <= vCount(5 downto 3)&hCount(7 downto 4)&hCount(2);
	vramAddr(12 downto 8) <= vCount(7 downto 6)&vCount(2 downto 0) when hCount(1) = '0' else "110"&vCount(7 downto 6);

	v <= vSync;
	h <= hSync;
	r <= '0' when videoBlank = '1' else attrOut(1) when dataSelect = '1' else attrOut(4);
	g <= '0' when videoBlank = '1' else attrOut(2) when dataSelect = '1' else attrOut(5);
	b <= '0' when videoBlank = '1' else attrOut(0) when dataSelect = '1' else attrOut(3);
	i <= '0' when videoBlank = '1' else attrOut(6);

	process(cpuClock)
	begin
		if falling_edge(cpuClock)
		then
			if mreq = '0' or iorequla = '0' then cancelContention <= '0'; else cancelContention <= '1'; end if;
		end if;
	end process;

	causeContention <= '0' when aP = '1' or iorequla = '0' else '1';
	mayContend <= '0' when hCount(3 downto 0) > 3 and dataEnable = '1' else '1';
	iorequla <= iorq or a0;
	cpuEnable <= mayContend or causeContention or cancelContention;

end;
