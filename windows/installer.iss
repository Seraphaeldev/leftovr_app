; Optional Inno Setup installer for leftovr.
; Build it after build_windows.bat has produced the Release folder:
;   ISCC.exe windows\installer.iss
; Install Inno Setup from https://jrsoftware.org/isinfo.php

[Setup]
AppName=leftovr
AppVersion=1.0.0
AppPublisher=leftovr
SourceDir=..
DefaultDirName={autopf}\leftovr
DefaultGroupName=leftovr
OutputDir=build\installer
OutputBaseFilename=leftovr-setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\leftovr.exe

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: desktopicon; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Icons]
Name: "{group}\leftovr"; Filename: "{app}\leftovr.exe"
Name: "{autodesktop}\leftovr"; Filename: "{app}\leftovr.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\leftovr.exe"; Description: "Launch leftovr"; Flags: nowait postinstall skipifsilent
