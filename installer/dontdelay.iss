; DontDelay Windows 설치 프로그램 (Inno Setup 6)
; 컴파일 전: flutter build windows  (windows 철자 주의, window 아님)

#define MyAppName "DontDelay"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "안미룬이"
#define MyAppExeName "dontdelay.exe"
#define ReleaseDir "..\build\windows\x64\runner\Release"
#define AppIcon "..\windows\runner\resources\app_icon.ico"

#ifexist "..\build\windows\x64\runner\Release\dontdelay.exe"
#else
#pragma error "릴리스 빌드가 없습니다. 프로젝트 루트에서 'flutter build windows' 를 먼저 실행하세요."
#endif

[Setup]
AppId={{A7C3E91F-4B2D-4F8E-9A1C-5D6E7F8091B2}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=DontDelay_Setup_{#MyAppVersion}
SetupIconFile={#AppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
VersionInfoVersion={#MyAppVersion}.0

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Tasks]
Name: "desktopicon"; Description: "바탕화면에 바로가기 만들기"; GroupDescription: "추가 작업:"

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{#MyAppName} 제거"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{#MyAppName} 실행"; Flags: nowait postinstall skipifsilent
