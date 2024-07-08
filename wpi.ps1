<#
.SYNOPSIS
    Este é um script de customização do Windows.
.DESCRIPTION
    Este script automatiza a configuração e personalização do Windows. Compatível com Windows 10 ou superior.
.PARAMETER option
    Modo de instalação:
    --default OU --dev
#>

# Dica: instalar o windows 11 usando uma conta local (offline) --> oobe\bypassnro

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("--default", "--dev")]
    [string]$option
)

$OutputEncoding = [System.Text.Encoding]::UTF8

# ------------ VARIÁVEIS ------------ #

$DEV_PKGS       = @("Git.Git",
                    "Microsoft.VisualStudioCode",
                    "Microsoft.VisualStudio.2022.Community",
                    "Microsoft.WindowsTerminal",
                    "Notepad++.Notepad++",
                    "Oracle.JDK.22",
                    "Python.Python.3.12")

$DEFAULT_PKGS   = @("9NKSQGP7F2NH", # Whatsapp Desktop
                    "Discord.Discord",
                    "Google.Chrome",
                    "Oracle.JavaRuntimeEnvironment",
                    "qBittorrent.qBittorrent",
                    "RARLab.WinRAR",
                    "TeamViewer.TeamViewer",
                    "Valve.Steam")

$TempDir = Join-Path -Path $PSScriptRoot -ChildPath "wpi_temp"
$ErrorLog = Join-Path -Path $PSScriptRoot -ChildPath "wpi_errors.log"

# GitHub info for .gitconfig file:
$GitUser = "Reinaldo G. P. Neto"
$GitEmail = "reinaldogpn@outlook.com"
$GitConfigFile = Join-Path -Path $env:USERPROFILE -ChildPath ".gitconfig"

# ------------ FUNÇÕES DE SAÍDA ------------ #

function Write-Cyan {
    param(
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Green {
    param(
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Green
}

function Write-Yellow {
    param(
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Yellow
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
    
    Write-Yellow "Fim do script! `nO computador precisa ser reiniciado para que todas as alterações sejam aplicadas. Deseja reiniciar agora? (s = sim | n = não)" ; $i = Read-Host
    if ($i -ceq 's') {
        Write-Yellow "Reiniciando agora..."
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
    Test-Connection 8.8.8.8 -Count 1 -ErrorAction SilentlyContinue | Out-Null
    
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
        Write-Green "Sistema operacional identificado: $OS_name"
        $OS_version = ($OS_name -split ' ')[2]
    
        if ($OS_version -lt 10) {
            Exit-Error "Versão do windows desconhecida ou não suportada!"
        } 
        else {
            Write-Cyan "Versão do sistema operacional: $OS_version"
        }
    }
}

# ------------ FUNÇÕES ------------ #

# Ponto de restauração 1

function Set-Checkpoint {
    Write-Cyan "Criando ponto de restauração do sistema..."
    
    try {
        Checkpoint-Computer -Description "Pré Execução do Script Windows Post Install" -ErrorAction Stop | Out-Null
    }
    catch {
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "Pré Execução do Script Windows Post Install" -ErrorAction SilentlyContinue | Out-Null
    }
    
    if ($?) { 
        Write-Green "Ponto de restauração do sistema criado." 
    } else { 
        Write-Warning -Message "Falha ao criar ponto de restauração do sistema." 
    }
}

# Personalização do sistema

function Set-CustomOptions {
    $wallpaperUrl = "https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/resources/wallpaper.jpg"
    $wallpaperPath = Join-Path -Path $env:UserProfile -ChildPath "wallpaper.jpg"

    Write-Cyan "Aplicando personalizações do sistema..."
    #Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchBoxTaskbarMode" -Value 1 -Type DWORD -Force
    #Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWORD -Force
    #Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "ColorPrevalence" -Value 1 -Type DWORD -Force
    #Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWORD -Force
    #Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWORD -Force
    #Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWORD -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "JPEGImportQuality" -Value 100 -Type DWORD -Force

    # Cria um atalho para a pasta pessoal ($env:UserProfile) na área de trabalho
    $SourceFileLocation = "$env:UserProfile"
    $ShortcutLocation = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop) + "\Pasta Pessoal.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
    $Shortcut.TargetPath = $SourceFileLocation
    $Shortcut.Save()

    Write-Cyan "Aplicando novo wallpaper..."
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath | Out-Null
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $wallpaperPath -Type STRING -Force
    Invoke-Expression -Command 'rundll32.EXE user32.dll, UpdatePerUserSystemParameters 1, True'

    Write-Green "Personalizações aplicadas. O Windows Explorer será reiniciado."
    Pause
    Stop-Process -Name explorer -Force ; Start-Process explorer
}

# Configurações e serviços de rede

function Set-NetworkOptions {
    # FTP service
    Write-Cyan "Habilitando serviço de FTP..."
    $ftpService = Get-Service -Name "ftpsvc" -ErrorAction SilentlyContinue

    if (-not $ftpService) {
        Write-Yellow "O serviço de FTP (ftpsvc) não está habilitado, habilitando agora..."
        Enable-WindowsOptionalFeature -FeatureName "IIS-WebServerRole" -Online -All -NoRestart | Out-Null
        Enable-WindowsOptionalFeature -FeatureName "IIS-WebServer" -Online -All -NoRestart | Out-Null
        Enable-WindowsOptionalFeature -FeatureName "IIS-FTPServer" -Online -All -NoRestart | Out-Null

        try {
            Set-Service -Name "ftpsvc" -StartupType Automatic -ErrorAction Stop | Out-Null
            Start-Service -Name "ftpsvc" -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning -Message "Falha ao tentar iniciar o serviço 'ftpsvc', tente fazer isso manualmente após reiniciar o computador."
        }
    }
    else {
        Write-Yellow "O serviço de FTP (ftpsvc) já está habilitado."
    }

    # SSH service
    Write-Cyan "Habilitando serviço de SSH..."
    $sshService = Get-Service -Name "sshd" -ErrorAction SilentlyContinue

    if (-not $sshService) {
        Write-Yellow "O serviço SSH (sshd) não está habilitado, habilitando agora..."
        Add-WindowsCapability -Online -Name OpenSSH.Client | Out-Null
        Add-WindowsCapability -Online -Name OpenSSH.Server | Out-Null

        try {
            Set-Service -Name "sshd" -StartupType Automatic -ErrorAction Stop | Out-Null
            Start-Service -Name "sshd" -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning -Message "Falha ao tentar iniciar o serviço 'sshd', tente fazer isso manualmente após reiniciar o computador."
        }
    }
    else {
        Write-Yellow "O serviço de SSH (sshd) já está habilitado."
    }

    Write-Green "Configurações de rede aplicadas."
}

# Configurações de energia

function Set-PowerOptions {
    Write-Cyan "Alterando configurações de energia do Windows..."
    
    Invoke-Expression -Command "powercfg /change standby-timeout-ac 0"
    Invoke-Expression -Command "powercfg /change standby-timeout-dc 0"

    Write-Green "Configurações de energia aplicadas."
}

# Outros recursos

function Set-ExtraOptions {
    Write-Cyan "Aplicando configurações extras..."

    Write-Cyan "Configurando o git..."
    "[user]" | Out-File -FilePath $GitConfigFile
    "    name = $GitUser" | Out-File -FilePath $GitConfigFile -Append
    "    email = $GitEmail" | Out-File -FilePath $GitConfigFile -Append

    Write-Green "Configurações extras aplicadas."
}

# Instalação do winget

function Add-Winget {
    Write-Cyan "Iniciando o download e instalação do Winget e suas dependências..."

    # Fazer o download dos 3 arquivos manualmente economiza MUITO tempo! 
    # De qualquer forma, o script faz o download automático dos arquivos caso não sejam encontrados na pasta Downloads.
    $VCLibsURL = "https://download.microsoft.com/download/4/7/c/47c6134b-d61f-4024-83bd-b9c9ea951c25/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $UIXamlURL = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
    $WingetURL = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

    $VCLibsPKG = $VCLibsURL.Split('/')[-1]
    $UIXamlPKG = $UIXamlURL.Split('/')[-1]
    $WingetPKG = $WingetURL.Split('/')[-1]
    
    $VCLibsPath = Join-Path -Path "$env:UserProfile\Downloads" -ChildPath $VCLibsPKG
    $UIXamlPath = Join-Path -Path "$env:UserProfile\Downloads" -ChildPath $UIXamlPKG
    $WingetPath = Join-Path -Path "$env:UserProfile\Downloads" -ChildPath $WingetPKG
    
    try {
        if (-not (Test-Path $VCLibsPath)) {
            Write-Cyan "Fazendo o download de $($VCLibsPKG). Isso pode demorar um pouco..."
            Invoke-WebRequest $VCLibsURL -OutFile (Join-Path -Path $TempDir -ChildPath $VCLibsPKG) -ErrorAction Stop | Out-Null
            Add-AppxPackage -Path (Join-Path -Path $TempDir -ChildPath $VCLibsPKG) -ErrorAction Stop | Out-Null
        }
        else {
            Add-AppxPackage -Path $VCLibsPath -ErrorAction Stop | Out-Null
        }
        
        if (-not (Test-Path $UIXamlPath)) {
            Write-Cyan "Fazendo o download de $($UIXamlPKG). Isso pode demorar um pouco..."
            Invoke-WebRequest $UIXamlURL -OutFile (Join-Path -Path $TempDir -ChildPath $UIXamlPKG) -ErrorAction Stop | Out-Null
            Add-AppxPackage -Path (Join-Path -Path $TempDir -ChildPath $UIXamlPKG) -ErrorAction Stop | Out-Null
        }
        else {
            Add-AppxPackage -Path $UIXamlPath -ErrorAction Stop | Out-Null
        }
        
        if (-not (Test-Path $WingetPath)) {
            Write-Cyan "Fazendo o download de $($WingetPKG). Isso pode demorar um pouco..."
            Invoke-WebRequest $WingetURL -OutFile (Join-Path -Path $TempDir -ChildPath $WingetPKG) -ErrorAction Stop | Out-Null
            Add-AppxPackage -Path (Join-Path -Path $TempDir -ChildPath $WingetPKG) -ForceApplicationShutdown -ErrorAction Stop | Out-Null
        }
        else {
            Add-AppxPackage -Path $WingetPath -ForceApplicationShutdown -ErrorAction Stop | Out-Null
        }
        
        Invoke-Expression -Command "echo y | winget list --accept-source-agreements" -ErrorAction Stop | Out-Null
        
        Write-Green "Winget foi devidamente atualizado e está pronto para o uso."
    }
    catch {
        return 1
    }
    
    return 0
}

# Instalação de pacotes (winget)

function Add-WingetPkgs {
    # Verifica se o winget está instalado e na versão correta
    $WingetVer = Invoke-Expression -Command "winget -v" 2> $null

    if (!$WingetVer -or ([version]($WingetVer.Split('v')[1]) -lt [version]("1.7.10661"))) {
        Write-Warning -Message "Winget não encontrado ou desatualizado. Tentando atualizar o winget..."
        $output = Add-Winget
        if ($output -ne 0) {
            Write-Warning -Message "Falha ao tentar atualizar o winget."
            return
        }
    }

    Write-Cyan "Iniciando a instalação de pacotes do Winget..."
    Write-Yellow "Para acrescentar ou remover pacotes ao script, edite o conteúdo da respectiva variável 'Pkgs'."
    Write-Yellow "Para descobrir o ID da aplicação desejada, use 'winget search <nomedoapp>' no terminal."

    $count = 0

    switch ($option) {
    
        "--default" {
            $WingetPackages = $DEFAULT_PKGS
        }
    
        "--dev" {
            $WingetPackages = $DEV_PKGS
        }

        default {
            return
        }
    }

    foreach ($pkg in $WingetPackages) {
        $installed = Invoke-Expression -Command "winget list $pkg --accept-source-agreements"
        # Comparação feita escapando caracteres especiais nos nomes dos pacotes.
        if ($installed -match ([regex]::Escape($pkg))) {
            Write-Yellow "$pkg já está instalado."
        }
        else {
            Write-Cyan "Instalando $pkg ..."
            Invoke-Expression -Command "winget install $pkg --accept-package-agreements --accept-source-agreements --silent" -ErrorAction SilentlyContinue
            
            if ($?) {
                Write-Green "O pacote $pkg foi instalado com sucesso!"
                $count++
            }
            else {
                Write-Warning -Message "Falha ao tentar instalar o pacote $pkg."
                Write-Warning -Message "Detalhes sobre o erro podem ser vistos no arquivo de log."
            }
        }
    }

    Write-Green "Fim da instalação de pacotes."
    Write-Green "$count de $($WingetPackages.Count) pacotes foram instalados com sucesso."
}

# Instalação de outros pacotes

function Add-ExtraPkgs {
    Write-Cyan "Iniciando a instalação de pacotes extras..."
    # DriverBooster
    if (-not (Test-Path "C:\Program Files (x86)\IObit\Driver Booster")) {
        $DriverBPath = Join-Path -Path $TempDir -ChildPath "driver_booster_setup.exe"
        
        Write-Cyan "Baixando e instalando o DriverBooster..."
        Invoke-WebRequest "https://cdn.iobit.com/dl/driver_booster_setup.exe" -OutFile $DriverBPath -ErrorAction SilentlyContinue | Out-Null
        Start-Process $DriverBPath /verysilent -ErrorAction SilentlyContinue | Out-Null
    }
    else {
        Write-Warning -Message "DriverBooster já está instalado."
    }

    Write-Green "Fim da instalação de pacotes."
}

# ------------ EXECUÇÃO ------------ #

Confirm-Resources
Set-Checkpoint

switch ($option) {
    "--default" {
        Add-ExtraPkgs
        Add-WingetPkgs
        Exit-Script
    }

    "--dev" {
        Set-CustomOptions
        #Set-NetworkOptions
        #Set-PowerOptions
        Set-ExtraOptions
        Add-ExtraPkgs
        Add-WingetPkgs
        Exit-Script
    }
    
    default {
        Write-Warning -Message "Parâmetros válidos: `n`n    --default  =  Instala pacotes e configurações padrão para sistemas ordinários `n    --dev  =  Instala ferramentas e recursos para desenvolvedor"
    }
}
