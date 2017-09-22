@echo off
SETLOCAL
if "%1"=="" goto Help
set _method=%1
set _forw=0
if f==%_method:~0,1% set _forw=1
if -==%_method:~2,1% set _lit=-c

:Loop
if "%3"=="" goto Continue
if 1==%_forw% (
  echo.
  echo ^>^>  exomizer raw %3 %_lit% -o %3.exo
  echo.
  exomizer raw %3 %_lit% -o %3.exo
) else (
  echo.
  echo ^>^>  exomizer raw %3 %_lit% -b -r -o %3.exo
  echo.
  exomizer raw %3 %_lit% -b -r -o %3.exo
)
set _result=%_result% %3.exo
shift /3
goto Loop

:Help
echo.
echo compress plain files with exomizer and exoopt, same syntax as exoopt
echo.
echo   compress ^<type^> ^<table_address^> ^<file1^> ^<file2^> .. ^<fileN^>
echo.
echo   ^<type^>           Target decruncher
echo   ^<table_address^>  Hexadecimal address for the temporal 156 bytes table
echo   ^<file1..N^>       Origin files
echo.
echo   A dash after ^<type^> (without space) forces the -c command in exomizer
goto :eof

:Continue
echo.
echo ^>^> exoopt %_method:~0,2% %2 %_result%
exoopt %_method:~0,2% %2 %_result%
echo.
echo ^>^> del %_result%
del %_result%
ENDLOCAL