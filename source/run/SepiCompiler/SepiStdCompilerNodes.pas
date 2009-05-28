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
  Classes de compilation standard d'une unit� Sepi
  @author sjrd
  @version 1.0
*}
unit SepiStdCompilerNodes;

interface

{$ASSERTIONS ON}

uses
  Windows, Types, SysUtils, Classes, StrUtils, TypInfo, SysConst, ScUtils,
  ScStrUtils, ScDelphiLanguage,
  SepiCore,
  SepiReflectionCore, SepiMembers, SepiOrdTypes, SepiStrTypes, SepiArrayTypes,
  SepiOpCodes,
  SepiCompiler, SepiCompilerErrors, SepiExpressions, SepiInstructions,
  SepiCompilerConsts,
  SepiParseTrees, SepiCompilerUtils, SepiDelphiLikeCompilerUtils;

type
  {*
    Noeud section uses
    Chaque enfant d'un noeud section uses doit �tre un noeud dont le AsText est
    un nom d'unit�. Chaque unit� ainsi r�f�renc�e est ajout�e aux uses de
    l'unit� en cours de compilation.
    @author sjrd
    @version 1.0
  *}
  TSepiUsesNode = class(TSepiNonTerminal)
  private
    function IsRedeclared(const UnitName: string): Boolean;
  protected
    procedure ChildEndParsing(Child: TSepiParseTreeNode); override;
  end;

  {*
    Identificateur qualifi�
    Chaque enfant d'un identificateur qualifi� est un des qualificateurs. Le
    AsText d'un TSepiQualifiedIdent est la liaison des AsText de ses enfants,
    avec des '.' entre chaque.
    @author sjrd
    @version 1.0
  *}
  TSepiQualifiedIdentNode = class(TSepiNonTerminal)
  protected
    function GetAsText: string; override;
  end;

  {*
    Noeud d'expression d'initialisation
    Une expression d'initialisation est une expression constante qui initialise
    une valeur connue � la compilation, et dont le type est d�j� connu.
    Avant son BeginParsing, la m�thode SetValueTypeAndPtr doit �tre appel�e pour
    sp�cifier quel est le type de valeur attendu, et o� placer le r�sultat.
    Les types accept�s par une instance particuli�re de
    TSepiInitializationExpressionNode peuvent �tre test�s avec IsValidType. Par
    d�faut, TSepiInitializationExpressionNode accepte tous les types non-nil.
    @author sjrd
    @version 1.0
  *}
  TSepiInitializationExpressionNode = class(TSepiNonTerminal)
  private
    FValueType: TSepiType; /// Type de valeur
    FValuePtr: Pointer;    /// Pointeur sur la valeur � initialiser

    FOwnsValue: Boolean; /// True si poss�de la valeur dans FValuePtr
  public
    destructor Destroy; override;

    procedure BeginParsing; override;

    function IsValidType(AValueType: TSepiType): Boolean; virtual;

    procedure SetValueTypeAndPtr(AValueType: TSepiType;
      AValuePtr: Pointer = nil);

    property ValueType: TSepiType read FValueType;
    property ValuePtr: Pointer read FValuePtr;
  end;

  {*
    Noeud expression
    @author sjrd
    @version 1.0
  *}
  TSepiExpressionNode = class(TSepiNonTerminal)
  private
    FExpression: ISepiExpression; /// Expression compil�e

    function TryAndForceType(var Value: ISepiValue;
      ValueType: TSepiType): Boolean;
    function TryAndConvert(var Value: ISepiValue;
      ValueType: TSepiType): Boolean;
    function TryAndMatchType(var Value: ISepiValue; ValueType: TSepiType;
      AllowConvertion: Boolean): Boolean;
    procedure RequireType(var Value: ISepiValue; ValueType: TSepiType;
      AllowConvertion: Boolean);
  protected
    procedure SetExpression(const AExpression: ISepiExpression);
    procedure SetExpressionPart(const ExpressionPart: ISepiExpressionPart);

    function MakeErroneousValue(ValueType: TSepiType = nil): ISepiReadableValue;

    function ValidateExpression: Boolean; virtual;
    procedure MakeErroneousExpression; virtual;
  public
    procedure EndParsing; override;

    function AsExpressionPart(const IID: TGUID; out Intf;
      const ErrorMsg: string = ''): Boolean;

    function AsValue(ValueType: TSepiType = nil;
      AllowConvertion: Boolean = True): ISepiValue;
    function AsReadableValue(ValueType: TSepiType = nil;
      AllowConvertion: Boolean = True): ISepiReadableValue;
    function AsMeta: TSepiMeta;
    function AsType: TSepiType;

    property Expression: ISepiExpression read FExpression;
  end;

  {*
    Noeud expression qui vaut la m�me expression que son unique fils
    Un exemple d'un tel noeud est l'expression parenth�s�e, qui se d�crit comme
      '('* Expression ')'*
    Sa fonction est uniquement syntaxique, et sa valeur se r�cup�re directement
    de son unique fils.
    @author sjrd
    @version 1.0
  *}
  TSepiSameAsChildExpressionNode = class(TSepiExpressionNode)
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud valeur
    @author sjrd
    @version 1.0
  *}
  TSepiValueNode = class(TSepiExpressionNode)
  protected
    function ValidateExpression: Boolean; override;
  end;

  {*
    Sens d'�valuation d'un op�rateur binaire
    - bodLeftToRight : �valu� de gauche � droite (comme la soustraction) ;
    - bodRightToLeft : �valu� de droite � gauche (comme le = du C).
  *}
  TSepiBinaryOpDirection = (bodLeftToRight, bodRightToLeft);

  {*
    Noeud repr�sentant un op�rateur binaire
    @author sjrd
    @version 1.0
  *}
  TSepiBinaryOpNode = class(TSepiNonTerminal)
  protected
    function GetPriority: Integer; virtual;
    function GetDirection: TSepiBinaryOpDirection; virtual;
  public
    function MakeOperation(
      const Left, Right: ISepiExpression): ISepiExpression; virtual; abstract;

    property Priority: Integer read GetPriority;
    property Direction: TSepiBinaryOpDirection read GetDirection;
  end;

  {*
    Noeud expression calcul� par un arbre d'op�rations binaires
    @author sjrd
    @version 1.0
  *}
  TSepiBinaryOpTreeNode = class(TSepiExpressionNode)
  private
    function FindSubTreeOpIndex(Lower, Higher: Integer): Integer;
    function CompileSubTree(Lower, Higher: Integer): ISepiExpression;
  protected
    function CompileTree: ISepiExpression;
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud repr�sentant un op�rateur unaire
    @author sjrd
    @version 1.0
  *}
  TSepiUnaryOpNode = class(TSepiNonTerminal)
  public
    function MakeOperation(
      const Operand: ISepiExpression): ISepiExpression; virtual; abstract;
  end;

  {*
    Noeud expression calcul� par une op�ration unaire
    Un noeud de ce type doit poss�der exactement deux enfants. L'un des deux
    doit �tre de type TSepiUnaryOpNode et l'autre de type TSepiExpressionNode.
    @author sjrd
    @version 1.0
  *}
  TSepiUnaryOperationNode = class(TSepiExpressionNode)
  protected
    function CompileOperation(OperatorNode: TSepiUnaryOpNode;
      OperandNode: TSepiExpressionNode): ISepiExpression;
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud repr�sentant une constante litt�rale
    @author sjrd
    @version 1.0
  *}
  TSepiLiteralConstNode = class(TSepiExpressionNode)
  protected
    function CompileAsValue: ISepiValue; virtual; abstract;
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud repr�sentant une constante litt�rale enti�re
    @author sjrd
    @version 1.0
  *}
  TSepiConstIntegerNode = class(TSepiLiteralConstNode)
  protected
    function CompileAsInteger: Int64; virtual;

    function CompileAsValue: ISepiValue; override;
  end;

  {*
    Noeud repr�sentant une constante litt�rale flottante
    @author sjrd
    @version 1.0
  *}
  TSepiConstFloatNode = class(TSepiLiteralConstNode)
  protected
    function CompileAsExtended: Extended; virtual;

    function CompileAsValue: ISepiValue; override;
  end;

  {*
    Noeud repr�sentant une constante litt�rale cha�ne de caract�res
    @author sjrd
    @version 1.0
  *}
  TSepiConstStringNode = class(TSepiLiteralConstNode)
  protected
    function CompileAsString: string; virtual;

    function CompileAsValue: ISepiValue; override;
  end;

  {*
    Noeud repr�sentant un identificateur � r�soudre
    @author sjrd
    @version 1.0
  *}
  TSepiIdentifierExpressionNode = class(TSepiExpressionNode)
  protected
    procedure CompileIdentifier; virtual;
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud repr�sentant la valeur sp�ciale nil
    @author sjrd
    @version 1.0
  *}
  TSepiNilValueNode = class(TSepiExpressionNode)
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud repr�sentant une expression d'appel inherited
    @author sjrd
    @version 1.0
  *}
  TSepiInheritedExpressionNode = class(TSepiExpressionNode)
  protected
    function RequireClassOrObjectMethod: Boolean;

    function GetMethodName: string; virtual;
    function FindMethod: TSepiMeta; virtual;

    function MakeCallable(SepiMethod: TSepiMeta;
      const SelfParam: ISepiReadableValue): ISepiCallable; virtual;

    function CompileCallable: ISepiCallable; virtual;
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud repr�sentant une expression avec des modificateurs
    Le premier enfant d'un noeud de ce type est une expression classique, de
    type TSepiExpressionNode. Les suivants sont des "modifieurs", de type
    TSepiExpressionModifierNode, qui modifient successivement les expressions
    interm�diaire.
    Par exemple, s'il y a trois enfants, le r�sultat est l'application du
    modifieur 2 sur une expression interm�diaire, qui est l'application du
    modifieur 1 sur l'expression de l'enfant 0.
    Des modifieurs courants sont des indices de tableaux, des param�tres d'appel
    de m�thode ou une s�lection d'un champ.
    @author sjrd
    @version 1.0
  *}
  TSepiExpressionWithModifiersNode = class(TSepiExpressionNode)
  protected
    procedure ChildBeginParsing(Child: TSepiParseTreeNode); override;
    procedure ChildEndParsing(Child: TSepiParseTreeNode); override;
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud modifieur d'expression
    Une modifieur d'expression est un noeud qui part d'une expression existante
    et la modifie. L'expression de base doit �tre renseign�e avec SetBase avant
    BeginParsing.
    @author sjrd
    @version 1.0
  *}
  TSepiExpressionModifierNode = class(TSepiExpressionNode)
  private
    FBase: ISepiExpression; /// Expression de base � modifier
  protected
    property Base: ISepiExpression read FBase;
  public
    procedure SetBase(const ABase: ISepiExpression);
  end;

  {*
    Noeud index de tableau ou de propri�t� tableau
    @author sjrd
    @version 1.0
  *}
  TSepiArrayIndicesModifierNode = class(TSepiExpressionModifierNode)
  protected
    procedure CompileProperty(const Prop: ISepiProperty); virtual;
    procedure CompileArrayItem(const BaseValue: ISepiValue); virtual;
    procedure CompileDefaultProperty(
      const ObjectValue: ISepiReadableValue); virtual;
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud s�lection de champ
    @author sjrd
    @version 1.0
  *}
  TSepiFieldSelectionModifierNode = class(TSepiExpressionModifierNode)
  protected
    function MakeFieldSelection: ISepiExpression; virtual;
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud d�r�f�rencement
    @author sjrd
    @version 1.0
  *}
  TSepiDereferenceModifierNode = class(TSepiExpressionModifierNode)
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud repr�sentant une d�claration d'un identificateur
    TSepiIdentifierDeclarationNode prend en charge la v�rification de l'unicit�
    de l'identificateur, et son remplacement en cas d'erreur.
    La v�rification se fait au moyen de IsRedeclared. De plus, si le parent d'un
    tel noeud est une instance de TSepiIdentifierDeclListNode, sont consid�r�s
    les identificateurs d�j� d�clar�s dans la liste, tels que test�s avec la
    fonction TSepiIdentifierDeclListNode.IsDeclared.
    @author sjrd
    @version 1.0
  *}
  TSepiIdentifierDeclarationNode = class(TSepiNonTerminal)
  private
    FIdentifier: string; /// Identificateur (si vide, AsText est utilis�)

    function IsRedeclaredInCurrentList: Boolean;

    function GetIdentifier: string;
  protected
    procedure SetIdentifier(const AIdentifier: string);

    function IsRedeclared: Boolean; virtual;
    procedure MakeErroneousName; virtual;
  public
    procedure EndParsing; override;

    property Identifier: string read GetIdentifier;
  end;

  {*
    Noeud repr�sentant une d�claration d'un identificateur non v�rifi�
    @author sjrd
    @version 1.0
  *}
  TSepiUncheckedIdentifierDeclNode = class(TSepiIdentifierDeclarationNode)
  protected
    function IsRedeclared: Boolean; override;
  end;

  {*
    Noeud repr�sentant une liste de d�clarations d'identificateurs
    Tous les enfants d'une instance de TSepiIdentifierDeclListNode doivent �tre
    des instances de TSepiIdentifierDeclarationNode.
    @author sjrd
    @version 1.0
  *}
  TSepiIdentifierDeclListNode = class(TSepiNonTerminal)
  private
    FIdentifierCount: Integer; /// Nombre d'identificateurs

    function GetIdentifiers(Index: Integer): string;
  protected
    procedure ChildBeginParsing(Child: TSepiParseTreeNode); override;
    procedure ChildEndParsing(Child: TSepiParseTreeNode); override;
  public
    function IsDeclared(const Identifier: string): Boolean;

    property IdentifierCount: Integer read FIdentifierCount;
    property Identifiers[Index: Integer]: string read GetIdentifiers;
  end;

  {*
    Classe de base pour les noeuds qui doivent construire une signature
    TSepiSignatureBuilderNode ne cr�e pas elle-m�me d'instance de
    TSepiSignature. Elle est pr�vue pour construire une signature cr��e par un
    noeud parent, et renseign�e au moyen de SetSignature (avant BeginParsing).
    Certaines sous-classes de TSepiSignatureBuilderNode acceptent que Signature
    ne soit pas renseign�e. Dans ce cas, elles n'ont aucun effet en elles-m�mes,
    mais proposent souvent des propri�t�s permettant de savoir quel aurait �t�
    son effet si Signature avait �t� renseign�.
    TSepiSignatureBuilderNode transf�re aussi sa signature � tous ses enfants
    qui sont des instances de TSepiSignatureBuilderNode.
    leur effet.
    @author sjrd
    @version 1.0
  *}
  TSepiSignatureBuilderNode = class(TSepiNonTerminal)
  private
    FSignature: TSepiSignature; /// Signature � construire
  protected
    procedure ChildBeginParsing(Child: TSepiParseTreeNode); override;

    property Signature: TSepiSignature read FSignature;
  public
    procedure SetSignature(ASignature: TSepiSignature);
  end;

  {*
    Noeud repr�sentant un type de signature
    Cette classe admet que Signature ne soit pas renseign�e.
    @author sjrd
    @version 1.0
  *}
  TSepiSignatureKindNode = class(TSepiSignatureBuilderNode)
  protected
    function GetKind: TSepiSignatureKind; virtual;
  public
    procedure EndParsing; override;

    property Kind: TSepiSignatureKind read GetKind;
  end;

  {*
    Noeud repr�sentant la convention d'appel d'une signature
    Cette classe admet que Signature ne soit pas renseign�e.
    @author sjrd
    @version 1.0
  *}
  TSepiCallingConventionNode = class(TSepiSignatureBuilderNode)
  protected
    function GetCallingConvention: TCallingConvention; virtual;
  public
    procedure EndParsing; override;

    property CallingConvention: TCallingConvention read GetCallingConvention;
  end;

  {*
    Noeud repr�sentant le type de retour d'une signature
    @author sjrd
    @version 1.0
  *}
  TSepiSignatureReturnTypeNode = class(TSepiSignatureBuilderNode)
  private
    procedure AdaptSignatureKindToProcedure;
    procedure AdaptSignatureKindToFunction;
    procedure AdaptSignatureKindIfNeeded;
  protected
    function MustAdaptSignatureKind: Boolean; virtual;

    function GetTypeName: string;

    procedure CompileNoReturnType; virtual;
    function CompileReturnType: TSepiType; virtual;

    property TypeName: string read GetTypeName;
  public
    procedure EndParsing; override;
  end;

  {*
    Noeud d�claration de m�thode
    @author sjrd
    @version 1.0
  *}
  TSepiMethodDeclarationNode = class(TSepiNonTerminal)
  private
    FName: string;              /// Nom de la m�thode
    FSignature: TSepiSignature; /// Signature
    FIsOverloaded: Boolean;     /// True si surcharg�e
  protected
    procedure ChildBeginParsing(Child: TSepiParseTreeNode); override;
    procedure ChildEndParsing(Child: TSepiParseTreeNode); override;
  public
    destructor Destroy; override;

    procedure BeginParsing; override;
    procedure EndParsing; override;

    property Name: string read FName;
    property Signature: TSepiSignature read FSignature;
    property IsOverloaded: Boolean read FIsOverloaded;
  end;

  {*
    Marqueur overload
    @author sjrd
    @version 1.0
  *}
  TSepiOverloadMarkerNode = class(TSepiNonTerminal)
  end;

  {*
    Noeud repr�sentant un type
    @author sjrd
    @version 1.0
  *}
  TSepiTypeNode = class(TSepiNonTerminal)
  private
    FSepiType: TSepiType; /// Type repr�sent�
  protected
    procedure SetSepiType(ASepiType: TSepiType);

    procedure MakeErroneousType; virtual;
  public
    procedure EndParsing; override;

    property SepiType: TSepiType read FSepiType;
  end;

  {*
    Noeud repr�sentant une d�finition de type
    @author sjrd
    @version 1.0
  *}
  TSepiTypeDefinitionNode = class(TSepiTypeNode)
  private
    FTypeName: string; /// Nom du type � d�finir (peut �tre '')

    function GetIsAnonymous: Boolean;
  protected
    procedure MakeErroneousType; override;
  public
    procedure SetTypeName(const ATypeName: string);

    property IsAnonymous: Boolean read GetIsAnonymous;
    property TypeName: string read FTypeName;
  end;

  {*
    Noeud descripteur de contenu de record
    Le contexte Sepi d'un tel noeud doit toujours �tre de type TSepiRecordType.
    @author sjrd
    @version 1.0
  *}
  TSepiRecordContentsNode = class(TSepiNonTerminal)
  private
    FAfterField: string; /// Nom du champ apr�s lequel se placer
  protected
    procedure ChildBeginParsing(Child: TSepiParseTreeNode); override;
    procedure ChildEndParsing(Child: TSepiParseTreeNode); override;

    property AfterField: string read FAfterField;
  public
    procedure BeginParsing; override;

    procedure SetAfterField(const AAfterField: string);
  end;

  {*
    Noeud d'un champ de record
    Le contexte Sepi d'un tel noeud doit toujours �tre de type TSepiRecordType.
    @author sjrd
    @version 1.0
  *}
  TSepiRecordFieldNode = class(TSepiNonTerminal)
  private
    FAfterField: string;    /// Champ apr�s lequel se placer
    FLastField: TSepiField; /// Dernier champ compil�
  protected
    property AfterField: string read FAfterField;
  public
    procedure EndParsing; override;

    procedure SetAfterField(const AAfterField: string);

    property LastField: TSepiField read FLastField;
  end;

  {*
    Noeud du corps d'une m�thode
    @author sjrd
    @version 1.0
  *}
  TSepiMethodBodyNode = class(TSepiNonTerminal)
  private
    FSepiMethod: TSepiMethod;       /// M�thode Sepi impl�ment�e dans ce corps
    FCompiler: TSepiMethodCompiler; /// Compilateur de la m�thode
  protected
    procedure ChildBeginParsing(Child: TSepiParseTreeNode); override;

    function GetMethodCompiler: TSepiMethodCompiler; override;
    function GetSepiContext: TSepiMeta; override;
  public
    function ResolveIdent(const Identifier: string): ISepiExpression; override;

    procedure EndParsing; override;

    procedure SetSepiMethod(ASepiMethod: TSepiMethod);

    property SepiMethod: TSepiMethod read FSepiMethod;
  end;

  {*
    Classe de base pour les noeuds instruction
    @author sjrd
    @version 1.0
  *}
  TSepiInstructionNode = class(TSepiNonTerminal)
  private
    FInstructionList: TSepiInstructionList; /// Liste d'instructions contenante
  public
    property InstructionList: TSepiInstructionList
      read FInstructionList write FInstructionList;
  end;

  {*
    Noeud "pas d'instruction"
    @author sjrd
    @version 1.0
  *}
  TSepiNoInstructionNode = class(TSepiInstructionNode)
  end;

  {*
    Liste d'instructions
    @author sjrd
    @version 1.0
  *}
  TSepiInstructionListNode = class(TSepiInstructionNode)
  protected
    procedure ChildBeginParsing(Child: TSepiParseTreeNode); override;
  end;

  {*
    Bloc begin..end
    @author sjrd
    @version 1.0
  *}
  TSepiBeginEndBlockNode = class(TSepiInstructionListNode)
  end;

  {*
    Instruction if..then..else
    @author sjrd
    @version 1.0
  *}
  TSepiIfThenElseInstructionNode = class(TSepiInstructionNode)
  private
    FInstruction: TSepiIfThenElse; /// Instruction
  protected
    procedure ChildBeginParsing(Child: TSepiParseTreeNode); override;
    procedure ChildEndParsing(Child: TSepiParseTreeNode); override;
  public
    procedure BeginParsing; override;
    procedure EndParsing; override;

    property Instruction: TSepiIfThenElse read FInstruction;
  end;

  {*
    Instruction while..do ou similaire
    @author sjrd
    @version 1.0
  *}
  TSepiWhileInstructionNode = class(TSepiInstructionNode)
  private
    FTestAtEnd: Boolean;  /// True si le test est � la fin
    FInvertTest: Boolean; /// True si le test doit �tre invers� (not Test)

    FInstruction: TSepiWhile; /// Instruction
  protected
    procedure Configure(ATestAtEnd, AInvertTest: Boolean);

    procedure ChildBeginParsing(Child: TSepiParseTreeNode); override;
    procedure ChildEndParsing(Child: TSepiParseTreeNode); override;
  public
    procedure BeginParsing; override;
    procedure EndParsing; override;

    property TestAtEnd: Boolean read FTestAtEnd;
    property InvertTest: Boolean read FInvertTest;

    property Instruction: TSepiWhile read FInstruction;
  end;

  {*
    Instruction do..while
    @author sjrd
    @version 1.0
  *}
  TSepiDoWhileInstructionNode = class(TSepiWhileInstructionNode)
  public
    constructor Create(AParent: TSepiNonTerminal; AClass: TSepiSymbolClass;
      const ASourcePos: TSepiSourcePosition); override;
  end;

  {*
    Instruction repeat..until (comme do..while mais avec un test invers�)
    @author sjrd
    @version 1.0
  *}
  TSepiRepeatUntilInstructionNode = class(TSepiWhileInstructionNode)
  public
    constructor Create(AParent: TSepiNonTerminal; AClass: TSepiSymbolClass;
      const ASourcePos: TSepiSourcePosition); override;
  end;

  {*
    Instruction raise
    @author sjrd
    @version 1.0
  *}
  TSepiRaiseInstructionNode = class(TSepiInstructionNode)
  private
    procedure MakeRaiseInstruction;
    procedure MakeReraiseInstruction;
  public
    procedure EndParsing; override;
  end;

implementation

{------------------------}
{ TUsesSectionNode class }
{------------------------}

{*
  Teste si un nom d'unit� est red�clar�
*}
function TSepiUsesNode.IsRedeclared(const UnitName: string): Boolean;
var
  I: Integer;
begin
  // Same as the current unit name?
  if AnsiSameText(UnitName, SepiUnit.Name) then
  begin
    Result := True;
    Exit;
  end;

  // Already using this unit?
  for I := 0 to SepiUnit.UsedUnitCount-1 do
  begin
    if AnsiSameText(UnitName, SepiUnit.UsedUnits[I].Name) then
    begin
      Result := True;
      Exit;
    end;
  end;

  Result := False;
end;

{*
  [@inheritDoc]
*}
procedure TSepiUsesNode.ChildEndParsing(Child: TSepiParseTreeNode);
var
  UnitName: string;
begin
  UnitName := Child.AsText;

  if IsRedeclared(UnitName) then
    Child.MakeError(SRedeclaredIdentifier)
  else
    SepiUnit.MoreUses([UnitName]);

  inherited;
end;

{-------------------------------}
{ TSepiQualifiedIdentNode class }
{-------------------------------}

{*
  [@inheritDoc]
*}
function TSepiQualifiedIdentNode.GetAsText: string;
var
  I: Integer;
begin
  Result := Children[0].AsText;
  for I := 1 to ChildCount-1 do
    Result := Result + '.' + Children[I].AsText;
end;

{-----------------------------------------}
{ TSepiInitializationExpressionNode class }
{-----------------------------------------}

{*
  [@inheritDoc]
*}
destructor TSepiInitializationExpressionNode.Destroy;
begin
  if FOwnsValue then
    ValueType.DisposeValue(FValuePtr);

  inherited;
end;

{*
  [@inheritDoc]
*}
procedure TSepiInitializationExpressionNode.BeginParsing;
begin
  inherited;

  Assert(ValueType <> nil);
end;

{*
  Teste si un type est valide pour cet initialiseur
  @param AValueType   Type � tester
  @return True si le type est valide, False sinon
*}
function TSepiInitializationExpressionNode.IsValidType(
  AValueType: TSepiType): Boolean;
begin
  Result := AValueType <> nil;
end;

{*
  Indique le type de valeur attendu, et o� stocker le r�sultat
  Si AValuePtr vaut nil, une nouvelle valeur du type AValueType sera cr��e, et
  lib�r�e � la destruction de cet objet.
  Cette m�thode doit �tre appel�e exactement une fois, avant BeginParsing.
  @param AValueType   Type de valeur attendu (doit �tre valide)
  @param AValuePtr    Pointeur o� stocker le r�sultat (peut �tre nil)
*}
procedure TSepiInitializationExpressionNode.SetValueTypeAndPtr(
  AValueType: TSepiType; AValuePtr: Pointer = nil);
begin
  Assert((FValueType = nil) and IsValidType(AValueType));

  FValueType := AValueType;
  FOwnsValue := AValuePtr = nil;

  if FOwnsValue then
    FValuePtr := ValueType.NewValue
  else
    FValuePtr := AValuePtr;
end;

{---------------------------}
{ TSepiExpressionNode class }
{---------------------------}

{*
  Tente de forcer le type d'une valeur
  @param Value       Valeur dont forcer le type
  @param ValueType   Type requis
  @return True en cas de succ�s, False sinon
*}
function TSepiExpressionNode.TryAndForceType(var Value: ISepiValue;
  ValueType: TSepiType): Boolean;
var
  TypeForceableValue: ISepiTypeForceableValue;
begin
  Result := Supports(Value, ISepiTypeForceableValue, TypeForceableValue) and
    TypeForceableValue.CanForceType(ValueType);

  if Result then
    TypeForceableValue.ForceType(ValueType);
end;

{*
  Tente de convertir une valeur en un type donn�
  @param Value       Valeur � convertir
  @param ValueType   Type requis
  @return True en cas de succ�s, False sinon
*}
function TSepiExpressionNode.TryAndConvert(var Value: ISepiValue;
  ValueType: TSepiType): Boolean;
var
  ReadableValue: ISepiReadableValue;
begin
  Result := Supports(Value, ISepiReadableValue, ReadableValue) and
    TSepiConvertOperation.ConvertionExists(ValueType, Value.ValueType);

  if Result then
    Value := TSepiConvertOperation.ConvertValue(ValueType, ReadableValue);
end;

{*
  Tente de faire conrrespondre le type d'une valeur � un type donn�
  @param Value             Valeur � convertir
  @param ValueType         Type requis
  @param AllowConvertion   Autoriser des conversion pour obtenir le type requis
  @return True en cas de succ�s, False sinon
*}
function TSepiExpressionNode.TryAndMatchType(var Value: ISepiValue;
  ValueType: TSepiType; AllowConvertion: Boolean): Boolean;
begin
  Result := (Value.ValueType = ValueType) or
    ((Value.ValueType <> nil) and ValueType.Equals(Value.ValueType)) or
    TryAndForceType(Value, ValueType);

  Value.Finalize;

  if (not Result) and AllowConvertion then
    Result := TryAndConvert(Value, ValueType);
end;

{*
  Exige qu'une variable ait un type donn�
  @param Value             Valeur � convertir
  @param ValueType         Type requis
  @param AllowConvertion   Autoriser des conversion pour obtenir le type requis
*}
procedure TSepiExpressionNode.RequireType(var Value: ISepiValue;
  ValueType: TSepiType; AllowConvertion: Boolean);
begin
  if not TryAndMatchType(Value, ValueType, AllowConvertion) then
    MakeError(Format(STypeMismatch, [ValueType.Name, Value.ValueType.Name]));
end;

{*
  Modifie l'expression
  @param AExpression   Nouvelle expression
*}
procedure TSepiExpressionNode.SetExpression(const AExpression: ISepiExpression);
begin
  FExpression := AExpression;
end;

{*
  Modifie l'expression comme nouvelle expression partielle
  @param ExpressionPart   Nouvelle expression partielle
*}
procedure TSepiExpressionNode.SetExpressionPart(
  const ExpressionPart: ISepiExpressionPart);
begin
  SetExpression(MakeExpression);
  ExpressionPart.AttachToExpression(Expression);
end;

{*
  Construit une valeur erron�e
  @param ValueType   Type de valeur erron�e (peut �tre nil)
  @return Valeur construite
*}
function TSepiExpressionNode.MakeErroneousValue(
  ValueType: TSepiType = nil): ISepiReadableValue;
begin
  if ValueType = nil then
    Result := TSepiErroneousValue.Create(SepiRoot)
  else
    Result := TSepiErroneousValue.Create(ValueType);
end;

{*
  V�rifie la validit� de l'expression compil�e
  ValidateExpression n'est appel�e que si Expression <> nil.
  @return True si l'expression est valide, False sinon
*}
function TSepiExpressionNode.ValidateExpression: Boolean;
begin
  Result := True;
end;

{*
  Construit une expression erron�e
*}
procedure TSepiExpressionNode.MakeErroneousExpression;
begin
  SetExpressionPart(MakeErroneousValue);
end;

{*
  [@inheritDoc]
*}
procedure TSepiExpressionNode.EndParsing;
begin
  if (Expression = nil) or (not ValidateExpression) then
  begin
    MakeErroneousExpression;
    Assert(Expression <> nil);
  end;

  if (Expression.SourcePos.Line = 0) and (Expression.SourcePos.Col = 0) then
    Expression.SourcePos := SourcePos;

  inherited;
end;

{*
  Lit l'expression comme un type donn� de partie d'expression
  Si l'expression n'est du type requis, et si ErrorMsg est non vide, un message
  d'erreur est �mis, et AsExpressionPart renvoie False.
  @param IID        Type de partie d'expression requis
  @param Intf       En sortie : partie d'expression demand�e, si succ�s
  @param ErrorMsg   Message d'erreur en cas d'�chec
  @return True en cas de succ�s, False sinon
*}
function TSepiExpressionNode.AsExpressionPart(const IID: TGUID; out Intf;
  const ErrorMsg: string = ''): Boolean;
begin
  Result := Supports(Expression, IID, Intf);

  if (not Result) and (ErrorMsg <> '') then
    MakeError(ErrorMsg);
end;

{*
  Lit l'expression en tant que valeur
  @param ValueType         Type de valeur attendu (nil = tout type)
  @param AllowConvertion   Autoriser des conversion pour obtenir le type requis
  @return Valeur repr�sent�e par l'expression (ou nil en cas d'erreur)
*}
function TSepiExpressionNode.AsValue(ValueType: TSepiType = nil;
  AllowConvertion: Boolean = True): ISepiValue;
begin
  if not AsExpressionPart(ISepiValue, Result, SValueRequired) then
    Exit;

  if ValueType <> nil then
    RequireType(Result, ValueType, AllowConvertion);
end;

{*
  Lit l'expression en tant que valeur qui peut �tre lue
  @param ValueType         Type de valeur attendu (nil = tout type)
  @param AllowConvertion   Autoriser des conversion pour obtenir le type requis
  @return Valeur repr�sent�e par l'expression (ou nil en cas d'erreur)
*}
function TSepiExpressionNode.AsReadableValue(ValueType: TSepiType = nil;
  AllowConvertion: Boolean = True): ISepiReadableValue;
var
  Value: ISepiValue;
begin
  Value := AsValue(ValueType, AllowConvertion);

  if not Supports(Value, ISepiReadableValue, Result) then
    MakeError(SReadableValueRequired);
end;

{*
  Lit l'expression en tant que meta
  @return Meta repr�sent� par l'expression (ou nil en cas d'erreur)
*}
function TSepiExpressionNode.AsMeta: TSepiMeta;
var
  MetaExpression: ISepiMetaExpression;
begin
  if AsExpressionPart(ISepiMetaExpression, MetaExpression, SMetaRequired) then
    Result := MetaExpression.Meta
  else
    Result := nil;
end;

{*
  Lit l'expression en tant que type
  @return Type repr�sent� par l'expression (ou System.Integer en cas d'erreur)
*}
function TSepiExpressionNode.AsType: TSepiType;
var
  TypeExpression: ISepiTypeExpression;
begin
  if AsExpressionPart(ISepiTypeExpression, TypeExpression,
    STypeIdentifierRequired) then
    Result := TypeExpression.ExprType
  else
    Result := SystemUnit.Integer;
end;

{--------------------------------------}
{ TSepiSameAsChildExpressionNode class }
{--------------------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiSameAsChildExpressionNode.EndParsing;
begin
  Assert(ChildCount = 1);
  
  SetExpression((Children[0] as TSepiExpressionNode).Expression);

  inherited;
end;

{----------------------}
{ TSepiValueNode class }
{----------------------}

{*
  [@inheritDoc]
*}
function TSepiValueNode.ValidateExpression: Boolean;
begin
  Result := Supports(Expression, ISepiValue);
end;

{-----------------------------}
{ TSepiBinaryOpTreeNode class }
{-----------------------------}

{*
  Trouve l'op�rateur majeur d'un sous-arbre
  L'op�rateur majeur est celui de plus basse priorit� dans le sous-arbre. En cas
  d'�galit�, c'est celui de droite pour une �valuation left-to-right ; et c'est
  celui de gauche pour une �valuation right-to-left.
  @param Lower    Index bas des symboles du sous-arbre
  @param Higher   Index haut des symboles du sous-arbre
  @return Index de l'op�rateur majeur parmi les enfants de ce noeud
*}
function TSepiBinaryOpTreeNode.FindSubTreeOpIndex(
  Lower, Higher: Integer): Integer;
var
  OpIndex: Integer;
  MinPriority: Integer;
  OpChild: TSepiBinaryOpNode;
begin
  Result := -1;
  MinPriority := MaxInt;

  OpIndex := Lower+1;
  while OpIndex < Higher do
  begin
    OpChild := Children[OpIndex] as TSepiBinaryOpNode;

    if OpChild.Priority <= MinPriority then
    begin
      Result := OpIndex;
      MinPriority := OpChild.Priority;

      // In right-to-left, priority must strictly decrease to be taken into
      // account.
      if OpChild.Direction = bodRightToLeft then
        Dec(MinPriority);
    end;

    Inc(OpIndex, 2);
  end;

  Assert(Result > 0);
end;

{*
  Compile un sous-arbre de l'expression
  @param Lower    Index bas des symboles du sous-arbre
  @param Higher   Index haut des symboles du sous-arbre
  @return Expression repr�sentant le sous-arbre
*}
function TSepiBinaryOpTreeNode.CompileSubTree(
  Lower, Higher: Integer): ISepiExpression;
var
  OpIndex: Integer;
  LeftExpression, RightExpression: ISepiExpression;
begin
  if Lower = Higher then
    Result := (Children[Lower] as TSepiExpressionNode).Expression
  else
  begin
    OpIndex := FindSubTreeOpIndex(Lower, Higher);

    LeftExpression := CompileSubTree(Lower, OpIndex-1);
    RightExpression := CompileSubTree(OpIndex+1, Higher);

    Result := TSepiBinaryOpNode(Children[OpIndex]).MakeOperation(
      LeftExpression, RightExpression);
  end;
end;

{*
  Compile l'arbre de l'expression
  @return Expression repr�sentant l'arbre
*}
function TSepiBinaryOpTreeNode.CompileTree: ISepiExpression;
begin
  Assert(ChildCount mod 2 <> 0);

  Result := CompileSubTree(0, ChildCount-1);
end;

{*
  [@inheritDoc]
*}
procedure TSepiBinaryOpTreeNode.EndParsing;
begin
  if Expression = nil then
    SetExpression(CompileTree);

  inherited;
end;

{-------------------------}
{ TSepiBinaryOpNode class }
{-------------------------}

{*
  Priorit� de cet op�rateur
  @return Priorit� de cet op�rateur
*}
function TSepiBinaryOpNode.GetPriority: Integer;
begin
  Result := 1;
end;

{*
  Direction d'�valuation de cet op�rateur
  Afin que l'�valuation d'expressions soit coh�rente, tous les op�rateurs
  poss�dant la m�me priorit� doivent �galement �tre �valu�s dans la m�me
  direction.
  @return Direction d'�valuation de cet op�rateur
*}
function TSepiBinaryOpNode.GetDirection: TSepiBinaryOpDirection;
begin
  Result := bodLeftToRight;
end;

{-------------------------------}
{ TSepiUnaryOperationNode class }
{-------------------------------}

{*
  Compile l'arbre de l'expression
  @return Expression repr�sentant l'arbre
*}
function TSepiUnaryOperationNode.CompileOperation(
  OperatorNode: TSepiUnaryOpNode;
  OperandNode: TSepiExpressionNode): ISepiExpression;
begin
  Result := OperatorNode.MakeOperation(OperandNode.Expression);
end;

{*
  [@inheritDoc]
*}
procedure TSepiUnaryOperationNode.EndParsing;
begin
  if Expression = nil then
  begin
    Assert(ChildCount = 2);

    if (Children[0] is TSepiUnaryOpNode) and
      (Children[1] is TSepiExpressionNode) then
    begin
      SetExpression(CompileOperation(TSepiUnaryOpNode(Children[0]),
        TSepiExpressionNode(Children[1])));
    end else if (Children[0] is TSepiExpressionNode) and
      (Children[1] is TSepiUnaryOpNode) then
    begin
      SetExpression(CompileOperation(TSepiUnaryOpNode(Children[1]),
        TSepiExpressionNode(Children[0])));
    end else
    begin
      Assert(False);
    end;
  end;

  inherited;
end;

{-----------------------------}
{ TSepiLiteralConstNode class }
{-----------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiLiteralConstNode.EndParsing;
var
  Value: ISepiValue;
begin
  Value := CompileAsValue;

  if Value <> nil then
  begin
    SetExpression(MakeExpression);
    Value.AttachToExpression(Expression);
  end;

  inherited;
end;

{-----------------------------}
{ TSepiConstIntegerNode class }
{-----------------------------}

{*
  Compile la valeur sous forme d'entier
  En cas d'erreur, peut renvoyer une valeur arbitraire, 0 le plus souvent.
  @return Valeur repr�sent�e par le litt�ral
*}
function TSepiConstIntegerNode.CompileAsInteger: Int64;
begin
  if not TryStrToInt64(AsText, Result) then
  begin
    MakeError(Format(SInvalidInteger, [AsText]));
    Result := 0;
  end;
end;

{*
  [@inheritDoc]
*}
function TSepiConstIntegerNode.CompileAsValue: ISepiValue;
begin
  Result := TSepiTrueConstValue.Create(SepiRoot, CompileAsInteger);
end;

{---------------------------}
{ TSepiConstFloatNode class }
{---------------------------}

{*
  Compile la valeur sous forme de nombre � virgule flottante
  En cas d'erreur, peut renvoyer une valeur arbitraire, 0 le plus souvent.
  @return Valeur repr�sent�e par le litt�ral
*}
function TSepiConstFloatNode.CompileAsExtended: Extended;
var
  FormatSettings: TFormatSettings;
begin
  FormatSettings.ThousandSeparator := #0;
  FormatSettings.DecimalSeparator := '.';

  if not TryStrToFloat(AsText, Result, FormatSettings) then
  begin
    MakeError(Format(SInvalidFloat, [AsText]));
    Result := 0.0;
  end;
end;

{*
  [@inheritDoc]
*}
function TSepiConstFloatNode.CompileAsValue: ISepiValue;
begin
  Result := TSepiTrueConstValue.Create(SepiRoot, CompileAsExtended);
end;

{----------------------------}
{ TSepiConstStringNode class }
{----------------------------}

{*
  Compile la valeur sous forme de cha�ne de caract�res
  En cas d'erreur, peut renvoyer une valeur arbitraire, '' le plus souvent.
  @return Valeur repr�sent�e par le litt�ral
*}
function TSepiConstStringNode.CompileAsString: string;
begin
  Result := StrRepresToStr(AsText);
end;

{*
  [@inheritDoc]
*}
function TSepiConstStringNode.CompileAsValue: ISepiValue;
var
  StrValue: string;
begin
  StrValue := CompileAsString;

  if Length(StrValue) = 1 then
    Result := TSepiTrueConstValue.Create(SepiRoot, StrValue[1])
  else
    Result := TSepiTrueConstValue.Create(SepiRoot, StrValue);
end;

{-------------------------------------}
{ TSepiIdentifierExpressionNode class }
{-------------------------------------}

{*
  Compile l'identificateur dans Expression
*}
procedure TSepiIdentifierExpressionNode.CompileIdentifier;
begin
  SetExpression(ResolveIdent(AsText));

  CheckIdentFound(Expression, AsText, Self);
end;

{*
  [@inheritDoc]
*}
procedure TSepiIdentifierExpressionNode.EndParsing;
begin
  CompileIdentifier;

  inherited;
end;

{-------------------------}
{ TSepiNilValueNode class }
{-------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiNilValueNode.EndParsing;
begin
  SetExpression(MakeExpression);

  ISepiExpressionPart(TSepiNilValue.Create(SepiRoot)).AttachToExpression(
    Expression);

  inherited;
end;

{------------------------------------}
{ TSepiInheritedExpressionNode class }
{------------------------------------}

{*
  V�rifie qu'on est bien en train de compiler une m�thode
  @return True en cas de succ�s, False sinon
*}
function TSepiInheritedExpressionNode.RequireClassOrObjectMethod: Boolean;
begin
  Result := (MethodCompiler <> nil) and
    (MethodCompiler.SepiMethod.Owner is TSepiClass);

  if not Result then
    MakeError(SInheritNeedClassOrObjectMethod);
end;

{*
  Nom de la m�thode h�rit�e � appeler
  @return Nom de la m�thode h�rit�e � appeler
*}
function TSepiInheritedExpressionNode.GetMethodName: string;
begin
  Result := AsText;
end;

{*
  Trouve la m�thode h�rit�e � appeler
  @return M�thode � appeler (TSepiMethod et TSepiOverloadedMethod sont valides)
*}
function TSepiInheritedExpressionNode.FindMethod: TSepiMeta;
var
  CurrentClass, ParentClass: TSepiClass;
begin
  CurrentClass := MethodCompiler.SepiMethod.Owner as TSepiClass;
  ParentClass := CurrentClass.Parent;

  Result := ParentClass.LookForMember(GetMethodName,
    CurrentClass.OwningUnit, CurrentClass);

  CheckIdentFound(Result, GetMethodName, Self);
end;

{*
  Construit un callable
  @param SepiMethod   M�thode � appeler
  @param SelfVar      Variable locale Self
*}
function TSepiInheritedExpressionNode.MakeCallable(SepiMethod: TSepiMeta;
  const SelfParam: ISepiReadableValue): ISepiCallable;
const
  ForceStaticCall = True;
  FreeParamIsAlwaysFalse = False;
begin
  if SepiMethod is TSepiMethod then
  begin
    Result := TSepiMethodCall.Create(TSepiMethod(SepiMethod),
      SelfParam, ForceStaticCall, FreeParamIsAlwaysFalse);
  end else if SepiMethod is TSepiOverloadedMethod then
  begin
    Result := TSepiMethodCall.Create(TSepiOverloadedMethod(SepiMethod),
      SelfParam, ForceStaticCall, FreeParamIsAlwaysFalse);
  end else
  begin
    MakeError(SMethodRequired);
  end;
end;

{*
  Compile l'appel inherited comme un callable
  @return Callable repr�sent� par l'appel inherited (ou nil en cas d'erreur)
*}
function TSepiInheritedExpressionNode.CompileCallable: ISepiCallable;
var
  SepiMethod: TSepiMeta;
  SelfParam: ISepiValue;
begin
  if not RequireClassOrObjectMethod then
    Exit;

  SepiMethod := FindMethod;

  if SepiMethod <> nil then
  begin
    SelfParam := TSepiLocalVarValue.MakeValue(MethodCompiler,
      MethodCompiler.Locals.SelfVar);

    Result := MakeCallable(SepiMethod, SelfParam as ISepiReadableValue);
  end;
end;

{*
  [@inheritDoc]
*}
procedure TSepiInheritedExpressionNode.EndParsing;
var
  Callable: ISepiCallable;
begin
  Callable := CompileCallable;

  if Callable <> nil then
  begin
    SetExpression(MakeExpression);
    Callable.AttachToExpression(Expression);
  end;

  inherited;
end;

{----------------------------------------}
{ TSepiExpressionWithModifiersNode class }
{----------------------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiExpressionWithModifiersNode.ChildBeginParsing(
  Child: TSepiParseTreeNode);
begin
  inherited;

  if Child is TSepiExpressionModifierNode then
    TSepiExpressionModifierNode(Child).SetBase(Expression);
end;

{*
  [@inheritDoc]
*}
procedure TSepiExpressionWithModifiersNode.ChildEndParsing(
  Child: TSepiParseTreeNode);
begin
  SetExpression((Child as TSepiExpressionNode).Expression);

  inherited;
end;

{*
  [@inheritDoc]
*}
procedure TSepiExpressionWithModifiersNode.EndParsing;
begin
  Assert(ChildCount > 0);

  inherited;
end;

{-----------------------------------}
{ TSepiExpressionModifierNode class }
{-----------------------------------}

{*
  Sp�cifie l'expression de base � modifier
  @param ABase   Expression de base � modifier
*}
procedure TSepiExpressionModifierNode.SetBase(const ABase: ISepiExpression);
begin
  FBase := ABase;
end;

{-------------------------------------}
{ TSepiArrayIndicesModifierNode class }
{-------------------------------------}

{*
  Compile les indices d'une propri�t� de type tableau
  @param Prop   Propri�t�
*}
procedure TSepiArrayIndicesModifierNode.CompileProperty(
  const Prop: ISepiProperty);
var
  Count, I: Integer;
  Value: ISepiValue;
begin
  if ChildCount < Prop.ParamCount then
    Count := ChildCount
  else
    Count := Prop.ParamCount;

  for I := 0 to Count-1 do
  begin
    if Supports((Children[I] as TSepiExpressionNode).Expression,
      ISepiValue, Value) then
      Prop.Params[I] := Value
    else
      Children[I].MakeError(SValueRequired);
  end;

  if ChildCount < Prop.ParamCount then
    MakeError(SNotEnoughActualParameters)
  else if ChildCount > Prop.ParamCount then
    MakeError(STooManyActualParameters);

  SetExpression(Base);
end;

{*
  Compile l'acc�s � un �l�ment de tableau
  @param BaseValue   Valeur tableau de base
*}
procedure TSepiArrayIndicesModifierNode.CompileArrayItem(
  const BaseValue: ISepiValue);
var
  CurrentValue: ISepiValue;
  IndexValue: ISepiReadableValue;
  I: Integer;
  Child: TSepiExpressionNode;
  BaseType: TSepiType;
begin
  CurrentValue := BaseValue;

  for I := 0 to ChildCount-1 do
  begin
    Child := Children[0] as TSepiExpressionNode;
    BaseType := CurrentValue.ValueType;

    if not (BaseType is TSepiArrayType) then
    begin
      Child.MakeError(STooManyArrayIndices);
      Break;
    end else
    begin
      if Supports(Child.Expression, ISepiReadableValue, IndexValue) then
      begin
        CurrentValue := TSepiArrayItemValue.MakeArrayItemValue(
          CurrentValue, IndexValue);
      end else
      begin
        Child.Expression.MakeError(SReadableValueRequired);
        Break;
      end;
    end;
  end;

  SetExpression(CurrentValue as ISepiExpression);
end;

{*
  Compile les indices de la propri�t� par d�faut d'un objet
  @param ObjectValue   Valeur objet
*}
procedure TSepiArrayIndicesModifierNode.CompileDefaultProperty(
  const ObjectValue: ISepiReadableValue);
var
  Prop: TSepiProperty;
begin
  Prop := TSepiClass(ObjectValue.ValueType).DefaultProperty;

  SetBase(TSepiExpression.Create(Base));

  ISepiExpressionPart(TSepiPropertyValue.Create(ObjectValue,
    Prop)).AttachToExpression(Base);

  CompileProperty(Base as ISepiProperty);
end;

{*
  [@inheritDoc]
*}
procedure TSepiArrayIndicesModifierNode.EndParsing;
var
  Prop: ISepiProperty;
  BaseValue: ISepiValue;
  ObjectValue: ISepiReadableValue;
begin
  if Expression = nil then
  begin
    if Supports(Base, ISepiProperty, Prop) and (not Prop.ParamsCompleted) then
    begin
      // Array property
      CompileProperty(Prop);
    end else if Supports(Base, ISepiValue, BaseValue) and
      (BaseValue.ValueType is TSepiArrayType) then
    begin
      // True array indices
      CompileArrayItem(BaseValue);
    end else if Supports(Base, ISepiReadableValue, ObjectValue) and
      (ObjectValue.ValueType is TSepiClass) and
      (TSepiClass(ObjectValue.ValueType).DefaultProperty <> nil) then
    begin
      // Default array property
      CompileDefaultProperty(ObjectValue);
    end else
    begin
      // Error
      Base.MakeError(SArrayOrArrayPropRequired);
    end;
  end;

  inherited;
end;

{---------------------------------------}
{ TSepiFieldSelectionModifierNode class }
{---------------------------------------}

function TSepiFieldSelectionModifierNode.MakeFieldSelection: ISepiExpression;
begin
  Result := FieldSelection(SepiContext, Base, Children[0].AsText);
end;

{*
  [@inheritDoc]
*}
procedure TSepiFieldSelectionModifierNode.EndParsing;
begin
  if Expression = nil then
  begin
    SetExpression(MakeFieldSelection);
    CheckIdentFound(Expression, Children[0].AsText, Children[0]);
  end;

  inherited;
end;

{------------------------------------}
{ TSepiDereferenceModifierNode class }
{------------------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiDereferenceModifierNode.EndParsing;
var
  Value: ISepiReadableValue;
begin
  if Supports(Base, ISepiReadableValue, Value) and
    (Value.ValueType is TSepiPointerType) then
  begin
    SetExpression(TSepiDereferenceValue.MakeDereference(
      Value) as ISepiExpression);
  end else
  begin
    MakeError(SPointerTypeRequired);
  end;

  inherited;
end;

{--------------------------------------}
{ TSepiIdentifierDeclarationNode class }
{--------------------------------------}

{*
  Teste si cet identificateur est red�clar� dans sa liste courante
  @return True s'il est red�clar�, False sinon
*}
function TSepiIdentifierDeclarationNode.IsRedeclaredInCurrentList: Boolean;
begin
  Result := (Parent is TSepiIdentifierDeclListNode) and
    TSepiIdentifierDeclListNode(Parent).IsDeclared(Identifier);
end;

{*
  Identificateur repr�sent� par ce noeud
  @return Identificateur repr�sent� par ce noeud
*}
function TSepiIdentifierDeclarationNode.GetIdentifier: string;
begin
  if FIdentifier = '' then
    Result := AsText
  else
    Result := FIdentifier;
end;

{*
  Modifie l'identificateur repr�sent� par ce noeud
  @param AIdentifier   Nouvel identificateur
*}
procedure TSepiIdentifierDeclarationNode.SetIdentifier(
  const AIdentifier: string);
begin
  FIdentifier := AIdentifier;
end;

{*
  Teste si cet identificateur est red�clar�
  @return True s'il est red�clar�, False sinon
*}
function TSepiIdentifierDeclarationNode.IsRedeclared: Boolean;
var
  FirstDecl: TSepiMeta;
begin
  FirstDecl := SepiContext.GetMeta(Identifier);
  Result := (FirstDecl <> nil) and (not FirstDecl.IsForward);
end;

{*
  Construit un identificateur erron�
*}
procedure TSepiIdentifierDeclarationNode.MakeErroneousName;
begin
  SetIdentifier(SepiContext.MakeUnnamedChildName);
end;

{*
  [@inheritDoc]
*}
procedure TSepiIdentifierDeclarationNode.EndParsing;
begin
  if IsRedeclared or IsRedeclaredInCurrentList then
  begin
    MakeError(SRedeclaredIdentifier);
    MakeErroneousName;
  end;

  inherited;
end;

{----------------------------------------}
{ TSepiUncheckedIdentifierDeclNode class }
{----------------------------------------}

{*
  [@inheritDoc]
*}
function TSepiUncheckedIdentifierDeclNode.IsRedeclared: Boolean;
begin
  Result := False;
end;

{-----------------------------------}
{ TSepiIdentifierDeclListNode class }
{-----------------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiIdentifierDeclListNode.ChildBeginParsing(
  Child: TSepiParseTreeNode);
begin
  inherited;

  Assert(Child is TSepiIdentifierDeclarationNode);
end;

{*
  [@inheritDoc]
*}
procedure TSepiIdentifierDeclListNode.ChildEndParsing(
  Child: TSepiParseTreeNode);
begin
  Inc(FIdentifierCount);

  inherited;
end;

{*
  Tableau zero-based des identificateurs
  @param Index   Index d'un identificateur
  @return L'identificateur � l'index donn�
*}
function TSepiIdentifierDeclListNode.GetIdentifiers(Index: Integer): string;
begin
  Result := TSepiIdentifierDeclarationNode(Children[Index]).Identifier;
end;

{*
  Teste si un identificateur donn� est d�clar� dans cette liste
  @param Identifier   Identificateur � tester
  @return True si l'identificateur est d�clar�, False sinon
*}
function TSepiIdentifierDeclListNode.IsDeclared(
  const Identifier: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to IdentifierCount-1 do
  begin
    if AnsiSameText(Identifier, Identifiers[I]) then
    begin
      Result := True;
      Exit;
    end;
  end;

  Result := False;
end;

{---------------------------------}
{ TSepiSignatureBuilderNode class }
{---------------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiSignatureBuilderNode.ChildBeginParsing(
  Child: TSepiParseTreeNode);
begin
  inherited;

  if Child is TSepiSignatureBuilderNode then
    TSepiSignatureBuilderNode(Child).SetSignature(Signature);
end;

{*
  Renseigne la signature � construire
  @param ASignature   Signature � construire
*}
procedure TSepiSignatureBuilderNode.SetSignature(ASignature: TSepiSignature);
begin
  FSignature := ASignature;
end;

{------------------------------}
{ TSepiSignatureKindNode class }
{------------------------------}

{*
  Type de signature repr�sent�e par ce noeud
  @return Type de signature repr�sent�e par ce noeud
*}
function TSepiSignatureKindNode.GetKind: TSepiSignatureKind;
var
  OrdKind: Integer;
begin
  OrdKind := AnsiIndexText(AsText, SignatureKindStrings);

  if OrdKind < 0 then
    Result := skStaticProcedure
  else
    Result := TSepiSignatureKind(OrdKind);
end;

{*
  [@inheritDoc]
*}
procedure TSepiSignatureKindNode.EndParsing;
begin
  if Signature <> nil then
    Signature.Kind := Kind;

  inherited;
end;

{----------------------------------}
{ TSepiCallingConventionNode class }
{----------------------------------}

{*
  Type de signature repr�sent�e par ce noeud
  @return Type de signature repr�sent�e par ce noeud
*}
function TSepiCallingConventionNode.GetCallingConvention: TCallingConvention;
var
  OrdCallingConvention: Integer;
begin
  OrdCallingConvention := AnsiIndexText(AsText, CallingConventionStrings);

  if OrdCallingConvention < 0 then
    Result := ccRegister
  else
    Result := TCallingConvention(OrdCallingConvention);
end;

{*
  [@inheritDoc]
*}
procedure TSepiCallingConventionNode.EndParsing;
begin
  if Signature <> nil then
    Signature.CallingConvention := CallingConvention;

  inherited;
end;

{------------------------------}
{ TSepiSignatureReturnTypeNode }
{------------------------------}

{*
  Adapte le type de signature en proc�dure (sans valeur de retour)
*}
procedure TSepiSignatureReturnTypeNode.AdaptSignatureKindToProcedure;
begin
  case Signature.Kind of
    skStaticFunction:
      Signature.Kind := skStaticProcedure;
    skObjectFunction:
      Signature.Kind := skObjectProcedure;
    skClassFunction:
      Signature.Kind := skClassProcedure;
  end;
end;

{*
  Adapte le type de signature en fonction (avec valeur de retour)
*}
procedure TSepiSignatureReturnTypeNode.AdaptSignatureKindToFunction;
begin
  case Signature.Kind of
    skStaticProcedure:
      Signature.Kind := skStaticFunction;
    skObjectProcedure:
      Signature.Kind := skObjectFunction;
    skClassProcedure:
      Signature.Kind := skClassFunction;
  end;
end;

{*
  Adapte le type de signature si n�cessaire
*}
procedure TSepiSignatureReturnTypeNode.AdaptSignatureKindIfNeeded;
begin
  if MustAdaptSignatureKind then
  begin
    if TypeName = '' then
      AdaptSignatureKindToProcedure
    else
      AdaptSignatureKindToFunction;
  end;
end;

{*
  Si True, adapte Signature.Kind en fonction la pr�sence d'un type de retour
  Si False, la pr�sence d'un type de retour doit se conformer � la valeur
  courante de Signature.Kind.
  Par d�faut, AdaptSignatureKind renvoie False, ce qui correspond au
  comportement du langage Delphi.
  @return True s'il faut adapter Signature.Kind, False sinon.
*}
function TSepiSignatureReturnTypeNode.MustAdaptSignatureKind: Boolean;
begin
  Result := False;
end;

{*
  Nom du type de retour
  Le nom du type de retour est toujours la valeur de AsText. Si vous voulez
  modifier ce comportement dans une classe de base, surchargez AsText.
  @return Nom du type de retour, ou '' si absent
*}
function TSepiSignatureReturnTypeNode.GetTypeName: string;
begin
  Result := AsText;
end;

{*
  Compile le fait qu'il n'y a pas de type de retour
  S'il y a un type de retour, �met une erreur.
*}
procedure TSepiSignatureReturnTypeNode.CompileNoReturnType;
begin
  if TypeName <> '' then
    MakeError(SReturnTypeForbidden);

  Signature.ReturnType := nil;
end;

{*
  Compile le type de retour qui doit �tre pr�sent
  Si le type de retour est absent ou invalide, �met une erreur.
  @return Type de retour
*}
function TSepiSignatureReturnTypeNode.CompileReturnType: TSepiType;
begin
  if TypeName = '' then
  begin
    MakeError(SReturnTypeRequired);
    Result := SystemUnit.Integer;
  end else
  begin
    Result := TSepiType(LookForSelfTextOrError(
      TSepiType, STypeIdentifierRequired));

    if Result = nil then
      Result := SystemUnit.Integer;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TSepiSignatureReturnTypeNode.EndParsing;
begin
  AdaptSignatureKindIfNeeded;

  if Signature.Kind in skWithReturnType then
    Signature.ReturnType := CompileReturnType
  else
    CompileNoReturnType;

  inherited;
end;

{----------------------------------}
{ TSepiMethodDeclarationNode class }
{----------------------------------}

{*
  [@inheritDoc]
*}
destructor TSepiMethodDeclarationNode.Destroy;
begin
  FSignature.Free;

  inherited;
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodDeclarationNode.BeginParsing;
begin
  inherited;

  FSignature := TSepiSignature.CreateConstructing(SepiUnit);
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodDeclarationNode.ChildBeginParsing(
  Child: TSepiParseTreeNode);
begin
  inherited;

  if Child is TSepiSignatureBuilderNode then
    TSepiSignatureBuilderNode(Child).SetSignature(Signature);
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodDeclarationNode.ChildEndParsing(Child: TSepiParseTreeNode);
begin
  if Child is TSepiIdentifierDeclarationNode then
    FName := TSepiIdentifierDeclarationNode(Child).Identifier
  else if Child is TSepiOverloadMarkerNode then
    FIsOverloaded := True;

  inherited;
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodDeclarationNode.EndParsing;
begin
  Signature.Complete;

  if IsOverloaded then
    TSepiMethod.CreateOverloaded(SepiContext, Name, nil, Signature)
  else
    TSepiMethod.Create(SepiContext, Name, nil, Signature);

  inherited;
end;

{---------------------}
{ TSepiTypeNode class }
{---------------------}

{*
  Renseigne le type repr�sent�
  @param ASepiType   Type repr�sent�
*}
procedure TSepiTypeNode.SetSepiType(ASepiType: TSepiType);
begin
  FSepiType := ASepiType;
end;

{*
  Construit un type erron�
*}
procedure TSepiTypeNode.MakeErroneousType;
begin
  SetSepiType(UnitCompiler.GetErroneousType);
end;

{*
  [@inheritDoc]
*}
procedure TSepiTypeNode.EndParsing;
begin
  if SepiType = nil then
    MakeErroneousType;

  inherited;
end;

{-------------------------------}
{ TSepiTypeDefinitionNode class }
{-------------------------------}

{*
  Indique si le type � d�finir est anonyme
  @return True si le type est anonyme, False sinon
*}
function TSepiTypeDefinitionNode.GetIsAnonymous: Boolean;
begin
  Result := TypeName = '';
end;

{*
  [@inheritDoc]
*}
procedure TSepiTypeDefinitionNode.MakeErroneousType;
begin
  SetSepiType(UnitCompiler.MakeErroneousTypeAlias(TypeName));
end;

{*
  Sp�cifie le nom type � d�finir
  @param ATypeName   Nom du type � d�finir
*}
procedure TSepiTypeDefinitionNode.SetTypeName(const ATypeName: string);
begin
  FTypeName := ATypeName;
end;

{-------------------------------}
{ TSepiRecordContentsNode class }
{-------------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiRecordContentsNode.BeginParsing;
begin
  inherited;

  Assert(SepiContext is TSepiRecordType);
end;

{*
  [@inheritDoc]
*}
procedure TSepiRecordContentsNode.ChildBeginParsing(Child: TSepiParseTreeNode);
begin
  inherited;

  if Child is TSepiRecordFieldNode then
  begin
    if ChildCount = 1 then
      TSepiRecordFieldNode(Child).SetAfterField(AfterField)
    else
      TSepiRecordFieldNode(Child).SetAfterField('~');
  end else if Child is TSepiRecordContentsNode then
  begin
    TSepiRecordContentsNode(Child).SetAfterField(AfterField);
  end;
end;

{*
  [@inheritDoc]
*}
procedure TSepiRecordContentsNode.ChildEndParsing(Child: TSepiParseTreeNode);
begin
  if Child is TSepiRecordFieldNode then
  begin
    if TSepiRecordFieldNode(Child).LastField <> nil then
      FAfterField := TSepiRecordFieldNode(Child).LastField.Name;
  end;

  inherited;
end;

{*
  Sp�cifie le nom du champ apr�s lequel placer les champs enfants de ce noeud
  @param AAfterField   Nom du champ
*}
procedure TSepiRecordContentsNode.SetAfterField(const AAfterField: string);
begin
  FAfterField := AAfterField;
end;

{----------------------------}
{ TSepiRecordFieldNode class }
{----------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiRecordFieldNode.EndParsing;
var
  RecordType: TSepiRecordType;
  IdentList: TSepiIdentifierDeclListNode;
  FieldType: TSepitype;
  I: Integer;
begin
  RecordType := SepiContext as TSepiRecordType;
  IdentList := Children[0] as TSepiIdentifierDeclListNode;
  FieldType := (Children[1] as TSepiTypeNode).SepiType;

  if FieldType <> nil then
  begin
    if AfterField = '~' then
      FLastField := RecordType.AddField(
        IdentList.Identifiers[0], FieldType)
    else
      FLastField := RecordType.AddFieldAfter(
        IdentList.Identifiers[0], FieldType, AfterField);

    for I := 1 to IdentList.IdentifierCount-1 do
      FLastField := RecordType.AddField(
        IdentList.Identifiers[I], FieldType, True);
  end;

  inherited;
end;

{*
  Sp�cifie le nom du champ apr�s lequel placer les champs enfants de ce noeud
  @param AAfterField   Nom du champ
*}
procedure TSepiRecordFieldNode.SetAfterField(const AAfterField: string);
begin
  FAfterField := AAfterField;
end;

{---------------------------}
{ TSepiMethodBodyNode class }
{---------------------------}

{*
  [@inheritDoc]
*}
function TSepiMethodBodyNode.GetMethodCompiler: TSepiMethodCompiler;
begin
  Result := FCompiler;
end;

{*
  [@inheritDoc]
*}
function TSepiMethodBodyNode.GetSepiContext: TSepiMeta;
begin
  if FCompiler <> nil then
    Result := FCompiler.LocalNamespace
  else
    Result := inherited GetSepiContext;
end;

{*
  [@inheritDoc]
*}
function TSepiMethodBodyNode.ResolveIdent(
  const Identifier: string): ISepiExpression;
begin
  Result := MethodResolveIdent(MethodCompiler, Identifier);
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodBodyNode.ChildBeginParsing(Child: TSepiParseTreeNode);
begin
  inherited;

  if Child is TSepiInstructionNode then
    TSepiInstructionNode(Child).InstructionList := MethodCompiler.Instructions;
end;

{*
  [@inheritDoc]
*}
procedure TSepiMethodBodyNode.EndParsing;
begin
  FCompiler.Complete;

  inherited;
end;

{*
  Sp�cifie la m�thode Sepi dont le corps est compil� dans ce noeud
  Cette m�thode doit �tre appel�e une fois avant BeginParsing.
  @param ASepiMethod   M�thode � compiler
*}
procedure TSepiMethodBodyNode.SetSepiMethod(ASepiMethod: TSepiMethod);
begin
  FSepiMethod := ASepiMethod;

  if SepiMethod = nil then
    FCompiler := nil
  else
    FCompiler := UnitCompiler.FindMethodCompiler(SepiMethod, True);
end;

{--------------------------------}
{ TSepiInstructionListNode class }
{--------------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiInstructionListNode.ChildBeginParsing(Child: TSepiParseTreeNode);
begin
  inherited;

  (Child as TSepiInstructionNode).InstructionList := InstructionList;
end;

{--------------------------------------}
{ TSepiIfThenElseInstructionNode class }
{--------------------------------------}

{*
  [@inheritDoc]
*}
procedure TSepiIfThenElseInstructionNode.BeginParsing;
begin
  inherited;

  FInstruction := TSepiIfThenElse.Create(MethodCompiler);
end;

{*
  [@inheritDoc]
*}
procedure TSepiIfThenElseInstructionNode.ChildBeginParsing(
  Child: TSepiParseTreeNode);
const
  TrueBranchChild = 1;
  FalseBranchChild = 2;
begin
  inherited;

  case Child.IndexAsChild of
    TrueBranchChild:
      (Child as TSepiInstructionNode).InstructionList :=
        Instruction.TrueInstructions;
    FalseBranchChild:
      (Child as TSepiInstructionNode).InstructionList :=
        Instruction.FalseInstructions;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TSepiIfThenElseInstructionNode.ChildEndParsing(
  Child: TSepiParseTreeNode);
begin
  if Child is TSepiExpressionNode then
  begin
    Instruction.TestValue :=
      TSepiExpressionNode(Child).AsReadableValue(SystemUnit.Boolean);
  end;

  inherited;
end;

{*
  [@inheritDoc]
*}
procedure TSepiIfThenElseInstructionNode.EndParsing;
begin
  InstructionList.Add(Instruction);

  inherited;
end;

{---------------------------------}
{ TSepiWhileInstructionNode class }
{---------------------------------}

{*
  Configure le type de boucle
  @param ATestAtEnd    True si le test est � la fin
  @param AInvertTest   True si le test doit �tre invert� (not Test)
*}
procedure TSepiWhileInstructionNode.Configure(ATestAtEnd, AInvertTest: Boolean);
begin
  FTestAtEnd := ATestAtEnd;
  FInvertTest := AInvertTest;
end;

{*
  [@inheritDoc]
*}
procedure TSepiWhileInstructionNode.BeginParsing;
begin
  inherited;

  FInstruction := TSepiWhile.Create(MethodCompiler, TestAtEnd);
end;

{*
  [@inheritDoc]
*}
procedure TSepiWhileInstructionNode.ChildBeginParsing(
  Child: TSepiParseTreeNode);
begin
  inherited;

  if Child is TSepiInstructionNode then
    TSepiInstructionNode(Child).InstructionList := Instruction.LoopInstructions;
end;

{*
  [@inheritDoc]
*}
procedure TSepiWhileInstructionNode.ChildEndParsing(Child: TSepiParseTreeNode);
var
  TestValue: ISepiReadableValue;
begin
  if Child is TSepiExpressionNode then
  begin
    TestValue := TSepiExpressionNode(Child).AsReadableValue(SystemUnit.Boolean);

    if TestValue <> nil then
    begin
      if InvertTest then
        TestValue := TSepiUnaryOperation.MakeOperation(opNot, TestValue);

      Instruction.TestValue := TestValue;
    end;
  end;

  inherited;
end;

{*
  [@inheritDoc]
*}
procedure TSepiWhileInstructionNode.EndParsing;
begin
  InstructionList.Add(Instruction);

  inherited;
end;

{-----------------------------------}
{ TSepiDoWhileInstructionNode class }
{-----------------------------------}

{*
  [@inheritDoc]
*}
constructor TSepiDoWhileInstructionNode.Create(AParent: TSepiNonTerminal;
  AClass: TSepiSymbolClass; const ASourcePos: TSepiSourcePosition);
begin
  inherited;

  Configure(True, False);
end;

{---------------------------------------}
{ TSepiRepeatUntilInstructionNode class }
{---------------------------------------}

{*
  [@inheritDoc]
*}
constructor TSepiRepeatUntilInstructionNode.Create(AParent: TSepiNonTerminal;
  AClass: TSepiSymbolClass; const ASourcePos: TSepiSourcePosition);
begin
  inherited;

  Configure(True, True);
end;

{---------------------------------}
{ TSepiRaiseInstructionNode class }
{---------------------------------}

{*
  Construit l'instruction raise avec un objet
*}
procedure TSepiRaiseInstructionNode.MakeRaiseInstruction;
var
  Instruction: TSepiRaise;
  ExceptionValue: ISepiReadableValue;
begin
  // Get exception value
  ExceptionValue := (Children[0] as TSepiExpressionNode).AsReadableValue(
    SystemUnit.TObject);

  // Make instruction
  if ExceptionValue <> nil then
  begin
    Instruction := TSepiRaise.Create(MethodCompiler);
    Instruction.ExceptionValue := ExceptionValue;
    InstructionList.Add(Instruction);
  end;
end;

{*
  Construit l'instruction raise sans objet (reraise)
*}
procedure TSepiRaiseInstructionNode.MakeReraiseInstruction;
var
  Instruction: TSepiReraise;
begin
  Instruction := TSepiReraise.Create(MethodCompiler);
  InstructionList.Add(Instruction);
end;

{*
  [@inheritDoc]
*}
procedure TSepiRaiseInstructionNode.EndParsing;
begin
  if ChildCount > 0 then
    MakeRaiseInstruction
  else
    MakeReraiseInstruction;

  inherited;
end;

end.

