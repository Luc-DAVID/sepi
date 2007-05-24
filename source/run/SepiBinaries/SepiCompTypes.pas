{*
  D�finit les classes de gestion des types composites
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit SepiCompTypes;

interface

uses
  Classes, SysUtils, ScUtils, SepiMetaUnits, SysConst, TypInfo, Contnrs,
  ScLists, StrUtils, ScStrUtils, ScExtra;

type
  {*
    Type de liaison d'une m�thode
    - mlkStatic : m�thode statique (ni virtuelle ni dynamique)
    - mlkVirtual : m�thode � liaison virtuelle (via VMT)
    - mlkDynamic : m�thode � liaison dynamique (via DMT)
    - mlkMessage : m�thode d'interception de message (via DMT)
    - mlkOverride : d�termine le type de liaison depuis la m�thode h�rit�e
  *}
  TMethodLinkKind = (mlkStatic, mlkVirtual, mlkDynamic, mlkMessage,
    mlkOverride);

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
    FOffset : integer; /// Offset
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AType : TSepiType; AOffset : integer);

    property FieldType : TSepiType read FType;
    property Offset : integer read FOffset;
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

    constructor RegisterParamData(AOwner : TSepiMeta; var ParamData : Pointer);
    constructor CreateFromString(AOwner : TSepiMeta; const Definition : string);
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
    constructor RegisterTypeData(AOwner : TSepiMeta; ATypeData : PTypeData);
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
    FFirstDeclaration : boolean;       /// Faux uniquement quand 'override'
    FAbstract : boolean;               /// Indique si la m�thode est abstraite
    FInherited : TSepiMetaMethod;      /// M�thode h�rit�e

    FLinkIndex : integer; /// Offset de VMT ou index de DMT, selon la liaison

    procedure MakeLink;
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      ACode : Pointer; const ASignature : string;
      ACallConvention : TCallConvention = ccRegister;
      ALinkKind : TMethodLinkKind = mlkStatic; AAbstract : boolean = False;
      AMsgID : integer = 0);
    destructor Destroy; override;

    property Code : Pointer read FCode;
    property Signature : TSepiMethodSignature read FSignature;
    property LinkKind : TMethodLinkKind read FLinkKind;
    property FirstDecleration : boolean read FFirstDeclaration;
    property IsAbstract : boolean read FAbstract;
    property InheritedMethod : TSepiMetaMethod read FInherited;

    property VMTOffset : integer read FLinkIndex;
    property DMTIndex : integer read FLinkIndex;
    property MsgID : integer read FLinkIndex;
    property IMTIndex : integer read FLinkIndex;
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
    function FindMethod(
      ASignature : TSepiMethodSignature) : TSepiMetaMethod; overload;
    function FindMethod(
      const ATypes : array of TSepiType) : TSepiMetaMethod; overload;
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

  {*
    Type enregistrement
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiRecordType = class(TSepiType)
  private
    FPacked : boolean; /// Indique si le record est packed

    function NextOffset(Field : TSepiMetaField) : integer;
    function AddField(const FieldName : string; FieldType : TSepiType;
      After : TSepiMetaField) : TSepiMetaField; overload;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      APacked : boolean = False);

    function AddField(const FieldName : string;
      FieldType : TSepiType) : TSepiMetaField; overload;
    function AddField(const FieldName : string; FieldType : TSepiType;
      const After : string) : TSepiMetaField; overload;
    function AddField(const FieldName : string;
      FieldTypeInfo : PTypeInfo) : TSepiMetaField; overload;
    function AddField(const FieldName : string; FieldTypeInfo : PTypeInfo;
      const After : string) : TSepiMetaField; overload;

    function CompatibleWith(AType : TSepiType) : boolean; override;

    property IsPacked : boolean read FPacked;
  end;

  {*
    Interface
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiInterface = class(TSepiType)
  private
    FParent : TSepiInterface; /// Interface parent (ou nil - IInterface)
    FCompleted : boolean;     /// Indique si l'interface est enti�rement d�finie

    FHasGUID : boolean;         /// Indique si l'interface poss�de un GUID
    FIsDispInterface : boolean; /// Indique si c'est une disp interface
    FIsDispatch : boolean;      /// Indique si c'est une IDispatch
    FGUID : TGUID;              /// GUID de l'interface, si elle en a un

    procedure MakeTypeInfo;
  protected
    procedure Loaded; override;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AParent : TSepiInterface; const AGUID : TGUID;
      AIsDispInterface : boolean = False);

    procedure Complete;

    function IntfInheritsFrom(AParent : TSepiInterface) : boolean;

    property Parent : TSepiInterface read FParent;
    property Completed : boolean read FCompleted;

    property HasGUID : boolean read FHasGUID;
    property IsDispInterface : boolean read FIsDispInterface;
    property IsDispatch : boolean read FIsDispatch;
    property GUID : TGUID read FGUID;
  end;

  {*
    Classe (type objet)
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiClass = class(TSepiType)
  private
    FDelphiClass : TClass;   /// Classe Delphi
    FParent : TSepiClass;    /// Classe parent (nil si n'existe pas - TObject)
    FCompleted : boolean;    /// Indique si la classe est enti�rement d�finie

    FVMTSize : integer;      /// Taille de la VMT dans les index positifs
    FDMTNextIndex : integer; /// Prochain index � utiliser dans la DMT

    FShortClassName : ShortString; /// Nom de classe pour la VMT

    procedure MakeTypeInfo;
    procedure MakeDMT;
    procedure MakeVMT;

    function GetVMTEntries(Index : integer) : Pointer;
    procedure SetVMTEntries(Index : integer; Value : Pointer);
  protected
    procedure Loaded; override;

    property VMTEntries[index : integer] : Pointer
      read GetVMTEntries write SetVMTEntries;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AParent : TSepiClass);
    destructor Destroy; override;

    procedure Complete;

    function CompatibleWith(AType : TSepiType) : boolean; override;
    function ClassInheritsFrom(AParent : TSepiClass) : boolean;

    function LookForMember(const MemberName : string; FromUnit : TSepiMetaUnit;
      FromClass : TSepiClass = nil) : TSepiMeta;

    property DelphiClass : TClass read FDelphiClass;
    property Parent : TSepiClass read FParent;
    property Completed : boolean read FCompleted;

    property VMTSize : integer read FVMTSize;
  end;

  {*
    Meta-classe (type classe)
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMetaClass = class(TSepiType)
  private
    FClass : TSepiClass; /// Classe correspondante
  protected
    procedure Loaded; override;
  public
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AClass : TSepiClass);

    function CompatibleWith(AType : TSepiType) : boolean; override;

    property SepiClass : TSepiClass read FClass;
  end;

  {*
    Type r�f�rence de m�thode
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiMethodRefType = class(TSepiType)
  private
    FSignature : TSepiMethodSignature; /// Signature
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName, ASignature : string;
      AOfObject : boolean = False;
      ACallConvention : TCallConvention = ccRegister);
    destructor Destroy; override;

    function CompatibleWith(AType : TSepiType) : boolean; override;

    property Signature : TSepiMethodSignature read FSignature;
  end;

const
  /// Proc�dure d'unit�
  mkUnitProcedure = TMethodKind(integer(High(TMethodKind))+1);
  /// Fonction d'unit�
  mkUnitFunction = TMethodKind(integer(High(TMethodKind))+2);
  /// Propri�t�
  mkProperty = TMethodKind(integer(High(TMethodKind))+3);

  /// Cha�nes des types de m�thode
  MethodKindStrings : array[mkProcedure..mkProperty] of string = (
    'procedure', 'function', 'constructor', 'destructor',
    'class procedure', 'class function', 'class constructor',
    '', '', '', 'unit procedure', 'unit function', 'property'
  );

implementation

const
  // Tailles de structure TTypeData en fonction des types
  RecordTypeDataLength = 0;
  IntfTypeDataLengthBase =
    sizeof(Pointer) + sizeof(TIntfFlagsBase) + sizeof(TGUID) + 2*sizeof(Word);
  ClassTypeDataLengthBase =
    sizeof(TClass) + sizeof(Pointer) + sizeof(SmallInt) + sizeof(Word);

  PropInfoLengthBase = sizeof(TPropInfo) - sizeof(ShortString);

  vmtMinIndex = vmtSelfPtr;
  vmtMinMethodIndex = vmtParent + 4;

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
  AType : TSepiType; AOffset : integer);
begin
  inherited Create(AOwner, AName);
  FType := AType;
  FOffset := AOffset;
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
  Cr�e un param�tre depuis les donn�es de type d'une r�f�rence de m�thode
  En sortie, le pointeur ParamData a avanc� jusqu'au param�tre suivant
  @param AOwner      Propri�taire du param�tre
  @param ParamData   Pointeur vers les donn�es du param�tre
*}
constructor TSepiMetaParam.RegisterParamData(AOwner : TSepiMeta;
  var ParamData : Pointer);
var AFlags : TParamFlags;
    AName, ATypeStr : string;
begin
  AFlags := TParamFlags(ParamData^);
  inc(LongInt(ParamData), sizeof(TParamFlags));
  AName := PShortString(ParamData)^;
  inc(LongInt(ParamData), PByte(ParamData)^ + 1);
  ATypeStr := PShortString(ParamData)^;
  inc(LongInt(ParamData), PByte(ParamData)^ + 1);

  Create(AOwner, AName, AOwner.Root.FindType(ATypeStr), AFlags);
end;

{*
  Cr�e un param�tre depuis sa d�finition Delphi
  @param AOwner       Propri�taire du param�tre
  @param Definition   D�finition Delphi du param�tre
*}
constructor TSepiMetaParam.CreateFromString(AOwner : TSepiMeta;
  const Definition : string);
var AFlags : TParamFlags;
    NamePart, TypePart, FlagStr, AName, ATypeStr : string;
begin
  AFlags := [];
  SplitToken(Definition, ':', NamePart, TypePart);

  // Partie du nom - � gauche du :
  if SplitToken(Trim(NamePart), ' ', FlagStr, AName) then
  begin
    case AnsiIndexText(FlagStr, ['var', 'const', 'out']) of {don't localize}
      0 : Include(AFlags, pfVar);
      1 : Include(AFlags, pfConst);
      2 : Include(AFlags, pfOut);
    end;
  end;

  // Partie du type - � droite du :
  TypePart := Trim(TypePart);
  if AnsiStartsText('array of ', TypePart) then {don't localize}
  begin
    Include(AFlags, pfArray);
    ATypeStr := TrimLeft(Copy(TypePart, 10, MaxInt)); // 10 is 'array of |'
  end else ATypeStr := TypePart;

  Create(AOwner, AName, AOwner.Root.FindType(ATypeStr), AFlags);
end;

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
  Cr�e une signature � partir des donn�es de type d'un type m�thode
  @param AOwner      Propri�taire de la signature
  @param ATypeData   Donn�es de type
*}
constructor TSepiMethodSignature.RegisterTypeData(AOwner : TSepiMeta;
  ATypeData : PTypeData);
var ParamData : Pointer;
    I : integer;
begin
  inherited Create;

  FOwner := AOwner;
  FKind := ATypeData.MethodKind;
  ParamData := @ATypeData.ParamList;

  for I := 1 to ATypeData.ParamCount do
    TSepiMetaParam.RegisterParamData(FOwner, ParamData);

  FReturnType := FOwner.Root.FindType(PShortString(ParamData)^);
  FCallConvention := ccRegister;
end;

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
  @param AOwner            Propri�taire de la signature
  @param ASignature        Signature Delphi
  @param ACallConvention   Convention d'appel
*}
constructor TSepiMethodSignature.Create(AOwner : TSepiMeta;
  const ASignature : string; ACallConvention : TCallConvention = ccRegister);

  function MultiPos(const Chars : array of Char; const Str : string;
    Offset : integer = 1) : integer;
  var I : integer;
  begin
    for I := Low(Chars) to High(Chars) do
    begin
      Result := PosEx(Chars[I], Str, Offset);
      if Result > 0 then exit;
    end;
    Result := Length(Str)+1;
  end;

var ParamPos, ReturnTypePos, ParamEnd : integer;
begin
  inherited Create;

  FOwner := AOwner;
  FKind := mkProcedure;
  FReturnType := nil;
  FCallConvention := ACallConvention;

  // Type de m�thode
  ParamPos := MultiPos(['(', '[', ':'], ASignature);
  FKind := TMethodKind(AnsiIndexText(
    Trim(Copy(ASignature, 1, ParamPos-1)), MethodKindStrings));

  // Type de retour
  if (Kind = mkFunction) or (Kind = mkUnitFunction) or (Kind = mkProperty) then
  begin
    ReturnTypePos := RightPos(':', ASignature);
    FReturnType := FOwner.Root.FindType(
      Trim(Copy(ASignature, ReturnTypePos+1, MaxInt)));
  end;

  // Param�tres
  if ParamPos <= Length(ASignature) then
  begin
    while not (ASignature[ParamPos] in [')', ']', ':']) do
    begin
      inc(ParamPos);
      ParamEnd := MultiPos([';', ')', ']', ':'], ASignature, ParamPos);
      TSepiMetaParam.CreateFromString(FOwner,
        Copy(ASignature, ParamPos, ParamEnd-ParamPos));
      ParamPos := ParamEnd;
    end;
  end;
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

  if Kind <> ASignature.Kind then exit;
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
  Stream.ReadBuffer(FFirstDeclaration, 1);
  Stream.ReadBuffer(FAbstract, 1);
  Stream.ReadBuffer(FLinkIndex, 2); // only for messages

  MakeLink;
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
  ALinkKind : TMethodLinkKind = mlkStatic; AAbstract : boolean = False;
  AMsgID : integer = 0);
begin
  inherited Create(AOwner, AName);

  FCode := ACode;
  FSignature := TSepiMethodSignature.Create(Self, ASignature, ACallConvention);
  FLinkKind := ALinkKind;
  FFirstDeclaration := FLinkKind <> mlkOverride;
  FAbstract := AAbstract and (FLinkKind in [mlkVirtual, mlkDynamic]);
  FLinkIndex := AMsgID; // only for messages

  MakeLink;
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
  Met au point la liaison et l'index de liaison
  Par extension, recherche aussi la m�thode h�rit�e.
*}
procedure TSepiMetaMethod.MakeLink;
var OwningClass : TSepiClass;
    LookFor : string;
    Meta : TSepiMeta;
begin
  FInherited := nil;

  // If not a method, then nothing to do, but be sure link kind is static
  if not (Owner is TSepiClass) then
  begin
    FLinkKind := mlkStatic;
    FLinkIndex := 0;
    exit;
  end;

  OwningClass := TSepiClass(Owner);

  if OwningClass.Parent <> nil then
  begin
    // Setting the inherited method name
    LookFor := Name;
    if Copy(Name, 1, 3) = 'OL$' then // overloaded
    begin
      Delete(LookFor, 1, 3);
      Delete(LookFor, Pos('$', LookFor), MaxInt);
    end;

    // Looking for the inherited method
    Meta := OwningClass.Parent.LookForMember(LookFor, OwningUnit, OwningClass);
    if Meta is TSepiMetaMethod then
    begin
      if TSepiMetaMethod(Meta).Signature.Equals(Signature) then
        FInherited := TSepiMetaMethod(Meta);
    end else
    if Meta is TSepiMetaOverloadedMethod then
      FInherited := TSepiMetaOverloadedMethod(Meta).FindMethod(Signature);
  end;

  // Setting up link kind and index
  case FLinkKind of
    mlkStatic : FLinkIndex := 0;
    mlkVirtual :
    begin
      FLinkIndex := OwningClass.FVMTSize;
      inc(OwningClass.FVMTSize, 4);
    end;
    mlkDynamic :
    begin
      FLinkIndex := OwningClass.FDMTNextIndex;
      dec(OwningClass.FDMTNextIndex);
    end;
    mlkMessage : ; // nothing to do, FLinkKind already set
    mlkOverride :
    begin
      FLinkKind := FInherited.LinkKind;
      FLinkIndex := FInherited.FLinkIndex;
    end;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TSepiMetaMethod.Loaded;
begin
  inherited;
  FSignature.Loaded;
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
  Trouve la m�thode effective qui correspond � une signature donn�e
  @param ASignature   Signature � rechercher
  @return M�thode effective correspondante
*}
function TSepiMetaOverloadedMethod.FindMethod(
  ASignature : TSepiMethodSignature) : TSepiMetaMethod;
var I : integer;
begin
  for I := 0 to FMethodCount-1 do
  begin
    Result := TSepiMetaMethod(Owner.FindMeta(Format('OL$%s$%d', [Name, I])));
    if Result.Signature.Equals(ASignature) then exit;
  end;
  Result := nil;
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

{------------------------}
{ Classe TSepiRecordType }
{------------------------}

{*
  Charge un type record depuis un flux
*}
constructor TSepiRecordType.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  AllocateTypeInfo;
  Stream.ReadBuffer(FPacked, 1);
  LoadChildren(Stream);
end;

{*
  Cr�e un nouveau type record
  @param AOwner   Propri�taire du type
  @param AName    Nom du type
*}
constructor TSepiRecordType.Create(AOwner : TSepiMeta; const AName : string;
  APacked : boolean = False);
begin
  inherited Create(AOwner, AName, tkRecord);

  AllocateTypeInfo;
  FPacked := APacked;
end;

{*
  D�termine l'offset d'un champ suivant un champ donn� en m�moire
  @param Field   Champ d�j� existant, pr�c�dent le nouveau
  @return Offset du nouveau champ
*}
function TSepiRecordType.NextOffset(Field : TSepiMetaField) : integer;
begin
  Result := Field.Offset + Field.FieldType.Size;
  { TODO 2 : Aligner les champs dans un record non packed }
end;

{*
  Ajoute un champ au record
  @param FieldName   Nom du champ
  @param FieldType   Type du champ
  @param After       Champ pr�c�dent en m�moire
  @return Champ nouvellement ajout�
*}
function TSepiRecordType.AddField(const FieldName : string;
  FieldType : TSepiType; After : TSepiMetaField) : TSepiMetaField;
var Offset : integer;
begin
  if After = nil then Offset := 0 else
    Offset := NextOffset(After);

  Result := TSepiMetaField.Create(Self, FieldName, FieldType, Offset);

  if Offset + FieldType.Size > FSize then
    FSize := Offset + FieldType.Size;
end;

{*
  Ajoute un champ au record
  @param FieldName   Nom du champ
  @param FieldType   Type du champ
  @return Champ nouvellement ajout�
*}
function TSepiRecordType.AddField(const FieldName : string;
  FieldType : TSepiType) : TSepiMetaField;
var LastField : TSepiMetaField;
begin
  if ChildCount = 0 then LastField := nil else
    LastField := TSepiMetaField(Children[ChildCount-1]);

  Result := AddField(FieldName, FieldType, LastField);
end;

{*
  Ajoute un champ au record apr�s un champ donn� en m�moire
  @param FieldName   Nom du champ
  @param FieldType   Type du champ
  @param After       Nom du champ pr�c�dent en m�moire (vide pour le d�but)
  @return Champ nouvellement ajout�
*}
function TSepiRecordType.AddField(const FieldName : string;
  FieldType : TSepiType; const After : string) : TSepiMetaField;
begin
  Result := AddField(FieldName, FieldType, TSepiMetaField(FindMeta(After)));
end;

{*
  Ajoute un champ au record
  @param FieldName       Nom du champ
  @param FieldTypeInto   RTTI du type du champ
  @return Champ nouvellement ajout�
*}
function TSepiRecordType.AddField(const FieldName : string;
  FieldTypeInfo : PTypeInfo) : TSepiMetaField;
begin
  Result := AddField(FieldName, Root.FindType(FieldTypeInfo));
end;

{*
  Ajoute un champ au record apr�s un champ donn� en m�moire
  @param FieldName       Nom du champ
  @param FieldTypeInfo   RTTI du type du champ
  @param After           Nom du champ pr�c�dent en m�moire (vide pour le d�but)
  @return Champ nouvellement ajout�
*}
function TSepiRecordType.AddField(const FieldName : string;
  FieldTypeInfo : PTypeInfo; const After : string) : TSepiMetaField;
begin
  Result := AddField(FieldName, Root.FindType(FieldTypeInfo),
    TSepiMetaField(FindMeta(After)));
end;

{*
  [@inheritDoc]
*}
function TSepiRecordType.CompatibleWith(AType : TSepiType) : boolean;
begin
  Result := Self = AType;
end;

{-----------------------}
{ Classe TSepiInterface }
{-----------------------}

{*
  Recense une interface native
*}
constructor TSepiInterface.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
var Flags : TIntfFlags;
begin
  inherited;

  FSize := 4;
  if Assigned(TypeData.IntfParent^) then
    FParent := TSepiInterface(Root.FindType(TypeData.IntfParent^))
  else
    FParent := nil; // This is IInterface
  FCompleted := False;

  Flags := TypeData.IntfFlags;
  FHasGUID := ifHasGuid in Flags;
  FIsDispInterface := ifDispInterface in Flags;
  FIsDispatch := ifDispatch in Flags;

  if not FHasGUID then FGUID := NoGUID else
    FGUID := TypeData.Guid;
end;

{*
  Charge une interface depuis un flux
*}
constructor TSepiInterface.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  FSize := 4;
  FParent := TSepiInterface(Root.FindMeta(ReadStrFromStream(Stream)));
  FCompleted := False;

  LoadChildren(Stream);
end;

{*
  Cr�e une nouvelle interface
  @param AOwner    Propri�taire du type
  @param AName     Nom du type
  @param AParent   Classe parent
*}
constructor TSepiInterface.Create(AOwner : TSepiMeta; const AName : string;
  AParent : TSepiInterface; const AGUID : TGUID;
  AIsDispInterface : boolean = False);
begin
  inherited Create(AOwner, AName, tkInterface);

  FSize := 4;
  if Assigned(AParent) then FParent := AParent else
    FParent := TSepiInterface(Root.FindType(System.TypeInfo(IInterface)));
  FCompleted := False;

  FHasGUID := not IsNoGUID(AGUID);
  FIsDispInterface := AIsDispInterface;
  FIsDispatch := IntfInheritsFrom(
    TSepiInterface(Root.FindType(System.TypeInfo(IDispatch))));
  FGUID := AGUID;
end;

{*
  Construit les RTTI
*}
procedure TSepiInterface.MakeTypeInfo;
var Flags : TIntfFlags;
    OwningUnitName : ShortString;
    Count : PWord;
begin
  // Creating the RTTI
  AllocateTypeInfo(IntfTypeDataLengthBase + Length(OwningUnit.Name) + 1);
  TypeData.IntfParent := FParent.TypeInfoRef;

  // Interface flags
  Flags := [];
  if FHasGUID then Include(Flags, ifHasGuid);
  if FIsDispInterface then Include(Flags, ifDispInterface);
  if FIsDispatch then Include(Flags, ifDispatch);
  TypeData.IntfFlags := Flags;

  // GUID
  TypeData.Guid := FGUID;

  // Owning unit name
  OwningUnitName := OwningUnit.Name;
  Move(OwningUnitName[0], TypeData.IntfUnit[0], Length(OwningUnitName)+1);

  // Method count in the interface
  Count := SkipPackedShortString(@TypeData.IntfUnit);
  Count^ := ChildCount;
  inc(Integer(Count), 2);
  Count^ := $FFFF; // no more information available
end;

{*
  [@inheritDoc]
*}
procedure TSepiInterface.Loaded;
begin
  inherited;

  Complete;
end;

{*
  Termine l'interface et construit ses RTTI si ce n'est pas d�j� fait
*}
procedure TSepiInterface.Complete;
begin
  if FCompleted then exit;

  FCompleted := True;
  if not Native then
    MakeTypeInfo;
end;

{*
  D�termine si l'interface h�rite d'une interface donn�e
  @param AParent   Anc�tre � tester
  @return True si l'interface h�rite de AParent, False sinon
*}
function TSepiInterface.IntfInheritsFrom(AParent : TSepiInterface) : boolean;
begin
  Result := (AParent = Self) or
    (Assigned(FParent) and FParent.IntfInheritsFrom(AParent));
end;

{-------------------}
{ Classe TSepiClass }
{-------------------}

{*
  Recense une classe native
*}
constructor TSepiClass.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited;

  FSize := 4;
  FDelphiClass := TypeData.ClassType;
  if Assigned(TypeData.ParentInfo^) then
  begin
    FParent := TSepiClass(Root.FindType(TypeData.ParentInfo^));
    FVMTSize := Parent.VMTSize;
    FDMTNextIndex := Parent.FDMTNextIndex;
  end else
  begin
    // This is TObject
    FParent := nil;
    FVMTSize := vmtMinMethodIndex;
    FDMTNextIndex := -1;
  end;
  FCompleted := False;
end;

{*
  Charge une classe depuis un flux
*}
constructor TSepiClass.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  FSize := 4;
  FDelphiClass := nil;
  FParent := TSepiClass(Root.FindMeta(ReadStrFromStream(Stream)));
  FCompleted := False;

  FVMTSize := Parent.VMTSize;
  FDMTNextIndex := Parent.FDMTNextIndex;

  LoadChildren(Stream);
end;

{*
  Cr�e une nouvelle classe
  @param AOwner    Propri�taire du type
  @param AName     Nom du type
  @param AParent   Classe parent
*}
constructor TSepiClass.Create(AOwner : TSepiMeta; const AName : string;
  AParent : TSepiClass);
begin
  inherited Create(AOwner, AName, tkClass);

  FSize := 4;
  FDelphiClass := nil;
  if Assigned(AParent) then FParent := AParent else
    FParent := TSepiClass(Root.FindType(System.TypeInfo(TObject)));
  FCompleted := False;

  FVMTSize := Parent.VMTSize;
  FDMTNextIndex := Parent.FDMTNextIndex;
end;

{*
  D�truit l'instance
*}
destructor TSepiClass.Destroy;
var PTable : Pointer;
begin
  if (not Native) and (FDelphiClass <> nil) then
  begin
    // Destroying the DMT
    PTable := VMTEntries[vmtDynamicTable];
    FreeMem(PTable, 2 + 6*PWord(PTable)^);

    // Destroying the VMT
    PTable := Pointer(Integer(FDelphiClass) + vmtMinIndex);
    FreeMem(PTable, FVMTSize);
  end;

  inherited;
end;

{*
  Construit les RTTI
*}
procedure TSepiClass.MakeTypeInfo;
var OwningUnitName, PropName : ShortString;
    TypeDataLength, I : integer;
    Props : TObjectList;
    Prop : TSepiMetaProperty;
    PropCount : PWord;
    PropInfo : PPropInfo;
begin
  OwningUnitName := OwningUnit.Name;
  Props := TObjectList.Create(False);
  try
    TypeDataLength := ClassTypeDataLengthBase;
    inc(TypeDataLength, Length(OwningUnitName));
    inc(TypeDataLength);

    // Listing the published properties, and computing the type data length
    for I := 0 to ChildCount-1 do if Children[I] is TSepiMetaProperty then
    begin
      Prop := TSepiMetaProperty(Children[I]);
      if Prop.Visibility <> mvPublished then Continue;

      Props.Add(Prop);
      inc(TypeDataLength, PropInfoLengthBase);
      inc(TypeDataLength, Length(Prop.Name));
      inc(TypeDataLength);
    end;

    // Creating the RTTI
    AllocateTypeInfo(TypeDataLength);

    // Basic information
    TypeData.ClassType := DelphiClass;
    TypeData.ParentInfo := FParent.TypeInfoRef;
    TypeData.PropCount := Props.Count;
    Move(OwningUnitName[0], TypeData.UnitName[0], Length(OwningUnitName)+1);

    // Property count
    PropCount := SkipPackedShortString(@TypeData.UnitName);
    PropCount^ := Props.Count;

    // Property information
    PropInfo := PPropInfo(Integer(PropCount) + 2);
    for I := 0 to Props.Count-1 do
    begin
      Prop := TSepiMetaProperty(Props[I]);

      PropName := Prop.Name;
      Move(PropName[0], PropInfo.Name[0], Length(PropName)+1);

      PropInfo := SkipPackedShortString(@PropInfo.Name);
    end;
  finally
    Props.Free;
  end;
end;

{*
  Construit la DMT
  Range �galement l'adresse de la DMT � l'emplacement pr�vu de la VMT
*}
procedure TSepiClass.MakeDMT;
var PDMT : Pointer;
    I, Count : integer;
    IndexList, CodeList : integer;
    Methods : TObjectList;
begin
  Methods := TObjectList.Create(False);
  try
    // Listing dynamic methods
    for I := 0 to ChildCount-1 do if Children[I] is TSepiMetaMethod then
      Methods.Add(TSepiMetaMethod(Children[I]));
    Count := Methods.Count;

    // Creating the DMT
    GetMem(PDMT, 2 + 6*Count);
    VMTEntries[vmtDynamicTable] := PDMT;
    PWord(PDMT)^ := Count;
    IndexList := Integer(PDMT) + 2;
    CodeList := IndexList + 2*Count;

    // Filling the DMT
    for I := 0 to Count-1 do with TSepiMetaMethod(Methods[I]) do
    begin
      PWord(IndexList + 2*I)^ := DMTIndex;
      PPointer(CodeList + 4*I)^ := Code;
    end;
  finally
    Methods.Free;
  end;
end;

{*
  Construit la VMT
*}
procedure TSepiClass.MakeVMT;
var PVMT : Pointer;
    I : integer;
    Method : TSepiMetaMethod;
begin
  // Creating the VMT
  GetMem(PVMT, FVMTSize - vmtMinIndex);
  FillChar(PVMT^, FVMTSize - vmtMinIndex, 0);
  dec(integer(PVMT), vmtMinIndex);
  FDelphiClass := TClass(PVMT);

  // Creating the RTTI
  MakeTypeInfo;

  // Setting class properties
  FShortClassName := Name;

  if FVMTSize > 0 then
    VMTEntries[vmtSelfPtr] := PVMT
  else
    VMTEntries[vmtSelfPtr] := @TypeInfo.Name;

  VMTEntries[vmtClassName] := @TypeInfo.Name;
  VMTEntries[vmtParent] := Pointer(Parent.DelphiClass);

  // Copy the parent VMT
  Move(Pointer(Integer(Parent.DelphiClass) + vmtMinMethodIndex)^,
    Pointer(Integer(PVMT) + vmtMinMethodIndex)^,
    Parent.VMTSize - vmtMinMethodIndex);

  // Setting the new method addresses
  for I := 0 to ChildCount-1 do if Children[I] is TSepiMetaMethod then
  begin
    Method := TSepiMetaMethod(Children[I]);
    if Method.LinkKind = mlkVirtual then
      VMTEntries[Method.VMTOffset] := Method.Code;
  end;

  // Making the other tables
  MakeDMT;
end;

{*
  VMT de la classe, index�e par les constantes vmtXXX
  @param Index   Index dans la VMT
  @return Information contenue dans la VMT � l'index sp�cifi�
*}
function TSepiClass.GetVMTEntries(Index : integer) : Pointer;
begin
  Result := PPointer(Integer(FDelphiClass) + Index)^;
end;

{*
  Modifie la VMT de la classe, index�e par les constantes vmtXXX
  Cette m�thode ne fonctionne que pour des VMT cr��es par Sepi. Dans le cas o�
  la VMT serait cr��e � la compilation, cette m�thode provoquera une violation
  d'acc�s.
  @param Index   Index dans la VMT
  @param Value   Information � stocker dans la VMT � l'index sp�cifi�
*}
procedure TSepiClass.SetVMTEntries(Index : integer; Value : Pointer);
begin
  PPointer(Integer(FDelphiClass) + Index)^ := Value;
end;

{*
  [@inheritDoc]
*}
procedure TSepiClass.Loaded;
begin
  inherited;

  Complete;
end;

{*
  Termine la classe et construit ses RTTI si ce n'est pas d�j� fait
*}
procedure TSepiClass.Complete;
begin
  if FCompleted then exit;

  FCompleted := True;
  if not Native then
    MakeVMT;
end;

{*
  [@inheritDoc]
*}
function TSepiClass.CompatibleWith(AType : TSepiType) : boolean;
begin
  Result := (AType is TSepiClass) and
    TSepiClass(AType).ClassInheritsFrom(Self);
end;

{*
  D�termine si la classe h�rite d'une classe donn�e
  @param AParent   Anc�tre � tester
  @return True si la classe h�rite de AParent, False sinon
*}
function TSepiClass.ClassInheritsFrom(AParent : TSepiClass) : boolean;
begin
  Result := (AParent = Self) or
    (Assigned(FParent) and FParent.ClassInheritsFrom(AParent));
end;

{*
  Recherche un membre dans la classe, en tenant compte des visibilit�s
  @param MemberName   Nom du membre recherch�
  @param FromUnit     Unit� d'o� l'on cherche
  @param FromClass    Classe d'o� l'on cherche (ou nil si pas de classe)
  @return Le membre correspondant, ou nil si non trouv�
*}
function TSepiClass.LookForMember(const MemberName : string;
  FromUnit : TSepiMetaUnit; FromClass : TSepiClass = nil) : TSepiMeta;
begin
  Result := GetMeta(MemberName);

  if Result <> nil then
  begin
    case Result.Visibility of
      mvPrivate  : if FromClass <> Self then Result := nil;
      mvInternal : if FromUnit <> OwningUnit then Result := nil;
      mvProtected :
        if (FromClass = nil) or (not FromClass.ClassInheritsFrom(Self)) then
          Result := nil;
      mvInternalProtected :
        if (FromUnit <> OwningUnit) and
           ((FromClass = nil) or (not FromClass.ClassInheritsFrom(Self))) then
          Result := nil;
    end;
  end;

  if (Result = nil) and (Parent <> nil) then
    Result := Parent.LookForMember(MemberName, FromUnit, FromClass);
end;

{-----------------------}
{ Classe TSepiMetaClass }
{-----------------------}

{*
  Charge une classe depuis un flux
*}
constructor TSepiMetaClass.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;
  Stream.ReadBuffer(FClass, 4);
end;

{*
  Cr�e une nouvelle classe
  @param AOwner   Propri�taire du type
  @param AName    Nom du type
  @param AClass   Classe correspondante
*}
constructor TSepiMetaClass.Create(AOwner : TSepiMeta; const AName : string;
  AClass : TSepiClass);
begin
  inherited Create(AOwner, AName, tkClass);
  FClass := AClass;
end;

{*
  [@inheritDoc]
*}
procedure TSepiMetaClass.Loaded;
begin
  inherited;
  OwningUnit.LoadRef(FClass);
end;

{*
  [@inheritDoc]
*}
function TSepiMetaClass.CompatibleWith(AType : TSepiType) : boolean;
begin
  Result := (AType is TSepiMetaClass) and
    TSepiMetaClass(AType).SepiClass.ClassInheritsFrom(SepiClass);
end;

{---------------------------}
{ Classe TSepiMethodRefType }
{---------------------------}

{*
  Recense un type r�f�rence de m�thode natif
*}
constructor TSepiMethodRefType.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited;
  FSignature := TSepiMethodSignature.RegisterTypeData(Self, TypeData);
end;

{*
  Charge un type r�f�rence de m�thode depuis un flux
*}
constructor TSepiMethodRefType.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;
  FSignature := TSepiMethodSignature.Load(Self, Stream);
end;

{*
  Cr�e un nouveau type r�f�rence de m�thode
  @param AOwner            Propri�taire du type
  @param AName             Nom du type
  @param ASignature        Signature
  @param AOfObject         Indique s'il s'agit d'une m�thode
  @param ACallConvention   Convention d'appel
*}
constructor TSepiMethodRefType.Create(AOwner : TSepiMeta;
  const AName, ASignature : string; AOfObject : boolean = False;
  ACallConvention : TCallConvention = ccRegister);
var Prefix : string;
begin
  inherited Create(AOwner, AName, tkMethod);

  if AOfObject then Prefix := '' else Prefix := 'unit ';
  FSignature := TSepiMethodSignature.Create(Self,
    Prefix + ASignature, ACallConvention);
end;

{*
  D�truit l'instance
*}
destructor TSepiMethodRefType.Destroy;
begin
  FSignature.Free;
  inherited Destroy;
end;

{*
  [@inheritDoc]
*}
function TSepiMethodRefType.CompatibleWith(AType : TSepiType) : boolean;
begin
  Result := (AType.Kind = tkMethod) and
    FSignature.Equals(TSepiMethodRefType(AType).FSignature);
end;

initialization
  SepiRegisterMetaClasses([
    TSepiMetaField, TSepiMetaParam, TSepiMetaMethod, TSepiMetaOverloadedMethod,
    TSepiMetaProperty, TSepiRecordType, TSepiInterface, TSepiClass,
    TSepiMethodRefType
  ]);
end.

