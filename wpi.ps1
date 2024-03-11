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

# Define a codificação do PowerShell para UTF-8 temporariamente (pode ser necessário em alguns terminais)
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ------------ VARIÁVEIS ------------ #

$WingetPackages = @("9NKSQGP7F2NH", # Whatsapp Desktop
                    "9NCBCSZSJRSB", # Spotify Client
                    "9PF4KZ2VN4W9", # TranslucentTB
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
                    "Microsoft.XNARedist")

$TempDir = Join-Path -Path $PSScriptRoot -ChildPath "wpi_temp"
$ErrorLog = Join-Path -Path $PSScriptRoot -ChildPath "wpi_errors.log"

# GitHub info for .gitconfig file:
$GitUser = "reinaldogpn"
$GitEmail = "reinaldogpn@outlook.com"
$GitConfigFile = Join-Path -Path $env:USERPROFILE -ChildPath ".gitconfig"

# ------------ FUNÇÕES DE SAÍDA ------------ #

function Write-Cyan {
    param(
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Magenta {
    param(
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Magenta
}

function Exit-Error {
    param ([string]$ErrorMessage)

    Write-Error -Message $ErrorMessage
    exit 1
}

function Exit-Script {
    Write-Cyan "Fazendo a limpeza do sistema... `nEventuais erros podem ser visualizados posteriormente em: '$ErrorLog'."
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force | Out-Null 
    }
    
    $error | Out-File -FilePath $ErrorLog
    
    Write-Magenta "Fim do script! `nO computador precisa ser reiniciado para que todas as alterações sejam aplicadas. Deseja reiniciar agora? (s = sim | n = não)" ; $i = Read-Host
    if ($i -ceq 's') {
        Write-Cyan "Reiniciando agora..."
        Restart-Computer
    }
    
    exit 0
}

# ------------ FUNÇÃO DE TESTES ------------- #

function Confirm-Resources {
    # Diretório temporário para download de arquivos:
    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir | Out-Null 
    }

    # Executando como admin?
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Exit-Error "Este script deve ser executado como Administrador!"
    }
    
    # Conectado à internet?
    Write-Cyan "Verificando conexão com a internet..."
    Test-NetConnection -ErrorAction SilentlyContinue | Out-Null
    
    if (-not $?) {
        Exit-Error "O computador precisa estar conectado à internet para executar este script!"
    }
    
    # O sistema é compatível?
    Write-Cyan "Verificando compatibilidade do sistema..."
    $OS_name = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
    
    if (-not $OS_name) {
        Write-Warning -Message "Sistema operacional não encontrado."
        Exit-Error "Versão do windows desconhecida ou não suportada!"
    } 
    else {
        Write-Cyan "Sistema operacional identificado: $OS_name"
        $OS_version = ($OS_name -split ' ')[2]
    
        if ($OS_version -lt 10) {
            Exit-Error "Versão do windows desconhecida ou não suportada!"
        } 
        else {
            Write-Cyan "Versão do sistema operacional: $OS_version"
        }
    }

    # Chocolatey instalado?
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Magenta "Chocolatey não está instalado. Instalando Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) | Out-Null 
    } else {
        Write-Cyan "Chocolatey está devidamente instalado."
    }

}

# ------------ FUNÇÕES ------------ #

# Ponto de restauração 1

function Set-Checkpoint {
    param ([int]$Code)
    
    switch ($Code) {
        1 {
            Write-Cyan "Criando primeiro ponto de restauração do sistema..."
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 1 -Type DWORD -Force | Out-Null
            
            try {
                Checkpoint-Computer -Description "Pré Execução do Script Windows Post Install" -ErrorAction Stop | Out-Null
            }
            catch {
                Enable-ComputerRestore -Drive "C:\"
                Checkpoint-Computer -Description "Pré Execução do Script Windows Post Install" -ErrorAction SilentlyContinue | Out-Null
            }
            
            if ($?) { Write-Cyan "Ponto de restauração do sistema criado." } else { Write-Warning -Message "Falha ao criar ponto de restauração do sistema." }
        }

        2 {
            Write-Cyan "Criando segundo ponto de restauração do sistema..."
            Checkpoint-Computer -Description "Pós Execução do Script Windows Post Install" -ErrorAction SilentlyContinue | Out-Null
            if ($?) { Write-Cyan "Ponto de restauração do sistema criado." } else { Write-Warning -Message "Falha ao criar ponto de restauração do sistema." }
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Force | Out-Null
        }

        default {
            Write-Warning "Parâmetro inválido para criação de ponto de restauração!"
        }
    }
}

# Personalização do sistema

function Set-CustomOptions {
    $wallpaperUrl = "https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/resources/wallpaper.jpg"
    $wallpaperPath = Join-Path -Path $TempDir -ChildPath "wallpaper.jpg"
    
    Write-Cyan "Aplicando personalizações do sistema..."
    if ($OS_version -eq 10) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWORD -Force }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchBoxTaskbarMode" -Value 1 -Type DWORD -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWORD -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "ColorPrevalence" -Value 1 -Type DWORD -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWORD -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "JPEGImportQuality" -Value 100 -Type DWORD -Force

    Write-Cyan "Aplicando novo wallpaper..."
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath | Out-Null
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $wallpaperPath -Type STRING -Force
    Invoke-Expression -Command 'rundll32.EXE user32.dll, UpdatePerUserSystemParameters 1, True'

    Write-Magenta "Personalizações aplicadas. O Windows Explorer será reiniciado."
    Pause
    Stop-Process -Name explorer -Force ; Start-Process explorer
}

# Configurações e serviços de rede

function Set-NetworkOptions {
    # FTP service
    Write-Cyan "Habilitando serviço de FTP..."
    $ftpService = Get-Service -Name "ftpsvc" -ErrorAction SilentlyContinue

    if (-not $ftpService) {
        Write-Magenta "O serviço de FTP (ftpsvc) não está habilitado, habilitando agora..."
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServerRole" -All | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServer" -All | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-FTPServer" -All | Out-Null

        try {
            Start-Service -Name "ftpsvc" -ErrorAction Stop | Out-Null
            Set-Service -Name "ftpsvc" -StartupType Automatic -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning -Message "Falha ao tentar iniciar o serviço 'ftpsvc', tente fazer isso manualmente após reiniciar o computador."
        }
    }
    else {
        Write-Cyan "O serviço de FTP (ftpsvc) já está habilitado."
    }

    # SSH service
    Write-Cyan "Habilitando serviço de SSH..."
    $sshService = Get-Service -Name "sshd" -ErrorAction SilentlyContinue

    if (-not $sshService) {
        Write-Magenta "O serviço SSH (sshd) não está habilitado, habilitando agora..."
        Add-WindowsCapability -Online -Name OpenSSH.Client | Out-Null
        Add-WindowsCapability -Online -Name OpenSSH.Server | Out-Null

        try {
            Start-Service -Name "sshd" -ErrorAction Stop | Out-Null
            Set-Service -Name "sshd" -StartupType Automatic -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning -Message "Falha ao tentar iniciar o serviço 'sshd', tente fazer isso manualmente após reiniciar o computador."
        }
    }
    else {
        Write-Cyan "O serviço de SSH (sshd) já está habilitado."
    }

    # Firewall rules
    Write-Cyan "Criando regras de firewall para serviços e game servers..."
    $firewallRules = @(
        @{
            DisplayName = "FTP"
            LocalPort = 21
            Protocol = "TCP"
        },
        @{
            DisplayName = "SSH"
            LocalPort = 22
            Protocol = "TCP"
        },
        @{
            DisplayName = "PZ Dedicated Server"
            LocalPort = "16261-16262"
            Protocol = "UDP"
        },
        @{
            DisplayName = "Valheim Dedicated Server"
            LocalPort = "2456-2458"
            Protocol = "UDP"
        },
        @{
            DisplayName = "DST Dedicated Server"
            LocalPort = 10889
            Protocol = "UDP"
        }
    )

    foreach ($rule in $firewallRules) {
        New-NetFirewallRule -DisplayName $rule.DisplayName -Direction Inbound -Action Allow -Protocol $rule.Protocol -LocalPort $rule.LocalPort | Out-Null
    }

    Write-Cyan "Configurações de rede aplicadas."
}

# Configurações de energia

function Set-PowerOptions {
    Write-Cyan "Alterando configurações de energia do Windows..."
    Invoke-Expression -Command "powercfg /change standby-timeout-ac 0"
    Invoke-Expression -Command "powercfg /change standby-timeout-dc 0"
}

# Outros recursos

function Set-ExtraOptions {
    if ($OS_version -eq 10) {
        try {
            Write-Cyan "Ativando o recurso DirectPlay..."
            $directPlayState = (Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State
            if ($directPlayState -ne "Enabled") { 
                Enable-WindowsOptionalFeature -Online -FeatureName DirectPlay -All -ErrorAction Stop | Out-Null
            }
        }
        catch {
            Write-Warning -Message "Ocorreu um erro ao ativar o recurso DirectPlay: $_"
        }
        
        try {
            Write-Cyan "Ativando o recurso .NET Framework 3.5..."
            $netFx3State = (Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State
            if ($netFx3State -ne "Enabled") { 
                Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -ErrorAction Stop | Out-Null
            }
        }
        catch {
        Write-Warning -Message "Ocorreu um erro ao ativar o recurso .NET Framework 3.5: $_"
        }
    }

    try {
        Write-Cyan "Baixando e instalando o DriverBooster..."
        Invoke-WebRequest "https://cdn.iobit.com/dl/driver_booster_setup.exe" -OutFile $TempDir"\driver_booster_setup.exe" -ErrorAction SilentlyContinue | Out-Null
        Start-Process $TempDir"\driver_booster_setup.exe" /verysilent -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Warning -Message "Ocorreu um erro ao tentar instalar o DriverBooster."
    }

    Write-Cyan "Configurando o git..."
    "[user]" | Out-File -FilePath $GitConfigFile
    "    name = $GitUser" | Out-File -FilePath $GitConfigFile -Append
    "    email = $GitEmail" | Out-File -FilePath $GitConfigFile -Append
}

# Instalação de pacotes (chocolatey)

function Add-ChocoPackages {
    $ChocoConfigFile = Join-Path -Path $TempDir -ChildPath "packages.config"
    $ChocoConfigUrl = "https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/packages.config"

    Write-Cyan "Para acrescentar ou remover pacotes ao script, edite o arquivo de configuração do Chocolatey: $ChocoConfigFile."
    
    if (-not (Test-Path $ChocoConfigFile)) {
        Invoke-WebRequest -Uri $ChocoConfigUrl -OutFile $ChocoConfigFile -UseBasicParsing | Out-Null 
    }

    try {
        choco install $ChocoConfigFile -y -ErrorAction Stop
        Start-Sleep -Seconds 3
        Write-Cyan "O Chocolatey finalizou a instalação de pacotes. Confira os pacotes instalados:" ; choco list
    }
    catch {
        Write-Warning -Message "Ocorreu um erro ao tentar executar o script de instalação do Chocolatey. Detalhes: $_"
    }
}

# Instalação de pacotes (winget)

function Add-WingetPackages {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Magenta "Winget não encontrado. Instalando o winget..."
        Invoke-Expression -Command "choco install winget-cli --version 1.7.10582 -y" -ErrorAction SilentlyContinue | Out-Null
        
        try {
            $output = Invoke-Expression -Command "echo y | winget list --accept-source-agreements" -ErrorAction Stop
        }
        catch {
            Write-Warning -Message "Falha ao tentar instalar o winget."
            Write-Warning -Message "Detalhes do erro: " $output
            return
        }
    }

    Write-Cyan "Para acrescentar ou remover pacotes ao script, edite o conteúdo da variável 'WingetPackages'."
    Write-Cyan "Para descobrir o ID da aplicação desejada, use 'winget search <nomedoapp>' no terminal."
    $count = 0

    foreach ($pkg in $WingetPackages) {
        $installed = Invoke-Expression -Command "winget list $pkg"
        if ($installed -match $pkg) {
            Write-Magenta "$pkg já está instalado."
        }
        else {
            Write-Cyan "Instalando $pkg ..."
            $output = Invoke-Expression -Command "winget install $pkg --accept-package-agreements --accept-source-agreements --disable-interactivity --silent" -ErrorAction SilentlyContinue
            if ($?) {
                Write-Cyan "O pacote $pkg foi instalado com sucesso!"
                $count++
            }
            else {
                Write-Warning -Message "Falha ao tentar instalar o pacote $pkg."
                Write-Warning -Message "Detalhes do erro: " $output
            }
        }
    }

    Write-Magenta "$count de $($WingetPackages.Count) pacotes foram instalados com sucesso."
}

# ------------ EXECUÇÃO ------------ #

switch ($option) {
    "--server" {
        Confirm-Resources
        Set-Checkpoint 1
        Set-CustomOptions
        Set-NetworkOptions
        Set-PowerOptions
        Set-Checkpoint 2
        Exit-Script
    }
    
    "--client" {
        Confirm-Resources
        Set-Checkpoint 1
        Set-CustomOptions
        Set-ExtraOptions
        Add-ChocoPackages
        Add-WingetPackages
        Set-Checkpoint 2
        Exit-Script
    }
    
    "--full" {
        Confirm-Resources
        Set-Checkpoint 1
        Set-CustomOptions
        Set-NetworkOptions
        Set-PowerOptions
        Set-ExtraOptions
        Add-ChocoPackages
        Add-WingetPackages
        Set-Checkpoint 2
        Exit-Script
    }
    
    "--help" {
        Write-Warning -Message "Parâmetros válidos: `n`n    --client  =  Instala pacotes e configurações para máquinas do tipo CLIENTE `n    --server  =  Instala pacotes e configurações para máquinas do tipo SERVER `n    --full  =  Realiza uma instalação completa e aplica todas as configurações válidas `n    --help  =  Exibe esta mensagem de ajuda"
        exit 0
    }
    
    default {
        Exit-Error "Parâmetro inválido! Para obter a lista de parâmetros use .\wpi.ps1 --help"
    }
}
