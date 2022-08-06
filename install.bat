@REM Johnny the Sysadmin Installation
@REM https://github.com/lxvs/jsa

@echo off
setlocal
set "dir=%~dp0jsa"
set name=jsa
set exec=jsa.bat
set regpath=HKCU\Software\lxvs\jsa
set silent=
set term=
set uninstall=
set exitcode=0
:parseargs
if %1. == . (goto endparseargs)
set term=1
if /i "%~1" == "--silent" (
    set silent=1
    shift /1
    goto parseargs
)
if /i "%~1" == "--uninstall" (
    set uninstall=1
    shift /1
    goto parseargs
)
if "%~1" == "/?" (goto help)
if "%~1" == "-?" (goto help)
if /i "%~1" == "-h" (goto help)
if /i "%~1" == "--help" (goto help)
>&2 echo error: invalid argument `%~1'
>&2 echo Try `install.bat --help' for more information.
exit /b 1
:endparseargs

if defined uninstall (
    if not defined silent (
        call %~dp0uninstall.bat
    ) else (
        call %~dp0uninstall.bat --silent
    )
    exit /b
) else (
    call %~dp0uninstall.bat --silent
)

call:getreg "HKCU\Environment" "Path" UserPath
call:getreg "%regpath%" "path" installation
setlocal EnableDelayedExpansion
if defined UserPath (
    if not defined silent (
        setx Path "%dir%;%UserPath%" 1>nul || (
            set exitcode=%errorlevel%
            goto end
        )
        reg add "%regpath%" /v "path" /d "%dir%" /f 1>nul
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /ve /d "%dir%\%exec%" /f 1>nul
    ) else (
        setx Path "%dir%;%UserPath%" 1>nul 2>&1 || (
            set exitcode=%errorlevel%
            goto end
        )
        reg add "%regpath%" /v "path" /d "%dir%" /f 1>nul 2>&1
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /ve /d "%dir%\%exec%" /f 1>nul 2>&1
    )
) else (
    if not defined silent (
        >&2 echo error: failed to get user Path
    )
    set exitcode=1
    goto end
)
endlocal
if not defined silent (echo Install complete.)
goto end

:getreg
set %3=
if "%~2" == "/ve" (
    set getreg_switch=/ve
    set getreg_key=
    set getreg_name=default
) else (
    set getreg_switch=/v
    set "getreg_key=%~2"
    set "getreg_name=%~2"
)
for /f "skip=2 tokens=1,2*" %%a in ('reg query "%~1" %getreg_switch% "%getreg_key%" 2^>nul') do (
    if /i "%%~a" == "%getreg_name%" (set "%3=%%~c")
)
exit /b

:help
echo usage: install.bat
echo    or: install.bat --silent
echo    or: install.bat --uninstall
exit /b

:end
if not defined term (pause)
exit /b %exitcode%
