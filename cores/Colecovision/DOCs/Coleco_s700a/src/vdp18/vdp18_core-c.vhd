-------------------------------------------------------------------------------
--
-- Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
--
-- $Id: vdp18_core-c.vhd,v 1.10 2006/06/18 10:47:01 arnim Exp $
--
-------------------------------------------------------------------------------

configuration vdp18_core_struct_c0 of vdp18_core is

  for struct

    for clk_gen_b: vdp18_clk_gen
      use configuration work.vdp18_clk_gen_rtl_c0;
    end for;

    for hor_vert_b: vdp18_hor_vert
      use configuration work.vdp18_hor_vert_rtl_c0;
    end for;

    for ctrl_b: vdp18_ctrl
      use configuration work.vdp18_ctrl_rtl_c0;
    end for;

    for cpu_io_b: vdp18_cpuio
      use configuration work.vdp18_cpuio_rtl_c0;
    end for;

    for addr_mux_b: vdp18_addr_mux
      use configuration work.vdp18_addr_mux_rtl_c0;
    end for;

    for pattern_b: vdp18_pattern
      use configuration work.vdp18_pattern_rtl_c0;
    end for;

    for sprite_b: vdp18_sprite
      use configuration work.vdp18_sprite_rtl_c0;
    end for;

    for col_mux_b: vdp18_col_mux
      use configuration work.vdp18_col_mux_rtl_c0;
    end for;

  end for;

end vdp18_core_struct_c0;
