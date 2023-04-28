:: ---------------------------------------------------------------------------------------
:: * Descrição: Script batch para instalação automatizada de aplicações no Windows 11.
:: * Autor: Reinaldo G. P. Neto
:: * Criado em: 28/04/2023
:: ---------------------------------------------------------------------------------------
::
:: * Changelog:
::
::  v1.0 28/04/2023, reinaldogpn:
::      - Criação do script bruto, polimentos serão feitos futuramente =D. O script
::      realiza testes, instala as ferramentas necessárias para a execução, instala 
::      alguns programas úteis e faz a atualização do sistema.
::  v1.1 28/04/2023, reinaldogpn:
::      - Correção do uso da variável de ambiente "!errorlevel!" para funcionar
::      corretamente no Windows 10; agora os aplicativos a serem instalados são definidos
::      dentro do arquivo "applist.txt" e não mais em variáveis dentro do script.
:: ---------------------------------------------------------------------------------------

@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

:: ------------ VARIÁVEIS ------------ ::
set "APP_LIST_FILE=applist.txt"

:: ------------ FUNÇÕES ------------ ::
:checkAdminPrivileges
echo Verificando privilégios de administrador...
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Este script precisa ser executado com privilégios de administrador.
    pause
    exit /b
)
echo Privilégios de administrador verificados com sucesso.

:checkInternetConnection
echo Verificando conexão com a internet...
ping -n 1 8.8.8.8 >nul 2>&1
if !errorlevel! neq 0 (
    echo Não há conexão com a internet. O script será encerrado.
    pause
    exit
) else (
    echo Conexão com a internet OK.
)

:checkNecessaryTools
echo Verificando a existência das ferramentas necessárias...
where winget >nul 2>&1 || (
    echo Instalando o winget...
    powershell -c "Invoke-WebRequest https://github.com/microsoft/winget-cli/releases/download/v1.0.11692/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appinstaller -OutFile winget.appinstaller; .\winget.appinstaller"
)
where dism >nul 2>&1 || (
    echo Instalando o dism...
    dism /online /enable-feature /featurename:NetFx3 /all /norestart
)
where wuauclt.exe >nul 2>&1 || (
    echo Instalando o wuauclt.exe...
    powershell -c "Start-Process wuinstall.exe -Verb RunAs"
)
echo Todas as ferramentas necessárias estão instaladas!

:installApps
echo Para acrescentar ou remover programas ao script, modifique o arquivo "applist.txt"
echo Para descobrir o ID da aplicação desejada, use "winget search <nomedoapp>" no terminal.

if not exist "%APP_LIST_FILE%" (
  echo Arquivo de lista de aplicativos não encontrado: "%APP_LIST_FILE%"
  exit /b 1
)
for /f "usebackq delims=" %%a in ("%APP_LIST_FILE%") do (
  set "APP_NAME=%%a"
  winget list !APP_NAME! > nul 2>&1
  if !errorlevel! equ 0 (
    echo !APP_NAME! já está instalado...
  ) else (
    echo Instalando !APP_NAME!...
    winget install !APP_NAME! -h --accept-package-agreements --accept-source-agreements
  )
)

:extraConfig
echo Aplicando tema escuro.
REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 0 /f
echo Ativando o recurso DirectPlay...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:DirectPlay}"
echo Ativando o recurso .NET Framework 3.5...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:NetFx3}"
echo Desinstalando OneDrive...
winget uninstall "OneDrive" -h --accept-source-agreements
winget uninstall "Microsoft.OneDrive" -h --accept-source-agreements
echo Atualizando aplicações...
winget upgrade --all -h

:updateWindows
set /p answer="Deseja atualizar o Windows agora? (S/N) "
if /i "%answer%"=="s" (
    echo Procurando por atualizações...
    wuauclt.exe /detectnow /updatenow
    echo Aguarde enquanto as atualizações são baixadas e instaladas...
    timeout /t 300 /nobreak
    echo As atualizações foram instaladas com sucesso!
) else (
    echo A atualização foi cancelada pelo usuário.
    pause
    exit
)

:: ------------ EXECUÇÃO ------------ ::

call :checkAdminPrivileges
call :checkInternetConnection
call :checkNecessaryTools
call :installApps
call :extraConfig
call :updateWindows

:: Fim do script
endlocal
pause
exit /b
