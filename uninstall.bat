@REM Johnny the Sysadmin Uninstallation
@REM https://github.com/lxvs/jsa

@echo off
setlocal

set name=jsa
set regpath=HKCU\Software\lxvs\jsa
set silent=
set term=
set install=
set exitcode=0
:parseargs
if %1. == . (goto endparseargs)
set term=1
if /i "%~1" == "--silent" (
    set silent=1
    shift /1
    goto parseargs
)
if /i "%~1" == "--install" (
    set install=1
    shift /1
    goto parseargs
)
if "%~1" == "/?" (goto help)
if "%~1" == "-?" (goto help)
if /i "%~1" == "-h" (goto help)
if /i "%~1" == "--help" (goto help)
>&2 echo error: invalid argument `%~1'
>&2 echo Try `uninstall.bat --help' for more information.
exit /b 1
:endparseargs

if defined install (
    if not defined silent (
        call %~dp0install.bat
    ) else (
        call %~dp0install.bat --silent
    )
    exit /b
)
call:getreg "HKCU\Environment" "Path" UserPath
call:getreg "%regpath%" "path" installation
setlocal EnableDelayedExpansion
if defined UserPath (
    if not defined silent (
        if defined installation (
            setx Path "!UserPath:%installation%;=!" 1>nul
        ) else (
            >&2 echo warning: no installation found; try to uninstall anyway
        )
        reg delete "%regpath%" /f 1>nul
        reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /f 1>nul
    ) else (
        if defined installation (setx Path "!UserPath:%installation%;=!" 1>nul 2>&1)
        reg delete "%regpath%" /f 1>nul 2>&1
        reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /f 1>nul 2>&1
    )
) else (
    if not defined silent (
        >&2 echo error: failed to get user Path
    )
    set exitcode=1
    goto end
)
endlocal
if not defined silent (echo Uninstall complete.)
goto end

:getreg
set %3=
set getregretval=
if /i "%~2" == "/ve" (
    set getreg_switch=/ve
    set getreg_key=
    set "getreg_name=(Default)"
) else (
    set getreg_switch=/v
    set getreg_key="%~2"
    set "getreg_name=%~2"
)
for /f "skip=2 tokens=1* delims=" %%a in ('reg query "%~1" %getreg_switch% %getreg_key% 2^>nul') do (
    call:getregparse "%%~a"
)
if defined getregretval (set "%3=%getregretval%")
exit /b

:getregparse
if "%~1" == "" (exit /b 1)
set "getregparse_str=%~1"
set "getregparse_str=%getregparse_str:    =	%
for /f "tokens=1,2* delims=	" %%A in ("%getregparse_str%") do (
    if /i "%getreg_name%" == "%%~A" (set "getregretval=%%~C")
)
exit /b

:help
echo usage: uninstall.bat
echo    or: uninstall.bat --silent
echo    or: uninstall.bat --install
exit /b 0

:end
if not defined term (pause)
exit /b %exitcode%
