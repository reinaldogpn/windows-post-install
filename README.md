# Windows Post Install (WPI)

This PowerShell script automatically installs the programs I use in my PC, runs updates and apply some personal preferences. Tested on **Windows 10 and Windows 11**.

### Winget

Winget is the Windows Package Manager (as good as '*apt install*' on Linux, no joke). The winget command line tool enables users to discover, install, upgrade, remove and configure applications on Windows 10 and Windows 11 computers. This tool is the client interface to the Windows Package Manager service. It's pre-installed by default on Windows 10 and 11, but it may needs to be updated just after installing the OS (relax, this script will do it for you).

For further information and troubleshooting, please visit [winget's official Github repository](https://github.com/microsoft/winget-cli).

**Winget dependencies (OPTIONAL):**

> The script downloads these files automatically, but you should download it manually to go faster:
> 
> **1) Microsoft Visual C++ Redist:**
> 
> - https://download.microsoft.com/download/4/7/c/47c6134b-d61f-4024-83bd-b9c9ea951c25/Microsoft.VCLibs.x64.14.00.Desktop.appx
> 
> **2) Microsoft UI Xaml:**
> 
> - https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx
>   
> **3) Microsoft Desktop App Installer (Winget):**
> 
> - https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

#
### Installation
1. Open `Windows PowerShell` **as Administrator** and download the [.ps1 file](https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/wpi.ps1)
    ```
    cd ~ ; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/wpi.ps1' -OutFile 'wpi.ps1' -UseBasicParsing
    ```

2. To run the script, you have 3 installation options **(choose only one)**. Note that this command uses "-ExecutionPolicy Bypass" allowing PowerShell scripts execution:
        
    - `--default`: install common applications and customizations to Windows:
        ```
        powershell -ExecutionPolicy Bypass -Command "& .\wpi.ps1 --default"
        ```
        
    - `--dev`: install tools and resources for software development, it also applies power and network settings:
        ```
        powershell -ExecutionPolicy Bypass -Command "& .\wpi.ps1 --dev"
        ```

#
### Customization Tools

* [Windows 11 Cursors Concept](https://www.deviantart.com/jepricreations/art/Windows-11-Cursors-Concept-v2-886489356) - a modern option to customize Windows mouse cursor.
* [TranslucentTB](https://apps.microsoft.com/store/detail/translucenttb/9PF4KZ2VN4W9?hl=en-us&gl=us) - a good choice for bringing a modern translucent look for Windows taskbar.

#
### Useful Commands

* Fix for TranslucentTB (making taskbar translucent):

    1. Download [ViVeTool](https://github.com/thebookisclosed/ViVe).

    2. Run this command inside ViVe's directory as admin:

    ``` batch
    vivetool /disable /id:26008830 && vivetool /disable /id:38764045
    ```

#
**Popular App ID Names**:
- `9NKSQGP7F2NH` = *WhatsApp Desktop*
- `9NCBCSZSJRSB` = *Spotify Client*
- `9PF4KZ2VN4W9` = *TranslucentTB*
- `9WZDNCRF0083` = *Facebook Messenger*
