-- -----------------------------------------------------------------------
--
--                                 FPGA 64
--
--     A fully functional commodore 64 implementation in a single FPGA
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- All Rights Reserved.
--
-- http://www.syntiac.com/fpga64.html
-- -----------------------------------------------------------------------
--
-- Interface to 6502/6510 core
--
-- -----------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity cpu_65xx is
	generic (
		enable_jam : boolean := true;
		pipelineOpcode : boolean;
		pipelineAluMux : boolean;
		pipelineAluOut : boolean
	);
	port (
		clk : in std_logic;
		enable : in std_logic;
		halt : in std_logic := '0';
		reset : in std_logic;
		nmi_n : in std_logic := '1';
		irq_n : in std_logic := '1';
		so_n : in std_logic := '1';

		d : in unsigned(7 downto 0);
		q : out unsigned(7 downto 0);
		addr : out unsigned(15 downto 0);
		we : out std_logic;
		
		debugOpcode : out unsigned(7 downto 0);
		debugJam : out std_logic;
		debugPc : out unsigned(15 downto 0);
		debugA : out unsigned(7 downto 0);
		debugX : out unsigned(7 downto 0);
		debugY : out unsigned(7 downto 0);
		debugS : out unsigned(7 downto 0);
		debug_flags : out unsigned(7 downto 0)
	);
end entity;
