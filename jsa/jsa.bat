@echo off
setlocal enableExtensions disableDelayedExpansion
call:Prepare
call:SetDefaults
call:SetMeta
call:SetColor

if %1. == . (
    call:ShowVersion
    goto main_usage
)
set host=
set args=
set op=
set realhost=
set usrn=
set pswd=
set intf=
:parse
if %1. == . goto postparse
if "%~1" == "-H" (
    if "%~2" == "" (
        >&2 echo error: `%~1' needs a value
        exit /b 1
    )
    set "host=%~2"
    shift /1
    shift /1
    goto parse
) else if "%~1" == "-U" (
    if "%~2" == "" (
        >&2 echo error: `%~1' needs a value
        exit /b 1
    )
    set "usrn=%~2"
    shift /1
    shift /1
    goto parse
) else if "%~1" == "-P" (
    if "%~2" == "" (
        >&2 echo error: `%~1' needs a value
        exit /b 1
    )
    set "pswd=%~2"
    shift /1
    shift /1
    goto parse
) else if "%~1" == "-I" (
    if "%~2" == "" (
        >&2 echo error: `%~1' needs a value
        exit /b 1
    )
    set "intf=%~2"
    shift /1
    shift /1
    goto parse
) else if "%~1" == "/?" (
    goto lookupusage
) else if "%~1" == "-?" (
    goto lookupusage
) else if /i "%~1" == "-h" (
    goto lookupusage
) else if /i "%~1" == "--help" (
    goto lookupusage
) else if /i "%~1" == "--version" (
    call:ShowVersion
    exit /b
) else if not defined op (
    set "op=%~1"
    shift /1
    goto parse
) else (
    set "args=%args% %~1"
    shift /1
    goto parse
)
:postparse
if not defined usrn set "usrn=%JSA_DEF_USERNAME%"
if not defined pswd set "pswd=%JSA_DEF_PASSWORD%"
if not defined intf set "intf=%JSA_DEF_IPMI_INTF%"
set "paraU= -U %usrn%"
set "paraP= -P %pswd%"
set "paraI= -I %intf%"
if "%JSA_CM_COLOR_EN%" == "0" (
    set "cmSuf="
) else (
    @set "cmSuf=%cSuf%"
)

call:ParseHost %host% || exit /b
call:Execute %args%
exit /b

:Prepare
set "precd=%cd%"
if "%precd:~-1%" == "\" set "precd=%precd:~0,-1%"
pushd "%~dp0.."
exit /b
::Prepare

:SetDefaults
if not defined JSA_IPMIT set "JSA_IPMIT=%cd%\ipmitool.exe"
if not defined JSA_JVIEWER set "JSA_JVIEWER=%cd%\JViewer\JViewer.jar"
if not defined JSA_SOL_LOG_DIR set "JSA_SOL_LOG_DIR=%cd%\log\sol"
if not defined JSA_CM_LOG_DIR set "JSA_CM_LOG_DIR=%cd%\log\cm"
if not defined JSA_IPMI_CUSTOM_DIR set "JSA_IPMI_CUSTOM_DIR=%cd%\custom"
if not defined JSA_GLOBAL_COLOR_EN set "JSA_GLOBAL_COLOR_EN=1"
if not defined JSA_IP_PREF set "JSA_IP_PREF=192.168.1"
if not defined JSA_DEF_HOSTNAME set "JSA_DEF_HOSTNAME="
if not defined JSA_DEF_USERNAME set "JSA_DEF_USERNAME=admin"
if not defined JSA_DEF_PASSWORD set "JSA_DEF_PASSWORD=admin"
if not defined JSA_DEF_IPMI_INTF set "JSA_DEF_IPMI_INTF=lanplus"
if not defined JSA_IPMI_ECHO_EN set "JSA_IPMI_ECHO_EN=1"
if not defined JSA_IPMI_ECHO_COLOR set "JSA_IPMI_ECHO_COLOR=cyan"
if not defined JSA_IPMI_CUSTOM_ECHO_EN set "JSA_IPMI_CUSTOM_ECHO_EN=1"
if not defined JSA_IPMI_CUSTOM_ECHO_COLOR set "JSA_IPMI_CUSTOM_ECHO_COLOR=cyan"
if not defined JSA_LOOP_INTERVAL_S set /a "JSA_LOOP_INTERVAL_S=30"
if not defined JSA_LOOP_TIMESTAMP_EN set "JSA_LOOP_TIMESTAMP_EN=1"
if not defined JSA_MNTR_INTERVAL_S set /a "JSA_MNTR_INTERVAL_S=30"
if not defined JSA_MNTR_TIMESTAMP_EN set "JSA_MNTR_TIMESTAMP_EN=1"
if not defined JSA_CM_PING_RETRY set /a "JSA_CM_PING_RETRY=3"
if not defined JSA_CM_WEB_RETRY set /a "JSA_CM_WEB_RETRY=2"
if not defined JSA_CM_LOG_LEVEL set /a "JSA_CM_LOG_LEVEL=2"
if not defined JSA_CM_COLOR_EN set "JSA_CM_COLOR_EN=1"
if not defined JSA_CM_WEB_TIMEOUT_S set /a "JSA_CM_WEB_TIMEOUT_S=1"
if not defined JSA_CM_PING_TIMEOUT_MS set /a "JSA_CM_PING_TIMEOUT_MS=100"
if not defined JSA_KVM_WEBPORT set /a "JSA_KVM_WEBPORT=443"
exit /b
::SetDefaults

:SetMeta
set "jsa_version=0.2.0"
title Johnny the Sysadmin %jsa_version%
exit /b
::SetMeta

:SetColor
if "%JSA_GLOBAL_COLOR_EN%" == "0" (
    set cRed=
    set cGrn=
    set cYlw=
    set cBlu=
    set cMgt=
    set cCyn=
    set cSuf=
    set clr_e=
    set clr_c=
    exit /b
)
@set "cRed=[91m"
@set "cGrn=[92m"
@set "cYlw=[93m"
@set "cBlu=[94m"
@set "cMgt=[95m"
@set "cCyn=[96m"
@set "cSuf=[0m"
if /i "%JSA_IPMI_ECHO_COLOR%" == "red" (
    @set "clr_e=%cRed%"
) else if /i "%JSA_IPMI_ECHO_COLOR%" == "green" (
    @set "clr_e=%cGrn%"
) else if /i "%JSA_IPMI_ECHO_COLOR%" == "yellow" (
    @set "clr_e=%cYlw%"
) else if /i "%JSA_IPMI_ECHO_COLOR%" == "blue" (
    @set "clr_e=%cBlu%"
) else if /i "%JSA_IPMI_ECHO_COLOR%" == "magenta" (
    @set "clr_e=%cMgt%"
) else if /i "%JSA_IPMI_ECHO_COLOR%" == "cyan" (
    @set "clr_e=%cCyn%"
) else set clr_e=
if /i "%JSA_IPMI_CUSTOM_ECHO_COLOR%" == "red" (
    @set "clr_c=%cRed%"
) else if /i "%JSA_IPMI_CUSTOM_ECHO_COLOR%" == "green" (
    @set "clr_c=%cGrn%"
) else if /i "%JSA_IPMI_CUSTOM_ECHO_COLOR%" == "yellow" (
    @set "clr_c=%cYlw%"
) else if /i "%JSA_IPMI_CUSTOM_ECHO_COLOR%" == "blue" (
    @set "clr_c=%cBlu%"
) else if /i "%JSA_IPMI_CUSTOM_ECHO_COLOR%" == "magenta" (
    @set "clr_c=%cMgt%"
) else if /i "%JSA_IPMI_CUSTOM_ECHO_COLOR%" == "cyan" (
    @set "clr_c=%cCyn%"
) else set clr_c=
exit /b
::SetColor

:ParseHost
if not defined host (
    if defined JSA_DEF_HOSTNAME (
        set "realhost=%JSA_DEF_HOSTNAME%"
        exit /b 0
    )
    >&2 echo error: no hostname specified
    >&2 echo Try `jsa --help' for more information.
    exit /b 1
)
echo %host% | findstr /r /c:"^[0-9.]* $" 1>nul 2>&1 || (
    set "realhost=%host%"
    exit /b 0
)
for /f "delims=. tokens=1-3" %%a in ("%JSA_IP_PREF%") do (
    if "%%a" NEQ "" set "prea=%%a" else goto hostparsemid
    if "%%b" NEQ "" set "preb=%%b" else goto hostparsemid
    if "%%c" NEQ "" set "prec=%%c" else goto hostparsemid
)
:hostparsemid
for /f "delims=. tokens=1-4,*" %%a in ("%~1") do (
    if "%%a" NEQ "" set "seca=%%a" else goto afterhostparse
    if "%%b" NEQ "" set "secb=%%b" else goto afterhostparse
    if "%%c" NEQ "" set "secc=%%c" else goto afterhostparse
    if "%%d" NEQ "" set "secd=%%d" else goto afterhostparse
    if "%%e" NEQ "" set "sece=%%e" else goto afterhostparse
)
:afterhostparse
if defined sece (
    >&2 echo error: Specified IP address %host% has more than 4 sections.
    exit /b 1
)
if defined secd (
    set "realhost=%host%"
    exit /b 0
)
if defined secc if defined prea (
    set "realhost=%prea%.%host%"
    exit /b 0
)
if defined secb if defined preb (
    set "realhost=%prea%.%preb%.%host%"
    exit /b 0
)
if defined seca if defined prec (
    set "realhost=%prea%.%preb%.%prec%.%host%"
    exit /b 0
)
>&2 echo error: Parsed IP has less than 4 sections.
>&2 echo JSA_IP_PREF = %JSA_IP_PREF%
>&2 echo Try `jsa host --help' for more information.
exit /b 1
::ParseHost

:Execute
if /i "%op%" == "ipmi" goto ipmi_default
if /i "%op%" == "cm" goto cmparsepre
if /i "%op%" == "custom" goto custom_cmd
if /i "%op%" == "sol" goto solpre
if /i "%op%" == "bios" goto ipmi_bios
if /i "%op%" == "br" goto ipmi_br
if /i "%op%" == "bootdev" goto bootdevparse
if /i "%op%" == "loop" goto ipmi_loop
if /i "%op%" == "mntr" goto ipmi_mntr
if /i "%op%" == "monitor" goto ipmi_mntr
if /i "%op%" == "kvm" goto kvmparse
:custom_cmd
set customCmd=
set customFound=
if /i "%op%" == "custom" (
    set customCmd=1
    set "op=%~1"
)
if exist "%JSA_IPMI_CUSTOM_DIR%\%op%.txt" (
    set "customFound=1"
    for /f "usebackq eol=# delims=" %%i in ("%JSA_IPMI_CUSTOM_DIR%\%op%.txt") do (
        call:execline "%%~i"
    )
)
if defined customFound exit /b
if defined customCmd (
    >&2 echo error: custom command `%op%' not found
    >&2 echo Try `jsa custom --help' for more information.
    exit /b 1
) else (
    goto ipmi_default
)
:execline
if "%JSA_IPMI_CUSTOM_ECHO_EN%" NEQ "0" (
    echo %clr_c%ipmitool%paraI%%paraU%%paraP% -H %realhost% %~1%cSuf%
)
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% %~1
exit /b
::execline
::Execute

:ipmi_bios
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% chassis bootdev bios
exit /b
::ipmi_bios

:ipmi_br
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% chassis bootdev bios
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% chassis power cycle
exit /b
::ipmi_br

:bootdevparse
set "dev=%~1"
shift /1
set efiflag=
set persflag=
:bdpstart
if "%~1" == "" goto postbdp
if /i "%~1" == "efi" (
    set "efiflag=options=efiboot"
    shift /1
    goto bdpstart
) else if /i "%~1" == "efiboot" (
    set "efiflag=options=efiboot"
    shift /1
    goto bdpstart
) else if /i "%~1" == "persistent" (
    set "persflag=options=persistent"
    shift /1
    goto bdpstart
) else (
    set "bdargs=%bdargs% %~1"
    shift /1
    goto bdpstart
)
:postbdp
if "%JSA_IPMI_ECHO_EN%" NEQ "0" @echo %clr_e%ipmitool%paraI%%paraU%%paraP% -H %realhost% chassis bootdev %dev% %efiflag% %persflag% %bdargs%%cSuf%
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% chassis bootdev %dev% %efiflag% %persflag% %bdargs%
exit /b
::bootdevparse

:ipmi_loop
set "lom=loop"
goto lomstart
:ipmi_mntr
set "lom=mntr"
:lomstart
if "%~1" == "" (
    >&2 echo error: no command provided
    >&2 echo Try `jsa --help' for more information.
    exit /b 1
)
if "%~1" == "0" goto lomparse
set /a "lom_int=%~1" 2>nul || goto lomparse
if "%lom_int%" == "%~1" (
    shift /1
)
:lomparse
if "%lom_int%" == "0" set lom_int=
if "%~1" NEQ "" (
    set "lom_args=%lom_args% %~1"
    shift /1
    goto lomparse
)
if /i "%lom%" == "mntr" (
    goto cmd_mntr_pre
) else if /i "%lom%" == "loop" (
    goto cmd_loop_pre
) else (
    >&2 echo error: invalid mode: %lom%
    exit /b 1
)
::lomstart

:cmd_loop_pre
if not defined lom_int set lom_int=%JSA_LOOP_INTERVAL_S%
:cmd_loop
if "%JSA_LOOP_TIMESTAMP_EN%" == "0" (
    @echo;
    goto loop_skip_ts
)
call:GetTime lpYear lpMon lpDay lpHour lpMin lpSec
@echo %cYlw%%lpYear%-%lpMon%-%lpDay% %lpHour%:%lpMin%:%lpSec%%cSuf%
:loop_skip_ts
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% %lom_args%
call:Delay_s %lom_int%
goto cmd_loop
::cmd_loop_pre

:cmd_mntr_pre
if not defined lom_int set lom_int=%JSA_MNTR_INTERVAL_S%
set "monLast=%TEMP%\ipmi-mon-last"
set "monCurr=%TEMP%\ipmi-mon-current"
if "%JSA_MNTR_TIMESTAMP_EN%" == "0" (
    @echo;
    goto mntr_pre_skip_ts
)
call:GetTime lpYear lpMon lpDay lpHour lpMin lpSec
@echo %cYlw%%lpYear%-%lpMon%-%lpDay% %lpHour%:%lpMin%:%lpSec%%cSuf%
:mntr_pre_skip_ts
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% %lom_args% 1>%monLast% 2>&1
type %monLast%
:cmd_mntr
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% %lom_args% 1>%monCurr% 2>&1
fc "%monCurr%" "%monLast%" 1>NUL 2>&1 && (
    call:Delay_s %lom_int%
    goto cmd_mntr
)
if "%JSA_MNTR_TIMESTAMP_EN%" == "0" (
    @echo;
    goto mntr_skip_ts
)
call:GetTime lpYear lpMon lpDay lpHour lpMin lpSec
@echo %cYlw%%lpYear%-%lpMon%-%lpDay% %lpHour%:%lpMin%:%lpSec%%cSuf%
:mntr_skip_ts
type "%monCurr%"
move /Y "%monCurr%" "%monLast%" 1>NUL 2>&1
goto cmd_mntr
::cmd_mntr_pre

:solpre
if "%~1" == "" (
    call:ActSol
    exit /b
)
if "%~2" NEQ "" goto ipmi_default
set "solArg=%~1"
if /i "%solArg:~-4%" == ".log" (
    call:ActSol %solArg%
    exit /b
) else if /i "%solArg:~-4%" == ".txt" (
    call:ActSol %solArg%
    exit /b
) else goto ipmi_default
::solpre

:kvmparse
set kvm_wp=
set kvm_args=
if not exist "%JSA_JVIEWER%" (
    >&2 echo error: unable to find JViewer.jar in %JSA_JVIEWER%
    >&2 echo Please defined the path to JViewer.jar in variable `JSA_JVIEWER'.
    exit /b 1
)
:kvmparseloop
if "%~1" == "" goto kvmstart
if /i "%~1" == "-w" (
    if "%~2" == "" (
        >&2 echo error: `%~1' requires a value
        exit /b 1
    )
    set /a "kvm_wp=%~2"
    shift /1
    shift /1
    goto kvmparseloop
)
if /i "%~1" == "--web-port" (
    if "%~2" == "" (
        >&2 echo error: `%~1' requires a value
        exit /b 1
    )
    set /a "kvm_wp=%~2"
    shift /1
    shift /1
    goto kvmparseloop
)
set "kvm_args=%kvm_args% %~1"
shift /1
goto kvmparseloop

:kvmstart
if not defined kvm_wp set "kvm_wp=%JSA_KVM_WEBPORT%"
if not defined kvm_wp set "kvm_wp=443"
start "" "%JSA_JVIEWER%" -hostname "%realhost%" -u "%usrn%" -p "%pswd%" -webport %kvm_wp% %kvm_args%
exit /b
::kvmparse

:ipmi_default
if "%op%" == "ipmi" set op=
if "%JSA_IPMI_ECHO_EN%" NEQ "0" echo %clr_e%ipmitool%paraI%%paraU%%paraP% -H %realhost% %op%%args%%cSuf%
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% %op%%args%
exit /b
::ipmi_default

:GenLogFilename
call:GetTime lfnYear lfnMon lfnDay lfnHour lfnMin
set "lfnWf=%JSA_SOL_LOG_DIR%\%lfnYear%-%lfnMon%-%lfnDay%"
if "%~3" NEQ "0" if not exist "%lfnWf%" md "%lfnWf%"
set "%2=%lfnWf%\%1-%lfnHour%.%lfnMin%.log"
exit /b
::GenLogFilename

:ActSol
title Johnny the Sysadmin %jsa_version% - SOL %realhost%
set "solLfn="
if "%~1" NEQ "" set "solLfn=%precd%\%~1"
if not defined solLfn goto sol_continue
if not exist "%solLfn%" goto sol_continue
set "solow="
set /p "solow=%solLfn% exists, overwrite it? (Y/n): "
if /i "%solow%" == "y" (
    del /f "%solLfn%" || (
        >&2 echo error: Failed to delete file %solLfn%
        exit /b 1
    )
) else (
    exit /b 1
)
:sol_continue
@echo deactivating previous SOL session ^(if any^)...
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% sol deactivate 1>nul 2>&1
if not defined solLfn (call:GenLogFilename %realhost% solLfn 1)
@type nul >"%solLfn%" || (
    >&2 echo error: unable to create log file
    >&2 echo Please change a directory or run as administrator.
    exit /b 1
)
@echo Activated SOL, saving to %SolLfn%
explorer /select,"%solLfn%"
%JSA_IPMIT%%paraI%%paraU%%paraP% -H %realhost% sol activate 1>"%solLfn%" 2>&1
exit /b
::ActSol

:cmparsepre
set cmlegacy=
set cm_log_input=
set cm_ping_input=
set cm_web_input=
set "cm_log=%JSA_CM_LOG_LEVEL%"
set "cm_ping=%JSA_CM_PING_RETRY%"
set "cm_web=%JSA_CM_WEB_RETRY%"
:cmparse
if /i "%~1" == "" goto postCmParse
if /i "%~1" == "-l" (
    set "cmlegacy=1"
    shift /1
    goto cmparse
)
if /i "%~1" == "--legacy" (
    set "cmlegacy=1"
    shift /1
    goto cmparse
)
if /i "%~1" == "-g" (
    if "%~2" == "" (
        >&2 echo error: `%~1' requires a value
        exit /b 1
    )
    set "cm_log_input=%~2"
    shift /1
    shift /1
    goto cmparse
)
if /i "%~1" == "--log-level" (
    if "%~2" == "" (
        >&2 echo error: `%~1' requires a value
        exit /b 1
    )
    set "cm_log_input=%~2"
    shift /1
    shift /1
    goto cmparse
)
if /i "%~1" == "-p" (
    if "%~2" == "" (
        >&2 echo error: `%~1' requires a value
        exit /b 1
    )
    set "cm_ping_input=%~2"
    shift /1
    shift /1
    goto cmparse
)
if /i "%~1" == "--ping-retry" (
    if "%~2" == "" (
        >&2 echo error: `%~1' requires a value
        exit /b 1
    )
    set "cm_ping_input=%~2"
    shift /1
    shift /1
    goto cmparse
)
if /i "%~1" == "-w" (
    if "%~2" == "" (
        >&2 echo error: `%~1' requires a value
        exit /b 1
    )
    set "cm_web_input=%~2"
    shift /1
    shift /1
    goto cmparse
)
if /i "%~1" == "--web-retry" (
    if "%~2" == "" (
        >&2 echo error: `%~1' requires a value
        exit /b 1
    )
    set "cm_web_input=%~2"
    shift /1
    shift /1
    goto cmparse
)
>&2 echo error: invalid switch: `%~1'
>&2 echo Try `jsa --help' for more information.
exit /b 1
:postCmParse
set /a "cm_log_input_a=cm_log_input"
set /a "cm_ping_input_a=cm_ping_input"
set /a "cm_web_input_a=cm_web_input"
if defined cm_log_input if "%cm_log_input_a%" == "%cm_log_input%" (
    set /a "cm_log=cm_log_input_a"
) else (
    >&2 echo warning: Parameter log_level was designated but did not applied.
)
if defined cm_ping_input if "%cm_ping_input_a%" == "%cm_ping_input%" (
    set /a "cm_ping=cm_ping_input_a"
) else (
    >&2 echo warning: Parameter ping_retry was designated but did not applied.
)
if defined cm_web_input if "%cm_web_input_a%" == "%cm_web_input%" (
    set /a "cm_web=cm_web_input_a"
) else (
    >&2 echo warning: Parameter web_retry was designated but did not applied.
)
title Johnny the Sysadmin %jsa_version% - CM %realhost%
if not exist "%JSA_CM_LOG_DIR%" md "%JSA_CM_LOG_DIR%"
set "cmCurrentStatus="
set "cmEwsStatus="
set "cmLastHttpCode="
set "cmEwsOrgG=Web is accessible."
set "cmEwsOrgB=Web is not ready."
set "cmEwsTrnG=Web is up."
set "cmEwsTrnB=Web is down."
set "cmPingB=Ping timed out."
set "cmPingOrgG=Ping is OK."
set "cmPingTrnG=Ping is OK."
call:CmWrite "------------------------------------------------------" 0 0
call:CmWrite "Host:          %realhost%" 0 0
call:CmWrite "Version:       %jsa_version%" 0 0
call:CmWrite "Ping retry:    %cm_ping%" 0 0
call:CmWrite "Ping timeout:  %JSA_CM_PING_TIMEOUT_MS% ms" 0 0
if not defined cmlegacy (
    call:CmWrite "Web retry:     %cm_web%" 0 0
    call:CmWrite "Web timeout:   %JSA_CM_WEB_TIMEOUT_S% s" 0 0
    call:CmWrite "Log level:     %cm_log%" 0 0
    if %cm_log% GTR 0 call:CmWrite "Log directory: %JSA_CM_LOG_DIR%" 0 0
) else call:CmWrite "Log directory: %JSA_CM_LOG_DIR%" 0 0
call:CmWrite "------------------------------------------------------" 0 0

:cmloop
for /f "skip=2 tokens=1-8 delims= " %%a in ('ping %realhost% -n 1 -w %JSA_CM_PING_TIMEOUT_MS%') do (
    set "TtlSeg=%%f"
    goto cm_loop_afterfor
)
:cm_loop_afterfor
if /i "%TtlSeg:~0,3%" == "TTL" (
    call:CmWrite "ping: OK." 2
    if not defined cmCurrentStatus (
        set "cmCurrentStatus=g"
        if not defined cmlegacy call:CmWrite "debug: calling GHC because status is not defined." 8
        if not defined cmlegacy (call:CmGetHttpCode) else call:CmWrite "%cmPingOrgG%" g
        call:Delay_s 1
        goto cmloop
    )
    if /i "%cmCurrentStatus%" == "b" (
        set "cmCurrentStatus=g"
        if not defined cmlegacy call:CmWrite "debug: calling GHC because status turns good." 8
        if not defined cmlegacy (call:CmGetHttpCode) else call:CmWrite "%cmPingTrnG%" g
        call:Delay_s 1
        goto cmloop
    )
    if /i "%cmCurrentStatus:~0,1%" == "b" (
        set "cmCurrentStatus=g"
        call:CmWrite "Just jitters, ignored." 1
        if not defined cmlegacy call:CmWrite "debug: calling GHC because of jitters." 8
        if not defined cmlegacy call:CmGetHttpCode
        call:Delay_s 1
        goto cmloop
    )
    if not defined cmlegacy call:CmWrite "debug: calling GHC mandatorily." 8
    if not defined cmlegacy call:CmGetHttpCode
    call:Delay_s 1
    goto cmloop
)
call:CmWrite "ping: failed!" 2
if not defined cmCurrentStatus goto CmWriteBad
if /i "%cmCurrentStatus%" == "b" goto cmloop
if /i "%cmCurrentStatus:~0,1%" == "b" goto CmPingTrans
if %cm_ping% GTR 0 (
    set "cmCurrentStatus=b0"
    call:CmWrite "Ping failed, retrying." 1
    goto cmloop
) else goto CmWriteBad
::cmloop

:CmGetHttpCode
for /f %%i in ('curl -m %JSA_CM_WEB_TIMEOUT_S% -so /dev/null -Iw %%{http_code} %realhost%') do (
    call:CmWrite "debug: HTTP code updated:   %cmLastHttpCode% to %%i" 8
    call:CmWrite "debug: BMC web status:      %cmEwsStatus%" 8
    call:CmWrite "HTTP code: %%i" 2
    if "%%i" NEQ "%cmLastHttpCode%" (
        set "cmLastHttpCode=%%i"
        call:CmWrite "HTTP code updated: %%i" 1
    )
    if "%%i" == "000" (
        if not defined cmEwsStatus (
            call:CmWrite "%cmEwsOrgB%" y
            set "cmEwsStatus=b"
        ) else if /i "%cmEwsStatus%" NEQ "b" (
            if /i "%cmEwsStatus:~0,1%" == "b" (
                call:CmWebTrans
                exit /b
            )
            if %cm_web% GTR 0 (
                set "cmEwsStatus=b0"
                call:CmWrite "EWS seems down, retrying." 1
                exit /b
            ) else (
                call:CmWrite "%cmEwsTrnB%" y
                set "cmEwsStatus=b"
            )
        )
    ) else (
        if not defined cmEwsStatus (
            call:CmWrite "%cmEwsOrgG%" g
        ) else if /i "%cmEwsStatus%" == "b" (
            call:CmWrite "%cmEwsTrnG%" g
        )
        set "cmEwsStatus=g"
    )
)
exit /b
::CmGetHttpCode

:CmPingTrans
set /a "cmPingRetried=%cmCurrentStatus:~-1%"
set /a "cmPingRetried+=1"
set "cmCurrentStatus=b%cmPingRetried%"
if /i "%cmEwsStatus:~0,1%" == "b" if /i "%cmEwsStatus%" NEQ "b" set /a "cmPingRetried=cm_ping"
call:CmWrite "Ping failed, retried = %cmPingRetried%." 1
if %cmPingRetried% GEQ %cm_ping% (
    set "cmPingRetried="
    goto CmWriteBad
)
goto cmloop
::CmPingTrans

:CmWriteBad
set "cmCurrentStatus=b"
set "cmEwsStatus="
set "cmLastHttpCode="
call:CmWrite "%cmPingB%" r
goto cmloop
::CmWriteBad

:CmWebTrans
set /a "cmEwsRetried=%cmEwsStatus:~-1%"
set /a "cmEwsRetried+=1"
set "cmEwsStatus=b%cmEwsRetried%"
call:CmWrite "EWS seems down, retried = %cmEwsRetried%." 1
if %cmEwsRetried% GEQ %cm_web% (
    set "cmEwsRetried="
    call:CmWrite "%cmEwsTrnB%" y
    set "cmEwsStatus=b"
)
exit /b
::CmWebTrans

:CmWrite
@REM %1: message
@REM %2: color (0/Red/Green/Yellow/Blue/Magenta/Cyan)
@REM     -OR- MsgLvl (0-9)
@REM %3: iftimestamp (0/1) default 1
set "cmClr=%~2"
set "cmIfts=%~3"
if not defined cmIfts set "cmIfts=1"
set /a "cmMsgLvl=cmClr"
set "cmPre="
set "cmSuf="
if "%JSA_CM_COLOR_EN%" == "0" goto cmcontinue
if not defined cmClr goto cmcontinue
if "%cmClr%" == "%cmMsgLvl%" goto cmcontinue
if /i "%cmClr%" == "r" (
    @set "cmPre=%cRed%"
    goto cmcontinue
)
if /i "%cmClr%" == "g" (
    @set "cmPre=%cGrn%"
    goto cmcontinue
)
if /i "%cmClr%" == "y" (
    @set "cmPre=%cYlw%"
    goto cmcontinue
)
if /i "%cmClr%" == "b" (
    @set "cmPre=%cBlu%"
    goto cmcontinue
)
if /i "%cmClr%" == "m" (
    @set "cmPre=%cMgt%"
    goto cmcontinue
)
if /i "%cmClr%" == "c" (
    @set "cmPre=%cCyn%"
    goto cmcontinue
)
:cmcontinue
@if defined cmPre set "cmSuf=%cSuf%"
if "%cmMsgLvl%" NEQ "0" if %cmMsgLvl% GEQ %cm_log% exit /b 0
if "%cmIfts%" NEQ "0" call:GetTime cmYear cmMon cmDay cmHour cmMin cmSec
if "%cmIfts%" NEQ "0" (
    set "cmTimeStamp=%cmyear%-%cmmon%-%cmday% %cmhour%:%cmmin%:%cmsec%"
) else set "cmTimeStamp="
set "cmLogMsg=%~1"
if %cmMsgLvl% EQU 0 @echo %cmpre%%cmTimeStamp% %cmLogMsg%%cmsuf%
if %cmMsgLvl% GEQ %cm_log% exit /b 0
if not exist "%JSA_CM_LOG_DIR%" md "%JSA_CM_LOG_DIR%"
if %cmMsgLvl% EQU 0 >>"%JSA_CM_LOG_DIR%\%realhost%.log" echo %cmTimeStamp% %cmLogMsg%
if %cm_log% LEQ 1 exit /b 0
if %cmMsgLvl% LSS %cm_log% >>"%JSA_CM_LOG_DIR%\%realhost%.verbose.log" echo %cmTimeStamp% %cmLogMsg%
exit /b 0
::CmWrite

:GetTime
for /f "tokens=1-6 usebackq delims=_" %%a in (`powershell -command "&{Get-Date -format 'yyyy_MM_dd_HH_mm_ss'}"`) do (
    if "%1" NEQ "" set "%1=%%a" else exit /b
    if "%2" NEQ "" set "%2=%%b" else exit /b
    if "%3" NEQ "" set "%3=%%c" else exit /b
    if "%4" NEQ "" set "%4=%%d" else exit /b
    if "%5" NEQ "" set "%5=%%e" else exit /b
    if "%6" NEQ "" set "%6=%%f" else exit /b
)
exit /b
::GetTime

:ShowVersion
@echo;
@echo     Johnny the Sysadmin %jsa_version%
@echo     https://github.com/lxvs/jsa
@echo;
exit /b
::ShowVersion

:Delay_s
setlocal
set /a "sec=%~1" || exit /b
set /a "sec+=1"
ping localhost -n %sec% 1>nul 2>&1
endlocal
exit /b
::Delay_s

:lookupusage
if defined op (
    if /i "%op%" == "ipmi" goto %op%_usage
    if /i "%op%" == "cm" goto %op%_usage
    if /i "%op%" == "kvm" goto %op%_usage
    if /i "%op%" == "custom" goto %op%_usage
    if /i "%op%" == "host" goto %op%_usage
    if /i "%op%" == "var" goto %op%_usage
    if /i "%op%" == "loop" goto ipmi_usage
    if /i "%op%" == "mntr" goto ipmi_usage
    if /i "%op%" == "sol" goto ipmi_usage
    if /i "%op%" == "br" goto ipmi_usage
    if /i "%op%" == "bootdev" goto ipmi_usage
    if /i "%op%" == "jviewer" goto kvm_usage
    if /i "%op%" == "ip" goto host_usage
)
call:ShowVersion
goto main_usage
exit /b
::lookupusage

:main_usage
@echo usage: jsa OPERATION ARGUMENTS ...
@echo    or: jsa --version
@echo    or: jsa --help
@echo;
@echo operations:
@echo     ipmi        send an ipmi command
@echo     custom      send custom ipmi commands
@echo     cm          connection monitor
@echo     kvm         KVM
@echo;
@echo Try `jsa OPERATION --help' for more information on OPERATION.
@echo Try `jsa host --help' for description of IPv4 hostname shorthand.
@echo Try `jsa var --help' for description of variables.
exit /b
::main_usage

:ipmi_usage
@echo usage: jsa [ipmi] [OPTIONS...] COMMAND [ARGUMENTS...]
@echo    or: jsa [custom] [OPTIONS...] COMMAND [ARGUMENTS...]
@echo    or: jsa sol [OPTIONS...] [FILENAME.log]
@echo    or: jsa loop [INTERVAL] [OPTIONS...] COMMAND [ARGUMENTS...]
@echo    or: jsa monitor [INTERVAL] [OPTIONS...] COMMAND [ARGUMENTS...]
@echo    or: jsa bootdev DEVICE [efi] [persistent] [OPTIONS...]
@echo    or: jsa br [OPTIONS...]
@echo;
@echo operations:
@echo     ipmi        Send an ipmi command; `ipmi' can be omitted.
@echo     custom      Send a custom ipmi command; try `jsa custom --help' for more.
@echo     sol         Activate an SOL session and save output to a file.
@echo     loop        Send an ipmi command repeatedly, with an interval of INTERVAL
@echo                   second^(s^).
@echo     monitor     Similar to `loop', but only prints updates.
@echo     bootdev     Specify boot device for next boot. If `efi' is specified,
@echo                   append `options=efiboot'; if `persistent' is specified, append
@echo                   `options=persistent'.
@echo     br          Force to enter BIOS Setup on next boot and then power cycle.
@echo;
@echo options:
@echo     -H  Specify hostname; use JSA_DEF_HOSTNAME if not specified.
@echo     -U  Specify username; use JSA_DEF_USERNAME if not specified.
@echo     -P  Specify password; use JSA_DEF_PASSWORD if not specified.
@echo     -I  Specify interface; use JSA_DEF_INTERFACE if not specified.
exit /b
::ipmi_usage

:cm_usage
@echo useage: jsa cm [OPTIONS...]
@echo;
@echo options:
@echo     -l, --legacy        Only monitor ping results, not web accessibility.
@echo     -g, --log-level     Specify log level, default is normal ^(controlled by
@echo                           JSA_CM_LOG_LEVEL^).
@echo                           0, quiet: quiet;
@echo                           1, min: log console outputs;
@echo                           2, normal: also log retries and http code changes.
@echo                           3, max: also log all ping and http code results.
@echo     -p, --ping-retry    Specify retry times before announcing a ping failure.
@echo                           Default is 3 ^(controlled by JSA_CM_PING_RETRY^).
@echo     -w, --web-retry    Specify retry times before announcing the web is down.
@echo                           Default is 2 ^(controlled by JSA_CM_WEB_RETRY^).
exit /b
::cm_usage

:kvm_usage
@echo usage: jsa kvm [OPTIONS...] [JVIEWER_OPTIONS...]
@echo;
@echo options:
@echo     -H              Specify hostname; use JSA_DEF_HOSTNAME if not specified.
@echo     -U              Specify username; use JSA_DEF_USERNAME if not specified.
@echo     -P              Specify password; use JSA_DEF_PASSWORD if not specified.
@echo     -w, --web-port  Specify web port; use JSA_KVM_WEBPORT if not specified.
@echo;
@echo JViewer options:
@echo     -apptype StandAlone
@echo     -localization/-lang Language
@echo     -launch Application Type
exit /b
::kvm_usage

:custom_usage
@echo Write ipmi command to file `custom\COMMAND.txt', one command per line. Lines
@echo starting with `#' will be ignored. Custom commands cannot contain other custom
@echo commands.
@echo;
@echo example:
@echo     write `raw 0x0 0x9 0x5 0x0 0x0' to file `custom\getbootorder.txt', and then
@echo     you can use command `jsa getbootorder' or `jsa custom getbootorder' as a
@echo     shortcut to command `jsa ipmi raw 0x0 0x9 0x5 0x0 0x0'.
exit /b
::custom_usage

:host_usage
@echo HOSTNAME can be either a domain name ^(e.g. www.example.com^) or IP address.
@echo When use IPv4 address as HOSTNAME, you can just specify a part of full IPv4
@echo   address after set the variable JSA_IP_PREF properly.
@echo HOSTNAME can be 1~4 segment^(s^), but
@echo   {segment^(s^) of HOSTNAME} + {segment^(s^) of JSA_IP_PREF} must ^>= 4.
@echo;
@echo example:
@echo -------------------------------------------
@echo HOSTNAME       JSA_IP_PREF      Result IPv4
@echo -------------------------------------------
@echo         7       192.168.0       192.168.0.7
@echo       7.7       192.168.0       192.168.7.7
@echo   7.7.7.7       192.168.0       7.7.7.7
@echo       7.7       192             invalid
@echo -------------------------------------------
@echo;
@echo Try `jsa var --help' for more information on variables.
exit /b
::host_usage

:var_usage
@echo;
@echo Variable / Current Value / Description
@echo --------------------------------------
@echo JSA_IPMIT
@echo     %JSA_IPMIT%
@echo     Path to ipmitool.exe
@echo --------------------------------------
@echo JSA_JVIEWER
@echo     %JSA_JVIEWER%
@echo     Path to jviewer.jar
@echo --------------------------------------
@echo JSA_SOL_LOG_DIR
@echo     %JSA_SOL_LOG_DIR%
@echo     Directory to save sol logs
@echo --------------------------------------
@echo JSA_CM_LOG_DIR
@echo     %JSA_CM_LOG_DIR%
@echo     Directory to save connection monitor logs
@echo --------------------------------------
@echo JSA_IPMI_CUSTOM_DIR
@echo     %JSA_IPMI_CUSTOM_DIR%
@echo     Directory of custom ipmi commands
@echo --------------------------------------
@echo JSA_GLOBAL_COLOR_EN
@echo     %JSA_GLOBAL_COLOR_EN%
@echo     Global control of colorful output. Set to a non-zero value to enable; set
@echo       to 0 to disable.
@echo --------------------------------------
@echo JSA_IP_PREF
@echo     %JSA_IP_PREF%
@echo     IPv4 address prefix, try `jsa host --help' for more information.
@echo --------------------------------------
@echo JSA_DEF_HOSTNAME
@echo     %JSA_DEF_HOSTNAME%
@echo     Default hostname when not specified
@echo --------------------------------------
@echo JSA_DEF_USERNAME
@echo     %JSA_DEF_USERNAME%
@echo     default username of ipmi commands
@echo --------------------------------------
@echo JSA_DEF_PASSWORD
@echo     %JSA_DEF_PASSWORD%
@echo     default password of ipmi commands
@echo --------------------------------------
@echo JSA_DEF_IPMI_INTF
@echo     %JSA_DEF_IPMI_INTF%
@echo     default interface of ipmi commands
@echo --------------------------------------
@echo JSA_IPMI_ECHO_EN
@echo     %JSA_IPMI_ECHO_EN%
@echo     set to a non-zero value to enable echo of ipmi commands; set to 0 to disable
@echo --------------------------------------
@echo JSA_IPMI_ECHO_COLOR
@echo     %JSA_IPMI_ECHO_COLOR%
@echo     color of the echo of ipmi commands: red, green, yellow, blue, magenta,
@echo       cyan.
@echo --------------------------------------
@echo JSA_IPMI_CUSTOM_ECHO_EN
@echo     %JSA_IPMI_CUSTOM_ECHO_EN%
@echo     set to a non-zero value to enable echo of custom ipmi commands; set to 0 to
@echo      disable
@echo --------------------------------------
@echo JSA_IPMI_CUSTOM_ECHO_COLOR
@echo     %JSA_IPMI_CUSTOM_ECHO_COLOR%
@echo     colors of the echo of custom ipmi commands: red, green, yellow, blue,
@echo       magenta, cyan.
@echo --------------------------------------
@echo JSA_LOOP_INTERVAL_S
@echo     %JSA_LOOP_INTERVAL_S%
@echo     The interval between 2 executions when loop an ipmi command ^(in second^)
@echo --------------------------------------
@echo JSA_LOOP_TIMESTAMP_EN
@echo     %JSA_LOOP_TIMESTAMP_EN%
@echo     Set to a non-zero value to enable displaying timestamps when loop an ipmi
@echo       command; set to 0 to disable.
@echo --------------------------------------
@echo JSA_MNTR_INTERVAL_S
@echo     %JSA_MNTR_INTERVAL_S%
@echo     The interval between 2 executions when monitor an ipmi command ^(in second^)
@echo --------------------------------------
@echo JSA_MNTR_TIMESTAMP_EN
@echo     %JSA_MNTR_TIMESTAMP_EN%
@echo     Set to a non-zero value to enable displaying timestamps when monitor an
@echo       ipmi command; set to 0 to disable.
@echo --------------------------------------
@echo JSA_CM_PING_RETRY
@echo     %JSA_CM_PING_RETRY%
@echo     Default ping retry times before announcing a bad connection
@echo --------------------------------------
@echo JSA_CM_WEB_RETRY
@echo     %JSA_CM_WEB_RETRY%
@echo     Default web accessibility query retry times before announcing the web is
@echo       down
@echo --------------------------------------
@echo JSA_CM_LOG_LEVEL
@echo     %JSA_CM_LOG_LEVEL%
@echo     Default log level of connection monitor
@echo --------------------------------------
@echo JSA_CM_COLOR_EN
@echo     %JSA_CM_COLOR_EN%
@echo     Set to a non-zero value to enable colorful output of connection monitor;
@echo       set to 0 to disable.
@echo --------------------------------------
@echo JSA_CM_WEB_TIMEOUT_S
@echo     %JSA_CM_WEB_TIMEOUT_S%
@echo     Web accessibility query timeout ^(in second^)
@echo --------------------------------------
@echo JSA_CM_PING_TIMEOUT_MS
@echo     %JSA_CM_PING_TIMEOUT_MS%
@echo     Ping timeout ^(in millisecond^)
@echo --------------------------------------
@echo JSA_KVM_WEBPORT
@echo     %JSA_KVM_WEBPORT%
@echo     Secure web port of JViewer, default 443
exit /b
::var_usage
