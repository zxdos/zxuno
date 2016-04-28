ChangeLog
---------

2.2 (Kees)

Version: SDDOS V2.2(C)KC

Original version, 18th March 2010

See http://www.stardot.org.uk/forums/viewtopic.php?f=44&t=6313&start=30#p73029

2.3 (Kees)

Version: SDDOS V2.3E (C)KC

Addressed at #E000 and to boot like AtomMMC does, using patched Kernel
(earlier versions were #A000 Utility ROMS)

See http://www.stardot.org.uk/forums/viewtopic.php?f=44&t=6313&start=60#p73211

2.3a (Kees)

Version: SDDOS V2.3E

Removed old SDDOS initialization command
(not needed, to save space)

Removed *COS and *DOS commands
(to save space)

Implemented Shift-BREAK
(this temporarily patches OSRDCH to inject *MENU)

Fixed a bug in *RUN and *<filename> which could cause a hang
(copy_params, $0D instead of #$0D beging checked as terminator)

See http://www.stardot.org.uk/forums/viewtopic.php?f=44&t=6313&start=60#p73326 
 
2.3b (Dave)

Version: SDDOS V2.3E

Fixed a bug with *MENU not working after a cold boot
(due to $9E not being initialized, only affected AtomFPGA because RAM as a different init value)

See http://www.stardot.org.uk/forums/viewtopic.php?f=44&t=6313&start=60#p73347

2.3c (Dave)

Version: SDDOS V2.3E

Fixed another initialization bug that only affected AtomFPGA

See http://www.stardot.org.uk/forums/viewtopic.php?f=44&t=6313&start=90#p73525

2.3d (Dave)

Version: SDDOS V2.3E

Fixed a bug that caused all drives to be seen as not initialized if a disk number greater
than 326 was accessed.
(This affected Atom Software Archive as this uses 1016-1022 to hold menu chapters)

See http://www.stardot.org.uk/forums/viewtopic.php?f=44&t=8154


