{*
  D�finit quelques routines usuelles
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit ScUtils;

interface

uses
{$IFDEF LINUX}
  QDialogs, QGraphics,
{$ENDIF}
  SysUtils, Classes, Math;

{$IFDEF LINUX}
const
  dtCustom = mtCustom;
  dtInformation = mtInformation;
  dtWarning = mtWarning;
  dtError = mtError;
  dtConfirmation = mtConfirmation;

  dbOK = [mbOK];
  dbOKCancel = mbOKCancel;
  dbYesNo = [mbYes, mbNo];
  dbYesNoCancel = mbYesNoCancel;
  dbRetryCancel = [mbRetry, mbCancel];
  dbAbortRetryIgnore = mbAbortRetryIgnore;

  drOK = mrOK;
  drYes = mrYes;
  drNo = mrNo;
  drCancel = mrCancel;
  drAbort = mrAbort;
  drRetry = mrRetry;
  drIgnore = mrIgnore;
{$ENDIF}

type

{$REGION 'Exceptions'}

  {*
    D�clench�e lorsqu'une erreur a �t� report�e par une API Windows
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  EAPIError = class(Exception)
  private
    FErrorCode : integer; /// Code d'erreur HRESULT
  public
    constructor Create(Error : integer); overload;
    constructor Create; overload;

    property ErrorCode : integer read FErrorCode;
  end platform;

{$ENDREGION}

  {*
    Repr�sente un point situ� dans un espace en trois dimensions
  *}
  T3DPoint = record
    X : integer; /// Coordonn�e X du point
    Y : integer; /// Coordonn�e Y du point
    Z : integer; /// Coordonn�e Z du point
  end;

  {*
    Type d'une bo�te de dialogue
    dtCustom       : Type g�n�rique
    dtInformation  : Information
    dtWarning      : Avertissement
    dtError        : Erreur
    dtConfirmation : Confirmation
  *}
  {$IFDEF MSWINDOWS}
    TDialogType = (dtCustom, dtInformation, dtWarning, dtError, dtConfirmation);
  {$ELSE}
    TDialogType = type TMsgDlgType;
  {$ENDIF}

  {*
    Boutons pr�sents dans une bo�te de dialogue
    dbOK               : OK
    dbOKCancel         : OK et Annuler
    dbYesNo            : Oui et Non
    dbYesNoCancel      : Oui, Non et Annuler
    dbRetryCancel      : R�essayer et Annuler
    dbAbortRetryIgnore : Abandonner, R�essayer et Ignorer
  *}
  {$IFDEF MSWINDOWS}
    TDialogButtons = (dbOK, dbOKCancel, dbYesNo, dbYesNoCancel, dbRetryCancel,
                      dbAbortRetryIgnore);
  {$ELSE}
    TDialogButtons = type TMsgDlgButtons;
  {$ENDIF}

  {*
    R�sultat de l'affichage d'une bo�te de dialogue
    drOK     : OK
    drYes    : Oui
    drNo     : Non
    drCancel : Annuler
    drAbort  : Abandonner
    drRetry  : R�essayer
    drIgnore : Ignorer
  *}
  {$IFDEF MSWINDOWS}
    TDialogResult = (drOK, drYes, drNo, drCancel, drAbort, drRetry, drIgnore);
  {$ELSE}
    TDialogResult = type Word;
  {$ENDIF}

  {*
    Ensemble de Byte
  *}
  TSysByteSet = set of Byte;

  {*
    Ensemble de caract�res
    Ce type est d�pr�ci�, utilisez TSysCharSet � la place.
  *}
  TSetOfChars = TSysCharSet {$IFNDEF DCTD} deprecated {$ENDIF};

  {*
    Ensemble de Byte
    Ce type est d�pr�ci�, utilisez TSysByteSet � la place.
  *}
  TSetOfBytes = TSysByteSet {$IFNDEF DCTD} deprecated {$ENDIF};

function Dir : string;

// Fonctions de If Imm�diat
function IIF(Cond : boolean; Int1, Int2 : integer) : integer; overload;
function IIF(Cond : boolean; Flo1, Flo2 : Double ) : Double ; overload;
function IIF(Cond : boolean; Chr1, Chr2 : Char   ) : Char   ; overload;
function IIF(Cond : boolean; const Str1, Str2 : string) : string; overload;
function IIF(Cond : boolean; Obj1, Obj2 : TObject) : TObject; overload;
function IIF(Cond : boolean; Ptr1, Ptr2 : Pointer) : Pointer; overload;
function IIF(Cond : boolean; Var1, Var2 : Variant) : Variant; overload;

function Point3DToString(Point3D : T3DPoint;
  const Delim : string = ' ') : string;

function MinMax(Value, Min, Max : integer) : integer;

function IntDiv(Op1, Op2 : integer) : integer;
function IntMod(Op1, Op2 : integer) : integer;

{$IFDEF MSWINDOWS}
function ShowMes(const Title, Text : string;
  Flags : LongWord) : integer; platform;
{$ENDIF}

function ShowDialog(const Title, Text : string;
  DlgType : TDialogType = dtInformation; DlgButtons : TDialogButtons = dbOK;
  DefButton : Byte = 1; AddFlags : LongWord = 0) : TDialogResult;

procedure Wait(Milliseconds : integer); deprecated;
procedure WaitProcessMessages(Milliseconds : integer);

function IntToStr0(Value, Digits : integer) : string;

function ReadStrFromStream(Stream : TStream) : string;
procedure WriteStrToStream(Stream : TStream; const Str : string);

function CorrectFileName(const FileName : string;
  AcceptPathDelim : boolean = False; AcceptDriveDelim : boolean = False) : boolean;

function Point3D(X, Y, Z : integer) : T3DPoint;

function Same3DPoint(Point1, Point2 : T3DPoint) : boolean;

{$IFDEF MSWINDOWS}
procedure RunURL(const URL : string; const Verb : string = 'open');
{$ENDIF}

implementation

uses
{$IFDEF MSWINDOWS}
  Windows, ShellAPI,
{$ENDIF}
  DateUtils, Forms;

{$REGION 'Classe EAPIError'}

{------------------}
{ Classe EAPIError }
{------------------}

{*
  Cr�e une nouvelle instance de EAPIError
  @param Error   Code d'erreur HRESULT
*}
constructor EAPIError.Create(Error : integer);
begin
  // Le message est r�cup�r� via SysErrorMessage
  inherited Create(SysErrorMessage(Error));
  FErrorCode := Error;
end;

{*
  Cr�e une nouvelle instance de EAPIError
  Le code d'erreur est r�cup�r� avec la routien GetLastError
*}
constructor EAPIError.Create;
begin
  Create(GetLastError);
end;

{$ENDREGION}

{----------------------------------}
{ Proc�dures et fonctions globales }
{----------------------------------}

{*
  Renvoie le chemin du dossier dans lequel se trouve l'application qui s'ex�cute
  @return Le chemin du dossier dans lequel se trouve l'application qui s'ex�cute
*}
function Dir : string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

{$REGION 'Fonctions de If Imm�diat'}

{*
  Fonction de If Imm�diat pour les entiers
  @param Cond   Condition � v�rifier
  @param Int1   Valeur � renvoyer si la condition est vraie
  @param Int2   Valeur � renvoyer si la condition est fausse
  @return Int1 si Cond vaut True, Int2 sinon
*}
function IIF(Cond : boolean; Int1, Int2 : integer) : integer;
begin
  if Cond then Result := Int1 else Result := Int2;
end;

{*
  Fonction de If Imm�diat pour les d�cimaux
  @param Cond   Condition � v�rifier
  @param Flo1   Valeur � renvoyer si la condition est vraie
  @param Flo2   Valeur � renvoyer si la condition est fausse
  @return Flo1 si Cond vaut True, Flo2 sinon
*}
function IIF(Cond : boolean; Flo1, Flo2 : Double) : Double;
begin
  if Cond then Result := Flo1 else Result := Flo2;
end;

{*
  Fonction de If Imm�diat pour les caract�res
  @param Cond   Condition � v�rifier
  @param Chr1   Valeur � renvoyer si la condition est vraie
  @param Chr2   Valeur � renvoyer si la condition est fausse
  @return Chr1 si Cond vaut True, Chr2 sinon
*}
function IIF(Cond : boolean; Chr1, Chr2 : Char) : Char;
begin
  if Cond then Result := Chr1 else Result := Chr2;
end;

{*
  Fonction de If Imm�diat pour les cha�nes de caract�res
  @param Cond   Condition � v�rifier
  @param Str1   Valeur � renvoyer si la condition est vraie
  @param Str2   Valeur � renvoyer si la condition est fausse
  @return Str1 si Cond vaut True, Str2 sinon
*}
function IIF(Cond : boolean; const Str1, Str2 : string) : string;
begin
  if Cond then Result := Str1 else Result := Str2;
end;

{*
  Fonction de If Imm�diat pour les objets
  @param Cond   Condition � v�rifier
  @param Obj1   Valeur � renvoyer si la condition est vraie
  @param Obj2   Valeur � renvoyer si la condition est fausse
  @return Obj1 si Cond vaut True, Obj2 sinon
*}
function IIF(Cond : boolean; Obj1, Obj2 : TObject) : TObject;
begin
  if Cond then Result := Obj1 else Result := Obj2;
end;

{*
  Fonction de If Imm�diat pour les pointeurs
  @param Cond   Condition � v�rifier
  @param Ptr1   Valeur � renvoyer si la condition est vraie
  @param Ptr2   Valeur � renvoyer si la condition est fausse
  @return Ptr1 si Cond vaut True, Ptr2 sinon
*}
function IIF(Cond : boolean; Ptr1, Ptr2 : Pointer) : Pointer;
begin
  if Cond then Result := Ptr1 else Result := Ptr2;
end;

{*
  Fonction de If Imm�diat pour les variants
  @param Cond   Condition � v�rifier
  @param Var1   Valeur � renvoyer si la condition est vraie
  @param Var2   Valeur � renvoyer si la condition est fausse
  @return Var1 si Cond vaut True, Var2 sinon
*}
function IIF(Cond : boolean; Var1, Var2 : Variant) : Variant;
begin
  if Cond then Result := Var1 else Result := Var2;
end;

{$ENDREGION}

{*
  Convertit un point 3D en cha�ne de caract�res
  @param Point3D   Point 3D � convertir
  @param Delim     D�limiteur � placer entre les coordonn�es
  @return Point3D convertit en cha�ne de caract�res
*}
function Point3DToString(Point3D : T3DPoint;
  const Delim : string = ' ') : string;
begin
  Result := IntToStr(Point3D.X) + Delim +
            IntToStr(Point3D.Y) + Delim +
            IntToStr(Point3D.Z);
end;

{*
  S'assure qu'une valeur est bien dans un intervalle sp�cifi�
  @param Value   Valeur de base
  @param Min     Valeur minimale
  @param Max     Valeur maximale
  @return Valeur la plus proche de Value dans l'intervalle [Min;Max]
*}
function MinMax(Value, Min, Max : integer) : integer;
begin
  if Value > Max then Result := Max else
  if Value < Min then Result := Min else
  Result := Value;
end;

{*
  Division euclidienne
  @param Op1   Dividande
  @param Op2   Diviseur
  @return R�sultat de la division euclidienne de Op1 par Op2
  @raise EDivByZero Division par 0
*}
function IntDiv(Op1, Op2 : integer) : integer;
begin
  Result := Floor(Op1 / Op2);
end;

{*
  Reste de la division euclidienne
  @param Op1   Dividande
  @param Op2   Diviseur
  @return Reste de la division euclidienne de Op1 par Op2
  @raise EDivByZero Division par 0
*}
function IntMod(Op1, Op2 : integer) : integer;
begin
  Result := Op1 - IntDiv(Op1, Op2) * Op2;
end;

{$REGION 'Fonctions de bo�tes de dialogue'}

{$IFDEF MSWINDOWS}
{*
  Affiche une bo�te de dialogue modale Windows
  @param Title   Titre de la bo�te de dialogue
  @param Text    Texte de la bo�te de dialogue
  @param Flags   Flags contr�lant le style de bo�te de dialogue
  @return Code de r�sultat du bouton sur lequel a cliqu� l'utilisateur
*}
function ShowMes(const Title, Text : string; Flags : LongWord) : integer;
var AText, ATitle : PChar;
    AFlags : LongWord;
begin
  AText  := PChar(Text);
  ATitle := PChar(Title);
  AFlags := Flags or MB_APPLMODAL; // Ajout du style Modal
  Result := MessageBox(Application.Handle, AText, ATitle, AFlags);
end;
{$ENDIF}

{*
  Affiche une bo�te de dialogue modale Windows ou QT (selon la VCL utilis�e)
  @param Title        Titre de la bo�te de dialogue
  @param Text         Texte de la bo�te de dialogue
  @param DlgType      Type de bo�te de dialogue
  @param DlgButtons   Boutons � placer dans la bo�te de dialogue
  @param DefButton    Num�ro du bouton s�lectionn� par d�faut (� partir de 1)
  @param AddFlags     Flags additionnels contr�lant de style de bo�te (Win32)
  @return Bouton sur lequel a cliqu� l'utilisateur
*}

{$IFDEF MSWINDOWS}
function ShowDialog(const Title, Text : string;
  DlgType : TDialogType = dtInformation; DlgButtons : TDialogButtons = dbOK;
  DefButton : Byte = 1; AddFlags : LongWord = 0) : TDialogResult;
var TypeFlags, BtnsFlags, DefBtnFlags, Flags : LongWord;
begin
  // Transformation du param�tre DlgType en flag de type
  case DlgType of
    dtCustom       : TypeFlags := 0;
    dtInformation  : TypeFlags := MB_ICONINFORMATION;
    dtWarning      : TypeFlags := MB_ICONEXCLAMATION;
    dtError        : TypeFlags := MB_ICONERROR;
    dtConfirmation : TypeFlags := MB_ICONQUESTION;
    else TypeFlags := 0;
  end;

  // Transformation du param�tre DlgButtons en flag de boutons
  case DlgButtons of
    dbOK               : BtnsFlags := MB_OK;
    dbOKCancel         : BtnsFlags := MB_OKCANCEL;
    dbYesNo            : BtnsFlags := MB_YESNO;
    dbYesNoCancel      : BtnsFlags := MB_YESNOCANCEL;
    dbRetryCancel      : BtnsFlags := MB_RETRYCANCEL;
    dbAbortRetryIgnore : BtnsFlags := MB_AbortRetryIgnore;
    else BtnsFlags := MB_OK;
  end;

  // Transformation du param�tre DefButton en flag de bouton par d�faut
  case DefButton of
    1 : DefBtnFlags := MB_DEFBUTTON1;
    2 : DefBtnFlags := MB_DEFBUTTON2;
    3 : DefBtnFlags := MB_DEFBUTTON3;
    else DefBtnFlags := 0;
  end;

  // Appel de ShowMes et transformation du retour Word en TDialogResult
  Flags := TypeFlags or BtnsFlags or DefBtnFlags or AddFlags;
  case ShowMes(Title, Text, Flags) of
    IDOK     : Result := drOK;
    IDYES    : Result := drYes;
    IDNO     : Result := drNo;
    IDCANCEL : Result := drCancel;
    IDABORT  : Result := drAbort;
    IDRETRY  : Result := drRetry;
    IDIGNORE : Result := drIgnore;
    else Result := drCancel;
  end;
end;
{$ENDIF}

{$IFDEF LINUX}
function ShowDialog(const Title, Text : string;
  DlgType : TDialogType = dtInformation; DlgButtons : TDialogButtons = dbOK;
  DefButton : Byte = 1; AddFlags : LongWord = 0) : TDialogResult;
var NbBtns : integer;
    MsgDefButton : TMsgDlgBtn;
begin
  // D�termination du nombre de boutons
  case DlgButtons of
    dbOK               : NbBtns := 1;
    dbOKCancel         : NbBtns := 2;
    dbYesNo            : NbBtns := 2;
    dbYesNoCancel      : NbBtns := 3;
    dbRetryCancel      : NbBtns := 2;
    dbAbortRetryIgnore : NbBtns := 3;
    else begin NbBtns := 1 end;
  end;

  MsgDefButton := mbNone;
  if (DefButton < 1) or (DefButton > NbBtns) then DefButton := 1;

  // D�termination du bouton par d�faut
  case DefButton of
    1 :
    begin
      if DlgButtons = [dbOK, dbOKCancel] then
        MsgDefButton := mbOK else
      if DlgButtons = [dbYesNo, dbYesNoCancel] then
        MsgDefButton := mbYes else
      if DlgButtons = dbRetryCancel then
        MsgDefButton := mbRetry else
      if DlgButtons = dbAbortRetryIgnore then
        MsgDefButton := mbAbort;
    end;
    2 :
    begin
      if DlgButtons = [dbOKCancel, dbRetryCancel] then
        MsgDefButton := mbCancel else
      if DlgButtons = [dbYesNo, dbYesNoCancel]
        then MsgDefButton := mbNo else
      if DlgButtons = dbAbortRetryIgnore then
        MsgDefButton := mbRetry;
    end;
    3 :
    begin
      if DlgButtons = dbYesNoCancel then
        MsgDefButton := mbCancel else
      if DlgButtons = dbAbortRetryIgnore then
        MsgDefButton := mbIgnore;
    end;
  end;

  // Appel de MessageDlg et renvoi de la valeur renvoy�e par celle-ci
  Result := MessageDlg(Title, Text, DlgType, DlgButtons, 0, MsgDefBtn);
end;
{$ENDIF}

{$ENDREGION}

{*
  Met en pause l'ex�cution pendant un temps d�fini
  Cette routine est d�pr�ci�e, utilisez Sleep � la place.
  @param Milliseconds   Nombre de milisecondes pendant lesquelles pauser
*}
procedure Wait(Milliseconds : integer);
begin
  Sleep(Milliseconds);
end;

{*
  Met en pause l'ex�cution pendant un temps d�fini
  Pendant cette pause, les messages Windows de l'applications sont tout de
  m�me trait�s.
  @param Milliseconds   Nombre de milisecondes pendant lesquelles pauser
*}
procedure WaitProcessMessages(Milliseconds : integer);
var BeginTime : TDateTime;
begin
  BeginTime := Now;
  while MilliSecondsBetween(Now, BeginTime) < Milliseconds do
    Application.ProcessMessages;
end;

{*
  Convertit un entier en cha�ne, avec un nombre minimal de caract�res sp�cifi�
  Exemples : IntToStr(345, 4) = '0345' ; IntToStr0(1000, 3) = '1000'
  @param Value    Entier � convertir
  @param Digits   Nombre minimal de caract�res de la cha�ne convertie
  @return La repr�sentation en cha�ne de Value, avec Digits caract�res minimum
*}
function IntToStr0(Value, Digits : integer) : string;
begin
  Result := Format('%.*d', [Digits, Value]);
end;

{*
  Lit une cha�ne de caract�res depuis un flux
  Cette cha�ne doit avoir �t� �crite avec WriteStrToStream.
  @param Stream   Flux depuis lequel lire la cha�ne
  @return La cha�ne lue
*}
function ReadStrFromStream(Stream : TStream) : string;
var Len : integer;
begin
  Stream.ReadBuffer(Len, 4);
  SetLength(Result, Len);
  Stream.ReadBuffer(Result[1], Len);
end;

{*
  �crit une cha�ne de caract�res dans un flux
  Cette chaine pourra �tre relue avec ReadStrFromStream.
  @param Stream   Flux dans lequel enregistrer la cha�ne
  @param Str      Cha�ne de caract�res � �crire
*}
procedure WriteStrToStream(Stream : TStream; const Str : string);
var Len : integer;
begin
  Len := Length(Str);
  Stream.WriteBuffer(Len, 4);
  Stream.WriteBuffer(Str[1], Len);
end;

{*
  Teste si une cha�ne de caract�res est un nom de fichier correct
  Ce test est effectu� conform�ment aux r�gles de nommage des fichiers du
  syst�me d'exploitation.
  @param FileName           Cha�ne � tester
  @param AcceptPathDelim    Indique si le s�parateur de chemin est accept�
  @param AcceptDriveDelim   Indique si le s�parateur de disque est accept�
  @return True si FileName est un nom de fichier correct, False sinon
*}
function CorrectFileName(const FileName : string;
  AcceptPathDelim : boolean = False;
  AcceptDriveDelim : boolean = False) : boolean;
var I : integer;
    BadChars : set of Char;
begin
  BadChars := ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
  Result := False;
  if FileName = '' then exit;

  // Si le d�limiteur de chemin est accept�, on l'exclut de BadChars
  if AcceptPathDelim then
    Exclude(BadChars, PathDelim);

  // Si le d�limiteur de disque est accept�, on l'exclut de BadChars
  if AcceptDriveDelim then
    Exclude(BadChars, DriveDelim);

  // On teste tous les caract�res de FileName
  for I := 1 to Length(FileName) do if FileName[I] in BadChars then exit;
  Result := True;
end;

{*
  Cr�e un point 3D
  @param X   Coordonn�e X du point
  @param Y   Coordonn�e Y du point
  @param Z   Coordonn�e Z du point
  @return Le point 3D (X, Y, Z)
*}
function Point3D(X, Y, Z : integer) : T3DPoint;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

{*
  Compare deux points 3D
  @param Point1   Premier point
  @param Point2   Second point
  @return True si Point1 et Point2 sont identiques, False sinon
*}
function Same3DPoint(Point1, Point2 : T3DPoint) : boolean;
begin
  Result := (Point1.X = Point2.X) and
    (Point1.Y = Point2.Y) and (Point1.Z = Point2.Z);
end;

{$IFDEF MSWINDOWS}
{*
  Lance une URL
  @param URL    URL � lancer
  @param Verb   Verbe � utiliser pour lancer l'URL
*}
procedure RunURL(const URL : string; const Verb : string = 'open');
begin
  ShellExecute(GetDesktopWindow(), PChar(Verb), PChar(URL),
    nil, nil, SW_SHOWNORMAL);
end;
{$ENDIF}

end.

