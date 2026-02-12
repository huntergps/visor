; Inno Setup script para TheosVisor - Visor de Precios
; Compilar con: iscc /DMyAppVersion=1.0.1 /DMyProjectDir="D:\2026\visor" installer.iss

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#ifndef MyProjectDir
  #define MyProjectDir ".."
#endif

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName=TheosVisor - Visor de Precios
AppVersion={#MyAppVersion}
AppPublisher=HunterGPS
DefaultDirName={autopf}\Visor
DefaultGroupName=Visor
UninstallDisplayIcon={app}\visor.exe
OutputDir={#MyProjectDir}\instalador
OutputBaseFilename=visor-windows-v{#MyAppVersion}-setup
SetupIconFile={#MyProjectDir}\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "{#MyProjectDir}\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autodesktop}\Visor de Precios"; Filename: "{app}\visor.exe"; IconFilename: "{app}\visor.exe"
Name: "{group}\Visor de Precios"; Filename: "{app}\visor.exe"
Name: "{group}\Desinstalar Visor"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\visor.exe"; Description: "Ejecutar Visor de Precios"; Flags: nowait postinstall skipifsilent
