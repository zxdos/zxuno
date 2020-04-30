-------------------------------------------------------------------------------
--
-- FPGA Colecovision
--
-- $Id: cv_bus_mux.vhd,v 1.3 2006/01/05 22:22:29 arnim Exp $
--
-- Bus Multiplexer
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
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

entity cv_bus_mux is

  port (
    bios_rom_ce_n_i : in  std_logic;
	 boot_i 		     : in  std_logic;
    ram_ce_n_i      : in  std_logic;
    vdp_r_n_i       : in  std_logic;
    ctrl_r_n_i      : in  std_logic;
    cart_en_80_n_i  : in  std_logic;
    cart_en_a0_n_i  : in  std_logic;
    cart_en_c0_n_i  : in  std_logic;
    cart_en_e0_n_i  : in  std_logic;
    bios_rom_d_i    : in  std_logic_vector(7 downto 0);
	 boot_rom_d_i    : in  std_logic_vector(7 downto 0);
    cpu_ram_d_i     : in  std_logic_vector(7 downto 0);
    vdp_d_i         : in  std_logic_vector(7 downto 0);
    ctrl_d_i        : in  std_logic_vector(7 downto 0);
    cart_d_i        : in  std_logic_vector(7 downto 0);
    d_o             : out std_logic_vector(7 downto 0)
  );

end cv_bus_mux;


architecture rtl of cv_bus_mux is

begin

  -----------------------------------------------------------------------------
  -- Process mux
  --
  -- Purpose:
  --   Masks the data buses and ands them together
  --
  mux: process (bios_rom_ce_n_i, bios_rom_d_i,
                ram_ce_n_i,      cpu_ram_d_i,
                vdp_r_n_i,       vdp_d_i,
                ctrl_r_n_i,      ctrl_d_i,
                cart_en_80_n_i,  cart_en_a0_n_i,
                cart_en_c0_n_i,  cart_en_e0_n_i,
                cart_d_i,  boot_rom_d_i,boot_i)
    constant d_inact_c : std_logic_vector(7 downto 0) := (others => '1');
    variable d_bios_v,
				 d_boot_v,
             d_ram_v,
             d_vdp_v,
             d_ctrl_v,
             d_cart_v  : std_logic_vector(7 downto 0);
  begin
    -- default assignments
    d_bios_v := d_inact_c;
	 d_boot_v := d_inact_c;
    d_ram_v  := d_inact_c;
    d_vdp_v  := d_inact_c;
    d_ctrl_v := d_inact_c;
    d_cart_v := d_inact_c;

    if bios_rom_ce_n_i = '0' then
      d_bios_v := bios_rom_d_i;
    end if;

    if ram_ce_n_i = '0' then
      d_ram_v  := cpu_ram_d_i;
    end if;
    if vdp_r_n_i = '0' then
      d_vdp_v  := vdp_d_i;
    end if;
    if ctrl_r_n_i = '0' then
      d_ctrl_v := ctrl_d_i;
    end if;
    if (cart_en_80_n_i and cart_en_a0_n_i and
        cart_en_c0_n_i and cart_en_e0_n_i) = '0' 
		  and (boot_i='0') then
      d_cart_v := cart_d_i;
    end if;

	if (cart_en_80_n_i = '0')  -- 8k boot rom 
		 and (boot_i='1') then
      d_boot_v := boot_rom_d_i;
    end if;

    d_o <= d_bios_v and
           d_ram_v  and
           d_vdp_v  and
           d_ctrl_v and
			  d_boot_v and
           d_cart_v;

  end process mux;
  --
  -----------------------------------------------------------------------------

end rtl;
