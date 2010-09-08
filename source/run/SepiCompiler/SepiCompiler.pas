{-------------------------------------------------------------------------------
Sepi - Object-oriented script engine for Delphi
Copyright (C) 2006-2009  S�bastien Doeraene
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

Linking this library statically or dynamically with other modules is making a
combined work based on this library.  Thus, the terms and conditions of the GNU
General Public License cover the whole combination.

As a special exception, the copyright holders of this library give you
permission to link this library with independent modules to produce an
executable, regardless of the license terms of these independent modules, and
to copy and distribute the resulting executable under terms of your choice,
provided that you also meet, for each linked independent module, the terms and
conditions of the license of that module.  An independent module is a module
which is not derived from or based on this library.  If you modify this
library, you may extend this exception to your version of the library, but you
are not obligated to do so.  If you do not wish to do so, delete this exception
statement from your version.
-------------------------------------------------------------------------------}

{*
  Compilateur Sepi
  @author sjrd
  @version 1.0
*}
unit SepiCompiler;

interface

uses
  Types, Windows, SysUtils, Classes, Contnrs, TypInfo, ScUtils, ScTypInfo,
  ScIntegerSets, ScInterfaces, SepiReflectionCore, SepiMembers, SepiOrdTypes,
  SepiSystemUnit, SepiOpCodes, SepiReflectionConsts, SepiCompilerErrors,
  SepiCompilerConsts, SepiArrayTypes;

type
  TSepiAsmInstrList = class;
  TSepiInstructionList = class;
  ISepiExpression = interface;
  TSepiMethodCompiler = class;
  TSepiCompilerBase = class;
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

    function GetCurrentEndRef: TSepiInstructionRef;

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

    FDeclarationLocation: TSepiSourcePosition; /// Position de la d�claration

    FIsUseful: Boolean; /// True d�s que la variable a �t� utilis�e

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
    constructor CreateResult(Signature: TSepiSignature);
    constructor CreateAbsolute(const AName: string; AType: TSepiType;
      AAbsoluteTo: TSepiLocalVar);
    destructor Destroy; override;

    procedure HandleLife;
    procedure CompileLife;

    function InterfereWith(Other: TSepiLocalVar): Boolean;
    procedure SetOffset(AOffset: Integer);

    procedure CheckUseful(Errors: TSepiCompilerErrorList);

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

    property DeclarationLocation: TSepiSourcePosition
      read FDeclarationLocation write FDeclarationLocation;

    property IsUseful: Boolean read FIsUseful write FIsUseful;
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

    function GetHiddenVar(Kind: TSepiHiddenParamKind): TSepiLocalVar;
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

    function Exists(const Name: string): Boolean;
    function GetVarByName(const Name: string): TSepiLocalVar;

    procedure Compile;
    procedure WriteInitInfo(Stream: TStream);

    property Compiler: TSepiMethodCompiler read FCompiler;
    property Count: Integer read GetCount;
    property Variables[Index: Integer]: TSepiLocalVar
      read GetVariables; default;

    property SelfVar: TSepiLocalVar index hpSelf read GetHiddenVar;
    property ResultVar: TSepiLocalVar index hpResult read GetHiddenVar;

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

    function Extract(TempVar: TSepiLocalVar): TSepiLocalVar;
    procedure Acquire(TempVar: TSepiLocalVar);

    function FindVarFromMemoryRef(
      MemoryRef: TSepiMemoryReference): TSepiLocalVar;
  end;

  {*
    R�gles s�mantiques d'un langage
    @author sjrd
    @version 1.0
  *}
  TSepiLanguageRules = class(TObject)
  private
    FUnitCompiler: TSepiUnitCompiler; /// Compilateur d'unit�
    FSepiRoot: TSepiRoot;             /// Racine Sepi
    FSystemUnit: TSepiSystemUnit;     /// Unit� System
  public
    constructor Create(AUnitCompiler: TSepiUnitCompiler); virtual;

    {*
      R�soud un identificateur
      @param Context      Contexte dans lequel rechercher l'identificateur
      @param Identifier   Identificateur recherch�
      @return Expression repr�sentant l'identificateur, ou nil si non trouv�
    *}
    function ResolveIdent(Context: TSepiComponent;
      const Identifier: string): ISepiExpression; virtual; abstract;

    {*
      R�soud un identificateur dans le contexte d'une m�thode
      @param Compiler     Compilateur de la m�thode
      @param Identifier   Identificateur recherch�
      @return Expression repr�sentant l'identificateur, ou nil si non trouv�
    *}
    function ResolveIdentInMethod(Compiler: TSepiMethodCompiler;
      const Identifier: string): ISepiExpression; virtual; abstract;

    {*
      S�lection de champ d'une expression
      @param Context          Contexte Sepi depuis lequel chercher
      @param BaseExpression   Expression de base
      @param FieldName        Nom du champ
      @return Expression repr�sentant le champ s�lectionn� (nil si inexistant)
    *}
    function FieldSelection(Context: TSepiComponent;
      const BaseExpression: ISepiExpression;
      const FieldName: string): ISepiExpression; virtual; abstract;

    function ConvertionToOpenArrayExists(ElementType: TSepiType;
      const Expression: ISepiExpression): Boolean; virtual;

    function ConvertToOpenArray(ElementType: TSepiType;
      const Expression: ISepiExpression): ISepiExpression; virtual;

    property UnitCompiler: TSepiUnitCompiler read FUnitCompiler;
    property SepiRoot: TSepiRoot read FSepiRoot;
    property SystemUnit: TSepiSystemUnit read FSystemUnit;
  end;

  /// Classe de TSepiLanguageRules
  TSepiLanguageRulesClass = class of TSepiLanguageRules;

  {*
    Partie liable dynamiquement � une expression Sepi
    @author sjrd
    @version 1.0
  *}
  ISepiExpressionPart = interface(IDynamicallyLinkable)
    ['{2BBD5F29-1EDF-4C3F-A114-3820BAFB355A}']

    procedure AttachToExpression(const Expression: ISepiExpression);
  end;

  {*
    Expression Sepi
    Dans Sepi, une expression peut avoir diff�rents types en m�me temps. Elle
    peut � la fois �tre un composant et l'appel � une m�thode, par exemple.
    Les expressions Sepi sont donc des contr�leurs d'interfaces dynamiques, et
    il est possible de leur attacher/d�tacher toute interface impl�mentant
    ISepiExpressionPart.
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
      Compilateur de base
      @return Compilateur de base
    *}
    function GetBaseCompiler: TSepiCompilerBase;

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
      R�gles du langage utilis�
      @return R�gles du langage utilis�
    *}
    function GetLanguageRules: TSepiLanguageRules;

    {*
      Position dans le source
      @return Position dans le source
    *}
    function GetSourcePos: TSepiSourcePosition;

    {*
      Position dans le source
      @return Position dans le source
    *}
    procedure SetSourcePos(const Value: TSepiSourcePosition);

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
    property BaseCompiler: TSepiCompilerBase read GetBaseCompiler;
    property UnitCompiler: TSepiUnitCompiler read GetUnitCompiler;
    property MethodCompiler: TSepiMethodCompiler read GetMethodCompiler;
    property LanguageRules: TSepiLanguageRules read GetLanguageRules;

    property SourcePos: TSepiSourcePosition
      read GetSourcePos write SetSourcePos;
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
    FBaseCompiler: TSepiCompilerBase;     /// Compilateur de base
    FUnitCompiler: TSepiUnitCompiler;     /// Compilateur d'unit�
    FMethodCompiler: TSepiMethodCompiler; /// Compilateur de m�thode
    FLanguageRules: TSepiLanguageRules;   /// R�gles du langage utilis�

    FSourcePos: TSepiSourcePosition; /// Position dans le source
  protected
    function GetSepiRoot: TSepiRoot;
    function GetBaseCompiler: TSepiCompilerBase;
    function GetUnitCompiler: TSepiUnitCompiler;
    function GetMethodCompiler: TSepiMethodCompiler;
    function GetLanguageRules: TSepiLanguageRules;

    function GetSourcePos: TSepiSourcePosition;
    procedure SetSourcePos(const Value: TSepiSourcePosition);
  public
    constructor Create(ACompiler: TSepiCompilerBase); overload;
    constructor Create(const Context: ISepiExpression); overload;

    procedure Attach(const IID: TGUID; const Intf: ISepiExpressionPart);
    procedure Detach(const IID: TGUID);

    procedure MakeError(const Msg: string; Kind: TSepiErrorKind = ekError);

    property SepiRoot: TSepiRoot read FSepiRoot;
    property BaseCompiler: TSepiCompilerBase read FBaseCompiler;
    property UnitCompiler: TSepiUnitCompiler read FUnitCompiler;
    property MethodCompiler: TSepiMethodCompiler read FMethodCompiler;
    property LanguageRules: TSepiLanguageRules read FLanguageRules;

    property SourcePos: TSepiSourcePosition read FSourcePos write FSourcePos;
  end;

  {*
    Classe de base pour les classes TSepiMethodCompiler et TSepiUnitCompiler
    @author sjrd
    @version 1.0
  *}
  TSepiCompilerBase = class(TObject)
  private
    FUnitCompiler: TSepiUnitCompiler; /// Compilateur d'unit�

    FErrors: TSepiCompilerErrorList; /// Erreurs

    FSepiUnit: TSepiUnit;         /// Unit� Sepi
    FSepiRoot: TSepiRoot;         /// Racine Sepi
    FSystemUnit: TSepiSystemUnit; /// Unit� System
  public
    constructor Create(AUnitCompiler: TSepiUnitCompiler;
      AErrors: TSepiCompilerErrorList; ASepiUnit: TSepiUnit);

    property UnitCompiler: TSepiUnitCompiler read FUnitCompiler;

    property Errors: TSepiCompilerErrorList read FErrors;

    property SepiUnit: TSepiUnit read FSepiUnit;
    property SepiRoot: TSepiRoot read FSepiRoot;
    property SystemUnit: TSepiSystemUnit read FSystemUnit;
  end;

  {*
    Compilateur d'une m�thode Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiMethodCompiler = class(TSepiCompilerBase)
  private
    FObjFreeList: TObjectList; /// Liste des objets � lib�rer en fin de vie

    FSepiMethod: TSepiMethod;        /// M�thode Sepi correspondante
    FLocalNamespace: TSepiNamespace; /// Espace de noms local
    FLocals: TSepiLocalVariables;    /// Variables locales

    FInstructions: TSepiInstructionList; /// Instructions
    FAsmInstructions: TSepiAsmInstrList; /// Instructions assembleur
    FSize: Integer;                      /// Taille totale (apr�s assemblage)

    FLastInstruction: TSepiAsmInstrList;

    FNamedLabels: TStrings; /// Labels nomm�s (paire nom/instruction)

    FContinueReferences: TObjectStack; /// R�f�rences pour continue
    FBreakReferences: TObjectStack;    /// R�f�rences pour break

    procedure SetLabel(NamedLabel: TSepiNamedLabel);

    function GetHasLocalNamespace: Boolean;
    function GetLocalNamespace: TSepiNamespace;

    function GetContinueRef: TSepiInstructionRef;
    function GetBreakRef: TSepiInstructionRef;
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
      AllowCreate: Boolean = False): TSepiNamedLabel;

    procedure EnterLoop(ContinueRef, BreakRef: TSepiInstructionRef);
    procedure LeaveLoop;

    function MakeUnnamedTrueConst(AType: TSepiType;
      const AValue): TSepiConstant;

    procedure Complete;

    procedure Compile;
    procedure WriteToStream(Stream: TStream);
    procedure WriteLocalsInfo(Stream: TStream);

    property SepiMethod: TSepiMethod read FSepiMethod;
    property HasLocalNamespace: Boolean read GetHasLocalNamespace;
    property LocalNamespace: TSepiNamespace read GetLocalNamespace;
    property Locals: TSepiLocalVariables read FLocals;

    property ContinueRef: TSepiInstructionRef read GetContinueRef;
    property BreakRef: TSepiInstructionRef read GetBreakRef;

    property Instructions: TSepiInstructionList read FInstructions;
    property Size: Integer read FSize;
  end;

  {*
    Compilateur d'unit� Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiUnitCompiler = class(TSepiCompilerBase)
  private
    FMethods: TObjectList; /// Compilateurs de m�thodes

    FLanguageRules: TSepiLanguageRules; /// R�gles du langage utilis�

    FCompileTimeTypes: TSepiComponent; /// Types de compilation
    FErroneousType: TSepiType;         /// Type erron�

    FReferences: TObjectList; /// R�f�rences

    procedure NeedCompileTimeTypes;

    function GetMethodCount: Integer;
    function GetMethods(Index: Integer): TSepiMethodCompiler;
  public
    constructor Create(AErrors: TSepiCompilerErrorList;
      ASepiUnit: TSepiUnit; ALanguageRulesClass: TSepiLanguageRulesClass);
    destructor Destroy; override;

    function GetPointerType(PointTo: TSepiType): TSepiPointerType;
    function GetMetaClass(SepiClass: TSepiClass): TSepiMetaClass;
    function GetMethodRefType: TSepiType;
    function GetEmptySetType: TSepiType;

    function MakeSetType(CompType: TSepiOrdType): TSepiSetType;

    function GetErroneousType: TSepiType;
    function MakeErroneousTypeAlias(const AliasName: string): TSepiType;

    function FindMethodCompiler(SepiMethod: TSepiMethod;
      AllowCreate: Boolean = False): TSepiMethodCompiler;

    function MakeReference(Component: TSepiComponent): Integer;

    procedure WriteToStream(Stream: TStream);

    property LanguageRules: TSepiLanguageRules read FLanguageRules;

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
    procedure EnsureResolved;

    function GetOperationCount: Integer;
    function GetOperations(Index: Integer): TSepiAddressDerefAndOpRec;
  public
    constructor Create(AMethodCompiler: TSepiMethodCompiler;
      AOptions: TSepiAddressOptions = []; AConstSize: Integer = 0);
    constructor Clone(Source: TSepiMemoryReference);
    destructor Destroy; override;

    procedure SetSpace(ASpace: TSepiMemorySpace;
      ASpaceArgument: Integer = 0); overload;
    procedure SetSpace(LocalVar: TSepiLocalVar); overload;
    procedure SetSpace(Constant: TSepiConstant); overload;
    procedure SetSpace(Variable: TSepiVariable); overload;
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
    function IsConstantOne: Boolean;

    procedure Assign(Source: TSepiMemoryReference;
      SealAfter: Boolean = True);

    procedure Seal;

    function Equals(Other: TSepiMemoryReference): Boolean;
      {$IF RTLVersion >= 20} reintroduce; {$IFEND}

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

    procedure WriteToStream(Stream: TStream; FromPos: Integer);

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

implementation

uses
  SepiCompilerUtils, SepiExpressions;

const
  /// Ensemble des op�rations qui ont un argument m�moire
  OpsWithMemArg = [
    aoPlusMemShortint..aoPlusLongConstTimesMemLongWord
  ];

  /// Tableau de conversion op�ration vers taille de l'argument constant
  OperationToConstArgSize: array[TSepiAddressOperation] of Integer = (
    0, SizeOf(Shortint), SizeOf(Smallint), SizeOf(Longint),
    0, 0, 0,
    SizeOf(Byte), SizeOf(Byte),
    SizeOf(Byte), SizeOf(Byte),
    SizeOf(Byte), SizeOf(Byte),
    SizeOf(LongWord), SizeOf(LongWord),
    SizeOf(LongWord), SizeOf(LongWord),
    SizeOf(LongWord), SizeOf(LongWord)
  );

  /// Le label n'a pas �t� assign�
  LabelUnassigned = TObject($FFFFFFFF);

type
  {*
    Noeud d'un graphe de variables locales
    @author sjrd
    @version 1.0
  *}
  TSepiLocalVarVertex = class(TObject)
  private
    FLocalVar: TSepiLocalVar; /// Variable locale repr�sent�e
    FColor: Integer;          /// Couleur assign�e

    FAdjacents: TObjectList; /// Liste des noeuds adjacents

    function GetAdjacentCount: Integer;
    function GetAdjacents(Index: Integer): TSepiLocalVarVertex;
  public
    constructor Create(ALocalVar: TSepiLocalVar);

    procedure AddAdjacent(Adjacent: TSepiLocalVarVertex;
      DoReciprocal: Boolean = True);
    procedure RemoveAdjacent(Adjacent: TSepiLocalVarVertex;
      DoReciprocal: Boolean = True);

    property LocalVar: TSepiLocalVar read FLocalVar;
    property Color: Integer read FColor write FColor;

    property AdjacentCount: Integer read GetAdjacentCount;
    property Adjacents[Index: Integer]: TSepiLocalVarVertex read GetAdjacents;
  end;

  {*
    Graphe d'interf�rence des variables locales
    @author sjrd
    @version 1.0
  *}
  TSepiLocalVarGraph = class(TObject)
  private
    FVertices: TObjectList;        /// Liste des noeuds du graphe
    FColorSizes: TIntegerDynArray; /// Tailles associ�es aux couleurs

    procedure MakeAdjacents;
    function ColorForVertex(Vertex: TSepiLocalVarVertex): Integer;
    procedure Colorize;
    procedure SetOffsets(var Size: Integer);

    function GetVertexCount: Integer;
    function GetVertices(Index: Integer): TSepiLocalVarVertex;
    function GetColorCount: Integer;
    procedure SetColorCount(Value: Integer);

    property ColorCount: Integer read GetColorCount write SetColorCount;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddLocalVar(LocalVar: TSepiLocalVar);

    procedure ColorizeAndSetOffsets(var Size: Integer);

    property VertexCount: Integer read GetVertexCount;
    property Vertices[Index: Integer]: TSepiLocalVarVertex read GetVertices;
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

{*
  Obtient une r�f�rence sur la fin courante de la liste d'instructions
  @return R�f�rence sur la fin courante de la liste d'instructions
*}
function TSepiInstructionList.GetCurrentEndRef: TSepiInstructionRef;
begin
  if Count = 0 then
    Result := BeforeRef
  else
    Result := Instructions[Count-1].AfterRef;
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
  begin
    AddInterval(FInstrIntervals[2*I].InstructionIndex,
      FInstrIntervals[2*I+1].InstructionIndex);
  end;
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
    Result := Temp.IntervalCount > 0;
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

  FDeclarationLocation := Param.DeclarationLocation;
end;

{*
  Cr�e la variable r�sultat d'une m�thode
  @param Signature   Signature de la m�thode
*}
constructor TSepiLocalVar.CreateResult(Signature: TSepiSignature);
begin
  inherited Create;

  FName := ResultFieldName;
  FType := Signature.ReturnType;
  FIsFixed := True;
  FOffset := 0;

  FDeclarationLocation := Signature.Owner.DeclarationLocation;

  FIsUseful := True;
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

{*
  V�rifie si cette variable est utile, et produit un conseil sinon
*}
procedure TSepiLocalVar.CheckUseful(Errors: TSepiCompilerErrorList);
begin
  if not ((Name = '') or IsParam or IsUseful) then
  begin
    // The variable is never used
    Errors.MakeError(Format(SLocalVarIsNeverUsed, [Name]), ekHint,
      DeclarationLocation);
  end;
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
  Graph: TSepiLocalVarGraph;
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
  Graph := TSepiLocalVarGraph.Create;
  try
    for I := 0 to Count-1 do
    begin
      LocalVar := Variables[I];
      if not (LocalVar.IsAbsolute or LocalVar.IsFixed) then
        Graph.AddLocalVar(LocalVar);
    end;

    Graph.ColorizeAndSetOffsets(FSize);
  finally
    Graph.Free;
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
  Tableau des variables cach�es indic�es par le type de param�tre cach�
  @param Kind   Type de param�tre cach�
  @return Variable correspondante
*}
function TSepiLocalVariables.GetHiddenVar(
  Kind: TSepiHiddenParamKind): TSepiLocalVar;
begin
  Result := GetVarByName(HiddenParamNames[Kind]);
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
    for I := ActualParamCount-1 downto 0 do
      FVariables.Add(TSepiLocalVar.CreateParam(ActualParams[I]));

    if not (ReturnType.SafeResultBehavior in [rbNone, rbParameter]) then
      FVariables.Add(TSepiLocalVar.CreateResult(Signature));
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
  Teste si une variable locale existe
  @param Name   Nom de la variable recherch�e
  @return True si la variable existe, False sinon
*}
function TSepiLocalVariables.Exists(const Name: string): Boolean;
var
  I: Integer;
begin
  Result := True;

  for I := 0 to Count-1 do
    if AnsiSameText(Variables[I].Name, Name) then
      Exit;

  Result := False;
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
    begin
      Result.IsUseful := True;
      Exit;
    end;
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
  begin
    Variables[I].CompileLife;
    Variables[I].CheckUseful(Compiler.Errors);
  end;

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

{*
  Extrait une variable temporaire de ce gestionnaire, sans terminer sa vie
  @param TempVar   Variable temporaire � extraire
  @return TempVar si elle faisait bien partie de ce gestionnaire, nil sinon
*}
function TSepiTempVarsLifeManager.Extract(
  TempVar: TSepiLocalVar): TSepiLocalVar;
begin
  Result := TSepiLocalVar(FTempVars.Extract(TempVar));
end;

{*
  Acquiert la gestion d'une variable temporaire
  La vie de cette variable doit avoir un intervalle en cours
  @param TempVar   Variable � acqu�rir
*}
procedure TSepiTempVarsLifeManager.Acquire(TempVar: TSepiLocalVar);
begin
  Assert(TempVar.IsLifeHandled and (TempVar.Life.FBegunAt <> nil));

  if FTempVars.IndexOf(TempVar) < 0 then
    FTempVars.Add(TempVar);
end;

{*
  Cherche une variable temporaire point�e par une r�f�rence m�moire
  @param MemoryRef   R�f�rence m�moire
  @return Variable temporaire point�e, ou nil si non trouv�e
*}
function TSepiTempVarsLifeManager.FindVarFromMemoryRef(
  MemoryRef: TSepiMemoryReference): TSepiLocalVar;
begin
  if (MemoryRef.Space = msUnresolvedLocalVar) and
    (MemoryRef.OperationCount = 0) and
    (FTempVars.IndexOf(MemoryRef.FUnresolvedLocalVar) >= 0) then
  begin
    Result := MemoryRef.FUnresolvedLocalVar;
  end else
  begin
    Result := nil;
  end;
end;

{--------------------------}
{ TSepiLanguageRules class }
{--------------------------}

{*
  Cr�e de nouvelles r�gles de langage
  @param AUnitCompiler   Compilateur d'unit�
*}
constructor TSepiLanguageRules.Create(AUnitCompiler: TSepiUnitCompiler);
begin
  inherited Create;

  FUnitCompiler := AUnitCompiler;
  FSepiRoot := AUnitCompiler.SepiRoot;
  FSystemUnit := AUnitCompiler.SystemUnit;
end;

{*
  Teste si une conversion vers un tableau ouvert existe
  @param ElementType   Type d'�l�ment voulu pour le tableau ouvert
  @param Expression    Expression � convertir
  @return True si Expression peut �tre convertie, False sinon
*}
function TSepiLanguageRules.ConvertionToOpenArrayExists(ElementType: TSepiType;
  const Expression: ISepiExpression): Boolean;
var
  OpenArray: ISepiOpenArrayValue;
  Value: ISepiReadableValue;
begin
  Result := Supports(Expression, ISepiOpenArrayValue, OpenArray) and
    (OpenArray.ElementType.Equals(ElementType) or
    OpenArray.CanForceElementType(ElementType));

  if (not Result) and Supports(Expression, ISepiReadableValue, Value) and
    (Value.ValueType is TSepiArrayType) and
    TSepiArrayType(Value.ValueType).ElementType.Equals(ElementType) then
    Result := True;
end;

{*
  Convertit une expression en tableau ouvert
  ConvertToOpenArray ne peut �tre appel�e que si ConvertionToOpenArrayExists
  renvoie True pour les m�mes arguments.
  L'expression renvoy�e est garantie supporter l'interface
  SepiExpressions.ISepiOpenArrayValue.
  @param ElementType   Type d'�l�ment voulu pour le tableau ouvert
  @param Expression    Expression � convertir
  @return Expression convertie en tableau ouvert
*}
function TSepiLanguageRules.ConvertToOpenArray(ElementType: TSepiType;
  const Expression: ISepiExpression): ISepiExpression;
var
  OpenArray: ISepiOpenArrayValue;
  Value: ISepiReadableValue;
begin
  Assert(ConvertionToOpenArrayExists(ElementType, Expression));

  if Supports(Expression, ISepiOpenArrayValue, OpenArray) then
  begin
    Result := Expression;
    if not OpenArray.ElementType.Equals(ElementType) then
      OpenArray.ForceElementType(ElementType);
  end else
  begin
    Value := Expression as ISepiReadableValue;
    Assert(Value.ValueType is TSepiArrayType);

    Result := TSepiOpenArrayFromArrayValue.MakeOpenArrayValue(
      Value) as ISepiExpression;
  end;
end;

{-----------------------}
{ TSepiExpression class }
{-----------------------}

{*
  Cr�e une expression
  @param ACompiler   Compilateur
*}
constructor TSepiExpression.Create(ACompiler: TSepiCompilerBase);
begin
  inherited Create;

  FBaseCompiler := ACompiler;
  if ACompiler is TSepiMethodCompiler then
    FMethodCompiler := TSepiMethodCompiler(ACompiler);
  FUnitCompiler := ACompiler.UnitCompiler;

  FSepiRoot := UnitCompiler.SepiRoot;
  FLanguageRules := UnitCompiler.LanguageRules;
end;

{*
  Cr�e une expression dans le m�me contexte qu'une autre expression
  @param Context   Expression qui fournit le contexte
*}
constructor TSepiExpression.Create(const Context: ISepiExpression);
begin
  inherited Create;

  FBaseCompiler := Context.BaseCompiler;
  FMethodCompiler := Context.MethodCompiler;
  FUnitCompiler := Context.UnitCompiler;
  FSepiRoot := Context.SepiRoot;
  FLanguageRules := Context.LanguageRules;

  FSourcePos := Context.SourcePos;
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
  Compilateur de base
  @return Compilateur de base
*}
function TSepiExpression.GetBaseCompiler: TSepiCompilerBase;
begin
  Result := FBaseCompiler;
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
  R�gles du langage utilis�
  @return R�gles du langage utilis�
*}
function TSepiExpression.GetLanguageRules: TSepiLanguageRules;
begin
  Result := FLanguageRules;
end;

{*
  Position dans le source
  @return Position dans le source
*}
function TSepiExpression.GetSourcePos: TSepiSourcePosition;
begin
  Result := FSourcePos;
end;

{*
  [@inheritDoc]
*}
procedure TSepiExpression.SetSourcePos(const Value: TSepiSourcePosition);
begin
  FSourcePos := Value;
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

{-------------------------}
{ TSepiCompilerBase class }
{-------------------------}

{*
  Cr�e un nouveau compilateur Sepi
  @param AUnitCompiler   Compilateur d'unit�
  @param AErrors         Gestionnaire d'erreurs
  @param ASepiUnit       Unit� Sepi � compiler
*}
constructor TSepiCompilerBase.Create(AUnitCompiler: TSepiUnitCompiler;
  AErrors: TSepiCompilerErrorList; ASepiUnit: TSepiUnit);
begin
  inherited Create;

  FUnitCompiler := AUnitCompiler;
  FErrors := AErrors;

  FSepiUnit := ASepiUnit;
  FSepiRoot := ASepiUnit.Root;
  FSystemUnit := FSepiRoot.SystemUnit as TSepiSystemUnit;
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
  inherited Create(AUnitCompiler, AUnitCompiler.Errors, AUnitCompiler.SepiUnit);

  FUnitCompiler := AUnitCompiler;
  FSystemUnit := FUnitCompiler.SystemUnit;
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

  FContinueReferences := TObjectStack.Create;
  FBreakReferences := TObjectStack.Create;
end;

{*
  [@inheritDoc]
*}
destructor TSepiMethodCompiler.Destroy;
begin
  FBreakReferences.Free;
  FContinueReferences.Free;

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
  Indique si la m�thode a un espace de noms local
  @return True si la m�thode a un espace de noms local, False sinon
*}
function TSepiMethodCompiler.GetHasLocalNamespace: Boolean;
begin
  Result := FLocalNamespace <> nil;
end;

{*
  Espace de noms local
  @return Espace de noms local
*}
function TSepiMethodCompiler.GetLocalNamespace: TSepiNamespace;
var
  SepiUnit: TSepiUnit;
  OldVisibility: TMemberVisibility;
begin
  if FLocalNamespace = nil then
  begin
    SepiUnit := UnitCompiler.SepiUnit;
    OldVisibility := SepiUnit.CurrentVisibility;
    try
      SepiUnit.CurrentVisibility := mvPrivate;
      FLocalNamespace := TSepiNamespace.Create(SepiUnit, '', SepiMethod);
    finally
      SepiUnit.CurrentVisibility := OldVisibility;
    end;
  end;

  Result := FLocalNamespace;
end;

{*
  R�f�rence � l'instruction de destination d'un continue courante
  Renvoie nil si on n'est pas actuellement dans une boucle
  @return R�f�rence � l'instruction de destination d'un continue courante
*}
function TSepiMethodCompiler.GetContinueRef: TSepiInstructionRef;
begin
  if FContinueReferences.Count = 0 then
    Result := nil
  else
    Result := TSepiInstructionRef(FContinueReferences.Peek);
end;

{*
  R�f�rence � l'instruction de destination d'un break courante
  Renvoie nil si on n'est pas actuellement dans une boucle
  @return R�f�rence � l'instruction de destination d'un break courante
*}
function TSepiMethodCompiler.GetBreakRef: TSepiInstructionRef;
begin
  if FBreakReferences.Count = 0 then
    Result := nil
  else
    Result := TSepiInstructionRef(FBreakReferences.Peek);
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
  �tre de type TSepiComponent ou TSepiParam.
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

  if FLocalNamespace = nil then
    Result := SepiMethod.LookFor(Name)
  else
    Result := FLocalNamespace.LookFor(Name);
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
  const LabelName: string; AllowCreate: Boolean = False): TSepiNamedLabel;
var
  Index: Integer;
begin
  Index := FNamedLabels.IndexOf(LabelName);

  if Index >= 0 then
    Result := TSepiNamedLabel(FNamedLabels.Objects[Index])
  else if AllowCreate then
    Result := TSepiNamedLabel.Create(Self, LabelName)
  else
    raise ESepiLabelError.CreateResFmt(@SLabelNotFound, [LabelName]);
end;

{*
  Entre dans une boucle, et met � jour ContinueRef et BreakRef
  @param ContinueRef   R�f�rence � l'instruction de destination d'un continue
  @param BreakRef      R�f�rence � l'instruction de destination d'un break
*}
procedure TSepiMethodCompiler.EnterLoop(
  ContinueRef, BreakRef: TSepiInstructionRef);
begin
  FContinueReferences.Push(ContinueRef);
  FBreakReferences.Push(BreakRef);
end;

{*
  Quitte la boucle courante, et r�cup�re les anciens ContinueRef et BreakRef
*}
procedure TSepiMethodCompiler.LeaveLoop;
begin
  FContinueReferences.Pop;
  FBreakReferences.Pop;
end;

{*
  Cr�e une vraie constante anonyme avec une valeur
  @param AType    Type de la constante
  @param AValue   Valeur de la constante
  @return Constante cr��e
*}
function TSepiMethodCompiler.MakeUnnamedTrueConst(AType: TSepiType;
  const AValue): TSepiConstant;
begin
  Result := TSepiConstant.Create(LocalNamespace, '', AType, AValue);
end;

{*
  Compl�te le corps de la m�thode
*}
procedure TSepiMethodCompiler.Complete;
begin
  if FLocalNamespace <> nil then
    FLocalNamespace.Complete;
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
  @param AErrors               Gestionnaire d'erreurs
  @param ASepiUnit             Unit� Sepi � compiler
  @param ALanguageRulesClass   Classe du gestionnaire des r�gles du langage
*}
constructor TSepiUnitCompiler.Create(AErrors: TSepiCompilerErrorList;
  ASepiUnit: TSepiUnit; ALanguageRulesClass: TSepiLanguageRulesClass);
begin
  inherited Create(Self, AErrors, ASepiUnit);

  FMethods := TObjectList.Create;
  FReferences := TObjectList.Create(False);

  FLanguageRules := ALanguageRulesClass.Create(Self);
end;

{*
  [@inheritDoc]
*}
destructor TSepiUnitCompiler.Destroy;
begin
  FReferences.Free;
  FLanguageRules.Free;
  FMethods.Free;

  inherited;
end;

{*
  S'assure que le conteneur de types de compilation est cr��
*}
procedure TSepiUnitCompiler.NeedCompileTimeTypes;
const
  CompileTimeTypesName = '$CompileTimeTypes';
begin
  if FCompileTimeTypes = nil then
    FCompileTimeTypes := TSepiComponent.Create(SepiUnit, CompileTimeTypesName);
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
  Obtient un type pointeur qui ne durera que la compilation
  @param PointTo   Type de donn�es point�es par le pointeur
  @return Type pointeur
*}
function TSepiUnitCompiler.GetPointerType(PointTo: TSepiType): TSepiPointerType;
var
  PointerTypeName: string;
  I: Integer;
begin
  if (PointTo = nil) or (PointTo is TSepiUntypedType) then
  begin
    Result := SystemUnit.Pointer;
    Exit;
  end;

  PointerTypeName := '^' + PointTo.GetFullName;
  for I := 1 to Length(PointerTypeName) do
    if PointerTypeName[I] = '.' then
      PointerTypeName[I] := '$';

  NeedCompileTimeTypes;
  Result := FCompileTimeTypes.GetComponent(PointerTypeName) as TSepiPointerType;
  if Result = nil then
    Result := TSepiPointerType.Create(FCompileTimeTypes,
      PointerTypeName, PointTo);
end;

{*
  Obtient un type meta-classe qui ne durera que la compilation
  @param SepiClass   Classe dont obtenir une meta-classe
  @return Meta-classe de la classe
*}
function TSepiUnitCompiler.GetMetaClass(SepiClass: TSepiClass): TSepiMetaClass;
var
  MetaClassName: string;
  I: Integer;
begin
  MetaClassName := 'class$' + SepiClass.GetFullName;
  for I := 1 to Length(MetaClassName) do
    if MetaClassName[I] = '.' then
      MetaClassName[I] := '$';

  NeedCompileTimeTypes;
  Result := FCompileTimeTypes.GetComponent(MetaClassName) as TSepiMetaClass;
  if Result = nil then
    Result := TSepiMetaClass.Create(FCompileTimeTypes,
      MetaClassName, SepiClass);
end;

{*
  Obtient un type g�n�rique r�f�rence de m�thode pour la compilation
  @return Type g�n�rique r�f�rence de m�thode
*}
function TSepiUnitCompiler.GetMethodRefType: TSepiType;
const
  MethodRefTypeName = '$MethodRef';
begin
  NeedCompileTimeTypes;
  Result := FCompileTimeTypes.GetComponent(MethodRefTypeName) as TSepiType;
  if Result = nil then
    Result := TSepiTypeForceMeType.Create(FCompileTimeTypes, MethodRefTypeName);
end;

{*
  Obtient un type d'ensemble vide qui ne durera que la compilation
  @return Type ensemble vide
*}
function TSepiUnitCompiler.GetEmptySetType: TSepiType;
const
  EmptySetTypeName = '$EmptySet';
begin
  NeedCompileTimeTypes;
  Result := FCompileTimeTypes.GetComponent(EmptySetTypeName) as TSepiType;
  if Result = nil then
    Result := TSepiEmptySetType.Create(FCompileTimeTypes, EmptySetTypeName);
end;

{*
  Construit un type ensemble pour un type d'�l�ment donn� (passe la compilation)
  @param CompType   Type d'�l�ment de l'ensemble
  @return Type ensemble dont les �l�ments sont de type CompType
*}
function TSepiUnitCompiler.MakeSetType(CompType: TSepiOrdType): TSepiSetType;
var
  I: Integer;
  Child: TSepiComponent absolute Result;
begin
  for I := 0 to SepiUnit.ChildCount-1 do
  begin
    Child := SepiUnit.Children[I];
    if (Child is TSepiSetType) and (Result.CompType = CompType) then
      Exit;
  end;

  Result := TSepiSetType.Create(SepiUnit, '', CompType);
end;

{*
  R�cup�re le type erron� s'il existe d�j�, sinon le cr�e
  @return Type erron�
*}
function TSepiUnitCompiler.GetErroneousType: TSepiType;
begin
  if FErroneousType = nil then
    FErroneousType := TSepiIntegerType.Create(SepiUnit,
      SSepiErroneousTypeName);

  Result := FErroneousType;
end;

{*
  Cr�e un alias du type erron�
  @param TypeName   Nom de l'alias (une cha�ne vide ne cr�e pas d'alias)
  @return Type erron�
*}
function TSepiUnitCompiler.MakeErroneousTypeAlias(
  const AliasName: string): TSepiType;
begin
  Result := GetErroneousType;
  if AliasName <> '' then
    TSepiTypeAlias.Create(SepiUnit, AliasName, Result);
end;

{*
  Cherche le compilateur de m�thode pour une m�thode donn�e
  @param SepiMethod    M�thode dont on cherche le compilateur
  @param AllowCreate   Si True, permet de cr�er le compilateur si inexistant
  @return Compilateur pour la m�thode donn�e, ou nil si non trouv�
*}
function TSepiUnitCompiler.FindMethodCompiler(SepiMethod: TSepiMethod;
  AllowCreate: Boolean = False): TSepiMethodCompiler;
var
  I: Integer;
begin
  for I := 0 to MethodCount-1 do
  begin
    Result := Methods[I];
    if Result.SepiMethod = SepiMethod then
      Exit;
  end;

  if AllowCreate then
    Result := TSepiMethodCompiler.Create(Self, SepiMethod)
  else
    Result := nil;
end;

{*
  Construit un num�ro de r�f�rence � un meta Sepi
  @param Component   Component pour lequel construire un num�ro de r�f�rence
  @return Num�ro de r�f�rence du meta
*}
function TSepiUnitCompiler.MakeReference(Component: TSepiComponent): Integer;
begin
  Result := FReferences.IndexOf(Component);
  if Result < 0 then
  begin
    Result := FReferences.Add(Component);
    SepiUnit.MoreUses([Component.OwningUnit.Name]);
  end;
end;

{*
  Ecrit l'unit� compil�e dans un flux
  @param Stream   Flux destination
*}
procedure TSepiUnitCompiler.WriteToStream(Stream: TStream);
var
  I, Count: Integer;
  Digest: TSepiDigest;
begin
  // Compile methods
  for I := 0 to MethodCount-1 do
    Methods[I].Compile;

  // Delete compile-time types
  FreeAndNil(FCompileTimeTypes);

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
  begin
    WriteStrToStream(Stream, TSepiComponent(FReferences[I]).GetFullName);
    Digest := TSepiComponent(FReferences[I]).Digest;
    Stream.WriteBuffer(Digest, SizeOf(TSepiDigest));
  end;

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

  Assign(Source, False);
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
  S'assure que la r�f�rence m�moire est r�solue
*}
procedure TSepiMemoryReference.EnsureResolved;
begin
  if Space = msUnresolvedLocalVar then
  begin
    FIsSealed := False;
    SetSpace(FUnresolvedLocalVar);
  end;
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
  Modifie l'espace m�moire sur base d'une variable locale
  @param Variable   Variable � pointer par l'espace m�moire
*}
procedure TSepiMemoryReference.SetSpace(LocalVar: TSepiLocalVar);
begin
  if LocalVar.IsFixed then
  begin
    if LocalVar.IsParam then
      SetSpace(msParamsBase, LocalVar.Offset)
    else
      SetSpace(msLocalsBase, LocalVar.Offset);

    if LocalVar.NeedDereference then
      AddOperation(adSimple);
  end else
  begin
    SetSpace(msUnresolvedLocalVar);
    FUnresolvedLocalVar := LocalVar;
  end;
end;

{*
  Modifie l'espace m�moire sur base d'une vraie constante
  @param Constant   Constante � pointer par l'espace m�moire
*}
procedure TSepiMemoryReference.SetSpace(Constant: TSepiConstant);
begin
  with Constant do
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
        MethodCompiler.UnitCompiler.MakeReference(Constant));
    end;
  end;
end;

{*
  Modifie l'espace m�moire sur base d'une variable globale
  @param Variable   Variable � pointer par l'espace m�moire
*}
procedure TSepiMemoryReference.SetSpace(Variable: TSepiVariable);
begin
  SetSpace(msVariable, MethodCompiler.UnitCompiler.MakeReference(Variable));
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
  else if Obj is TSepiConstant then
    SetSpace(TSepiConstant(Obj))
  else if Obj is TSepiVariable then
    SetSpace(TSepiVariable(Obj))
  else
    raise ESepiComponentNotFoundError.CreateFmt(
      SSepiComponentNotFound, [Name]);
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
  MemArgSizes:
    array[aoPlusMemShortint..aoPlusLongConstTimesMemLongWord] of Integer
    = (1, 2, 4, 1, 2, 4, 1, 2, 4, 1, 2, 4, 1, 2, 4);
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
      Operation := ConstArgSizeToOp[IntegerSize(AConstOperationArg)]
    else if (Operation in
      [aoPlusConstTimesMemShortint..aoPlusConstTimesMemLongWord]) and
      (CardinalSize(AConstOperationArg) > 1) then
      Inc(Byte(Operation), 6)
    else if (Operation in
      [aoPlusLongConstTimesMemShortint..aoPlusLongConstTimesMemLongWord]) and
      (CardinalSize(AConstOperationArg) = 1) then
      Dec(Byte(Operation), 6);

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
  Teste si la r�f�rence m�moire vaut en fait la constante 1
  @return True si la r�f�rence m�moire vaut la constante 1, False sinon
*}
function TSepiMemoryReference.IsConstantOne: Boolean;
var
  I: Integer;
begin
  Result := False;

  if (Space <> msConstant) or (OperationCount <> 0) then
    Exit;

  if Byte(FConstant^) <> 1 then
    Exit;

  for I := 1 to ConstSize-1 do
    if TByteArray(FConstant^)[I] <> 0 then
      Exit;

  Result := True;
end;

{*
  Recopie depuis une r�f�rence m�moire
  Cette m�thode ne fait pas un cl�ne : elle copie les espace m�moire et
  op�rations, mais pas les options ou le statut scell�. Il est donc possible
  que cette m�thode �choue si la r�f�rence source n'est pas compatible avec les
  options de celles-ci.
  @param Source      R�f�rence m�moire � recopier
  @param SealAfter   Si True (par d�faut), scelle cette r�f�rence m�moire apr�s
*}
procedure TSepiMemoryReference.Assign(Source: TSepiMemoryReference;
  SealAfter: Boolean = True);
var
  ConstType: TSepiType;
  ConstVariable: TSepiVariable;
  I: Integer;
  MemOpArg: TSepiMemoryReference;
begin
  CheckUnsealed;

  ClearOperations;

  if (Source.Space = msConstant) and (not (aoAcceptConstInCode in Options)) then
  begin
    case Source.ConstSize of
      1: ConstType := MethodCompiler.SystemUnit.Byte;
      2: ConstType := MethodCompiler.SystemUnit.Word;
      4: ConstType := MethodCompiler.SystemUnit.LongWord;
      8: ConstType := MethodCompiler.SystemUnit.Int64;
      10: ConstType := MethodCompiler.SystemUnit.Extended;
    else
      ConstType := TSepiStaticArrayType.Create(MethodCompiler.LocalNamespace,
        '', MethodCompiler.SystemUnit.Integer, 0, Source.ConstSize-1,
        MethodCompiler.SystemUnit.Byte);
    end;

    ConstVariable := TSepiVariable.Create(MethodCompiler.LocalNameSpace, '',
      ConstType, True);
    Source.GetConstant(ConstVariable.Value^);
    SetSpace(ConstVariable);
  end else
  begin
    SetSpace(Source.Space, Source.SpaceArgument);

    if Space = msConstant then
      Source.GetConstant(FConstant^)
    else if Space = msUnresolvedLocalVar then
      FUnresolvedLocalVar := Source.FUnresolvedLocalVar;
  end;

  for I := 0 to Source.OperationCount-1 do
  begin
    with Source.Operations[I] do
    begin
      MemOpArg := AddOperation(Dereference, Operation, ConstOperationArg);
      if MemOpArg <> nil then
        MemOpArg.Assign(MemOperationArg);
    end;
  end;
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
  Teste si cette r�f�rence m�moire et �gale � une autre
  @param Other   Autre r�f�rence m�moire
  @return True si Self et Other r�f�rencent le m�me emplacement m�moire
*}
function TSepiMemoryReference.Equals(Other: TSepiMemoryReference): Boolean;

  function SameOperation(const Left, Right: TSepiAddressDerefAndOpRec): Boolean;
  begin
    Result := (Left.Dereference = Right.Dereference) and
      (Left.Operation = Right.Operation) and
      (Left.ConstOperationArg = Right.ConstOperationArg) and
      Left.MemOperationArg.Equals(Right.MemOperationArg);
  end;

var
  I: Integer;
begin
  if (Self = nil) or (Other = nil) then
  begin
    Result := Self = Other;
    Exit;
  end;

  EnsureResolved;
  Other.EnsureResolved;
  Result := False;

  // Space
  if (Space <> Other.Space) or (SpaceArgument <> Other.SpaceArgument) then
    Exit;

  // Operation count
  if OperationCount <> Other.OperationCount then
    Exit;

  // Operations
  for I := 0 to OperationCount-1 do
    if not SameOperation(Operations[I], Other.Operations[I]) then
      Exit;

  Result := True;
end;

{*
  Construit la r�f�rence m�moire
*}
procedure TSepiMemoryReference.Make;
var
  I: Integer;
begin
  // Resolve the local var, if needed
  EnsureResolved;

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
      Inc(FSize, OperationToConstArgSize[Operation]);

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
      if OperationToConstArgSize[Operation] > 0 then
        Stream.WriteBuffer(ConstOperationArg,
          OperationToConstArgSize[Operation]);

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

{---------------------------}
{ TSepiLocalVarVertex class }
{---------------------------}

{*
  Cr�e un noeud de variable locale
  @param ALocalVar   Variable locale repr�sent�e
*}
constructor TSepiLocalVarVertex.Create(ALocalVar: TSepiLocalVar);
begin
  inherited Create;

  FLocalVar := ALocalVar;

  FAdjacents := TObjectList.Create(False);
end;

{*
  Nombre de noeuds adjacents
  @return Nombre de noeuds adjacents
*}
function TSepiLocalVarVertex.GetAdjacentCount: Integer;
begin
  Result := FAdjacents.Count;
end;

{*
  Tableau zero-based des noeuds adjacents
  @param Index   Index d'un noeud adjacent
  @return Noeud adjacent � l'index sp�cifi�
*}
function TSepiLocalVarVertex.GetAdjacents(Index: Integer): TSepiLocalVarVertex;
begin
  Result := TSepiLocalVarVertex(FAdjacents[Index]);
end;

{*
  Ajoute un noeud adjencent
  @param Adjacent   Noeud adjacent
  @param DoReciprocal   Indique s'il faut faire l'op�ration r�ciproque
*}
procedure TSepiLocalVarVertex.AddAdjacent(Adjacent: TSepiLocalVarVertex;
  DoReciprocal: Boolean = True);
begin
  FAdjacents.Add(Adjacent);
  if DoReciprocal then
    Adjacent.AddAdjacent(Self, False);
end;

{*
  Supprime un noeud adjencent
  @param Adjacent   Noeud adjacent
  @param DoReciprocal   Indique s'il faut faire l'op�ration r�ciproque
*}
procedure TSepiLocalVarVertex.RemoveAdjacent(Adjacent: TSepiLocalVarVertex;
  DoReciprocal: Boolean = True);
begin
  FAdjacents.Remove(Adjacent);
  if DoReciprocal then
    Adjacent.RemoveAdjacent(Self, False);
end;

{--------------------------}
{ TSepiLocalVarGraph class }
{--------------------------}

{*
  Cr�e un graphe vide
*}
constructor TSepiLocalVarGraph.Create;
begin
  inherited Create;

  FVertices := TObjectList.Create;
end;

{*
  [@inheritDoc]
*}
destructor TSepiLocalVarGraph.Destroy;
begin
  FVertices.Free;

  inherited;
end;

{*
  Construit les arcs d'adjacence
*}
procedure TSepiLocalVarGraph.MakeAdjacents;
var
  I, J: Integer;
  VertexI, VertexJ: TSepiLocalVarVertex;
begin
  for I := 0 to VertexCount-2 do
  begin
    VertexI := Vertices[I];
    for J := I+1 to VertexCount-1 do
    begin
      VertexJ := Vertices[J];
      if VertexI.LocalVar.InterfereWith(VertexJ.LocalVar) then
        VertexI.AddAdjacent(VertexJ);
    end;
  end;
end;

{*
  Choisit une couleur pour un noeud donn�
  @param Vertex   Noeud concern�
  @return Couleur choisie
*}
function TSepiLocalVarGraph.ColorForVertex(
  Vertex: TSepiLocalVarVertex): Integer;
var
  UsedColors: TBooleanDynArray;
  I: Integer;
begin
  SetLength(UsedColors, ColorCount);
  FillChar(UsedColors[0], ColorCount * SizeOf(Boolean), 0);

  for I := 0 to Vertex.AdjacentCount-1 do
    UsedColors[Vertex.Adjacents[I].Color] := True;

  Result := 0;
  while (Result < ColorCount) and UsedColors[Result] do
    Inc(Result);

  if Result = ColorCount then
  begin
    ColorCount := ColorCount+1;
    FColorSizes[Result] := 0;
  end;
end;

{*
  Colorie le graphe
*}
procedure TSepiLocalVarGraph.Colorize;
var
  Backups: TObjectStack;
  I: Integer;
  Vertex: TSepiLocalVarVertex;
begin
  ColorCount := 0;

  Backups := TObjectStack.Create;
  try
    // Pass 1 - remove all nodes of the graph
    while VertexCount > 0 do
    begin
      // Find the vertex with lowest degree
      Vertex := Vertices[0];
      for I := 1 to VertexCount-1 do
      begin
        if Vertices[I].AdjacentCount < Vertex.AdjacentCount then
          Vertex := Vertices[I];
      end;

      // Disconnect the vertex from the graph
      FVertices.Extract(Vertex);
      for I := 0 to Vertex.AdjacentCount-1 do
        Vertex.Adjacents[I].RemoveAdjacent(Vertex, False);

      // Back up the vertex
      Backups.Push(Vertex);
    end;

    // Pass 2 - rebuild the graph and give colors
    while Backups.Count > 0 do
    begin
      Vertex := TSepiLocalVarVertex(Backups.Pop);
      Vertex.Color := ColorForVertex(Vertex);

      // Update color size
      if Vertex.LocalVar.VarType.Size > FColorSizes[Vertex.Color] then
        FColorSizes[Vertex.Color] := Vertex.LocalVar.VarType.Size;

      // Reconnect the vertex to the graph
      for I := 0 to Vertex.AdjacentCount-1 do
        Vertex.Adjacents[I].AddAdjacent(Vertex, False);
      FVertices.Add(Vertex);
    end;
  finally
    Backups.Free;
  end;
end;

{*
  Assigne les offsets
  @param Size   Taille des variables locales
*}
procedure TSepiLocalVarGraph.SetOffsets(var Size: Integer);
var
  ColorOffsets: TIntegerDynArray;
  I: Integer;
begin
  // Compute color offsets
  SetLength(ColorOffsets, ColorCount);
  for I := 0 to ColorCount-1 do
  begin
    ColorOffsets[I] := Size;
    Inc(Size, FColorSizes[I]);
  end;

  // Set offsets to variables
  for I := 0 to VertexCount-1 do
    Vertices[I].LocalVar.SetOffset(ColorOffsets[Vertices[I].Color]);
end;

{*
  Nombre de noeuds
  @return Nombre de noeuds
*}
function TSepiLocalVarGraph.GetVertexCount: Integer;
begin
  Result := FVertices.Count;
end;

{*
  Tableau zero-based des noeuds
  @param Index   Index d'un noeud
  @return Noeud � l'index sp�cifi�
*}
function TSepiLocalVarGraph.GetVertices(Index: Integer): TSepiLocalVarVertex;
begin
  Result := TSepiLocalVarVertex(FVertices[Index]);
end;

{*
  Nombre de couleurs
  @return Nombre de couleurs
*}
function TSepiLocalVarGraph.GetColorCount: Integer;
begin
  Result := Length(FColorSizes);
end;

{*
  Modifie le nombre de couleurs
  @param Value   Nouveau nombre de couleurs
*}
procedure TSepiLocalVarGraph.SetColorCount(Value: Integer);
begin
  SetLength(FColorSizes, Value);
end;

{*
  Ajoute une variable locale � traiter
  @param LocalVar   Variable locale � ajouter
*}
procedure TSepiLocalVarGraph.AddLocalVar(LocalVar: TSepiLocalVar);
begin
  FVertices.Add(TSepiLocalVarVertex.Create(LocalVar));
end;

{*
  Colorie le graphe et assigne les offsets
  @param Size   Taille des variables locales
*}
procedure TSepiLocalVarGraph.ColorizeAndSetOffsets(var Size: Integer);
begin
  MakeAdjacents;
  Colorize;
  SetOffsets(Size);
end;

end.

