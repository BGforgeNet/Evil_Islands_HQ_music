; Evil Islands HQ music installer:
;   iscc installer/setup.iss /DVersion=<version>
; Takes res\ and stream\ from the repository root; writes to out\ there.
;
; Installs into the game folder, found from the game's registry keys; the folder must hold game.exe. Each game file
; it replaces is kept under hq-music\backup and put back on uninstall.

#if !Defined(Version)
  #error Define Version
#endif

[Setup]
AppId=EvilIslandsHQMusic
AppName=Evil Islands HQ music
AppVersion={#Version}
AppVerName=Evil Islands HQ music {#Version}
AppPublisher=BGforge
AppPublisherURL=https://github.com/BGforgeNet/Evil_Islands_HQ_music
SourceDir=..
OutputDir=out
OutputBaseFilename=evil_islands_hq_music_{#Version}
; FLAC and MP3 do not compress further.
Compression=none
; Game folders are usually writable by the user. For one that is not, the installer restarts itself with /ALLUSERS,
; which asks for administrator rights.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
DefaultDirName={code:FindGameDir}
AppendDefaultDirName=no
DirExistsWarning=no
DisableProgramGroupPage=yes
UninstallFilesDir={app}\hq-music
WizardStyle=modern
; The setup's own language follows Windows'; it asks only when that is none of its languages.
ShowLanguageDialog=auto

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[CustomMessages]
en.SelectGame=Select the Evil Islands folder, the one with game.exe.
en.NoGame=There is no game.exe in this folder. Select the Evil Islands folder.
en.NoEixCaption=eix not found
en.NoEixDesc=The lossless music needs eix 0.2.0 or later.
en.NoEix=eix 0.2.0 or later was not found in EIStarter-UM's folder or its mods. Without it, the game keeps playing its own MP3 music.%n%nGet eix at https://github.com/BGforgeNet/eix/releases. You can install it before or after this music.%n%nClick Next to install the music anyway.
ru.SelectGame=Выберите папку Проклятых Земель, в которой находится game.exe.
ru.NoGame=В этой папке нет game.exe. Выберите папку Проклятых Земель.
ru.NoEixCaption=eix не найден
ru.NoEixDesc=Для музыки без потерь нужен eix 0.2.0 или новее.
ru.NoEix=eix 0.2.0 или новее не найден ни в папке EIStarter-UM, ни в её модах. Без него игра продолжит играть свою музыку MP3.%n%neix можно скачать на https://github.com/BGforgeNet/eix/releases. Его можно установить до или после этой музыки.%n%nНажмите "Далее", чтобы всё равно установить музыку.
de.SelectGame=Wählen Sie den Ordner von Evil Islands, in dem game.exe liegt.
de.NoGame=In diesem Ordner gibt es keine game.exe. Wählen Sie den Ordner von Evil Islands.
de.NoEixCaption=eix nicht gefunden
de.NoEixDesc=Die verlustfreie Musik braucht eix 0.2.0 oder neuer.
de.NoEix=eix 0.2.0 oder neuer wurde weder im Ordner von EIStarter-UM noch in seinen Mods gefunden. Ohne eix spielt das Spiel weiter seine eigene MP3-Musik.%n%neix gibt es unter https://github.com/BGforgeNet/eix/releases. Sie können es vor oder nach dieser Musik installieren.%n%nKlicken Sie auf "Weiter", um die Musik trotzdem zu installieren.

[Files]
; music.ini is the editable source of music.reg; the game reads only the .reg.
Source: "res\*"; Excludes: "music.ini"; DestDir: "{app}\res"; Flags: ignoreversion; BeforeInstall: Backup
Source: "stream\*"; DestDir: "{app}\stream"; Flags: ignoreversion; BeforeInstall: Backup

[Code]
var
  Relaunched: Boolean;
  EixPage: TOutputMsgWizardPage;

{ The game's own key first, then EI starter's copy of it, then GOG's; else GOG's default folder. }
function FindGameDir(Param: String): String;
begin
  if not RegQueryStringValue(HKCU, 'Software\Nival Interactive\EvilIslands\Path Settings', 'WORK PATH', Result)
    or (Result = '') then
    if not RegQueryStringValue(HKCU, 'Software\Gipat.ru\EI_Starter\EvilIslands\Path Settings', 'WORK PATH', Result)
      or (Result = '') then
      if not RegQueryStringValue(HKLM, 'Software\GOG.com\Games\1457950224', 'PATH', Result) or (Result = '') then
        Result := ExpandConstant('{sd}\GOG Games\Evil Islands');
  Result := RemoveBackslashUnlessRoot(Result);
end;

function HasGame(Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'game.exe');
end;

{ Whether this run can write into Dir: a folder under Program Files needs administrator rights. }
function CanWrite(Dir: String): Boolean;
var
  Probe: String;
begin
  Probe := AddBackslash(Dir) + 'hq-music-write-test.tmp';
  Result := SaveStringToFile(Probe, '', False);
  if Result then
    DeleteFile(Probe);
end;

{ Starts this setup again with administrator rights and the chosen folder, and closes this one. }
procedure RelaunchAsAdmin;
var
  ErrorCode: Integer;
begin
  if ShellExec('', ExpandConstant('{srcexe}'), '/ALLUSERS /DIR="' + WizardDirValue + '"', '', SW_SHOWNORMAL,
    ewNoWait, ErrorCode) then
  begin
    Relaunched := True;
    WizardForm.Close;
  end
  else
    Log('Starting again as administrator failed: ' + SysErrorMessage(ErrorCode));
end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  if Relaunched then
    Confirm := False;
end;

{ Whether the addon.dll in Dir is eix 0.2.0 or later: from that version on it reads the EIX_GAIN tag, and its name
  is in the file. eix carries no version resource to read instead. }
function IsEixAddon(const Dir: String): Boolean;
var
  Data: AnsiString;
begin
  Result := LoadStringFromFile(AddBackslash(Dir) + 'addon.dll', Data) and (Pos('EIX_GAIN', Data) > 0);
  if Result then
    Log('eix 0.2.0 or later in ' + Dir);
end;

{ eix's addon.dll goes into EIStarter-UM's folder, or a mod's folder under it (EItweaks); the game folder is checked
  too. }
function FindEix: Boolean;
var
  Starter: String;
  Found: TFindRec;
begin
  Result := IsEixAddon(WizardDirValue);
  if Result or not RegQueryStringValue(HKCU, 'Software\Gipat.ru\EI_Starter', 'path', Starter) or (Starter = '') then
    Exit;
  Starter := RemoveBackslashUnlessRoot(Starter);
  Result := IsEixAddon(Starter);
  if not Result and FindFirst(Starter + '\Mods\*', Found) then
    try
      repeat
        if (Found.Name <> '.') and (Found.Name <> '..') and (Found.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0) then
          Result := IsEixAddon(Starter + '\Mods\' + Found.Name);
      until Result or not FindNext(Found);
    finally
      FindClose(Found);
    end;
end;

procedure InitializeWizard;
begin
  WizardForm.SelectDirLabel.Caption := CustomMessage('SelectGame');
  EixPage := CreateOutputMsgPage(wpSelectDir, CustomMessage('NoEixCaption'), CustomMessage('NoEixDesc'),
    CustomMessage('NoEix'));
end;

{ The warning about eix shows only when it is missing; the music installs either way. }
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := (PageID = EixPage.ID) and FindEix;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = wpSelectDir then
  begin
    if not HasGame(WizardDirValue) then
    begin
      MsgBox(CustomMessage('NoGame'), mbError, MB_OK);
      Result := False;
    end
    else if not IsAdminInstallMode and not CanWrite(WizardDirValue) then
    begin
      Log('Cannot write into ' + WizardDirValue + ': starting again as administrator');
      RelaunchAsAdmin;
      Result := False;
    end;
  end;
end;

{ Also reached by silent installs, which skip the wizard pages. }
function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  if not HasGame(WizardDirValue) then
    Result := CustomMessage('NoGame')
  else if WizardSilent and not FindEix then
    Log('eix 0.2.0 or later not found: the game will play its own MP3 music');
end;

{ Before each file is copied: keeps the game's original once, under hq-music\backup. }
procedure Backup;
var
  Dest, Saved: String;
begin
  Dest := ExpandConstant(CurrentFileName);
  Saved := ExpandConstant('{app}\hq-music\backup\') + Copy(Dest, Length(ExpandConstant('{app}\')) + 1, MaxInt);
  if FileExists(Dest) and not FileExists(Saved) then
  begin
    ForceDirectories(ExtractFileDir(Saved));
    if not CopyFile(Dest, Saved, False) then
      RaiseException('Could not back up ' + Dest);
  end;
end;

procedure RestoreDir(const Src, Dst: String);
var
  Found: TFindRec;
begin
  if FindFirst(Src + '\*', Found) then
    try
      repeat
        if (Found.Name <> '.') and (Found.Name <> '..') then
          if Found.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
          begin
            ForceDirectories(Dst + '\' + Found.Name);
            RestoreDir(Src + '\' + Found.Name, Dst + '\' + Found.Name);
          end
          else
            CopyFile(Src + '\' + Found.Name, Dst + '\' + Found.Name, False);
      until not FindNext(Found);
    finally
      FindClose(Found);
    end;
end;

{ After the uninstaller has removed the music: puts the game's originals back. }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Saved: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    Saved := ExpandConstant('{app}\hq-music\backup');
    if DirExists(Saved) then
    begin
      RestoreDir(Saved, ExpandConstant('{app}'));
      DelTree(ExpandConstant('{app}\hq-music'), True, True, True);
    end;
  end;
end;
