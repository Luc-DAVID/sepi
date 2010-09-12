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
  Types et constantes d�finissant les OpCodes de Sepi
  @author sjrd
  @version 1.0
*}
unit SepiOpCodes;

interface

uses
  SysUtils, SepiReflectionCore, SepiMembers;

resourcestring
  SInvalidOpCode = 'OpCode invalide';

type
  {*
    D�clench�e si l'interpr�teur rencontre un OpCode invalide
    @author sjrd
    @version 1.0
  *}
  ESepiInvalidOpCode = class(Exception);

  /// Type d'un OpCode
  TSepiOpCode = type Byte;

  {*
    Type d'adressage
    L'octet est d�compos� en deux partie : $HL. Les 4 bits de poids faible (L)
    sont une valeur de type TSepiMemorySpace. Les 4 bits de poids fort (H)
    indiquent le nombre d'op�rations de type Address � appliquer successivement
    sur l'adresse.
  *}
  TSepiMemoryRef = type Byte;

  {*
    Espace d'adressage
    Les deux valeurs msConstant et msTrueConst repr�sentent, comme leur nom
    l'indique, des constantes. Certaines op�rations n'acceptent pas les
    constantes en param�tre, par exemple la destination d'un MOV ne peut pas
    �tre une constante. De m�me, msVariable indique une TSepiVariable, qui peut
    �galement �tre une constante (adress�e) : la plupart des op�rations
    n'acceptant pas les constantes n'acceptent pas non plus une TSepiVariable
    constante.
    La valeur msZero est parfois accept�e par des instructions n'acceptant pas
    de constantes, bien que 0 soit manifestement une constante. C'est le cas
    par exemple de l'affectation de cha�ne, qui n'accepte que la constante
    nulle (qui vaut la cha�ne vide '').
    La valeur msZero en tant que valeur de retour d'un CALL est interpr�t�e
    plut�t en tant que msNoResult, autrement dit cela demande que le r�sultat
    ne soit pas stock�. C'est �galement le cas de l'argument ExceptObject d'un
    TRYE (try-except).
    - msZero : 0, nil, '', etc. selon le type de variable
    - msConstant : la variable est une constante, stock�e juste derri�re
    - msLocalsBase : variable locale, sans offset
    - msLocalsByte : variable locale, offset d'un octet
    - msLocalsWord : variable locale, offset de deux octets
    - msParamsBase : param�tre, sans offset
    - msParamsByte : param�tre, offset d'un octet
    - msParamsWord : param�tre, offset de deux octets
    - msTrueConst : r�f�rence � une TSepiConstant
    - msVariable : r�f�rence � une TSepiVariable
  *}
  TSepiMemorySpace = (
    msZero, msConstant, msLocalsBase, msLocalsByte, msLocalsWord, msParamsBase,
    msParamsByte, msParamsWord, msTrueConst, msVariable
  );

{$IF Byte(High(TSepiMemorySpace)) >= 16}
  {$MESSAGE ERROR 'TSepiMemorySpace mustn''t have more than 16 values'}
{$IFEND}

const
  msNil = msZero;          /// Constante nil
  msNoResult = msZero;     /// Ne pas garder le r�sultat
  msResult = msLocalsBase; /// Variable r�sultat
  msSelf = msParamsBase;   /// Param�tre Self

type
  {*
    Combinaison d'un d�r�f�rencement et d'une op�ration sur une adresse
    Utilisez les routines AddressDerefAndOpEncode et AddressDerefAndOpDecode
    pour travailler sur des valeurs de type TSepiAddressDerefAndOp.
    S'il est pr�sent, le d�r�f�rencement est toujours appliqu� avant
    l'op�ration. Cela correspond � l'acc�s indic� d'un tableau (ou cha�ne de
    caract�res).
  *}
  TSepiAddressDerefAndOp = type Byte;

  {*
    Type d'op�ration � appliquer � une adresse
    Les "+ const" sont utiles pour les offsets de champs, comme dans les record
    ou les objets, ou encore dans les VMT.
    Les "+ mem" sont utiles pour les index de tableaux de bytes, ou pour les
    index de caract�re dans les cha�nes.
    Les "+ const*mem" sont utiles pour les index de tableaux dont les �l�ments
    font plus d'un octet.
    - aoNone : aucune op�ration
    - aoPlusConstShortint : ajoute un Shortint constant
    - aoPlusConstSmallint : ajoute un Smallint constant
    - aoPlusConstLongint : ajoute un Longint constant
    - aoPlusMemShortint : ajoute un Shortint m�moire
    - aoPlusMemSmallint : ajoute un Smallint m�moire
    - aoPlusMemLongint : ajoute un Longint m�moire
    - aoPlusConstTimesMemShortint : ajoute un Byte constant multipli� par un
      Shortint m�moire
    - aoPlusConstTimesMemSmallint : ajoute un Byte constant multipli� par un
      Smallint m�moire
    - aoPlusConstTimesMemLongint : ajoute un Byte constant multipli� par un
      Longint m�moire
  *}
  TSepiAddressOperation = (
    aoNone, aoPlusConstShortint, aoPlusConstSmallint, aoPlusConstLongint,
    aoPlusMemShortint, aoPlusMemSmallint, aoPlusMemLongint,
    aoPlusConstTimesMemShortint, aoPlusConstTimesMemSmallint,
    aoPlusConstTimesMemLongint, aoPlusConstTimesMemByte,
    aoPlusConstTimesMemWord, aoPlusConstTimesMemLongWord,
    aoPlusLongConstTimesMemShortint, aoPlusLongConstTimesMemSmallint,
    aoPlusLongConstTimesMemLongint, aoPlusLongConstTimesMemByte,
    aoPlusLongConstTimesMemWord, aoPlusLongConstTimesMemLongWord
  );

  {*
    D�r�rencement d'adresse
    Les doubles d�r�f�rencements sont utilis�s essentiellement lorsqu'on acc�de
    � un champ de la VMT d'un objet. Mais ils peuvent avoir d'autres
    utilisations.
    - adNone : pas de d�r�f�rencement
    - adSimple : d�r�f�rencement simple (Ptr^)
    - adDouble : d�r�f�rencement double (Ptr^^)
  *}
  TSepiAddressDereference = (adNone, adSimple, adDouble);

  {*
    Types de donn�es de base que g�re l'interpr�teur Sepi
  *}
  TSepiBaseType = (
    btBoolean, btByte, btWord, btDWord, btShortint, btSmallint, btLongint,
    btInt64, btSingle, btDouble, btExtended, btComp, btCurrency, btAnsiChar,
    btWideChar, btAnsiStr, btWideStr, btUnicodeStr, btVariant
  );

  {*
    Ensemble de types de donn�es de base
  *}
  TSepiBaseTypes = set of TSepiBaseType;

const
  btIntegers =
    [btByte, btWord, btDWord, btShortint, btSmallint, btLongint, btInt64];
  btFloats = [btSingle, btDouble, btExtended, btComp, btCurrency];
  btNumbers = btIntegers + btFloats;
  btChars = [btAnsiChar, btWideChar];
  btStrings = [btAnsiStr, btWideStr, btUnicodeStr];
  btCharsAndStrings = btChars + btStrings;

type
  /// Configuration d'un appel basique
  TSepiCallSettings = type Byte;

  /// Taille d'un param�tre � passer � une proc�dure
  TSepiParamSize = type Byte;

  {*
    Option de lecture d'adresse
    Si aoZeroAsNil est sp�cifi�, aoAcceptZero n'a aucun effet.
    Si la taille des constantes est n�gative ou nulle, aoAcceptConstInCode n'a
    aucun effet.
    - aoZeroAsNil : mappe un msZero en nil au retour
    - aoAcceptZero : accepte msZero
    - aoAcceptTrueConst : accepte les vraies constantes
    - aoAcceptAddressedConst : accepte les constantes adress�es
    - aoAcceptConstInCode : accepte les constantes dans le code
  *}
  TSepiAddressOption = (
    aoZeroAsNil, aoAcceptZero, aoAcceptTrueConst, aoAcceptAddressedConst,
    aoAcceptConstInCode
  );

  /// Options de lecture d'adresse
  TSepiAddressOptions = set of TSepiAddressOption;

const
  // Accepte tous les types de constantes
  aoAcceptAllConsts = [
    aoAcceptZero, aoAcceptTrueConst, aoAcceptAddressedConst,
    aoAcceptConstInCode
  ];

  /// Accepte tous les types de constantes hors code
  aoAcceptNonCodeConsts = [
    aoAcceptZero, aoAcceptTrueConst, aoAcceptAddressedConst
  ];

  /// Taille des constantes en fonction des types de base
  BaseTypeConstSizes: array[TSepiBaseType] of Integer = (
    1, 1, 2, 4, 1, 2, 4, 8, 4, 8, 10, 8, 8, 1, 2, 0, 0, 0, 0
  );

  /// Le param�tre est pass� par adresse
  psByAddress = TSepiParamSize(0);

const
  MemPlaceMask = $0F;   /// Masque d'espace m�moire
  MemOpCountMask = $F0; /// Masque du nombre d'op�rations
  MemOpCountShift = 4;  /// Offset du nombre d'op�rations

  AddrOperationMask = $3F; /// Masque de l'op�ration sur adresse
  AddrDerefMask = $C0;     /// Masque de d�r�f�rencement
  AddrDerefShift = 6;      /// Offset du d�r�f�rencement

  SettingsCallingConvMask = $07;    /// Masque de la convention d'appel
  SettingsRegUsageMask = $18;       /// Masque de l'usage des registres
  SettingsRegUsageShift = 3;        /// Offset de l'usage des registres
  SettingsResultBehaviorMask = $E0; /// Masque du comportement du r�sultat
  SettingsResultBehaviorShift = 5;  /// Offset du comportement du r�sultat

const
  (*
    Mem := TSepiMemoryRef + Value [+ Operations]
    Value :=
      Zero        -> Nothing
      Constant    -> Constant of the relevant type
      LocalsBase  -> Local vars, no offset
      LocalsByte  -> Byte offset in local vars
      LocalsWord  -> Word offset in local vars
      ParamsBase  -> Parameters, no offset
      ParamsByte  -> Byte offset in parameters
      ParamsWord  -> Word offset in parameters
      GlobalConst -> Constant reference
      GlobalVar   -> Variable reference
    Params := Byte-Count + (Byte or Word)-Size + (Param){Count} + Result
      (Size is counted by 4 bytes ; it is Byte-wide if Count <= (255 div 3))
      Parameters must be ordered in growing SepiStackOffset.
    Param := Param-Size + Mem
    Result := Mem (zero as nil)
    Class := Mem(4) where a constant is a TSepiClass reference
    Type := TSepiBaseType
  *)

  // No category
  ocNope     = TSepiOpCode($00); /// NOP
  ocExtended = TSepiOpCode($01); /// Instruction �tendue (non utilis�)

  // Flow control (destinations are relative to end of instruction)
  ocJump        = TSepiOpCode($02); /// JUMP Dest
  ocJumpIfTrue  = TSepiOpCode($03); /// JIT  Dest, Test
  ocJumpIfFalse = TSepiOpCode($04); /// JIF  Dest, Test

  // Calls
  ocAddressCall = TSepiOpCode($05); /// CALL CallSettings (ORS)? Address Params
  ocStaticCall  = TSepiOpCode($06); /// CALL Method-Ref Params
  ocDynamicCall = TSepiOpCode($07); /// CALL Method-Ref Self Params

  // Memory moves
  ocLoadAddress    = TSepiOpCode($10); /// LEA   Dest, Src
  ocMoveByte       = TSepiOpCode($11); /// MOVB  Dest, Src
  ocMoveWord       = TSepiOpCode($12); /// MOVW  Dest, Src
  ocMoveDWord      = TSepiOpCode($13); /// MOVD  Dest, Src
  ocMoveQWord      = TSepiOpCode($14); /// MOVQ  Dest, Src
  ocMoveExt        = TSepiOpCode($15); /// MOVE  Dest, Src
  ocMoveAnsiStr    = TSepiOpCode($16); /// MOVAS Dest, Src
  ocMoveWideStr    = TSepiOpCode($17); /// MOVWS Dest, Src
  ocMoveUnicodeStr = TSepiOpCode($18); /// MOVUS Dest, Src
  ocMoveVariant    = TSepiOpCode($19); /// MOVV  Dest, Src
  ocMoveIntf       = TSepiOpCode($1A); /// MOVI  Dest, Src
  ocMoveSome       = TSepiOpCode($1B); /// MOVS  Byte-Count, Dest, Src
  ocMoveMany       = TSepiOpCode($1C); /// MOVM  Word-Count, Dest, Src
  ocMoveOther      = TSepiOpCode($1D); /// MOVO  Type-Ref, Dest, Src
  ocConvert        = TSepiOpCode($1E); /// CVRT  Type, Type, [CP,] Mem, Mem

  // Self dest unary operations
  ocSelfInc = TSepiOpCode($20); /// INC Type, Var
  ocSelfDec = TSepiOpCode($21); /// DEC Type, Var
  ocSelfNot = TSepiOpCode($22); /// NOT Type, Var
  ocSelfNeg = TSepiOpCode($23); /// NEG Type, Var

  // Self dest binary operations
  ocSelfAdd      = TSepiOpCode($24); /// ADD Type, Var, Value
  ocSelfSubtract = TSepiOpCode($25); /// SUB Type, Var, Value
  ocSelfMultiply = TSepiOpCode($26); /// MUL Type, Var, Value
  ocSelfDivide   = TSepiOpCode($27); /// DIV Type, Var, Value
  ocSelfIntDiv   = TSepiOpCode($28); /// IDV Type, Var, Value
  ocSelfModulus  = TSepiOpCode($29); /// MOD Type, Var, Value
  ocSelfShl      = TSepiOpCode($2A); /// SHL Type, Var, Value
  ocSelfShr      = TSepiOpCode($2B); /// SHR Type, Var, Value
  ocSelfAnd      = TSepiOpCode($2C); /// AND Type, Var, Value
  ocSelfOr       = TSepiOpCode($2D); /// OR  Type, Var, Value
  ocSelfXor      = TSepiOpCode($2E); /// XOR Type, Var, Value

  // Other dest unary operations
  ocOtherInc = TSepiOpCode($30); /// INC Type, Dest, Value
  ocOtherDec = TSepiOpCode($31); /// DEC Type, Dest, Value
  ocOtherNot = TSepiOpCode($32); /// NOT Type, Dest, Value
  ocOtherNeg = TSepiOpCode($33); /// NEG Type, Dest, Value

  // Other dest binary operations
  ocOtherAdd      = TSepiOpCode($34); /// ADD Type, Dest, Left, Right
  ocOtherSubtract = TSepiOpCode($35); /// SUB Type, Dest, Left, Right
  ocOtherMultiply = TSepiOpCode($36); /// MUL Type, Dest, Left, Right
  ocOtherDivide   = TSepiOpCode($37); /// DIV Type, Dest, Left, Right
  ocOtherIntDiv   = TSepiOpCode($38); /// IDV Type, Dest, Left, Right
  ocOtherModulus  = TSepiOpCode($39); /// MOD Type, Dest, Left, Right
  ocOtherShl      = TSepiOpCode($3A); /// SHL Type, Dest, Left, Right
  ocOtherShr      = TSepiOpCode($3B); /// SHR Type, Dest, Left, Right
  ocOtherAnd      = TSepiOpCode($3C); /// AND Type, Dest, Left, Right
  ocOtherOr       = TSepiOpCode($3D); /// OR  Type, Dest, Left, Right
  ocOtherXor      = TSepiOpCode($3E); /// XOR Type, Dest, Left, Right

  // Comparisons
  ocCompEquals    = TSepiOpCode($40); /// EQ  Type, Dest, Left, Right
  ocCompNotEquals = TSepiOpCode($41); /// NEQ Type, Dest, Left, Right
  ocCompLower     = TSepiOpCode($42); /// LT  Type, Dest, Left, Right
  ocCompGreater   = TSepiOpCode($43); /// GT  Type, Dest, Left, Right
  ocCompLowerEq   = TSepiOpCode($44); /// LE  Type, Dest, Left, Right
  ocCompGreaterEq = TSepiOpCode($45); /// GE  Type, Dest, Left, Right

  // Compile time objects which must be read at runtime in Sepi
  ocGetTypeInfo    = TSepiOpCode($50); /// GTI Dest, Type-Ref
  ocGetDelphiClass = TSepiOpCode($51); /// GDC Dest, Class-Ref
  ocGetMethodCode  = TSepiOpCode($52); /// GMC Dest, Method-Ref

  // is and as operators
  ocIsClass = TSepiOpCode($53); /// IS Dest, Object, Class
  ocAsClass = TSepiOpCode($54); /// AS Object, Class

  // Exception handling
  ocRaise      = TSepiOpCode($60); /// RAISE ExceptObject
  ocReraise    = TSepiOpCode($61); /// RERS
  ocTryExcept  = TSepiOpCode($62); /// TRYE TrySize, ExceptSize, [ExceptObject]
  ocTryFinally = TSepiOpCode($63); /// TRYF TrySize, FinallySize
  /// ON ExceptObject, Byte-Count, (Class-Ref, Dest){Count}
  ocMultiOn    = TSepiOpCode($64);

  // Set operations
  ocSetInclude        = TSepiOpCode($70); /// SINC Dest, Elem
  ocSetExclude        = TSepiOpCode($71); /// SEXC Dest, Elem
  ocSetIn             = TSepiOpCode($72); /// SIN  Dest, Set, Elem
  ocSetElem           = TSepiOpCode($73); /// SELE SetSize, Dest, Elem
  ocSetRange          = TSepiOpCode($74); /// SRNG SetSize, Dest, Lo, Hi
  ocSetUnionRange     = TSepiOpCode($75); /// SUR  SetSize, Dest, Lo, Hi
  ocSetEquals         = TSepiOpCode($76); /// SEQ  SetSize, Dest, Set1, Set2
  ocSetNotEquals      = TSepiOpCode($77); /// SNE  SetSize, Dest, Set1, Set2
  ocSetContained      = TSepiOpCode($78); /// SLE  SetSize, Dest, Set1, Set2
  ocSetSelfIntersect  = TSepiOpCode($79); /// SINT SetSize, Dest, Src
  ocSetSelfUnion      = TSepiOpCode($7A); /// SADD SetSize, Dest, Src
  ocSetSelfSubtract   = TSepiOpCode($7B); /// SSUB SetSize, Dest, Src
  ocSetOtherIntersect = TSepiOpCode($7C); /// SINT SetSize, Dest, Left, Right
  ocSetOtherUnion     = TSepiOpCode($7D); /// SADD SetSize, Dest, Left, Right
  ocSetOtherSubtract  = TSepiOpCode($7E); /// SSUB SetSize, Dest, Left, Right
  ocSetExpand         = TSepiOpCode($7F); /// SEXP Dest, Src, Lo, Hi

  // Standard Delphi functions
  ocAnsiStrLength       = TSepiOpCode($80); /// ASL Dest, Value
  ocWideStrLength       = TSepiOpCode($81); /// WSL Dest, Value
  ocUnicodeStrLength    = TSepiOpCode($82); /// USL Dest, Value
  ocDynArrayLength      = TSepiOpCode($83); /// DAL Dest, Value
  ocDynArrayHigh        = TSepiOpCode($84); /// DAH Dest, Value
  ocAnsiStrSetLength    = TSepiOpCode($85); /// ASSL Var, Len
  ocWideStrSetLength    = TSepiOpCode($86); /// WSSL Var, Len
  ocUnicodeStrSetLength = TSepiOpCode($87); /// USSL Var, Len
  ocDynArraySetLength   = TSepiOpCode($88); /// DASL Type-Ref, Var,DimCount,Dims
  ocAnsiStrCopy         = TSepiOpCode($89); /// ASCP Dest, Src, Index, Count
  ocWideStrCopy         = TSepiOpCode($8A); /// WSCP Dest, Src, Index, Count
  ocUnicodeStrCopy      = TSepiOpCode($8B); /// USCP Dest, Src, Index, Count
  ocDynArrayCopy        = TSepiOpCode($8C); /// DACP Type-Ref, Dest, Src
  ocDynArrayCopyRange   = TSepiOpCode($8D); /// DACP Type-Ref, Dest, Src,Idx,Cnt

  // Routine reference instructions
  /// RRFMR MethodRefType, Dest, Source
  ocRoutineRefFromMethodRef = TSepiOpCode($A0);

function MemoryRefEncode(MemorySpace: TSepiMemorySpace;
  OpCount: Integer): TSepiMemoryRef;
procedure MemoryRefDecode(MemoryRef: TSepiMemoryRef;
  out MemorySpace: TSepiMemorySpace; out OpCount: Integer);

function AddressDerefAndOpEncode(Dereference: TSepiAddressDereference;
  Operation: TSepiAddressOperation): TSepiAddressDerefAndOp;
procedure AddressDerefAndOpDecode(AddressDerefAndOp: TSepiAddressDerefAndOp;
  out Dereference: TSepiAddressDereference;
  out Operation: TSepiAddressOperation);

function CallSettingsEncode(CallingConvention: TCallingConvention;
  RegUsage: Byte; ResultBehavior: TSepiTypeResultBehavior): TSepiCallSettings;
procedure CallSettingsDecode(Settings: TSepiCallSettings;
  out CallingConvention: TCallingConvention; out RegUsage: Byte;
  out ResultBehavior: TSepiTypeResultBehavior);

procedure RaiseInvalidOpCode;

implementation

{*
  Encode une r�f�rence m�moire
  @param Place     Espace m�moire
  @param OpCount   Nombre d'op�rations
  @return R�f�rence m�moire correspondante
*}
function MemoryRefEncode(MemorySpace: TSepiMemorySpace;
  OpCount: Integer): TSepiMemoryRef;
begin
  Result := Byte(MemorySpace) or (Byte(OpCount) shl MemOpCountShift);
end;

{*
  D�code une r�f�rence m�moire
  @param MemoryRef   R�f�rence m�moire � d�coder
  @param Place       En sortie : Espace m�moire
  @param OpCount     En sortie : Nombre d'op�rations
*}
procedure MemoryRefDecode(MemoryRef: TSepiMemoryRef;
  out MemorySpace: TSepiMemorySpace; out OpCount: Integer);
begin
  MemorySpace := TSepiMemorySpace(MemoryRef and MemPlaceMask);
  OpCount := (MemoryRef and MemOpCountMask) shr MemOpCountShift;
end;

{*
  Encode un d�r�f�rencement + op�ration sur adresse
  @param Dereference   D�r�f�rencement
  @param Operation     Op�ration
  @return Combinaison du d�r�f�rencement et de l'op�ration
*}
function AddressDerefAndOpEncode(Dereference: TSepiAddressDereference;
  Operation: TSepiAddressOperation): TSepiAddressDerefAndOp;
begin
  Result := Byte(Operation) or (Byte(Dereference) shl AddrDerefShift);
end;

{*
  D�code un d�r�f�rencement + op�ration sur adresse
  @param AddressDerefAndOp   Combinaison � d�coder
  @param Dereference         En sortie : D�r�f�rencement
  @param Operation           En sortie : Op�ration
*}
procedure AddressDerefAndOpDecode(AddressDerefAndOp: TSepiAddressDerefAndOp;
  out Dereference: TSepiAddressDereference;
  out Operation: TSepiAddressOperation);
begin
  Dereference := TSepiAddressDereference(
    (AddressDerefAndOp and AddrDerefMask) shr AddrDerefShift);
  Operation := TSepiAddressOperation(AddressDerefAndOp and AddrOperationMask);
end;

{*
  Encode une configuration d'appel
  @param CallingConvention   Convention d'appel
  @param RegUsage            Usage des registres
  @param ResultBehavior      Comportement du r�sultat
  @return Configuration d'appel correspondante
*}
function CallSettingsEncode(CallingConvention: TCallingConvention;
  RegUsage: Byte; ResultBehavior: TSepiTypeResultBehavior): TSepiCallSettings;
begin
  Result := Byte(CallingConvention) or
    (RegUsage shl SettingsRegUsageShift) or
    (Byte(ResultBehavior) shl SettingsResultBehaviorShift);
end;

{*
  D�code une configuration d'appel
  @param Settings            Configuration � d�coder
  @param CallingConvention   En sortie : Convention d'appel
  @param RegUsage            En sortie : Usage des registres
  @param ResultBehavior      En sortie : Comportement du r�sultat
*}
procedure CallSettingsDecode(Settings: TSepiCallSettings;
  out CallingConvention: TCallingConvention; out RegUsage: Byte;
  out ResultBehavior: TSepiTypeResultBehavior);
begin
  CallingConvention := TCallingConvention(Settings and SettingsCallingConvMask);
  RegUsage := (Settings and SettingsRegUsageMask) shr SettingsRegUsageShift;
  ResultBehavior := TSepiTypeResultBehavior(
    (Settings and SettingsResultBehaviorMask) shr SettingsResultBehaviorShift);
end;

{*
  D�clenche une exception OpCode invalide
*}
procedure RaiseInvalidOpCode;

  function ReturnAddress: Pointer;
  asm
        MOV     EAX,[ESP+4]
  end;

begin
  raise ESepiInvalidOpCode.CreateRes(@SInvalidOpCode) at ReturnAddress;
end;

end.

