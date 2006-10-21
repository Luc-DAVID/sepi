{*
  D�finit quelques routines d'utilisation plus ou avanc�e
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit ScExtra;

interface

uses
{$IFDEF MSWINDOWS}
  Windows, ComObj, ShlObj, ActiveX,
{$ENDIF}
  SysUtils, Classes, ZLib, ScUtils, ScConsts;

type
  EUpdateResError = class(EAPIError) end platform;

  {$IFDEF MSWINDOWS}
  TSoundType = (stFileName, stResource, stSysSound);
  {$ENDIF}

function CorrectIdentifier(const Ident : string) : boolean;
// V�rifie si Ident est un identificateur Delphi correct

function IntToBase(Value : integer; Base : Byte = 10) : string;
// Convertit une valeur enti�re en sa repr�sentation cha�ne
function BaseToInt(const Value : string; Base : Byte = 10) : integer;
// Convertit une cha�ne en l'entier qu'elle repr�sente
function BaseToIntDef(const Value : string; Default : integer = 0; Base : Byte = 10) : integer;
// Comme SjrdStrToInt mais renvoie une valeur par d�faut en cas d'�chec

function GetMethodFromName(Obj : TObject; MethodName : ShortString) : TMethod;
// Renvoie l'adresse de la m�thode de nom NomMethode de l'objet Objet

function ConvertDoubleToInt64(Value : Double) : Int64;
// Convertit une valeur Double en la valeur Int64 ayant les m�mes bits
// Attention ! Il n'y a aucune correspondance entre Value et Result
//             Cette fonction est totalement empirique

function ConvertInt64ToDouble(Value : Int64) : Double;
// Convertit une valeur Int64 en la valeur Double ayant les m�mes bits
// Attention ! Il n'y a aucune correspondance entre Value et Result
//             Cette fonction est totalement empirique

function StrToStrRepres(const Str : string; ExcludedChars : TSysCharSet = []) : string;
// Renvoie la repr�sentation de Str en Pascal
// (si Str = �C'est No�l !�, renvoie �'C''est No�l !'�)

function StrRepresToStr(Str : string) : string;
// Renvoie la cha�ne repr�sent�e en Pascal par Str
// (si Str = �'A qui l''tour ?'�, renvoie �A qui l'tour ?�)

function CharToCharRepres(Charact : Char) : string;
// Renvoie la repr�sentation de Charact en Pascal
// (si Charact = �A�, renvoie �'A'� ; si Charact = Tab, renvoie �#9�)

function CharRepresToChar(Str : string) : Char;
// Renvoie le caract�re repr�sent� en Pascal par Str
// (si Str = �'A'�, renvoie �A� ; si Str = �#10�, renvoie LineFeed)

function CharSetToStr(SetOfChars : TSysCharSet) : string;
// Renvoie la cha�ne repr�sentant l'ensemble SetOfChars (sans les [])

function StrToCharSet(Str : string) : TSysCharSet;
// Renvoie l'ensemble de caract�res repr�sent� par Str (Str avec ou sans les [])

{$IFDEF MSWINDOWS}
procedure CreateShellLink(const Source, Dest : string;
                          const Description : string = '';
                          const IconLocation : string = '';
                          IconIndex : integer = 0;
                          const Arguments : string = '';
                          const WorkDir : string = '';
                          ShowCommand : integer = SW_SHOW); platform;
// Cr�e un raccourci avec les informations indiqu�es
{$ENDIF}

{$IFDEF MSWINDOWS}
function ExecuteSound(const Sound : string; SoundType : TSoundType = stFileName;
                      Synchronous : boolean = False; Module : HMODULE = 0;
                      AddFlags : LongWord = 0) : boolean; platform;
// Ex�cute un son via MMSytem.PlaySound
{$ENDIF}

{$REGION 'Modification des ressources'}

{$IFDEF MSWINDOWS}
function BeginUpdateRes(const FileName : string) : integer; platform;
procedure AddResource(ResHandle : integer; const ResName : string;
  Resource : TStream; const ResType : string = 'RT_RCDATA'); platform;
procedure DelResource(ResHandle : integer; const ResName : string); platform;
procedure EndUpdateRes(ResHandle : integer; Cancel : boolean = False); platform;
procedure AddResToFile(const FileName, ResName : string; Resource : TStream;
  const ResType : string = 'RT_RCDATA'); platform;
procedure DelResInFile(const FileName, ResName : string); platform;
{$ENDIF}

{$ENDREGION}

{$REGION 'Compression/d�compression'}

const
  clNoComp      = ZLib.clNone;    // pas de compression
  clFastestComp = ZLib.clFastest; // compression la plus rapide
  clDefaultComp = ZLib.clDefault; // compression par d�faut
  clMaxComp     = ZLib.clMax;     // compression maximale
procedure CompressStream(Stream : TStream; Dest : TStream = nil;
                         CompressionLevel : TCompressionLevel = clDefaultComp);
// Compresse le contenu de Stream dans Dest (si Dest = nil, dans Stream)
procedure DecompressStream(Stream : TStream; Dest : TStream = nil);
// D�compresse le contenu de Stream dans Dest (si Dest = nil, dans Stream)

{$ENDREGION}

implementation

uses
{$IFDEF MSWINDOWS}
  MMSystem;
{$ENDIF}

const
  NumbersStr = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  MaxBase = 36;

function CorrectIdentifier(const Ident : string) : boolean;
var I : integer;
begin
  Result := False;
  // Si Ident est vide, ce n'est un indentificateur correct
  if Ident = '' then exit;
  // Si le premier caract�re n'est pas alphab�tique,
  // ce n'est pas un identificateur correct
  if not (Ident[1] in ['A'..'Z', '_', 'a'..'z']) then exit;
  // Si l'un des caract�res suivant n'est pas alphanum�rique,
  // ce n'est pas un identificateur correct
  for I := 2 to Length(Ident) do
    if not (Ident[I] in ['0'..'9', 'A'..'Z', '_', 'a'..'z']) then exit;
  // Dans les autres cas, �a l'est
  Result := True;
end;

procedure VerifyBase(Base : Byte);
begin
  if (Base < 2) or (Base > MaxBase) then
    raise EConvertError.CreateFmt(sScWrongBase, [Base]);
end;

function IntToBase(Value : integer; Base : Byte = 10) : string;
var Negative : boolean;
begin
  VerifyBase(Base);
  if Value = 0 then Result := NumbersStr[1] else
  begin
    Negative := Value < 0;
    if Negative then Value := -Value;
    Result := '';
    while Value > 0 do
    begin
      Result := NumbersStr[Value mod Base + 1] + Result;
      Value := Value div Base;
    end;
    if Negative then Result := '-'+Result;
  end;
end;

function BaseToInt(const Value : string; Base : Byte = 10) : integer;
  procedure RaiseUncorrectInteger;
  begin
    raise EConvertError.CreateFmt(sScWrongInteger, [Value]);
  end;
var Negative : boolean;
    ResultCopy, Num : integer;
    Val : string;
begin
  Val := Value;
  VerifyBase(Base);
  if (Val = '') or (Val = '-') then
    RaiseUncorrectInteger;
  Negative := Val[1] = '-';
  if Negative then Delete(Val, 1, 1);
  Result := 0;
  while Val <> '' do
  begin
    Num := Pos(Val[1], NumbersStr);
    if (Num = 0) or (Num > Base) then
      RaiseUncorrectInteger;
    dec(Num);
    ResultCopy := Result;
    Result := Result * Base + Num;
    if Result < ResultCopy then
      RaiseUncorrectInteger;
    Delete(Val, 1, 1);
  end;
  if Negative then Result := -Result;
end;

function BaseToIntDef(const Value : string; Default : integer = 0; Base : Byte = 10) : integer;
begin
  try
    Result := BaseToInt(Value, Base);
  except
    on Error : EConvertError do Result := Default;
  end;
end;

function GetMethodFromName(Obj : TObject; MethodName : ShortString) : TMethod;
begin
  Result.Code := Obj.MethodAddress(MethodName);
  Result.Data := Obj;
end;

function ConvertDoubleToInt64(Value : Double) : Int64;
type
  TypeDeTransition = packed record
    case integer of
    0 : (DblValue : Double);
    1 : (IntValue : Int64);
  end;
var VarDeTransition : TypeDeTransition;
begin
  // Ceci est totalement empirique, seuls les bits sont �gaux (ce qui ne
  // correspond absolument pas � la valeur)
  VarDeTransition.DblValue := Value;
  Result := VarDeTransition.IntValue;
end;

function ConvertInt64ToDouble(Value : Int64) : Double;
type
  TypeDeTransition = packed record
    case integer of
    0 : (IntValue : Int64);
    1 : (DblValue : Double);
  end;
var VarDeTransition : TypeDeTransition;
begin
  // Ceci est totalement empirique, seuls les bits sont �gaux (ce qui ne
  // correspond absolument pas � la valeur)
  VarDeTransition.IntValue := Value;
  Result := VarDeTransition.DblValue;
end;

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
        Result := Result+'#'+IntToStr(Byte(Str[I]));
        inc(I);
      end else
      begin
        Result := Result+'''';
        while (I <= Length(Str)) and (not (Str[I] in ExcludedChars)) do
        begin
          if Str[I] = '''' then Result := Result + '''''' else
            Result := Result + Str[I];
          inc(I);
        end;
        Result := Result+'''';
      end;
    end;
  end;
end;

function StrRepresToStr(Str : string) : string;
var CharStr : string;
    I, IntChar : integer;
begin
  Result := '';
  Str := Trim(Str);
  I := 1;
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
      if (IntChar >= 0) and (IntChar <= 255) then Result := Result+Char(IntChar) else
        raise EConvertError.CreateFmt(sScWrongString, [Str]);
    end;
  end;
  if I <= Length(Str) then
    raise EConvertError.CreateFmt(sScWrongString, [Str]);
end;

function CharToCharRepres(Charact : Char) : string;
begin
  if Charact < #32 then Result := '#'+IntToStr(Byte(Charact)) else
  if Charact = '''' then Result := '''''''''' else
  Result := ''''+Charact+'''';
end;

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

function CharSetToStr(SetOfChars : TSysCharSet) : string;
var I, From : Word;
begin
  Result := '';
  I := 0;
  // On cherche d'abord le premier caract�re inclu
  while (I <= 255) and (not (Chr(I) in SetOfChars)) do inc(I);
  while I <= 255 do
  begin
    // Chr(I) est inclu
    From := I;
    // On cherche le caract�re suivant qui n'est pas inclu
    while (I <= 255) and (Chr(I) in SetOfChars) do inc(I);
    // On teste I-From, soit le nombre de caract�re cons�cutifs
    case I-From of
      // 1 : on ajoute simplement ce caract�re
      1 : Result := Result+', '+CharToCharRepres(Chr(From));
      // 2 : on ajoute ces deux caract�res s�par�s par des virgules
      2 : Result := Result+', '+CharToCharRepres(Chr(From))+', '+CharToCharRepres(Chr(I-1));
      // 3+ : on ajoute les deux extr�mes s�par�s par ..
      else Result := Result+', '+CharToCharRepres(Chr(From))+'..'+CharToCharRepres(Chr(I-1));
    end;
    // on cherche le caract�re suivant inclu
    repeat inc(I) until (I > 255) or (Chr(I) in SetOfChars);
  end;
  // On supprime les deux premiers caract�res, car ce sont ', '
  Delete(Result, 1, 2);
end;

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

{$IFDEF MSWINDOWS}
procedure CreateShellLink(const Source, Dest : string;
                          const Description : string = '';
                          const IconLocation : string = '';
                          IconIndex : integer = 0;
                          const Arguments : string = '';
                          const WorkDir : string = '';
                          ShowCommand : integer = SW_SHOW);
var Link : IShellLink;
begin
  // Cr�ation de l'objet ShellLink
  Link := CreateComObject(CLSID_ShellLink) as IShellLink;
  // Fichier source
  Link.SetPath(PChar(Source));
  // Description
  if Description <> '' then
    Link.SetDescription(PChar(Description));
  // Emplacement de l'ic�ne
  if IconLocation <> '' then
    Link.SetIconLocation(PChar(IconLocation), IconIndex);
  // Arguments
  if Arguments <> '' then
    Link.SetArguments(PChar(Arguments));
  // Dossier de travail
  if WorkDir <> '' then
    Link.SetWorkingDirectory(PChar(WorkDir));
  // Type de lancement
  Link.SetShowCmd(ShowCommand);
  // Enregistrement
  (Link as IPersistFile).Save(StringToOleStr(Dest), True);
end;
{$ENDIF}

function ExecuteSound(const Sound : string; SoundType : TSoundType = stFileName;
  Synchronous : boolean = False; Module : HMODULE = 0;
  AddFlags : LongWord = 0) : boolean;
var Flags : LongWord;
begin
  Flags := AddFlags;
  case SoundType of
    stFileName : Flags := Flags or SND_FILENAME; // Fichier son
    stResource : Flags := Flags or SND_RESOURCE; // Ressource son
    stSysSound : Flags := Flags or SND_ALIAS;    // Alias son syst�me
  end;
  if not Synchronous then Flags := Flags or SND_ASYNC; // Asynchr�ne ?
  if SoundType <> stResource then Module := 0;
  // Appel de PlaySound et renvoi de la valeur renvoy�e par celle-ci
  Result := PlaySound(PChar(Sound), Module, Flags);
end;

{$REGION 'Modification des ressources'}

///////////////////////////////////////
/// Ajout-suppression de ressources ///
///////////////////////////////////////
{$IFDEF MSWINDOWS}

function BeginUpdateRes(const FileName : string) : integer;
begin
  // Appel de Windows.BeginUpdateResource
  Result := BeginUpdateResource(PChar(FileName), False);
  // Si Result = 0, il y a eu une erreur API
  if Result = 0 then
    raise EUpdateResError.Create;
end;

procedure AddResource(ResHandle : integer; const ResName : string;
  Resource : TStream; const ResType : string = 'RT_RCDATA');
var MemRes : TMemoryStream;
    MustFreeRes, OK : boolean;
begin
  MustFreeRes := False;
  // On met dans MemRes un flux m�moire qui contient les donn�es de la ressource
  if Resource is TMemoryStream then MemRes := Resource as TMemoryStream else
  begin
    MemRes := TMemoryStream.Create;
    MemRes.LoadFromStream(Resource);
    MustFreeRes := True;
  end;
  // Appel de Windows.UpdateResource
  OK := UpdateResource(ResHandle, PChar(ResType), PChar(ResName), 0,
                       MemRes.Memory, MemRes.Size);
  // On supprime le flux m�moire si on l'a cr��
  if MustFreeRes then MemRes.Free;
  // Si UpdateResource a renvoy� False, il y a eu une erreur
  if not OK then raise EUpdateResError.Create;
end;

procedure DelResource(ResHandle : integer; const ResName : string);
begin
  // Appel de Windows.UpdateResource
  if not UpdateResource(ResHandle, '', PChar(ResName), 0, nil, 0) then
  // Si UpdateResource a renvoy� False, il y a eu une erreur
    raise EUpdateResError.Create;
end;

procedure EndUpdateRes(ResHandle : integer; Cancel : boolean = False);
begin
  // Appel de Windows.EndUpdateResource
  if not EndUpdateResource(ResHandle, Cancel) then
  // Si EndUpdateResource a renvoy� False, il y a eu une erreur
    raise EUpdateResError.Create;
end;

procedure AddResToFile(const FileName, ResName : string; Resource : TStream;
  const ResType : string = 'RT_RCDATA');
var ResHandle : integer;
begin
  ResHandle := BeginUpdateRes(FileName);
  try
    AddResource(ResHandle, ResName, Resource, ResType);
    EndUpdateRes(ResHandle);
  except
    try EndUpdateRes(ResHandle, True) except end;
    raise;
  end;
end;

procedure DelResInFile(const FileName, ResName : string);
var ResHandle : integer;
begin
  ResHandle := BeginUpdateRes(FileName);
  try
    DelResource(ResHandle, ResName);
    EndUpdateRes(ResHandle);
  except
    try EndUpdateRes(ResHandle, True) except end;
    raise;
  end;
end;

{$ENDIF}

{$ENDREGION}

{$REGION 'Compression/d�compression'}

procedure CompressStream(Stream : TStream; Dest : TStream = nil;
                         CompressionLevel : TCompressionLevel = clDefaultComp);
var Compress : TCompressionStream;
    Destination : TStream;
begin
  // Si Dest vaut nil, on cr�e un flux temporaire de destination
  if Dest = nil then Destination := TMemoryStream.Create else
  begin
    Destination := Dest;
    Destination.Position := 0;
    Destination.Size := 0;
  end;
  // Cr�ation, utilisation et lib�ration du flux de compression
  Compress := TCompressionStream.Create(CompressionLevel, Destination);
  Compress.CopyFrom(Stream, 0);
  Compress.Free;
  // Si Dest vaut nil, on recopie Destination dans Stream
  if Dest = nil then
  begin
    Stream.Position := 0;
    Stream.Size := 0;
    Stream.CopyFrom(Destination, 0);
    Destination.Free;
  end;
end;

procedure DecompressStream(Stream : TStream; Dest : TStream = nil);
var Decompress : TDecompressionStream;
    Destination : TStream;
    Buffer : array [0..1023] of Byte;
    Copies : integer;
begin
  // Si Dest vaut nil, on cr�e un flux temporaire de destination
  if Dest = nil then Destination := TMemoryStream.Create else
  begin
    Destination := Dest;
    Destination.Position := 0;
    Destination.Size := 0;
  end;
  // Cr�ation, utilisation et lib�ration du flux de d�compression
  Decompress := TDecompressionStream.Create(Stream);
  Decompress.Position := 0;
  repeat
    Copies := Decompress.Read(Buffer, 1024);
    Destination.Write(Buffer, Copies);
  until Copies < 1024;
  Decompress.Free;
  // Si Dest vaut nil, on recopieDestination dans Stream
  if Dest = nil then
  begin
    Stream.Position := 0;
    Stream.Size := 0;
    Stream.CopyFrom(Destination, 0);
  end;
end;

{$ENDREGION}

end.

