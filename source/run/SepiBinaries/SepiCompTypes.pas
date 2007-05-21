{*
  D�finit les classes de gestion des types composites
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit SepiCompTypes;

interface

uses
  Classes, SysUtils, ScUtils, SepiMetaUnits, SepiMetaMembers, SysConst, TypInfo,
  ScLists;

type
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
    FParentInfo : PTypeInfo;  /// RTTI de l'interface parent (ou nil)
    FCompleted : boolean;     /// Indique si l'interface est enti�rement d�finie
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AParent : TSepiInterface);

    property Parent : TSepiInterface read FParent;
    property Completed : boolean read FCompleted;
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
    FParentInfo : PTypeInfo; /// RTTI de la classe parent (nil si n'existe pas)
    FCompleted : boolean;    /// Indique si la classe est enti�rement d�finie

    FOwnVMT : boolean;  /// Indique si la VMT a �t� cr��e par Sepi
    FVMTSize : integer; /// Taille de la VMT dans les index positifs

    procedure PrepareVMT;

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

    procedure Complete;

    function CompatibleWith(AType : TSepiType) : boolean; override;
    function InheritsFrom(AParent : TSepiClass) : boolean;

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

implementation

const
  // Tailles de structure TTypeData en fonction des types
  RecordTypeDataLength = 0;
  ClassTypeDataLengthBase = sizeof(TClass) + sizeof(Pointer) + sizeof(SmallInt);
  IntfTypeDataLengthBase =
    sizeof(Pointer) + sizeof(TIntfFlagsBase) + sizeof(TGUID);

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
begin
  inherited;

  FSize := 4;
  FParentInfo := TypeData.ParentInfo^;
  if Assigned(FParentInfo) then
    FParent := TSepiInterface(Root.FindType(FParentInfo))
  else
    FParent := nil; // This is IInterface
  FCompleted := False;
end;

{*
  Charge une interface depuis un flux
*}
constructor TSepiInterface.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  FSize := 4;
  FParent := TSepiInterface(Root.FindMeta(ReadStrFromStream(Stream)));
  FParentInfo := Parent.TypeInfo;
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
  AParent : TSepiInterface);
begin
  inherited Create(AOwner, AName, tkInterface);

  FSize := 4;
  if Assigned(AParent) then FParent := AParent else
    FParent := TSepiInterface(Root.FindType(System.TypeInfo(IInterface)));
  FParentInfo := Parent.TypeInfo;
  FCompleted := False;
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
  FParentInfo := TypeData.ParentInfo^;
  if Assigned(FParentInfo) then
  begin
    FParent := TSepiClass(Root.FindType(FParentInfo));
    FVMTSize := Parent.VMTSize;
  end else
  begin
    // This is TObject
    FParent := nil;
    FVMTSize := vmtParent + 4; // vmtParent is the last non-method VMT entry
  end;
  FCompleted := False;

  FOwnVMT := False;
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
  FParentInfo := Parent.TypeInfo;
  FCompleted := False;

  FOwnVMT := True;
  FVMTSize := Parent.VMTSize;

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
  FParentInfo := Parent.TypeInfo;
  FCompleted := False;

  FOwnVMT := True;
  FVMTSize := Parent.VMTSize;
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
  D�termine la taille de la VMT et de ses composantes et les alloue si besoin
*}
procedure TSepiClass.PrepareVMT;
var I : integer;
    Child : TSepiMeta;
    Method : TSepiMetaMethod;
begin
  for I := 0 to ChildCount-1 do
  begin
    Child := Children[I];
    if Child is TSepiMetaMethod then
    begin
      Method := TSepiMetaMethod(Child);
      if (Method.LinkKind = mlkVirtual) and (Method.InheritedMethod = nil) then
        inc(FVMTSize, 4);
    end;
  end;
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
  Termine la classe et construit ses RTTI si ce n'est pas d�j� fait
*}
procedure TSepiClass.Complete;
begin
  FCompleted := True;
  if Assigned(TypeInfo) then exit;

  PrepareVMT;
end;

{*
  [@inheritDoc]
*}
function TSepiClass.CompatibleWith(AType : TSepiType) : boolean;
begin
  Result := (AType is TSepiClass) and
    TSepiClass(AType).InheritsFrom(Self);
end;

{*
  D�termine si la classe h�rite d'une classe donn�e
  @param AParent   Anc�tre � tester
  @return True si la classe h�rite de AParent, False sinon
*}
function TSepiClass.InheritsFrom(AParent : TSepiClass) : boolean;
begin
  Result := (AParent = Self) or
    (Assigned(FParent) and FParent.InheritsFrom(AParent));
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
        if (FromClass = nil) or (not FromClass.InheritsFrom(Self)) then
          Result := nil;
      mvInternalProtected :
        if (FromUnit <> OwningUnit) and
           ((FromClass = nil) or (not FromClass.InheritsFrom(Self))) then
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
    TSepiMetaClass(AType).SepiClass.InheritsFrom(SepiClass);
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
    TSepiRecordType, TSepiClass, TSepiMethodRefType
  ]);
end.

