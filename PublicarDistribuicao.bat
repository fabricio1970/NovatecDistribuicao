@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "REPO=%ROOT%."
set "CLIENT_EXE=%ROOT%cliente\NovatecCliente.exe"
set "SERVER_EXE=%ROOT%servidor\NovatecServidor.exe"
set "CLIENT_VERSION=%ROOT%cliente\version.txt"
set "SERVER_VERSION=%ROOT%servidor\version.txt"

if not exist "!CLIENT_EXE!" (
    echo ERRO: EXE do Cliente nao encontrado: !CLIENT_EXE!
    exit /b 40
)

if not exist "!SERVER_EXE!" (
    echo ERRO: EXE do Servidor nao encontrado: !SERVER_EXE!
    exit /b 40
)

for /f "delims=" %%V in ('powershell -NoProfile -Command "(Get-Item -LiteralPath '!CLIENT_EXE!').VersionInfo.FileVersion"') do set "CLIENT_FILEVERSION=%%V"
for /f "delims=" %%V in ('powershell -NoProfile -Command "(Get-Item -LiteralPath '!SERVER_EXE!').VersionInfo.FileVersion"') do set "SERVER_FILEVERSION=%%V"

if not defined CLIENT_FILEVERSION (
    echo ERRO: versao do Cliente nao identificada.
    exit /b 40
)

if not defined SERVER_FILEVERSION (
    echo ERRO: versao do Servidor nao identificada.
    exit /b 40
)

if not "!CLIENT_FILEVERSION!"=="!SERVER_FILEVERSION!" (
    echo ERRO: Cliente e Servidor possuem versoes diferentes.
    echo Cliente: !CLIENT_FILEVERSION!
    echo Servidor: !SERVER_FILEVERSION!
    exit /b 40
)

>"!CLIENT_VERSION!" echo !CLIENT_FILEVERSION!
if errorlevel 1 exit /b 50
>"!SERVER_VERSION!" echo !SERVER_FILEVERSION!
if errorlevel 1 exit /b 50

git -C "!REPO!" add -- "cliente\NovatecCliente.exe" "cliente\version.txt" "servidor\NovatecServidor.exe" "servidor\version.txt" "CompilarCliente.bat" "CompilarServidor.bat" "CompilarTudo.bat" "ObterVersaoBuild.ps1" "PublicarDistribuicao.bat" "docs\build-pipeline-map.md"
if errorlevel 1 (
    echo ERRO: git add falhou.
    exit /b 60
)

git -C "!REPO!" diff --cached --quiet -- "cliente\NovatecCliente.exe" "cliente\version.txt" "servidor\NovatecServidor.exe" "servidor\version.txt" "CompilarCliente.bat" "CompilarServidor.bat" "CompilarTudo.bat" "ObterVersaoBuild.ps1" "PublicarDistribuicao.bat" "docs\build-pipeline-map.md"
if not errorlevel 1 (
    echo Nenhuma alteracao para commit.
    exit /b 0
)

git -C "!REPO!" commit -m "Release Cliente e Servidor v!CLIENT_FILEVERSION!"
if errorlevel 1 (
    echo ERRO: git commit falhou.
    exit /b 60
)

git -C "!REPO!" push origin main
if errorlevel 1 (
    echo ERRO: git push falhou.
    exit /b 60
)

echo Git atualizado: Release Cliente e Servidor v!CLIENT_FILEVERSION!
exit /b 0
