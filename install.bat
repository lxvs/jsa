@REM Johnny the Sysadmin Installation
@REM https://github.com/lxvs/jsa

@echo off
setlocal EnableDelayedExpansion
set "name=jsa"
set "dir=%~dp0jsa"
set "exec=jsa.bat"
set "reg=%SystemRoot%\System32\reg.exe"
for /f "skip=2 tokens=1,2*" %%a in ('%reg% query "HKCU\Environment" /v "Path" 2^>NUL') do if /i "%%~a" == "path" set "UserPath=%%c"
if not defined UserPath (
    >&2 echo error: Failed to get user Path. Abort to avoid messing up.
    goto end
)

set uninstall=
:parseargs
if %1. == . (goto endparseargs)
if /i "%~1" == "--uninstall" (
    set uninstall=1
    shift /1
    goto parseargs
)
if /i "%~1" == "/?" (goto ShowHelp)
if /i "%~1" == "-?" (goto ShowHelp)
if /i "%~1" == "-h" (goto ShowHelp)
if /i "%~1" == "--help" (goto ShowHelp)
>&2 echo error: invalid argument `%~1'
>&2 echo Try `install.bat --help' for more information.
goto end
:endparseargs

set conflict=
for /f %%i in ('where %name% 2^>nul') do if not defined conflict set "conflict=%%~i"
if defined conflict (
    if defined uninstall (
        call:uninstall
        goto end
    ) else (
        echo Uninstalling previous installation...
        call:uninstall || goto end
    )
)

setx PATH "%dir%;%UserPath%" 1>NUL || goto end
%reg% add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /ve /d "%dir%\%exec%" /f 1>nul
@echo Install complete.
goto end

:uninstall
set newpath=
set "_path=%USERPATH%"
set "_path=%_path: =#%"
set "_path=%_path:;= %"
set "_path=%_path:(=[%"
set "_path=%_path:)=]%"
set "path_conflict=!conflict:\%exec%=!"
for %%i in (%_path%) do (
    echo %%i | findstr /l "%path_conflict%" 1>nul || set "newpath=!newpath!%%i;"
)
set "newpath=%newpath:#= %"
set "newpath=%newpath:[=(%"
set "newpath=%newpath:]=)%"
setx Path "%newpath%" 1>nul || exit /b 1
set "UserPath=%newpath%"
%reg% delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /f 1>nul 2>&1
echo Uninstall complete.
exit /b 0

:ShowHelp
echo usage: install.bat
echo    or: install.bat --uninstall
exit /b

:end
pause
exit /b
