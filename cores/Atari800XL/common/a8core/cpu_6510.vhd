-- -----------------------------------------------------------------------
--
--                                 FPGA 64
--
--     A fully functional commodore 64 implementation in a single FPGA
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
-- -----------------------------------------------------------------------
--
-- 6510 wrapper for 65xx core
-- Adds 8 bit I/O port mapped at addresses $0000 to $0001
--
-- -----------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity cpu_6510 is
	generic (
		pipelineOpcode : boolean;
		pipelineAluMux : boolean;
		pipelineAluOut : boolean;
		emulate_bitfade : boolean;
		emulate_01_write : boolean
	);
	port (
		clk : in std_logic;
		ena_1khz : in std_logic := '0';
		enable : in std_logic;
		halt : in std_logic;
		reset : in std_logic;
		nmi_n : in std_logic;
		irq_n : in std_logic;

		we : out std_logic;
		a : out unsigned(15 downto 0);
		d : in unsigned(7 downto 0);
		q : out unsigned(7 downto 0);

		vic_last_data : in unsigned(7 downto 0) := (others => '1');
		diIO : in unsigned(7 downto 0);
		doIO : out unsigned(7 downto 0);
		
		debugOpcode : out unsigned(7 downto 0);
		debugJam : out std_logic;
		debugPc : out unsigned(15 downto 0);
		debugA : out unsigned(7 downto 0);
		debugX : out unsigned(7 downto 0);
		debugY : out unsigned(7 downto 0);
		debugS : out unsigned(7 downto 0);
		debug_flags : out unsigned(7 downto 0);
		debug_io : out unsigned(7 downto 0)
	);
end cpu_6510;

-- -----------------------------------------------------------------------

architecture rtl of cpu_6510 is
	signal localA : unsigned(15 downto 0);
	signal localD : unsigned(7 downto 0);
	signal localQ : unsigned(7 downto 0);
	signal localWe : std_logic;

	signal currentIO : unsigned(7 downto 0);
	signal ioDir : unsigned(7 downto 0);
	signal ioData : unsigned(7 downto 0);
	
	signal accessing_IO : boolean;
	signal ioFade : unsigned(7 downto 0) := (others => '0');
begin
	cpuInstance: entity work.cpu_65xx
		generic map (
			pipelineOpcode => pipelineOpcode,
			pipelineAluMux => pipelineAluMux,
			pipelineAluOut => pipelineAluOut
		)
		port map (
			clk => clk,
			enable => enable,
			halt => halt,
			reset => reset,
			nmi_n => nmi_n,
			irq_n => irq_n,

			d => localD,
			q => localQ,
			addr => localA,
			we => localWe,

			debugOpcode => debugOpcode,
			debugJam => debugJam,
			debugPc => debugPc,
			debugA => debugA,
			debugX => debugX,
			debugY => debugY,
			debugS => debugS,
			debug_flags => debug_flags
		);
	
	accessing_IO <= localA(15 downto 1) = 0;
	
	process(d, localA, ioDir, currentIO, accessing_IO)
	begin
		localD <= d;
		if accessing_IO then
			if localA(0) = '0' then
				localD <= ioDir;
			else
				localD <= currentIO;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge(clk) then
			if accessing_IO then
				if localWe = '1'
				and enable = '1' then
					if localA(0) = '0' then
						ioDir <= localQ;
					else
						ioData <= localQ;
					end if;
				end if;
			end if;
			if reset = '1' then
				ioDir <= (others => '0');
			end if;
		end if;
	end process;
	
	process(ioDir, ioData, diIO, ioFade)
	begin
		for i in 0 to 7 loop
			if ioDir(i) = '0' then
				currentIO(i) <= diIO(i);
			else
				currentIO(i) <= ioData(i);
			end if;
		end loop;
		if emulate_bitfade then
			currentIO(7) <= ioFade(7);
			currentIO(6) <= ioFade(6);
			currentIO(3) <= ioFade(3);
		end if;
	end process;
	
	-- Cunnect zee wires
	a <= localA;
	q <= vic_last_data when (emulate_01_write and accessing_IO) else localQ;
	we <= localWe;
	doIO <= currentIO;
	debug_io <= "00" & (ioData(5 downto 0) or (not ioDir(5 downto 0)));
end architecture;
