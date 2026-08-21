@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "NOVATEC_BUILD_ALL=1"

ssh-add -l 2>nul | findstr /c:"SHA256:Y76+xKkyLleAq+m3qxNwqmyNK+hfAQIEqXvWtQ9A8PI" >nul
if errorlevel 1 (
    echo Carregando chave SSH...
    ssh-add "%USERPROFILE%\.ssh\id_ed25519_novatec"
    if errorlevel 1 (
        echo ERRO: nao foi possivel carregar a chave SSH.
        exit /b 60
    )
)
set "NOVATEC_SSH_READY=1"

echo ================================================
echo COMPILANDO NOVATEC SERVIDOR E CLIENTE
echo ================================================
echo.

call "%ROOT%CompilarServidor.bat"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo ERRO: etapa do Servidor falhou. Exit code: %RC%
    exit /b %RC%
)

call "%ROOT%CompilarCliente.bat"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo ERRO: etapa do Cliente falhou. Exit code: %RC%
    exit /b %RC%
)

call "%ROOT%PublicarDistribuicao.bat"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo ERRO: publicacao no Git falhou. Exit code: %RC%
    exit /b %RC%
)

echo.
echo ================================================
echo COMPILACAO CONCLUIDA COM SUCESSO
echo ================================================
exit /b 0
