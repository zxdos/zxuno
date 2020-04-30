@echo off
..\22nice\22nice.com
copy "coleco.h" ..
copy "*.as" ..
cd ..
del libcv.lib
del crtcv.obj
ZAS -U -J ascii.as
ZAS -U -J collisio.as
ZAS -U -J crtcv.as
ZAS -U -J delay.as
ZAS -U -J get_rand.as
ZAS -U -J memcpyb.as
ZAS -U -J memcpyf.as
ZAS -U -J memset.as
ZAS -U -J nmi.as
ZAS -U -J os7.as
ZAS -U -J rle2ram.as
ZAS -U -J rle2vram.as
ZAS -U -J screen.as
ZAS -U -J sound.as
ZAS -U -J ssound.as
ZAS -U -J sprites0.as
ZAS -U -J sprites1.as
ZAS -U -J sprites2.as
ZAS -U -J utoa.as
ZAS -U -J vdp0.as
ZAS -U -J vdp1.as
ZAS -U -J vdp2.as
ZAS -U -J vdp3.as
ZAS -U -J vdpex.as
ZAS -U -J vdppat.as
ZAS -U -J vdpname.as
ZAS -U -J primpkg0.as
ZAS -U -J primpkg1.as
ZAS -U -J primpkg2.as
del ascii.as
del collisio.as
del crtcv.as
del delay.as
del get_rand.as
del memcpyb.as
del memcpyf.as
del memset.as
del nmi.as
del os7.as
del rle2ram.as
del rle2vram.as
del screen.as
del sound.as
del ssound.as
del sprites0.as
del sprites1.as
del sprites2.as
del utoa.as
del vdp0.as
del vdp1.as
del vdp2.as
del vdp3.as
del vdpex.as
del vdppat.as
del vdpname.as
del primpkg0.as
del primpkg1.as
del primpkg2.as
libr r libcv.lib ascii.obj
libr r libcv.lib collisio.obj
libr r libcv.lib delay.obj
libr r libcv.lib get_rand.obj
libr r libcv.lib memcpyb.obj
libr r libcv.lib memcpyf.obj
libr r libcv.lib memset.obj
libr r libcv.lib nmi.obj
libr r libcv.lib os7.obj
libr r libcv.lib rle2ram.obj
libr r libcv.lib rle2vram.obj
libr r libcv.lib screen.obj
libr r libcv.lib sound.obj
libr r libcv.lib ssound.obj
libr r libcv.lib sprites0.obj
libr r libcv.lib sprites1.obj
libr r libcv.lib sprites2.obj
libr r libcv.lib utoa.obj
libr r libcv.lib vdp0.obj
libr r libcv.lib vdp1.obj
libr r libcv.lib vdp2.obj
libr r libcv.lib vdp3.obj
libr r libcv.lib vdpex.obj
libr r libcv.lib vdppat.obj
libr r libcv.lib vdpname.obj
libr r libcv.lib primpkg0.obj
libr r libcv.lib primpkg1.obj
libr r libcv.lib primpkg2.obj
del ascii.obj
del collisio.obj
del delay.obj
del get_rand.obj
del memcpyb.obj
del memcpyf.obj
del memset.obj
del nmi.obj
del os7.obj
del rle2ram.obj
del rle2vram.obj
del screen.obj
del sound.obj
del ssound.obj
del sprites0.obj
del sprites1.obj
del sprites2.obj
del utoa.obj
del vdp0.obj
del vdp1.obj
del vdp2.obj
del vdp3.obj
del vdpex.obj
del vdppat.obj
del vdpname.obj
del primpkg0.obj
del primpkg1.obj
del primpkg2.obj
copy crtcv.obj lib4k
copy libcv.lib lib4k