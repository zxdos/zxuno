** 27.12.2018 changes by byrtolet:
Oric atmos with read-only dos8d support.

keyboard:
Scroll Lock - toggles vga/rgb+composite
End - NMI
Home+End - reset
Page up - image number up
Page down - image number down

While holding the Home key, some hexedecimal numbers apear.
First two are the curent floppy track.
Next two are the current image number;
The reset four is the current program counter register. The value is latched when the Page Down key is pressed.

The images sould be prepared with dsk2nib utility
and should be 232960 bytes long each.

then they sould be written to the sdcard starting on sector 0

One could use on linux the command
cat *.nib >/dev/sdf

which will put all images with the .nib extension in the current
folder on the sdcard located on device /dev/sdf (please double check
the used device)


**Oric Atmos code ported to ZX-UNO board 25/8/2015 by Quest


README ORIGINAL:
----------------

22/01/2012 : Version 0.91 de travail / release working
 FR :
 Des mises à jour pour debugger
 Correction de bugs.

 GB
 Many upadates to debug
 Bugs fixes


01/02/2010 : Version 0.9 de travail / release working 

 Ce n'est pas encore un version fonctionnelle
mais c'est pour bientôt.
 It's not running but perhaps tomorrow ? ;-)

======================================================
======================================================

Merci à / Thanks to :
 + MikeJ de www.fpgaarcade.com pour avoir mis à disposition une 
   version de AY-3-8192 qui a permis de corriger la mienne et pour 
   le source du VIA 6522,
 + Gregory Estrade de www.torlus.com  (pour son aide et son libre accès
à son code vhdl)
 + Daniel Wallner pour le T65 (www.opencores.org)
