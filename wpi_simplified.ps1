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
    "Oracle.MySQLWorkbench",
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

# Retry function
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
        } catch {
            Write-Warning "Attempt $($attempts + 1) failed. Error: $($_.Exception.Message)"
            Start-Sleep -Seconds $RetryDelay
            $attempts++
        }
    }
    if (-not $success) {
        throw "Command failed after $MaxRetries attempts."
    }
}

# Is winget installed and updated?
function Update-Winget {
	$WingetVer = Invoke-Expression -Command "winget -v" 2> $null

	if (!$WingetVer -or ([version]($WingetVer.Split('v')[1]) -lt [version]("1.9.25200"))) {
		Write-Warning "Winget command failed or outdated.\nDownloading winget last version now..."

		$DependenciesURL = "https://github.com/microsoft/winget-cli/releases/latest/download/DesktopAppInstaller_Dependencies.zip"
		$WingetURL = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
		$DependenciesPath = Join-Path -Path $DownloadDir -ChildPath "Dependencies.zip"
		$WingetPath = Join-Path -Path $DownloadDir -ChildPath "Winget.msixbundle"
		
		(Test-Path $DownloadDir) -or New-Item -ItemType Directory -Path $DownloadDir

		try {
			Retry-Command -Command { Invoke-WebRequest $DependenciesURL -OutFile $DependenciesPath -ErrorAction Stop }
			Retry-Command -Command { Invoke-WebRequest $WingetURL -OutFile $WingetPath -ErrorAction Stop }

			Expand-Archive -Path $DependenciesPath -DestinationPath $DownloadDir -Force

			$AppxFiles = @()
			if ($Architecture -ieq "amd64") {
				$AppxFiles = Get-ChildItem -Path (Join-Path -Path $DownloadDir -ChildPath "x64") -Filter "*.appx"
			} else {
				$AppxFiles = Get-ChildItem -Path (Join-Path -Path $DownloadDir -ChildPath $Architecture) -Filter "*.appx"
			}

			foreach ($Appx in $AppxFiles) {
				Retry-Command -Command { Add-AppxPackage -Path $Appx.FullName -ForceApplicationShutdown -DisableDevelopmentMode -ErrorAction Stop }
			}

			Retry-Command -Command { Add-AppxPackage -Path $WingetPath -ForceApplicationShutdown -DisableDevelopmentMode -ErrorAction Stop }

		} catch {
			Write-Warning "An error occurred: $($_.Exception.Message)"
			return
		}
	}
}

# Install packages using winget
function Add-WingetPkgs {
	foreach ($Pkg in $Pkgs) {
		try {
			$installed = Invoke-Expression -Command "winget list $Pkg --accept-source-agreements"
			if ($installed -match ([regex]::Escape($Pkg))) {
				Write-Warning "$Pkg já está instalado."
			}
			else {
				Retry-Command -Command { Invoke-Expression -Command "winget install --exact --id $Pkg --silent --accept-package-agreements --accept-source-agreements --source winget" -ErrorAction Stop }
				Write-Host "Package $Pkg installed successfully." -ForegroundColor Green
			}
		} catch {
			Write-Warning "Failed to install package: $Pkg. Error: $($_.Exception.Message)"
		}
	}
	Write-Host "All packages processed." -ForegroundColor Blue
}

# Add $UserProfile shortcut to desktop
function Add-UserShortcut {
	$ShortcutLocation = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop) + "\Pasta Pessoal.lnk"
	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
	$Shortcut.TargetPath = "$env:UserProfile"
	$Shortcut.Save()
	
	Write-Host "Added UserProfile shortcut to desktop." -ForegroundColor Blue
}

# Execution
Start-Transcript -Path $OutputLog 

(Test-Path $RootDir) -or New-Item -ItemType Directory -Path $RootDir

Add-UserShortcut
Update-Winget
Add-WingetPkgs

Stop-Transcript
