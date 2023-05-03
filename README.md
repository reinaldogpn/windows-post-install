# windows-post-install.bat

This batch script automatically installs the programs I use in my PC, runs updates and apply some personal preferences.

Works fine on ***Windows 10 or higher***.

#
### How to use
* Define the programs to be installed in file "applist.txt" by it's "winget ID". 
* In case you don't know the ID of an app, use `winget search <appname>` on terminal.
* Always run the .bat file as admin.
<!--
#
If you don't want to change the app list, just run the command:
```
curl -sSf https://raw.githubusercontent.com/reinaldogpn/windows-post-install/main/windows-post-install.bat | cmd
```
-->
