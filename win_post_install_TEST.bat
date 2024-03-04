@echo off

color 1B
setlocal EnableDelayedExpansion
chcp 65001 > nul
cd /d "%~dp0"

REM ------------ VARIÁVEIS ------------ ::

set "APP_LIST=%~dp0apps.txt"
set "RES_DIR=%~dp0resources"

set "OS_name="
set "OS_version="

REM GitHub info for .gitconfig file:
set "GIT_USER=reinaldogpn"
set "GIT_EMAIL=reinaldogpn@outlook.com"
set "GIT_CONFIG_FILE=%USERPROFILE%\.gitconfig"

REM ------------ TESTES ------------ ::

REM Executando como admin?

echo Verificando privilégios de administrador...
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Este script precisa ser executado com privilégios de administrador. O script será encerrado.
    goto :end
)

echo.

REM ------------------------ ::

REM Conectado à internet?

echo Verificando conexão com a internet...
ping -n 1 8.8.8.8 >nul 2>&1
if !errorlevel! neq 0 (
    echo Não há conexão com a internet. O script será encerrado.
    goto :end
)

echo.

REM ------------------------ ::

REM Versão do Windows?

for /f "skip=1 tokens=*" %%a in ('wmic os get Caption') do (
    set "OS_name=%%a"
    goto :next
)
:next

for /f "tokens=3" %%b in ("%OS_name%") do (
    set "OS_version=%%b"
    goto :done
)
:done

echo Sistema operacional identificado: %OS_name%
echo Versão do Windows: %OS_version%

if "%OS_version%" neq "11" (
    if "%OS_version%" neq "10" (
        echo Versão do Windows não suportada. O script será encerrado.
        goto :end
    )
)

echo.

REM ------------------------ ::

REM Winget instalado?

echo Verificando a instalação do winget...
where winget >nul 2>&1 || (
    echo Instalando o winget e suas dependências...
    powershell -Command "Add-AppxPackage -Path '%RES_DIR%\winget\Microsoft.UI.Xaml_7.2208.15002.0_X64_msix_en-US.msix'"
    powershell -Command "Add-AppxPackage -Path '%RES_DIR%\winget\Microsoft.VC.2015.UWP.DRP_14.0.30704.0_X64_msix_en-US.msix'"
    rem powershell -Command "Invoke-WebRequest 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile winget.msixbundle; .\winget.msi"
    powershell -Command "Invoke-WebRequest 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile winget.msixbundle; Add-AppxPackage -Path .\winget.msixbundle"

    echo y | winget list >nul 2>&1
    if !errorlevel! neq 0 (
        echo Falha ao tentar instalar o winget. O script será encerrado.
        goto :end
    )
)

echo Atualizando o winget...
winget upgrade Microsoft.AppInstaller --accept-package-agreements --accept-source-agreements --disable-interactivity --silent >nul 2>&1
if !errorlevel! equ 0 (
    echo Winget está devidamente instalado e atualizado.
) else (
    echo Falha ao tentar atualizar o winget.
)

echo.

REM ------------ FUNÇÕES ------------ ::

REM Ponto de restauração 1

echo Criando ponto de restauração do sistema...
powershell -Command "Enable-ComputerRestore -Drive 'C:\'"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 1 /f
powershell -Command "Checkpoint-Computer -Description 'Pré Execução do Script Windows Post Install'"
echo Ponto de restauração do sistema criado.

echo.

REM ------------------------ ::

REM Configurações e serviços de rede

echo Habilitando serviço FTP...
sc query ftpsvc > nul 2>&1
if %errorlevel% == 0 (
    echo O serviço de FTP (ftpsvc) já está instalado.
) else (
    echo O serviço de FTP (ftpsvc) não está instalado, instalando agora...
    powershell -Command "dism /online /enable-feature /featurename:IIS-WebServerRole /all"
    powershell -Command "dism /online /enable-feature /featurename:IIS-WebServer /all"
    powershell -Command "dism /online /enable-feature /featurename:IIS-FTPServer /all"
)

echo Habilitando serviço SSH...
sc query ssh-agent > nul 2>&1
if %errorlevel% == 0 (
    echo O serviço SSH (ssh-agent) já está instalado.
) else (
    echo O serviço SSH (ssh-agent) não está instalado, instalando agora...
    powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Client"
    powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Server"
    powershell -Command "Start-Service sshd"
    powershell -Command "Set-Service -Name sshd -StartupType 'Automatic'"
)

echo Criando regras de firewall para serviços e game servers...
netsh advfirewall firewall add rule name="FTP" dir=in action=allow protocol=TCP localport=21
netsh advfirewall firewall add rule name="SSH" dir=in action=allow protocol=TCP localport=22
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=in action=allow protocol=UDP localport=16261-16262
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=out action=allow protocol=UDP localport=16261-16262
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=in action=allow protocol=UDP localport=2456-2458
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=out action=allow protocol=UDP localport=2456-2458
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=in action=allow protocol=UDP localport=10889
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=out action=allow protocol=UDP localport=10889
ipconfig /all

echo Configurações de rede aplicadas.

echo.

REM ------------------------ ::

REM Instalação de pacotes

echo Para acrescentar ou remover pacotes ao script, modifique o arquivo "%APP_LIST%"
echo Para descobrir o ID da aplicação desejada, use "winget search <nomedoapp>" no terminal.
if not exist %APP_LIST% (
    echo Lista de pacotes não encontrada: "%APP_LIST%"
    goto :end
)

set "count=0"
for /f "usebackq delims=" %%a in (%APP_LIST%) do (
    set "app_name=%%a"
    winget list !app_name! > nul 2>&1
    if !errorlevel! equ 0 (
        echo !app_name! já está instalado...
    ) else (
        echo Instalando !app_name!...
        winget install --id !app_name! --accept-package-agreements --accept-source-agreements --disable-interactivity --silent
        if !errorlevel! equ 0 set /a count+=1
    )
)
echo %count% pacotes foram instalados com sucesso.

echo Instalando DriverBooster...
%RES_DIR%\driver_booster_setup.exe /verysilent /supressmsgboxes

echo.

REM ------------------------ ::

REM Customizações do sistema

REM Taskbar, tema escuro e wallpaper
echo Customizando o Windows
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d 2 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchBoxTaskbarMode" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "ColorPrevalence" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d 100 /f
copy "%RES_DIR%\wallpaper.png" "%USERPROFILE%\wallpaper.png"
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%USERPROFILE%\wallpaper.png" /f
rundll32.exe user32.dll,UpdatePerUserSystemParameters
echo Tema escuro aplicado. Reiniciando o Windows Explorer...
taskkill /F /IM explorer.exe && start explorer.exe

echo.

REM ------------------------ ::

REM Configurações de energia

echo Alterando configurações de energia do Windows...
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0

echo.

REM ------------------------ ::

REM Outros recursos

rem echo Ativando o recurso DirectPlay...
rem powershell -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:DirectPlay}"
rem echo Ativando o recurso .NET Framework 3.5...
rem powershell -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:NetFx3}"

echo Configurando o git...
rem copy "%RES_DIR%\gitconfig.txt" "%USERPROFILE%\.gitconfig"
echo [user] >> %GIT_CONFIG_FILE%
echo     name = %GIT_USER% >> %GIT_CONFIG_FILE%
echo     email = %GIT_EMAIL% >> %GIT_CONFIG_FILE%

echo.

REM ------------------------ ::

REM Ponto de restauração 2

echo Criando ponto de restauração do sistema...
powershell -Command "Checkpoint-Computer -Description 'Pós Execução do Script Windows Post Install'"
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f
echo Ponto de restauração do sistema criado.

echo.

REM ------------ FIM ------------ ::

:end
echo Fim do script!
endlocal
pause
color 07
exit /b
