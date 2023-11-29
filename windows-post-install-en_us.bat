:: -------------------------------------------------------------------------------------------
:: * Description: Batch script for automated installation of applications on Windows 10 and 11.
:: * Author: Reinaldo G. P. Neto
:: * Created on: 04/28/2023
:: -------------------------------------------------------------------------------------------
:: * Changelog:
::
:: v1.0 04/28/2023, reinaldogpn:
::     - Creation of the raw script, polishing will be done in the future =D. The script
::     performs tests, installs necessary tools for execution, installs
::     some useful programs, and updates the system.
:: v1.1 04/28/2023, reinaldogpn:
::     - Correction of the use of the "!errorlevel!" environment variable to function
::     correctly on Windows 10; now the applications to be installed are defined
::     within the "applist.txt" file rather than in variables inside the script.
:: v1.2 04/28/2023, reinaldogpn:
::     - Changes in the general structure of the script, as well as minor corrections and adjustments.
:: v1.3 05/27/2023, reinaldogpn:
::     - Inclusion of new functions for creating two system restore points
::     and for downloading customization tools for Windows elements.
:: v1.4 05/30/2023, reinaldogpn:
::     - Refactoring and implementation of the 'curl' command to download the tools.
:: v1.5 06/01/2023, reinaldogpn:
::     - Refactoring and error handling in some functions.
:: v1.6 09/26/2023, reinaldogpn:
::     - Addition of Windows power settings (sleep time and monitor shutdown).
:: v1.7 11/28/2023, reinaldogpn:
::     - Translation of the script to english :)
:: -------------------------------------------------------------------------------------------

@echo off

color 0a
setlocal EnableDelayedExpansion
chcp 65001 > nul
cd %~dp0

:: ------------ VARIABLES ------------ ::

set APP_LIST=apps.txt
set URL_LIST=urls.txt
set COUNT=0
set DOWNLOAD_FOLDER=%USERPROFILE%\Downloads\Tools

:: ------------ FUNCTIONS ------------ ::

:checkAdminPrivileges
echo Checking administrator privileges...
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo This script needs to be executed with administrator privileges.
    goto :end
)
:: END ::

:checkInternetConnection
echo Checking internet connection...
ping -n 1 8.8.8.8 >nul 2>&1
if !errorlevel! neq 0 (
    echo No internet connection. The script will be terminated.
    goto :end
)
:: END ::

:createRestorePoint1
echo Creating system restore point...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 1 /f
powershell -Command "Checkpoint-Computer -Description 'Execution of Windows Post Install Script'"
echo System restore point created.
:: END ::

:checkNecessaryTools
echo Checking for the existence of necessary tools...
where winget >nul 2>&1 || (
    echo Installing winget...
    powershell -c "Invoke-WebRequest https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile winget.msixbundle; .\winget.msixbundle"
)

where dism >nul 2>&1 || (
    echo Installing dism...
    dism /online /enable-feature /featurename:NetFx3 /all /norestart
)

where wuauclt.exe >nul 2>&1 || (
    echo Installing wuauclt.exe...
    powershell -c "Start-Process wuinstall.exe -Verb RunAs"
)

where curl > nul 2>&1 || (
    echo Installing curl...
    winget install cURL.cURL -h --accept-package-agreements --accept-source-agreements
    if !errorlevel! neq 0 (
        echo Error installing curl!
        goto :end
    )
)
echo All necessary tools are installed.
:: END ::

:netConfig
echo Creating rules in the firewall and applying network settings...
:: Network settings
netsh interface ipv4 set address name="Ethernet" static 192.168.0.100 255.255.255.0 192.168.0.1
netsh interface ipv4 set dns "Ethernet" static 192.168.0.1
netsh interface ipv4 add dns "Ethernet" 8.8.8.8 index=2
:: Firewall rules
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=in action=allow protocol=UDP localport=16261-16262
netsh advfirewall firewall add rule name="PZ Dedicated Server" dir=out action=allow protocol=UDP localport=16261-16262
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=in action=allow protocol=UDP localport=2456-2458
netsh advfirewall firewall add rule name="Valheim Dedicated Server" dir=out action=allow protocol=UDP localport=2456-2458
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=in action=allow protocol=UDP localport=10889
netsh advfirewall firewall add rule name="DST Dedicated Server" dir=out action=allow protocol=UDP localport=10889
:: End of rules
ipconfig /all
echo Network settings applied.
:: END ::

:applyDarkTheme
echo Applying dark theme...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v ColorPrevalence /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v JPEGImportQuality /t REG_DWORD /d 100 /f

echo Dark theme applied. The explorer.exe process will be restarted.
pause
taskkill /F /IM explorer.exe && start explorer.exe
:: END ::

:downloadTools
echo Downloading tools...
if not exist %URL_LIST% (
    echo URLs list file not found: "%URL_LIST%"
    echo Attempting to download...
    powershell -c "Invoke-WebRequest https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/%URL_LIST% -OutFile %URL_LIST%"
    if not exist %URL_LIST% (
        echo Failed to download the list of applications: "%URL_LIST%"
        goto :end
    ) 
)

if not exist "%DOWNLOAD_FOLDER%" mkdir "%DOWNLOAD_FOLDER%"
for /f "usebackq delims=" %%i in (%URL_LIST%) do (
    if not exist "%DOWNLOAD_FOLDER%\%%~nxi" (
        echo Downloading "%%~nxi"...
        curl -sL "%%i" -o "%DOWNLOAD_FOLDER%\%%~nxi" > nul
    ) else (
        echo File "%%~nxi" already exists.
    )
)
echo Download complete. Files saved in: "%DOWNLOAD_FOLDER%"
:: END ::

:extraConfig
echo Activating DirectPlay feature...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:DirectPlay}"
echo Activating .NET Framework 3.5 feature...
powershell.exe -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -ne 'Enabled') {dism /online /enable-feature /all /featurename:NetFx3}"
echo Configuring git settings...
git config --global user.name reinaldogpn
git config --global user.email reinaldogpn@outlook.com
echo Changing Windows power settings...
powercfg /change monitor-timeout-ac 600
powercfg /change monitor-timeout-dc 600
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
:: END ::

:installApps
echo To add or remove programs from the script, modify the file "%APP_LIST%"
echo To find the desired application ID, use "winget search <appname>" in the terminal.
if not exist %APP_LIST% (
    echo Applications list file not found: "%APP_LIST%"
    echo Attempting to download...
    powershell -c "Invoke-WebRequest https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/%APP_LIST% -OutFile %APP_LIST%"
    if not exist %APP_LIST% (
        echo Failed to download the list of applications: "%APP_LIST%"
        goto :end
    ) 
)
for /f "usebackq delims=" %%a in (%APP_LIST%) do (
    set "APP_NAME=%%a"
    winget list !APP_NAME! > nul 2>&1
    if !errorlevel! equ 0 (
        echo !APP_NAME! is already installed...
    ) else (
        echo Installing !APP_NAME!...
        winget install !APP_NAME! -h --accept-package-agreements --accept-source-agreements
        if !errorlevel! equ 0 set /a COUNT+=1
    )
)
echo %COUNT% applications were successfully installed.
:: END ::

:updateWindows
echo Searching for updates...
wuauclt.exe /detectnow /updatenow
echo If available, updates will be downloaded and installed...
:: END ::

:createRestorePoint2
echo Creating system restore point...
powershell -Command "Checkpoint-Computer -Description 'Post Execution of Windows Post Install Script'"
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f
echo System restore point created.
:: END ::

:: ------------ END ------------ ::
:end
echo End of the script!
endlocal
pause
exit /b
