<#
.SYNOPSIS
    Este é um script de customização do Windows.

.DESCRIPTION
    Este script automatiza a configuração e personalização do Windows. Compatível com Windows 10 ou superior.

.AUTHOR
    reinaldogpn

.DATE
    06/03/2024
#>

param (
    [string]$option = "?" # ? = show options; -s | --server = install server tools only; -c | --client = install client tools only; -f | --full = full installation
)

# ------------ VARIÁVEIS ------------ #

$CLIENT_PKGS  = "9NKSQGP7F2NH", # Whatsapp Desktop
                "9NCBCSZSJRSB", # Spotify Client
                "9PF4KZ2VN4W9", # TranslucentTB
                "Adobe.Acrobat.Reader.64-bit",
                "AnyDeskSoftwareGmbH.AnyDesk",
                "CPUID.CPU-Z",
                "Discord.Discord",
                "EpicGames.EpicGamesLauncher",
                "Git.Git",
                "Google.Chrome",
                "HyperX NGENUITY",
                "Microsoft.DotNet.DesktopRuntime.3_1",
                "Microsoft.VCRedist.2010.x86",
                "Microsoft.VCRedist.2010.x64",
                "Microsoft.VCRedist.2012.x86",
                "Microsoft.VCRedist.2012.x64",
                "Microsoft.VCRedist.2013.x86",
                "Microsoft.VCRedist.2013.x64",
                "Microsoft.VCRedist.2015+.x86",
                "Microsoft.VCRedist.2015+.x64",
                "Microsoft.XNARedist",
                "Microsoft.VisualStudioCode",
                "Notepad++.Notepad++",
                "OpenJS.NodeJS.LTS",
                "Oracle.JavaRuntimeEnvironment",
                "Oracle.JDK.18",
                "Python.Python.3.11",
                "qBittorrent.qBittorrent",
                "RARLab.WinRAR",
                "TeamViewer.TeamViewer",
                "Valve.Steam",
                "VideoLAN.VLC"

$SERVER_PKGS  = "AnyDeskSoftwareGmbH.AnyDesk",
                "RARLab.WinRAR",
                "TeamViewer.TeamViewer"

$UserProfile = $env:USERPROFILE
$ResourcesPath = Join-Path -Path $PSScriptRoot -ChildPath "resources"

$OS_name = ""
$OS_version = ""

# GitHub info for .gitconfig file:

$GitUser = "reinaldogpn"
$GitEmail = "reinaldogpn@outlook.com"
$GitConfigFile = Join-Path -Path $UserProfile -ChildPath ".gitconfig"

# ------------ FUNÇÃO DE SAÍDA ------------ #

function exitScript {
    param ([int]$err = 0)

    switch ($err) {

        0 {
            Write-Host "Fim do script!"
            exit
        }

        1 {
            Write-Error -Message "Este script deve ser executado como Administrador!" -ErrorId $err -Category PermissionDenied
            exit
        }

        2 {
            Write-Error -Message "O computador precisa estar conectado à internet para executar este script!" -ErrorId $err -Category ConnectionError
            exit
        }

        3 {
            Write-Error -Message "Versão do windows não suportada!" -ErrorId $err -Category DeviceError
            exit
        }

        4 {
            Write-Error -Message "Script encerrado pelo usuário!" -ErrorId $err -Category ResourceUnavailable
            exit
        }

        5 {
            Write-Error -Message "Parâmetro inválido! Para obter a lista de parâmetros use -? ou --help" -ErrorId $err -Category InvalidArgument
            exit
        }
    }
}

# ------------ TESTES ------------- #

# Executando como admin?

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    exitScript 1
}

# Conectado à internet?

Write-Host "Verificando conexão com a internet..."

Test-NetConnection -ErrorAction SilentlyContinue

if (-not $?) {
    exitScript 2
}

# O sistema é compatível?

Write-Host "Verificando compatibilidade do sistema..."

$OS_name = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption -ErrorAction SilentlyContinue

if (-not $OS_name) {
    Write-Warning -Message "Sistema operacional não encontrado."
    exitScript 3
} 
else {
    Write-Host "Sistema operacional identificado: $OS_name"
    $OS_version = ($OS_name -split ' ')[2]

    if ($OS_version -lt 10) {
        exitScript 3
    } 
    else {
        Write-Host "Versão do sistema operacional: $OS_version"
    }
}

# Winget instalado?

Write-Host "Verificando instalação do winget..."

try {
    $wingetVer = winget -v
} 
catch {
    Write-Warning -Message "Winget não está instalado. Tentando instalar agora..."
    Add-AppxPackage -Path $ResourcesPath\winget\Microsoft.UI.Xaml_7.2208.15002.0_X64_msix_en-US.msix -ErrorAction SilentlyContinue
    Add-AppxPackage -Path $ResourcesPath\winget\Microsoft.VC.2015.UWP.DRP_14.0.30704.0_X64_msix_en-US.msix -ErrorAction SilentlyContinue
    Add-AppxPackage -Path $ResourcesPath\winget\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -ErrorAction SilentlyContinue
}

if ($wingetVer -cne 'v1.7.10582') {
    Write-Host "Atualizando o Winget..."
    Add-AppxPackage -Path $ResourcesPath\winget\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -ForceApplicationShutdown -ErrorAction SilentlyContinue
} 
else {
    Write-Host "Winget está devidamente instalado e atualizado."
}

# ------------ FUNÇÕES ------------ #

# Ponto de restauração 1

function setFirstCheckpoint {
    Write-Host "Criando ponto de restauração do sistema..."
    Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue
    REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 1 /f
    Checkpoint-Computer -Description 'Pré Execução do Script Windows Post Install' -ErrorAction SilentlyContinue
    
    if (-not $?) {
        Write-Warning "Falha ao criar ponto de restauração do sistema. Deseja continuar mesmo assim? (s = sim | n = não)" ; $i = Read-Host
        if ($i -ceq "n") {
            exitScript 4
        }
    }
    else {
        Write-Host "Ponto de restauração do sistema criado."
    }
}

# Configurações e serviços de rede

function setNetworkOptions {
    # FTP service

    Write-Host "Habilitando serviço de FTP..."
    $ftpService = Get-Service -Name "ftpsvc" -ErrorAction SilentlyContinue

    if (-not $ftpService) {
        Write-Host "O serviço de FTP (ftpsvc) não está habilitado, habilitando agora..."
        Install-WindowsFeature Web-Ftp-Server
    }
    else {
        Write-Host "O serviço de FTP (ftpsvc) já está habilitado."
    }

    Start-Service -Name "ftpsvc"
    Set-Service -Name "ftpsvc" -StartupType Automatic

    # SSH service

    Write-Host "Habilitando serviço de SSH..."
    $sshService = Get-Service -Name "sshd" -ErrorAction SilentlyContinue

    if (-not $sshService) {
        Write-Host "O serviço SSH (sshd) não está habilitado, habilitando agora..."
        Install-Module -Name OpenSSHUtils -Force -Confirm:$false
        Install-SSHModule -Force
    }
    else {
        Write-Host "O serviço de SSH (sshd) já está habilitado."
    }

    Start-Service -Name "sshd"
    Set-Service -Name "sshd" -StartupType Automatic

    # Firewall rules

    Write-Host "Criando regras de firewall para serviços e game servers..."

    netsh advfirewall firewall add rule name="FTP" dir=in action=allow protocol=TCP localport=21
    netsh advfirewall firewall add rule name="SSH" dir=in action=allow protocol=TCP localport=22
    netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=in action=allow protocol=UDP localport=16261-16262
    netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=out action=allow protocol=UDP localport=16261-16262
    netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=in action=allow protocol=UDP localport=2456-2458
    netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=out action=allow protocol=UDP localport=2456-2458
    netsh advfirewall firewall add rule name="DST Dedicated Server" dir=in action=allow protocol=UDP localport=10889
    netsh advfirewall firewall add rule name="DST Dedicated Server" dir=out action=allow protocol=UDP localport=10889
    ipconfig /all

    Write-Host "Configurações de rede aplicadas."
}

# Instalação de pacotes (client)

function installClientPKGs {
    Write-Host 'Para acrescentar ou remover pacotes ao script, edite o conteúdo da variável "CLIENT_PKGS"'
    Write-Host 'Para descobrir o ID da aplicação desejada, use "winget search <nomedoapp>" no terminal.'

    $count = 0

    foreach ($pkg in $CLIENT_PKGS) {
        winget list $pkg > null

        if (-not $?) {
            Write-Host "Instalando $pkg ..."
            winget install $pkg --accept-package-agreements --accept-source-agreements --disable-interactivity --silent
            if ($?) { $count++ }
        }
        else {
            Write-Host "$pkg já está instalado."
        }
    }

    Write-Host "$count de $CLIENT_PKGS.Count pacotes foram instalados com sucesso."

    Write-Host "Instalando DriverBooster..."
    .\$ResourcesPath\driver_booster_setup.exe /verysilent /supressmsgboxes
}

# Instalação de pacotes (server)

function installServerPKGs {
    Write-Host 'Para acrescentar ou remover pacotes ao script, edite o conteúdo da variável "SERVER_PKGS"'
    Write-Host 'Para descobrir o ID da aplicação desejada, use "winget search <nomedoapp>" no terminal.'

    $count = 0

    foreach ($pkg in $SERVER_PKGS) {
        winget list $pkg > null

        if (-not $?) {
            Write-Host "Instalando $pkg ..."
            winget install $pkg --accept-package-agreements --accept-source-agreements --disable-interactivity --silent
            if ($?) { $count++ }
        }
        else {
            Write-Host "$pkg já está instalado."
        }
    }

    Write-Host "$count de $SERVER_PKGS.Count pacotes foram instalados com sucesso."

    Write-Host "Instalando DriverBooster..."
    .\$ResourcesPath\driver_booster_setup.exe /verysilent /supressmsgboxes
}

# Personalização do sistema

function setCustomOptions {
    Write-Host "Aplicando personalizações do sistema..."

    REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d 2 /f
    REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchBoxTaskbarMode" /t REG_DWORD /d 1 /f
    REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
    REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "ColorPrevalence" /t REG_DWORD /d 1 /f
    REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f
    REG ADD "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d 100 /f
    Copy-Item $ResourcesPath\wallpaper.png $UserProfile\wallpaper.png
    REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$UserProfile\wallpaper.png" /f
    rundll32.exe user32.dll, UpdatePerUserSystemParameters

    Write-Host "Personalizações aplicadas. O Windows Explorer será reiniciado."
    pause

    taskkill /F /IM explorer.exe ; Start-Process explorer.exe
}

# Configurações de energia

function setPowerOptions {
    Write-Host "Alterando configurações de energia do Windows..."

    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0
}

# Outros recursos

function setExtraOptions {
    Write-Host "Ativando o recurso DirectPlay..."
    if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') { dism /online /enable-feature /all /featurename:DirectPlay }

    Write-Host "Ativando o recurso .NET Framework 3.5..."
    if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') { dism /online /enable-feature /all /featurename:NetFx3 }

    Write-Host "Configurando o git..."

    Write-Host "[user]" >> $GitConfigFile
    Write-Host "    name = $GitUser >> $GitConfigFile"
    Write-Host "    email = $GitEmail >> $GitConfigFile"
}

# Ponto de restauração 2

function setSecondCheckpoint {
    Write-Host "Criando ponto de restauração do sistema..."
    Checkpoint-Computer -Description 'Pós Execução do Script Windows Post Install' -ErrorAction SilentlyContinue

    if (-not $?) { Write-Host "Falha ao criar ponto de restauração do sistema." } else { Write-Host "Ponto de restauração do sistema criado." }

    REG DELETE "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f
}

# ------------ EXECUÇÃO ------------ #

if ($option -ceq "-s" -or $option -ceq "--server") {
    setFirstCheckpoint
    setNetworkOptions
    setPowerOptions
    installServerPKGs
    setSecondCheckpoint
    exitScript
}
elseif ($option -ceq "-c" -or $option -ceq "--client") {
    setFirstCheckpoint
    setCustomOptions
    setExtraOptions
    installClientPKGs
    setSecondCheckpoint
    exitScript
}
elseif ($option -ceq "-f" -or $option -ceq "--full") {
    setFirstCheckpoint
    setNetworkOptions
    setPowerOptions
    setCustomOptions
    setExtraOptions
    installClientPKGs
    installServerPKGs
    setSecondCheckpoint
    exitScript
}
elseif ($option -ceq "-?" -or $option -ceq "--help") {
    Write-Warning "Parâmetros válidos: `n`n    -c | --client  =  Instala pacotes e configurações para máquinas do tipo CLIENTE `n    -s | --server  =  Instala pacotes e configurações para máquinas do tipo SERVER `n    -f | --full  =  Realiza uma instalação completa e aplica todas as configurações válidas `n    -? | --help  =  Exibe esta mensagem de ajuda"
    exitScript
}
else {
    exitScript 5
}
