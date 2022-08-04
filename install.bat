@REM Johnny the Sysadmin Installation
@REM https://github.com/lxvs/jsa

@echo off
setlocal
set "name=jsa"
set "dir=%~dp0jsa"
set "exec=jsa.bat"
set "reg=%SystemRoot%\System32\reg.exe"
pushd %USERPROFILE%
set conflict=
for /f %%i in ('where %name% 2^>nul') do if not defined conflict set "conflict=%%~i"
popd
for /f "skip=2 tokens=1,2*" %%a in ('%reg% query "HKCU\Environment" /v "Path" 2^>NUL') do if /i "%%~a" == "path" set "UserPath=%%c"
if not defined UserPath (
    >&2 echo The user PATH seems empty; installation is aborted.
    goto end
)
if not defined conflict goto continue
if "%dir%\%exec%" == "%conflict%" (
    echo %name% has already been installed.
) else (
    echo %name% has already been installed in %conflict%
)
:confirm
set uninst=
set /p "uninst=Do you want to uninstall? [Y/N]: "
if /i "%uninst%" == "n" exit /b
if /i "%uninst%" == "y" goto uninstall
goto confirm

:continue
setx PATH "%dir%;%UserPath%" 1>NUL || goto end
%reg% add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /ve /d "%dir%\%exec%" /f 1>nul
@echo Complete.
goto end

:uninstall
setlocal EnableDelayedExpansion
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
setx PATH "%newpath%" 1>nul || (
    pause
    exit /b 1
)
%SystemRoot%\System32\reg.exe delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /f 1>nul 2>&1
echo Uninstallation finished.

:end
pause
exit /b
