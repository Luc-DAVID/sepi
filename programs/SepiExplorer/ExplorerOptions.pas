{-------------------------------------------------------------------------------
SepiExplorer - Example program for Sepi
As an example program, SepiExplorer is free of any usage. It is released in the
public domain.
-------------------------------------------------------------------------------}

{*
  Options de l'explorateur
  @author sjrd
  @version 1.0
*}
unit ExplorerOptions;

interface

uses
  SysUtils, IniFiles, ScUtils, ExplorerConsts;

type
  {*
    Options enregistr�es de l'explorateur
    @author sjrd
    @version 1.0
  *}
  TExplorerOptions = class
  private
    FFileName: TFileName; /// Nom du fichier o� sont sock�es les options

    FBrowsingPath: string; /// Chemin de recherche des unit�s Sepi

    procedure LoadFromFile;
    procedure SaveToFile;
  protected
    property FileName: TFileName read FFileName;
  public
    constructor Create;

    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function SearchFile(const FileName: TFileName): TFileName;

    property BrowsingPath: string read FBrowsingPath write FBrowsingPath;
  end;

implementation

{*
  [@inheritDoc]
*}
constructor TExplorerOptions.Create;
begin
  inherited Create;

  FFileName := ChangeFileExt(ParamStr(0), IniExt);
end;

{*
  Charge les options depuis le fichier d'options
*}
procedure TExplorerOptions.LoadFromFile;
var
  IniFile: TMemIniFile;
begin
  if not FileExists(FileName) then
    Exit;

  IniFile := TMemIniFile.Create(FileName);
  try
    BrowsingPath := IniFile.ReadString('Sepi', 'BrowsingPath', '');
  finally
    IniFile.Free;
  end;
end;

{*
  Enregistre les options dans le fichier d'options
*}
procedure TExplorerOptions.SaveToFile;
var
  IniFile: TMemIniFile;
begin
  IniFile := TMemIniFile.Create(FileName);
  try
    IniFile.WriteString('Sepi', 'BrowsingPath', BrowsingPath);
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TExplorerOptions.AfterConstruction;
begin
  inherited;

  LoadFromFile;
end;

{*
  [@inheritDoc]
*}
procedure TExplorerOptions.BeforeDestruction;
begin
  inherited;

  SaveToFile;
end;

{*
  Recherche un fichier dans un chemin de recherche
  @param FileName   Nom du fichier recherch�
  @return Nom complet du fichier, ou une cha�ne vide si non trouv�
*}
function TExplorerOptions.SearchFile(const FileName: TFileName): TFileName;
begin
  Result := FileSearch(FileName, BrowsingPath);
end;

end.

