$Pkgs = @(
    "7zip.7zip",
    "Cloudflare.Warp",
    "Discord.Discord",
    "Git.Git",
    "Google.Chrome.EXE",
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.VCRedist.2015+.x86",
    "Microsoft.VisualStudioCode",
    "Microsoft.VisualStudio.2022.Community",
    "Microsoft.WindowsTerminal",
    "Notepad++.Notepad++",
    "Oracle.JavaRuntimeEnvironment",
    "Oracle.MySQL",
    "qBittorrent.qBittorrent",
    "RARLab.WinRAR",
    "TeamViewer.TeamViewer",
    "Valve.Steam",
    "VideoLAN.VLC"
)

$RootDir = Join-Path -Path $env:UserProfile -ChildPath "WPI"
$DownloadDir = Join-Path -Path $RootDir -ChildPath "downloads"
$OutputLog = Join-Path -Path $RootDir -ChildPath "output.log"
$Architecture = $env:Processor_Architecture.ToLower()

if( [System.Environment]::OSVersion.Version.Build -lt 26100 ) {
    $AppxParam = ""
} else {
    $AppxParam = "-AllowUnsigned"
}

if (-not (Test-Path $RootDir)) { New-Item -ItemType Directory -Path $RootDir | Out-Null }
if (-not (Test-Path $DownloadDir)) { New-Item -ItemType Directory -Path $DownloadDir | Out-Null }

# Functions

function Retry-Command {
    param (
        [ScriptBlock]$Command,
        [int]$MaxRetries = 5,
        [int]$RetryDelay = 5
    )

    $attempts = 0
    $success = $false

    while (-not $success -and $attempts -lt $MaxRetries) {
        try {
            & $Command
            $success = $true
        }
        catch {
            Write-Warning "Attempt $($attempts + 1) failed. Error: $($_.Exception.Message)"
            Start-Sleep -Seconds $RetryDelay
            $attempts++
        }
    }

    if (-not $success) {
        throw "Command failed after $MaxRetries attempts."
    }
}

function Add-WingetLocally {
    foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
        $found = Join-Path -Path $drive.RootDirectory -ChildPath 'Winget' -Resolve -ErrorAction 'SilentlyContinue';
    }

    if ($found) {
        $AppxFiles = @()
        $DependenciesPath = Join-Path -Path $found -ChildPath "Dependencies"

        if ($Architecture -ieq "amd64") {
            $AppxFiles = Get-ChildItem -Path (Join-Path -Path $DependenciesPath -ChildPath "x64") -Filter "*.appx"
        }
        else {
            $AppxFiles = Get-ChildItem -Path (Join-Path -Path $DependenciesPath -ChildPath $Architecture) -Filter "*.appx"
        }

        foreach ($Appx in $AppxFiles) {
            Retry-Command -Command { Add-AppxPackage -Path $Appx.FullName -ForceApplicationShutdown -ErrorAction Stop $AppxParam }
        }

        Retry-Command -Command { Add-AppxPackage -Path (Join-Path -Path $found -ChildPath "Winget.msixbundle") -ForceApplicationShutdown -ErrorAction Stop $AppxParam }
    } 
    else {
        Write-Warning "An error occurred: $($_.Exception.Message)"
        return
    }
}

function Add-WingetRemotely {
    $DependenciesURL = "https://github.com/microsoft/winget-cli/releases/latest/download/DesktopAppInstaller_Dependencies.zip"
    $WingetURL = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $DependenciesPath = Join-Path -Path $DownloadDir -ChildPath "Dependencies.zip"
    $WingetPath = Join-Path -Path $DownloadDir -ChildPath "Winget.msixbundle"

    Retry-Command -Command { Invoke-WebRequest $DependenciesURL -OutFile $DependenciesPath -UseBasicParsing -ErrorAction Stop }
    Retry-Command -Command { Invoke-WebRequest $WingetURL -OutFile $WingetPath -UseBasicParsing -ErrorAction Stop }
    Expand-Archive -Path $DependenciesPath -DestinationPath $DownloadDir -Force

    $AppxFiles = @()

    if ($Architecture -ieq "amd64") {
        $AppxFiles = Get-ChildItem -Path (Join-Path -Path $DownloadDir -ChildPath "x64") -Filter "*.appx"
    }
    else {
        $AppxFiles = Get-ChildItem -Path (Join-Path -Path $DownloadDir -ChildPath $Architecture) -Filter "*.appx"
    }

    foreach ($Appx in $AppxFiles) {
        Retry-Command -Command { Add-AppxPackage -Path $Appx.FullName -ForceApplicationShutdown -ErrorAction Stop $AppxParam }
    }

    Retry-Command -Command { Add-AppxPackage -Path $WingetPath -ForceApplicationShutdown -ErrorAction Stop $AppxParam }
}

function Test-Winget {
    $WingetVer = Invoke-Expression -Command "winget -v" 2> $null

    if (!$WingetVer -or ([version]($WingetVer.Split('v')[1]) -lt [version]("1.9.25200"))) {
        Write-Warning "Winget command failed or outdated. Downloading winget last version now..."

        try {
            Add-WingetLocally
        }
        catch {
            Add-WingetRemotely
        }
    }
    else {
        Write-Host "Winget is up to date!" -ForegroundColor Green
    }
}

function Add-WingetPkgs {
    foreach ($Pkg in $Pkgs) {
        try {
            $installed = Invoke-Expression -Command "winget list $Pkg --accept-source-agreements"
            if ($installed -match ([regex]::Escape($Pkg))) {
                Write-Warning "$Pkg is already installed."
            }
            else {
                Retry-Command -Command { Invoke-Expression -Command "winget install --exact --id $Pkg --silent --accept-package-agreements --accept-source-agreements --source winget" -ErrorAction Stop }
                if ($?) { Write-Host "Package $Pkg installed successfully." -ForegroundColor Green }
            }
        }
        catch {
            Write-Warning "Failed to install package: $Pkg. Error: $($_.Exception.Message)"
        }
    }
    Write-Host "All packages processed."
}

function Add-UserShortcut {
    $ShortcutLocation = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop) + "\Pasta Pessoal.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
    $Shortcut.TargetPath = "$env:UserProfile"
    $Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,160"
    $Shortcut.Save()

    Write-Host "Added UserProfile shortcut to desktop with custom icon." -ForegroundColor Green
}

function Set-GitProfile {
    $GitConfigFile = Join-Path -Path $env:USERPROFILE -ChildPath ".gitconfig"

    "[user]" | Out-File -FilePath $GitConfigFile
    "    name = Reinaldo G. P. Neto" | Out-File -FilePath $GitConfigFile -Append
    "    email = reinaldogpn@outlook.com" | Out-File -FilePath $GitConfigFile -Append

    Write-Host "Added .gitconfig file." -ForegroundColor Green
}

# Execution

Start-Transcript -Path $OutputLog 

Test-Winget
Add-WingetPkgs
Add-UserShortcut
Set-GitProfile

if (Test-Path $DownloadDir) { Remove-Item -Path $DownloadDir -Recurse -Force | Out-Null }

Stop-Transcript
