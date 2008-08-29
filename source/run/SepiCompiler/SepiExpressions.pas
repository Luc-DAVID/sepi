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
  Expressions Sepi
  @author sjrd
  @version 1.0
*}
unit SepiExpressions;

interface

uses
  SysUtils, ScUtils, ScInterfaces, SepiReflectionCore, SepiMembers,
  SepiOpCodes, SepiCompiler, SepiCompilerErrors, SepiCompilerConsts,
  SepiAsmInstructions;

type
  /// Op�ration Sepi
  TSepiOperation = opAdd..opCmpGE;

const
  /// Toutes les op�rations valides
  opAllOps = [Low(TSepiOperation)..High(TSepiOperation)];

  /// Op�rations unaires
  opUnaryOps = [opNegate, opNot];

  /// Operations binaires (dont comparaisons)
  opBinaryOps = opAllOps - opUnaryOps;

  /// Op�rations de comparaison
  opComparisonOps = [opCmpEQ..opCmpGE];

type
  {*
    Valeur qui peut �tre lue � l'ex�cution
    @author sjrd
    @version 1.0
  *}
  ISepiReadableValue = interface(ISepiExpressionPart)
    ['{D7207F63-22F1-41C7-8366-2D4A87DD5200}']

    function GetValueType: TSepiType;

    procedure CompileRead(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
      TempVars: TSepiTempVarsLifeManager);

    property ValueType: TSepiType read GetValueType;
  end;

  {*
    Valeur qui peut �tre modifi�e � l'ex�cution
    @author sjrd
    @version 1.0
  *}
  ISepiWritableValue = interface(ISepiExpressionPart)
    ['{E5E9C42F-E9A2-4B13-AE79-E1229013007D}']

    function GetValueType: TSepiType;

    procedure CompileWrite(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; Source: ISepiReadableValue);

    property ValueType: TSepiType read GetValueType;
  end;

  {*
    Valeur dont on peut r�cup�rer l'adresse � l'ex�cution
    @author sjrd
    @version 1.0
  *}
  ISepiAddressableValue = interface(ISepiExpressionPart)
    ['{096E1AD8-04D6-4DA1-9426-A307C7965F73}']

    function GetAddressType: TSepiType;

    procedure CompileLoadAddress(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
      TempVars: TSepiTempVarsLifeManager);

    property AddressType: TSepiType read GetAddressType;
  end;

  {*
    Valeur constante � la compilation
    @author sjrd
    @version 1.0
  *}
  ISepiConstantValue = interface(ISepiExpressionPart)
    ['{78955B99-2FAA-487D-B295-2986E8C720DF}']

    function GetValueType: TSepiType;
    function GetValuePtr: Pointer;

    property ValueType: TSepiType read GetValueType;
    property ValuePtr: Pointer read GetValuePtr;
  end;

  {*
    Valeur � acc�s direct (par opposition � une valeur � calculer)
    @author sjrd
    @version 1.0
  *}
  ISepiDirectValue = interface(ISepiExpressionPart)
    ['{12678933-C5A4-4BBA-9BBF-3E3BF30B4AD5}']

    function GetValueType: TSepiType;

    property ValueType: TSepiType read GetValueType;
  end;

  {*
    Expression qui peut �tre appel�e
    @author sjrd
    @version 1.0
  *}
  ISepiCallable = interface(ISepiExpressionPart)
    ['{CD26F811-9B78-4F42-ACD7-82B1FB93EA3F}']

    function GetParamCount: Integer;
    function GetParams(Index: Integer): ISepiExpression;
    function GetParamsCompleted: Boolean;

    procedure AddParam(Param: ISepiExpression);
    procedure CompleteParams;

    function GetReturnType: TSepiType;

    procedure CompileNoResult(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList);

    property ParamCount: Integer read GetParamCount;
    property Params[Index: Integer]: ISepiExpression read GetParams;
    property ParamsCompleted: Boolean read GetParamsCompleted;

    property ReturnType: TSepiType read GetReturnType;
  end;

  {*
    Propri�t�
    @author sjrd
    @version 1.0
  *}
  ISepiProperty = interface(ISepiExpressionPart)
    ['{9C5A0B51-BDB2-45FA-B2D4-179763CB7F16}']

    function GetParamCount: Integer;
    function GetParams(Index: Integer): ISepiExpression;
    procedure SetParams(Index: Integer; Value: ISepiExpression);
    function GetParamsCompleted: Boolean;

    procedure CompleteParams;

    function GetValueType: TSepiType;

    property ParamCount: Integer read GetParamCount;
    property Params[Index: Integer]: ISepiExpression
      read GetParams write SetParams;
    property ParamsCompleted: Boolean read GetParamsCompleted;

    property ValueType: TSepiType read GetValueType;
  end;

  {*
    Expression nil
    @author sjrd
    @version 1.0
  *}
  ISepiNilValue = interface(ISepiExpressionPart)
    ['{2574C3DC-87FE-426C-931D-5230267A1573}']
  end;

  {*
    Expression qui repr�sente un meta
    @author sjrd
    @version 1.0
  *}
  ISepiMetaExpression = interface(ISepiExpressionPart)
    ['{444E8E70-1173-44E5-AA91-5B28629A9AA4}']

    function GetMeta: TSepiMeta;

    property Meta: TSepiMeta read GetMeta;
  end;

  {*
    Expression qui repr�sente un type
    @author sjrd
    @version 1.0
  *}
  ISepiTypeExpression = interface(ISepiExpressionPart)
    ['{F8DB8648-9F7B-421A-9BEC-0C4AEC9D1C56}']

    function GetType: TSepiType;

    property ExprType: TSepiType read GetType;
  end;

  {*
    Impl�mentation de base de ISepiExpressionPart
    La majorit� des classes devant impl�menter ISepiExpressionPart devraient
    h�riter de cette classe.
    @author sjrd
    @version 1.0
  *}
  TSepiCustomExpressionPart = class(TDynamicallyLinkedObject,
    ISepiExpressionPart)
  private
    FExpression: Pointer; /// R�f�rence faible � l'expression contr�leur

    FSepiRoot: TSepiRoot;                 /// Racine Sepi
    FUnitCompiler: TSepiUnitCompiler;     /// Compilateur d'unit�
    FMethodCompiler: TSepiMethodCompiler; /// Compilateur de m�thode

    function GetExpression: ISepiExpression;
  protected
    procedure AttachTo(const Controller: IInterface); override;
    procedure DetachFromController; override;

    procedure MakeError(const Msg: string; Kind: TSepiErrorKind = ekError);

    property Expression: ISepiExpression read GetExpression;

    property SepiRoot: TSepiRoot read FSepiRoot;
    property UnitCompiler: TSepiUnitCompiler read FUnitCompiler;
    property MethodCompiler: TSepiMethodCompiler read FMethodCompiler;
  end;

  {*
    Impl�mentation de base de ISepiDirectValue
    Bien que, syntaxiquement, cette classe impl�mente les trois interfaces
    ISepiReadableValue, ISepiWritableValue et ISepiAddressableValue, les
    classes descendantes peuvent activer et d�sactiver celles-ci � volont� au
    moyen des propri�t�s IsReadable, IsWritable et IsAddressable respectivement.
    De m�me, l'impl�mentation de l'interface ISepiConstantValue n'est effective
    que si ConstValuePtr <> nil.
    @author sjrd
    @version 1.0
  *}
  TSepiCustomDirectValue = class(TSepiCustomExpressionPart, ISepiDirectValue,
    ISepiReadableValue, ISepiWritableValue, ISepiAddressableValue,
    ISepiConstantValue)
  private
    FValueType: TSepiType; /// Type de la valeur

    FIsReadable: Boolean;    /// Indique si la valeur peut �tre lue
    FIsWritable: Boolean;    /// Indique si la valeur peut �tre �crite
    FIsAddressable: Boolean; /// Indique si la valeur peut �tre adress�e

    FConstValuePtr: Pointer; /// Pointeur sur la valeur constante
  protected
    function QueryInterface(const IID: TGUID;
      out Obj): HResult; override; stdcall;

    function GetValueType: TSepiType;
    procedure SetValueType(AType: TSepiType);
    function GetAddressType: TSepiType;

    function GetValuePtr: Pointer;

    function CompileAsMemoryRef(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList;
      TempVars: TSepiTempVarsLifeManager): TSepiMemoryReference; virtual;
      abstract;

    procedure CompileRead(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
      TempVars: TSepiTempVarsLifeManager); virtual;

    procedure CompileWrite(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; Source: ISepiReadableValue); virtual;

    procedure CompileLoadAddress(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
      TempVars: TSepiTempVarsLifeManager); virtual;

    property IsReadable: Boolean read FIsReadable write FIsReadable;
    property IsWritable: Boolean read FIsWritable write FIsWritable;
    property IsAddressable: Boolean read FIsAddressable write FIsAddressable;

    property ConstValuePtr: Pointer read FConstValuePtr write FConstValuePtr;
  public
    property ValueType: TSepiType read FValueType;
    property AddressType: TSepiType read GetAddressType;
  end;

  {*
    Classe de base pour des valeurs � calculer
    Bien que, syntaxiquement, cette classe impl�mente l'interface
    ISepiConstantValue, celle-ci est d�sactiv�e jusqu'� ce qu'un appel �
    AllocateConstant ait �t� fait.
    @author sjrd
    @version 1.0
  *}
  TSepiCustomComputedValue = class(TSepiCustomExpressionPart,
    ISepiReadableValue, ISepiConstantValue)
  private
    FValueType: TSepiType; /// Type de valeur

    FConstValuePtr: Pointer; /// Pointeur sur la valeur constante
  protected
    function QueryInterface(const IID: TGUID;
      out Obj): HResult; override; stdcall;

    function GetValueType: TSepiType;
    procedure SetValueType(AType: TSepiType);

    function GetValuePtr: Pointer;

    procedure AllocateConstant;

    procedure CompileCompute(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
      TempVars: TSepiTempVarsLifeManager); virtual; abstract;

    procedure CompileRead(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
      TempVars: TSepiTempVarsLifeManager);

    property ConstValuePtr: Pointer read FConstValuePtr;
  public
    destructor Destroy; override;

    property ValueType: TSepiType read FValueType;
  end;

  {*
    Valeur constante (vraie constante ou constante lit�rale)
    @author sjrd
    @version 1.0
  *}
  TSepiTrueConstValue = class(TSepiCustomDirectValue)
  private
    FConstant: TSepiConstant;

    constructor Create(AType: TSepiType); overload;
  protected
    function CompileAsMemoryRef(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList;
      TempVars: TSepiTempVarsLifeManager): TSepiMemoryReference; override;
  public
    constructor Create(Constant: TSepiConstant); overload;

    constructor Create(SepiRoot: TSepiRoot; Value: Int64); overload;
    constructor Create(SepiRoot: TSepiRoot; Value: Extended); overload;

    constructor Create(SepiRoot: TSepiRoot; Value: AnsiChar); overload;
    constructor Create(SepiRoot: TSepiRoot; Value: WideChar); overload;

    constructor Create(SepiRoot: TSepiRoot; const Value: AnsiString); overload;
    constructor Create(SepiRoot: TSepiRoot; const Value: WideString); overload;

    destructor Destroy; override;

    property Constant: TSepiConstant read FConstant;
    property ConstValuePtr;
  end;

  {*
    Op�rateur de transtypage
    @author sjrd
    @version 1.0
  *}
  TSepiCastOperator = class(TSepiCustomDirectValue)
  private
    FOperand: ISepiExpression; /// Expression source
    FForceCast: Boolean;      /// True force m�me avec des tailles diff�rentes

    procedure CollapseConsts;
  protected
    procedure CompileRead(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
      TempVars: TSepiTempVarsLifeManager); override;

    procedure CompileWrite(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; Source: ISepiReadableValue); override;

    procedure CompileLoadAddress(Compiler: TSepiMethodCompiler;
      Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
      TempVars: TSepiTempVarsLifeManager); override;
  public
    constructor Create(DestType: TSepiType;
      const AOperand: ISepiExpression = nil);

    procedure Complete;

    property Operand: ISepiExpression read FOperand write FOperand;
    property ForceCast: Boolean read FForceCast write FForceCast;
  end;

  {*
    Valeur nil
    @author sjrd
    @version 1.0
  *}
  TSepiNilValue = class(TSepiCustomExpressionPart, ISepiNilValue)
  end;

  {*
    Expression repr�sentant un meta
    @author sjrd
    @version 1.0
  *}
  TSepiMetaExpression = class(TSepiCustomExpressionPart, ISepiMetaExpression)
  private
    FMeta: TSepiMeta; /// Meta
  protected
    function GetMeta: TSepiMeta;
  public
    constructor Create(AMeta: TSepiMeta);

    property Meta: TSepiMeta read FMeta;
  end;

  {*
    Expression repr�sentant un type
    @author sjrd
    @version 1.0
  *}
  TSepiTypeExpression = class(TSepiCustomExpressionPart, ISepiTypeExpression)
  private
    FType: TSepiType; /// Type
  protected
    function GetType: TSepiType;
  public
    constructor Create(AType: TSepiType);

    property ExprType: TSepiType read FType;
  end;

procedure NeedDestination(var Destination: TSepiMemoryReference;
  ValueType: TSepiType; Compiler: TSepiMethodCompiler;
  TempVars: TSepiTempVarsLifeManager; BeginLifeAt: TSepiInstructionRef);

function IsZeroMemory(Address: Pointer; Size: Integer): Boolean;

implementation

const
  /// Z�ro m�moire
  ZeroMemory: array[0..SizeOf(Variant)-1] of Byte = (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  );

{-----------------}
{ Global routines }
{-----------------}

{*
  Exige une destination m�moire valide
  Si Destination vaut nil en entr�e, cette routine allouera une variable
  temporaire du type demand� pour avoir une r�f�rence m�moire valide.
  @param Destination   Destination m�moire
  @param ValueType     Type de valeur � mettre dans la destination
  @param Compiler      Compilateur
  @param TempVars      Gestionnaire de vie de variables temporaires
  @param BeginLifeAt   D�but de la vie de la variable temporaire
*}
procedure NeedDestination(var Destination: TSepiMemoryReference;
  ValueType: TSepiType; Compiler: TSepiMethodCompiler;
  TempVars: TSepiTempVarsLifeManager; BeginLifeAt: TSepiInstructionRef);
var
  TempVar: TSepiLocalVar;
begin
  if Destination <> nil then
    Exit;

  TempVar := Compiler.Locals.AddTempVar(ValueType);
  TempVars.BeginLife(TempVar, BeginLifeAt);

  Destination := TSepiMemoryReference.Create(Compiler);
  Destination.SetSpace(TempVar);
  Destination.Seal;
end;

{*
  Teste si une valeur est un z�ro m�moire, tel qu'on peut utiliser msZero
  Une valeur est un z�ro m�moire si et seulement si sa taille n'est pas plus
  grande qu'un Variant et que tous ses octets sont nuls.
  @param Address   Adresse m�moire de la valeur
  @param Size      Taille de la valeur
  @return True si la valeur est un z�ro m�moire, False sinon
*}
function IsZeroMemory(Address: Pointer; Size: Integer): Boolean;
begin
  if Size > SizeOf(Variant) then
    Result := False
  else
  begin
    while Size > 0 do
    begin
      if PByte(Address)^ <> 0 then
      begin
        Result := False;
        Exit;
      end;

      Inc(Cardinal(Address));
      Dec(Size);
    end;

    Result := True;
  end;
end;

{---------------------------------}
{ TSepiCustomExpressionPart class }
{---------------------------------}

{*
  Expression � laquelle est rattach�e cette part d'expression
*}
function TSepiCustomExpressionPart.GetExpression: ISepiExpression;
begin
  Result := ISepiExpression(FExpression);
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomExpressionPart.AttachTo(const Controller: IInterface);
var
  ExprController: ISepiExpression;
begin
  inherited;

  if Controller.QueryInterface(ISepiExpression, ExprController) = 0 then
    FExpression := Pointer(ExprController);
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomExpressionPart.DetachFromController;
begin
  inherited;

  FExpression := nil;
end;

{*
  Produit une erreur de compilation au niveau de cette expression
  @param Msg    Message de l'erreur
  @param Kind   Type d'erreur (d�faut = ekError)
*}
procedure TSepiCustomExpressionPart.MakeError(const Msg: string;
  Kind: TSepiErrorKind = ekError);
begin
  Expression.MakeError(Msg, Kind);
end;

{------------------------------}
{ TSepiCustomDirectValue class }
{------------------------------}

{*
  [@inheritDoc]
*}
function TSepiCustomDirectValue.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if SameGUID(IID, ISepiReadableValue) and (not IsReadable) then
    Result := E_NOINTERFACE
  else if SameGUID(IID, ISepiWritableValue) and (not IsWritable) then
    Result := E_NOINTERFACE
  else if SameGUID(IID, ISepiAddressableValue) and (not IsAddressable) then
    Result := E_NOINTERFACE
  else if SameGUID(IID, ISepiConstantValue) and (ConstValuePtr = nil) then
    Result := E_NOINTERFACE
  else
    Result := inherited QueryInterface(IID, Obj);
end;

{*
  [@inheritDoc]
*}
function TSepiCustomDirectValue.GetValueType: TSepiType;
begin
  Result := FValueType;
end;

{*
  Renseigne le type de la valeur
  @param AType   Type de la valeur
*}
procedure TSepiCustomDirectValue.SetValueType(AType: TSepiType);
begin
  FValueType := AType;
end;

{*
  [@inheritDoc]
*}
function TSepiCustomDirectValue.GetAddressType: TSepiType;
begin
  Result := SepiRoot.FindType('System.Pointer');
end;

{*
  [@inheritDoc]
*}
function TSepiCustomDirectValue.GetValuePtr: Pointer;
begin
  Result := FConstValuePtr;
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomDirectValue.CompileRead(Compiler: TSepiMethodCompiler;
  Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
  TempVars: TSepiTempVarsLifeManager);
begin
  Destination := CompileAsMemoryRef(Compiler, Instructions, TempVars);
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomDirectValue.CompileWrite(Compiler: TSepiMethodCompiler;
  Instructions: TSepiInstructionList; Source: ISepiReadableValue);
var
  TempVars: TSepiTempVarsLifeManager;
  Destination, TempDest: TSepiMemoryReference;
  MoveInstr: TSepiAsmMove;
begin
  if Source.ValueType <> ValueType then
  begin
    MakeError(Format(STypeMismatch, [Source.ValueType.Name, ValueType.Name]));
    Exit;
  end;

  TempVars := TSepiTempVarsLifeManager.Create;
  try
    Destination := CompileAsMemoryRef(Compiler, Instructions, TempVars);
    TempDest := Destination;
    try
      Destination.Seal;
      Source.CompileRead(Compiler, Instructions, TempDest, TempVars);

      TempVars.EndAllLifes(Instructions.GetCurrentEndRef);

      if TempDest <> Destination then
      begin
        MoveInstr := TSepiAsmMove.Create(Compiler, ValueType);
        MoveInstr.SourcePos := Expression.SourcePos;
        MoveInstr.Destination.Assign(Destination);
        MoveInstr.Source.Assign(TempDest);
        Instructions.Add(MoveInstr);
      end;
    finally
      if TempDest <> Destination then
        TempDest.Free;
      Destination.Free;
    end;
  finally
    TempVars.EndAllLifes(Instructions.GetCurrentEndRef);
    TempVars.Free;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomDirectValue.CompileLoadAddress(
  Compiler: TSepiMethodCompiler; Instructions: TSepiInstructionList;
  var Destination: TSepiMemoryReference; TempVars: TSepiTempVarsLifeManager);
var
  MemoryRef: TSepiMemoryReference;
  LoadAddressInstr: TSepiAsmLoadAddress;
begin
  MemoryRef := CompileAsMemoryRef(Compiler, Instructions, TempVars);
  try
    if MemoryRef.CanRemoveDereference then
    begin
      Destination := TSepiMemoryReference.Clone(MemoryRef);
      Destination.RemoveDereference;
      Destination.Seal;
    end else
    begin
      TempVars.EndAllLifes(Instructions.GetCurrentEndRef);

      LoadAddressInstr := TSepiAsmLoadAddress.Create(Compiler);
      LoadAddressInstr.SourcePos := Expression.SourcePos;

      NeedDestination(Destination, AddressType, Compiler, TempVars,
        LoadAddressInstr.AfterRef);

      LoadAddressInstr.Destination.Assign(Destination);
      LoadAddressInstr.Source.Assign(MemoryRef);
      Instructions.Add(LoadAddressInstr);
    end;
  finally
    MemoryRef.Free;
  end;
end;

{--------------------------------}
{ TSepiCustomComputedValue class }
{--------------------------------}

{*
  [@inheritDoc]
*}
destructor TSepiCustomComputedValue.Destroy;
begin
  if ConstValuePtr <> nil then
    ValueType.DisposeValue(ConstValuePtr);

  inherited;
end;

{*
  [@inheritDoc]
*}
function TSepiCustomComputedValue.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if SameGUID(IID, ISepiConstantValue) and (ConstValuePtr = nil) then
    Result := E_NOINTERFACE
  else
    Result := inherited QueryInterface(IID, Obj);
end;

{*
  Type de valeur
  @return Type de valeur
*}
function TSepiCustomComputedValue.GetValueType: TSepiType;
begin
  Result := FValueType;
end;

{*
  Renseigne le type de valeur
  @param AType   Type de valeur
*}
procedure TSepiCustomComputedValue.SetValueType(AType: TSepiType);
begin
  FValueType := AType;
end;

{*
  [@inheritDoc]
*}
function TSepiCustomComputedValue.GetValuePtr: Pointer;
begin
  Result := FConstValuePtr;
end;

{*
  Alloue la constante et devient par l� un ISepiConstantValue
  La constante est initialis�e � 0
*}
procedure TSepiCustomComputedValue.AllocateConstant;
begin
  if FConstValuePtr = nil then
  begin
    GetMem(FConstValuePtr, ValueType.Size);
    FillChar(FConstValuePtr^, ValueType.Size, 0);
  end;
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomComputedValue.CompileRead(Compiler: TSepiMethodCompiler;
  Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
  TempVars: TSepiTempVarsLifeManager);
begin
  if ConstValuePtr = nil then
    CompileCompute(Compiler, Instructions, Destination, TempVars)
  else
  begin
    Destination := TSepiMemoryReference.Create(Compiler, aoAcceptAllConsts,
      ValueType.Size);

    if IsZeroMemory(ConstValuePtr, ValueType.Size) then
      Destination.SetSpace(msZero)
    else if ValueType.NeedInit then
    begin
      Destination.SetSpace(Compiler.MakeUnnamedTrueConst(
        ValueType, ConstValuePtr^));
    end else
    begin
      Destination.SetSpace(msConstant);
      Destination.SetConstant(ConstValuePtr^);
    end;

    Destination.Seal;
  end;
end;

{---------------------}
{ TSepiTrueConstValue }
{---------------------}

{*
  Tronc commun des cr�ations de constantes lit�rales
  @param AType   Type de la constante
*}
constructor TSepiTrueConstValue.Create(AType: TSepiType);
begin
  inherited Create;

  SetValueType(AType);
  ConstValuePtr := ValueType.NewValue;

  IsReadable := True;
end;

{*
  Cr�e une expression repr�sentant une vraie constante
  @param Constant   Vraie constante repr�sent�e
*}
constructor TSepiTrueConstValue.Create(Constant: TSepiConstant);
begin
  inherited Create;

  FConstant := Constant;
  SetValueType(Constant.ConstType);
  ConstValuePtr := Constant.ValuePtr;

  IsReadable := True;
end;

{*
  Cr�e une constante lit�rale enti�re
  @param SepiRoot   Racine Sepi (pour trouver le type Sepi)
  @param Value      Valeur de la constante
*}
constructor TSepiTrueConstValue.Create(SepiRoot: TSepiRoot;
  Value: Int64);
begin
  Create(SepiRoot.FindType(TypeInfo(Int64)));

  Int64(ConstValuePtr^) := Value;
end;

{*
  Cr�e une constante lit�rale flottante
  @param SepiRoot   Racine Sepi (pour trouver le type Sepi)
  @param Value      Valeur de la constante
*}
constructor TSepiTrueConstValue.Create(SepiRoot: TSepiRoot;
  Value: Extended);
begin
  Create(SepiRoot.FindType(TypeInfo(Extended)));

  Extended(ConstValuePtr^) := Value;
end;

{*
  Cr�e une constante lit�rale caract�re ANSI
  @param SepiRoot   Racine Sepi (pour trouver le type Sepi)
  @param Value      Valeur de la constante
*}
constructor TSepiTrueConstValue.Create(SepiRoot: TSepiRoot;
  Value: AnsiChar);
begin
  Create(SepiRoot.FindType(TypeInfo(AnsiChar)));

  AnsiChar(ConstValuePtr^) := Value;
end;

{*
  Cr�e une constante lit�rale caract�re Unicode
  @param SepiRoot   Racine Sepi (pour trouver le type Sepi)
  @param Value      Valeur de la constante
*}
constructor TSepiTrueConstValue.Create(SepiRoot: TSepiRoot;
  Value: WideChar);
begin
  Create(SepiRoot.FindType(TypeInfo(WideChar)));

  WideChar(ConstValuePtr^) := Value;
end;

{*
  Cr�e une constante lit�rale cha�ne ANSI
  @param SepiRoot   Racine Sepi (pour trouver le type Sepi)
  @param Value      Valeur de la constante
*}
constructor TSepiTrueConstValue.Create(SepiRoot: TSepiRoot;
  const Value: AnsiString);
begin
  Create(SepiRoot.FindType(TypeInfo(AnsiString)));

  AnsiString(ConstValuePtr^) := Value;
end;

{*
  Cr�e une constante lit�rale cha�ne Unicode
  @param SepiRoot   Racine Sepi (pour trouver le type Sepi)
  @param Value      Valeur de la constante
*}
constructor TSepiTrueConstValue.Create(SepiRoot: TSepiRoot;
  const Value: WideString);
begin
  Create(SepiRoot.FindType(TypeInfo(WideString)));

  WideString(ConstValuePtr^) := Value;
end;

{*
  [@inheritDoc]
*}
destructor TSepiTrueConstValue.Destroy;
begin
  if FConstant = nil then
    ValueType.DisposeValue(ConstValuePtr);

  inherited;
end;

{*
  [@inheritDoc]
*}
function TSepiTrueConstValue.CompileAsMemoryRef(Compiler: TSepiMethodCompiler;
  Instructions: TSepiInstructionList;
  TempVars: TSepiTempVarsLifeManager): TSepiMemoryReference;
begin
  Result := TSepiMemoryReference.Create(Compiler, aoAcceptAllConsts,
    ValueType.Size);
  try
    if IsZeroMemory(ConstValuePtr, ValueType.Size) then
      Result.SetSpace(msZero)
    else if Constant <> nil then
    begin
      Result.SetSpace(Constant);
    end else if ValueType.NeedInit then
    begin
      Result.SetSpace(Compiler.MakeUnnamedTrueConst(
        ValueType, ConstValuePtr^));
    end else
    begin
      Result.SetSpace(msConstant);
      Result.SetConstant(ConstValuePtr^);
    end;

    Result.Seal;
  except
    Result.Free;
    raise;
  end;
end;

{-------------------------}
{ TSepiCastOperator class }
{-------------------------}

constructor TSepiCastOperator.Create(DestType: TSepiType;
  const AOperand: ISepiExpression = nil);
begin
  inherited Create;

  SetValueType(DestType);
  FOperand := AOperand;
end;

{*
  Pliage des constantes
*}
procedure TSepiCastOperator.CollapseConsts;
var
  ConstOp: ISepiConstantValue;
  OpType: TSepiType;
begin
  // Handle nil constant
  if Supports(Operand, ISepiNilValue) then
  begin
    ConstValuePtr := @ZeroMemory;
    Exit;
  end;

  // If operand is not a constant value, exit
  if Operand.QueryInterface(ISepiConstantValue, ConstOp) <> 0 then
    Exit;

  // Can't collapse a cast if operand type is unknown
  OpType := ConstOp.ValueType;
  if OpType = nil then
    Exit;

  // Can't collapse a cast on a need-init-type (unless operand is zero-memory)
  if (OpType.NeedInit or ValueType.NeedInit) and
    (not IsZeroMemory(ConstOp.ValuePtr, OpType.Size)) then
    Exit;

  // Do the job
  ConstValuePtr := ConstOp.ValuePtr;
end;

{*
  [@inheritDoc]
*}
procedure TSepiCastOperator.CompileRead(Compiler: TSepiMethodCompiler;
  Instructions: TSepiInstructionList; var Destination: TSepiMemoryReference;
  TempVars: TSepiTempVarsLifeManager);
begin
  (Operand as ISepiReadableValue).CompileRead(Compiler, Instructions,
    Destination, TempVars);
end;

{*
  [@inheritDoc]
*}
procedure TSepiCastOperator.CompileWrite(Compiler: TSepiMethodCompiler;
  Instructions: TSepiInstructionList; Source: ISepiReadableValue);
begin
  (Operand as ISepiWritableValue).CompileWrite(Compiler, Instructions,
    Source);
end;

{*
  [@inheritDoc]
*}
procedure TSepiCastOperator.CompileLoadAddress(
  Compiler: TSepiMethodCompiler; Instructions: TSepiInstructionList;
  var Destination: TSepiMemoryReference; TempVars: TSepiTempVarsLifeManager);
begin
  (Operand as ISepiAddressableValue).CompileLoadAddress(Compiler, Instructions,
    Destination, TempVars);
end;

{*
  Compl�te le transtypage
*}
procedure TSepiCastOperator.Complete;
var
  OpType: TSepiType;
begin
  Assert(Operand <> nil);

  OpType := nil;

  if Supports(Operand, ISepiNilValue) then
    IsReadable := True;

  if Supports(Operand, ISepiReadableValue) then
  begin
    IsReadable := True;
    OpType := (Operand as ISepiReadableValue).ValueType;
  end;

  if Supports(Operand, ISepiWritableValue) then
  begin
    IsWritable := (OpType = nil) or
      ((Operand as ISepiReadableValue).ValueType = OpType);
    if OpType = nil then
      OpType := (Operand as ISepiReadableValue).ValueType;
  end;

  if Supports(Operand, ISepiAddressableValue) then
    IsAddressable := True;

  if (OpType <> nil) and (OpType.Size <> ValueType.Size) then
  begin
    if (OpType.Size < ValueType.Size) or (not ForceCast) then
    begin
      MakeError(Format(SInvalidCast, [OpType.Name, ValueType.Name]));

      IsReadable := False;
      IsWritable := False;
      IsAddressable := False;

      Exit;
    end;
  end;

  CollapseConsts;
end;

{---------------------------}
{ TSepiMetaExpression class }
{---------------------------}

{*
  Cr�e une expression repr�sentant un meta
  @param AMeta   Meta repr�sent�
*}
constructor TSepiMetaExpression.Create(AMeta: TSepiMeta);
begin
  inherited Create;

  FMeta := AMeta;
end;

{*
  Meta
  @return Meta
*}
function TSepiMetaExpression.GetMeta: TSepiMeta;
begin
  Result := FMeta;
end;

{---------------------------}
{ TSepiTypeExpression class }
{---------------------------}

{*
  Cr�e une expression repr�sentant un type
  @param AType   Type repr�sent�
*}
constructor TSepiTypeExpression.Create(AType: TSepiType);
begin
  inherited Create;

  FType := AType;
end;

{*
  Type
  @return Type
*}
function TSepiTypeExpression.GetType: TSepiType;
begin
  Result := FType;
end;

end.

