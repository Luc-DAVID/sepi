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
  Utilitaires d'analyse lexicale Sepi
  @author sjrd
  @version 1.0
*}
unit SepiLexerUtils;

interface

{$D-,L-}

uses
  SysUtils, Classes, Contnrs, ScUtils, SepiCore, SepiReflectionCore,
  SepiCompilerErrors, SepiParseTrees, SepiCompilerConsts;

const
  tkEof = 0;     /// Lex�me fin de fichier
  tkBlank = 1;   /// Lex�me blanc
  tkComment = 2; /// Lex�me commentaire

type
  TSepiCustomLexer = class;

  {*
    Fonction d'analyse d'un terminal
    @return True si un v�ritable terminal a �t� analys�, False sinon
  *}
  TSepiLexingProc = procedure of object;

  {*
    Type d'�v�nement OnNeedFile des analyseurs lexicaux Sepi
    @param Sender     Analyseur lexical qui a d�clench� l'�v�nement
    @param FileName   Nom de fichier � r�soudre
  *}
  TSepiLexerNeedFileEvent = procedure(Sender: TSepiCustomLexer;
    var FileName: TFileName) of object;

  {*
    Erreur d'analyse lexicale
    @author sjrd
    @version 1.0
  *}
  ESepiLexicalError = class(ESepiError);

  {*
    Marque dans le source - utilis� pour retourner en arri�re dans le code
    @author sjrd
    @version 1.0
  *}
  TSepiLexerBookmark = class(TObject)
  end;

  {*
    Classe de base pour les analyseurs lexicaux Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiCustomLexer = class(TObject)
  private
    FErrors: TSepiCompilerErrorList; /// Erreurs de compilation

    FExcludedTokens: TSysByteSet; /// Types de lex�mes � exclure compl�tement

    FContext: TSepiNonTerminal; /// Contexte courant (peut �tre nil)

    /// �v�nement d�clench� lorsque cet analyseur a besoin d'un fichier
    FOnNeedFile: TSepiLexerNeedFileEvent;

    procedure SetExcludedTokens(const Value: TSysByteSet);

    function GetIsEof: Boolean;
  protected
    procedure MakeError(const ErrorMsg: string;
      Kind: TSepiErrorKind = ekError);

    function GetCurrentPos: TSepiSourcePosition; virtual; abstract;
    function GetCurTerminal: TSepiTerminal; virtual; abstract;
    procedure SetContext(Value: TSepiNonTerminal); virtual;

    procedure DoNeedFile(var FileName: TFileName); virtual;
    function FindFile(const FileName: TFileName): TFileName;

    procedure DoNextTerminal; virtual; abstract;
  public
    constructor Create(AErrors: TSepiCompilerErrorList; const ACode: string;
      const AFileName: TFileName = ''); virtual;

    procedure NextTerminal;

    function MakeBookmark: TSepiLexerBookmark; virtual;
    procedure ResetToBookmark(Bookmark: TSepiLexerBookmark;
      FreeBookmark: Boolean = True); virtual;

    property Errors: TSepiCompilerErrorList read FErrors;

    property ExcludedTokens: TSysByteSet
      read FExcludedTokens write SetExcludedTokens;

    property CurrentPos: TSepiSourcePosition read GetCurrentPos;
    property CurTerminal: TSepiTerminal read GetCurTerminal;
    property IsEof: Boolean read GetIsEof;

    property Context: TSepiNonTerminal read FContext write SetContext;

    property OnNeedFile: TSepiLexerNeedFileEvent
      read FOnNeedFile write FOnNeedFile;
  end;

  /// Classe de TSepiCustomLexerClass
  TSepiCustomLexerClass = class of TSepiCustomLexer;

  {*
    Bookmark pour TSepiBaseLexer
    @author sjrd
    @version 1.0
  *}
  TSepiBaseLexerBookmark = class(TSepiLexerBookmark)
  private
    FCursor: Integer;                 /// Index courant dans le source
    FCurrentPos: TSepiSourcePosition; /// Position courante
    FNextPos: TSepiSourcePosition;    /// Prochaine position
    FCurTerminal: TSepiTerminal;      /// Dernier terminal analys�
  public
    constructor Create(ACursor: Integer;
      const ACurrentPos, ANextPos: TSepiSourcePosition;
      ACurTerminal: TSepiTerminal);
    destructor Destroy; override;

    property Cursor: Integer read FCursor;
    property CurrentPos: TSepiSourcePosition read FCurrentPos;
    property NextPos: TSepiSourcePosition read FNextPos;
    property CurTerminal: TSepiTerminal read FCurTerminal;
  end;

  {*
    Classe de base pour les analyseurs lexicaux Sepi de base (non composites)
    @author sjrd
    @version 1.0
  *}
  TSepiBaseLexer = class(TSepiCustomLexer)
  private
    FCode: string;                    /// Code source � analyser
    FCursor: Integer;                 /// Index courant dans le source
    FCurrentPos: TSepiSourcePosition; /// Position courante
    FNextPos: TSepiSourcePosition;    /// Prochaine position
    FCurTerminal: TSepiTerminal;      /// Dernier terminal analys�
  protected
    function GetCurrentPos: TSepiSourcePosition; override;
    function GetCurTerminal: TSepiTerminal; override;

    procedure TerminalParsed(SymbolClass: TSepiSymbolClass;
      const Representation: string);

    procedure CursorForward(Amount: Integer = 1);

    procedure IdentifyKeyword(const Key: string;
      var SymbolClass: TSepiSymbolClass); virtual;
  public
    constructor Create(AErrors: TSepiCompilerErrorList; const ACode: string;
      const AFileName: TFileName = ''); override;
    destructor Destroy; override;

    function MakeBookmark: TSepiLexerBookmark; override;
    procedure ResetToBookmark(ABookmark: TSepiLexerBookmark;
      FreeBookmark: Boolean = True); override;

    property Code: string read FCode;
    property Cursor: Integer read FCursor;

    property CurrentPos: TSepiSourcePosition read FCurrentPos;
    property CurTerminal: TSepiTerminal read FCurTerminal;
  end;

  {*
    Classe de base pour les analyseurs lexicaux Sepi �crits � la main
    @author sjrd
    @version 1.0
  *}
  TSepiCustomManualLexer = class(TSepiBaseLexer)
  protected
    /// Tableau des fonctions d'analyse index� par les caract�res de d�but
    LexingProcs: array[#0..#255] of TSepiLexingProc;

    procedure DoNextTerminal; override;

    procedure InitLexingProcs; virtual;

    procedure ActionUnknown;
    procedure ActionEof;
    procedure ActionBlank;
  public
    constructor Create(AErrors: TSepiCompilerErrorList; const ACode: string;
      const AFileName: TFileName = ''); override;
  end;

  {*
    Bookmark pour TSepiCustomCompositeLexer
    @author sjrd
    @version 1.0
  *}
  TSepiCompositeLexerBookmark = class(TSepiLexerBookmark)
  private
    FLexerChangeCount: Integer;            /// Nombre de changements d'analyseur
    FCurLexerBookmark: TSepiLexerBookmark; /// Bookmark pour l'analyseur courant
  public
    constructor Create(ALexerChangeCount: Integer;
      ACurLexerBookmark: TSepiLexerBookmark);
    destructor Destroy; override;

    property LexerChangeCount: Integer read FLexerChangeCount;
    property CurLexerBookmark: TSepiLexerBookmark read FCurLexerBookmark;
  end;

  {*
    Classe de base pour les analyseurs lexicaux composites
    Un analyseur lexical composite n'analyse pas directement un code source,
    mais prend sa source depuis un ou plusieurs autres analyseurs lexicaux, et
    transforme leur produit.
    Un exemple simple est celui d'un pr�-processeur, ou d'un processeur de
    directives de compilations comme celui de Delphi.
    @author sjrd
    @version 1.0
  *}
  TSepiCustomCompositeLexer = class(TSepiCustomLexer)
  private
    FCurLexer: TSepiCustomLexer; /// Analyseur courant
    FLexerStack: TObjectStack;   /// Pile des analyseurs sauvegard�s
    FLexerChangeCount: Integer;  /// Nombre de changements d'analyseur
  protected
    function GetCurrentPos: TSepiSourcePosition; override;
    function GetCurTerminal: TSepiTerminal; override;
    procedure SetContext(Value: TSepiNonTerminal); override;

    procedure DoNextTerminal; override;

    procedure SetBaseLexer(BaseLexer: TSepiCustomLexer);

    procedure CurLexerChanged; virtual;

    procedure EnterLexer(NewLexer: TSepiCustomLexer);
    procedure EnterFile(const FileName: TFileName);
    procedure LeaveCurLexer;

    property CurLexer: TSepiCustomLexer read FCurLexer;
  public
    constructor Create(AErrors: TSepiCompilerErrorList; const ACode: string;
      const AFileName: TFileName = ''); override;
    destructor Destroy; override;

    function MakeBookmark: TSepiLexerBookmark; override;
    procedure ResetToBookmark(ABookmark: TSepiLexerBookmark;
      FreeBookmark: Boolean = True); override;
  end;

const
  BlankChars = [#9, #10, #13, ' '];

implementation

{------------------------}
{ TSepiCustomLexer class }
{------------------------}

{*
  Cr�e un analyseur lexical
  @param AErrors     Erreurs de compilation
  @param ACode       Code source � analyser
  @param AFileName   Nom du fichier source
*}
constructor TSepiCustomLexer.Create(AErrors: TSepiCompilerErrorList;
  const ACode: string; const AFileName: TFileName = '');
begin
  inherited Create;

  FErrors := AErrors;
  FExcludedTokens := [tkBlank, tkComment];
end;

{*
  Modifie les types de lex�mes � exclure compl�tement
  @param Value   Nouvel ensemble de lex�mes � exclure (tkEof non pris en compte)
*}
procedure TSepiCustomLexer.SetExcludedTokens(const Value: TSysByteSet);
begin
  FExcludedTokens := Value;
  Exclude(FExcludedTokens, tkEof);
end;

{*
  Indique si l'analyseur a atteint la fin du fichier
  @return True si la fin de fichier a �t� atteinte, False sinon
*}
function TSepiCustomLexer.GetIsEof: Boolean;
var
  ACurTerminal: TSepiTerminal;
begin
  ACurTerminal := CurTerminal;
  Result := (ACurTerminal <> nil) and (ACurTerminal.SymbolClass = tkEof);
end;

{*
  Produit une erreur
  @param ErrorMsg   Message d'erreur
  @param Kind       Type d'erreur (d�faut = Erreur)
*}
procedure TSepiCustomLexer.MakeError(const ErrorMsg: string;
  Kind: TSepiErrorKind = ekError);
begin
  Errors.MakeError(ErrorMsg, Kind, CurrentPos);
end;

{*
  Modifie le noeud contexte courant
  @param Value   Nouveau noeud contexte
*}
procedure TSepiCustomLexer.SetContext(Value: TSepiNonTerminal);
begin
  FContext := Value;
end;

{*
  Ex�cut� lorsque cet analyseur a besoin d'un fichier valide
  @param FileName   Nom de fichier recherch�
*}
procedure TSepiCustomLexer.DoNeedFile(var FileName: TFileName);
begin
  if Assigned(FOnNeedFile) then
    FOnNeedFile(Self, FileName);
end;

{*
  Trouve un fichier
  @param FileName   Nom de fichier recherch� au d�part
  @return Nom de fichier complet valide
  @throws ESepiCompilerFatalError Le fichier n'a pas �t� trouv�
*}
function TSepiCustomLexer.FindFile(const FileName: TFileName): TFileName;
begin
  Result := FileName;
  DoNeedFile(Result);

  if not FileExists(Result) then
    MakeError(Format(SCantOpenSourceFile, [FileName]), ekFatalError);
end;

{*
  Passe au lex�me suivant
*}
procedure TSepiCustomLexer.NextTerminal;
begin
  repeat
    DoNextTerminal;
  until not (CurTerminal.SymbolClass in ExcludedTokens);
end;

{*
  Construit un marque-page � la position courante
  @return Le marque-page construit
*}
function TSepiCustomLexer.MakeBookmark: TSepiLexerBookmark;
begin
  Result := TSepiLexerBookmark.Create;
end;

{*
  Retourne dans le code source � la position d'un marque-page
  @param Bookmark       Marque-page
  @param FreeBookmark   Si True, le marque-page est ensuite d�truit
*}
procedure TSepiCustomLexer.ResetToBookmark(Bookmark: TSepiLexerBookmark;
  FreeBookmark: Boolean = True);
begin
  if FreeBookmark then
    Bookmark.Free;
end;

{------------------------------}
{ TSepiBaseLexerBookmark class }
{------------------------------}

{*
  Cr�e un marque-page
  @param ACursor        Index courant dans le source
  @param ACurrentPos    Position courante
  @param ANextPos       Prochaine position
  @param ACurTerminal   Dernier terminal analys�
*}
constructor TSepiBaseLexerBookmark.Create(ACursor: Integer;
  const ACurrentPos, ANextPos: TSepiSourcePosition;
  ACurTerminal: TSepiTerminal);
begin
  inherited Create;

  FCursor := ACursor;
  FCurrentPos := ACurrentPos;
  FNextPos := ANextPos;

  FCurTerminal := TSepiTerminal.Clone(ACurTerminal);
end;

{*
  [@inheritDoc]
*}
destructor TSepiBaseLexerBookmark.Destroy;
begin
  FCurTerminal.Free;

  inherited;
end;

{----------------------}
{ TSepiBaseLexer class }
{----------------------}

{*
  Cr�e un analyseur lexical
  @param AErrors     Erreurs de compilation
  @param ACode       Code source � analyser
  @param AFileName   Nom du fichier source
*}
constructor TSepiBaseLexer.Create(AErrors: TSepiCompilerErrorList;
  const ACode: string; const AFileName: TFileName = '');
begin
  inherited;

  FCode := ACode;
  FCursor := 1;

  if AFileName = '' then
    FNextPos.FileName := AErrors.CurrentFileName
  else
    FNextPos.FileName := AFileName;
  FNextPos.Line := 1;
  FNextPos.Col := 1;

  FCurrentPos := FNextPos;

  FCurTerminal := nil;
end;

{*
  [@inheritDoc]
*}
destructor TSepiBaseLexer.Destroy;
begin
  FreeAndNil(FCurTerminal);

  inherited;
end;

{*
  Indique qu'un terminal a �t� analys�
  @param SymbolClass      Class de symbole
  @param Representation   Repr�sentation du terminal
*}
procedure TSepiBaseLexer.TerminalParsed(SymbolClass: TSepiSymbolClass;
  const Representation: string);
begin
  FreeAndNil(FCurTerminal);

  FCurTerminal := TSepiTerminal.Create(SymbolClass, CurrentPos,
    Representation);
  FCurrentPos := FNextPos;
end;

{*
  Avance le curseur
  @param Amount   Nombre de caract�res � passer (d�faut = 1)
*}
procedure TSepiBaseLexer.CursorForward(Amount: Integer = 1);
var
  I: Integer;
begin
  Assert(Amount >= 0);

  for I := FCursor to FCursor+Amount-1 do
  begin
    if (I > 0) and (Code[I] = #10) and (Code[I-1] = #13) then
      // skip
    else if (Code[I] = #13) or (Code[I] = #10) then
    begin
      Inc(FNextPos.Line);
      FNextPos.Col := 1;
    end else
      Inc(FNextPos.Col);
  end;

  Inc(FCursor, Amount);
end;

{*
  Identifie un mot-clef
  @param Key           Mot-clef �ventuel � identifier
  @param SymbolClass   � modifier selon la classe du mot-clef
*}
procedure TSepiBaseLexer.IdentifyKeyword(const Key: string;
  var SymbolClass: TSepiSymbolClass);
begin
end;

{*
  [@inheritDoc]
*}
function TSepiBaseLexer.GetCurrentPos: TSepiSourcePosition;
begin
  Result := FCurrentPos;
end;

{*
  [@inheritDoc]
*}
function TSepiBaseLexer.GetCurTerminal: TSepiTerminal;
begin
  Result := FCurTerminal;
end;

{*
  [@inheritDoc]
*}
function TSepiBaseLexer.MakeBookmark: TSepiLexerBookmark;
begin
  Result := TSepiBaseLexerBookmark.Create(FCursor, FCurrentPos, FNextPos,
    FCurTerminal);
end;

{*
  [@inheritDoc]
*}
procedure TSepiBaseLexer.ResetToBookmark(ABookmark: TSepiLexerBookmark;
  FreeBookmark: Boolean = True);
var
  Bookmark: TSepiBaseLexerBookmark;
begin
  Bookmark := ABookmark as TSepiBaseLexerBookmark;

  FCursor := Bookmark.Cursor;
  FCurrentPos := Bookmark.CurrentPos;
  FNextPos := Bookmark.NextPos;

  FreeAndNil(FCurTerminal);
  FCurTerminal := TSepiTerminal.Clone(Bookmark.CurTerminal);

  inherited;
end;

{------------------------------}
{ TSepiCustomManualLexer class }
{------------------------------}

{*
  [@inheritDoc]
*}
constructor TSepiCustomManualLexer.Create(AErrors: TSepiCompilerErrorList;
  const ACode: string; const AFileName: TFileName = '');
begin
  inherited;

  InitLexingProcs;
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomManualLexer.DoNextTerminal;
var
  Discriminant: Char;
begin
  Discriminant := Code[Cursor];

  {$IF SizeOf(Char) > 1}
    if Discriminant <= #255 then
      LexingProcs[Discriminant]
    else
      ActionUnknown;
  {$ELSE}
    LexingProcs[Discriminant];
  {$IFEND}
end;

{*
  Initialise le tableau LexingProcs
*}
procedure TSepiCustomManualLexer.InitLexingProcs;
var
  C: Char;
begin
  for C := #0 to #255 do
  begin
    if C = #0 then
      LexingProcs[C] := ActionEof
    else if CharInSet(C, BlankChars) then
      LexingProcs[C] := ActionBlank
    else
      LexingProcs[C] := ActionUnknown;
  end;
end;

{*
  Action pour un caract�re inconnu - d�clenche une erreur lexicale
  @return Ne retourne jamais
  @raise ESepiLexicalError
*}
procedure TSepiCustomManualLexer.ActionUnknown;
begin
  MakeError(Format(SBadSourceCharacter, [Code[Cursor]]), ekFatalError);
end;

{*
  Analise un caract�re de fin de fichier
  @return True - la fin de fichier est bien r�elle
*}
procedure TSepiCustomManualLexer.ActionEof;
begin
  TerminalParsed(tkEof, SEndOfFile);
end;

{*
  Analise un blanc
  @return False - les blancs ne sont pas de v�ritables lex�mes
*}
procedure TSepiCustomManualLexer.ActionBlank;
begin
  while CharInSet(Code[Cursor], BlankChars) do
    CursorForward;

  TerminalParsed(tkBlank, ' ');
end;

{-----------------------------------}
{ TSepiCompositeLexerBookmark class }
{-----------------------------------}

{*
  Cr�e un bookmark
  @param ALexerChangeCount   Nombre de changements d'analyseur
  @param ACurLexerBookmark   Bookmark pour l'analyseur courant
*}
constructor TSepiCompositeLexerBookmark.Create(ALexerChangeCount: Integer;
  ACurLexerBookmark: TSepiLexerBookmark);
begin
  inherited Create;

  FLexerChangeCount := ALexerChangeCount;
  FCurLexerBookmark := ACurLexerBookmark;
end;

{*
  [@inheritDoc]
*}
destructor TSepiCompositeLexerBookmark.Destroy;
begin
  FCurLexerBookmark.Free;

  inherited;
end;

{---------------------------------}
{ TSepiCustomCompositeLexer class }
{---------------------------------}

{*
  [@inheritDoc]
*}
constructor TSepiCustomCompositeLexer.Create(AErrors: TSepiCompilerErrorList;
  const ACode: string; const AFileName: TFileName = '');
begin
  inherited;

  FLexerStack := TObjectStack.Create;
end;

{*
  [@inheritDoc]
*}
destructor TSepiCustomCompositeLexer.Destroy;
begin
  if Assigned(FLexerStack) then
  begin
    while FLexerStack.Count > 0 do
      FLexerStack.Pop.Free;
    FLexerStack.Free;
  end;

  FCurLexer.Free;

  inherited;
end;

{*
  [@inheritDoc]
*}
function TSepiCustomCompositeLexer.GetCurrentPos: TSepiSourcePosition;
begin
  Result := CurLexer.CurrentPos;
end;

{*
  [@inheritDoc]
*}
function TSepiCustomCompositeLexer.GetCurTerminal: TSepiTerminal;
begin
  Result := CurLexer.CurTerminal;

  if (Result = nil) and (FLexerStack.Count > 0) then
    Result := TSepiCustomLexer(FLexerStack.Peek).CurTerminal;
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomCompositeLexer.SetContext(Value: TSepiNonTerminal);
begin
  inherited;

  CurLexer.Context := Context;
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomCompositeLexer.DoNextTerminal;
begin
  CurLexer.NextTerminal;

  while CurLexer.IsEof and (FLexerStack.Count > 0) do
  begin
    LeaveCurLexer;
    CurLexer.NextTerminal;
  end;
end;

{*
  Renseigne l'analyseur de base
  Cette m�thode doit �tre appel�e une et une seule fois dans le constructeur.
  @param BaseLexer   Analyseur de base
*}
procedure TSepiCustomCompositeLexer.SetBaseLexer(BaseLexer: TSepiCustomLexer);
begin
  Assert(FCurLexer = nil);
  FCurLexer := BaseLexer;

  CurLexerChanged;
end;

{*
  Appel� lorsque l'analyseur courant a �t� modifi�
*}
procedure TSepiCustomCompositeLexer.CurLexerChanged;
begin
  Inc(FLexerChangeCount);
  CurLexer.Context := Context;
  Errors.CurrentFileName := CurLexer.CurrentPos.FileName;
end;

{*
  Entre dans un nouvel analyseur
  @param NewLexer   Nouvel analyseur dans lequel entrer
*}
procedure TSepiCustomCompositeLexer.EnterLexer(NewLexer: TSepiCustomLexer);
begin
  FLexerStack.Push(FCurLexer);
  FCurLexer := NewLexer;

  CurLexerChanged;
end;

{*
  Entre dans un nouvel analyseur pour un fichier donn�
  Le type d'analyseur utilis� est le m�me que celui de l'analyseur courant
  @param FileName   Nom du fichier a charg� dans le nouvel analyseur
*}
procedure TSepiCustomCompositeLexer.EnterFile(const FileName: TFileName);
var
  CompleteFileName: TFileName;
  FileContents: TStrings;
  LexerClass: TSepiCustomLexerClass;
begin
  CompleteFileName := FindFile(FileName);

  FileContents := TStringList.Create;
  try
    FileContents.LoadFromFile(CompleteFileName);

    LexerClass := TSepiCustomLexerClass(CurLexer.ClassType);
    EnterLexer(LexerClass.Create(Errors, FileContents.Text, CompleteFileName));
  finally
    FileContents.Free;
  end;
end;

{*
  Quitte l'analyseur courant
  S'il n'y a plus d'analyseur "en r�serve", sur la pile, l'analyseur de base
  est amen� jusqu'� sa fin de fichier.
*}
procedure TSepiCustomCompositeLexer.LeaveCurLexer;
begin
  if FLexerStack.Count > 0 then
  begin
    FreeAndNil(FCurLexer);
    FCurLexer := TSepiCustomLexer(FLexerStack.Pop);

    CurLexerChanged;
  end else
  begin
    while not CurLexer.IsEof do
      CurLexer.NextTerminal;
  end;
end;

{*
  [@inheritDoc]
*}
function TSepiCustomCompositeLexer.MakeBookmark: TSepiLexerBookmark;
var
  CurLexerBookmark: TSepiLexerBookmark;
begin
  CurLexerBookmark := CurLexer.MakeBookmark;
  try
    Result := TSepiCompositeLexerBookmark.Create(FLexerChangeCount,
      CurLexerBookmark);
  except
    CurLexerBookmark.Free;
    raise;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TSepiCustomCompositeLexer.ResetToBookmark(
  ABookmark: TSepiLexerBookmark; FreeBookmark: Boolean = True);
var
  Bookmark: TSepiCompositeLexerBookmark;
begin
  Bookmark := ABookmark as TSepiCompositeLexerBookmark;

  if Bookmark.LexerChangeCount <> FLexerChangeCount then
    MakeError(SBookmarksCantPassThroughLexer, ekFatalError);

  CurLexer.ResetToBookmark(Bookmark.CurLexerBookmark, False);

  inherited;
end;

end.

