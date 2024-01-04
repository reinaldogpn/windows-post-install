:: -----------------------------------------------------------------------------------------------------
:: * Descrição: Script batch para instalação automatizada de aplicações no Windows 10 e 11. 
:: * Autor: Reinaldo G. P. Neto                                                             
:: * Criado em: 28/04/2023                                                                  
:: -----------------------------------------------------------------------------------------------------
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
::  v1.3 27/05/2023, reinaldogpn:                                                           
::      - Inclusão de novas funções para criação de dois pontos de restauração do sistema   
::      e para download de ferramentas de personalização de elementos do Windows.           
::  v1.4 30/05/2023, reinaldogpn:                                                           
::      - Refatoração e implementação do commando 'curl' para fazer o download das          
::      ferramentas.            
::  v1.5 01/06/2023, reinaldogpn:                                                           
::      - Refatoração e tratamento de erros em algumas funções.
::  v1.6 26/09/2023, reinaldogpn:                                                           
::      - Adição de configurações de energia do Windows (tempo de suspensão e desligamento de monitor).
::  v2.0 04/01/2024, reinaldogpn:
::      - Remoção de pacotes e ferramentas não utilizadas, renovação do código e novas configurações 
::      pessoais para o sistema.
:: -----------------------------------------------------------------------------------------------------

@echo off

setlocal EnableDelayedExpansion
chcp 65001 > nul
cd %~dp0

:: ------------ VARIÁVEIS ------------ ::

set APP_LIST=%~dp0apps.txt
set RESOURCES_PATH=%~dp0resources
set COUNT=0

:: ------------ FUNÇÕES ------------ ::

:: Executando como admin?

echo Verificando privilégios de administrador...
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Este script precisa ser executado com privilégios de administrador.
    goto :end
)

echo.

:: ------------------------ ::

:: Conectado à internet?

echo Verificando conexão com a internet...
ping -n 1 8.8.8.8 >nul 2>&1
if !errorlevel! neq 0 (
    echo Não há conexão com a internet. O script será encerrado.
    goto :end
)

echo.

:: ------------------------ ::

:: Ponto de restauração 1

echo Criando ponto de restauração do sistema...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 1 /f
powershell -Command "Checkpoint-Computer -Description 'Pré Execução do Script Windows Post Install'"
echo Ponto de restauração do sistema criado.

echo.

:: ------------------------ ::

:: Winget instalado?

echo Verificando a existência do Winget...
where winget >nul 2>&1 || (
    echo Instalando o winget e suas dependências...
    powershell -Command "Add-AppxPackage -Path '%RESOURCES_PATH%\winget\Microsoft.UI.Xaml_7.2208.15002.0_X64_msix_en-US.msix'"
    powershell -Command "Add-AppxPackage -Path '%RESOURCES_PATH%\winget\Microsoft.VC.2015.UWP.DRP_14.0.30704.0_X64_msix_en-US.msix'"
    powershell -Command "Invoke-WebRequest 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile winget.msixbundle; .\winget.msi"
    echo y | winget list >nul 2>&1
    if !errorlevel! equ 0 (
        echo Winget está devidamente instalado e configurado.
    ) else (
        echo Ocorreu um erro.
    )
)

echo.

:: ------------------------ ::

:: Configurações de rede

echo Aplicando configurações de rede...
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=in action=allow protocol=UDP localport=16261-16262
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=out action=allow protocol=UDP localport=16261-16262
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=in action=allow protocol=UDP localport=2456-2458
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=out action=allow protocol=UDP localport=2456-2458
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=in action=allow protocol=UDP localport=10889
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=out action=allow protocol=UDP localport=10889
ipconfig /all
echo Configurações de rede aplicadas.

echo.

:: ------------------------ ::

:: Instalação de pacotes

echo Para acrescentar ou remover programas ao script, modifique o arquivo "%APP_LIST%"
echo Para descobrir o ID da aplicação desejada, use "winget search <nomedoapp>" no terminal.
if not exist %APP_LIST% (
    echo Arquivo de lista de aplicativos não encontrado: "%APP_LIST%"
    goto :end
)
for /f "usebackq delims=" %%a in (%APP_LIST%) do (
    set "APP_NAME=%%a"
    winget list !APP_NAME! > nul 2>&1
    if !errorlevel! equ 0 (
        echo !APP_NAME! já está instalado...
    ) else (
        echo Instalando !APP_NAME!...
        winget install --id !APP_NAME! --accept-package-agreements --accept-source-agreements --disable-interactivity --silent
        if !errorlevel! equ 0 set /a COUNT+=1
    )
)
echo %COUNT% aplicativos foram instalados com sucesso.

echo Instalando DriverBooster...
%RESOURCES_PATH%\driver_booster_setup.exe /verysilent /supressmsgboxes

echo.

:: ------------------------ ::

:: Customizações do sistema

:: Taskbar, tema escuro e wallpaper
echo Customizando o Windows
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d 2 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchBoxTaskbarMode" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "ColorPrevalence" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d 100 /f
copy "%RESOURCES_PATH%\wallpaper.png" "%USERPROFILE%\Pictures"
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%USERPROFILE%\Pictures\wallpaper.png" /f
rundll32.exe user32.dll,UpdatePerUserSystemParameters
echo Tema escuro aplicado. Reiniciando o Windows Explorer...
taskkill /F /IM explorer.exe && start explorer.exe

echo.

:: ------------------------ ::

:: Configurações de energia

echo Alterando configurações de energia do Windows...
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0

echo.

:: ------------------------ ::

:: Outros recursos

echo Ativando o recurso DirectPlay...
powershell -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:DirectPlay}"
echo Ativando o recurso .NET Framework 3.5...
powershell -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:NetFx3}"
echo Configurando o git...
%RESOURCES_PATH%\git.bat

echo.

:: ------------------------ ::

:: Ponto de restauração 2

echo Criando ponto de restauração do sistema...
powershell -Command "Checkpoint-Computer -Description 'Pós Execução do Script Windows Post Install'"
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f
echo Ponto de restauração do sistema criado.

echo.

:: ------------ FIM ------------ ::

:end
echo Fim do script!
endlocal
pause
exit /b