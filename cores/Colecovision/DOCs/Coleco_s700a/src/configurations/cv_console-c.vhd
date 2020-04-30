-------------------------------------------------------------------------------
--
-- FPGA Colecovision
--
-- $Id: cv_console-c.vhd,v 1.3 2006/01/05 22:25:25 arnim Exp $
--
-------------------------------------------------------------------------------

configuration cv_console_struct_c0 of cv_console is

  for struct

    for por_b: cv_por
      use configuration work.cv_por_rtl_c0;
    end for;

    for clock_b: cv_clock
      use configuration work.cv_clock_rtl_c0;
    end for;

    for t80a_b: T80a
      use configuration work.T80a_rtl_c0;
    end for;

    for vdp18_b: vdp18_core
      use configuration work.vdp18_core_struct_c0;
    end for;

    for psg_b: sn76489_top
      use configuration work.sn76489_top_struct_c0;
    end for;

    for ctrl_b: cv_ctrl
      use configuration work.cv_ctrl_rtl_c0;
    end for;

    for addr_dec_b: cv_addr_dec
      use configuration work.cv_addr_dec_rtl_c0;
    end for;

    for bus_mux_b: cv_bus_mux
      use configuration work.cv_bus_mux_rtl_c0;
    end for;

  end for;

end cv_console_struct_c0;
