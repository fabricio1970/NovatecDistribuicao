@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "NOVATEC_BUILD_ALL=1"

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
