{*
  D�finit quelques routines d'utilisation plus rare ou avanc�e
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit ScDelphiLanguage;

interface

uses
  SysUtils, TypInfo, ScUtils;

function CorrectIdentifier(const Ident : string) : boolean;

procedure SetBit(var Value : integer; const Bit : Byte); register;
procedure ClearBit(var Value : integer; const Bit : Byte); register;
procedure ToggleBit(var Value : integer; const Bit : Byte); register;
function TestBit(const Value : integer; const Bit : Byte) : boolean; register;

function GetMethodFromName(Obj : TObject;
  const MethodName : ShortString) : TMethod;

function StrToStrRepres(const Str : string;
  ExcludedChars : TSysCharSet = []) : string;
function StrRepresToStr(Str : string) : string;

function CharToCharRepres(Chr : Char;
  ExcludedChars : TSysCharSet = []) : string;
function CharRepresToChar(Str : string) : Char;

function CharSetToStr(const CharSet : TSysCharSet) : string;
function StrToCharSet(Str : string) : TSysCharSet;

function EnumSetToStr(const EnumSet; TypeInfo : PTypeInfo) : string;
procedure StrToEnumSet(const Str : string; TypeInfo : PTypeInfo; out EnumSet);

procedure ExplicitInitialize(var Value; TypeInfo : PTypeInfo;
  Count : Cardinal = 1);
procedure ExplicitFinalize(var Value; TypeInfo : PTypeInfo;
  Count : Cardinal = 1);

function SkipPackedShortString(Value : PShortstring) : Pointer;

implementation

uses
  ScConsts;

{*
  V�rifie si une cha�ne de caract�res est un identificateur Pascal correct
  @param Ident   Cha�ne de caract�res � tester
  @return True si Ident est un identificateur Pascal correct, False sinon
*}
function CorrectIdentifier(const Ident : string) : boolean;
var I : integer;
begin
  Result := False;

  // Si Ident est vide, ce n'est un indentificateur correct
  if Ident = '' then exit;

  { Si le premier caract�re n'est pas alphab�tique,
    ce n'est pas un identificateur correct }
  if not (Ident[1] in ['A'..'Z', '_', 'a'..'z']) then exit;

  { Si l'un des caract�res suivants n'est pas alphanum�rique,
    ce n'est pas un identificateur correct }
  for I := 2 to Length(Ident) do
    if not (Ident[I] in ['0'..'9', 'A'..'Z', '_', 'a'..'z']) then exit;

  // Dans les autres cas, �a l'est
  Result := True;
end;

{*
  Positionne un bit � 1
  @param Value   Valeur � modifier
  @param Bit     Index du bit � modifier
  @author waskol
*}
procedure SetBit(var Value : integer; const Bit : Byte); register;
asm
        BTS     [EAX],EDX
end;

{*
  Positionne un bit � 0
  @param Value   Valeur � modifier
  @param Bit     Index du bit � modifier
  @author waskol
*}
procedure ClearBit(var Value : integer; const Bit : Byte); register;
asm
        BTR     [EAX],EDX
end;

{*
  Inverse un bit
  @param Value   Valeur � modifier
  @param Bit     Index du bit � modifier
  @author waskol
*}
procedure ToggleBit(var Value : integer; const Bit : Byte); register;
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
function TestBit(const Value : integer; const Bit : Byte) : boolean; register;
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
function GetMethodFromName(Obj : TObject;
  const MethodName : ShortString) : TMethod;
begin
  Result.Code := Obj.MethodAddress(MethodName);
  Result.Data := Obj;
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
function StrToStrRepres(const Str : string;
  ExcludedChars : TSysCharSet = []) : string;
var I : integer;
begin
  if Str = '' then Result := '''''' else
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
        inc(I);
      end else
      begin
        Result := Result+'''';
        while (I <= Length(Str)) and (not (Str[I] in ExcludedChars)) do
        begin
          if I mod 256 = 0 then
            Result := Result+'''+''';

          if Str[I] = '''' then Result := Result + '''''' else
            Result := Result + Str[I];
          inc(I);
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
  @raise EConvertError Cha�ne de caract�re incorrecte
*}
function StrRepresToStr(Str : string) : string;
var CharStr : string;
    I, IntChar : integer;
begin
  Result := '';
  Str := Trim(Str);
  I := 1;
  repeat
    if I > 1 then inc(I);
    
    while (I <= Length(Str)) and ((Str[I] = '''') or (Str[I] = '#')) do
    begin
      if Str[I] = '''' then
      begin
        inc(I);
        while True do
        begin
          if I > Length(Str) then
            raise EConvertError.CreateFmt(sScWrongString, [Str]);
          if Str[I] = '''' then
          begin
            inc(I);
            if (I <= Length(Str)) and (Str[I] = '''') then
            begin
              Result := Result+'''';
              inc(I);
            end else Break;
          end else
          begin
            Result := Result+Str[I];
            inc(I);
          end;
        end;
      end else
      begin
        inc(I);
        if I > Length(Str) then
          raise EConvertError.CreateFmt(sScWrongString, [Str]);
        CharStr := '';
        while (I <= Length(Str)) and (Str[I] in ['0'..'9']) do
        begin
          CharStr := CharStr+Str[I];
          inc(I);
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
function CharToCharRepres(Chr : Char;
  ExcludedChars : TSysCharSet = []) : string;
begin
  ExcludedChars := ExcludedChars + [#0..#31];
  if Chr in ExcludedChars then Result := '#'+IntToStr(Byte(Chr)) else
  if Chr = '''' then Result := '''''''''' else
  Result := ''''+Chr+'''';
end;

{*
  D�termine un caract�re � partir de sa repr�sentation Pascal
  @param Str   Cha�ne � traiter
  @return Caract�re repr�sent� par Str en Pascal
  @raise EConvertError Caract�re incorrect
*}
function CharRepresToChar(Str : string) : Char;
begin
  try
    Str := Trim(Str);
    if Str = '' then raise EConvertError.Create('');
    case Str[1] of
      '#' :
      begin
        // Le r�sultat est le caract�re dont le code ASCII est l'entier
        // sp�cifi� � la suite
        Delete(Str, 1, 1);
        Result := Chr(StrToInt(Str));
      end;
      '''' :
      begin
        case Length(Str) of
          // Si 3 caract�res, le troisi�me doit �tre ' et le deuxi�me
          // est le caract�re r�sultat
          3 : if Str[3] = '''' then Result := Str[2] else
            raise EConvertError.Create('');
          // Si 4 caract�res, ce doit �tre '''', auquel cas le caract�re
          // retour est '
          4 : if Str = '''''''''' then Result := '''' else
            raise EConvertError.Create('');
          // Sinon, ce n'est pas un caract�re correct
          else raise EConvertError.Create('');
        end;
      end;
      else raise EConvertError.Create('');
    end;
  except
    on Error : EConvertError do
      raise EConvertError.CreateFmt(sSjrdWrongChar, [Str]);
  end;
end;

{*
  D�termine la repr�sentation Pascal d'un ensemble de caract�res (sans les [])
  @param CharSet   Ensemble de caract�res � traiter
  @return Repr�sentation Pascal de CharSet
*}
function CharSetToStr(const CharSet : TSysCharSet) : string;
var I, From : Word;
begin
  Result := '';
  I := 0;
  // On cherche d'abord le premier caract�re inclus
  while (I <= 255) and (not (Chr(I) in CharSet)) do inc(I);
  while I <= 255 do
  begin
    // Chr(I) est inclus
    From := I;
    // On cherche le caract�re suivant qui n'est pas inclus
    while (I <= 255) and (Chr(I) in CharSet) do inc(I);
    // On teste I-From, soit le nombre de caract�re cons�cutifs
    case I-From of
      // 1 : on ajoute simplement ce caract�re
      1 : Result := Result+', '+CharToCharRepres(Chr(From));
      // 2 : on ajoute ces deux caract�res s�par�s par des virgules
      2 : Result := Result+', '+CharToCharRepres(Chr(From))+
        ', '+CharToCharRepres(Chr(I-1));
      // 3+ : on ajoute les deux extr�mes s�par�s par ..
      else Result := Result+', '+CharToCharRepres(Chr(From))+
        '..'+CharToCharRepres(Chr(I-1));
    end;
    // on cherche le caract�re suivant inclus
    repeat inc(I) until (I > 255) or (Chr(I) in CharSet);
  end;
  // On supprime les deux premiers caract�res, car ce sont ', '
  Delete(Result, 1, 2);
end;

{*
  D�termine un ensemble de caract�res � partir de sa repr�sentation Pascal
  @param Str   Cha�ne � traiter
  @return Ensemble de caract�res repr�sent� par CharSet
  @raise EConvertError Ensemble de caract�res incorrect
*}
function StrToCharSet(Str : string) : TSysCharSet;
var I : integer;
  function GetCharAt : Char;
  // Renvoie le caract�re � la position courante et augmente I en cons�quence
  // Fonctionne sur le m�me principe que CharRepresToChar
  var From : integer;
  begin
    case Str[I] of
      '#' :
      begin
        From := I+1;
        repeat inc(I) until (I > Length(Str)) or (not (Str[I] in ['0'..'9']));
        Result := Chr(StrToInt(Copy(Str, From, I-From)));
      end;
      '''' :
      begin
        inc(I);
        if I > Length(Str) then
          raise EConvertError.Create('');
        if Str[I] = '''' then
        begin
          if I+2 > Length(Str) then
            raise EConvertError.Create('');
          if (Str[I+1] <> '''') or (Str[I+2] <> '''') then
            raise EConvertError.Create('');
          Result := '''';
          inc(I, 3);
        end else
        begin
          if I+1 > Length(Str) then
            raise EConvertError.Create('');
          if Str[I+1] <> '''' then
            raise EConvertError.Create('');
          Result := Str[I];
          inc(I, 2);
        end;
      end;
      else raise EConvertError.Create('');
    end;
  end;
var C1, C2 : Char;
begin
  try
    Result := [];
    Str := Trim(Str);
    // Si Str est vide, il n'y a aucun caract�re dans l'ensemble
    if Str = '' then exit;
    // Si il y des [] aux extr�mit�s, on les supprime
    if (Str[1] = '[') and (Str[Length(Str)] = ']') then
      Str := Trim(Copy(Str, 2, Length(Str)-2));

    I := 1;
    while I <= Length(Str) do
    begin
      // On r�cup�re le caract�re � la position courante
      C1 := GetCharAt;
      // On passe tous les espaces
      while (I <= Length(Str)) and (Str[I] = ' ') do inc(I);

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
        repeat inc(I) until (I > Length(Str)) or (Str[I] <> ' ');
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
        inc(I);
        if (I > Length(Str)) or (Str[I] <> '.') then
          raise EConvertError.Create('');
        // On passe ce point et les espaces
        repeat inc(I) until (I > Length(Str)) or (Str[I] <> ' ');
        // On r�cup�re le deuxi�me caract�re
        C2 := GetCharAt;
        // On passe les espaces
        while (I <= Length(Str)) and (Str[I] = ' ') do inc(I);

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
          repeat inc(I) until (I > Length(Str)) or (Str[I] <> ' ');
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
    on Error : EConvertError do
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
function EnumSetToStr(const EnumSet; TypeInfo : PTypeInfo) : string;
var TypeData : PTypeData;
    ByteValue : Byte;
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
procedure StrToEnumSet(const Str : string; TypeInfo : PTypeInfo; out EnumSet);
type
  TSetAsBytes = array[0..31] of Byte;
var SetName : string;
    TypeData : PTypeData;
    SetStr : string;
    Index, Len, BeginIndex, Value : integer;
begin
  if TypeInfo.Kind = tkSet then
  begin
    SetName := TypeInfo.Name;
    TypeInfo := GetTypeData(TypeInfo).CompType^;
  end else SetName := Format(sScSetOf, [TypeInfo.Name]);
  TypeData := GetTypeData(TypeInfo);

  Len := TypeData.MaxValue div 8 + 1;
  FillChar(EnumSet, Len, 0);

  try
    Index := 1;
    Len := Length(Str);
    if (Str <> '') and (Str[1] = '[') and (Str[Len] = ']') then
    begin
      SetStr := ',' + Copy(Str, 2, Len-2);
      dec(Len, 1);
    end else
    begin
      SetStr := ',' + Str;
      inc(Len, 1);
    end;

    while Index <= Len do
    begin
      if SetStr[Index] <> ',' then
        raise Exception.Create('');
      inc(Index);

      while (Index <= Len) and (SetStr[Index] in [' ', #13, #10]) do
        inc(Index);
      BeginIndex := Index;
      while (Index <= Len) and (not (SetStr[Index] in [',', ' ', #13, #10])) do
        inc(Index);

      Value := GetEnumValue(TypeInfo,
        Copy(SetStr, BeginIndex, Index-BeginIndex));
      if Value < 0 then
        raise Exception.Create('');
      Include(TSysByteSet(EnumSet), Value);

      while (Index <= Len) and (SetStr[Index] in [' ', #13, #10]) do inc(Index);
    end;
  except
    raise EConvertError.CreateFmt(sScWrongEnumSet, [Str, SetName]);
  end;
end;

{*
  Initialise une variable
  Cette routine n'est rien de plus qu'un moyen d'appeler explicitement la
  routine cach�e _InitializeArray de l'unit� System.
  @param Value      Variable � initialiser
  @param TypeInfo   RTTI du type de la variable
  @param Count      Nombre d'�l�ments dans la variable
*}
procedure ExplicitInitialize(var Value; TypeInfo : PTypeInfo;
  Count : Cardinal = 1);
asm
        JMP     System.@InitializeArray
end;

{*
  Finalise une variable
  Cette routine n'est rien de plus qu'un moyen d'appeler explicitement la
  routine cach�e _FinalizeArray de l'unit� System.
  @param Value      Variable � finaliser
  @param TypeInfo   RTTI du type de la variable
  @param Count      Nombre d'�l�ments dans la variable
*}
procedure ExplicitFinalize(var Value; TypeInfo : PTypeInfo;
  Count : Cardinal = 1);
asm
        JMP     System.@FinalizeArray
end;

{*
  Renvoie un pointeur vers le champ suivant un ShortString compact�e (des RTTI)
  Cette routine peut �tre utilis�e pour passer � au-dessus � d'une ShortString
  compact�e, telle qu'on peut en trouver dans les record extra-compact�s des
  RTTI.
  @param Value    Adresse de la ShortString compact�e
  @return Adresse du champ suivant
*}
function SkipPackedShortString(Value : PShortstring) : Pointer;
asm
        { ->    EAX Pointer to type info }
        { <-    EAX Pointer to type data }
        XOR     EDX,EDX
        MOV     DL,[EAX]
        LEA     EAX,[EAX].Byte[EDX+1]
end;

end.

