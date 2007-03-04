{*
  D�finit les classes de meta-membres
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit SepiMetaMembers;

interface

uses
  SysUtils, Classes, StrUtils, TypInfo, SepiMetaUnits;

type
  {*
    Type de liaison d'une m�thode
  *}
  TMethodLinkKind = (mlkStatic, mlkVirtual, mlkDynamic);

  {*
    Convention d'appel d'une m�thode
  *}
  TCallConvention = (ccRegister, ccStdCall, ccPascal, ccCDecl);

  {*
    Type d'accesseur d'une propri�t�
  *}
  TPropertyAccessKind = (pakNone, pakField, pakMethod);

  {*
    Meta-variable
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaField = class(TSepiMeta)
  private
    FType : TSepiType; /// Type du champ
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AType : TSepiType);

    property FieldType : TSepiType read FType;
  end;

  {*
    Meta-param�tre de m�thode
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaParam = class(TSepiMeta)
  private
    FType : TSepiType;    /// Type du param�tre
    FFlags : TParamFlags; /// Flags du param�tre
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AType : TSepiType; AFlags : TParamFlags = []);

    function Equals(AParam : TSepiMetaParam) : boolean;
    function CompatibleWith(AType : TSepiType) : boolean;

    property ParamType : TSepiType read FType;
    property Flags : TParamFlags read FFlags;
  end;

  {*
    Signature d'une m�thode
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMethodSignature = class
  private
    FOwner : TSepiMeta;                /// Propri�taire de la signature
    FKind : TMethodKind;               /// Type de m�thode
    FReturnType : TSepiType;           /// Type de retour
    FCallConvention : TCallConvention; /// Convention d'appel

    procedure Loaded;

    function GetParamCount : integer;
    function GetParams(Index : integer) : TSepiMetaParam;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream);
    constructor Create(AOwner : TSepiMeta; const ASignature : string;
      ACallConvention : TCallConvention = ccRegister);

    function Equals(ASignature : TSepiMethodSignature) : boolean;
    function CompatibleWith(const ATypes : array of TSepiType) : boolean;

    property Kind : TMethodKind read FKind;
    property ParamCount : integer read GetParamCount;
    property Params[index : integer] : TSepiMetaParam read GetParams;
    property ReturnType : TSepiType read FReturnType;
    property CallConvention : TCallConvention read FCallConvention;
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
    FCode : Pointer;                   /// Adresse de code natif
    FSignature : TSepiMethodSignature; /// Signature de la m�thode
    FLinkKind : TMethodLinkKind;       /// Type de liaison d'appel
    FAbstract : boolean;               /// Indique si la m�thode est abstraite
    FInherited : TSepiMetaMethod;      /// M�thode h�rit�e

    procedure FindInherited;
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      ACode : Pointer; const ASignature : string;
      ACallConvention : TCallConvention = ccRegister;
      ALinkKind : TMethodLinkKind = mlkStatic; AAbstract : boolean = False);
    destructor Destroy; override;

    property Signature : TSepiMethodSignature read FSignature;
    property LinkKind : TMethodLinkKind read FLinkKind;
    property IsAbstract : boolean read FAbstract;
  end;

  {*
    Meta-m�thode surcharg�e
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaOverloadedMethod = class(TSepiMeta)
  private
    FMethodCount : integer; /// Nombre de m�thodes de m�me nom
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string);

    function NextID : integer;
    function FindMethod(const ATypes : array of TSepiType) : TSepiMetaMethod;
  end;

  {*
    Acc�s de propri�t�
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiPropertyAccess = record
    Kind : TPropertyAccessKind;               /// Type d'acc�s
    case TPropertyAccessKind of
      pakNone : (Meta : TSepiMeta);           /// Meta d'acc�s (neutre)
      pakField : (Field : TSepiMetaField);    /// Meta-champ d'acc�s
      pakMethod : (Method : TSepiMetaMethod); /// Meta-m�thode d'acc�s
  end;

  {*
    Meta-propri�t�
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaProperty = class(TSepiMeta)
  private
    FSignature : TSepiMethodSignature;  /// Signature

    FReadAccess : TSepiPropertyAccess;  /// Acc�s en lecture
    FWriteAccess : TSepiPropertyAccess; /// Acc�s en �criture

    function GetPropType : TSepiType;
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName, ASignature : string;
      AReadAccess, AWriteAccess : TSepiMeta);
    destructor Destroy; override;

    property Signature : TSepiMethodSignature read FSignature;
    property PropType : TSepiType read GetPropType;

    property ReadAccess : TSepiPropertyAccess read FReadAccess;
    property WriteAccess : TSepiPropertyAccess read FWriteAccess;
  end;

const
  MethodKindStrings : array[mkProcedure..mkClassConstructor] of string = (
    'procedure', 'function', 'constructor', 'destructor',
    'class procedure', 'class function', 'class constructor'
  );

implementation

{-----------------------}
{ Classe TSepiMetaField }
{-----------------------}

{*
  Charge un champ depuis un flux
*}
constructor TSepiMetaField.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;
  Stream.ReadBuffer(FType, 4);
end;

{*
  Cr�e un nouveau champ
  @param AOwner   Propri�taire du champ
  @param AName    Nom du champ
  @param AType    Type du champ
*}
constructor TSepiMetaField.Create(AOwner : TSepiMeta; const AName : string;
  AType : TSepiType);
begin
  inherited Create(AOwner, AName);
  FType := AType;
end;

{*
  [@inheritDoc]
*}
procedure TSepiMetaField.Loaded;
begin
  inherited;
  OwningUnit.LoadRef(FType);
end;

{-----------------------}
{ Classe TSepiMetaParam }
{-----------------------}

{*
  Charge un param�tre depuis un flux
*}
constructor TSepiMetaParam.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  Stream.ReadBuffer(FType, 4);
  Stream.ReadBuffer(FFlags, 1);
end;

{*
  Cr�e un nouveau param�tre
  @param AOwner   Propri�taire du param�tre
  @param AName    Nom du param�tre
  @param AType    Type du param�tre
  @param AFlags   Flags
*}
constructor TSepiMetaParam.Create(AOwner : TSepiMeta; const AName : string;
  AType : TSepiType; AFlags : TParamFlags = []);
begin
  inherited Create(AOwner, AName);

  FType := AType;
  FFlags := AFlags;
end;

{*
  [@inheritDoc]
*}
procedure TSepiMetaParam.Loaded;
begin
  inherited;
  OwningUnit.LoadRef(FType);
end;

{*
  D�termine si deux param�tres sont identiques
  @param AParam   Param�tre � comparer
  @return True si les param�tres sont identiques, False sinon
*}
function TSepiMetaParam.Equals(AParam : TSepiMetaParam) : boolean;
begin
  Result := (ParamType = AParam.ParamType) and (Flags = AParam.Flags);
end;

{*
  D�termine si un type est compatible avec le param�tre
  @param AType   Type � Tester
  @return True si le type est compatible, False sinon
*}
function TSepiMetaParam.CompatibleWith(AType : TSepiType) : boolean;
begin
  Result := FType.CompatibleWith(AType);
end;

{-----------------------------}
{ Classe TSepiMethodSignature }
{-----------------------------}

{*
  Charge une signature depuis un flux
  @param AOwner   Propri�taire de la signature
  @param Stream   Flux depuis lequel charger la signature
*}
constructor TSepiMethodSignature.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited Create;

  FOwner := AOwner;
  Stream.ReadBuffer(FKind, 1);
  Stream.ReadBuffer(FReturnType, 4);
  Stream.ReadBuffer(FCallConvention, 1);

  // Parameters should be loaded by the owner, for they are children of it
end;

{*
  Cr�e une signature de m�thode
  @param AOwner       Propri�taire de la signature
  @param ASignature   Signature Delphi
*}
constructor TSepiMethodSignature.Create(AOwner : TSepiMeta;
  const ASignature : string; ACallConvention : TCallConvention = ccRegister);
var I : integer;
begin
  inherited Create;

  FOwner := AOwner;
  FKind := mkProcedure;
  FReturnType := nil;
  FCallConvention := ACallConvention;

  I := Pos('(', ASignature);
  if I = 0 then I := Length(ASignature)+1;

  FKind := TMethodKind(AnsiIndexText(
    Copy(ASignature, 1, I-1), MethodKindStrings));
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodSignature.Loaded;
begin
  inherited;
  FOwner.OwningUnit.LoadRef(FReturnType);
end;

{*
  Nombre de param�tres
  @return Nombre de param�tres
*}
function TSepiMethodSignature.GetParamCount : integer;
begin
  Result := FOwner.ChildCount;
end;

{*
  Tableau zero-based des param�tres
  @param Index   Index du param�tre � r�cup�rer
  @return Param�tre situ� � l'index Index
*}
function TSepiMethodSignature.GetParams(Index : integer) : TSepiMetaParam;
begin
  { Here, we can't guarantee that all children are TSepiMetaParam, so we
    check it with an as operator. }
  Result := FOwner.Children[Index] as TSepiMetaParam;
end;

{*
  D�termine si deux signatures sont identiques
  @param ASignature   Signature � comparer
  @return True si les signatures sont identiques, False sinon
*}
function TSepiMethodSignature.Equals(
  ASignature : TSepiMethodSignature) : boolean;
var I : integer;
begin
  Result := False;

  if ParamCount <> ASignature.ParamCount then exit;
  for I := 0 to ParamCount-1 do
    if not Params[I].Equals(ASignature.Params[I]) then exit;
  if FReturnType <> ASignature.ReturnType then exit;

  Result := True;
end;

{*
  D�termine si une liste de types est compatible avec la signature
  @param ATypes   Liste des types � tester
  @return True si la liste de types est compatible, False sinon
*}
function TSepiMethodSignature.CompatibleWith(
  const ATypes : array of TSepiType) : boolean;
var I : integer;
begin
  Result := False;

  if ParamCount <> Length(ATypes) then exit;
  for I := 0 to ParamCount-1 do
    if not Params[I].CompatibleWith(ATypes[Low(ATypes)+I]) then exit;

  Result := True;
end;

{------------------------}
{ Classe TSepiMetaMethod }
{------------------------}

{*
  Charge une meta-m�thode depuis un flux
*}
constructor TSepiMetaMethod.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  FCode := nil;
  FSignature := TSepiMethodSignature.Load(Self, Stream);
  LoadChildren(Stream);
  Stream.ReadBuffer(FLinkKind, 1);
  Stream.ReadBuffer(FAbstract, 1);
  FInherited := nil;
end;

{*
  Cr�e une nouvelle meta-m�thode
  @param AOwner       Propri�taire de la m�thode
  @param AName        Nom de la m�thode
  @param ASignature   Signature Delphi de la m�thode
  @param ALinkKind    Type de liaison
  @param AAbstract    Indique si la m�thode est abstraite
*}
constructor TSepiMetaMethod.Create(AOwner : TSepiMeta; const AName : string;
  ACode : Pointer; const ASignature : string;
  ACallConvention : TCallConvention = ccRegister;
  ALinkKind : TMethodLinkKind = mlkStatic; AAbstract : boolean = False);
begin
  inherited Create(AOwner, AName);

  FCode := ACode;
  FSignature := TSepiMethodSignature.Create(Self, ASignature, ACallConvention);
  FLinkKind := ALinkKind;
  FAbstract := AAbstract and (FLinkKind <> mlkStatic);
  FindInherited;
end;

{*
  D�truit l'instance
*}
destructor TSepiMetaMethod.Destroy;
begin
  FSignature.Free;
  inherited Destroy;
end;

{*
  Trouve la m�thode h�rit�e de m�me nom
*}
procedure TSepiMetaMethod.FindInherited;
var Overloaded : boolean;
    LookFor : string;
begin
  LookFor := Name;

  Overloaded := Copy(Name, 1, 3) = 'OL$';
  if Overloaded then
  begin
    Delete(LookFor, 1, 3);
    Delete(LookFor, Pos('$', LookFor), Length(LookFor));
  end;

  FInherited := nil;
  { TODO 3 -cMetaunit�s : Trouver la m�thode h�rit�e }
end;

{*
  [@inheritDoc]
*}
procedure TSepiMetaMethod.Loaded;
begin
  inherited;
  FSignature.Loaded;
  FindInherited;
end;

{----------------------------------}
{ Classe TSepiMetaOverloadedMethod }
{----------------------------------}

{*
  Charge une m�thode surcharg�e depuis un flux
*}
constructor TSepiMetaOverloadedMethod.Load(AOwner : TSepiMeta;
  Stream : TStream);
begin
  inherited;
  Stream.ReadBuffer(FMethodCount, 4);
end;

{*
  Cr�e une nouvelle m�thode surcharg�e
  @param AOwner   Propri�taire de la m�thode
  @param AName    Nom de la m�thode
*}
constructor TSepiMetaOverloadedMethod.Create(AOwner : TSepiMeta;
  const AName : string);
begin
  inherited Create(AOwner, AName);
  FMethodCount := 0;
end;

{*
  D�termine l'ID de m�thode surcharg�e suivant
  @return Nouvel ID
*}
function TSepiMetaOverloadedMethod.NextID : integer;
begin
  Result := FMethodCount;
  inc(FMethodCount);
end;

{*
  Trouve la m�thode effective qui correspond � une liste de types de param�tres
  @param ATypes   Liste des types de param�tres
  @return M�thode effective correspondante
*}
function TSepiMetaOverloadedMethod.FindMethod(
  const ATypes : array of TSepiType) : TSepiMetaMethod;
var I : integer;
begin
  for I := 0 to FMethodCount-1 do
  begin
    Result := TSepiMetaMethod(Owner.FindMeta(Format('OL$%s$%d', [Name, I])));
    if Result.Signature.CompatibleWith(ATypes) then exit;
  end;
  Result := nil;
end;

{--------------------------}
{ Classe TSepiMetaProperty }
{--------------------------}

{*
  Charge une propri�t� depuis un flux
*}
constructor TSepiMetaProperty.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  FSignature := TSepiMethodSignature.Load(AOwner, Stream);
  LoadChildren(Stream);

  Stream.ReadBuffer(FReadAccess, sizeof(TSepiPropertyAccess));
  Stream.ReadBuffer(FWriteAccess, sizeof(TSepiPropertyAccess));
end;

{*
  Cr�e une nouvelle propri�t�
  @param AOwner         Propri�taire de la propri�t�
  @param AName          Nom de la propri�t�
  @param ASignature     Signature
  @param AReadAccess    Acc�s en lecture � la propri�t� (peut �tre nul)
  @param AWriteAccess   Acc�s en �criture � la propri�t� (peut �tre nul)
*}
constructor TSepiMetaProperty.Create(AOwner : TSepiMeta;
  const AName, ASignature : string; AReadAccess, AWriteAccess : TSepiMeta);
begin
  inherited Create(AOwner, AName);

  FSignature := TSepiMethodSignature.Create(Self, ASignature);

  FReadAccess.Meta := AReadAccess;
  if AReadAccess is TSepiMetaField then
    FReadAccess.Kind := pakField
  else if AReadAccess is TSepiMetaMethod then
    FReadAccess.Kind := pakMethod
  else
    FReadAccess.Kind := pakNone;

  FWriteAccess.Meta := AWriteAccess;
  if AWriteAccess is TSepiMetaField then
    FWriteAccess.Kind := pakField
  else if AWriteAccess is TSepiMetaMethod then
    FWriteAccess.Kind := pakMethod
  else
    FWriteAccess.Kind := pakNone;
end;

{*
  D�truit l'instance
*}
destructor TSepiMetaProperty.Destroy;
begin
  FSignature.Free;
  inherited;
end;

{*
  Type de la propri�t�
  @return Type de la propri�t�
*}
function TSepiMetaProperty.GetPropType : TSepiType;
begin
  Result := Signature.ReturnType;
end;

{*
  [@inheritDoc]
*}
procedure TSepiMetaProperty.Loaded;
begin
  inherited;

  OwningUnit.LoadRef(FReadAccess.Meta);
  OwningUnit.LoadRef(FWriteAccess.Meta);
end;

initialization
  SepiRegisterMetaClasses([
    TSepiMetaField, TSepiMetaParam, TSepiMetaMethod, TSepiMetaOverloadedMethod,
    TSepiMetaProperty
  ]);
end.

