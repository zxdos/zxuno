
library ieee;
use ieee.std_logic_1164.all;

entity dpSRAM_1288 is
	port (
		clk_i				:  in    std_logic;
		-- Porta 0
		porta0_addr_i	:  in    std_logic_vector(16 downto 0);
		porta0_ce_i		:  in    std_logic;
		porta0_oe_i		:  in    std_logic;
		porta0_we_i		:  in    std_logic;
		porta0_data_i	:  in    std_logic_vector(7 downto 0);
		porta0_data_o	:  out   std_logic_vector(7 downto 0);
		-- Porta 1
		porta1_addr_i	:  in    std_logic_vector(16 downto 0);
		porta1_ce_i		:  in    std_logic;
		porta1_oe_i		:  in    std_logic;
		porta1_we_i		:  in    std_logic;
		porta1_data_i	:  in    std_logic_vector(7 downto 0);
		porta1_data_o	:  out   std_logic_vector(7 downto 0);
		-- Output to SRAM in board
		sram_addr_o		:  out   std_logic_vector(16 downto 0);
		sram_data_io	:  inout std_logic_vector(7 downto 0);
		sram_ce_n_o		:  out   std_logic								:= '1';
		sram_oe_n_o		:  out   std_logic								:= '1';
		sram_we_n_o		:  out   std_logic								:= '1'
	);
end entity;

architecture Behavior of dpSRAM_1288 is

	signal sram_we_n_s	: std_logic;
	signal sram_oe_n_s	: std_logic;

begin

	sram_ce_n_o	<= '0';		-- sempre ativa
	sram_we_n_o	<= sram_we_n_s;
	sram_oe_n_o	<= sram_oe_n_s;

	process (clk_i)

		variable state_v		: std_logic									:= '0';
		variable p0_ce_v		: std_logic_vector(1 downto 0);
		variable p1_ce_v		: std_logic_vector(1 downto 0);
		variable acesso0_v	: std_logic;
		variable acesso1_v	: std_logic;
		variable p0_req_v		: std_logic									:= '0';
		variable p1_req_v		: std_logic									:= '0';
		variable p0_we_v		: std_logic									:= '0';
		variable p1_we_v		: std_logic									:= '0';
		variable p0_addr_v	: std_logic_vector(16 downto 0);
		variable p1_addr_v	: std_logic_vector(16 downto 0);
		variable p0_data_v	: std_logic_vector(7 downto 0);
		variable p1_data_v	: std_logic_vector(7 downto 0);

	begin
		if rising_edge(clk_i) then
			acesso0_v	:= porta0_ce_i and (porta0_oe_i or porta0_we_i);
			acesso1_v	:= porta1_ce_i and (porta1_oe_i or porta1_we_i);
			p0_ce_v		:= p0_ce_v(0) & acesso0_v;
			p1_ce_v		:= p1_ce_v(0) & acesso1_v;

			if p0_ce_v = "01" then							-- detecta rising edge do pedido da porta0
				p0_req_v		:= '1';							-- marca que porta0 pediu acesso
				p0_we_v		:= '0';							-- por enquanto eh leitura
				p0_addr_v	:= porta0_addr_i;				-- pegamos endereco
				if porta0_we_i = '1' then					-- se foi gravacao que a porta0 pediu
					p0_we_v		:= '1';						-- marcamos que eh gravacao
					p0_data_v	:= porta0_data_i;			-- pegamos dado
				end if;
			end if;

			if p1_ce_v = "01" then							-- detecta rising edge do pedido da porta1
				p1_req_v		:= '1';							-- marca que porta1 pediu acesso
				p1_we_v		:= '0';							-- por enquanto eh leitura
				p1_addr_v	:= porta1_addr_i;				-- pegamos endereco
				if porta1_we_i = '1' then					-- se foi gravacao que a porta1 pediu
					p1_we_v		:= '1';						-- marcamos que eh gravacao
					p1_data_v	:= porta1_data_i;			-- pegamos dado
				end if;
			end if;

			if state_v = '0' then							-- Estado 0
				sram_data_io	<= (others => 'Z');		-- desconectar bus da SRAM
				if p0_req_v = '1' then						-- pedido da porta0 pendente
					sram_addr_o	<= p0_addr_v;				-- colocamos o endereco pedido na SRAM
					sram_we_n_s		<= '1';
--					sram_ce_n		<= '0';
					sram_oe_n_s		<= '0';
					if p0_we_v = '1' then					-- se for gravacao
						sram_data_io	<= p0_data_v;		-- damos o dado para a SRAM
						sram_we_n_s		<= '0';				-- e dizemos para ela gravar
						sram_oe_n_s		<= '1';
					end if;
					state_v	:= '1';
				elsif p1_req_v = '1' then					-- pedido da porta1 pendente
					sram_addr_o	<= p1_addr_v;				-- colocamos o endereco pedido na SRAM
					sram_we_n_s		<= '1';
--					sram_ce_n		<= '0';
					sram_oe_n_s		<= '0';
					if p1_we_v = '1' then					-- se for gravacao
						sram_data_io	<= p1_data_v;		-- damos o dado para a SRAM
						sram_we_n_s		<= '0';				-- e dizemos para ela gravar
						sram_oe_n_s		<= '1';
					end if;
					state_v	:= '1';							-- proximo rising do clock vamos para segundo estado
				end if;
			elsif state_v = '1' then						-- Estado 1
				if p0_req_v = '1' then						-- pedido da porta0 pendente
					sram_we_n_s		<= '1';
					sram_data_io	<= (others => 'Z');	-- desconectar bus da SRAM
					if p0_we_v = '0' then					-- se for leitura
						porta0_data_o	<= sram_data_io;	-- pegamos o dado que a SRAM devolveu
					end if;
					p0_req_v	:= '0';							-- limpamos a flag de requisicao da porta0
					state_v		:= '0';						-- voltar para estado 0
					sram_oe_n_s	<= '1';
--					sram_ce_n	<= '1';
				elsif p1_req_v = '1' then					-- pedido da porta1 pendente
					sram_we_n_s		<= '1';
					sram_data_io	<= (others => 'Z');	-- desconectar bus da SRAM
					if p1_we_v = '0' then					-- se for leitura
						porta1_data_o	<= sram_data_io;	-- pegamos o dado que a SRAM devolveu
					end if;
					p1_req_v		:= '0';						-- limpamos a flag de requisicao da porta1
					state_v		:= '0';						-- voltar para estado 0
					sram_oe_n_s	<= '1';
--					sram_ce_n	<= '1';
				end if;
			end if;
		end if;
	end process;

end;