:: -----------------------------------------------------------------------------------------
:: * Descrição: Script batch para instalação automatizada de aplicações no Windows 10 e 11.
:: * Autor: Reinaldo G. P. Neto
:: * Criado em: 28/04/2023
:: -----------------------------------------------------------------------------------------
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
::  v1.2 28/04/2023, reinaldogpn:
::      - Mudanças na estrutura geral do script, além de pequenas correções e ajustes.
::
:: -----------------------------------------------------------------------------------------

@echo off

color 0a
setlocal EnableDelayedExpansion
chcp 65001 > nul
cd %~dp0

:: ------------ VARIÁVEIS ------------ ::
set APP_LIST_FILE="applist.txt"
set COUNT=0
:: ------------ FUNÇÕES ------------ ::
:checkAdminPrivileges
echo Verificando privilégios de administrador...
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Este script precisa ser executado com privilégios de administrador.
    pause
    goto :end

:checkInternetConnection
echo Verificando conexão com a internet...
ping -n 1 8.8.8.8 >nul 2>&1
if !errorlevel! neq 0 (
    echo Não há conexão com a internet. O script será encerrado.
    pause
    goto :end

:checkNecessaryTools
echo Verificando a existência das ferramentas necessárias...
where winget >nul 2>&1 || (
    echo Instalando o winget...
    powershell -c "Invoke-WebRequest https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile winget.msixbundle; .\winget.msixbundle"
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

if not exist %APP_LIST_FILE% (
    echo Arquivo de lista de aplicativos não encontrado: %APP_LIST_FILE%
    echo Tentando fazer o download...
    powershell -c "Invoke-WebRequest https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/applist.txt -OutFile applist.txt"
    if not exist %APP_LIST_FILE% (
        echo Falha ao fazer o download da lista de aplicativos: %APP_LIST_FILE%
        goto :end
    )
)
    
for /f "usebackq delims=" %%a in (%APP_LIST_FILE%) do (
    set "APP_NAME=%%a"
    winget list !APP_NAME! > nul 2>&1
    if !errorlevel! equ 0 (
        echo !APP_NAME! já está instalado...
    ) else (
        echo Instalando !APP_NAME!...
        winget install !APP_NAME! -h --accept-package-agreements --accept-source-agreements
        if !errorlevel! equ 0 set /a COUNT+=1
    )
)
echo %COUNT% aplicativos foram instalados com sucesso.

:netConfig
echo Criando regras no firewall e aplicando configurações de rede...
:: Configurações da rede
netsh interface ipv4 set address name="Ethernet" static 192.168.0.116 255.255.255.0 192.168.0.1
netsh interface ipv4 set dns "Ethernet" static 8.8.8.8
netsh interface ipv4 add dns "Ethernet" 8.8.4.4 index=2
:: Regras para o firewall
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=in action=allow protocol=UDP localport=16261,16262
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=out action=allow protocol=UDP localport=16261,16262
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=in action=allow protocol=UDP localport=2456,2457
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=out action=allow protocol=UDP localport=2456,2457
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=in action=allow protocol=UDP localport=10889
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=out action=allow protocol=UDP localport=10889
:: Fim das regras
ipconfig /all
echo Configurações de rede aplicadas.

:applyDarkTheme
echo Aplicando tema escuro...
REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 0 /f
REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v ColorPrevalence /t REG_DWORD /d 1 /f
REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v SystemUsesLightTheme /t REG_DWORD /d 0 /f
echo Tema escuro aplicado.

:extraConfig
echo Ativando o recurso DirectPlay...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:DirectPlay}"
echo Ativando o recurso .NET Framework 3.5...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:NetFx3}"
echo Desinstalando OneDrive...
winget uninstall "OneDrive" -h --accept-source-agreements

:updateWindows
echo Procurando por atualizações...
wuauclt.exe /detectnow /updatenow
echo Se disponíveis, atualizações serão baixadas e instaladas...

:: ------------ FIM ------------ ::

:end
endlocal
pause
exit /b
