# Makefile for the Apple ][-on-an-FPGA project
#
# Mostly creates an archive, prepares the ROM images, and run test benches
#
# DOES NOT compile the VHDL for the FPGA.  This is done within Quartus.
#
# Stephen A. Edwards, Columbia University, sedwards@cs.columbia.edu

VERSION = 1.2
NAME = apple2fpga-$(VERSION)

ZIPFILES = \
README \
Makefile \
DE1_TOP.qsf \
DE2_TOP.qsf \
apple2fpga_DE1.qpf \
apple2fpga_DE2.qpf \
apple2.vhd \
character_rom.vhd \
CLK28MPLL.vhd \
CLK28MPLL.qip \
cpu6502.vhd \
DE1_TOP.vhd \
DE2_TOP.vhd \
disk_ii.vhd \
i2c_controller.vhd \
keyboard.vhd \
PS2_Ctrl.vhd \
spi_controller.vhd \
timing_generator.vhd \
vga_controller.vhd \
video_generator.vhd \
wm8731_audio.vhd \
disk_ii_rom.vhd \
main_roms.vhd \
i2c_testbench.vhd \
timing_testbench.vhd \
dos33master.nib \
dsk2nib.c \
dsk2nib.sln \
dsk2nib.vcproj \
rom2vhdl \
makenibs \
bios.a65 \
bios.rom \
DE1_TOP.sof \
DE2_TOP.sof \
apple_II.rom \
slot6.rom

##############################
# Create the .zip file archive

$(NAME).zip : $(ZIPFILES)
	zip $(NAME).zip $(ZIPFILES)

##############################
# Create the two VHDL files for the actual ROMS

# apple_II.rom should be a 12287-byte file that represents the contents
# of the Apple II's ROMS, i.e., memory from 0xd000 to 0xffff

main_roms.vhd : apple_II.rom
	./rom2vhdl main_roms 13 12287 < apple_II.rom > main_roms.vhd

# slot6.rom should be a 256-byte file that represents the contents of the
# Disk II controller card.  When in slot 6, it appears in memory from
# 0xc600 to 0xc6FF

disk_ii_rom.vhd : slot6.rom
	./rom2vhdl disk_ii_rom 7 255 < slot6.rom > disk_ii_rom.vhd

##############################
# Assemble the "fake BIOS" using the xa65 cross-assembler

bios.rom : bios.a65
	xa -bt 53248 -A 53248 -o bios.rom -l bios.labels bios.a65

# Disassemble the "fake BIOS" to

bios.dis : bios.rom
	dxa -g d000 -a dump -r d000 bios.rom > bios.dis

##############################
# Rules for running the various testbenches using ghdl, the GNU VHDL simulator

VHDL_SRC = timing_generator.vhd \
	timing_testbench.vhd \
	i2c_controller.vhd \
	i2c_testbench.vhd

TIMING = 10000000ns

timing_testbench : $(VHDL_SRC:%.vhd=%.o)
	ghdl -e timing_testbench

timing_testbench.o : timing_generator.o

# Run the timing testbench to generate a .vcd file, which can be viewed with
#
# gtkwave timing_testbench.vcd timing_testbench.sav
#
timing_testbench.vcd : timing_testbench Makefile
	-./timing_testbench --vcd=timing_testbench.vcd --stop-time=$(TIMING) 2> timing_testbench.log

i2c_testbench : $(VHDL_SRC:%.vhd=%.o)
	ghdl -e i2c_testbench

i2c_testbench.o : i2c_controller.o

# Run the i2c testbench to generate a .vcd file, which can be viewed with
#
# gtkwave i2c_testbench.vcd i2c_testbench.sav
#
i2c_testbench.vcd : i2c_testbench Makefile
	./i2c_testbench --vcd=i2c_testbench.vcd --stop-time=$(TIMING) 2> i2c_testbench.log

%.o : %.vhd
	ghdl -a $<
