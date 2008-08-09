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
  Assembleur Sepi
  @author sjrd
  @version 1.0
*}
unit SepiAssembler;

interface

uses
  SysUtils, Classes, Contnrs, ScUtils, SepiReflectionCore, SepiMembers,
  SepiOpCodes, SepiReflectionConsts;

resourcestring
  SNoInstruction = 'Aucune instruction';
  SLabelAlreadyExists = 'Le label ''%s'' existe d�j�';
  SLabelNotFound = 'Label ''%s'' non trouv�';
  SMixBetweenAssemblers = 'M�lange de donn�es entre diff�rents assembleurs';
  SMemoryCantBeZero = 'La r�f�rence m�moire ne peut �tre z�ro';
  SMemoryCantBeConstant = 'La r�f�rence m�moire ne peut �tre constante';
  SMemoryCantBeTrueConst =
    'La r�f�rence m�moire ne peut �tre une vraie constante';
  SMemorySpaceOffsetMustBeWord =
    'L''offset d''espace m�moire doit �tre contenu dans un Word';
  SMemoryCantAccessObject = 'Impossible d''acc�der � l''objet %s';
  STooManyOperations =
    'Une r�f�rence m�moire ne peut avoir que 15 op�rations maximum';
  SZeroMemoryCantHaveOperations =
    'Une r�f�rence m�moire vers des 0 ne peut avoir d''op�rations';
  SConstArgMustBeShort =
    'L''argument constant doit �tre contenu dans un Shortint';
  SJumpDestMustBeFixed = 'La destination du JUMP doit �tre fixe';
  SJumpMinFromPosGreaterThanMaxFromPos =
    'La position minimale (%d) est sup�rieure � la position maximale (%d)';
  SDestCantBeBetweenMinAndMaxFromPos =
    'La destination d''un JUMP ne peut �tre entre ses positions min et max';

type
  TSepiAsmInstrList = class;
  TSepiInstructionList = class;
  TSepiMethodAssembler = class;
  TSepiUnitAssembler = class;
  TSepiMemoryReference = class;

  {*
    Erreur d'assemblage Sepi
  *}
  ESepiAssemblerError = class(Exception);

  {*
    Label non trouv� lors de l'assemblage Sepi
  *}
  ESepiLabelError = class(ESepiAssemblerError);

  {*
    R�f�rence m�moire invalide d'apr�s l'instruction contenante
  *}
  ESepiInvalidMemoryReference = class(ESepiAssemblerError);

  {*
    Destination de JUMP invalide
  *}
  ESepiInvalidJumpDest = class(ESepiAssemblerError);

  {*
    R�f�rence � une instruction
    @author sjrd
    @version 1.0
  *}
  TSepiInstructionRef = class(TObject)
  private
    FMethodAssembler: TSepiMethodAssembler; /// Assembleur de code

    FInstructionIndex: Integer; /// Position de l'instruction r�f�renc�e

    procedure SetInstructionIndex(Value: Integer);

    function GetPosition: Integer;
  public
    constructor Create(AMethodAssembler: TSepiMethodAssembler);

    property MethodAssembler: TSepiMethodAssembler read FMethodAssembler;
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
    FMethodAssembler: TSepiMethodAssembler; /// Assembleur de code
    FUnitAssembler: TSepiUnitAssembler;     /// Assembleur d'unit�

    FBeforeRef: TSepiInstructionRef; /// R�f�rence avant cette instruction
    FAfterRef: TSepiInstructionRef;  /// R�f�rence apr�s cette instruction
  protected
    procedure CustomCompile; virtual;
  public
    constructor Create(AMethodAssembler: TSepiMethodAssembler);
    destructor Destroy; override;

    procedure AfterConstruction; override;

    procedure Compile;

    property MethodAssembler: TSepiMethodAssembler read FMethodAssembler;
    property UnitAssembler: TSepiUnitAssembler read FUnitAssembler;

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
    constructor Create(AMethodAssembler: TSepiMethodAssembler);

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
    constructor Create(AMethodAssembler: TSepiMethodAssembler);
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
    FMethodAssembler: TSepiMethodAssembler; /// Assembleur de code

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
    constructor Create(AMethodAssembler: TSepiMethodAssembler);
    destructor Destroy; override;

    procedure Clear;

    procedure Assemble;
    procedure WriteToStream(Stream: TStream);

    property MethodAssembler: TSepiMethodAssembler read FMethodAssembler;

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
    constructor Create(AMethodAssembler: TSepiMethodAssembler;
      const AName: string);

    procedure AfterConstruction; override;

    property Name: string read FName;
  end;

  {*
    Informations d'initialisation d'une variable locale
    @author sjrd
    @version 1.0
  *}
  TLocalInfo = record
    TypeRef: Integer; /// R�f�rence au type de la variable
    Offset: Integer;  /// Offset de la variable
  end;

  {*
    Assembleur du code d'une m�thode Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiMethodAssembler = class(TObject)
  private
    FUnitAssembler: TSepiUnitAssembler; /// Assembleur d'unit�

    FObjFreeList: TObjectList; /// Liste des objets � lib�rer en fin de vie

    FSepiMethod: TSepiMethod; /// M�thode Sepi correspondante
    FLocals: TSepiRecordType; /// Variables locales

    FInstructions: TSepiInstructionList; /// Instructions
    FAsmInstructions: TSepiAsmInstrList; /// Instructions assembleur
    FSize: Integer;                      /// Taille totale (apr�s assemblage)

    FLastInstruction: TSepiAsmInstrList;

    FNamedLabels: TStrings; /// Labels nomm�s (paire nom/instruction)

    FLocalsInfo: array of TLocalInfo; /// Informations sur les locales

    procedure SetLabel(NamedLabel: TSepiNamedLabel);
  protected
    property AsmInstructions: TSepiAsmInstrList read FAsmInstructions;
  public
    constructor Create(AUnitAssembler: TSepiUnitAssembler;
      ASepiMethod: TSepiMethod);
    destructor Destroy; override;

    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure AddObjToFreeList(Obj: TObject);

    function LookFor(const Name: string): TObject;

    function LabelExists(const LabelName: string): Boolean;
    function FindLabel(const LabelName: string;
      Create: Boolean = False): TSepiNamedLabel;

    procedure Assemble;
    procedure WriteToStream(Stream: TStream);
    procedure WriteLocalsInfo(Stream: TStream);

    property UnitAssembler: TSepiUnitAssembler read FUnitAssembler;
    property SepiMethod: TSepiMethod read FSepiMethod;
    property Locals: TSepiRecordType read FLocals;

    property Instructions: TSepiInstructionList read FInstructions;
    property Size: Integer read FSize;
  end;

  {*
    Assembleur d'unit� Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiUnitAssembler = class(TObject)
  private
    FSepiUnit: TSepiUnit;  /// Unit� Sepi
    FMethods: TObjectList; /// Assembleurs de m�thodes

    FReferences: TObjectList; /// R�f�rences

    function GetMethodCount: Integer;
    function GetMethods(Index: Integer): TSepiMethodAssembler;
  public
    constructor Create(ASepiUnit: TSepiUnit);
    destructor Destroy; override;

    function MakeReference(Meta: TSepiMeta): Integer;

    procedure WriteToStream(Stream: TStream);

    property SepiUnit: TSepiUnit read FSepiUnit;

    property MethodCount: Integer read GetMethodCount;
    property Methods[Index: Integer]: TSepiMethodAssembler read GetMethods;
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
    FMethodAssembler: TSepiMethodAssembler; /// Assembleur de m�thode

    FOptions: TSepiAddressOptions; /// Options
    FConstSize: Integer;           /// Taille d'une constante

    FSpace: TSepiMemorySpace; /// Espace d'adressage
    FSpaceArgument: Integer;  /// Argument de l'espace d'adressage (offset)

    FOperations: array of TSepiAddressDerefAndOpRec; /// Op�rations

    FConstant: Pointer; /// Constante (si Space = msConstant) - 0 par d�faut

    FSize: Integer; /// Taille de la r�f�rence m�moire dans le code

    function GetOperationCount: Integer;
    function GetOperations(Index: Integer): TSepiAddressDerefAndOpRec;
  public
    constructor Create(AMethodAssembler: TSepiMethodAssembler;
      AOptions: TSepiAddressOptions = []; AConstSize: Integer = 0);
    destructor Destroy; override;

    procedure SetSpace(ASpace: TSepiMemorySpace;
      ASpaceArgument: Integer = 0); overload;
    procedure SetSpace(Meta: TSepiMeta); overload;
    procedure SetSpace(Param: TSepiParam; AutoDeref: Boolean = True); overload;
    procedure SetSpace(const Name: string;
      AutoDerefParam: Boolean = True); overload;

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

    procedure GetConstant(var AConstant);
    procedure SetConstant(const AConstant);

    procedure Make;

    procedure WriteToStream(Stream: TStream);

    property MethodAssembler: TSepiMethodAssembler read FMethodAssembler;

    property Options: TSepiAddressOptions read FOptions;
    property ConstSize: Integer read FConstSize;
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
    FMethodAssembler: TSepiMethodAssembler; /// Assembleur de m�thode

    FInstructionRef: TSepiInstructionRef; /// Ref � l'instruction destination
  public
    constructor Create(AMethodAssembler: TSepiMethodAssembler);

    procedure SetToLabel(NamedLabel: TSepiNamedLabel); overload;
    procedure SetToLabel(const LabelName: string;
      Create: Boolean = False); overload;

    procedure Make;

    function MakeOffset(FromPos: Integer): Integer;

    procedure WriteToStream(Stream: TStream; FromPos: Integer); overload;
    procedure WriteToStream(Stream: TStream); overload;

    property MethodAssembler: TSepiMethodAssembler read FMethodAssembler;

    property InstructionRef: TSepiInstructionRef
      read FInstructionRef write FInstructionRef;
  end;

const // don't localize
  LocalVarsName = '$Locals';  /// Nom du type record des variables locales
  ResultFieldName = 'Result'; /// Nom de la variable locale Result

const
  MaxOperationCount = $0F; /// Nombre maximum d'op�rations sur une adresse

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
  @param AMethodAssembler   Assembleur de m�thode
*}
constructor TSepiInstruction.Create(AMethodAssembler: TSepiMethodAssembler);
begin
  inherited Create;

  FMethodAssembler := AMethodAssembler;
  FUnitAssembler := FMethodAssembler.UnitAssembler;

  FBeforeRef := TSepiInstructionRef.Create(MethodAssembler);
  FAfterRef := TSepiInstructionRef.Create(MethodAssembler);
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

  MethodAssembler.AddObjToFreeList(Self);
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
  Compile l'instruction
*}
procedure TSepiInstruction.Compile;
begin
  FBeforeRef.SetInstructionIndex(MethodAssembler.FAsmInstructions.CurrentPos);

  CustomCompile;

  FAfterRef.SetInstructionIndex(MethodAssembler.FAsmInstructions.CurrentPos);
end;

{---------------------------}
{ TSepiInstructionRef class }
{---------------------------}

{*
  Cr�e une r�f�rence � une instruction
  @param AMethodAssembler   Assembleur de m�thode
*}
constructor TSepiInstructionRef.Create(AMethodAssembler: TSepiMethodAssembler);
begin
  inherited Create;

  FMethodAssembler := AMethodAssembler;
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

  Instructions := MethodAssembler.AsmInstructions;

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
  @param AMethodAssembler   Assembleur de m�thode
*}
constructor TSepiAsmInstr.Create(AMethodAssembler: TSepiMethodAssembler);
begin
  inherited Create(AMethodAssembler);

  FOpCode := ocNope;
end;

{*
  Compile l'instruction assembleur
  La compilation d'une instruction assembleur consiste uniquement � s'ajouter �
  la liste des instructions assembleur de son assembleur de m�thode.
*}
procedure TSepiAsmInstr.CustomCompile;
begin
  MethodAssembler.FAsmInstructions.Add(Self);
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
  @param AMethodAssembler   Assembleur de m�thode
*}
constructor TSepiInstructionList.Create(AMethodAssembler: TSepiMethodAssembler);
begin
  inherited Create(AMethodAssembler);

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
  @param AMethodAssembler   Assembleur de m�thode
*}
constructor TSepiAsmInstrList.Create(AMethodAssembler: TSepiMethodAssembler);
begin
  inherited Create;

  FMethodAssembler := AMethodAssembler;
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
  Ecrit l'instruction dans un flux
  WriteToStream doit �crire exactement autant d'octets dans le flux que la
  valeur de la propri�t� Size.
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
  @param AMethodAssembler   Assembleur de m�thode
  @param AName              Nom du label
*}
constructor TSepiNamedLabel.Create(AMethodAssembler: TSepiMethodAssembler;
  const AName: string);
begin
  inherited Create(AMethodAssembler);

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
  MethodAssembler.SetLabel(Self);
end;

{----------------------------}
{ TSepiMethodAssembler class }
{----------------------------}

{*
  Cr�e un nouvel assembleur de m�thode Sepi
  Si la m�thode poss�de d�j� des variables locales - c'est-�-dire si un type
  record dont le nom est LocalVarsName est pr�sent - celles-ci sont prises
  comme variables locales d'assemblage. Sinon, l'assembleur cr�e un record de
  variables locales, et le lib�rera � sa destruction.
  @param AUnitAssembler   Assembleur d'unit�
  @param ASepiMethod      M�thode Sepi
*}
constructor TSepiMethodAssembler.Create(AUnitAssembler: TSepiUnitAssembler;
  ASepiMethod: TSepiMethod);
begin
  inherited Create;

  FUnitAssembler := AUnitAssembler;
  FSepiMethod := ASepiMethod;

  FObjFreeList := TObjectList.Create(False);

  // Fetch locals or create them if they don't exist

  FLocals := SepiMethod.GetMeta(LocalVarsName) as TSepiRecordType;
  if FLocals = nil then
    FLocals := TSepiRecordType.Create(SepiMethod, LocalVarsName);

  with SepiMethod.Signature do
  begin
    if (FLocals.ChildCount = 0) and
      (not (ReturnType.SafeResultBehavior in [rbNone, rbParameter])) then
      FLocals.AddField(ResultFieldName, ReturnType);
  end;

  // Initialize other fields

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
destructor TSepiMethodAssembler.Destroy;
begin
  FNamedLabels.Free;
  FAsmInstructions.Free;

  FObjFreeList.Free;

  inherited;
end;

{*
  Notifie l'existence d'un label nomm�
  @param NamedLabel   Label nomm� � ajouter
*}
procedure TSepiMethodAssembler.SetLabel(NamedLabel: TSepiNamedLabel);
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
procedure TSepiMethodAssembler.AfterConstruction;
begin
  inherited;

  UnitAssembler.FMethods.Add(Self);
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodAssembler.BeforeDestruction;
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
procedure TSepiMethodAssembler.AddObjToFreeList(Obj: TObject);
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
function TSepiMethodAssembler.LookFor(const Name: string): TObject;
begin
  Result := Locals.GetMeta(Name);
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
function TSepiMethodAssembler.LabelExists(const LabelName: string): Boolean;
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
function TSepiMethodAssembler.FindLabel(
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
  Assemble les instructions
*}
procedure TSepiMethodAssembler.Assemble;
var
  Count: Integer;
  I: Integer;
  LocalVar: TSepiField;
begin
  // Local variables must have been completed
  if not Locals.Completed then
    Locals.Complete;

  // Compile
  AsmInstructions.Clear;
  Instructions.Compile;

  // Assemble
  AsmInstructions.Assemble;
  FSize := AsmInstructions.Size;

  // Make locals info
  SetLength(FLocalsInfo, Locals.ChildCount);
  Count := 0;
  for I := 0 to Locals.ChildCount-1 do
  begin
    // Ignore non-field children
    if not (Locals.Children[I] is TSepiField) then
      Continue;

    // Ignore variables whose type doesn't require initialization
    LocalVar := TSepiField(Locals.Children[I]);
    if not LocalVar.FieldType.NeedInit then
      Continue;

    // Add an item to locals info
    with FLocalsInfo[Count] do
    begin
      TypeRef := UnitAssembler.MakeReference(LocalVar.FieldType);
      Offset := LocalVar.Offset;
      Inc(Count);
    end;
  end;
  SetLength(FLocalsInfo, Count);
end;

{*
  Ecrit la m�thode dans un flux (tel que TSepiRuntimeMethod puisse le lire)
  La m�thode doit avoir �t� assembl�e au pr�alable via la m�thode Assemble.
  @param Stream   Flux de destination
*}
procedure TSepiMethodAssembler.WriteToStream(Stream: TStream);
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
procedure TSepiMethodAssembler.WriteLocalsInfo(Stream: TStream);
var
  Count: Integer;
begin
  Count := Length(FLocalsInfo);
  Stream.WriteBuffer(Count, 4);

  Stream.WriteBuffer(FLocalsInfo[0], Count*SizeOf(TLocalInfo));
end;

{--------------------------}
{ TSepiUnitAssembler class }
{--------------------------}

{*
  Cr�e un nouvel assembleur d'unit� Sepi
  @param ASepiUnit   Unit� Sepi � assembler
*}
constructor TSepiUnitAssembler.Create(ASepiUnit: TSepiUnit);
begin
  inherited Create;

  FSepiUnit := ASepiUnit;
  FMethods := TObjectList.Create;
  FReferences := TObjectList.Create(False);
end;

{*
  [@inheritDoc]
*}
destructor TSepiUnitAssembler.Destroy;
begin
  FReferences.Free;
  FMethods.Free;

  inherited;
end;

{*
  Nombre d'assembleurs de m�thode
  @return Nombre d'assembleurs de m�thode
*}
function TSepiUnitAssembler.GetMethodCount: Integer;
begin
  Result := FMethods.Count;
end;

{*
  Tableau zero-based des assembleurs de m�thode
  @param Index   Index d'un assembleur
  @return Assembleur � l'index sp�cifi�
*}
function TSepiUnitAssembler.GetMethods(Index: Integer): TSepiMethodAssembler;
begin
  Result := TSepiMethodAssembler(FMethods[Index]);
end;

{*
  Construit un num�ro de r�f�rence � un meta Sepi
  @param Meta   Meta pour lequel construire un num�ro de r�f�rence
  @return Num�ro de r�f�rence du meta
*}
function TSepiUnitAssembler.MakeReference(Meta: TSepiMeta): Integer;
begin
  Result := FReferences.IndexOf(Meta);
  if Result < 0 then
    Result := FReferences.Add(Meta);
end;

{*
  Ecrit l'unit� assembl�e dans un flux
  @param Stream   Flux destination
*}
procedure TSepiUnitAssembler.WriteToStream(Stream: TStream);
var
  I, Count: Integer;
begin
  // Assemble methods
  for I := 0 to MethodCount-1 do
    Methods[I].Assemble;

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
  @param AOptions     Options
  @param AConstSize   Taille de constante
*}
constructor TSepiMemoryReference.Create(AMethodAssembler: TSepiMethodAssembler;
  AOptions: TSepiAddressOptions = []; AConstSize: Integer = 0);
begin
  inherited Create;

  FMethodAssembler := AMethodAssembler;

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
  [@inheritDoc]
*}
destructor TSepiMemoryReference.Destroy;
begin
  if Assigned(FConstant) then
    FreeMem(FConstant);
  ClearOperations;

  inherited;
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
  mpZero (qui ne supporte pas les op�rations).
  @param Value   Nouvelle valeur d'espace m�moire
*}
procedure TSepiMemoryReference.SetSpace(ASpace: TSepiMemorySpace;
  ASpaceArgument: Integer = 0);
begin
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
end;

{*
  Modifie l'espace m�moire sur base d'un meta
  Le meta peut �tre une variable locale, une variable globale ou une constante
  globale (sous r�serve d'acceptation des constantes).
  @param Meta   Meta � pointer par l'espace m�moire
*}
procedure TSepiMemoryReference.SetSpace(Meta: TSepiMeta);
begin
  if Meta is TSepiField then
  begin
    // Local variable

    if Meta.Owner <> MethodAssembler.Locals then
      raise ESepiInvalidMemoryReference.CreateResFmt(@SMemoryCantAccessObject,
        [Meta.GetFullName]);

    SetSpace(msLocalsBase, TSepiField(Meta).Offset);
  end else if Meta is TSepiConstant then
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
          MethodAssembler.UnitAssembler.MakeReference(Meta));
      end;
    end;
  end else if Meta is TSepiVariable then
  begin
    // Global variable or addressed constant
    SetSpace(msVariable, MethodAssembler.UnitAssembler.MakeReference(Meta));
  end else
  begin
    // Other types of meta are not accepted
    raise ESepiInvalidMemoryReference.CreateResFmt(@SMemoryCantAccessObject,
      [Meta.GetFullName]);
  end;
end;

{*
  Modifie l'espace m�moire sur base d'un param�tre
  Le param�tre doit �tre de la m�thode courante. Si AutoDeref vaut True, et que
  le param�tre est pass� par adresse, le d�r�f�rencement est ajout�
  automatiquement.
  @param Param       Param�tre � pointer par l'espace m�moire
  @param AutoDeref   D�r�f�rence automatiquement
*}
procedure TSepiMemoryReference.SetSpace(Param: TSepiParam;
  AutoDeref: Boolean = True);
begin
  if Param.Owner <> MethodAssembler.SepiMethod.Signature then
    raise ESepiInvalidMemoryReference.CreateResFmt(@SMemoryCantAccessObject,
      [Param.Owner.Owner.GetFullName + '.' + Param.Name]);

  SetSpace(msParamsBase, Param.CallInfo.SepiStackOffset);

  if AutoDeref and Param.CallInfo.ByAddress then
    AddOperation(adSimple);
end;

{*
  Modifie l'espace m�moire sur base d'un nom, qui est d'abord recherch�
  L'espace m�moire est recherch� dans les variables locales, puis dans les
  param�tres, puis via la m�thode LookFor de la m�thode qui est asssembl�e.
  Si AutoDerefParam vaut True, et que c'est un param�tre est pass� par adresse,
  le d�r�f�rencement est ajout� automatiquement.
  @param Name             Nom de l'espace m�moire, � rechercher
  @param AutoDerefParam   D�r�f�rence automatiquement les param�tres
*}
procedure TSepiMemoryReference.SetSpace(const Name: string;
  AutoDerefParam: Boolean = True);
var
  Obj: TObject;
begin
  Obj := MethodAssembler.LookFor(Name);
  if Obj is TSepiMeta then
    SetSpace(TSepiMeta(Obj))
  else if Obj is TSepiParam then
    SetSpace(TSepiParam(Obj), AutoDerefParam)
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
      MemOperationArg := TSepiMemoryReference.Create(MethodAssembler,
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
  Move(AConstant, FConstant^, ConstSize);
end;

{*
  Construit la r�f�rence m�moire
*}
procedure TSepiMemoryReference.Make;
var
  I: Integer;
begin
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
  @param AMethodAssembler   Assembleur de m�thode
*}
constructor TSepiJumpDest.Create(AMethodAssembler: TSepiMethodAssembler);
begin
  inherited Create;

  FMethodAssembler := AMethodAssembler;

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
  SetToLabel(MethodAssembler.FindLabel(LabelName, Create));
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

