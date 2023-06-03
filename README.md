# windows-post-install.bat

This batch script automatically installs the programs I use in my PC, runs updates and apply some personal preferences.

Works fine on **Windows 10** & **Windows 11**.

#
### How To
* Define the programs to be installed in file "apps.txt" by it's "winget ID". 
* In case you don't know the ID of an app, use `winget search <appname>` on terminal.
* Define the download url of programs to be downloaded in file "urls.txt".
* Always run the .bat file as admin.

#
### Personalization Tools
* [Mica For Everyone](https://github.com/MicaForEveryone/MicaForEveryone)
  - [Explorer Frame (For Mica For Everyone)](https://github.com/MicaForEveryone/ExplorerFrame)
* [Rectify](https://github.com/MishaProductions/Rectify11Installer)
* [Windows 11 Cursors Concept](https://www.deviantart.com/jepricreations/art/Windows-11-Cursors-Concept-v2-886489356)
* [TranslucentTB](https://apps.microsoft.com/store/detail/translucenttb/9PF4KZ2VN4W9?hl=en-us&gl=us)
* [ViVeTool](https://github.com/thebookisclosed/ViVe)

#
### Useful Commands

* Fix for TranslucentTB (making toolbar translucent):
 
``` batch
vivetool /disable /id:26008830 && vivetool /disable /id:38764045
```

#
> **App ID Names**:
> - "9NKSQGP7F2NH" = WhatsApp
> - "9NCBCSZSJRSB" = Spotify
> - "9PF4KZ2VN4W9" = TranslucentTB
> - "9WZDNCRF0083" = Facebook Messenger
