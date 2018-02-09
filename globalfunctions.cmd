@echo off

set runapp=%1
if not defined runapp goto nullparamter
if "%runapp%" equ "getdate" call :getdate
if "%runapp%" equ "datemath" call :datemath %2 %3 %4 %5 %6
if "%runapp%" equ "makemisdir" call :makemisdir %2
if "%runapp%" equ "pkzipccheck" call :pkzipccheck
if "%runapp%" equ "tectiacheck" call :tectiacheck
if "%runapp%" equ "copyfile" call :copyfile %2 %3
if "%runapp%" equ "choice" goto choicefunc
if "%runapp%" equ "?" goto help

if "%runapp%" neq "getdate" (
  if "%runapp%" neq "datemath" (
    if "%runapp%" neq "makemisdir" (
      if "%runapp%" neq "pkzipccheck" (
        if "%runapp%" neq "tectiacheck" (
          if "%runapp%" neq "copyfile" (
            if "%runapp%" neq "choice" (
              if "%runapp%" neq "?" (
                goto incorrectparamter
              )
            )
          )
        )
      )
    )
  )
)

:getdate
rem This will return the date into environment variables
rem 2002-03-20 : Works on any NT/2K/XP machine independent of regional date settings
rem 2011-05-04 : Updated to also handle the German language under Windows 7
FOR /f "tokens=1-4 delims=/-. " %%G IN ('date /t') DO (call :s_fixdate %%G %%H %%I %%J)
goto :s_print_the_date

:s_fixdate
if "%1:~0,1%" GTR "9" shift
FOR /f "skip=1 tokens=2-4 delims=(-)" %%G IN ('echo.^|date') DO (
Set %%G=%1&set %%H=%2&Set %%I=%3)
goto :eof

:s_print_the_date
Endlocal&(
Echo.|date|find "JJ">nul
If errorlevel 1 (
rem English locale
SET yy=%yy%&SET mm=%mm%&SET dd=%dd%
) Else (
rem German locale
SET yy=%JJ%&Set mm=%MM%&SET dd=%TT%
))
exit /b

:datemath
:: DateMath, a general purpose date math routine
:: If DateMath detects an error, variable _dd_int is set to 999999.
SET v_dd_int=0
SET v_mm_int=0
SET v_yy_int=0
SET v_ymd_str=
SET v_mm_str=
SET v_dd_str=

IF "%3"=="" goto s_syntax
IF "%4"=="+" goto s_validate_year
IF "%4"=="-" goto s_validate_year
IF "%4"=="" goto s_validate_year

:s_syntax
SET /a _dd_int=999999
goto :eof

:s_validate_year
::strip leading zeros
SET v_yy=%1
if %v_yy:~0,1% EQU 0 set v_yy=%v_yy:~1%

:: Check for Y2K
IF %v_yy% LSS 100 IF %v_yy% GEQ 80 SET /A v_yy += 1900
IF %v_yy% LSS 80 SET /A v_yy += 2000

:: at this point v_yy contains a 4 digit year
::validate month and day
if %2 GTR 12 goto s_syntax
if %3 GTR 31 goto s_syntax

SET v_mm=%2
SET v_dd=%3

::strip leading zeros
if %v_mm:~0,1% EQU 0 set v_mm=%v_mm:~1%
if %v_dd:~0,1% EQU 0 set v_dd=%v_dd:~1%

:: Set the int variables
SET /a v_dd_int=%v_dd%
SET /a v_yy_int=%v_yy%
SET /a v_mm_int=%v_mm%

:: Determine which function to perform - ADD, SUBTRACT or CONVERT
If not "%6"=="" goto s_validate_2nd_date
if "%4"=="" goto s_convert_only

:: Add or subtract days to a date
SET /a v_number_of_days=%5
goto s_add_or_subtract_days

:s_convert_only
SET /a v_dd_int=%v_dd%
IF %v_dd% LEQ 9 (SET v_dd_str=0%v_dd%) ELSE (SET v_dd_str=%v_dd%)
IF %v_mm% LEQ 9 (SET v_mm_str=0%v_mm%) ELSE (SET v_mm_str=%v_mm%)
SET v_ymd_str=%v_yy%%v_mm_str%%v_dd_str%

rem ECHO DATEMATH - Convert date only (no maths)
goto s_end
::::::::::::::::::::::::::::::::::::::::::::::::::

:s_validate_2nd_date
If "%4"=="+" goto s_syntax
:: Subtracting one date from another ::::::
:: strip leading zero
SET v_yy2=%5
if %v_yy2:~0,1% EQU 0 set v_yy2=%v_yy2:~1%
if %v_yy2% GTR 99 goto s_validate2nd_month
if %v_yy2% GTR 49 goto s_prefix_2_1950_1999
if %v_yy2% LSS 10 goto s_prefix_2_2000_2009
SET v_yy2=20%v_yy2%
goto s_validate2nd_month

:s_prefix_2_2000_2009
SET v_yy2=200%v_yy2%
goto s_validate2nd_month

:s_prefix_2_1950_1999
SET v_yy2=19%v_yy2%

:s_validate2nd_month
::strip leading zeros
::SET /a v_yy2=%v_yy2%
if %v_yy2:~0,1% EQU 0 set v_yy2=%v_yy2:~1%
::v_yy2 now contains a 4 digit year

if %6 GTR 12 goto s_syntax
SET v_mm2=%6

if %7 GTR 31 goto s_syntax
SET v_dd2=%7

::strip leading zeros
::SET /a v_mm2=%v_mm2%

if %v_mm2:~0,1% EQU 0 set v_mm2=%v_mm2:~1%
::SET /a v_dd2=%v_dd2%
if %v_dd2:~0,1% EQU 0 set v_dd2=%v_dd2:~1%

call :s_julian_day %v_yy_int% %v_mm_int% %v_dd_int%
SET v_sumdays1=%v_JulianDay%

call :s_julian_day %v_yy2% %v_mm2% %v_dd2%
SET v_sumdays2=%v_JulianDay%

SET /a v_dd_int=%v_sumdays1% - %v_sumdays2%

ECHO DATEMATH - Subtracting one date from another = days difference
ECHO ~~~~~~
ECHO %v_dd_int%
ECHO ~~~~~~
goto s_end_days
::::::::::::::::::::::::::::::::::::::::::::::::::

:s_add_or_subtract_days
if /i "%4"=="+" goto s_add_up_days

:: Subtract all days ::::::
SET /a v_dd=%v_dd% - %v_number_of_days%

:s_adjust_month_year
if %v_dd% GEQ 1 goto s_add_subtract_days_DONE
SET /a v_mm=%v_mm% - 1
if %v_mm% GEQ 1 goto s_add_days_%v_mm%
SET /a v_yy=%v_yy% - 1
SET /a v_mm=%v_mm% + 12
goto s_add_days_%v_mm%

:s_add_days_2
SET /a v_dd=%v_dd% + 28
SET /a v_leapyear=%v_yy% / 4
SET /a v_leapyear=%v_leapyear% * 4
if %v_leapyear% NEQ %v_yy% goto s_adjust_month_year
SET /a v_dd=%v_dd% + 1
goto s_adjust_month_year

:s_add_days_4
:s_add_days_6
:s_add_days_9
:s_add_days_11
SET /a v_dd=%v_dd% + 30
goto s_adjust_month_year

:s_add_days_1
:s_add_days_3
:s_add_days_5
:s_add_days_7
:s_add_days_8
:s_add_days_10
:s_add_days_12
SET /a v_dd=%v_dd% + 31
goto s_adjust_month_year

:s_add_up_days
:: add all days ::::::
SET /a v_dd=%v_dd% + %v_number_of_days%

:s_subtract_days_
goto s_subtract_days_%v_mm%

:s_adjust_mth_yr
SET /a v_mm=%v_mm% + 1
if %v_mm% LEQ 12 goto s_subtract_days_%v_mm%
SET /a v_yy=%v_yy% + 1
SET /a v_mm=%v_mm% - 12
goto s_subtract_days_%v_mm%

:s_subtract_days_2
SET /a v_leapyear=%v_yy% / 4
SET /a v_leapyear=%v_leapyear% * 4
If %v_leapyear% EQU %v_yy% goto s_subtract_leapyear

if %v_dd% LEQ 28 goto s_add_subtract_days_DONE
SET /a v_dd=%v_dd% - 28
goto s_adjust_mth_yr

:s_subtract_leapyear
if %v_dd% LEQ 29 goto s_add_subtract_days_DONE
SET /a v_dd=%v_dd% - 29
goto s_adjust_mth_yr

:s_subtract_days_4
:s_subtract_days_6
:s_subtract_days_9
:s_subtract_days_11
if %v_dd% LEQ 30 goto s_add_subtract_days_DONE
SET /a v_dd=%v_dd% - 30
goto s_adjust_mth_yr

:s_subtract_days_1
:s_subtract_days_3
:s_subtract_days_5
:s_subtract_days_7
:s_subtract_days_8
:s_subtract_days_10
:s_subtract_days_12
if %v_dd% LEQ 31 goto s_add_subtract_days_DONE
SET /a v_dd=%v_dd% - 31
goto s_adjust_mth_yr

:s_add_subtract_days_DONE
SET /a v_dd_int=%v_dd%
SET /a v_mm_int=%v_mm%
SET /a v_yy_int=%v_yy%
IF %v_dd% GTR 9 (SET v_dd_str=%v_dd%) ELSE (SET v_dd_str=0%v_dd%)
IF %v_mm% GTR 9 (SET v_mm_str=%v_mm%) ELSE (SET v_mm_str=0%v_mm%)
SET v_ymd_str=%v_yy%%v_mm_str%%v_dd_str%

goto s_end
::::::::::::::::::::::::::::::::::::::::::::::::::

:s_julian_day
SET v_year=%1
SET v_month=%2
SET v_day=%3
SET /a v_month=v_month
SET /a v_day=v_day
SET /A a = 14 - v_month
SET /A a /= 12
SET /A y = v_year + 4800 - a
SET /A m = v_month + 12 * a - 3
SET /A m = 153 * m + 2
SET /A m /= 5
SET /A v_JulianDay = v_day + m + 365 * y + y / 4 - y / 100 + y / 400 - 32045

ECHO The Julian Day is [%v_JulianDay%]
goto :eof
::::::::::::::::::::::::::::::::::::::::::::::::::

:s_end
:s_end_days
SET /a _yy_int=%v_yy_int%&SET /a _mm_int=%v_mm_int%&SET /a _dd_int=%v_dd_int%&SET _ymd_str=%v_ymd_str%&SET _mm_str=%v_mm_str%&SET _dd_str=%v_dd_str%
exit /b


:makemisdir
rem %1 - what directory to create if missing
set dirtocr=%1
if not defined dirtocr (
  color C0
  Echo ERROR: Directory not defined. Press any key to exit
  pause>nul
  exit
)
if not exist %dirtocr% (
  color C0
  echo Directory %dirtocr% is missing. Press any key to exit script.
  pause>nul
  exit
)
exit /b


:pkzipccheck
"C:\Program Files\PKWARE\PKZIPC\pkzipc.exe" -license -silent=all>nul 2>&1
if %errorlevel% EQU 0 (
  set PKZIP="C:\Program Files\PKWARE\PKZIPC\pkzipc.exe"
  goto :pkzipcchekfin
)
"C:\Program Files (x86)\PKWARE\PKZIPC\pkzipc.exe" -license -silent=all>nul 2>&1
if %errorlevel% EQU 0 (
  set PKZIP="C:\Program Files (x86)\PKWARE\PKZIPC\pkzipc.exe"
  goto :pkzipcchekfin
)
color C0
Echo No pkzipc was found. Please, request its installation though CMP.
Echo Press any key to exit
pause>nul
exit

:pkzipcchekfin
exit /b


:choicefunc
set /a chhelp=0
rem Text to show
set choicetext=%~2
rem Following defines how many options are set. Number in choice represent key on keyboard
set choice1=%3
set choice2=%4
set choice3=%5
set choice4=%6
set choice5=%7
set choice6=%8
set choice7=%9
shift
shift
shift
set choice8=%7
set choice9=%8
set choice0=%9
rem Extra function: pressing "Q" will always quit the application completely

if not defined choicetext (
  color C0
  Echo No text for choice was provided
  Echo Provide "?" as parameter for help
  Echo Press any key to exit application
  pause>nul
  exit
)
If "%choicetext%" equ "?" (
  set /a chhelp=1
  goto choicehelp
)

:choiceinput
set /p choice=%choicetext%
if %choice% equ 1 (
  if DEFINED choice1 (
    set /a chosen=1
    exit /b
  ) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if %choice% equ 2 (
  if DEFINED choice2 (
    set /a chosen=2
    exit /b
  ) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if %choice% equ 3 (
  if DEFINED choice3 (
    set /a chosen=3
    exit /b
  ) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if %choice% equ 4 (
  if DEFINED choice4 (
    set /a chosen=4
    exit /b
  ) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if %choice% equ 5 (
  if DEFINED choice5 (
    set /a chosen=5
    exit /b
) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if %choice% equ 6 (
  if DEFINED choice6 (
    set /a chosen=6
    exit /b
  ) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if %choice% equ 7 (
  if DEFINED choice7 (
    set /a chosen=7
    exit /b
  ) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if %choice% equ 8 (
  if DEFINED choice8 (
    set /a chosen=8
    exit /b
  ) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if %choice% equ 9 (
  if DEFINED choice9 (
    set /a chosen=9
    exit /b
  ) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if %choice% equ 0 (
  if DEFINED choice0 (
    set /a chosen=0
    exit /b
  ) ELSE (
    Echo ERROR: Action for parameter is not defined
    Echo.
    goto choiceinput
  )
)
if "%choice%" equ "?" (
  set /a chhelp=2
  goto choicehelp
)
If /I "%choice%" equ "q" (
  exit
) ELSE (
  Echo ERROR: Parameter not supported
  goto choiceinput
)


:copyfile
rem %1 - copy what
rem %2 - copy where
set infile=%1
set outfile=%2
if not defined infile (
  color C0
  Echo ERROR: Source file not defined. Press any key to exit
  pause>nul
  exit
)
if not defined outfile (
  color C0
  Echo ERROR: Output file not not defined. Press any key to exit
  pause>nul
  exit
)
echo Copying %infile% to %outfile%...
Echo.
COPY /V /Z /B /Y %infile% %outfile%
if %errorlevel% neq 0 (
  color C0
  Echo Failed to copy %infile% to %outfile%. Press any key to exit and retry
  pause > nul
  exit
)
exit /b


:tectiacheck
If Exist "C:\Program Files\SSH Communications Security\SSH Tectia\SSH Tectia Client\sftpg3.exe" (
  set tectiaexe="C:\Program Files\SSH Communications Security\SSH Tectia\SSH Tectia Client\sftpg3.exe"
) ELSE (
  If Exist "C:\Program Files (x86)\SSH Communications Security\SSH Tectia\SSH Tectia Client\sftpg3.exe" (
    set tectiaexe="C:\Program Files (x86)\SSH Communications Security\SSH Tectia\SSH Tectia Client\sftpg3.exe"
  ) ELSE (
    color C0
    Echo System does not appear to have Tectia Client
    pause
    exit
  )
)
set /a restartrequired=0
Setlocal EnableDelayedExpansion
if not exist "%appdata%\SSH" (
  mkdir "%appdata%\SSH" >nul 2>&1
)
if not exist "%appdata%\SSH\1.ssh2" (
  set /a restartrequired=1
  copy /b /v /y "\\path\TectiaProfiles\1.ssh2" "%appdata%\SSH\1.ssh2" >nul
)
if not exist "%appdata%\SSH\global.dat" (
  set /a restartrequired=1
  copy /b /v /y "\\path\TectiaProfiles\global.dat" "%appdata%\SSH\global.dat" >nul
)
if not exist "%appdata%\SSH\ssh-broker-config.xml" (
  set /a restartrequired=1
  copy /b /v /y "\\path\TectiaProfiles\ssh-broker-config.xml" "%appdata%\SSH\ssh-broker-config.xml" >nul
)
if !restartrequired! equ 1 (
  Echo Profiles were created, press any key to kill currently active Tectia client processes...
  pause>nul
  Echo Killing processes...
  taskkill /f /t /im ssh-broker-gui.exe >nul 2>&1
  taskkill /f /t /im ssh-broker-g3.exe >nul 2>&1
  taskkill /f /t /im ssh-client-g3.exe >nul 2>&1
  Echo Processes killed. Continuing...
)
exit /b



:nullparamter
Echo No parameter provided. Redirecting to help library...
goto help


:incorrectparamter
Echo Incorrect parameter provided. Redirecting to help library...
goto help


:help
Echo ******Global Functions Help******
Echo.
Echo This a an applciation holding a few frequently used functions. Function names and descriptions are as follows:
Echo "getdate" - gets current system date. Independent of system regional settings
Echo.
Echo "datemath" - calculates date before or after a given one. Require 5 paramters:
Echo ---Year as YY parameter
Echo ---Month as MM parameter
Echo ---Day as DD parameter
Echo ---Ariphmentic sign (plus or minus)
Echo ---Number of days to add or retract
Echo The call for this function should look like this: "YY MM DD + 12"
Echo.
Echo "makemisdir" - checks if a directory exists. If not - notifies. Requires directory path as parameter
Echo.
Echo "pkzipccheck" - cheks whether PKZIPC 14 is installed and uses either 32-bit or 64-bit bersion depending on OS
Echo.
Echo "tectiacheck" - checks whether Tectia client is installed
Echo.
Echo "copyfile" - copies a file. Requires source file and destination as parameters
Echo.
Echo "choice" - provides choice functionallity, where user chooses an action by pressing a specified key. Refer to choice's help for details (start application with choice "parameter")
Echo.
Echo "?" - shows this help library
Echo.
Echo Press any key to exit application
pause>nul


:choicehelp
Echo.
Echo ******Help for choice procedure******
Echo.
Echo This is a custom choice procedure based on use of "set /p" parameter
Echo This procedure can use up to 10 numeric choices ^(keystrokes^) from 0 to 9
Echo Separate global keystrokes are possible, as well:
Echo "Q" - exit applciation completely
Echo "?" - this help text
Echo.
Echo Currently running procedure utilises following keystrokes:
Echo %choice1% %choice2% %choice3% %choice4% %choice5% %choice6% %choice7% %choice8% %choice9% %choice0%
Echo.
if %chhelp% equ 2 (
  Echo Press any key to return to choosing an action you require...
  pause>nul
  Echo.
  goto choiceinput
)
if %chhelp% equ 1 (
  Echo Press any key to exit...
  pause>nul
  exit
)
