@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "DPROJ=D:\sistemas\novatec\cliente\NovatecCliente.dproj"
set "OUTPUT=%ROOT%cliente"
set "LOGDIR=%ROOT%logs"
set "LOG=%LOGDIR%\CompilarCliente.log"
set "VERSION_HELPER=%ROOT%ObterVersaoBuild.ps1"
set "BDSDIR=C:\Program Files (x86)\Embarcadero\Studio\23.0"
set "RSVARS=%BDSDIR%\bin\rsvars.bat"
set "MSBUILD=C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"

if not exist "!DPROJ!" (
    echo ERRO: DPROJ do Cliente nao encontrado: !DPROJ!
    exit /b 10
)

if not exist "!RSVARS!" (
    echo ERRO: ambiente Delphi nao encontrado: !RSVARS!
    exit /b 10
)

if not exist "!MSBUILD!" (
    echo ERRO: MSBuild nao encontrado: !MSBUILD!
    exit /b 10
)

if not exist "!VERSION_HELPER!" (
    echo ERRO: helper de versao nao encontrado: !VERSION_HELPER!
    exit /b 10
)

for /f "delims=" %%V in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!VERSION_HELPER!" -Mode Max') do set "TARGET_FILEVERSION=%%V"
if not defined TARGET_FILEVERSION (
    echo ERRO: nao foi possivel identificar o maior serial.
    exit /b 10
)

for /f "delims=" %%V in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!VERSION_HELPER!" -Mode Keys -ProjectPath "!DPROJ!" -FileVersion "!TARGET_FILEVERSION!"') do set "VERINFO_KEYS=%%V"
if not defined VERINFO_KEYS (
    echo ERRO: nao foi possivel preparar os metadados de versao.
    exit /b 10
)

if not exist "%OUTPUT%" mkdir "%OUTPUT%"
if errorlevel 1 exit /b 50
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
if errorlevel 1 exit /b 50

call "%RSVARS%"
if errorlevel 1 exit /b 10

echo Compilando Cliente Release/Win32...
echo DPROJ: %DPROJ%
echo EXE: %OUTPUT%\NovatecCliente.exe
echo Serial comum: %TARGET_FILEVERSION%

"%MSBUILD%" "%DPROJ%" /t:Build /p:Config=Release /p:Platform=Win32 /p:PostBuildEvent= /p:PostBuildEventIgnoreExitCode=False /p:VerInfo_AutoIncBuild=False /p:VerInfo_AutoIncVersion=False /p:VerInfo_Keys="!VERINFO_KEYS!" /p:DCC_ExeOutput="%OUTPUT%" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo ERRO: compilacao do Cliente falhou. Exit code: %RC%
    echo Log: %LOG%
    exit /b %RC%
)

if not exist "%OUTPUT%\NovatecCliente.exe" (
    echo ERRO: EXE do Cliente nao foi gerado.
    exit /b 40
)

del /q "%OUTPUT%\NovatecCliente.map" "%OUTPUT%\NovatecCliente.drc" 2>nul
echo Cliente compilado com sucesso.
if defined NOVATEC_BUILD_ALL exit /b 0
call "%ROOT%PublicarDistribuicao.bat"
exit /b %ERRORLEVEL%
