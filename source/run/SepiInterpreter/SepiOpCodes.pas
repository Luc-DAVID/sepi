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
    sont une valeur de type TSepiMemoryPlace. Les 4 bits de poids fort (H)
    indiquent le nombre d'op�rations de type Address � appliquer successivement
    sur l'adresse.
  *}
  TSepiMemoryRef = type Byte;

  {*
    Espace d'adressage
    Les deux valeurs mpConstant et mpGlobalConst repr�sentent, comme leur nom
    l'indique, des constantes. Certaines op�rations n'acceptent pas les
    constantes en param�tre, par exemple la destination d'un MOV ne peut pas
    �tre une constante.
    La valeur mpConstant en tant que valeur de retour d'un CALL est interpr�t�e
    plut�t en temps que mpNoResult, autrement dit cela demande que le r�sultat
    ne soit pas stock�.
    - mpConstant : la variable est une constante, stock�e juste derri�re
    - mpLocalsBase : variable locale, sans offset
    - mpLocalsByte : variable locale, offset d'un octet
    - mpLocalsWord : variable locale, offset de deux octets
    - mpParamsBase : param�tre, sans offset
    - mpParamsByte : param�tre, offset d'un octet
    - mpParamsWord : param�tre, offset de deux octets
    - mpPreparedParamsBase : param�tres en pr�paration, sans offset
    - mpPreparedParamsByte : param�tres en pr�paration, offset d'un octet
    - mpPreparedParamsWord : param�tres en pr�paration, offset de deux octet
    - mpGlobalConst : r�f�rence � une TSepiConstant
    - mpGlobalVar : r�f�rence � une TSepiVariable
  *}
  TSepiMemorySpace = (
    mpConstant, mpLocalsBase, mpLocalsByte, mpLocalsWord, mpParamsBase,
    mpParamsByte, mpParamsWord, mpPreparedParamsBase, mpPreparedParamsByte,
    mpPreparedParamsWord, mpGlobalConst, mpGlobalVar
  );

{$IF Byte(High(TSepiMemorySpace)) >= 16}
  {$MESSAGE Error 'TSepiMemoryPlace mustn''t have more than 16 values'}
{$IFEND}

const
  mpNoResult = mpConstant;               /// Ne pas garder le r�sultat
  mpResult = mpLocalsBase;               /// Variable r�sultat
  mpSelf = mpParamsBase;                 /// Param�tre Self
  mpPreparedSelf = mpPreparedParamsBase; /// Param�tre Self en pr�paration

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
    - aoPlusConstTimesMemShortint : ajoute un Shortint constant multipli� par
      un Shortint m�moire
    - aoPlusConstTimesMemSmallint : ajoute un Shortint constant multipli� par
      un Smallint m�moire
    - aoPlusConstTimesMemLongint : ajoute un Shortint constant multipli� par
      un Longint m�moire
  *}
  TSepiAddressOperation = (
    aoNone, aoPlusConstShortint, aoPlusConstSmallint, aoPlusConstLongint,
    aoPlusMemShortint, aoPlusMemSmallint, aoPlusMemLongint,
    aoPlusConstTimesMemShortint, aoPlusConstTimesMemSmallint,
    aoPlusConstTimesMemLongint
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
    btBoolean, btByte, btWord, btDWord, btQWord, btShortint, btSmallint,
    btLongint, btInt64, btSingle, btDouble, btExtended, btComp, btCurrency,
    btAnsiStr, btWideStr, btVariant
  );

  {*
    Type de destination d'un JUMP
    jdkShortint, jdkSmallint et jdkLongint ont des valeurs relatives par
    rapport � la fin de l'instruction de JUMP.
    jdkMemory est une valeur pointeur absolue lue en m�moire
  *}
  TSepiJumpDestKind = (jdkShortint, jdkSmallint, jdkLongint, jdkMemory);

  /// Configuration d'un appel basique
  TSepiCallSettings = type Byte;

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
  {
    Mem := TSepiMemoryPlace + Value [+ Operations]
    Value :=
      Constant (const accepted) -> Constant of the relevant type
      Constant (as CALL result) -> Nothing (don't fetch result)
      LocalsBase                -> Local vars, no offset
      LocalsByte                -> Byte offset in local vars
      LocalsWord                -> Word offset in local vars
      ParamsBase                -> Parameters, no offset
      ParamsByte                -> Byte offset in parameters
      ParamsWord                -> Word offset in parameters
      PreparedParamsBase        -> Prepared parameters, no offset
      PreparedParamsByte        -> Byte offset in prepared parameters
      PreparedParamsWord        -> Word offset in prepared parameters
      GlobalConst               -> Constant reference
      GlobalVar                 -> Variable reference
    Class := Mem(4) where a constant is a TSepiClass reference
    Dest := TSepiJumpestKind + DestValue
    DestValue :=
      Shortint -> Shortint relative value
      Smallint -> Smallint relative value
      Longint  -> Longint relative value
      Memory   -> Mem (absolute)
    Type := TSepiBaseType
  }

  // No category
  ocNope        = TSepiOpCode($00); /// NOP
  ocExtended    = TSepiOpCode($01); /// Instruction �tendue (non utilis�)

  // Flow control (destinations are relative to end of instruction)
  ocJump          = TSepiOpCode($02); /// JUMP Dest
  ocJumpIfTrue    = TSepiOpCode($03); /// JIT  Dest, Test
  ocJumpIfFalse   = TSepiOpCode($04); /// JIF  Dest, Test
  ocReturn        = TSepiOpCode($05); /// RET
  ocJumpAndReturn = TSepiOpCode($06); /// JRET Dest

  // Calls
  ocPrepareParams = TSepiOpCode($07); /// PRPA Word-Size
  ocBasicCall     = TSepiOpCode($08); /// CALL CallSettings Address [Result]
  ocSignedCall    = TSepiOpCode($09); /// CALL Signature-Ref Address [Result]
  ocStaticCall    = TSepiOpCode($0A); /// CALL Method-Ref [Result]
  ocDynamicCall   = TSepiOpCode($0B); /// CALL Method-Ref [Result]

  // Memory moves
  ocLoadAddress = TSepiOpCode($10); /// LEA   Dest, Src
  ocMoveByte    = TSepiOpCode($11); /// MOVB  Dest, Src
  ocMoveWord    = TSepiOpCode($12); /// MOVW  Dest, Src
  ocMoveDWord   = TSepiOpCode($13); /// MOVD  Dest, Src
  ocMoveQWord   = TSepiOpCode($14); /// MOVQ  Dest, Src
  ocMoveExt     = TSepiOpCode($15); /// MOVE  Dest, Src
  ocMoveAnsiStr = TSepiOpCode($16); /// MOVAS Dest, Src
  ocMoveWideStr = TSepiOpCode($17); /// MOVWS Dest, Src
  ocMoveVariant = TSepiOpCode($18); /// MOVV  Dest, Src
  ocMoveIntf    = TSepiOpCode($19); /// MOVI  Dest, Src
  ocMoveSome    = TSepiOpCode($1A); /// MOVS  Byte-Count, Dest, Src
  ocMoveMany    = TSepiOpCode($1B); /// MOVM  Word-Count, Dest, Src
  ocMoveOther   = TSepiOpCode($1C); /// MOVO  Type-Ref, Dest, Src
  ocConvert     = TSepiOpCode($1D); /// CVRT  Type, Type, Mem, Mem

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
  ocSelfIntDiv   = TSepiOpCode($28); /// DIV Type, Var, Value
  ocSelfModulus  = TSepiOpCode($29); /// MOD Type, Var, Value
  ocSelfShl      = TSepiOpCode($2A); /// SHL Type, Var, Value
  ocSelfShr      = TSepiOpCode($2B); /// SHR Type, Var, Value
  ocSelfSal      = TSepiOpCode($2A); /// SAL Type, Var, Value
  ocSelfSar      = TSepiOpCode($2C); /// SAR Type, Var, Value
  ocSelfAnd      = TSepiOpCode($2D); /// AND Type, Var, Value
  ocSelfOr       = TSepiOpCode($2E); /// OR  Type, Var, Value
  ocSelfXor      = TSepiOpCode($2F); /// XOR Type, Var, Value

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
  ocOtherIntDiv   = TSepiOpCode($38); /// DIV Type, Dest, Left, Right
  ocOtherModulus  = TSepiOpCode($39); /// MOD Type, Dest, Left, Right
  ocOtherShl      = TSepiOpCode($3A); /// SHL Type, Dest, Left, Right
  ocOtherShr      = TSepiOpCode($3B); /// SHR Type, Dest, Left, Right
  ocOtherSal      = TSepiOpCode($3A); /// SAL Type, Dest, Left, Right
  ocOtherSar      = TSepiOpCode($3C); /// SAR Type, Dest, Left, Right
  ocOtherAnd      = TSepiOpCode($3D); /// AND Type, Dest, Left, Right
  ocOtherOr       = TSepiOpCode($3E); /// OR  Type, Dest, Left, Right
  ocOtherXor      = TSepiOpCode($3F); /// XOR Type, Dest, Left, Right

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
  ocTryExcept  = TSepiOpCode($62); /// TRYE Dest, [ExceptObject]
  ocTryFinally = TSepiOpCode($63); /// TRYF Dest
  /// ON ExceptObject, Byte-Count, Class-Refs{Count}, Dest-Kind, Dests{Count}
  ocMultiOn    = TSepiOpCode($64);

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
        MOV     EAX,[ESP]
  end;

begin
  raise ESepiInvalidOpCode.CreateRes(@SInvalidOpCode) at ReturnAddress;
end;

end.

