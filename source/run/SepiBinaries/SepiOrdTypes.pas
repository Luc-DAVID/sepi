{*
  D�finit les classes de gestion des types ordinaux
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit SepiOrdTypes;

interface

uses
  Classes, SysUtils, ScUtils, SepiMetaUnits, SysConst, TypInfo, ScLists;

const
  MinInt64 = Int64($FFFFFFFFFFFFFFFF);
  MaxInt64 = Int64($7FFFFFFFFFFFFFFF);

  otUnknown = TOrdType(-1);

type
  {*
    Type de bool�en
  *}
  TBooleanKind = (bkBoolean, bkByteBool, bkWordBool, bkLongBool);

  {*
    Pointeur sur ShortString
  *}
  PShortString = ^ShortString;

  TSepiOrdType = class(TSepiType)
  private
    FMinValue : Longint; /// Valeur minimale
    FMaxValue : Longint; /// Valeur maximale
  protected
    procedure ExtractTypeData; override;
  public
    property MinValue : Longint read FMinValue;
    property MaxValue : Longint read FMaxValue;
  end;

  {*
    Type entier
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiIntegerType = class(TSepiOrdType)
  private
    FSigned : boolean;         /// Indique si l'entier est sign� ou non
    FNeedRangeCheck : boolean; /// Indique s'il faut v�rifier les �tendues
  protected
    procedure ExtractTypeData; override;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AMinValue : Longint = -MaxInt-1; AMaxValue : Longint = MaxInt;
      ASigned : boolean = True);

    function InRange(Value : Longint) : boolean;
    procedure CheckInRange(Value : Longint);

    property Signed : boolean read FSigned;
    property NeedRangeCheck : boolean read FNeedRangeCheck;
  end;

  {*
    Type caract�re
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiCharType = class(TSepiOrdType)
  private
    FIsUnicode : boolean;      /// Indique si le caract�re est Unicode
    FChrMinValue : WideChar;      /// Valeur minimale
    FChrMaxValue : WideChar;      /// Valeur maximale
    FNeedRangeCheck : boolean; /// Indique s'il faut v�rifier les �tendues
  protected
    procedure ExtractTypeData; override;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AMinValue : WideChar = #0; AMaxValue : WideChar = #255;
      AForceUnicode : boolean = False);

    function InRange(Value : WideChar) : boolean;
    procedure CheckInRange(Value : WideChar);

    property IsUnicode : boolean read FIsUnicode;
    property ChrMinValue : WideChar read FChrMinValue;
    property ChrMaxValue : WideChar read FChrMaxValue;
    property NeedRangeCheck : boolean read FNeedRangeCheck;
  end;

  {*
    Type entier long (64 bits)
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiInt64Type = class(TSepiType)
  private
    FMinValue : Int64;         /// Valeur minimale
    FMaxValue : Int64;         /// Valeur maximale
    FNeedRangeCheck : boolean; /// Indique s'il faut v�rifier les �tendues
  protected
    procedure ExtractTypeData; override;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AMinValue : Int64 = MinInt64; AMaxValue : Int64 = MaxInt64);

    function InRange(Value : Int64) : boolean;
    procedure CheckInRange(Value : Int64);

    property MinValue : Int64 read FMinValue;
    property MaxValue : Int64 read FMaxValue;
    property NeedRangeCheck : boolean read FNeedRangeCheck;
  end;

  {*
    Type nombre � virgule flottante
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiFloatType = class(TSepiType)
  private
    FFloatType : TFloatType; /// Type de flottant
  protected
    procedure ExtractTypeData; override;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      AFloatType : TFloatType = ftDouble);

    property FloatType : TFloatType read FFloatType;
  end;

  {*
    Type bool�en
    Note : il est impossible de cr�er un nouveau type bool�en.
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiBooleanType = class(TSepiOrdType)
  private
    FBooleanKind : TBooleanKind;
  protected
    procedure ExtractTypeData; override;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;

    property BooleanKind : TBooleanKind read FBooleanKind;
  end;

  {*
    Type �num�ration
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiEnumType = class(TSepiOrdType)
  private
    FBaseType : TSepiEnumType;       /// Type de base (peut �tre Self)
    FBaseTypeInfo : PTypeInfo;       /// TypeInfo du type de base
    FValueCount : integer;           /// Nombre de valeurs
    FValues : array of PShortString; /// Noms des valeurs

    function GetNames(Value : integer) : string;
    function GetValues(const Name : string) : integer;
  protected
    procedure Loaded; override;

    procedure ExtractTypeData; override;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      const AValues : array of string);

    function CompatibleWith(AType : TSepiType) : boolean; override;

    property BaseType : TSepiEnumType read FBaseType;
    property ValueCount : integer read FValueCount;
    property Names[Value : integer] : string read GetNames;
    property Values[const Name : string] : integer read GetValues;
  end;

  {*
    Type ensemble
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSepiSetType = class(TSepiType)
  private
    FCompType : TSepiOrdType;  /// Type des �l�ments
    FCompTypeInfo : PTypeInfo; /// TypeInfo du type des �l�ments
  protected
    procedure Loaded; override;

    procedure ExtractTypeData; override;
  public
    constructor RegisterTypeInfo(AOwner : TSepiMeta;
      ATypeInfo : PTypeInfo); override;
    constructor Load(AOwner : TSepiMeta; Stream : TStream); override;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      ACompType : TSepiOrdType); overload;
    constructor Create(AOwner : TSepiMeta; const AName : string;
      ACompType : PTypeInfo); overload;

    function CompatibleWith(AType : TSepiType) : boolean; override;

    property CompType : TSepiOrdType read FCompType;
  end;

implementation

const
  // Tailles de structure TTypeData en fonction des types
  IntegerTypeDataLength = sizeof(TOrdType) + 2*sizeof(Longint);
  CharTypeDataLength = IntegerTypeDataLength;
  Int64TypeDataLength = 2*sizeof(Int64);
  FloatTypeDataLength = sizeof(TFloatType);
  EnumTypeDataLength = sizeof(TOrdType) + 2*sizeof(Longint) + sizeof(Pointer);
  SetTypeDataLength = sizeof(TOrdType) + sizeof(Pointer);

{---------------------}
{ Classe TSepiOrdType }
{---------------------}

{*
  [@inheritDoc]
*}
procedure TSepiOrdType.ExtractTypeData;
begin
  inherited;

  case TypeData.OrdType of
    otSByte, otUByte : FSize := 1;
    otSWord, otUWord : FSize := 2;
    otSLong, otULong : FSize := 4;
  end;

  FMinValue := TypeData.MinValue;
  FMaxValue := TypeData.MaxValue;
end;

{-------------------------}
{ Classe TSepiIntegerType }
{-------------------------}

{*
  Recense un type entier natif
*}
constructor TSepiIntegerType.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited;
  ExtractTypeData;
end;

{*
  Charge un type entier depuis un flux
*}
constructor TSepiIntegerType.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  AllocateTypeInfo(IntegerTypeDataLength);
  Stream.ReadBuffer(TypeData^, IntegerTypeDataLength);

  ExtractTypeData;
end;

{*
  Cr�e un nouveau type entier
  @param AOwner      Propri�taire du type
  @param AName       Nom du type
  @param AMinValue   Valeur minimale
  @param AMaxValue   Valeur maximale
  @param ASigned     Indique si l'entier est sign� ou non
*}
constructor TSepiIntegerType.Create(AOwner : TSepiMeta; const AName : string;
  AMinValue : Longint = -MaxInt-1; AMaxValue : Longint = MaxInt;
  ASigned : boolean = True);
begin
  inherited Create(AOwner, AName, tkInteger);

  AllocateTypeInfo(IntegerTypeDataLength);

  if AMinValue < 0 then
  begin
    // Signed
    if (AMinValue < -32768) or (AMaxValue >= 32768) then
      TypeData.OrdType := otSLong else
    if (AMinValue < -128) or (AMaxValue >= 128) then
      TypeData.OrdType := otSWord else
    TypeData.OrdType := otSByte;
  end else
  begin
    // Unsigned
    if AMaxValue >= 65536 then
      TypeData.OrdType := otULong else
    if AMaxValue >= 256 then
      TypeData.OrdType := otUWord else
    TypeData.OrdType := otUByte;
  end;

  TypeData.MinValue := AMinValue;
  TypeData.MaxValue := AMaxValue;

  ExtractTypeData;
end;

{*
  [@inheritDoc]
*}
procedure TSepiIntegerType.ExtractTypeData;
begin
  inherited;

  FSigned := TypeData.OrdType in [otSByte, otSWord, otSLong];
  FNeedRangeCheck := (FMinValue <> -MaxInt - 1) or (FMaxValue <> MaxInt);
end;

{*
  Teste si une valeur est dans l'intervalle support� par le type
  @param Value   Valeur � tester
  @return True si Value est dans l'intervalle support�, False sinon
*}
function TSepiIntegerType.InRange(Value : Longint) : boolean;
begin
  Result := (Value >= FMinValue) and (Value <= FMaxValue);
end;

{*
  S'assure qu'une valeur est dans l'intervalle support� par le type
  @param Value   Valeur � tester
  @throws ERangeError Value n'�tait pas dans l'intervalle support�
*}
procedure TSepiIntegerType.CheckInRange(Value : Longint);
begin
  if not InRange(Value) then
    raise ERangeError.CreateRes(@SRangeError);
end;

{----------------------}
{ Classe TSepiCharType }
{----------------------}

{*
  Recense un type caract�re natif
*}
constructor TSepiCharType.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited;
  ExtractTypeData;
end;

{*
  Charge un type caract�re depuis un flux
*}
constructor TSepiCharType.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  AllocateTypeInfo(CharTypeDataLength);
  Stream.ReadBuffer(TypeData^, CharTypeDataLength);

  ExtractTypeData;
end;

{*
  Cr�e un nouveau type caract�re
  @param AOwner          Propri�taire du type
  @param AName           Nom du type
  @param AMinValue       Valeur minimale
  @param AMaxValue       Valeur maximale
  @param AForceUnicode   Positionn� � True, force l'utilisation d'Unicode
*}
constructor TSepiCharType.Create(AOwner : TSepiMeta; const AName : string;
  AMinValue : WideChar = #0; AMaxValue : WideChar = #255;
  AForceUnicode : boolean = False);
var AKind : TTypeKind;
begin
  if AForceUnicode or (AMaxValue > #255) then
    AKind := tkWChar
  else
    AKind := tkChar;
  inherited Create(AOwner, AName, AKind);

  AllocateTypeInfo(IntegerTypeDataLength);

  if Kind = tkWChar then
    TypeData.OrdType := otUWord
  else
    TypeData.OrdType := otUByte;

  TypeData.MinValue := Longint(AMinValue);
  TypeData.MaxValue := Longint(AMaxValue);

  ExtractTypeData;
end;

{*
  [@inheritedDoc]
*}
procedure TSepiCharType.ExtractTypeData;
begin
  inherited;

  FIsUnicode := Kind = tkWChar;
  FChrMinValue := WideChar(MinValue);
  FChrMaxValue := WideChar(MaxValue);

  if FIsUnicode then
    FNeedRangeCheck := (FChrMinValue <> #0) or (FChrMaxValue <> #65535)
  else
    FNeedRangeCheck := (FChrMinValue <> #0) or (FChrMaxValue <> #255);
end;

{*
  Teste si une valeur est dans l'intervalle support� par le type
  @param Value   Valeur � tester
  @return True si Value est dans l'intervalle support�, False sinon
*}
function TSepiCharType.InRange(Value : WideChar) : boolean;
begin
  Result := (Value >= FChrMinValue) and (Value <= FChrMaxValue);
end;

{*
  S'assure qu'une valeur est dans l'intervalle support� par le type
  @param Value   Valeur � tester
  @throws ERangeError Value n'�tait pas dans l'intervalle support�
*}
procedure TSepiCharType.CheckInRange(Value : WideChar);
begin
  if not InRange(Value) then
    raise ERangeError.CreateRes(@SRangeError);
end;

{-----------------------}
{ Classe TSepiInt64Type }
{-----------------------}

{*
  Recense un type entier 64 bits natif
*}
constructor TSepiInt64Type.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited;
  ExtractTypeData;
end;

{*
  Charge un type entier 64 bits depuis un flux
*}
constructor TSepiInt64Type.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  AllocateTypeInfo(Int64TypeDataLength);
  Stream.ReadBuffer(TypeData^, Int64TypeDataLength);

  ExtractTypeData;
end;

{*
  Cr�e un nouveau type entier 64 bits
  @param AOwner      Propri�taire du type
  @param AName       Nom du type
  @param AMinValue   Valeur minimale
  @param AMaxValue   Valeur maximale
*}
constructor TSepiInt64Type.Create(AOwner : TSepiMeta; const AName : string;
  AMinValue : Int64 = MinInt64; AMaxValue : Int64 = MaxInt64);
begin
  inherited Create(AOwner, AName, tkInt64);

  AllocateTypeInfo(Int64TypeDataLength);

  TypeData.MinValue := AMinValue;
  TypeData.MaxValue := AMaxValue;

  ExtractTypeData;
end;

{*
  [@inheritedDoc]
*}
procedure TSepiInt64Type.ExtractTypeData;
begin
  inherited;

  FSize := 8;
  FMinValue := TypeData.MinInt64Value;
  FMaxValue := TypeData.MaxInt64Value;

  FNeedRangeCheck := (FMinValue <> MinInt64) or (FMaxValue <> MaxInt64);
end;

{*
  Teste si une valeur est dans l'intervalle support� par le type
  @param Value   Valeur � tester
  @return True si Value est dans l'intervalle support�, False sinon
*}
function TSepiInt64Type.InRange(Value : Int64) : boolean;
begin
  Result := (Value >= FMinValue) and (Value <= FMaxValue);
end;

{*
  S'assure qu'une valeur est dans l'intervalle support� par le type
  @param Value   Valeur � tester
  @throws ERangeError Value n'�tait pas dans l'intervalle support�
*}
procedure TSepiInt64Type.CheckInRange(Value : Int64);
begin
  if not InRange(Value) then
    raise ERangeError.CreateRes(@SRangeError);
end;

{-----------------------}
{ Classe TSepiFloatType }
{-----------------------}

{*
  Recense un type flottant natif
*}
constructor TSepiFloatType.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited;
  ExtractTypeData;
end;

{*
  Charge un type flottant depuis un flux
*}
constructor TSepiFloatType.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  AllocateTypeInfo(FloatTypeDataLength);
  Stream.ReadBuffer(TypeData^, FloatTypeDataLength);

  ExtractTypeData;
end;

{*
  Cr�e un nouveau type flottant
  @param AOwner       Propri�taire du type
  @param AName        Nom du type
  @param AFloatType   Type de flottant
*}
constructor TSepiFloatType.Create(AOwner : TSepiMeta; const AName : string;
  AFloatType : TFloatType = ftDouble);
begin
  inherited Create(AOwner, AName, tkFloat);

  AllocateTypeInfo(FloatTypeDataLength);
  TypeData.FloatType := AFloatType;

  ExtractTypeData;
end;

{*
  [@inheritedDoc]
*}
procedure TSepiFloatType.ExtractTypeData;
begin
  inherited;

  FFloatType := TypeData.FloatType;

  case FFloatType of
    ftSingle : FSize := 4;
    ftDouble, ftComp, ftCurr : FSize := 8;
    ftExtended : FSize := 10;
  end;
end;

{-------------------------}
{ Classe TSepiBooleanType }
{-------------------------}

{*
  Recense un type bool�en natif
*}
constructor TSepiBooleanType.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited;
  ExtractTypeData;
end;

{*
  Charge un type bool�en depuis un flux
*}
constructor TSepiBooleanType.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  AllocateTypeInfo(EnumTypeDataLength);
  Stream.ReadBuffer(TypeData^, EnumTypeDataLength);

  ExtractTypeData;
end;

{*
  [@inheritedDoc]
*}
procedure TSepiBooleanType.ExtractTypeData;
begin
  inherited;

  case TypeData.OrdType of
    otSByte : FBooleanKind := bkByteBool;
    otSWord : FBooleanKind := bkWordBool;
    otSLong : FBooleanKind := bkLongBool;
    else FBooleanKind := bkBoolean;
  end;
end;

{----------------------}
{ Classe TSepiEnumType }
{----------------------}

{*
  Recense un type �num�r� natif
*}
constructor TSepiEnumType.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited;
  ExtractTypeData;
end;

{*
  Charge un type �num�r� depuis un flux
*}
constructor TSepiEnumType.Load(AOwner : TSepiMeta; Stream : TStream);
var TypeDataLength : integer;
begin
  inherited;

  Stream.ReadBuffer(TypeDataLength, 4);
  AllocateTypeInfo(TypeDataLength);
  Stream.ReadBuffer(TypeData^, TypeDataLength);
end;

{*
  Cr�e un nouveau type �num�r�
  @param AOwner    Propri�taire du type
  @param AName     Nom du type
  @param AValues   Noms des �l�ments de l'�num�ration
*}
constructor TSepiEnumType.Create(AOwner : TSepiMeta; const AName : string;
  const AValues : array of string);
var TypeDataLength, I, Len : integer;
    Current : PChar;
    OwningUnitName : ShortString;
begin
  inherited Create(AOwner, AName, tkEnumeration);

  // Calcul de la taille des donn�es de type et allocation de celles-ci
  TypeDataLength := EnumTypeDataLength;
  for I := Low(AValues) to High(AValues) do
    inc(TypeDataLength, Length(AValues[I]));
  inc(TypeDataLength, Length(AValues)); // Longueurs des cha�nes
  inc(TypeDataLength, Length(OwningUnit.Name)+1);
  AllocateTypeInfo(TypeDataLength);

  // Initialisation des variables priv�es
  FBaseTypeInfo := TypeInfo;
  FValueCount := Length(AValues);
  SetLength(FValues, ValueCount);

  // Initialisation des informations scalaires des donn�es de type
  TypeData.OrdType := otUByte;
  TypeData.MinValue := 0;
  TypeData.MaxValue := ValueCount-1;
  TypeData.BaseType := @FBaseTypeInfo;
  inherited ExtractTypeData;

  // Enregistrement des noms d'�num�ration dans les donn�es de type
  Current := @TypeData.NameList;
  for I := 0 to ValueCount-1 do
  begin
    Len := Length(AValues[Low(AValues)+I]);

    // Enregistrement de l'adresse dans le tableau FValues
    FValues[I] := PShortString(Current);

    // Recopie du nom dans les donn�es de type
    Current[0] := Chr(Len);
    inc(Current);
    Move(AValues[Low(AValues)+I][1], Current^, Len);

    // Passage � l'�l�ment suivant
    inc(Current, Len);
  end;

  // Enregistrement du nom de l'unit� dans les donn�es de type
  OwningUnitName := OwningUnit.Name;
  Move(OwningUnitName[0], Current[0], Length(OwningUnitName)+1);
end;

{*
  Tableau des noms par leurs valeurs
  @param Value   Valeur d'�l�ment d'�num�ration
  @return Nom de la valeur Value
*}
function TSepiEnumType.GetNames(Value : integer) : string;
begin
  Result := BaseType.FValues[Value]^;
end;

{*
  Tableau des valeurs par leurs noms
  @param Name   Nom d'�l�ment d'�num�ration
  @return Valeur du nom donn�
*}
function TSepiEnumType.GetValues(const Name : string) : integer;
begin
  Result := GetEnumValue(TypeInfo, Name);
end;

{*
  [@inheritDoc]
*}
procedure TSepiEnumType.Loaded;
begin
  inherited;

  FBaseType := TSepiEnumType(TypeData.BaseType);
  OwningUnit.LoadRef(FBaseType);
  FBaseTypeInfo := FBaseType.FBaseTypeInfo;
  TypeData.BaseType := @FBaseTypeInfo;

  ExtractTypeData;
end;

{*
  [@inheritedDoc]
*}
procedure TSepiEnumType.ExtractTypeData;
var Current : PShortString;
    I : integer;
begin
  inherited;

  FBaseTypeInfo := TypeData.BaseType^;

  if FBaseTypeInfo = TypeInfo then
  begin
    FBaseType := Self;
    FValueCount := MaxValue+1;

    // Mise au point du tableau des r�f�rences vers les noms
    SetLength(FValues, ValueCount);
    Current := @TypeData.NameList;
    for I := 0 to ValueCount-1 do
    begin
      FValues[I] := Current;
      inc(Current, Length(Current^)+1);
    end;
  end else
  begin
    FBaseType := Root.FindTypeByTypeInfo(FBaseTypeInfo) as TSepiEnumType;
    FValueCount := BaseType.ValueCount;
  end;
end;

{*
  [@inheritDoc]
*}
function TSepiEnumType.CompatibleWith(AType : TSepiType) : boolean;
begin
  Result := (AType is TSepiEnumType) and
    (BaseType = TSepiEnumType(AType).BaseType);
end;

{---------------------}
{ Classe TSepiSetType }
{---------------------}

{*
  Recense un type ensemble natif
*}
constructor TSepiSetType.RegisterTypeInfo(AOwner : TSepiMeta;
  ATypeInfo : PTypeInfo);
begin
  inherited;

  FCompTypeInfo := TypeData.CompType^;
  FCompType := Root.FindTypeByTypeInfo(FCompTypeInfo) as TSepiOrdType;

  ExtractTypeData;
end;

{*
  Charge un type ensemble depuis un flux
*}
constructor TSepiSetType.Load(AOwner : TSepiMeta; Stream : TStream);
begin
  inherited;

  AllocateTypeInfo(SetTypeDataLength);
  Stream.ReadBuffer(TypeData^, SetTypeDataLength);
end;

{*
  Cr�e un nouveau type ensemble
  @param AOwner      Propri�taire du type
  @param AName       Nom du type
  @param ACompType   Type des �l�ments de l'ensemble
*}
constructor TSepiSetType.Create(AOwner : TSepiMeta; const AName : string;
  ACompType : TSepiOrdType);
begin
  inherited Create(AOwner, AName, tkSet);

  FCompType := ACompType;
  FCompTypeInfo := FCompType.TypeInfo;

  AllocateTypeInfo(SetTypeDataLength);

  case CompType.MaxValue - CompType.MinValue + 1 of
    1..8   : TypeData.OrdType := otUByte;
    9..16  : TypeData.OrdType := otUWord;
    17..32 : TypeData.OrdType := otULong;
    else TypeData.OrdType := otUnknown;
  end;

  TypeData.CompType := @FCompType;

  ExtractTypeData;
end;

{*
  Cr�e un nouveau type ensemble
  @param AOwner      Propri�taire du type
  @param AName       Nom du type
  @param ACompType   RTTI du type des �l�ments de l'ensemble
*}
constructor TSepiSetType.Create(AOwner : TSepiMeta; const AName : string;
  ACompType : PTypeInfo);
begin
  Create(AOwner, AName,
    AOwner.Root.FindTypeByTypeInfo(ACompType) as TSepiOrdType);
end;

{*
  [@inheritDoc]
*}
procedure TSepiSetType.Loaded;
begin
  inherited;

  OwningUnit.LoadRef(FCompType);
  FCompTypeInfo := FCompType.TypeInfo;
  TypeData.CompType := @FCompTypeInfo;

  ExtractTypeData;
end;

{*
  [@inheritedDoc]
*}
procedure TSepiSetType.ExtractTypeData;
begin
  inherited;

  if FSize = 0 then
    FSize := (FCompType.MaxValue - FCompType.MinValue + 1) div 8;
end;

{*
  [@inheritDoc]
*}
function TSepiSetType.CompatibleWith(AType : TSepiType) : boolean;
begin
  Result := (AType.Kind = tkSet) and
    FCompType.CompatibleWith(TSepiSetType(AType).FCompType);
end;

initialization
  SepiRegisterMetaClasses([
    TSepiIntegerType, TSepiCharType, TSepiInt64Type, TSepiFloatType,
    TSepiBooleanType, TSepiEnumType, TSepiSetType
  ]);
end.

