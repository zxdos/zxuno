#!/bin/bash
#call %ruta_bat%mypath
ngdbuild -intstyle ise -dd _ngo -sd ipcore_dir -nt timestamp -uc "$ruta_ucf"_zxuno_"$1".ucf -p xc6slx9-tqg144-"$speed" "$machine".ngc "$machine".ngd
map      -intstyle ise -w -ol high -mt 2 -p xc6slx9-tqg144-"$speed" -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o "$machine"_map.ncd "$machine".ngd "$machine".pcf
par      -intstyle ise -w -ol high -mt 4 "$machine"_map.ncd "$machine".ncd "$machine".pcf
trce     -intstyle ise -v 3 -s "$speed" -n 3 -fastpaths -xml "$machine".twx "$machine".ncd -o "$machine".twr "$machine".pcf
bitgen   -intstyle ise -g UnusedPin:Pullup -f "$machine".ut "$machine".ncd
bit2bin "$machine".bit COREn."$2"
cp  "$machine".bit "$machine"."$1".bit
