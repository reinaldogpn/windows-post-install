:: -------------------------------------------------------------------------------------------
:: * Descrição: Script batch para instalação automatizada de aplicações no Windows 10 e 11. 
:: * Autor: Reinaldo G. P. Neto                                                             
:: * Criado em: 28/04/2023                                                                  
:: -------------------------------------------------------------------------------------------
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
:: -------------------------------------------------------------------------------------------

@echo off

color 0a
setlocal EnableDelayedExpansion
chcp 65001 > nul
cd %~dp0

:: ------------ VARIÁVEIS ------------ ::

set APP_LIST=apps.txt
set URL_LIST=urls.txt
set COUNT=0
set DOWNLOAD_FOLDER=%USERPROFILE%\Downloads\Tools

:: ------------ FUNÇÕES ------------ ::
:checkAdminPrivileges
echo Verificando privilégios de administrador...
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Este script precisa ser executado com privilégios de administrador.
    goto :end
)
:: FIM ::

:checkInternetConnection
echo Verificando conexão com a internet...
ping -n 1 8.8.8.8 >nul 2>&1
if !errorlevel! neq 0 (
    echo Não há conexão com a internet. O script será encerrado.
    goto :end
)
:: FIM ::

:createRestorePoint1
echo Criando ponto de restauração do sistema...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 1 /f
powershell -Command "Checkpoint-Computer -Description 'Execução do Script Windows Post Install'"
echo Ponto de restauração do sistema criado.
:: FIM ::

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

where curl > nul 2>&1 || (
    echo Instalando o curl...
    winget install cURL.cURL -h --accept-package-agreements --accept-source-agreements
    if !errorlevel! neq 0 (
        echo Erro ao instalar o curl!
        goto :end
    )
)
echo Todas as ferramentas necessárias estão instaladas.
:: FIM ::

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
:: FIM ::

:applyDarkTheme
echo Aplicando tema escuro...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v ColorPrevalence /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f
echo Tema escuro aplicado. O processo explorer.exe será reiniciado.
pause
taskkill /F /IM explorer.exe && start explorer.exe
:: FIM ::

:downloadTools
echo Fazendo download de ferramentas...

if not exist %URL_LIST% (
    echo Arquivo de lista de URLs não encontrado: "%URL_LIST%"
    echo Tentando fazer o download...
    powershell -c "Invoke-WebRequest https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/%URL_LIST% -OutFile %URL_LIST%"
    if not exist %URL_LIST% (
        echo Falha ao fazer o download da lista de aplicativos: "%URL_LIST%"
        goto :end
    ) 
)

if not exist "%DOWNLOAD_FOLDER%" mkdir "%DOWNLOAD_FOLDER%"
for /f "usebackq delims=" %%i in (%URL_LIST%) do (
    if not exist "%DOWNLOAD_FOLDER%\%%~nxi" (
        echo Fazendo o download de "%%~nxi"...
        curl -L "%%i" -o "%DOWNLOAD_FOLDER%\%%~nxi" > nul
    ) else (
        echo Arquivo "%%~nxi" já existe.
    )
)

echo Download completo. Arquivos salvos em: "%DOWNLOAD_FOLDER%"
:: FIM ::

:extraConfig
echo Ativando o recurso DirectPlay...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:DirectPlay}"
echo Ativando o recurso .NET Framework 3.5...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:NetFx3}"
:: FIM ::

:purgeOneDrive
set OD_FOLDER=%USERPROFILE%\OneDrive
set OD_DESKTOP=%USERPROFILE%\OneDrive\Desktop
set OD_DOCUMENTS=%USERPROFILE%\OneDrive\Documents
set OD_PICTURES=%USERPROFILE%\OneDrive\Pictures

echo Desinstalando OneDrive...
winget uninstall "Microsoft.OneDriveSync_8wekyb3d8bbwe" -h --accept-source-agreements >nul 2>&1
winget uninstall "Microsoft.OneDrive" -h --accept-source-agreements >nul 2>&1
powershell.exe -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\System\DisableOneDriveFileSync' -Name value -Value 1"
powershell.exe -Command "gpupdate /force"

echo Restaurando caminho padrão das pastas de usuário...
ver | findstr /i "Windows 11"
if %errorlevel%==0 (
    echo Você está usando o Windows 11.

    if not exist "%USERPROFILE%\Desktop" mkdir "%USERPROFILE%\Desktop"
    if exist "%OD_DESKTOP%" move /y "%OD_DESKTOP%\*" "%USERPROFILE%\Desktop"

    if not exist "%USERPROFILE%\Documents" mkdir "%USERPROFILE%\Documents"
    if exist "%OD_DOCUMENTS%" move /y "%OD_DOCUMENTS%\*" "%USERPROFILE%\Documents"

    if not exist "%USERPROFILE%\Pictures" mkdir "%USERPROFILE%\Pictures"
    if exist "%OD_PICTURES%" move /y "%OD_PICTURES%\*" "%USERPROFILE%\Pictures"

    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Desktop" /t REG_EXPAND_SZ /d "%USERPROFILE%\Desktop" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Pictures" /t REG_EXPAND_SZ /d "%USERPROFILE%\Pictures" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Personal" /t REG_EXPAND_SZ /d "%USERPROFILE%\Documents" /f

    if exist "%OD_FOLDER%" rmdir /s /q "%OD_FOLDER%"
) else (
    echo Você não está usando o Windows 11.
)
echo OneDrive foi completamente expurgado!
:: FIM ::

:installApps
echo Para acrescentar ou remover programas ao script, modifique o arquivo "%APP_LIST%"
echo Para descobrir o ID da aplicação desejada, use "winget search <nomedoapp>" no terminal.
if not exist %APP_LIST% (
    echo Arquivo de lista de aplicativos não encontrado: "%APP_LIST%"
    echo Tentando fazer o download...
    powershell -c "Invoke-WebRequest https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/%APP_LIST% -OutFile %APP_LIST%"
    if not exist %APP_LIST% (
        echo Falha ao fazer o download da lista de aplicativos: "%APP_LIST%"
        goto :end
    ) 
)
for /f "usebackq delims=" %%a in (%APP_LIST%) do (
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
:: FIM ::

:updateWindows
echo Procurando por atualizações...
wuauclt.exe /detectnow /updatenow
echo Se disponíveis, atualizações serão baixadas e instaladas...
:: FIM ::

:createRestorePoint2
echo Criando ponto de restauração do sistema...
powershell -Command "Checkpoint-Computer -Description 'Pós Execução do Script Windows Post Install'"
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f
echo Ponto de restauração do sistema criado.
:: FIM ::

:: ------------ FIM ------------ ::

:end
echo Fim do script!
endlocal
pause
exit /b
