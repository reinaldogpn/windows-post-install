# win_post_install.ps1

This PowerShell script automatically installs the programs I use in my PC, runs updates and apply some personal preferences. Tested on **Windows 10 and Windows 11**.

### Winget

Winget is the Windows Package Manager (as good as '*apt install*' on Linux, no joke). The winget command line tool enables users to discover, install, upgrade, remove and configure applications on Windows 10 and Windows 11 computers. This tool is the client interface to the Windows Package Manager service. It's pre-installed by default on Windows 10 and 11, but it may needs to be updated just after installing the OS (relax, this script will do it for you).

For further information and troubleshooting, please visit [winget's Github repository](https://github.com/microsoft/winget-cli).

#
### Installation
1. Open `powershell.exe` **as Administrator** and download the [.ps1 file](https://raw.githubusercontent.com/reinaldogpn/script-windows-post-install/main/win_post_install.ps1)
    ```
    Invoke-WebRequest 'https://raw.githubusercontent.com/reinaldogpn/script-windows-post-install/main/win_post_install.ps1' -OutFile 'win_post_install.ps1'
    ```

2. If needed, set PowerShell execution policy to "Unrestricted", so you can run .ps1 scripts:
    ```
    Set-ExecutionPolicy Unrestricted -Scope CurrentUser
    ```

3. To run the script, you have 3 installation options **(choose only one)**:
    - `--server`: install services as FTP and SSH servers, open specific ports in firewall (game servers ports), change power options and install useful applications for server management:
        ```
        .\win_post_install.ps1 --server
        ```
        
    - `--client`: install client-like applications, tools and frameworks, it also make customizations to Windows:
        ```
        .\win_post_install.ps1 --client
        ```
        
    - `--full`: full installation, install both server and client options:
        ```
        .\win_post_install.ps1 --full
        ```

4. For security reasons, when the installation is done, change PowerShell execution policy back to "Restricted":
    ```
    Set-ExecutionPolicy Restricted -Scope CurrentUser
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
