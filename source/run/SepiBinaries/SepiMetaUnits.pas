{*
  D�finit les classes de gestion des meta-unit�s
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit SepiMetaUnits;

interface

uses
  SysUtils, Classes, Contnrs, RTLConsts, SepiCore, ScUtils, IniFiles, TypInfo,
  ScLists, ScStrUtils, SepiBinariesConsts;

type
  {*
    �tat d'un meta
  *}
  TSepiMetaState = (msNormal, msConstructing, msLoading, msDestroying);

  {*
    Visibilit� d'un membre d'une classe, d'un objet, ou d'une unit�
  *}
  TMemberVisibility = (mvPrivate, mvInternal, mvProtected,
    mvInternalProtected, mvPublic, mvPublished);

  {*
    Type de l'�v�nement OnGetMethodCode de TSepiMetaRoot
    @param Sender   M�thode d�clenchant l'�v�nement (toujours TSepiMetaMethod)
    @param Code     Adresse de code de la m�thode
  *}
  TGetMethodCodeEvent = procedure(Sender : TObject;
    var Code : Pointer) of object;

  {*
    D�clench�e si l'on tente de recr�er un meta (second appel au constructeur)
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  ESepiMetaAlreadyCreated = class(ESepiError);

  {*
    D�clench�e lorsque la recherche d'un meta s'est sold�e par un �chec
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  ESepiMetaNotFoundError = class(ESepiError);

  TSepiMeta = class;
  TSepiMetaRoot = class;
  TSepiMetaUnit = class;
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
  protected
    procedure InsertItem(Index : Integer; const S : string;
      AObject : TObject); override;
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
    FIsForward : boolean;        /// True tant que le meta n'a pas �t� construit
    FState : TSepiMetaState;     /// �tat
    FOwner : TSepiMeta;          /// Propri�taire
    FRoot : TSepiMetaRoot;       /// Racine
    FOwningUnit : TSepiMetaUnit; /// Unit� contenante
    FName : string;              /// Nom
    FForwards : TStrings;        /// Liste des enfants forwards
    FChildren : TSepiMetaList;   /// Liste des enfants

    procedure AddChild(Child : TSepiMeta);
    procedure RemoveChild(Child : TSepiMeta);

    function GetChildCount : integer;
    function GetChildren(Index : integer) : TSepiMeta;
  protected
    FVisibility : TMemberVisibility; /// Visibilit�

    procedure LoadChildren(Stream : TStream);
    procedure SaveChildren(Stream : TStream);

    procedure AddForward(const ChildName : string; Child : TObject);
    procedure ChildAdded(Child : TSepiMeta); virtual;
    procedure ChildRemoving(Child : TSepiMeta); virtual;

    procedure Loaded; virtual;

    procedure ListReferences; virtual;
    procedure Save(Stream : TStream); virtual;

    property State : TSepiMetaState read FState;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); virtual;
    constructor Create(AOwner : TSepiMeta; const AName : string);
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    class function NewInstance : TObject; override;

    function GetFullName : string;
    function GetMeta(const Name : string) : TSepiMeta;
    function FindMeta(const Name : string) : TSepiMeta;

    property IsForward : boolean read FIsForward;
    property Owner : TSepiMeta read FOwner;
    property Root : TSepiMetaRoot read FRoot;
    property OwningUnit : TSepiMetaUnit read FOwningUnit;
    property Name : string read FName;
    property Visibility : TMemberVisibility read FVisibility write FVisibility;

    property ChildCount : integer read GetChildCount;
    property Children[index : integer] : TSepiMeta read GetChildren;
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
    FNative : boolean;         /// Indique si le type est un type natif Delphi
    FTypeInfoLength : integer; /// Taille des RTTI cr��es (ou 0 si non cr��es)
    FTypeInfo : PTypeInfo;     /// RTTI (Runtime Type Information)
    FTypeData : PTypeData;     /// RTTD (Runtime Type Data)
    FTypeInfoRef : PPTypeInfo; /// R�f�rence aux RTTI
  protected
    FSize : integer;     /// Taille d'une variable de ce type
    FNeedInit : boolean; /// Indique si ce type requiert une initialisation

    procedure Save(Stream : TStream); override;

    procedure ForceNative(ATypeInfo : PTypeInfo = nil);
    procedure AllocateTypeInfo(TypeDataLength : integer = 0);
    procedure ExtractTypeData; virtual;

    property TypeInfoRef : PPTypeInfo read FTypeInfoRef;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); virtual;
    constructor Clone(AOwner : TSepiMeta; const AName : string;
      Source : TSepiType); virtual;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AKind : TTypeKind);
    destructor Destroy; override;

    class function NewInstance : TObject; override;

    class function LoadFromTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo) : TSepiType;

    function CompatibleWith(AType : TSepiType) : boolean; virtual;

    property Kind : TTypeKind read FKind;
    property Native : boolean read FNative;
    property TypeInfo : PTypeInfo read FTypeInfo;
    property TypeData : PTypeData read FTypeData;
    property Size : integer read FSize;
    property NeedInit : boolean read FNeedInit;
  end;

  {*
    Classe de TSepiType
  *}
  TSepiTypeClass = class of TSepiType;

  {*
    Meta-racine
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaRoot = class(TSepiMeta)
  private
    /// D�clench� pour chaque m�thode au chargement, pour obtenir son code
    FOnGetMethodCode : TGetMethodCodeEvent;

    function GetUnitCount : integer;
    function GetUnits(Index : integer) : TSepiMetaUnit;
  public
    constructor Create;

    function LoadUnit(const UnitName : string) : TSepiMetaUnit;

    function FindType(TypeInfo : PTypeInfo) : TSepiType; overload;
    function FindType(const TypeName : string) : TSepiType; overload;

    property UnitCount : integer read GetUnitCount;
    property Units[index : integer] : TSepiMetaUnit read GetUnits;

    property OnGetMethodCode : TGetMethodCodeEvent
      read FOnGetMethodCode write FOnGetMethodCode;
  end;

  {*
    Meta-unit�
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaUnit = class(TSepiType)
  private
    { TODO 2 -cMetaunit�s : Ajouter des champs concernant les en-t�te d'unit� }
    FUsesList : TStrings;                   /// Liste des uses
    FCurrentVisibility : TMemberVisibility; /// Visibilit� courante

    FReferences : array of TStrings; /// R�f�rences en chargement/sauvegarde

    function AddUses(AUnit : TSepiMetaUnit) : integer; overload;

    procedure SetCurrentVisibility(Value : TMemberVisibility);
  protected
    procedure Save(Stream : TStream); override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string);
    destructor Destroy; override;

    function AddUses(const UnitName : string) : TSepiMetaUnit; overload;

    procedure SaveToStream(Stream : TStream);

    procedure ReadRef(Stream : TStream; out Ref);
    procedure AddRef(Ref : TSepiMeta);
    procedure WriteRef(Stream : TStream; Ref : TSepiMeta);

    property CurrentVisibility : TMemberVisibility
      read FCurrentVisibility write SetCurrentVisibility;
  end;

  {*
    Alias de type
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiTypeAlias = class(TSepiMeta)
  private
    FDest : TSepiType; /// Type destination
  protected
    procedure ListReferences; override;
    procedure Save(Stream : TStream); override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      ADest : TSepiType); overload;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      ADest : PTypeInfo); overload;

    property Dest : TSepiType read FDest;
  end;

  {*
    Constante
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiConstant = class(TSepiMeta)
  private
    FType : TSepiType;      /// Type de la constante
    FValue : TMemoryStream; /// Valeur
  protected
    procedure ListReferences; override;
    procedure Save(Stream : TStream); override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AType : TSepiType);

    property ConstType : TSepiType read FType;
    property Value : TMemoryStream read FValue;
  end;

  {*
    Type de routine call-back pour l'import d'une unit� sous Sepi
  *}
  TSepiImportUnitFunc = function(Root : TSepiMetaRoot) : TSepiMetaUnit;

procedure SepiRegisterMetaClasses(const MetaClasses : array of TSepiMetaClass);

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
procedure SepiRegisterMetaClasses(const MetaClasses : array of TSepiMetaClass);
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
  Ajoute un �l�ment dans la liste de metas
  @param Index     Index o� ajouter l'�l�ment
  @param S         Cha�ne � ajouter
  @param AObject   Objet � ajouter
*}
procedure TSepiMetaList.InsertItem(Index : Integer; const S : string;
  AObject : TObject);
begin
  if IndexOf(S) >= 0 then
    raise EListError.CreateFmt(SSepiMetaAlreadyExists, [S]);
  inherited;
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
  if not IsForward then
    raise ESepiMetaAlreadyCreated.CreateFmt(SSepiMetaAlreadyCreated, [Name]);

  inherited Create;
  FIsForward := False;
  FState := msConstructing;
  FOwner := AOwner;
  FName := AName;
  FVisibility := mvPublic;
  FForwards := THashedStringList.Create;
  FChildren := TSepiMetaList.Create;

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
end;

{*
  D�truit l'instance
*}
destructor TSepiMeta.Destroy;
var I : integer;
begin
  if Assigned(FChildren) then
  begin
    for I := 0 to FChildren.Count-1 do
      FChildren.Objects[I].Free;
    FChildren.Free;
  end;
  FForwards.Free;

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
end;

{*
  Supprime un enfant
  RemoveChild est appel�e dans le destructeur du meta enfant, et ne doit pas
  �tre appel�e ailleurs.
  @param Child   Enfant � supprimer
*}
procedure TSepiMeta.RemoveChild(Child : TSepiMeta);
var Index : integer;
begin
  if State <> msDestroying then
  begin
    FChildren.Remove(Child);

    Index := FForwards.IndexOfObject(Child);
    if Index >= 0 then FForwards.Delete(Index);
  end;
end;

{*
  Nombre d'enfants
  @return Nombre d'enfants
*}
function TSepiMeta.GetChildCount : integer;
begin
  Result := FChildren.Count;
end;

{*
  Tableau zero-based des enfants
  @param Index   Index de l'enfant � r�cup�rer
  @return Enfant � l'index sp�cifi�
*}
function TSepiMeta.GetChildren(Index : integer) : TSepiMeta;
begin
  Result := TSepiMeta(FChildren[Index]);
end;

{*
  Charge les enfants depuis un flux
  @param Stream   Flux depuis lequel charger les enfants
*}
procedure TSepiMeta.LoadChildren(Stream : TStream);
var Count, I : integer;
    ForwardChild : TObject;
    IsForward : boolean;
begin
  // Forwards
  Stream.ReadBuffer(Count, 4);
  for I := 0 to Count-1 do
  begin
    ForwardChild := SepiFindMetaClass(ReadStrFromStream(Stream)).NewInstance;
    AddForward(ReadStrFromStream(Stream), ForwardChild);
  end;

  // Actual loading
  Stream.ReadBuffer(Count, 4);
  for I := 0 to Count-1 do
  begin
    Stream.ReadBuffer(IsForward, 1);
    if IsForward then
      FindMeta(ReadStrFromStream(Stream)).Load(Self, Stream)
    else
      SepiFindMetaClass(ReadStrFromStream(Stream)).Load(Self, Stream);
  end;
end;

{*
  Enregistre les enfants dans un flux
  @param Stream   Flux dans lequel enregistrer les enfants
*}
procedure TSepiMeta.SaveChildren(Stream : TStream);
var Count, I : integer;
    Child : TSepiMeta;
    IsForward : boolean;
begin
  // Forwards
  Count := FForwards.Count;
  Stream.WriteBuffer(Count, 4);
  for I := 0 to Count-1 do
  begin
    WriteStrToStream(Stream, FForwards.Objects[I].ClassName);
    WriteStrToStream(Stream, FForwards[I]);
  end;

  // Actual saving
  Count := FChildren.Count;
  Stream.WriteBuffer(Count, 4);
  for I := 0 to Count-1 do
  begin
    Child := FChildren[I];

    IsForward := FForwards.IndexOfObject(Child) >= 0;
    Stream.WriteBuffer(IsForward, 1);

    if IsForward then
      WriteStrToStream(Stream, Child.Name)
    else
      WriteStrToStream(Stream, Child.ClassName);

    Child.Save(Stream);
  end;
end;

{*
  Ajoute un enfant forward
  @param ChildName   Nom de l'enfant
  @param Child       Enfant � ajouter
*}
procedure TSepiMeta.AddForward(const ChildName : string; Child : TObject);
begin
  FForwards.AddObject(ChildName, Child);
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
  Liste les r�f�rences aupr�s de l'unit� contenante, pour pr�parer la sauvegarde
*}
procedure TSepiMeta.ListReferences;
var I : integer;
begin
  for I := 0 to FChildren.Count-1 do
    FChildren[I].ListReferences;
end;

{*
  Enregistre le meta dans un flux
  @param Stream   Flux dans lequel enregistrer le meta
*}
procedure TSepiMeta.Save(Stream : TStream);
begin
  WriteStrToStream(Stream, Name);
  Stream.WriteBuffer(FVisibility, 1);
end;

{*
  Appel� juste apr�s l'ex�cution du dernier constructeur
*}
procedure TSepiMeta.AfterConstruction;
begin
  inherited;
  if Assigned(Owner) then
    Owner.ChildAdded(Self);
end;

{*
  Appel� juste avant l'ex�cution du premier destructeur
*}
procedure TSepiMeta.BeforeDestruction;
begin
  inherited;
  FState := msDestroying;
  if Assigned(Owner) then
    Owner.ChildRemoving(Self);
end;

{*
  Cr�e une nouvelle instance de TSepiMeta
  @return Instance cr��e
*}
class function TSepiMeta.NewInstance : TObject;
begin
  Result := inherited NewInstance;
  TSepiMeta(Result).FIsForward := True;
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
  if not SplitToken(Name, '.', MetaName, Field) then
    Field := '';
  Result := FChildren.MetaFromName[MetaName];

  if (Result = nil) and (Field = '') then
  begin
    I := FForwards.IndexOf(MetaName);
    if I >= 0 then
      Result := TSepiMeta(FForwards.Objects[I]);
  end;

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
  FNative := True;
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
  FNative := False;
  FTypeInfoLength := 0;
  FTypeInfo := nil;
  FTypeData := nil;
  FSize := 0;
  FNeedInit := False;
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
  FNative := False;
  FTypeInfoLength := 0;
  FTypeInfo := nil;
  FTypeData := nil;
  FSize := 0;
  FNeedInit := False;
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
  FNative := False;
  FTypeInfoLength := 0;
  FTypeInfo := nil;
  FTypeData := nil;
  FSize := 0;
  FNeedInit := False;
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

procedure TSepiType.Save(Stream : TStream);
begin
  inherited;
  Stream.WriteBuffer(FKind, 1);
end;

{*
  Cr�e une nouvelle instance de TSepiType
  @return Instance cr��e
*}
class function TSepiType.NewInstance : TObject;
begin
  Result := inherited NewInstance;
  TSepiType(Result).FTypeInfoRef := @TSepiType(Result).FTypeInfo;
end;

{*
  Force le type comme �tant natif, en modifiant �galement les RTTI
  Cette m�thode est utilis�e par les types record et tableau statique, qui n'ont
  pas toujours, m�me natifs, de RTTI.
  @param ATypeInfo   RTTI � fixer (peut �tre nil)
*}
procedure TSepiType.ForceNative(ATypeInfo : PTypeInfo = nil);
begin
  FNative := True;
  FTypeInfo := ATypeInfo;
  if FTypeInfo = nil then
    FTypeData := nil
  else
    FTypeData := GetTypeData(FTypeInfo);
end;

{*
  Alloue une zone m�moire pour les RTTI
  Alloue une zone m�moire adapt�e au nom du type et � la taille des donn�es de
  type, et remplit les champs de TypeInfo (TypeData reste non initialis�).
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
const
  TypeClasses : array[TTypeKind] of TSepiTypeClass = (
    nil, TSepiIntegerType, TSepiCharType, TSepiEnumType, TSepiFloatType,
    TSepiShortStringType, TSepiSetType, TSepiClass, TSepiMethodRefType,
    TSepiCharType, TSepiStringType, TSepiStringType, nil, nil, nil,
    TSepiInterface, TSepiInt64Type, TSepiDynArrayType
  );
var TypeClass : TSepiTypeClass;
begin
  TypeClass := TypeClasses[ATypeInfo.Kind];
  if Assigned(TypeClass) then
  begin
    if TypeClass = TSepiEnumType then
    begin
      with GetTypeData(ATypeInfo)^ do
        if (BaseType^ = System.TypeInfo(Boolean)) or
           (GetTypeData(BaseType^).MinValue < 0) then
          TypeClass := TSepiBooleanType;
    end;

    Result := TypeClass.RegisterTypeInfo(AOwner, ATypeInfo)
  end else raise EAbstractError.Create(SSepiNoRegisterTypeInfo);
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

{*
  Cr�e une instance de TSepiMetaRoot
*}
constructor TSepiMetaRoot.Create;
begin
  inherited Create(nil, '');
  FRoot := Self;
  FOnGetMethodCode := nil;
end;

{*
  Nombre d'unit�s
  @return Nombre d'unit�s
*}
function TSepiMetaRoot.GetUnitCount : integer;
begin
  Result := FChildren.Count;
end;

{*
  Tableau zero-based des unit�s
  @param Index   Index de l'unit� � r�cup�rer
  @return Unit� � l'index sp�cifi�
*}
function TSepiMetaRoot.GetUnits(Index : integer) : TSepiMetaUnit;
begin
  Result := TSepiMetaUnit(FChildren.Objects[Index]);
end;

{*
  Charge une unit�
  @param UnitName   Nom de l'unit� � charger
  @return Unit� charg�e
*}
function TSepiMetaRoot.LoadUnit(const UnitName : string) : TSepiMetaUnit;
var ImportFunc : TSepiImportUnitFunc;
begin
  Result := TSepiMetaUnit(GetMeta(UnitName));
  if Result <> nil then exit;

  ImportFunc := SepiImportedUnit(UnitName);
  if Assigned(ImportFunc) then
    Result := ImportFunc(Self);

  { TODO 2 -cMetaunit�s : Charger une unit� non syst�me par son nom }
end;

{*
  Trouve un type enregistr� � partir de ses informations de type
  @param TypeInfo   Informations de type du type recherch�
  @return Le type correspondant aux informations de type donn�es
  @throw ESepiMetaNotFoundError Aucun type enregistr� correspondant
*}
function TSepiMetaRoot.FindType(TypeInfo : PTypeInfo) : TSepiType;
var TypeName : string;
    I : integer;
    Meta : TSepiMeta;
begin
  if TypeInfo = nil then
  begin
    Result := nil;
    exit;
  end;

  TypeName := TypeInfo.Name;
  for I := 0 to UnitCount-1 do
  begin
    Meta := Units[I].GetMeta(TypeName);
    if (Meta is TSepiType) and (TSepiType(Meta).TypeInfo = TypeInfo) then
    begin
      Result := TSepiType(Meta);
      exit;
    end;
  end;

  raise ESepiMetaNotFoundError.CreateFmt(SSepiObjectNotFound, [TypeName]);
end;

{*
  Trouve un type enregistr� � partir de son nom
  @param TypeName   Nom du type recherch�
  @return Le type correspondant au nom donn�
  @throw ESepiMetaNotFoundError Aucun type enregistr� correspondant
*}
function TSepiMetaRoot.FindType(const TypeName : string) : TSepiType;
var I : integer;
    Meta : TSepiMeta;
begin
  if TypeName = '' then
  begin
    Result := nil;
    exit;
  end;

  Meta := GetMeta(TypeName);
  if Meta is TSepiType then
  begin
    Result := TSepiType(Meta);
    exit;
  end;

  for I := 0 to UnitCount-1 do
  begin
    Meta := Units[I].GetMeta(TypeName);
    if Meta is TSepiType then
    begin
      Result := TSepiType(Meta);
      exit;
    end;
  end;

  raise ESepiMetaNotFoundError.CreateFmt(SSepiObjectNotFound, [TypeName]);
end;

{----------------------}
{ Classe TSepiMetaUnit }
{----------------------}

{*
  Charge une unit� depuis un flux
*}
constructor TSepiMetaUnit.Load(AOwner : TSepiMeta; Stream : TStream);
var UsesCount, RefCount, I, J : integer;
    Str : string;
begin
  Stream.ReadBuffer(UsesCount, 4);
  SetLength(FReferences, UsesCount+1);
  FillChar(FReferences[0], 4*(UsesCount+1), 0);

  try
    // Loading uses and setting up the references lists
    FUsesList := TStringList.Create;
    for I := 0 to UsesCount do
    begin
      if I > 0 then
      begin
        Str := ReadStrFromStream(Stream);
        FUsesList.AddObject(Str, TSepiMetaRoot(AOwner).LoadUnit(Str));
      end;

      FReferences[I] := TStringList.Create;
      Stream.ReadBuffer(RefCount, 4);
      for J := 0 to RefCount-1 do
        FReferences[I].Add(ReadStrFromStream(Stream));
    end;

    // Now, you can add yourself to the root children
    inherited;

    FOwningUnit := Self;
    FCurrentVisibility := mvPublic;

    LoadChildren(Stream);
  finally
    for I := 0 to UsesCount do
      if Assigned(FReferences[I]) then
        FReferences[I].Free;
    SetLength(FReferences, 0);
  end;
end;

{*
  Cr�e une nouvelle unit�
  @param AOwner   Propri�taire de l'unit� (la racine)
  @param AName    Nom de l'unit�
*}
constructor TSepiMetaUnit.Create(AOwner : TSepiMeta; const AName : string);
begin
  inherited Create(AOwner, AName, tkUnknown);

  FOwningUnit := Self;
  FUsesList := TStringList.Create;
  FCurrentVisibility := mvPublic;
end;

{*
  [@inheritDoc]
*}
destructor TSepiMetaUnit.Destroy;
begin
  FUsesList.Free;
  inherited;
end;

{*
  Ajoute une unit� aux uses de cette unit�
  @param AUnit   Unit� � ajouter aux uses
  @return Index de la nouvelle unit� dans les uses
*}
function TSepiMetaUnit.AddUses(AUnit : TSepiMetaUnit) : integer;
begin
  if AUnit = Self then Result := -1 else
  begin
    Result := FUsesList.IndexOfObject(AUnit);
    if Result < 0 then
    begin
      Result := FUsesList.AddObject(AUnit.Name, AUnit);

      if Length(FReferences) > 0 then // saving
      begin
        // Yes, this is ugly programming, sorry :-(
        SetLength(FReferences, Result+2);
        FReferences[Result+1] := TStringList.Create;
      end;
    end;
  end;
end;

{*
  Change la visibilit� courante
  @param Value   Nouvelle visibilit�
*}
procedure TSepiMetaUnit.SetCurrentVisibility(Value : TMemberVisibility);
begin
  if Value in [mvPublic, mvPublished] then
    FCurrentVisibility := mvPublic
  else
    FCurrentVisibility := mvPrivate;
end;

{*
  [@inheritDoc]
*}
procedure TSepiMetaUnit.Save(Stream : TStream);
begin
  inherited;
  SaveChildren(Stream);
end;

{*
  Ajoute une unit� aux uses de cette unit�
  @param UnitName   Nom de l'unit� � ajouter aux uses
  @return Nouvelle unit� dans les uses
*}
function TSepiMetaUnit.AddUses(const UnitName : string) : TSepiMetaUnit;
begin
  Result := Root.LoadUnit(UnitName);
  AddUses(Result);
end;

{*
  Enregistre l'unit� dans un flux
*}
procedure TSepiMetaUnit.SaveToStream(Stream : TStream);
var UsesCount, RefCount, I, J : integer;
    RefList : TStrings;
begin
  UsesCount := FUsesList.Count;
  SetLength(FReferences, UsesCount+1);
  FillChar(FReferences[0], 4*(UsesCount+1), 0);
  try
    // Listing the references
    for I := 0 to UsesCount do
      FReferences[I] := TStringList.Create;
    ListReferences;

    // Writing the references lists to stream
    UsesCount := FUsesList.Count; // this could have changed meanwhile
    Stream.WriteBuffer(UsesCount, 4);
    for I := 0 to UsesCount do
    begin
      if I > 0 then
        WriteStrToStream(Stream, FUsesList[I-1]);

      RefList := FReferences[I];
      RefCount := RefList.Count;
      Stream.WriteBuffer(RefCount, 4);

      for J := 0 to RefCount-1 do
        WriteStrToStream(Stream, RefList[J]);
    end;

    // Actually saving the unit
    Save(Stream);
  finally
    for I := 0 to UsesCount do
      if Assigned(FReferences[I]) then
        FReferences[I].Free;
    SetLength(FReferences, 0);
  end;
end;

{*
  Lit une r�f�rence depuis un flux
  Cette m�thode ne peut �tre appel�e que depuis le constructeur Load des metas
  contenus dans cette unit�. � tout autre moment, c'est la violation d'acc�s
  assur�e.
  @param Stream   Flux dans lequel �crire la r�f�rence
  @param Ref      Variable de type TSepiMeta o� stocker la r�f�rence lue
*}
procedure TSepiMetaUnit.ReadRef(Stream : TStream; out Ref);
var UnitIndex, RefIndex : integer;
    RefList : TStrings;
begin
  // Reading unit index and checking for nil reference
  UnitIndex := 0;
  Stream.ReadBuffer(UnitIndex, 2);
  if UnitIndex = $FFFF then
  begin
    TObject(Ref) := nil;
    exit;
  end;

  // Reading reference index
  Stream.ReadBuffer(RefIndex, 4);
  RefList := FReferences[UnitIndex];

  TObject(Ref) := RefList.Objects[RefIndex];

  if TObject(Ref) = nil then
  begin
    if UnitIndex = 0 then // local reference
      TObject(Ref) := FindMeta(RefList[RefIndex])
    else // remote reference
      TObject(Ref) := TSepiMetaUnit(FUsesList.Objects[UnitIndex-1])
        .FindMeta(RefList[RefIndex]);
    RefList.Objects[RefIndex] := TObject(Ref);
  end;
end;

{*
  Ajoute une r�f�rence qui va devoir �tre enregistr�e
  Cette m�thode ne peut �tre appel�e que depuis la m�thode ListReferences des
  metas contenus dans cette unit�. � tout autre moment, c'est la violation
  d'acc�s assur�e.
  @param Ref   R�f�rence � ajouter
*}
procedure TSepiMetaUnit.AddRef(Ref : TSepiMeta);
var UnitIndex : integer;
    RefList : TStrings;
begin
  if Ref = nil then exit;

  UnitIndex := AddUses(Ref.OwningUnit)+1;
  RefList := FReferences[UnitIndex];

  if RefList.IndexOfObject(Ref) < 0 then
    RefList.AddObject(Copy(
      Ref.GetFullName, Length(Ref.OwningUnit.Name)+2, MaxInt), Ref);
end;

{*
  �crit une r�f�rence dans un flux
  Toute r�f�rence � �crire doit �tre ajout�e au moyen de la m�thode AddRef dans
  la m�thode ListReferences de son r�f�renceur.
  Cette m�thode ne peut �tre appel�e que depuis la m�thode Save des metas
  contenus dans cette unit�. � tout autre moment, c'est la violation d'acc�s
  assur�e.
  @param Stream   Flux dans lequel �crire la r�f�rence
  @param Ref      R�f�rence � �crire
*}
procedure TSepiMetaUnit.WriteRef(Stream : TStream; Ref : TSepiMeta);
var UnitIndex, RefIndex : integer;
begin
  if Ref = nil then
  begin
    UnitIndex := $FFFF;
    Stream.WriteBuffer(UnitIndex, 2);
  end else
  begin
    UnitIndex := FUsesList.IndexOfObject(Ref.OwningUnit)+1;
    RefIndex := FReferences[UnitIndex].IndexOfObject(Ref);
    Assert(RefIndex >= 0);

    Stream.WriteBuffer(UnitIndex, 2);
    Stream.WriteBuffer(RefIndex, 4);
  end;
end;

{-----------------------}
{ Classe TSepiTypeAlias }
{-----------------------}

{*
  Charge un alias de type depuis un flux
*}
constructor TSepiTypeAlias.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;
  OwningUnit.ReadRef(Stream, FDest);
end;

{*
  Cr�e un nouvel alias de type
  @param AOwner   Propri�taire de l'alias de type
  @param AName    Nom de l'alias de type
  @param ADest    Destination de l'alias
*}
constructor TSepiTypeAlias.Create(AOwner : TSepiMeta; const AName : string;
  ADest : TSepiType);
begin
  inherited Create(AOwner, AName);
  FDest := ADest;
end;

{*
  Cr�e un nouvel alias de type
  @param AOwner   Propri�taire de l'alias de type
  @param AName    Nom de l'alias de type
  @param ADest    RTTI de la destination de l'alias
*}
constructor TSepiTypeAlias.Create(AOwner : TSepiMeta; const AName : string;
  ADest : PTypeInfo);
begin
  Create(AOwner, AName, AOwner.Root.FindType(ADest));
end;

{*
  [@inheritDoc]
*}
procedure TSepiTypeAlias.ListReferences;
begin
  inherited;
  OwningUnit.AddRef(FDest);
end;

{*
  [@inheritDoc]
*}
procedure TSepiTypeAlias.Save(Stream : TStream);
begin
  inherited;
  OwningUnit.WriteRef(Stream, FDest);
end;

{----------------------}
{ Classe TSepiConstant }
{----------------------}

{*
  Charge une constante depuis un flux
*}
constructor TSepiConstant.Load(AOwner : TSepiMeta; Stream : TStream);
var ValueLength : integer;
begin
  inherited;
  OwningUnit.ReadRef(Stream, FType);
  FValue := TMemoryStream.Create;

  Stream.ReadBuffer(ValueLength, 4);
  if ValueLength > 0 then // to prevent a CopyFrom(0) *
    FValue.CopyFrom(Stream, ValueLength);

  { * I reckon a null ValueLength shouldn't happen. But as a newly created
    TSepiConstant has got a null Value, it is more logical and safer to allow
    and check for a null ValueLength. }
end;

{*
  Cr�e une nouvelle constante
  @param AOwner   Propri�taire de la constante
  @param AName    Nom de la constante
  @param AType    Type de la constante
*}
constructor TSepiConstant.Create(AOwner : TSepiMeta; const AName : string;
  AType : TSepiType);
begin
  inherited Create(AOwner, AName);
  FType := AType;
  FValue := TMemoryStream.Create;
end;

{*
  [@inheritDoc]
*}
procedure TSepiConstant.ListReferences;
begin
  inherited;
  OwningUnit.AddRef(FType);
end;

{*
  [@inheritDoc]
*}
procedure TSepiConstant.Save(Stream : TStream);
begin
  inherited;
  OwningUnit.WriteRef(Stream, FType);
end;

initialization
  SepiRegisterMetaClasses([
    TSepiMetaUnit, TSepiTypeAlias, TSepiConstant
  ]);
finalization
  SepiMetaClasses.Free;
  SepiImportedUnits.Free;
end.

