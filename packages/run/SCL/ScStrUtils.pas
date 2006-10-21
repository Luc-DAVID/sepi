{*
  D�finit quelques routines de gestion de cha�nes
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit ScStrUtils;

interface

type
  TCompareStrOption = (
    coIgnoreCase,        // Ignore la casse
    coIgnoreNonSpace,    // Ignore les accents
    coIgnoreSymbols);    // Ignore les symboles
  TCompareStrOptions = set of TCompareStrOption;

function NberSubStr(const SubStr, Str : string) : integer;
// Renvoie le nombre d'occurences de SubStr dans Str
// Attention ! Si vous recherchez '..' dans '...', vous en trouverez 2 !

function NberCharInStr(C : Char; const Str : string) : integer;
// Version optimis�e de NberSubStr lorsqu'il ne faut chercher qu'un caract�re

{$IFDEF MSWINDOWS}
function CompareStringEx(const S1, S2 : string;
  CompareOptions : TCompareStrOptions = []) : integer; platform;
// Compare deux cha�nes suivant les options sp�cifi�es par CompareOptions
{$ENDIF}

function GetFirstToken(const S : string; Token : Char) : string;
// Renvoie la premi�re sous-cha�ne de S d�limit�e par Token
// (si Token n'est pas dans S, renvoie S)
function GetLastToken(const S : string; Token : Char) : string;
// Renvoie la derni�re sous-cha�ne de S d�limit�e par Token
// (si Token n'est pas dans S, renvoie S)
function GetXToken(const S : string; Token : Char; X : integer) : string;
// Renvoie la X�me sous-cha�ne de S d�limit�e par Token

function GetXWord(const S : string; X : integer) : string;
// Recherche le X�me mot dans S
// Attention ! L'appel GetXWord('Je m''appelle S�bastien', 2) renverra 'm''appelle' !

function PosWord(const Wrd, Str : string; Index : integer = 1) : integer;
// Renvoie la premi�re position de Wrd dans Str � partir de la position Index
// Renvoie 0 si le mot n'est pas trouv�
// Attention ! L'appel PosWord('Chose', 'Chose-Machin Chouette Chose') renverra 23
//                                                             *
// De m�me que l'appel PosWord('revoir', 'Au revoir.') renverra 0 (non trouv� � cause du '.')

implementation

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  StrUtils;

function NberSubStr(const SubStr, Str : string) : integer;
var I : integer;
begin
  Result := 0;
  // On parcourt la cha�ne et on incr�mente Result si la correspondance est
  // �tablie
  for I := 1 to Length(Str)-Length(SubStr)+1 do
    if Copy(Str, I, Length(SubStr)) = SubStr then inc(Result);
end;

function NberCharInStr(C : Char; const Str : string) : integer;
var I : integer;
begin
  Result := 0;
  for I := 1 to Length(Str) do
    if Str[I] = C then inc(Result);
end;

{$IFDEF MSWINDOWS}
function CompareStringEx(const S1, S2 : string;
  CompareOptions : TCompareStrOptions = []) : integer;
var Flags : DWord;
begin
  Flags := 0;
  // On ajoute les flags de comparaison
  if coIgnoreCase     in CompareOptions then Flags := Flags+NORM_IGNORECASE;
  if coIgnoreNonSpace in CompareOptions then Flags := Flags+NORM_IGNORENONSPACE;
  if coIgnoreSymbols  in CompareOptions then Flags := Flags+NORM_IGNORESYMBOLS;
  // Appel de Windows.CompareString
  Result := Windows.CompareString(LOCALE_USER_DEFAULT, Flags,
                                  PChar(S1), -1, PChar(S2), -1)-2;
end;
{$ENDIF}

function GetFirstToken(const S : string; Token : Char) : string;
var I : integer;
begin
  I := 1;
  // On parcourt la cha�ne jusqu'� trouver un caract�re Token
  while (I <= Length(S)) and (S[I] <> Token) do inc(I);
  // On copie la cha�ne depuis le d�but jusqu'au caract�re avant Token
  Result := Copy(S, 1, I-1);
end;

function GetLastToken(const S : string; Token : Char) : string;
var I : integer;
begin
  I := Length(S);
  // On parcourt la cha�ne � l'envers jusqu'� trouver un caract�re Token
  while (I > 0) and (S[I] <> Token) do dec(I);
  // On copie la cha�ne depuis le caract�re apr�s Token jusqu'� la fin
  Result := Copy(S, I+1, Length(S));
end;

function GetXToken(const S : string; Token : Char; X : integer) : string;
var I, J : integer;
begin
  dec(X);
  I := 1;
  // On boucle jusqu'� trouver la bonne occurence de Token
  while (X > 0) and (I <= Length(S)) do
  begin
    if S[I] = Token then dec(X);
    inc(I);
  end;
  // Si X est encore plus grand que 0, c'est qu'il n'y a pas assez d'occurences
  if X > 0 then Result := '' else
  begin
    J := I;
    while (J <= Length(S)) and (S[J] <> Token) do inc(J);
    Result := Copy(S, I, J-I);
  end;
end;

function GetXWord(const S : string; X : integer) : string;
begin
  Result := GetXToken(S, ' ', X);
end;

function PosWord(const Wrd, Str : string; Index : integer = 1) : integer;
begin
  Result := PosEx(' '+Wrd+' ', ' '+Str+' ', Index);
end;

end.
