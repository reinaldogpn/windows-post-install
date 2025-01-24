$Pkgs = @(
    "9NKSQGP7F2NH",
    "9NCBCSZSJRSB",
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

Start-Transcript -Path $OutputLog 

if (-not (Test-Path $RootDir)) { New-Item -ItemType Directory -Path $RootDir }
if (-not (Test-Path $DownloadDir)) { New-Item -ItemType Directory -Path $DownloadDir }

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

$WingetVer = Invoke-Expression -Command "winget -v" 2> $null
if (!$WingetVer -or ([version]($WingetVer.Split('v')[1]) -lt [version]("1.9.25200"))) {
	Write-Warning "Winget command failed or outdated.\nDownloading winget last version now..."
	
	$DependenciesURL = "https://github.com/microsoft/winget-cli/releases/latest/download/DesktopAppInstaller_Dependencies.zip"
	$WingetURL = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
	$DependenciesPath = Join-Path -Path $DownloadDir -ChildPath "Dependencies.zip"
	$WingetPath = Join-Path -Path $DownloadDir -ChildPath "Winget.msixbundle"
	
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
			Retry-Command -Command { Add-AppxPackage -Path $Appx.FullName -AllowUnsigned -ForceApplicationShutdown -ErrorAction Stop }
		}
		
		Retry-Command -Command { Add-AppxPackage -Path $WingetPath -AllowUnsigned -ForceApplicationShutdown -ErrorAction Stop }
	} catch {
		Write-Warning "An error occurred: $($_.Exception.Message)"
		return
	}
}

foreach ($Pkg in $Pkgs) {
	try {
		$installed = Invoke-Expression -Command "winget list $Pkg --accept-source-agreements"
		if ($installed -match ([regex]::Escape($Pkg))) {
			Write-Warning "$Pkg is already installed."
		}
		else {
			Retry-Command -Command { Invoke-Expression -Command "winget install --exact --id $Pkg --silent --accept-package-agreements --accept-source-agreements --source winget" -ErrorAction Stop }
			Write-Host "Package $Pkg installed successfully." -ForegroundColor Green
		}
	} catch {
		Write-Warning "Failed to install package: $Pkg. Error: $($_.Exception.Message)"
	}
}
Write-Host "All packages processed."

$ShortcutLocation = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop) + "\Pasta Pessoal.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
$Shortcut.TargetPath = "$env:UserProfile"
$Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,160"
$Shortcut.Save()

Write-Host "Added UserProfile shortcut to desktop with custom icon." -ForegroundColor Green

$GitConfigFile = Join-Path -Path $env:USERPROFILE -ChildPath ".gitconfig"

"[user]" | Out-File -FilePath $GitConfigFile
"    name = Reinaldo G. P. Neto" | Out-File -FilePath $GitConfigFile -Append
"    email = reinaldogpn@outlook.com" | Out-File -FilePath $GitConfigFile -Append

Write-Host "Added .gitconfig file." -ForegroundColor Green

Stop-Transcript
