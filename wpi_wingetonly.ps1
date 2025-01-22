$Pkgs = @(
    "9NKSQGP7F2NH",
    "Discord.Discord",
    "Google.Chrome",
    "Oracle.JavaRuntimeEnvironment",
    "qBittorrent.qBittorrent",
    "RARLab.WinRAR",
    "TeamViewer.TeamViewer",
    "Valve.Steam",
    "Git.Git",
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.VCRedist.2015+.x86",
    "Microsoft.VisualStudioCode",
    "Microsoft.VisualStudio.2022.Community",
    "Microsoft.WindowsTerminal",
    "Notepad++.Notepad++"
)

$Winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
$TempDir = Join-Path -Path $PSScriptRoot -ChildPath "Temp"
$CPUArch = $env:Processor_Architecture.ToLower()

if (!(Test-Path $Winget)) {
    Write-Warning "Winget executable not found at: $Winget\nDownloading now..."

    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir
    }

    $DependenciesURL = "https://github.com/microsoft/winget-cli/releases/latest/download/DesktopAppInstaller_Dependencies.zip"
    $WingetURL = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

    $DependenciesPath = Join-Path -Path $TempDir -ChildPath "Dependencies.zip"
    $WingetPath = Join-Path -Path $TempDir -ChildPath "Winget.msixbundle"

    try {
        Invoke-WebRequest $DependenciesURL -OutFile $DependenciesPath -ErrorAction Stop
        Invoke-WebRequest $WingetURL -OutFile $WingetPath -ErrorAction Stop
        Expand-Archive -Path $DependenciesPath -DestinationPath $TempDir -Force

        $AppxFiles = @()
        if ($CPUArch -ieq "amd64") {
            $AppxFiles = Get-ChildItem -Path (Join-Path -Path $TempDir -ChildPath "x64") -Filter "*.appx"
        } else {
            $AppxFiles = Get-ChildItem -Path (Join-Path -Path $TempDir -ChildPath $CPUArch) -Filter "*.appx"
        }

        foreach ($Appx in $AppxFiles) {
            Add-AppxPackage -Path $Appx.FullName -ForceApplicationShutdown -DisableDevelopmentMode -ErrorAction Stop 
        }
        Add-AppxPackage -Path $WingetPath -ForceApplicationShutdown -DisableDevelopmentMode -ErrorAction Stop

    } catch {
        Write-Warning "An error occured: $($_.Exception.Message)"
        return
    }
}

foreach ($Pkg in $Pkgs) {
    try {
        & $winget install --exact --id $Pkg --silent --accept-package-agreements --accept-source-agreements --source winget --scope machine
        Write-Host "Package $Pkg installed successfully." -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install package: $Pkg. Error: $($_.Exception.Message)"
    }
}

Write-Host "All packages processed."