#!/bin/sh

mypath=`dirname "$0"`

fpadbin="${mypath}/fpad"
"${fpadbin}" >/dev/null 2>&1
retval=$?
if [ $retval != 0 ]; then
    echo $("ERROR: fpad Not found")
    exit $retVal
fi

fcutbin="${mypath}/fcut"
"${fcutbin}" >/dev/null 2>&1
retval=$?
if [ $retval != 0 ]; then
    echo $("ERROR: fcut Not found")
    exit $retVal
fi


"${fpadbin}" 120000 0 padzero.int >/dev/null
cat "${1}" padzero.int > intfile.int

size="$(wc -c <"${1}")"
echo $size

"${fcutbin}" intfile.int 0 120000 "${2}.00.ZX3"
if [ "${size}" -gt "1179648" ]; then "${fcutbin}" intfile.int 120000 120000 "${2}.01.ZX3"; fi
if [ "${size}" -gt "2359296" ]; then "${fcutbin}" intfile.int 240000 120000 "${2}.02.ZX3"; fi
if [ "${size}" -gt "3538944" ]; then "${fcutbin}" intfile.int 360000 120000 "${2}.03.ZX3"; fi
if [ "${size}" -gt "4718592" ]; then "${fcutbin}" intfile.int 480000 120000 "${2}.04.ZX3"; fi

rm -f padzero.int
rm -f intfile.int

exit 0