:: ---------------------------------------------------------------------------------------
:: * Descrição: Script batch para instalação automatizada de aplicações no Windows 10/11.
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
::
:: ---------------------------------------------------------------------------------------
@echo off
chcp 65001
setlocal EnableDelayedExpansion
:: ------------ VARIÁVEIS ------------ ::

:: ATUALIZAR A CHAMADA DA FUNÇÃO "installApp" SEMPRE QUE ACRESCENTAR ALGUM PROGRAMA!!
:: Para descobrir o ID da aplicação desejada, use "winget search <nomedoapp>" no terminal.

set apps[0]="Audacity.Audacity"
set apps[1]="Blitz.Blitz"
set apps[2]="Codeblocks.Codeblocks"
set apps[3]="Discord.Discord"
set apps[4]="Dropbox.Dropbox"
set apps[5]="GIMP.GIMP"
set apps[6]="Git.Git"
set apps[7]="Google.Chrome"
set apps[8]="Google.Drive"
set apps[9]="Inkscape.Inkscape"
set apps[10]="RiotGames.LeagueOfLegends.BR"
set apps[11]="Microsoft.VCRedist.2010.x86"
set apps[12]="Microsoft.VCRedist.2010.x64"
set apps[13]="Microsoft.VCRedist.2012.x86"
set apps[14]="Microsoft.VCRedist.2012.x64"
set apps[15]="Microsoft.VCRedist.2013.x86"
set apps[16]="Microsoft.VCRedist.2013.x64"
set apps[17]="Microsoft.VCRedist.2015+.x86"
set apps[18]="Microsoft.VCRedist.2015+.x64"
set apps[19]="Microsoft.VisualStudioCode"
set apps[20]="Notepad++.Notepad++"
set apps[21]="PostgreSQL.PostgreSQL"
set apps[22]="qBittorrent.qBittorrent"
set apps[23]="Valve.Steam"
set apps[24]="VideoLAN.VLC"
set apps[25]="RARLab.WinRAR"
set apps[26]="ApacheFriends.Xampp.8.2"
set apps[27]="Python.Python.3.11"
set apps[28]="Anaconda.Anaconda3"
set apps[29]="WhatsApp.WhatsApp"
set apps[30]="Spotify.Spotify"
set apps[31]="HyperX NGENUITY"
set apps[32]="IObit.DriverBooster"
set apps[33]="OpenJS.NodeJS.LTS"
set apps[34]="Oracle.JavaRuntimeEnvironment"
set apps[35]="Oracle.JDK.19"
set apps[36]="Oracle.VirtualBox"

:: ------------ FUNÇÕES ------------ ::
:checkAdminPrivileges
echo Verificando privilégios de administrador...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Este script precisa ser executado com privilégios de administrador.
    pause
    exit /b
)
echo Privilégios de administrador verificados com sucesso.

:checkInternetConnection
echo Verificando conexão com a internet...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel% neq 0 (
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
for /L %%i in (0,1,36) do (
    winget list !apps[%%i]! > nul 2>&1
    if %errorlevel% equ 0 (
        echo !apps[%%i]! já está instalado...
    ) else (
        echo Instalando !apps[%%i]!...
        winget install !apps[%%i]! -h --accept-package-agreements --accept-source-agreements
    )
)
endlocal

:extraConfig
REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 0 /f
::dism /online /enable-feature /all /featurename:DirectPlay
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:DirectPlay}"
::dism /online /enable-feature /featurename:NetFx4
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx4 -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /featurename:NetFx4}"
winget uninstall "OneDrive" -h --accept-source-agreements
winget uninstall "Microsoft.OneDrive" -h --accept-source-agreements
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
pause
exit /b
