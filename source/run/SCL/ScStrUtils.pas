{*
  D�finit quelques routines de gestion de cha�nes
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit ScStrUtils;

interface

type
  {*
    Option de comparaison de cha�nes
    coIgnoreCase     : Ignore la casse
    coIgnoreNonSpace : Ignore les accents
    coIgnoreSymbols  : Ignore les symboles
  *}
  TCompareStrOption = (
    coIgnoreCase,
    coIgnoreNonSpace,
    coIgnoreSymbols
  );

  {*
    Ensemble d'options de comparaison de cha�nes
  *}
  TCompareStrOptions = set of TCompareStrOption;

function NberSubStr(const SubStr, Str : string) : integer;
function NberCharInStr(C : Char; const Str : string) : integer;

{$IFDEF MSWINDOWS}
function CompareStringEx(const S1, S2 : string;
  CompareOptions : TCompareStrOptions = []) : integer; platform;
{$ENDIF}

function GetFirstToken(const S : string; Token : Char) : string;
function GetLastToken(const S : string; Token : Char) : string;

function GetXToken(const S : string; Token : Char; X : integer) : string;
function GetXWord(const S : string; X : integer) : string;

function PosWord(const Wrd, Str : string; Index : integer = 1) : integer;

implementation

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  StrUtils;

{*
  Calcule le nombre d'occurences d'une sous-cha�ne dans une cha�ne
  @param SubStr   Sous-cha�ne � chercher
  @param Str      Cha�ne dans laquelle chercher SubStr
  @return Nombre d'occurences de SubStr dans Str
*}
function NberSubStr(const SubStr, Str : string) : integer;
var I : integer;
begin
  Result := 0;
  for I := Length(Str)-Length(SubStr)+1 downto 1 do
    if Copy(Str, I, Length(SubStr)) = SubStr then inc(Result);
end;

{*
  Calcule le nombre d'occurences d'un caract�re dans une cha�ne
  @param C     Caract�re � chercher
  @param Str   Cha�ne dans laquelle chercher C
  @return Nombre d'occurences de C dans Str
*}
function NberCharInStr(C : Char; const Str : string) : integer;
var I : integer;
begin
  Result := 0;
  for I := Length(Str) downto 1 do
    if Str[I] = C then inc(Result);
end;

{$IFDEF MSWINDOWS}
{*
  Compare deux cha�nes de caract�res avec des options avanc�es
  @param S1               Premi�re cha�ne
  @param S2               Seconde cha�ne
  @param CompareOptions   Options de comparaison
  @return 0 si les cha�nes sont semblables, un nombre positif si la premi�re
          est sup�rieure � la seconde, un nombre n�gatif dans le cas inverse
*}
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

{*
  D�coupe une cha�ne selon un d�limiteur et r�cup�re la premi�re sous-cha�ne
  @param S       Cha�ne � d�couper
  @param Token   D�limiteur
  @return La premi�re sous-cha�ne de S d�limit�e par Token (ou S si non trouv�)
*}
function GetFirstToken(const S : string; Token : Char) : string;
var I : integer;
begin
  I := 1;
  // On parcourt la cha�ne jusqu'� trouver un caract�re Token
  while (I <= Length(S)) and (S[I] <> Token) do inc(I);
  // On copie la cha�ne depuis le d�but jusqu'au caract�re avant Token
  Result := Copy(S, 1, I-1);
end;

{*
  D�coupe une cha�ne selon un d�limiteur et r�cup�re la derni�re sous-cha�ne
  @param S       Cha�ne � d�couper
  @param Token   D�limiteur
  @return La derni�re sous-cha�ne de S d�limit�e par Token (ou S si non trouv�)
*}
function GetLastToken(const S : string; Token : Char) : string;
var I : integer;
begin
  I := Length(S);
  // On parcourt la cha�ne � l'envers jusqu'� trouver un caract�re Token
  while (I > 0) and (S[I] <> Token) do dec(I);
  // On copie la cha�ne depuis le caract�re apr�s Token jusqu'� la fin
  Result := Copy(S, I+1, Length(S));
end;

{*
  D�coupe une cha�ne selon un d�limiteur et r�cup�re la X�me sous-cha�ne
  @param S       Cha�ne � d�couper
  @param Token   D�limiteur
  @param X       Index base sur 1 de la sous-cha�ne � r�cup�rer
  @return La X�me sous-cha�ne de S d�limit�e par Token (ou '' si X trop grand)
*}
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

{*
  D�coupe une cha�ne en mots et r�cup�re le X�me mot
  Les mots sont d�limit�s par des espaces uniquement.
  @param S       Cha�ne � d�couper
  @param X       Index base sur 1 du mot � r�cup�rer
  @return Le X�me mot de S (ou '' si X trop grand)
*}
function GetXWord(const S : string; X : integer) : string;
begin
  Result := GetXToken(S, ' ', X);
end;

{*
  Cherche la premi�re occurence d'un mot dans une cha�ne
  Les mots sont d�limit�s par des espaces uniquement.
  @param Wrd     Mot � chercher
  @param Str     Cha�ne dans laquelle chercher le mot
  @param Index   Position dans la cha�ne � partir de laquelle chercher le mot
  @return La position du premier caract�re du mot dans la cha�ne
*}
function PosWord(const Wrd, Str : string; Index : integer = 1) : integer;
begin
  Result := PosEx(' '+Wrd+' ', ' '+Str+' ', Index);
end;

end.

