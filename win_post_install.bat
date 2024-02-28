:: -----------------------------------------------------------------------------------------------------
:: * Description: Batch script for automated installation of applications on Windows 10 and 11.
:: * Author: reinaldogpn
:: * Created on: 04/28/2023
:: -----------------------------------------------------------------------------------------------------
:: * Changelog:
::
::  v1.0 04/28/2023, reinaldogpn:
::      - Creation of the raw script, polishing will be done in the future =D. The script
::      performs tests, installs necessary tools for execution, installs
::      some useful programs and updates the system.
::  v1.1 04/28/2023, reinaldogpn:
::      - Correction of the use of the environment variable "!errorlevel!" to work
::      correctly on Windows 10; now the applications to be installed are defined
::      inside the file "applist.txt" and no longer as variables within the script.
::  v1.2 04/28/2023, reinaldogpn:
::      - Changes in the overall structure of the script, as well as small corrections and adjustments.
::  v1.3 05/27/2023, reinaldogpn:
::      - Inclusion of new functions to create two system restore points
::      and to download tools for customizing Windows elements.
::  v1.4 05/30/2023, reinaldogpn:
::      - Refactoring and implementation of the 'curl' command to download the tools.
::  v1.5 06/01/2023, reinaldogpn:
::      - Refactoring and error handling in some functions.
::  v1.6 09/26/2023, reinaldogpn:
::      - Addition of Windows power settings (suspension time and monitor shutdown).
::  v2.0 01/04/2024, reinaldogpn:
::      - Removal of unused packages and tools, code renewal, and new personal settings
::      for the system.
::  v2.1 02/17/2024, reinaldogpn:
::      - Inclusion of additional network and firewall settings; resetting some tests.
::  v2.2 02/28/2024, reinaldogpn:
::      - Script translation and minor code fixes.
:: -----------------------------------------------------------------------------------------------------

@echo off

color 1B
setlocal EnableDelayedExpansion
chcp 65001 > nul
cd /d "%~dp0"

:: ------------ VARS ------------ ::

set "APP_list=%~dp0apps.txt"
set "RES_dir=%~dp0resources"
set "OS_name="
set "OS_version="

:: GitHub info for .gitconfig file:
set "GIT_user=reinaldogpn"
set "GIT_email=reinaldogpn@outlook.com"

:: ------------ TESTS ------------ ::

:: Running as admin?

echo Checking administrator privileges...
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo This script needs to be run with administrator privileges. The script will be terminated.
    goto :end
)

echo.

:: ------------------------ ::

:: Connected to the internet?

echo Checking internet connection...
ping -n 1 8.8.8.8 >nul 2>&1
if !errorlevel! neq 0 (
    echo No internet connection. The script will be terminated.
    goto :end
)

echo.

:: ------------------------ ::

:: Windows version?

for /f "tokens=*" %%a in ('systeminfo ^| findstr /B /C:"OS Name"') do (
    set "count=0"
    for %%b in (%%a) do (
        set /a count+=1
        if !count! geq 5 (
            set "OS_name=!OS_name! %%b"
        )
    )
)

set "OS_name=!OS_name:~1!"

for /f "tokens=7" %%c in ('systeminfo ^| findstr /B /C:"OS Version"') do (
    set "OS_version=%%c"
)

echo Identified operating system: %OS_name%

if %OS_version% lt 10 (
    echo Windows version not supported. The script will be terminated.
    goto :end
)

echo.

:: ------------------------ ::

:: Winget installed?

echo Checking winget installation...
where winget >nul 2>&1 || (
    echo Installing winget and its dependencies...
    powershell -Command "Add-AppxPackage -Path '%RES_dir%\winget\Microsoft.UI.Xaml_7.2208.15002.0_X64_msix_en-US.msix'"
    powershell -Command "Add-AppxPackage -Path '%RES_dir%\winget\Microsoft.VC.2015.UWP.DRP_14.0.30704.0_X64_msix_en-US.msix'"
    powershell -Command "Invoke-WebRequest 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile winget.msixbundle; .\winget.msi"
    echo y | winget list >nul 2>&1
    if !errorlevel! neq 0 (
        echo Failed to install winget. The script will be terminated.
        goto :end
    )
)

echo Updating winget...
winget upgrade Microsoft.AppInstaller --accept-package-agreements --accept-source-agreements --disable-interactivity --silent >nul 2>&1
if !errorlevel! equ 0 (
    echo Winget is properly installed and updated.
) else (
    echo Failed to update winget.
)

echo.

:: ------------ FUNCTIONS ------------ ::

:: System restore point 1

echo Creating system restore point...
powershell -Command "Enable-ComputerRestore -Drive 'C:\'"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 1 /f
powershell -Command "Checkpoint-Computer -Description 'Pre-Execution of Windows Post Install Script'"
echo System restore point created.

echo.

:: ------------------------ ::

:: Network settings and services

echo Enabling FTP service...
powershell -Command "dism /online /enable-feature /featurename:IIS-WebServerRole /all"
powershell -Command "dism /online /enable-feature /featurename:IIS-WebServer /all"
powershell -Command "dism /online /enable-feature /featurename:IIS-FTPServer /all"

echo Enabling SSH service...
powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Client"
powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Server"
powershell -Command "Start-Service sshd"
powershell -Command "Set-Service -Name sshd -StartupType 'Automatic'"

echo Creating firewall rules...
netsh advfirewall firewall add rule name="FTP" dir=in action=allow protocol=TCP localport=21
netsh advfirewall firewall add rule name="SSH" dir=in action=allow protocol=TCP localport=22
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=in action=allow protocol=UDP localport=16261-16262
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=out action=allow protocol=UDP localport=16261-16262
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=in action=allow protocol=UDP localport=2456-2458
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=out action=allow protocol=UDP localport=2456-2458
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=in action=allow protocol=UDP localport=10889
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=out action=allow protocol=UDP localport=10889
ipconfig /all

echo Network settings applied.

echo.

:: ------------------------ ::

:: Package installation

echo To add or remove packages from the script, modify the file "%APP_list%"
echo To find out the ID of the desired application, use "winget search <appname>" in the terminal.
if not exist %APP_list% (
    echo Package list not found: "%APP_list%"
    goto :end
)

set "count=0"
for /f "usebackq delims=" %%a in (%APP_list%) do (
    set "app_name=%%a"
    winget list !app_name! > nul 2>&1
    if !errorlevel! equ 0 (
        echo !app_name! is already installed...
    ) else (
        echo Installing !app_name!...
        winget install --id !app_name! --accept-package-agreements --accept-source-agreements --disable-interactivity --silent
        if !errorlevel! equ 0 set /a count+=1
    )
)
echo %count% packages were successfully installed.

echo Installing DriverBooster...
%RES_dir%\driver_booster_setup.exe /verysilent /suppressmsgboxes

echo.

:: ------------------------ ::

:: System customizations

:: Taskbar, dark theme, and wallpaper
echo Customizing Windows
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d 2 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchBoxTaskbarMode" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "ColorPrevalence" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d 100 /f
copy "%RES_dir%\wallpaper.png" "%USERPROFILE%\wallpaper.png"
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%USERPROFILE%\wallpaper.png" /f
rundll32.exe user32.dll,UpdatePerUserSystemParameters
echo Dark theme applied. Restarting Windows Explorer...
taskkill /F /IM explorer.exe && start explorer.exe

echo.

:: ------------------------ ::

:: Power settings

echo Changing Windows power settings...
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0

echo.

:: ------------------------ ::

:: Other resources

rem echo Activating DirectPlay feature...
rem powershell -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:DirectPlay}"
rem echo Activating .NET Framework 3.5 feature...
rem powershell -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:NetFx3}"

echo Configuring git...

rem copy "%RES_dir%\gitconfig.txt" "%USERPROFILE%\.gitconfig"

echo [user] >> %USERPROFILE%\.gitconfig
echo     name = %GITUSER% >> %USERPROFILE%\.gitconfig
echo     email = %GITEMAIL% >> %USERPROFILE%\.gitconfig

echo.

:: ------------------------ ::

:: System restore point 2

echo Creating system restore point...
powershell -Command "Checkpoint-Computer -Description 'Post-Execution of Windows Post Install Script'"
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f
echo System restore point created.

echo.

:: ------------ END ------------ ::

:end
echo End of script!
endlocal
pause
exit /b
