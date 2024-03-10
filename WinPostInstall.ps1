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

$OS_name = ""
$OS_version = ""

$TempDir = Join-Path -Path $env:TEMP -ChildPath "WinPostInstall"
$ErrorLog = Join-Path -Path $PSScriptRoot -ChildPath "wpi_errors.log"

# Chocolatey
$ChocoConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "packages.config"
$ChocoConfigUrl = "https://raw.githubusercontent.com/reinaldogpn/script-windows-post-install/main/packages.config"

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

    <#
    Write-Cyan "Verificando instalação do winget..."
    
    try {
        $WingetVer = Invoke-Expression "winget -v"
    } 
    catch {
        Write-Warning -Message "Winget não está instalado. Instalando winget e suas dependências..."
        Invoke-WebRequest "https://download.microsoft.com/download/4/7/c/47c6134b-d61f-4024-83bd-b9c9ea951c25/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile $TempDir"Microsoft_VCLibs.appx" | Out-Null ; Add-AppxPackage -Path $TempDir"Microsoft_VCLibs.appx" | Out-Null
        Invoke-WebRequest "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx" -OutFile $TempDir"Microsoft_UI_Xaml.appx"  | Out-Null ; Add-AppxPackage -Path $TempDir"Microsoft_UI_Xaml.appx"  | Out-Null
        Invoke-WebRequest "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile $TempDir"Microsoft_Winget.msixbundle"  | Out-Null ; Add-AppxPackage -Path $TempDir"Microsoft_Winget.msixbundle"  | Out-Null
        Invoke-Expression "winget -v"  | Out-Null
    }
    
    if (-not $WingetVer) {
        Write-Warning "Falha ao tentar instalar o Winget."
    }
    elseif ($WingetVer -cne "v1.7.10582") {
        Write-Cyan "Atualizando o Winget..."
        Invoke-WebRequest "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile $TempDir"\Microsoft_Winget.msixbundle"  | Out-Null ; Add-AppxPackage -Path $TempDir"\Microsoft_Winget.msixbundle" -ForceApplicationShutdown  | Out-Null
    } 
    else {
        Write-Cyan "Winget já está devidamente instalado e atualizado."
    }

    Invoke-Expression -Command "winget list --accept-source-agreements"  | Out-Null
    #>

    # Chocolatey instalado?
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Magenta "Chocolatey não está instalado. Instalando Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
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
            REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 1 /f
            
            try {
                Checkpoint-Computer -Description "Pré Execução do Script Windows Post Install" | Out-Null
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
            REG DELETE "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f
        }

        default {
            Exit-Error "Parâmetro inválido para criação de ponto de restauração!"
        }
    }
}

# Personalização do sistema

function Set-CustomOptions {
    Write-Cyan "Aplicando personalizações do sistema..."
    REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d 2 /f
    REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchBoxTaskbarMode" /t REG_DWORD /d 1 /f
    REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
    REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "ColorPrevalence" /t REG_DWORD /d 1 /f
    REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f
    REG ADD "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d 100 /f

    Write-Cyan "Aplicando novo wallpaper..."
    Invoke-WebRequest "https://raw.githubusercontent.com/reinaldogpn/script-windows-post-install/main/resources/wallpaper.jpg" -OutFile (Join-Path -Path $env:USERPROFILE -ChildPath "wallpaper.jpg") | Out-Null
    REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$env:USERPROFILE\wallpaper.jpg" /f
    Invoke-Expression -Command "rundll32.exe user32.dll, UpdatePerUserSystemParameters"
    Write-Magenta "Personalizações aplicadas. O Windows Explorer será reiniciado."
    PAUSE
    Stop-Process -Name explorer -Force ; Start-Process explorer

    # Write-Cyan "Baixando e instalando o DriverBooster..."
    # Invoke-WebRequest "https://cdn.iobit.com/dl/driver_booster_setup.exe" -OutFile $TempDir"\driver_booster_setup.exe" | Out-Null ; Start-Process $TempDir"\driver_booster_setup.exe" /verysilent | Out-Null
}

# Configurações e serviços de rede

function Set-NetworkOptions {
    # FTP service
    Write-Cyan "Habilitando serviço de FTP..."
    Get-Service -Name "ftpsvc" -ErrorAction SilentlyContinue | Out-Null

    if (-not $?) {
        Write-Magenta "O serviço de FTP (ftpsvc) não está habilitado, habilitando agora..."
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServerRole" -All | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServer" -All | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-FTPServer" -All | Out-Null
    }
    else {
        Write-Cyan "O serviço de FTP (ftpsvc) já está habilitado."
    }

    try {
        Start-Service -Name "ftpsvc" | Out-Null ; Set-Service -Name "ftpsvc" -StartupType Automatic | Out-Null
    }
    catch {
        Write-Warning -Message "Falha ao tentar iniciar o serviço 'ftpsvc', tente fazer isso manualmente após reiniciar o computador."
    }

    # SSH service
    Write-Cyan "Habilitando serviço de SSH..."
    Get-Service -Name "sshd" -ErrorAction SilentlyContinue | Out-Null

    if (-not $?) {
        Write-Magenta "O serviço SSH (sshd) não está habilitado, habilitando agora..."
        Add-WindowsCapability -Online -Name OpenSSH.Client | Out-Null
        Add-WindowsCapability -Online -Name OpenSSH.Server | Out-Null
    }
    else {
        Write-Cyan "O serviço de SSH (sshd) já está habilitado."
    }

    try {
        Start-Service -Name "sshd" | Out-Null ; Set-Service -Name "sshd" -StartupType Automatic | Out-Null
    }
    catch {
        Write-Warning -Message "Falha ao tentar iniciar o serviço 'ftpsvc', tente fazer isso manualmente após reiniciar o computador."
    }

    # Firewall rules
    Write-Cyan "Criando regras de firewall para serviços e game servers..."
    New-NetFirewallRule -DisplayName "FTP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 21 | Out-Null
    New-NetFirewallRule -DisplayName "SSH" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 | Out-Null
    New-NetFirewallRule -DisplayName "PZ Dedicated Server" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 16261-16262 | Out-Null
    New-NetFirewallRule -DisplayName "Valheim Dedicated Server" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 2456-2458 | Out-Null
    New-NetFirewallRule -DisplayName "DST Dedicated Server" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 10889 | Out-Null
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
    Write-Cyan "Ativando o recurso DirectPlay..."
    if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne "Enabled") { 
        Enable-WindowsOptionalFeature -Online -FeatureName DirectPlay -All -ErrorAction SilentlyContinue | Out-Null
    }
    
    Write-Cyan "Ativando o recurso .NET Framework 3.5..."
    if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne "Enabled") { 
        Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Cyan "Configurando o git..."
    "[user]" | Out-File -FilePath $GitConfigFile
    "    name = $GitUser" | Out-File -FilePath $GitConfigFile -Append
    "    email = $GitEmail" | Out-File -FilePath $GitConfigFile -Append
}

# Instalação de pacotes (chocolatey)

function Add-ChocoPackages {
    Write-Cyan "Para acrescentar ou remover pacotes ao script, edite o arquivo de configuração do Chocolatey: $ChocoConfigFile."
    
    if (-not (Test-Path $ChocoConfigFile)) {
        Invoke-WebRequest -Uri $ChocoConfigUrl -OutFile $ChocoConfigFile -UseBasicParsing | Out-Null 
    }

    try {
        choco install --configfile=$ChocoConfigFile
        Write-Cyan "O Chocolatey finalizou a instalação de pacotes. Confira os pacotes instalados:" ; choco list
    }
    catch {
        Write-Warning -Message "Ocorreu um erro ao tentar executar o script de instalação do Chocolatey."
    }
}

# Instalação de pacotes (winget)

function Add-WingetPackages {
    Write-Cyan "Para acrescentar ou remover pacotes ao script, edite o conteúdo da variável 'WingetPackages'."
    Write-Cyan "Para descobrir o ID da aplicação desejada, use 'winget search <nomedoapp>' no terminal."
    $count = 0

    foreach ($pkg in $WingetPackages) {
        try {
            Invoke-Expression -Command "winget list $pkg" | Out-Null
            Write-Cyan "$pkg já está instalado."
        }
        catch {
            Write-Cyan "Instalando $pkg ..."
            Invoke-Expression -Command "winget install $pkg --accept-package-agreements --accept-source-agreements --disable-interactivity --silent" -ErrorAction SilentlyContinue | Out-Null
            
            if ($?) {
                Write-Cyan "O pacote $pkg foi instalado com sucesso!"
                $count++
            }
            else {
                Write-Warning -Message "Falha ao tentar instalar o pacote $pkg."
            }
        }
    }

    Write-Magenta "$count de $WingetPackages.Count pacotes foram instalados com sucesso."
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
        Exit-Error "Parâmetro inválido! Para obter a lista de parâmetros use .\WinPostInstall.ps1 --help"
    }
}
