@call ..\..\..\sdk\setenv.bat
genMenu
rcs screen.scr screen.rcs
fcut screen.rcs 0 1800 screen.cut
zx7b screen.cut screen.cut.zx7b
sjasmplus kartusho.asm
copy /b kartusho.rom+         ^
        48.rom+               ^
        lechesaa.rom+         ^
        sinleches.rom+        ^
        testrom.rom+          ^
        testrom48.rom+        ^
        se2.rom+              ^
        inves.rom+            ^
        seachange.rom+        ^
        gw03.rom+             ^
        JetSetWilly.rom+      ^
        Pssst.rom+            ^
        Gyruss.rom+           ^
        JetPac.rom+           ^
        Chess.rom+            ^
        Planetoids.rom+       ^
        HoraceSpiders.rom+    ^
        SpaceRaiders.rom+     ^
        TranzAm.rom+          ^
        ShadowUnicorn.rom+    ^
        HungryHorace.rom+     ^
        LocoMotion.rom+       ^
        PanamaJoe.rom+        ^
        Popeye.rom+           ^
        MiscoJones.rom+       ^
        ReturnJedi.rom+       ^
        StarWars.rom+         ^
        Deathchase.rom+       ^
        Cookie.rom+           ^
        LalaPrologue.rom+     ^
        Backgammon.rom+       ^
        QBert.rom             ^
    kartusho.bin
