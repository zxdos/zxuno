#ifndef __WFN_H
#define __WFN_H

WFUNC(DirectoryOpen)
WFUNC(DirectoryRead)
WFUNC(SetCWDirectory)
WFUNC(FileOpenRead)
WFUNC(FileOpenWrite)
WFUNC(FileOpenRAF)
WFUNC(FileGetInfo)
WFUNC(FileRead)
WFUNC(FileWrite)
WFUNC(FileClose)
WFUNC(FileDelete)
WFUNC(FileSeek)
WFUNC(ExecuteArbitrary)

#ifdef INCLUDE_SDDOS

WFUNC(OpenSDDOSImg)
WFUNC(ReadSDDOSSect)
WFUNC(WriteSDDOSSect)
WFUNC(ValidateSDDOSDrives)
WFUNC(SerialiseSDDOSDrives)
WFUNC(UnmountSDDOSImg)
WFUNC(GetSDDOSImgNames)

#endif

#endif // __WFN_H
