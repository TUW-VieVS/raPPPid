@echo off

rem  batch program : CRZ2RNX.bat
rem  
rem  Purpose: uncompression of multiple RINEX files (including conversion from Compact RINEX format)
rem  Usage  : see :SHOW_USAGE
rem  Function: uncompress multiple RINEX files. Compact RINEX files are also converted  
rem            to RINEX file.
rem
rem  Remarks:
rem    - Long filenames or old short filenames of RINEX conventions are assumed for 
rem      input RINEX and Compacct RINEX files and output RINEX files, accordingly.
rem      For old short file names of compressed files, NOT VMS/DOS types, but only UNIX types can be handled.
rem    - It works on Windows10. Not tested on other vertions of Windows.
rem    - Following commands are neede to be installed in command search path:
rem        CRX2RNX.exe (to convert Compact RINEX files)
rem        gzip.exe (if .gz or .Z files are included in the input)
rem
rem  Changes: 2021-12-22 Created by Y. Hatanaka
rem           xxxx-xx-xx   
rem  


set program=%0
setlocal EnableDelayedExpansion

rem ----------------
rem Default settings
rem ----------------
set out2cdir=NO
set delete=NO
set keep=NO
set quiet=NO
set skip=NO

rem -------------
rem parse options
rem -------------
for %%f in (%*) do (
   set opt=%%f

   if not "!opt:~0,1!" == "-" goto :END_OPT

   if        !opt! == -h (
      call :SHOW_USAGE %0
      exit /b
   ) else if !opt! == -c (
      set out2cdir=YES
   ) else if !opt! == -d (
      set delete=YES
   ) else if !opt! == -k (
      set keep=YES
   ) else if !opt! == -s (
      set skip=YES
   ) else if !opt! == -q (
      set quiet=YES
   ) else (
      echo Error: Invalid option "!opt!"
      exit /b
   )

   shift
 
)

:END_OPT
if %quiet%==NO (
   echo Option settings
   echo --------------------------------
   echo output to current path:   !out2cdir!
   echo delete input files:       !delete!
   echo keep output when failed:  !keep!
   echo skip the file with error: !skip!
   echo --------------------------------
)

rem -----------------
rem process each file
rem -----------------
:LOOP_ARG
   rem check argument
   rem --------------
   set arg=%~1
   if "%arg%" == "" goto :EXIT
   if "!arg:~0,1!"=="-" (
       if %quiet%==NO echo Error: Invalid file name "%~1"
       exit /b 2
   )

   set tmplog=tmp_errlvl_%DATE:%%RANDOM%%.log
   for %%f in (%~1) do (
      call :PROC_FILE %%f
      if errorlevel 1 exit /b 1
   )

   shift
goto :LOOP_ARG

:EXIT
exit /b

rem -----------
rem Subroutines
rem -----------

:SHOW_USAGE
echo Usage: %1 [-c] [-d] [-k] [-s] [-q] [-h] file1 file2 ...
echo     -c : output to current path (default: the same path as the input file)
echo     -d : delete input files after conversion
echo     -k : keep output files when compression is failed (default: delete)
echo     -s : skip the file with error (default: stop with errorlevel=1)
echo     -q : quiet mode
echo     -h : show this message and end
echo   file1, file2 ... : files to be processed (wild card may be used)
exit /b

:PROC_FILE
rem set command string to COMMAND
rem -----------------------------

set filein=%1

if %out2cdir%==YES (
   rem remove path
   set file2=%~nx1
) else (
   set file2=%1
)

if not exist !filein! (
   if %quiet%==NO echo file %1 does not exist ... skip
   exit /b
)

rem setting filter to pipe RINEX files and string for manipulation of file name
rem    file_unz : input file name (.gz or .Z removed)
rem    file_skl : the same except for the path removed if %out2die% is "YES"
rem ---------------------------------------------------------------------------
if        "!filein:~-3!" == ".gz" ( set FILTER=^| gzip -dc
                                    set file_unz=!filein:~0,-3!
                                    set file_skl=!file2:~0,-3!
) else if "!filein:~-2!" == ".Z"  ( set FILTER=^| gzip -dc
                                    set file_unz=!filein:~0,-2!
                                    set file_skl=!file2:~0,-2!
) else                            ( set FILTER=
                                    set file_unz=!filein!
                                    set file_skl=!file2!
)

rem compose COMMAND according to the type of the input file
rem -------------------------------------------------------
set COMMAND=
if        "!file_unz:~-4!" == ".crx"     ( call :TO_RNX !filein! !file_skl:~0,-4!.rnx
) else if "!file_unz:~-4!" == ".CRX"     ( call :TO_RNX !filein! !file_skl:~0,-4!.RNX
) else if "!file_unz:~-4!" == ".rnx"     ( call :UNZIP  !filein! !file_skl!
) else if "!file_unz:~-4!" == ".RNX"     ( call :UNZIP  !filein! !file_skl!
rem ### for the old file naming convention of RINEX ver.2 (only for long file name) 
rem -------------------------------------------------------------------------------
) else if "!file_unz:~-4,1!" == "." (
   if        "!file_unz:~-1!" == "d"        ( call :TO_RNX !filein! !file_skl:~0,-1!o
   ) else if "!file_unz:~-1!" == "D"        ( call :TO_RNX !filein! !file_skl:~0,-1!O
   ) else if "!file_unz:~-1!" == "o"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "O"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "n"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "N"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "m"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "M"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "g"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "G"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "l"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "L"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "h"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "H"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "b"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "B"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "c"        ( call :UNZIP  !filein! !file_skl!
   ) else if "!file_unz:~-1!" == "C"        ( call :UNZIP  !filein! !file_skl!
   )
) else (
   if %quiet%==NO echo !filein! ... skipped since the filename doesn't follow RINEX convention.
   exit /b
)
if %ERRORLEVEL%==-1 exit /b

rem run conversion
rem --------------
if %quiet%==NO echo "%COMMAND%"
%COMMAND%

set ERRLVL=
for /f %%e in (%tmplog%) do ( set ERRLVL=%%e )
del %tmplog%
if %ERRLVL% gtr 0 (
   if %quiet%==NO echo Error happens in processing !filein!
   if %keep%==NO call :DELETE %file_out%
   if %skip%==NO exit /b 1
   echo                  ... skip
)

if %delete%==YES call :DELETE %1
exit /b 0

:TO_RNX
set file_out=%2
set COMMAND=(type %1 !FILTER! ^| CRX2RNX - ^& call echo %%^^^^ERRORLEVEL%% ^> %tmplog% ) ^> %2
exit /b 0

:UNZIP
set file_out=%2
if "%1"=="%2" (
   if %quiet%==NO  echo %1  already uncompressed ... skip
   exit /b -1
)
set COMMAND=(type %1 !FILTER! ^& call echo %%^^^^ERRORLEVEL%% ^> %tmplog% ) ^> %2
exit /b 0

:DELETE
if %quiet%==NO echo "del /Q %1"
del /Q %1
exit /b 0

endlocal
