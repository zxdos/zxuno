# colecofpga
Colecovision FGPA port from old PACE project.

The original project information is here:
http://members.iinet.net.au/~msmcdoug/pace/Nanoboard/nanoboard.html

This project is a ColecoFPGA design port to the Terasic DE-1 and DE-2 development boards, ZX-Uno board and a stand-alone version with a EP2C5 Chinese board.

The Hardware folder is the Eagle project for the prototype. In Synth folder there are projects for all cards. The prototype 1 did not work and is abandoned, the project with the EP4C10 card is not completed.

The second prototype use SNES control to emulate all of the original joystick buttons. Holding TL button the original buttons simulate:

<pre>
Y      => 1
X      => 2
B      => 3
A      => 4
SELECT => 5
START  => 6
</pre>

Holding TR button the original buttons simulate:

<pre>
Y      => 7
X      => 8
B      => 9
A      => 0
SELECT => *
START  => #
</pre>

Holding START and SELECT together resets the machine, returning in the multcart menu.

The B button and Y (auto-fire) is the fire 1 of original joystick. The A button and X (auto-fire) is the fire 2.

For the DE-1, DE-2 and ZX-Uno boards the PS/2 keyboard emulates the original joystick:

The arrow keys simulate the original directional. Z key is the 'fire 1', X key is 'fire 2', 0-9 is '0-9', Q key is '*' and W key is '#'. ESC key resets the machine. For the ZX-Uno the joystick port also works for directionals and fire 1.

The key combination CTRL+ALT+BACKSPACE, on ZX-Uno version, reloads the main core of Xilinx, returning to the main menu.

In boards with VGA output (ZX-Uno), uses the HOME key to toggle VGA output.

In this circuit the BIOS ROM is loaded from the SD card as well as the ROM multcart. In the source folder 'SD_Card' contains all necessary files to the SD card. Format it to FAT16 and copy the files.

In multcart menu, use the directionals to navigate the ROMs and use FIRE 1 button to load the selected ROM.
