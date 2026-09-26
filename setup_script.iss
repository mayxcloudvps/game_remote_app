[Setup]
AppName=MAYX CLOUD GAMING Server
AppVersion=1.0.0
DefaultDirName={autopf}\MayxCloudGamingServer
DefaultGroupName=MAYX CLOUD GAMING
UninstallDisplayIcon={app}\MayxServer.exe
Compression=lzma2/ultra
SolidCompression=yes
OutputDir=Output
OutputBaseFilename=MayxCloudGaming_Server_Setup
SetupIconFile=app_icon.ico

[Files]
Source: "dist\MayxServer.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\MAYX CLOUD GAMING Server"; Filename: "{app}\MayxServer.exe"
Name: "{autodesktop}\MAYX CLOUD GAMING Server"; Filename: "{app}\MayxServer.exe"

[Run]
Filename: "{app}\MayxServer.exe"; Description: "Chạy MAYX CLOUD GAMING Server ngay"; Flags: nowait postinstall skipifsilent
