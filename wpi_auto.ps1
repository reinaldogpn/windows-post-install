$Pkgs = @(
    "Anthropic.Claude",
    "AnyDesk.AnyDesk",
    "CharlesMilette.TranslucentTB",
    "Cloudflare.Warp",
    "Discord.Discord",
    "Google.Chrome.EXE",
    "Oracle.JavaRuntimeEnvironment",
    "qBittorrent.qBittorrent",
    "RARLab.WinRAR",
    "Valve.Steam",
    "VideoLAN.VLC",
    "Logitech.GHUB",
    "Logitech.OptionsPlus",
    "Nvidia.NvidiaApp",
    "Kingston.SSDManager",
    "CPUID.CPU-Z.ROG",
    "TechPowerUp.GPU-Z",
    "RiotGames.LeagueOfLegends.BR",
    "Blitz.Blitz",
    "TeamViewer.TeamViewer",
    "REALiX.HWiNFO",
    "OCBase.OCCT.Personal",
    "Maxon.CinebenchR23"
)

$RootDir = Join-Path -Path $env:UserProfile -ChildPath "WPI"
$DownloadDir = Join-Path -Path $RootDir -ChildPath "downloads"
$OutputLog = Join-Path -Path $RootDir -ChildPath "output.log"

if (-not (Test-Path $RootDir)) { New-Item -ItemType Directory -Path $RootDir | Out-Null }
if (-not (Test-Path $DownloadDir)) { New-Item -ItemType Directory -Path $DownloadDir | Out-Null }

# Functions

function Retry-Command {
    param (
        [ScriptBlock]$Command,
        [int]$MaxRetries = 3,
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

function Add-WingetPkgs {
    foreach ($Pkg in $Pkgs) {
        try {
            $installed = winget list $Pkg --accept-source-agreements
            if ($installed -match ([regex]::Escape($Pkg))) {
                Write-Warning "$Pkg is already installed."
            }
            else {
                Retry-Command -Command { winget install --exact --id $Pkg --silent --accept-package-agreements --accept-source-agreements --source winget }
                if ($?) { Write-Host "Package $Pkg installed successfully." -ForegroundColor Green }
            }
        }
        catch {
            Write-Warning "Failed to install package: $Pkg. Error: $($_.Exception.Message)"
        }
    }
    
    Write-Host "All packages processed."
}

# Execution

Start-Transcript -Path $OutputLog 

Add-WingetPkgs

if (Test-Path $DownloadDir) { Remove-Item -Path $DownloadDir -Recurse -Force | Out-Null }

Stop-Transcript
