#!/bin/bash

mkdir -p build

pushd build

for file in SDROM.ASM int.inc math-lib.inc sd.inc; do

cp ../$file tmp

# .org => ORG
sed -e 's/\.org/ORG/g' < tmp > tmp1
mv tmp1 tmp 

# .byte => EQUS
sed -e 's/\.byte/EQUS/g' < tmp > tmp1
mv tmp1 tmp 

# .db => EQUS
sed -e 's/\.db/EQUS/g' < tmp > tmp1
mv tmp1 tmp 

# EQUS 'some string' => EQUS "some string"
sed -e "s/EQUS '\([^']\+\)'/EQUS \"\1\"/g" < tmp > tmp1
mv tmp1 tmp 

# INCLUDE some_file => include "some_file"
sed -e 's/include[ \t]*\([a-zA-Z0-9_.-]*\)/include "\1"/g' < tmp > tmp1
mv tmp1 tmp 

# TOKEN_TERMINATED_IN_# => TOKEN_TERMINATED_IN_
sed -e 's/\([a-zA-Z0-9_]\+\)#/\1/g' < tmp > tmp1
mv tmp1 tmp 

# LABEL_TERMINATES_IN_: => LABEL_TERMINATES_IN_
sed -e 's/^\([a-zA-Z0-9_]\+\):/\1/g' < tmp > tmp1
mv tmp1 tmp 

# EQU * => deleted
sed -e 's/EQU[ \t]\+\*//g' < tmp > tmp1
mv tmp1 tmp 

# Label<space><space> => .Label<space>
sed -e 's/^\([a-zA-Z0-9_]\+\)  /.\1 /g' < tmp > tmp1
mv tmp1 tmp 

# Label => .Label
sed -e 's/^\([a-zA-Z0-9_]\+\)/.\1/g' < tmp > tmp1
mv tmp1 tmp 

# .MACEND => ENDMACRO
sed -e 's/\.MACEND/ENDMACRO/g' < tmp > tmp1
mv tmp1 tmp 

# .Name .MACRO => MACRO NAME
sed -e 's/^\.\([a-zA-Z0-9_]\+\)[ \t]\+\.MACRO/MACRO \1/g' < tmp > tmp1
mv tmp1 tmp 

# .Label equ => Label = 
sed -e 's/\.\([a-zA-Z0-9_]\+\)[ \t]\+equ[ \t]\+/\1 = /g' < tmp > tmp1
mv tmp1 tmp 

# .IFZ anything => IF (anything) = 0
sed -e 's/\.IFZ[ \t]\+\(.*\)/ IF (\1) = 0 /g' < tmp > tmp1
mv tmp1 tmp 

# .IFTRUE => IF
sed -e 's/\.IFTRUE/ IF/g' < tmp > tmp1
mv tmp1 tmp 

# .IF => IF
sed -e 's/\.IF/ IF/g' < tmp > tmp1
mv tmp1 tmp 

# .ENDIF => ENDIF
sed -e 's/\.ENDIF/ ENDIF/g' < tmp > tmp1
mv tmp1 tmp 

# .ELSE => ELSE
sed -e 's/\.ELSE/ ELSE/g' < tmp > tmp1
mv tmp1 tmp 

# >> => >
sed -e 's/>>/>/g' < tmp > tmp1
mv tmp1 tmp 

# << => <
sed -e 's/<</</g' < tmp > tmp1
mv tmp1 tmp 

# Remove Windows Line Endings
tr -d "\r" <tmp >$file

done

# Add a Save
cat >> SDROM.ASM << EOF
SAVE "SDROM.rom", start_asm, eind_asm
EOF

# Build
../../../BeebASM/beebasm/beebasm -v -i  SDROM.ASM

mv SDROM.rom ..

rm -rf build

popd




