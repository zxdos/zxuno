The Oric TapeTools collection by F.Frances
------------------------------------------

This short guide intends to explain how to transfer
Oric tapes to the PC or back to the Oric, what the
different formats are, and what Euphoric can do with
these formats. The Oric TapeTools is a collection of
PC programs (mainly file format converters) that ease
your work when you try to use tape-images either with
Euphoric or a real Oric.

So, the first question that may come to mind is:

WHAT IS A TAPE-IMAGE ?

A tape-image is a file that you can store on your
PC's hard disk (or wherever else) AND that contains
a digital form of the data you usually find on a
real Oric tape. A real Oric tape is simply an audio
tape, so obviously any file format that allows to store
sound can be used to build tape-images. There are a
lot of sound-file formats, and Euphoric's main purpose
is not to deal with sound, so only two formats were
retained for use with Euphoric.

WHICH TAPE-IMAGE FORMATS ARE USED WITH EUPHORIC ?

A high-level format, and a low-level one...
The high-level format abstract the normal encoding
schemes (FAST or SLOW) used by the Oric ROM routines
(mainly CLOAD and CSAVE). This means that this format
stores the data bytes without any encoding. This is
the most common format found on the Internet archives,
and the filenames usually have a .TAP extension.
The low-level format is a faithful image of the audio
signal emitted by the Oric. This allows those programs
that use their own tape routines (instead of the rom
ones) to run in Euphoric. Some time ago, I was using
a specific format that allowed to keep those soundfiles
quite small (.4K8 files), but now the latest Euphoric
releases deal with standard .WAV files. However,
BE AWARE THAT ONLY ONE KIND OF WAV FILES IS RECOGNIZED,
Euphoric currently only handles 4800 Hz, 8-bit, mono.
If you don't know what the previous line means, read
the rest of this guide carefully...


OK, HOW DO I TRANSFER A TAPE TO MY PC ?

It is a quite simple, I'm no longer recommending the
special Oriclink cable since the sampling method gives
good results. This is a two-stage process: you sample
the real tape with your PC's soundcard and then you
clean the result.
It sounds simple, but you need to be very careful
with the first stage if you want a good result
(remember that reading a tape with the Oric was not
always successfull afterall). 
In order to sample your tape with a PC, you must
connect the Line-Out output of your tape recorder
to the Line-In input of your PC's soundcard,
and use the bundled software of your soundcard that
allows you to record sound, or one of the numerous
freeware or shareware sound programs on the Internet.
Take the time to check your tapecorder: clean the
head if needed, and adjust the azimut screw if you
want the best results (play your Oric tape and turn
the screw left or right in order to have the clearer
sound). In your PC's sound software, select the
following format: 44100 Hz, 8 bits unsigned, mono.
THIS IS THE ONLY FORMAT RECOGNIZED BY WAVCLEAN !
Play the tape and adjust the recording level so that
the signal is the loudest possible, without being
truncated : try to have at least half of the maximum
amplitude. Now you can record your Oric program.
If your program is in several parts, record all the
parts in a single WAV file. The second stage requires
you to execute WAVCLEAN. WAVCLEAN tries to give back
a square waveform to the distorted signal it reads,
and it reduces the sampling rate from 44100 Hz to
4800 Hz, so the resulting WAV file is near 10 times
smaller than the original, and you can then use it with
Euphoric (from Windows, you only need to right-click on
it and then select 'CLOAD on Atmos').
However, if the quality of the sampling was not
terrific, you might get parity errors (the
famous ERRORS FOUND message) when loading the file
under Euphoric, so, check all the factors that have
an effect on the quality of your sampling, as explained
above, and retry the whole procedure.
If you still get errors, this means that the quality 
of your tape is not up to the par:
try to load your tape with a real Oric, if you can load
the program on the Oric without errors, then connect the
Oric tape-out to the Line-In input of your PC's soundcard
and record the Oric when you CSAVE the program: you will
get a very clean sampling, and WAVCLEAN will analyse it
easily.
If you can't manage to load the program on a real Oric
without errors, then you will have to manually correct
the errors: take care to all the quality factors as
explained above, and sample the tape with your soundcard
(if you load the program on the real Oric, you won't
know where the parity errors are, and if you then CSAVE
the program, you validate the errors), then use WAV2TAP
(next section), this tool will tell you where the errors are.

THOSE WAV FILES ARE REALLY HUGE, CAN'T I DOWNSIZE THEM ?

If you got a .WAV file from an Internet archive, there
are chances it has to be in WAV format because the program
doesn't use the standard tape routines of the Oric's ROM.
But if you used the WAVCLEAN tool above, there are good chances
the program can be converted to the high-level tape-image
format (.TAP). Use WAV2TAP for this task.

HOW DO I TRANSFER .TAP/.WAV IMAGES TO MY REAL ORIC ?

This is quite easy: you have to connect your Oric Tape-input
to the PC's Line-Out. If you have a .WAV file, type CLOAD""
<ENTER> on the Oric and just play the WAV file with any
WAV-player (or just double-click on it).
BE AWARE THAT MANY PCs DON'T PLAY 4800 Hz WAV FILES CORRECTLY !
If you get ERRORS FOUND on your Oric, then you have to convert
the WAV file to a "standard" frequency like 8 kHz or 11.025kHz
(use your favorite soundtool for this task).
If you have a .TAP file, there's an additional step, you must
convert the .TAP file to a .WAV file first: this is TAP2WAV's
job. Once again, if you get ERRORS FOUND on your Oric, this
means that your PC (or software) doesn't correctly play 4800Hz,
thus TAP2WAV has a command-line option that allows it to
generate 8 kHz or 11 kHz WAV-files.
Alternatively, you can connect a tape-recorder to your
soundcard's output, if you want to write a real tape that you
can use with your Oric. Of course, you can use those WAV files
in many other ways: burn an audio-CD and connect a CD-player
to your Oric, etc. Some people have even converted them to the
MP3's format and successfully read them from their Oric...

SUMMARY TABLE: WHAT TOOL FOR WHAT USE...

|real tape | dirty WAV | clean WAV | TAP  | Euphoric | real Oric
|          |  44100 Hz |           |image |          |or tape,CD
+----------+-----------+-----------+------+----------+----------
|  record/sample       |           |      |          |
|    ---------->       |           |      |          |
+----------+-----------+-----------+------+----------+----------
|          |       WAVCLEAN        |      |          |
|          |     ------------>     |      |          |
+----------+-----------+-----------+------+----------+----------
|          |           |       WAV2TAP    |          |
|          |           |      -------->   |          |
|          |           |       TAP2WAV    |          |
|          |           |      <--------   |          |
+----------+-----------+------------------+----------+----------
|          |           |      Euphoric's hardware    |
|          |           |      tape emulation mode    |
|          |           |      <----------------->    |
+----------+-----------+-----------+-----------------+----------
|          |           |           |    .TAP mode    |  
|          |           |           |   <-------->    |
+----------+-----------+-----------+-----------------+----------
|                                play
|                          ------------------------------>
|               ----------------------------------------->
+---------------------------------------------------------------

