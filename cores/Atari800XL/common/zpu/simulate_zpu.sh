#!/bin/bash

echo "---------------------------------------------------------"
echo "Use 'simulate -run' to skip compilation stage."
echo "Use 'simulate -view' to show previous simulation results."
echo "---------------------------------------------------------"

name=zpucore



. /home/markw/fpga/xilinx/14.7/ISE_DS/settings64.sh

mkdir -p sim
pushd sim

# if we have a WDB file, we can view it if requested (otherwise we remove it)
if [ ! -e $name.wdb -o "$1" != "-view" ]; then

    rm -f $name.wdb

    # if we have a EXE, we can run it if requested (otherwise we remove it)
    if [ ! -e $name.exe -o "$1" != "-run" ]; then

        rm -f $name.exe

        # copy testbench files
        cp -p ../tb/* .

        # copy source files
	cp `find ../ -iname "*.vhd"` .
	cp `find ../ -iname "*.vhdl"` .
	cp "../../components/generic_ram_infer.vhdl" .
	cp "../../components/spi_master.vhd" .
	cp "../../components/complete_address_decoder.vhdl" .
	cp "../../components/delay_line.vhdl" .
	cp "../../components/syncreset_enable_divider.vhd" .
	cp "../../components/synchronizer.vhdl" .

	cp "../../a8core/pokey.vhdl" .
	cp "../../a8core/pokey_keyboard_scanner.vhdl" .
	cp "../../a8core/pokey_countdown_timer.vhdl" .
	cp "../../a8core/pokey_noise_filter.vhdl" .
	cp "../../a8core/pokey_poly_4.vhdl" .
	cp "../../a8core/pokey_poly_5.vhdl" .
	cp "../../a8core/pokey_poly_17_9.vhdl" .

        # set up project definition file
	ls *.vhd* | perl -e 'while (<>){s/(.*)/vhdl work $1/;print $_;}' | cat > $name.prj
	echo NumericStdNoWarnings = 1 >> xilinxsim.ini

        # verbose & no multthreading - fallback in case of problems
        # fuse -v 1 -mt off -incremental -prj %name%.prj -o %name%.exe -t %name%

        fuse -timeprecision_vhdl 1fs -incremental -prj $name.prj -o $name.exe -t ${name}_tb || exit 1
        # fuse --mt off -prj %name%.prj -o %name%.exe -t %name%_tb

        # Check for the EXE again, independent of the errorlevel of fuse...
        [ -e $name.exe ] || echo "No simulation executable created"


    fi

    # Open the iSIM GUI and run the simulation
    ./$name.exe -gui -f ../$name.cmd -wdb $name.wdb -log $name.log -view ../$name.wcfg || exit 1
    #strace ./$name.exe -gui -f ../$name.cmd -wdb $name.wdb -log $name.log -view ../$name.wcfg >& out
    #./$name.exe -h -log $name.log 


else

    # Only start the viewer on an existing wave configuration (from an old simulation)
    isimgui -view ../$name.wcfg || exit 1

fi

popd
