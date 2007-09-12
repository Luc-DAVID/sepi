{*
  Chargeur d'unit� Sepi-PS
  @author sjrd
  @version 1.0
*}
unit SepiPSLoader;

interface

uses
  SysUtils, Classes, SepiReflectionCore;

function LoadSepiPSUnitFromStream(Root : TSepiRoot;
  Stream : TStream) : TSepiUnit;
function LoadSepiPSUnitFromFile(Root : TSepiRoot;
  const FileName : TFileName) : TSepiUnit;
function LoadSepiPSUnitFromName(Root : TSepiRoot;
  const UnitName : string) : TSepiUnit;

function SepiPSLoadUnit(Self : TObject; Root : TSepiRoot;
  const UnitName : string) : TSepiUnit;

const {don't localize}
  /// Extension des fichiers unit� Sepi-PS
  sSepiPSExtension = '.sps';

implementation

uses
  Windows, ScUtils, ScDelphiLanguage, SepiMembers, uPSRunTime, SepiPSRuntime;

{-----------------}
{ Global routines }
{-----------------}

{*
  Ex�cute la main proc d'un interpr�teur Pascal Script
  @param PSExecuter   Interpr�teur Pascal Script
*}
procedure MainProc(PSExecuter : TPSExec);
begin
  if not PSExecuter.RunScript then
    PSExecuter.RaiseCurrentException;
end;

{*
  Lie une routine de l'interpr�teur Pascal Script � son correspondant Sepi
  @param Routine      Routine Sepi
  @param PSExecuter   Interpr�teur Pascal Script
*}
procedure LinkPSToSepiRoutine(Routine : TSepiMethod; PSExecuter : TPSExec);
var ProcName : string;
    Method : TMethod;
begin
  if AnsiSameText(Routine.Name, '$MAIN') then
  begin
    // Main proc of the Pascal Script executer
    Method.Code := @MainProc;
    Method.Data := PSExecuter;
  end else
  begin
    // Normal routine or method
    ProcName := Routine.Name;
    if Routine.Owner is TSepiClass then
      ProcName := Routine.Owner.Name + '_' + ProcName;
    Method := PSExecuter.GetProcAsMethodN(ProcName);
  end;

  Routine.SetCodeMethod(Method);
end;

{*
  Lie chaque �l�ment de l'interpr�teur Pascal Script � son correspondant Sepi
  @param SepiUnit     Unit� Sepi
  @param PSExecuter   Interpr�teur Pascal Script
*}
procedure LinkPSToSepiClass(SepiClass : TSepiClass; PSExecuter : TPSExec);
var I : integer;
    Child : TSepiMeta;
begin
  for I := 0 to SepiClass.ChildCount-1 do
  begin
    Child := SepiClass.Children[I];

    if Child is TSepiMethod then
      LinkPSToSepiRoutine(TSepiMethod(Child), PSExecuter);
  end;
end;

{*
  Lie chaque �l�ment de l'interpr�teur Pascal Script � son correspondant Sepi
  @param SepiUnit     Unit� Sepi
  @param PSExecuter   Interpr�teur Pascal Script
*}
procedure LinkPSToSepi(SepiUnit : TSepiUnit; PSExecuter : TPSExec);
var I : integer;
    Child : TSepiMeta;
begin
  for I := 0 to SepiUnit.ChildCount-1 do
  begin
    Child := SepiUnit.Children[I];

    if Child is TSepiMethod then
      LinkPSToSepiRoutine(TSepiMethod(Child), PSExecuter)
    else if Child is TSepiClass then
      LinkPSToSepiClass(TSepiClass(Child), PSExecuter);
  end;
end;

{*
  Charge une unit� Sepi-PS depuis un flux
  @param Root     Racine Sepi
  @param Stream   Flux source
  @return Unit� Sepi charg�e
*}
function LoadSepiPSUnitFromStream(Root : TSepiRoot;
  Stream : TStream) : TSepiUnit;
var I : integer;
    UsesList : array of TSepiUnit;
    PSExecuter : TPSExec;
begin
  // Load the Sepi unit
  Result := TSepiUnit.LoadFromStream(Root, Stream);
  try
    // Set up the uses list
    SetLength(UsesList, Result.UsedUnitCount);
    for I := 0 to Result.UsedUnitCount-1 do
      UsesList[I] := Result.UsedUnits[I];

    // Create the PS executer
    PSExecuter := TPSExec.Create;
    Result.AddObjResource(PSExecuter);

    // Load the PS unit
    SepiLoadPSExecuter(Root, UsesList, PSExecuter,
      ReadStrFromStream(Stream));

    // Link PS unit to Sepi unit
    LinkPSToSepi(Result, PSExecuter);
  except
    Result.Free;
    raise;
  end;
end;

{*
  Charge une unit� Sepi-PS depuis un fichier
  @param Root       Racine Sepi
  @param FileName   Nom du fichier
  @return Unit� Sepi charg�e
*}
function LoadSepiPSUnitFromFile(Root : TSepiRoot;
  const FileName : TFileName) : TSepiUnit;
var Stream : TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := LoadSepiPSUnitFromStream(Root, Stream);
  finally
    Stream.Free;
  end;
end;

{*
  Charge une unit� Sepi-PS depuis son nom
  @param Root       Racine Sepi
  @param UnitName   Nom de l'unit�
  @return Unit� Sepi charg�e
*}
function LoadSepiPSUnitFromName(Root : TSepiRoot;
  const UnitName : string) : TSepiUnit;
var FileName : TFileName;
begin
  FileName := UnitName + sSepiPSExtension;
  if FileExists(FileName) then
    Result := LoadSepiPSUnitFromFile(Root, FileName)
  else
    Result := nil;
end;

{*
  Routine de call-back pour l'�v�nement OnLoadUnit de TSepiRoot
  @param Self       Objet courant, non utilis�
  @param Root       Racine Sepi
  @param UnitName   Nom de l'unit�
  @return Unit� Sepi charg�e
*}
function SepiPSLoadUnit(Self : TObject; Root : TSepiRoot;
  const UnitName : string) : TSepiUnit;
begin
  Result := LoadSepiPSUnitFromName(Root, UnitName);
end;

end.

