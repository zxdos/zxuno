set PATH=C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64;%PATH%

promgen -w -p mcs -c FF -o cvuno -s 131072 -spi -data_file up 0000 header.bin -u 4000 ../synth/cvuno/cvuno_top.bit

pause
