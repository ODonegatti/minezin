@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "HORIZON_PORTABLE_ROOT=%~dp0"
set "HORIZON_LAUNCHER_HOME=%HORIZON_PORTABLE_ROOT%data"
set "HORIZON_LAUNCHER=%HORIZON_PORTABLE_ROOT%horizon-launcher.exe"

if not exist "%HORIZON_LAUNCHER%" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%HORIZON_PORTABLE_ROOT%install.ps1" -Dir "%HORIZON_PORTABLE_ROOT%" -NoStart
    if errorlevel 1 (
        echo.
        echo Nao foi possivel instalar o Horizon.
        pause
        exit /b 1
    )
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%HORIZON_PORTABLE_ROOT%repair-native-build.ps1" -PortableRoot "%HORIZON_PORTABLE_ROOT%" -Quiet

set "HORIZON_RUST="
for /f "delims=" %%D in ('dir /b /ad /o-d "%HORIZON_LAUNCHER_HOME%\rust\*-x86_64-pc-windows-gnu" 2^>nul') do if not defined HORIZON_RUST set "HORIZON_RUST=%HORIZON_LAUNCHER_HOME%\rust\%%D"

if defined HORIZON_RUST (
    set "CC=!HORIZON_RUST!\mingw64\bin\gcc.exe"
    set "CFLAGS=-I%USERPROFILE%\.horizon-build-include"
    set "PATH=!HORIZON_RUST!\mingw64\bin;!HORIZON_RUST!\bin;!PATH!"
)

start "" "%HORIZON_LAUNCHER%"
exit /b 0
