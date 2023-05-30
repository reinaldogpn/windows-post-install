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
:: -------------------------------------------------------------------------------------------

@echo off

color 0a
setlocal EnableDelayedExpansion
chcp 65001 > nul
cd %~dp0

:: ------------ VARIÁVEIS ------------ ::

set APP_LIST_FILE="applist.txt"
set COUNT=0
set DOWNLOAD_FOLDER=C:\Users\%USERNAME%\Downloads\Tools

:: ------------ FUNÇÕES ------------ ::
:checkAdminPrivileges
echo Verificando privilégios de administrador...
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Este script precisa ser executado com privilégios de administrador.
    pause
    goto :end
)
:: FIM ::

:checkInternetConnection
echo Verificando conexão com a internet...
ping -n 1 8.8.8.8 >nul 2>&1
if !errorlevel! neq 0 (
    echo Não há conexão com a internet. O script será encerrado.
    pause
    goto :end
)
:: FIM ::

:createRestorePoint1
echo Criando ponto de restauração do sistema...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 5 /f
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
echo Todas as ferramentas necessárias estão instaladas!
:: FIM ::

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
    ) else (
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
    )
)
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
taskkill /F /IM explorer.exe && start explorer.exe
echo Tema escuro aplicado.
:: FIM ::

:downloadTools
echo Fazendo download de ferramentas de customização do sistema...
mkdir "%DOWNLOAD_FOLDER%"
curl -L "https://github.com/MicaForEveryone/MicaForEveryone/releases/latest/download/MicaForEveryone-x64-Release-Installer.exe" -o "%DOWNLOAD_FOLDER%\MicaForEveryone.exe"
curl -L "https://github.com/MicaForEveryone/ExplorerFrame/releases/download/v0.2.0.0/ExplorerFrame-0.2.0.0-x64.zip" -o "%DOWNLOAD_FOLDER%\ExplorerFrame.zip"
curl -L "https://github.com/thebookisclosed/ViVe/releases/latest/download/ViVeTool-v0.3.3.zip" -o "%DOWNLOAD_FOLDER%\ViVeTool.zip"
curl -L "https://windows.php.net/downloads/releases/php-8.2.6-nts-Win32-vs16-x64.zip" -o "%DOWNLOAD_FOLDER%\php-8.2.6.zip"
curl -L "https://sonik.dl.sourceforge.net/project/luabinaries/5.4.2/Tools%20Executables/lua-5.4.2_Win64_bin.zip" -o "%DOWNLOAD_FOLDER%\lua-5.4.2.zip"
curl -L "https://download.virtualbox.org/virtualbox/7.0.8/Oracle_VM_VirtualBox_Extension_Pack-7.0.8.vbox-extpack" -o "%DOWNLOAD_FOLDER%\Oracle_VM_VirtualBox_Extension_Pack-7.0.8.vbox-extpack"
curl -L "https://github.com/liballeg/allegro5/releases/download/5.2.8.0/allegro-x86_64-w64-mingw32-gcc-12.1.0-posix-seh-static-5.2.8.0.zip" -o "%DOWNLOAD_FOLDER%\allegro-static-5.2.8.zip"
curl -L "https://get.enterprisedb.com/postgresql/postgresql-15.3-1-windows-x64.exe" -o "%DOWNLOAD_FOLDER%\PostgreSQL15.exe"
curl -L "https://github.com/MishaProductions/Rectify11Installer/releases/download/v-3.0-rp3/Rectify11Installer.exe" -o "%DOWNLOAD_FOLDER%\Rectify11.exe"
echo Download completo. Arquivos salvos em: "%DOWNLOAD_FOLDER%"
:: FIM ::

:extraConfig
echo Ativando o recurso DirectPlay...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:DirectPlay}"
echo Ativando o recurso .NET Framework 3.5...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:NetFx3}"
:: FIM ::

:purgeOneDrive
echo Desinstalando OneDrive...
winget uninstall "Microsoft.OneDriveSync_8wekyb3d8bbwe" -h --accept-source-agreements
winget uninstall "Microsoft.OneDrive" -h --accept-source-agreements
powershell.exe -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name DisableFileSyncNGSC -Value 1"
powershell.exe -Command "gpupdate /force"
if not exist "%USERPROFILE%\Área de Trabalho\" mkdir "%USERPROFILE%\Área de Trabalho\"
move /Y "%USERPROFILE%\OneDrive\Área de Trabalho\*" "%USERPROFILE%\Área de Trabalho\"
if exist "%USERPROFILE%\OneDrive\Área de Trabalho" rmdir /s /q "%USERPROFILE%\OneDrive\Área de Trabalho"
if not exist "%USERPROFILE%\Pictures\" mkdir "%USERPROFILE%\Pictures\"
move /Y "%USERPROFILE%\OneDrive\Pictures\*" "%USERPROFILE%\Pictures\"
if exist "%USERPROFILE%\OneDrive\Pictures" rmdir /s /q "%USERPROFILE%\OneDrive\Pictures"
if not exist "%USERPROFILE%\Documents" mkdir "%USERPROFILE%\Documents"
move /Y "%USERPROFILE%\OneDrive\Documents\*" "%USERPROFILE%\Documents\"
if exist "%USERPROFILE%\OneDrive\Documents" rmdir /s /q "%USERPROFILE%\OneDrive\Documents"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Desktop" /t REG_EXPAND_SZ /d "%USERPROFILE%\Área de Trabalho" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Personal" /t REG_EXPAND_SZ /d "%USERPROFILE%\Documents" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Pictures" /t REG_EXPAND_SZ /d "%USERPROFILE%\Pictures" /f
echo OneDrive foi completamente expurgado!
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
