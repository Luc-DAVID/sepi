{*
  D�finit des routines en lien avec le langage Delphi lui-m�me
  @author sjrd
  @version 1.0
*}
unit ScDelphiLanguage;

interface

uses
  SysUtils, TypInfo, ScUtils;

type
  {*
    Instruction JMP ou CALL
    @author sjrd
    @version 1.0
  *}
  TJmpInstruction = packed record
    OpCode: Byte;      /// OpCode
    Argument: Integer; /// Destination
  end;

function CorrectIdentifier(const Ident: string): Boolean;

procedure SetBit(var Value: Integer; const Bit: Byte); register;
procedure ClearBit(var Value: Integer; const Bit: Byte); register;
procedure ToggleBit(var Value: Integer; const Bit: Byte); register;
function TestBit(const Value: Integer; const Bit: Byte): Boolean; register;

function GetMethodFromName(Obj: TObject;
  const MethodName: ShortString): TMethod;

function MakeMethod(Code: Pointer; Data: Pointer = nil): TMethod;

function GetClassVirtualCode(AClass: TClass; VMTOffset: Integer): Pointer;
function GetClassVirtualMethod(AClass: TClass; VMTOffset: Integer): TMethod;
function GetObjectVirtualCode(AObject: TObject;
  VMTOffset: Integer): Pointer;
function GetObjectVirtualMethod(AObject: TObject;
  VMTOffset: Integer): TMethod;

function GetClassDynamicCode(AClass: TClass; DMTIndex: Integer): Pointer;
function GetClassDynamicMethod(AClass: TClass; DMTIndex: Integer): TMethod;
function GetObjectDynamicCode(AObject: TObject; DMTIndex: Integer): Pointer;
function GetObjectDynamicMethod(AObject: TObject;
  DMTIndex: Integer): TMethod;

function StrToStrRepres(const Str: string;
  ExcludedChars: TSysCharSet = []): string;
function StrRepresToStr(Str: string): string;

function CharToCharRepres(Chr: Char;
  ExcludedChars: TSysCharSet = []): string;
function CharRepresToChar(Str: string): Char;

function CharSetToStr(const CharSet: TSysCharSet): string;
function StrToCharSet(Str: string): TSysCharSet;

function EnumSetToStr(const EnumSet; TypeInfo: PTypeInfo): string;
procedure StrToEnumSet(const Str: string; TypeInfo: PTypeInfo; out EnumSet);

function SkipPackedShortString(Value: PShortstring): Pointer;

function JmpArgument(JmpAddress, JmpDest: Pointer): Integer;
procedure MakeJmp(var Instruction; Dest: Pointer);
procedure MakeCall(var Instruction; Dest: Pointer);

function MakeProcOfRegisterMethod(const Method: TMethod;
  UsedRegCount: Byte; MoveStackCount: Word = 0): Pointer;
function MakeProcOfStdCallMethod(const Method: TMethod): Pointer;
function MakeProcOfPascalMethod(const Method: TMethod): Pointer;
function MakeProcOfCDeclMethod(const Method: TMethod): Pointer;
procedure ClearCDeclCallInfo;
procedure FreeProcOfMethod(Proc: Pointer);

implementation

uses
  Windows, ScConsts;

type
  /// Pointeur vers TCDeclCallInfo
  PCDeclCallInfo = ^TCDeclCallInfo;

  {*
    Informations de contexte sur l'appel d'une m�thode cdecl
    @author sjrd
    @version 1.0
  *}
  TCDeclCallInfo = packed record
    Previous: PCDeclCallInfo; /// Pointeur vers le contexte pr�c�dent
    StackPointer: Pointer;    /// Valeur de ESP au moment de l'appel
    ReturnAddress: Pointer;   /// Adresse de retour de l'appel
  end;

threadvar
  /// Liste des infos sur les appels cdecl (sp�cifique � chaque thread)
  CDeclCallInfoList: PCDeclCallInfo;

{*
  Trouve la derni�re info de routine cdecl valide
  @param StackPointer   Valeur du registre esp au moment de l'appel
  @param AllowSame      True pour permettre un StackPointer �gal, False sinon
  @return Pointeur sur la derni�re info de routine cdecl valide
*}
function GetLastValidCDeclCallInfo(StackPointer: Pointer;
  AllowSame: Boolean): PCDeclCallInfo;
var
  Previous: PCDeclCallInfo;
begin
  Result := CDeclCallInfoList;
  while (Result <> nil) and
    (Cardinal(Result.StackPointer) <= Cardinal(StackPointer)) do
  begin
    if AllowSame and (Result.StackPointer = StackPointer) then
      Break;
    Previous := Result.Previous;
    Dispose(Result);
    Result := Previous;
  end;
end;

{*
  S'assure que toutes les informations de routines cdecl sont supprim�es
  Cette routine devrait �tre appel�e � la fin de chaque thread susceptible
  d'utiliser des routines issues de m�thodes cdecl.
  Si ce n'est pas possible, ce n'est pas dramatique, mais l'application
  s'expose � de l�g�res fuites m�moire en cas d'exception � l'int�rieur de
  telles m�thodes.
  Pour le thread principal, ce n'est pas n�cessaire, le code de finalisation de
  ScDelphiLanguage.pas s'en charge.
*}
procedure ClearCDeclCallInfo;
begin
  GetLastValidCDeclCallInfo(Pointer($FFFFFFFF), False);
  CDeclCallInfoList := nil;
end;

{*
  Ajoute une adresse de retour
  @param StackPointer    Valeur du registre ESP
  @param ReturnAddress   Adresse � ajouter
*}
procedure StoreCDeclReturnAddress(
  StackPointer, ReturnAddress: Pointer); stdcall;
var
  LastInfo, CurInfo: PCDeclCallInfo;
begin
  LastInfo := GetLastValidCDeclCallInfo(StackPointer, False);

  New(CurInfo);
  CurInfo.Previous := LastInfo;
  CurInfo.StackPointer := StackPointer;
  CurInfo.ReturnAddress := ReturnAddress;
  CDeclCallInfoList := CurInfo;
end;

{*
  R�cup�re une adresse de retour
  @param StackPointer   Valeur du registre ESP
  @return L'adresse de retour qui a �t� ajout�e en dernier
*}
function GetCDeclReturnAddress(StackPointer: Pointer): Pointer; register;
var
  LastInfo: PCDeclCallInfo;
begin
  LastInfo := GetLastValidCDeclCallInfo(StackPointer, True);

  if (LastInfo = nil) or (LastInfo.StackPointer <> StackPointer) then
  begin
    CDeclCallInfoList := LastInfo;
    Assert(False);
  end;

  CDeclCallInfoList := LastInfo.Previous;
  Result := LastInfo.ReturnAddress;
  Dispose(LastInfo);
end;

{*
  V�rifie si une cha�ne de caract�res est un identificateur Pascal correct
  @param Ident   Cha�ne de caract�res � tester
  @return True si Ident est un identificateur Pascal correct, False sinon
*}
function CorrectIdentifier(const Ident: string): Boolean;
var
  I: Integer;
begin
  Result := False;

  // Si Ident est vide, ce n'est un indentificateur correct
  if Ident = '' then
    Exit;

  { Si le premier caract�re n'est pas alphab�tique,
    ce n'est pas un identificateur correct }
  if not (Ident[1] in ['A'..'Z', '_', 'a'..'z']) then
    Exit;

  { Si l'un des caract�res suivants n'est pas alphanum�rique,
    ce n'est pas un identificateur correct }
  for I := 2 to Length(Ident) do
    if not (Ident[I] in ['0'..'9', 'A'..'Z', '_', 'a'..'z']) then
      Exit;

  // Dans les autres cas, �a l'est
  Result := True;
end;

{*
  Positionne un bit � 1
  @param Value   Valeur � modifier
  @param Bit     Index du bit � modifier
  @author waskol
*}
procedure SetBit(var Value: Integer; const Bit: Byte); register;
asm
        BTS     [EAX],EDX
end;

{*
  Positionne un bit � 0
  @param Value   Valeur � modifier
  @param Bit     Index du bit � modifier
  @author waskol
*}
procedure ClearBit(var Value: Integer; const Bit: Byte); register;
asm
        BTR     [EAX],EDX
end;

{*
  Inverse un bit
  @param Value   Valeur � modifier
  @param Bit     Index du bit � modifier
  @author waskol
*}
procedure ToggleBit(var Value: Integer; const Bit: Byte); register;
asm
        BTC     [EAX],EDX
end;

{*
  Teste la valeur d'un bit
  @param Value   Valeur � tester
  @param Bit     Index du bit � tester
  @return True si le bit est � 1, False sinon
  @author waskol
*}
function TestBit(const Value: Integer; const Bit: Byte): Boolean; register;
asm
        BT      EAX,EDX
        SETB    AL
end;

{*
  Recherche une m�thode d'un objet � partir de son nom
  La m�thode en question doit �tre publi�e pour pouvoir �tre trouv�e.
  @param Obj          L'objet d�finissant la m�thode
  @param MethodName   Nom de la m�thode
  @return Une r�f�rence � la m�thode recherch�e pour l'objet Obj
*}
function GetMethodFromName(Obj: TObject;
  const MethodName: ShortString): TMethod;
begin
  Result.Code := Obj.MethodAddress(MethodName);
  Result.Data := Obj;
end;

{*
  Construit un record TMethod
  @param Code   Valeur du champ Code
  @param Data   Valeur du champ Data
  @return Un enregistrement TMethod avec les champs indiqu�s
*}
function MakeMethod(Code: Pointer; Data: Pointer = nil): TMethod;
begin
  Result.Code := Code;
  Result.Data := Data;
end;

{*
  Trouve le code d'une m�thode virtuelle, pour une classe
  @param AClass      Classe concern�e
  @param VMTOffset   VMT offset de la m�thode
  @return Pointeur sur le code de la m�thode
*}
function GetClassVirtualCode(AClass: TClass; VMTOffset: Integer): Pointer;
asm
        { ->    EAX     Pointer to class  }
        {       EDX     DMTIndex          }
        { <-    EAX     Pointer to method }
        MOV     EAX,[EAX+EDX]
end;

{*
  Trouve une m�thode virtuelle, pour une classe
  @param AClass      Classe concern�e
  @param VMTOffset   VMT offset de la m�thode
  @return M�thode correspondante
*}
function GetClassVirtualMethod(AClass: TClass; VMTOffset: Integer): TMethod;
begin
  Result.Data := AClass;
  Result.Code := GetClassVirtualCode(AClass, VMTOffset);
end;

{*
  Trouve le code d'une m�thode virtuelle, pour un objet
  @param AObject     Objet concern�
  @param VMTOffset   VMT offset de la m�thode
  @return Pointeur sur le code de la m�thode
*}
function GetObjectVirtualCode(AObject: TObject;
  VMTOffset: Integer): Pointer;
asm
        { ->    EAX     Pointer to object }
        {       EDX     DMTIndex          }
        { <-    EAX     Pointer to method }
        MOV     EAX,[EAX]
        MOV     EAX,[EAX+EDX]
end;

{*
  Trouve une virtuelle dynamique, pour un objet
  @param AObject     Objet concern�
  @param VMTOffset   VMT offset de la m�thode
  @return M�thode correspondante
*}
function GetObjectVirtualMethod(AObject: TObject;
  VMTOffset: Integer): TMethod;
begin
  Result.Data := AObject;
  Result.Code := GetObjectVirtualCode(AObject, VMTOffset);
end;

{*
  Trouve le code d'une m�thode dynamique, pour une classe
  @param AClass     Classe concern�e
  @param DMTIndex   DMT index de la m�thode
  @return Pointeur sur le code de la m�thode
  @throws EAbstractError La classe n'impl�mente pas la m�thode recherch�e
*}
function GetClassDynamicCode(AClass: TClass; DMTIndex: Integer): Pointer;
asm
        { ->    EAX     Pointer to class  }
        {       EDX     DMTIndex          }
        { <-    EAX     Pointer to method }
        CALL    System.@FindDynaClass
end;

{*
  Trouve une m�thode dynamique, pour une classe
  @param AClass     Classe concern�e
  @param DMTIndex   DMT index de la m�thode
  @return M�thode correspondante
  @throws EAbstractError La classe n'impl�mente pas la m�thode recherch�e
*}
function GetClassDynamicMethod(AClass: TClass; DMTIndex: Integer): TMethod;
begin
  Result.Data := AClass;
  Result.Code := GetClassDynamicCode(AClass, DMTIndex);
end;

{*
  Trouve le code d'une m�thode dynamique, pour un objet
  @param AObject    Objet concern�
  @param DMTIndex   DMT index de la m�thode
  @return Pointeur sur le code de la m�thode
  @throws EAbstractError La classe n'impl�mente pas la m�thode recherch�e
*}
function GetObjectDynamicCode(AObject: TObject; DMTIndex: Integer): Pointer;
asm
        { ->    EAX     Pointer to object }
        {       EDX     DMTIndex          }
        { <-    EAX     Pointer to method }
        MOV     EAX,[EAX]
        CALL    System.@FindDynaClass
end;

{*
  Trouve une m�thode dynamique, pour un objet
  @param AObject    Objet concern�
  @param DMTIndex   DMT index de la m�thode
  @return M�thode correspondante
  @throws EAbstractError La classe n'impl�mente pas la m�thode recherch�e
*}
function GetObjectDynamicMethod(AObject: TObject;
  DMTIndex: Integer): TMethod;
begin
  Result.Data := AObject;
  Result.Code := GetObjectDynamicCode(AObject, DMTIndex);
end;

{*
  D�termine la repr�sentation Pascal d'une cha�ne de caract�res
  Cette repr�sentation est la cha�ne encadr�e de guillemets simples ('), dont
  ces caract�res � l'int�rieur de la cha�ne sont doubl�s, et dont certains
  caract�res sp�ciaux sont �chapp�s au moyen de #.
  Cette cha�ne peut alors �tre par exemple ins�r�e dans un code Pascal.
  @param Str             Cha�ne � traiter
  @param ExcludedChars   Ensemble des caract�res qu'il faut �chapper
  @return Repr�sentation Pascal de Str
*}
function StrToStrRepres(const Str: string;
  ExcludedChars: TSysCharSet = []): string;
var
  I: Integer;
begin
  if Str = '' then
    Result := ''''''
  else
  begin
    I := 1;
    Result := '';
    ExcludedChars := ExcludedChars + [#0..#31];
    while I <= Length(Str) do
    begin
      if Str[I] in ExcludedChars then
      begin
        if I mod 256 = 0 then
          Result := Result+'+';

        Result := Result+'#'+IntToStr(Byte(Str[I]));
        Inc(I);
      end else
      begin
        Result := Result+'''';
        while (I <= Length(Str)) and (not (Str[I] in ExcludedChars)) do
        begin
          if I mod 256 = 0 then
            Result := Result+'''+''';

          if Str[I] = '''' then
            Result := Result + ''''''
          else
            Result := Result + Str[I];
          Inc(I);
        end;
        Result := Result+'''';
      end;
    end;
  end;
end;

{*
  D�termine une cha�ne � partir de sa repr�sentation Pascal
  Cette repr�sentation est la cha�ne encadr�e de guillemets simples ('), dont
  ces caract�res � l'int�rieur de la cha�ne sont doubl�s, et dont certains
  caract�res sp�ciaux sont �chapp�s au moyen de #.
  Cette cha�ne peut par exemple �tre extraite d'un code Pascal.
  @param Str   Cha�ne � traiter
  @return Cha�ne repr�sent�e par Str en Pascal
  @throws EConvertError Cha�ne de caract�re incorrecte
*}
function StrRepresToStr(Str: string): string;
var
  CharStr: string;
  I, IntChar: Integer;
begin
  Result := '';
  Str := Trim(Str);
  I := 1;
  repeat
    if I > 1 then
      Inc(I);

    while (I <= Length(Str)) and ((Str[I] = '''') or (Str[I] = '#')) do
    begin
      if Str[I] = '''' then
      begin
        Inc(I);
        while True do
        begin
          if I > Length(Str) then
            raise EConvertError.CreateFmt(sScWrongString, [Str]);
          if Str[I] = '''' then
          begin
            Inc(I);
            if (I <= Length(Str)) and (Str[I] = '''') then
            begin
              Result := Result+'''';
              Inc(I);
            end else
              Break;
          end else
          begin
            Result := Result+Str[I];
            Inc(I);
          end;
        end;
      end else
      begin
        Inc(I);
        if I > Length(Str) then
          raise EConvertError.CreateFmt(sScWrongString, [Str]);
        CharStr := '';
        while (I <= Length(Str)) and (Str[I] in ['0'..'9']) do
        begin
          CharStr := CharStr+Str[I];
          Inc(I);
        end;
        IntChar := StrToIntDef(CharStr, -1);
        if (IntChar >= 0) and (IntChar <= 255) then
          Result := Result+Char(IntChar)
        else
          raise EConvertError.CreateFmt(sScWrongString, [Str]);
      end;
    end;
  until (I > Length(Str)) or (Str[I] <> '+');
  if I <= Length(Str) then
    raise EConvertError.CreateFmt(sScWrongString, [Str]);
end;

{*
  D�termine la repr�sentation Pascal d'un caract�re
  @param Chr             Caract�re � traiter
  @param ExcludedChars   Ensemble des caract�res qu'il faut �chapper
  @return Repr�sentation Pascal de Chr
*}
function CharToCharRepres(Chr: Char;
  ExcludedChars: TSysCharSet = []): string;
begin
  ExcludedChars := ExcludedChars + [#0..#31];
  if Chr in ExcludedChars then
    Result := '#'+IntToStr(Byte(Chr))
  else if Chr = '''' then
    Result := ''''''''''
  else
    Result := ''''+Chr+'''';
end;

{*
  D�termine un caract�re � partir de sa repr�sentation Pascal
  @param Str   Cha�ne � traiter
  @return Caract�re repr�sent� par Str en Pascal
  @throws EConvertError Caract�re incorrect
*}
function CharRepresToChar(Str: string): Char;
begin
  try
    Str := Trim(Str);
    if Str = '' then
      raise EConvertError.Create('');
    case Str[1] of
      '#':
      begin
        // Le r�sultat est le caract�re dont le code ASCII est l'entier
        // sp�cifi� � la suite
        Delete(Str, 1, 1);
        Result := Chr(StrToInt(Str));
      end;
      '''':
      begin
        case Length(Str) of
          // Si 3 caract�res, le troisi�me doit �tre ' et le deuxi�me
          // est le caract�re r�sultat
          3: if Str[3] = '''' then
              Result := Str[2]
            else
              raise EConvertError.Create('');
          // Si 4 caract�res, ce doit �tre '''', auquel cas le caract�re
          // retour est '
          4: if Str = '''''''''' then
              Result := ''''
            else
              raise EConvertError.Create('');
        else
          // Sinon, ce n'est pas un caract�re correct
          raise EConvertError.Create('');
        end;
      end;
    else
      raise EConvertError.Create('');
    end;
  except
    on Error: EConvertError do
      raise EConvertError.CreateFmt(sSjrdWrongChar, [Str]);
  end;
end;

{*
  D�termine la repr�sentation Pascal d'un ensemble de caract�res (sans les [])
  @param CharSet   Ensemble de caract�res � traiter
  @return Repr�sentation Pascal de CharSet
*}
function CharSetToStr(const CharSet: TSysCharSet): string;
var
  I, From: Word;
begin
  Result := '';
  I := 0;
  // On cherche d'abord le premier caract�re inclus
  while (I <= 255) and (not (Chr(I) in CharSet)) do
    Inc(I);
  while I <= 255 do
  begin
    // Chr(I) est inclus
    From := I;
    // On cherche le caract�re suivant qui n'est pas inclus
    while (I <= 255) and (Chr(I) in CharSet) do
      Inc(I);
    // On teste I-From, soit le nombre de caract�re cons�cutifs
    case I-From of
      // 1 : on ajoute simplement ce caract�re
      1: Result := Result+', '+CharToCharRepres(Chr(From));
      // 2 : on ajoute ces deux caract�res s�par�s par des virgules
      2: Result := Result+', '+CharToCharRepres(Chr(From))+
          ', '+CharToCharRepres(Chr(I-1));
    else
      // 3+ : on ajoute les deux extr�mes s�par�s par ..
      Result := Result+', '+CharToCharRepres(Chr(From))+
        '..'+CharToCharRepres(Chr(I-1));
    end;
    // on cherche le caract�re suivant inclus
    repeat
      Inc(I);
    until (I > 255) or (Chr(I) in CharSet);
  end;
  // On supprime les deux premiers caract�res, car ce sont ', '
  Delete(Result, 1, 2);
end;

{*
  D�termine un ensemble de caract�res � partir de sa repr�sentation Pascal
  @param Str   Cha�ne � traiter
  @return Ensemble de caract�res repr�sent� par CharSet
  @throws EConvertError Ensemble de caract�res incorrect
*}
function StrToCharSet(Str: string): TSysCharSet;
var
  I: Integer;

  // Renvoie le caract�re � la position courante et augmente I en cons�quence
  // Fonctionne sur le m�me principe que CharRepresToChar
  function GetCharAt: Char;
  var
    From: Integer;
  begin
    case Str[I] of
      '#':
      begin
        From := I+1;
        repeat
          Inc(I);
        until (I > Length(Str)) or (not (Str[I] in ['0'..'9']));
        Result := Chr(StrToInt(Copy(Str, From, I-From)));
      end;
      '''':
      begin
        Inc(I);
        if I > Length(Str) then
          raise EConvertError.Create('');
        if Str[I] = '''' then
        begin
          if I+2 > Length(Str) then
            raise EConvertError.Create('');
          if (Str[I+1] <> '''') or (Str[I+2] <> '''') then
            raise EConvertError.Create('');
          Result := '''';
          Inc(I, 3);
        end else
        begin
          if I+1 > Length(Str) then
            raise EConvertError.Create('');
          if Str[I+1] <> '''' then
            raise EConvertError.Create('');
          Result := Str[I];
          Inc(I, 2);
        end;
      end;
    else
      raise EConvertError.Create('');
    end;
  end;

var
  C1, C2: Char;
begin
  try
    Result := [];
    Str := Trim(Str);
    // Si Str est vide, il n'y a aucun caract�re dans l'ensemble
    if Str = '' then
      Exit;
    // Si il y des [] aux extr�mit�s, on les supprime
    if (Str[1] = '[') and (Str[Length(Str)] = ']') then
      Str := Trim(Copy(Str, 2, Length(Str)-2));

    I := 1;
    while I <= Length(Str) do
    begin
      // On r�cup�re le caract�re � la position courante
      C1 := GetCharAt;
      // On passe tous les espaces
      while (I <= Length(Str)) and (Str[I] = ' ') do
        Inc(I);

      // Si I > Length(Str), on ajoute le caract�re et on arr�te
      if I > Length(Str) then
      begin
        Include(Result, C1);
        Break;
      end;

      // Si Str[I] = ',', on ajoute le caract�re et on passe la virgule
      if Str[I] = ',' then
      begin
        // On ajoute le caract�re
        Include(Result, C1);
        // On passe la virgule et les espaces
        repeat
          Inc(I);
        until (I > Length(Str)) or (Str[I] <> ' ');
        // Si on a atteint la fin de la cha�ne, il y a une erreur
        // (on termine par une virgule)
        if I > Length(Str) then
          raise EConvertError.Create('');
        Continue;
      end;

      // Si Str[I] = '.', ce doit �tre une plage de caract�res
      if Str[I] = '.' then
      begin
        // On teste si le caract�re suivant est aussi un point
        Inc(I);
        if (I > Length(Str)) or (Str[I] <> '.') then
          raise EConvertError.Create('');
        // On passe ce point et les espaces
        repeat
          Inc(I);
        until (I > Length(Str)) or (Str[I] <> ' ');
        // On r�cup�re le deuxi�me caract�re
        C2 := GetCharAt;
        // On passe les espaces
        while (I <= Length(Str)) and (Str[I] = ' ') do
          Inc(I);

        // Si I > Length(Str), on ajoute la plage de caract�re et on termine
        if I > Length(Str) then
        begin
          Result := Result+[C1..C2];
          Break;
        end;

        // Si Str[I] = ',', on ajoute les caract�res et on passe la virgule
        if Str[I] = ',' then
        begin
          // On ajoute la plage de caract�res
          Result := Result+[C1..C2];
          // On passe la virgule et les espaces
          repeat
            Inc(I);
          until (I > Length(Str)) or (Str[I] <> ' ');
          // Si on a atteint la fin de la cha�ne, il y a une erreur
          // (on termine par une virgule)
          if I > Length(Str) then
            raise EConvertError.Create('');
          Continue;
        end;
        raise EConvertError.Create('');
      end;
      raise EConvertError.Create('');
    end;
  except
    on Error: EConvertError do
      raise EConvertError.CreateFmt(sScWrongCharSet, [Str]);
  end;
end;

{*
  Convertit un type ensemble d'�l�ments d'�num�ration en cha�ne
  La repr�sentation est celle du langage Pascal, sans les [].
  Cette routine fonctionne �galement pour les ensembles d'entiers.
  @param EnumSet    Ensemble � convertir
  @param TypeInfo   RTTI du type ensemble ou du type �num�ration
  @return Cha�ne repr�sentant l'ensemble EnumSet
*}
function EnumSetToStr(const EnumSet; TypeInfo: PTypeInfo): string;
var
  TypeData: PTypeData;
  ByteValue: Byte;
begin
  if TypeInfo.Kind = tkSet then
    TypeInfo := GetTypeData(TypeInfo).CompType^;
  TypeData := GetTypeData(TypeInfo);

  Result := '';

  for ByteValue := TypeData.MinValue to TypeData.MaxValue do
  begin
    if ByteValue in TSysByteSet(EnumSet) then
      Result := Result + GetEnumName(TypeInfo, ByteValue) + ', ';
  end;

  if Result <> '' then
    SetLength(Result, Length(Result)-2);
end;

{*
  Convertit une cha�ne en type ensemble d'�l�ments d'�num�ration
  La repr�sentation est celle du langage Pascal, avec ou sans les [].
  Cette routine fonctionne �galement pour les ensembles d'entiers.
  @param Str        Cha�ne � convertir
  @param TypeInfo   RTTI du type ensemble ou du type �num�ration
  @param EnumSet    Ensemble converti en sortie
  @return Cha�ne repr�sentant l'ensemble EnumSet
*}
procedure StrToEnumSet(const Str: string; TypeInfo: PTypeInfo; out EnumSet);
type
  TSetAsBytes = array[0..31] of Byte;
var
  SetName: string;
  TypeData: PTypeData;
  SetStr: string;
  Index, Len, BeginIndex, Value: Integer;
begin
  if TypeInfo.Kind = tkSet then
  begin
    SetName := TypeInfo.Name;
    TypeInfo := GetTypeData(TypeInfo).CompType^;
  end else
    SetName := Format(sScSetOf, [TypeInfo.Name]);
  TypeData := GetTypeData(TypeInfo);

  Len := TypeData.MaxValue div 8 + 1;
  FillChar(EnumSet, Len, 0);

  try
    Index := 1;
    Len := Length(Str);
    if (Str <> '') and (Str[1] = '[') and (Str[Len] = ']') then
    begin
      SetStr := ',' + Copy(Str, 2, Len-2);
      Dec(Len, 1);
    end else
    begin
      SetStr := ',' + Str;
      Inc(Len, 1);
    end;

    while Index <= Len do
    begin
      if SetStr[Index] <> ',' then
        raise Exception.Create('');
      Inc(Index);

      while (Index <= Len) and (SetStr[Index] in [' ', #13, #10]) do
        Inc(Index);
      BeginIndex := Index;
      while (Index <= Len) and (not (SetStr[Index] in [',', ' ', #13, #10])) do
        Inc(Index);

      Value := GetEnumValue(TypeInfo,
        Copy(SetStr, BeginIndex, Index-BeginIndex));
      if Value < 0 then
        raise Exception.Create('');
      Include(TSysByteSet(EnumSet), Value);

      while (Index <= Len) and (SetStr[Index] in [' ', #13, #10]) do
        Inc(Index);
    end;
  except
    raise EConvertError.CreateFmt(sScWrongEnumSet, [Str, SetName]);
  end;
end;

{*
  Renvoie un pointeur vers le champ suivant un ShortString compact�e (des RTTI)
  Cette routine peut �tre utilis�e pour passer � au-dessus � d'une ShortString
  compact�e, telle qu'on peut en trouver dans les record extra-compact�s des
  RTTI.
  @param Value    Adresse de la ShortString compact�e
  @return Adresse du champ suivant
*}
function SkipPackedShortString(Value: PShortstring): Pointer;
asm
        { ->    EAX Pointer to a packed ShortString                   }
        { <-    EAX Pointer to data following this packed ShortString }
        XOR     EDX,EDX
        MOV     DL,[EAX]
        LEA     EAX,[EAX].Byte[EDX+1]
end;

{*
  Calcule l'argument d'une instruction JMP ou CALL
  @param JmpAddress   Adresse de l'instruction JMP
  @param JmpDest      Destination du JMP
  @return Argument � donner au JMP
*}
function JmpArgument(JmpAddress, JmpDest: Pointer): Integer;
asm
        { -> EAX Address of the jump instruction }
        { -> EDX Pointer to destination          }
        { -> Return value = EDX - EAX - 5        }

        NEG     EAX
        ADD     EAX,EDX
        SUB     EAX,5
end;

{*
  Construit une instruction JMP
  @param Instruction   Instruction (minimum 5 octets)
  @param Dest          Destination du JMP
*}
procedure MakeJmp(var Instruction; Dest: Pointer);
asm
        { -> EAX Pointer to a TJmpInstruction record }
        { -> EDX Pointer to destination              }

        MOV     BYTE PTR [EAX],$E9
        SUB     EDX,EAX
        SUB     EDX,5
        MOV     [EAX+1],EDX
end;

{*
  Construit une instruction CALL
  @param Instruction   Instruction (minimum 5 octets)
  @param Dest          Destination du CALL
*}
procedure MakeCall(var Instruction; Dest: Pointer);
asm
        { -> EAX Pointer to a TJmpInstruction record }
        { -> EDX Pointer to destination              }

        MOV     BYTE PTR [EAX],$E8
        SUB     EDX,EAX
        SUB     EDX,5
        MOV     [EAX+1],EDX
end;

{*
  Construit une routine �quivalente � une m�thode register, version courte
  @param Method           M�thode � convertir
  @param UsedRegCount     Nombre de registres utilis�s dans l'appel de proc�dure
  @param MoveStackCount   Nombre de cases de pile empil�es apr�s ECX
  @return Pointeur vers le code de la proc�dure cr��e
*}
function MakeShortProcOfRegisterMethod(const Method: TMethod;
  UsedRegCount: Byte; MoveStackCount: Word): Pointer;

const
  MoveStackItem: LongWord = $00244C87; // 874C24 xx   XCHG ECX,[ESP+xx]
  MoveRegisters: array[0..7] of Byte = (
    $87, $0C, $24, // XCHG    ECX,[ESP]
    $51,           // PUSH    ECX
    $8B, $CA,      // MOV     ECX,EDX
    $8B, $D0       // MOV     EDX,EAX
  );

type
  PRegisterRedirector = ^TRegisterRedirector;
  TRegisterRedirector = packed record
    MovEAXObj: Byte;
    ObjAddress: Pointer;
    Jump: TJmpInstruction;
  end;

var
  MoveStackSize: Integer;
  MoveRegSize: Integer;
  InstrPtr: Pointer;
  I: Cardinal;
begin
  if UsedRegCount >= 3 then
    UsedRegCount := 4;
  MoveRegSize := 2*UsedRegCount;
  MoveStackSize := 4*MoveStackCount;

  GetMem(Result, MoveStackSize + MoveRegSize + SizeOf(TRegisterRedirector));
  InstrPtr := Result;

  for I := MoveStackCount downto 1 do
  begin
    // I shl 26 => I*4 in the most significant byte (kind of $ I*4 00 00 00)
    PLongWord(InstrPtr)^ := (I shl 26) or MoveStackItem;
    Inc(Integer(InstrPtr), 4);
  end;

  Move(MoveRegisters[SizeOf(MoveRegisters) - MoveRegSize],
    InstrPtr^, MoveRegSize);
  Inc(Integer(InstrPtr), MoveRegSize);

  with PRegisterRedirector(InstrPtr)^ do
  begin
    MovEAXObj := $B8;
    ObjAddress := Method.Data;
    MakeJmp(Jump, Method.Code);
  end;
end;

{*
  Construit une routine �quivalente � une m�thode register, version longue
  @param Method           M�thode � convertir
  @param MoveStackCount   Nombre de cases de pile empil�es apr�s ECX
  @return Pointeur vers le code de la proc�dure cr��e
*}
function MakeLongProcOfRegisterMethod(const Method: TMethod;
  MoveStackCount: Word): Pointer;

type
  PRegisterRedirector = ^TRegisterRedirector;
  TRegisterRedirector = packed record
    Reserved1: array[0..8] of Byte;
    MoveStackCount4: LongWord;
    Reserved2: array[13..20] of Byte;
    FourMoveStackCount1: LongWord;
    Reserved3: array[25..29] of Byte;
    ObjAddress: Pointer;
    Jump: TJmpInstruction;
  end;

const
  Code: array[0..SizeOf(TRegisterRedirector)-1] of Byte = (
    $56,                     // PUSH    ESI
    $57,                     // PUSH    EDI
    $51,                     // PUSH    ECX

    $8B, $F4,                // MOV     ESI,ESP
    $51,                     // PUSH    ECX
    $8B, $FC,                // MOV     EDI,ESP
    $B9, $FF, $FF, $FF, $FF, // MOV     ECX,MoveStackCount+4

    $F3, $A5,                // REP     MOVSD

    $59,                     // POP     ECX
    $5F,                     // POP     EDI
    $5E,                     // POP     ESI

    $89, $8C, $24, $EE, $EE, $EE, $EE,
    // MOV     [ESP + 4*(MoveStackCount+1)],ECX
    $8B, $CA,                // MOV     ECX,EDX
    $8B, $D0,                // MOV     EDX,EAX
    $B8, $DD, $DD, $DD, $DD, // MOV     EAX,0
    $E9, $CC, $CC, $CC, $CC  // JMP     MethodAddress
  );

begin
  GetMem(Result, SizeOf(Code));
  Move(Code[0], Result^, SizeOf(Code));

  with PRegisterRedirector(Result)^ do
  begin
    MoveStackCount4 := MoveStackCount+4;
    FourMoveStackCount1 := 4 * (MoveStackCount+1);
    ObjAddress := Method.Data;
    MakeJmp(Jump, Method.Code);
  end;
end;

{*
  Construit une routine �quivalente � une m�thode register
  MakeProcOfMethod permet d'obtenir un pointeur sur une routine, construite
  dynamiquement, qui �quivaut � une m�thode. Ce qui signifie que la routine
  renvoy�e commence par ajouter un param�tre suppl�mentaire, avant d'appeler
  la m�thode initiale.
  La proc�dure devra �tre lib�r�e avec FreeProcOfMethod une fois utilis�e.
  Vous devez d�terminer UsedRegCount et MoveStackCount d'apr�s la d�lcaration de
  la *proc�dure*. UsedRegCount est le nombre de registres utilis�s pour la
  transmission des param�tres (dans l'ordre EAX, EDX et ECX). Si les trois sont
  utilis�s, le param�tre MoveStackCount doit renseigner le nombre de "cases" de
  pile (de doubles mots) utilis�s par les param�tres d�clar�s *apr�s* le
  param�tre transmis dans ECX.
  @param Method           M�thode � convertir
  @param UsedRegCount     Nombre de registres utilis�s dans l'appel de proc�dure
  @param MoveStackCount   Nombre de cases de pile empil�es apr�s ECX
  @return Pointeur vers le code de la proc�dure cr��e
*}
function MakeProcOfRegisterMethod(const Method: TMethod;
  UsedRegCount: Byte; MoveStackCount: Word = 0): Pointer;
begin
  Assert((MoveStackCount = 0) or (UsedRegCount >= 3));

  if MoveStackCount <= 8 then
    Result := MakeShortProcOfRegisterMethod(
      Method, UsedRegCount, MoveStackCount)
  else
    Result := MakeLongProcOfRegisterMethod(Method, MoveStackCount);
end;

{*
  Construit une routine �quivalente � une m�thode stdcall
  MakeProcOfMethod permet d'obtenir un pointeur sur une routine, construite
  dynamiquement, qui �quivaut � une m�thode. Ce qui signifie que la routine
  renvoy�e commence par ajouter un param�tre suppl�mentaire, avant d'appeler
  la m�thode initiale.
  La proc�dure devra �tre lib�r�e avec FreeProcOfMethod une fois utilis�e.
  @param Method   M�thode � convertir
  @return Pointeur vers le code de la proc�dure cr��e
*}
function MakeProcOfStdCallMethod(const Method: TMethod): Pointer;
type
  PStdCallRedirector = ^TStdCallRedirector;
  TStdCallRedirector = packed record
    PopEAX: Byte;
    PushObj: Byte;
    ObjAddress: Pointer;
    PushEAX: Byte;
    Jump: TJmpInstruction;
  end;
begin
  GetMem(Result, SizeOf(TStdCallRedirector));
  with PStdCallRedirector(Result)^ do
  begin
    PopEAX := $58;
    PushObj := $68;
    ObjAddress := Method.Data;
    PushEAX := $50;
    MakeJmp(Jump, Method.Code);
  end;
end;

{*
  Construit une routine �quivalente � une m�thode pascal
  MakeProcOfMethod permet d'obtenir un pointeur sur une routine, construite
  dynamiquement, qui �quivaut � une m�thode. Ce qui signifie que la routine
  renvoy�e commence par ajouter un param�tre suppl�mentaire, avant d'appeler
  la m�thode initiale.
  La proc�dure devra �tre lib�r�e avec FreeProcOfMethod une fois utilis�e.
  @param Method   M�thode � convertir
  @return Pointeur vers le code de la proc�dure cr��e
*}
function MakeProcOfPascalMethod(const Method: TMethod): Pointer;
begin
  Result := MakeProcOfStdCallMethod(Method);
end;

{*
  Construit une routine �quivalente � une m�thode cdecl
  MakeProcOfMethod permet d'obtenir un pointeur sur une routine, construite
  dynamiquement, qui �quivaut � une m�thode. Ce qui signifie que la routine
  renvoy�e commence par ajouter un param�tre suppl�mentaire, avant d'appeler
  la m�thode initiale.
  La proc�dure devra �tre lib�r�e avec FreeProcOfMethod une fois utilis�e.
  @param Method   M�thode � convertir
  @return Pointeur vers le code de la proc�dure cr��e
*}
function MakeProcOfCDeclMethod(const Method: TMethod): Pointer;

type
  PCDeclRedirector = ^TCDeclRedirector;
  TCDeclRedirector = packed record
    PushESP: Byte;
    CallStoreAddress: TJmpInstruction;
    PushObj: Byte;
    ObjAddress: Pointer;
    CallMethod: TJmpInstruction;
    MovESPEAX: array[0..2] of Byte;
    MovEAXESP: array[0..1] of Byte;
    PushEDX: Byte;
    CallGetAddress: TJmpInstruction;
    PopEDX: Byte;
    Xchg: array[0..2] of Byte;
    Ret: Byte;
  end;

const
  Code: array[0..SizeOf(TCDeclRedirector)-1] of Byte = (
    $54,                     // PUSH    ESP
    $E8, $FF, $FF, $FF, $FF, // CALL    StoreCDeclReturnAddress
    $68, $EE, $EE, $EE, $EE, // PUSH    ObjAddress
    $E8, $DD, $DD, $DD, $DD, // CALL    MethodCode
    $89, $04, $24,           // MOV     [ESP],EAX
    $8B, $C4,                // MOV     EAX,ESP
    $52,                     // PUSH    EDX
    $E8, $CC, $CC, $CC, $CC, // CALL    GetCDeclReturnAddress
    $5A,                     // POP     EDX
    $87, $04, $24,           // XCHG    EAX,[ESP]
    $C3                      // RET
  );

begin
  GetMem(Result, SizeOf(Code));
  Move(Code[0], Result^, SizeOf(Code));

  with PCDeclRedirector(Result)^ do
  begin
    MakeCall(CallStoreAddress, @StoreCDeclReturnAddress);
    ObjAddress := Method.Data;
    MakeCall(CallMethod, Method.Code);
    MakeCall(CallGetAddress, @GetCDeclReturnAddress);
  end;
end;

{*
  Lib�re une routine construite avec une des MakeProcOfMethod
  @param Proc   Routine � lib�rer
*}
procedure FreeProcOfMethod(Proc: Pointer);
begin
  FreeMem(Proc);
end;

initialization
finalization
  ClearCDeclCallInfo;
end.

