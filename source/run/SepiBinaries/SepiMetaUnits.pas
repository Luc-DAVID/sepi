{*
  D�finit les classes de gestion des meta-unit�s
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit SepiMetaUnits;

interface

uses
  SysUtils, Classes, Contnrs, RTLConsts, SepiCore, ScUtils, IniFiles, TypInfo,
  ScLists, SepiBinariesConsts;

type
  {*
    �tat d'un meta
  *}
  TSepiMetaState = (msNormal, msConstructing, msLoading, msDestroying);

  {*
    Visibilit� d'un membre d'une classe, d'un objet, ou d'une unit�
  *}
  TSepiMemberVisibility = (mvPrivate, mvInternal, mvProtected,
    mvInternalProtected, mvPublic, mvPublished);

  {*
    Statut dynamique d'une m�thode
  *}
  TSepiMethodOverrideState = (osNone, osVirtual, osDynamic, osOverride);

  {*
    Convention d'appel d'une m�thode
  *}
  TSepiCallConvention = (ccRegister, ccStdCall, ccPascal, ccCDecl);

  {*
    Type d'accesseur d'une propri�t�
  *}
  TSepiPropertyAccessKind = (pakNone, pakVariable, pakMethod);

  {*
    D�clench�e lorsque la recherche d'un meta s'est sold�e par un �chec
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  ESepiMetaNotFoundError = class(ESepiError);

  TSepiMeta = class;
  TSepiMetaRoot = class;
  TSepiMetaUnit = class;
  TSepiMetaVariable = class;
  TSepiMetaMethod = class;
  TSepiMetaOverloadedMethod = class;
  TSepiMetaProperty = class;
  TSepiConstant = class;
  TSepiTypeAlias = class;

  {*
    Liste de meta
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaList = class(THashedStringList)
  private
    function GetMetas(Index : integer) : TSepiMeta;
    procedure SetMetas(Index : integer; Value : TSepiMeta);
    function GetMetaFromName(const Name : string) : TSepiMeta;
    procedure SetMetaFromName(const Name : string; Value : TSepiMeta);
  public
    constructor Create;

    function AddMeta(Meta : TSepiMeta) : integer;
    function IndexOfMeta(Meta : TSepiMeta) : integer;
    function Remove(Meta : TSepiMeta) : integer;

    property Metas[index : integer] : TSepiMeta
      read GetMetas write SetMetas; default;
    property MetaFromName[const Name : string] : TSepiMeta
      read GetMetaFromName write SetMetaFromName;
  end;

  {*
    Meta g�n�rique
    Les meta sont les informations statiques qui repr�sentent les unit�s
    compil�es.
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMeta = class
  private
    FState : TSepiMetaState;             /// �tat
    FOwner : TSepiMeta;                  /// Propri�taire
    FRoot : TSepiMetaRoot;               /// Racine
    FOwningUnit : TSepiMetaUnit;         /// Unit� contenante
    FName : string;                      /// Nom
    FVisibility : TSepiMemberVisibility; /// Visibilit�
    FChildren : TSepiMetaList;           /// Liste des enfants

    procedure AddChild(Child : TSepiMeta);
    procedure RemoveChild(Child : TSepiMeta);
  protected
    procedure LoadChildren(Stream : TStream);

    procedure ChildAdded(Child : TSepiMeta); virtual;
    procedure ChildRemoving(Child : TSepiMeta); virtual;

    procedure Loaded; virtual;

    property State : TSepiMetaState read FState;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); virtual;
    constructor Create(AOwner : TSepiMeta; const AName : string);
    destructor Destroy; override;
    procedure BeforeDestruction; override;

    function GetFullName : string;
    function GetMeta(const Name : string) : TSepiMeta;
    function FindMeta(const Name : string) : TSepiMeta;

    property Owner : TSepiMeta read FOwner;
    property Root : TSepiMetaRoot read FRoot;
    property OwningUnit : TSepiMetaUnit read FOwningUnit;
    property Name : string read FName;
    property Visibility : TSepiMemberVisibility
      read FVisibility write FVisibility;
  end;

  {*
    Classe de TSepiMeta
  *}
  TSepiMetaClass = class of TSepiMeta;

  {*
    Type
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiType = class(TSepiMeta)
  private
    FKind : TTypeKind;         /// Type de type
    FTypeInfoLength : integer; /// Taille des RTTI cr��es (ou 0 si non cr��es)
    FTypeInfo : PTypeInfo;     /// RTTI (Runtime Type Information)
    FTypeData : PTypeData;     /// RTTD (Runtime Type Data)
  protected
    FSize : integer; /// Taille d'une variable de ce type

    procedure AllocateTypeInfo(TypeDataLength : integer = 0);
    procedure ExtractTypeData; virtual;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); virtual;
    constructor Clone(AOwner : TSepiMeta; const AName : string;
      Source : TSepiType); virtual;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AKind : TTypeKind);
    destructor Destroy; override;

    class function LoadFromTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo) : TSepiType;

    function CompatibleWith(AType : TSepiType) : boolean; virtual;

    property Kind : TTypeKind read FKind;
    property TypeInfo : PTypeInfo read FTypeInfo;
    property TypeData : PTypeData read FTypeData;
    property Size : integer read FSize;
  end;

  {*
    Meta-racine
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaRoot = class(TSepiMeta)
  private
    function GetUnitCount : integer;
    function GetUnits(Index : integer) : TSepiMetaUnit;
  public
    constructor Create;

    procedure LoadUnit(UnitName : string);

    function FindTypeByTypeInfo(TypeInfo : PTypeInfo) : TSepiType;

    property UnitCount : integer read GetUnitCount;
    property Units[index : integer] : TSepiMetaUnit read GetUnits;
  end;

  {*
    Meta-unit�
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaUnit = class(TSepiType)
  private
    { TODO 2 -cMetaunit�s : Ajouter des champs concernant les en-t�te d'unit� }
    FCurrentVisibility : TSepiMemberVisibility;
    FLoadingReferences : TStrings;

    procedure SetCurrentVisibility(Value : TSepiMemberVisibility);
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string);

    procedure LoadRef(var Ref);

    property CurrentVisibility : TSepiMemberVisibility
      read FCurrentVisibility write SetCurrentVisibility;
  end;

  {*
    Alias de type
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiTypeAlias = class(TSepiMeta)
  private
    FDest : TSepiType;
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      ADest : TSepiType);

    property Dest : TSepiType read FDest;
  end;

  {*
    Constante
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiConstant = class(TSepiMeta)
  private
    FType : TSepiType;
    FValue : TMemoryStream;
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AType : TSepiType);

    property ConstType : TSepiType read FType;
    property Value : TMemoryStream read FValue;
  end;

  {*
    Meta-variable
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaVariable = class(TSepiMeta)
  private
    FType : TSepiType;
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AType : TSepiType);

    property VarType : TSepiType read FType;
  end;

  {*
    Meta-param�tre de m�thode
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaParam = class(TSepiMetaVariable)
  private
    FParamKind : TParamFlags;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AType : TSepiType; AParamKind : TParamFlags = []);

    function CompatibleWith(AVariable : TSepiMetaVariable) : boolean;

    property ParamKind : TParamFlags read FParamKind;
  end;

  {*
    Signature d'une m�thode
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMethodSignature = class
  private
    FOwner : TSepiMeta;
    FParams : TSepiMetaList;
    FReturnType : TSepiType;

    procedure Loaded;

    function GetParamCount : integer;
    function GetParams(Index : integer) : TSepiMetaParam;
  public
    constructor Create(AOwner : TSepiMeta);
    destructor Destroy; override;

    procedure Load(Stream : TStream);

    function CompatibleWith(ASignature : TSepiMethodSignature) : boolean;

    property ParamCount : integer read GetParamCount;
    property Params[index : integer] : TSepiMetaParam read GetParams;
    property ReturnType : TSepiType read FReturnType;
  end;

  {*
    Meta-m�thode
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaMethod = class(TSepiMeta)
  private
    { TODO 2 -cMetaunit�s : Ajouter des champs concernant les directives de
      m�thodes }
    FSignature : TSepiMethodSignature;
    FKind : TMethodKind;
    FOverrideState : TSepiMethodOverrideState;
    FAbstract : boolean;
    FInherited : TSepiMetaMethod;

    procedure FindInherited;
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AKind : TMethodKind = mkProcedure;
      AOverrideState : TSepiMethodOverrideState = osNone;
      AAbstract : boolean = False);
    destructor Destroy; override;

    property Signature : TSepiMethodSignature read FSignature;
    property OverrideState : TSepiMethodOverrideState read FOverrideState;
    property IsAbstract : boolean read FAbstract;
  end;

  {*
    Meta-m�thode manag�e Sepi
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaSepiMethod = class(TSepiMetaMethod)
  private
    FVariables : TSepiMetaList;
    FCode : TStream;

    function GetVariableCount : integer;
    function GetVariables(Index : integer) : TSepiMetaVariable;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AKind : TMethodKind = mkProcedure;
      AOverrideState : TSepiMethodOverrideState = osNone;
      AAbstract : boolean = False);
    destructor Destroy; override;

    property VariableCount : integer read GetVariableCount;
    property Variables[index : integer] : TSepiMetaVariable read GetVariables;
    property Code : TStream read FCode;
  end;

  {*
    Meta-m�thode native Delphi
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaDelphiMethod = class(TSepiMetaMethod)
  private
    FCallConvention : TSepiCallConvention;
    FCode : Pointer;
  public
    constructor Create(AOwner : TSepiMeta; const AName : string;
      ACode : Pointer; AKind : TMethodKind = mkProcedure;
      AOverrideState : TSepiMethodOverrideState = osNone;
      AAbstract : boolean = False;
      ACallConvention : TSepiCallConvention = ccRegister);

    property CallConvention : TSepiCallConvention read FCallConvention;
    property Code : Pointer read FCode;
  end;

  {*
    Meta-m�thode surcharg�e
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaOverloadedMethod = class(TSepiMeta)
  private
    FMethodCount : integer;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string);

    function NextID : integer;
    function FindMethod(Signature : TSepiMethodSignature) : TSepiMetaMethod;
  end;

  {*
    Meta-propri�t�
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaProperty = class(TSepiMeta)
  private
    FSignature : TSepiMethodSignature;

    FReadAccess : TSepiMeta;
    FReadAccessKind : TSepiPropertyAccessKind;
    FReadVariableAccess : TSepiMetaVariable;
    FReadMethodAccess : TSepiMetaMethod;

    FWriteAccess : TSepiMeta;
    FWriteAccessKind : TSepiPropertyAccessKind;
    FWriteVariableAccess : TSepiMetaVariable;
    FWriteMethodAccess : TSepiMetaMethod;

    procedure DevelopAccess;
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AReadAccess : TSepiMeta; AWriteAccess : TSepiMeta);
    destructor Destroy; override;

    property Signature : TSepiMethodSignature read FSignature;

    property ReadAccessKind : TSepiPropertyAccessKind read FReadAccessKind;
    property ReadVariableAccess : TSepiMetaVariable read FReadVariableAccess;
    property ReadMethodAccess : TSepiMetaMethod read FReadMethodAccess;

    property WriteAccessKind : TSepiPropertyAccessKind read FWriteAccessKind;
    property WriteVariableAccess : TSepiMetaVariable read FWriteVariableAccess;
    property WriteMethodKind : TSepiMetaMethod read FWriteMethodAccess;
  end;

  {*
    Type de routine call-back pour l'import d'une unit� sous Sepi
  *}
  TSepiImportUnitFunc = function(Root : TSepiMetaRoot) : TSepiMetaUnit;

procedure SepiRegisterMetaClasses(MetaClasses : array of TSepiMetaClass);

procedure SepiRegisterImportedUnit(const UnitName : string;
  ImportFunc : TSepiImportUnitFunc);
procedure SepiUnregisterImportedUnit(const UnitName : string);

implementation

uses
  SepiOrdTypes, SepiStrTypes, SepiArrayTypes, SepiCompTypes, SepiImportsSystem;

var
  SepiMetaClasses : TStrings = nil;
  SepiImportedUnits : TStrings = nil;

{*
  Recense des classes de meta
  @param MetaClasses   Classes de meta � recenser
*}
procedure SepiRegisterMetaClasses(MetaClasses : array of TSepiMetaClass);
var I : integer;
begin
  if not Assigned(SepiMetaClasses) then
  begin
    SepiMetaClasses := TStringList.Create;
    with TStringList(SepiMetaClasses) do
    begin
      CaseSensitive := False;
      Duplicates := dupIgnore;
    end;
  end;

  for I := Low(MetaClasses) to High(MetaClasses) do
  begin
    SepiMetaClasses.AddObject(
      MetaClasses[I].ClassName, TObject(MetaClasses[I]));
  end;
end;

{*
  Cherche une classe de meta par son nom
  La classe recherch�e doit avoir �t� recens�e au pr�alable avec
  SepiRegisterMetaClasses.
  @param MetaClassName   Nom de la classe de meta
  @return La classe de meta dont le nom correspond
  @throws EClassNotFound La classe recherch�e n'existe pas
*}
function SepiFindMetaClass(const MetaClassName : string) : TSepiMetaClass;
var Index : integer;
begin
  if not Assigned(SepiMetaClasses) then Index := -1 else
    Index := SepiMetaClasses.IndexOf(MetaClassName);
  if Index < 0 then
    EClassNotFound.CreateFmt(SClassNotFound, [MetaClassName]);

  Result := TSepiMetaClass(SepiMetaClasses.Objects[Index]);
end;

{*
  Recense une routine d'import d'unit�
  @param UnitName     Nom de l'unit�
  @param ImportFunc   Routine de call-back pour l'import de l'unit�
*}
procedure SepiRegisterImportedUnit(const UnitName : string;
  ImportFunc : TSepiImportUnitFunc);
begin
  if not Assigned(SepiImportedUnits) then
  begin
    SepiImportedUnits := TStringList.Create;
    with TStringList(SepiImportedUnits) do
    begin
      CaseSensitive := False;
      Duplicates := dupIgnore;
    end;
  end;

  SepiImportedUnits.AddObject(UnitName, TObject(@ImportFunc));
end;

{*
  Supprime un recensement d'import d'unit�
  @param UnitName   Nom de l'unit�
*}
procedure SepiUnregisterImportedUnit(const UnitName : string);
var Index : integer;
begin
  if not Assigned(SepiImportedUnits) then exit;
  Index := SepiImportedUnits.IndexOf(UnitName);
  if Index >= 0 then
    SepiImportedUnits.Delete(Index);
end;

{*
  Cherche une routine d'import d'une unit�
  Cette routine doit avoir �t� recens�e au pr�lable avec
  SepiRegisterImportedUnit.
  @param UnitName   Nom de l'unit�
  @return Routine de call-back pour l'import de l'unit�, ou nil si n'existe pas
*}
function SepiImportedUnit(const UnitName : string) : TSepiImportUnitFunc;
var Index : integer;
begin
  if not Assigned(SepiImportedUnits) then Result := nil else
  begin
    Index := SepiImportedUnits.IndexOf(UnitName);
    if Index < 0 then Result := nil else
      Result := TSepiImportUnitFunc(SepiImportedUnits.Objects[Index]);
  end;
end;

{----------------------}
{ Classe TSepiMetaList }
{----------------------}

{*
  Cr�e une instance de TSepiMetaList
*}
constructor TSepiMetaList.Create;
begin
  inherited;
  CaseSensitive := False;
  Duplicates := dupError;
end;

{*
  Liste zero-based des metas
  @param Index   Index du meta � obtenir
  @return Meta � l'index sp�cifi�
*}
function TSepiMetaList.GetMetas(Index : integer) : TSepiMeta;
begin
  Result := TSepiMeta(Objects[Index]);
end;

{*
  Assigne la r�f�rence � un meta
  Un meta ne peut pas �tre modif� une fois assign�, il ne peut donc �tre assign�
  qu'une et une seule fois.
  @param Index   Index du meta � modifier
  @param Value   R�f�rence au nouveau meta
*}
procedure TSepiMetaList.SetMetas(Index : integer; Value : TSepiMeta);
begin
  if Assigned(Objects[Index]) then
    Error(@SSepiMetaAlreadyAssigned, Index);
  Objects[Index] := Value;
end;

{*
  Liste des metas index�e par leurs noms
  @param Name   Nom d'un meta
  @return Le meta dont le nom a �t� sp�cifi�, ou nil s'il n'existe pas
*}
function TSepiMetaList.GetMetaFromName(const Name : string) : TSepiMeta;
var Index : integer;
begin
  Index := IndexOf(Name);
  if Index < 0 then Result := nil else
    Result := TSepiMeta(Objects[Index]);
end;

{*
  Assigne ou ajoute un meta par son nom
  Un meta ne peut pas �tre modif� une fois assign�, il ne peut donc �tre assign�
  qu'une et une seule fois.
  @param Name    Nom du meta
  @param Value   R�f�rence au meta
*}
procedure TSepiMetaList.SetMetaFromName(const Name : string; Value : TSepiMeta);
var Index : integer;
begin
  Index := IndexOf(Name);
  if Index < 0 then AddObject(Name, Value) else
    Metas[Index] := Value;
end;

{*
  Ajoute un meta
  @param Meta   Meta � ajouter
  @return Index du meta nouvellement ajout�
*}
function TSepiMetaList.AddMeta(Meta : TSepiMeta) : integer;
begin
  Result := AddObject(Meta.Name, Meta);
end;

{*
  Cherche un meta dans la liste
  @param Meta   Meta � chercher
  @return L'index du meta dans la liste, ou nil s'il n'existe pas
*}
function TSepiMetaList.IndexOfMeta(Meta : TSepiMeta) : integer;
begin
  Result := IndexOf(Meta.Name);
end;

{*
  Supprime un meta de la liste
  @param Meta   Meta � supprimer
  @return L'index auquel se trouvait le meta
*}
function TSepiMetaList.Remove(Meta : TSepiMeta) : integer;
begin
  Result := IndexOfMeta(Meta);
  Delete(Result);
end;

{------------------}
{ Classe TSepiMeta }
{------------------}

{*
  Charge un meta depuis un flux
  @param AOwner   Propri�taire du meta
  @param Stream   Flux depuis lequel charger le meta
*}
constructor TSepiMeta.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  Create(AOwner, ReadStrFromStream(Stream));
  Stream.ReadBuffer(FVisibility, 1);
  FState := msLoading;
end;

{*
  Cr�e un nouveau meta
  @param AOwner   Propri�taire du meta
  @param AName    Nom du meta
*}
constructor TSepiMeta.Create(AOwner : TSepiMeta; const AName : string);
begin
  inherited Create;
  FState := msConstructing;
  FOwner := AOwner;
  FName := AName;
  if Assigned(FOwner) then
  begin
    FRoot := FOwner.Root;
    FOwningUnit := FOwner.OwningUnit;
    FOwner.AddChild(Self);
  end else
  begin
    FRoot := nil;
    FOwningUnit := nil;
  end;
  FVisibility := mvPublic;
  FChildren := TSepiMetaList.Create;
end;

{*
  D�truit l'instance
*}
destructor TSepiMeta.Destroy;
var I : integer;
begin
  for I := 0 to FChildren.Count-1 do
    FChildren.Objects[I].Free; // a bit faster than using Metas[I]
  FChildren.Free;
  if Assigned(FOwner) then
    FOwner.RemoveChild(Self);
  inherited Destroy;
end;

{*
  Ajoute un enfant
  AddChild est appel�e dans le constructeur du meta enfant, et ne doit pas �tre
  appel�e ailleurs.
  @param Child   Enfant � ajouter
*}
procedure TSepiMeta.AddChild(Child : TSepiMeta);
begin
  FChildren.AddMeta(Child);
  ChildAdded(Child);
end;

{*
  Supprime un enfant
  RemoveChild est appel�e dans le destructeur du meta enfant, et ne doit pas
  �tre appel�e ailleurs.
  @param Child   Enfant � supprimer
*}
procedure TSepiMeta.RemoveChild(Child : TSepiMeta);
begin
  if State = msDestroying then exit;
  ChildRemoving(Child);
  FChildren.Remove(Child);
end;

{*
  Charge les enfants depuis un flux
  @param Stream   Flux depuis lequel charger les enfants
*}
procedure TSepiMeta.LoadChildren(Stream : TStream);
var Count, I : integer;
begin
  Stream.ReadBuffer(Count, 4);
  for I := 0 to Count-1 do
    SepiFindMetaClass(ReadStrFromStream(Stream)).Load(Self, Stream);
end;

{*
  Appel� lorsqu'un enfant vient d'�tre ajout�
  @param Child   Enfant qui vient d'�tre ajout�
*}
procedure TSepiMeta.ChildAdded(Child : TSepiMeta);
begin
end;

{*
  Appel� lorsqu'un enfant va �tre supprim�
  @param Child   Enfant sur le point d'�tre supprim�
*}
procedure TSepiMeta.ChildRemoving(Child : TSepiMeta);
begin
end;

{*
  Appel� lorsque tous les metas ont �t� charg�s
  Ce n'est qu'� partir de l'appel � Loaded que l'on peut �tre s�r que les
  r�f�rences existent.
*}
procedure TSepiMeta.Loaded;
var I : integer;
begin
  for I := 0 to FChildren.Count do
    FChildren[I].Loaded;
  FState := msNormal;
end;

{*
  Appel� juste avant l'ex�cution du premier destructeur
*}
procedure TSepiMeta.BeforeDestruction;
begin
  inherited;
  FState := msDestroying;
end;

{*
  Nom qualifi� du meta, depuis l'unit� contenante
  @return Nom qualifi� du meta
*}
function TSepiMeta.GetFullName : string;
begin
  if Assigned(FOwner) and (FOwner.Name <> '') then
    Result := FOwner.GetFullName+'.'+Name
  else
    Result := Name;
end;

{*
  Cherche un meta enfant
  @param Name   Nom du meta � trouver
  @return Le meta correspondant, ou nil s'il n'a pas �t� trouv�
*}
function TSepiMeta.GetMeta(const Name : string) : TSepiMeta;
var I : integer;
    MetaName, Field : string;
begin
  I := Pos('.', Name);
  if I > 0 then
  begin
    MetaName := Copy(Name, 1, I-1);
    Field := Copy(Name, I+1, Length(Name));
  end else
  begin
    MetaName := Name;
    Field := '';
  end;

  Result := FChildren.MetaFromName[MetaName];

  if not Assigned(Result) then exit;
  while Result is TSepiTypeAlias do
    Result := TSepiTypeAlias(Result).Dest;
  if Field <> '' then
    Result := Result.GetMeta(Field);
end;

{*
  Cherche un meta enfant
  @param Name   Nom du meta � trouver
  @return Le meta correspondant
  @throws ESepiMetaNotFoundError Le meta n'a pas �t� trouv�
*}
function TSepiMeta.FindMeta(const Name : string) : TSepiMeta;
begin
  Result := GetMeta(Name);
  if Result = nil then
    raise ESepiMetaNotFoundError.CreateFmt(SSepiObjectNotFound, [Name]);
end;

{------------------}
{ Classe TSepiType }
{------------------}

{*
  Recense un type natif
  @param AOwner      Propri�taire du type
  @param ATypeInfo   RTTI du type � recenser
*}
constructor TSepiType.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited Create(AOwner, ATypeInfo.Name);

  FKind := ATypeInfo.Kind;
  FTypeInfoLength := 0;
  FTypeInfo := ATypeInfo;
  FTypeData := GetTypeData(FTypeInfo);
  FSize := 0;
end;

{*
  Clone un type
  @param AOwner   Propri�taire du type
  @param AName    Nom du type
  @param Source   Type � cloner
*}
constructor TSepiType.Clone(AOwner : TSepiMeta; const AName : string;
  Source : TSepiType);
begin
  inherited Create(AOwner, AName);

  FKind := Source.Kind;
  FTypeInfoLength := 0;
  FTypeInfo := nil;
  FTypeData := nil;
  FSize := 0;
end;

{*
  Charge un type depuis un flux
  @param AOwner   Propri�taire du type
  @param Stream   Flux depuis lequel charger le type
*}
constructor TSepiType.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  Stream.ReadBuffer(FKind, sizeof(TTypeKind));
  FTypeInfoLength := 0;
  FTypeInfo := nil;
  FTypeData := nil;
  FSize := 0;
end;

{*
  Cr�e un nouveau type
  @param AOwner   Propri�taire du type
  @param AName    Nom du type
  @param AKind    Type de type
*}
constructor TSepiType.Create(AOwner : TSepiMeta; const AName : string;
  AKind : TTypeKind);
begin
  inherited Create(AOwner, AName);

  FKind := AKind;
  FTypeInfoLength := 0;
  FTypeInfo := nil;
  FTypeData := nil;
  FSize := 0;
end;

{*
  [@inheritDoc]
*}
destructor TSepiType.Destroy;
begin
  if FTypeInfoLength > 0 then
    FreeMem(FTypeInfo, FTypeInfoLength);

  inherited Destroy;
end;

{*
  Alloue une zone m�moire pour les RTTI
  Alloue une zone m�moire adapt�e au nom du type et � la taille des donn�es de
  type, et rempli les champs de TypeInfo (TypeData reste non initialis�).
  La zone m�moire ainsi allou�e sera automatiquement lib�r�e � la destruction du
  type.
  @param TypeDataLength   Taille des donn�es de type
*}
procedure TSepiType.AllocateTypeInfo(TypeDataLength : integer = 0);
var ShortName : ShortString;
    NameLength : integer;
begin
  ShortName := Name;
  NameLength := Length(Name)+1; // 1 byte for string length

  FTypeInfoLength := sizeof(TTypeKind) + NameLength + TypeDataLength;
  GetMem(FTypeInfo, FTypeInfoLength);

  FTypeInfo.Kind := FKind;
  Move(ShortName, FTypeInfo.Name, NameLength);
  FTypeData := GetTypeData(FTypeInfo);
end;

{*
  Extrait les informations les plus importantes depuis les donn�es de type
*}
procedure TSepiType.ExtractTypeData;
begin
end;

{*
  Recense un type natif � partir de ses RTTI
  @param AOwner      Propri�taire du type
  @param ATypeInfo   RTTI du type � recenser
  @return Type nouvellement cr��
*}
class function TSepiType.LoadFromTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo) : TSepiType;
begin
  case ATypeInfo.Kind of
    tkInteger :
      Result := TSepiIntegerType.RegisterTypeInfo(AOwner, ATypeInfo);
{    tkInt64       : Result := TSepiInt64Type    .Load(AOwner, ATypeInfo);
    tkFloat       : Result := TSepiDoubleType   .Load(AOwner, ATypeInfo);
    tkString      : Result := TSepiStringType   .Load(AOwner, ATypeInfo);
    tkEnumeration : Result := TSepiEnumType     .Load(AOwner, ATypeInfo);
    tkSet         : Result := TSepiSetType      .Load(AOwner, ATypeInfo);
    tkRecord      : Result := TSepiRecordType   .Load(AOwner, ATypeInfo);
    tkClass       : Result := TSepiClassType    .Load(AOwner, ATypeInfo);
    tkArray       : Result := TSepiArrayType    .Load(AOwner, ATypeInfo);
    tkDynArray    : Result := TSepiDynArrayType .Load(AOwner, ATypeInfo);
    tkMethod      : Result := TSepiMethodRefType.Load(AOwner, ATypeInfo);}
    else Result := nil;
  end;
end;

{*
  Teste si un type est compatible avec un autre
  Il faut appeler CompatibleWith sur le type de la variable affect�e, et avec en
  param�tre le type de l'expression � droite de l'assignation.
  @param AType   Type avec lequel tester la compatibilit�
  @return True si les types sont compatibles, False sinon
*}
function TSepiType.CompatibleWith(AType : TSepiType) : boolean;
begin
  Result := AType.FKind = FKind;
end;

{----------------------}
{ Classe TSepiMetaRoot }
{----------------------}

constructor TSepiMetaRoot.Create;
begin
  inherited Create(nil, '');
  FRoot := Self;
end;

function TSepiMetaRoot.GetUnitCount : integer;
begin
  Result := FChildren.Count;
end;

function TSepiMetaRoot.GetUnits(Index : integer) : TSepiMetaUnit;
begin
  Result := TSepiMetaUnit(FChildren.Objects[Index]);
end;

procedure TSepiMetaRoot.LoadUnit(UnitName : string);
begin
  { TODO 2 -cMetaunit�s : Charger une unit� par son nom (ce peut �tre une unit�
    "syst�me" ou non) }
end;

{*
  Trouve un type enregistr� � partir de ses informations de type
  @param TypeInfo   Informations de type du type recherch�
  @return Le type correspondant aux informations de type donn�es
  @throw ESepiMetaNotFoundError Aucun type enregistr� correspondant
*}
function TSepiMetaRoot.FindTypeByTypeInfo(TypeInfo : PTypeInfo) : TSepiType;
var AnsiTypeName : string;
    I : integer;
    Meta : TSepiMeta;
begin
  AnsiTypeName := TypeInfo.Name;
  for I := 0 to UnitCount-1 do
  begin
    Meta := Units[I].GetMeta(AnsiTypeName);
    if Assigned(Meta) and (Meta is TSepiType) and
       (TSepiType(Meta).TypeInfo = TypeInfo) then
    begin
      Result := TSepiType(Meta);
      exit;
    end;
  end;

  raise ESepiMetaNotFoundError.CreateFmt(SSepiObjectNotFound, [Name]);
end;

{----------------------}
{ Classe TSepiMetaUnit }
{----------------------}

constructor TSepiMetaUnit.Load(AOwner : TSepiMeta; Stream : TStream);
var Str : string;
begin
  inherited;
  FOwningUnit := Self;
  FCurrentVisibility := mvPublic;
  FLoadingReferences := TStringList.Create;
  FLoadingReferences.Add(''); // 0 is nil
  while True do
  begin
    Str := ReadStrFromStream(Stream);
    if Str = '' then break;
    FLoadingReferences.Add(Str);
  end;
end;

constructor TSepiMetaUnit.Create(AOwner : TSepiMeta; const AName : string);
begin
  inherited Create(AOwner, AName, tkUnknown);
  FOwningUnit := Self;
  FCurrentVisibility := mvPublic;
  FLoadingReferences := nil;
end;

procedure TSepiMetaUnit.SetCurrentVisibility(Value : TSepiMemberVisibility);
begin
  if Value in [mvPublic, mvPublished] then
    FCurrentVisibility := mvPublic
  else
    FCurrentVisibility := mvPrivate;
end;

procedure TSepiMetaUnit.Loaded;
var I : integer;
begin
  for I := 1 to FLoadingReferences.Count-1 do // 0 is nil
    FLoadingReferences.Objects[I] := Root.FindMeta(FLoadingReferences[I]);
  inherited;
  FLoadingReferences.Free;
  FLoadingReferences := nil;
end;

procedure TSepiMetaUnit.LoadRef(var Ref);
begin
  { This method may only be called from the Loaded method of the items
    contained in this unit. }
  TObject(Ref) := FLoadingReferences.Objects[integer(Ref)];
end;

{-----------------------}
{ Classe TSepiTypeAlias }
{-----------------------}

constructor TSepiTypeAlias.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;
  Stream.ReadBuffer(FDest, 4);
end;

constructor TSepiTypeAlias.Create(AOwner : TSepiMeta; const AName : string;
  ADest : TSepiType);
begin
  inherited Create(AOwner, AName);
  FDest := ADest;
end;

procedure TSepiTypeAlias.Loaded;
begin
  inherited;
  OwningUnit.LoadRef(FDest);
end;

{----------------------}
{ Classe TSepiConstant }
{----------------------}

constructor TSepiConstant.Load(AOwner : TSepiMeta; Stream : TStream);
var ValueLength : integer;
begin
  inherited;
  Stream.ReadBuffer(FType, 4);
  FValue := TMemoryStream.Create;

  Stream.ReadBuffer(ValueLength, 4);
  if ValueLength > 0 then // to prevent a CopyFrom(0) *
    FValue.CopyFrom(Stream, ValueLength);

  { * I reckon a null ValueLength shouldn't happen. But as a newly created
    TSepiConstant has got a null Value, it is more logical and safer to allow
    and check for a null ValueLength. }
end;

constructor TSepiConstant.Create(AOwner : TSepiMeta; const AName : string;
  AType : TSepiType);
begin
  inherited Create(AOwner, AName);
  FType := AType;
  FValue := TMemoryStream.Create;
end;

procedure TSepiConstant.Loaded;
begin
  inherited;
  OwningUnit.LoadRef(FType);
end;

{--------------------------}
{ Classe TSepiMetaVariable }
{--------------------------}

constructor TSepiMetaVariable.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;
  Stream.ReadBuffer(FType, 4);
end;

constructor TSepiMetaVariable.Create(AOwner : TSepiMeta; const AName : string;
  AType : TSepiType);
begin
  inherited Create(AOwner, AName);
  FType := AType;
end;

procedure TSepiMetaVariable.Loaded;
begin
  OwningUnit.LoadRef(FType);
end;

{-----------------------}
{ Classe TSepiMetaParam }
{-----------------------}

constructor TSepiMetaParam.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;
  Stream.ReadBuffer(FParamKind, 1);
end;

constructor TSepiMetaParam.Create(AOwner : TSepiMeta; const AName : string;
  AType : TSepiType; AParamKind : TParamFlags = []);
begin
  inherited Create(AOwner, AName, AType);
  FParamKind := AParamKind;
end;

function TSepiMetaParam.CompatibleWith(AVariable : TSepiMetaVariable) : boolean;
begin
  if (AVariable is TSepiMetaParam) and
     (TSepiMetaParam(AVariable).FParamKind <> FParamKind) then
    Result := False
  else if FParamKind - [pfConst] = [] then
    Result := FType.CompatibleWith(AVariable.FType)
  else
    Result := FType = AVariable.FType;
end;

{-----------------------------}
{ Classe TSepiMethodSignature }
{-----------------------------}

constructor TSepiMethodSignature.Create(AOwner : TSepiMeta);
begin
  inherited Create;
  FOwner := AOwner;
  FParams := TSepiMetaList.Create;
  FReturnType := nil;
end;

destructor TSepiMethodSignature.Destroy;
begin
  FParams.Free;
  inherited Destroy;
end;

procedure TSepiMethodSignature.Load(Stream : TStream);
var ParamCount : integer;
begin
  Stream.ReadBuffer(ParamCount, 4);
  while ParamCount > 0 do
  begin
    FParams.AddMeta(TSepiMetaParam.Load(FOwner, Stream));
    dec(ParamCount);
  end;
  Stream.ReadBuffer(FReturnType, 4);
end;

procedure TSepiMethodSignature.Loaded;
begin
  inherited;
  FOwner.OwningUnit.LoadRef(FReturnType);
end;

function TSepiMethodSignature.GetParamCount : integer;
begin
  Result := FParams.Count;
end;

function TSepiMethodSignature.GetParams(Index : integer) : TSepiMetaParam;
begin
  Result := TSepiMetaParam(FParams.Objects[Index]);
end;

function TSepiMethodSignature.CompatibleWith(
  ASignature : TSepiMethodSignature) : boolean;
var I : integer;
begin
  Result := False;

  if FParams.Count <> ASignature.FParams.Count then exit;
  for I := 0 to FParams.Count-1 do
    if not Params[I].CompatibleWith(ASignature.Params[I]) then exit;

  if FReturnType <> ASignature.FReturnType then exit;

  Result := True;
end;

{------------------------}
{ Classe TSepiMetaMethod }
{------------------------}

constructor TSepiMetaMethod.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;
  FSignature := TSepiMethodSignature.Create(Self);
  FSignature.Load(Stream);
  Stream.ReadBuffer(FKind, 1);
  Stream.ReadBuffer(FOverrideState, 1);
  Stream.ReadBuffer(FAbstract, 1);
  FInherited := nil;
end;

constructor TSepiMetaMethod.Create(AOwner : TSepiMeta; const AName : string;
  AKind : TMethodKind = mkProcedure;
  AOverrideState : TSepiMethodOverrideState = osNone;
  AAbstract : boolean = False);
begin
  inherited Create(AOwner, AName);
  FSignature := TSepiMethodSignature.Create(Self);
  FKind := AKind;
  FOverrideState := AOverrideState;
  FAbstract := AAbstract and (FOverrideState in [osVirtual, osDynamic]);
  FindInherited;
end;

destructor TSepiMetaMethod.Destroy;
begin
  FSignature.Free;
  inherited Destroy;
end;

procedure TSepiMetaMethod.FindInherited;
var Overloaded : boolean;
    LookFor : string;
begin
  LookFor := FName;

  Overloaded := Copy(FName, 1, 3) = 'OL$';
  if Overloaded then
  begin
    Delete(LookFor, 1, 3);
    Delete(LookFor, Pos('$', LookFor), Length(LookFor));
  end;

  FInherited := nil;
  { TODO 3 -cMetaunit�s : Trouver la m�thode h�rit�e }
end;

procedure TSepiMetaMethod.Loaded;
begin
  inherited;
  FSignature.Loaded;
  FindInherited;
end;

{----------------------------}
{ Classe TSepiMetaSepiMethod }
{----------------------------}

constructor TSepiMetaSepiMethod.Load(AOwner : TSepiMeta; Stream : TStream);
var Count : integer;
begin
  inherited;
  FVariables := TSepiMetaList.Create;
  FCode := TMemoryStream.Create;

  Stream.ReadBuffer(Count, 4);
  while Count > 0 do
  begin
    FVariables.AddMeta(TSepiMetaVariable.Load(Self, Stream));
    dec(Count);
  end;

  Stream.ReadBuffer(Count, 4);
  if Count > 0 then // To prevent a CopyFrom(0)
    FCode.CopyFrom(Stream, Count);
end;

constructor TSepiMetaSepiMethod.Create(AOwner : TSepiMeta; const AName : string;
  AKind : TMethodKind = mkProcedure;
  AOverrideState : TSepiMethodOverrideState = osNone;
  AAbstract : boolean = False);
begin
  inherited Create(AOwner, AName, AKind, AOverrideState, AAbstract);
  FCode := TMemoryStream.Create;
end;

destructor TSepiMetaSepiMethod.Destroy;
begin
  FCode.Free;
  inherited Destroy;
end;

function TSepiMetaSepiMethod.GetVariableCount : integer;
begin
  Result := FVariables.Count;
end;

function TSepiMetaSepiMethod.GetVariables(Index : integer) : TSepiMetaVariable;
begin
  Result := TSepiMetaVariable(FVariables.Objects[Index]);
end;

{------------------------------}
{ Classe TSepiMetaDelphiMethod }
{------------------------------}

constructor TSepiMetaDelphiMethod.Create(AOwner : TSepiMeta;
  const AName : string; ACode : Pointer; AKind : TMethodKind = mkProcedure;
  AOverrideState : TSepiMethodOverrideState = osNone;
  AAbstract : boolean = False;
  ACallConvention : TSepiCallConvention = ccRegister);
begin
  inherited Create(AOwner, AName, AKind, AOverrideState, AAbstract);
  FCallConvention := ACallConvention;
  FCode := ACode;
end;

{----------------------------------}
{ Classe TSepiMetaOverloadedMethod }
{----------------------------------}

constructor TSepiMetaOverloadedMethod.Load(AOwner : TSepiMeta;
  Stream : TStream);
begin
  inherited;
  Stream.ReadBuffer(FMethodCount, 4);
end;

constructor TSepiMetaOverloadedMethod.Create(AOwner : TSepiMeta;
  const AName : string);
begin
  inherited Create(AOwner, AName);
  FMethodCount := 0;
end;

function TSepiMetaOverloadedMethod.NextID : integer;
begin
  Result := FMethodCount;
  inc(FMethodCount);
end;

function TSepiMetaOverloadedMethod.FindMethod(
  Signature : TSepiMethodSignature) : TSepiMetaMethod;
var I : integer;
begin
  for I := 0 to FMethodCount-1 do
  begin
    Result := TSepiMetaMethod(FOwner.FindMeta(Format('OL$%s$%d', [FName, I])));
    if Result.FSignature.CompatibleWith(Signature) then exit;
  end;
  Result := nil;
end;

{--------------------------}
{ Classe TSepiMetaProperty }
{--------------------------}

constructor TSepiMetaProperty.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;
  FSignature := TSepiMethodSignature.Create(Self);
  FSignature.Load(Stream);

  Stream.ReadBuffer(FReadAccess, 4);
  FReadAccessKind := pakNone;
  FReadVariableAccess := nil;
  FReadMethodAccess := nil;

  Stream.ReadBuffer(FWriteAccess, 4);
  FWriteAccessKind := pakNone;
  FWriteVariableAccess := nil;
  FWriteMethodAccess := nil;
end;

constructor TSepiMetaProperty.Create(AOwner : TSepiMeta; const AName : string;
  AReadAccess : TSepiMeta; AWriteAccess : TSepiMeta);
begin
  inherited Create(AOwner, AName);
  FSignature := TSepiMethodSignature.Create(Self);

  FReadAccess := AReadAccess;
  FReadAccessKind := pakNone;
  FReadVariableAccess := nil;
  FReadMethodAccess := nil;

  FWriteAccess := AWriteAccess;
  FWriteAccessKind := pakNone;
  FWriteVariableAccess := nil;
  FWriteMethodAccess := nil;

  DevelopAccess;
end;

destructor TSepiMetaProperty.Destroy;
begin
  FSignature.Free;
  inherited;
end;

procedure TSepiMetaProperty.DevelopAccess;
begin
  if Assigned(FReadAccess) then
  begin
    if FReadAccess is TSepiMetaVariable then
    begin
      FReadAccessKind := pakVariable;
      FReadVariableAccess := TSepiMetaVariable(FReadAccess);
    end else
    if FReadAccess is TSepiMetaMethod then
    begin
      FReadAccessKind := pakMethod;
      FReadMethodAccess := TSepiMetaMethod(FReadAccess);
    end else
    FReadAccess := nil;
  end;

  if Assigned(FWriteAccess) then
  begin
    if FWriteAccess is TSepiMetaVariable then
    begin
      FWriteAccessKind := pakVariable;
      FWriteVariableAccess := TSepiMetaVariable(FWriteAccess);
    end else
    if FWriteAccess is TSepiMetaMethod then
    begin
      FWriteAccessKind := pakMethod;
      FReadMethodAccess := TSepiMetaMethod(FWriteAccess);
    end else
    FWriteAccess := nil;
  end;
end;

procedure TSepiMetaProperty.Loaded;
begin
  inherited;
  OwningUnit.LoadRef(FReadAccess);
  OwningUnit.LoadRef(FWriteAccess);
  DevelopAccess;
end;

initialization
  SepiRegisterMetaClasses([
    TSepiMetaUnit, TSepiTypeAlias, TSepiConstant, TSepiMetaVariable,
    TSepiMetaParam, TSepiMetaSepiMethod, TSepiMetaDelphiMethod,
    TSepiMetaOverloadedMethod, TSepiMetaProperty
  ]);
finalization
  SepiMetaClasses.Free;
  SepiImportedUnits.Free;
end.

