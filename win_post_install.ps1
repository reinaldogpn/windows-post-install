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

# Dica: instalar o windows 11 usando uma conta local (offline) --> oobe\bypassnro

param (
    [string]$option = "--help" # --help = show options | --server = install server tools only | --client = install client tools only | --full = full installation
)

# Define a codificação do PowerShell para UTF-8 temporariamente (pode ser necessário em alguns sistemas)
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

$OS_name = ""
$OS_version = ""

# GitHub info for .gitconfig file:

$GitUser = "reinaldogpn"
$GitEmail = "reinaldogpn@outlook.com"
$GitConfigFile = Join-Path -Path $env:USERPROFILE -ChildPath ".gitconfig"

# ------------ FUNÇÃO DE SAÍDA ------------ #

function exitScript {
    param ([int]$err = -1)
    
    switch ($err) {
        0 {
            Write-Host "Fim do script! `nO computador precisa ser reiniciado para que todas as alterações sejam aplicadas. Deseja reiniciar agora? (s = sim | n = não)" ; $i = Read-Host
            if ($i -ceq "s") {
                Write-Host "Reiniciando agora..."
                Restart-Computer
            }
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
            Write-Error -Message "Versão do windows desconhecida ou não suportada!" -ErrorId $err -Category DeviceError
            exit
        }

        4 {
            Write-Error -Message "Script encerrado pelo usuário!" -ErrorId $err -Category ResourceUnavailable
            exit
        }

        5 {
            Write-Error -Message "Parâmetro inválido! Para obter a lista de parâmetros use .\win_post_install.ps1 --help" -ErrorId $err -Category InvalidArgument
            exit
        }

        default {
            exit
        }
    }
}

# ------------ FUNÇÃO DE TESTES ------------- #

function checkRequisites {
    # Executando como admin?
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        exitScript 1
    }
    
    # Conectado à internet?
    Write-Host "Verificando conexão com a internet..."
    Test-NetConnection -ErrorAction SilentlyContinue > $null 2>&1
    
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
        Invoke-WebRequest 'https://download.microsoft.com/download/4/7/c/47c6134b-d61f-4024-83bd-b9c9ea951c25/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile Microsoft_VCLibs.appx -ErrorAction SilentlyContinue ; Add-AppxPackage -Path .\Microsoft_VCLibs.appx -ErrorAction SilentlyContinue
        Invoke-WebRequest 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' -OutFile Microsoft_UI_Xaml.appx -ErrorAction SilentlyContinue ; Add-AppxPackage -Path .\Microsoft_UI_Xaml.appx -ErrorAction SilentlyContinue
        Invoke-WebRequest 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile Microsoft_Winget.msixbundle -ErrorAction SilentlyContinue ; Add-AppxPackage -Path .\Microsoft_Winget.msixbundle -ErrorAction SilentlyContinue
    }
    
    if ($wingetVer -cne 'v1.7.10582') {
        Write-Host "Atualizando o Winget..."
        Invoke-WebRequest 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile Microsoft_Winget.msixbundle -ErrorAction SilentlyContinue ; Add-AppxPackage -Path .\Microsoft_Winget.msixbundle -ForceApplicationShutdown -ErrorAction SilentlyContinue
    } 
    else {
        Write-Host "Winget está devidamente instalado e atualizado."
    }

    echo y | winget list > $null 2>&1
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
    Get-Service -Name "ftpsvc" -ErrorAction SilentlyContinue

    if (-not $?) {
        Write-Host "O serviço de FTP (ftpsvc) não está habilitado, habilitando agora..."
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServerRole" -All
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServer" -All
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-FTPServer" -All
    }
    else {
        Write-Host "O serviço de FTP (ftpsvc) já está habilitado."
    }

    try {
        Start-Service -Name "ftpsvc" -ErrorAction SilentlyContinue; Set-Service -Name "ftpsvc" -StartupType Automatic -ErrorAction SilentlyContinue
    }
    catch {
        $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command 'Start-Service -Name ftpsvc ; Set-Service -Name ftpsvc -StartupType Automatic'"
        $trigger = New-ScheduledTaskTrigger -AtStartup
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'HabilitarFTP' -RunLevel Highest
        Write-Host "O serviço de FTP foi instalado e será habilitado após a próxima vez em que o sistema for reiniciado."
    }

    # SSH service
    Write-Host "Habilitando serviço de SSH..."
    Get-Service -Name "sshd" -ErrorAction SilentlyContinue

    if (-not $?) {
        Write-Host "O serviço SSH (sshd) não está habilitado, habilitando agora..."
        Add-WindowsCapability -Online -Name OpenSSH.Client
        Add-WindowsCapability -Online -Name OpenSSH.Server
    }
    else {
        Write-Host "O serviço de SSH (sshd) já está habilitado."
    }

    try {
        Start-Service -Name "sshd" -ErrorAction SilentlyContinue ; Set-Service -Name "sshd" -StartupType Automatic -ErrorAction SilentlyContinue
    }
    catch {
        $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command 'Start-Service -Name sshd ; Set-Service -Name sshd -StartupType Automatic'"
        $trigger = New-ScheduledTaskTrigger -AtStartup
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'HabilitarSSH' -RunLevel Highest
        Write-Host "O serviço de SSH foi instalado e será habilitado após a próxima vez em que o sistema for reiniciado."
    }

    # Firewall rules
    Write-Host "Criando regras de firewall para serviços e game servers..."
    New-NetFirewallRule -DisplayName "FTP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 21
    New-NetFirewallRule -DisplayName "SSH" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22
    New-NetFirewallRule -DisplayName "PZ Dedicated Server" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 16261-16262
    New-NetFirewallRule -DisplayName "Valheim Dedicated Server" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 2456-2458
    New-NetFirewallRule -DisplayName "DST Dedicated Server" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 10889
    Write-Host "Configurações de rede aplicadas."
}

# Instalação de pacotes (client)

function installClientPKGs {
    Write-Host 'Para acrescentar ou remover pacotes ao script, edite o conteúdo da variável "CLIENT_PKGS"'
    Write-Host 'Para descobrir o ID da aplicação desejada, use "winget search <nomedoapp>" no terminal.'
    $count = 0

    foreach ($pkg in $CLIENT_PKGS) {
        winget list $pkg > $null 2>&1

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
}

# Instalação de pacotes (server)

function installServerPKGs {
    Write-Host 'Para acrescentar ou remover pacotes ao script, edite o conteúdo da variável "SERVER_PKGS"'
    Write-Host 'Para descobrir o ID da aplicação desejada, use "winget search <nomedoapp>" no terminal.'

    $count = 0

    foreach ($pkg in $SERVER_PKGS) {
        winget list $pkg > $null 2>&1

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

    Write-Host "Aplicando novo wallpaper..."
    Invoke-WebRequest 'https://raw.githubusercontent.com/reinaldogpn/script-windows-post-install/main/resources/wallpaper.jpg' -OutFile $env:USERPROFILE'\wallpaper.jpg'
    REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$env:USERPROFILE\wallpaper.jpg" /f
    Invoke-Expression -Command "rundll32.exe user32.dll, UpdatePerUserSystemParameters"
    Write-Host "Personalizações aplicadas. O Windows Explorer será reiniciado."
    Pause
    Stop-Process -Name explorer -Force ; Start-Process explorer

    Write-Host "Baixando e instalando o DriverBooster..."
    Invoke-WebRequest 'https://cdn.iobit.com/dl/driver_booster_setup.exe' -OutFile driver_booster_setup.exe -ErrorAction SilentlyContinue ; Start-Process driver_booster_setup.exe /verysilent > $null 2>&1
}

# Configurações de energia

function setPowerOptions {
    Write-Host "Alterando configurações de energia do Windows..."
    Invoke-Expression -Command "powercfg /change standby-timeout-ac 0"
    Invoke-Expression -Command "powercfg /change standby-timeout-dc 0"
}

# Outros recursos

function setExtraOptions {
    Write-Host "Ativando o recurso DirectPlay..."
    if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') { 
        Enable-WindowsOptionalFeature -Online -FeatureName DirectPlay -All 
    }
    
    Write-Host "Ativando o recurso .NET Framework 3.5..."
    if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') { 
        Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All 
    }

    Write-Host "Configurando o git..."
    "[user]" | Out-File -FilePath $GitConfigFile
    "    name = $GitUser" | Out-File -FilePath $GitConfigFile -Append
    "    email = $GitEmail" | Out-File -FilePath $GitConfigFile -Append
}

# Ponto de restauração 2

function setSecondCheckpoint {
    Write-Host "Criando ponto de restauração do sistema..."
    Checkpoint-Computer -Description 'Pós Execução do Script Windows Post Install' -ErrorAction SilentlyContinue
    if (-not $?) { Write-Host "Falha ao criar ponto de restauração do sistema." } else { Write-Host "Ponto de restauração do sistema criado." }
    REG DELETE "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f
}

# ------------ EXECUÇÃO ------------ #

if ($option -ceq "--server") {
    checkRequisites
    setFirstCheckpoint
    setCustomOptions
    setNetworkOptions
    setPowerOptions
    installServerPKGs
    setSecondCheckpoint
    exitScript 0
}
elseif ($option -ceq "--client") {
    checkRequisites
    setFirstCheckpoint
    setCustomOptions
    setExtraOptions
    installClientPKGs
    setSecondCheckpoint
    exitScript 0
}
elseif ($option -ceq "--full") {
    checkRequisites
    setFirstCheckpoint
    setNetworkOptions
    setPowerOptions
    setCustomOptions
    setExtraOptions
    installClientPKGs
    installServerPKGs
    setSecondCheckpoint
    exitScript 0
}
elseif ($option -ceq "--help") {
    Write-Warning -Message "Parâmetros válidos: `n`n    --client  =  Instala pacotes e configurações para máquinas do tipo CLIENTE `n    --server  =  Instala pacotes e configurações para máquinas do tipo SERVER `n    --full  =  Realiza uma instalação completa e aplica todas as configurações válidas `n    --help  =  Exibe esta mensagem de ajuda"
    exitScript
}
else {
    exitScript 5
}
