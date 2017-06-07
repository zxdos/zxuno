---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

ENTITY cpu IS
PORT 
(
	CLK,RESET,ENABLE : IN STD_logic;
	DI : IN std_logic_vector(7 downto 0);
	IRQ_n   : in  std_logic;
	NMI_n   : in  std_logic;
	MEMORY_READY : in std_logic;
	THROTTLE : in std_logic;
	RDY : in std_logic;
	DO : OUT std_logic_vector(7 downto 0);
	A : OUT std_logic_vector(15 downto 0);
	R_W_n : OUT std_logic;
	CPU_FETCH : out std_logic
);
END cpu;

architecture vhdl of cpu is
component cpu_65xx is
	generic (
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
		debugPc : out unsigned(15 downto 0);
		debugA : out unsigned(7 downto 0);
		debugX : out unsigned(7 downto 0);
		debugY : out unsigned(7 downto 0);
		debugS : out unsigned(7 downto 0);
		debug_flags : out unsigned(7 downto 0)
	);
end component;

	signal CPU_ENABLE: std_logic; -- Apply Antic HALT and throttle
		
	-- Support for Peter's core (NMI patch applied)
	signal debugOpcode : unsigned(7 downto 0);
	signal debugPc : unsigned(15 downto 0);
	signal debugA : unsigned(7 downto 0);
	signal debugX : unsigned(7 downto 0);
	signal debugY : unsigned(7 downto 0);
	signal debugS : unsigned(7 downto 0);
	signal di_unsigned : unsigned(7 downto 0);
   signal do_unsigned : unsigned(7 downto 0);
	signal addr_unsigned : unsigned(15 downto 0);
	signal CPU_ENABLE_RDY : std_logic; -- it has not RDY line
	signal WE : std_logic;
	signal nmi_pending_next : std_logic; -- NMI during RDY
	signal nmi_pending_reg : std_logic;
	signal nmi_n_adjusted : std_logic;
	signal nmi_n_reg : std_logic;
	signal nmi_edge : std_logic;
	
	signal CPU_ENABLE_RESET : std_logic;
	signal not_rdy : std_logic;	
	
BEGIN
	CPU_ENABLE <= ENABLE and memory_ready and THROTTLE;
	
	-- CPU designed by Peter W - as used in Chameleon
	di_unsigned <= unsigned(di);
	cpu_6502_peter:cpu_65xx
		generic map
		(
			pipelineOpcode => false,
			pipelineAluMux => false,
			pipelineAluOut => false
		)
		port map (
			clk => clk,
			enable => CPU_ENABLE_RDY,
			halt => '0',
			reset=>reset,
			nmi_n=>nmi_n_adjusted,
			irq_n=>irq_n,
			d=>di_unsigned,
			q=>do_unsigned,
			addr=>addr_unsigned,
			WE=>WE,
			debugOpcode => debugOpcode,
			debugPc => debugPc,
			debugA => debugA,
			debugX => debugX,
			debugY => debugY,
			debugS => debugS
		);
		CPU_ENABLE_RDY <= (CPU_ENABLE and (rdy or we)) or reset;
		
		CPU_ENABLE_RESET <= CPU_ENABLE or reset;
		not_rdy <= not(rdy);
		
		nmi_edge <= not(nmi_n) and nmi_n_reg;
		nmi_pending_next <= (nmi_edge and not(rdy or we)) or (nmi_pending_reg and not(rdy)) or (nmi_pending_reg and rdy and not(cpu_enable));
		nmi_n_adjusted <= not(nmi_pending_reg) and nmi_n;
		
	-- register
	process(clk,reset)
	begin
		if (RESET = '1') then
			nmi_pending_reg <= '0';
			nmi_n_reg <= '1';
		elsif (clk'event and clk='1') then						
			nmi_pending_reg <= nmi_pending_next;		
			nmi_n_reg <= nmi_n;
		end if;
	end process;	

	-- outputs
	r_w_n <= not(we);
	do <= std_logic_vector(do_unsigned);
	a <= std_logic_vector(addr_unsigned);
		
	CPU_FETCH <= ENABLE and THROTTLE;

END vhdl;
