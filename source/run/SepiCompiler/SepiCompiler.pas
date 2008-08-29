{-------------------------------------------------------------------------------
Sepi - Object-oriented script engine for Delphi
Copyright (C) 2006-2007  S�bastien Doeraene
All Rights Reserved

This file is part of Sepi.

Sepi is free software: you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

Sepi is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
Sepi.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------}

{*
  Compilateur Sepi
  @author sjrd
  @version 1.0
*}
unit SepiCompiler;

interface

uses
  Windows, SysUtils, Classes, Contnrs, TypInfo, ScUtils, ScTypInfo,
  ScIntegerSets, ScInterfaces, SepiReflectionCore, SepiMembers, SepiOpCodes,
  SepiReflectionConsts, SepiCompilerErrors, SepiCompilerConsts;

type
  TSepiAsmInstrList = class;
  TSepiInstructionList = class;
  TSepiMethodCompiler = class;
  TSepiUnitCompiler = class;
  TSepiMemoryReference = class;

  {*
    Erreur de compilation Sepi
  *}
  ESepiCompilerError = class(Exception);

  {*
    Label non trouv� lors de la compilation Sepi
  *}
  ESepiLabelError = class(ESepiCompilerError);

  {*
    Erreur de r�f�rence m�moire
  *}
  ESepiMemoryReferenceError = class(ESepiCompilerError);

  {*
    R�f�rence m�moire scell�e
  *}
  ESepiSealedMemoryReference = class(ESepiMemoryReferenceError);

  {*
    R�f�rence m�moire invalide d'apr�s l'instruction contenante
  *}
  ESepiInvalidMemoryReference = class(ESepiMemoryReferenceError);

  {*
    Destination de JUMP invalide
  *}
  ESepiInvalidJumpDest = class(ESepiCompilerError);

  {*
    R�f�rence � une instruction
    @author sjrd
    @version 1.0
  *}
  TSepiInstructionRef = class(TObject)
  private
    FMethodCompiler: TSepiMethodCompiler; /// Compilateur

    FInstructionIndex: Integer; /// Position de l'instruction r�f�renc�e

    procedure SetInstructionIndex(Value: Integer);

    function GetPosition: Integer;
  public
    constructor Create(AMethodCompiler: TSepiMethodCompiler);

    property MethodCompiler: TSepiMethodCompiler read FMethodCompiler;
    property InstructionIndex: Integer read FInstructionIndex;
    property Position: Integer read GetPosition;
  end;

  {*
    Instruction Sepi
    Les instructions Sepi sont toujours rattach�es � un assembleur de m�thodes.
    Lorsque l'assembleur de m�thodes est lib�r�s, toutes les instructions qui
    lui ont �t� rattach�es sont lib�r�es elles aussi. Ne lib�rez donc pas
    manuellement une instruction Sepi.
    @author sjrd
    @version 1.0
  *}
  TSepiInstruction = class(TObject)
  private
    FMethodCompiler: TSepiMethodCompiler; /// Compilateur
    FUnitCompiler: TSepiUnitCompiler;     /// Compilateur d'unit�

    FSourcePos: TSepiSourcePosition; /// Position dans le source

    FBeforeRef: TSepiInstructionRef; /// R�f�rence avant cette instruction
    FAfterRef: TSepiInstructionRef;  /// R�f�rence apr�s cette instruction
  protected
    procedure CustomCompile; virtual;
  public
    constructor Create(AMethodCompiler: TSepiMethodCompiler);
    destructor Destroy; override;

    procedure AfterConstruction; override;

    procedure MakeError(const Msg: string; Kind: TSepiErrorKind = ekError);

    procedure Compile;

    property MethodCompiler: TSepiMethodCompiler read FMethodCompiler;
    property UnitCompiler: TSepiUnitCompiler read FUnitCompiler;

    property SourcePos: TSepiSourcePosition read FSourcePos write FSourcePos;

    property BeforeRef: TSepiInstructionRef read FBeforeRef;
    property AfterRef: TSepiInstructionRef read FAfterRef;
  end;

  {*
    Instruction d'assemblage Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiAsmInstr = class(TSepiInstruction)
  private
    FPosition: Integer; /// Position de l'instruction
  protected
    FOpCode: TSepiOpCode; /// OpCode
    FSize: Integer;       /// Taille

    procedure CustomCompile; override;

    function GetEndPosition: Integer; virtual;
  public
    constructor Create(AMethodCompiler: TSepiMethodCompiler);

    procedure Make; virtual;
    procedure ComputeActualSize; virtual;
    procedure SetPosition(Value: Integer); virtual;
    procedure WriteToStream(Stream: TStream); virtual;

    property Position: Integer read FPosition;
    property OpCode: TSepiOpCode read FOpCode;
    property Size: Integer read FSize;
    property EndPosition: Integer read GetEndPosition;
  end;

  {*
    Liste d'instructions Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiInstructionList = class(TSepiInstruction)
  private
    FInstructions: TObjectList; /// Instructions

    function GetCount: Integer;
    function GetInstructions(Index: Integer): TSepiInstruction;
  protected
    procedure CustomCompile; override;
  public
    constructor Create(AMethodCompiler: TSepiMethodCompiler);
    destructor Destroy; override;

    function Add(Instruction: TSepiInstruction): Integer;
    procedure Insert(Index: Integer; Instruction: TSepiInstruction);

    property Count: Integer read GetCount;
    property Instructions[Index: Integer]: TSepiInstruction
      read GetInstructions; default;
  end;

  {*
    Liste d'instructions assembleur Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiAsmInstrList = class(TObject)
  private
    FMethodCompiler: TSepiMethodCompiler; /// Compilateur

    FInstructions: TObjectList; /// Instructions

    FSize: Integer; /// Taille

    procedure Make;
    procedure ComputeActualSize;
    procedure SetPositions;

    function GetCount: Integer;
    function GetInstructions(Index: Integer): TSepiAsmInstr;
  protected
    procedure Add(Instruction: TSepiAsmInstr);

    property CurrentPos: Integer read GetCount;
  public
    constructor Create(AMethodCompiler: TSepiMethodCompiler);
    destructor Destroy; override;

    procedure Clear;

    procedure Assemble;
    procedure WriteToStream(Stream: TStream);

    property MethodCompiler: TSepiMethodCompiler read FMethodCompiler;

    property Count: Integer read GetCount;
    property Instructions[Index: Integer]: TSepiAsmInstr
      read GetInstructions; default;

    property Size: Integer read FSize;
  end;

  {*
    Pseudo-instruction label nomm�
    @author sjrd
    @version 1.0
  *}
  TSepiNamedLabel = class(TSepiInstruction)
  private
    FName: string;
  protected
    procedure CustomCompile; override;
  public
    constructor Create(AMethodCompiler: TSepiMethodCompiler;
      const AName: string);

    procedure AfterConstruction; override;

    property Name: string read FName;
  end;

  {*
    Vie d'une variable locale
    @author sjrd
    @version 1.0
  *}
  TSepiLocalVarLife = class(TScIntegerSet)
  private
    /// Tableau des intervalles d'instructions en attente de compilation
    FInstrIntervals: array of TSepiInstructionRef;

    FBegunAt: TSepiInstructionRef; /// Commencement de l'intervalle � compl�ter
  public
    constructor Create;

    procedure AddInstrInterval(BeginAt, EndAt: TSepiInstructionRef);
    procedure BeginInstrInterval(At: TSepiInstructionRef);
    procedure EndInstrInterval(At: TSepiInstructionRef);

    procedure Compile;

    function InterfereWith(Other: TSepiLocalVarLife): Boolean;
  end;

  {*
    Variable locale d'une m�thode Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiLocalVar = class(TObject)
  private
    FName: string;                      /// Nom (peut �tre vide)
    FType: TSepiType;                   /// Type de la variable
    FAbsoluteTo: TSepiLocalVar;         /// Variable sur laquelle se caler
    FAbsolutes: array of TSepiLocalVar; /// Variables cal�es sur celle-ci
    FIsFixed: Boolean;                  /// Indique si sa position est fix�e
    FIsParam: Boolean;                  /// Indique si c'est un param�tre
    FParamKind: TSepiParamKind;         /// Type de param�tre
    FLife: TSepiLocalVarLife;           /// Vie de la variable (peut �tre vide)
    FOffset: Integer;                   /// Offset

    procedure AddAbsolute(AbsVar: TSepiLocalVar);
    procedure SetLife(ALife: TSepiLocalVarLife);

    function GetIsAbsolute: Boolean;
    function GetIsConstant: Boolean;
    function GetNeedDereference: Boolean;
    function GetIsLifeShared: Boolean;
    function GetIsLifeHandled: Boolean;
  public
    constructor CreateVar(const AName: string; AType: TSepiType);
    constructor CreateTempVar(AType: TSepiType);
    constructor CreateParam(Param: TSepiParam);
    constructor CreateResult(AType: TSepiType);
    constructor CreateAbsolute(const AName: string; AType: TSepiType;
      AAbsoluteTo: TSepiLocalVar);
    destructor Destroy; override;

    procedure HandleLife;
    procedure CompileLife;

    function InterfereWith(Other: TSepiLocalVar): Boolean;
    procedure SetOffset(AOffset: Integer);

    property Name: string read FName;
    property VarType: TSepiType read FType;
    property IsAbsolute: Boolean read GetIsAbsolute;
    property AbsoluteTo: TSepiLocalVar read FAbsoluteTo;
    property IsFixed: Boolean read FIsFixed;
    property IsParam: Boolean read FIsParam;
    property ParamKind: TSepiParamKind read FParamKind;
    property IsConstant: Boolean read GetIsConstant;
    property NeedDereference: Boolean read GetNeedDereference;
    property IsLifeShared: Boolean read GetIsLifeShared;
    property IsLifeHandled: Boolean read GetIsLifeHandled;
    property Life: TSepiLocalVarLife read FLife;
    property Offset: Integer read FOffset;
  end;

  {*
    Informations d'initialisation d'une variable locale
    @author sjrd
    @version 1.0
  *}
  TLocalInitInfo = record
    TypeRef: Integer; /// R�f�rence au type de la variable
    Offset: Integer;  /// Offset de la variable
  end;

  {*
    Variables locales d'une m�thode Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiLocalVariables = class(TObject)
  private
    FCompiler: TSepiMethodCompiler; /// Compilateur de m�thode
    FVariables: TObjectList;        /// Variables

    FSize: Integer;                     /// Taille des variables locales
    FInitInfo: array of TLocalInitInfo; /// Informations d'initialisation

    procedure AllocateOffsets;
    procedure MakeInitInfo;

    function GetCount: Integer;
    function GetVariables(Index: Integer): TSepiLocalVar;
  public
    constructor Create(ACompiler: TSepiMethodCompiler);
    destructor Destroy; override;

    procedure AddFromSignature(Signature: TSepiSignature);
    function AddLocalVar(const AName: string;
      AType: TSepiType): TSepiLocalVar; overload;
    function AddLocalVar(const AName: string;
      ATypeInfo: PTypeInfo): TSepiLocalVar; overload;
    function AddLocalVar(const AName: string;
      const ATypeName: string): TSepiLocalVar; overload;
    function AddTempVar(AType: TSepiType): TSepiLocalVar;
    function AddAbsolute(const AName: string; AType: TSepiType;
      AAbsoluteTo: TSepiLocalVar): TSepiLocalVar;

    function GetVarByName(const Name: string): TSepiLocalVar;

    procedure Compile;
    procedure WriteInitInfo(Stream: TStream);

    property Compiler: TSepiMethodCompiler read FCompiler;
    property Count: Integer read GetCount;
    property Variables[Index: Integer]: TSepiLocalVar
      read GetVariables; default;

    property Size: Integer read FSize;
  end;

  {*
    Gestionnaire de vie de plusieurs variables temporaires
    @author sjrd
    @version 1.0
  *}
  TSepiTempVarsLifeManager = class(TObject)
  private
    FTempVars: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure BeginLife(TempVar: TSepiLocalVar; At: TSepiInstructionRef);
    procedure EndLife(TempVar: TSepiLocalVar; At: TSepiInstructionRef);

    procedure EndAllLifes(At: TSepiInstructionRef);
  end;

  {*
    Partie liable dynamiquement � une expression Sepi
  *}
  ISepiExpressionPart = interface(IDynamicallyLinkable)
    ['{2BBD5F29-1EDF-4C3F-A114-3820BAFB355A}']
  end;

  {*
    Expression Sepi
    Dans Sepi, une expression peut avoir diff�rents types en m�me temps. Elle
    peut � la fois �tre un meta et l'appel � une m�thode, par exemple.
    Les expressions Sepi sont donc des contr�leurs d'interfaces dynamiques, et
    il est possible de leur attacher/d�tacher toute interface impl�mentant
    IDynamicLinkable.
    @author sjrd
    @version 1.0
  *}
  ISepiExpression = interface(IInterface)
    ['{C747A8D6-6563-4B4C-8781-28769F808430}']

    {*
      Racine Sepi
      @return Racine Sepi
    *}
    function GetSepiRoot: TSepiRoot;

    {*
      Compilateur d'unit�
      @return Compilateur d'unit�
    *}
    function GetUnitCompiler: TSepiUnitCompiler;

    {*
      Compilateur de m�thode
      @return Compilateur de m�thode
    *}
    function GetMethodCompiler: TSepiMethodCompiler;

    {*
      Attache une interface dynamique
      @param IID    ID de l'interface � attacher
      @param Intf   Interface � lier
    *}
    procedure Attach(const IID: TGUID; const Intf: ISepiExpressionPart);

    {*
      D�tache une interface dynamique identifi�e par son ID
      @param IID   ID de l'interface � d�tacher
    *}
    procedure Detach(const IID: TGUID);

    {*
      Produit une erreur de compilation au niveau de cette expression
      @param Msg    Message de l'erreur
      @param Kind   Type d'erreur (d�faut = ekError)
    *}
    procedure MakeError(const Msg: string; Kind: TSepiErrorKind = ekError);

    property SepiRoot: TSepiRoot read GetSepiRoot;
    property UnitCompiler: TSepiUnitCompiler read GetUnitCompiler;
    property MethodCompiler: TSepiMethodCompiler read GetMethodCompiler;
  end;

  {*
    M�thode de call-back de r�solution d'identificateur
    @param Identifier   Identificateur recherch�
    @return Expression correspondant � cet identificateur
  *}
  TSepiResolveIdentFunc = function(
    const Identifier: string): ISepiExpression of object;

  {*
    Impl�mentation principale de ISepiExpression
    @author sjrd
    @version 1.0
  *}
  TSepiExpression = class(TDynamicIntfController, ISepiExpression)
  private
    FSepiRoot: TSepiRoot;                 /// Racine Sepi
    FUnitCompiler: TSepiUnitCompiler;     /// Compilateur d'unit�
    FMethodCompiler: TSepiMethodCompiler; /// Compilateur de m�thode

    FSourcePos: TSepiSourcePosition; /// Position dans le source
  protected
    function GetSepiRoot: TSepiRoot;
    function GetUnitCompiler: TSepiUnitCompiler;
    function GetMethodCompiler: TSepiMethodCompiler;
  public
    constructor Create(AUnitCompiler: TSepiUnitCompiler); overload;
    constructor Create(AMethodCompiler: TSepiMethodCompiler); overload;

    procedure Attach(const IID: TGUID; const Intf: ISepiExpressionPart);
    procedure Detach(const IID: TGUID);

    procedure MakeError(const Msg: string; Kind: TSepiErrorKind = ekError);

    property SepiRoot: TSepiRoot read FSepiRoot;
    property UnitCompiler: TSepiUnitCompiler read FUnitCompiler;
    property MethodCompiler: TSepiMethodCompiler read FMethodCompiler;

    property SourcePos: TSepiSourcePosition read FSourcePos write FSourcePos;
  end;

  {*
    Compilateur d'une m�thode Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiMethodCompiler = class(TObject)
  private
    FUnitCompiler: TSepiUnitCompiler; /// Compilateur d'unit�

    FObjFreeList: TObjectList; /// Liste des objets � lib�rer en fin de vie

    FSepiMethod: TSepiMethod;     /// M�thode Sepi correspondante
    FLocals: TSepiLocalVariables; /// Variables locales

    FInstructions: TSepiInstructionList; /// Instructions
    FAsmInstructions: TSepiAsmInstrList; /// Instructions assembleur
    FSize: Integer;                      /// Taille totale (apr�s assemblage)

    FLastInstruction: TSepiAsmInstrList;

    FNamedLabels: TStrings; /// Labels nomm�s (paire nom/instruction)

    procedure SetLabel(NamedLabel: TSepiNamedLabel);
  protected
    property AsmInstructions: TSepiAsmInstrList read FAsmInstructions;
  public
    constructor Create(AUnitCompiler: TSepiUnitCompiler;
      ASepiMethod: TSepiMethod);
    destructor Destroy; override;

    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure AddObjToFreeList(Obj: TObject);

    function LookFor(const Name: string): TObject;

    function LabelExists(const LabelName: string): Boolean;
    function FindLabel(const LabelName: string;
      Create: Boolean = False): TSepiNamedLabel;

    procedure Compile;
    procedure WriteToStream(Stream: TStream);
    procedure WriteLocalsInfo(Stream: TStream);

    property UnitCompiler: TSepiUnitCompiler read FUnitCompiler;
    property SepiMethod: TSepiMethod read FSepiMethod;
    property Locals: TSepiLocalVariables read FLocals;

    property Instructions: TSepiInstructionList read FInstructions;
    property Size: Integer read FSize;
  end;

  {*
    Compilateur d'unit� Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiUnitCompiler = class(TObject)
  private
    FErrors: TSepiCompilerErrorList; /// Erreurs

    FSepiUnit: TSepiUnit;  /// Unit� Sepi
    FMethods: TObjectList; /// Compilateurs de m�thodes

    FReferences: TObjectList; /// R�f�rences

    function GetMethodCount: Integer;
    function GetMethods(Index: Integer): TSepiMethodCompiler;
  public
    constructor Create(AErrors: TSepiCompilerErrorList;
      ASepiUnit: TSepiUnit);
    destructor Destroy; override;

    function MakeReference(Meta: TSepiMeta): Integer;

    procedure WriteToStream(Stream: TStream);

    property Errors: TSepiCompilerErrorList read FErrors;

    property SepiUnit: TSepiUnit read FSepiUnit;

    property MethodCount: Integer read GetMethodCount;
    property Methods[Index: Integer]: TSepiMethodCompiler read GetMethods;
  end;

  {*
    Record d'informations de d�r�f�rencement et d'op�ration sur adresse
    @author sjrd
    @version 1.0
  *}
  TSepiAddressDerefAndOpRec = record
    Dereference: TSepiAddressDereference;  /// D�r�f�rencement
    Operation: TSepiAddressOperation;      /// Op�ration
    ConstOperationArg: Integer;            /// Argument constant de l'op�ration
    MemOperationArg: TSepiMemoryReference; /// Argument m�moire de l'op�ration
  end;

  {*
    R�f�rence � un emplacement m�moire
    @author sjrd
    @version 1.0
  *}
  TSepiMemoryReference = class(TObject)
  private
    FMethodCompiler: TSepiMethodCompiler; /// Compilateur de m�thode

    FOptions: TSepiAddressOptions; /// Options
    FConstSize: Integer;           /// Taille d'une constante
    FIsSealed: Boolean;            /// Indique si la r�f�rence est scell�e

    FSpace: TSepiMemorySpace; /// Espace d'adressage
    FSpaceArgument: Integer;  /// Argument de l'espace d'adressage (offset)

    FUnresolvedLocalVar: TSepiLocalVar; /// Variable locale non r�solue

    FOperations: array of TSepiAddressDerefAndOpRec; /// Op�rations

    FConstant: Pointer; /// Constante (si Space = msConstant) - 0 par d�faut

    FSize: Integer; /// Taille de la r�f�rence m�moire dans le code

    procedure CheckUnsealed;

    function GetOperationCount: Integer;
    function GetOperations(Index: Integer): TSepiAddressDerefAndOpRec;
  public
    constructor Create(AMethodCompiler: TSepiMethodCompiler;
      AOptions: TSepiAddressOptions = []; AConstSize: Integer = 0);
    constructor Clone(Source: TSepiMemoryReference);
    destructor Destroy; override;

    procedure SetSpace(ASpace: TSepiMemorySpace;
      ASpaceArgument: Integer = 0); overload;
    procedure SetSpace(Meta: TSepiMeta); overload;
    procedure SetSpace(Variable: TSepiLocalVar); overload;
    procedure SetSpace(const Name: string); overload;

    procedure SetAsConst(Value: Int64); overload;
    procedure SetAsConst(Value: Boolean); overload;
    procedure SetAsConst(Value: Extended); overload;
    procedure SetAsConst(Value: Currency); overload;

    procedure ClearOperations;
    function AddOperation(ADereference: TSepiAddressDereference;
      AOperation: TSepiAddressOperation;
      AConstOperationArg: Integer = 0): TSepiMemoryReference; overload;
    procedure AddOperation(ADereference: TSepiAddressDereference); overload;
    function AddOperation(AOperation: TSepiAddressOperation;
      AConstOperationArg: Integer = 0): TSepiMemoryReference; overload;

    function CanRemoveDereference: Boolean;
    procedure RemoveDereference;

    procedure GetConstant(var AConstant);
    procedure SetConstant(const AConstant);

    procedure Seal;

    procedure Make;

    procedure WriteToStream(Stream: TStream);

    property MethodCompiler: TSepiMethodCompiler read FMethodCompiler;

    property Options: TSepiAddressOptions read FOptions;
    property ConstSize: Integer read FConstSize;
    property IsSealed: Boolean read FIsSealed;
    property Space: TSepiMemorySpace read FSpace;
    property SpaceArgument: Integer read FSpaceArgument;

    property OperationCount: Integer read GetOperationCount;
    property Operations[Index: Integer]: TSepiAddressDerefAndOpRec
      read GetOperations;

    property Size: Integer read FSize;
  end;

  {*
    Destination d'un JUMP Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiJumpDest = class(TObject)
  private
    FMethodCompiler: TSepiMethodCompiler; /// Compilateur de m�thode

    FInstructionRef: TSepiInstructionRef; /// Ref � l'instruction destination
  public
    constructor Create(AMethodCompiler: TSepiMethodCompiler);

    procedure SetToLabel(NamedLabel: TSepiNamedLabel); overload;
    procedure SetToLabel(const LabelName: string;
      Create: Boolean = False); overload;

    procedure Make;

    function MakeOffset(FromPos: Integer): Integer;

    procedure WriteToStream(Stream: TStream; FromPos: Integer); overload;
    procedure WriteToStream(Stream: TStream); overload;

    property MethodCompiler: TSepiMethodCompiler read FMethodCompiler;

    property InstructionRef: TSepiInstructionRef
      read FInstructionRef write FInstructionRef;
  end;

const // don't localize
  ResultFieldName = 'Result'; /// Nom de la variable locale Result

const
  MaxOperationCount = $0F; /// Nombre maximum d'op�rations sur une adresse

  /// Indique une variable locale non encore r�solue
  msUnresolvedLocalVar = TSepiMemorySpace(-1);

function IntegerSize(Value: Integer; ZeroGivesZero: Boolean = False): Integer;
function CardinalSize(Value: Cardinal;
  ZeroGivesZero: Boolean = False): Integer;

implementation

const
  /// Ensemble des op�rations qui ont un argument m�moire
  OpsWithMemArg = [
    aoPlusMemShortint, aoPlusMemSmallint, aoPlusMemLongint,
    aoPlusConstTimesMemShortint, aoPlusConstTimesMemSmallint,
    aoPlusConstTimesMemLongint
  ];

  /// Le label n'a pas �t� assign�
  LabelUnassigned = TObject($FFFFFFFF);

{*
  Calcule la taille en octets d'un entier sign�
  @param Value           Entier sign�
  @param ZeroGivesZero   Si True, alors Value = 0 renvoie 0
  @return Taille de l'entier sign�
*}
function IntegerSize(Value: Integer; ZeroGivesZero: Boolean = False): Integer;
begin
  if ZeroGivesZero and (Value = 0) then
    Result := 0
  else
  begin
    if Value < 0 then
      Value := not Value;

    if Value and Integer($FFFFFF80) = 0 then
      Result := 1
    else if Value and Integer($FFFF8000) = 0 then
      Result := 2
    else
      Result := 4;
  end;
end;

{*
  Calcule la taille en octets d'un entier non sign�
  @param Value           Entier non sign�
  @param ZeroGivesZero   Si True, alors Value = 0 renvoie 0
  @return Taille de l'entier non sign�
*}
function CardinalSize(Value: Cardinal;
  ZeroGivesZero: Boolean = False): Integer;
begin
  if ZeroGivesZero and (Value = 0) then
    Result := 0
  else if Value and Cardinal($FFFFFF00) = 0 then
    Result := 1
  else if Value and Cardinal($FFFF0000) = 0 then
    Result := 2
  else
    Result := 4;
end;

{------------------------}
{ TSepiInstruction class }
{------------------------}

{*
  Cr�e une nouvelle instruction Sepi
  @param AMethodCompiler   Compilateur de m�thode
*}
constructor TSepiInstruction.Create(AMethodCompiler: TSepiMethodCompiler);
begin
  inherited Create;

  FMethodCompiler := AMethodCompiler;
  FUnitCompiler := FMethodCompiler.UnitCompiler;

  FBeforeRef := TSepiInstructionRef.Create(MethodCompiler);
  FAfterRef := TSepiInstructionRef.Create(MethodCompiler);
end;

{*
  [@inheritDoc]
*}
destructor TSepiInstruction.Destroy;
begin
  FBeforeRef.Free;
  FAfterRef.Free;

  inherited;
end;

{*
  [@inheritDoc]
*}
procedure TSepiInstruction.AfterConstruction;
begin
  inherited;

  MethodCompiler.AddObjToFreeList(Self);
end;

{*
  Compile l'instruction
  Cette m�thode doit �tre surcharg�e par toutes les instructions afin de se
  compiler. La compilation fera intervenir la cr�ation d'instructions assembleur
  et leur compilation, en fin de r�cursion. La compilation des instructions
  assembleur est particuli�re et consiste uniquement � s'ajouter � la liste des
  instructions assembleur de la m�thode.
  Pour compiler les instructions subalternes, appelez Compile et non
  CustomCompile. Mais surchargez CustomCompile.
*}
procedure TSepiInstruction.CustomCompile;
begin
end;

{*
  Produit une erreur de compilation au niveau de cette instruction
  @param Msg    Message de l'erreur
  @param Kind   Type d'erreur (d�faut = ekError)
*}
procedure TSepiInstruction.MakeError(const Msg: string;
  Kind: TSepiErrorKind = ekError);
begin
  MethodCompiler.UnitCompiler.Errors.MakeError(Msg, Kind, SourcePos);
end;

{*
  Compile l'instruction
*}
procedure TSepiInstruction.Compile;
begin
  FBeforeRef.SetInstructionIndex(MethodCompiler.FAsmInstructions.CurrentPos);

  CustomCompile;

  FAfterRef.SetInstructionIndex(MethodCompiler.FAsmInstructions.CurrentPos);
end;

{---------------------------}
{ TSepiInstructionRef class }
{---------------------------}

{*
  Cr�e une r�f�rence � une instruction
  @param AMethodCompiler   Compilateur de m�thode
*}
constructor TSepiInstructionRef.Create(AMethodCompiler: TSepiMethodCompiler);
begin
  inherited Create;

  FMethodCompiler := AMethodCompiler;
  FInstructionIndex := -1;
end;

{*
  Renseigne la position de l'instruction r�f�renc�e
  @param Value Position de l'instruction r�f�renc�e
*}
procedure TSepiInstructionRef.SetInstructionIndex(Value: Integer);
begin
  Assert(FInstructionIndex < 0);
  FInstructionIndex := Value;
end;

{*
  Position de la r�f�rence
  @return Position de la r�f�rence
*}
function TSepiInstructionRef.GetPosition: Integer;
var
  Instructions: TSepiAsmInstrList;
begin
  Assert(FInstructionIndex >= 0);

  Instructions := MethodCompiler.AsmInstructions;

  if InstructionIndex < Instructions.Count then
    Result := Instructions[InstructionIndex].Position
  else
    Result := Instructions.Size;
end;

{---------------------}
{ TSepiAsmInstr class }
{---------------------}

{*
  Cr�e une nouvelle instruction assembleur Sepi
  @param AMethodCompiler   Compilateur de m�thode
*}
constructor TSepiAsmInstr.Create(AMethodCompiler: TSepiMethodCompiler);
begin
  inherited Create(AMethodCompiler);

  FOpCode := ocNope;
end;

{*
  Compile l'instruction assembleur
  La compilation d'une instruction assembleur consiste uniquement � s'ajouter �
  la liste des instructions assembleur de son compilateur de m�thode.
*}
procedure TSepiAsmInstr.CustomCompile;
begin
  MethodCompiler.FAsmInstructions.Add(Self);
end;

{*
  Position de la fin de l'instruction
  @return Position de la fin de l'instruction
*}
function TSepiAsmInstr.GetEndPosition: Integer;
begin
  Result := Position + Size;
end;

{*
  Construit l'instruction
  A partir de l'appel � Make, l'instruction ne sera plus modifi�e jusqu'�
  l'assemblage d�finitif.
  La m�thode Make doit au minimum renseigner correctement la propri�t� Size.
  L'impl�mentation par d�faut dans TSepiAsmInstr donne � MaxSize la taille d'un
  OpCode (1).
*}
procedure TSepiAsmInstr.Make;
begin
  FSize := SizeOf(TSepiOpCode);
end;

{*
  Calcule la taille r�elle en tenant compte des compressions possibles
  Apr�s l'appel � ComputeActualSize, la taille ne doit plus changer !
  L'impl�mentation par d�faut dans TSepiAsmInstr ne fait rien.
*}
procedure TSepiAsmInstr.ComputeActualSize;
begin
end;

{*
  Donne sa position � l'instruction
  @param Value   Position
*}
procedure TSepiAsmInstr.SetPosition(Value: Integer);
begin
  FPosition := Value;
end;

{*
  Ecrit l'instruction dans un flux
  WriteToStream doit �crire exactement autant d'octets dans le flux que la
  valeur de la propri�t� Size.
  L'impl�mentation par d�faut dans TSepiAsmInstr �crit l'OpCode
  @param Stream   Flux destination
*}
procedure TSepiAsmInstr.WriteToStream(Stream: TStream);
begin
  Stream.WriteBuffer(FOpCode, SizeOf(TSepiOpCode));
end;

{----------------------------}
{ TSepiInstructionList class }
{----------------------------}

{*
  Cr�e une liste d'instructions
  @param AMethodCompiler   Compilateur de m�thode
*}
constructor TSepiInstructionList.Create(AMethodCompiler: TSepiMethodCompiler);
begin
  inherited Create(AMethodCompiler);

  FInstructions := TObjectList.Create(False);
end;

{*
  [@inheritDoc]
*}
destructor TSepiInstructionList.Destroy;
begin
  FInstructions.Free;

  inherited;
end;

{*
  Nombre d'instructions
  @return Nombre d'instructions dans la liste
*}
function TSepiInstructionList.GetCount: Integer;
begin
  Result := FInstructions.Count;
end;

{*
  Tableau zero-based des instructions
  @param Index   Index d'une instruction
  @return L'instruction � l'index sp�cifi�
*}
function TSepiInstructionList.GetInstructions(Index: Integer): TSepiInstruction;
begin
  Result := TSepiInstruction(FInstructions[Index]);
end;

{*
  Compile les instructions
*}
procedure TSepiInstructionList.CustomCompile;
var
  I: Integer;
begin
  for I := 0 to Count-1 do
    Instructions[I].Compile;
end;

{*
  Ajoute une instruction � la fin de la liste
  @param Instruction   Instruction � ajouter
  @return Position de l'instruction dans la liste
*}
function TSepiInstructionList.Add(Instruction: TSepiInstruction): Integer;
begin
  Result := FInstructions.Add(Instruction);
end;

{*
  Ins�re une instruction � une position donn�e dans la liste
  @param Index         Index o� ins�rer l'instruction
  @param Instruction   Instruction � ins�rer
*}
procedure TSepiInstructionList.Insert(Index: Integer;
  Instruction: TSepiInstruction);
begin
  FInstructions.Insert(Index, Instruction);
end;

{-------------------------}
{ TSepiAsmInstrList class }
{-------------------------}

{*
  Cr�e une liste d'instructions assembleur
  @param AMethodCompiler   Compilateur de m�thode
*}
constructor TSepiAsmInstrList.Create(AMethodCompiler: TSepiMethodCompiler);
begin
  inherited Create;

  FMethodCompiler := AMethodCompiler;
  FInstructions := TObjectList.Create(False);

  FSize := 0;
end;

{*
  [@inheritDoc]
*}
destructor TSepiAsmInstrList.Destroy;
begin
  FInstructions.Free;

  inherited;
end;

{*
  Construit les instructions
*}
procedure TSepiAsmInstrList.Make;
var
  I: Integer;
begin
  FSize := 0;
  for I := 0 to Count-1 do
  begin
    Instructions[I].Make;
    Inc(FSize, Instructions[I].Size);
  end;
end;

{*
  Calcule la taille r�elle en tenant compte des compressions possibles
*}
procedure TSepiAsmInstrList.ComputeActualSize;
var
  I: Integer;
begin
  FSize := 0;
  for I := 0 to Count-1 do
  begin
    Instructions[I].ComputeActualSize;
    Inc(FSize, Instructions[I].Size);
  end;
end;

{*
  Donne leur position aux instructions
  @param Value   Position de base
*}
procedure TSepiAsmInstrList.SetPositions;
var
  I, Pos: Integer;
begin
  Pos := 0;

  for I := 0 to Count-1 do
  begin
    Instructions[I].SetPosition(Pos);
    Inc(Pos, Instructions[I].Size);
  end;
end;

{*
  Nombre d'instructions
  @return Nombre d'instructions dans la liste
*}
function TSepiAsmInstrList.GetCount: Integer;
begin
  Result := FInstructions.Count;
end;

{*
  Tableau zero-based des instructions
  @param Index   Index d'une instruction
  @return L'instruction � l'index sp�cifi�
*}
function TSepiAsmInstrList.GetInstructions(Index: Integer): TSepiAsmInstr;
begin
  Result := TSepiAsmInstr(FInstructions[Index]);
end;

{*
  Ajoute une instruction assembleur � la liste
  @param Instruction Instruction � ajouter
*}
procedure TSepiAsmInstrList.Add(Instruction: TSepiAsmInstr);
begin
  FInstructions.Add(Instruction);
end;

{*
  Vide la liste des instructions
*}
procedure TSepiAsmInstrList.Clear;
begin
  FInstructions.Clear;
end;

{*
  Assemble les instructions
*}
procedure TSepiAsmInstrList.Assemble;
begin
  Make;
  SetPositions;
  ComputeActualSize;
  SetPositions;
end;

{*
  Ecrit les instructions dans un flux
  @param Stream   Flux destination
*}
procedure TSepiAsmInstrList.WriteToStream(Stream: TStream);
var
  I: Integer;
begin
  for I := 0 to Count-1 do
    Instructions[I].WriteToStream(Stream);
end;

{-----------------------}
{ TSepiNamedLabel class }
{-----------------------}

{*
  Cr�e une nouveau label nomm�
  @param AMethodCompiler   Compilateur de m�thode
  @param AName             Nom du label
*}
constructor TSepiNamedLabel.Create(AMethodCompiler: TSepiMethodCompiler;
  const AName: string);
begin
  inherited Create(AMethodCompiler);

  FName := AName;
end;

{*
  [@inheritDoc]
*}
procedure TSepiNamedLabel.CustomCompile;
begin
end;

{*
  [@inheritDoc]
*}
procedure TSepiNamedLabel.AfterConstruction;
begin
  MethodCompiler.SetLabel(Self);
end;

{-------------------------}
{ TSepiLocalVarLife class }
{-------------------------}

{*
  Cr�e la vie d'une variable locale
*}
constructor TSepiLocalVarLife.Create;
begin
  inherited Create;
end;

{*
  Ajoute un intervalle d'instructions
  @param BeginAt   D�but de l'intervalle
  @param EndAt     Fin de l'intervalle
*}
procedure TSepiLocalVarLife.AddInstrInterval(
  BeginAt, EndAt: TSepiInstructionRef);
var
  Index: Integer;
begin
  Index := Length(FInstrIntervals);
  SetLength(FInstrIntervals, Index+2);

  FInstrIntervals[Index] := BeginAt;
  FInstrIntervals[Index+1] := EndAt;
end;

{*
  Commence un intervalle de vie
  L'intervalle devra �tre termin� avec EndInstrInterval.
  @param At   D�but de l'intervalle
*}
procedure TSepiLocalVarLife.BeginInstrInterval(At: TSepiInstructionRef);
begin
  Assert(FBegunAt = nil);
  FBegunAt := At;
end;

{*
  Termine un intervalle de vie commenc� avec BeginInstrInterval
  @param At   Fin de l'intervalle
*}
procedure TSepiLocalVarLife.EndInstrInterval(At: TSepiInstructionRef);
begin
  Assert(FBegunAt <> nil);
  AddInstrInterval(FBegunAt, At);
  FBegunAt := nil;
end;

{*
  Compile les r�f�rences d'instructions en leurs positions
*}
procedure TSepiLocalVarLife.Compile;
var
  I: Integer;
begin
  for I := 0 to Length(FInstrIntervals) div 2 - 1 do
    AddInterval(FInstrIntervals[I].Position, FInstrIntervals[I+1].Position);
end;

{*
  Teste si cette vie interf�re avec une autre
  @param Other   Vie � comparer
  @return True si les vies interf�rent entre elles, False sinon
*}
function TSepiLocalVarLife.InterfereWith(Other: TSepiLocalVarLife): Boolean;
var
  Temp: TScIntegerSet;
begin
  Temp := TScIntegerSet.Clone(Self);
  try
    Temp.Intersect(Other);
    Result := Temp.IntervalCount = 0;
  finally
    Temp.Free;
  end;
end;

{---------------------}
{ TSepiLocalVar class }
{---------------------}

{*
  Cr�e une nouvelle variable locale
  @param AName   Nom
  @param AType   Type
*}
constructor TSepiLocalVar.CreateVar(const AName: string; AType: TSepiType);
begin
  inherited Create;

  FName := AName;
  FType := AType;
end;

{*
  Cr�e une nouvelle variable temporaire
  @param AType   Type
*}
constructor TSepiLocalVar.CreateTempVar(AType: TSepiType);
begin
  inherited Create;

  FType := AType;
end;

{*
  Cr�e une variable d'acc�s � un param�tre
  @param Param   Param�tre � acc�der
*}
constructor TSepiLocalVar.CreateParam(Param: TSepiParam);
begin
  inherited Create;

  FName := Param.Name;
  FType := Param.ParamType;
  FIsFixed := True;
  FIsParam := True;
  FParamKind := Param.Kind;
  FOffset := Param.CallInfo.SepiStackOffset;
end;

{*
  Cr�e la variable r�sultat d'une m�thode
  @param AType   Type de retour
*}
constructor TSepiLocalVar.CreateResult(AType: TSepiType);
begin
  inherited Create;

  FName := ResultFieldName;
  FType := AType;
  FIsFixed := True;
  FOffset := 0;
end;

{*
  Cr�e une variable cal�e sur une autre
  Une variable cal�e sur une autre aura le m�me offset que celle-ci, quels que
  soit leurs types respectifs. Leurs lignes de vies sont combin�es, et
  l'initialisation/finalisation du type de la variable cal�e n'est jamais prise
  en compte.
  @param AName         Nom
  @param AType         Type
  @param AAbsoluteTo   Variable sur laquelle se caler
*}
constructor TSepiLocalVar.CreateAbsolute(const AName: string; AType: TSepiType;
  AAbsoluteTo: TSepiLocalVar);
begin
  inherited Create;

  FName := AName;
  FType := AType;

  if AAbsoluteTo.IsAbsolute then
    AAbsoluteTo := AAbsoluteTo.AbsoluteTo;

  FAbsoluteTo := AAbsoluteTo;
  FAbsoluteTo.AddAbsolute(Self);

  FIsFixed := AbsoluteTo.IsFixed;
  FIsParam := AbsoluteTo.IsParam;
  FParamKind := AbsoluteTo.ParamKind;
  FLife := AbsoluteTo.Life;
  FOffset := AbsoluteTo.Offset;
end;

{*
  [@inheritDoc]
*}
destructor TSepiLocalVar.Destroy;
begin
  if not IsAbsolute then
    FLife.Free;

  inherited;
end;

{*
  Recense une variable qui est cal�e sur celle-ci
  @param AbsVar   Variable � recenser
*}
procedure TSepiLocalVar.AddAbsolute(AbsVar: TSepiLocalVar);
begin
  SetLength(FAbsolutes, Length(FAbsolutes)+1);
  FAbsolutes[Length(FAbsolutes)-1] := AbsVar;
end;

{*
  Renseigne la vie de la variable
  Pour une variable sur laquelle sont cal�es d'autres, ces derni�res sont
  �galement notifi�es de cette affectation.
  @param ALife   Vie de la variable
*}
procedure TSepiLocalVar.SetLife(ALife: TSepiLocalVarLife);
var
  I: Integer;
begin
  FLife := ALife;

  for I := 0 to Length(FAbsolutes)-1 do
    FAbsolutes[I].SetLife(FLife);
end;

{*
  Indique si la variable est cal�e sur une autre
  @return True si elle est cal�e sur une autre, False sinon
*}
function TSepiLocalVar.GetIsAbsolute: Boolean;
begin
  Result := FAbsoluteTo <> nil;
end;

{*
  Indique si la variable est en lecture seule
  @return True si elle est en lecture seule, False sinon
*}
function TSepiLocalVar.GetIsConstant: Boolean;
begin
  Result := IsParam and (ParamKind = pkConst);
end;

{*
  Indique si la variable doit �tre d�r�f�renc�e pour y acc�der
  Les variables qui doivent �tre d�r�f�renc�es sont les param�tres qui sont
  transmis par adresse, et eux seuls.
  @return True si elle doit �tre d�r�f�renc�e, False sinon
*}
function TSepiLocalVar.GetNeedDereference: Boolean;
begin
  Result := IsParam and
    ((ParamKind in [pkVar, pkOut]) or
    VarType.ParamBehavior.AlwaysByAddress);
end;

{*
  Indique si la vie de cette variable est partag�e avec une autre
  Seules les vies de variables cal�es les unes sur les autres sont partag�es.
  Si vous �crivez une analyse de vie dans votre compilateur, tenez compte de
  cette information, sous peine de rater votre analyse, et donc de corrompre la
  compilation.
  @return True si sa vie est partag�e, False sinon
*}
function TSepiLocalVar.GetIsLifeShared: Boolean;
begin
  Result := (FAbsoluteTo <> nil) or (Length(FAbsolutes) <> 0);
end;

{*
  Indique si la vie de cette variable est g�r�e
  @return True si sa vie est g�r�e, False sinon
*}
function TSepiLocalVar.GetIsLifeHandled: Boolean;
begin
  Result := FLife <> nil;
end;

{*
  Commence la gestion de la vie de cette variable
*}
procedure TSepiLocalVar.HandleLife;
begin
  if FLife <> nil then
    Exit;

  if IsAbsolute then
    AbsoluteTo.HandleLife
  else
    SetLife(TSepiLocalVarLife.Create);
end;

{*
  Compile la vie de cette variable
*}
procedure TSepiLocalVar.CompileLife;
begin
  if Life <> nil then
    Life.Compile;
end;

{*
  Teste si cette variable interf�re avec une autre
  Deux variables qui interf�rent entre elles ne peuvent �tre positionn�e au
  m�me offset dans les variables locales.
  @param Other   Variable avec laquelle comparer
  @return True si les variables interf�rent, False sinon
*}
function TSepiLocalVar.InterfereWith(Other: TSepiLocalVar): Boolean;
begin
  Result := True;

  if IsAbsolute then
    Exit;
  if (not IsLifeHandled) or (not Other.IsLifeHandled) then
    Exit;
  if not AreInitFinitCompatible(VarType.TypeInfo,
    Other.VarType.TypeInfo) then
    Exit;
  if Life.InterfereWith(Other.Life) then
    Exit;

  Result := False;
end;

{*
  Renseigne l'offset de cette variable
  Pour les variables sur lesquelles sont cal�es d'autres, celles-ci sont
  �galement notifi�es de cette affectation.
*}
procedure TSepiLocalVar.SetOffset(AOffset: Integer);
var
  I: Integer;
begin
  FIsFixed := True;
  FOffset := AOffset;

  for I := 0 to Length(FAbsolutes)-1 do
    FAbsolutes[I].SetOffset(AOffset);
end;

{---------------------------}
{ TSepiLocalVariables class }
{---------------------------}

{*
  Cr�e les variables locales d'une m�thode
  @param ACompiler   Compilateur de m�thode
*}
constructor TSepiLocalVariables.Create(ACompiler: TSepiMethodCompiler);
begin
  inherited Create;

  FCompiler := ACompiler;
  FVariables := TObjectList.Create;
end;

{*
  [@inheritDoc]
*}
destructor TSepiLocalVariables.Destroy;
begin
  FVariables.Free;

  inherited;
end;

{*
  Alloue l'espace m�moire pour les variables locales et renseigne leurs offsets
  Cette m�thode renseigne �galement la propri�t� Size.
*}
procedure TSepiLocalVariables.AllocateOffsets;
var
  I: Integer;
  LocalVar: TSepiLocalVar;
begin
  FSize := 0;

  // Bypass all fixed variables
  for I := 0 to Count-1 do
  begin
    LocalVar := Variables[I];
    if LocalVar.IsAbsolute or LocalVar.IsParam or (not LocalVar.IsFixed) then
      Continue;
    if LocalVar.Offset + LocalVar.VarType.Size > FSize then
      FSize := LocalVar.Offset + LocalVar.VarType.Size;
  end;

  // Give offsets to non fixed variables
  for I := 0 to Count-1 do
  begin
    LocalVar := Variables[I];
    if LocalVar.IsAbsolute or LocalVar.IsFixed then
      Continue;

    LocalVar.VarType.AlignOffset(FSize);
    LocalVar.SetOffset(FSize);
    Inc(FSize, LocalVar.VarType.Size);
  end;

  // Align total size on a 4-byte boundary
  if FSize and 3 <> 0 then
    FSize := (FSize and not 3) + 4;
end;

{*
  Construit les informations d'initialisation/finalisation
*}
procedure TSepiLocalVariables.MakeInitInfo;
var
  InitCount, I: Integer;
  LocalVar: TSepiLocalVar;
begin
  SetLength(FInitInfo, Count);
  InitCount := 0;

  for I := 0 to Count-1 do
  begin
    LocalVar := Variables[I];

    { Ignore parameters, absolute variables and variables whose type doesn't
      require initialization. }
    if LocalVar.IsParam or LocalVar.IsAbsolute or
      (not LocalVar.VarType.NeedInit) then
      Continue;

    // Add an item to locals info
    with FInitInfo[InitCount] do
    begin
      TypeRef := Compiler.UnitCompiler.MakeReference(LocalVar.VarType);
      Offset := LocalVar.Offset;
      Inc(InitCount);
    end;
  end;

  SetLength(FInitInfo, InitCount);
end;

{*
  Nombre de variables
  @return Nombre de variables
*}
function TSepiLocalVariables.GetCount: Integer;
begin
  Result := FVariables.Count;
end;

{*
  Tableau zero-based des variables
  @param Index   Index d'une variable
  @return Variable � l'index sp�cifi�
*}
function TSepiLocalVariables.GetVariables(Index: Integer): TSepiLocalVar;
begin
  Result := TSepiLocalVar(FVariables[Index]);
end;

{*
  Ajoute toutes les variables correspondant � une signature
  @param Signature   Signature
*}
procedure TSepiLocalVariables.AddFromSignature(Signature: TSepiSignature);
var
  I: Integer;
begin
  with Signature do
  begin
    for I := 0 to ActualParamCount-1 do
      FVariables.Add(TSepiLocalVar.CreateParam(ActualParams[I]));

    if not (ReturnType.SafeResultBehavior in [rbNone, rbParameter]) then
      FVariables.Add(TSepiLocalVar.CreateResult(ReturnType));
  end;
end;

{*
  Ajoute une variable locale
  @param AName   Nom de la variable
  @param AType   Type de la variable
  @return Variable cr��e
*}
function TSepiLocalVariables.AddLocalVar(const AName: string;
  AType: TSepiType): TSepiLocalVar;
begin
  Result := TSepiLocalVar.CreateVar(AName, AType);
  FVariables.Add(Result);
end;

{*
  Ajoute une variable locale
  @param AName       Nom de la variable
  @param ATypeInfo   RTTI du type de la variable
  @return Variable cr��e
*}
function TSepiLocalVariables.AddLocalVar(const AName: string;
  ATypeInfo: PTypeInfo): TSepiLocalVar;
begin
  Result := AddLocalVar(AName,
    Compiler.SepiMethod.Root.FindType(ATypeInfo));
end;

{*
  Ajoute une variable locale
  @param AName      Nom de la variable
  @param ATypeNom   Nom du type de la variable
  @return Variable cr��e
*}
function TSepiLocalVariables.AddLocalVar(const AName: string;
  const ATypeName: string): TSepiLocalVar;
begin
  Result := AddLocalVar(AName,
    Compiler.SepiMethod.Root.FindType(ATypeName));
end;

{*
  Ajoute une variable temporaire
  @param AType   Type de la variable
  @return Variable cr��e
*}
function TSepiLocalVariables.AddTempVar(AType: TSepiType): TSepiLocalVar;
begin
  Result := TSepiLocalVar.CreateTempVar(AType);
  FVariables.Add(Result);
end;

{*
  Ajoute une variable call�e sur une autre
  @param AName         Nom de la variable
  @param AType         Type de la variable
  @param AAbsoluteTo   Variable sur laquelle se caller
*}
function TSepiLocalVariables.AddAbsolute(const AName: string; AType: TSepiType;
  AAbsoluteTo: TSepiLocalVar): TSepiLocalVar;
begin
  Result := TSepiLocalVar.CreateAbsolute(AName, AType, AAbsoluteTo);
  FVariables.Add(Result);
end;

{*
  R�cup�re une variable locale par son nom
  @param Name   Nom de la variable recherch�e
  @return Variable correspondante, ou nil si non trouv�e
*}
function TSepiLocalVariables.GetVarByName(const Name: string): TSepiLocalVar;
var
  I: Integer;
begin
  for I := 0 to Count-1 do
  begin
    Result := Variables[I];
    if AnsiSameText(Result.Name, Name) then
      Exit;
  end;

  Result := nil;
end;

{*
  Compile les variables locales et leur donne des offsets
*}
procedure TSepiLocalVariables.Compile;
var
  I: Integer;
begin
  for I := 0 to Count-1 do
    Variables[I].CompileLife;

  AllocateOffsets;
  MakeInitInfo;
end;

{*
  Ecrit les informations d'initialisation des variables locales
  @param Stream   Flux de destination
*}
procedure TSepiLocalVariables.WriteInitInfo(Stream: TStream);
var
  InitCount: Integer;
begin
  InitCount := Length(FInitInfo);
  Stream.WriteBuffer(InitCount, 4);

  Stream.WriteBuffer(FInitInfo[0], InitCount * SizeOf(TLocalInitInfo));
end;

{--------------------------------}
{ TSepiTempVarsLifeManager class }
{--------------------------------}

{*
  Cr�e un gestionnaire
*}
constructor TSepiTempVarsLifeManager.Create;
begin
  inherited Create;

  FTempVars := TObjectList.Create(False);
end;

{*
  [@inheritDoc]
*}
destructor TSepiTempVarsLifeManager.Destroy;
begin
  FTempVars.Free;

  inherited;
end;

{*
  Commence la vie d'une variable temporaire
  @param TempVar   Variable
  @param At        Position o� la vie commence
*}
procedure TSepiTempVarsLifeManager.BeginLife(TempVar: TSepiLocalVar;
  At: TSepiInstructionRef);
begin
  if TempVar = nil then
    Exit;

  Assert(FTempVars.IndexOf(TempVar) < 0);

  FTempVars.Add(TempVar);
  TempVar.HandleLife;
  TempVar.Life.BeginInstrInterval(At);
end;

{*
  Termine la vie d'une variable temporaire
  @param TempVar   Variable
  @param At        Position o� la vie s'arr�te
*}
procedure TSepiTempVarsLifeManager.EndLife(TempVar: TSepiLocalVar;
  At: TSepiInstructionRef);
var
  Index: Integer;
begin
  if TempVar = nil then
    Exit;

  Index := FTempVars.IndexOf(TempVar);
  Assert(Index >= 0);

  TempVar.Life.EndInstrInterval(At);
  FTempVars.Delete(Index);
end;

{*
  Termine la vie de toutes les variables temporaires de ce gestionnaire
  @param At   Position o� la vie s'arr�te
*}
procedure TSepiTempVarsLifeManager.EndAllLifes(At: TSepiInstructionRef);
var
  I: Integer;
begin
  for I := 0 to FTempVars.Count-1 do
    TSepiLocalVar(FTempVars[I]).Life.EndInstrInterval(At);
  FTempVars.Clear;
end;

{-----------------------}
{ TSepiExpression class }
{-----------------------}

{*
  Cr�e une expression relative � une unit�
  @param AUnitCompiler   Compilateur d'unit�
*}
constructor TSepiExpression.Create(AUnitCompiler: TSepiUnitCompiler);
begin
  inherited Create;

  FUnitCompiler := AUnitCompiler;
  FSepiRoot := UnitCompiler.SepiUnit.Root;
end;

{*
  Cr�e une expression relative � une m�thode
  @param AMethodCompiler   Compilateur de m�thode
*}
constructor TSepiExpression.Create(AMethodCompiler: TSepiMethodCompiler);
begin
  inherited Create;

  FMethodCompiler := AMethodCompiler;
  FUnitCompiler := MethodCompiler.UnitCompiler;
  FSepiRoot := UnitCompiler.SepiUnit.Root;
end;

{*
  Racine Sepi
  @return Racine Sepi
*}
function TSepiExpression.GetSepiRoot: TSepiRoot;
begin
  Result := FSepiRoot;
end;

{*
  Compilateur d'unit�
  @return Compilateur d'unit�
*}
function TSepiExpression.GetUnitCompiler: TSepiUnitCompiler;
begin
  Result := FUnitCompiler;
end;

{*
  Compilateur de m�thode
  @return Compilateur de m�thode
*}
function TSepiExpression.GetMethodCompiler: TSepiMethodCompiler;
begin
  Result := FMethodCompiler;
end;

{*
  [@inheritDoc]
*}
procedure TSepiExpression.Attach(const IID: TGUID;
  const Intf: ISepiExpressionPart);
begin
  inherited Attach(IID, Intf);
end;

{*
  [@inheritDoc]
*}
procedure TSepiExpression.Detach(const IID: TGUID);
begin
  inherited Detach(IID);
end;

{*
  [@inheritDoc]
*}
procedure TSepiExpression.MakeError(const Msg: string;
  Kind: TSepiErrorKind = ekError);
begin
  UnitCompiler.Errors.MakeError(Msg, Kind, SourcePos);
end;

{---------------------------}
{ TSepiMethodCompiler class }
{---------------------------}

{*
  Cr�e un nouveau compilateur de m�thode Sepi
  @param AUnitCompiler   Compilateur d'unit�
  @param ASepiMethod     M�thode Sepi
*}
constructor TSepiMethodCompiler.Create(AUnitCompiler: TSepiUnitCompiler;
  ASepiMethod: TSepiMethod);
begin
  inherited Create;

  FUnitCompiler := AUnitCompiler;
  FSepiMethod := ASepiMethod;

  FObjFreeList := TObjectList.Create(False);

  FLocals := TSepiLocalVariables.Create(Self);
  FLocals.AddFromSignature(SepiMethod.Signature);

  FInstructions := TSepiInstructionList.Create(Self);
  FAsmInstructions := TSepiAsmInstrList.Create(Self);
  FLastInstruction := nil;
  FSize := 0;

  FNamedLabels := TStringList.Create;
  TStringList(FNamedLabels).CaseSensitive := False;
end;

{*
  [@inheritDoc]
*}
destructor TSepiMethodCompiler.Destroy;
begin
  FNamedLabels.Free;
  FAsmInstructions.Free;

  FLocals.Free;

  FObjFreeList.Free;

  inherited;
end;

{*
  Notifie l'existence d'un label nomm�
  @param NamedLabel   Label nomm� � ajouter
*}
procedure TSepiMethodCompiler.SetLabel(NamedLabel: TSepiNamedLabel);
var
  Index: Integer;
begin
  Index := FNamedLabels.IndexOf(NamedLabel.Name);
  
  if Index < 0 then
    FNamedLabels.AddObject(NamedLabel.Name, NamedLabel)
  else
    raise ESepiLabelError.CreateResFmt(@SLabelAlreadyExists, [NamedLabel.Name]);
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodCompiler.AfterConstruction;
begin
  inherited;

  UnitCompiler.FMethods.Add(Self);
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodCompiler.BeforeDestruction;
var
  I: Integer;
begin
  inherited;

  for I := 0 to FObjFreeList.Count-1 do
    FObjFreeList[I].Free;
  FObjFreeList.Clear;
end;

{*
  Ajoute un objet � ceux devant �tre lib�r�s en fin de vie
*}
procedure TSepiMethodCompiler.AddObjToFreeList(Obj: TObject);
begin
  if FObjFreeList.IndexOf(Obj) < 0 then
    FObjFreeList.Add(Obj);
end;

{*
  Cherche un objet � partir de son nom
  LookFor cherche parmi les variables locales, puis les param�tres, et enfin
  essaie la m�thode LookFor de la m�thode Sepi correspondante. Le r�sultat peut
  �tre de type TSepiMeta ou TSepiParam.
  @param Name   Nom de l'objet recherch�
  @return Objet recherch�, ou nil si non trouv�
*}
function TSepiMethodCompiler.LookFor(const Name: string): TObject;
begin
  Result := Locals.GetVarByName(Name);
  if Result <> nil then
    Exit;

  Result := SepiMethod.Signature.GetParam(Name);
  if Result <> nil then
    Exit;

  Result := SepiMethod.LookFor(Name);
end;

{*
  Teste l'existence d'un un label nomm�
  @param LabelName   Nom du label
  @return True si un label de ce nom existe, False sinon
*}
function TSepiMethodCompiler.LabelExists(const LabelName: string): Boolean;
begin
  Result := FNamedLabels.IndexOf(LabelName) >= 0;
end;

{*
  Cherche un label nomm�
  @param LabelName   Nom du label recherch�
  @param Create      Si True, un label non trouv� est cr�� automatiquement
  @return Label nomm�
  @throws ESepiLabelError Le label n'a pas �t� trouv�
*}
function TSepiMethodCompiler.FindLabel(
  const LabelName: string; Create: Boolean = False): TSepiNamedLabel;
var
  Index: Integer;
begin
  Index := FNamedLabels.IndexOf(LabelName);

  if Index >= 0 then
    Result := TSepiNamedLabel(FNamedLabels.Objects[Index])
  else if Create then
    Result := TSepiNamedLabel.Create(Self, LabelName)
  else
    raise ESepiLabelError.CreateResFmt(@SLabelNotFound, [LabelName]);
end;

{*
  Compile les instructions
*}
procedure TSepiMethodCompiler.Compile;
begin
  // Compile
  AsmInstructions.Clear;
  Instructions.Compile;
  Locals.Compile;

  // Assemble
  AsmInstructions.Assemble;
  FSize := AsmInstructions.Size;
end;

{*
  Ecrit la m�thode dans un flux (tel que TSepiRuntimeMethod puisse le lire)
  La m�thode doit avoir �t� compil�e au pr�alable via la m�thode Compile.
  @param Stream   Flux de destination
*}
procedure TSepiMethodCompiler.WriteToStream(Stream: TStream);
var
  NearlyFullName: string;
  Size: Integer;
begin
  // Write name
  NearlyFullName := SepiMethod.GetFullName;
  Delete(NearlyFullName, 1, Pos('.', NearlyFullName));
  WriteStrToStream(Stream, NearlyFullName);

  // Write parameters, locals and code sizes
  Size := SepiMethod.Signature.SepiStackUsage;
  Stream.WriteBuffer(Size, 4);
  Size := Locals.Size;
  if Size and 3 <> 0 then
    Size := (Size and (not 3)) + 4;
  Stream.WriteBuffer(Size, 4);
  Stream.WriteBuffer(FSize, 4);

  // Write code
  AsmInstructions.WriteToStream(Stream);
end;

{*
  Ecrit les informations d'initialisation des variables locales
  @param Stream   Flux de destination
*}
procedure TSepiMethodCompiler.WriteLocalsInfo(Stream: TStream);
begin
  Locals.WriteInitInfo(Stream);
end;

{-------------------------}
{ TSepiUnitCompiler class }
{-------------------------}

{*
  Cr�e un nouveau compilateur d'unit� Sepi
  @param ASepiUnit   Unit� Sepi � assembler
*}
constructor TSepiUnitCompiler.Create(AErrors: TSepiCompilerErrorList;
  ASepiUnit: TSepiUnit);
begin
  inherited Create;

  FErrors := AErrors;

  FSepiUnit := ASepiUnit;
  FMethods := TObjectList.Create;
  FReferences := TObjectList.Create(False);
end;

{*
  [@inheritDoc]
*}
destructor TSepiUnitCompiler.Destroy;
begin
  FReferences.Free;
  FMethods.Free;

  inherited;
end;

{*
  Nombre de compilateurs de m�thode
  @return Nombre de compilateurs de m�thode
*}
function TSepiUnitCompiler.GetMethodCount: Integer;
begin
  Result := FMethods.Count;
end;

{*
  Tableau zero-based des compilateurs de m�thode
  @param Index   Index d'un compilateur
  @return Compilateur � l'index sp�cifi�
*}
function TSepiUnitCompiler.GetMethods(Index: Integer): TSepiMethodCompiler;
begin
  Result := TSepiMethodCompiler(FMethods[Index]);
end;

{*
  Construit un num�ro de r�f�rence � un meta Sepi
  @param Meta   Meta pour lequel construire un num�ro de r�f�rence
  @return Num�ro de r�f�rence du meta
*}
function TSepiUnitCompiler.MakeReference(Meta: TSepiMeta): Integer;
begin
  Result := FReferences.IndexOf(Meta);
  if Result < 0 then
    Result := FReferences.Add(Meta);
end;

{*
  Ecrit l'unit� compil�e dans un flux
  @param Stream   Flux destination
*}
procedure TSepiUnitCompiler.WriteToStream(Stream: TStream);
var
  I, Count: Integer;
begin
  // Compile methods
  for I := 0 to MethodCount-1 do
    Methods[I].Compile;

  // Write methods
  Count := MethodCount;
  Stream.WriteBuffer(Count, 4);
  for I := 0 to Count-1 do
    Methods[I].WriteToStream(Stream);

  // Save Sepi unit
  SepiUnit.SaveToStream(Stream);

  // Write references
  Count := FReferences.Count;
  Stream.WriteBuffer(Count, 4);
  for I := 0 to Count-1 do
    WriteStrToStream(Stream, TSepiMeta(FReferences[I]).GetFullName);

  // Write locals information
  for I := 0 to MethodCount-1 do
    Methods[I].WriteLocalsInfo(Stream);
end;

{----------------------------}
{ TSepiMemoryReference class }
{----------------------------}

{*
  Cr�e une nouvelle r�f�rence m�moire
  @param AMethodCompiler   Compilateur de m�thode
  @param AOptions          Options
  @param AConstSize        Taille de constante
*}
constructor TSepiMemoryReference.Create(AMethodCompiler: TSepiMethodCompiler;
  AOptions: TSepiAddressOptions = []; AConstSize: Integer = 0);
begin
  inherited Create;

  FMethodCompiler := AMethodCompiler;

  FOptions := AOptions;
  FConstSize := AConstSize;
  if FConstSize <= 0 then
    Exclude(FOptions, aoAcceptConstInCode);

  if [aoZeroAsNil, aoAcceptZero] * Options <> [] then
    FSpace := msZero
  else
    FSpace := msLocalsBase;
  FSpaceArgument := 0;

  if aoAcceptConstInCode in Options then
    GetMem(FConstant, ConstSize)
  else
    FConstant := nil;

  FSize := 0;
end;

{*
  Construit une copie d'une r�f�rence m�moire
  La copie est en tout point identique � l'originale, except� qu'elle n'est
  jamais scell�e.
  @param Source   R�f�rence m�moire � copier
*}
constructor TSepiMemoryReference.Clone(Source: TSepiMemoryReference);
begin
  inherited Create;

  FMethodCompiler := Source.MethodCompiler;

  FOptions := Source.Options;
  FConstSize := Source.FConstSize;
  FSpace := Source.Space;
  FSpaceArgument := Source.SpaceArgument;

  if Source.FConstant <> nil then
  begin
    GetMem(FConstant, ConstSize);
    Move(Source.FConstant^, FConstant^, ConstSize);
  end;

  FSize := Source.Size;
end;

{*
  [@inheritDoc]
*}
destructor TSepiMemoryReference.Destroy;
begin
  FIsSealed := False;

  if Assigned(FConstant) then
    FreeMem(FConstant);
  ClearOperations;

  inherited;
end;

{*
  V�rifie que la r�f�rence m�moire n'est pas scell�e
*}
procedure TSepiMemoryReference.CheckUnsealed;
begin
  if IsSealed then
    raise ESepiSealedMemoryReference.Create(SMemoryRefIsSealed);
end;

{*
  Nombre d'op�rations
  @return Nombre d'op�rations
*}
function TSepiMemoryReference.GetOperationCount: Integer;
begin
  Result := Length(FOperations);
end;

{*
  Tableau zero-based des op�rations
  @param Index   Index d'une op�ration
  @return Op�ration � l'index sp�cifi�
*}
function TSepiMemoryReference.GetOperations(
  Index: Integer): TSepiAddressDerefAndOpRec;
begin
  Result := FOperations[Index];
end;

{*
  Modifie l'espace m�moire
  Cette modification supprime toutes les op�rations si le nouvel espace est
  msZero (qui ne supporte pas les op�rations).
  @param Value   Nouvelle valeur d'espace m�moire
*}
procedure TSepiMemoryReference.SetSpace(ASpace: TSepiMemorySpace;
  ASpaceArgument: Integer = 0);
begin
  CheckUnsealed;

  case ASpace of
    msZero:
    begin
      if [aoZeroAsNil, aoAcceptZero] * Options = [] then
        raise ESepiInvalidMemoryReference.CreateRes(@SMemoryCantBeZero);
      ClearOperations;
    end;
    msConstant:
    begin
      if not (aoAcceptConstInCode in Options) then
        raise ESepiInvalidMemoryReference.CreateRes(@SMemoryCantBeConstant);
    end;
    msLocalsBase, msLocalsByte, msLocalsWord:
    begin
      case CardinalSize(ASpaceArgument, True) of
        0: ASpace := msLocalsBase;
        1: ASpace := msLocalsByte;
        2: ASpace := msLocalsWord;
      else
        raise ESepiInvalidMemoryReference.CreateRes(
          @SMemorySpaceOffsetMustBeWord);
      end;
    end;
    msParamsBase, msParamsByte, msParamsWord:
    begin
      case CardinalSize(ASpaceArgument, True) of
        0: ASpace := msParamsBase;
        1: ASpace := msParamsByte;
        2: ASpace := msParamsWord;
      else
        raise ESepiInvalidMemoryReference.CreateRes(
          @SMemorySpaceOffsetMustBeWord);
      end;
    end;
    msTrueConst:
    begin
      if not (aoAcceptTrueConst in Options) then
        raise ESepiInvalidMemoryReference.CreateRes(@SMemoryCantBeTrueConst);
    end;
  end;

  FSpace := ASpace;
  FSpaceArgument := ASpaceArgument;
  FUnresolvedLocalVar := nil;
end;

{*
  Modifie l'espace m�moire sur base d'un meta
  Le meta peut �tre une une variable globale ou une constante globale (sous
  r�serve d'acceptation des constantes).
  @param Meta   Meta � pointer par l'espace m�moire
*}
procedure TSepiMemoryReference.SetSpace(Meta: TSepiMeta);
begin
  if Meta is TSepiConstant then
  begin
    // Global true constant
    with TSepiConstant(Meta) do
    begin
      if (not ConstType.NeedInit) and (ConstType.Size <= SizeOf(Extended)) then
      begin
        { Small constants which do not require initialization are directly
          written in the code. }
        SetSpace(msConstant);
        SetConstant(ValuePtr^);
      end else
      begin
        SetSpace(msTrueConst,
          MethodCompiler.UnitCompiler.MakeReference(Meta));
      end;
    end;
  end else if Meta is TSepiVariable then
  begin
    // Global variable or addressed constant
    SetSpace(msVariable, MethodCompiler.UnitCompiler.MakeReference(Meta));
  end else
  begin
    // Other types of meta are not accepted
    raise ESepiInvalidMemoryReference.CreateResFmt(@SMemoryCantAccessObject,
      [Meta.GetFullName]);
  end;
end;

{*
  Modifie l'espace m�moire sur base d'une variable locale
  @param Variable   Variable � pointer par l'espace m�moire
*}
procedure TSepiMemoryReference.SetSpace(Variable: TSepiLocalVar);
begin
  if Variable.IsFixed then
  begin
    if Variable.IsParam then
      SetSpace(msParamsBase, Variable.Offset)
    else
      SetSpace(msLocalsBase, Variable.Offset);

    if Variable.NeedDereference then
      AddOperation(adSimple);
  end else
  begin
    SetSpace(msUnresolvedLocalVar);
    FUnresolvedLocalVar := Variable;
  end;
end;

{*
  Modifie l'espace m�moire sur base d'un nom, qui est d'abord recherch�
  L'espace m�moire est recherch� dans les variables locales, puis dans les
  param�tres, puis via la m�thode LookFor de la m�thode qui est asssembl�e.
  @param Name   Nom de l'espace m�moire, � rechercher
*}
procedure TSepiMemoryReference.SetSpace(const Name: string);
var
  Obj: TObject;
begin
  Obj := MethodCompiler.LookFor(Name);
  if Obj is TSepiLocalVar then
    SetSpace(TSepiLocalVar(Obj))
  else if Obj is TSepiMeta then
    SetSpace(TSepiMeta(Obj))
  else
    raise ESepiMetaNotFoundError.CreateResFmt(@SSepiObjectNotFound, [Name]);
end;

{*
  Assigne la r�f�rence m�moire � une constante enti�re
  @param Value   Valeur constante
*}
procedure TSepiMemoryReference.SetAsConst(Value: Int64);
begin
  if Value = 0 then
    SetSpace(msZero)
  else
  begin
    SetSpace(msConstant);
    SetConstant(Value);
  end;
end;

{*
  Assigne la r�f�rence m�moire � une constante bool�enne
  @param Value   Valeur constante
*}
procedure TSepiMemoryReference.SetAsConst(Value: Boolean);
begin
  if not Value then
    SetSpace(msZero)
  else
  begin
    SetSpace(msConstant);
    SetConstant(Value);
  end;
end;

{*
  Assigne la r�f�rence m�moire � une constante flottante
  @param Value   Valeur constante
*}
procedure TSepiMemoryReference.SetAsConst(Value: Extended);
begin
  SetSpace(msConstant);
  case ConstSize of
    4: Single(FConstant^) := Value;
    8: Double(FConstant^) := Value;
  else
    SetConstant(Value);
  end;
end;

{*
  Assigne la r�f�rence m�moire � une constante Currency
  @param Value   Valeur constante
*}
procedure TSepiMemoryReference.SetAsConst(Value: Currency);
begin
  SetSpace(msConstant);
  SetConstant(Value);
end;

{*
  Supprime toutes les op�rations
*}
procedure TSepiMemoryReference.ClearOperations;
var
  I: Integer;
begin
  CheckUnsealed;

  for I := 0 to Length(FOperations)-1 do
    FOperations[I].MemOperationArg.Free;
  SetLength(FOperations, 0);
end;

{*
  Ajoute un d�r�f�rencement et une op�ration
  @param ADereference         D�r�f�rencement
  @param AOperation           Op�ration
  @param AConstOperationArg   Argument constant de l'op�ration, si applicable
  @return Argument m�moire de l'op�ration, si applicable (nil sinon)
*}
function TSepiMemoryReference.AddOperation(
  ADereference: TSepiAddressDereference; AOperation: TSepiAddressOperation;
  AConstOperationArg: Integer = 0): TSepiMemoryReference;
const
  OnlyShortConstArgOps = [
    aoPlusConstTimesMemShortint, aoPlusConstTimesMemSmallint,
    aoPlusConstTimesMemLongint
  ];
  ConstArgSizeToOp: array[1..4] of TSepiAddressOperation = (
    aoPlusConstShortint, aoPlusConstSmallint, aoPlusConstLongint,
    aoPlusConstLongint
  );
  MemArgSizes: array[aoPlusMemShortint..aoPlusConstTimesMemLongint] of Integer
    = (1, 2, 4, 1, 2, 4);
var
  Index: Integer;
begin
  CheckUnsealed;

  Index := Length(FOperations);

  // Check parameters consistency
  if (AOperation in OnlyShortConstArgOps) and
    (IntegerSize(AConstOperationArg) > 1) then
    raise ESepiInvalidMemoryReference.CreateRes(@SConstArgMustBeShort);

  // Try to compress dereference and operation
  if (Index > 0) and (ADereference = adNone) and
    (FOperations[Index-1].Operation = aoNone) then
  begin
    // Compression OK
    Dec(Index);
  end else
  begin
    // Some checks
    if Length(FOperations) >= MaxOperationCount then
      raise ESepiInvalidMemoryReference.CreateRes(@STooManyOperations);

    if Space = msZero then
      raise ESepiInvalidMemoryReference.CreateRes(
        @SZeroMemoryCantHaveOperations);

    // Add a new operation
    SetLength(FOperations, Index+1);

    // Set dereference
    FOperations[Index].Dereference := ADereference;
  end;

  // Set operation
  with FOperations[Index] do
  begin
    Operation := AOperation;
    ConstOperationArg := AConstOperationArg;

    // Adapt operation to const arg size
    if Operation in [aoPlusConstShortint..aoPlusConstLongint] then
      Operation := ConstArgSizeToOp[IntegerSize(AConstOperationArg)];

    // Create memory reference
    if Operation in OpsWithMemArg then
    begin
      MemOperationArg := TSepiMemoryReference.Create(MethodCompiler,
        aoAcceptAllConsts, MemArgSizes[Operation]);
    end else
      MemOperationArg := nil;

    Result := MemOperationArg;
  end;
end;

{*
  Ajoute un d�r�f�rencement
  @param ADereference   D�r�f�rencement
*}
procedure TSepiMemoryReference.AddOperation(
  ADereference: TSepiAddressDereference);
begin
  AddOperation(ADereference, aoNone);
end;

{*
  Ajoute une op�ration
  @param AOperation           Op�ration
  @param AConstOperationArg   Argument constant de l'op�ration, si applicable
  @return Argument m�moire de l'op�ration, si applicable (nil sinon)
*}
function TSepiMemoryReference.AddOperation(AOperation: TSepiAddressOperation;
  AConstOperationArg: Integer = 0): TSepiMemoryReference;
begin
  Result := AddOperation(adNone, AOperation, AConstOperationArg);
end;

{*
  Teste s'il est possible de retirer un d�r�f�rencement � la fin
  @return True si c'est possible, False sinon
*}
function TSepiMemoryReference.CanRemoveDereference: Boolean;
var
  Index: Integer;
begin
  Index := Length(FOperations)-1;
  Result := (Index > 0) and (FOperations[Index].Operation = aoNone) and
    (FOperations[Index].Dereference <> adNone);
end;

{*
  Retire le d�r�f�rencement en bout d'op�rations
  L'appel � cette m�thode n'est pas valide si CanRemoveDereference renvoie
  False.
*}
procedure TSepiMemoryReference.RemoveDereference;
var
  Index: Integer;
begin
  CheckUnsealed;

  if not CanRemoveDereference then
    raise ESepiMemoryReferenceError.Create(SCantRemoveDereference);

  Index := Length(FOperations)-1;
  if FOperations[Index].Dereference = adSimple then
    SetLength(FOperations, Index)
  else
    FOperations[Index].Dereference := adSimple;
end;

{*
  R�cup�re la constante
  La r�f�rence m�moire doit accepter les constantes non nulles.
  @param AConstant   En sortie : valeur de la constante
*}
procedure TSepiMemoryReference.GetConstant(var AConstant);
begin
  Move(FConstant^, AConstant, ConstSize);
end;

{*
  Sp�cifie la constante
  La r�f�rence m�moire doit accepter les constantes non nulles.
  @param AConstant   Nouvelle valeur de la constante
*}
procedure TSepiMemoryReference.SetConstant(const AConstant);
begin
  CheckUnsealed;

  Move(AConstant, FConstant^, ConstSize);
end;

{*
  Scelle la r�f�rence m�moire
  D�s lors qu'une r�f�rence m�moire est scell�e, toute tentative de modification
  de celle-ci provoquera une exception.
*}
procedure TSepiMemoryReference.Seal;
begin
  FIsSealed := True;
end;

{*
  Construit la r�f�rence m�moire
*}
procedure TSepiMemoryReference.Make;
var
  I: Integer;
begin
  // Resolve the local var, if needed
  if Space = msUnresolvedLocalVar then
  begin
    FIsSealed := False;
    SetSpace(FUnresolvedLocalVar);
  end;

  // Seal the memory reference
  Seal;

  // Head byte (TSepiMemoryRef)
  FSize := SizeOf(TSepiMemoryRef);

  // Space argument
  case Space of
    msConstant:
      Inc(FSize, ConstSize);
    msLocalsByte, msParamsByte:
      Inc(FSize, SizeOf(Byte));
    msLocalsWord, msParamsWord:
      Inc(FSize, SizeOf(Word));
    msTrueConst, msVariable:
      Inc(FSize, SizeOf(Integer));
  end;

  // Operations
  for I := 0 to Length(FOperations)-1 do
  begin
    with FOperations[I] do
    begin
      // Head byte (TSepiAddressDerefAndOp)
      Inc(FSize, SizeOf(TSepiAddressDerefAndOp));

      // Const argument
      case Operation of
        aoPlusConstShortint, aoPlusConstTimesMemShortint,
          aoPlusConstTimesMemSmallint, aoPlusConstTimesMemLongint:
          Inc(FSize, SizeOf(Shortint));
        aoPlusConstSmallint:
          Inc(FSize, SizeOf(Smallint));
        aoPlusConstLongint:
          Inc(FSize, SizeOf(Longint));
      end;

      // Memory argument
      if Assigned(MemOperationArg) then
      begin
        MemOperationArg.Make;
        Inc(FSize, MemOperationArg.Size);
      end;
    end;
  end;
end;

{*
  Ecrit la r�f�rence m�moire dans un flux
  @param Stream   Flux de destination
*}
procedure TSepiMemoryReference.WriteToStream(Stream: TStream);
var
  MemRef: TSepiMemoryRef;
  I: Integer;
  DerefAndOp: TSepiAddressDerefAndOp;
begin
  // Head byte (TSepiMemoryRef)
  MemRef := MemoryRefEncode(Space, OperationCount);
  Stream.WriteBuffer(MemRef, SizeOf(TSepiMemoryRef));

  // Space argument
  case Space of
    msConstant:
      Stream.WriteBuffer(FConstant^, ConstSize);
    msLocalsByte, msParamsByte:
      Stream.WriteBuffer(FSpaceArgument, SizeOf(Byte));
    msLocalsWord, msParamsWord:
      Stream.WriteBuffer(FSpaceArgument, SizeOf(Word));
    msTrueConst, msVariable:
      Stream.WriteBuffer(FSpaceArgument, SizeOf(Integer));
  end;

  // Operations
  for I := 0 to Length(FOperations)-1 do
  begin
    with FOperations[I] do
    begin
      // Head byte (TSepiAddressDerefAndOp)
      DerefAndOp := AddressDerefAndOpEncode(Dereference, Operation);
      Stream.WriteBuffer(DerefAndOp, SizeOf(TSepiAddressDerefAndOp));

      // Const argument
      case Operation of
        aoPlusConstShortint, aoPlusConstTimesMemShortint,
          aoPlusConstTimesMemSmallint, aoPlusConstTimesMemLongint:
          Stream.WriteBuffer(ConstOperationArg, SizeOf(Shortint));
        aoPlusConstSmallint:
          Stream.WriteBuffer(ConstOperationArg, SizeOf(Smallint));
        aoPlusConstLongint:
          Stream.WriteBuffer(ConstOperationArg, SizeOf(Longint));
      end;

      // Memory argument
      if Assigned(MemOperationArg) then
        MemOperationArg.WriteToStream(Stream);
    end;
  end;
end;

{---------------------}
{ TSepiJumpDest class }
{---------------------}

{*
  Cr�e une destination de JUMP
  @param AMethodCompiler   Compilateur de m�thode
*}
constructor TSepiJumpDest.Create(AMethodCompiler: TSepiMethodCompiler);
begin
  inherited Create;

  FMethodCompiler := AMethodCompiler;

  FInstructionRef := nil;
end;

{*
  Position la destination du Jump sur un label nomm�
  @param NamedLabel   Label nomm�
*}
procedure TSepiJumpDest.SetToLabel(NamedLabel: TSepiNamedLabel);
begin
  InstructionRef := NamedLabel.BeforeRef;
end;

{*
  Position la destination du Jump sur un label nomm�
  @param LabelName   Nom du label
*}
procedure TSepiJumpDest.SetToLabel(const LabelName: string;
  Create: Boolean = False);
begin
  SetToLabel(MethodCompiler.FindLabel(LabelName, Create));
end;

{*
  Construit la destination de Jump
*}
procedure TSepiJumpDest.Make;
begin
  Assert(InstructionRef <> nil);
end;

{*
  Calcule l'offset
  @param FromPos   Position de provenance
  @return Offset
*}
function TSepiJumpDest.MakeOffset(FromPos: Integer): Integer;
begin
  Result := InstructionRef.Position - FromPos;
end;

{*
  Ecrit la destination de JUMP dans un flux
  @param Stream    Flux de destination
  @param FromPos   Position de provenance
*}
procedure TSepiJumpDest.WriteToStream(Stream: TStream; FromPos: Integer);
var
  Offset: Smallint;
begin
  Offset := MakeOffset(FromPos);
  Stream.WriteBuffer(Offset, SizeOf(Smallint));
end;

{*
  Ecrit la destination de JUMP dans un flux
  @param Stream   Flux de destination
*}
procedure TSepiJumpDest.WriteToStream(Stream: TStream);
begin
  WriteToStream(Stream, Stream.Position + SizeOf(Smallint));
end;

end.

