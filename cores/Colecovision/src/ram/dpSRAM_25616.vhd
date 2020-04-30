-------------------------------------------------------------------------------
--
-- Copyright (c) 2016, Fabio Belavenuto (belavenuto@gmail.com)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity dpSRAM_25616 is
	port (
		clk_i				: in    std_logic;
		-- Port 0
		porta0_addr_i	: in    std_logic_vector(18 downto 0);
		porta0_ce_i		: in    std_logic;
		porta0_oe_i		: in    std_logic;
		porta0_we_i		: in    std_logic;
		porta0_d_i		: in    std_logic_vector(7 downto 0);
		porta0_d_o		: out   std_logic_vector(7 downto 0);
		-- Port 1
		porta1_addr_i	: in    std_logic_vector(18 downto 0);
		porta1_ce_i		: in    std_logic;
		porta1_oe_i		: in    std_logic;
		porta1_we_i		: in    std_logic;
		porta1_d_i		: in    std_logic_vector(7 downto 0);
		porta1_d_o		: out   std_logic_vector(7 downto 0);
		-- SRAM in board
		sram_addr_o		: out   std_logic_vector(17 downto 0);
		sram_data_io	: inout std_logic_vector(15 downto 0);
		sram_ub_o		: out   std_logic;
		sram_lb_o		: out   std_logic;
		sram_ce_n_o		: out   std_logic								:= '1';
		sram_oe_n_o		: out   std_logic								:= '1';
		sram_we_n_o		: out   std_logic								:= '1'
	);
end entity;

architecture Behavior of dpSRAM_25616 is

	signal sram_a_s	: std_logic_vector(18 downto 0);
	signal sram_d_s	: std_logic_vector(7 downto 0);
	signal sram_we_s	: std_logic;
	signal sram_oe_s	: std_logic;

begin

	sram_ce_n_o		<= '0';						-- sempre ativa
	sram_oe_n_o		<= sram_oe_s;
	sram_we_n_o		<= sram_we_s;
	sram_ub_o		<= not sram_a_s(0);		-- UB = 0 ativa bits 15..8
	sram_lb_o		<= sram_a_s(0);			-- LB = 0 ativa bits 7..0
	sram_addr_o		<= sram_a_s(18 downto 1);
	sram_data_io	<= "ZZZZZZZZ" & sram_d_s	when sram_a_s(0) = '0' else
							sram_d_s & "ZZZZZZZZ";

	process (clk_i)

		variable state_v		: std_logic	:= '0';
		variable p0_ce_v		: std_logic_vector(1 downto 0);
		variable p1_ce_v		: std_logic_vector(1 downto 0);
		variable acesso0_v	: std_logic;
		variable acesso1_v	: std_logic;
		variable p0_req_v		: std_logic									:= '0';
		variable p1_req_v		: std_logic									:= '0';
		variable p0_we_v		: std_logic									:= '0';
		variable p1_we_v		: std_logic									:= '0';
		variable p0_addr_v	: std_logic_vector(18 downto 0);
		variable p1_addr_v	: std_logic_vector(18 downto 0);
		variable p0_data_v	: std_logic_vector(7 downto 0);
		variable p1_data_v	: std_logic_vector(7 downto 0);

	begin
		if rising_edge(clk_i) then
			acesso0_v	:= porta0_ce_i and (porta0_oe_i or porta0_we_i);
			acesso1_v	:= porta1_ce_i and (porta1_oe_i or porta1_we_i);
			p0_ce_v		:= p0_ce_v(0) & acesso0_v;
			p1_ce_v		:= p1_ce_v(0) & acesso1_v;

			if p0_ce_v = "01" then								-- detecta rising edge do pedido da porta0
				p0_req_v			:= '1';							-- marca que porta0 pediu acesso
				p0_we_v			:= '0';							-- por enquanto eh leitura
				p0_addr_v		:= porta0_addr_i;				-- pegamos endereco
				if porta0_we_i = '1' then						-- se foi gravacao que a porta0 pediu
					p0_we_v		:= '1';							-- marcamos que eh gravacao
					p0_data_v	:= porta0_d_i;					-- pegamos dado
				end if;
			end if;

			if p1_ce_v = "01" then								-- detecta rising edge do pedido da porta1
				p1_req_v			:= '1';							-- marca que porta1 pediu acesso
				p1_we_v			:= '0';							-- por enquanto eh leitura
				p1_addr_v		:= porta1_addr_i;				-- pegamos endereco
				if porta1_we_i = '1' then						-- se foi gravacao que a porta1 pediu
					p1_we_v		:= '1';							-- marcamos que eh gravacao
					p1_data_v	:= porta1_d_i;					-- pegamos dado
				end if;
			end if;

			if state_v = '0' then								-- Estado 0
				sram_d_s			<= (others => 'Z');			-- desconectar bus da SRAM
				if p0_req_v = '1' then							-- pedido da porta0 pendente
					sram_a_s			<= p0_addr_v;					-- colocamos o endereco pedido na SRAM
					sram_we_s		<= '1';
					sram_oe_s		<= '0';
					if p0_we_v = '1' then						-- se for gravacao
						sram_d_s		<= p0_data_v;				-- damos o dado para a SRAM
						sram_we_s	<= '0';						-- e dizemos para ela gravar
						sram_oe_s	<= '1';
					end if;
					state_v	:= '1';
				elsif p1_req_v = '1' then						-- pedido da porta1 pendente
					sram_a_s			<= p1_addr_v;				-- colocamos o endereco pedido na SRAM
					sram_we_s		<= '1';
					sram_oe_s		<= '0';
					if p1_we_v = '1' then						-- se for gravacao
						sram_d_s		<= p1_data_v;				-- damos o dado para a SRAM
						sram_we_s	<= '0';						-- e dizemos para ela gravar
						sram_oe_s	<= '1';
					end if;
					state_v	:= '1';							-- proximo rising do clock vamos para segundo estado
				end if;
			elsif state_v = '1' then						-- Estado 1
				if p0_req_v = '1' then						-- pedido da porta0 pendente
					sram_we_s	<= '1';
					sram_d_s		<= (others => 'Z');		-- desconectar bus da SRAM
					if p0_we_v = '0' then					-- se for leitura
						if sram_a_s(0) = '0' then			-- pegamos o dado que a SRAM devolveu
							porta0_d_o	<= sram_data_io(7 downto 0);
						else
							porta0_d_o	<= sram_data_io(15 downto 8);
						end if;
					end if;
					p0_req_v		:= '0';						-- limpamos a flag de requisicao da porta0
					state_v		:= '0';						-- voltar para estado 0
					sram_oe_s	<= '1';
				elsif p1_req_v = '1' then					-- pedido da porta1 pendente
					sram_we_s	<= '1';
					sram_d_s		<= (others => 'Z');		-- desconectar bus da SRAM
					if p1_we_v = '0' then					-- se for leitura
						if sram_a_s(0) = '0' then			-- pegamos o dado que a SRAM devolveu
							porta1_d_o	<= sram_data_io(7 downto 0);
						else
							porta1_d_o	<= sram_data_io(15 downto 8);
						end if;
					end if;
					p1_req_v		:= '0';						-- limpamos a flag de requisicao da porta1
					state_v		:= '0';						-- voltar para estado 0
					sram_oe_s	<= '1';
				end if;
			end if;
		end if;
	end process;

end;